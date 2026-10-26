import Fakable
import Foundation

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
struct TestPaged {
    static let firstPage = 1

    var page: Int = Self.firstPage
    var note: String? = "draft"
}

@Fakable
public struct TestPublicDefaults {
    static let firstPage = 1

    public var limit: Int = 20
    public var tags: [String] = ["a"]
    public var page: Int = Self.firstPage
}

protocol TestShape {
    var sides: Int { get }
}

struct TestSquare: TestShape {
    var sides: Int { 4 }
}

@Fakable
struct TestHandlers {
    static func ignore() {}

    let onTap: () -> Void
    let onChange: @Sendable (Int) -> Void
    var onDone: () -> Void = Self.ignore
    var onCancel: (() -> Void)?
}

@Fakable
struct TestStructural {
    let pair: (Int, String)
    let shape: any TestShape
    let kind: TestSquare.Type
}

@Fakable
struct TestNormalized {
    let name: String
    let count: Int

    init(name: String, count: Int) {
        self.name = name.lowercased()
        self.count = max(count, 0)
    }
}

@Fakable
struct TestExtensionInitialized {
    let name: String
}

extension TestExtensionInitialized {
    init(title: String) {
        self.init(name: title)
    }
}

@Fakable
struct TestConditionalMembers {
    let name: String
    #if FAKABLE_RUNTIME_TEST_CONDITION
    let flagged: Bool
    #else
    let unflagged: Int
    #endif
    #if NEVER_DEFINED_IN_FAKABLE_TESTS
    let neverPresent: String
    #endif
}

@Fakable
struct TestAccount {
    @FakeValue("user@example.com")
    let email: String
    @FakeValue(TestStatus.inactive)
    let status: TestStatus
    @FakeValue(3)
    var page: Int = 1
}

@Fakable
enum TestConnection: Equatable {
    case unknown
    @FakeCase
    case connected(host: String, port: Int)
    case disconnected
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

@Fakable
struct TestSearchKeyword: Codable, Equatable, Sendable {
    let keyword: String
    let updateDate: Date
}

@Fakable
struct TestReceipt {
    let id: UUID
    let issuedAt: Date
    let endpoint: URL
    let payload: Data
    let amount: Decimal
    let duration: TimeInterval
    let tags: Set<String>
}

@Fakable
struct TestLonghandContainer {
    let name: Optional<String>
    let items: Array<String>
    let mapping: Dictionary<String, Int>
    let tags: Set<String>
}

@Fakable
struct TestQualifiedEntry {
    let name: Swift.String
    let count: Swift.Int
    let createdAt: Foundation.Date
    let payload: Foundation.Data
    let items: Swift.Array<Swift.String>
}

@Fakable
struct TestNestedCollectionContainer {
    let grouped: [String: [Int]]
    let matrix: [[String]]
    let name: String!
}
