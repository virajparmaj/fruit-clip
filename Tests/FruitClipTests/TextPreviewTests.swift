import Foundation
import Testing

@testable import FruitClip

@Suite("Text Preview Tests")
struct TextPreviewTests {
    @Test("Short text remains unchanged")
    func shortTextUnchanged() {
        let result = ClipboardHistoryStore.makeTextPreview("hello")
        #expect(result == "hello")
    }

    @Test("Multiline collapses to first two non-empty lines")
    func multilineCollapsesToTwoLines() {
        let result = ClipboardHistoryStore.makeTextPreview("line1\nline2\nline3")
        #expect(result == "line1 line2")
    }

    @Test("Long text truncates at 200 characters with ellipsis")
    func longTextTruncatesAt200() {
        let longText = String(repeating: "A", count: 300)
        let result = ClipboardHistoryStore.makeTextPreview(longText)
        #expect(result.count == 203)  // 200 + "..."
        #expect(result.hasSuffix("..."))
    }

    @Test("Blank lines are stripped")
    func blankLinesStripped() {
        let result = ClipboardHistoryStore.makeTextPreview("a\n\n\nb")
        #expect(result == "a b")
    }

    @Test("Whitespace-only input produces empty string")
    func whitespaceOnlyInput() {
        let result = ClipboardHistoryStore.makeTextPreview("   \n   ")
        #expect(result == "")
    }

    @Test("Empty string produces empty preview")
    func emptyStringPreview() {
        let result = ClipboardHistoryStore.makeTextPreview("")
        #expect(result == "")
    }
}
