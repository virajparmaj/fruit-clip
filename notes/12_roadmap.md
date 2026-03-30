# FruitClip — Roadmap

## Immediate fixes

- [ ] Migrate `ThumbnailCache` from deprecated `lockFocus/unlockFocus` to `NSBitmapImageRep`-based drawing
- [ ] Add user feedback when Launch at Login fails (currently silent)
- [ ] Add schema version field to `metadata.json` to handle future model migrations safely
- [ ] Fix `NSApp.activate(ignoringOtherApps:)` deprecation warning in `PreferencesWindowController`

## Short-term improvements

- [ ] Hotkey conflict detection — check if combo is already registered and warn the user
- [ ] Indicate in search UI that image items are excluded from search (or add image search by preview string)
- [ ] Configurable `dismissOnMouseMove` threshold (or increase default from 10px to reduce false triggers)
- [ ] Version bump automation in `build.sh` (read from git tag or a `VERSION` file)
- [ ] Set up basic CI with GitHub Actions: `swift build` + `swift test` on PR

## Medium-term improvements

- [ ] Notarization pipeline — Developer ID signing + `xcrun notarytool` for distribution outside dev machines
- [ ] Rich text clipboard support (RTF, HTML pasteboard types)
- [ ] File/URL clipboard type capture
- [ ] Configurable storage location (beyond hardcoded `applicationSupportDirectory`)
- [ ] Keyboard shortcut to open Preferences directly from popup

## Long-term enhancements

- [ ] App Store distribution (requires sandbox review, entitlements audit)
- [ ] iCloud sync for clipboard history across Macs
- [ ] Sparkle-based auto-update
- [ ] Collections / folder-style organization for pinned items
- [ ] Quick Look preview for images in popup
- [ ] Plain-text stripping for rich text pastes

## Architecture / infra hardening

- [ ] Replace Carbon `RegisterEventHotKey` with a modern alternative (if Apple provides one before Carbon is fully removed)
- [ ] Add `NSSecureCoding` or versioned Codable migrations for `metadata.json`
- [ ] Consider entitlements review if App Store submission becomes a goal

## Product polish

- [ ] Onboarding flow explaining keyboard shortcuts on first launch (beyond just opening Preferences)
- [ ] Visual indicator in menu bar icon when monitoring is paused
- [ ] "Copy without pasting" (⌘C in popup) should show a brief confirmation toast
- [ ] Accessibility: announce paste action via `NSAccessibility` for VoiceOver users
