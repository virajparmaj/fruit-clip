import Foundation
import Testing

@testable import FruitClip

@Suite("Elapsed String Tests")
struct ElapsedStringTests {
    @Test("Less than one minute shows <1m")
    func lessThanOneMinute() {
        let result = elapsedString(from: Date())
        #expect(result == "<1m")
    }

    @Test("Minutes shown for 1-59 minute range")
    func minutes() {
        let date = Date().addingTimeInterval(-5 * 60)
        let result = elapsedString(from: date)
        #expect(result == "5m")
    }

    @Test("Hours shown for 1-23 hour range")
    func hours() {
        let date = Date().addingTimeInterval(-2 * 3600)
        let result = elapsedString(from: date)
        #expect(result == "2h")
    }

    @Test("Days shown for 24+ hours")
    func days() {
        let date = Date().addingTimeInterval(-3 * 86400)
        let result = elapsedString(from: date)
        #expect(result == "3d")
    }

    @Test("Boundary: 59 minutes shows 59m, 60 minutes shows 1h")
    func exactBoundaries() {
        let at59m = elapsedString(from: Date().addingTimeInterval(-59 * 60))
        #expect(at59m == "59m")

        let at60m = elapsedString(from: Date().addingTimeInterval(-60 * 60))
        #expect(at60m == "1h")

        let at24h = elapsedString(from: Date().addingTimeInterval(-24 * 3600))
        #expect(at24h == "1d")
    }
}
