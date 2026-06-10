# FruitClip — Deployment

## Current deployment model

Manual, local only. No CI/CD, no remote hosting, no distribution pipeline.

**Confirmed from code**:

| Step | Command | Output |
|------|---------|--------|
| Build release app bundle | `./build.sh` | `FruitClip.app/` in project root |
| Install to `/Applications` | `./install.sh` | App copied, quarantine cleared, launched (6-step script) |
| Launch (without install) | `open FruitClip.app` | App running in menu bar |
| Uninstall app only | `./uninstall.sh` | Removes `/Applications/FruitClip.app`, preserves history |
| Uninstall + wipe data | `./uninstall.sh --wipe-data` | Also removes `~/Library/Application Support/com.veer.FruitClip/` and the prefs plist, flushes `cfprefsd` |

## Code signing

Ad-hoc only (`codesign --sign -`). This means:
- Works on the machine that built it
- Gatekeeper will block it on other machines ("app is damaged" or "unidentified developer")
- Cannot be distributed via direct download, TestFlight, or App Store without Developer ID / notarization

## Info.plist values

**Confirmed from code** (`build.sh`):

| Key | Value |
|-----|-------|
| `CFBundleIdentifier` | `com.veer.FruitClip` |
| `CFBundleVersion` | from `VERSION` file (currently `1.0`) |
| `CFBundleShortVersionString` | from `VERSION` file (currently `1.0`) |
| `LSMinimumSystemVersion` | `15.0` |
| `LSUIElement` | `true` (menu bar agent, no Dock) |
| `NSHighResolutionCapable` | `true` |
| `NSAccessibilityUsageDescription` | Permission prompt string |

## Distribution blockers

| Blocker | What's needed |
|---------|---------------|
| No notarization | Apple Developer account + `xcrun notarytool` workflow |
| No Developer ID signing | Paid Apple Developer Program membership |
| No App Store submission | Entitlements audit, sandbox review |
| No auto-update mechanism | Sparkle framework or similar (previously removed) |

## Environment separation

**Not found in repository** — single environment only. No staging/prod split, no feature flags, no config profiles.

## Deployment risks

- Ad-hoc signing will be revoked if the binary is modified post-sign — re-run `build.sh` then `install.sh`
- `VERSION` file is the single source of truth; bumping a release means editing `VERSION` (or pushing an annotated git tag) before `./build.sh`
- `install.sh` overwrites `/Applications/FruitClip.app` without further confirmation once prerequisites pass
- `uninstall.sh --wipe-data` is irreversible (clipboard history is local-only, not synced)
