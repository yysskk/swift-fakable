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

### Properties inside `#if`

A stored property declared inside `#if` is part of the memberwise initializer
only in the configurations that clause selects, so `fake()` follows the same
split. Each clause gets a `fake()` of its own, taking the properties that
configuration declares, and a block without `#else` gains one for the
configuration where no clause holds:

```swift
@Fakable
struct Item {
    let name: String
    #if os(iOS)
    let badge: Int
    #endif
}

// Generated, inside the usual #if DEBUG:
#if os(iOS)
static func fake(name: String = "", badge: Int = 0) -> Self { ... }
#else
static func fake(name: String = "") -> Self { ... }
#endif
```

Nested blocks split within their clause, and a block that declares no stored
properties — one holding only methods, say — does not split `fake()` at all. Blocks
in sequence multiply, because each configuration of one combines with each of
the next: two blocks that declare properties give four `fake()` variants, and
three give eight. Keep conditional properties in as few blocks as the model
allows. An
`init` in the body must stand in for the memberwise initializer of every
configuration for `fake()` to use it. An enum's cases inside `#if` are not
considered when choosing the case `fake()` returns.

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

Because it calls `Self(...)`, `fake()` needs the memberwise initializer, and
Swift synthesizes that only for a struct that declares no `init` in its body.
Declare a custom `init` in an extension to keep both:

```swift
@Fakable
struct Item {
    let name: String
}

extension Item {
    init(title: String) {
        self.init(name: title)
    }
}
```

An `init` in the body still works when it takes exactly the stored properties
as labels, in declaration order, and can be called as `Self(...)` with nothing
more — not failable, not `throws`, and not `async`. `fake()` then calls it in
place of the memberwise initializer, so any normalization it does applies to
fakes too. Any other `init` in the body is an error, reported on that `init`
(see [Errors](#errors)).

### A struct with no stored properties

Nothing is generated, and the macro warns: there would be no parameters to
default and no initializer call to make, so the attribute had no effect.

## Enums

### Which case `fake()` returns

1. The case marked **`@FakeCase`**, if there is one, whatever it carries.
2. Otherwise the **first case without associated values**, wherever it appears
   in the declaration. It needs no values invented for it, so it is preferred.
3. If every case has associated values, the **first case** whose values can
   all be written, with each value filled in from the default table.
4. If the enum has no cases at all, nothing is generated and the macro warns.

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

Note that the search in step 2 scans all cases, including the later elements of
a comma-separated `case a, b` list.

Mark a case `@FakeCase` when the automatic choice is not a useful starting
point:

```swift
@Fakable
enum Connection {
    case unknown
    @FakeCase
    case connected(host: String, port: Int)   // fake() == .connected(host: "", port: 0)
    case disconnected
}
```

A marked case's associated values become parameters the same way, and a value
the macro cannot write — a generic parameter, a closure — is an error on the
marker rather than a reason to pick another case. Mark at most one case, on a
declaration of its own: `@FakeCase case a, b` would not say which is meant, and
both mistakes are errors. `@FakeCase` in an enum without `@Fakable` warns, and
so does one on a case inside `#if`, since those cases are not considered.

### Associated values become parameters

The chosen case's associated values are the parameters `fake()` takes, each
defaulted by its type, the way a struct's stored properties are. `fake()` with
no arguments returns what it always did; a test that wants one value different
names that one:

```swift
@Fakable
enum Connection {
    case connected(host: String, port: Int)
}

// expands to:
static func fake(
    host: String = "",
    port: Int = 0
) -> Self {
    .connected(host: host, port: port)
}

Connection.fake()                      // .connected(host: "", port: 0)
Connection.fake(host: "example.com")   // .connected(host: "example.com", port: 0)
```

A label the case declares is the parameter's argument label. A value declared
without one is passed positionally, and its parameter takes no label either,
named after its position inside the method:

```swift
@Fakable
enum Event {
    case tapped(String, at: Int)
}

// expands to:
static func fake(
    _ value0: String = "",
    at: Int = 0
) -> Self {
    .tapped(value0, at: at)
}

Event.fake("button", at: 3)
```

A case that names an unlabeled value itself keeps that name:
`case tapped(_ title: String)` gives `fake(_ title: String = "")`, since `_` is
how a case declares a value unlabeled and names it for its own body.

Only the name inside the method comes from the position, so a case free to
label a value `value0` does not collide with it: the second of the two takes an
underscore.

## Default values

| Type as written | Default |
| --- | --- |
| `String`, `Substring` | `""` |
| `Character` | `" "` |
| `Int`, `Int8`, `Int16`, `Int32`, `Int64`, `Int128` | `0` |
| `UInt`, `UInt8`, `UInt16`, `UInt32`, `UInt64`, `UInt128` | `0` |
| `Double`, `Float`, `Float16`, `CGFloat`, `TimeInterval` | `0.0` |
| `Bool` | `false` |
| `Decimal` | `0` |
| `Date` | `Date(timeIntervalSince1970: 0)` |
| `UUID` | `UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))` |
| `URL` | `URL(fileURLWithPath: "/")` |
| `Data` | `Data()` |
| `Duration` | `.zero` |
| `CGPoint`, `CGSize`, `CGRect`, `CGVector` | the zero value, as `CGPoint()` and so on |
| `T?`, `T!`, or `Optional<T>` | `nil` |
| `[K: V]` or `Dictionary<K, V>` | `[:]` |
| `[T]`, `Array<T>`, `ArraySlice<T>`, or `ContiguousArray<T>` | `[]` |
| `Set<T>` | `[]` |
| a generic parameter of the enclosing type | none — the parameter is required |
| a closure, tuple, `any P`, `P & Q`, or metatype | none — the parameter is required |
| any other named type | `.fake()` |

The same table is used for struct properties and for enum associated values.

Eight details are worth spelling out:

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
- **A geometry type gets its zero value from an initializer.** `CGPoint()`
  rather than `.zero`, because Foundation is what names `CGPoint`, `CGSize`,
  `CGRect`, and `CGVector`, while `.zero` is declared in CoreGraphics — an
  import the property's own type does not require.
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

### Teaching `.fake()` about a type you do not own

The `.fake()` fallback is what makes nested models compose, and it only needs a
`static func fake() -> Self` to be in scope: the macro reads syntax and never
resolves types, so it writes the call and leaves the rest to the compiler. For
the structs and enums you own, `@Fakable` writes that method. For a type you
cannot attach the macro to — one from another module, a class, or an actor —
conform it to `FakeProvider`:

```swift
import CoreLocation
import Fakable

extension CLLocationCoordinate2D: FakeProvider {
    public static func fake() -> Self {
        Self(latitude: 0, longitude: 0)
    }
}

@Fakable
struct Place {
    let name: String
    let coordinate: CLLocationCoordinate2D   // defaults to .fake()
}
```

The protocol is the contract written down. Conforming is not what makes
`.fake()` resolve — a plain `extension` declaring the same method works just as
well — but it names the contract, has the compiler check that the method has the
shape `fake()` expects, and lets generic code build a value of a type it does
not know:

```swift
func fakes<Element: FakeProvider>(_ count: Int) -> [Element] {
    (0..<count).map { _ in Element.fake() }
}
```

Return a value that does not change between two calls, the way the macro's own
defaults do, so two fakes of the same type stay equal.

A `@Fakable` struct or enum does not conform on its own, and nothing needs it
to: its `fake()` is guarded by a compilation condition while a conformance holds
in every configuration, and a struct's `fake()` takes one defaulted parameter
per stored property, which does not satisfy a requirement written `fake()`.

## Overriding a default with `@FakeValue`

`@FakeValue(value)` on a stored property sets the default its `fake()`
parameter takes. It is the only way to give a `let` a default other than its
type's, since a `let` with a value of its own is not in the memberwise
initializer:

```swift
@Fakable
struct User {
    @FakeValue("user@example.com")
    let email: String
    @FakeValue(Role.member)
    let role: Role
    @FakeValue(3)
    var page: Int = 1
}

// Generated:
static func fake(
    email: String = "user@example.com",
    role: Role = Role.member,
    page: Int = 3
) -> Self
```

The value is written into `fake()` exactly as given, and wins over both a
declared value and the type's default. A few rules follow from how the
attribute is checked:

- **The value needs a type of its own.** The compiler type-checks a macro's
  arguments before it knows which property they belong to, so an implicit
  member such as `.member` cannot be resolved, and a bare `[]` or `nil` cannot
  either. Name the type (`Role.member`); `[]` and `nil` are already the
  defaults for collections and optionals.
- **One property per declaration.** Attached peer macros apply to a single
  variable, so the compiler rejects `@FakeValue` on `let width, height: Int`.
  Declare the two separately.
- **A public `fake()` inlines it.** The value becomes a default argument, so
  on a `public` type it may reference only public declarations. Unlike a
  declared value, the macro does not fall back here: you wrote the value for
  `fake()`, so it is used as written.

`@FakeValue` has no effect where `fake()` takes no parameter — on a `static`
property, a computed one, one whose type is inferred, a `let` that already has
a value — or on a property
of a type without `@Fakable`, and warns there. On anything other than a
property it is an error.

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

`FakeCompilationCondition` is `ExpressibleByStringLiteral`, so a custom
condition can be written as the literal itself:

```swift
@Fakable(condition: "FAKING")              // the same as .custom("FAKING")
@Fakable(condition: "DEBUG || UITESTS")
```

The value has to be written literally at the attachment site. The macro expands
at compile time, so a `let condition = ...` defined elsewhere is not something
it can read, and passing one is an error — as is an interpolated literal, for
the same reason.

## Errors

Attaching `@Fakable` to anything other than a struct or an enum is a
compile-time error, reported on the attribute itself:

```
'@Fakable' can only be applied to a struct or an enum
```

Classes, actors, and protocols all hit this. A class has no memberwise
initializer to forward to, which is the underlying reason.

A class or actor can still take part in a `@Fakable` model: conform it to
`FakeProvider`, and every property of that type picks its `fake()` up through
the `.fake()` fallback.

```swift
final class Session {
    let token: String
    init(token: String) { self.token = token }
}

extension Session: FakeProvider {
    static func fake() -> Self {
        Self(token: "")
    }
}

@Fakable
struct Request {
    let session: Session   // defaults to Session.fake()
}
```

A struct whose body declares an `init` that cannot stand in for the memberwise
initializer is an error, reported on that `init`, since `fake()` would have
nothing to call:

```
'@Fakable' calls the memberwise initializer, which a struct that declares an 'init' in its body does not get; move this 'init' to an extension
```

Two more cases warn rather than fail, because the declaration is valid and the
attribute simply had nothing to do:

```
'@Fakable' generates nothing for a struct with no stored properties
'@Fakable' generates nothing for an enum with no cases
```

`@FakeValue` warns where it has no effect and is an error on anything other
than a property:

```
'@FakeValue' has no effect here; 'fake()' takes no parameter for this property, or its type is not '@Fakable'
'@FakeValue' can only be applied to a stored property
```

`@FakeCase` is an error on a case with a value the macro cannot write, on a
second marked case, on a declaration of several cases, and on anything other
than a case; it warns in an enum without `@Fakable` and on a case inside `#if`:

```
'@FakeCase' marks a case with an associated value that has no default, such as a generic or a closure
'@FakeCase' can mark only one case of an enum
'@FakeCase' marks a single case; declare this case on its own
'@FakeCase' can only be applied to an enum case
'@FakeCase' has no effect in an enum that is not '@Fakable'
'@FakeCase' has no effect on a case declared inside '#if'
```

The `condition:` argument has two errors of its own, for a value that is not
written literally and for a condition `#if` would reject:

```
'@Fakable' needs 'condition:' written literally as '.debug', '.always', '.custom("FLAG")', or "FLAG"
"not a condition!" is not a compilation condition '#if' accepts
```
