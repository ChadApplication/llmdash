import Foundation

struct SharedProviderBalance: Codable {
    let providerName: String
    let providerType: String
    let balance: Double?
    let cost: Double
    let tokens: Int
    let lastUpdated: Date
}

struct SharedBalanceData: Codable {
    let providers: [SharedProviderBalance]
    let totalCost: Double
    let lastUpdated: Date

    static let appGroupID = "group.com.llmdash"
    static let fileName = "llmdash-balance.json"

    static var sharedFileURL: URL {
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return groupURL.appendingPathComponent(fileName)
        }
        // Fallback
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("LLMDash", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(fileName)
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self) else { return }
        try? data.write(to: Self.sharedFileURL)
    }

    static func load() -> SharedBalanceData? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: sharedFileURL) else { return nil }
        return try? decoder.decode(SharedBalanceData.self, from: data)
    }
}
