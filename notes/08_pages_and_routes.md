# FruitClip — Pages and Routes

No traditional routing — this is a macOS menu bar app with discrete UI surfaces, not a page-based app.

## UI surfaces

| Surface | Trigger | Key components | Auth needed | Status |
|---------|---------|----------------|-------------|--------|
| Menu bar icon + dropdown | App launch (always visible) | `StatusItemController`, `NSStatusItem`, `NSMenu` | No | Confirmed |
| Clipboard popup | Hotkey press or "Open Clipboard" menu item | `PopupPanelController`, `FloatingPanel`, `ClipboardPopupView`, `ClipboardItemRow` | No | Confirmed |
| Preferences window | Menu → Preferences or `⌘,` | `PreferencesWindowController`, `PreferencesView`, `HotkeyRecorderView` | No | Confirmed |
| Accessibility alert | Auto-paste attempted without permission | `NSAlert` (inline in `PasteController`) | No | Confirmed |
| Clear history confirmation | Menu → Clear History or Preferences button | `NSAlert` (inline in `AppCoordinator`) | No | Confirmed |

## Menu bar dropdown items

**Confirmed from code** (`StatusItemController.swift`):

```
Open Clipboard
─────────────
Preferences...  (⌘,)
Pause Monitoring / Resume Monitoring
─────────────
Clear History
─────────────
Quit FruitClip  (⌘Q)
```

## Popup layout

```
┌──────────────────────────────────────┐
│  🔍 Search clips...              [×] │  ← search bar (auto-focused)
│ ─────────────────────────────────── │
│  📌 Preview text              <1m    │  ← selected (blue highlight)
│     Another clip              5m    │
│     🔗 github.com/...         1h    │
│     [photo] Image 1920x1080   2d    │
└──────────────────────────────────────┘
```
Size: 340×380pt. Positioned at screen center.

## Preferences window layout

```
┌──────────────────────────────────────┐
│  FruitClip Preferences               │
│ ─────────────────────────────────── │
│  Hotkey                              │
│    Global Shortcut: [⌘⇧V] [Record]  │
│ ─────────────────────────────────── │
│  General                             │
│    ☐ Launch at Login                 │
│    ☐ Dismiss on mouse move           │
│ ─────────────────────────────────── │
│  Accessibility                       │
│    ✓ Accessibility permission granted│
│ ─────────────────────────────────── │
│  Data                                │
│    [Clear History]                   │
└──────────────────────────────────────┘
```
Size: 420×370pt. Standard titled closable NSWindow.
