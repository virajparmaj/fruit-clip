import AppKit
import SwiftUI

@MainActor
final class AppCoordinator: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController!
    private var settingsStore: SettingsStore!
    private var historyStore: ClipboardHistoryStore!
    private var hotkeyManager: GlobalHotkeyManager!
    private var popupController: PopupPanelController!
    private var pasteController: PasteController!
    private var preferencesWindow: PreferencesWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        applyDockIcon()

        settingsStore = SettingsStore()
        historyStore = ClipboardHistoryStore(settingsStore: settingsStore)
        pasteController = PasteController(historyStore: historyStore)
        popupController = PopupPanelController()

        popupController.onItemSelected = { [weak self] item in
            guard let self else { return }
            let prevApp = self.popupController.previousApp
            self.popupController.dismiss()
            self.pasteController.pasteItem(item, previousApp: prevApp)
        }

        popupController.onItemCopied = { [weak self] item in
            guard let self else { return }
            self.pasteController.copyItemOnly(item)
        }

        popupController.onItemDeleted = { [weak self] item in
            self?.historyStore.deleteItem(item)
        }

        popupController.onItemPinToggled = { [weak self] item in
            self?.historyStore.togglePin(item)
        }

        hotkeyManager = GlobalHotkeyManager(settingsStore: settingsStore) { [weak self] in
            self?.togglePopup()
        }
        hotkeyManager.onRegistrationFailed = { [weak self] message in
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Hotkey Conflict"
            alert.informativeText = message
            alert.runModal()
            self?.showPreferences()
        }
        hotkeyManager.register()

        statusItemController = StatusItemController(
            onOpenClipboard: { [weak self] in self?.togglePopup() },
            onPreferences: { [weak self] in self?.showPreferences() },
            onTogglePause: { [weak self] in self?.togglePause() },
            onClearHistory: { [weak self] in self?.clearHistory() },
            onQuit: { NSApp.terminate(nil) },
            settingsStore: settingsStore
        )

        if settingsStore.isFirstLaunch {
            settingsStore.isFirstLaunch = false
            showPreferences()
        }
    }

    private func togglePopup() {
        if popupController.isVisible {
            popupController.dismiss()
        } else {
            popupController.show(items: historyStore.items, settingsStore: settingsStore)
        }
    }

    private func showPreferences() {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindowController(
                settingsStore: settingsStore,
                hotkeyManager: hotkeyManager,
                onClearHistory: { [weak self] in self?.clearHistory() }
            )
        }
        preferencesWindow?.showWindow()
    }

    private func togglePause() {
        settingsStore.isPaused.toggle()
        statusItemController.updateMenu()
    }

    private func clearHistory() {
        let alert = NSAlert()
        alert.messageText = "Clear Clipboard History"
        alert.informativeText = "This will permanently delete all saved clipboard items."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            historyStore.clearAll()
        }
    }

    private func applyDockIcon() {
        guard
            let url = Bundle.module.url(forResource: "fruit-clip", withExtension: "png"),
            let image = NSImage(contentsOf: url)
        else { return }

        NSApplication.shared.applicationIconImage = image
    }
}
