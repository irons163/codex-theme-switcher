# Secure Updates and Releases

Codex Theme Switcher uses Sparkle 2 for in-app updates. Release artifacts are
Developer ID signed, notarized by Apple, and signed again with the app's Sparkle
Ed25519 key. Unsigned update archives are not accepted.

The release implementation is split across:

- `.github/workflows/release.yml`
- `scripts/build-release-dmg.sh`
- `scripts/generate-sparkle-appcast.sh`
- `scripts/test-generate-sparkle-appcast.sh`

## Update feeds

Feeds are architecture- and channel-specific:

| Channel | Apple Silicon | Intel |
| --- | --- | --- |
| Stable | `appcast-arm64.xml` | `appcast-x86_64.xml` |
| Beta | `appcast-beta-arm64.xml` | `appcast-beta-x86_64.xml` |

The public URLs are:

```text
https://github.com/irons163/codex-theme-switcher/releases/latest/download/appcast-arm64.xml
https://github.com/irons163/codex-theme-switcher/releases/latest/download/appcast-x86_64.xml
https://github.com/irons163/codex-theme-switcher/releases/latest/download/appcast-beta-arm64.xml
https://github.com/irons163/codex-theme-switcher/releases/latest/download/appcast-beta-x86_64.xml
```

GitHub's `releases/latest` endpoint ignores prereleases. A Beta release
therefore uploads its `appcast-beta-*` files to the latest Stable release. The
Beta appcast enclosure still points to the Beta release's signed DMG.

When a new Stable release is published, its installer becomes the item in both
Stable and Beta appcasts. This lets Beta users return to the newest Stable
version naturally.

At least one Stable release must exist before publishing the first Beta.

## Sparkle Ed25519 key

Generate the key once using the `generate_keys` tool from the same Sparkle
distribution used by this project:

```bash
./bin/generate_keys --account codex-theme-switcher
./bin/generate_keys --account codex-theme-switcher -p
./bin/generate_keys --account codex-theme-switcher -x sparkle-private-key
```

The first command prints the `SUPublicEDKey` entry. The second prints only the
public key. The third exports the private key as a base64 string.

Store the exact contents of `sparkle-private-key` in the
`SPARKLE_ED_PRIVATE_KEY` GitHub Actions secret. Store the public key printed by
the second command in the `SPARKLE_PUBLIC_ED_KEY` secret. Then securely remove
the temporary private-key file.

The private key is a long-lived release credential:

- Never commit it.
- Never print it in CI.
- Keep an offline encrypted backup.
- Do not rotate `SPARKLE_PUBLIC_ED_KEY` without following Sparkle's supported
  key-rotation process.

The workflow validates `SPARKLE_PUBLIC_ED_KEY` as a base64-encoded 32-byte
Ed25519 public key and injects it as `SUPublicEDKey` into the staged app. The
source `Packaging/Info.plist` therefore does not contain a production key, but
`SUPublicEDKey` must exist in every distributed build.

`SUAllowsInsecureUpdates` is prohibited in distributed builds. The release
script removes it from the staged Info.plist and fails if it is still present.
Every enclosure must contain a non-empty `sparkle:edSignature`.

## Required GitHub Actions secrets

Configure these repository secrets:

- `APPLE_CERTIFICATE_P12_BASE64`
- `APPLE_CERTIFICATE_PASSWORD`
- `KEYCHAIN_PASSWORD`
- `APPLE_TEAM_ID`
- `APPLE_API_KEY_ID`
- `APPLE_API_ISSUER_ID`
- `APPLE_API_PRIVATE_KEY_BASE64`
- `SPARKLE_ED_PRIVATE_KEY`
- `SPARKLE_PUBLIC_ED_KEY`

`APPLE_CERTIFICATE_P12_BASE64` must contain a Developer ID Application
certificate and its private key. `APPLE_API_PRIVATE_KEY_BASE64` is the
base64-encoded App Store Connect API key used by `notarytool`.

## Version requirements

Before creating a GitHub Release, update `Packaging/Info.plist`:

- `CFBundleShortVersionString` must exactly match the Git tag after removing a
  leading `v`.
- `CFBundleVersion` must be an unsigned integer and must increase for every
  Stable and Beta release.

Examples:

| Git tag | Channel | Short version | Build |
| --- | --- | --- | --- |
| `v0.3.0-beta.1` | Beta | `0.3.0-beta.1` | `11` |
| `v0.3.0-beta.2` | Beta | `0.3.0-beta.2` | `12` |
| `v0.3.0` | Stable | `0.3.0` | `13` |

Never reuse a build number. Sparkle uses `CFBundleVersion` /
`sparkle:version` as the authoritative update ordering value.

Stable versions must not contain a prerelease suffix. Beta versions must
contain one, such as `-beta.1` or `-rc.1`.

## Localized release notes

Every release must include all seven files under an exact version directory:

```text
docs/release-notes/v0.3.0/
  release-notes.en.md
  release-notes.zh-Hant.md
  release-notes.zh-Hans.md
  release-notes.fr.md
  release-notes.es.md
  release-notes.ja.md
  release-notes.ko.md
```

For a Beta tag, include the suffix in the directory:

```text
docs/release-notes/v0.3.0-beta.1/
```

Empty files, fallback directories, partial translations, unknown language
codes, and duplicate language entries are rejected. The workflow uploads these
files as GitHub Release assets and emits seven `sparkle:releaseNotesLink`
elements in each appcast.

## Publishing a release

1. Bump both version values in `Packaging/Info.plist`.
2. Add all seven localized release-note files.
3. Commit and push the release preparation.
4. Create the matching Git tag.
5. Create and publish a GitHub Release from that tag.
6. Mark it as a prerelease for the Beta channel; leave prerelease disabled for
   Stable.
7. Wait for the `Release` workflow to complete.

The workflow:

1. Verifies the tag, channel, bundle versions, public Sparkle key secret, and
   all localized release notes.
2. Builds separate arm64 and x86_64 SwiftPM executables.
3. Embeds and signs Sparkle's framework and nested helpers.
4. Signs the app and DMG with Developer ID and hardened runtime.
5. Generates matching dSYM archives.
6. Notarizes and staples both DMGs.
7. Signs the final, stapled DMG bytes with Sparkle Ed25519.
8. Verifies that signature against `SPARKLE_PUBLIC_ED_KEY`, preventing a
   mismatched public/private key pair from shipping.
9. Uploads DMGs, dSYMs, and localized notes to the GitHub Release.
10. Generates appcasts with mandatory EdDSA signatures and publishes the
   appropriate Stable or Beta feeds.

`workflow_dispatch` can rerun an already published release by providing its tag
and channel. The selected channel must match the GitHub Release's prerelease
state.

## Local validation

The appcast generator test does not need signing credentials:

```bash
scripts/test-generate-sparkle-appcast.sh
```

It verifies:

- arm64 and x86_64 output
- the fixed repository slug
- version, build, and minimum-system-version metadata
- all seven localized release-note links
- XML escaping and XML validity
- mandatory correctly shaped Ed25519 signatures
- rejection of incomplete language manifests
- rejection of missing or malformed signatures

The full DMG script requires a configured Developer ID identity, a stored
`notarytool` profile, the Sparkle `sign_update` tool, and the private Sparkle
key:

```bash
TARGET_ARCH=arm64 \
ARCH_LABEL=apple-silicon \
RELEASE_VERSION=0.3.0 \
BUILD_VERSION=13 \
CODE_SIGN_IDENTITY="Developer ID Application: Example (TEAMID)" \
NOTARY_PROFILE=CODEX_THEME_SWITCHER_NOTARY \
SPARKLE_SIGN_UPDATE=/path/to/Sparkle/bin/sign_update \
SPARKLE_ED_PRIVATE_KEY='base64-private-key' \
SPARKLE_PUBLIC_ED_KEY='base64-public-key' \
scripts/build-release-dmg.sh
```
