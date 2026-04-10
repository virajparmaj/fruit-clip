import AppKit
import Carbon
import ServiceManagement
import SwiftUI

private let settingsAccentBlue = Color(red: 0.2, green: 0.5, blue: 1.0)
private let settingsDeleteRed = Color(red: 0.92, green: 0.32, blue: 0.36)

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case shortcuts
    case storage
    case accessibility

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .shortcuts: "Shortcuts"
        case .storage: "Storage"
        case .accessibility: "Accessibility"
        }
    }

    var symbolName: String {
        switch self {
        case .general: "slider.horizontal.3"
        case .shortcuts: "command"
        case .storage: "externaldrive"
        case .accessibility: "figure.wave"
        }
    }
}

private enum ShortcutRecorderTarget: Hashable {
    case openBoard
    case openStar
    case starItem
    case deleteItem
    case switchToStar
    case copySelected
    case focusSearch
}

fileprivate enum ShortcutRecorderMode {
    case global
    case singleKey
    case modified
}

@MainActor
private final class PreferencesNavigationState: ObservableObject {
    @Published var activeSection: SettingsSection = .general
}

@MainActor
final class PreferencesWindowController {
    private var window: NSWindow?
    private let settingsStore: SettingsStore
    private let hotkeyManager: GlobalHotkeyManager
    private let historyStore: ClipboardHistoryStore
    private let onClearHistory: () -> Void
    private let navigationState = PreferencesNavigationState()

    init(
        settingsStore: SettingsStore,
        hotkeyManager: GlobalHotkeyManager,
        historyStore: ClipboardHistoryStore,
        onClearHistory: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.hotkeyManager = hotkeyManager
        self.historyStore = historyStore
        self.onClearHistory = onClearHistory
    }

    func showWindow() {
        navigationState.activeSection = .general

        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        let prefsView = PreferencesView(
            settingsStore: settingsStore,
            hotkeyManager: hotkeyManager,
            historyStore: historyStore,
            onClearHistory: onClearHistory,
            navigationState: navigationState
        )

        let hostingView = NSHostingView(rootView: prefsView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 760, height: 560)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 560),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "FruitClip Settings"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }
}

private struct PreferencesView: View {
    @ObservedObject var settingsStore: SettingsStore
    let hotkeyManager: GlobalHotkeyManager
    let historyStore: ClipboardHistoryStore
    let onClearHistory: () -> Void
    @ObservedObject var navigationState: PreferencesNavigationState

    @State private var activeRecorder: ShortcutRecorderTarget?

    private var popupFontSizeSliderValue: Binding<Double> {
        Binding(
            get: { Double(settingsStore.popupFontSize) },
            set: { settingsStore.popupFontSize = Int($0.rounded()) }
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            content
        }
        .frame(width: 760, height: 560)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color.black.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(
            ShortcutRecorderView(
                isRecording: Binding(
                    get: { activeRecorder != nil },
                    set: { isRecording in
                        if !isRecording {
                            activeRecorder = nil
                        }
                    }
                ),
                mode: recorderMode,
                onRecord: { shortcut in
                    applyRecordedShortcut(shortcut)
                },
                onCancel: {
                    activeRecorder = nil
                }
            )
            .frame(width: 0, height: 0)
        )
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Settings")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 20)

            VStack(spacing: 8) {
                ForEach(SettingsSection.allCases) { section in
                    SidebarSectionButton(
                        section: section,
                        isSelected: navigationState.activeSection == section
                    ) {
                        navigationState.activeSection = section
                    }
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Label(
                    PermissionsManager.isAccessibilityGranted(prompt: false)
                        ? "Auto-paste ready"
                        : "Accessibility needed",
                    systemImage: PermissionsManager.isAccessibilityGranted(prompt: false)
                        ? "checkmark.circle.fill"
                        : "exclamationmark.triangle.fill"
                )
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(
                    PermissionsManager.isAccessibilityGranted(prompt: false)
                        ? Color.green
                        : Color.orange
                )

                Text("Requires permission from macOS.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
            .padding(12)
        }
        .frame(width: 220)
        .background(Color.black.opacity(0.08))
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(navigationState.activeSection.title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .padding(.bottom, 18)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch navigationState.activeSection {
                    case .general:
                        generalSection
                    case .shortcuts:
                        shortcutsSection
                    case .storage:
                        storageSection
                    case .accessibility:
                        accessibilitySection
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsPanel {
                SettingToggleRow(
                    title: "Launch at Login",
                    isOn: Binding(
                        get: { settingsStore.launchAtLogin },
                        set: { newValue in
                            settingsStore.launchAtLogin = newValue
                            updateLaunchAtLogin(newValue)
                        }
                    )
                )

                Divider().opacity(0.08)

                SettingToggleRow(
                    title: "Dismiss on mouse move",
                    isOn: $settingsStore.dismissOnMouseMove
                )
            }

            SettingsPanel {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Popup font size")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    Text("\(settingsStore.popupFontSize) pt")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.22))
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Slider(
                        value: popupFontSizeSliderValue,
                        in: Double(PopupFontSize.min)...Double(PopupFontSize.max),
                        step: 1
                    )
                    .tint(settingsAccentBlue)

                    HStack {
                        Text("\(PopupFontSize.min) pt")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(PopupFontSize.max) pt")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                PopupFontPreviewCard(fontSize: CGFloat(settingsStore.popupFontSize))
            }
        }
    }

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsPanel {
                ShortcutCaptureRow(
                    title: "Open Board",
                    shortcutLabel: HotkeyFormatter.format(settingsStore.openBoardShortcut),
                    isRecording: activeRecorder == .openBoard,
                    onRecord: { activeRecorder = .openBoard }
                )

                Divider().opacity(0.08)

                ShortcutCaptureRow(
                    title: "Open Star",
                    shortcutLabel: HotkeyFormatter.format(settingsStore.openStarShortcut),
                    isRecording: activeRecorder == .openStar,
                    isEnabled: settingsStore.openStarShortcutEnabled,
                    onToggleEnabled: { enabled in
                        settingsStore.openStarShortcutEnabled = enabled
                        hotkeyManager.reregister()

                        if enabled && settingsStore.openStarShortcut == nil {
                            activeRecorder = .openStar
                        }
                    },
                    onRecord: { activeRecorder = .openStar }
                )
            }

            SettingsPanel {
                ShortcutCaptureRow(
                    title: "Star selected item",
                    shortcutLabel: HotkeyFormatter.format(settingsStore.starItemShortcut),
                    isRecording: activeRecorder == .starItem,
                    onRecord: { activeRecorder = .starItem }
                )

                Divider().opacity(0.08)

                ShortcutCaptureRow(
                    title: "Delete selected item",
                    shortcutLabel: HotkeyFormatter.format(settingsStore.deleteItemShortcut),
                    isRecording: activeRecorder == .deleteItem,
                    onRecord: { activeRecorder = .deleteItem }
                )

                Divider().opacity(0.08)

                ShortcutCaptureRow(
                    title: "Switch to Star",
                    shortcutLabel: HotkeyFormatter.format(settingsStore.switchToStarShortcut),
                    isRecording: activeRecorder == .switchToStar,
                    onRecord: { activeRecorder = .switchToStar }
                )

                Divider().opacity(0.08)

                ShortcutCaptureRow(
                    title: "Copy selected item",
                    shortcutLabel: HotkeyFormatter.format(settingsStore.copySelectedShortcut),
                    isRecording: activeRecorder == .copySelected,
                    onRecord: { activeRecorder = .copySelected }
                )

                Divider().opacity(0.08)

                ShortcutCaptureRow(
                    title: "Focus search",
                    shortcutLabel: HotkeyFormatter.format(settingsStore.focusSearchShortcut),
                    isRecording: activeRecorder == .focusSearch,
                    onRecord: { activeRecorder = .focusSearch }
                )
            }
        }
    }

    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsPanel {
                PickerRow(
                    title: "Board retention",
                    selection: $settingsStore.boardRetentionPolicy
                )

                Divider().opacity(0.08)

                PickerRow(
                    title: "Star retention",
                    selection: $settingsStore.starRetentionPolicy
                )
            }

            SettingsPanel {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clear Board")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    Button("Clear Board") {
                        onClearHistory()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(settingsDeleteRed)
                }
            }
        }
        .onChange(of: settingsStore.boardRetentionPolicy) { _, _ in
            historyStore.refreshStoragePolicies()
        }
        .onChange(of: settingsStore.starRetentionPolicy) { _, _ in
            historyStore.refreshStoragePolicies()
        }
    }

    private var accessibilitySection: some View {
        let granted = PermissionsManager.isAccessibilityGranted(prompt: false)

        return VStack(alignment: .leading, spacing: 16) {
            SettingsPanel {
                HStack(spacing: 14) {
                    Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(granted ? Color.green : Color.orange)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(granted ? "Accessibility permission granted" : "Accessibility permission required")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    if !granted {
                        Button("Grant Access") {
                            _ = PermissionsManager.isAccessibilityGranted(prompt: true)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(settingsAccentBlue)
                    }
                }
            }
        }
    }

    private var recorderMode: ShortcutRecorderMode {
        switch activeRecorder {
        case .openBoard, .openStar:
            .global
        case .starItem, .deleteItem, .switchToStar:
            .singleKey
        case .copySelected, .focusSearch:
            .modified
        case nil:
            .global
        }
    }

    private func applyRecordedShortcut(_ shortcut: ShortcutConfiguration) {
        switch activeRecorder {
        case .openBoard:
            settingsStore.openBoardShortcut = shortcut
            hotkeyManager.reregister()
        case .openStar:
            settingsStore.openStarShortcut = shortcut
            settingsStore.openStarShortcutEnabled = true
            hotkeyManager.reregister()
        case .starItem:
            settingsStore.starItemShortcut = shortcut
        case .deleteItem:
            settingsStore.deleteItemShortcut = shortcut
        case .switchToStar:
            settingsStore.switchToStarShortcut = shortcut
        case .copySelected:
            settingsStore.copySelectedShortcut = shortcut
        case .focusSearch:
            settingsStore.focusSearchShortcut = shortcut
        case nil:
            break
        }

        activeRecorder = nil
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
            settingsStore.launchAtLogin = !enabled

            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Launch at Login could not be \(enabled ? "enabled" : "disabled")."
            alert.informativeText = """
                Make sure FruitClip is installed in /Applications and launched from there.

                \(error.localizedDescription)
                """
            alert.runModal()
        }
    }
}

private struct SidebarSectionButton: View {
    let section: SettingsSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: section.symbolName)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 16)

                Text(section.title)
                    .font(.system(size: 13, weight: .semibold))

                Spacer()
            }
            .foregroundStyle(isSelected ? .white : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? settingsAccentBlue.opacity(0.92) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsPanel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

private struct PopupFontPreviewCard: View {
    let fontSize: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Welcome to FruitClip")
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.32))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )
                    .shadow(color: settingsAccentBlue.opacity(0.12), radius: 12, y: 6)
            )
        }
    }
}

private struct SettingToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
}

private struct ShortcutCaptureRow: View {
    let title: String
    let shortcutLabel: String
    let isRecording: Bool
    var isEnabled: Bool = true
    var onToggleEnabled: ((Bool) -> Void)? = nil
    let onRecord: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)

                    if let onToggleEnabled {
                        Toggle("", isOn: Binding(
                            get: { isEnabled },
                            set: { onToggleEnabled($0) }
                        ))
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .scaleEffect(0.9)
                    }
                }
            }

            Spacer()

            Button(action: onRecord) {
                Text(isRecording ? "Press keys…" : shortcutLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isRecording ? settingsAccentBlue : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.22))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        isRecording ? settingsAccentBlue.opacity(0.45) : Color.white.opacity(0.06),
                                        lineWidth: 1
                                    )
                            )
                    )
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled && onToggleEnabled != nil)
            .opacity((!isEnabled && onToggleEnabled != nil) ? 0.55 : 1)
        }
    }
}

private struct PickerRow: View {
    let title: String
    @Binding var selection: RetentionPolicy

    var body: some View {
        HStack(spacing: 16) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()

            Picker(title, selection: $selection) {
                ForEach(RetentionPolicy.allCases) { policy in
                    Text(policy.title).tag(policy)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 140)
        }
    }
}

fileprivate struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var isRecording: Bool
    let mode: ShortcutRecorderMode
    let onRecord: (ShortcutConfiguration) -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = ShortcutRecorderNSView()
        view.onRecord = onRecord
        view.onCancel = onCancel
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? ShortcutRecorderNSView else { return }

        view.onRecord = onRecord
        view.onCancel = onCancel

        if isRecording {
            view.startRecording(mode: mode)
        } else {
            view.stopRecording()
        }
    }
}

fileprivate final class ShortcutRecorderNSView: NSView {
    var onRecord: ((ShortcutConfiguration) -> Void)?
    var onCancel: (() -> Void)?
    private var monitor: Any?

    func startRecording(mode: ShortcutRecorderMode) {
        stopRecording()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }

            if event.keyCode == 0x35 {
                self.onCancel?()
                return nil
            }

            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            switch mode {
            case .global, .modified:
                guard !modifiers.isEmpty else { return event }
            case .singleKey:
                guard modifiers.isEmpty else { return event }
            }

            let shortcut = ShortcutConfiguration(
                keyCode: UInt32(event.keyCode),
                modifiers: mode == .singleKey
                    ? 0
                    : HotkeyFormatter.cocoaToCarbonModifiers(modifiers.rawValue)
            )
            self.onRecord?(shortcut)
            return nil
        }
    }

    func stopRecording() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}
