import Fakable
import Testing

// Test models for runtime verification

@Fakable
struct TestPerson {
    let name: String
    let age: Int
    let email: String?
}

@Fakable
public struct TestUser {
    let id: String
    let name: String
    let isAdmin: Bool
}

@Fakable
enum TestStatus {
    case active
    case inactive
    case pending
}

@Fakable
public enum TestUserRole {
    case user(id: String)
    case guest
    case admin(id: String, level: Int)
}

@Fakable
enum TestOnlyAssociatedValues {
    case user(id: String)
    case admin(id: String, level: Int)
}

@Fakable
enum TestSingleCase {
    case only
}

@Fakable
struct TestContainer {
    let items: [String]
    let metadata: [String: Int]
    let count: Int
}

@Fakable
struct TestNested {
    let id: String
    let status: TestStatus
    let person: TestPerson
}

// Runtime tests

@Suite("Fakable Runtime Tests")
struct FakableRuntimeTests {

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

    @Test("Public struct generates accessible fake() method")
    func testPublicStruct() {
        let user = TestUser.fake()

        #expect(user.id == "")
        #expect(user.name == "")
        #expect(user.isAdmin == false)
    }

    @Test("Public struct with custom values")
    func testPublicStructCustomValues() {
        let user = TestUser.fake(id: "123", name: "Bob", isAdmin: true)

        #expect(user.id == "123")
        #expect(user.name == "Bob")
        #expect(user.isAdmin == true)
    }

    @Test("Enum generates fake() returning first case")
    func testEnumFirstCase() {
        let status = TestStatus.fake()

        #expect(status == .active)
    }

    @Test("Public enum with associated values returns first parameter-less case")
    func testPublicEnumWithAssociatedValues() {
        let role = TestUserRole.fake()

        if case .guest = role {
            // Success - first parameter-less case is guest
        } else {
            Issue.record("Expected .guest, got \(role)")
        }
    }

    @Test("Enum with only associated values generates fake() with default parameters")
    func testEnumWithOnlyAssociatedValues() {
        // TestOnlyAssociatedValues now generates fake() with default parameters
        let value = TestOnlyAssociatedValues.fake()

        // Should return the first case with default parameter values
        if case .user(let id) = value {
            #expect(id == "", "Expected default empty string for id parameter")
        } else {
            Issue.record("Expected .user(id: \"\"), got \(value)")
        }
    }

    @Test("Enum with single case works correctly")
    func testSingleCaseEnum() {
        let singleCase = TestSingleCase.fake()

        #expect(singleCase == .only)
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

    @Test("Enum with multiple associated value parameters generates correct defaults")
    func testEnumWithMultipleParameters() {
        // Create an enum with multiple associated value parameters
        @Fakable
        enum TestResult {
            case success(value: Int, message: String, isValid: Bool)
            case failure(error: String, code: Int)
        }

        let result = TestResult.fake()

        // Should return the first case with default parameter values
        if case .success(let value, let message, let isValid) = result {
            #expect(value == 0, "Expected default 0 for Int parameter")
            #expect(message == "", "Expected default empty string for String parameter")
            #expect(isValid == false, "Expected default false for Bool parameter")
        } else {
            Issue.record("Expected .success(value: 0, message: \"\", isValid: false), got \(result)")
        }
    }
}
