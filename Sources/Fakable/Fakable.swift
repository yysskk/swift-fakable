/// Generates a `fake()` factory method for a struct or an enum.
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
///     let itemID: String
///     let name: String?
///     let price: Int
/// }
///
/// let item = Item.fake(itemID: "test-id")
/// let another = Item.fake(itemID: "id", price: 500)
/// ```
///
/// The generated `fake(...)` takes one parameter per stored property, in
/// declaration order. A `var` that declares its own value defaults to that
/// value; a `public` `fake()` uses it only when it is a literal, since its
/// default arguments may reference only public declarations. Every other
/// parameter is defaulted by its type:
///
/// - `String` and `Substring`: `""`; `Character`: `" "`
/// - `Int`, `UInt`, and the sized integer types, `Int128` and `UInt128`
///   included: `0`
/// - `Double`, `Float`, `Float16`, `CGFloat`, `TimeInterval`: `0.0`
/// - `Bool`: `false`
/// - `Decimal`: `0`
/// - `Date`: the epoch; `UUID`: the nil UUID; `URL`: `URL(fileURLWithPath: "/")`;
///   `Data`: `Data()`
/// - `Duration`: `.zero`; `CGPoint`, `CGSize`, `CGRect`, `CGVector`: the zero
///   value, written as `CGPoint()` and so on
/// - `Array` (`[T]`), `ArraySlice`, `ContiguousArray`, and `Set` (`Set<T>`): `[]`
/// - `Dictionary` (`[K: V]`): `[:]`
/// - `Optional`: `nil`
/// - a closure, tuple, `any P`, `P & Q`, or metatype: no default, so the
///   parameter is required; a closure is marked `@escaping`
/// - any other named type: `.fake()`, so that type needs `@Fakable` too, or a
///   ``FakeProvider`` conformance where the macro cannot be attached to it
///
/// ## Enums
///
/// ```swift
/// @Fakable
/// enum Status {
///     case active
///     case inactive
/// }
///
/// let status = Status.fake() // .active
/// ```
///
/// `fake()` returns the case marked ``FakeCase()``, or else the first case that
/// has no associated values. When every case has associated values, the first
/// one whose values can all be written is used, filled in with the same
/// defaults listed above.
///
/// ## Availability
///
/// The generated method is wrapped in `#if DEBUG` by default, so it never
/// reaches a release build. Reference it from test targets or debug
/// configurations only.
///
/// Pass a ``FakeCompilationCondition`` to guard it with a flag of your own, or
/// to emit it in every configuration:
///
/// ```swift
/// @Fakable(condition: .custom("FAKING"))
/// struct Order { ... }        // fake() wrapped in #if FAKING
///
/// @Fakable(condition: .always)
/// struct Preview { ... }      // fake() with no #if guard
/// ```
///
/// - Note: `@Fakable` can only be attached to a struct or an enum. Attaching it
///   to anything else is a compile-time error, and so is a struct whose body
///   declares an `init` other than one taking exactly its stored properties,
///   since `fake()` calls the memberwise initializer. A struct with no stored
///   properties and an enum with no cases warn instead, since the attribute
///   had nothing to do.
/// - Parameter condition: The compilation condition that guards the generated
///   method. Defaults to ``FakeCompilationCondition/debug``. It has to be
///   written literally at the attachment site (`.debug`, `.always`, or
///   `.custom("FLAG")` with a string literal).
@attached(member, names: named(fake))
public macro Fakable(
    condition: FakeCompilationCondition = .debug
) = #externalMacro(module: "FakableMacros", type: "FakableMacro")

/// Sets the value a `@Fakable` struct's `fake()` defaults this property to.
///
/// Use it when the type's default is not a useful starting point, or when the
/// property is a `let` and so cannot declare a value of its own:
///
/// ```swift
/// @Fakable
/// struct User {
///     @FakeValue("user@example.com")
///     let email: String
///     @FakeValue(Role.member)
///     let role: Role
/// }
///
/// User.fake().email // "user@example.com"
/// ```
///
/// The value is written into `fake()` as a default argument, exactly as given,
/// and takes precedence over both a declared value and the type's default.
/// Like any attached peer macro, it applies to a declaration of one property,
/// so split `let width, height: Int` to give each its own value.
///
/// - Note: The value is type-checked on its own, before the property's type is
///   known, so it has to have a type of its own: an implicit member such as
///   `.member` has to name its type, as in `Role.member`, and a bare `[]` or
///   `nil` does not compile (those are the defaults already). A `public`
///   `fake()` emits its default arguments into its callers, so the value may
///   reference only public declarations there.
/// - Parameter value: The value `fake()` uses when the caller passes none.
@attached(peer)
public macro FakeValue<Value>(
    _ value: Value
) = #externalMacro(module: "FakableMacros", type: "FakeValueMacro")

/// Selects the case a `@Fakable` enum's `fake()` returns.
///
/// Without it, `fake()` returns the first case that has no associated values.
/// Mark another case when that is not a useful starting point:
///
/// ```swift
/// @Fakable
/// enum Status {
///     case unknown
///     @FakeCase
///     case active
///     case inactive
/// }
///
/// Status.fake() // .active
/// ```
///
/// A marked case with associated values gets them filled in from their types,
/// the same way an unmarked one does, and is an error when one of them has no
/// value the macro can write.
///
/// - Note: Mark at most one case, on a declaration of its own:
///   `@FakeCase case active, inactive` would not say which one is meant.
///   Cases inside `#if` are not considered, so a marker there warns.
@attached(peer)
public macro FakeCase() = #externalMacro(
    module: "FakableMacros",
    type: "FakeCaseMacro"
)
