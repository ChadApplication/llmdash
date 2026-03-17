import Foundation

struct UsageData: Identifiable {
    let id = UUID()
    let providerAccountId: UUID
    let providerType: ProviderType
    let providerName: String

    var totalTokensUsed: Int
    var totalCost: Double
    var remainingCredits: Double?
    var hardLimitUSD: Double?
    var currentPeriodStart: Date?
    var currentPeriodEnd: Date?
    var lastUpdated: Date

    var formattedCost: String {
        String(format: "$%.2f", totalCost)
    }

    var formattedRemaining: String {
        guard let remaining = remainingCredits else { return "N/A" }
        return String(format: "$%.2f", remaining)
    }

    var formattedTokens: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: totalTokensUsed)) ?? "\(totalTokensUsed)"
    }
}

struct DailyUsage: Identifiable {
    let id = UUID()
    let date: Date
    let tokensUsed: Int
    let cost: Double
}
