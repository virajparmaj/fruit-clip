import Foundation
import Testing

@testable import FruitClip

@Suite("ResourceLoader Tests")
struct ResourceLoaderTests {
    @Test("Status icon resources resolve safely")
    func statusIconsResolve() {
        let url1x = ResourceLoader.url(forResource: "fruit-clip-status", withExtension: "png")
        #expect(url1x != nil)
        if let url1x {
            #expect(FileManager.default.fileExists(atPath: url1x.path))
        }

        let url2x = ResourceLoader.url(forResource: "fruit-clip-status@2x", withExtension: "png")
        #expect(url2x != nil)
        if let url2x {
            #expect(FileManager.default.fileExists(atPath: url2x.path))
        }
    }

    @Test("App icon resource resolves safely")
    func appIconResolves() {
        let url = ResourceLoader.url(forResource: "fruit-clip", withExtension: "png")
        #expect(url != nil)
        if let url {
            #expect(FileManager.default.fileExists(atPath: url.path))
        }
    }

    @Test("Missing resource returns nil without crashing")
    func missingResourceReturnsNil() {
        let url = ResourceLoader.url(forResource: "nonexistent-resource-file", withExtension: "png")
        #expect(url == nil)
    }
}
