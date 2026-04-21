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
func toggleStar(_ item: ClipboardHistoryItem)
func clearAll()                                      // wipes everything (starred + board)
func clearBoard()                                    // wipes only non-starred items
func refreshStoragePolicies()                        // re-applies retention + count pruning

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
    var isStarred: Bool          // backward-compat: decodes as false if missing
}

// Wrapper persisted to metadata.json
struct StorageEnvelope: Codable {
    static let currentVersion = 3
    let schemaVersion: Int
    let items: [ClipboardHistoryItem]
}
```

### PopupPanelController callbacks

**Confirmed from code** (`PopupPanelController.swift`):

```swift
var onItemSelected: ((ClipboardHistoryItem) -> Void)?    // paste + dismiss
var onItemCopied: ((ClipboardHistoryItem) -> Void)?      // copy only, dismiss
var onItemDeleted: ((ClipboardHistoryItem) -> Void)?     // remove from history
var onItemStarToggled: ((ClipboardHistoryItem) -> Void)? // toggle star

// Show/toggle is parameterised by initial tab (.board or .star)
func toggle(initialTab: PopupTab, historyStore:, settingsStore:)
func show(historyStore:, settingsStore:, initialTab:)
```

### SettingsStore persisted keys

**Confirmed from code** (`SettingsStore.swift`):

| Key | Type | Default |
|-----|------|---------|
| `openBoardShortcut` | `ShortcutConfiguration` (JSON-encoded) | `⌘⇧V` (`keyCode 0x09`, `cmdKey \| shiftKey`) |
| `openStarShortcut` | `ShortcutConfiguration?` (JSON-encoded, optional) | unset |
| `openStarShortcutEnabled` | Bool | false |
| `starItemShortcut` | `ShortcutConfiguration` | `S` (`keyCode 0x01`, no modifier) |
| `deleteItemShortcut` | `ShortcutConfiguration` | `D` (`keyCode 0x02`, no modifier) |
| `switchToStarShortcut` | `ShortcutConfiguration` | `F` (`keyCode 0x03`, no modifier) |
| `copySelectedShortcut` | `ShortcutConfiguration` | `⌘C` (`keyCode 0x08`, `cmdKey`) |
| `focusSearchShortcut` | `ShortcutConfiguration` | `⌘F` (`keyCode 0x03`, `cmdKey`) |
| `launchAtLogin` | Bool | false |
| `isPaused` | Bool | false |
| `isFirstLaunch` | Bool | true |
| `maxHistoryCount` | Int | 50 (clamped 1–100) |
| `popupFontSize` | Int | 12 (clamped to `PopupFontSize.min..max` = 11..15) |
| `dismissOnMouseMove` | Bool | false |
| `boardRetentionPolicy` | `RetentionPolicy.rawValue` | `oneWeek` |
| `starRetentionPolicy` | `RetentionPolicy.rawValue` | `oneMonth` |

Legacy `hotkeyKeyCode` / `hotkeyModifiers` are still read once on first launch and migrated into `openBoardShortcut`.

`SettingsStore.activeOpenStarShortcut` returns the open-star shortcut only when both the value is set and `openStarShortcutEnabled == true`.

### metadata.json schema

**Confirmed from code** — Persisted as `StorageEnvelope { schemaVersion, items }` (`ClipboardHistoryStore.saveMetadata()`). On load, the versioned envelope is tried first; if decoding fails, `loadMetadata()` falls back to the legacy unversioned `[ClipboardHistoryItem]` array and re-saves in the new format on the spot. Schema bumps require updating `StorageEnvelope.currentVersion`.
