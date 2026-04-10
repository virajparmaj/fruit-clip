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

        popupController.onItemStarToggled = { [weak self] item in
            self?.historyStore.toggleStar(item)
        }

        hotkeyManager = GlobalHotkeyManager(settingsStore: settingsStore) { [weak self] action in
            switch action {
            case .openBoard:
                self?.togglePopup(initialTab: .board)
            case .openStar:
                self?.togglePopup(initialTab: .star)
            }
        }
        hotkeyManager.onRegistrationFailed = { [weak self] message in
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Shortcut Conflict"
            alert.informativeText = message
            alert.runModal()
            self?.showSettings()
        }
        hotkeyManager.register()

        statusItemController = StatusItemController(
            onOpenClipboard: { [weak self] in self?.togglePopup(initialTab: .board) },
            onPreferences: { [weak self] in self?.showSettings() },
            onTogglePause: { [weak self] in self?.togglePause() },
            onClearHistory: { [weak self] in self?.clearBoard() },
            onQuit: { NSApp.terminate(nil) },
            settingsStore: settingsStore
        )

        if settingsStore.isFirstLaunch {
            settingsStore.isFirstLaunch = false
            showSettings()
        }
    }

    private func togglePopup(initialTab: PopupTab) {
        popupController.toggle(
            initialTab: initialTab,
            historyStore: historyStore,
            settingsStore: settingsStore
        )
    }

    private func showSettings() {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindowController(
                settingsStore: settingsStore,
                hotkeyManager: hotkeyManager,
                historyStore: historyStore,
                onClearHistory: { [weak self] in self?.clearBoard() }
            )
        }
        preferencesWindow?.showWindow()
    }

    private func togglePause() {
        settingsStore.isPaused.toggle()
        statusItemController.updateMenu()
    }

    private func clearBoard() {
        let alert = NSAlert()
        alert.messageText = "Clear Board"
        alert.informativeText =
            "This will permanently delete non-starred clipboard items. Starred clips will be kept."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            historyStore.clearBoard()
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
