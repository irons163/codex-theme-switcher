# Kurisu Amadeus — fan-made Live2D source pack

This folder contains original fan-art source material prepared for a personal
Kurisu Amadeus-style Voice avatar. It does not contain artwork or model data
extracted from the anime, game, or the referenced YouTube demonstration.

## Included source files

- `source/kurisu-amadeus-live2d-source.psd`
  - `00_BASE__neutral`
  - `20_EYES__closed`
  - `30_MOUTH__A_open`
  - `31_MOUTH__O_round`
- `source/kurisu-amadeus-base.png`: transparent neutral reference
- `source/layers/*.png`: aligned transparent expression layers
- `source/source-manifest.json`: intended Cubism parameter mapping

The expression layers are hidden by default in the PSD. The PNG files can also
be used immediately with Theme Switcher's existing flat-image Voice mode while
the Cubism model is being rigged.

## Ready-to-import Live2D model

The `runtime/` folder contains a Cubism 5.3 export with blink and lip-sync
parameter groups. Import this file in Codex Theme Switcher:

`runtime/kurisu-amadeus.model3.json`

In the app, choose **Voice → Live2D → Select model3.json**, select the file
above, then apply the theme and open a Voice conversation.

The editable Cubism source is:

`source/kurisu-amadeus-live2d-source.cmo3`

This first prototype uses aligned full-canvas ArtMeshes for a neutral base,
closed eyes, an A mouth and an O mouth. It supports blinking, continuous
audio-driven mouth opening, and a subtle whole-character sway through
`ParamAngleZ`. More advanced head turns, body deformation and hair physics
require additional part separation and rigging in Cubism Editor.

## Rights

This is unofficial fan-made material. Confirm that your intended use complies
with the rights holder's policies and the Live2D licenses before publishing or
redistributing the finished model.
