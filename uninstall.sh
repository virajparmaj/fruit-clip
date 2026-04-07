#!/bin/bash
set -euo pipefail

# ─── Usage ────────────────────────────────────────────────────────────────────
# ./uninstall.sh              — removes /Applications/FruitClip.app only
# ./uninstall.sh --wipe-data  — also removes app data and preferences

# ─── Constants ────────────────────────────────────────────────────────────────
APP_NAME="FruitClip"
BUNDLE_ID="com.veer.FruitClip"
APP_BUNDLE="${APP_NAME}.app"
INSTALL_DEST="/Applications/${APP_BUNDLE}"
APP_DATA_DIR="${HOME}/Library/Application Support/${BUNDLE_ID}"
PREFS_FILE="${HOME}/Library/Preferences/${BUNDLE_ID}.plist"

WIPE_DATA=false
if [[ "${1:-}" == "--wipe-data" ]]; then
    WIPE_DATA=true
fi

# ─── Helpers ──────────────────────────────────────────────────────────────────
step=0
total_steps=2
[[ "${WIPE_DATA}" == "true" ]] && total_steps=3

log_step() {
    step=$((step + 1))
    echo ""
    echo "[${step}/${total_steps}] $1"
}

log_info() { echo "          $1"; }
log_ok()   { echo "       ✓  $1"; }
log_warn() { echo "       ⚠  $1"; }

on_error() {
    echo ""
    echo "  Uninstall failed at step ${step}/${total_steps}. See output above." >&2
    exit 1
}
trap on_error ERR

# ─── Banner ───────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║         FruitClip Uninstaller                    ║"
printf "║  Date:    %-38s  ║\n" "$(date '+%Y-%m-%d %H:%M:%S')"
if [[ "${WIPE_DATA}" == "true" ]]; then
echo "║  Mode:    Full removal (app + data)              ║"
else
echo "║  Mode:    App only  (run with --wipe-data        ║"
echo "║           to also remove history and prefs)      ║"
fi
echo "╚══════════════════════════════════════════════════╝"

echo ""
echo "  Will remove:"
echo "    ${INSTALL_DEST}"
if [[ "${WIPE_DATA}" == "true" ]]; then
    echo "    ${APP_DATA_DIR}/"
    echo "    ${PREFS_FILE}"
fi

# ─── Step 1: Stop running instance ────────────────────────────────────────────
log_step "Stopping any running ${APP_NAME} instances..."

if pgrep -x "${APP_NAME}" > /dev/null 2>&1; then
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

# ─── Step 2: Remove /Applications/FruitClip.app ───────────────────────────────
log_step "Removing ${INSTALL_DEST}..."

if [ -d "${INSTALL_DEST}" ]; then
    rm -rf "${INSTALL_DEST}"
    log_ok "Removed ${INSTALL_DEST}"
else
    log_warn "${INSTALL_DEST} not found — nothing to remove."
fi

# ─── Step 3 (optional): Wipe data and preferences ────────────────────────────
if [[ "${WIPE_DATA}" == "true" ]]; then
    log_step "Removing app data and preferences..."

    if [ -d "${APP_DATA_DIR}" ]; then
        rm -rf "${APP_DATA_DIR}"
        log_ok "Removed app data: ${APP_DATA_DIR}/"
    else
        log_info "App data directory not found — skipping."
        log_info "(${APP_DATA_DIR})"
    fi

    if [ -f "${PREFS_FILE}" ]; then
        rm -f "${PREFS_FILE}"
        log_ok "Removed preferences: ${PREFS_FILE}"
    else
        log_info "Preferences file not found — skipping."
        log_info "(${PREFS_FILE})"
    fi

    # Also flush any UserDefaults still cached in cfprefsd
    defaults delete "${BUNDLE_ID}" 2>/dev/null || true
    log_ok "Flushed UserDefaults cache."
fi

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "  ✓ FruitClip uninstalled."
if [[ "${WIPE_DATA}" == "false" ]]; then
    echo ""
    echo "  Your clipboard history is preserved at:"
    echo "    ${APP_DATA_DIR}/"
    echo ""
    echo "  To also remove history and preferences, run:"
    echo "    ./uninstall.sh --wipe-data"
fi
echo ""
