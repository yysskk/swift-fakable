import Fakable
import Testing

@Suite("Access Level Tests")
struct AccessLevelTests {
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

    @Test("Package struct generates a package fake()")
    func testPackageAccessLevel() {
        #expect(TestPackaged.fake(id: "a").id == "a")
    }

    @Test("Package enum generates a package fake()")
    func testPackageEnumAccessLevel() {
        #expect(TestPackagedStatus.fake() == .active)
    }
}
