import Fakable
import Testing

@Suite("Stored Property Tests")
struct StoredPropertyTests {
    @Test("Property observer is a fake() parameter")
    func testPropertyObserver() {
        let counter = TestCounter.fake()

        #expect(counter.id == "")
        #expect(counter.previousCount == 0)
        #expect(counter.count == 0)
        #expect(TestCounter.fake(id: "a", count: 3).count == 3)
    }

    @Test("Property observer does not run while fake() builds the value")
    func testPropertyObserverDuringConstruction() {
        var counter = TestCounter.fake(previousCount: 7, count: 3)

        // didSet does not fire for the initial assignment in an initializer,
        // so the value passed to fake() survives untouched.
        #expect(counter.previousCount == 7)

        counter.count = 9

        #expect(counter.previousCount == 3)
    }

    @Test("Static property is not a fake() parameter")
    func testStaticProperty() {
        #expect(TestConfig.fake().id == "")
        #expect(TestConfig.shared == "shared")
    }

    @Test("Every binding of a declaration is a fake() parameter")
    func testSeveralBindingsPerDeclaration() {
        let origin = TestPoint.fake()

        #expect(origin.x == 0)
        #expect(origin.y == 0)

        let point = TestPoint.fake(x: 1, y: 2)

        #expect(point.x == 1)
        #expect(point.y == 2)
    }

    @Test("Bindings sharing one type annotation are each a fake() parameter")
    func testSharedTypeAnnotation() {
        let size = TestSize.fake(width: 3, height: 4)

        #expect(size.width == 3)
        #expect(size.height == 4)
    }

    @Test("Constant with a value keeps its own value")
    func testInitializedConstant() {
        let versioned = TestVersioned.fake(name: "a", revision: 9)

        #expect(versioned.name == "a")
        #expect(versioned.version == 5)
        #expect(versioned.revision == 9)
    }

    @Test("Computed property is not a fake() parameter")
    func testComputedProperty() {
        #expect(TestComputed.fake(name: "a").label == "a")
    }
}
