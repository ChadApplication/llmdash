import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            APIKeysTab()
                .environmentObject(appState)
                .tabItem {
                    Label("API Keys", systemImage: "key.fill")
                }

            BalanceFetchTab()
                .environmentObject(appState)
                .tabItem {
                    Label("Balance", systemImage: "dollarsign.circle")
                }
        }
        .frame(width: 520, height: 450)
    }
}

// MARK: - Balance Fetch Tab

struct BalanceFetchTab: View {
    @EnvironmentObject var appState: AppState
    @State private var showWebLogin: ProviderType?
    @State private var fetchStatus: [ProviderType: FetchStatus] = [:]

    enum FetchStatus {
        case success(Double)
        case failed(String)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Fetch Balance from Web")
                    .font(.title2.bold())
                Spacer()
            }
            .padding()

            Divider()

            VStack(spacing: 12) {
                Text("Log in to each provider's billing page to automatically fetch your remaining balance.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)

                ForEach([ProviderType.openai, .anthropic], id: \.self) { provider in
                    HStack {
                        // Status indicator
                        Circle()
                            .fill(statusColor(for: provider))
                            .frame(width: 10, height: 10)

                        Image(systemName: provider.iconName)
                            .foregroundColor(provider == .openai ? .green : .orange)
                            .frame(width: 24)

                        Text(provider.rawValue)
                            .font(.body.bold())

                        Spacer()

                        // Balance or error display
                        switch fetchStatus[provider] {
                        case .success(let balance):
                            Text("$\(String(format: "%.2f", balance))")
                                .font(.body.bold())
                                .foregroundColor(.green)
                        case .failed(let msg):
                            Text(msg)
                                .font(.caption)
                                .foregroundColor(.red)
                                .lineLimit(1)
                        case nil:
                            if let balance = appState.fetchedBalances[provider] {
                                Text("$\(String(format: "%.2f", balance))")
                                    .font(.body.bold())
                                    .foregroundColor(.green)
                            } else {
                                Text("Not connected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button("Fetch") {
                            showWebLogin = provider
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                }
            }

            Spacer()

            Text("Session cookies are stored locally. You only need to log in once.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.bottom, 12)
        }
        .sheet(item: $showWebLogin) { provider in
            WebLoginView(providerType: provider) { result in
                switch result {
                case .success(let balance):
                    fetchStatus[provider] = .success(balance)
                    appState.fetchedBalances[provider] = balance
                    appState.updateBalanceForAccounts(provider: provider, balance: balance)
                case .failure(let error):
                    fetchStatus[provider] = .failed(error)
                }
                showWebLogin = nil
            }
            .interactiveDismissDisabled()
        }
    }

    private func statusColor(for provider: ProviderType) -> Color {
        switch fetchStatus[provider] {
        case .success:
            return .green
        case .failed:
            return .red
        case nil:
            return appState.fetchedBalances[provider] != nil ? .green : .gray
        }
    }
}

extension ProviderType: Hashable {}

// MARK: - API Keys Tab

struct APIKeysTab: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddSheet = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("API Key Management")
                    .font(.title2.bold())
                Spacer()
                Button(action: { showAddSheet = true }) {
                    Label("Add Key", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()

            Divider()

            if appState.accounts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No API keys configured")
                        .font(.headline)
                    Text("Add your LLM provider API keys to start monitoring usage.\nOpenAI and Anthropic require Admin API keys for usage tracking.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(appState.accounts) { account in
                        AccountRow(account: account, onDelete: {
                            appState.removeAccount(account)
                        })
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddAccountSheet(isPresented: $showAddSheet) { account in
                appState.addAccount(account)
            }
        }
    }
}

struct AccountRow: View {
    let account: LLMProviderAccount
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        HStack {
            Image(systemName: account.type.iconName)
                .foregroundColor(providerColor)
                .frame(width: 24)

            VStack(alignment: .leading) {
                Text(account.name)
                    .font(.body.bold())
                HStack(spacing: 4) {
                    Text(maskedKey(account.apiKey))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontDesign(.monospaced)
                    if let balance = account.manualBalance {
                        Text("| Balance: $\(String(format: "%.2f", balance))")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()

            Text(account.type.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(providerColor.opacity(0.15))
                .cornerRadius(4)

            Button(action: { showDeleteConfirm = true }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
            .confirmationDialog("Delete \(account.name)?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive, action: onDelete)
                Button("Cancel", role: .cancel) {}
            }
        }
        .padding(.vertical, 4)
    }

    private var providerColor: Color {
        switch account.type {
        case .openai: return .green
        case .anthropic: return .orange
        case .google: return .blue
        }
    }

    private func maskedKey(_ key: String) -> String {
        guard key.count > 8 else { return "****" }
        let prefix = String(key.prefix(4))
        let suffix = String(key.suffix(4))
        return "\(prefix)...\(suffix)"
    }
}

struct AddAccountSheet: View {
    @Binding var isPresented: Bool
    let onAdd: (LLMProviderAccount) -> Void

    @State private var name = ""
    @State private var selectedType: ProviderType = .openai
    @State private var apiKey = ""
    @State private var balanceStr = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Add API Key")
                .font(.title2.bold())

            Form {
                TextField("Display Name", text: $name)
                    .textFieldStyle(.roundedBorder)

                Picker("Provider", selection: $selectedType) {
                    ForEach(ProviderType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }

                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)

                if selectedType.requiresAdminKey {
                    Text(selectedType.adminKeyHint)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }

                TextField("Remaining Balance (USD, optional)", text: $balanceStr)
                    .textFieldStyle(.roundedBorder)

                Text(selectedType.balanceHint)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add") {
                    let balance = Double(balanceStr)
                    let account = LLMProviderAccount(
                        name: name.isEmpty ? selectedType.rawValue : name,
                        type: selectedType,
                        apiKey: apiKey,
                        manualBalance: balance
                    )
                    onAdd(account)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(apiKey.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 440)
    }
}
