import SwiftUI
import WebKit

enum BalanceFetchResult {
    case success(Double)
    case failure(String)
}

struct WebLoginView: View {
    let providerType: ProviderType
    let onResult: (BalanceFetchResult) -> Void
    @Environment(\.dismiss) private var dismiss

    @StateObject private var fetcher: WebBalanceFetcher
    @State private var showDebug = false

    init(providerType: ProviderType, onResult: @escaping (BalanceFetchResult) -> Void) {
        self.providerType = providerType
        self.onResult = onResult
        _fetcher = StateObject(wrappedValue: WebBalanceFetcher(providerType: providerType))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(providerType.rawValue) - Fetch Balance")
                    .font(.headline)

                Spacer()

                if fetcher.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }

                Button("Fetch Balance") {
                    fetcher.fetchBalance { value in
                        if let value {
                            onResult(.success(value))
                        } else {
                            onResult(.failure(fetcher.error ?? "Balance not found"))
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button(showDebug ? "Hide Debug" : "Debug") {
                    showDebug.toggle()
                }
                .controlSize(.small)

                Button("Close") {
                    dismiss()
                }
                .controlSize(.small)
            }
            .padding(12)

            // Status messages
            if let balance = fetcher.balance {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Balance found: $\(String(format: "%.2f", balance))")
                        .font(.subheadline.bold())
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

            if let error = fetcher.error {
                HStack(alignment: .top) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .lineLimit(3)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

            // Debug panel
            if showDebug, let pageText = fetcher.debugPageText {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Page Text (for debugging):")
                        .font(.caption.bold())
                    ScrollView {
                        Text(pageText)
                            .font(.system(size: 10, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(height: 150)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
            }

            Divider()

            // WebView
            WebViewRepresentable(fetcher: fetcher)
        }
        .frame(width: 900, height: 700)
        .onAppear {
            fetcher.loadLogin()
        }
    }
}

struct WebViewRepresentable: NSViewRepresentable {
    let fetcher: WebBalanceFetcher

    func makeNSView(context: Context) -> WKWebView {
        return fetcher.createWebView()
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
