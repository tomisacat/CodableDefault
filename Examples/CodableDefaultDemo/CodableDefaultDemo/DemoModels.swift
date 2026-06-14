import CodableDefault
import Foundation

// MARK: - Defaults only

@CodableDefault
struct FeatureFlags: Codable {
    @Default(false)
    var isEnabled: Bool

    @Default(0)
    var maxRetries: Int

    @Default("production")
    var environment: String
}

// MARK: - Required + defaulted

@CodableDefault
struct AppConfig: Codable {
    var apiVersion: String

    @Default(true)
    var enabled: Bool

    @Default(10, codingKey: "retry")
    var retryCount: Int

    @Default("guest")
    var username: String
}

// MARK: - Custom JSON keys

@CodableDefault
struct UserPreferences: Codable {
    @Default(false, codingKey: "dark_mode")
    var darkMode: Bool

    @Default("en")
    var locale: String
}

// MARK: - User-defined CodingKeys

@CodableDefault
struct APIResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case isActive = "is_active"
        case score
    }

    var displayName: String
    var isActive: Bool

    @Default(0)
    var score: Int
}

// MARK: - Class

@CodableDefault
final class Session: Codable {
    var sessionID: String

    @Default(3600)
    var ttlSeconds: Int

    @Default(false, codingKey: "is_guest")
    var isGuest: Bool
}

// MARK: - Transform

@CodableDefault
struct RateLimitedConfig: Codable {
    @Default(10, transform: { min($0, 100) })
    var retryCount: Int
}

@CodableDefault
struct TrimmedUsername: Codable {
    @Default("guest", transform: { $0.trimmingCharacters(in: .whitespaces) })
    var username: String
}

@CodableDefault
struct ValidatedCount: Codable {
    @Default(0, transform: { value in
        guard value >= 0 else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "negative value")
            )
        }
        return value
    })
    var count: Int
}
