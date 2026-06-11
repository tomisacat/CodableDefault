import CodableDefault
import Foundation
import Testing

@Suite struct CodableDefaultTests {
    @Test func decodesMissingPropertyWithDefault() throws {
        @CodableDefault
        struct Settings: Codable {
            @Default(false)
            var isEnabled: Bool
        }

        let json = "{}".data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        #expect(settings.isEnabled == false)
    }

    @Test func decodesPresentProperty() throws {
        @CodableDefault
        struct Settings: Codable {
            @Default(false)
            var isEnabled: Bool
        }

        let json = #"{"isEnabled":true}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        #expect(settings.isEnabled)
    }

    @Test func decodesMixedDefaultAndRequiredProperties() throws {
        @CodableDefault
        struct Settings: Codable {
            var name: String
            @Default(false)
            var isEnabled: Bool
        }

        let json = #"{"name":"App"}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        #expect(settings.name == "App")
        #expect(settings.isEnabled == false)
    }

    @Test func decodesMixedPropertiesWhenAllKeysPresent() throws {
        @CodableDefault
        struct Settings: Codable {
            var name: String
            @Default(0)
            var count: Int
        }

        let json = #"{"name":"App","count":3}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        #expect(settings.name == "App")
        #expect(settings.count == 3)
    }

    @Test func missingRequiredPropertyThrows() throws {
        @CodableDefault
        struct Settings: Codable {
            var name: String
            @Default(false)
            var isEnabled: Bool
        }

        let json = "{}".data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Settings.self, from: json)
        }
    }

    @Test func decodesPropertyWithCodingKeyOnDefault() throws {
        @CodableDefault
        struct Settings: Codable {
            @Default(false, codingKey: "is_enabled")
            var isEnabled: Bool
        }

        let json = #"{"is_enabled":true}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        #expect(settings.isEnabled)
    }

    @Test func decodesWithUserDefinedCodingKeysEnum() throws {
        @CodableDefault
        struct Settings: Codable {
            enum CodingKeys: String, CodingKey {
                case name = "display_name"
                case isEnabled = "is_enabled"
            }

            var name: String
            @Default(false)
            var isEnabled: Bool
        }

        let json = #"{"display_name":"App","is_enabled":true}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        #expect(settings.name == "App")
        #expect(settings.isEnabled)
    }

    @Test func decodesMixedCodingKeyAndDefault() throws {
        @CodableDefault
        struct Settings: Codable {
            enum CodingKeys: String, CodingKey {
                case name = "display_name"
                case isEnabled = "is_enabled"
            }

            var name: String

            @Default(false)
            var isEnabled: Bool
        }

        let json = #"{"display_name":"App"}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        #expect(settings.name == "App")
        #expect(settings.isEnabled == false)
    }

    @Test func defaultWithCodingKeyParameter() throws {
        @CodableDefault
        struct Settings: Codable {
            @Default(false, codingKey: "is_enabled")
            var isEnabled: Bool
        }

        let json = #"{"is_enabled":true}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        #expect(settings.isEnabled)
    }

    @Test func defaultWithCodingKeyParameterUsesDefaultWhenMissing() throws {
        @CodableDefault
        struct Settings: Codable {
            @Default("guest", codingKey: "user_name")
            var username: String
        }

        let json = "{}".data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        #expect(settings.username == "guest")
    }

    @Test func decodesNullValueWithDefault() throws {
        @CodableDefault
        struct Settings: Codable {
            @Default(false)
            var isEnabled: Bool

            @Default(0)
            var count: Int
        }

        let json = #"{"isEnabled":null,"count":null}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        #expect(settings.isEnabled == false)
        #expect(settings.count == 0)
    }

    @Test func decodesClassWithDefaults() throws {
        @CodableDefault
        final class Session: Codable {
            var sessionID: String

            @Default(3600)
            var ttlSeconds: Int

            @Default(false, codingKey: "is_guest")
            var isGuest: Bool
        }

        let json = #"{"sessionID":"abc-123","is_guest":true}"#.data(using: .utf8)!
        let session = try JSONDecoder().decode(Session.self, from: json)
        #expect(session.sessionID == "abc-123")
        #expect(session.ttlSeconds == 3600)
        #expect(session.isGuest)
    }

    @Test func encodeDecodeRoundTrip() throws {
        @CodableDefault
        struct Config: Codable {
            var apiVersion: String

            @Default(true)
            var enabled: Bool

            @Default(10, codingKey: "retry")
            var retryCount: Int
        }

        let seedJSON = """
        {
            "apiVersion": "v1",
            "enabled": false,
            "retry": 5
        }
        """.data(using: .utf8)!
        let original = try JSONDecoder().decode(Config.self, from: seedJSON)
        let encoded = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(Config.self, from: encoded)
        #expect(restored.apiVersion == "v1")
        #expect(restored.enabled == false)
        #expect(restored.retryCount == 5)
    }

    @Test func wrongTypeUsesDefault() throws {
        @CodableDefault
        struct Settings: Codable {
            @Default(false)
            var isEnabled: Bool
        }

        let json = #"{"isEnabled":"not-a-bool"}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        #expect(settings.isEnabled == false)
    }

    @Test func transformAppliedToDecodedValue() throws {
        @CodableDefault
        struct Config: Codable {
            @Default(10, transform: { min($0, 100) })
            var retryCount: Int
        }

        let json = #"{"retryCount":150}"#.data(using: .utf8)!
        let config = try JSONDecoder().decode(Config.self, from: json)
        #expect(config.retryCount == 100)
    }

    @Test func transformAppliedToDefaultValue() throws {
        @CodableDefault
        struct Config: Codable {
            @Default(10, transform: { min($0, 100) })
            var retryCount: Int
        }

        let json = "{}".data(using: .utf8)!
        let config = try JSONDecoder().decode(Config.self, from: json)
        #expect(config.retryCount == 10)
    }

    @Test func transformWithCodingKey() throws {
        @CodableDefault
        struct Config: Codable {
            @Default(0, codingKey: "limit", transform: { min($0, 100) })
            var limit: Int
        }

        let json = #"{"limit":200}"#.data(using: .utf8)!
        let config = try JSONDecoder().decode(Config.self, from: json)
        #expect(config.limit == 100)
    }

    @Test func throwingTransformPropagatesError() throws {
        @CodableDefault
        struct Config: Codable {
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

        let validJSON = #"{"count":5}"#.data(using: .utf8)!
        let valid = try JSONDecoder().decode(Config.self, from: validJSON)
        #expect(valid.count == 5)

        let invalidJSON = #"{"count":-1}"#.data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Config.self, from: invalidJSON)
        }
    }

    @Test func transformAppliedWhenValueIsNull() throws {
        @CodableDefault
        struct Config: Codable {
            @Default(10, transform: { $0 + 1 })
            var retryCount: Int
        }

        let json = #"{"retryCount":null}"#.data(using: .utf8)!
        let config = try JSONDecoder().decode(Config.self, from: json)
        #expect(config.retryCount == 11)
    }

    @Test func transformAppliedWhenWrongTypeUsesDefault() throws {
        @CodableDefault
        struct Config: Codable {
            @Default(10, transform: { $0 + 5 })
            var retryCount: Int
        }

        let json = #"{"retryCount":"not-a-number"}"#.data(using: .utf8)!
        let config = try JSONDecoder().decode(Config.self, from: json)
        #expect(config.retryCount == 15)
    }

    @Test func throwingTransformOnDefaultPathPropagatesError() throws {
        @CodableDefault
        struct Config: Codable {
            @Default(0, transform: { value in
                guard value != 0 else {
                    throw DecodingError.dataCorrupted(
                        .init(codingPath: [], debugDescription: "zero not allowed")
                    )
                }
                return value
            })
            var count: Int
        }

        let json = "{}".data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Config.self, from: json)
        }
    }

    @Test func stringTransformTrimsWhitespace() throws {
        @CodableDefault
        struct Config: Codable {
            @Default("guest", transform: { $0.trimmingCharacters(in: .whitespaces) })
            var username: String
        }

        let json = #"{"username":"  bryan  "}"#.data(using: .utf8)!
        let config = try JSONDecoder().decode(Config.self, from: json)
        #expect(config.username == "bryan")
    }

    @Test func transformOnClassProperty() throws {
        @CodableDefault
        final class Session: Codable {
            var sessionID: String

            @Default(3600, transform: { min($0, 7200) })
            var ttlSeconds: Int
        }

        let json = #"{"sessionID":"abc","ttlSeconds":9000}"#.data(using: .utf8)!
        let session = try JSONDecoder().decode(Session.self, from: json)
        #expect(session.sessionID == "abc")
        #expect(session.ttlSeconds == 7200)
    }

    @Test func transformWithUserDefinedCodingKeys() throws {
        @CodableDefault
        struct Settings: Codable {
            enum CodingKeys: String, CodingKey {
                case name = "display_name"
                case limit = "max_limit"
            }

            var name: String

            @Default(10, transform: { min($0, 100) })
            var limit: Int
        }

        let json = #"{"display_name":"App","max_limit":150}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        #expect(settings.name == "App")
        #expect(settings.limit == 100)
    }
}
