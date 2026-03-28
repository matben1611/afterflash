#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# build-app.sh — builds afterflash-mac-VERSION.app for macOS
#
# Steps:
#   1. Assemble a self-contained standalone.sh from all modules + setup
#   2. Create a signed-ready .app bundle that opens Terminal on double-click
#   3. Verify the bundle structure
#
# Usage:
#   bash mac/tools/build-app.sh          # from repo root
#   bash mac/tools/build-app.sh --force  # rebuild even if up to date
# ---------------------------------------------------------------------------

set -euo pipefail

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAC_DIR="$(dirname "$TOOLS_DIR")"         # mac/
REPO_ROOT="$(dirname "$MAC_DIR")"         # repo root
SCRIPTS_DIR="$MAC_DIR/scripts"
MODULES_DIR="$SCRIPTS_DIR/modules"

FORCE=false
for arg in "$@"; do
    [[ "$arg" == "--force" ]] && FORCE=true
done

# ── 0. Read version ──────────────────────────────────────────────────────────

VERSION_FILE="$REPO_ROOT/VERSION"
if [[ ! -f "$VERSION_FILE" ]]; then
    echo "ERROR: VERSION file not found at $VERSION_FILE" >&2
    exit 1
fi
VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"

APP_NAME="afterflash-mac-$VERSION"
APP_PATH="$REPO_ROOT/${APP_NAME}.app"
STANDALONE_SH="$MAC_DIR/afterflash-mac-standalone.sh"

echo ""
echo "========================================"
echo "      afterflash-mac app builder        "
echo "========================================"
echo ""
echo "  Version : $VERSION"
echo "  Output  : ${APP_NAME}.app"
echo ""

# ── 1. Up-to-date check ──────────────────────────────────────────────────────

if [[ "$FORCE" == "false" && -d "$APP_PATH" ]]; then
    newest_src=0
    while IFS= read -r -d '' f; do
        mtime=$(stat -f '%m' "$f" 2>/dev/null || stat -c '%Y' "$f" 2>/dev/null || echo 0)
        (( mtime > newest_src )) && newest_src=$mtime
    done < <(find "$SCRIPTS_DIR" -name '*.sh' -print0)

    app_mtime=$(stat -f '%m' "$APP_PATH" 2>/dev/null || stat -c '%Y' "$APP_PATH" 2>/dev/null || echo 0)

    if (( app_mtime >= newest_src )); then
        echo "  .app is up to date. Use --force to rebuild."
        echo ""
        exit 0
    fi
    echo "  Source files are newer — rebuilding..."
    echo ""
fi

# ── 2. Assemble standalone script ────────────────────────────────────────────

echo "[1/3] Assembling standalone script..."

{
    echo "#!/usr/bin/env bash"
    echo "set -euo pipefail"
    echo ""
    echo "# afterflash-mac v${VERSION} — standalone (auto-generated, do not edit)"
    echo "# Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    for module in helpers system tweaks apps; do
        src="$MODULES_DIR/${module}.sh"
        if [[ ! -f "$src" ]]; then
            echo "ERROR: Module not found: $src" >&2
            exit 1
        fi
        echo "# ── Module: ${module} ──────────────────────────────────────────────"
        # Strip the shebang line
        tail -n +2 "$src"
        echo ""
    done

    echo "# ── Orchestrator ────────────────────────────────────────────────────"
    # From setup.sh: skip shebang, SCRIPT_DIR, MODULES_DIR and source lines
    tail -n +2 "$SCRIPTS_DIR/setup.sh" \
        | grep -v '^SCRIPT_DIR=' \
        | grep -v '^MODULES_DIR=' \
        | grep -v '^source "'

} > "$STANDALONE_SH"

chmod +x "$STANDALONE_SH"
echo "    -> $STANDALONE_SH"

# ── 3. Build .app bundle ─────────────────────────────────────────────────────

echo ""
echo "[2/3] Building .app bundle..."

rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# --- Launcher (opens Terminal and runs the bundled script) ---

LAUNCHER="$APP_PATH/Contents/MacOS/afterflash-mac"
cat > "$LAUNCHER" << 'LAUNCHER_EOF'
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP="$SCRIPT_DIR/../Resources/setup.sh"
chmod +x "$SETUP"

osascript - "$SETUP" << 'APPLESCRIPT'
on run argv
    set setupScript to item 1 of argv
    tell application "Terminal"
        activate
        do script "bash " & quoted form of setupScript & "; exit"
    end tell
end run
APPLESCRIPT
LAUNCHER_EOF
chmod +x "$LAUNCHER"

# --- Bundled script ---
cp "$STANDALONE_SH" "$APP_PATH/Contents/Resources/setup.sh"
chmod +x "$APP_PATH/Contents/Resources/setup.sh"

# --- Info.plist ---
cat > "$APP_PATH/Contents/Info.plist" << PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>afterflash-mac</string>
    <key>CFBundleIdentifier</key>
    <string>com.afterflash.mac</string>
    <key>CFBundleName</key>
    <string>afterflash-mac</string>
    <key>CFBundleDisplayName</key>
    <string>afterflash-mac</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST_EOF

echo "    -> $APP_PATH"

# ── 4. Verify ────────────────────────────────────────────────────────────────

echo ""
echo "[3/3] Verifying bundle..."

errors=0
for required in \
    "$APP_PATH/Contents/Info.plist" \
    "$APP_PATH/Contents/MacOS/afterflash-mac" \
    "$APP_PATH/Contents/Resources/setup.sh"
do
    if [[ -f "$required" ]]; then
        echo "    [OK] $(basename "$required")"
    else
        echo "    [!!] MISSING: $required" >&2
        (( errors++ )) || true
    fi
done

if [[ $errors -gt 0 ]]; then
    echo ""
    echo "ERROR: Bundle verification failed ($errors missing file(s))." >&2
    exit 1
fi

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "========================================"
echo "               Done                     "
echo "========================================"
echo ""
echo "  Built  : ${APP_NAME}.app"
echo "  Version: $VERSION"
echo ""
echo "  Double-click the .app to run in Terminal."
echo "  Or distribute as a zipped .app:"
echo "    cd $(dirname "$APP_PATH") && zip -r ${APP_NAME}.zip ${APP_NAME}.app"
echo ""
