# DMGForge Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a git-ready SwiftPM macOS project for DMGForge with a shared project-file core, CLI bootstrap, GUI shell, docs, and tests.

**Architecture:** A single SwiftPM package exposes `DMGForgeCore` for project parsing and validation, plus a `DMGForge` executable that chooses CLI mode when arguments are present and GUI mode otherwise. The GUI is intentionally thin in the bootstrap; the project-file and CLI contract are the stable v1 foundation.

**Tech Stack:** Swift 6, SwiftPM, XCTest, SwiftUI/AppKit, Foundation.

---

### Task 1: Repository Skeleton

**Files:**
- Create: `Package.swift`
- Create: `.gitignore`
- Create: `README.md`
- Create: `Sources/DMGForge/main.swift`
- Create: `Sources/DMGForge/DMGForgeApp.swift`
- Create: `Sources/DMGForge/ContentView.swift`

- [ ] Add the SwiftPM package with one executable, one core library, and one test target.
- [ ] Add a focused README explaining human and agent workflows.
- [ ] Add a minimal GUI shell that starts without CLI arguments.
- [ ] Run `swift test` to confirm the package compiles.

### Task 2: Project File Core

**Files:**
- Create: `Sources/DMGForgeCore/DMGProject.swift`
- Create: `Sources/DMGForgeCore/ProjectFactory.swift`
- Create: `Sources/DMGForgeCore/ProjectValidator.swift`
- Create: `Tests/DMGForgeTests/DMGProjectTests.swift`

- [ ] Write failing tests for default project generation, JSON roundtrip, valid project validation, and missing app-path validation.
- [ ] Implement the minimal core types and validation.
- [ ] Run `swift test` and verify all tests pass.

### Task 3: CLI Bootstrap

**Files:**
- Create: `Sources/DMGForge/CLI.swift`
- Create: `Tests/DMGForgeTests/CLITests.swift`

- [ ] Write failing tests for `init`, `validate`, and unknown command parsing.
- [ ] Implement CLI parsing and command execution for `init` and `validate`.
- [ ] Wire placeholder output for `preview`, `export`, and `open`.
- [ ] Run `swift test` and direct CLI smoke tests.

### Task 4: Git Ready Finish

**Files:**
- Modify: `README.md`
- Modify: all created files as needed.

- [ ] Run `swift test`.
- [ ] Initialize git.
- [ ] Commit the scaffold.
- [ ] Report repo path and next recommended implementation slice.

