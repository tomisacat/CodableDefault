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
}
