import Fakable
import Testing

@Suite("Enum Tests")
struct EnumTests {
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
