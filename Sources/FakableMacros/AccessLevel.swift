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

    /// The modifier to write on the generated member, with its trailing space.
    ///
    /// Empty for ``internal``, which is the default and needs no keyword.
    var modifier: String {
        self == .internal ? "" : "\(rawValue) "
    }
}
