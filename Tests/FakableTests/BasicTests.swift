import Fakable
import Foundation
import Testing

@Suite("Basic Tests")
struct BasicTests {
    @Test("Struct with basic types creates instance with default values")
    func testBasicStruct() {
        let person = TestPerson.fake()

        #expect(person.name == "")
        #expect(person.age == 0)
        #expect(person.email == nil)
    }

    @Test("Struct with custom values creates instance correctly")
    func testCustomValues() {
        let person = TestPerson.fake(name: "Alice", age: 30, email: "alice@example.com")

        #expect(person.name == "Alice")
        #expect(person.age == 30)
        #expect(person.email == "alice@example.com")
    }

    @Test("Struct with collections uses empty defaults")
    func testCollectionDefaults() {
        let container = TestContainer.fake()

        #expect(container.items.isEmpty)
        #expect(container.metadata.isEmpty)
        #expect(container.count == 0)
    }

    @Test("Struct with collections accepts custom values")
    func testCollectionCustomValues() {
        let container = TestContainer.fake(
            items: ["a", "b", "c"],
            metadata: ["key": 42],
            count: 3
        )

        #expect(container.items == ["a", "b", "c"])
        #expect(container.metadata == ["key": 42])
        #expect(container.count == 3)
    }
    @Test("Struct with longhand collections uses the same defaults as the sugar")
    func testLonghandCollectionDefaults() {
        let container = TestLonghandContainer.fake()

        #expect(container.name == nil)
        #expect(container.items.isEmpty)
        #expect(container.mapping.isEmpty)
        #expect(container.tags.isEmpty)
    }

    @Test("Struct with longhand collections accepts custom values")
    func testLonghandCollectionCustomValues() {
        let container = TestLonghandContainer.fake(
            name: "box",
            items: ["a", "b"],
            mapping: ["key": 42],
            tags: ["new"]
        )

        #expect(container.name == "box")
        #expect(container.items == ["a", "b"])
        #expect(container.mapping == ["key": 42])
        #expect(container.tags == ["new"])
    }

    @Test("Struct with module-qualified types uses the same defaults as the bare names")
    func testModuleQualifiedDefaults() {
        let entry = TestQualifiedEntry.fake()

        #expect(entry.name == "")
        #expect(entry.count == 0)
        #expect(entry.createdAt == Date(timeIntervalSince1970: 0))
        #expect(entry.payload.isEmpty)
        #expect(entry.items.isEmpty)
    }

    @Test("Struct with module-qualified types accepts custom values")
    func testModuleQualifiedCustomValues() {
        let entry = TestQualifiedEntry.fake(name: "entry", count: 7, items: ["a"])

        #expect(entry.name == "entry")
        #expect(entry.count == 7)
        #expect(entry.items == ["a"])
    }

    @Test("Struct with nested collection sugar uses empty defaults")
    func testNestedCollectionDefaults() {
        let container = TestNestedCollectionContainer.fake()

        #expect(container.grouped.isEmpty)
        #expect(container.matrix.isEmpty)
        #expect(container.name == nil)
    }

    @Test("Struct with nested collection sugar accepts custom values")
    func testNestedCollectionCustomValues() {
        let container = TestNestedCollectionContainer.fake(
            grouped: ["a": [1, 2]],
            matrix: [["x"], ["y"]],
            name: "grid"
        )

        #expect(container.grouped == ["a": [1, 2]])
        #expect(container.matrix == [["x"], ["y"]])
        #expect(container.name == "grid")
    }

    @Test("Struct with Foundation value types uses empty defaults")
    func testFoundationValueDefaults() {
        let receipt = TestReceipt.fake()

        #expect(receipt.id.uuidString == "00000000-0000-0000-0000-000000000000")
        #expect(receipt.issuedAt == Date(timeIntervalSince1970: 0))
        #expect(receipt.endpoint == URL(fileURLWithPath: "/"))
        #expect(receipt.payload.isEmpty)
        #expect(receipt.amount == 0)
        #expect(receipt.duration == 0)
        #expect(receipt.tags.isEmpty)
    }

    @Test("Struct with Foundation value types accepts custom values")
    func testFoundationValueCustomValues() {
        let receipt = TestReceipt.fake(
            issuedAt: Date(timeIntervalSince1970: 1_000),
            amount: 1_200,
            tags: ["book", "sale"]
        )

        #expect(receipt.issuedAt == Date(timeIntervalSince1970: 1_000))
        #expect(receipt.amount == 1_200)
        #expect(receipt.tags == ["book", "sale"])
    }

    @Test("Foundation defaults do not change between two fakes")
    func testFoundationValueDefaultsAreDeterministic() {
        #expect(TestSearchKeyword.fake() == TestSearchKeyword.fake())
        #expect(TestReceipt.fake().id == TestReceipt.fake().id)
        #expect(TestReceipt.fake().issuedAt == TestReceipt.fake().issuedAt)
    }

    @Test("Codable model with a Date needs no values of its own")
    func testCodableModelWithDate() {
        let keyword = TestSearchKeyword.fake()

        #expect(keyword.keyword == "")
        #expect(keyword.updateDate == Date(timeIntervalSince1970: 0))
    }

    @Test("Nested structs use .fake() for custom types")
    func testNestedStructs() {
        let nested = TestNested.fake()

        #expect(nested.id == "")
        #expect(nested.status == .active)
        #expect(nested.person.name == "")
        #expect(nested.person.age == 0)
    }

    @Test("Nested structs accept custom nested values")
    func testNestedStructsCustomValues() {
        let customPerson = TestPerson.fake(name: "Charlie", age: 25)
        let nested = TestNested.fake(
            id: "nested-1",
            status: .pending,
            person: customPerson
        )

        #expect(nested.id == "nested-1")
        #expect(nested.status == .pending)
        #expect(nested.person.name == "Charlie")
        #expect(nested.person.age == 25)
    }

    @Test("Multiple instances are independent")
    func testInstanceIndependence() {
        let person1 = TestPerson.fake(name: "Alice")
        let person2 = TestPerson.fake(name: "Bob")

        #expect(person1.name == "Alice")
        #expect(person2.name == "Bob")
        #expect(person1.name != person2.name)
    }

    @Test("Function-typed properties are escaping parameters")
    func testFunctionTypes() {
        var taps = 0
        let handlers = TestHandlers.fake(onTap: { taps += 1 }, onChange: { _ in })

        handlers.onTap()
        handlers.onDone()
        #expect(taps == 1)
        #expect(handlers.onCancel == nil)
    }

    @Test("Tuple, existential and metatype properties are required")
    func testStructuralTypes() {
        let structural = TestStructural.fake(
            pair: (1, "a"),
            shape: TestSquare(),
            kind: TestSquare.self
        )

        #expect(structural.pair == (1, "a"))
        #expect(structural.shape.sides == 4)
        #expect(structural.kind == TestSquare.self)
    }

    @available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    @Test("128-bit integers default to zero")
    func testWideIntegers() {
        let wide = TestWideIntegers.fake()

        #expect(wide.signed == 0)
        #expect(wide.unsigned == 0)
        #expect(TestWideIntegers.fake(signed: -1).signed == -1)
    }

    @Test("Noncopyable struct gets a fake()")
    func testNoncopyable() {
        let token = TestToken.fake(value: "a")

        #expect(token.value == "a")
    }

    @Test("fake() is only available in DEBUG")
    func testDebugOnlyAvailability() {
        #if DEBUG
            // Should compile - fake() is available in DEBUG
            _ = TestPerson.fake()
        #else
            // This test only runs in DEBUG builds
            Issue.record("This test should only run in DEBUG builds")
        #endif
    }
}
