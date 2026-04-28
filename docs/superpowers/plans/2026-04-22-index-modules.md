# Index Page Module Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the oversized `Index.ets` page shell into separate auth, record, AI, and profile modules without breaking the current HarmonyOS app behavior.

**Architecture:** Keep business state and mutation methods in `Index.ets` for now, and extract page-level UI composition into focused ArkTS modules. Start with low-risk page shells and shared builder handoff so the app keeps compiling while the file size and responsibilities shrink.

**Tech Stack:** ArkTS, ArkUI declarative UI, HarmonyOS `Tabs`, local state persistence, backend-backed user state sync.

---

### Task 1: Create module file boundaries

**Files:**
- Create: `entry/src/main/ets/pages/modules/AuthModule.ets`
- Create: `entry/src/main/ets/pages/modules/RecordModule.ets`
- Create: `entry/src/main/ets/pages/modules/AiModule.ets`
- Create: `entry/src/main/ets/pages/modules/ProfileModule.ets`

- [ ] Add exported ArkTS components for the four modules.
- [ ] Keep each file responsible only for one top-level page shell.
- [ ] Prefer `@BuilderParam` handoff for large existing builder sections to reduce risk during the first extraction pass.

### Task 2: Move auth and onboarding shells out of `Index.ets`

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/modules/AuthModule.ets`

- [ ] Extract login/register page layout into `AuthModule.ets`.
- [ ] Extract onboarding page layout into `AuthModule.ets`.
- [ ] Keep form state and submit methods in `Index.ets`, passed into the module through links and callbacks.

### Task 3: Move record, AI, and profile page shells out of `Index.ets`

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/modules/RecordModule.ets`
- Modify: `entry/src/main/ets/pages/modules/AiModule.ets`
- Modify: `entry/src/main/ets/pages/modules/ProfileModule.ets`

- [ ] Extract the record page container into `RecordModule.ets`.
- [ ] Extract the AI page container and message list into `AiModule.ets`.
- [ ] Extract the profile page container into `ProfileModule.ets`.
- [ ] Update `Index.ets` imports and root `build()` to render the new modules.

### Task 4: Clean up and verify

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`

- [ ] Remove page-shell duplication left behind in `Index.ets`.
- [ ] Re-scan for broken builder references and missing imports.
- [ ] Run available static verification and summarize any remaining build risk for DevEco compilation.
