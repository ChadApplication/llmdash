import SwiftUI

struct ProviderCardView: View {
    let account: LLMProviderAccount
    let usage: UsageData?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Provider header
            HStack {
                Image(systemName: account.type.iconName)
                    .foregroundColor(providerColor)
                    .frame(width: 20)
                Text(account.name)
                    .font(.subheadline.bold())
                Spacer()
                Text(account.type.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(providerColor.opacity(0.15))
                    .cornerRadius(4)
            }

            if let usage = usage {
                // Cost info
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cost")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(usage.formattedCost)
                            .font(.callout.bold())
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Remaining")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(usage.formattedRemaining)
                            .font(.callout.bold())
                            .foregroundColor(remainingColor(usage))
                    }
                }

                // Usage bar
                if let remaining = usage.remainingCredits, let limit = usage.hardLimitUSD, limit > 0 {
                    let usageRatio = min(usage.totalCost / limit, 1.0)
                    VStack(alignment: .leading, spacing: 2) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.secondary.opacity(0.2))
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(barColor(ratio: usageRatio))
                                    .frame(width: geo.size.width * usageRatio)
                            }
                        }
                        .frame(height: 6)

                        Text(String(format: "%.0f%% used", usageRatio * 100))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Last updated
                if let date = usage.lastUpdated as Date? {
                    Text("Updated: \(date.formatted(.relative(presentation: .named)))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }

    private var providerColor: Color {
        switch account.type {
        case .openai: return .green
        case .anthropic: return .orange
        case .google: return .blue
        }
    }

    private func remainingColor(_ usage: UsageData) -> Color {
        guard let remaining = usage.remainingCredits, let limit = usage.hardLimitUSD, limit > 0 else {
            return .primary
        }
        let ratio = remaining / limit
        if ratio < 0.1 { return .red }
        if ratio < 0.3 { return .orange }
        return .green
    }

    private func barColor(ratio: Double) -> Color {
        if ratio > 0.9 { return .red }
        if ratio > 0.7 { return .orange }
        return .green
    }
}
