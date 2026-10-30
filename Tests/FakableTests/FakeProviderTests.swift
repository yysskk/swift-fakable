import Fakable
import Testing

/// Generic code that builds values without knowing their type, which is what
/// the protocol makes possible.
private func fakes<Element: FakeProvider>(_ count: Int) -> [Element] {
    (0..<count).map { _ in Element.fake() }
}

@Suite("Fake Provider Tests")
struct FakeProviderTests {
    @Test("A provider fills the parameter of a model that nests it")
    func providerFillsNestedParameter() {
        let place = TestPlace.fake()

        #expect(place.name == "")
        #expect(place.coordinate == TestCoordinate.fake())
        #expect(place.pool.name == "")
    }

    @Test("A nested provider value can still be passed explicitly")
    func providerParameterAcceptsCustomValue() {
        let place = TestPlace.fake(coordinate: TestCoordinate(latitude: 35, longitude: 139))

        #expect(place.coordinate == TestCoordinate(latitude: 35, longitude: 139))
    }

    @Test("A provider's fake() does not change between two calls")
    func providerIsDeterministic() {
        #expect(TestCoordinate.fake() == TestCoordinate.fake())
    }

    @Test("Generic code builds values through the protocol")
    func genericCodeBuildsValues() {
        let coordinates: [TestCoordinate] = fakes(2)

        #expect(coordinates == [TestCoordinate.fake(), TestCoordinate.fake()])
    }

    @Test("A class conforms as well, which @Fakable cannot generate")
    func classProvider() {
        let pools: [TestConnectionPool] = fakes(1)

        #expect(pools.count == 1)
        #expect(pools[0].name == "")
    }
}
