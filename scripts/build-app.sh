#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== 1. Generating Icons ==="
bash "$SCRIPT_DIR/generate-icons.sh"

echo "=== 2. Building Release Binary ==="
swift build -c release --package-path "$ROOT_DIR"

BIN_PATH="$ROOT_DIR/.build/release/MacMail"
if [ ! -f "$BIN_PATH" ]; then
    # Try finding the product in arm64 release or standard path
    BIN_PATH=$(swift build -c release --show-bin-path)/MacMail
fi

echo "Using binary: $BIN_PATH"

echo "=== 3. Assembling MacMail.app Bundle ==="
APP_BUNDLE="$ROOT_DIR/build/MacMail.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/MacMail"
chmod +x "$APP_BUNDLE/Contents/MacOS/MacMail"

cp "$ROOT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

if [ -f "$ROOT_DIR/build/AppIcon.icns" ]; then
    cp "$ROOT_DIR/build/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

echo "=== 4. Codesigning MacMail.app ==="
codesign --force --deep --sign - --entitlements "$ROOT_DIR/Resources/MacMail.entitlements" "$APP_BUNDLE"

echo "=== 5. Registering with LaunchServices ==="
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_BUNDLE"

echo "=== Build & Registration Complete: $APP_BUNDLE ==="
