#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PRODUCT_NAME="${APP_PRODUCT_NAME:-CodexThemeSwitcher}"
APP_DISPLAY_NAME="${APP_DISPLAY_NAME:-Codex Theme Switcher}"
TARGET_ARCH="${TARGET_ARCH:-}"
ARCH_LABEL="${ARCH_LABEL:-}"
RELEASE_VERSION="${RELEASE_VERSION:-}"
BUILD_VERSION="${BUILD_VERSION:-}"
CONFIGURATION="${CONFIGURATION:-release}"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-Developer ID Application}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
SPARKLE_SIGN_UPDATE="${SPARKLE_SIGN_UPDATE:-}"
SPARKLE_ED_PRIVATE_KEY="${SPARKLE_ED_PRIVATE_KEY:-}"
SPARKLE_PUBLIC_ED_KEY="${SPARKLE_PUBLIC_ED_KEY:-}"
DIST_DIR="${DIST_DIR:-${PROJECT_ROOT}/dist}"
WORK_DIR="${WORK_DIR:-${PROJECT_ROOT}/build/release-${TARGET_ARCH:-unknown}}"

fail() {
  echo "build-release-dmg: $*" >&2
  exit 1
}

require_nonempty() {
  local name="$1"
  local value="$2"
  [[ -n "${value//[[:space:]]/}" ]] || fail "${name} is required."
}

require_nonempty "TARGET_ARCH" "$TARGET_ARCH"
require_nonempty "ARCH_LABEL" "$ARCH_LABEL"
require_nonempty "RELEASE_VERSION" "$RELEASE_VERSION"
require_nonempty "BUILD_VERSION" "$BUILD_VERSION"
require_nonempty "CODE_SIGN_IDENTITY" "$CODE_SIGN_IDENTITY"
require_nonempty "NOTARY_PROFILE" "$NOTARY_PROFILE"
require_nonempty "SPARKLE_SIGN_UPDATE" "$SPARKLE_SIGN_UPDATE"
require_nonempty "SPARKLE_ED_PRIVATE_KEY" "$SPARKLE_ED_PRIVATE_KEY"
require_nonempty "SPARKLE_PUBLIC_ED_KEY" "$SPARKLE_PUBLIC_ED_KEY"

[[ "$TARGET_ARCH" == "arm64" || "$TARGET_ARCH" == "x86_64" ]] \
  || fail "TARGET_ARCH must be arm64 or x86_64."
[[ "$BUILD_VERSION" =~ ^[0-9]+$ ]] \
  || fail "BUILD_VERSION must be an unsigned integer."
[[ -x "$SPARKLE_SIGN_UPDATE" ]] \
  || fail "SPARKLE_SIGN_UPDATE is not executable: ${SPARKLE_SIGN_UPDATE}"

SAFE_VERSION="$(printf '%s' "$RELEASE_VERSION" | sed -E 's/[^A-Za-z0-9._-]+/-/g; s/^-+//; s/-+$//')"
require_nonempty "sanitized release version" "$SAFE_VERSION"

python3 - "$SPARKLE_PUBLIC_ED_KEY" <<'PY'
import base64
import binascii
import sys

try:
    public_key = base64.b64decode(sys.argv[1], validate=True)
except (binascii.Error, ValueError) as error:
    raise SystemExit(f"SPARKLE_PUBLIC_ED_KEY is not valid base64: {error}")
if len(public_key) != 32:
    raise SystemExit("SPARKLE_PUBLIC_ED_KEY must decode to a 32-byte Ed25519 public key.")
PY

APP_PATH="${WORK_DIR}/${APP_PRODUCT_NAME}.app"
APP_BINARY="${APP_PATH}/Contents/MacOS/${APP_PRODUCT_NAME}"
FRAMEWORKS_DIR="${APP_PATH}/Contents/Frameworks"
RESOURCES_DIR="${APP_PATH}/Contents/Resources"
STAGING_DIR="${WORK_DIR}/dmg-staging"
DMG_NAME="${APP_PRODUCT_NAME}-${SAFE_VERSION}-${ARCH_LABEL}.dmg"
DMG_PATH="${WORK_DIR}/${DMG_NAME}"
DSYM_PATH="${WORK_DIR}/${APP_PRODUCT_NAME}.app.dSYM"
DSYM_ZIP_NAME="${APP_PRODUCT_NAME}-${SAFE_VERSION}-${ARCH_LABEL}.dSYM.zip"
DSYM_ZIP_PATH="${WORK_DIR}/${DSYM_ZIP_NAME}"
SIGNATURE_PATH="${DIST_DIR}/${DMG_NAME}.edSignature"

case "$WORK_DIR" in
  "$PROJECT_ROOT"/build/release-*)
    ;;
  *)
    fail "WORK_DIR must be a release staging directory under ${PROJECT_ROOT}/build."
    ;;
esac

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR" "$DIST_DIR"

cd "$PROJECT_ROOT"

echo "==> Building ${APP_PRODUCT_NAME} for ${TARGET_ARCH}"
swift build \
  -c "$CONFIGURATION" \
  --arch "$TARGET_ARCH" \
  --product "$APP_PRODUCT_NAME"

BIN_DIR="$(swift build -c "$CONFIGURATION" --arch "$TARGET_ARCH" --show-bin-path)"
BINARY_SOURCE="${BIN_DIR}/${APP_PRODUCT_NAME}"
SPARKLE_FRAMEWORK_SOURCE="${BIN_DIR}/Sparkle.framework"
RUNTIME_RESOURCE_BUNDLE="${BIN_DIR}/${APP_PRODUCT_NAME}_CodexThemeRuntime.bundle"
APP_RESOURCE_BUNDLE="${BIN_DIR}/${APP_PRODUCT_NAME}_${APP_PRODUCT_NAME}.bundle"

[[ -f "$BINARY_SOURCE" ]] || fail "Missing executable: ${BINARY_SOURCE}"
[[ -d "$SPARKLE_FRAMEWORK_SOURCE" ]] || fail "Missing Sparkle.framework: ${SPARKLE_FRAMEWORK_SOURCE}"
[[ -d "$RUNTIME_RESOURCE_BUNDLE" ]] || fail "Missing runtime resource bundle: ${RUNTIME_RESOURCE_BUNDLE}"
[[ -d "$APP_RESOURCE_BUNDLE" ]] || fail "Missing app resource bundle: ${APP_RESOURCE_BUNDLE}"

echo "==> Staging .app bundle"
mkdir -p \
  "${APP_PATH}/Contents/MacOS" \
  "$FRAMEWORKS_DIR" \
  "$RESOURCES_DIR"

ditto "$BINARY_SOURCE" "$APP_BINARY"
ditto "$PROJECT_ROOT/Packaging/Info.plist" "${APP_PATH}/Contents/Info.plist"
ditto "$PROJECT_ROOT/Packaging/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
ditto "$SPARKLE_FRAMEWORK_SOURCE" "${FRAMEWORKS_DIR}/Sparkle.framework"
ditto "$RUNTIME_RESOURCE_BUNDLE" "${RESOURCES_DIR}/${APP_PRODUCT_NAME}_CodexThemeRuntime.bundle"
ditto "$APP_RESOURCE_BUNDLE" "${RESOURCES_DIR}/${APP_PRODUCT_NAME}_${APP_PRODUCT_NAME}.bundle"
chmod +x "$APP_BINARY"

/usr/libexec/PlistBuddy \
  -c "Set :CFBundleShortVersionString ${RELEASE_VERSION}" \
  "${APP_PATH}/Contents/Info.plist"
/usr/libexec/PlistBuddy \
  -c "Set :CFBundleVersion ${BUILD_VERSION}" \
  "${APP_PATH}/Contents/Info.plist"

/usr/libexec/PlistBuddy \
  -c "Delete :SUAllowsInsecureUpdates" \
  "${APP_PATH}/Contents/Info.plist" \
  >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy \
  -c "Delete :SUPublicEDKey" \
  "${APP_PATH}/Contents/Info.plist" \
  >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy \
  -c "Add :SUPublicEDKey string ${SPARKLE_PUBLIC_ED_KEY}" \
  "${APP_PATH}/Contents/Info.plist"

PACKAGED_PUBLIC_ED_KEY="$(
  /usr/libexec/PlistBuddy \
    -c "Print :SUPublicEDKey" \
    "${APP_PATH}/Contents/Info.plist"
)"
[[ "$PACKAGED_PUBLIC_ED_KEY" == "$SPARKLE_PUBLIC_ED_KEY" ]] \
  || fail "The staged app does not contain the requested SUPublicEDKey."
if /usr/libexec/PlistBuddy \
  -c "Print :SUAllowsInsecureUpdates" \
  "${APP_PATH}/Contents/Info.plist" \
  >/dev/null 2>&1; then
  fail "The staged app contains SUAllowsInsecureUpdates."
fi

if ! otool -l "$APP_BINARY" | grep -Fq '@executable_path/../Frameworks'; then
  install_name_tool -add_rpath '@executable_path/../Frameworks' "$APP_BINARY"
fi

BUILT_ARCHS="$(lipo -archs "$APP_BINARY")"
printf 'Built executable architectures: %s\n' "$BUILT_ARCHS"
grep -qw "$TARGET_ARCH" <<< "$BUILT_ARCHS" \
  || fail "Executable does not contain requested architecture ${TARGET_ARCH}."
if [[ "$TARGET_ARCH" == "arm64" ]] && grep -qw "x86_64" <<< "$BUILT_ARCHS"; then
  fail "arm64 release executable unexpectedly contains x86_64."
fi
if [[ "$TARGET_ARCH" == "x86_64" ]] && grep -qw "arm64" <<< "$BUILT_ARCHS"; then
  fail "x86_64 release executable unexpectedly contains arm64."
fi

echo "==> Generating dSYM"
dsymutil "$APP_BINARY" -o "$DSYM_PATH"
[[ -d "$DSYM_PATH" ]] || fail "dsymutil did not produce ${DSYM_PATH}."
ditto -c -k --sequesterRsrc --keepParent "$DSYM_PATH" "$DSYM_ZIP_PATH"

sign_preserving_metadata() {
  local target="$1"

  codesign \
    --force \
    --timestamp \
    --options runtime \
    --preserve-metadata=identifier,entitlements \
    --sign "$CODE_SIGN_IDENTITY" \
    "$target"
}

echo "==> Signing embedded Sparkle components"
SPARKLE_FRAMEWORK="${FRAMEWORKS_DIR}/Sparkle.framework"

while IFS= read -r nested_binary; do
  [[ -n "$nested_binary" ]] || continue
  echo "Signing nested executable: ${nested_binary}"
  sign_preserving_metadata "$nested_binary"
done < <(
  find "$SPARKLE_FRAMEWORK/Versions" -type f \
    -print0 \
    | while IFS= read -r -d '' candidate; do
        if file "$candidate" | grep -Fq "Mach-O"; then
          printf '%s\n' "$candidate"
        fi
      done \
    | awk '{ path=$0; depth=gsub("/", "/", path); print depth "\t" $0 }' \
    | sort -rn \
    | cut -f2-
)

while IFS= read -r nested_bundle; do
  [[ -n "$nested_bundle" ]] || continue
  echo "Signing nested bundle: ${nested_bundle}"
  sign_preserving_metadata "$nested_bundle"
done < <(
  find "$SPARKLE_FRAMEWORK/Versions" -type d \
    \( -name "*.xpc" -o -name "*.app" -o -name "*.framework" \) \
    -print \
    | awk '{ path=$0; depth=gsub("/", "/", path); print depth "\t" $0 }' \
    | sort -rn \
    | cut -f2-
)

sign_preserving_metadata "$SPARKLE_FRAMEWORK"

echo "==> Signing main app"
codesign \
  --force \
  --timestamp \
  --options runtime \
  --sign "$CODE_SIGN_IDENTITY" \
  "$APP_PATH"

codesign --verify --deep --strict --verbose=2 "$APP_PATH"
APP_SIGNATURE_DETAILS="$(codesign -d --verbose=4 "$APP_PATH" 2>&1 || true)"
printf '%s\n' "$APP_SIGNATURE_DETAILS"
grep -q "Authority=Developer ID Application" <<< "$APP_SIGNATURE_DETAILS" \
  || fail "App is not signed with Developer ID Application."
grep -q "Timestamp=" <<< "$APP_SIGNATURE_DETAILS" \
  || fail "App signature has no secure timestamp."
grep -q "Runtime Version=" <<< "$APP_SIGNATURE_DETAILS" \
  || fail "Hardened runtime is not enabled."

APP_UUIDS="$(dwarfdump --uuid "$APP_BINARY" | awk '{print $2}' | sort -u)"
DSYM_UUIDS="$(dwarfdump --uuid "$DSYM_PATH" | awk '{print $2}' | sort -u)"
[[ -n "$APP_UUIDS" && "$APP_UUIDS" == "$DSYM_UUIDS" ]] \
  || fail "dSYM UUIDs do not match the app executable."

echo "==> Creating signed DMG"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
ditto "$APP_PATH" "${STAGING_DIR}/${APP_PRODUCT_NAME}.app"
ln -s /Applications "${STAGING_DIR}/Applications"

hdiutil create \
  -volname "$APP_DISPLAY_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

codesign \
  --force \
  --timestamp \
  --sign "$CODE_SIGN_IDENTITY" \
  "$DMG_PATH"
codesign --verify --strict --verbose=2 "$DMG_PATH"

echo "==> Notarizing DMG"
NOTARY_RESULT_PATH="${WORK_DIR}/notary-result.json"
xcrun notarytool submit \
  "$DMG_PATH" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait \
  --output-format json \
  | tee "$NOTARY_RESULT_PATH"

NOTARY_STATUS="$(
  python3 - "$NOTARY_RESULT_PATH" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    result = json.load(handle)
print(result.get("status", ""))
PY
)"
[[ "$NOTARY_STATUS" == "Accepted" ]] \
  || fail "Notarization failed with status: ${NOTARY_STATUS:-unknown}"

echo "==> Stapling and validating notarization ticket"
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
spctl \
  --assess \
  --type open \
  --context context:primary-signature \
  --verbose=2 \
  "$DMG_PATH"

echo "==> Generating Sparkle EdDSA signature"
ED_SIGNATURE="$(
  printf '%s\n' "$SPARKLE_ED_PRIVATE_KEY" \
    | "$SPARKLE_SIGN_UPDATE" --ed-key-file - -p "$DMG_PATH" \
    | tail -n 1 \
    | tr -d '[:space:]'
)"
printf '%s' "$ED_SIGNATURE" | grep -Eq '^[A-Za-z0-9+/]{86}==$' \
  || fail "sign_update did not return a valid Ed25519 signature."

echo "==> Verifying Sparkle signature against the packaged public key"
swift - "$SPARKLE_PUBLIC_ED_KEY" "$ED_SIGNATURE" "$DMG_PATH" <<'SWIFT'
import CryptoKit
import Foundation

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count == 3,
      let publicKeyData = Data(base64Encoded: arguments[0]),
      let signatureData = Data(base64Encoded: arguments[1]) else {
    fputs("Invalid Sparkle signature verification arguments.\n", stderr)
    exit(1)
}

do {
    let publicKey = try Curve25519.Signing.PublicKey(
        rawRepresentation: publicKeyData
    )
    let archive = try Data(
        contentsOf: URL(fileURLWithPath: arguments[2]),
        options: .mappedIfSafe
    )
    guard publicKey.isValidSignature(signatureData, for: archive) else {
        fputs(
            "Sparkle private key does not match SPARKLE_PUBLIC_ED_KEY.\n",
            stderr
        )
        exit(1)
    }
} catch {
    fputs("Sparkle signature verification failed: \(error)\n", stderr)
    exit(1)
}
SWIFT

ditto "$DMG_PATH" "${DIST_DIR}/${DMG_NAME}"
ditto "$DSYM_ZIP_PATH" "${DIST_DIR}/${DSYM_ZIP_NAME}"
printf '%s\n' "$ED_SIGNATURE" > "$SIGNATURE_PATH"

echo "Release artifacts:"
ls -la \
  "${DIST_DIR}/${DMG_NAME}" \
  "${DIST_DIR}/${DSYM_ZIP_NAME}" \
  "$SIGNATURE_PATH"
