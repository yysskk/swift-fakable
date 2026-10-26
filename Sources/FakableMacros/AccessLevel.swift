import SwiftSyntax

/// The access level of a declaration, and of the `fake()` generated for it.
///
/// The raw values are the keywords themselves, so reading one back from source
/// is a lookup rather than a list of cases to keep in step.
enum AccessLevel: String {
    case `private`
    case `fileprivate`
    case `internal`
    case `package`
    case `public`

    /// The level written on `declaration`, or ``internal`` when none is.
    init(of declaration: some DeclGroupSyntax) {
        self =
            declaration.modifiers
            .lazy
            .compactMap { AccessLevel(rawValue: $0.name.text) }
            .first ?? .internal
    }

    /// The level a member needs to be reachable everywhere its type is.
    ///
    /// A `private` member is visible only inside its type and that type's
    /// extensions in the same file, which is narrower than a `private` type,
    /// so a `private static func fake()` could not be called even from the
    /// rest of the file. `private` widens to `fileprivate` for that reason.
    /// Every other level carries over unchanged, and the member can never end
    /// up more visible than the type that holds it.
    var memberLevel: AccessLevel {
        self == .private ? .fileprivate : self
    }

    /// The keyword to write on the generated member, or `nil` for
    /// ``internal``, which is the default and needs none.
    var keyword: String? {
        self == .internal ? nil : rawValue
    }

    /// `declaration` with this level's keyword in front, such as
    /// `public static func fake` for `static func fake`.
    func prefixing(_ declaration: String) -> String {
        [keyword, declaration].compactMap { $0 }.joined(separator: " ")
    }
}
