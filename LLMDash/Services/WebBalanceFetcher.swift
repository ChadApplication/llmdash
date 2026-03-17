import Foundation
import WebKit

@MainActor
class WebBalanceFetcher: NSObject, ObservableObject {
    @Published var isLoading = false
    @Published var isLoggedIn = false
    @Published var balance: Double?
    @Published var error: String?
    @Published var debugPageText: String?

    let providerType: ProviderType
    private var webView: WKWebView?
    private var onBalanceFetched: ((Double?) -> Void)?

    var loginURL: URL {
        switch providerType {
        case .openai:
            return URL(string: "https://platform.openai.com/login")!
        case .anthropic:
            return URL(string: "https://platform.claude.com/login")!
        case .google:
            return URL(string: "https://aistudio.google.com/")!
        }
    }

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
        super.init()
    }

    func createWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = persistentDataStore()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = self
        self.webView = wv
        return wv
    }

    func loadLogin() {
        isLoading = true
        error = nil
        webView?.load(URLRequest(url: loginURL))
    }

    func fetchBalance(completion: @escaping (Double?) -> Void) {
        onBalanceFetched = completion
        isLoading = true
        webView?.load(URLRequest(url: billingURL))
    }

    private func parseBalance(from text: String) -> Double? {
        let patterns: [String]
        switch providerType {
        case .openai:
            // Path: Billing > Overview > Pay as you go > Credit balance
            patterns = [
                "(?i)credit\\s*balance\\s*\\$\\s*([\\d,]+\\.\\d{2})",
                "(?i)credit\\s*balance[^\\$]{0,30}\\$\\s*([\\d,]+\\.\\d{2})",
                "(?i)pay\\s*as\\s*you\\s*go[\\s\\S]*?credit\\s*balance[^\\$]{0,30}\\$\\s*([\\d,]+\\.\\d{2})",
            ]
        case .anthropic:
            // Actual format: "$145.49Remaining Balance$689.64 pending"
            // The dollar amount BEFORE "Remaining Balance" is the actual balance
            patterns = [
                // Dollar amount immediately before "Remaining Balance"
                "\\$\\s*([\\d,]+\\.\\d{2})\\s*Remaining\\s*Balance",
                // Dollar amount with some gap before "Remaining Balance"
                "\\$\\s*([\\d,]+\\.\\d{2})[^\\$]{0,20}Remaining\\s*Balance",
            ]
        case .google:
            return nil
        }

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                let valueStr = text[range].replacingOccurrences(of: ",", with: "")
                if let value = Double(valueStr) {
                    return value
                }
            }
        }
        return nil
    }

    private func extractBalanceWithRetry(attempt: Int = 1) {
        let dumpJS = "document.body.innerText"

        webView?.evaluateJavaScript(dumpJS) { [weak self] result, err in
            guard let self else { return }

            guard let pageText = result as? String else {
                self.isLoading = false
                self.error = "Could not read page content"
                self.onBalanceFetched?(nil)
                return
            }

            self.debugPageText = pageText
            let balance = self.parseBalance(from: pageText)

            if let balance {
                self.isLoading = false
                self.balance = balance
                self.isLoggedIn = true
                self.onBalanceFetched?(balance)
            } else if attempt < 3 {
                // Page might not be fully rendered yet, retry after 3 seconds
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    self.extractBalanceWithRetry(attempt: attempt + 1)
                }
            } else {
                self.isLoading = false
                self.error = "Balance not found after \(attempt) attempts. Page preview: \(String(pageText.prefix(300)))"
                self.onBalanceFetched?(nil)
            }
        }
    }

    private func persistentDataStore() -> WKWebsiteDataStore {
        return WKWebsiteDataStore.default()
    }
}

extension WebBalanceFetcher: WKNavigationDelegate {
    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            guard let currentURL = webView.url else { return }
            let urlStr = currentURL.absoluteString

            // Check if we landed on the billing page
            let isBillingPage: Bool
            switch providerType {
            case .openai:
                isBillingPage = urlStr.contains("billing")
            case .anthropic:
                isBillingPage = urlStr.contains("billing")
            case .google:
                isBillingPage = false
            }

            if isBillingPage {
                // Wait for SPA page to fully render (longer for OpenAI which does client-side routing)
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                extractBalanceWithRetry()
            } else {
                isLoading = false
                isLoggedIn = true
            }
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            self.isLoading = false
            self.error = error.localizedDescription
        }
    }
}
