#!/bin/bash
set -euo pipefail

APP_NAME="FruitClip"
BUNDLE_ID="com.veer.FruitClip"

# Read version from VERSION file, then git tag, then fall back to "1.0".
if [ -f VERSION ]; then
    VERSION="$(tr -d '[:space:]' < VERSION)"
elif git describe --tags --exact-match HEAD 2>/dev/null; then
    VERSION="$(git describe --tags --exact-match HEAD)"
else
    VERSION="1.0"
fi
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"
ICON_SOURCE_DIR="assets/icons/macos"
RUNTIME_ICON_NAME="AppIconRuntime.png"

# Icon normalization ratios (resize artwork then pad to full canvas).
# Bundle icons appear in Finder / Applications / Launchpad.
# Dock/runtime icons appear in Activity Monitor / Force Quit / Settings.
TARGET_ALPHA_BOUNDS_RATIO="0.82"
DOCK_ICON_BOUNDS_RATIO="0.72"

copy_icon_variant() {
    local source_size="$1"
    local dest_name="$2"
    local work_dir="$3"
    local source_path="$work_dir/fruit_clip_icon_${source_size}.png"

    if [ ! -f "$source_path" ]; then
        echo "Missing icon source: $source_path" >&2
        exit 1
    fi

    cp "$source_path" "$ICONSET/$dest_name"
}

normalize_icon_set() {
    local work_dir="$1"
    local ratio="$2"

    cp "$ICON_SOURCE_DIR"/fruit_clip_icon_*.png "$work_dir"/
    for size in 16 32 64 128 256 512 1024; do
        local target_size
        target_size="$(python3 - "$size" "$ratio" <<'PY'
import sys

size = int(sys.argv[1])
ratio = float(sys.argv[2])
print(max(1, int(round(size * ratio))))
PY
)"
        sips -z "$target_size" "$target_size" \
            "$work_dir/fruit_clip_icon_${size}.png" \
            --out "$work_dir/fruit_clip_icon_${size}.scaled.png" >/dev/null
        sips -p "$size" "$size" \
            "$work_dir/fruit_clip_icon_${size}.scaled.png" \
            --out "$work_dir/fruit_clip_icon_${size}.png" >/dev/null
        rm -f "$work_dir/fruit_clip_icon_${size}.scaled.png"
    done
}

echo "Building ${APP_NAME}..."
swift build -c release

echo "Assembling ${APP_BUNDLE}..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Preflight: verify icon source variants exist
for size in 16 32 64 128 256 512 1024; do
    if [ ! -f "$ICON_SOURCE_DIR/fruit_clip_icon_${size}.png" ]; then
        echo "Missing icon source: $ICON_SOURCE_DIR/fruit_clip_icon_${size}.png" >&2
        echo "Run scripts/generate_icons.sh first." >&2
        exit 1
    fi
done

# Normalize icon artwork with resize+pad for proper visual weight
WORK_DIR="$(mktemp -d)"
BUNDLE_WORK_DIR="$WORK_DIR/bundle"
DOCK_WORK_DIR="$WORK_DIR/dock"
mkdir -p "$BUNDLE_WORK_DIR" "$DOCK_WORK_DIR"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "   Normalizing bundle icons (ratio ${TARGET_ALPHA_BOUNDS_RATIO})..."
normalize_icon_set "$BUNDLE_WORK_DIR" "$TARGET_ALPHA_BOUNDS_RATIO"
echo "   Normalizing runtime icons (ratio ${DOCK_ICON_BOUNDS_RATIO})..."
normalize_icon_set "$DOCK_WORK_DIR" "$DOCK_ICON_BOUNDS_RATIO"

# Assemble AppIcon.iconset
ICONSET="${APP_BUNDLE}/Contents/Resources/AppIcon.iconset"
mkdir -p "$ICONSET"
copy_icon_variant 16   "icon_16x16.png"      "$BUNDLE_WORK_DIR"
copy_icon_variant 32   "icon_16x16@2x.png"   "$BUNDLE_WORK_DIR"
copy_icon_variant 32   "icon_32x32.png"       "$BUNDLE_WORK_DIR"
copy_icon_variant 64   "icon_32x32@2x.png"    "$BUNDLE_WORK_DIR"
copy_icon_variant 128  "icon_128x128.png"     "$BUNDLE_WORK_DIR"
copy_icon_variant 256  "icon_128x128@2x.png"  "$BUNDLE_WORK_DIR"
copy_icon_variant 256  "icon_256x256.png"      "$BUNDLE_WORK_DIR"
copy_icon_variant 512  "icon_256x256@2x.png"  "$BUNDLE_WORK_DIR"
copy_icon_variant 512  "icon_512x512.png"      "$BUNDLE_WORK_DIR"
copy_icon_variant 1024 "icon_512x512@2x.png"  "$BUNDLE_WORK_DIR"
iconutil -c icns "$ICONSET" -o "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
cp "$DOCK_WORK_DIR/fruit_clip_icon_512.png" "${APP_BUNDLE}/Contents/Resources/$RUNTIME_ICON_NAME"
rm -rf "$ICONSET"
echo "   Icon resources: AppIcon.icns, $RUNTIME_ICON_NAME"

cat > "${APP_BUNDLE}/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAccessibilityUsageDescription</key>
    <string>FruitClip needs Accessibility permission to automatically paste clipboard items into other applications.</string>
</dict>
</plist>
PLIST

# Copy SPM module resources bundle (contains status bar icon accessed via Bundle.module)
SPM_BUNDLE="${BUILD_DIR}/FruitClip_FruitClip.bundle"
if [ -d "${SPM_BUNDLE}" ]; then
    echo "Copying SPM resources bundle..."
    cp -R "${SPM_BUNDLE}" "${APP_BUNDLE}/Contents/Resources/"
else
    echo "Warning: SPM resources bundle not found at ${SPM_BUNDLE} — status bar icon will fall back to paperclip"
fi

echo "Code signing (ad-hoc)..."
codesign --force --sign - "${APP_BUNDLE}"

echo "Verifying build..."
codesign --verify --deep --strict "${APP_BUNDLE}"
plutil -lint "${APP_BUNDLE}/Contents/Info.plist" > /dev/null
test -x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" || { echo "ERROR: binary not executable"; exit 1; }

echo ""
echo "Build complete: $(pwd)/${APP_BUNDLE}"
echo "Run with: open ${APP_BUNDLE}"
