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
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 420)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 420),
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
    @State private var updateStatus: UpdateStatus = .idle

    private enum UpdateStatus {
        case idle
        case checking
        case upToDate
        case available(String)
        case error
    }

    private struct GitHubRelease: Decodable {
        let tagName: String
        enum CodingKeys: String, CodingKey { case tagName = "tag_name" }
    }

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

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
                Toggle("Dismiss on mouse move", isOn: $settingsStore.dismissOnMouseMove)
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

            Section("Updates") {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Version \(currentVersion)")
                            .font(.body)
                        updateStatusView
                    }
                    Spacer()
                    Button {
                        Task { await checkForUpdates() }
                    } label: {
                        if case .checking = updateStatus {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("Check for Updates")
                        }
                    }
                    .disabled({ if case .checking = updateStatus { return true }; return false }())
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 420)
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

    @ViewBuilder
    private var updateStatusView: some View {
        switch updateStatus {
        case .idle:
            EmptyView()
        case .checking:
            EmptyView()
        case .upToDate:
            Label("FruitClip is up to date.", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .available(let version):
            HStack(spacing: 6) {
                Label("Version \(version) is available.", systemImage: "info.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Button("Download") {
                    NSWorkspace.shared.open(
                        URL(string: "https://github.com/virajparmaj/fruit-clip/releases/latest")!
                    )
                }
                .font(.caption)
                .buttonStyle(.link)
            }
        case .error:
            Label("Could not check for updates.", systemImage: "exclamationmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    private func checkForUpdates() async {
        updateStatus = .checking
        do {
            let url = URL(string: "https://api.github.com/repos/virajparmaj/fruit-clip/releases/latest")!
            let (data, response) = try await URLSession.shared.data(from: url)
            if (response as? HTTPURLResponse)?.statusCode == 404 {
                // No releases published yet — already on latest
                updateStatus = .upToDate
                return
            }
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let latest = release.tagName.trimmingCharacters(in: .init(charactersIn: "v"))
            if latest.compare(currentVersion, options: .numeric) == .orderedDescending {
                updateStatus = .available(latest)
            } else {
                updateStatus = .upToDate
            }
        } catch {
            updateStatus = .error
        }
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
