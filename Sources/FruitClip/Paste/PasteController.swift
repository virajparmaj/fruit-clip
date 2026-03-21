import AppKit
import CoreGraphics
import Foundation
import os

@MainActor
final class PasteController {
    private let historyStore: ClipboardHistoryStore
    private let logger = Logger(subsystem: "com.veer.FruitClip", category: "PasteController")
    private var hasShownAccessibilityAlert = false

    init(historyStore: ClipboardHistoryStore) {
        self.historyStore = historyStore
    }

    func pasteItem(_ item: ClipboardHistoryItem, previousApp: NSRunningApplication?) {
        guard let data = historyStore.loadPayload(for: item) else {
            logger.error("Failed to load payload for item: \(item.id)")
            return
        }

        restoreToClipboard(item: item, data: data)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { @MainActor in
            if let app = previousApp {
                app.activate()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { @MainActor in
                self.synthesizePaste()
            }
        }
    }

    private func restoreToClipboard(item: ClipboardHistoryItem, data: Data) {
        let pasteboard = NSPasteboard.general
        historyStore.isWritingToPasteboard = true

        pasteboard.clearContents()

        switch item.kind {
        case .text:
            if let string = String(data: data, encoding: .utf8) {
                pasteboard.setString(string, forType: .string)
            }
        case .image:
            pasteboard.setData(data, forType: .tiff)
        }

        historyStore.lastSelfChangeCount = pasteboard.changeCount
        historyStore.isWritingToPasteboard = false
    }

    private func synthesizePaste() {
        guard PermissionsManager.isAccessibilityGranted(prompt: false) else {
            if !hasShownAccessibilityAlert {
                hasShownAccessibilityAlert = true
                showAccessibilityAlert()
            }
            return
        }

        let source = CGEventSource(stateID: .hidSystemState)

        // Key code 0x09 = V
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        else { return }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText =
            "FruitClip needs Accessibility permission to auto-paste into other apps.\n\n"
            + "The selected item has been copied to your clipboard. You can paste manually with Cmd+V.\n\n"
            + "To enable auto-paste, go to System Settings > Privacy & Security > Accessibility and add FruitClip."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "OK")

        if alert.runModal() == .alertFirstButtonReturn {
            PermissionsManager.openAccessibilitySettings()
        }
    }
}
