#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-release}"
CONFIGURATION="$(printf '%s' "$CONFIGURATION" | tr '[:upper:]' '[:lower:]')"
ARCHS="${ARCHS:-}"
APP_PATH="$PROJECT_ROOT/dist/CodexThemeSwitcher.app"
STAGING_PATH="$PROJECT_ROOT/dist/.CodexThemeSwitcher.app.staging"
INFO_PLIST_PATH="$STAGING_PATH/Contents/Info.plist"
APP_BINARY_PATH="$STAGING_PATH/Contents/MacOS/CodexThemeSwitcher"
AGENT_CLI_PATH="$STAGING_PATH/Contents/Helpers/codex-theme"
AGENT_SCHEMA_PATH="$STAGING_PATH/Contents/Resources/Schemas/codextheme.schema.json"
SPARKLE_FRAMEWORK_PATH="$STAGING_PATH/Contents/Frameworks/Sparkle.framework"
PLIST_BUDDY="/usr/libexec/PlistBuddy"

case "$CONFIGURATION" in
  debug|release) ;;
  *)
    echo "Unsupported CONFIGURATION: $CONFIGURATION (expected debug or release)." >&2
    exit 1
    ;;
esac

SWIFT_BUILD_ARGS=(-c "$CONFIGURATION")
NORMALIZED_ARCHS="${ARCHS//,/ }"
for arch in $NORMALIZED_ARCHS; do
  case "$arch" in
    arm64|x86_64)
      SWIFT_BUILD_ARGS+=(--arch "$arch")
      ;;
    *)
      echo "Unsupported ARCHS entry: $arch (expected arm64 or x86_64)." >&2
      exit 1
      ;;
  esac
done

cd "$PROJECT_ROOT"
swift build "${SWIFT_BUILD_ARGS[@]}"
BUILD_PATH="$(swift build "${SWIFT_BUILD_ARGS[@]}" --show-bin-path)"
BINARY_PATH="$BUILD_PATH/CodexThemeSwitcher"
AGENT_CLI_SOURCE="$BUILD_PATH/codex-theme"
RUNTIME_RESOURCE_BUNDLE="$BUILD_PATH/CodexThemeSwitcher_CodexThemeRuntime.bundle"
APP_RESOURCE_BUNDLE="$BUILD_PATH/CodexThemeSwitcher_CodexThemeSwitcher.bundle"
SPARKLE_FRAMEWORK_SOURCE="$BUILD_PATH/Sparkle.framework"

for required_path in \
  "$BINARY_PATH" \
  "$AGENT_CLI_SOURCE" \
  "$PROJECT_ROOT/Sources/CodexThemeAgentCLI/Resources/codextheme.schema.json" \
  "$RUNTIME_RESOURCE_BUNDLE" \
  "$APP_RESOURCE_BUNDLE" \
  "$SPARKLE_FRAMEWORK_SOURCE"; do
  if [[ ! -e "$required_path" ]]; then
    echo "Required build product is missing: $required_path" >&2
    exit 1
  fi
done

rm -rf "$STAGING_PATH"
mkdir -p \
  "$STAGING_PATH/Contents/MacOS" \
  "$STAGING_PATH/Contents/Helpers" \
  "$STAGING_PATH/Contents/Resources" \
  "$STAGING_PATH/Contents/Resources/Schemas" \
  "$STAGING_PATH/Contents/Frameworks"

cp "$BINARY_PATH" "$APP_BINARY_PATH"
cp "$AGENT_CLI_SOURCE" "$AGENT_CLI_PATH"
chmod +x "$AGENT_CLI_PATH"
cp "$PROJECT_ROOT/Packaging/Info.plist" "$INFO_PLIST_PATH"
cp "$PROJECT_ROOT/Packaging/AppIcon.icns" \
  "$STAGING_PATH/Contents/Resources/AppIcon.icns"
cp \
  "$PROJECT_ROOT/Sources/CodexThemeAgentCLI/Resources/codextheme.schema.json" \
  "$AGENT_SCHEMA_PATH"
ditto \
  "$RUNTIME_RESOURCE_BUNDLE" \
  "$STAGING_PATH/Contents/Resources/CodexThemeSwitcher_CodexThemeRuntime.bundle"
ditto \
  "$APP_RESOURCE_BUNDLE" \
  "$STAGING_PATH/Contents/Resources/CodexThemeSwitcher_CodexThemeSwitcher.bundle"
ditto "$SPARKLE_FRAMEWORK_SOURCE" "$SPARKLE_FRAMEWORK_PATH"

RPATHS="$(
  otool -l "$APP_BINARY_PATH" | awk '
    $1 == "cmd" && $2 == "LC_RPATH" { in_rpath = 1; next }
    in_rpath && $1 == "path" { print $2; in_rpath = 0 }
  '
)"
if ! grep -Fqx "@executable_path/../Frameworks" <<<"$RPATHS"; then
  install_name_tool \
    -add_rpath "@executable_path/../Frameworks" \
    "$APP_BINARY_PATH"
fi

test -f \
  "$STAGING_PATH/Contents/Resources/CodexThemeSwitcher_CodexThemeRuntime.bundle/Resources/runtime/cli.js"
test -f \
  "$STAGING_PATH/Contents/Resources/CodexThemeSwitcher_CodexThemeSwitcher.bundle/MenuBarIcon.png"
test -x "$AGENT_CLI_PATH"
test -f "$AGENT_SCHEMA_PATH"
test -f "$SPARKLE_FRAMEWORK_PATH/Versions/B/Sparkle"
test -f "$SPARKLE_FRAMEWORK_PATH/Versions/B/Autoupdate"
test -d "$SPARKLE_FRAMEWORK_PATH/Versions/B/Updater.app"
test -d "$SPARKLE_FRAMEWORK_PATH/Versions/B/XPCServices/Downloader.xpc"
test -d "$SPARKLE_FRAMEWORK_PATH/Versions/B/XPCServices/Installer.xpc"

HOST_ARCH="$(uname -m)"
AGENT_CLI_ARCHS="$(lipo -archs "$AGENT_CLI_PATH")"
AGENT_CLI_RUNNER=("$AGENT_CLI_PATH")
CAN_RUN_AGENT_CLI=true
if ! grep -qw "$HOST_ARCH" <<<"$AGENT_CLI_ARCHS"; then
  if [[ "$HOST_ARCH" == "arm64" ]] \
      && grep -qw "x86_64" <<<"$AGENT_CLI_ARCHS" \
      && /usr/bin/arch -x86_64 /usr/bin/true 2>/dev/null; then
    AGENT_CLI_RUNNER=(/usr/bin/arch -x86_64 "$AGENT_CLI_PATH")
  else
    CAN_RUN_AGENT_CLI=false
  fi
fi

if [[ "$CAN_RUN_AGENT_CLI" == true ]]; then
  (
    cd /
    "${AGENT_CLI_RUNNER[@]}" capabilities
  ) | python3 -c '
import json
import sys

payload = json.load(sys.stdin)
if payload.get("ok") is not True or payload.get("command") != "capabilities":
    raise SystemExit("Packaged agent CLI capabilities smoke test failed.")
'
  (
    cd /
    "${AGENT_CLI_RUNNER[@]}" schema
  ) | python3 -c '
import json
import sys

payload = json.load(sys.stdin)
schema = payload.get("data", {}).get("schema", {})
if payload.get("ok") is not True or "$schema" not in schema:
    raise SystemExit("Packaged agent CLI schema smoke test failed.")
'
else
  echo "Skipping agent CLI smoke tests for non-runnable architectures: $AGENT_CLI_ARCHS"
fi

if ! otool -L "$APP_BINARY_PATH" \
  | grep -Fq "@rpath/Sparkle.framework/Versions/B/Sparkle"; then
  echo "Packaged executable is not linked to Sparkle.framework." >&2
  exit 1
fi

SIGNING_IDENTITY="${CODESIGN_IDENTITY:--}"
IS_DISTRIBUTION_BUILD=false
if [[ "$SIGNING_IDENTITY" != "-" ]]; then
  IS_DISTRIBUTION_BUILD=true
fi

delete_plist_key() {
  local key="$1"
  "$PLIST_BUDDY" -c "Delete :$key" "$INFO_PLIST_PATH" \
    >/dev/null 2>&1 || true
}

if [[ "$IS_DISTRIBUTION_BUILD" == true ]]; then
  SPARKLE_PUBLIC_ED_KEY="${SPARKLE_PUBLIC_ED_KEY:-}"
  if [[ -z "${SPARKLE_PUBLIC_ED_KEY//[[:space:]]/}" ]]; then
    echo "SPARKLE_PUBLIC_ED_KEY is required for a Developer ID build." >&2
    exit 1
  fi

  KEY_CHECK_PATH="$(mktemp)"
  if ! printf '%s' "$SPARKLE_PUBLIC_ED_KEY" \
      | base64 -D >"$KEY_CHECK_PATH" 2>/dev/null \
      || [[ "$(wc -c <"$KEY_CHECK_PATH" | tr -d '[:space:]')" != "32" ]]; then
    rm -f "$KEY_CHECK_PATH"
    echo "SPARKLE_PUBLIC_ED_KEY must be a Base64-encoded 32-byte Ed25519 public key." >&2
    exit 1
  fi
  rm -f "$KEY_CHECK_PATH"

  delete_plist_key "SUAllowsInsecureUpdates"
  delete_plist_key "SUPublicEDKey"
  "$PLIST_BUDDY" \
    -c "Add :SUPublicEDKey string $SPARKLE_PUBLIC_ED_KEY" \
    "$INFO_PLIST_PATH"
else
  delete_plist_key "SUPublicEDKey"
  delete_plist_key "SUAllowsInsecureUpdates"
  "$PLIST_BUDDY" \
    -c "Add :SUAllowsInsecureUpdates bool true" \
    "$INFO_PLIST_PATH"
fi

sign_target() {
  local target="$1"
  local sign_args=(
    --force
    --sign "$SIGNING_IDENTITY"
  )
  if [[ "$IS_DISTRIBUTION_BUILD" == true ]]; then
    sign_args+=(
      --options runtime
      --preserve-metadata=identifier,entitlements,flags
      --timestamp
    )
  else
    # An ad-hoc app and its embedded framework have no shared Team ID.
    # Enabling library validation here would make dyld reject Sparkle.
    sign_args+=(--preserve-metadata=identifier,entitlements)
  fi
  codesign "${sign_args[@]}" "$target"
}

while IFS= read -r -d '' nested_binary; do
  sign_target "$nested_binary"
done < <(
  find "$SPARKLE_FRAMEWORK_PATH/Versions/B" \
    -type f \( -perm -111 -o -name "*.dylib" \) \
    -print0
)

while IFS= read -r -d '' nested_bundle; do
  sign_target "$nested_bundle"
done < <(
  find "$SPARKLE_FRAMEWORK_PATH/Versions/B" \
    -type d \( -name "*.xpc" -o -name "*.app" \) \
    -print0
)

sign_target "$AGENT_CLI_PATH"
sign_target "$SPARKLE_FRAMEWORK_PATH"
sign_target "$STAGING_PATH"

codesign --verify --deep --strict --verbose=2 "$STAGING_PATH"

if [[ "$IS_DISTRIBUTION_BUILD" == true ]]; then
  SIGNATURE_DETAILS="$(codesign -d --verbose=4 "$STAGING_PATH" 2>&1)"
  if ! grep -Fq "Authority=Developer ID Application" \
      <<<"$SIGNATURE_DETAILS"; then
    echo "Distribution package is not signed with Developer ID Application." >&2
    exit 1
  fi
  if ! grep -Fq "Timestamp=" <<<"$SIGNATURE_DETAILS"; then
    echo "Distribution package signature is missing a secure timestamp." >&2
    exit 1
  fi
  if "$PLIST_BUDDY" -c "Print :SUAllowsInsecureUpdates" \
      "$INFO_PLIST_PATH" >/dev/null 2>&1; then
    echo "Distribution package must not allow insecure Sparkle updates." >&2
    exit 1
  fi
else
  if [[ "$("$PLIST_BUDDY" -c "Print :SUAllowsInsecureUpdates" "$INFO_PLIST_PATH")" != "true" ]]; then
    echo "Local ad-hoc package is missing its local-only Sparkle update allowance." >&2
    exit 1
  fi
fi

rm -rf "$APP_PATH"
mv "$STAGING_PATH" "$APP_PATH"

echo "$APP_PATH"
