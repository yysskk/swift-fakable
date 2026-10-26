import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// The implementation of the `@FakeValue` macro.
///
/// It expands to nothing. `@Fakable` reads the attribute off the property when
/// it builds `fake()`, so all this does is report an attribute that would be
/// silently ignored.
public struct FakeValueMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let variable = declaration.as(VariableDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node, message: FakableDiagnostic.misplacedFakeValue))
            return []
        }

        if !variable.takesFakeParameter || !context.isInsideFakableType {
            context.diagnose(Diagnostic(node: node, message: FakableDiagnostic.unusedFakeValue))
        }
        return []
    }
}

extension VariableDeclSyntax {
    /// The value written in this property's `@FakeValue`, or `nil` when it has
    /// none.
    ///
    /// The attribute is matched by name, bare or qualified with the module, as
    /// the macro has no way to resolve it.
    var fakeValue: ExprSyntax? {
        for element in attributes {
            guard case .attribute(let attribute) = element,
                attribute.attributeName.unqualifiedName == "FakeValue",
                case .argumentList(let arguments)? = attribute.arguments,
                let argument = arguments.first
            else {
                continue
            }
            return argument.expression
        }
        return nil
    }

    /// Whether `fake()` takes a parameter for at least one of the properties
    /// this declaration introduces.
    ///
    /// Mirrors the rules `FakeGenerator` applies: a type-level, computed, or
    /// inferred property gets no parameter, and neither does a `let` that
    /// already has a value.
    fileprivate var takesFakeParameter: Bool {
        guard !isStatic else {
            return false
        }
        return bindingsWithResolvedTypes.contains { binding, type in
            type != nil && binding.isStored && !(isConstant && binding.initializer != nil)
        }
    }
}

extension TypeSyntax {
    /// The last component of the name, so `Fakable.FakeValue` gives `FakeValue`.
    fileprivate var unqualifiedName: String {
        if let member = self.as(MemberTypeSyntax.self) {
            return member.name.text
        }
        return trimmedDescription
    }
}

extension MacroExpansionContext {
    /// Whether the innermost enclosing type is a struct marked `@Fakable`.
    fileprivate var isInsideFakableType: Bool {
        guard let structDecl = lexicalContext.first?.as(StructDeclSyntax.self) else {
            return false
        }
        return structDecl.attributes.contains { element in
            guard case .attribute(let attribute) = element else {
                return false
            }
            return attribute.attributeName.unqualifiedName == "Fakable"
        }
    }
}
