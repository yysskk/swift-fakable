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
