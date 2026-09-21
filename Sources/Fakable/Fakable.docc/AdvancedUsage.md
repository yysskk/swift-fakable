# Advanced Usage

The rules `@Fakable` follows when it generates `fake()`.

## Overview

``Fakable()`` is an attached member macro. It never sees types — only the syntax
of the declaration it is attached to. Every rule below follows from that:
decisions come from the text you wrote, not from what the compiler later
resolves it to.

## Which struct properties become parameters

`fake()` takes exactly the parameters the memberwise initializer takes, because
its body calls that initializer. A property is included when it is an identifier
binding with an **explicit type annotation** that is stored, is not `static`,
and is not a `let` that already has a value:

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

The type-annotation requirement is the one that surprises people: the macro has
no type information, so an inferred property gives it nothing to write a
parameter type from. Annotate it to include it.

Parameters keep declaration order, and the body forwards them to the memberwise
initializer by label. Because it calls `Self(...)`, `fake()` is only usable
where the memberwise initializer is — declare any custom `init` in an extension
so the memberwise one survives.

A struct with no stored properties generates nothing, which is not an error.

## Which enum case `fake()` returns

1. The first case **without** associated values, wherever it appears — it needs
   no values invented for it, so it always wins.
2. Otherwise the first case, with each associated value defaulted.
3. An enum with no cases generates nothing, and the macro warns.

```swift
@Fakable
enum UserRole {
    case user(id: String)
    case guest                          // fake() == .guest
    case admin(id: String, level: Int)
}

@Fakable
enum Account {
    case user(id: String)               // fake() == .user(id: "")
    case admin(id: String, level: Int)
}
```

Labels on associated values are preserved when present and omitted when not:
`case tapped(String, at: Int)` fakes as `.tapped("", at: 0)`.

## Default values

| Type as written | Default |
| --- | --- |
| `String` | `""` |
| `Int`, `Int8`, `Int16`, `Int32`, `Int64` | `0` |
| `UInt`, `UInt8`, `UInt16`, `UInt32`, `UInt64` | `0` |
| `Double`, `Float`, `CGFloat` | `0.0` |
| `Bool` | `false` |
| `T?` or `T!` | `nil` |
| `[K: V]` | `[:]` |
| `[T]` | `[]` |
| a generic parameter of the enclosing type | none — the parameter is required |
| anything else | `.fake()` |

- **Optional wins first.** `String?` is `nil`, not `""`.
- **Dictionary is checked before array**, by the presence of a colon inside the
  brackets, so `[String: Int]` is `[:]` and `[String]` is `[]`.
- **Matching is on the written spelling.** `typealias UserID = String` resolves
  to `.fake()`, not `""`. Write the underlying type, make the alias target
  `@Fakable`, or pass the value explicitly.

The `.fake()` fallback is what makes nested models compose. If a nested type has
no `fake()`, the failure surfaces as `value of type 'X' has no member 'fake'` in
the generated code — add ``Fakable()`` to that type, or pass the parameter
explicitly. For a type from a module you do not control, passing it explicitly
(or wrapping it in a `@Fakable` type of your own) is the way.

## Generic types

A property whose type is a generic parameter becomes a **required** parameter,
since no value can be written for it:

```swift
@Fakable
struct Box<T> {
    let value: T
    let label: String
}

let box = Box.fake(value: 42)   // label defaults to ""
```

Types that merely involve a generic parameter without needing a value of it —
`[T]`, `T?` — keep their usual defaults of `[]` and `nil`.

For enums the same situation has no answer, because `fake()` takes no
parameters. A generic enum works as long as it has a case without associated
values; when every case carries a generic associated value, the macro reports an
error rather than generating something that cannot compile.

## Access levels

The generated method carries the access level of its type:

| Declaration | Generated |
| --- | --- |
| `public struct` | `public static func fake(...)` |
| `struct` / `internal struct` | `static func fake(...)` |
| `fileprivate struct` | `fileprivate static func fake(...)` |
| `private struct` | `private static func fake(...)` |

A `public fake()` works from another module even though the memberwise
initializer it calls is `internal` by default: only a signature has to be as
visible as the declaration itself, and the initializer appears only in the body.

## The `#if DEBUG` guard

Every generated method is wrapped in `#if DEBUG`, so `fake()` exists only where
`DEBUG` is defined — Xcode's Debug configuration, `swift test`, and `swift build`
without `-c release`. Nothing from this macro reaches shipping code.

There is currently no argument to change the guard. If you need fixtures in a
release-configuration test-support module, build that target with `-D DEBUG`, or
construct the models without `fake()`.

## Errors

Attaching ``Fakable()`` to anything other than a struct or an enum is a
compile-time error, reported on the attribute itself:

```
'@Fakable' can only be applied to a struct or an enum
```

Classes, actors, and protocols all hit this. A class has no memberwise
initializer to forward to, which is the underlying reason.

A struct with no stored properties and an enum with no cases each warn instead:
the declaration is valid, and the attribute simply had nothing to do.
