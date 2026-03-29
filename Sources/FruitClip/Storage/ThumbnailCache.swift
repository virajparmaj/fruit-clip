import AppKit
import Foundation

@MainActor
final class ThumbnailCache {
    static let shared = ThumbnailCache()

    private let cache = NSCache<NSString, NSImage>()
    private var loadingKeys = Set<String>()

    private init() {
        cache.countLimit = 100
    }

    func thumbnail(for filename: String, storageDir: URL) -> NSImage? {
        if let cached = cache.object(forKey: filename as NSString) {
            return cached
        }

        guard !loadingKeys.contains(filename) else { return nil }
        loadingKeys.insert(filename)

        let fileURL = storageDir.appendingPathComponent(filename)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let imageData = try? Data(contentsOf: fileURL)
            DispatchQueue.main.async { @MainActor in
                guard let self else { return }
                self.loadingKeys.remove(filename)

                guard let imageData, let image = NSImage(data: imageData) else { return }

                // Resize to thumbnail
                let thumbSize = NSSize(width: 64, height: 64)
                let thumb = NSImage(size: thumbSize)
                thumb.lockFocus()
                image.draw(in: NSRect(origin: .zero, size: thumbSize),
                           from: NSRect(origin: .zero, size: image.size),
                           operation: .copy, fraction: 1.0)
                thumb.unlockFocus()

                self.cache.setObject(thumb, forKey: filename as NSString)
            }
        }

        return nil
    }

    // Async version for SwiftUI .task — drives view re-render when thumbnail is ready
    func loadThumbnailAsync(for filename: String, storageDir: URL) async -> NSImage? {
        if let cached = cache.object(forKey: filename as NSString) {
            return cached
        }

        let fileURL = storageDir.appendingPathComponent(filename)

        // Load raw data off the main thread
        guard let data = await Task.detached(priority: .userInitiated, operation: {
            try? Data(contentsOf: fileURL)
        }).value else { return nil }

        guard let image = NSImage(data: data) else { return nil }

        // Resize on @MainActor (AppKit requirement)
        let thumbSize = NSSize(width: 64, height: 64)
        let thumb = NSImage(size: thumbSize)
        thumb.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: thumbSize),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy, fraction: 1.0
        )
        thumb.unlockFocus()

        cache.setObject(thumb, forKey: filename as NSString)
        return thumb
    }

    func invalidate(filename: String) {
        cache.removeObject(forKey: filename as NSString)
        loadingKeys.remove(filename)
    }

    func invalidateAll() {
        cache.removeAllObjects()
        loadingKeys.removeAll()
    }
}
