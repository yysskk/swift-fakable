# swift-fakable

[![Test](https://github.com/yysskk/swift-fakable/actions/workflows/test.yml/badge.svg)](https://github.com/yysskk/swift-fakable/actions/workflows/test.yml)
[![Coverage](https://codecov.io/gh/yysskk/swift-fakable/graph/badge.svg)](https://codecov.io/gh/yysskk/swift-fakable)
[![Release](https://img.shields.io/github/v/release/yysskk/swift-fakable)](https://github.com/yysskk/swift-fakable/releases)
[![Swift](https://img.shields.io/badge/Swift-6.0%20%7C%206.2%20%7C%206.4-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-blue.svg)](https://developer.apple.com)
[![License](https://img.shields.io/github/license/yysskk/swift-fakable)](LICENSE)

`swift-fakable` provides a `@Fakable` macro that generates a `fake()` factory method for test fixtures.

- A test names only the values it cares about; every other parameter has a default.
- Generated methods are emitted inside `#if DEBUG`, so they never ship in a release build.
- Works on both structs (one parameter per stored property) and enums (returns a representative case).

## Installation

Add the package:

```swift
dependencies: [
    .package(url: "https://github.com/yysskk/swift-fakable.git", from: "0.1.0")
]
```

Add `Fakable` to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["Fakable"]
)
```

> [!NOTE]
> The first time you build a target that uses `@Fakable`, Xcode shows a
> "trust macro" prompt. Choose **Trust & Enable** to allow the macro to run.
> On the command line, `swift build` runs macros without prompting.

## Quick Start

```swift
import Fakable

@Fakable
struct Item {
    let itemId: String
    let name: String?
    let price: Int
}

@Fakable
enum Sex {
    case man
    case woman
}

let item = Item.fake()
#expect(item.itemId == "")
#expect(item.name == nil)
#expect(item.price == 0)

// Override only what the test is about.
let sale = Item.fake(itemId: "item-1", price: 500)
#expect(sale.itemId == "item-1")
#expect(sale.price == 500)

#expect(Sex.fake() == .man)
```

## What Gets Generated

### Structs

`@Fakable` generates a `static func fake(...)` with one parameter per stored
property, in declaration order, each defaulted by its type:

```swift
@Fakable
struct Person {
    let name: String
    let age: Int
}

// expands to:
#if DEBUG
static func fake(
    name: String = "",
    age: Int = 0
) -> Self {
    Self(
        name: name,
        age: age
    )
}
#endif
```

The method calls the struct's memberwise initializer, so it is available
wherever that initializer is.

### Enums

`@Fakable` generates a parameterless `static func fake()` that returns one case:

```swift
@Fakable
enum Status {
    case active
    case inactive
}

// expands to:
#if DEBUG
static func fake() -> Self {
    .active
}
#endif
```

## Default Values

| Type | Default |
| --- | --- |
| `String` | `""` |
| `Int`, `Int8`, `Int16`, `Int32`, `Int64` | `0` |
| `UInt`, `UInt8`, `UInt16`, `UInt32`, `UInt64` | `0` |
| `Double`, `Float`, `CGFloat` | `0.0` |
| `Bool` | `false` |
| `Array` (`[T]`) | `[]` |
| `Dictionary` (`[K: V]`) | `[:]` |
| `Optional` (`T?`, `T!`) | `nil` |
| anything else | `.fake()` |

The `.fake()` fallback is what makes nested models compose: a property of type
`Address` resolves to `Address.fake()`, so `Address` needs `@Fakable` too.

```swift
@Fakable
struct Address {
    let city: String
}

@Fakable
struct User {
    let name: String
    let address: Address   // defaults to Address.fake()
}

let user = User.fake(address: .fake(city: "Tokyo"))
```

The same table applies to an enum case's associated values.

## Supported Features

- Structs with any number of stored properties
- Enums with or without associated values
- Access-level-aware generation (`public` types get a `public fake()`)
- Optional and implicitly unwrapped optional properties
- Arrays and dictionaries, including nested generic spellings
- Nested `@Fakable` types through the `.fake()` fallback
- Labeled and unlabeled associated values on enum cases

## Behavioral Notes

- The generated method is always wrapped in `#if DEBUG`.
- Struct parameters keep the declaration order of the stored properties, and the
  body forwards them to the memberwise initializer by label. One declaration can
  introduce several of them: `let x, y: Int` yields a parameter each.
- A stored property that declares its own value (`var page: Int = 1`) still gets
  a parameter, defaulted from its type rather than from the declared value.
- For enums, a case **without** associated values is preferred no matter where it
  appears in the declaration, because it needs no values invented for it:

  ```swift
  @Fakable
  enum UserRole {
      case user(id: String)
      case guest              // fake() returns .guest
      case admin(id: String, level: Int)
  }
  ```

- Only when every case has associated values does the first case win, with each
  value filled in from the default table:

  ```swift
  @Fakable
  enum Account {
      case user(id: String)                  // fake() returns .user(id: "")
      case admin(id: String, level: Int)
  }
  ```

- An enum with no cases generates nothing, and neither does a struct with no
  stored properties. Both warn, since the attribute had no effect.

## Diagnostics and Limitations

- `@Fakable` can only be applied to a struct or an enum. Applying it to a class,
  actor, or protocol is a compile-time error reported on the attribute itself.
- `fake()` takes exactly the parameters the memberwise initializer takes, since
  that is what its body calls. Type-level (`static`) properties, computed
  properties, and constants that already have a value are left out for that
  reason, while a `willSet` or `didSet` observer leaves a property stored and so
  keeps its parameter.
- Only stored properties with an **explicit type annotation** get a parameter.
  A property whose type is inferred (`let count = 0`) is skipped, because the
  macro reads the syntax tree and has no type information to work from. Annotate
  the property to include it.
- The `.fake()` fallback is emitted for any unrecognized type. If that type has
  no `fake()`, the error surfaces at compile time in the generated code; add
  `@Fakable` to it, or pass an explicit value at the call site.
- Types are matched by their written spelling, so a type alias for `String`
  resolves to `.fake()` rather than `""`.
- There is currently no way to change the `#if DEBUG` guard.

## Troubleshooting

- **`fake()` can't be found.** The generated method lives inside `#if DEBUG`, so
  it only exists in debug builds. Reference it from test targets or debug
  configurations.
- **"Macro expansion" / trust prompt in Xcode.** Choose **Trust & Enable** the
  first time you build a target that uses `@Fakable` (see the note in
  [Installation](#installation)).
- **`value of type 'X' has no member 'fake'`.** A property of type `X` fell
  through to the `.fake()` default. Add `@Fakable` to `X`, or pass a value for
  that parameter explicitly.
- **A property is missing from `fake()`.** It most likely has no explicit type
  annotation, or it is computed. See [Diagnostics and Limitations](#diagnostics-and-limitations).

## Documentation

- [Docs index](docs/README.md)
- [Advanced usage and generation rules](docs/advanced-usage.md)
- [Changelog](CHANGELOG.md)
- [Contributing](CONTRIBUTING.md)

## Requirements

- Swift 6.0+
- macOS 10.15+ / iOS 13+ / tvOS 13+ / watchOS 6+ / visionOS 1+

## License

MIT
