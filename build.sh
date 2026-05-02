#!/bin/bash
set -euo pipefail

# Build a macOS .app bundle for the Pomodoro menu bar app.
# Usage: ./build.sh [debug|release]   (default: release)

CONFIG="${1:-release}"
APP_NAME="Pomodoro"
ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$ROOT/$APP_NAME.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RES_DIR="$APP_DIR/Contents/Resources"

echo "→ swift build -c $CONFIG"
cd "$ROOT"
swift build -c "$CONFIG"

BIN_PATH="$(swift build -c "$CONFIG" --show-bin-path)/$APP_NAME"
if [[ ! -f "$BIN_PATH" ]]; then
    echo "Binary not found at $BIN_PATH" >&2
    exit 1
fi

echo "→ Assembling $APP_NAME.app"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RES_DIR"

cp "$BIN_PATH" "$MACOS_DIR/$APP_NAME"
cp "$ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"

echo "→ Ad-hoc codesigning"
codesign --force --deep --sign - "$APP_DIR"

echo "✓ Built $APP_DIR"
echo "  Run:  open \"$APP_DIR\""
