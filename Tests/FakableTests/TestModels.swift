import Fakable

// The models every runtime suite in this target builds fixtures from.

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

@Fakable(condition: .always)
struct TestAlwaysFaked {
    let id: String
}

@Fakable(condition: .custom("FAKABLE_RUNTIME_TEST_CONDITION"))
struct TestConditionallyFaked {
    let id: String
}
