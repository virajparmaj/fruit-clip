# FruitClip — Design System

No formal design system. All styling is inline SwiftUI.

## Visual direction

Glassmorphic / modern macOS. `.regularMaterial` vibrancy background, animated blue gradient border, dark selection highlight. Keyboard-first.

## Colors

**Confirmed from code** (`ClipboardPopupView.swift`):

| Token | Value | Usage |
|-------|-------|-------|
| `fruitClipBlue` | `Color(red: 0.2, green: 0.5, blue: 1.0)` | Selection background, sidebar accent, row shadow |
| `fruitClipGold` | `Color(red: 0.97, green: 0.8, blue: 0.24)` | Star icon fill on starred rows |
| `fruitClipDelete` | `Color(red: 0.92, green: 0.32, blue: 0.36)` | Destructive actions (Clear Board, delete flash) |
| Selection shadow | `fruitClipBlue.opacity(0.4)` | Selected row glow |
| Gradient stops | `#1A59E6` → `#66B3FF` → `#2672F2` → `#4D99FF` → `#1A59E6` | Border animation |

System colors used elsewhere: `.primary`, `.secondary`, `.tertiary`, `.accentColor`, `Color(nsColor: .controlColor)`.

## Typography

**Confirmed from code**:

| Context | Font |
|---------|------|
| Clip preview text | `.system(size: popupTextSize)` — user-configurable 11–15pt, default 12 (`SettingsStore.popupFontSize`) |
| Timestamp / chip labels | `popupTextSize − 1/2`, clamped to 9–10pt |
| Tab picker label | `popupTextSize − 1`, min 11pt |
| Settings sidebar item | `.system(size: 13, weight: .semibold)` |
| Settings section heading | `.system(size: 26, weight: .bold)` |
| Hotkey badge in `ShortcutCaptureRow` | `.system(size: 13, weight: .semibold)` |
| Empty state title | `popupTitleSize` (= `popupTextSize + 4`), `.semibold` |
| Empty state subtext | `popupChipLabelSize` |

## Spacing & shape

- Popup container: **400×520pt**, `cornerRadius: 18`, dark `.regularMaterial` + `Color.black.opacity(0.55)` overlay
- Popup padding: 8pt around container
- Item rows: `popupRowHeight: 72`, `popupRowCornerRadius: 13`, `popupRowTrailingInset: 50`
- Image thumbnails in row: `popupThumbnailSize: 44pt`, async-loaded via `ThumbnailCache`, source rendered up to 600px max dimension
- Search bar: `padding(.horizontal, 12)`, `padding(.vertical, 8)`, `cornerRadius: 12`
- Divider: `opacity(0.14)`
- Preferences window: **760×560pt**, two-pane layout — 220pt sidebar (sections + Accessibility status card) + scrollable content
- Settings panels: `cornerRadius: 18`, white `opacity(0.05)` fill with `opacity(0.06)` stroke
- Star fill color (`fruitClipGold`) on starred-row indicator

## Animation

- **Gradient border**: `.linear(duration: 5.0).repeatForever(autoreverses: false)` — 360° rotation
- **Scroll on navigation**: `.easeOut(duration: 0.2)`
- No other explicit animations

## Interaction patterns

- Keyboard-first: all actions reachable without mouse, routed through `PopupKeyboardRouter`
- Tab switch (Board ↔ Star) by click on `PopupTabPicker` or via `switchToStarShortcut` (default `F`)
- Click-outside dismisses popup (global monitor)
- Mouse move dismiss: opt-in, **50pt** accumulated delta threshold (raised from 10pt to avoid hair-trigger on trackpads)
- Search field is auto-focused on activation; `inputMode == .search` re-focuses it whenever the popup re-activates

## Consistency issues

- `Strongly inferred` — image items excluded from search results; this is intentional (no meaningful text to match) but not communicated to the user in the UI
