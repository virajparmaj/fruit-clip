# FruitClip — Features

## Confirmed Implemented

| Feature | Where in code |
|---------|---------------|
| Clipboard polling (text + TIFF/PNG images) | `ClipboardHistoryStore.checkPasteboard()` / `importFromPasteboard()` |
| SHA256 deduplication | `ClipboardHistoryItem.computeHash()` + `addItem()` hash check |
| Persistent history (metadata.json + .dat files) | `ClipboardHistoryStore.saveMetadata()` / `loadMetadata()` |
| Adaptive polling (300ms active / 1500ms idle) | `scheduleNextPoll()`, 30s idle threshold |
| Global hotkey registration (Carbon API) | `GlobalHotkeyManager.register()` |
| Configurable hotkey | `SettingsStore.hotkeyKeyCode/hotkeyModifiers` + Preferences recorder |
| Floating popup (NSPanel, .nonactivatingPanel) | `PopupPanelController`, `FloatingPanel` |
| Search (text items only) | `ClipboardPopupView.filteredItems` — images excluded from search |
| Keyboard navigation (↑↓ Enter Escape Delete) | `ClipboardPopupView` key press handlers |
| Direct index paste (1–9) | `onKeyPress(characters: "123456789")` |
| ⌘P pin toggle | `onKeyPress(characters: "p")` with `.command` check |
| ⌘C copy without pasting | `onKeyPress(characters: "c")` → `onItemCopied` |
| ⌘F focus search | `onKeyPress(characters: "f")` → `isSearchFocused = true` |
| Auto-paste via CGEvent Cmd+V synthesis | `PasteController.synthesizePaste()` |
| Pinned items sort to top | `ClipboardHistoryStore.togglePin()` |
| Pinned items preserved during pruning | `pruneIfNeeded()` — only removes unpinned |
| Self-capture prevention | `beginPasteboardWrite()` / `endPasteboardWrite()` + `lastSelfChangeCount` |
| Orphaned .dat file cleanup on startup | `cleanOrphanedFiles()` |
| Configurable history limit (1–100, default 50) | `SettingsStore.maxHistoryCount` |
| Pause/Resume monitoring | `SettingsStore.isPaused` + menu toggle |
| Clear history (with confirmation alert) | `AppCoordinator.clearHistory()` |
| Launch at Login | `SMAppService.mainApp.register()` in `PreferencesView` |
| Dismiss on mouse move | `PopupPanelController` mouse delta monitor (threshold: 10px) |
| Image thumbnails (64×64, LRU cache) | `ThumbnailCache.shared`, `ClipboardItemRow.thumbnailView` |
| URL detection in text previews | `ClipboardHistoryStore.detectURL()` — NSDataDetector |
| Accessibility permission check + prompt | `PermissionsManager.isAccessibilityGranted()` |
| Menu bar icon (custom PNG, falls back to SF Symbol) | `StatusItemController.loadStatusIcon()` |
| Animated gradient border on popup | `AnimatedGradientBorder` (5s rotating AngularGradient) |
| Relative timestamps (<1m, 10m, 2h, 3d) | `elapsedString()` in `ClipboardPopupView.swift` |
| First-launch → open Preferences | `AppCoordinator` — `isFirstLaunch` check |

## Partially Implemented

| Feature | Status |
|---------|--------|
| Launch at Login | Wired via `SMAppService` but silently swallows errors; needs testing on clean install |
| Dismiss on mouse move | Code present, real-world behavior not validated |

## Not Implemented / Removed

| Feature | Note |
|---------|------|
| In-app update checker | Removed in commit c316141 — no update logic in current code |
| Notarization | Not found — ad-hoc signed only |
| CI/CD | Not found |
| Rich-text clipboard support | Not found — plain `.string` pasteboard type only |
| File/URL clipboard type | Not found — text and image only |
