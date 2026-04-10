import CryptoKit
import Foundation

// Wraps the item list with a schema version so future model changes can be migrated
// gracefully instead of silently falling back to an empty history.
struct StorageEnvelope: Codable {
    static let currentVersion = 3
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
    var isStarred: Bool

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case timestamp
        case contentHash
        case preview
        case payloadFilename
        case isStarred
    }

    enum Kind: String, Codable, Sendable {
        case text
        case image
    }

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        kind: Kind,
        contentHash: String,
        preview: String,
        payloadFilename: String,
        isStarred: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.timestamp = timestamp
        self.contentHash = contentHash
        self.preview = preview
        self.payloadFilename = payloadFilename
        self.isStarred = isStarred
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        kind = try container.decode(Kind.self, forKey: .kind)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        contentHash = try container.decode(String.self, forKey: .contentHash)
        preview = try container.decode(String.self, forKey: .preview)
        payloadFilename = try container.decode(String.self, forKey: .payloadFilename)
        isStarred = try container.decodeIfPresent(Bool.self, forKey: .isStarred) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(kind, forKey: .kind)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(contentHash, forKey: .contentHash)
        try container.encode(preview, forKey: .preview)
        try container.encode(payloadFilename, forKey: .payloadFilename)
        try container.encode(isStarred, forKey: .isStarred)
    }

    static func computeHash(of data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
