import CodableDefault
import Foundation

// MARK: - 1. Defaults only (missing keys)

@CodableDefault
struct FeatureFlags: Codable {
    @Default(false)
    var isEnabled: Bool

    @Default(0)
    var maxRetries: Int

    @Default("production")
    var environment: String
}

// MARK: - 2. Required + defaulted (mixed)

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

// MARK: - 3. Custom JSON keys via @Default(_:codingKey:)

@CodableDefault
struct UserPreferences: Codable {
    @Default(false, codingKey: "dark_mode")
    var darkMode: Bool

    @Default("en")
    var locale: String
}

// MARK: - 4. User-defined CodingKeys enum

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

// MARK: - 5. Class with defaults

@CodableDefault
final class Session: Codable {
    var sessionID: String

    @Default(3600)
    var ttlSeconds: Int

    @Default(false, codingKey: "is_guest")
    var isGuest: Bool
}

// MARK: - Demos

func printHeader(_ title: String) {
    print("\n=== \(title) ===")
}

func runDemo(
    _ title: String,
    json: String,
    decode: (Data) throws -> Void
) rethrows {
    printHeader(title)
    print("JSON:", json.split(separator: "\n").joined(separator: " "))
    try decode(Data(json.utf8))
}

// 1. Empty object → all defaults
try runDemo("Defaults only (empty JSON)", json: "{}") { data in
    let flags = try JSONDecoder().decode(FeatureFlags.self, from: data)
    print("→ isEnabled:", flags.isEnabled)
    print("→ maxRetries:", flags.maxRetries)
    print("→ environment:", flags.environment)
}

// 2. Partial JSON
try runDemo("Defaults only (partial JSON)", json: #"{"isEnabled":true}"#) { data in
    let flags = try JSONDecoder().decode(FeatureFlags.self, from: data)
    print("→ isEnabled:", flags.isEnabled, "(from JSON)")
    print("→ maxRetries:", flags.maxRetries, "(default)")
    print("→ environment:", flags.environment, "(default)")
}

// 3. null values → treated like missing for @Default fields
try runDemo("Null values use defaults", json: #"{"maxRetries":null,"environment":null}"#) { data in
    let flags = try JSONDecoder().decode(FeatureFlags.self, from: data)
    print("→ maxRetries:", flags.maxRetries)
    print("→ environment:", flags.environment)
}

// 4. Mixed required + defaulted + custom coding key
try runDemo(
    "Mixed properties",
    json: """
    {
        "apiVersion": "v2",
        "username": "bryan",
        "retry": 3
    }
    """
) { data in
    let config = try JSONDecoder().decode(AppConfig.self, from: data)
    print("→ apiVersion:", config.apiVersion)
    print("→ enabled:", config.enabled, "(default, key omitted)")
    print("→ retryCount:", config.retryCount, "(from \"retry\")")
    print("→ username:", config.username)
}

// 5. Missing required field → throws
printHeader("Missing required property (throws)")
let badJSON = #"{"enabled":true}"#.data(using: .utf8)!
do {
    _ = try JSONDecoder().decode(AppConfig.self, from: badJSON)
    print("→ unexpected success")
} catch {
    print("→ decode failed as expected:", type(of: error))
}

// 6. @Default(_:codingKey:)
try runDemo(
    "Custom keys on @Default",
    json: #"{"dark_mode":true}"#
) { data in
    let prefs = try JSONDecoder().decode(UserPreferences.self, from: data)
    print("→ darkMode:", prefs.darkMode)
    print("→ locale:", prefs.locale, "(default)")
}

// 7. User-defined CodingKeys
try runDemo(
    "User-defined CodingKeys enum",
    json: #"{"display_name":"Bryan","is_active":true}"#
) { data in
    let response = try JSONDecoder().decode(APIResponse.self, from: data)
    print("→ displayName:", response.displayName)
    print("→ isActive:", response.isActive)
    print("→ score:", response.score, "(default)")
}

// 8. Class
try runDemo(
    "Class with @CodableDefault",
    json: #"{"sessionID":"abc-123","is_guest":true}"#
) { data in
    let session = try JSONDecoder().decode(Session.self, from: data)
    print("→ sessionID:", session.sessionID)
    print("→ ttlSeconds:", session.ttlSeconds, "(default)")
    print("→ isGuest:", session.isGuest)
}

// 9. Encode → decode round-trip (types with @CodableDefault use macro-generated init(from:))
printHeader("Encode / decode round-trip")
let seedJSON = """
{
    "apiVersion": "v1",
    "enabled": false,
    "retry": 5,
    "username": "roundtrip"
}
""".data(using: .utf8)!
let original = try JSONDecoder().decode(AppConfig.self, from: seedJSON)
let encoded = try JSONEncoder().encode(original)
let jsonString = String(data: encoded, encoding: .utf8) ?? ""
print("Encoded:", jsonString)
let restored = try JSONDecoder().decode(AppConfig.self, from: encoded)
print("→ apiVersion:", restored.apiVersion)
print("→ enabled:", restored.enabled)
print("→ retryCount:", restored.retryCount)
print("→ username:", restored.username)

print("\nDone.")
