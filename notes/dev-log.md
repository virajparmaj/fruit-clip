# FruitClip — Dev Log & Design Notes

_Last updated: 2026-04-19_

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

### Popup search & image render fix (`6f109a6`)
- **`ThumbnailCache.loadThumbnailAsync()`** — async counterpart to the sync loader. Uses `.task(id: item.payloadFilename)` in `ClipboardItemRow`; drives SwiftUI re-render directly when thumbnail is ready. Replaces the poll-and-miss approach (the old sync path returned `nil` on first call and relied on the next poll cycle to redraw). `Confirmed from code`
- **Deferred search focus** — `isSearchFocused = true` wrapped in `DispatchQueue.main.async { }` so the window is fully key before SwiftUI assigns first responder; fixes search not activating on popup open. `Confirmed from code`
- **Delete / digit key guards** — `onKeyPress(.delete)` and `onKeyPress(characters: "123456789")` both early-return `.ignored` when `isSearchFocused` is `true`, preventing key interception while typing in the search field. `Confirmed from code`
- **`build.sh` bundle copy** — added step to copy SPM resource bundle so `fruit-clip-status.png` resolves at runtime when run as a built `.app`. `Strongly inferred` from commit message ("copy spm bundle for fruit icon").

### Preferences window refinement (`c316141`)
- **"Check for Updates" section removed** — `UpdateStatus` enum, `GitHubRelease` struct, `currentVersion` computed property, and the `checkForUpdates()` async method all deleted. No in-app update checking. `Confirmed from code`
- **Hotkey badge restyled** — pill background switched to `.controlColor` (was `.controlBackgroundColor`), corner radius 6→7, shows "Press keys…" in accent color while recording. `Confirmed from code`
- **Window dimensions** — 400×420 → 420×370 (wider, shorter). `Confirmed from code`
- **Accessibility row spacing** refined in Preferences rows. `Strongly inferred` from commit message.

### Popup redesign (`49149eb`)
- **AnimatedGradientBorder** — `AngularGradient` with 5 blue stops, rotates 360° on 5s `repeatForever` linear animation. Double-layered: blurred outer (radius 6, opacity 0.7) + crisp inner (1.5pt stroke).
- Background switched to `.regularMaterial` (vibrancy) — removed shadow halos for cleaner glass feel
- Corner radii: dialog 12→16, selected row 6→10, image thumbnails 4→6
- Keyboard scroll wrapped in `withAnimation(.easeOut(duration: 0.2))`; `focusEffectDisabled()` on list
- **Search scoped to `.text` items** — image items excluded from filtered results (current working-tree state). `Confirmed from code`
- **Directional scroll anchor** — going down pins lookahead item to bottom edge; going up uses minimum scroll (no `anchor:` argument) to avoid position jumping. `Confirmed from code`

### Preferences height + status bar icon refinement (`8131e2a`, `efdfe4e`)
- Preferences window height bumped 370→480 to accommodate growing settings UI
- Status bar icon size increased 18→22px; added proper retina @2x representation
- Icon assets regenerated to match new dimensions

### Icon generation pipeline (`ba3d996`, `e405fd3`)
- **`scripts/generate_icons.sh`** — one-time generator; produces all standard macOS sizes (16–1024px) from source PNG using `sips`, with normalize+pad at 0.82/0.72 ratios
- **`assets/icons/macos/`** — pre-generated icon set checked into repo
- **`build.sh` updated** — icon normalization pipeline replaces simple `sips` resize; handles transparent padding for macOS icon guidelines
- Menubar icons reverted to `fruit-clip-status.png` / `@2x.png` names at 22×22px after experimenting with separate `menubar.png` assets

### Install scripts + polish (`6eec257`)
- **`VERSION` file** — single source of truth for version string; `build.sh` reads it first, falls back to `git describe`, then hardcoded `1.0`
- **`install.sh` / `uninstall.sh`** — deployment scripts: copy app to `/Applications`, verify signature, display installed version; uninstall removes app + support data
- **Hotkey conflict alert** — `GlobalHotkeyManager` surfaces a user-visible alert when registration fails, with a button to open Preferences
- **`StorageEnvelope`** — schema versioning wrapper for `ClipboardHistoryItem`; enables forward-compatible migrations
- Search filter corrected: non-text items no longer incorrectly excluded when query is empty
- Mouse dismiss threshold raised 10→50pts to reduce accidental dismissals
- Launch-at-login failure now rolls back the toggle and presents an alert rather than silently failing
- `NSApp.activate(ignoringOtherApps:)` deprecation warnings resolved

### Pre-publish repo hygiene (`36d9514`)
- MIT license added (`LICENSE`)
- `AGENTS.md` removed (was a duplicate of `CLAUDE.md`)
- `.gitignore` expanded: covers `*.xcuserstate`, `*.icns`, editor swap files, and other build artifacts

### Starred items + multi-shortcut system (`11b0654`)
- **Pin → Star rename** — `isPinned` replaced by `isStarred` throughout; popup gains a dedicated **Starred** tab alongside All
- **Multi-hotkey support** — `GlobalHotkeyManager` now handles multiple named actions (`openBoard`, `openStar`); each maps to an independent `ShortcutConfiguration`
- **`ShortcutConfiguration`** (`SettingsModels.swift`) — `Codable` struct replacing the flat `keyCode`/`modifiers` pair; defaults defined as static constants
- **`PopupKeyboardRouter`** extracted from `ClipboardPopupView` — owns all keyboard handling logic, eliminating the massive `onKeyPress` chain
- **`PopupScrollPlanner`** extracted — encapsulates directional scroll anchor decisions
- **`SettingsModels.swift`** added — `ShortcutConfiguration`, `RetentionPolicy` (1 day → never), `PopupFontSize` (11–15pt, default 12)
- **Expanded Preferences UI** — per-action shortcut recorders, retention policy picker, font size slider
- **New test suites** — `GlobalHotkeyManagerTests`, `PopupKeyboardRouterTests`, `PopupScrollPlannerTests`

### Image preview polish + fixes (`110003b`)
- Proportional thumbnails up to 600px wide (replaces fixed 64×64 crop)
- Image rows expand to fit content; aspect ratio mode changed to `.fit`
- Separate row layout for image vs text items in the popup list
- Popup overlay background opacity deepened to 0.55 for better contrast
- Nil-guard added on selection reset when popup activates

---

## Popup Keyboard Map

| Key | Action |
|-----|--------|
| ↑ / ↓ | Navigate |
| Return | Paste selected |
| D (default) | Remove selected |
| S (default) | Toggle star |
| F (default) | Switch to Starred tab |
| ⌘C (default) | Copy without pasting |
| ⌘F (default) | Jump to search |
| 1–9 | Direct paste by index |
| Esc | Clear search / dismiss |

_Shortcuts are configurable in Preferences. Defaults defined in `ShortcutConfiguration`._

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
- Launch at login (`ServiceManagement`) wired; error rollback added but real-world testing needed
- No CI/CD pipeline
- `ThumbnailCache` uses `lockFocus/unlockFocus` (both sync and async paths) which is deprecated in favor of `NSBitmapImageRep`-based drawing — works fine for now
- `dismissOnMouseMove` implemented in `PopupPanelController`; behavior needs real-world testing
- Per-action shortcut recorders in Preferences do not validate conflicts with system hotkeys or other registered actions
