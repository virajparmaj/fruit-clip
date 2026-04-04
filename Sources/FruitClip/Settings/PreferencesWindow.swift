import AppKit
import Carbon
import ServiceManagement
import SwiftUI

@MainActor
final class PreferencesWindowController {
    private var window: NSWindow?
    private let settingsStore: SettingsStore
    private let hotkeyManager: GlobalHotkeyManager
    private let onClearHistory: () -> Void

    init(
        settingsStore: SettingsStore,
        hotkeyManager: GlobalHotkeyManager,
        onClearHistory: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.hotkeyManager = hotkeyManager
        self.onClearHistory = onClearHistory
    }

    func showWindow() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let prefsView = PreferencesView(
            settingsStore: settingsStore,
            hotkeyManager: hotkeyManager,
            onClearHistory: onClearHistory
        )

        let hostingView = NSHostingView(rootView: prefsView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 420, height: 480)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "FruitClip Preferences"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct PreferencesView: View {
    @ObservedObject var settingsStore: SettingsStore
    let hotkeyManager: GlobalHotkeyManager
    let onClearHistory: () -> Void

    @State private var isRecordingHotkey = false
    @State private var hotkeyDisplay: String = ""

    var body: some View {
        Form {
            Section("Hotkey") {
                HStack {
                    Text("Global Shortcut:")
                    Spacer()
                    // Keyboard-badge style: dark filled pill
                    Text(isRecordingHotkey ? "Press keys…" : hotkeyDisplay)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isRecordingHotkey ? Color.accentColor : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(isRecordingHotkey
                                    ? Color.accentColor.opacity(0.18)
                                    : Color(nsColor: .controlColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )

                    Button(isRecordingHotkey ? "Cancel" : "Record") {
                        isRecordingHotkey.toggle()
                    }
                }
            }

            Section("General") {
                Toggle("Launch at Login", isOn: Binding(
                    get: { settingsStore.launchAtLogin },
                    set: { newValue in
                        settingsStore.launchAtLogin = newValue
                        updateLaunchAtLogin(newValue)
                    }
                ))
                Toggle("Dismiss on mouse move", isOn: $settingsStore.dismissOnMouseMove)
            }

            Section("Accessibility") {
                HStack(spacing: 10) {
                    let granted = PermissionsManager.isAccessibilityGranted(prompt: false)
                    Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(granted ? .green : .red)
                        .font(.system(size: 16))
                    Text(
                        granted
                            ? "Accessibility permission granted"
                            : "Accessibility permission required for auto-paste"
                    )
                    Spacer()
                    if !granted {
                        Button("Grant Access") {
                            _ = PermissionsManager.isAccessibilityGranted(prompt: true)
                        }
                    }
                }
            }

            Section("Data") {
                Button("Clear History") {
                    onClearHistory()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 480)
        .onAppear {
            hotkeyDisplay = formatHotkey(
                keyCode: settingsStore.hotkeyKeyCode,
                modifiers: settingsStore.hotkeyModifiers
            )
        }
        .background(
            HotkeyRecorderView(
                isRecording: $isRecordingHotkey,
                onRecord: { keyCode, modifiers in
                    settingsStore.hotkeyKeyCode = keyCode
                    settingsStore.hotkeyModifiers = modifiers
                    hotkeyDisplay = formatHotkey(keyCode: keyCode, modifiers: modifiers)
                    hotkeyManager.reregister()
                    isRecordingHotkey = false
                }
            )
            .frame(width: 0, height: 0)
        )
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            // Silently fail — SMAppService may not work without proper bundle
        }
    }

    private func formatHotkey(keyCode: UInt32, modifiers: UInt32) -> String {
        HotkeyFormatter.format(keyCode: keyCode, modifiers: modifiers)
    }
}

struct HotkeyRecorderView: NSViewRepresentable {
    @Binding var isRecording: Bool
    let onRecord: (UInt32, UInt32) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = HotkeyRecorderNSView()
        view.onRecord = onRecord
        context.coordinator.view = view
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? HotkeyRecorderNSView {
            if isRecording {
                view.startRecording()
            } else {
                view.stopRecording()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var view: HotkeyRecorderNSView?
    }
}

class HotkeyRecorderNSView: NSView {
    var onRecord: ((UInt32, UInt32) -> Void)?
    private var monitor: Any?

    func startRecording() {
        stopRecording()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard !modifiers.isEmpty else { return event }

            let carbonMods = self.cocoaToCarbonModifiers(modifiers)
            self.onRecord?(UInt32(event.keyCode), carbonMods)
            return nil
        }
    }

    func stopRecording() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

    private func cocoaToCarbonModifiers(_ flags: NSEvent.ModifierFlags) -> UInt32 {
        HotkeyFormatter.cocoaToCarbonModifiers(flags.rawValue)
    }
}
