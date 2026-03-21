import CryptoKit
import Foundation

struct ClipboardHistoryItem: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let kind: Kind
    let timestamp: Date
    let contentHash: String
    let preview: String
    let payloadFilename: String

    enum Kind: String, Codable, Sendable {
        case text
        case image
    }

    init(kind: Kind, contentHash: String, preview: String, payloadFilename: String) {
        self.id = UUID()
        self.kind = kind
        self.timestamp = Date()
        self.contentHash = contentHash
        self.preview = preview
        self.payloadFilename = payloadFilename
    }

    static func computeHash(of data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
