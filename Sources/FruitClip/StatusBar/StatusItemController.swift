import AppKit

@MainActor
final class StatusItemController {
    private let statusItem: NSStatusItem
    private let onOpenClipboard: () -> Void
    private let onPreferences: () -> Void
    private let onTogglePause: () -> Void
    private let onClearHistory: () -> Void
    private let onQuit: () -> Void
    private let settingsStore: SettingsStore

    init(
        onOpenClipboard: @escaping () -> Void,
        onPreferences: @escaping () -> Void,
        onTogglePause: @escaping () -> Void,
        onClearHistory: @escaping () -> Void,
        onQuit: @escaping () -> Void,
        settingsStore: SettingsStore
    ) {
        self.onOpenClipboard = onOpenClipboard
        self.onPreferences = onPreferences
        self.onTogglePause = onTogglePause
        self.onClearHistory = onClearHistory
        self.onQuit = onQuit
        self.settingsStore = settingsStore

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            if let image = StatusItemController.loadStatusIcon() {
                image.size = NSSize(width: 22, height: 22)
                button.image = image
            } else {
                button.image = nil
            }
            button.imageScaling = .scaleProportionallyDown
        }

        buildMenu()
    }

    private static func loadStatusIcon() -> NSImage? {
        guard let url1x = Bundle.module.url(forResource: "fruit-clip-status", withExtension: "png"),
              let image = NSImage(contentsOf: url1x) else {
            let fallback = NSImage(systemSymbolName: "paperclip", accessibilityDescription: "FruitClip")
            fallback?.isTemplate = true
            return fallback
        }
        image.isTemplate = false

        // Add 2x representation for Retina displays
        if let url2x = Bundle.module.url(forResource: "fruit-clip-status@2x", withExtension: "png"),
           let data2x = try? Data(contentsOf: url2x),
           let rep2x = NSBitmapImageRep(data: data2x) {
            rep2x.size = NSSize(width: 22, height: 22)
            image.addRepresentation(rep2x)
        }

        return image
    }

    func updateMenu() {
        buildMenu()
    }

    private func buildMenu() {
        let menu = NSMenu()

        let openItem = NSMenuItem(title: "Open Clipboard", action: #selector(handleOpen), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(handlePreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        let pauseTitle = settingsStore.isPaused ? "Resume Monitoring" : "Pause Monitoring"
        let pauseItem = NSMenuItem(title: pauseTitle, action: #selector(handleTogglePause), keyEquivalent: "")
        pauseItem.target = self
        menu.addItem(pauseItem)

        menu.addItem(.separator())

        let clearItem = NSMenuItem(title: "Clear History", action: #selector(handleClearHistory), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit FruitClip", action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func handleOpen() { onOpenClipboard() }
    @objc private func handlePreferences() { onPreferences() }
    @objc private func handleTogglePause() { onTogglePause() }
    @objc private func handleClearHistory() { onClearHistory() }
    @objc private func handleQuit() { onQuit() }
}
