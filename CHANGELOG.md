# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-09-21

### Changed

- Diagnostics are now reported on the attribute with a stable `MessageID`
  rather than thrown as a plain error, and the wording of the
  struct-or-enum diagnostic changed to `'@Fakable' can only be applied to a
  struct or an enum`.

### Added

- `@Fakable(condition:)` chooses the compilation condition that guards the
  generated method: `.debug` (the default, `#if DEBUG`), `.custom("FLAG")` for
  any condition `#if` accepts, or `.always` for no guard at all. A custom
  condition is validated by parsing `#if <condition>`, so one the compiler
  would reject is reported at the attribute.
- Generic types are supported. A property whose type is a generic parameter
  becomes a required `fake()` parameter, since no value can be written for it,
  while `[T]` and `T?` keep their `[]` and `nil` defaults. A generic enum picks
  the first case whose values can be written, and is an error only when every
  case carries a generic associated value.
- A struct with no stored properties and an enum with no cases now warn.
  Both previously expanded to nothing in silence.

### Fixed

- A `package` type now gets a `package fake()`. The modifier was not
  recognised, so the generated method fell back to `internal` and was
  invisible to the rest of the package.

- `fake()` now mirrors the memberwise initializer exactly. `static` properties
  and constants that already have a value no longer become parameters, a
  `willSet` / `didSet` observer no longer removes one, and a declaration that
  introduces several properties (`let x: Int, y: Int` or `let x, y: Int`) now
  yields a parameter for each. Each of these previously generated a `fake()`
  that did not compile, or no `fake()` at all.

## [0.1.0] - 2026-09-21

### Added

- `@Fakable` macro that generates a `static func fake(...)` for structs and a
  `static func fake()` for enums, wrapped in `#if DEBUG`.
- Type-driven default values for struct properties and enum associated values:
  `""`, `0`, `0.0`, `false`, `[]`, `[:]`, `nil`, and a `.fake()` fallback that
  lets nested `@Fakable` models compose.
- Access-level-aware generation, so a `public` type gets a `public fake()`.
- Enum case selection that prefers a case without associated values, and falls
  back to the first case with defaulted values when every case has them.

[Unreleased]: https://github.com/yysskk/swift-fakable/compare/0.2.0...HEAD
[0.2.0]: https://github.com/yysskk/swift-fakable/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/yysskk/swift-fakable/releases/tag/0.1.0
