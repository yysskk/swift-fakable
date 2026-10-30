import Fakable
import Foundation
import Testing

#if canImport(CoreGraphics)
    import CoreGraphics
#endif

@Suite("Default Value Tests")
struct DefaultValueTests {
    @Test("Text types default to their empty values")
    func textDefaults() {
        let label = TestLabel.fake()

        #expect(label.title == "")
        #expect(label.tail == "")
        #expect(label.initial == " ")
    }

    @Test("Text defaults accept custom values")
    func textCustomValues() {
        let label = TestLabel.fake(title: "Sale", tail: "le", initial: "S")

        #expect(label.title == "Sale")
        #expect(label.tail == "le")
        #expect(label.initial == "S")
    }

    @Test("Collections an array literal builds default to empty")
    func arrayLiteralCollectionDefaults() {
        let buffer = TestBuffer.fake()

        #expect(buffer.page.isEmpty)
        #expect(buffer.storage.isEmpty)
    }

    @Test("Collections an array literal builds accept custom values")
    func arrayLiteralCollectionCustomValues() {
        let buffer = TestBuffer.fake(page: ["a", "b"], storage: [1, 2])

        #expect(buffer.page == ["a", "b"])
        #expect(buffer.storage == [1, 2])
    }

    #if canImport(CoreGraphics)
        @Test("Geometry types default to zero")
        func geometryDefaults() {
            let layout = TestLayout.fake()

            #expect(layout.origin == .zero)
            #expect(layout.size == .zero)
            #expect(layout.frame == .zero)
            #expect(layout.offset == .zero)
        }

        @Test("Geometry types accept custom values")
        func geometryCustomValues() {
            let layout = TestLayout.fake(size: CGSize(width: 10, height: 20))

            #expect(layout.size == CGSize(width: 10, height: 20))
        }
    #endif

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
    @Test("Duration defaults to zero")
    func durationDefault() {
        #expect(TestTiming.fake().animation == .zero)
        #expect(TestTiming.fake(animation: .seconds(2)).animation == .seconds(2))
    }
}
