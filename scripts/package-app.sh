#!/bin/sh
set -eu

PROJECT_ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-release}"
APP_PATH="$PROJECT_ROOT/dist/CodexThemeSwitcher.app"
BUILD_PATH="$PROJECT_ROOT/.build/$CONFIGURATION"
BINARY_PATH="$BUILD_PATH/CodexThemeSwitcher"
RUNTIME_RESOURCE_BUNDLE="$BUILD_PATH/CodexThemeSwitcher_CodexThemeRuntime.bundle"
APP_RESOURCE_BUNDLE="$BUILD_PATH/CodexThemeSwitcher_CodexThemeSwitcher.bundle"
STAGING_PATH="$PROJECT_ROOT/dist/.CodexThemeSwitcher.app.staging"

cd "$PROJECT_ROOT"
swift build -c "$CONFIGURATION"

rm -rf "$STAGING_PATH"
mkdir -p \
  "$STAGING_PATH/Contents/MacOS" \
  "$STAGING_PATH/Contents/Resources"

cp "$BINARY_PATH" "$STAGING_PATH/Contents/MacOS/CodexThemeSwitcher"
cp "$PROJECT_ROOT/Packaging/Info.plist" "$STAGING_PATH/Contents/Info.plist"
cp "$PROJECT_ROOT/Packaging/AppIcon.icns" \
  "$STAGING_PATH/Contents/Resources/AppIcon.icns"
cp -R \
  "$RUNTIME_RESOURCE_BUNDLE" \
  "$STAGING_PATH/Contents/Resources/CodexThemeSwitcher_CodexThemeRuntime.bundle"
cp -R \
  "$APP_RESOURCE_BUNDLE" \
  "$STAGING_PATH/Contents/Resources/CodexThemeSwitcher_CodexThemeSwitcher.bundle"

if [ -n "${CODESIGN_IDENTITY:-}" ]; then
  codesign \
    --force \
    --deep \
    --options runtime \
    --timestamp \
    --sign "$CODESIGN_IDENTITY" \
    "$STAGING_PATH"
else
  codesign --force --deep --sign - "$STAGING_PATH"
fi

rm -rf "$APP_PATH"
mv "$STAGING_PATH" "$APP_PATH"

echo "$APP_PATH"
