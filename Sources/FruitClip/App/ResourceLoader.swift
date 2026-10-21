import AppKit
import Foundation

enum ResourceLoader {
    /// Safely resolves the URL for an application resource without invoking SPM's `Bundle.module`,
    /// which causes a fatal crash when running inside a macOS .app bundle if the resource bundle
    /// is located in Contents/Resources.
    static func url(forResource name: String, withExtension ext: String) -> URL? {
        // 1. Look directly in the main app bundle's Contents/Resources
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return url
        }

        // 2. Look inside a nested SPM bundle in Contents/Resources
        if let spmBundleURL = Bundle.main.url(forResource: "FruitClip_FruitClip", withExtension: "bundle"),
           let spmBundle = Bundle(url: spmBundleURL),
           let url = spmBundle.url(forResource: name, withExtension: ext) {
            return url
        }

        // 3. Look adjacent to the executable bundle
        let adjacentBundle = Bundle.main.bundleURL.appendingPathComponent("FruitClip_FruitClip.bundle")
        if let bundle = Bundle(url: adjacentBundle),
           let url = bundle.url(forResource: name, withExtension: ext) {
            return url
        }

        let adjacentFile = Bundle.main.bundleURL.appendingPathComponent("\(name).\(ext)")
        if FileManager.default.fileExists(atPath: adjacentFile.path) {
            return adjacentFile
        }

        // 4. Fallback to source tree for debug / swift run
        let sourcePath = "Sources/FruitClip/Resources/\(name).\(ext)"
        if FileManager.default.fileExists(atPath: sourcePath) {
            return URL(fileURLWithPath: sourcePath)
        }

        return nil
    }
}
