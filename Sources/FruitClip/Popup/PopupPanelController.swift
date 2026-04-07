import AppKit
import SwiftUI

@MainActor
final class PopupPanelController {
    // Accumulated mouse delta (points) before the popup auto-dismisses.
    // 50pts ≈ a quarter-inch on a trackpad; 10 was hair-trigger on high-res input devices.
    private let mouseDismissThreshold: CGFloat = 50

    private var panel: FloatingPanel?
    private var clickMonitor: Any?
    private var mouseMoveMonitor: Any?
    private var accumulatedMouseDelta: CGFloat = 0
    var onItemSelected: ((ClipboardHistoryItem) -> Void)?
    var onItemCopied: ((ClipboardHistoryItem) -> Void)?
    var onItemDeleted: ((ClipboardHistoryItem) -> Void)?
    var onItemPinToggled: ((ClipboardHistoryItem) -> Void)?
    private(set) var previousApp: NSRunningApplication?

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    func show(items: [ClipboardHistoryItem], settingsStore: SettingsStore) {
        previousApp = NSWorkspace.shared.frontmostApplication

        dismiss()

        let panelWidth: CGFloat = 340
        let panelHeight: CGFloat = 380

        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)
        )

        let popupView = ClipboardPopupView(
            items: items,
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
            onTogglePin: { [weak self] item in
                self?.onItemPinToggled?(item)
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
