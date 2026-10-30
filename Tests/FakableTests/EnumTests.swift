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

    @Test("Case marked @FakeCase is what fake() returns")
    func testFakeCase() {
        #expect(TestConnection.fake() == .connected(host: "", port: 0))
    }

    @Test("An associated value can be overridden by its label")
    func testOverridingALabeledAssociatedValue() {
        let value = TestOnlyAssociatedValues.fake(id: "user-1")

        if case .user(let id) = value {
            #expect(id == "user-1")
        } else {
            Issue.record("Expected .user(id: \"user-1\"), got \(value)")
        }
    }

    @Test("An unlabeled associated value is overridden positionally")
    func testOverridingAnUnlabeledAssociatedValue() {
        #expect(TestMeasurement.fake() == .point(0, unit: ""))
        #expect(TestMeasurement.fake(7) == .point(7, unit: ""))
        #expect(TestMeasurement.fake(7, unit: "cm") == .point(7, unit: "cm"))
    }

    @Test("The marked case's associated values are overridable too")
    func testOverridingAMarkedCaseValue() {
        #expect(TestConnection.fake(host: "example.com") == .connected(host: "example.com", port: 0))
        #expect(TestConnection.fake(port: 8080) == .connected(host: "", port: 8080))
    }
}
