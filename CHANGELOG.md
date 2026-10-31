# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- The diagnostics whose repair needs no guess now carry a Fix-It, so an editor
  offers it in one click: "Remove '@FakeCase'" and "Remove '@FakeValue'" where
  a marker has no effect or cannot be used where it is, and "Replace with
  '.debug'" where `condition:` is not written in a form the macro can read.
- A `condition:` written as a bare string literal is the `.custom` condition it
  spells, so `@Fakable(condition: "FAKING")` says what
  `@Fakable(condition: .custom("FAKING"))` says.
  `FakeCompilationCondition` conforms to `ExpressibleByStringLiteral` for it.
  The literal still has to be a plain one the macro can read from the source
  text, so an interpolated literal is an error.
- More of the standard value types have a default, so they no longer fall
  through to `.fake()` and fail to compile: `Substring` takes `""` and
  `Character` a single space, `Duration` takes `.zero`, `ArraySlice` and
  `ContiguousArray` take `[]`, and `CGPoint`, `CGSize`, `CGRect`, and
  `CGVector` take their zero value as `CGPoint()` and so on — the no-argument
  initializer rather than `.zero`, which is declared in CoreGraphics while
  Foundation is what names the type. A type of your own with one of these
  names now takes the table's default rather than `.fake()`, the way one named
  `Date` or `URL` already did.
- `FakeProvider` is the `.fake()` fallback written down as a protocol: one
  `static func fake() -> Self`. Conform a type `@Fakable` cannot be attached to
  — one from another module, a class, or an actor — and a `@Fakable` model that
  nests it compiles with no value of its own. The conformance is checked by the
  compiler and usable from generic code; a `@Fakable` type needs none, since
  its `fake()` is guarded by a compilation condition.
- `Int128` and `UInt128` default to `0`, and `Float16` to `0.0`. They used to
  fall through to `.fake()` and fail to compile.
- `@FakeCase` marks the case an enum's `fake()` returns, in place of the first
  case without associated values. Its associated values are filled in as
  usual, and one the macro cannot write is an error on the marker.
- `@FakeValue(value)` sets the default a stored property's `fake()` parameter
  takes, ahead of a declared value and of the type's default. It is the only
  way to give a `let` a default of your own. It warns where it has no effect
  and is an error on anything other than a property.
- Stored properties declared inside `#if` are now parameters in the
  configurations that declare them. Each clause gets a `fake()` of its own, and
  a block without `#else` gains one for the configuration where no clause
  holds, matching the memberwise initializer of each. They used to be skipped,
  so `fake()` failed with `missing argument` wherever such a property existed.
- A struct that declares an `init` in its body, and so gets no memberwise
  initializer, is now reported on that `init` with a message that says to move
  it to an extension. It used to fail inside the generated code with an
  argument-label error that did not say why. An `init` that takes exactly the
  stored properties as labels, in order, and is neither failable, `throws`, nor
  `async` stands in for the memberwise one and is what `fake()` calls.

### Changed

- `swift-docc-plugin` is added to the manifest only when
  `FAKABLE_BUILD_DOCUMENTATION` is set, so a package depending on
  `swift-fakable` no longer resolves it, or the symbol-kit package behind it.
  Nothing about the library changes; building the documentation now needs the
  variable, which the docs workflow sets.
- An enum's `fake()` now takes the chosen case's associated values as
  parameters, each defaulted by its type, the way a struct's stored properties
  are. `fake()` with no arguments returns what it always did, so nothing that
  compiled stops compiling, and a test that wants one value different no longer
  has to write the case out by hand: `Connection.fake(host: "example.com")`. A
  value the case declares no label for is passed positionally, as `_ value0`,
  `_ value1`, and so on.
- A `var` that declares its own value now defaults to that value in `fake()`,
  the way the memberwise initializer does, instead of to its type's default.
  `var page: Int = 1` gives `page: Int = 1` rather than `0`, and
  `var note: String? = "draft"` gives `"draft"` rather than `nil`. A
  `public fake()` uses the declared value only when it is a literal, because a
  public function's default arguments may reference only public declarations;
  any other value keeps the type's default there.

### Fixed

- A property of function type is now an `@escaping` parameter. Without the
  attribute the generated method failed to compile with `passing non-escaping
  parameter to function expecting an '@escaping' closure`, so no model with a
  closure property could use `@Fakable`. An optional closure is escaping
  already and keeps its `nil` default.
- A closure, tuple, `any P`, `P & Q`, or metatype property is now a required
  parameter rather than defaulting to `.fake()`, which none of them can have.
  The enum diagnostic for a case with only such values now names them.

- A `private` struct or enum now gets a `fileprivate fake()` rather than a
  `private` one. A `private` member is visible only inside its type and that
  type's extensions, so `fake()` could not be called from anywhere else in the
  file and failed with `'fake' is inaccessible due to 'private' protection
  level`.

## [0.3.0] - 2026-10-16

### Added

- Foundation value types have a default, so a model carrying one no longer needs
  a value at every call site. `Date` fakes as the epoch, `UUID` as the nil UUID,
  `URL` as `URL(fileURLWithPath: "/")`, `Data` as `Data()`, `Decimal` as `0`,
  and `TimeInterval` as `0.0`. `Set<T>` joins `[T]` and `[K: V]` at `[]`, and
  wins over the generic-parameter rule the same way they do. Every value is
  deterministic, so two fakes of the same model are equal where the model is
  `Equatable`.
- A module-qualified spelling takes the default its bare name takes, so
  `Swift.String` fakes as `""` and `Foundation.Date` as the epoch. Only
  `Swift`, `Foundation`, and `CoreGraphics` count as qualifiers; a type nested
  in one of your own, such as `Models.Date`, keeps the `.fake()` fallback.

### Changed

- A property of one of those types used to fall through to `.fake()` and fail to
  compile with `value of type 'Date' has no member 'fake'`. A project that
  worked around that with an `extension Date { static func fake() }` of its own
  now gets the built-in value instead, as does a project with a type of its own
  named `Date`, `UUID`, `URL`, `Data`, `Decimal`, or `TimeInterval`. Types are
  still matched on their written spelling.

### Fixed

- `Optional<T>`, `Array<T>`, and `Dictionary<K, V>` written longhand now
  resolve to `nil`, `[]`, and `[:]`, the same as `T?`, `[T]`, and `[K: V]`.
  They used to fall through to `.fake()` and fail to compile with
  `value of type 'Optional<String>' has no member 'fake'`, because the macro
  read the text of the type rather than the syntax node. Which collection a
  type is now comes from the node, so `[String: [Int]]` is a dictionary
  because the node says so rather than because the text holds a colon.
- The advanced usage guide no longer advises annotating a `let` that already has
  a value to include it in `fake()`. A constant with a value is not in the
  memberwise initializer, so it has to become a `var`.

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

[Unreleased]: https://github.com/yysskk/swift-fakable/compare/0.3.0...HEAD
[0.3.0]: https://github.com/yysskk/swift-fakable/compare/0.2.0...0.3.0
[0.2.0]: https://github.com/yysskk/swift-fakable/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/yysskk/swift-fakable/releases/tag/0.1.0
