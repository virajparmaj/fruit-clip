import CryptoKit
import Foundation

// Wraps the item list with a schema version so future model changes can be migrated
// gracefully instead of silently falling back to an empty history.
struct StorageEnvelope: Codable {
    static let currentVersion = 1
    let schemaVersion: Int
    let items: [ClipboardHistoryItem]
}

struct ClipboardHistoryItem: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let kind: Kind
    let timestamp: Date
    let contentHash: String
    let preview: String
    let payloadFilename: String
    var isPinned: Bool

    enum Kind: String, Codable, Sendable {
        case text
        case image
    }

    init(kind: Kind, contentHash: String, preview: String, payloadFilename: String, isPinned: Bool = false) {
        self.id = UUID()
        self.kind = kind
        self.timestamp = Date()
        self.contentHash = contentHash
        self.preview = preview
        self.payloadFilename = payloadFilename
        self.isPinned = isPinned
    }

    static func computeHash(of data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
