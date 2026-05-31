#if canImport(CodableDefaultMacros)
import CodableDefaultMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

private let testMacros: [String: Macro.Type] = [
    "CodableDefault": CodableDefaultMacro.self,
    "Default": DefaultMacro.self,
]

final class CodableDefaultMacroTests: XCTestCase {
    func testExpandsStructWithDefaultsAndRequiredProperties() throws {
        assertMacroExpansion(
            """
            @CodableDefault
            struct Settings: Codable {
                var name: String

                @Default(false)
                var isEnabled: Bool
            }
            """,
            expandedSource: """
            struct Settings: Codable {
                var name: String
                var isEnabled: Bool

                enum CodingKeys: String, CodingKey {
                    case name
                    case isEnabled
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)

                    self.name = try container.decode(String.self, forKey: .name)

                    self.isEnabled =
                    (try? container.decodeIfPresent(Bool.self, forKey: .isEnabled))
                    ?? false
                }
            }
            """,
            macros: testMacros
        )
    }

    func testExpandsCustomCodingKeyOnDefault() throws {
        assertMacroExpansion(
            """
            @CodableDefault
            struct Settings: Codable {
                @Default("guest", codingKey: "user_name")
                var username: String
            }
            """,
            expandedSource: """
            struct Settings: Codable {
                var username: String

                enum CodingKeys: String, CodingKey {
                    case username = "user_name"
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)

                    self.username =
                    (try? container.decodeIfPresent(String.self, forKey: .username))
                    ?? "guest"
                }
            }
            """,
            macros: testMacros
        )
    }

    func testExpandsClassWithRequiredInit() throws {
        assertMacroExpansion(
            """
            @CodableDefault
            final class Session: Codable {
                var sessionID: String

                @Default(3600)
                var ttlSeconds: Int
            }
            """,
            expandedSource: """
            final class Session: Codable {
                var sessionID: String
                var ttlSeconds: Int

                enum CodingKeys: String, CodingKey {
                    case sessionID
                    case ttlSeconds
                }

                required init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)

                    self.sessionID = try container.decode(String.self, forKey: .sessionID)

                    self.ttlSeconds =
                    (try? container.decodeIfPresent(Int.self, forKey: .ttlSeconds))
                    ?? 3600
                }
            }
            """,
            macros: testMacros
        )
    }

    func testSkipsCodingKeysWhenUserProvidesEnum() throws {
        assertMacroExpansion(
            """
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
            """,
            expandedSource: """
            struct Settings: Codable {
                enum CodingKeys: String, CodingKey {
                    case name = "display_name"
                    case isEnabled = "is_enabled"
                }

                var name: String
                var isEnabled: Bool

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)

                    self.name = try container.decode(String.self, forKey: .name)

                    self.isEnabled =
                    (try? container.decodeIfPresent(Bool.self, forKey: .isEnabled))
                    ?? false
                }
            }
            """,
            macros: testMacros
        )
    }

    func testDefaultMacroProducesNoPeers() throws {
        assertMacroExpansion(
            """
            @Default(false)
            var isEnabled: Bool
            """,
            expandedSource: """
            var isEnabled: Bool
            """,
            macros: testMacros
        )
    }
}
#else
import XCTest

final class CodableDefaultMacroTests: XCTestCase {
    func testMacrosRequireHostPlatform() throws {
        throw XCTSkip("Macro tests run on the macOS host only.")
    }
}
#endif
