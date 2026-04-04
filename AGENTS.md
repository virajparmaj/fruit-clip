# AGENTS.md — FruitClip

---

## Project Overview
- **Name:** FruitClip
- **Description:** Lightweight native macOS menu bar clipboard manager
- **Status:** Active
- **Owner:** Veer

---

## Tech Stack
- **Language:** Swift 6.0+
- **UI:** SwiftUI + AppKit (NSPanel, NSStatusItem, NSPasteboard)
- **Hotkeys:** Carbon API (EventHotKeyRef)
- **Hashing:** CryptoKit (SHA256 deduplication)
- **Logging:** os.Logger (structured logging throughout)
- **Build System:** Swift Package Manager + custom `build.sh`
- **Minimum OS:** macOS 15.0+
- **Code Signing:** Ad-hoc (`codesign --sign -`)

---

## Architecture

### Directory Structure
```text
Sources/FruitClip/
├── App/
│   ├── FruitClipApp.swift          # @main entry point
│   └── AppCoordinator.swift        # NSApplicationDelegate, wires all components
├── Models/
│   └── ClipboardHistoryItem.swift  # Core data model (Codable, Identifiable)
├── Storage/
│   ├── ClipboardHistoryStore.swift # Polling, persistence, dedup
│   └── ThumbnailCache.swift        # LRU image thumbnail cache
├── Hotkey/
│   ├── GlobalHotkeyManager.swift   # Carbon hotkey registration
│   └── HotkeyFormatter.swift       # Key code → readable string (e.g., "⌘⇧V")
├── Popup/
│   ├── PopupPanelController.swift  # NSPanel window management
│   └── ClipboardPopupView.swift    # SwiftUI popup UI (search, nav, paste)
├── Paste/
│   └── PasteController.swift       # Clipboard restore + CGEvent Cmd+V synthesis
├── Settings/
│   ├── SettingsStore.swift         # UserDefaults wrapper, @Published properties
│   └── PreferencesWindow.swift     # Preferences UI
├── StatusBar/
│   └── StatusItemController.swift  # Menu bar icon + dropdown menu
├── Permissions/
│   └── PermissionsManager.swift    # Accessibility permission checks
└── Resources/
    ├── fruit-clip.png              # App icon
    ├── fruit-clip-status.png       # Menu bar icon (18x18)
    └── fruit-clip-status@2x.png    # Retina menu bar icon
```

### App Boot Flow
```
FruitClipApp (@main)
  └─ AppCoordinator (NSApplicationDelegate)
     ├─ SettingsStore          (UserDefaults)
     ├─ ClipboardHistoryStore  (polling + persistence)
     ├─ GlobalHotkeyManager    (Carbon hotkey)
     ├─ PopupPanelController   (floating NSPanel)
     ├─ PasteController        (auto-paste via CGEvent)
     ├─ StatusItemController   (menu bar)
     └─ PreferencesWindow      (settings UI)
```

### Key Patterns
- **@MainActor** isolation on all core classes for thread-safe AppKit access
- **Callback-based wiring** between components (onItemSelected, onItemCopied, etc.)
- **Adaptive polling** — 300ms when active, 1500ms when idle (30s threshold)
- **SHA256 deduplication** — items hashed to avoid storing duplicates
- **Pasteboard write tracking** — `beginPasteboardWrite()` / `endPasteboardWrite()` to prevent self-capture
- **Pinned items** sort to top; unpinned items pruned first when over limit
- **Orphaned file cleanup** on startup (removes .dat files not in metadata.json)

### Data Storage
- **Location:** `~/Library/Application Support/com.veer.FruitClip/`
- **Format:** `metadata.json` (item list) + individual `.dat` files (payload data)
- **Settings:** UserDefaults (com.veer.FruitClip suite)
- No database, no env vars, no API keys

---

## Development Setup

### Prerequisites
- macOS 15.0+
- Swift 6.0+ (comes with Xcode 16+)
- Accessibility permission (required for auto-paste)

### Build & Run
```bash
# Debug build
swift build

# Run tests
swift test

# Release build + .app bundle
./build.sh

# Launch the app
open FruitClip.app
```

`build.sh` handles: release compilation, .icns icon generation, .app bundle assembly, Info.plist creation, ad-hoc code signing, and bundle validation.

---

## Coding Standards

### Style
- Swift 6.0 strict concurrency
- @MainActor on classes that touch AppKit
- Google-style inline comments — explain "why" not "what"
- Functions under ~50 lines

### Naming
- Files: PascalCase (match type name)
- Types/protocols: PascalCase
- Functions/variables: camelCase
- Constants: camelCase (Swift convention)

### File Organization
- One primary type per file
- Group by feature folder (App/, Models/, Storage/, Hotkey/, Popup/, Paste/, Settings/, StatusBar/, Permissions/)
- Resources in Resources/

---

## Reusable Utilities (use these, don't reinvent)
- `ClipboardHistoryItem.computeHash()` — SHA256 content hashing
- `ClipboardHistoryStore.makeTextPreview()` — text summary with URL detection
- `ClipboardHistoryStore.detectURL()` — NSDataDetector URL extraction
- `elapsedString()` — relative time formatting (<1m, 10m, 2h, 3d)
- `HotkeyFormatter` — key code + modifiers → readable string
- `ThumbnailCache.shared` — singleton LRU image cache

---

## Testing
- **Framework:** XCTest (Swift Package Manager)
- **Run:** `swift test`
- **Test files:** `Tests/FruitClipTests/`
- **Suites:** ClipboardHistoryItem, ClipboardHistoryStore (unit + integration), SettingsStore, HotkeyFormatter, TextPreview, ElapsedString

---

## Deployment
- `./build.sh` produces `FruitClip.app/` in project root
- No CI/CD pipeline — manual builds
- No notarization or App Store distribution (yet)
- Ad-hoc code signed

---

## Permissions
- **Accessibility** — required for CGEvent-based auto-paste (Cmd+V synthesis)
- App prompts user on first launch if not granted
- Without it, copy-to-clipboard still works but auto-paste into previous app does not

---

## Known Issues & Tech Debt
- No notarization for distribution outside dev machines
- Launch at login linked (ServiceManagement) but may need polish
- No CI/CD pipeline

---

## Debugging Tips
- If auto-paste fails → check System Settings > Privacy & Security > Accessibility
- If hotkey stops working → another app may have registered the same combo
- Clipboard data stored at `~/Library/Application Support/com.veer.FruitClip/` — inspect metadata.json for state
- Use Console.app and filter by "FruitClip" for os.Logger output

---

## Learned Patterns
<!-- Add patterns here when mistakes are corrected -->
