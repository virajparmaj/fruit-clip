import Foundation
import Testing

@testable import FruitClip

@Suite("ClipboardHistoryItem Tests")
struct ClipboardHistoryItemTests {
    @Test("Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let item = ClipboardHistoryItem(
            kind: .text,
            contentHash: "abc123",
            preview: "Hello world",
            payloadFilename: "test.dat"
        )

        let encoded = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ClipboardHistoryItem.self, from: encoded)

        #expect(decoded.id == item.id)
        #expect(decoded.kind == item.kind)
        #expect(decoded.contentHash == item.contentHash)
        #expect(decoded.preview == item.preview)
        #expect(decoded.payloadFilename == item.payloadFilename)
    }

    @Test("Content hash is deterministic")
    func hashDeterministic() {
        let data = Data("Hello, FruitClip!".utf8)
        let hash1 = ClipboardHistoryItem.computeHash(of: data)
        let hash2 = ClipboardHistoryItem.computeHash(of: data)
        #expect(hash1 == hash2)
        #expect(hash1.count == 64)  // SHA256 hex
    }

    @Test("Different data produces different hashes")
    func hashDiffers() {
        let hash1 = ClipboardHistoryItem.computeHash(of: Data("aaa".utf8))
        let hash2 = ClipboardHistoryItem.computeHash(of: Data("bbb".utf8))
        #expect(hash1 != hash2)
    }

    @Test("Image kind encodes correctly")
    func imageKindCodable() throws {
        let item = ClipboardHistoryItem(
            kind: .image,
            contentHash: "def456",
            preview: "Image 100x200",
            payloadFilename: "img.dat"
        )
        let encoded = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ClipboardHistoryItem.self, from: encoded)
        #expect(decoded.kind == .image)
    }
}
