# FruitClip — Roadmap

## Recently shipped (post-v1, kept for context)

- [x] `ThumbnailCache` migrated from deprecated `lockFocus/unlockFocus` to `NSBitmapImageRep` offscreen rendering
- [x] User feedback when Launch at Login fails — `NSAlert` shown and the toggle is reverted (`PreferencesWindow.swift:521-542`)
- [x] Schema version field added to persistence — `StorageEnvelope` v3 with legacy-array migration (`ClipboardHistoryStore.swift:283-306`)
- [x] `NSApp.activate(ignoringOtherApps:)` deprecation removed — codebase now uses no-arg `NSApp.activate()`
- [x] Hotkey conflict detection — `RegisterEventHotKey` failure triggers a "Shortcut Conflict" alert and opens Settings (`GlobalHotkeyManager.swift:75-82`, `AppCoordinator.swift:51-58`)
- [x] Version automation — `build.sh` reads `VERSION` file (with `git describe` fallback, then literal `1.0`)
- [x] Dismiss-on-mouse-move threshold raised from 10pt to 50pt to stop hair-triggering on high-resolution trackpads
- [x] Pin → Star rename, dedicated Star tab, configurable per-action shortcuts
- [x] Install / uninstall scripts (`install.sh`, `uninstall.sh --wipe-data`)

## Short-term improvements

- [ ] Indicate in search UI that image items are excluded from search (or add image search by metadata string)
- [ ] Configurable `dismissOnMouseMove` threshold in Preferences (currently a hardcoded 50pt constant)
- [ ] Set up basic CI with GitHub Actions: `swift build` + `swift test` on PR
- [ ] Surface `clearAll()` in the UI (currently only `clearBoard` is wired — no in-app way to wipe stars in bulk)

## Medium-term improvements

- [ ] Notarization pipeline — Developer ID signing + `xcrun notarytool` for distribution outside dev machines
- [ ] Rich text clipboard support (RTF, HTML pasteboard types)
- [ ] File/URL clipboard type capture
- [ ] Configurable storage location (beyond hardcoded `applicationSupportDirectory`)
- [ ] Keyboard shortcut to open Preferences directly from the popup

## Long-term enhancements

- [ ] App Store distribution (requires sandbox review, entitlements audit)
- [ ] iCloud sync for clipboard history across Macs
- [ ] Sparkle-based auto-update
- [ ] Collections / folder-style organization for starred items
- [ ] Quick Look preview for images in popup
- [ ] Plain-text stripping for rich text pastes

## Architecture / infra hardening

- [ ] Replace Carbon `RegisterEventHotKey` with a modern alternative (if Apple provides one before Carbon is fully removed)
- [ ] Consider entitlements review if App Store submission becomes a goal

## Product polish

- [ ] Onboarding flow explaining keyboard shortcuts on first launch (beyond just opening Preferences)
- [ ] Visual indicator in menu bar icon when monitoring is paused
- [ ] "Copy without pasting" (`copySelectedShortcut`, default ⌘C in popup) should show a brief confirmation toast
- [ ] Accessibility: announce paste action via `NSAccessibility` for VoiceOver users
