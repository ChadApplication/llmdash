import Foundation
import Security

class AccountStore {
    private let accountsKey = "com.llmdash.accounts"
    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("LLMDash", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.fileURL = appDir.appendingPathComponent("accounts.json")
    }

    func saveAccounts(_ accounts: [LLMProviderAccount]) {
        // Save account metadata (without API keys) to file
        let metadata = accounts.map { AccountMetadata(id: $0.id, name: $0.name, type: $0.type, isActive: $0.isActive) }
        if let data = try? JSONEncoder().encode(metadata) {
            try? data.write(to: fileURL)
        }

        // Save API keys to Keychain
        for account in accounts {
            saveToKeychain(key: account.id.uuidString, value: account.apiKey)
        }
    }

    func loadAccounts() -> [LLMProviderAccount] {
        guard let data = try? Data(contentsOf: fileURL),
              let metadata = try? JSONDecoder().decode([AccountMetadata].self, from: data) else {
            return []
        }

        return metadata.compactMap { meta in
            guard let apiKey = loadFromKeychain(key: meta.id.uuidString) else { return nil }
            var account = LLMProviderAccount(name: meta.name, type: meta.type, apiKey: apiKey)
            account.isActive = meta.isActive
            return account
        }
    }

    // MARK: - Keychain

    private func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.llmdash",
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.llmdash",
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.llmdash",
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

private struct AccountMetadata: Codable {
    let id: UUID
    let name: String
    let type: ProviderType
    let isActive: Bool
}
