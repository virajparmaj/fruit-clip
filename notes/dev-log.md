# FruitClip — Dev Log & Design Notes

_Last updated: 2026-03-25_

---

## Current State

FruitClip is a working native macOS menu bar clipboard manager. All core features are implemented and functional. No CI/CD, no notarization.

**Build:** `./build.sh` → produces `FruitClip.app/` with ad-hoc signing
**Storage:** `~/Library/Application Support/com.veer.FruitClip/` — `metadata.json` + `.dat` payload files
**Settings:** UserDefaults suite `com.veer.FruitClip`

---

## Feature Changelog (post v1)

### Menu bar icon (`90e1aa5`)
- Added custom `fruit-clip-status.png` / `@2x.png` assets (18×18) loaded via `Bundle.module`
- Falls back to `paperclip` SF Symbol if asset missing
- `isTemplate = false` — preserves color tint rather than rendering as template mask

### Hotkey support + storage optimization (`2c6e92f`)
- **HotkeyFormatter** — Carbon key code → readable string (⌘⇧V style). Handles A–Z, 0–9, F1–F12, arrows, navigation keys. `cocoaToCarbonModifiers()` converts NSEvent flags to Carbon bitmask.
- **ThumbnailCache** — singleton `NSCache<NSString, NSImage>` (limit: 100). Async load from disk on `userInitiated` QoS, renders 64×64 thumb via `lockFocus/unlockFocus`. Returns `nil` on first call (cache miss triggers background load; SwiftUI redraws on next poll).
- **Storage refactor** — `ClipboardHistoryStore` gained `beginPasteboardWrite()` / `endPasteboardWrite(changeCount:)` to suppress self-capture. Tracks `lastSelfChangeCount` to skip own pasteboard writes (0.2s debounce window).
- **Adaptive polling** — single-fire `Timer` rescheduled after each tick. Active: 300ms, idle: 1500ms (idle threshold: 30s from `lastActivityTime`). Avoids `repeats: true` drift.
- **Prune strategy** — unpinned items removed last; pinned items survive past the `maxHistoryCount` cap.
- **Orphan cleanup** — on init, any `.dat` files not in `metadata.json` are deleted.
- **SettingsStore additions** — `dismissOnMouseMove` (Bool), `maxHistoryCount` clamped 1–100, hotkey key code + modifiers persisted separately.
- **PreferencesWindow** — hotkey recorder via `NSEvent.addLocalMonitorForEvents`, live key capture with modifier display.
- **Test coverage** — XCTest suites: `ClipboardHistoryItemTests`, `ClipboardHistoryStoreIntegrationTests`, `ElapsedStringTests`, `HotkeyFormatterTests`, `SettingsStoreTests`, `TextPreviewTests`.

### App icon (`ed10914`)
- `build.sh` generates `.icns` via `sips` + `iconutil` (all standard macOS sizes from `fruit-clip.png`)
- `CFBundleIconFile` set in `Info.plist` — icon shows in Finder/Dock
- Skips gracefully if source PNG absent

### Popup redesign (`49149eb`)
- **AnimatedGradientBorder** — `AngularGradient` with 5 blue stops, rotates 360° on 5s `repeatForever` linear animation. Double-layered: blurred outer (radius 6, opacity 0.7) + crisp inner (1.5pt stroke).
- Background switched to `.regularMaterial` (vibrancy) — removed shadow halos for cleaner glass feel
- Corner radii: dialog 12→16, selected row 6→10, image thumbnails 4→6
- Keyboard scroll wrapped in `withAnimation(.easeOut(duration: 0.2))`; `focusEffectDisabled()` on list

---

## Popup Keyboard Map

| Key | Action |
|-----|--------|
| ↑ / ↓ | Navigate |
| Return | Paste selected |
| Delete | Remove selected |
| ⌘P | Toggle pin |
| ⌘C | Copy without pasting |
| ⌘F | Jump to search |
| 1–9 | Direct paste by index |
| Esc | Clear search / dismiss |

---

## Key Design Decisions

**Why separate `.dat` files per item?**
Payload data (especially images/TIFF) can be large. Storing each payload in its own file avoids loading the entire history into memory. `metadata.json` stays small (just previews, hashes, metadata); payloads loaded on-demand.

**Why SHA256 dedup?**
Prevents storing the same content multiple times (e.g., re-copying the same URL). Hash is computed over raw payload bytes, so text and image dedup both work the same way.

**Why Carbon API for hotkeys?**
CGEvent tap requires Accessibility permission. Carbon `RegisterEventHotKey` works system-wide without that permission, registering a global hotkey cleanly. Downside: Carbon is technically deprecated but remains stable on macOS 15.

**Why NSCache for thumbnails instead of a dictionary?**
`NSCache` auto-evicts under memory pressure without needing manual LRU bookkeeping. 100-item limit is generous given 64×64px thumbs are tiny (~12KB each).

**Why callback-based wiring?**
`AppCoordinator` passes closures between components at init time rather than using shared state or notifications. Makes data flow explicit and keeps components testable in isolation.

---

## Known Issues / TODOs

- No notarization — can't distribute outside dev machines without it
- Launch at login (`ServiceManagement`) wired but may need polish/testing
- No CI/CD pipeline
- `ThumbnailCache` uses `lockFocus/unlockFocus` which is deprecated in favor of `NSBitmapImageRep`-based drawing — works fine for now
- `dismissOnMouseMove` setting exists in `SettingsStore` but implementation in `PopupPanelController` needs verification
- Hotkey recorder in Preferences doesn't validate conflicts with system hotkeys
