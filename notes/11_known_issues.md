# FruitClip — Known Issues

## Medium

| Issue | Detail | Source |
|-------|--------|--------|
| `ThumbnailCache` uses deprecated `lockFocus/unlockFocus` | Both sync and async paths draw thumbnails via the deprecated NSImage focus API. Works on macOS 15 but should be migrated to `NSBitmapImageRep`-based drawing. | `ThumbnailCache.swift:37-41`, `66-71` — Confirmed from code |
| Launch at Login silently fails | `SMAppService.register()` errors are caught and discarded. No user feedback if login item registration fails (e.g., when running outside a proper .app bundle). | `PreferencesWindow.swift:155-163` — Confirmed from code |
| Hotkey recorder has no conflict detection | If the user records a hotkey already registered by another app or macOS, `RegisterEventHotKey` will silently fail or steal the combo. No warning shown. | `GlobalHotkeyManager.swift` — Confirmed from code |
| Image items excluded from search with no UX indication | The filter only matches `.text` items. A user searching while an image is selected may be confused why images disappear. | `ClipboardPopupView.swift:21-24` — Confirmed from code |
| `metadata.json` has no schema version | If `ClipboardHistoryItem` fields change, old JSON files will silently fail to decode (`items = []` fallback). History lost on model changes. | `ClipboardHistoryStore.swift:234-245` — Confirmed from code |
| Dismiss-on-mouse-move threshold may be hair-trigger | 10px accumulated delta is very low, especially on trackpads with high-resolution scroll events. Real-world usability not validated. | `PopupPanelController.swift:79` — Strongly inferred |

## Low

| Issue | Detail | Source |
|-------|--------|--------|
| No notarization | Cannot distribute to other machines without Gatekeeper warnings. | `build.sh` — Confirmed from code |
| No CI/CD | Tests only run manually via `swift test`. No automated verification on commit. | Not found in repository |
| Version hardcoded in build.sh | `VERSION="1.0"` in `build.sh` — no automated bump, no git tag integration. | `build.sh:5` — Confirmed from code |
| Carbon API deprecated | `RegisterEventHotKey` is deprecated but stable. No timeline for removal from macOS, but worth tracking. | `GlobalHotkeyManager.swift` — Confirmed from code |
| `ClipboardHistoryStore` hardcodes `storageDir` path | Falls back to `applicationSupportDirectory` — only injectable for tests. If bundle ID changes, existing history is orphaned. | `ClipboardHistoryStore.swift:37-44` — Confirmed from code |
| `NSApp.activate(ignoringOtherApps: true)` usage | Called in `PreferencesWindowController.showWindow()`. The `ignoringOtherApps` parameter is deprecated in macOS 14+. | `PreferencesWindow.swift:27, 52` — Confirmed from code |
| Rich-text / file clipboard types not supported | Only `.string` (plain text) and `.tiff`/`.png` image types captured. RTF, HTML, file URLs silently ignored. | `ClipboardHistoryStore.importFromPasteboard()` — Confirmed from code |
