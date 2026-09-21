/// A macro that generates a `fake()` factory method for a struct or an enum (DEBUG only).
///
/// Attach `@Fakable` to a model and call `fake()` in tests to build an instance
/// without spelling out every property. Each parameter has a default, so a test
/// only names the values it actually cares about.
///
/// ## Structs
///
/// ```swift
/// @Fakable
/// struct Item {
///     let itemId: String
///     let name: String?
///     let price: Int
/// }
///
/// let item = Item.fake(itemId: "test-id")
/// let another = Item.fake(itemId: "id", price: 500)
/// ```
///
/// The generated `fake(...)` takes one parameter per stored property, in
/// declaration order, defaulted as follows:
///
/// - `String`: `""`
/// - `Int`, `UInt`, and the sized integer types: `0`
/// - `Double`, `Float`, `CGFloat`: `0.0`
/// - `Bool`: `false`
/// - `Array` (`[T]`): `[]`
/// - `Dictionary` (`[K: V]`): `[:]`
/// - `Optional`: `nil`
/// - any other type: `.fake()`, so that type needs `@Fakable` too
///
/// ## Enums
///
/// ```swift
/// @Fakable
/// enum Sex {
///     case man
///     case woman
/// }
///
/// let sex = Sex.fake() // .man
/// ```
///
/// `fake()` returns the first case that has no associated values. When every
/// case has associated values, the first case is used and its values are filled
/// in with the same defaults listed above.
///
/// ## Availability
///
/// The generated method is wrapped in `#if DEBUG`, so it never reaches a release
/// build. Reference it from test targets or debug configurations only.
///
/// - Note: `@Fakable` can only be attached to a struct or an enum. Attaching it
///   to anything else is a compile-time error.
@attached(member, names: named(fake))
public macro Fakable() = #externalMacro(module: "FakableMacros", type: "FakableMacro")
