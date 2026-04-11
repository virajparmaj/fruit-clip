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

                guard let thumb = ThumbnailCache.makeThumbnail(from: image, maxDimension: 600) else { return }
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
        guard let thumb = ThumbnailCache.makeThumbnail(from: image, maxDimension: 600) else { return nil }
        cache.setObject(thumb, forKey: filename as NSString)
        return thumb
    }

    // Offscreen render using NSBitmapImageRep — replaces the deprecated lockFocus/unlockFocus API.
    // Scales proportionally so the longer edge fits within maxDimension pixels.
    private static func makeThumbnail(from image: NSImage, maxDimension: CGFloat) -> NSImage? {
        let originalSize = image.size
        guard originalSize.width > 0, originalSize.height > 0 else { return nil }

        let scale: CGFloat
        if originalSize.width >= originalSize.height {
            scale = min(maxDimension / originalSize.width, 1.0)
        } else {
            scale = min(maxDimension / originalSize.height, 1.0)
        }

        let thumbSize = NSSize(
            width: round(originalSize.width * scale),
            height: round(originalSize.height * scale)
        )

        let width = Int(thumbSize.width)
        let height = Int(thumbSize.height)
        guard width > 0, height > 0 else { return nil }

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(origin: .zero, size: thumbSize),
                   from: NSRect(origin: .zero, size: originalSize),
                   operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        let thumb = NSImage(size: thumbSize)
        thumb.addRepresentation(rep)
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
