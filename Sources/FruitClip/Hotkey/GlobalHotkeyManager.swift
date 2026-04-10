import Carbon
import Foundation

enum GlobalHotkeyAction: UInt32, CaseIterable, Equatable {
    case openBoard = 1
    case openStar = 2

    var title: String {
        switch self {
        case .openBoard: "Open Board"
        case .openStar: "Open Star"
        }
    }
}

struct HotkeyRegistration: Equatable {
    let action: GlobalHotkeyAction
    let shortcut: ShortcutConfiguration
}

@MainActor
final class GlobalHotkeyManager {
    private let settingsStore: SettingsStore
    private let onActivate: (GlobalHotkeyAction) -> Void
    private var hotKeyRefs: [GlobalHotkeyAction: EventHotKeyRef] = [:]
    private var handlerRef: EventHandlerRef?

    // Called when RegisterEventHotKey fails (e.g., combo already claimed by another app).
    var onRegistrationFailed: ((String) -> Void)?

    private static let signature: OSType = 0x4643_4C50  // "FCLP"

    init(
        settingsStore: SettingsStore,
        onActivate: @escaping @MainActor (GlobalHotkeyAction) -> Void
    ) {
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

        for registration in configuredHotkeys() {
            let hotkeyID = EventHotKeyID(
                signature: GlobalHotkeyManager.signature,
                id: registration.action.rawValue
            )

            var hotKeyRef: EventHotKeyRef?
            let registrationStatus = RegisterEventHotKey(
                registration.shortcut.keyCode,
                registration.shortcut.modifiers,
                hotkeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )

            if registrationStatus != noErr {
                let combo = HotkeyFormatter.format(registration.shortcut)
                onRegistrationFailed?(
                    "The shortcut \(combo) for \(registration.action.title) is already in use by another app. Please choose a different shortcut in Settings."
                )
                continue
            }

            if let hotKeyRef {
                hotKeyRefs[registration.action] = hotKeyRef
            }
        }
    }

    func unregister() {
        for ref in hotKeyRefs.values {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        if let ref = handlerRef {
            RemoveEventHandler(ref)
            handlerRef = nil
        }
    }

    func reregister() {
        register()
    }

    func configuredHotkeys() -> [HotkeyRegistration] {
        var registrations = [
            HotkeyRegistration(action: .openBoard, shortcut: settingsStore.openBoardShortcut)
        ]

        if let starShortcut = settingsStore.activeOpenStarShortcut {
            registrations.append(
                HotkeyRegistration(action: .openStar, shortcut: starShortcut)
            )
        }

        return registrations
    }

    fileprivate func handleHotkey(_ action: GlobalHotkeyAction) {
        onActivate(action)
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

    guard let event else { return OSStatus(eventNotHandledErr) }

    var hotkeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotkeyID
    )

    guard status == noErr, let action = GlobalHotkeyAction(rawValue: hotkeyID.id) else {
        return OSStatus(eventNotHandledErr)
    }

    DispatchQueue.main.async { @MainActor in
        manager.handleHotkey(action)
    }
    return noErr
}
