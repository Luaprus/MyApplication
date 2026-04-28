# Health Icon Refresh Design

## Goal

Refresh the HarmonyOS health app icon set with a light skeuomorphic illustration style selected by the user.

## Selected Style

Use "C. light skeuomorphic illustration": rounded sticker-like icons, soft volume, mint green as the primary color, with pale blue, cream, and small coral accents. Icons must avoid text so they remain usable at launcher and tab sizes.

## Replacement Scope

- Replace app launcher layered image assets in both `entry` and `AppScope`.
- Replace `startIcon.png`.
- Replace bottom tab icons for Record, AI, and Profile, using generated raster assets.
- Replace empty/error state assets: `noImage.png` and `ic_failure.svg`.

## Implementation Notes

Generate one consistent sprite sheet with the image generation model, then crop and resize individual icons with local image tooling. Keep original resource names where possible so most ArkTS code does not need to change. Add new profile tab image resources and update `Index.ets` so the Profile tab uses them instead of hand-drawn shapes.

## Verification

Run `build-app.bat` after replacing resources and references. The expected result is a successful unsigned HAP build.
