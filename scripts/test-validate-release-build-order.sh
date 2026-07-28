#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

fail() {
  echo "test-validate-release-build-order: $*" >&2
  exit 1
}

write_appcast() {
  local path="$1"
  local build="$2"
  local version="$3"
  local tag="$4"

  sed \
    -e "s|__BUILD__|${build}|g" \
    -e "s|__VERSION__|${version}|g" \
    -e "s|__TAG__|${tag}|g" \
    > "$path" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0"
     xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <item>
      <enclosure
        url="https://github.com/irons163/codex-theme-switcher/releases/download/__TAG__/CodexThemeSwitcher.dmg"
        sparkle:version="__BUILD__"
        sparkle:shortVersionString="__VERSION__" />
    </item>
  </channel>
</rss>
XML
}

VALIDATOR=(python3 "$ROOT_DIR/scripts/validate-release-build-order.py")

EMPTY_DIR="$TEMP_DIR/empty"
mkdir -p "$EMPTY_DIR"
"${VALIDATOR[@]}" \
  --appcast-directory "$EMPTY_DIR" \
  --current-build 10 \
  --current-version 0.2.8 \
  --current-tag v0.2.8 \
  >/dev/null

FEED_DIR="$TEMP_DIR/feeds"
mkdir -p "$FEED_DIR"
write_appcast "$FEED_DIR/appcast-arm64.xml" 10 0.2.8 v0.2.8
write_appcast "$FEED_DIR/appcast-beta-arm64.xml" 11 0.3.0-beta.1 v0.3.0-beta.1

"${VALIDATOR[@]}" \
  --appcast-directory "$FEED_DIR" \
  --current-build 12 \
  --current-version 0.3.0-beta.2 \
  --current-tag v0.3.0-beta.2 \
  >/dev/null

"${VALIDATOR[@]}" \
  --appcast-directory "$FEED_DIR" \
  --current-build 11 \
  --current-version 0.3.0-beta.1 \
  --current-tag v0.3.0-beta.1 \
  >/dev/null

if "${VALIDATOR[@]}" \
  --appcast-directory "$FEED_DIR" \
  --current-build 10 \
  --current-version 0.3.0 \
  --current-tag v0.3.0 \
  >/dev/null 2>&1; then
  fail "validator accepted a build below the existing maximum"
fi

if "${VALIDATOR[@]}" \
  --appcast-directory "$FEED_DIR" \
  --current-build 11 \
  --current-version 0.3.0-beta.2 \
  --current-tag v0.3.0-beta.2 \
  >/dev/null 2>&1; then
  fail "validator accepted a reused build number for another release"
fi

printf '%s\n' "Release build-order validation tests passed."
