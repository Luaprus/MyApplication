# Health Icon Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the app's visible template icons with generated light skeuomorphic health icons.

**Architecture:** Generate one cohesive icon sprite sheet, crop individual transparent PNGs, and keep existing HarmonyOS resource names where possible. Add only the missing profile tab image resources and keep ArkTS changes tightly scoped to tab rendering.

**Tech Stack:** HarmonyOS ArkTS resources, PNG/SVG media assets, image generation model, local Pillow image processing, Hvigor build.

---

### Task 1: Generate And Extract Icon Assets

**Files:**
- Modify: `entry/src/main/resources/base/media/background.png`
- Modify: `entry/src/main/resources/base/media/foreground.png`
- Modify: `entry/src/main/resources/base/media/startIcon.png`
- Modify: `entry/src/main/resources/base/media/tab_home_active.png`
- Modify: `entry/src/main/resources/base/media/tab_home_inactive.png`
- Modify: `entry/src/main/resources/base/media/tab_ai_active.png`
- Modify: `entry/src/main/resources/base/media/tab_ai_inactive.png`
- Create: `entry/src/main/resources/base/media/tab_profile_active.png`
- Create: `entry/src/main/resources/base/media/tab_profile_inactive.png`
- Modify: `entry/src/main/resources/base/media/noImage.png`
- Modify: `entry/src/main/resources/base/media/ic_failure.png`
- Modify: `AppScope/resources/base/media/background.png`
- Modify: `AppScope/resources/base/media/foreground.png`

- [ ] Generate a single sprite sheet containing app, record, AI, profile, empty, failure, water, and exercise icons.
- [ ] Locate the generated file under the image generation output directory.
- [ ] Crop each grid cell and remove the chroma-key background.
- [ ] Resize each icon to its target project dimensions.
- [ ] Write all final PNGs to the HarmonyOS resource folders.

### Task 2: Update Tab Resource References

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`

- [ ] Change record and AI tab resources from SVG names to PNG names.
- [ ] Replace the hand-drawn profile tab icon with `tab_profile_active` and `tab_profile_inactive`.
- [ ] Leave tab text, sizing, and colors unchanged.

### Task 3: Verify Build

**Files:**
- Read: `build-app.bat`

- [ ] Run `.\build-app.bat`.
- [ ] Confirm Hvigor reports `BUILD SUCCESSFUL`.
- [ ] Report any signing warning separately from build success.
