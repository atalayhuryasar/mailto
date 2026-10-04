#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "============================================="
echo "   Building mailto: for Mac App Store (MAS)  "
echo "============================================="

# 1. Compile Release Binary with -DAPPSTORE flag
echo "=== 1. Compiling with -DAPPSTORE flag ==="
swift build -c release -Xswiftc -DAPPSTORE --package-path "$ROOT_DIR"

BIN_PATH="$ROOT_DIR/.build/release/mailto"
if [ ! -f "$BIN_PATH" ]; then
    BIN_PATH=$(swift build -c release -Xswiftc -DAPPSTORE --show-bin-path)/mailto
fi

echo "Using binary: $BIN_PATH"

# 2. Assemble App Bundle
echo "=== 2. Assembling App Store Bundle ==="
MAS_DIR="$ROOT_DIR/build/mas"
APP_BUNDLE="$MAS_DIR/mailto.app"

rm -rf "$MAS_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources/en.lproj"

cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/mailto"
chmod +x "$APP_BUNDLE/Contents/MacOS/mailto"

cp "$ROOT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

cat << 'EOF' > "$APP_BUNDLE/Contents/Resources/en.lproj/InfoPlist.strings"
"CFBundleDisplayName" = "mailto:";
"CFBundleName" = "mailto:";
EOF

if [ -f "$ROOT_DIR/Resources/AppIcon.icns" ]; then
    cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

if [ -f "$ROOT_DIR/Resources/Credits.rtf" ]; then
    cp "$ROOT_DIR/Resources/Credits.rtf" "$APP_BUNDLE/Contents/Resources/Credits.rtf"
fi

# 3. Codesigning with Sandbox Entitlements
ENTITLEMENTS="$ROOT_DIR/Resources/mailto-sandbox.entitlements"
echo "=== 3. Codesigning with App Sandbox Entitlements ==="

if [ -n "$APP_KEY" ]; then
    echo "Signing with Apple Distribution Identity: $APP_KEY"
    codesign --force --deep --options runtime --sign "$APP_KEY" --entitlements "$ENTITLEMENTS" "$APP_BUNDLE"
else
    echo "Notice: APP_KEY environment variable not set. Signing ad-hoc for local testing."
    codesign --force --deep --sign - --entitlements "$ENTITLEMENTS" "$APP_BUNDLE"
fi

# 4. Packaging into .pkg for App Store Connect upload
echo "=== 4. Packaging for Mac App Store (.pkg) ==="
PKG_PATH="$MAS_DIR/mailto.pkg"

if [ -n "$INSTALLER_KEY" ]; then
    echo "Building signed .pkg with: $INSTALLER_KEY"
    productbuild --component "$APP_BUNDLE" /Applications --sign "$INSTALLER_KEY" "$PKG_PATH"
    echo "Signed PKG created: $PKG_PATH"
else
    echo "Notice: INSTALLER_KEY not set. Building unsigned package component..."
    productbuild --component "$APP_BUNDLE" /Applications "$PKG_PATH"
    echo "Component PKG created: $PKG_PATH"
    echo ""
    echo "Tip: When ready for App Store submission, provide certificates:"
    echo "  APP_KEY=\"Apple Distribution: Your Name (TEAM_ID)\""
    echo "  INSTALLER_KEY=\"3rd Party Mac Developer Installer: Your Name (TEAM_ID)\""
    echo "  ./scripts/build-mas.sh"
fi

echo ""
echo "============================================="
echo " MAS Build Complete: $APP_BUNDLE"
echo " Package: $PKG_PATH"
echo "============================================="
