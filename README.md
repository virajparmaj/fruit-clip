# FruitClip
<div align="center">
    <img src="fruit-clip.png" width="120" alt="FruitClip logo" />
</div>

FruitClip is a native macOS clipboard manager that lives in your menu bar so you can reopen recent clips, search fast, and paste back into the app you were using.

## App Preview

<table>
  <tr>
    <td width="33%"><img src="docs/images/preview-menu-bar.png" width="280" alt="Menu bar menu"><br><sub>Menu bar menu</sub></td>
    <td width="33%"><img src="docs/images/preview-popup.png" width="280" alt="Board popup"><br><sub>Board popup</sub></td>
    <td width="33%"><img src="docs/images/preview-preferences.png" width="280" alt="Settings window"><br><sub>Settings window</sub></td>
  </tr>
</table>

## What You Can Do

- **Menu bar clipboard manager** with a clean, native feel
- **Board + Stars** — browse your full clipboard history on the Board tab, or keep important clips on Stars
- **Global shortcuts** to open the Board or Stars from anywhere (default: `⌘⇧V`)
- **Text and image support** — images display full-width previews in the popup
- **Search** text clips instantly inside the popup
- **Full keyboard flow** — arrows to navigate, `Enter` to paste, `S` to star, `D` to delete, `F` to switch to Stars, `⌘C` to copy without pasting, `⌘F` to focus search
- **Auto-paste into the previous app** when Accessibility access is granted
- **Retention policies** — set how long Board and Stars history is kept (1 day to never)
- **Up to 100 items** in history, default 50, configurable in preferences
- **Customizable shortcuts** — rebind every action in the Shortcuts tab
- **Font size control** — adjust the popup text size from 11 to 15 pt
- **Dismiss on mouse move** — optionally close the popup when the cursor leaves
- **Pause monitoring, clear history, and launch at login** from the menu bar or preferences
- **Local-only storage** — your clipboard history never leaves your Mac

## Install

FruitClip currently installs from source on macOS 15+. You will need Xcode 16 or Apple Command Line Tools with Swift 6.

```bash
git clone https://github.com/virajparmaj/fruit-clip
cd fruit-clip
./build.sh
./install.sh
```

The installer copies `FruitClip.app` to `/Applications`, clears the quarantine flag if needed, and launches the app.

To uninstall:

```bash
./uninstall.sh           # removes the app
./uninstall.sh --wipe-data  # removes the app and all clipboard data
```

## Getting Started

1. Copy text or images as you normally would.
2. Press `⌘⇧V` to open the Board.
3. Type to filter, or use the arrow keys to move through your recent clips.
4. Press `Return` to paste, `S` to star, `D` to delete, `F` to jump to Star, `⌘C` to copy without pasting, or `⌘F` to focus search.
5. Grant **System Settings → Privacy & Security → Accessibility → FruitClip** if you want automatic paste into other apps.

If Accessibility is not granted, FruitClip still restores the selected item to your clipboard so you can paste manually with `⌘V`.

## Developer Setup

Requirements: macOS 15.0+, Swift 6.0+ (Xcode 16 or Apple Command Line Tools)

```bash
git clone https://github.com/virajparmaj/fruit-clip
cd fruit-clip
swift build        # debug build
swift test         # run tests
./build.sh         # release build + .app bundle
open FruitClip.app # launch
```
