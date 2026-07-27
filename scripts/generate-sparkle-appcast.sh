#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${OUTPUT_DIR:-dist}"
OUTPUT_BASENAME="${OUTPUT_BASENAME:-appcast}"
APP_NAME="${APP_NAME:-Codex Theme Switcher}"
REPOSITORY_SLUG="${REPOSITORY_SLUG:-irons163/codex-theme-switcher}"
RELEASE_TAG="${RELEASE_TAG:-}"
RELEASE_NAME="${RELEASE_NAME:-}"
RELEASE_NOTES="${RELEASE_NOTES:-}"
LOCALIZED_RELEASE_NOTES_LINKS="${LOCALIZED_RELEASE_NOTES_LINKS:-}"
BUILD_VERSION="${BUILD_VERSION:-}"
PUBLISHED_AT="${PUBLISHED_AT:-}"
MINIMUM_SYSTEM_VERSION="${MINIMUM_SYSTEM_VERSION:-13.0}"
CHANNEL_LABEL="${CHANNEL_LABEL:-Stable}"
ARM64_URL="${ARM64_URL:-}"
ARM64_SIZE="${ARM64_SIZE:-}"
ARM64_ED_SIGNATURE="${ARM64_ED_SIGNATURE:-}"
X86_64_URL="${X86_64_URL:-}"
X86_64_SIZE="${X86_64_SIZE:-}"
X86_64_ED_SIGNATURE="${X86_64_ED_SIGNATURE:-}"

readonly EXPECTED_REPOSITORY_SLUG="irons163/codex-theme-switcher"
readonly REQUIRED_LANGUAGES=(
  "en"
  "zh-Hant"
  "zh-Hans"
  "fr"
  "es"
  "ja"
  "ko"
)

fail() {
  echo "generate-sparkle-appcast: $*" >&2
  exit 1
}

require_nonempty() {
  local name="$1"
  local value="$2"
  [[ -n "${value//[[:space:]]/}" ]] || fail "${name} is required."
}

require_unsigned_integer() {
  local name="$1"
  local value="$2"
  [[ "$value" =~ ^[0-9]+$ ]] || fail "${name} must be an unsigned integer."
}

validate_https_url() {
  local name="$1"
  local value="$2"
  [[ "$value" == https://* ]] || fail "${name} must use HTTPS."
}

validate_ed_signature() {
  local name="$1"
  local value="$2"
  local compact

  compact="$(printf '%s' "$value" | tr -d '[:space:]')"
  require_nonempty "$name" "$compact"
  printf '%s' "$compact" | grep -Eq '^[A-Za-z0-9+/]{86}==$' \
    || fail "${name} must be a base64-encoded 64-byte Ed25519 signature."
}

xml_escape() {
  printf '%s' "$1" | sed \
    -e 's/&/\&amp;/g' \
    -e 's/</\&lt;/g' \
    -e 's/>/\&gt;/g' \
    -e 's/"/\&quot;/g'
}

sanitize_release_notes() {
  local raw="$1"
  local cleaned

  cleaned="$(printf '%s' "$raw" \
    | tr -d '\r' \
    | sed -E 's/\[([^][]+)\]\(([^()]*)\)/\1/g' \
    | sed -E 's/^#{1,6}[[:space:]]*//g' \
    | sed -E 's/`([^`]*)`/\1/g' \
    | sed -E 's/[*_~]{1,3}//g' \
    | sed -E 's/^[[:space:]]*[-*][[:space:]]+/- /g' \
    | sed -E 's/[[:space:]]+$//g')"

  if [[ -z "${cleaned//[[:space:]]/}" ]]; then
    cleaned="Bug fixes and improvements."
  fi

  printf '%s' "$cleaned"
}

localized_notes_url() {
  local requested_language="$1"
  local line
  local language
  local url
  local matched_url=""
  local match_count=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -n "${line//[[:space:]]/}" ]] || continue
    [[ "$line" == *"="* ]] || fail "Invalid localized release-notes entry: ${line}"

    language="${line%%=*}"
    url="${line#*=}"
    if [[ "$language" == "$requested_language" ]]; then
      matched_url="$url"
      match_count=$((match_count + 1))
    fi
  done <<< "$LOCALIZED_RELEASE_NOTES_LINKS"

  [[ "$match_count" -eq 1 ]] \
    || fail "Expected exactly one localized release-notes URL for ${requested_language}; found ${match_count}."
  validate_https_url "release-notes URL for ${requested_language}" "$matched_url"
  printf '%s' "$matched_url"
}

validate_localized_notes_manifest() {
  local line
  local language
  local url
  local known
  local entry_count=0
  local required_language

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -n "${line//[[:space:]]/}" ]] || continue
    [[ "$line" == *"="* ]] || fail "Invalid localized release-notes entry: ${line}"
    language="${line%%=*}"
    url="${line#*=}"
    known=false

    for required_language in "${REQUIRED_LANGUAGES[@]}"; do
      if [[ "$language" == "$required_language" ]]; then
        known=true
        break
      fi
    done

    [[ "$known" == true ]] || fail "Unsupported release-notes language: ${language}"
    validate_https_url "release-notes URL for ${language}" "$url"
    entry_count=$((entry_count + 1))
  done <<< "$LOCALIZED_RELEASE_NOTES_LINKS"

  [[ "$entry_count" -eq "${#REQUIRED_LANGUAGES[@]}" ]] \
    || fail "Localized release-notes manifest must contain exactly ${#REQUIRED_LANGUAGES[@]} entries."

  for required_language in "${REQUIRED_LANGUAGES[@]}"; do
    localized_notes_url "$required_language" >/dev/null
  done
}

portable_pub_date() {
  local raw="$1"

  if [[ -n "$raw" && "$raw" != "null" ]]; then
    if date -u -d "$raw" "+%a, %d %b %Y %H:%M:%S +0000" 2>/dev/null; then
      return
    fi
    if date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$raw" "+%a, %d %b %Y %H:%M:%S +0000" 2>/dev/null; then
      return
    fi
    if date -u -j -f "%Y-%m-%dT%H:%M:%S.%NZ" "$raw" "+%a, %d %b %Y %H:%M:%S +0000" 2>/dev/null; then
      return
    fi
  fi

  LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S +0000"
}

require_nonempty "RELEASE_TAG" "$RELEASE_TAG"
require_nonempty "BUILD_VERSION" "$BUILD_VERSION"
require_nonempty "ARM64_URL" "$ARM64_URL"
require_nonempty "X86_64_URL" "$X86_64_URL"
require_nonempty "ARM64_SIZE" "$ARM64_SIZE"
require_nonempty "X86_64_SIZE" "$X86_64_SIZE"
require_nonempty "MINIMUM_SYSTEM_VERSION" "$MINIMUM_SYSTEM_VERSION"
[[ "$REPOSITORY_SLUG" == "$EXPECTED_REPOSITORY_SLUG" ]] \
  || fail "REPOSITORY_SLUG must be ${EXPECTED_REPOSITORY_SLUG}."
require_unsigned_integer "BUILD_VERSION" "$BUILD_VERSION"
require_unsigned_integer "ARM64_SIZE" "$ARM64_SIZE"
require_unsigned_integer "X86_64_SIZE" "$X86_64_SIZE"
validate_https_url "ARM64_URL" "$ARM64_URL"
validate_https_url "X86_64_URL" "$X86_64_URL"
validate_ed_signature "ARM64_ED_SIGNATURE" "$ARM64_ED_SIGNATURE"
validate_ed_signature "X86_64_ED_SIGNATURE" "$X86_64_ED_SIGNATURE"
validate_localized_notes_manifest

SHORT_VERSION="${RELEASE_TAG#refs/tags/}"
SHORT_VERSION="${SHORT_VERSION#v}"
SHORT_VERSION="${SHORT_VERSION#V}"
require_nonempty "short release version" "$SHORT_VERSION"

if [[ -z "${RELEASE_NAME//[[:space:]]/}" ]]; then
  RELEASE_NAME="${APP_NAME} ${SHORT_VERSION}"
fi

PUB_DATE="$(portable_pub_date "$PUBLISHED_AT")"
DESCRIPTION="$(sanitize_release_notes "$RELEASE_NOTES")"

localized_release_notes_xml() {
  local language
  local url

  for language in "${REQUIRED_LANGUAGES[@]}"; do
    url="$(localized_notes_url "$language")"
    printf '      <sparkle:releaseNotesLink xml:lang="%s">%s</sparkle:releaseNotesLink>\n' \
      "$(xml_escape "$language")" \
      "$(xml_escape "$url")"
  done
}

generate_feed() {
  local architecture="$1"
  local download_url="$2"
  local download_size="$3"
  local ed_signature="$4"
  local output_path="$5"

  {
    printf '%s\n' '<?xml version="1.0" encoding="utf-8"?>'
    printf '%s\n' '<rss version="2.0"'
    printf '%s\n' '     xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"'
    printf '%s\n' '     xmlns:dc="http://purl.org/dc/elements/1.1/">'
    printf '%s\n' '  <channel>'
    printf '    <title>%s Updates (%s, %s)</title>\n' \
      "$(xml_escape "$APP_NAME")" \
      "$(xml_escape "$CHANNEL_LABEL")" \
      "$(xml_escape "$architecture")"
    printf '    <link>https://github.com/%s/releases</link>\n' "$(xml_escape "$REPOSITORY_SLUG")"
    printf '    <description>%s update feed for %s</description>\n' \
      "$(xml_escape "$CHANNEL_LABEL")" \
      "$(xml_escape "$architecture")"
    printf '%s\n' '    <language>en</language>'
    printf '%s\n' '    <item>'
    printf '      <title>%s</title>\n' "$(xml_escape "$RELEASE_NAME")"
    printf '      <pubDate>%s</pubDate>\n' "$(xml_escape "$PUB_DATE")"
    printf '      <description sparkle:format="plain-text">%s</description>\n' "$(xml_escape "$DESCRIPTION")"
    localized_release_notes_xml
    printf '      <sparkle:minimumSystemVersion>%s</sparkle:minimumSystemVersion>\n' \
      "$(xml_escape "$MINIMUM_SYSTEM_VERSION")"
    printf '%s\n' '      <enclosure'
    printf '        url="%s"\n' "$(xml_escape "$download_url")"
    printf '        sparkle:version="%s"\n' "$(xml_escape "$BUILD_VERSION")"
    printf '        sparkle:shortVersionString="%s"\n' "$(xml_escape "$SHORT_VERSION")"
    printf '        sparkle:edSignature="%s"\n' "$(xml_escape "$(printf '%s' "$ed_signature" | tr -d '[:space:]')")"
    printf '%s\n' '        type="application/x-apple-diskimage"'
    printf '        length="%s" />\n' "$(xml_escape "$download_size")"
    printf '%s\n' '    </item>'
    printf '%s\n' '  </channel>'
    printf '%s\n' '</rss>'
  } > "$output_path"
}

mkdir -p "$OUTPUT_DIR"
generate_feed \
  "arm64" \
  "$ARM64_URL" \
  "$ARM64_SIZE" \
  "$ARM64_ED_SIGNATURE" \
  "${OUTPUT_DIR}/${OUTPUT_BASENAME}-arm64.xml"
generate_feed \
  "x86_64" \
  "$X86_64_URL" \
  "$X86_64_SIZE" \
  "$X86_64_ED_SIGNATURE" \
  "${OUTPUT_DIR}/${OUTPUT_BASENAME}-x86_64.xml"

echo "Generated signed Sparkle appcasts:"
ls -la \
  "${OUTPUT_DIR}/${OUTPUT_BASENAME}-arm64.xml" \
  "${OUTPUT_DIR}/${OUTPUT_BASENAME}-x86_64.xml"
