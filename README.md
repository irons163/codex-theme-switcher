# Codex Theme Switcher

**English** | [繁體中文](README.zh-Hant.md) | [简体中文](README.zh-Hans.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [한국어](README.ko.md)

[![Codex Theme Switcher video demo](docs/media/codex-theme-switcher-demo.gif)](https://github.com/irons163/codex-theme-switcher/raw/refs/heads/main/docs/media/codex-theme-switcher-demo.mp4)

A native macOS menu bar app for designing, previewing, applying, and sharing themes for the Codex / ChatGPT desktop app.

Theme Switcher injects temporary styles when it launches Codex. It does not modify, replace, or re-sign the original app.

## Download

**Current stable release: 0.3.0**

[Apple Silicon DMG](https://github.com/irons163/codex-theme-switcher/releases/download/v0.3.0/CodexThemeSwitcher-0.3.0-apple-silicon.dmg)
·
[Intel DMG](https://github.com/irons163/codex-theme-switcher/releases/download/v0.3.0/CodexThemeSwitcher-0.3.0-intel.dmg)
·
[Release notes and checksums](https://github.com/irons163/codex-theme-switcher/releases/tag/v0.3.0)

Requires macOS 13 or later. Both installers are signed and notarized by Apple.

## Highlights

- Menu bar theme library, editor, live preview, and connection status.
- Colors, fonts, spacing, radius, shadows, blur, scaling, and motion.
- Light and Dark background images with Fit, Fill, focal point, filters, overlays, and glass.
- Experimental ChatGPT Voice backgrounds, orb styling, animated portraits, mouth frames, blinking, and idle motion.
- Advanced component controls, selector rules, custom variables, and raw CSS.
- Single-file `.codextheme` import and export with embedded images and fonts.
- English, Traditional Chinese, Simplified Chinese, French, Spanish, Japanese, and Korean.

## Quick Start

1. Install and open Codex Theme Switcher. Click its icon in the macOS menu bar.
2. Click **Launch and Attach Codex**. The first connection may relaunch Codex.
3. Select a built-in theme, make an editable copy, or create a new theme.
4. Adjust the design and check the Light / Dark and Home / Chat previews.
5. Save the theme, then click **Apply** to send it to Codex.
6. Use **Export** to share a `.codextheme`; use **Import** to install one from someone else.

The first connection does not automatically apply the selected theme. Later connections restore the last successfully applied theme, not unapplied draft changes.

## Screenshots

### Theme Studio

![Codex Theme Switcher theme studio showing the theme library, live preview, and editor tabs](docs/images/theme-studio.png)

### Renderer Previews

| Paper · Light / Home | Midnight · Dark / Chat |
| --- | --- |
| ![Paper Light Home preview](docs/images/paper-light-home.png) | ![Midnight Dark Chat preview](docs/images/midnight-dark-chat.png) |

Agent-generated previews are close approximations. Always verify advanced CSS and selector rules in the actual Codex app before sharing a theme.

## Customization Guide

### Background and Glass

- Choose separate Light and Dark images or reuse one image with different effects.
- Use Fit, Fill, Stretch, Fit Width, Fit Height, Original, or Tile, then adjust the focal point and zoom.
- Control image opacity and filters independently from sidebar, content, composer, cards, menus, and code-block glass.
- Keep wallpaper across the whole window or exclude the sidebar.
- Add a central content panel with its own fill, border, shadow, blur, radius, width, and padding.

### ChatGPT Voice (Experimental)

- Set a Voice background and a separate image inside the animated orb.
- Add a closed-mouth portrait and up to eight mouth frames, or import a 2×2 / 3×3 sprite sheet.
- Tune sensitivity, noise gate, mouth opening and closing speed, blinking, idle motion, pulse, and native-orb visibility.
- Mouth animation follows audio intensity; it is not phoneme-level lip sync.

Voice styling depends on ChatGPT's internal renderer and may need updates after a Codex / ChatGPT release.

## Import and Export

- Export creates one `.codextheme` containing the theme settings and embedded assets.
- Importing a theme does not apply it automatically; inspect it first, then click **Apply**.
- Image Skin supports PNG, JPEG, WebP, GIF, and AVIF.
- Limits: 16 MB per asset, 32 MB total assets, and 48 MB per `.codextheme`.

Examples: [`minimal.codextheme`](Examples/minimal.codextheme) and [`full.codextheme`](Examples/full.codextheme).

## Design with an AI Agent

Give the following prompt to an AI agent after installing the app:

```text
Please use this Agent CLI to design a Codex theme:
/Applications/CodexThemeSwitcher.app/Contents/Helpers/codex-theme

Run capabilities and schema first. Complete validate, compile, and all four previews.
Do not apply the theme without my confirmation.
```

The CLI can create, validate, compile, import, export, and render Light / Dark × Home / Chat previews. Only explicit `attach`, `apply`, or `clear` commands change Codex.

See [`docs/AGENT_API.md`](docs/AGENT_API.md) for the command reference.

## Language and Updates

- The app follows the macOS language automatically; unsupported languages fall back to English.
- Choose a language manually in **Settings → Interface Language**.
- Choose the Stable or Beta update channel in Settings.
- Updates use Sparkle and provide the correct Apple Silicon or Intel installer.

## Safety and Recovery

- Theme Switcher does not patch `app.asar` or replace Codex / ChatGPT files.
- Theme data and the connection bridge stay on the local Mac.
- Imported themes cannot run JavaScript or load remote and local file URLs.
- If custom CSS makes Codex unreadable, choose **Restore Original Codex Styles** from the menu bar app.
- Quitting Codex and reopening it normally removes the temporary injected styles.

This is an independent project and is not affiliated with or endorsed by OpenAI.

## Build from Source

Requirements: macOS 13+, Swift 6, Node.js 22+, and the Codex / ChatGPT desktop app.

```sh
swift build
swift test
npm test
scripts/package-app.sh
open dist/CodexThemeSwitcher.app
```

Developer references:

- [Agent CLI](docs/AGENT_API.md)
- [Updates, signing, notarization, and releases](docs/UPDATES.md)
