import AppKit
import SwiftUI

enum PopupTab: String, CaseIterable, Identifiable {
    case board
    case star

    var id: String { rawValue }

    var title: String {
        switch self {
        case .board: "Board"
        case .star: "Star"
        }
    }

    var searchPlaceholder: String {
        switch self {
        case .board: "Search board items..."
        case .star: "Search starred items..."
        }
    }
}

@MainActor
final class PopupPresentationState: ObservableObject {
    @Published var activeTab: PopupTab = .board
    @Published var inputMode: PopupInputMode = .search
    @Published var activationID = UUID()

    func activate(tab: PopupTab) {
        activeTab = tab
        inputMode = .search
        activationID = UUID()
    }

    func selectTab(_ tab: PopupTab) {
        activeTab = tab
        inputMode = .search
    }
}

@MainActor
final class PopupPanelController {
    // Accumulated mouse delta (points) before the popup auto-dismisses.
    // 50pts ≈ a quarter-inch on a trackpad; 10 was hair-trigger on high-res input devices.
    private let mouseDismissThreshold: CGFloat = 50

    private var panel: FloatingPanel?
    private var clickMonitor: Any?
    private var mouseMoveMonitor: Any?
    private var accumulatedMouseDelta: CGFloat = 0
    private let presentationState = PopupPresentationState()
    var onItemSelected: ((ClipboardHistoryItem) -> Void)?
    var onItemCopied: ((ClipboardHistoryItem) -> Void)?
    var onItemDeleted: ((ClipboardHistoryItem) -> Void)?
    var onItemStarToggled: ((ClipboardHistoryItem) -> Void)?
    private(set) var previousApp: NSRunningApplication?

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    var activeTab: PopupTab {
        presentationState.activeTab
    }

    func toggle(
        initialTab: PopupTab,
        historyStore: ClipboardHistoryStore,
        settingsStore: SettingsStore
    ) {
        if isVisible {
            if presentationState.activeTab == initialTab {
                dismiss()
            } else {
                presentationState.activate(tab: initialTab)
                panel?.makeKeyAndOrderFront(nil)
            }
        } else {
            show(
                historyStore: historyStore,
                settingsStore: settingsStore,
                initialTab: initialTab
            )
        }
    }

    func show(
        historyStore: ClipboardHistoryStore,
        settingsStore: SettingsStore,
        initialTab: PopupTab
    ) {
        previousApp = NSWorkspace.shared.frontmostApplication
        historyStore.refreshStoragePolicies()

        dismiss()
        presentationState.activate(tab: initialTab)

        let panelWidth: CGFloat = 400
        let panelHeight: CGFloat = 520

        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)
        )

        let popupView = ClipboardPopupView(
            historyStore: historyStore,
            settingsStore: settingsStore,
            presentationState: presentationState,
            onSelect: { [weak self] item in
                self?.dismiss()
                self?.onItemSelected?(item)
            },
            onCopy: { [weak self] item in
                self?.dismiss()
                self?.onItemCopied?(item)
            },
            onDelete: { [weak self] item in
                self?.onItemDeleted?(item)
            },
            onToggleStar: { [weak self] item in
                self?.onItemStarToggled?(item)
            },
            onDismiss: { [weak self] in
                self?.dismiss()
            }
        )

        panel.contentView = NSHostingView(rootView: popupView)

        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
            ?? NSScreen.main
        if let screen {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - panelWidth / 2
            let y = screenFrame.midY - panelHeight / 2
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.makeKeyAndOrderFront(nil)
        self.panel = panel

        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] _ in
            self?.dismiss()
        }

        if settingsStore.dismissOnMouseMove {
            accumulatedMouseDelta = 0
            mouseMoveMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) {
                [weak self] event in
                guard let self else { return }
                self.accumulatedMouseDelta += abs(event.deltaX) + abs(event.deltaY)
                if self.accumulatedMouseDelta > self.mouseDismissThreshold {
                    self.dismiss()
                }
            }
        }
    }

    func dismiss() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
        if let monitor = mouseMoveMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMoveMonitor = nil
        }
        panel?.orderOut(nil)
        panel = nil
    }
}

final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .floating
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
    }
}
