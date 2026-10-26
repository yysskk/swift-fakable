import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// The implementation of the `@Fakable` macro.
///
/// It adds a `static func fake(...)` member, wrapped in `#if DEBUG`, to the
/// struct or enum it is attached to.
public struct FakableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let condition: CompilationCondition
        do {
            condition = try CompilationCondition(of: node)
        } catch {
            context.diagnose(node, error)
            return []
        }

        let accessLevel = AccessLevel(of: declaration).memberLevel

        if let structDecl = declaration.as(StructDeclSyntax.self) {
            let layout = FakeGenerator.storedPropertyLayout(
                of: structDecl,
                accessLevel: accessLevel
            )

            guard layout.configurations.contains(where: { !$0.isEmpty }) else {
                context.diagnose(node, .noStoredProperties)
                return []
            }

            if let initializer = FakeGenerator.initializerBlockingMemberwise(
                of: structDecl,
                layout: layout
            ) {
                context.diagnose(
                    Diagnostic(node: initializer, message: FakableDiagnostic.memberwiseInitializerUnavailable)
                )
                return []
            }

            let fakeMethod = FakeGenerator.fakeMethod(
                for: layout,
                accessLevel: accessLevel,
                condition: condition
            )
            return [DeclSyntax(stringLiteral: fakeMethod)]
        }

        if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            guard let firstCase = FakeGenerator.firstCase(of: enumDecl) else {
                context.diagnose(node, .noCases)
                return []
            }

            guard
                let fakeMethod = FakeGenerator.enumFakeMethod(
                    firstCase: firstCase,
                    accessLevel: accessLevel,
                    condition: condition
                )
            else {
                context.diagnose(node, .unwritableAssociatedValue)
                return []
            }
            return [DeclSyntax(stringLiteral: fakeMethod)]
        }

        context.diagnose(node, .unsupportedDeclaration)
        return []
    }
}

extension MacroExpansionContext {
    /// Reports `diagnostic` against the attribute the macro was written on.
    fileprivate func diagnose(_ node: AttributeSyntax, _ diagnostic: FakableDiagnostic) {
        diagnose(Diagnostic(node: node, message: diagnostic))
    }
}
