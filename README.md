# FruitClip
<div align="center">
    <img src="fruit-clip.png" width="120" alt="Fruit Clip logo" />
</div>

FruitClip is a lightweight native macOS clipboard manager that lives in your menu bar and lets you quickly reopen, search, and paste the things you copied most recently.

## App Preview

**Menu bar controls**

![FruitClip menu bar controls](docs/images/preview-menu-bar.png)

**Preferences**

![FruitClip preferences](docs/images/preview-preferences.png)

**Clipboard popup**

![FruitClip clipboard popup](docs/images/preview-popup.png)

## What You Get

- **Menu bar clipboard manager** for macOS with a clean, native feel
- **Global shortcut** to open your clipboard history from anywhere
- **Text and image support** so common clipboard items are easy to reuse
- **Search for text clips** right inside the popup
- **Fast keyboard flow** with arrow keys, `Enter`, and number keys for quick selection
- **Paste back into the previous app** automatically when Accessibility access is enabled
- **Pin important clips** so they stay near the top
- **Copy without auto-paste** when you want something back on the clipboard first
- **Pause monitoring, clear history, and launch at login** from the menu bar or preferences
- **Local-only storage** so your clipboard history stays on your Mac

By default, FruitClip keeps up to **50 clipboard items** and lets you change that limit in the app settings.

## Quick Use

1. Build and open the app.
2. Copy text or images as you normally would.
3. Press `⌘⇧V` to open FruitClip.
4. Type to search text clips, or move through the list with the keyboard.
5. Press `Enter` to paste the selected item back into the app you were using.

## Permissions

FruitClip needs **Accessibility** permission for automatic paste into other apps.

Without it, FruitClip still restores the selected item to your clipboard, and you can paste manually with `⌘V`.

## For Developers

### Option 1: Clone the repo

```bash
git clone https://github.com/virajparmaj/fruit-clip
cd fruit-clip
swift build
swift test
./build.sh
open FruitClip.app
```

### Option 2: Download the ZIP locally

1. Download the repository ZIP from GitHub.
2. Extract it on your Mac.
3. Open Terminal in the extracted `fruit-clip` folder.
4. Run:

```bash
swift build
swift test
./build.sh
open FruitClip.app
```

### Local Notes

- Requires **macOS 15.0+**
- Requires **Swift 6.0+** and Xcode 16 or Command Line Tools
- The first launch may prompt for **Accessibility** access if you want auto-paste
