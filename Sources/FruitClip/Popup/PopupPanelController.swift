import AppKit
import SwiftUI

@MainActor
final class PopupPanelController {
    private var panel: FloatingPanel?
    private var clickMonitor: Any?
    var onItemSelected: ((ClipboardHistoryItem) -> Void)?
    private(set) var previousApp: NSRunningApplication?

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    func show(items: [ClipboardHistoryItem], settingsStore: SettingsStore) {
        previousApp = NSWorkspace.shared.frontmostApplication

        dismiss()

        let panelWidth: CGFloat = 340
        let panelHeight: CGFloat = 340

        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)
        )

        let popupView = ClipboardPopupView(
            items: items,
            onSelect: { [weak self] item in
                self?.dismiss()
                self?.onItemSelected?(item)
            },
            onDismiss: { [weak self] in
                self?.dismiss()
            }
        )

        panel.contentView = NSHostingView(rootView: popupView)

        if let screen = NSScreen.main {
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
    }

    func dismiss() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
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
