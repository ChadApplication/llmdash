import Foundation

class UsageService {
    func fetchUsage(for account: LLMProviderAccount) async throws -> UsageData {
        switch account.type {
        case .openai:
            return try await fetchOpenAIUsage(account: account)
        case .anthropic:
            return try await fetchAnthropicUsage(account: account)
        case .google:
            return try await fetchGoogleUsage(account: account)
        }
    }

    // MARK: - OpenAI (Admin API)

    private func fetchOpenAIUsage(account: LLMProviderAccount) async throws -> UsageData {
        let now = Date()
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -30, to: now)!

        let startTimestamp = Int(startDate.timeIntervalSince1970)

        // Fetch costs via Admin API
        let costsURL = URL(string: "https://api.openai.com/v1/organization/costs?start_time=\(startTimestamp)&bucket_width=1d&limit=31")!
        var costsRequest = URLRequest(url: costsURL)
        costsRequest.setValue("Bearer \(account.apiKey)", forHTTPHeaderField: "Authorization")
        costsRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var totalCost: Double = 0
        var totalTokens: Int = 0

        if let (costsData, costsResp) = try? await URLSession.shared.data(for: costsRequest),
           (costsResp as? HTTPURLResponse)?.statusCode == 200 {
            let json = try? JSONSerialization.jsonObject(with: costsData) as? [String: Any]
            if let data = json?["data"] as? [[String: Any]] {
                for bucket in data {
                    if let results = bucket["results"] as? [[String: Any]] {
                        for result in results {
                            if let amount = result["amount"] as? [String: Any],
                               let value = amount["value"] as? Double {
                                totalCost += value
                            }
                        }
                    }
                }
            }
        }
        // No throw on 403 - balance from web scraping will be used instead

        // Fetch token usage via completions endpoint
        let usageURL = URL(string: "https://api.openai.com/v1/organization/usage/completions?start_time=\(startTimestamp)&bucket_width=1d&limit=31")!
        var usageRequest = URLRequest(url: usageURL)
        usageRequest.setValue("Bearer \(account.apiKey)", forHTTPHeaderField: "Authorization")
        usageRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let (usageData, usageResp) = try? await URLSession.shared.data(for: usageRequest),
           (usageResp as? HTTPURLResponse)?.statusCode == 200 {
            let json = try? JSONSerialization.jsonObject(with: usageData) as? [String: Any]
            if let data = json?["data"] as? [[String: Any]] {
                for bucket in data {
                    if let results = bucket["results"] as? [[String: Any]] {
                        for result in results {
                            let input = result["input_tokens"] as? Int ?? 0
                            let output = result["output_tokens"] as? Int ?? 0
                            totalTokens += input + output
                        }
                    }
                }
            }
        }

        // If API cost data available, calculate remaining; otherwise use web-scraped balance directly
        let remaining: Double?
        if totalCost > 0, let balance = account.manualBalance {
            remaining = balance - totalCost
        } else {
            remaining = account.manualBalance
        }

        return UsageData(
            providerAccountId: account.id,
            providerType: .openai,
            providerName: account.name,
            totalTokensUsed: totalTokens,
            totalCost: totalCost,
            remainingCredits: remaining,
            hardLimitUSD: account.manualBalance,
            currentPeriodStart: startDate,
            currentPeriodEnd: now,
            lastUpdated: now
        )
    }

    // MARK: - Anthropic (Admin API)

    private func fetchAnthropicUsage(account: LLMProviderAccount) async throws -> UsageData {
        let now = Date()
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -30, to: now)!

        let isoFormatter = ISO8601DateFormatter()
        let startStr = isoFormatter.string(from: startDate)
        let endStr = isoFormatter.string(from: now)

        var totalCost: Double = 0
        var totalTokens: Int = 0

        // Fetch cost report
        let costURL = URL(string: "https://api.anthropic.com/v1/organizations/cost_report?starting_at=\(startStr)&ending_at=\(endStr)&bucket_width=1d&limit=31")!
        var costRequest = URLRequest(url: costURL)
        costRequest.setValue(account.apiKey, forHTTPHeaderField: "x-api-key")
        costRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        if let (costData, costResp) = try? await URLSession.shared.data(for: costRequest),
           (costResp as? HTTPURLResponse)?.statusCode == 200 {
            let json = try? JSONSerialization.jsonObject(with: costData) as? [String: Any]
            if let data = json?["data"] as? [[String: Any]] {
                for bucket in data {
                    if let results = bucket["results"] as? [[String: Any]] {
                        for result in results {
                            if let cost = result["cost_usd"] as? Double {
                                totalCost += cost
                            }
                        }
                    }
                }
            }
        }

        // Fetch usage report for token counts
        let usageURL = URL(string: "https://api.anthropic.com/v1/organizations/usage_report/messages?starting_at=\(startStr)&ending_at=\(endStr)&bucket_width=1d&limit=31")!
        var usageRequest = URLRequest(url: usageURL)
        usageRequest.setValue(account.apiKey, forHTTPHeaderField: "x-api-key")
        usageRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        if let (usageData, usageResp) = try? await URLSession.shared.data(for: usageRequest),
           (usageResp as? HTTPURLResponse)?.statusCode == 200 {
            let json = try? JSONSerialization.jsonObject(with: usageData) as? [String: Any]
            if let data = json?["data"] as? [[String: Any]] {
                for bucket in data {
                    if let results = bucket["results"] as? [[String: Any]] {
                        for result in results {
                            let input = result["input_tokens"] as? Int ?? 0
                            let output = result["output_tokens"] as? Int ?? 0
                            totalTokens += input + output
                        }
                    }
                }
            }
        }

        let remaining: Double?
        if totalCost > 0, let balance = account.manualBalance {
            remaining = balance - totalCost
        } else {
            remaining = account.manualBalance
        }

        return UsageData(
            providerAccountId: account.id,
            providerType: .anthropic,
            providerName: account.name,
            totalTokensUsed: totalTokens,
            totalCost: totalCost,
            remainingCredits: remaining,
            hardLimitUSD: account.manualBalance,
            currentPeriodStart: startDate,
            currentPeriodEnd: now,
            lastUpdated: now
        )
    }

    // MARK: - Google AI

    private func fetchGoogleUsage(account: LLMProviderAccount) async throws -> UsageData {
        let now = Date()

        return UsageData(
            providerAccountId: account.id,
            providerType: .google,
            providerName: account.name,
            totalTokensUsed: 0,
            totalCost: 0,
            remainingCredits: account.manualBalance,
            hardLimitUSD: account.manualBalance,
            currentPeriodStart: nil,
            currentPeriodEnd: nil,
            lastUpdated: now
        )
    }

    // MARK: - Helpers

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UsageServiceError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw UsageServiceError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

enum UsageServiceError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}
