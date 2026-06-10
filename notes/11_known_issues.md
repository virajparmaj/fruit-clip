# FruitClip — Known Issues

## Medium

| Issue | Detail | Source |
|-------|--------|--------|
| Image items excluded from search with no UX indication | The filter only matches `.text` items. A user searching while an image is selected may be confused why images disappear. | `ClipboardPopupView.swift:31-40` — Confirmed from code |
| Single-key shortcut defaults are global within the popup, not the app | `starItem` (`S`), `deleteItem` (`D`), `switchToStar` (`F`) are bare keys with no modifier — fine inside the popup, but easy to record an unrecoverable combo if a user re-records a global open shortcut to a single key. | `SettingsModels.swift:13-15`, `ShortcutRecorderNSView` modes — Strongly inferred |

## Low

| Issue | Detail | Source |
|-------|--------|--------|
| No notarization | Cannot distribute to other machines without Gatekeeper warnings (although `install.sh` clears the quarantine flag for the local-build flow). | `build.sh`, `install.sh:131-134` — Confirmed from code |
| No CI/CD | Tests only run manually via `swift test`. No automated verification on commit. | Not found in repository |
| Carbon API deprecated | `RegisterEventHotKey` is deprecated but stable. No timeline for removal from macOS, but worth tracking. | `GlobalHotkeyManager.swift` — Confirmed from code |
| `ClipboardHistoryStore` hardcodes `storageDir` path | Falls back to `applicationSupportDirectory` — only injectable for tests. If bundle ID changes, existing history is orphaned. | `ClipboardHistoryStore.swift:36-43` — Confirmed from code |
| Rich-text / file clipboard types not supported | Only `.string` (plain text) and `.tiff`/`.png` image types captured. RTF, HTML, file URLs silently ignored. | `ClipboardHistoryStore.importFromPasteboard()` — Confirmed from code |
| `clearAll()` is unreachable from the UI | `ClipboardHistoryStore.clearAll()` exists but only `clearBoard()` is wired to the menu and Settings button — there is currently no in-app way to wipe starred items in bulk. | `AppCoordinator.swift:65,101-113` — Confirmed from code |

## Resolved since v1 (kept here for git context)

- `ThumbnailCache` migrated from deprecated `lockFocus/unlockFocus` to `NSBitmapImageRep` offscreen rendering (`ThumbnailCache.swift:62`).
- `metadata.json` is now wrapped in `StorageEnvelope` (schema v3) with automatic legacy-array migration (`ClipboardHistoryStore.swift:283-306`).
- Launch at Login surfaces failures in a user-visible alert and reverts the toggle (`PreferencesWindow.swift:521-542`).
- Hotkey conflict detection ships: `GlobalHotkeyManager.onRegistrationFailed` triggers a "Shortcut Conflict" alert and opens Settings (`GlobalHotkeyManager.swift:75-82`, `AppCoordinator.swift:51-58`).
- Build version is no longer hardcoded — `build.sh` reads the `VERSION` file (with `git describe` fallback, then literal `1.0`) (`build.sh:7-13`).
- Deprecated `NSApp.activate(ignoringOtherApps:)` is gone; the codebase now uses the no-arg `NSApp.activate()` (`PreferencesWindow.swift:83,111`).
- Dismiss-on-mouse-move threshold raised from 10pt to 50pt to stop hair-triggering on high-resolution trackpads (`PopupPanelController.swift:46-47`).
