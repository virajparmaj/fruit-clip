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
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 320)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 320),
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
                    Text(hotkeyDisplay)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    isRecordingHotkey
                                        ? Color.accentColor.opacity(0.2)
                                        : Color(nsColor: .controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    isRecordingHotkey ? Color.accentColor : Color.gray.opacity(0.3),
                                    lineWidth: 1)
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
            }

            Section("Accessibility") {
                HStack {
                    let granted = PermissionsManager.isAccessibilityGranted(prompt: false)
                    Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(granted ? .green : .red)
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
                Button("Clear History", role: .destructive) {
                    onClearHistory()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 320)
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
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("^") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("\u{2325}") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("\u{21E7}") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("\u{2318}") }
        parts.append(keyCodeToString(keyCode))
        return parts.joined()
    }

    private func keyCodeToString(_ keyCode: UInt32) -> String {
        let keyMap: [UInt32: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H",
            0x05: "G", 0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V",
            0x0B: "B", 0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R",
            0x10: "Y", 0x11: "T", 0x12: "1", 0x13: "2", 0x14: "3",
            0x15: "4", 0x17: "5", 0x16: "6", 0x1A: "7", 0x1C: "8",
            0x19: "9", 0x1D: "0", 0x1E: "]", 0x1F: "O", 0x20: "U",
            0x21: "[", 0x22: "I", 0x23: "P", 0x25: "L", 0x26: "J",
            0x28: "K", 0x2C: "/", 0x2D: "N", 0x2E: "M", 0x2F: ".",
            0x31: " ", 0x24: "\u{23CE}", 0x30: "\u{21E5}",
            0x33: "\u{232B}", 0x35: "\u{238B}",
        ]
        return keyMap[keyCode] ?? "?"
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
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        return carbon
    }
}
