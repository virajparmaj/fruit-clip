# FruitClip — Prompt Context for AI Agents

Use this file as orientation when working on FruitClip in a future session.

## What this app is

FruitClip is a native macOS menu bar clipboard manager written in Swift 6.0. It captures clipboard history (text + images), stores it locally, and lets the user paste previous clips via a global hotkey popup. It has no server, no network, no accounts, and no external dependencies.

## Stack at a glance

- **Language:** Swift 6.0 strict concurrency, `@MainActor` throughout
- **UI:** SwiftUI + AppKit (NSPanel, NSStatusItem, NSWindow)
- **Hotkey:** Carbon framework (`RegisterEventHotKey`) — deprecated but stable
- **Build:** `./build.sh` → `FruitClip.app` (SPM + manual bundle assembly + ad-hoc sign)
- **Persistence:** `~/Library/Application Support/com.veer.FruitClip/` — `metadata.json` + `<UUID>.dat` per item
- **Settings:** `UserDefaults.standard` via `SettingsStore`
- **Tests:** XCTest / Swift Testing — run with `swift test`

## Architecture guardrails

- **One primary type per file.** Feature folders: `App/`, `Models/`, `Storage/`, `Hotkey/`, `Popup/`, `Paste/`, `Settings/`, `StatusBar/`, `Permissions/`
- **All AppKit/UI classes are `@MainActor`.** Never call AppKit from a background thread.
- **Cross-component wiring is callback-based** — closures set in `AppCoordinator`, not shared state or notifications.
- **`ClipboardHistoryStore` is the single source of truth** for `items[]`. Mutate it through its public methods only (`deleteItem`, `togglePin`, `clearAll`).
- **Self-capture prevention is critical** — always call `beginPasteboardWrite()` before writing to `NSPasteboard.general` and `endPasteboardWrite(changeCount:)` after. Skipping this causes the paste to re-enter history.

## Behaviors to preserve

- Pinned items always sort to top and survive pruning (`pruneIfNeeded()` skips them)
- SHA256 dedup — never store duplicate content regardless of where it came from
- Orphaned `.dat` cleanup on startup (`cleanOrphanedFiles()`)
- Adaptive polling: 300ms active / 1500ms idle — do not change to `repeats: true`
- Search is text-only (`filteredItems` checks `kind == .text`) — this is intentional
- Accessibility degrades gracefully: if permission absent, clipboard copy still works, only auto-paste is skipped

## Weak points to watch

- `metadata.json` has no schema version — if `ClipboardHistoryItem` fields change, old JSON fails silently and history is lost
- `ThumbnailCache` uses deprecated `lockFocus/unlockFocus` — works now, flag if AppKit removes it
- Carbon hotkey API is deprecated — no replacement exists yet; do not remove without a verified alternative
- `SMAppService.register()` errors are swallowed — if you add any launch-at-login logic, add user-visible error handling
- `NSApp.activate(ignoringOtherApps: true)` is deprecated in macOS 14+ — use `NSApp.activate()` when targeting macOS 14+

## Editing expectations

- Functions under ~50 lines; files under ~400 lines
- Do not add network calls, accounts, or external frameworks without explicit discussion
- Do not change the storage format without adding migration logic
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
| Thumbnail loading (async) | `ThumbnailCache.shared.loadThumbnailAsync(for:storageDir:)` |
