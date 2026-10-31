import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder

/// The fix-its the macros offer alongside their diagnostics.
///
/// Each one says in the message exactly what it will do, since an editor offers
/// it as a single click with no preview of the edit.
enum FakableFixIt: FixItMessage {
    /// Take a marker attribute off a declaration it has no effect on.
    case removeAttribute(name: String)

    /// Replace a `condition:` argument the macro cannot read with the default.
    case useDebugCondition

    var message: String {
        switch self {
        case .removeAttribute(let name):
            "Remove '@\(name)'"
        case .useDebugCondition:
            "Replace with '.debug'"
        }
    }

    var fixItID: MessageID {
        switch self {
        case .removeAttribute:
            MessageID(domain: "FakableMacros", id: "removeAttribute")
        case .useDebugCondition:
            MessageID(domain: "FakableMacros", id: "useDebugCondition")
        }
    }
}

extension FixIt {
    /// Takes `attribute` off the declaration it is written on.
    ///
    /// Every diagnostic about a marker in the wrong place offers it, since the
    /// attribute does nothing where it is and removing it is the whole repair.
    ///
    /// `nil` when the attribute is not in an attribute list, which the syntax
    /// tree makes impossible but the type does not.
    static func removing(_ attribute: AttributeSyntax) -> FixIt? {
        guard let attributes = attribute.parent?.as(AttributeListSyntax.self) else {
            return nil
        }

        // `Array(...)` first, so this reads the same against every swift-syntax
        // version in the supported range: `filter` on a syntax collection
        // started returning the collection itself partway through it.
        var remaining = AttributeListSyntax(
            Array(attributes).filter { $0.as(AttributeSyntax.self)?.id != attribute.id }
        )

        // The trivia in front of the attribute — the line break and the
        // indentation that put it where it is — is the list's when the
        // attribute is what the list starts with. Whatever follows has to
        // inherit it, or it is removed along with the attribute and what
        // followed is pulled up onto the previous line.
        //
        // An attribute that remains takes it as part of the replacement, since
        // a change to a token inside the list being replaced would be thrown
        // away with the list. Only the declaration's own first token, which is
        // outside it, is edited on its own.
        let isFirst = attributes.first?.as(AttributeSyntax.self)?.id == attribute.id
        if isFirst, !remaining.isEmpty {
            remaining = remaining.with(\.leadingTrivia, attribute.leadingTrivia)
        }

        var changes: [FixIt.Change] = [
            .replace(oldNode: Syntax(attributes), newNode: Syntax(remaining))
        ]

        if isFirst, remaining.isEmpty, let next = attribute.nextToken(viewMode: .sourceAccurate) {
            changes.append(
                .replaceLeadingTrivia(token: next, newTrivia: attribute.leadingTrivia)
            )
        }

        return FixIt(
            message: FakableFixIt.removeAttribute(
                name: attribute.attributeName.trimmedDescription
            ),
            changes: changes
        )
    }

    /// Replaces the `condition:` argument of `attribute` with `.debug`.
    ///
    /// Offered where the argument cannot be read at all. `.debug` is what
    /// `@Fakable` means with no argument, so it is the one replacement that
    /// needs no guess about what was intended.
    ///
    /// `nil` when the attribute carries no `condition:` argument, which is not
    /// a case that is reported.
    static func usingDebugCondition(on attribute: AttributeSyntax) -> FixIt? {
        guard case .argumentList(let arguments)? = attribute.arguments,
            let argument = arguments.first(where: { $0.label?.text == "condition" })
        else {
            return nil
        }

        let debug = ExprSyntax(stringLiteral: ".debug")
            .with(\.leadingTrivia, argument.expression.leadingTrivia)
            .with(\.trailingTrivia, argument.expression.trailingTrivia)

        return FixIt(
            message: FakableFixIt.useDebugCondition,
            changes: [.replace(oldNode: Syntax(argument.expression), newNode: Syntax(debug))]
        )
    }
}

extension Diagnostic {
    /// A diagnostic reported on a marker attribute, offering to remove it.
    init(removing attribute: AttributeSyntax, message: FakableDiagnostic) {
        self.init(
            node: attribute,
            message: message,
            fixIts: [FixIt.removing(attribute)].compactMap { $0 }
        )
    }

    /// The same, where the attribute is the one a peer macro was expanded for.
    ///
    /// Such an attribute arrives on its own, with no attribute list above it to
    /// take it out of. `declaration` is what it is written on, and the
    /// attribute of the same name there is the one in the tree.
    init(
        removing attribute: AttributeSyntax,
        writtenOn declaration: some DeclSyntaxProtocol,
        message: FakableDiagnostic
    ) {
        let written =
            declaration
            .asProtocol((any WithAttributesSyntax).self)?
            .attributes
            .attribute(named: attribute.attributeName.trimmedDescription)

        self.init(
            node: attribute,
            message: message,
            fixIts: [written.flatMap(FixIt.removing)].compactMap { $0 }
        )
    }
}
