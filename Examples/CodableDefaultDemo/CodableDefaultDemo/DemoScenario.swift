import Foundation

enum DemoScenarioID: String, CaseIterable, Identifiable, Hashable {
    case defaultsEmpty
    case defaultsPartial
    case defaultsNull
    case mixedRequired
    case missingRequired
    case customCodingKey
    case userCodingKeys
    case classDefaults
    case transformClamp
    case transformDefaultPath
    case transformTrim
    case transformThrows
    case wrongTypeDefault
    case encodeRoundTrip

    var id: String { rawValue }
}

struct DemoScenario: Identifiable, Hashable {
    enum Category: String, CaseIterable, Identifiable {
        case basics = "Basics"
        case keys = "Coding Keys"
        case advanced = "Advanced"

        var id: String { rawValue }
    }

    let id: DemoScenarioID
    let category: Category
    let title: String
    let summary: String
    let json: String
    let highlights: [String]

    static let all: [DemoScenario] = DemoScenarioID.allCases.map(\.scenario)

    static func grouped() -> [(category: Category, scenarios: [DemoScenario])] {
        Category.allCases.map { category in
            (category, all.filter { $0.category == category })
        }
    }
}

private extension DemoScenarioID {
    var scenario: DemoScenario {
        switch self {
        case .defaultsEmpty:
            DemoScenario(
                id: self,
                category: .basics,
                title: "All defaults (empty JSON)",
                summary: "@Default fills in missing keys when the payload is `{}`.",
                json: "{}",
                highlights: [
                    "@Default(false), @Default(0), @Default(\"production\")",
                    "No manual init(from:) required",
                ]
            )
        case .defaultsPartial:
            DemoScenario(
                id: self,
                category: .basics,
                title: "Partial JSON",
                summary: "Present keys decode normally; omitted keys keep their defaults.",
                json: #"{"isEnabled":true}"#,
                highlights: [
                    "isEnabled comes from JSON",
                    "maxRetries and environment use defaults",
                ]
            )
        case .defaultsNull:
            DemoScenario(
                id: self,
                category: .basics,
                title: "Null uses default",
                summary: "`null` is treated like a missing key for @Default properties.",
                json: #"{"maxRetries":null,"environment":null}"#,
                highlights: [
                    "decodeIfPresent + fallback",
                    "Useful for loosely typed APIs",
                ]
            )
        case .mixedRequired:
            DemoScenario(
                id: self,
                category: .basics,
                title: "Required + defaulted",
                summary: "Properties without @Default stay strict; missing keys throw.",
                json: """
                {
                    "apiVersion": "v2",
                    "username": "bryan",
                    "retry": 3
                }
                """,
                highlights: [
                    "apiVersion is required",
                    "enabled defaults to true",
                    "retryCount maps from \"retry\"",
                ]
            )
        case .missingRequired:
            DemoScenario(
                id: self,
                category: .basics,
                title: "Missing required throws",
                summary: "Without @Default, a missing non-optional property fails decoding.",
                json: #"{"enabled":true}"#,
                highlights: [
                    "apiVersion is required",
                    "Demonstrates strict vs tolerant fields",
                ]
            )
        case .customCodingKey:
            DemoScenario(
                id: self,
                category: .keys,
                title: "@Default(_:codingKey:)",
                summary: "Map snake_case wire keys without writing a full CodingKeys enum.",
                json: #"{"dark_mode":true}"#,
                highlights: [
                    "darkMode reads \"dark_mode\"",
                    "locale falls back to \"en\"",
                ]
            )
        case .userCodingKeys:
            DemoScenario(
                id: self,
                category: .keys,
                title: "User-defined CodingKeys",
                summary: "Provide your own enum; the macro only emits init(from:).",
                json: #"{"display_name":"Bryan","is_active":true}"#,
                highlights: [
                    "Required fields use enum raw values",
                    "score still defaults to 0",
                ]
            )
        case .classDefaults:
            DemoScenario(
                id: self,
                category: .advanced,
                title: "Class with defaults",
                summary: "@CodableDefault works on classes and emits a required init(from:).",
                json: #"{"sessionID":"abc-123","is_guest":true}"#,
                highlights: [
                    "ttlSeconds defaults to 3600",
                    "isGuest maps from \"is_guest\"",
                ]
            )
        case .transformClamp:
            DemoScenario(
                id: self,
                category: .advanced,
                title: "Transform clamps value",
                summary: "Post-decode transform runs on JSON values and on defaults.",
                json: #"{"retryCount":150}"#,
                highlights: [
                    "@Default(10, transform: { min($0, 100) })",
                    "150 is clamped to 100",
                ]
            )
        case .transformDefaultPath:
            DemoScenario(
                id: self,
                category: .advanced,
                title: "Transform on default path",
                summary: "When the key is missing, the default is resolved first, then transformed.",
                json: "{}",
                highlights: [
                    "Default 10 is still passed through min(_, 100)",
                ]
            )
        case .transformTrim:
            DemoScenario(
                id: self,
                category: .advanced,
                title: "String transform",
                summary: "Normalize strings after decode or after applying a default.",
                json: #"{"username":"  bryan  "}"#,
                highlights: [
                    "trimmingCharacters(in: .whitespaces)",
                ]
            )
        case .transformThrows:
            DemoScenario(
                id: self,
                category: .advanced,
                title: "Throwing transform",
                summary: "Validation in transform propagates as a decoding error.",
                json: #"{"count":-1}"#,
                highlights: [
                    "guard + throw inside transform",
                    "Use for business-rule validation",
                ]
            )
        case .wrongTypeDefault:
            DemoScenario(
                id: self,
                category: .advanced,
                title: "Wrong type uses default",
                summary: "When @Default is present, type mismatches fall back to the default.",
                json: #"{"retryCount":"not-a-number"}"#,
                highlights: [
                    "Strict type checking is not applied to @Default fields",
                ]
            )
        case .encodeRoundTrip:
            DemoScenario(
                id: self,
                category: .advanced,
                title: "Encode / decode round-trip",
                summary: "Macro customizes decoding only; encoding can still be synthesized.",
                json: """
                {
                    "apiVersion": "v1",
                    "enabled": false,
                    "retry": 5,
                    "username": "roundtrip"
                }
                """,
                highlights: [
                    "JSONEncoder uses generated CodingKeys",
                    "Re-decode verifies stable round-trip",
                ]
            )
        }
    }
}

enum DemoRunner {
    static func run(_ scenario: DemoScenario) -> DemoOutcome {
        guard let data = scenario.json.data(using: .utf8) else {
            return .failure("Invalid UTF-8 in sample JSON.")
        }

        do {
            return try .success(execute(scenario.id, data: data))
        } catch {
            return .failure(String(describing: error))
        }
    }

    private static func execute(_ id: DemoScenarioID, data: Data) throws -> String {
        switch id {
        case .defaultsEmpty:
            let flags = try JSONDecoder().decode(FeatureFlags.self, from: data)
            return """
            isEnabled: \(flags.isEnabled)
            maxRetries: \(flags.maxRetries)
            environment: \(flags.environment)
            """

        case .defaultsPartial:
            let flags = try JSONDecoder().decode(FeatureFlags.self, from: data)
            return """
            isEnabled: \(flags.isEnabled) (from JSON)
            maxRetries: \(flags.maxRetries) (default)
            environment: \(flags.environment) (default)
            """

        case .defaultsNull:
            let flags = try JSONDecoder().decode(FeatureFlags.self, from: data)
            return """
            maxRetries: \(flags.maxRetries)
            environment: \(flags.environment)
            """

        case .mixedRequired:
            let config = try JSONDecoder().decode(AppConfig.self, from: data)
            return """
            apiVersion: \(config.apiVersion)
            enabled: \(config.enabled) (default)
            retryCount: \(config.retryCount) (from "retry")
            username: \(config.username)
            """

        case .missingRequired:
            _ = try JSONDecoder().decode(AppConfig.self, from: data)
            return "Unexpected success"

        case .customCodingKey:
            let prefs = try JSONDecoder().decode(UserPreferences.self, from: data)
            return """
            darkMode: \(prefs.darkMode)
            locale: \(prefs.locale) (default)
            """

        case .userCodingKeys:
            let response = try JSONDecoder().decode(APIResponse.self, from: data)
            return """
            displayName: \(response.displayName)
            isActive: \(response.isActive)
            score: \(response.score) (default)
            """

        case .classDefaults:
            let session = try JSONDecoder().decode(Session.self, from: data)
            return """
            sessionID: \(session.sessionID)
            ttlSeconds: \(session.ttlSeconds) (default)
            isGuest: \(session.isGuest)
            """

        case .transformClamp:
            let config = try JSONDecoder().decode(RateLimitedConfig.self, from: data)
            return "retryCount: \(config.retryCount) (clamped from 150)"

        case .transformDefaultPath:
            let config = try JSONDecoder().decode(RateLimitedConfig.self, from: data)
            return "retryCount: \(config.retryCount)"

        case .transformTrim:
            let model = try JSONDecoder().decode(TrimmedUsername.self, from: data)
            return "username: \"\(model.username)\""

        case .transformThrows:
            _ = try JSONDecoder().decode(ValidatedCount.self, from: data)
            return "Unexpected success"

        case .wrongTypeDefault:
            let config = try JSONDecoder().decode(RateLimitedConfig.self, from: data)
            return "retryCount: \(config.retryCount) (default 10)"

        case .encodeRoundTrip:
            let original = try JSONDecoder().decode(AppConfig.self, from: data)
            let encoded = try JSONEncoder().encode(original)
            let encodedJSON = String(data: encoded, encoding: .utf8) ?? ""
            let restored = try JSONDecoder().decode(AppConfig.self, from: encoded)
            return """
            Encoded JSON:
            \(encodedJSON)

            Restored:
            apiVersion: \(restored.apiVersion)
            enabled: \(restored.enabled)
            retryCount: \(restored.retryCount)
            username: \(restored.username)
            """
        }
    }
}

enum DemoOutcome: Equatable {
    case success(String)
    case failure(String)
}
