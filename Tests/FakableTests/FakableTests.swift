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

@Fakable
struct TestCounter {
    let id: String
    var previousCount: Int
    var count: Int {
        didSet {
            previousCount = oldValue
        }
    }
}

@Fakable
struct TestConfig {
    static let shared: String = "shared"
    let id: String
}

@Fakable
struct TestPoint {
    let x: Int, y: Int
}

@Fakable
struct TestSize {
    let width, height: Int
}

@Fakable
struct TestVersioned {
    let name: String
    let version: Int = 5
    var revision: Int = 7
}

@Fakable
struct TestComputed {
    let name: String
    var label: String {
        name
    }
}

@Fakable
struct TestBox<T> {
    let value: T
    let label: String
}

@Fakable
struct TestBag<Element> {
    let items: [Element]
    let first: Element?
}

@Fakable
enum TestEither<T: Equatable>: Equatable {
    case some(T)
    case none
}

@Fakable
enum TestWrapped<T: Equatable>: Equatable {
    case value(T)
    case count(Int)
}

@Fakable
package struct TestPackaged {
    package let id: String
}

@Fakable
package enum TestPackagedStatus: Equatable {
    case active
    case inactive
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

    @Test("Package struct generates a package fake()")
    func testPackageAccessLevel() {
        #expect(TestPackaged.fake(id: "a").id == "a")
    }

    @Test("Package enum generates a package fake()")
    func testPackageEnumAccessLevel() {
        #expect(TestPackagedStatus.fake() == .active)
    }
}
