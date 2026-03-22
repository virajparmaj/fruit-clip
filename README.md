# Fruit Clip

<img src="fruit-clip.png" width="120" alt="Fruit Clip logo" />

A lightweight native macOS clipboard manager. Keeps your last 10 clipboard items (text and images) accessible via a global hotkey, with auto-paste back into the previously focused app.

## Features

- **Global hotkey** (default: `⌘⇧V`) opens a floating popup with clipboard history
- **Keyboard-first navigation**: arrow keys to select, Enter to paste, Escape to dismiss
- **Auto-paste**: selected items are pasted directly into the previous app
- **Persisted history**: survives app relaunch (stored locally)
- **Menu bar app**: no Dock icon, runs as a background agent
- **Configurable hotkey** via Preferences
- **Launch at Login** toggle
- **Pause/Resume** clipboard monitoring
- **Clear History** to remove all saved items
- Supports **plain text** and **images**

## Requirements

- macOS 15.0+
- Swift 6.0+ (included with Xcode or Command Line Tools)
- **Accessibility permission** required for auto-paste (the app will prompt you)

## Install & Run

```bash
# Clone and build
cd fruit-clip
./build.sh

# Run
open FruitClip.app
```

The build script compiles with SPM, generates the app icon from `fruit-clip.png`, assembles a proper `.app` bundle with `Info.plist`, and ad-hoc code signs it.

Grant **Accessibility** permission when prompted on first launch (required for auto-paste).

## Usage

1. **Launch**: `open FruitClip.app` — a paperclip icon appears in the menu bar
2. **Copy things**: text and images you copy are automatically captured (up to 10 items)
3. **Open popup**: press `⌘⇧V` (or your configured hotkey)
4. **Navigate**: `↑`/`↓` arrow keys to move selection
5. **Paste**: `Enter` to paste the selected item into the previously focused app
6. **Dismiss**: `Escape` or click outside the popup
7. **Preferences**: click the menu bar icon → Preferences to change hotkey, toggle launch at login, or clear history

## Permissions

- **Accessibility**: required for auto-paste (`System Settings → Privacy & Security → Accessibility`). Without it, selected items are still copied to your clipboard — you just need to paste manually with `⌘V`.

## Data Storage

Clipboard history is stored locally at:

```
~/Library/Application Support/com.veer.FruitClip/
├── metadata.json    # Item index (timestamps, previews, hashes)
└── *.dat            # Payload files (text/image data)
```

Use **Clear History** from the menu bar or Preferences to delete all stored data.

## Architecture

```
Sources/FruitClip/
├── App/           # App entry point + coordinator
├── Models/        # ClipboardHistoryItem data model
├── Storage/       # Clipboard monitoring + persistence
├── Hotkey/        # Carbon global hotkey registration
├── Popup/         # Floating NSPanel + SwiftUI list
├── Paste/         # Clipboard restore + Cmd+V synthesis
├── Settings/      # UserDefaults + Preferences UI
├── StatusBar/     # Menu bar item
└── Permissions/   # Accessibility permission handling
```

## Development

```bash
swift build    # Debug build
swift test     # Run unit tests
./build.sh     # Release build + .app bundle
```
