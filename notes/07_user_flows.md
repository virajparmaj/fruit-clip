# FruitClip — User Flows

## First launch

1. `FruitClipApp` starts, `AppCoordinator.applicationDidFinishLaunching` runs.
2. `settingsStore.isFirstLaunch == true` → Settings window opens automatically.
3. `isFirstLaunch` set to `false` (persisted in UserDefaults).
4. User sees Settings; the Accessibility section shows permission status with a status badge.
5. If Accessibility not granted, user clicks "Grant Access" → `AXIsProcessTrustedWithOptions(prompt: true)` → system dialog.
6. Menu bar FruitClip icon appears.

**Confirmed from code** (`AppCoordinator.swift:70-73`)

---

## Copy → history capture

1. User copies text or image in any app.
2. `checkPasteboard()` fires on next poll (≤300ms active, ≤1500ms idle).
3. `changeCount` differs from last → `importFromPasteboard()` called.
4. `lastSelfChangeCount` check prevents capturing FruitClip's own writes.
5. SHA256 hash computed → if hash already in `items[]`, item is dropped (dedup).
6. Payload written to `<UUID>.dat`, item prepended to `items[]`.
7. If `items.count > maxHistoryCount`, last unpinned item removed (payload file deleted).
8. `metadata.json` updated.

**Confirmed from code** (`ClipboardHistoryStore.swift`)

---

## Open popup and paste

1. User presses an open shortcut: `openBoardShortcut` (default `⌘⇧V`) or — if enabled — `openStarShortcut` to land on the Star tab directly.
2. Carbon callback fires → `AppCoordinator` `togglePopup(initialTab:)`.
3. `PopupPanelController.show(...)` captures `NSWorkspace.shared.frontmostApplication` as `previousApp` and calls `historyStore.refreshStoragePolicies()` (so the user sees a freshly retention-pruned list).
4. `FloatingPanel` (400×520pt) created, positioned at the active screen center, made key.
5. `ClipboardPopupView` renders the requested tab, search field auto-focused via `inputMode = .search`.
6. User presses ↑/↓ to navigate or types to search (text items only).
7. User presses Enter → `onSelect` closure → `dismiss()` → `pasteController.pasteItem(...)`.
8. `restoreToClipboard()` sets payload on `NSPasteboard.general`.
9. 50ms delay → `previousApp.activate()`.
10. 100ms delay → `synthesizePaste()` sends CGEvent `Cmd+V` to HID event tap.
11. Target app pastes content.

**Confirmed from code** (`PopupPanelController.swift`, `PasteController.swift`, `AppCoordinator.swift:43-50`)

**Failure path (no Accessibility):** Steps 8–11 complete except step 10 aborts. One-time `NSAlert` shown with "Open System Settings" button. Item is still on clipboard; user pastes manually with `⌘V`.

---

## Search

1. Popup opens with search field focused.
2. User types — `filteredItems` recomputed: text items whose `preview` contains query (case-insensitive). Images always hidden in search results.
3. `selectedIndex` resets to 0 on search text change.
4. Clear button (×) appears inline; Escape clears search text first, then dismisses.

**Confirmed from code** (`ClipboardPopupView.swift:20-24`)

---

## Star / unstar item (and Star tab)

1. Popup open, navigate to item.
2. Press the Star shortcut (default `S`, no modifier) → `onToggleStar` → `ClipboardHistoryStore.toggleStar()`.
3. Item's `isStarred` toggled; metadata is saved (item position is left in place — starred items show a gold star indicator and remain visible in the dedicated Star tab).
4. Switch to the Star tab via `switchToStarShortcut` (default `F`) or by clicking `PopupTabPicker`. The Star tab filters to items where `isStarred == true`.
5. During pruning, `pruneIfNeeded()` only removes items where `!isStarred`; retention is also evaluated separately (`starRetentionPolicy` vs. `boardRetentionPolicy`).
6. `Open Star` global shortcut (optional, default unset) opens the popup directly on the Star tab.

**Confirmed from code** (`ClipboardHistoryStore.swift:82-86`, `pruneIfNeeded` 178-189, `ClipboardPopupView.swift`, `PopupPanelController.swift`)

---

## Delete item

1. Navigate to item (must be in `inputMode == .list`, i.e. not in the search field).
2. Press the Delete shortcut (default `D`, no modifier) → `onDelete` → `ClipboardHistoryStore.deleteItem()`.
3. `.dat` payload file removed from disk.
4. Item removed from `items[]`.
5. `metadata.json` saved.
6. `selectedIndex` adjusted if deleted item was last.

**Confirmed from code** (`PopupKeyboardRouter`, `ClipboardHistoryStore.swift:76-80`)

---

## Clear board

Via menu bar: icon → "Clear Board"
Via Settings → Storage: "Clear Board" button

Both paths → `AppCoordinator.clearBoard()` → `NSAlert` confirmation ("Starred clips will be kept.") → `historyStore.clearBoard()` → only `.dat` files for non-starred items deleted → `items` filtered to retain `isStarred` only → `metadata.json` saved.

`historyStore.clearAll()` exists as a separate API (wipes everything including stars) but is currently not surfaced in the UI.

**Confirmed from code** (`AppCoordinator.swift:101-113`, `ClipboardHistoryStore.swift:88-99`)

---

## Change a shortcut

1. Menu bar icon → Settings (or `⌘,`) → Shortcuts section in sidebar.
2. Click the badge on any `ShortcutCaptureRow` ("Press keys…" appears).
3. `ShortcutRecorderNSView.startRecording(mode:)` — local key-down monitor active. Mode varies per shortcut:
   - `.global` (Open Board, Open Star) — requires at least one modifier.
   - `.singleKey` (Star, Delete, Switch to Star) — requires NO modifier; raw key only.
   - `.modified` (Copy selected, Focus search) — requires at least one modifier.
4. Press desired combo. Escape (`keyCode 0x35`) cancels.
5. `onRecord(shortcut)` → `settingsStore.<shortcut>` updated. For the two global hotkeys, `hotkeyManager.reregister()` is called.
6. If `RegisterEventHotKey` reports the combo is taken, `onRegistrationFailed` fires → modal "Shortcut Conflict" alert → Settings opens so the user can pick another.

**Confirmed from code** (`PreferencesWindow.swift:495-519, 724-791`, `GlobalHotkeyManager.swift:75-82`, `AppCoordinator.swift:51-58`)

---

## Pause / resume monitoring

Menu bar icon → "Pause Monitoring" / "Resume Monitoring" → `settingsStore.isPaused.toggle()`.

When paused, `checkPasteboard()` returns early — no new items captured. Existing history preserved. Menu title updates to reflect state.

**Confirmed from code** (`ClipboardHistoryStore.swift:117-118`, `StatusItemController.swift:80-83`)

---

## Toggle Launch at Login

1. Settings → General → "Launch at Login" toggle.
2. `updateLaunchAtLogin(enabled)` calls `SMAppService.mainApp.register()` or `unregister()`.
3. On error (e.g. app not in `/Applications`), the toggle is reverted and an `NSAlert` is shown with the underlying error message and a hint to install via `install.sh`.

**Confirmed from code** (`PreferencesWindow.swift:521-542`)
