/// The compilation condition that guards a generated `fake()`.
///
/// Pass one to ``Fakable(condition:)``. The value has to be written literally at
/// the attachment site, because the macro expands at compile time and cannot
/// read a value computed at run time.
public enum FakeCompilationCondition: Sendable {
    /// Wrap `fake()` in `#if DEBUG`. This is the default.
    case debug

    /// Emit `fake()` with no `#if` guard, in every build configuration.
    case always

    /// Wrap `fake()` in `#if` with the given condition.
    ///
    /// The condition is anything `#if` accepts: a flag (`"FAKING"`), or an
    /// expression built from identifiers, `true` / `false`, `!`, `&&`, `||`,
    /// parentheses, and platform checks (`"DEBUG || UITESTS"`,
    /// `"os(iOS) && !RELEASE"`, `"canImport(XCTest)"`).
    ///
    /// Define each flag the condition names in every target that needs the
    /// fixtures: `SWIFT_ACTIVE_COMPILATION_CONDITIONS` in Xcode, or
    /// `.define("FLAG")` under `swiftSettings` in a package manifest.
    case custom(String)
}
