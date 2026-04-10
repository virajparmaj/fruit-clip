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
    private var lastActivityTime: Date = Date()
    private let logger = Logger(subsystem: "com.veer.FruitClip", category: "HistoryStore")

    private var activeInterval: TimeInterval { 0.3 }
    private var idleInterval: TimeInterval { 1.5 }
    private var idleThreshold: TimeInterval { 30 }

    private(set) var isWritingToPasteboard = false
    private(set) var lastSelfChangeCount: Int = -1

    func beginPasteboardWrite() { isWritingToPasteboard = true }
    func endPasteboardWrite(changeCount: Int) {
        lastSelfChangeCount = changeCount
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { @MainActor in
            self.isWritingToPasteboard = false
        }
    }

    init(settingsStore: SettingsStore, storageDirectory: URL? = nil) {
        self.settingsStore = settingsStore
        self.lastChangeCount = NSPasteboard.general.changeCount

        if let dir = storageDirectory {
            storageDir = dir
        } else {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first!
            storageDir = appSupport.appendingPathComponent("com.veer.FruitClip", isDirectory: true)
        }
        metadataURL = storageDir.appendingPathComponent("metadata.json")

        try? FileManager.default.createDirectory(at: storageDir, withIntermediateDirectories: true)

        loadMetadata()
        cleanOrphanedFiles()
        refreshStoragePolicies()
        startPolling()
    }

    func startPolling() {
        pollTimer?.invalidate()
        scheduleNextPoll()
    }

    private func scheduleNextPoll() {
        let isIdle = Date().timeIntervalSince(lastActivityTime) > idleThreshold
        let interval = isIdle ? idleInterval : activeInterval

        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.checkPasteboard()
                self?.scheduleNextPoll()
            }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func deleteItem(_ item: ClipboardHistoryItem) {
        deletePayloadFiles(for: items.filter { $0.id == item.id })
        items.removeAll { $0.id == item.id }
        saveMetadata()
    }

    func toggleStar(_ item: ClipboardHistoryItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isStarred.toggle()
        saveMetadata()
    }

    func clearAll() {
        deletePayloadFiles(for: items)
        items = []
        saveMetadata()
    }

    func clearBoard() {
        let boardOnly = items.filter { !$0.isStarred }
        deletePayloadFiles(for: boardOnly)
        items.removeAll { !$0.isStarred }
        saveMetadata()
    }

    func refreshStoragePolicies() {
        let removedByRetention = applyRetentionPolicies()
        let removedByCount = pruneIfNeeded()
        if removedByRetention || removedByCount {
            saveMetadata()
        }
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

        refreshStoragePolicies()

        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount

        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        guard currentCount != lastSelfChangeCount else { return }

        lastActivityTime = Date()
        importFromPasteboard(pasteboard)
    }

    private func importFromPasteboard(_ pasteboard: NSPasteboard) {
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            let data = Data(string.utf8)
            addItem(kind: .text, data: data, preview: Self.makeTextPreview(string))
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

        if items.contains(where: { $0.contentHash == hash }) {
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
        refreshStoragePolicies()
    }

    @discardableResult
    private func pruneIfNeeded() -> Bool {
        let max = settingsStore.maxHistoryCount
        var removedItems: [ClipboardHistoryItem] = []

        while items.filter({ !$0.isStarred }).count > max {
            guard let index = items.lastIndex(where: { !$0.isStarred }) else { break }
            removedItems.append(items.remove(at: index))
        }

        deletePayloadFiles(for: removedItems)
        return !removedItems.isEmpty
    }

    nonisolated static func makeTextPreview(_ text: String) -> String {
        // If the text is a URL, show the domain
        if let url = detectURL(in: text) {
            let domain = url.host ?? url.absoluteString
            let prefix = url.scheme == "https" ? "🔗 " : "🔗 "
            return prefix + domain + (url.path.count > 1 ? url.path : "")
        }

        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let preview = lines.prefix(2).joined(separator: " ")
        if preview.count > 200 {
            return String(preview.prefix(200)) + "..."
        }
        return preview
    }

    nonisolated static func detectURL(in text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Only treat as URL if the entire text is a single URL
        guard !trimmed.contains("\n") else { return nil }
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
        guard let match = detector.firstMatch(in: trimmed, range: range),
              match.range == range else {
            return nil
        }
        return match.url
    }

    private func makeImagePreview(_ data: Data) -> String {
        if let image = NSImage(data: data) {
            let size = image.size
            return "Image \(Int(size.width))x\(Int(size.height))"
        }
        return "Image"
    }

    private func cleanOrphanedFiles() {
        let knownFilenames = Set(items.map { $0.payloadFilename })
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: storageDir, includingPropertiesForKeys: nil) else { return }
        for fileURL in contents where fileURL.pathExtension == "dat" {
            if !knownFilenames.contains(fileURL.lastPathComponent) {
                try? FileManager.default.removeItem(at: fileURL)
                logger.info("Cleaned orphaned file: \(fileURL.lastPathComponent)")
            }
        }
    }

    @discardableResult
    private func applyRetentionPolicies(now: Date = Date()) -> Bool {
        var removedItems: [ClipboardHistoryItem] = []
        let retainedItems = items.filter { item in
            let policy = item.isStarred
                ? settingsStore.starRetentionPolicy
                : settingsStore.boardRetentionPolicy

            guard let interval = policy.timeInterval else {
                return true
            }

            let shouldKeep = now.timeIntervalSince(item.timestamp) < interval
            if !shouldKeep {
                removedItems.append(item)
            }
            return shouldKeep
        }

        guard retainedItems.count != items.count else { return false }

        items = retainedItems
        deletePayloadFiles(for: removedItems)
        return true
    }

    private func deletePayloadFiles(for items: [ClipboardHistoryItem]) {
        for item in items {
            let fileURL = storageDir.appendingPathComponent(item.payloadFilename)
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private func loadMetadata() {
        guard FileManager.default.fileExists(atPath: metadataURL.path) else { return }
        do {
            let data = try Data(contentsOf: metadataURL)
            let decoder = JSONDecoder()

            // Try the versioned envelope first; fall back to the legacy unversioned array
            // so existing installs migrate automatically on first load.
            if let envelope = try? decoder.decode(StorageEnvelope.self, from: data) {
                items = envelope.items
            } else {
                logger.info("Migrating metadata.json from legacy unversioned format to schema v\(StorageEnvelope.currentVersion).")
                items = try decoder.decode([ClipboardHistoryItem].self, from: data)
                saveMetadata()  // Re-save immediately in the new envelope format.
            }

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
            let envelope = StorageEnvelope(schemaVersion: StorageEnvelope.currentVersion, items: items)
            let data = try JSONEncoder().encode(envelope)
            try data.write(to: metadataURL)
        } catch {
            logger.error("Failed to save metadata: \(error.localizedDescription)")
        }
    }
}
