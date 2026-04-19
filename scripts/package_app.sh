#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="SlackMenuBadge.app"
PRODUCT_NAME="SlackMenuBadge"
BUILD_DIR="$ROOT_DIR/.build/apple/Products/Release"
APP_DIR="$BUILD_DIR/$APP_NAME"
DOWNLOADS_DIR="$HOME/Downloads"
DOWNLOADS_APP_DIR="$DOWNLOADS_DIR/$APP_NAME"
ICON_SOURCE_SVG="$ROOT_DIR/AppResources/AppIcon.svg"
ICON_RENDERED_PNG="$ROOT_DIR/.build/AppIcon.rendered.png"
ICONSET_DIR="$ROOT_DIR/.build/AppIcon.iconset"
ICON_FILE="$ROOT_DIR/.build/AppIcon.icns"

cd "$ROOT_DIR"

swift build -c release

rm -rf "$ICONSET_DIR" "$ICON_FILE" "$ICON_RENDERED_PNG"
mkdir -p "$ICONSET_DIR"

sips -s format png "$ICON_SOURCE_SVG" --out "$ICON_RENDERED_PNG" >/dev/null

cp "$ICON_RENDERED_PNG" "$ICONSET_DIR/icon_512x512@2x.png"
sips -z 16 16     "$ICON_RENDERED_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32     "$ICON_RENDERED_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32     "$ICON_RENDERED_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64     "$ICON_RENDERED_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128   "$ICON_RENDERED_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256   "$ICON_RENDERED_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$ICON_RENDERED_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512   "$ICON_RENDERED_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$ICON_RENDERED_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null

iconutil -c icns "$ICONSET_DIR" -o "$ICON_FILE"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$ROOT_DIR/AppResources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ICON_FILE" "$APP_DIR/Contents/Resources/AppIcon.icns"
cp "$ROOT_DIR/AppResources/slack-icon.png" "$APP_DIR/Contents/Resources/slack-icon.png"
cp "$ROOT_DIR/.build/release/$PRODUCT_NAME" "$APP_DIR/Contents/MacOS/$PRODUCT_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$PRODUCT_NAME"

rm -rf "$DOWNLOADS_APP_DIR"
mkdir -p "$DOWNLOADS_DIR"
cp -R "$APP_DIR" "$DOWNLOADS_APP_DIR"

echo "Packaged app:"
echo "  $DOWNLOADS_APP_DIR"
