import MacroToolkit
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

public struct EntryMacro: AccessorMacro, PeerMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.AccessorDeclSyntax] {
        let (
            enclosingType,
            identifier,
            _
        ) = try ensureValidApplication(
            context: context,
            declaration: declaration
        )

        let getterContent: String
        let setterContent: String

        let trimmedIdentifier = identifier.trimmingCharacters(in: ["`"])

        switch enclosingType {
            case .environment:
                getterContent = "self[`__Key_\(trimmedIdentifier)`.self]"
                setterContent = "self[`__Key_\(trimmedIdentifier)`.self] = newValue"
            case .focused:
                getterContent = "self[`__Key_\(trimmedIdentifier)`.self]"
                setterContent = "self[`__Key_\(trimmedIdentifier)`.self] = newValue"
            case .appStorage:
                getterContent = "getValue(`__Key_\(trimmedIdentifier)`.self)"
                setterContent = "setValue(`__Key_\(trimmedIdentifier)`.self, newValue: newValue)"
        }

        return [
            AccessorDeclSyntax(
                stringLiteral: """
                    get {
                        \(getterContent)
                    }
                    """
            ),
            AccessorDeclSyntax(
                stringLiteral: """
                    set {
                        \(setterContent)
                    }
                    """
            ),
        ]
    }

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard
            let (
                enclosingType,
                identifier,
                defaultValueDeclaration
            ) = try? ensureValidApplication(
                context: context,
                declaration: declaration
            )
        else {
            return []
        }

        let escapedIdentifier = identifier.replacingOccurrences(of: "\"", with: "\\\"")
        let trimmed = identifier.trimmingCharacters(in: ["`"])

        // A focused value has no default; its key only names the value type,
        // which is the property's type without its optional.
        if enclosingType == .focused {
            return [
                DeclSyntax(
                    stringLiteral: """
                        private struct `__Key_\(trimmed)`: \(enclosingType.keyName) {
                            \(defaultValueDeclaration)
                        }
                        """
                )
            ]
        }

        // AppStorage has got a special requirement to know the key name as string
        let nameDeclaration: String
        switch enclosingType {
            case .environment, .focused:
                nameDeclaration = ""
            case .appStorage:
                nameDeclaration = "\nstatic let name = \"\(escapedIdentifier)\""
        }

        let trimmedIdentifier = identifier.trimmingCharacters(in: ["`"])

        return [
            DeclSyntax(
                stringLiteral: """
                    private struct `__Key_\(trimmedIdentifier)`: \(enclosingType.keyName) {
                        \(defaultValueDeclaration)\(nameDeclaration)
                    } 
                    """
            )
        ]
    }

    private static func ensureValidApplication(
        context: some SwiftSyntaxMacros.MacroExpansionContext,
        declaration: some SwiftSyntax.DeclSyntaxProtocol
    ) throws -> (
        enclosingType: EnclosingType,
        identifier: String,
        defaultValueDeclaration: String
    ) {
        // Verify extension context
        guard
            let extensionDecl = context.lexicalContext.first?.as(ExtensionDeclSyntax.self),
            let enclosingValueType = EnclosingType(
                rawValue: extensionDecl.extendedType.trimmedDescription
            )
        else {
            throw MacroError(
                "@Entry-annotated properties must be direct children of EnvironmentValues, FocusedValues or AppStorageValues extensions."
            )
        }

        // Verify variable
        guard
            let variable = Decl(declaration).asVariable,
            let patternBinding = destructureSingle(variable.bindings),
            let identifier = patternBinding.identifier,
            variable._syntax.bindingSpecifier.text == "var"
        else {
            throw MacroError(
                "@Entry is only supported on single binding `var` declarations."
            )
        }

        let typeDeclaration: String
        if let typeName = patternBinding.type?.normalizedDescription {
            // NB: Swift won't automatically infer the `Value` type if it's an
            // implicitly unwrapped optional.
            typeDeclaration = if typeName.hasSuffix("!") {
                ": \(typeName.dropLast())?"
            } else {
                ": \(typeName)"
            }
        } else {
            typeDeclaration = ""
        }

        if enclosingValueType == .focused {
            guard patternBinding.initialValue == nil,
                let type = patternBinding.type,
                type.isOptional
            else {
                throw MacroError(
                    "@Entry in FocusedValues requires an optional type and no initial value."
                )
            }
            let typeName = type._syntax.trimmedDescription
            let wrapped =
                typeName.hasPrefix("Optional<") && typeName.hasSuffix(">")
                ? String(typeName.dropFirst("Optional<".count).dropLast())
                : String(typeName.dropLast())
            return (
                enclosingType: enclosingValueType,
                identifier: identifier,
                defaultValueDeclaration: "typealias Value = \(wrapped)"
            )
        }

        // Verify defaultValue
        let defaultValueDeclaration: String
        if patternBinding.initialValue == nil,
           let type = patternBinding.type,
           type.isOptional || type._syntax.trimmedDescription.hasSuffix("!")
        {
            defaultValueDeclaration = "static let defaultValue\(typeDeclaration) = nil"
        } else if let initialValue = patternBinding.initialValue?._syntax.trimmedDescription {
            defaultValueDeclaration = "static let defaultValue\(typeDeclaration) = \(initialValue)"
        } else {
            throw MacroError("@Entry requires an initial value for non-optional properties.")
        }

        return (
            enclosingType: enclosingValueType,
            identifier: identifier,
            defaultValueDeclaration: defaultValueDeclaration
        )
    }

    enum EnclosingType: String {
        case environment = "Environment"
        case appStorage = "AppStorage"
        case focused = "FocusedValue"

        init?(rawValue: String) {
            switch rawValue {
                case "SwiftCrossUI.EnvironmentValues", "EnvironmentValues":
                    self = .environment
                case "SwiftCrossUI.AppStorageValues", "AppStorageValues":
                    self = .appStorage
                case "SwiftCrossUI.FocusedValues", "FocusedValues":
                    self = .focused
                default:
                    return nil
            }
        }

        var keyName: String {
            "SwiftCrossUI.\(self.rawValue)Key"
        }
    }
}
