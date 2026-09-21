import Fakable
import Testing

@Suite("Generic Tests")
struct GenericTests {
    @Test("Generic property is a required fake() parameter")
    func testGenericProperty() {
        let box = TestBox.fake(value: 42)

        #expect(box.value == 42)
        #expect(box.label == "")
        #expect(TestBox<String>.fake(value: "x", label: "l").label == "l")
    }

    @Test("Collections and optionals of a generic parameter keep their default")
    func testGenericCollections() {
        let bag = TestBag<Int>.fake()

        #expect(bag.items.isEmpty)
        #expect(bag.first == nil)
        #expect(TestBag.fake(items: [1, 2], first: 1).items == [1, 2])
    }

    @Test("Generic enum returns the case without associated values")
    func testGenericEnum() {
        #expect(TestEither<Int>.fake() == .none)
    }

    @Test("Generic enum skips a case whose value cannot be written")
    func testPartlyWritableGenericEnum() {
        #expect(TestWrapped<String>.fake() == .count(0))
    }
}
