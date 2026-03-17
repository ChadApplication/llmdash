import Foundation
import WebKit

@MainActor
class BalanceAutoRefresher: NSObject, ObservableObject {
    @Published var lastRefreshed: Date?
    @Published var isRefreshing = false

    private var timer: Timer?
    private var fetchers: [ProviderType: BackgroundFetcher] = [:]
    private var onBalanceUpdated: ((ProviderType, Double) -> Void)?

    func start(interval: TimeInterval = 300, onUpdate: @escaping (ProviderType, Double) -> Void) {
        self.onBalanceUpdated = onUpdate
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refreshAll()
            }
        }
        // Run immediately on start
        Task { await refreshAll() }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func refreshAll() async {
        guard !isRefreshing else { return }
        isRefreshing = true

        let providers: [ProviderType] = [.openai, .anthropic]
        for provider in providers {
            await fetchBalance(for: provider)
        }

        lastRefreshed = Date()
        isRefreshing = false
    }

    private func fetchBalance(for provider: ProviderType) async {
        let fetcher: BackgroundFetcher
        if let existing = fetchers[provider] {
            fetcher = existing
        } else {
            fetcher = BackgroundFetcher(providerType: provider)
            fetchers[provider] = fetcher
        }

        let balance = await fetcher.fetch()
        if let balance {
            onBalanceUpdated?(provider, balance)
        }
    }
}

@MainActor
private class BackgroundFetcher: NSObject, WKNavigationDelegate {
    let providerType: ProviderType
    private var webView: WKWebView
    private var continuation: CheckedContinuation<Double?, Never>?

    var billingURL: URL {
        switch providerType {
        case .openai:
            return URL(string: "https://platform.openai.com/settings/organization/billing/overview")!
        case .anthropic:
            return URL(string: "https://platform.claude.com/settings/billing")!
        case .google:
            return URL(string: "https://aistudio.google.com/")!
        }
    }

    init(providerType: ProviderType) {
        self.providerType = providerType
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        self.webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: config)
        super.init()
        self.webView.navigationDelegate = self
    }

    func fetch() async -> Double? {
        return await withCheckedContinuation { cont in
            self.continuation = cont
            self.webView.load(URLRequest(url: billingURL))

            // Timeout after 30 seconds
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                if let cont = self.continuation {
                    self.continuation = nil
                    cont.resume(returning: nil)
                }
            }
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            guard let url = webView.url?.absoluteString else { return }

            // Only extract on billing page
            guard url.contains("billing") else {
                // Redirected to login = session expired, give up
                if url.contains("login") || url.contains("signin") {
                    if let cont = self.continuation {
                        self.continuation = nil
                        cont.resume(returning: nil)
                    }
                }
                return
            }

            // Wait for page render
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            let balance = await self.extractBalance()
            if let cont = self.continuation {
                self.continuation = nil
                cont.resume(returning: balance)
            }
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            if let cont = self.continuation {
                self.continuation = nil
                cont.resume(returning: nil)
            }
        }
    }

    private func extractBalance() async -> Double? {
        // Get page text and parse with same logic as WebBalanceFetcher
        let dumpJS = "document.body.innerText"
        guard let result = try? await webView.evaluateJavaScript(dumpJS),
              let pageText = result as? String else {
            return nil
        }

        let patterns: [String]
        switch providerType {
        case .openai:
            patterns = [
                "(?i)credit\\s*balance\\s*\\$\\s*([\\d,]+\\.\\d{2})",
                "(?i)credit\\s*balance[^\\$]{0,30}\\$\\s*([\\d,]+\\.\\d{2})",
                "(?i)pay\\s*as\\s*you\\s*go[\\s\\S]*?credit\\s*balance[^\\$]{0,30}\\$\\s*([\\d,]+\\.\\d{2})",
            ]
        case .anthropic:
            // Actual format: "$145.49Remaining Balance$689.64 pending"
            patterns = [
                "\\$\\s*([\\d,]+\\.\\d{2})\\s*Remaining\\s*Balance",
                "\\$\\s*([\\d,]+\\.\\d{2})[^\\$]{0,20}Remaining\\s*Balance",
            ]
        case .google:
            return nil
        }

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: pageText, range: NSRange(pageText.startIndex..., in: pageText)),
               let range = Range(match.range(at: 1), in: pageText) {
                let valueStr = pageText[range].replacingOccurrences(of: ",", with: "")
                if let value = Double(valueStr) {
                    return value
                }
            }
        }
        return nil
    }
}
