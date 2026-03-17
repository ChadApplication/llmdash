import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("LLMDash")
                    .font(.headline)
                Spacer()
                Button(action: { Task { await appState.refreshAll() } }) {
                    Image(systemName: appState.isLoading ? "arrow.trianglehead.2.clockwise" : "arrow.clockwise")
                        .rotationEffect(.degrees(appState.isLoading ? 360 : 0))
                        .animation(appState.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: appState.isLoading)
                }
                .buttonStyle(.borderless)

                Button(action: {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "settings")
                }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Summary
            HStack(spacing: 20) {
                SummaryCard(title: "Total Cost", value: String(format: "$%.2f", appState.totalCost), icon: "dollarsign.circle.fill", color: .orange)
                SummaryCard(title: "Providers", value: "\(appState.accounts.filter(\.isActive).count)", icon: "server.rack", color: .blue)
            }
            .padding(16)

            Divider()

            // Provider List
            if appState.accounts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No API keys added")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button(action: {
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "settings")
                    }) {
                        Text("Add API Key")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(appState.accounts) { account in
                            ProviderCardView(account: account, usage: appState.usageDataMap[account.id])
                        }
                    }
                    .padding(12)
                }
            }

            // Error
            if let error = appState.lastError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text(error)
                        .font(.caption2)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

            Divider()

            // Footer
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Auto-refresh: 5min")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if let lastBalance = appState.lastBalanceRefresh {
                        Text("Balance: \(lastBalance.formatted(.relative(presentation: .named)))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                .font(.caption2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 360, height: 480)
        .task {
            await appState.refreshAll()
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
