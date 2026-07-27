#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

readonly VALID_SIGNATURE='4KjvG1GjKwXrxfqXbU1j2CYClEDdkMDp2Ii2ICV+Jgx00MDpHFLpLJ+/2tHy9Mp9bTUk5KlpCG1OWBu4nLKOCw=='
readonly ALL_LOCALIZED_LINKS=$'en=https://example.com/release-notes.en.md\nzh-Hant=https://example.com/release-notes.zh-Hant.md\nzh-Hans=https://example.com/release-notes.zh-Hans.md\nfr=https://example.com/release-notes.fr.md\nes=https://example.com/release-notes.es.md\nja=https://example.com/release-notes.ja.md\nko=https://example.com/release-notes.ko.md'

fail() {
  echo "test-generate-sparkle-appcast: $*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"
  grep -Fq "$expected" "$file" \
    || fail "Expected ${file} to contain: ${expected}"
}

run_generator() {
  local output_dir="$1"
  local localized_links="$2"
  local arm64_signature="$3"

  OUTPUT_DIR="$output_dir" \
  OUTPUT_BASENAME="appcast" \
  APP_NAME="Codex Theme Switcher" \
  REPOSITORY_SLUG="irons163/codex-theme-switcher" \
  RELEASE_TAG="v0.3.0-beta.1" \
  RELEASE_NAME='Codex Theme Switcher 0.3.0 Beta 1 & Preview' \
  RELEASE_NOTES=$'# Highlights\n\n- Signed updates\n- Seven languages' \
  LOCALIZED_RELEASE_NOTES_LINKS="$localized_links" \
  BUILD_VERSION="42" \
  PUBLISHED_AT="2026-07-27T12:34:56Z" \
  MINIMUM_SYSTEM_VERSION="13.0" \
  CHANNEL_LABEL="Beta" \
  ARM64_URL="https://example.com/CodexThemeSwitcher-0.3.0-beta.1-apple-silicon.dmg" \
  ARM64_SIZE="123456" \
  ARM64_ED_SIGNATURE="$arm64_signature" \
  X86_64_URL="https://example.com/CodexThemeSwitcher-0.3.0-beta.1-intel.dmg" \
  X86_64_SIZE="654321" \
  X86_64_ED_SIGNATURE="$VALID_SIGNATURE" \
  "$ROOT_DIR/scripts/generate-sparkle-appcast.sh"
}

VALID_OUTPUT="$TEMP_DIR/valid"
run_generator "$VALID_OUTPUT" "$ALL_LOCALIZED_LINKS" "$VALID_SIGNATURE" >/dev/null

ARM64_APPCAST="$VALID_OUTPUT/appcast-arm64.xml"
X86_64_APPCAST="$VALID_OUTPUT/appcast-x86_64.xml"
[[ -f "$ARM64_APPCAST" ]] || fail "arm64 appcast was not generated"
[[ -f "$X86_64_APPCAST" ]] || fail "x86_64 appcast was not generated"

for appcast in "$ARM64_APPCAST" "$X86_64_APPCAST"; do
  assert_contains "$appcast" 'https://github.com/irons163/codex-theme-switcher/releases'
  assert_contains "$appcast" 'sparkle:version="42"'
  assert_contains "$appcast" 'sparkle:shortVersionString="0.3.0-beta.1"'
  assert_contains "$appcast" '<sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>'
  assert_contains "$appcast" "sparkle:edSignature=\"$VALID_SIGNATURE\""
  assert_contains "$appcast" '&amp; Preview'

  if grep -Fq 'sparkle:minimumSystemVersion="' "$appcast"; then
    fail "minimumSystemVersion was emitted as an enclosure attribute."
  fi

  for language in en zh-Hant zh-Hans fr es ja ko; do
    assert_contains "$appcast" "<sparkle:releaseNotesLink xml:lang=\"$language\">"
  done

  if command -v xmllint >/dev/null 2>&1; then
    xmllint --noout "$appcast"
  fi
done

assert_contains "$ARM64_APPCAST" 'url="https://example.com/CodexThemeSwitcher-0.3.0-beta.1-apple-silicon.dmg"'
assert_contains "$ARM64_APPCAST" 'length="123456"'
assert_contains "$X86_64_APPCAST" 'url="https://example.com/CodexThemeSwitcher-0.3.0-beta.1-intel.dmg"'
assert_contains "$X86_64_APPCAST" 'length="654321"'

MISSING_LANGUAGE_LINKS="$(printf '%s\n' "$ALL_LOCALIZED_LINKS" | sed '/^ko=/d')"
if run_generator "$TEMP_DIR/missing-language" "$MISSING_LANGUAGE_LINKS" "$VALID_SIGNATURE" >/dev/null 2>&1; then
  fail "Generator accepted a manifest missing Korean release notes."
fi

DUPLICATE_LANGUAGE_LINKS="${ALL_LOCALIZED_LINKS}"$'\nko=https://example.com/duplicate-ko.md'
if run_generator "$TEMP_DIR/duplicate-language" "$DUPLICATE_LANGUAGE_LINKS" "$VALID_SIGNATURE" >/dev/null 2>&1; then
  fail "Generator accepted duplicate Korean release notes."
fi

UNKNOWN_LANGUAGE_LINKS="$(printf '%s\n' "$ALL_LOCALIZED_LINKS" | sed 's/^ko=/de=/')"
if run_generator "$TEMP_DIR/unknown-language" "$UNKNOWN_LANGUAGE_LINKS" "$VALID_SIGNATURE" >/dev/null 2>&1; then
  fail "Generator accepted an unsupported release-notes language."
fi

if run_generator "$TEMP_DIR/missing-signature" "$ALL_LOCALIZED_LINKS" "" >/dev/null 2>&1; then
  fail "Generator accepted a missing arm64 EdDSA signature."
fi

if run_generator "$TEMP_DIR/invalid-signature" "$ALL_LOCALIZED_LINKS" "not-a-signature" >/dev/null 2>&1; then
  fail "Generator accepted a malformed arm64 EdDSA signature."
fi

if grep -Eq 'SUAllowsInsecureUpdates' "$ARM64_APPCAST" "$X86_64_APPCAST"; then
  fail "Generated appcast contains insecure-update configuration."
fi

echo "Sparkle appcast generator tests passed."
