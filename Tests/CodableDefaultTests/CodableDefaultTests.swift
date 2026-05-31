import CodableDefault
import XCTest

final class CodableDefaultTests: XCTestCase {
    func testDecodesMissingPropertyWithDefault() throws {
        @CodableDefault
        struct Settings: Codable {
            @Default(false)
            var isEnabled: Bool
        }

        let json = "{}".data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        XCTAssertFalse(settings.isEnabled)
    }

    func testDecodesPresentProperty() throws {
        @CodableDefault
        struct Settings: Codable {
            @Default(false)
            var isEnabled: Bool
        }

        let json = #"{"isEnabled":true}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        XCTAssertTrue(settings.isEnabled)
    }

    func testDecodesMixedDefaultAndRequiredProperties() throws {
        @CodableDefault
        struct Settings: Codable {
            var name: String
            @Default(false)
            var isEnabled: Bool
        }

        let json = #"{"name":"App"}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        XCTAssertEqual(settings.name, "App")
        XCTAssertFalse(settings.isEnabled)
    }

    func testDecodesMixedPropertiesWhenAllKeysPresent() throws {
        @CodableDefault
        struct Settings: Codable {
            var name: String
            @Default(0)
            var count: Int
        }

        let json = #"{"name":"App","count":3}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        XCTAssertEqual(settings.name, "App")
        XCTAssertEqual(settings.count, 3)
    }

    func testMissingRequiredPropertyThrows() throws {
        @CodableDefault
        struct Settings: Codable {
            var name: String
            @Default(false)
            var isEnabled: Bool
        }

        let json = "{}".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(Settings.self, from: json))
    }

    func testDecodesPropertyWithCodingKeyOnDefault() throws {
        @CodableDefault
        struct Settings: Codable {
            @Default(false, codingKey: "is_enabled")
            var isEnabled: Bool
        }

        let json = #"{"is_enabled":true}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        XCTAssertTrue(settings.isEnabled)
    }

    func testDecodesWithUserDefinedCodingKeysEnum() throws {
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
        XCTAssertEqual(settings.name, "App")
        XCTAssertTrue(settings.isEnabled)
    }

    func testDecodesMixedCodingKeyAndDefault() throws {
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
        XCTAssertEqual(settings.name, "App")
        XCTAssertFalse(settings.isEnabled)
    }

    func testDefaultWithCodingKeyParameter() throws {
        @CodableDefault
        struct Settings: Codable {
            @Default(false, codingKey: "is_enabled")
            var isEnabled: Bool
        }

        let json = #"{"is_enabled":true}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        XCTAssertTrue(settings.isEnabled)
    }

    func testDefaultWithCodingKeyParameterUsesDefaultWhenMissing() throws {
        @CodableDefault
        struct Settings: Codable {
            @Default("guest", codingKey: "user_name")
            var username: String
        }

        let json = "{}".data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        XCTAssertEqual(settings.username, "guest")
    }

    func testDecodesNullValueWithDefault() throws {
        @CodableDefault
        struct Settings: Codable {
            @Default(false)
            var isEnabled: Bool

            @Default(0)
            var count: Int
        }

        let json = #"{"isEnabled":null,"count":null}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        XCTAssertFalse(settings.isEnabled)
        XCTAssertEqual(settings.count, 0)
    }

    func testDecodesClassWithDefaults() throws {
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
        XCTAssertEqual(session.sessionID, "abc-123")
        XCTAssertEqual(session.ttlSeconds, 3600)
        XCTAssertTrue(session.isGuest)
    }

    func testEncodeDecodeRoundTrip() throws {
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
        XCTAssertEqual(restored.apiVersion, "v1")
        XCTAssertFalse(restored.enabled)
        XCTAssertEqual(restored.retryCount, 5)
    }

    func testWrongTypeUsesDefault() throws {
        @CodableDefault
        struct Settings: Codable {
            @Default(false)
            var isEnabled: Bool
        }

        let json = #"{"isEnabled":"not-a-bool"}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(Settings.self, from: json)
        XCTAssertFalse(settings.isEnabled)
    }
}
