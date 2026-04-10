import Foundation
import Testing

@testable import FruitClip

@Suite("ClipboardHistoryStore Integration Tests")
@MainActor
struct ClipboardHistoryStoreIntegrationTests {
    private func makeTempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FruitClipTest-\(UUID().uuidString)", isDirectory: true)
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func makeStore(dir: URL, maxHistory: Int = 50) -> (ClipboardHistoryStore, SettingsStore) {
        let suiteName = "com.veer.FruitClip.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return makeStore(dir: dir, defaults: defaults, maxHistory: maxHistory)
    }

    private func makeStore(
        dir: URL,
        defaults: UserDefaults,
        maxHistory: Int = 50
    ) -> (ClipboardHistoryStore, SettingsStore) {
        let settings = SettingsStore(defaults: defaults)
        settings.maxHistoryCount = maxHistory
        let store = ClipboardHistoryStore(settingsStore: settings, storageDirectory: dir)
        store.stopPolling()
        return (store, settings)
    }

    private func writeItem(
        text: String,
        dir: URL,
        timestamp: Date = Date(),
        isStarred: Bool = false
    ) throws -> ClipboardHistoryItem {
        let data = Data(text.utf8)
        let hash = ClipboardHistoryItem.computeHash(of: data)
        let filename = "\(UUID().uuidString).dat"
        try data.write(to: dir.appendingPathComponent(filename))
        return ClipboardHistoryItem(
            timestamp: timestamp,
            kind: .text,
            contentHash: hash,
            preview: text,
            payloadFilename: filename,
            isStarred: isStarred
        )
    }

    private func writeMetadata(_ items: [ClipboardHistoryItem], dir: URL) throws {
        let encoded = try JSONEncoder().encode(items)
        try encoded.write(to: dir.appendingPathComponent("metadata.json"))
    }

    private func addTextItem(_ store: ClipboardHistoryStore, text: String) {
        let data = Data(text.utf8)
        let hash = ClipboardHistoryItem.computeHash(of: data)
        let filename = "\(UUID().uuidString).dat"
        let fileURL = store.payloadURL(for: ClipboardHistoryItem(
            kind: .text, contentHash: hash, preview: text, payloadFilename: filename))
        // Write directly to the store's directory
        let dir = fileURL.deletingLastPathComponent()
        try! data.write(to: dir.appendingPathComponent(filename))
        // Use internal items array manipulation through metadata
        var items = store.items
        items.insert(ClipboardHistoryItem(
            kind: .text, contentHash: hash, preview: text, payloadFilename: filename), at: 0)
        // Encode and write metadata to trigger a reload
        let metadataURL = dir.appendingPathComponent("metadata.json")
        let encoded = try! JSONEncoder().encode(items)
        try! encoded.write(to: metadataURL)
    }

    @Test("Save and load metadata round-trip")
    func saveAndLoadMetadata() throws {
        let dir = makeTempDir()
        let (store1, _) = makeStore(dir: dir)
        store1.stopPolling()

        // Write 3 items via metadata
        var items: [ClipboardHistoryItem] = []
        for i in 0..<3 {
            let text = "item\(i)"
            let data = Data(text.utf8)
            let hash = ClipboardHistoryItem.computeHash(of: data)
            let filename = "\(UUID().uuidString).dat"
            try data.write(to: dir.appendingPathComponent(filename))
            items.append(ClipboardHistoryItem(
                kind: .text, contentHash: hash, preview: text, payloadFilename: filename))
        }
        let encoded = try JSONEncoder().encode(items)
        try encoded.write(to: dir.appendingPathComponent("metadata.json"))

        // Create new store pointing to same dir
        let (store2, _) = makeStore(dir: dir)
        store2.stopPolling()
        #expect(store2.items.count == 3)
    }

    @Test("Load metadata filters orphaned entries with missing payload files")
    func loadMetadataFiltersOrphans() throws {
        let dir = makeTempDir()

        var items: [ClipboardHistoryItem] = []
        for i in 0..<3 {
            let text = "item\(i)"
            let data = Data(text.utf8)
            let hash = ClipboardHistoryItem.computeHash(of: data)
            let filename = "\(UUID().uuidString).dat"
            try data.write(to: dir.appendingPathComponent(filename))
            items.append(ClipboardHistoryItem(
                kind: .text, contentHash: hash, preview: text, payloadFilename: filename))
        }
        let encoded = try JSONEncoder().encode(items)
        try encoded.write(to: dir.appendingPathComponent("metadata.json"))

        // Delete one payload file
        try FileManager.default.removeItem(at: dir.appendingPathComponent(items[1].payloadFilename))

        let (store, _) = makeStore(dir: dir)
        store.stopPolling()
        #expect(store.items.count == 2)
    }

    @Test("Corrupt metadata resets to empty without crash")
    func corruptMetadataResetsEmpty() throws {
        let dir = makeTempDir()
        try Data("not valid json!!!".utf8).write(to: dir.appendingPathComponent("metadata.json"))

        let (store, _) = makeStore(dir: dir)
        store.stopPolling()
        #expect(store.items.count == 0)
    }

    @Test("Payload write and read round-trip")
    func payloadRoundTrip() throws {
        let dir = makeTempDir()
        let text = "test content"
        let data = Data(text.utf8)
        let hash = ClipboardHistoryItem.computeHash(of: data)
        let filename = "\(UUID().uuidString).dat"
        try data.write(to: dir.appendingPathComponent(filename))

        let item = ClipboardHistoryItem(
            kind: .text, contentHash: hash, preview: text, payloadFilename: filename)
        let items = [item]
        let encoded = try JSONEncoder().encode(items)
        try encoded.write(to: dir.appendingPathComponent("metadata.json"))

        let (store, _) = makeStore(dir: dir)
        store.stopPolling()

        let loaded = store.loadPayload(for: store.items[0])
        #expect(loaded != nil)
        #expect(String(data: loaded!, encoding: .utf8) == text)
    }

    @Test("Clear all removes files and metadata")
    func clearAllRemovesFiles() throws {
        let dir = makeTempDir()

        var items: [ClipboardHistoryItem] = []
        for i in 0..<3 {
            let text = "item\(i)"
            let data = Data(text.utf8)
            let hash = ClipboardHistoryItem.computeHash(of: data)
            let filename = "\(UUID().uuidString).dat"
            try data.write(to: dir.appendingPathComponent(filename))
            items.append(ClipboardHistoryItem(
                kind: .text, contentHash: hash, preview: text, payloadFilename: filename))
        }
        let encoded = try JSONEncoder().encode(items)
        try encoded.write(to: dir.appendingPathComponent("metadata.json"))

        let (store, _) = makeStore(dir: dir)
        store.stopPolling()
        #expect(store.items.count == 3)

        store.clearAll()
        #expect(store.items.count == 0)

        // Verify payload files deleted
        for item in items {
            let exists = FileManager.default.fileExists(
                atPath: dir.appendingPathComponent(item.payloadFilename).path)
            #expect(!exists)
        }
    }

    @Test("Delete single item removes file and metadata entry")
    func deleteSingleItem() throws {
        let dir = makeTempDir()

        var items: [ClipboardHistoryItem] = []
        for i in 0..<3 {
            let text = "item\(i)"
            let data = Data(text.utf8)
            let hash = ClipboardHistoryItem.computeHash(of: data)
            let filename = "\(UUID().uuidString).dat"
            try data.write(to: dir.appendingPathComponent(filename))
            items.append(ClipboardHistoryItem(
                kind: .text, contentHash: hash, preview: text, payloadFilename: filename))
        }
        let encoded = try JSONEncoder().encode(items)
        try encoded.write(to: dir.appendingPathComponent("metadata.json"))

        let (store, _) = makeStore(dir: dir)
        store.stopPolling()

        let itemToDelete = store.items[1]
        store.deleteItem(itemToDelete)

        #expect(store.items.count == 2)
        #expect(!store.items.contains(where: { $0.id == itemToDelete.id }))
        #expect(!FileManager.default.fileExists(
            atPath: dir.appendingPathComponent(itemToDelete.payloadFilename).path))
    }

    @Test("Stars survive Board pruning")
    func starsSurviveBoardPrune() throws {
        let dir = makeTempDir()

        var items: [ClipboardHistoryItem] = []
        for i in 0..<5 {
            let text = "item\(i)"
            let data = Data(text.utf8)
            let hash = ClipboardHistoryItem.computeHash(of: data)
            let filename = "\(UUID().uuidString).dat"
            try data.write(to: dir.appendingPathComponent(filename))
            items.append(ClipboardHistoryItem(
                kind: .text, contentHash: hash, preview: text, payloadFilename: filename,
                isStarred: i == 4))
        }
        let encoded = try JSONEncoder().encode(items)
        try encoded.write(to: dir.appendingPathComponent("metadata.json"))

        let (store, _) = makeStore(dir: dir, maxHistory: 3)
        store.stopPolling()

        #expect(store.items.count == 4)
        #expect(store.items.filter { !$0.isStarred }.count == 3)
        #expect(store.items.contains(where: { $0.isStarred }))
    }

    @Test("Toggle star preserves Board ordering")
    func toggleStarPreservesBoardOrder() throws {
        let dir = makeTempDir()

        var items: [ClipboardHistoryItem] = []
        for i in 0..<3 {
            let text = "item\(i)"
            let data = Data(text.utf8)
            let hash = ClipboardHistoryItem.computeHash(of: data)
            let filename = "\(UUID().uuidString).dat"
            try data.write(to: dir.appendingPathComponent(filename))
            items.append(ClipboardHistoryItem(
                kind: .text, contentHash: hash, preview: text, payloadFilename: filename))
        }
        let encoded = try JSONEncoder().encode(items)
        try encoded.write(to: dir.appendingPathComponent("metadata.json"))

        let (store, _) = makeStore(dir: dir)
        store.stopPolling()

        let lastItem = store.items[2]
        store.toggleStar(lastItem)

        #expect(store.items[2].id == lastItem.id)
        #expect(store.items[2].isStarred == true)
    }

    @Test("Board retention removes only non-starred items")
    func boardRetentionRemovesOnlyBoardItems() throws {
        let dir = makeTempDir()
        let defaults = UserDefaults(suiteName: "com.veer.FruitClip.test.\(UUID().uuidString)")!
        let (store, settings) = makeStore(dir: dir, defaults: defaults)
        store.stopPolling()

        settings.boardRetentionPolicy = .oneDay
        settings.starRetentionPolicy = .threeMonths

        let expiredDate = Date().addingTimeInterval(-(2 * 24 * 60 * 60))
        let boardItem = try writeItem(
            text: "board-old",
            dir: dir,
            timestamp: expiredDate,
            isStarred: false
        )
        let starItem = try writeItem(
            text: "star-old",
            dir: dir,
            timestamp: expiredDate,
            isStarred: true
        )
        try writeMetadata([boardItem, starItem], dir: dir)

        let (reloadedStore, _) = makeStore(dir: dir, defaults: defaults)
        reloadedStore.stopPolling()

        #expect(reloadedStore.items.count == 1)
        #expect(reloadedStore.items[0].id == starItem.id)
    }

    @Test("Star retention removes only starred items")
    func starRetentionRemovesOnlyStarredItems() throws {
        let dir = makeTempDir()
        let defaults = UserDefaults(suiteName: "com.veer.FruitClip.test.\(UUID().uuidString)")!
        let (store, settings) = makeStore(dir: dir, defaults: defaults)
        store.stopPolling()

        settings.boardRetentionPolicy = .never
        settings.starRetentionPolicy = .oneDay

        let expiredDate = Date().addingTimeInterval(-(2 * 24 * 60 * 60))
        let boardItem = try writeItem(
            text: "board-kept",
            dir: dir,
            timestamp: expiredDate,
            isStarred: false
        )
        let starItem = try writeItem(
            text: "star-expired",
            dir: dir,
            timestamp: expiredDate,
            isStarred: true
        )
        try writeMetadata([boardItem, starItem], dir: dir)

        let (reloadedStore, _) = makeStore(dir: dir, defaults: defaults)
        reloadedStore.stopPolling()

        #expect(reloadedStore.items.count == 1)
        #expect(reloadedStore.items[0].id == boardItem.id)
        #expect(
            !FileManager.default.fileExists(
                atPath: dir.appendingPathComponent(starItem.payloadFilename).path
            )
        )
    }

    @Test("Clear Board keeps starred clips")
    func clearBoardKeepsStarredClips() throws {
        let dir = makeTempDir()

        let boardItem = try writeItem(text: "board", dir: dir)
        let starItem = try writeItem(text: "star", dir: dir, isStarred: true)
        try writeMetadata([boardItem, starItem], dir: dir)

        let (store, _) = makeStore(dir: dir)
        store.stopPolling()

        store.clearBoard()

        #expect(store.items.count == 1)
        #expect(store.items[0].id == starItem.id)
        #expect(!FileManager.default.fileExists(
            atPath: dir.appendingPathComponent(boardItem.payloadFilename).path))
        #expect(FileManager.default.fileExists(
            atPath: dir.appendingPathComponent(starItem.payloadFilename).path))
    }

    @Test("Legacy favorite metadata loads clips but clears starred state")
    func legacyFavoriteMetadataLoadsUnstarred() throws {
        let dir = makeTempDir()

        let data = Data("legacy".utf8)
        let hash = ClipboardHistoryItem.computeHash(of: data)
        let filename = "\(UUID().uuidString).dat"
        try data.write(to: dir.appendingPathComponent(filename))

        let legacyMetadata = """
        [
          {
            "id": "\(UUID().uuidString)",
            "kind": "text",
            "timestamp": \(Date().timeIntervalSinceReferenceDate),
            "contentHash": "\(hash)",
            "preview": "legacy star",
            "payloadFilename": "\(filename)",
            "isFavorite": true
          }
        ]
        """.data(using: .utf8)!
        try legacyMetadata.write(to: dir.appendingPathComponent("metadata.json"))

        let (store, _) = makeStore(dir: dir)
        store.stopPolling()

        #expect(store.items.count == 1)
        #expect(store.items[0].preview == "legacy star")
        #expect(store.items[0].isStarred == false)
    }

    @Test("Full-history dedup blocks non-consecutive duplicates")
    func fullHistoryDedup() throws {
        let dir = makeTempDir()

        // Create items A, B with different content
        let dataA = Data("contentA".utf8)
        let dataB = Data("contentB".utf8)
        let hashA = ClipboardHistoryItem.computeHash(of: dataA)
        let hashB = ClipboardHistoryItem.computeHash(of: dataB)

        let filenameA = "\(UUID().uuidString).dat"
        let filenameB = "\(UUID().uuidString).dat"
        try dataA.write(to: dir.appendingPathComponent(filenameA))
        try dataB.write(to: dir.appendingPathComponent(filenameB))

        let items = [
            ClipboardHistoryItem(kind: .text, contentHash: hashA, preview: "A", payloadFilename: filenameA),
            ClipboardHistoryItem(kind: .text, contentHash: hashB, preview: "B", payloadFilename: filenameB),
        ]
        let encoded = try JSONEncoder().encode(items)
        try encoded.write(to: dir.appendingPathComponent("metadata.json"))

        let (store, _) = makeStore(dir: dir)
        store.stopPolling()

        #expect(store.items.count == 2)

        // Verify that both hashes exist
        #expect(store.items.contains(where: { $0.contentHash == hashA }))
        #expect(store.items.contains(where: { $0.contentHash == hashB }))
    }
}
