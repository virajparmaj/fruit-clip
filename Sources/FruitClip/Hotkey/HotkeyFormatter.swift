import Carbon
import Foundation

enum HotkeyFormatter {
    static func format(keyCode: UInt32, modifiers: UInt32) -> String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("^") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("\u{2325}") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("\u{21E7}") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("\u{2318}") }
        parts.append(keyCodeToString(keyCode))
        return parts.joined()
    }

    static func format(_ shortcut: ShortcutConfiguration?) -> String {
        guard let shortcut else { return "Set Shortcut" }
        return format(keyCode: shortcut.keyCode, modifiers: shortcut.modifiers)
    }

    static func keyCodeToString(_ keyCode: UInt32) -> String {
        let keyMap: [UInt32: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H",
            0x05: "G", 0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V",
            0x0A: "§", 0x0B: "B", 0x0C: "Q", 0x0D: "W", 0x0E: "E",
            0x0F: "R", 0x10: "Y", 0x11: "T", 0x12: "1", 0x13: "2",
            0x14: "3", 0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=",
            0x19: "9", 0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0",
            0x1E: "]", 0x1F: "O", 0x20: "U", 0x21: "[", 0x22: "I",
            0x23: "P", 0x24: "\u{23CE}", 0x25: "L", 0x26: "J",
            0x27: "'", 0x28: "K", 0x29: ";", 0x2A: "\\", 0x2B: ",",
            0x2C: "/", 0x2D: "N", 0x2E: "M", 0x2F: ".",
            0x30: "\u{21E5}", 0x31: "Space", 0x32: "`",
            0x33: "\u{232B}", 0x35: "\u{238B}",
            // F-keys
            0x7A: "F1", 0x78: "F2", 0x63: "F3", 0x76: "F4",
            0x60: "F5", 0x61: "F6", 0x62: "F7", 0x64: "F8",
            0x65: "F9", 0x6D: "F10", 0x67: "F11", 0x6F: "F12",
            // Arrow keys
            0x7B: "\u{2190}", 0x7C: "\u{2192}",
            0x7D: "\u{2193}", 0x7E: "\u{2191}",
            // Navigation
            0x73: "Home", 0x77: "End",
            0x74: "PgUp", 0x79: "PgDn",
        ]
        return keyMap[keyCode] ?? "?"
    }

    static func normalizedKeyToken(for keyCode: UInt32) -> String {
        switch keyCodeToString(keyCode) {
        case "Space": " "
        default: keyCodeToString(keyCode).lowercased()
        }
    }

    static func cocoaToCarbonModifiers(_ flags: UInt) -> UInt32 {
        var carbon: UInt32 = 0
        let deviceIndependent = flags & 0xFFFF0000
        if deviceIndependent & (1 << 20) != 0 { carbon |= UInt32(cmdKey) }    // NSEvent.ModifierFlags.command
        if deviceIndependent & (1 << 17) != 0 { carbon |= UInt32(shiftKey) }  // NSEvent.ModifierFlags.shift
        if deviceIndependent & (1 << 19) != 0 { carbon |= UInt32(optionKey) } // NSEvent.ModifierFlags.option
        if deviceIndependent & (1 << 18) != 0 { carbon |= UInt32(controlKey) } // NSEvent.ModifierFlags.control
        return carbon
    }
}
