import AppKit
import Foundation
import os

@MainActor
final class ClipboardHistoryStore: ObservableObject {
    @Published private(set) var items: [ClipboardHistoryItem] = []

    private let settingsStore: SettingsStore
    private let storageDir: URL
    private let metadataURL: URL
    private var pollTimer: Timer?
    private var lastChangeCount: Int
    private let logger = Logger(subsystem: "com.veer.FruitClip", category: "HistoryStore")

    var isWritingToPasteboard = false
    var lastSelfChangeCount: Int = -1

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        self.lastChangeCount = NSPasteboard.general.changeCount

        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        storageDir = appSupport.appendingPathComponent("com.veer.FruitClip", isDirectory: true)
        metadataURL = storageDir.appendingPathComponent("metadata.json")

        try? FileManager.default.createDirectory(at: storageDir, withIntermediateDirectories: true)

        loadMetadata()
        startPolling()
    }

    func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.checkPasteboard()
            }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func clearAll() {
        for item in items {
            let fileURL = storageDir.appendingPathComponent(item.payloadFilename)
            try? FileManager.default.removeItem(at: fileURL)
        }
        items = []
        saveMetadata()
    }

    func payloadURL(for item: ClipboardHistoryItem) -> URL {
        storageDir.appendingPathComponent(item.payloadFilename)
    }

    func loadPayload(for item: ClipboardHistoryItem) -> Data? {
        try? Data(contentsOf: payloadURL(for: item))
    }

    private func checkPasteboard() {
        guard !settingsStore.isPaused else { return }
        guard !isWritingToPasteboard else { return }

        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount

        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        guard currentCount != lastSelfChangeCount else { return }

        importFromPasteboard(pasteboard)
    }

    private func importFromPasteboard(_ pasteboard: NSPasteboard) {
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            let data = Data(string.utf8)
            addItem(kind: .text, data: data, preview: makeTextPreview(string))
            return
        }

        if let imageData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
            let preview = makeImagePreview(imageData)
            addItem(kind: .image, data: imageData, preview: preview)
            return
        }
    }

    private func addItem(kind: ClipboardHistoryItem.Kind, data: Data, preview: String) {
        let hash = ClipboardHistoryItem.computeHash(of: data)

        if let newest = items.first, newest.contentHash == hash {
            return
        }

        let filename = "\(UUID().uuidString).dat"
        let fileURL = storageDir.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
        } catch {
            logger.error("Failed to write payload: \(error.localizedDescription)")
            return
        }

        let item = ClipboardHistoryItem(
            kind: kind,
            contentHash: hash,
            preview: preview,
            payloadFilename: filename
        )

        items.insert(item, at: 0)
        pruneIfNeeded()
        saveMetadata()
    }

    private func pruneIfNeeded() {
        let max = settingsStore.maxHistoryCount
        while items.count > max {
            let removed = items.removeLast()
            let fileURL = storageDir.appendingPathComponent(removed.payloadFilename)
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private func makeTextPreview(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let preview = lines.prefix(2).joined(separator: " ")
        if preview.count > 200 {
            return String(preview.prefix(200)) + "..."
        }
        return preview
    }

    private func makeImagePreview(_ data: Data) -> String {
        if let image = NSImage(data: data) {
            let size = image.size
            return "Image \(Int(size.width))x\(Int(size.height))"
        }
        return "Image"
    }

    private func loadMetadata() {
        guard FileManager.default.fileExists(atPath: metadataURL.path) else { return }
        do {
            let data = try Data(contentsOf: metadataURL)
            items = try JSONDecoder().decode([ClipboardHistoryItem].self, from: data)
            // Remove items whose payload files are missing
            items = items.filter { item in
                FileManager.default.fileExists(
                    atPath: storageDir.appendingPathComponent(item.payloadFilename).path)
            }
        } catch {
            logger.error("Failed to load metadata: \(error.localizedDescription)")
            items = []
        }
    }

    private func saveMetadata() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: metadataURL)
        } catch {
            logger.error("Failed to save metadata: \(error.localizedDescription)")
        }
    }
}
