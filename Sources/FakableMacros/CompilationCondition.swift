import SwiftParser
import SwiftSyntax

/// The `#if` guard placed around a generated member.
enum CompilationCondition {
    /// Emitted with no guard at all.
    case unguarded

    /// Emitted inside `#if <condition>`.
    case guarded(String)

    /// The condition written on the attribute, or ``guarded(_:)`` with `DEBUG`
    /// when the attribute carries no `condition:` argument.
    ///
    /// - Throws: A ``FakableDiagnostic`` describing why the argument could not
    ///   be read.
    init(of node: AttributeSyntax) throws(FakableDiagnostic) {
        guard case .argumentList(let arguments)? = node.arguments else {
            self = .guarded("DEBUG")
            return
        }

        guard let argument = arguments.first(where: { $0.label?.text == "condition" }) else {
            self = .guarded("DEBUG")
            return
        }

        self = try Self(expression: argument.expression)
    }

    private init(expression: ExprSyntax) throws(FakableDiagnostic) {
        // `.debug` or `.always`
        if let member = expression.as(MemberAccessExprSyntax.self), member.base == nil {
            switch member.declName.baseName.text {
            case "debug":
                self = .guarded("DEBUG")
                return
            case "always":
                self = .unguarded
                return
            default:
                throw .unreadableCondition
            }
        }

        // `.custom("FLAG")`
        guard let call = expression.as(FunctionCallExprSyntax.self),
            let callee = call.calledExpression.as(MemberAccessExprSyntax.self),
            callee.base == nil,
            callee.declName.baseName.text == "custom",
            call.arguments.count == 1,
            let literal = call.arguments.first?.expression.as(StringLiteralExprSyntax.self),
            let condition = literal.representedLiteralValue
        else {
            throw .unreadableCondition
        }

        guard Self.isValid(condition) else {
            throw .invalidCondition(condition)
        }

        self = .guarded(condition)
    }

    /// Whether `#if` accepts `condition`.
    ///
    /// Checked by parsing `#if <condition>`, so the rule is the compiler's own
    /// rather than a grammar this package would have to keep in step with it.
    ///
    /// A newline is rejected before that: a condition is a single-line
    /// expression, and text containing one could close the `#if` and carry on
    /// with declarations of its own, which would still parse.
    private static func isValid(_ condition: String) -> Bool {
        guard !condition.isEmpty, !condition.contains(where: \.isNewline) else {
            return false
        }

        return !Parser.parse(source: "#if \(condition)\n#endif\n").hasError
    }

    /// `source` wrapped in this guard.
    func guarding(_ source: String) -> String {
        switch self {
        case .unguarded:
            source
        case .guarded(let condition):
            """
            #if \(condition)
            \(source)
            #endif
            """
        }
    }
}
