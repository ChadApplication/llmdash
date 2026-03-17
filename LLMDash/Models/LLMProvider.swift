import Foundation

enum ProviderType: String, Codable, CaseIterable, Identifiable {
    case openai = "OpenAI"
    case anthropic = "Anthropic"
    case google = "Google AI"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .openai: return "sparkles"
        case .anthropic: return "message.fill"
        case .google: return "globe"
        }
    }

    var requiresAdminKey: Bool {
        switch self {
        case .openai, .anthropic: return true
        case .google: return false
        }
    }

    var adminKeyHint: String {
        switch self {
        case .openai: return "Admin key from platform.openai.com/settings/organization/admin-keys"
        case .anthropic: return "Admin key (sk-ant-admin...) from console.anthropic.com/settings/admin-keys"
        case .google: return ""
        }
    }

    var balanceHint: String {
        switch self {
        case .openai: return "Credit balance from platform.openai.com → Billing → Pay as you go"
        case .anthropic: return "Remaining Balance from platform.claude.com/settings/billing"
        case .google: return "Balance from Google AI Studio billing page"
        }
    }
}

struct LLMProviderAccount: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: ProviderType
    var apiKey: String
    var isActive: Bool
    var manualBalance: Double?

    init(name: String, type: ProviderType, apiKey: String, manualBalance: Double? = nil) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.apiKey = apiKey
        self.isActive = true
        self.manualBalance = manualBalance
    }
}
