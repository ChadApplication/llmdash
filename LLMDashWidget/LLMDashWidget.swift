import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct BalanceEntry: TimelineEntry {
    let date: Date
    let providers: [SharedProviderBalance]
    let totalCost: Double
    let isPlaceholder: Bool

    static var placeholder: BalanceEntry {
        BalanceEntry(
            date: .now,
            providers: [
                SharedProviderBalance(providerName: "OpenAI", providerType: "OpenAI", balance: 50.00, cost: 12.34, tokens: 150000, lastUpdated: .now),
                SharedProviderBalance(providerName: "Anthropic", providerType: "Anthropic", balance: 145.49, cost: 54.51, tokens: 320000, lastUpdated: .now),
            ],
            totalCost: 66.85,
            isPlaceholder: true
        )
    }
}

struct BalanceTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> BalanceEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (BalanceEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> BalanceEntry {
        guard let data = SharedBalanceData.load() else {
            return .placeholder
        }
        return BalanceEntry(
            date: data.lastUpdated,
            providers: data.providers,
            totalCost: data.totalCost,
            isPlaceholder: false
        )
    }
}

// MARK: - Widget Views

struct SmallWidgetView: View {
    let entry: BalanceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                Text("LLMDash")
                    .font(.caption.bold())
            }

            Spacer()

            ForEach(entry.providers.prefix(2), id: \.providerName) { provider in
                HStack {
                    Circle()
                        .fill(colorForProvider(provider.providerType))
                        .frame(width: 6, height: 6)
                    Text(provider.providerName)
                        .font(.caption2)
                    Spacer()
                    if let balance = provider.balance {
                        Text("$\(String(format: "%.2f", balance))")
                            .font(.caption2.bold())
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer()

            Text(entry.date.formatted(.relative(presentation: .named)))
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .padding(12)
    }

    private func colorForProvider(_ type: String) -> Color {
        switch type {
        case "OpenAI": return .green
        case "Anthropic": return .orange
        default: return .blue
        }
    }
}

struct MediumWidgetView: View {
    let entry: BalanceEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: Summary
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.blue)
                    Text("LLMDash")
                        .font(.subheadline.bold())
                }

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Cost")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("$\(String(format: "%.2f", entry.totalCost))")
                        .font(.title3.bold())
                        .foregroundColor(.orange)
                }

                Text(entry.date.formatted(.relative(presentation: .named)))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }

            Divider()

            // Right: Provider list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(entry.providers, id: \.providerName) { provider in
                    HStack {
                        Circle()
                            .fill(colorForProvider(provider.providerType))
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(provider.providerName)
                                .font(.caption.bold())
                            if let balance = provider.balance {
                                Text("Balance: $\(String(format: "%.2f", balance))")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }

                        Spacer()

                        if provider.cost > 0 {
                            Text("$\(String(format: "%.2f", provider.cost))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if entry.providers.isEmpty {
                    Text("No providers configured")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(14)
    }

    private func colorForProvider(_ type: String) -> Color {
        switch type {
        case "OpenAI": return .green
        case "Anthropic": return .orange
        default: return .blue
        }
    }
}

// MARK: - Widget Definition

struct LLMDashWidget: Widget {
    let kind: String = "LLMDashWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BalanceTimelineProvider()) { entry in
            if #available(macOS 14.0, *) {
                WidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                WidgetView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("LLM Balance")
        .description("Monitor your LLM API credit balances")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: BalanceEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct LLMDashWidgetBundle: WidgetBundle {
    var body: some Widget {
        LLMDashWidget()
    }
}
