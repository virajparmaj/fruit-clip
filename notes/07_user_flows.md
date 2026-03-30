# FruitClip — User Flows

## First launch

1. `FruitClipApp` starts, `AppCoordinator.applicationDidFinishLaunching` runs.
2. `settingsStore.isFirstLaunch == true` → Preferences window opens automatically.
3. `isFirstLaunch` set to `false` (persisted in UserDefaults).
4. User sees Preferences; Accessibility row shows permission status.
5. If Accessibility not granted, user clicks "Grant Access" → `AXIsProcessTrustedWithOptions(prompt: true)` → system dialog.
6. Menu bar paperclip icon appears.

**Confirmed from code** (`AppCoordinator.swift:57-60`)

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

1. User presses hotkey (`⌘⇧V` default).
2. Carbon callback fires → `AppCoordinator.togglePopup()`.
3. `PopupPanelController.show(items:)` captures `NSWorkspace.shared.frontmostApplication` as `previousApp`.
4. `FloatingPanel` created, positioned at screen center, made key.
5. `ClipboardPopupView` renders, search field auto-focused (deferred `DispatchQueue.main.async`).
6. User presses ↑/↓ to navigate or types to search (text items only).
7. User presses Enter → `onSelect` closure → `dismiss()` → `pasteController.pasteItem()`.
8. `restoreToClipboard()` sets payload on `NSPasteboard.general`.
9. 50ms delay → `previousApp.activate()`.
10. 100ms delay → `synthesizePaste()` sends CGEvent `Cmd+V` to HID event tap.
11. Target app pastes content.

**Confirmed from code** (`PopupPanelController.swift`, `PasteController.swift`)

**Failure path (no Accessibility):** Steps 8–11 complete except step 10 aborts. One-time `NSAlert` shown with "Open System Settings" button. Item is still on clipboard; user pastes manually with `⌘V`.

---

## Search

1. Popup opens with search field focused.
2. User types — `filteredItems` recomputed: text items whose `preview` contains query (case-insensitive). Images always hidden in search results.
3. `selectedIndex` resets to 0 on search text change.
4. Clear button (×) appears inline; Escape clears search text first, then dismisses.

**Confirmed from code** (`ClipboardPopupView.swift:20-24`)

---

## Pin / unpin item

1. Popup open, navigate to item.
2. Press `⌘P` → `onTogglePin` → `ClipboardHistoryStore.togglePin()`.
3. Item's `isPinned` toggled; all pinned items moved to top of `items[]`.
4. `metadata.json` saved.
5. Pinned item shows pin icon (blue when unselected, white when selected).
6. During future pruning, pinned items are skipped — only unpinned items removed.

**Confirmed from code** (`ClipboardHistoryStore.swift:82-89`, `ClipboardPopupView.swift`)

---

## Delete item

1. Navigate to item (must not be in search field — key guard active).
2. Press Delete → `onDelete` → `ClipboardHistoryStore.deleteItem()`.
3. `.dat` payload file removed from disk.
4. Item removed from `items[]`.
5. `metadata.json` saved.
6. `selectedIndex` adjusted if deleted item was last.

**Confirmed from code** (`ClipboardPopupView.swift:169-179`, `ClipboardHistoryStore.swift:75-79`)

---

## Clear all history

Via menu bar: icon → "Clear History"
Via Preferences: "Clear History" button

Both paths → `AppCoordinator.clearHistory()` → `NSAlert` confirmation → `historyStore.clearAll()` → all `.dat` files deleted → `items[]` emptied → `metadata.json` saved.

**Confirmed from code** (`AppCoordinator.swift:87-98`)

---

## Change hotkey

1. Menu bar icon → Preferences (or `⌘,`).
2. Click "Record" button in Hotkey section.
3. `HotkeyRecorderNSView.startRecording()` — local key-down monitor active.
4. Press desired key combo (must include at least one modifier).
5. `onRecord(keyCode, modifiers)` → `settingsStore.hotkeyKeyCode/Modifiers` updated → `hotkeyManager.reregister()`.
6. Old hotkey unregistered, new one registered with Carbon.
7. Badge displays new combo (e.g., `⌃⌥V`).

**Confirmed from code** (`PreferencesWindow.swift`, `GlobalHotkeyManager.swift`)

**Known gap**: No conflict detection with system hotkeys.

---

## Pause / resume monitoring

Menu bar icon → "Pause Monitoring" / "Resume Monitoring" → `settingsStore.isPaused.toggle()`.

When paused, `checkPasteboard()` returns early — no new items captured. Existing history preserved. Menu title updates to reflect state.

**Confirmed from code** (`ClipboardHistoryStore.swift:110`, `StatusItemController.swift:72-74`)
