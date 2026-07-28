# Secure Updates and Releases

Codex Theme Switcher uses Sparkle 2 for in-app updates. Release artifacts are
Developer ID signed, notarized by Apple, and signed again with the app's Sparkle
Ed25519 key. Unsigned update archives are not accepted.

Continuous integration is defined in `.github/workflows/ci.yml`. The release
implementation is split across:

- `.github/workflows/release.yml`
- `scripts/build-release-dmg.sh`
- `scripts/generate-sparkle-appcast.sh`
- `scripts/test-generate-sparkle-appcast.sh`

## Continuous integration

The CI workflow runs for pull requests, pushes to `main`, and manual
`workflow_dispatch` runs. Its macOS matrix covers native Apple Silicon
(`arm64`) and native Intel (`x86_64`) runners instead of relying on emulation for
architecture validation.

Both architecture lanes perform:

- Swift build and test validation
- Node runtime tests and JavaScript syntax checks
- an ad-hoc application packaging smoke test, including the packaged Agent CLI

The Apple Silicon lane also runs the Sparkle appcast generator test once for
the matrix.

CI does not publish releases and must not receive Apple notarization, Developer
ID, or Sparkle private-key secrets.

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

Configure this repository-level secret because the read-only `prepare` job
validates it before entering the release Environment:

- `SPARKLE_PUBLIC_ED_KEY`

Configure the remaining credentials as secrets in the
`release-production` Environment:

- `APPLE_CERTIFICATE_P12_BASE64`
- `APPLE_CERTIFICATE_PASSWORD`
- `KEYCHAIN_PASSWORD`
- `APPLE_TEAM_ID`
- `APPLE_API_KEY_ID`
- `APPLE_API_ISSUER_ID`
- `APPLE_API_PRIVATE_KEY_BASE64`
- `SPARKLE_ED_PRIVATE_KEY`

`APPLE_CERTIFICATE_P12_BASE64` must contain a Developer ID Application
certificate and its private key. `APPLE_API_PRIVATE_KEY_BASE64` is the
base64-encoded App Store Connect API key used by `notarytool`.

All nine values must currently be configured manually before the first release.
GitHub never returns a secret's value after it has been stored, so neither the
GitHub UI, API, nor `gh` can copy the secret values from the AIAgentPool
repository. Obtain each value from its original secure source or rotate and
recreate it; do not copy values through workflow logs.

## Repository rules and release environment

The repository files do not create or enforce GitHub rulesets, protected tags,
or Environment review policies. Configure these settings manually before
enabling releases:

- Protect `main`: require pull requests, successful CI checks, and Code Owner
  review; block force pushes and deletion.
- Protect `v*` tags: restrict tag creation to release maintainers and block tag
  updates, force moves, and deletion.
- Configure the `release-production` Environment used by the release workflow:
  require review by `@irons163`, restrict deployments to protected `v*` tags,
  and scope release credentials as tightly as the workflow permits. When
  manually rerunning a release, dispatch the workflow with its Git ref set to
  the same release tag so the Environment tag policy still matches.

The repository's `.github/CODEOWNERS` assigns release workflows, packaging,
release scripts, dependency manifests, and localized release notes to
`@irons163`. Code Owner review is only mandatory when the `main` ruleset is
configured to require it.

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
`sparkle:version` as the authoritative update ordering value. The release
workflow reads previously published Stable and Beta appcasts and rejects a
lower build or a build number already assigned to another release. Re-running
the same tag and version remains idempotent.

Stable versions must not contain a prerelease suffix. Beta versions must
contain one, such as `-beta.1` or `-rc.1`.

The first public release must be Stable because Beta appcasts need an existing
Stable release as their host. Stable `v0.2.8` is the initial host release. The
current source version is `v0.3.0-beta.1` with build `15`; publish it as a
GitHub prerelease on the Beta channel. Its seven release-note files are under:

```text
docs/release-notes/v0.3.0-beta.1/
  release-notes.en.md
  release-notes.zh-Hant.md
  release-notes.zh-Hans.md
  release-notes.fr.md
  release-notes.es.md
  release-notes.ja.md
  release-notes.ko.md
```

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
2. Rejects build numbers that do not advance existing Stable and Beta feeds.
3. Resolves the release tag once and pins every job to the same immutable source
   commit.
4. Builds separate arm64 and x86_64 SwiftPM executables.
5. Embeds and signs Sparkle's framework and nested helpers.
6. Signs the app and DMG with Developer ID and hardened runtime.
7. Generates matching dSYM archives.
8. Notarizes and staples both DMGs.
9. Signs the final, stapled DMG bytes with Sparkle Ed25519.
10. Verifies that signature against `SPARKLE_PUBLIC_ED_KEY`, preventing a
   mismatched public/private key pair from shipping.
11. Uploads DMGs, dSYMs, a `SHA256SUMS` manifest, and localized notes to the
    GitHub Release.
12. Generates appcasts with mandatory EdDSA signatures and publishes the
    appropriate Stable or Beta feeds.

`workflow_dispatch` can rerun an already published release by providing its tag
and channel. The selected channel must match the GitHub Release's prerelease
state.

Release publication is serialized with `cancel-in-progress: false` so Stable
and Beta feed writes cannot run concurrently. `queue: max` retains up to 100
pending releases instead of replacing an older pending run. Permissions are
assigned per job: validation and build jobs are read-only, while only the
publish job receives `contents: write`. Every checkout disables persisted Git
credentials, and official GitHub actions are pinned to full commit SHAs rather
than mutable version tags.

The workflow uses Sparkle `2.9.1` consistently with `Package.resolved`. Before
extracting the downloaded `Sparkle-2.9.1.tar.xz`, it verifies the archive
against the repository-pinned SHA-256 value. A Sparkle upgrade must update the
version, dependency lock, download URL, and reviewed SHA-256 together.

## Local validation

Run the same unprivileged checks used by CI:

```bash
bash -n scripts/*.sh
swift build
swift test
npm test
npm run check
scripts/test-generate-sparkle-appcast.sh
scripts/test-validate-release-build-order.sh
CONFIGURATION=release ARCHS="$(uname -m)" scripts/package-app.sh
test -x dist/CodexThemeSwitcher.app/Contents/Helpers/codex-theme
dist/CodexThemeSwitcher.app/Contents/Helpers/codex-theme capabilities
codesign --verify --deep --strict dist/CodexThemeSwitcher.app
```

The appcast generator test verifies:

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
