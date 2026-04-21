# FruitClip — Features

## Confirmed Implemented

| Feature | Where in code |
|---------|---------------|
| Clipboard polling (text + TIFF/PNG images) | `ClipboardHistoryStore.checkPasteboard()` / `importFromPasteboard()` |
| SHA256 deduplication | `ClipboardHistoryItem.computeHash()` + `addItem()` hash check |
| Persistent history with versioned envelope (`StorageEnvelope` v3, legacy fallback + auto-migrate) | `ClipboardHistoryStore.loadMetadata()` / `saveMetadata()` |
| Adaptive polling (300ms active / 1500ms idle) | `scheduleNextPoll()`, 30s idle threshold |
| Global hotkey registration (Carbon API) — Open Board + optional Open Star | `GlobalHotkeyManager.register()`, `configuredHotkeys()` |
| Multi-shortcut Settings (`ShortcutConfiguration` per action) | `SettingsModels.swift` + `SettingsStore` |
| Open Board shortcut (default `⌘⇧V`) | `SettingsStore.openBoardShortcut`, `ShortcutConfiguration.openBoardDefault` |
| Open Star shortcut (optional, off by default) | `SettingsStore.openStarShortcut` + `openStarShortcutEnabled` |
| Star item shortcut (default `S`, no modifier) | `SettingsStore.starItemShortcut` |
| Delete item shortcut (default `D`, no modifier) | `SettingsStore.deleteItemShortcut` |
| Switch-to-Star shortcut (default `F`, no modifier) | `SettingsStore.switchToStarShortcut` |
| Copy selected shortcut (default `⌘C`) | `SettingsStore.copySelectedShortcut` |
| Focus search shortcut (default `⌘F`) | `SettingsStore.focusSearchShortcut` |
| Floating popup (NSPanel, .nonactivatingPanel) | `PopupPanelController`, `FloatingPanel` |
| Board / Star tabs in popup | `PopupTab`, `PopupTabPicker`, `PopupPresentationState` |
| Search (text items only) — context-aware placeholder per tab | `ClipboardPopupView.filteredItems` — images excluded from search |
| Keyboard navigation routed through state machine | `PopupKeyboardRouter` + `PopupKeyboardState` |
| Direct index paste (1–9) | `PopupKeyboardRouter` digit handling |
| Auto-paste via CGEvent Cmd+V synthesis | `PasteController.synthesizePaste()` |
| Star toggle on item — `toggleStar` flips `isStarred` and saves metadata | `ClipboardHistoryStore.toggleStar()` |
| Starred items survive Board pruning and have their own retention policy | `pruneIfNeeded()` skips `isStarred`; `applyRetentionPolicies()` uses `starRetentionPolicy` |
| Configurable retention policy per scope (1d / 1w / 1mo / 3mo / never) | `RetentionPolicy`, `boardRetentionPolicy`, `starRetentionPolicy` |
| Configurable popup font size (11–15pt, default 12) | `PopupFontSize`, `SettingsStore.popupFontSize` |
| Self-capture prevention | `beginPasteboardWrite()` / `endPasteboardWrite()` + `lastSelfChangeCount` |
| Orphaned .dat file cleanup on startup | `cleanOrphanedFiles()` |
| Configurable history limit (1–100, default 50) | `SettingsStore.maxHistoryCount` |
| Pause/Resume monitoring | `SettingsStore.isPaused` + menu toggle |
| Clear Board (non-starred only) with confirmation | `AppCoordinator.clearBoard()`, `ClipboardHistoryStore.clearBoard()` |
| Launch at Login with user-visible error alert on failure | `SMAppService.mainApp.register()` in `PreferencesView.updateLaunchAtLogin` |
| Hotkey conflict detection — alert + jump to Settings | `GlobalHotkeyManager.onRegistrationFailed`, wired in `AppCoordinator` |
| Dismiss on mouse move | `PopupPanelController` mouse delta monitor (50pt accumulated) |
| Image thumbnails (async `NSBitmapImageRep`, max 600px, NSCache up to 100) | `ThumbnailCache` |
| URL detection in text previews | `ClipboardHistoryStore.detectURL()` — NSDataDetector |
| Accessibility permission check + prompt + Settings status badge | `PermissionsManager.isAccessibilityGranted()`, `accessibilitySection` |
| Menu bar icon (PNG @1x + @2x via `Bundle.module`, falls back to SF Symbol) | `StatusItemController.loadStatusIcon()` |
| Animated gradient border on popup | `AnimatedGradientBorder` (5s rotating AngularGradient) |
| Relative timestamps (<1m, 10m, 2h, 3d) | `elapsedString()` |
| First-launch → open Settings | `AppCoordinator` — `isFirstLaunch` check |
| `install.sh` / `uninstall.sh` (with optional `--wipe-data`) | repo root |

## Partially Implemented

| Feature | Status |
|---------|--------|
| Dismiss on mouse move | Code present, threshold raised to 50pt — broad real-world validation still pending |

## Not Implemented / Removed

| Feature | Note |
|---------|------|
| In-app update checker | Removed in commit c316141 — no update logic in current code |
| Notarization | Not found — ad-hoc signed only |
| CI/CD | Not found |
| Rich-text clipboard support | Not found — plain `.string` pasteboard type only |
| File/URL clipboard type | Not found — text and image only |
