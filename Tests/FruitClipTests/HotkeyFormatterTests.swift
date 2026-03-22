import Foundation
import Testing

@testable import FruitClip

@Suite("HotkeyFormatter Tests")
struct HotkeyFormatterTests {
    @Test("Format Cmd+Shift+V produces correct symbols")
    func formatCmdShiftV() {
        // cmdKey = 0x0100, shiftKey = 0x0200
        let result = HotkeyFormatter.format(keyCode: 0x09, modifiers: 0x0100 | 0x0200)
        #expect(result.contains("\u{21E7}"))  // Shift symbol
        #expect(result.contains("\u{2318}"))  // Cmd symbol
        #expect(result.contains("V"))
    }

    @Test("Unknown key code shows question mark")
    func unknownKeyCode() {
        let result = HotkeyFormatter.keyCodeToString(0xFF)
        #expect(result == "?")
    }

    @Test("All four modifier symbols present when all flags set")
    func allModifiers() {
        // controlKey=0x1000, optionKey=0x0800, shiftKey=0x0200, cmdKey=0x0100
        let result = HotkeyFormatter.format(
            keyCode: 0x09,
            modifiers: 0x1000 | 0x0800 | 0x0200 | 0x0100)
        #expect(result.contains("^"))         // Control
        #expect(result.contains("\u{2325}"))  // Option
        #expect(result.contains("\u{21E7}"))  // Shift
        #expect(result.contains("\u{2318}"))  // Cmd
    }

    @Test("F-keys and arrow keys are recognized")
    func specialKeys() {
        #expect(HotkeyFormatter.keyCodeToString(0x7A) == "F1")
        #expect(HotkeyFormatter.keyCodeToString(0x78) == "F2")
        #expect(HotkeyFormatter.keyCodeToString(0x6F) == "F12")
        #expect(HotkeyFormatter.keyCodeToString(0x7E) == "\u{2191}")  // Up arrow
        #expect(HotkeyFormatter.keyCodeToString(0x7D) == "\u{2193}")  // Down arrow
        #expect(HotkeyFormatter.keyCodeToString(0x7B) == "\u{2190}")  // Left arrow
        #expect(HotkeyFormatter.keyCodeToString(0x7C) == "\u{2192}")  // Right arrow
    }
}
