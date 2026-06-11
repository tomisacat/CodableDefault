/// Macro implementations for [CodableDefault](https://github.com/tomisacat/CodableDefault).
///
/// This module is loaded by the Swift compiler as a plugin. It expands `@CodableDefault` and `@Default`
/// into `CodingKeys` and `init(from:)` members that decode JSON with optional fallbacks for missing or `null` values.
import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - Compiler plugin

/// Entry point for the Swift compiler plugin that registers all CodableDefault macros.
///
/// The compiler discovers this type via `@main` and calls into it when expanding
/// `@CodableDefault` or `@Default` in client source files.
@main
struct CodableDefaultPlugin: CompilerPlugin {
    /// Macro types exposed to client modules through `CodableDefault`.
    let providingMacros: [Macro.Type] = [
        CodableDefaultMacro.self,
        DefaultMacro.self,
    ]
}

// MARK: - DefaultMacro

/// Implementation of the `@Default` peer macro.
///
/// `@Default` does not generate peer declarations. It exists so the attribute is a valid,
/// recognized macro at compile time; `CodableDefaultMacro` reads `@Default` attributes from
/// each property when generating `init(from:)`.
///
/// Supported forms in client code:
/// - `@Default(false)` — default value only; JSON key matches the property name.
/// - `@Default("guest", codingKey: "user_name")` — default value plus a custom JSON key.
/// - `@Default(10, transform: { min($0, 100) })` — default value plus a post-decode transform.
/// - `@Default(0, codingKey: "limit", transform: { min($0, 100) })` — custom key and transform.
public struct DefaultMacro: PeerMacro {

    /// Produces no peer declarations; decoding logic is emitted by `CodableDefaultMacro`.
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}

// MARK: - CodableDefaultMacro

/// Implementation of the `@CodableDefault` member macro.
///
/// Attached to a `struct` or `class`, this macro inspects stored instance properties and emits:
///
/// 1. `enum CodingKeys: String, CodingKey` — unless the type already defines `CodingKeys`.
/// 2. `init(from decoder: Decoder) throws` — `required` when the type is a class.
///
/// Properties annotated with `@Default` decode with `decodeIfPresent` and fall back to the
/// given expression when the key is absent or `null`. Properties without `@Default` use
/// strict `decode(_:forKey:)` and throw if the key is missing or not decodable.
public struct CodableDefaultMacro: MemberMacro {

    /// Collected metadata for one stored property used to generate `CodingKeys` and decode statements.
    private struct PropertySpec {
        /// Swift property name (e.g. `isEnabled`).
        let name: String
        /// Type spelling from the property’s type annotation (e.g. `Bool`, `[String]`).
        let typeName: String
        /// Source text of the `@Default` value expression, if present (e.g. `false`, `"guest"`).
        let defaultExpression: String?
        /// Wire-format key string for `CodingKeys` raw values, if different from the case name.
        let jsonKey: String?
        /// `CodingKeys` case used in `forKey:` (usually the property name).
        let codingKeyCaseName: String
        /// Source text of the `@Default` transform closure, if present.
        let transformExpression: String?
    }

    /// A case parsed from a user-defined `CodingKeys` enum.
    private struct CodingKeyCase {
        /// Enum case identifier (must match the property name).
        let caseName: String
        /// String raw value from `case name = "json_key"`, if any.
        let jsonKey: String?
    }

    /// Expands `@CodableDefault` into `CodingKeys` and/or `init(from:)`.
    ///
    /// - Parameters:
    ///   - node: The `@CodableDefault` attribute syntax.
    ///   - declaration: The attached struct or class.
    ///   - protocols: Conformance list from the macro invocation (unused).
    ///   - context: Expansion context for diagnostics.
    /// - Returns: Generated member declarations, or an empty array for unsupported types.
    /// - Throws: `MacroExpansionError` when a property lacks a matching case in a user `CodingKeys` enum.
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else {
            return []
        }

        let userCodingKeys = existingCodingKeysEnum(in: declaration)
        var properties: [PropertySpec] = []

        for member in declaration.memberBlock.members {
            guard
                let varDecl = member.decl.as(VariableDeclSyntax.self),
                !varDecl.modifiers.contains(where: { $0.name.text == "static" }),
                let binding = varDecl.bindings.first,
                let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self),
                let typeAnnotation = binding.typeAnnotation
            else {
                continue
            }

            let propertyName = identifierPattern.identifier.text
            let typeName = typeAnnotation.type.description
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let defaultAttribute = parseDefaultAttribute(from: varDecl.attributes)
            let defaultExpression = defaultAttribute?.defaultExpression
            let attributeJSONKey = defaultAttribute?.codingKey
            let transformExpression = defaultAttribute?.transformExpression

            let codingKeyCaseName: String
            let jsonKey: String?

            if let userCodingKeys {
                guard let userCase = codingKeyCase(named: propertyName, in: userCodingKeys) else {
                    throw MacroExpansionError(
                        message: """
                        Property '\(propertyName)' has no matching case in CodingKeys. \
                        Add `case \(propertyName)` or `case \(propertyName) = \"…\"` to your CodingKeys enum.
                        """
                    )
                }
                codingKeyCaseName = userCase.caseName
                jsonKey = attributeJSONKey ?? userCase.jsonKey
            } else {
                codingKeyCaseName = propertyName
                jsonKey = attributeJSONKey
            }

            properties.append(
                PropertySpec(
                    name: propertyName,
                    typeName: typeName,
                    defaultExpression: defaultExpression,
                    jsonKey: jsonKey,
                    codingKeyCaseName: codingKeyCaseName,
                    transformExpression: transformExpression
                )
            )
        }

        guard !properties.isEmpty else {
            return []
        }

        var members: [DeclSyntax] = []

        if userCodingKeys == nil {
            let codingKeysDecl = """
            enum CodingKeys: String, CodingKey {
            \(properties.map(codingKeyCaseDeclaration).joined(separator: "\n"))
            }
            """
            members.append(DeclSyntax(stringLiteral: codingKeysDecl))
        }

        let decodeLines = properties.map(decodeStatement)
        let initializerKeyword = declaration.is(ClassDeclSyntax.self) ? "required init" : "init"
        let initDecl = """
        \(initializerKeyword)(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

        \(decodeLines.map { "    \($0)" }.joined(separator: "\n\n"))
        }
        """
        members.append(DeclSyntax(stringLiteral: initDecl))

        return members
    }

    /// Renders one line of a generated `CodingKeys` enum.
    ///
    /// - Parameter property: Parsed property metadata.
    /// - Returns: `case name` or `case name = "json_key"` when `jsonKey` is set.
    private static func codingKeyCaseDeclaration(for property: PropertySpec) -> String {
        if let jsonKey = property.jsonKey {
            return "    case \(property.codingKeyCaseName) = \"\(escapedJSONKey(jsonKey))\""
        }
        return "    case \(property.codingKeyCaseName)"
    }

    /// Renders one assignment inside generated `init(from:)`.
    ///
    /// Defaulted properties use `decodeIfPresent` with a fallback; required properties use `decode`.
    ///
    /// - Parameter property: Parsed property metadata.
    /// - Returns: A `self.propertyName = …` source fragment.
    private static func decodeStatement(for property: PropertySpec) -> String {
        let key = property.codingKeyCaseName
        if let defaultExpression = property.defaultExpression {
            let resolvedValue = """
            (try? container.decodeIfPresent(\(property.typeName).self, forKey: .\(key)))
                ?? \(defaultExpression)
            """
            if let transformExpression = property.transformExpression {
                let tempName = "__codableDefault_\(property.name)"
                return """
                self.\(property.name) = try {
                    let \(tempName) = \(resolvedValue)
                    return try \(transformExpression)(\(tempName))
                }()
                """
            }
            return """
            self.\(property.name) =
                \(resolvedValue)
            """
        }
        return """
        self.\(property.name) = try container.decode(\(property.typeName).self, forKey: .\(key))
        """
    }

    /// Escapes backslashes and quotes for safe embedding in a generated string literal.
    private static func escapedJSONKey(_ key: String) -> String {
        key
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    /// Returns a `CodingKeys` enum declared on the type, if the author provided one.
    ///
    /// When present, the macro does not emit `CodingKeys` and instead validates that every
    /// stored property has a matching enum case.
    private static func existingCodingKeysEnum(in declaration: some DeclGroupSyntax) -> EnumDeclSyntax? {
        for member in declaration.memberBlock.members {
            if let enumDecl = member.decl.as(EnumDeclSyntax.self),
               enumDecl.name.text == "CodingKeys"
            {
                return enumDecl
            }
        }
        return nil
    }

    /// Looks up a `CodingKeys` case whose name matches the given property.
    ///
    /// - Parameters:
    ///   - propertyName: Swift property identifier.
    ///   - enumDecl: User-defined `CodingKeys` enum on the type.
    /// - Returns: Case metadata, or `nil` if no case matches.
    private static func codingKeyCase(named propertyName: String, in enumDecl: EnumDeclSyntax) -> CodingKeyCase? {
        for member in enumDecl.memberBlock.members {
            guard let enumCase = member.decl.as(EnumCaseDeclSyntax.self) else {
                continue
            }

            for element in enumCase.elements {
                let caseNameText = element.name.text
                if caseNameText == propertyName {
                    return CodingKeyCase(
                        caseName: caseNameText,
                        jsonKey: stringRawValue(from: element)
                    )
                }
            }
        }
        return nil
    }

    /// Extracts the string raw value from `case foo = "bar"` enum case syntax.
    private static func stringRawValue(from enumCaseElement: EnumCaseElementSyntax) -> String? {
        guard
            let rawValue = enumCaseElement.rawValue?.value,
            let literal = rawValue.as(StringLiteralExprSyntax.self),
            let segment = literal.segments.first?.as(StringSegmentSyntax.self)
        else {
            return nil
        }
        return String(segment.content.text)
    }

    /// Parsed arguments from a `@Default` attribute on a property.
    private struct ParsedDefaultAttribute {
        /// Source text of the default value (first unlabeled argument).
        let defaultExpression: String
        /// JSON key from `codingKey:` when using `@Default(_:codingKey:)`.
        let codingKey: String?
        /// Source text of the `transform:` closure, if present.
        let transformExpression: String?
    }

    /// Reads `@Default` attributes from a property’s attribute list.
    ///
    /// - Parameter attributes: Attributes on a `var` declaration.
    /// - Returns: Parsed default and optional coding key, or `nil` if `@Default` is absent.
    private static func parseDefaultAttribute(from attributes: AttributeListSyntax) -> ParsedDefaultAttribute? {
        for attribute in attributes {
            guard
                let attr = attribute.as(AttributeSyntax.self),
                macroName(attr) == "Default",
                let arguments = attr.arguments?.as(LabeledExprListSyntax.self),
                !arguments.isEmpty
            else {
                continue
            }

            var defaultExpression: String?
            var codingKey: String?
            var transformExpression: String?

            for argument in arguments {
                let label = argument.label?.text

                if label == "codingKey" {
                    codingKey = stringLiteralValue(from: argument.expression)
                    continue
                }

                if label == "transform" {
                    transformExpression = argument.expression.description
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    continue
                }

                if label == nil, defaultExpression == nil {
                    defaultExpression = argument.expression.description
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }

            guard let defaultExpression else {
                continue
            }

            return ParsedDefaultAttribute(
                defaultExpression: defaultExpression,
                codingKey: codingKey,
                transformExpression: transformExpression
            )
        }

        return nil
    }

    /// Normalizes an attribute’s name (`Default`, `@Default`, etc.) for comparison.
    private static func macroName(_ attribute: AttributeSyntax) -> String {
        attribute.attributeName.description
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Reads a string literal expression’s content, if the expression is a simple literal.
    private static func stringLiteralValue(from expression: ExprSyntax) -> String? {
        if let literal = expression.as(StringLiteralExprSyntax.self),
           let segment = literal.segments.first?.as(StringSegmentSyntax.self)
        {
            return String(segment.content.text)
        }

        let description = expression.description
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return parseStringLiteral(description)
    }

    /// Strips surrounding double quotes from a source fragment (e.g. `"key"` → `key`).
    private static func parseStringLiteral(_ expression: String) -> String? {
        guard expression.hasPrefix("\""), expression.hasSuffix("\""), expression.count >= 2 else {
            return nil
        }
        let start = expression.index(after: expression.startIndex)
        let end = expression.index(before: expression.endIndex)
        return String(expression[start..<end])
    }
}

/// A compile-time error reported during `@CodableDefault` expansion.
private struct MacroExpansionError: Error, CustomStringConvertible {
    /// Human-readable message shown in the Xcode issue navigator.
    let message: String
    var description: String { message }
}
