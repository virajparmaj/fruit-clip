# FruitClip — Prompt Context for AI Agents

Use this file as orientation when working on FruitClip in a future session.

## What this app is

FruitClip is a native macOS menu bar clipboard manager written in Swift 6.0. It captures clipboard history (text + images), stores it locally, and lets the user paste previous clips via configurable global hotkeys with a popup that has Board and Star tabs. It has no server, no network, no accounts, and no external dependencies.

## Stack at a glance

- **Language:** Swift 6.0 strict concurrency, `@MainActor` throughout
- **UI:** SwiftUI + AppKit (NSPanel, NSStatusItem, NSWindow)
- **Hotkey:** Carbon framework (`RegisterEventHotKey`) — deprecated but stable
- **Build:** `./build.sh` → `FruitClip.app` (SPM + manual bundle assembly + ad-hoc sign). Distribute via `./install.sh`; remove via `./uninstall.sh [--wipe-data]`.
- **Persistence:** `~/Library/Application Support/com.veer.FruitClip/` — `metadata.json` (`StorageEnvelope` v3) + `<UUID>.dat` per item
- **Settings:** `UserDefaults.standard` via `SettingsStore`
- **Tests:** XCTest / Swift Testing — run with `swift test`

## Architecture guardrails

- **One primary type per file.** Feature folders: `App/`, `Models/`, `Storage/`, `Hotkey/`, `Popup/`, `Paste/`, `Settings/`, `StatusBar/`, `Permissions/`
- **All AppKit/UI classes are `@MainActor`.** Never call AppKit from a background thread.
- **Cross-component wiring is callback-based** — closures set in `AppCoordinator`, not shared state or notifications.
- **`ClipboardHistoryStore` is the single source of truth** for `items[]`. Mutate it through its public methods only (`deleteItem`, `toggleStar`, `clearBoard`, `clearAll`).
- **Self-capture prevention is critical** — always call `beginPasteboardWrite()` before writing to `NSPasteboard.general` and `endPasteboardWrite(changeCount:)` after. Skipping this causes the paste to re-enter history.
- **Popup keyboard handling is pure logic** — `PopupKeyboardRouter` and `PopupScrollPlanner` are unit-tested state machines. Add new key behavior there, not inline in the SwiftUI view.

## Behaviors to preserve

- Starred items survive pruning (`pruneIfNeeded()` skips them) and live on a dedicated Star tab — they are not pinned-to-top
- SHA256 dedup — never store duplicate content regardless of where it came from
- Orphaned `.dat` cleanup on startup (`cleanOrphanedFiles()`)
- Adaptive polling: 300ms active / 1500ms idle — do not change to `repeats: true`
- Search is text-only (`filteredItems` checks `kind == .text`) — this is intentional
- Accessibility degrades gracefully: if permission absent, clipboard copy still works, only auto-paste is skipped
- Multi-shortcut routing: there are 9 configurable shortcuts (`SettingsStore`); two are global (`openBoardShortcut`, optional `openStarShortcut`), the rest are local to the popup. Global hotkeys re-register via `GlobalHotkeyManager.reregister()` on change.
- Storage envelope migration: legacy bare-array `metadata.json` is read transparently and rewritten as `StorageEnvelope` (`schemaVersion: 3`). Don't break this fallback when changing the format.

## Weak points to watch

- Carbon hotkey API is deprecated — no replacement exists yet; do not remove without a verified alternative
- `ClipboardHistoryStore.storageDir` resolves to a bundle-ID-derived path — if the bundle ID changes, existing history is orphaned
- Image items are silently filtered out of search results with no UX hint
- `clearAll()` exists on the store but no UI surface invokes it (only `clearBoard()` is wired)
- Bare-key shortcut modes (`.singleKey`) are intentionally unguarded — fine inside the popup, but a user re-recording a global shortcut to a single key could record an unrecoverable combo

## Editing expectations

- Functions under ~50 lines; files under ~400 lines
- Do not add network calls, accounts, or external frameworks without explicit discussion
- Do not change the storage format without extending `StorageEnvelope.currentVersion` and adding migration logic
- Run `swift build` and `swift test` after any change to `ClipboardHistoryStore`, `ClipboardHistoryItem`, or `SettingsStore`
- Use `./build.sh` to verify the full `.app` bundle before shipping — `swift run` alone won't catch SPM resource bundle issues
- Comment "why", not "what" — the codebase is well-structured; comments are for non-obvious decisions

## Key utilities — use, don't reinvent

| Utility | Location |
|---------|----------|
| SHA256 hashing | `ClipboardHistoryItem.computeHash(of:)` |
| Text preview with URL detection | `ClipboardHistoryStore.makeTextPreview(_:)` |
| URL extraction | `ClipboardHistoryStore.detectURL(in:)` |
| Relative time string | `elapsedString(from:)` in `ClipboardPopupView.swift` |
| Hotkey string formatting | `HotkeyFormatter.format(keyCode:modifiers:)` |
| Thumbnail loading (async, NSBitmapImageRep) | `ThumbnailCache.shared.loadThumbnailAsync(for:storageDir:)` |
| Popup key-event state machine | `PopupKeyboardRouter` (pure, unit-tested) |
| Scroll anchor for keyboard nav | `PopupScrollPlanner` (pure, unit-tested) |
| Versioned persistence wrapper | `StorageEnvelope` in `ClipboardHistoryItem.swift` |
| Per-action shortcut value type | `ShortcutConfiguration` in `SettingsModels.swift` |
