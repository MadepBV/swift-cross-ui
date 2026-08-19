import MacroToolkit
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

public struct ObservableObjectMacro: MemberAttributeMacro, ExtensionMacro {
    /// The spellings of the marker macro that opts a member out of automatic
    /// publishing.
    ///
    /// Both the bare and the module-qualified spelling have to be recognised,
    /// because the marker is only ever seen as syntax here — a
    /// member-attribute macro gets no name resolution.
    ///
    /// The `ObservationIgnored` spellings are the marker's former name, kept
    /// so that the rename can't silently start publishing a property that
    /// used to be excluded. In a file that imports `Observation`, the bare
    /// `@ObservationIgnored` now resolves to the standard library's macro
    /// (SwiftCrossUI's alias of that name is unavailable), which expands to
    /// nothing and would otherwise leave the property looking eligible.
    static let optOutMarkers = [
        "ObservableObjectIgnored",
        "SwiftCrossUI.ObservableObjectIgnored",
        "ObservationIgnored",
        "SwiftCrossUI.ObservationIgnored",
        "Observation.ObservationIgnored",
    ]

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard ClassDeclSyntax(declaration) != nil else {
            throw MacroError("@Observable can only be applied to classes")
        }

        guard
            let variable = Decl(member).asVariable,
            // only fully visible members
            !variable._syntax.modifiers.contains(where: { modifier in
                let kind = modifier.name.tokenKind

                return
                    kind == .keyword(.static) || kind == .keyword(.private)
                        || kind == .keyword(.fileprivate)
            }),
            // Only include variables
            variable._syntax.bindingSpecifier.text == "var",
            // Only include not yet observed and not opt out members
            !variable.attributes.contains(where: { attr in
                return
                    [
                        "Published",
                        "SwiftCrossUI.Published",
                    ].contains(attr.attribute?._syntax.trimmedDescription)
            }),
            !Self.optOutMarkers.contains(where: { marker in
                variable.hasMacroApplication(marker)
            }),
            // Only include properties without accessors
            let binding = destructureSingle(variable.bindings),
            // Don't allow any accessors, because even when the property is
            // stored (i.e. supports `@Published`), the added property wrapper
            // changes the meaning of `didSet` and `willSet` accessors.
            binding.accessors.isEmpty
        else {
            return []
        }

        return ["@SwiftCrossUI.Published"]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard ClassDeclSyntax(declaration) != nil else {
            throw MacroError("@Observable can only be applied to classes")
        }

        let extensionDecl = try ExtensionDeclSyntax(
            """
            extension \(raw: type): SwiftCrossUI.ObservableObject {}
            """
        )

        return [extensionDecl]
    }
}

/// Backs `@ObservableObjectIgnored`.
///
/// The macro is a pure marker for ``ObservableObjectMacro``, so it expands to
/// no accessors at all and leaves the property exactly as written.
struct ObservableObjectIgnoredMacro: AccessorMacro {
    static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.AccessorDeclSyntax] {
        []
    }
}
