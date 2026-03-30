# FruitClip — API Contracts

## No network API

**Not found in repository** — FruitClip has no server, no REST/GraphQL endpoints, no external API calls, and no network stack.

## Internal component interfaces (Swift)

These are the cross-component contracts enforced in code.

### ClipboardHistoryStore public surface

**Confirmed from code** (`ClipboardHistoryStore.swift`):

```swift
// Observable state
@Published private(set) var items: [ClipboardHistoryItem]

// Mutations
func deleteItem(_ item: ClipboardHistoryItem)
func togglePin(_ item: ClipboardHistoryItem)
func clearAll()

// Payload access
func loadPayload(for item: ClipboardHistoryItem) -> Data?
func payloadURL(for item: ClipboardHistoryItem) -> URL

// Polling control
func startPolling()
func stopPolling()

// Self-capture prevention
func beginPasteboardWrite()
func endPasteboardWrite(changeCount: Int)
```

### ClipboardHistoryItem model

**Confirmed from code** (`ClipboardHistoryItem.swift`):

```swift
struct ClipboardHistoryItem: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let kind: Kind          // .text | .image
    let timestamp: Date
    let contentHash: String // SHA256 hex, 64 chars
    let preview: String     // text summary or "Image WxH"
    let payloadFilename: String  // UUID.dat
    var isPinned: Bool
}
```

### PopupPanelController callbacks

**Confirmed from code** (`PopupPanelController.swift`):

```swift
var onItemSelected: ((ClipboardHistoryItem) -> Void)?   // paste + dismiss
var onItemCopied: ((ClipboardHistoryItem) -> Void)?     // copy only, dismiss
var onItemDeleted: ((ClipboardHistoryItem) -> Void)?    // remove from history
var onItemPinToggled: ((ClipboardHistoryItem) -> Void)? // toggle pin
```

### SettingsStore persisted keys

**Confirmed from code** (`SettingsStore.swift`):

| Key | Type | Default |
|-----|------|---------|
| `hotkeyKeyCode` | UInt32 | `0x09` (V) |
| `hotkeyModifiers` | UInt32 | `cmdKey \| shiftKey` |
| `launchAtLogin` | Bool | false |
| `isPaused` | Bool | false |
| `isFirstLaunch` | Bool | true |
| `maxHistoryCount` | Int | 50 (clamped 1–100) |
| `dismissOnMouseMove` | Bool | false |

### metadata.json schema

**Confirmed from code** — JSON array of `ClipboardHistoryItem` (Codable). Written by `JSONEncoder`, read by `JSONDecoder`. No versioning field — forward/backward compat risk if model fields change.
