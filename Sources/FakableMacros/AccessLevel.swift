import SwiftSyntax

/// Reads the access level of the annotated declaration so the generated `fake()`
/// is at least as visible as the type it belongs to.
///
/// - Returns: The keyword followed by a space (for example `"public "`), or an
///   empty string for `internal`, which needs no keyword.
func extractAccessLevel(from declaration: some DeclGroupSyntax) -> String {
    for modifier in declaration.modifiers {
        switch modifier.name.text {
        case "public":
            return "public "
        case "internal":
            return ""
        case "private":
            return "private "
        case "fileprivate":
            return "fileprivate "
        default:
            continue
        }
    }
    // Default is internal (no keyword needed)
    return ""
}
