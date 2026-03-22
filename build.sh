#!/bin/bash
set -euo pipefail

APP_NAME="FruitClip"
BUNDLE_ID="com.veer.FruitClip"
VERSION="1.0"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"

echo "Building ${APP_NAME}..."
swift build -c release

echo "Assembling ${APP_BUNDLE}..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Generate app icon from fruit-clip.png if present
ICON_SOURCE="fruit-clip.png"
ICON_DEST="${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
if [ -f "${ICON_SOURCE}" ]; then
    echo "Generating app icon..."
    ICONSET_DIR="$(mktemp -d)/AppIcon.iconset"
    mkdir -p "${ICONSET_DIR}"
    sips -z 16 16     "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_16x16.png"     > /dev/null
    sips -z 32 32     "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_16x16@2x.png"  > /dev/null
    sips -z 32 32     "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_32x32.png"     > /dev/null
    sips -z 64 64     "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_32x32@2x.png"  > /dev/null
    sips -z 128 128   "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_128x128.png"   > /dev/null
    sips -z 256 256   "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_128x128@2x.png"> /dev/null
    sips -z 256 256   "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_256x256.png"   > /dev/null
    sips -z 512 512   "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_256x256@2x.png"> /dev/null
    sips -z 512 512   "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_512x512.png"   > /dev/null
    sips -z 1024 1024 "${ICON_SOURCE}" --out "${ICONSET_DIR}/icon_512x512@2x.png"> /dev/null
    iconutil --convert icns "${ICONSET_DIR}" --output "${ICON_DEST}"
    rm -rf "$(dirname "${ICONSET_DIR}")"
else
    echo "Warning: ${ICON_SOURCE} not found — skipping app icon."
fi

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

echo "Code signing (ad-hoc)..."
codesign --force --sign - "${APP_BUNDLE}"

echo "Verifying build..."
codesign --verify --deep --strict "${APP_BUNDLE}"
plutil -lint "${APP_BUNDLE}/Contents/Info.plist" > /dev/null
test -x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" || { echo "ERROR: binary not executable"; exit 1; }

echo ""
echo "Build complete: $(pwd)/${APP_BUNDLE}"
echo "Run with: open ${APP_BUNDLE}"
