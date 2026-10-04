#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "============================================="
echo "       MacMail Clean Reset & Reinstall       "
echo "============================================="

# 1. Terminate running instances
echo "1. Terminating running MacMail instances..."
pkill -x MacMail 2>/dev/null || true
sleep 0.5

# 2. Reset default mail handler back to Apple Mail
echo "2. Resetting default mailto handler to Apple Mail..."
swift -e 'import Foundation; import CoreServices; LSSetDefaultHandlerForURLScheme("mailto" as CFString, "com.apple.mail" as CFString)' 2>/dev/null || true

# 3. Clean user preferences and caches
echo "3. Removing stored settings and caches..."
defaults delete com.atalayhuryasar.macmail 2>/dev/null || true
rm -rf "$HOME/Library/Caches/com.atalayhuryasar.macmail"
rm -rf "$HOME/Library/Application Support/com.atalayhuryasar.macmail"
rm -f "$HOME/Library/Preferences/com.atalayhuryasar.macmail.plist"

# 4. Clean previous build artifacts
echo "4. Removing previous build artifacts..."
rm -rf "$ROOT_DIR/build"

# 5. Rebuild from scratch
echo "5. Building fresh MacMail.app..."
bash "$SCRIPT_DIR/build-app.sh"

echo ""
echo "============================================="
echo "   Clean Reinstall Complete! Opening App...  "
echo "============================================="
open "$ROOT_DIR/build/MacMail.app"
