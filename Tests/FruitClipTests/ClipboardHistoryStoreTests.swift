import Foundation
import Testing

@testable import FruitClip

@Suite("ClipboardHistoryStore Metadata Tests")
struct ClipboardHistoryStoreMetadataTests {
    @Test("Metadata encode/decode round-trip")
    func metadataRoundTrip() throws {
        let items = [
            ClipboardHistoryItem(
                kind: .text, contentHash: "aaa", preview: "Hello", payloadFilename: "1.dat"),
            ClipboardHistoryItem(
                kind: .image, contentHash: "bbb", preview: "Image 50x50",
                payloadFilename: "2.dat"),
        ]

        let encoded = try JSONEncoder().encode(items)
        let decoded = try JSONDecoder().decode([ClipboardHistoryItem].self, from: encoded)

        #expect(decoded.count == 2)
        #expect(decoded[0].kind == .text)
        #expect(decoded[1].kind == .image)
    }

    @Test("Text preview truncation logic")
    func textPreview() {
        let longText = String(repeating: "A", count: 300)
        let lines = longText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let preview = lines.prefix(2).joined(separator: " ")
        let truncated = preview.count > 200 ? String(preview.prefix(200)) + "..." : preview

        #expect(truncated.count == 203)  // 200 chars + "..."
        #expect(truncated.hasSuffix("..."))
    }

    @Test("Dedup check: same hash should be detected")
    func dedupCheck() {
        let data1 = Data("same content".utf8)
        let data2 = Data("same content".utf8)
        let hash1 = ClipboardHistoryItem.computeHash(of: data1)
        let hash2 = ClipboardHistoryItem.computeHash(of: data2)
        #expect(hash1 == hash2)
    }
}
