# FruitClip — Dev Setup

## Requirements

| Requirement | Version | Notes |
|-------------|---------|-------|
| macOS | 15.0+ | Minimum deployment target |
| Swift | 6.0+ | Bundled with Xcode 16+ or Command Line Tools |
| Xcode (optional) | 16+ | Not required; SPM + CLI sufficient |

No Node.js, Python (only used internally by `build.sh` for ratio math), or external tools needed. No env vars, no secrets, no `.env` files.

## Install and build

```bash
# Clone
git clone <repo>
cd fruit-clip

# Debug build (fast, no .app bundle)
swift build

# Run tests
swift test

# Release build → produces FruitClip.app in project root
./build.sh

# Launch
open FruitClip.app
```

## What build.sh does

**Confirmed from code** (`build.sh`):

1. `swift build -c release`
2. Assembles `.app` bundle: `Contents/MacOS/FruitClip`, `Contents/Resources/`
3. Reads pre-generated icon variants from `assets/icons/macos/` (16–1024px). Aborts with a helpful message if they are missing — run `scripts/generate_icons.sh` first.
4. Two-pass normalize+pad: bundle icons scaled to 82% of canvas (`TARGET_ALPHA_BOUNDS_RATIO=0.82`), dock/runtime icons to 72% (`DOCK_ICON_BOUNDS_RATIO=0.72`). Both passes use `sips` resize then pad.
5. Assembles `AppIcon.iconset` → `AppIcon.icns` via `iconutil` (all standard macOS sizes).
6. Copies the 512px dock-normalized variant as `AppIconRuntime.png` (used by Activity Monitor / Force Quit).
7. Writes `Info.plist` with bundle ID `com.veer.FruitClip`, `LSUIElement = true`, version 1.0.
8. Copies SPM resource bundle (`FruitClip_FruitClip.bundle`) into `Contents/Resources/` — required for `Bundle.module` to resolve status bar icon at runtime.
9. Ad-hoc signs: `codesign --force --sign -`
10. Validates: `codesign --verify`, `plutil -lint`, binary executable check

### Icon source pipeline

`scripts/generate_icons.sh` is a one-time generator (run after artwork changes):
- Reads `fruit-clip.png` (app icon source) and `fruit-clip Background Removed.png` (menu bar source)
- Outputs `assets/icons/macos/fruit_clip_icon_{16..1024}.png` and status bar icons (`fruit-clip-status.png` 22×22, `fruit-clip-status@2x.png` 44×44) into `Sources/FruitClip/Resources/`
- Replaces `Resources/fruit-clip.png` with the 512px variant (avoids committing the 4+ MB original)

## Permissions required at runtime

- **Accessibility** (`Privacy_Accessibility`) — needed for CGEvent auto-paste. App prompts on first use of paste. Without it, clipboard copy still works.
- No other entitlements required.

## Common setup pitfalls

| Pitfall | Fix |
|---------|-----|
| Status bar icon missing (paperclip fallback) | Run `./build.sh` not `swift run` — SPM resource bundle must be copied manually |
| `build.sh` exits "Missing icon source" | Run `scripts/generate_icons.sh` first to populate `assets/icons/macos/` |
| Auto-paste not working | Grant Accessibility in System Settings → Privacy & Security → Accessibility |
| Hotkey conflicts with another app | Change hotkey in Preferences |
| Launch at login not persisting | `SMAppService` requires a properly bundled `.app`; won't work from `swift run` |
| Old stale history after code changes to model | Delete `~/Library/Application Support/com.veer.FruitClip/` |

## Storage inspection

```bash
# View metadata
cat ~/Library/Application\ Support/com.veer.FruitClip/metadata.json | python3 -m json.tool

# List payload files
ls ~/Library/Application\ Support/com.veer.FruitClip/*.dat

# View logs (Console.app or CLI)
log stream --predicate 'subsystem == "com.veer.FruitClip"'
```

## Test suite

**Confirmed from code** — XCTest-based (`swift test`), uses Swift Testing macros (`@Suite`, `@Test`, `#expect`).

| Suite | File |
|-------|------|
| `ClipboardHistoryItemTests` | Codable round-trip, hash determinism |
| `ClipboardHistoryStoreTests` | Unit tests with temp directory |
| `ClipboardHistoryStoreIntegrationTests` | Integration tests |
| `ElapsedStringTests` | `elapsedString()` formatting |
| `HotkeyFormatterTests` | Key code → string conversion |
| `SettingsStoreTests` | UserDefaults wrapper |
| `TextPreviewTests` | `makeTextPreview()`, URL detection |
