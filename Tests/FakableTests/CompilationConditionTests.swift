import Fakable
import Testing

@Suite("Compilation Condition Tests")
struct CompilationConditionTests {
    @Test("Unguarded fake() is available in every configuration")
    func testAlwaysCondition() {
        #expect(TestAlwaysFaked.fake(id: "a").id == "a")
    }

    @Test("Custom condition guards fake() behind its own flag")
    func testCustomCondition() {
        #expect(TestConditionallyFaked.fake(id: "a").id == "a")
    }
}
