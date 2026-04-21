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
       ├─ SettingsStore         — UserDefaults wrapper, @Published settings + 9 ShortcutConfigurations
       ├─ ClipboardHistoryStore — NSPasteboard polling, versioned file persistence (StorageEnvelope v3)
       │    └─ ThumbnailCache   — NSCache<NSString, NSImage>, singleton (NSBitmapImageRep render)
       ├─ GlobalHotkeyManager   — Carbon hotkey registration (Open Board + optional Open Star)
       ├─ PopupPanelController  — FloatingPanel lifecycle, event monitors, PopupPresentationState
       │    └─ ClipboardPopupView (SwiftUI)
       │         ├─ PopupTabPicker (Board / Star)
       │         ├─ PopupKeyboardRouter — pure key-event → command state machine
       │         ├─ PopupScrollPlanner — scroll anchor planning
       │         └─ ClipboardItemRow (SwiftUI)
       ├─ PasteController       — clipboard restore + CGEvent Cmd+V
       ├─ StatusItemController  — NSStatusItem + NSMenu
       └─ PreferencesWindowController
            └─ PreferencesView (SwiftUI) — sidebar layout (General / Shortcuts / Storage / Accessibility)
                 └─ ShortcutRecorderView (NSViewRepresentable, modal key capture)
```

## Wiring pattern

**Confirmed from code** — All cross-component communication uses closures set at init time in `AppCoordinator`:
- `popupController.onItemSelected` → `pasteController.pasteItem()`
- `popupController.onItemCopied` → `pasteController.copyItemOnly()`
- `popupController.onItemDeleted` → `historyStore.deleteItem()`
- `popupController.onItemStarToggled` → `historyStore.toggleStar()`
- `hotkeyManager.onActivate(.openBoard | .openStar)` → `togglePopup(initialTab:)`
- `hotkeyManager.onRegistrationFailed(message)` → modal alert + open Settings

No shared mutable state between components. No notifications. No Combine pipelines (beyond `@Published` in `SettingsStore` and `ClipboardHistoryStore`, and the per-popup `PopupPresentationState`).

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
├── metadata.json          — StorageEnvelope { schemaVersion: 3, items: [...] } (JSON, no payload data)
└── <UUID>.dat             — one file per item (raw text UTF-8 or TIFF/PNG bytes)
```

`loadMetadata()` first tries to decode the versioned `StorageEnvelope`; if that fails, it falls back to the legacy unversioned `[ClipboardHistoryItem]` array and re-saves immediately in the new envelope format. This makes `metadata.json` schema changes safely migratable.

UserDefaults suite: `com.veer.FruitClip` (standard `.standard` in current code — `Strongly inferred` same domain).

## Third-party services

None. Fully offline, local-only.

## Notable constraints

- macOS 15.0+ minimum (set in `Package.swift` and `Info.plist`)
- `LSUIElement = true` — no Dock icon, menu bar agent only
- Accessibility permission required for CGEvent auto-paste; gracefully degrades to clipboard-only without it
- Carbon hotkey API is deprecated but stable on macOS 15
- `SettingsModels.swift` defines the value types shared across SettingsStore and the recorder UI: `ShortcutConfiguration` (Codable `keyCode`+`modifiers`), `RetentionPolicy` (oneDay/oneWeek/oneMonth/threeMonths/never), `PopupFontSize` (min/default/max constants)
