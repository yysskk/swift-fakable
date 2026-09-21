# Getting Started

Add the package, attach the macro, and call `fake()` from your tests.

## Installation

Add `swift-fakable` to your package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/yysskk/swift-fakable.git", from: "0.1.0")
]
```

Then add the `Fakable` library to any target that declares fixtures:

```swift
.target(
    name: "YourTarget",
    dependencies: ["Fakable"]
)
```

The first time you build a target that uses `@Fakable`, Xcode shows a
"trust macro" prompt. Choose **Trust & Enable**. On the command line,
`swift build` runs macros without prompting.

## Faking a struct

Attach ``Fakable()`` to a struct. The macro adds one `fake()` parameter per
stored property, in declaration order:

```swift
import Fakable

@Fakable
struct Person {
    let name: String
    let age: Int
}
```

```swift
let anyone = Person.fake()            // name: "", age: 0
let adult = Person.fake(age: 30)      // name: "", age: 30
```

Each default comes from the property's type: `""` for `String`, `0` for the
integer types, `0.0` for the floating-point types, `false` for `Bool`, `[]` and
`[:]` for arrays and dictionaries, and `nil` for anything optional.

## Faking an enum

On an enum, `fake()` takes no parameters and returns a representative case:

```swift
@Fakable
enum Status {
    case active
    case inactive
}

let status = Status.fake()   // .active
```

A case without associated values is preferred, wherever it appears. When every
case has associated values, the first case is used and its values are defaulted
the same way a struct's properties are.

## Composing models

Any type the default table does not recognize resolves to `.fake()`, so nested
models compose as long as each one is also `@Fakable`:

```swift
@Fakable
struct Address {
    let city: String
}

@Fakable
struct User {
    let name: String
    let address: Address    // defaults to Address.fake()
}

let user = User.fake(address: .fake(city: "Tokyo"))
```

## Where `fake()` exists

The generated method lives inside `#if DEBUG`. It is available to test targets
and debug builds, and absent from release builds. If the compiler cannot find
`fake()`, check the configuration you are building.

## Next steps

Read <doc:AdvancedUsage> for the full generation rules: which properties are
included, how the enum case is chosen, and how access levels are propagated.
