import Fakable
import Testing

@Suite("Conditional Member Tests")
struct ConditionalMemberTests {
    @Test("fake() takes the properties of the active configuration")
    func testActiveConfiguration() {
        let item = TestConditionalMembers.fake(name: "a", flagged: true)

        #expect(item.name == "a")
        #expect(item.flagged)
    }

    @Test("Properties of the active configuration take their defaults")
    func testActiveConfigurationDefaults() {
        let item = TestConditionalMembers.fake()

        #expect(item.name == "")
        #expect(item.flagged == false)
    }
}
