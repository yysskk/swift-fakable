import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// The implementation of the `@FakeCase` macro.
///
/// It expands to nothing. `@Fakable` reads the attribute off the case when it
/// builds `fake()`, so all this does is report an attribute that would be
/// misread or silently ignored.
public struct FakeCaseMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let caseDecl = declaration.as(EnumCaseDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node, message: FakableDiagnostic.misplacedFakeCase))
            return []
        }

        if caseDecl.elements.count > 1 {
            context.diagnose(Diagnostic(node: node, message: FakableDiagnostic.ambiguousFakeCase))
        } else if !context.isInsideFakableType {
            context.diagnose(Diagnostic(node: node, message: FakableDiagnostic.unusedFakeCase))
        }
        return []
    }
}
