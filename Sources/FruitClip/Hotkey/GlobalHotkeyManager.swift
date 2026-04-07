import Carbon
import Foundation

@MainActor
final class GlobalHotkeyManager {
    private let settingsStore: SettingsStore
    private let onActivate: () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    // Called when RegisterEventHotKey fails (e.g., combo already claimed by another app).
    var onRegistrationFailed: ((String) -> Void)?

    private static let hotkeyID = EventHotKeyID(signature: 0x4643_4C50, id: 1)  // "FCLP"

    init(settingsStore: SettingsStore, onActivate: @escaping @MainActor () -> Void) {
        self.settingsStore = settingsStore
        self.onActivate = onActivate
    }

    func register() {
        unregister()

        var eventType = EventTypeSpec(eventClass: UInt32(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            globalHotkeyCallback,
            1,
            &eventType,
            refcon,
            &handlerRef
        )

        guard status == noErr else { return }

        let hotkeyID = GlobalHotkeyManager.hotkeyID

        let registrationStatus = RegisterEventHotKey(
            settingsStore.hotkeyKeyCode,
            settingsStore.hotkeyModifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if registrationStatus != noErr {
            let combo = HotkeyFormatter.format(
                keyCode: settingsStore.hotkeyKeyCode,
                modifiers: settingsStore.hotkeyModifiers
            )
            onRegistrationFailed?("The hotkey \(combo) is already in use by another app. Please choose a different shortcut in Preferences.")
        }
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = handlerRef {
            RemoveEventHandler(ref)
            handlerRef = nil
        }
    }

    func reregister() {
        register()
    }

    fileprivate func handleHotkey() {
        onActivate()
    }

    deinit {
        // Cannot call unregister() directly in deinit for MainActor class,
        // but the refs will be cleaned up when the process exits.
    }
}

private func globalHotkeyCallback(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData else { return OSStatus(eventNotHandledErr) }
    let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    DispatchQueue.main.async { @MainActor in
        manager.handleHotkey()
    }
    return noErr
}
