import Fakable
import Testing

// Declared here rather than in TestModels.swift: a private type is visible only
// in its own file, and the point is that its fake() is callable from the rest
// of that file.
@Fakable
private struct PrivateItem {
    let name: String
}

@Fakable
private enum PrivateStatus {
    case idle
    case running
}

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

    @Test("Private struct's fake() is callable from the rest of the file")
    func testPrivateStruct() {
        #expect(PrivateItem.fake().name == "")
        #expect(PrivateItem.fake(name: "a").name == "a")
    }

    @Test("Private enum's fake() is callable from the rest of the file")
    func testPrivateEnum() {
        #expect(PrivateStatus.fake() == .idle)
    }
}
