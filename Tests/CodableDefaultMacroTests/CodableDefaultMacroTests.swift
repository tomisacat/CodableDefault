#if canImport(CodableDefaultMacros)
import CodableDefaultMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

private let testMacros: [String: Macro.Type] = [
    "CodableDefault": CodableDefaultMacro.self,
    "Default": DefaultMacro.self,
]

@Suite struct CodableDefaultMacroTests {
    @Test func expandsStructWithDefaultsAndRequiredProperties() {
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

    @Test func expandsCustomCodingKeyOnDefault() {
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

    @Test func expandsClassWithRequiredInit() {
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

    @Test func skipsCodingKeysWhenUserProvidesEnum() {
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

    @Test func defaultMacroProducesNoPeers() {
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

    @Test func expandsTransformOnDefault() {
        assertMacroExpansion(
            """
            @CodableDefault
            struct Config: Codable {
                @Default(10, transform: { min($0, 100) })
                var retryCount: Int
            }
            """,
            expandedSource: """
            struct Config: Codable {
                var retryCount: Int

                enum CodingKeys: String, CodingKey {
                    case retryCount
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)

                    self.retryCount = try {
                    let __codableDefault_retryCount = (try? container.decodeIfPresent(Int.self, forKey: .retryCount))
                    ?? 10
                    return try {
                        min($0, 100)
                    }(__codableDefault_retryCount)
                    }()
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test func expandsTransformWithCodingKey() {
        assertMacroExpansion(
            """
            @CodableDefault
            struct Config: Codable {
                @Default(0, codingKey: "limit", transform: { min($0, 100) })
                var limit: Int
            }
            """,
            expandedSource: """
            struct Config: Codable {
                var limit: Int

                enum CodingKeys: String, CodingKey {
                    case limit = "limit"
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)

                    self.limit = try {
                    let __codableDefault_limit = (try? container.decodeIfPresent(Int.self, forKey: .limit))
                    ?? 0
                    return try {
                        min($0, 100)
                    }(__codableDefault_limit)
                    }()
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test func expandsMultiLineTransform() {
        assertMacroExpansion(
            """
            @CodableDefault
            struct Config: Codable {
                @Default(10, transform: { value in
                    min(value, 100)
                })
                var retryCount: Int
            }
            """,
            expandedSource: """
            struct Config: Codable {
                var retryCount: Int

                enum CodingKeys: String, CodingKey {
                    case retryCount
                }

                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)

                    self.retryCount = try {
                    let __codableDefault_retryCount = (try? container.decodeIfPresent(Int.self, forKey: .retryCount))
                    ?? 10
                    return try { value in
                        min(value, 100)
                    }(__codableDefault_retryCount)
                    }()
                }
            }
            """,
            macros: testMacros
        )
    }
}
#else
import Testing

@Suite struct CodableDefaultMacroTests {
    @Test(.disabled("Macro tests run on the macOS host only."))
    func macrosRequireHostPlatform() {}
}
#endif
