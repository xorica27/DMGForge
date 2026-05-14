# Preview and Export Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a real preview renderer and DMG export engine so agents can generate, validate, preview, and package `.dmgproject` files from the CLI while the GUI can reuse the same preview path.

**Architecture:** `DMGForgeCore` owns rendering and packaging. The executable target only parses CLI arguments and presents the SwiftUI shell. Preview rendering produces deterministic PNG files from the project background contract. DMG export stages the app, Applications symlink, background image, Finder layout, and compressed final image.

**Tech Stack:** Swift 6, SwiftPM, XCTest/Testing, Foundation, AppKit, hdiutil, Finder AppleScript.

---

### Task 1: Preview Renderer

**Files:**
- Create: `Sources/DMGForgeCore/PreviewRenderer.swift`
- Create: `Tests/DMGForgeTests/PreviewRendererTests.swift`

- [x] Test that generated background projects write a valid PNG.
- [x] Test that custom image projects render by copying the provided image.
- [x] Implement `PreviewRenderer.render(project:to:)`.
- [x] Run `swift test`.

### Task 2: DMG Builder

**Files:**
- Create: `Sources/DMGForgeCore/DMGBuilder.swift`
- Create: `Tests/DMGForgeTests/DMGBuilderTests.swift`

- [x] Test that AppleScript generation includes window bounds, background image, icon positions, and app name.
- [x] Test that staging copies the app, creates the Applications symlink, and writes the background PNG.
- [x] Implement staging and export orchestration.
- [x] Run `swift test`.

### Task 3: CLI Wiring

**Files:**
- Modify: `Sources/DMGForge/CLI.swift`
- Modify: `Tests/DMGForgeTests/CLITests.swift`
- Modify: `README.md`

- [x] Test `preview <project> --output <png>` writes the preview image.
- [x] Test `export <project> --dry-run` validates and prints the destination without creating a DMG.
- [x] Implement `preview`, `export`, and a useful `open` command.
- [x] Document the commands.
- [x] Run `swift test`.

### Task 4: GUI Preview Shell

**Files:**
- Modify: `Sources/DMGForge/ContentView.swift`

- [x] Show the default generated preview in the GUI shell.
- [x] Keep editing controls minimal until the next slice.
- [x] Run `swift test` and `swift build`.

### Task 5: Smoke Verification

**Files:**
- No new files.

- [x] Create a temporary fake `.app`.
- [x] Run `dmgforge init`.
- [x] Run `dmgforge preview`.
- [x] Run `dmgforge export`.
- [x] Verify the produced DMG with `hdiutil verify`.
- [x] Commit the finished slice.
