# Advanced Usage

This page documents the rules `@Fakable` follows when it generates `fake()`.
For installation and a quick tour, start from the root [README](../README.md).

## How the macro reads a declaration

`@Fakable` is an attached **member** macro. It never sees types — only the
syntax of the declaration it is attached to. Every rule below follows from that:
decisions are made from the text you wrote, not from what the compiler later
resolves it to.

The expansion adds exactly one member, always wrapped in `#if DEBUG`:

- a struct gets `static func fake(...) -> Self` with one parameter per stored property
- an enum gets `static func fake() -> Self` with no parameters

## Structs

### Which properties become parameters

`fake()` takes exactly the parameters the memberwise initializer takes, because
its body calls that initializer. A stored property is included when all of the
following hold:

- it is a `var` or `let` binding with an identifier pattern
- it has an **explicit type annotation**
- it is not declared `static`
- it is not computed — a `willSet` or `didSet` observer still counts as stored
- it is not a `let` that already has a value, which the memberwise initializer
  does not take either

```swift
@Fakable
struct Profile {
    let id: String             // included
    var nickname: String?      // included
    var visits: Int {          // included: an observer leaves it stored
        didSet { log(visits) }
    }
    let x, y: Int              // included: a parameter each
    static let version = 1     // skipped: type-level
    let createdAt = Date()     // skipped: no type annotation, and a let with a value
    var displayName: String {  // skipped: computed
        nickname ?? id
    }
}
```

Two of these are worth dwelling on.

The type annotation requirement is the one that surprises people. The macro has
no type information, so `let createdAt = Date()` gives it nothing to write a
parameter type from. Annotating it is not enough on its own, because a `let`
that already has a value is not in the memberwise initializer either. Write it
as `var createdAt: Date = Date()` to include it.

One declaration can introduce several properties, and they each get a parameter:
both `let x: Int, y: Int` and `let x, y: Int` yield `x` and `y`, the second by
sharing the single annotation.

### A property that declares its own value

A `var` with a value of its own defaults to that value, exactly as the
memberwise initializer does, so a fake starts from the state the model
describes:

```swift
@Fakable
struct Query {
    static let defaultPageSize = 20

    var page: Int = 1
    var pageSize: Int = Self.defaultPageSize
}

Query.fake()          // page 1, pageSize 20
Query.fake(page: 3)   // page 3, pageSize 20
```

The declared value wins over the type's default, so `var note: String? = "draft"`
fakes as `"draft"` rather than `nil`.

A `public fake()` is the one exception. Swift emits a public function's default
arguments into its callers, so they may reference only public declarations, and
the macro cannot tell whether `Self.defaultPageSize` is one. A `public fake()`
therefore takes a declared value only when it is a literal — a number, a string
without interpolation, `true` / `false`, `nil`, or an array or dictionary
literal of those — and uses the type's default otherwise. `package` and
narrower levels take any value as written.

### Parameter order and the initializer

Parameters keep the declaration order of the stored properties, and the body
forwards each one to the memberwise initializer by label:

```swift
#if DEBUG
static func fake(
    id: String = "",
    nickname: String? = nil
) -> Self {
    Self(
        id: id,
        nickname: nickname
    )
}
#endif
```

Because it calls `Self(...)`, `fake()` is only usable where the memberwise
initializer is. If you write a custom `init` in the same file, the memberwise
initializer disappears and the generated code stops compiling — declare the
custom `init` in an extension to keep both.

### A struct with no stored properties

Nothing is generated, and the macro warns: there would be no parameters to
default and no initializer call to make, so the attribute had no effect.

## Enums

### Which case `fake()` returns

1. The **first case without associated values**, wherever it appears in the
   declaration. It needs no values invented for it, so it is always preferred.
2. If every case has associated values, the **first case**, with each value
   filled in from the default table.
3. If the enum has no cases at all, nothing is generated and the macro warns.

```swift
@Fakable
enum UserRole {
    case user(id: String)
    case guest                             // fake() == .guest
    case admin(id: String, level: Int)
}

@Fakable
enum Account {
    case user(id: String)                  // fake() == .user(id: "")
    case admin(id: String, level: Int)
}
```

Note that the search in step 1 scans all cases, including the later elements of
a comma-separated `case a, b` list.

### Labeled and unlabeled associated values

Labels are preserved when present and omitted when not:

```swift
@Fakable
enum Event {
    case tapped(String, at: Int)   // fake() == .tapped("", at: 0)
}
```

## Default values

| Type as written | Default |
| --- | --- |
| `String` | `""` |
| `Int`, `Int8`, `Int16`, `Int32`, `Int64` | `0` |
| `UInt`, `UInt8`, `UInt16`, `UInt32`, `UInt64` | `0` |
| `Double`, `Float`, `CGFloat`, `TimeInterval` | `0.0` |
| `Bool` | `false` |
| `Decimal` | `0` |
| `Date` | `Date(timeIntervalSince1970: 0)` |
| `UUID` | `UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))` |
| `URL` | `URL(fileURLWithPath: "/")` |
| `Data` | `Data()` |
| `T?`, `T!`, or `Optional<T>` | `nil` |
| `[K: V]` or `Dictionary<K, V>` | `[:]` |
| `[T]` or `Array<T>` | `[]` |
| `Set<T>` | `[]` |
| a generic parameter of the enclosing type | none — the parameter is required |
| a closure, tuple, `any P`, `P & Q`, or metatype | none — the parameter is required |
| any other named type | `.fake()` |

The same table is used for struct properties and for enum associated values.

Seven details are worth spelling out:

- **Optional wins first.** `String?` is `nil`, not `""`. This is checked before
  the type name, so an optional of any type defaults to `nil`.
- **Sugar and longhand are the same type.** Which collection a type is comes
  from the syntax node rather than from the text, so `[String]` and
  `Array<String>` both resolve to `[]`, `[String: Int]` and
  `Dictionary<String, Int>` both to `[:]`, and `String?`, `String!` and
  `Optional<String>` all to `nil`. A nested spelling such as `[String: [Int]]`
  is a dictionary rather than an array for the same reason.
- **A module qualifier is dropped.** `Swift.String` takes the default `String`
  takes, and `Foundation.Date` the one `Date` takes. Only `Swift`, `Foundation`,
  and `CoreGraphics` count as qualifiers, so a type nested inside one of your
  own, such as `Models.Date`, keeps the `.fake()` fallback.
- **A Foundation value type gets a deterministic value.** `Date` is the epoch
  rather than `Date()`, and `UUID` is the nil UUID rather than a fresh one, so
  two fakes of the same model are equal where the model is `Equatable`. Pass the
  value explicitly when a test needs a realistic one.
- **Matching is on the written spelling.** `typealias UserID = String` resolves
  to `.fake()`, not `""`, because the macro sees the text `UserID`. Either write
  the underlying type, add `@Fakable` to the alias target, or pass the value
  explicitly at the call site.
- **Only a named type falls back to `.fake()`.** A closure, a tuple, an
  existential such as `any Shape`, a composition such as `Shape & Sendable`, and
  a metatype have no `fake()` to call, so each is a required parameter. A
  closure parameter is also marked `@escaping`, since `fake()` stores it; an
  optional closure is escaping already and defaults to `nil`.
- **A generic parameter gets no default.** There is no value the macro could
  write for it, so the parameter is required instead (see
  [Generic types](#generic-types)). The check is made token by token, so a type
  named `Total` is not mistaken for a generic parameter named `T`.

## Nested models

The `.fake()` fallback is what makes models compose. Any type the table does not
recognize is assumed to have a `fake()` of its own:

```swift
@Fakable
struct Address {
    let city: String
    let postalCode: String
}

@Fakable
struct User {
    let name: String
    let address: Address       // defaults to Address.fake()
    let role: UserRole         // defaults to UserRole.fake()
}

let user = User.fake(
    name: "Aoi",
    address: .fake(city: "Tokyo")
)
```

If a nested type has no `fake()`, the failure shows up as
`value of type 'X' has no member 'fake'` in the generated code. Add `@Fakable`
to that type, or pass the parameter explicitly.

A type from a module you do not control is the common case here. Pass it
explicitly, or wrap it in a `@Fakable` type of your own.

## Generic types

A property whose type is a generic parameter becomes a **required** parameter,
since no value can be written for it:

```swift
@Fakable
struct Box<T> {
    let value: T
    let label: String
}

let box = Box.fake(value: 42)          // label defaults to ""
let named = Box<String>.fake(value: "x", label: "l")
```

Swift allows defaulted parameters in any position, so the rest of the signature
is unaffected. Types that merely involve a generic parameter without needing a
value of it — `[T]`, `T?` — keep their usual defaults of `[]` and `nil`.

For enums the same situation has no answer, because `fake()` takes no
parameters. A generic enum is fine as long as some case can be written — one
with no associated values, or one whose values are not generic:

```swift
@Fakable
enum Either<T> {
    case some(T)
    case none          // fake() == .none
}

@Fakable
enum Wrapped<T> {
    case value(T)
    case count(Int)    // fake() == .count(0)
}
```

Only when *every* case carries an associated value it cannot write — a generic
parameter, a closure, a tuple — does the macro report an error, rather than generating something that cannot compile.

## Access levels

The generated method carries the access level of the type it is attached to, so
a `public` model gets a `public fake()` that test targets in other modules can
reach:

| Declaration | Generated |
| --- | --- |
| `public struct` | `public static func fake(...)` |
| `package struct` | `package static func fake(...)` |
| `struct` / `internal struct` | `static func fake(...)` |
| `fileprivate struct` | `fileprivate static func fake(...)` |
| `private struct` | `fileprivate static func fake(...)` |

A `private` type is the one exception: its `fake()` is `fileprivate`. A
`private` member is visible only inside its type and that type's extensions in
the same file, so a `private fake()` could not be called even from the rest of
the file the type lives in. `fileprivate` is as visible as the type itself and
no more.

A `public fake()` works from another module even though the memberwise
initializer it calls is `internal` by default: only a declaration's signature
has to be as visible as the declaration itself, and the initializer appears
only in the body. The `.fake()` default arguments are fine for the same reason.

## The compilation condition

By default every generated method is wrapped in `#if DEBUG`, so `fake()` exists
only where `DEBUG` is defined:

- Xcode's Debug configuration defines it by default
- `swift test` and `swift build` (without `-c release`) define it
- a release build does not, so nothing from this macro reaches shipping code

The `condition:` argument chooses a different guard:

```swift
@Fakable                                  // #if DEBUG (default)
@Fakable(condition: .custom("FAKING"))    // #if FAKING
@Fakable(condition: .custom("DEBUG || UITESTS"))
@Fakable(condition: .always)              // no #if guard
```

`.custom` takes anything `#if` accepts, as a string literal: identifiers,
`true` / `false`, `!`, `&&`, `||`, parentheses, and platform checks such as
`os(iOS)` or `canImport(UIKit)`. It is validated by parsing `#if <condition>`,
so the rule is the compiler's own; a condition it would reject is a
compile-time error rather than an `#if` that fails later. Define each flag the
condition names in every target that needs the fixture:
`SWIFT_ACTIVE_COMPILATION_CONDITIONS` in Xcode, or `.define("FLAG")` under
`swiftSettings` in a package manifest.

The value has to be written literally at the attachment site. The macro expands
at compile time, so a `let condition = ...` defined elsewhere is not something
it can read, and passing one is an error.

## Errors

Attaching `@Fakable` to anything other than a struct or an enum is a
compile-time error, reported on the attribute itself:

```
'@Fakable' can only be applied to a struct or an enum
```

Classes, actors, and protocols all hit this. A class has no memberwise
initializer to forward to, which is the underlying reason.

Two more cases warn rather than fail, because the declaration is valid and the
attribute simply had nothing to do:

```
'@Fakable' generates nothing for a struct with no stored properties
'@Fakable' generates nothing for an enum with no cases
```

The `condition:` argument has two errors of its own, for a value that is not
written literally and for a condition `#if` would reject:

```
'@Fakable' needs 'condition:' written literally as '.debug', '.always', or '.custom("FLAG")'
"not a condition!" is not a compilation condition '#if' accepts
```
