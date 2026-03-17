import Foundation
import SwiftUI
import Combine
import WidgetKit

@MainActor
class AppState: ObservableObject {
    @Published var accounts: [LLMProviderAccount] = []
    @Published var usageDataMap: [UUID: UsageData] = [:]
    @Published var fetchedBalances: [ProviderType: Double] = [:]
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var lastBalanceRefresh: Date?

    private let accountStore = AccountStore()
    private let usageService = UsageService()
    private var refreshTimer: Timer?
    private let balanceRefresher = BalanceAutoRefresher()

    init() {
        loadAccounts()
        startAutoRefresh()
        startBalanceAutoRefresh()
    }

    func loadAccounts() {
        accounts = accountStore.loadAccounts()
    }

    func addAccount(_ account: LLMProviderAccount) {
        accounts.append(account)
        accountStore.saveAccounts(accounts)
        Task { await fetchUsage(for: account) }
    }

    func removeAccount(_ account: LLMProviderAccount) {
        accounts.removeAll { $0.id == account.id }
        usageDataMap.removeValue(forKey: account.id)
        accountStore.saveAccounts(accounts)
    }

    func refreshAll() async {
        isLoading = true
        lastError = nil

        await withTaskGroup(of: Void.self) { group in
            for account in accounts where account.isActive {
                group.addTask { [weak self] in
                    await self?.fetchUsage(for: account)
                }
            }
        }

        isLoading = false
        syncToWidget()
    }

    func fetchUsage(for account: LLMProviderAccount) async {
        do {
            let usage = try await usageService.fetchUsage(for: account)
            usageDataMap[account.id] = usage
        } catch {
            lastError = "\(account.name): \(error.localizedDescription)"
        }
    }

    var totalCost: Double {
        usageDataMap.values.reduce(0) { $0 + $1.totalCost }
    }

    var totalTokens: Int {
        usageDataMap.values.reduce(0) { $0 + $1.totalTokensUsed }
    }

    func updateBalanceForAccounts(provider: ProviderType, balance: Double) {
        fetchedBalances[provider] = balance
        for i in accounts.indices where accounts[i].type == provider {
            accounts[i].manualBalance = balance
        }
        accountStore.saveAccounts(accounts)
        for account in accounts where account.type == provider {
            if var usage = usageDataMap[account.id] {
                usage.remainingCredits = balance
                usage.hardLimitUSD = balance
                usageDataMap[account.id] = usage
            }
        }
        syncToWidget()
    }

    func syncToWidget() {
        let providers = accounts.map { account in
            let usage = usageDataMap[account.id]
            return SharedProviderBalance(
                providerName: account.name,
                providerType: account.type.rawValue,
                balance: usage?.remainingCredits ?? account.manualBalance,
                cost: usage?.totalCost ?? 0,
                tokens: usage?.totalTokensUsed ?? 0,
                lastUpdated: usage?.lastUpdated ?? Date()
            )
        }
        let shared = SharedBalanceData(
            providers: providers,
            totalCost: totalCost,
            lastUpdated: Date()
        )
        shared.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Balance Auto Refresh (every 5 min via background WebView)

    private func startBalanceAutoRefresh() {
        balanceRefresher.start(interval: 300) { [weak self] provider, balance in
            Task { @MainActor [weak self] in
                self?.updateBalanceForAccounts(provider: provider, balance: balance)
                self?.lastBalanceRefresh = Date()
            }
        }
    }

    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.refreshAll()
            }
        }
    }
}
