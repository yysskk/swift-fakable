/// A type that can build a fake instance of itself.
///
/// `fake()` defaults a parameter of any other named type to `.fake()`, so a
/// nested model composes as long as that type has a `fake()` of its own.
/// `@Fakable` writes one for the structs and enums you own. `FakeProvider` is
/// the same contract spelled out, for the types you cannot attach the macro
/// to: a type from another module, a class, or an actor.
///
/// ```swift
/// import CoreLocation
///
/// extension CLLocationCoordinate2D: FakeProvider {
///     public static func fake() -> Self {
///         Self(latitude: 0, longitude: 0)
///     }
/// }
///
/// @Fakable
/// struct Place {
///     let name: String
///     let coordinate: CLLocationCoordinate2D   // defaults to .fake()
/// }
/// ```
///
/// Conforming is not what makes `.fake()` resolve — the macro reads syntax and
/// never resolves types, so any `static func fake() -> Self` in scope works.
/// What the protocol adds is a name for the contract, a compile-time check that
/// the method has the shape `fake()` expects, and generic code that can build a
/// value of an unknown type:
///
/// ```swift
/// func fakes<Element: FakeProvider>(_ count: Int) -> [Element] {
///     (0..<count).map { _ in Element.fake() }
/// }
/// ```
///
/// Return a value that does not change between two calls, the way the macro's
/// own defaults do. Two fakes of the same type are then equal, and a test that
/// compares them does not depend on when it ran.
///
/// - Note: A `@Fakable` struct or enum does not conform on its own. Its
///   `fake()` is guarded by a ``FakeCompilationCondition``, while a conformance
///   holds in every configuration, and a struct's `fake()` takes one defaulted
///   parameter per stored property, which does not satisfy a requirement
///   written `fake()`. Nothing needs the conformance for `.fake()` to resolve.
public protocol FakeProvider {
    /// A fake instance to start from.
    static func fake() -> Self
}
