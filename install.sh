#!/bin/bash
set -euo pipefail

# ─── Constants ────────────────────────────────────────────────────────────────
APP_NAME="FruitClip"
BUNDLE_ID="com.veer.FruitClip"
APP_BUNDLE="${APP_NAME}.app"
INSTALL_DEST="/Applications/${APP_BUNDLE}"
APP_DATA_DIR="${HOME}/Library/Application Support/${BUNDLE_ID}"

# ─── Helpers ──────────────────────────────────────────────────────────────────
step=0
total_steps=6

log_step() {
    step=$((step + 1))
    echo ""
    echo "[${step}/${total_steps}] $1"
}

log_info() {
    echo "          $1"
}

log_ok() {
    echo "       ✓  $1"
}

log_warn() {
    echo "       ⚠  $1"
}

log_error() {
    echo ""
    echo "  ERROR: $1" >&2
}

# Trap for clean error output — only fires if set -e triggers an unexpected exit.
on_error() {
    echo ""
    echo "  Installation failed at step ${step}/${total_steps}. See output above." >&2
    exit 1
}
trap on_error ERR

# ─── Banner ───────────────────────────────────────────────────────────────────
VERSION="unknown"
if [ -d "${APP_BUNDLE}/Contents" ]; then
    VERSION="$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" \
        "${APP_BUNDLE}/Contents/Info.plist" 2>/dev/null || echo "unknown")"
fi

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║         FruitClip Installer                      ║"
printf "║  Version: %-38s  ║\n" "${VERSION}"
printf "║  Date:    %-38s  ║\n" "$(date '+%Y-%m-%d %H:%M:%S')"
echo "╚══════════════════════════════════════════════════╝"

# ─── Prerequisite Check ───────────────────────────────────────────────────────
echo ""
echo "  Checking prerequisites..."

if [ ! -d "${APP_BUNDLE}" ]; then
    log_error "${APP_BUNDLE} not found in current directory."
    echo "          Run ./build.sh first to produce the app bundle." >&2
    exit 1
fi

if [ ! -x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}" ]; then
    log_error "Binary not executable: ${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
    echo "          Run ./build.sh to rebuild the app bundle." >&2
    exit 1
fi

if ! codesign --verify --deep --strict "${APP_BUNDLE}" 2>/dev/null; then
    log_error "Code signature verification failed for ${APP_BUNDLE}."
    echo "          Run ./build.sh to rebuild and re-sign the app bundle." >&2
    exit 1
fi

log_ok "Prerequisites satisfied — ${APP_BUNDLE} is built and signed."

# ─── Step 1: Stop running instances ───────────────────────────────────────────
log_step "Stopping any running ${APP_NAME} instances..."

if pgrep -x "${APP_NAME}" > /dev/null 2>&1; then
    # pkill -x matches the exact process name; || true ensures set -e doesn't
    # fire if the process exits before pkill sends the signal.
    pkill -x "${APP_NAME}" || true
    sleep 1
    if pgrep -x "${APP_NAME}" > /dev/null 2>&1; then
        log_warn "Process still running — sending SIGKILL."
        pkill -9 -x "${APP_NAME}" || true
        sleep 1
    fi
    log_ok "Stopped running ${APP_NAME} instance."
else
    log_info "No running instance found — skipping."
fi

# ─── Step 2: Remove previous version ─────────────────────────────────────────
log_step "Removing previous version..."
log_info "Location: ${INSTALL_DEST}"

if [ -d "${INSTALL_DEST}" ]; then
    rm -rf "${INSTALL_DEST}"
    log_ok "Removed previous install at ${INSTALL_DEST}"
else
    log_info "No previous install found — skipping."
fi

log_info "Note: App data at '${APP_DATA_DIR}' is preserved."

# ─── Step 3: Install to /Applications ────────────────────────────────────────
log_step "Installing ${APP_BUNDLE} to /Applications..."
log_info "Source:      $(pwd)/${APP_BUNDLE}"
log_info "Destination: ${INSTALL_DEST}"

cp -R "${APP_BUNDLE}" /Applications/

# Verify the binary landed correctly
if [ ! -x "${INSTALL_DEST}/Contents/MacOS/${APP_NAME}" ]; then
    log_error "Installation failed — binary not found at destination."
    exit 1
fi

log_ok "Installed successfully."

# ─── Step 4: Remove quarantine flag ──────────────────────────────────────────
log_step "Removing quarantine flag..."
# xattr may return non-zero if the attribute isn't set — that's fine.
xattr -dr com.apple.quarantine "${INSTALL_DEST}" 2>/dev/null || true
log_ok "Quarantine cleared (or was not set)."

# ─── Step 5: Launch ───────────────────────────────────────────────────────────
log_step "Launching ${APP_NAME} from /Applications..."
log_info "Running: open ${INSTALL_DEST}"

open "${INSTALL_DEST}"
sleep 2

if pgrep -x "${APP_NAME}" > /dev/null 2>&1; then
    log_ok "${APP_NAME} is running."
else
    log_warn "${APP_NAME} process not detected after 2s. It may still be starting up."
    log_info "Check Console.app or run: log stream --predicate 'subsystem == \"${BUNDLE_ID}\"'"
fi

# ─── Step 6: Summary ─────────────────────────────────────────────────────────
log_step "Installation complete."
echo ""
echo "  ┌─────────────────────────────────────────────────────────────┐"
echo "  │  Folder Locations                                           │"
printf "  │  Installed to:  %-44s│\n" "${INSTALL_DEST}"
printf "  │  App data:      %-44s│\n" "${APP_DATA_DIR}/"
echo "  │  Preferences:   ~/Library/Preferences/${BUNDLE_ID}.plist   │"
echo "  │                                                             │"
echo "  │  View live logs:                                            │"
echo "  │    log stream --predicate 'subsystem == \"${BUNDLE_ID}\"'     │"
echo "  │                                                             │"
echo "  │  Uninstall:  ./uninstall.sh                                 │"
echo "  │  Wipe data:  ./uninstall.sh --wipe-data                     │"
echo "  └─────────────────────────────────────────────────────────────┘"

# ─── Next Steps ──────────────────────────────────────────────────────────────
echo ""
echo "  NEXT STEPS"
echo "  ──────────"
echo "  1. ${APP_NAME} appears in your menu bar. Press ⌘⇧V to open."
echo "  2. Grant Accessibility for auto-paste:"
echo "       System Settings → Privacy & Security → Accessibility → ${APP_NAME}"
echo "  3. Enable Launch at Login in Preferences."
echo "  4. To change the hotkey, click Record in Preferences."
echo "  5. To reinstall: ./build.sh && ./install.sh"
echo "  6. To uninstall cleanly: ./uninstall.sh"
echo ""
