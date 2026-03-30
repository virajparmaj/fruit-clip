# FruitClip — Architecture

## Stack

| Layer | Technology |
|-------|-----------|
| Language | Swift 6.0 (strict concurrency) |
| UI | SwiftUI + AppKit (NSPanel, NSStatusItem, NSWindow) |
| Global hotkey | Carbon framework (`RegisterEventHotKey`) |
| Hashing | CryptoKit (SHA256) |
| Login items | ServiceManagement (`SMAppService`) |
| Logging | `os.Logger` (subsystem: `com.veer.FruitClip`) |
| Build | Swift Package Manager + `build.sh` |
| Persistence | Local files (no database, no network) |
| Signing | Ad-hoc (`codesign --sign -`) |

## Component diagram

```
FruitClipApp (@main, SwiftUI App)
  └─ AppCoordinator (NSApplicationDelegate, @MainActor)
       ├─ SettingsStore         — UserDefaults wrapper, @Published settings
       ├─ ClipboardHistoryStore — NSPasteboard polling, file persistence
       │    └─ ThumbnailCache   — NSCache<NSString, NSImage>, singleton
       ├─ GlobalHotkeyManager   — Carbon hotkey registration
       ├─ PopupPanelController  — FloatingPanel lifecycle, event monitors
       │    └─ ClipboardPopupView (SwiftUI)
       │         └─ ClipboardItemRow (SwiftUI)
       ├─ PasteController       — clipboard restore + CGEvent Cmd+V
       ├─ StatusItemController  — NSStatusItem + NSMenu
       └─ PreferencesWindowController
            └─ PreferencesView (SwiftUI)
                 └─ HotkeyRecorderView (NSViewRepresentable)
```

## Wiring pattern

**Confirmed from code** — All cross-component communication uses closures set at init time in `AppCoordinator`:
- `popupController.onItemSelected` → `pasteController.pasteItem()`
- `popupController.onItemCopied` → `pasteController.copyItemOnly()`
- `popupController.onItemDeleted` → `historyStore.deleteItem()`
- `popupController.onItemPinToggled` → `historyStore.togglePin()`

No shared mutable state between components. No notifications. No Combine pipelines (beyond `@Published` in `SettingsStore` and `ClipboardHistoryStore`).

## Threading model

**Confirmed from code** — `@MainActor` on all core classes. The only off-main work is:
- `ThumbnailCache` — disk reads on `DispatchQueue.global(qos: .userInitiated)` or `Task.detached`
- `globalHotkeyCallback` (C function) — dispatches to main via `DispatchQueue.main.async`

## Data flow

```
NSPasteboard (system)
  → ClipboardHistoryStore.checkPasteboard()  [300ms / 1500ms poll]
  → addItem() → SHA256 dedup → write .dat file → append to items[]
  → saveMetadata() → metadata.json

User presses hotkey
  → Carbon callback → GlobalHotkeyManager.handleHotkey()
  → AppCoordinator.togglePopup()
  → PopupPanelController.show(items:)
  → ClipboardPopupView renders items[]

User selects item
  → onItemSelected closure → PasteController.pasteItem()
  → restoreToClipboard() → NSPasteboard.clearContents() + set data
  → previousApp.activate() → synthesizePaste() → CGEvent Cmd+V
```

## Storage layout

```
~/Library/Application Support/com.veer.FruitClip/
├── metadata.json          — [ClipboardHistoryItem] (JSON, no payload data)
└── <UUID>.dat             — one file per item (raw text UTF-8 or TIFF/PNG bytes)
```

UserDefaults suite: `com.veer.FruitClip` (standard `.standard` in current code — `Strongly inferred` same domain).

## Third-party services

None. Fully offline, local-only.

## Notable constraints

- macOS 15.0+ minimum (set in `Package.swift` and `Info.plist`)
- `LSUIElement = true` — no Dock icon, menu bar agent only
- Accessibility permission required for CGEvent auto-paste; gracefully degrades to clipboard-only without it
- Carbon hotkey API is deprecated but stable on macOS 15
