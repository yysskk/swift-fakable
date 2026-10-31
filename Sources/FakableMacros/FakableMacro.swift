import SwiftDiagnostics
public import SwiftSyntax
import SwiftSyntaxBuilder
public import SwiftSyntaxMacros

/// The implementation of the `@Fakable` macro.
///
/// It adds a `static func fake(...)` member to the struct or enum it is
/// attached to, guarded by the `condition:` argument's compilation condition —
/// `#if DEBUG` unless the attachment site says otherwise.
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
            context.diagnose(
                Diagnostic(
                    node: node,
                    message: error,
                    // Only an argument the macro cannot read has one repair that
                    // needs no guess. A condition `#if` rejects is text the
                    // author meant, so it is theirs to correct.
                    fixIts: error.isUnreadableCondition
                        ? [FixIt.usingDebugCondition(on: node)].compactMap { $0 }
                        : []
                )
            )
            return []
        }

        let accessLevel = AccessLevel(of: declaration).memberLevel

        if let structDecl = declaration.as(StructDeclSyntax.self) {
            return expand(
                structDecl,
                markedBy: node,
                accessLevel: accessLevel,
                condition: condition,
                in: context
            )
        }

        if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            return expand(
                enumDecl,
                markedBy: node,
                accessLevel: accessLevel,
                condition: condition,
                in: context
            )
        }

        context.diagnose(node, .unsupportedDeclaration)
        return []
    }

    /// The `fake()` for a struct, or nothing when a diagnostic takes its place.
    private static func expand(
        _ structDecl: StructDeclSyntax,
        markedBy node: AttributeSyntax,
        accessLevel: AccessLevel,
        condition: CompilationCondition,
        in context: some MacroExpansionContext
    ) -> [DeclSyntax] {
        let builder = StructFakeBuilder(
            of: structDecl,
            accessLevel: accessLevel,
            condition: condition
        )

        guard builder.hasStoredProperties else {
            context.diagnose(node, .noStoredProperties)
            return []
        }

        if let initializer = builder.initializerBlockingMemberwise {
            context.diagnose(
                Diagnostic(
                    node: initializer,
                    message: FakableDiagnostic.memberwiseInitializerUnavailable
                )
            )
            return []
        }

        return [DeclSyntax(stringLiteral: builder.fakeMethod())]
    }

    /// The `fake()` for an enum, or nothing when a diagnostic takes its place.
    private static func expand(
        _ enumDecl: EnumDeclSyntax,
        markedBy node: AttributeSyntax,
        accessLevel: AccessLevel,
        condition: CompilationCondition,
        in context: some MacroExpansionContext
    ) -> [DeclSyntax] {
        let builder = EnumFakeBuilder(
            of: enumDecl,
            accessLevel: accessLevel,
            condition: condition
        )

        for attribute in builder.conditionalFakeCaseAttributes {
            context.diagnose(Diagnostic(removing: attribute, message: .conditionalFakeCase))
        }

        let markedCases = builder.markedCases
        for marked in markedCases.dropFirst() {
            context.diagnose(Diagnostic(removing: marked.attribute, message: .duplicateFakeCase))
        }
        guard markedCases.count <= 1 else {
            return []
        }

        // The case to return, and where a value the macro cannot write is
        // reported. A marked case is used whatever it carries, so the failure
        // belongs on the marker; an unmarked one was the macro's own choice, so
        // it belongs on the attribute.
        let fakeCase: EnumCase
        let unwritable: Diagnostic

        if let marked = markedCases.first {
            fakeCase = marked.fakeCase
            unwritable = Diagnostic(
                node: marked.attribute,
                message: FakableDiagnostic.unwritableFakeCase
            )
        } else {
            guard let chosen = builder.fakeCase else {
                context.diagnose(node, .noCases)
                return []
            }
            fakeCase = chosen
            unwritable = Diagnostic(
                node: node,
                message: FakableDiagnostic.unwritableAssociatedValue
            )
        }

        guard fakeCase.isWritable else {
            context.diagnose(unwritable)
            return []
        }

        return [DeclSyntax(stringLiteral: builder.fakeMethod(for: fakeCase))]
    }
}

extension MacroExpansionContext {
    /// Reports `diagnostic` against the attribute the macro was written on.
    fileprivate func diagnose(_ node: AttributeSyntax, _ diagnostic: FakableDiagnostic) {
        diagnose(Diagnostic(node: node, message: diagnostic))
    }
}
