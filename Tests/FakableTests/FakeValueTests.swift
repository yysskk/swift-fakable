import Fakable
import Testing

@Suite("FakeValue Tests")
struct FakeValueTests {
    @Test("@FakeValue sets the default fake() uses")
    func testFakeValueDefaults() {
        let account = TestAccount.fake()

        #expect(account.email == "user@example.com")
        #expect(account.status == .inactive)
        #expect(account.page == 3)
    }

    @Test("An explicit argument still overrides @FakeValue")
    func testExplicitArgument() {
        let account = TestAccount.fake(email: "a@b.c", status: .active, page: 1)

        #expect(account.email == "a@b.c")
        #expect(account.status == .active)
        #expect(account.page == 1)
    }

}
