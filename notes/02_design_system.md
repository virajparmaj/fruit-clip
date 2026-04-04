# FruitClip — Design System

No formal design system. All styling is inline SwiftUI.

## Visual direction

Glassmorphic / modern macOS. `.regularMaterial` vibrancy background, animated blue gradient border, dark selection highlight. Keyboard-first.

## Colors

**Confirmed from code** (`ClipboardPopupView.swift`):

| Token | Value | Usage |
|-------|-------|-------|
| `fruitClipBlue` | `Color(red: 0.2, green: 0.5, blue: 1.0)` | Selection background, pin icon, row shadow |
| Selection shadow | `fruitClipBlue.opacity(0.4)` | Selected row glow |
| Gradient stops | `#1A59E6` → `#66B3FF` → `#2672F2` → `#4D99FF` → `#1A59E6` | Border animation |

System colors used elsewhere: `.primary`, `.secondary`, `.tertiary`, `.accentColor`, `Color(nsColor: .controlColor)`.

## Typography

**Confirmed from code**:

| Context | Font |
|---------|------|
| Clip preview text | `.system(size: 13)` |
| Timestamp | `.system(size: 10)` |
| Preferences labels | SwiftUI Form defaults |
| Hotkey badge | `.system(size: 13, weight: .medium)` |
| Empty state headline | `.headline` |
| Empty state subtext | `.caption` |

## Spacing & shape

- Popup container: 340×380pt, `cornerRadius: 16`
- Popup padding: 8pt around container
- Item rows: `minHeight: 48`, `padding(.horizontal, 10)`, `padding(.vertical, 8)`, `cornerRadius: 10`
- Image thumbnails: 32×32 display, 64×64 cached, `cornerRadius: 6`
- Search bar: `padding(.horizontal, 12)`, `padding(.vertical, 8)`
- Divider: `opacity(0.3)`
- Preferences window: 420×480pt

## Animation

- **Gradient border**: `.linear(duration: 5.0).repeatForever(autoreverses: false)` — 360° rotation
- **Scroll on navigation**: `.easeOut(duration: 0.2)`
- No other explicit animations

## Interaction patterns

- Keyboard-first: all actions reachable without mouse
- Click-outside dismisses popup (global monitor)
- Mouse move dismiss: opt-in, 10px accumulated delta threshold
- Search auto-focused on popup open (deferred via `DispatchQueue.main.async`)

## Consistency issues

- `Strongly inferred` — image items excluded from search results; this is intentional (no meaningful text to match) but not communicated to the user in the UI
- `Strongly inferred` — `dismissOnMouseMove` threshold (10px) may feel hair-trigger on trackpads
