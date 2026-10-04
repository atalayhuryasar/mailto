#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== 1. Building Release Binary ==="
swift build -c release --package-path "$ROOT_DIR"

BIN_PATH="$ROOT_DIR/.build/release/mailto"
if [ ! -f "$BIN_PATH" ]; then
    BIN_PATH=$(swift build -c release --show-bin-path)/mailto
fi

echo "Using binary: $BIN_PATH"

echo "=== 2. Assembling Mailto.app Bundle ==="
APP_BUNDLE="$ROOT_DIR/build/Mailto.app"
rm -rf "$APP_BUNDLE" "$ROOT_DIR/build/mailto:.app" "$ROOT_DIR/build/MacMail.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/mailto"
chmod +x "$APP_BUNDLE/Contents/MacOS/mailto"

cp "$ROOT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

if [ -f "$ROOT_DIR/Resources/AppIcon.icns" ]; then
    cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

echo "=== 3. Codesigning Mailto.app ==="
codesign --force --deep --sign - --entitlements "$ROOT_DIR/Resources/mailto.entitlements" "$APP_BUNDLE"

echo "=== 4. Registering with LaunchServices ==="
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_BUNDLE"

echo "=== 5. Creating Distribution Archive ==="
(cd "$ROOT_DIR/build" && rm -f mailto.zip && zip -r -y -q -X mailto.zip "Mailto.app")
echo "Archive created: $ROOT_DIR/build/mailto.zip"

echo "=== Build & Registration Complete: $APP_BUNDLE ==="
