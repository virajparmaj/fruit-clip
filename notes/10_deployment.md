# FruitClip — Deployment

## Current deployment model

Manual, local only. No CI/CD, no remote hosting, no distribution pipeline.

**Confirmed from code**:

| Step | Command | Output |
|------|---------|--------|
| Build release app bundle | `./build.sh` | `FruitClip.app/` in project root |
| Launch | `open FruitClip.app` | App running in menu bar |

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
| `CFBundleVersion` | `1.0` |
| `CFBundleShortVersionString` | `1.0` |
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

- `SMAppService.mainApp` launch-at-login silently swallows errors — if it breaks, no user-facing indication (`Strongly inferred` from code comment in `PreferencesWindow.swift:162`)
- Ad-hoc signing will be revoked if the binary is modified post-sign
- No version bump automation — `VERSION="1.0"` hardcoded in `build.sh`
