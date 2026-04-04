#!/usr/bin/env bash
# Generate all icon variants from the source fruit-clip.png.
# Run once after changing the source artwork, then commit the outputs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE="$REPO_DIR/fruit-clip.png"
MENUBAR_SOURCE="$REPO_DIR/fruit-clip Background Removed.png"
ICON_OUT="$REPO_DIR/assets/icons/macos"
RESOURCES="$REPO_DIR/Sources/FruitClip/Resources"

if [ ! -f "$SOURCE" ]; then
    echo "Missing source: $SOURCE" >&2
    exit 1
fi

if [ ! -f "$MENUBAR_SOURCE" ]; then
    echo "Missing menubar source: $MENUBAR_SOURCE" >&2
    exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "→ Generating icon variants from fruit-clip.png..."

# Create a canonical 1024x1024 from the non-square source (1768x1772).
# -Z fits the longest edge to 1024, then -p pads to exact 1024x1024.
sips -Z 1024 "$SOURCE" --out "$WORK_DIR/canonical_1024.png" >/dev/null
sips -p 1024 1024 "$WORK_DIR/canonical_1024.png" --out "$WORK_DIR/canonical_1024.png" >/dev/null

# Generate all size variants
mkdir -p "$ICON_OUT"
for size in 16 32 64 128 256 512 1024; do
    if [ "$size" -eq 1024 ]; then
        cp "$WORK_DIR/canonical_1024.png" "$ICON_OUT/fruit_clip_icon_1024.png"
    else
        sips -z "$size" "$size" "$WORK_DIR/canonical_1024.png" \
            --out "$ICON_OUT/fruit_clip_icon_${size}.png" >/dev/null
    fi
    echo "   fruit_clip_icon_${size}.png"
done

# Generate menu bar icons from background-removed source
echo "→ Generating menu bar icons..."
sips -z 22 22 "$MENUBAR_SOURCE" --out "$RESOURCES/fruit-clip-status.png" >/dev/null
sips -z 44 44 "$MENUBAR_SOURCE" --out "$RESOURCES/fruit-clip-status@2x.png" >/dev/null
echo "   fruit-clip-status.png (22x22)"
echo "   fruit-clip-status@2x.png (44x44)"

# Replace the oversized fruit-clip.png in Resources with the 512px variant
cp "$ICON_OUT/fruit_clip_icon_512.png" "$RESOURCES/fruit-clip.png"
echo "   Replaced Resources/fruit-clip.png with 512px variant"

echo "✅ All icon assets generated."
