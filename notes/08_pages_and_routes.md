# FruitClip — Pages and Routes

No traditional routing — this is a macOS menu bar app with discrete UI surfaces, not a page-based app.

## UI surfaces

| Surface | Trigger | Key components | Auth needed | Status |
|---------|---------|----------------|-------------|--------|
| Menu bar icon + dropdown | App launch (always visible) | `StatusItemController`, `NSStatusItem`, `NSMenu` | No | Confirmed |
| Clipboard popup (Board / Star tabs) | Open Board hotkey, optional Open Star hotkey, or "Open Board" menu item | `PopupPanelController`, `FloatingPanel`, `ClipboardPopupView`, `PopupTabPicker`, `ClipboardItemRow` | No | Confirmed |
| Settings window | Menu → Settings… or `⌘,` | `PreferencesWindowController`, `PreferencesView` (sidebar), `ShortcutRecorderView` | No | Confirmed |
| Hotkey conflict alert | `RegisterEventHotKey` returns non-`noErr` | `NSAlert` (inline in `AppCoordinator`) | No | Confirmed |
| Launch at Login error alert | `SMAppService.register/unregister` throws | `NSAlert` (inline in `PreferencesView.updateLaunchAtLogin`) | No | Confirmed |
| Accessibility alert | Auto-paste attempted without permission | `NSAlert` (inline in `PasteController`) | No | Confirmed |
| Clear Board confirmation | Menu → Clear Board or Settings → Storage button | `NSAlert` (inline in `AppCoordinator`) | No | Confirmed |

## Menu bar dropdown items

**Confirmed from code** (`StatusItemController.swift:67-97`):

```
Open Board
─────────────
Settings...  (⌘,)
Pause Monitoring / Resume Monitoring
─────────────
Clear Board
─────────────
Quit FruitClip  (⌘Q)
```

## Popup layout

```
┌──────────────────────────────────────┐
│             [ Board | Star ]         │  ← PopupTabPicker (centered)
│  🔍 Search board items...        [×] │  ← search bar (auto-focused)
│ ─────────────────────────────────── │
│  Preview text                  ★ <1m │  ← selected (blue highlight, gold ★ if starred)
│     Another clip                  5m │
│     🔗 github.com/...             1h │
│     [thumb] Image 1920x1080       2d │
└──────────────────────────────────────┘
```
Size: 400×520pt, `cornerRadius: 18`, dark glass background. Positioned at the active screen's center.

## Settings window layout

```
┌────────────────────────────────────────────────────────────┐
│  Settings                  │  General                       │
│  ─────────────             │  ─────────────                 │
│  ⚙  General        ●       │  Launch at Login         ◯     │
│  ⌘  Shortcuts              │  Dismiss on mouse move   ◯     │
│  💾 Storage                 │                                │
│  ♿ Accessibility           │  Popup font size       12 pt   │
│                            │  ──○─────────────              │
│  [Auto-paste ready]        │  [ font preview card ]         │
└────────────────────────────────────────────────────────────┘
```

Size: **760×560pt**, `[.titled, .closable]` non-modal NSWindow. Sidebar (220pt) lists `General / Shortcuts / Storage / Accessibility`, plus a permanent Accessibility status card at the bottom. Right pane is a scrollable section view.

- **General**: Launch at Login, Dismiss on mouse move, Popup font size slider (11–15pt) with live preview card.
- **Shortcuts**: Open Board, Open Star (with enable toggle), Star item, Delete item, Switch to Star, Copy selected, Focus search.
- **Storage**: Board retention picker, Star retention picker, Clear Board button.
- **Accessibility**: status badge + Grant Access button when missing.
