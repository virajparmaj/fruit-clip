import AppKit
import ApplicationServices

enum PermissionsManager {
    static func isAccessibilityGranted(prompt: Bool = false) -> Bool {
        // Use string literal to avoid Swift 6 concurrency issue with C global
        let options = ["AXTrustedCheckOptionPrompt": prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func openAccessibilitySettings() {
        let url = URL(
            string:
                "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        )!
        NSWorkspace.shared.open(url)
    }
}
