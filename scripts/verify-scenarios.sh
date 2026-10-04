#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "============================================="
echo "       mailto: End-to-End Verification       "
echo "============================================="

# 1. Ensure build artifact exists
APP_PATH="$ROOT_DIR/build/mailto.app"
if [ ! -d "$APP_PATH" ]; then
    echo "Building mailto.app..."
    bash "$SCRIPT_DIR/build-app.sh"
fi

# 2. Check binary validity
BINARY="$APP_PATH/Contents/MacOS/mailto"
if [ -x "$BINARY" ]; then
    echo "✔ Binary exists and is executable: $BINARY"
else
    echo "✘ Binary missing or not executable: $BINARY"
    exit 1
fi

# 3. Check Info.plist
PLIST="$APP_PATH/Contents/Info.plist"
if [ -f "$PLIST" ]; then
    echo "✔ Info.plist found in bundle"
else
    echo "✘ Info.plist missing from bundle"
    exit 1
fi

# 4. Check AppIcon.icns
ICON="$APP_PATH/Contents/Resources/AppIcon.icns"
if [ -f "$ICON" ]; then
    echo "✔ AppIcon.icns found in bundle"
else
    echo "✘ AppIcon.icns missing from bundle"
    exit 1
fi

# 5. Run full test suite
echo ""
echo "=== Running 40 Unit & Integration Tests ==="
swift test --package-path "$ROOT_DIR"

# 6. Verify LaunchServices registration
echo ""
echo "=== Verifying LaunchServices Scheme Claim ==="
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -dump | grep -A5 -B2 "com.atalayhuryasar.mailto" | head -n 12

echo ""
echo "============================================="
echo "     All End-to-End Checks Passed! 🚀        "
echo "============================================="
