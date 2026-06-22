#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="/tmp/ds-balance-build"
CACHE_DIR="/tmp/ds-balance-mcache"
SDK="$(xcrun --show-sdk-path --sdk macosx)"

mkdir -p "$BUILD_DIR" "$CACHE_DIR"

echo "==> Compiling..."
swiftc \
  -o "$BUILD_DIR/DeepSeekBalance" \
  -module-name DeepSeekBalance \
  -target arm64-apple-macosx15.0 \
  -sdk "$SDK" \
  -module-cache-path "$CACHE_DIR" \
  -framework SwiftUI \
  -framework AppKit \
  -framework Foundation \
  -framework Security \
  -framework ServiceManagement \
  -framework UserNotifications \
  "$PROJECT_DIR/Sources/DeepSeekBalance/"*.swift

echo "==> Bundling .app..."
APP_BUNDLE="$PROJECT_DIR/DeepSeekBalance.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

cp "$PROJECT_DIR/DeepSeekBalance.app/Contents/Info.plist" \
   "$APP_BUNDLE/Contents/Info.plist"

cp "$BUILD_DIR/DeepSeekBalance" \
   "$APP_BUNDLE/Contents/MacOS/DeepSeekBalance"

echo "==> Done: $APP_BUNDLE"
