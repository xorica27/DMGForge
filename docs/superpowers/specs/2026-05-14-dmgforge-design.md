# DMGForge Design

## Summary

DMGForge is a native macOS app and CLI for making polished drag-to-install DMG packages from a reusable project file. It is built for agent-assisted release workflows: an agent can generate a `.dmgproject`, open the GUI for human visual approval, then export a DMG directly or hand the approved project back to the agent for release.

## Goals

- Let users package a `.app` into a styled DMG with an Applications shortcut.
- Store every visual and packaging choice in a deterministic `.dmgproject` JSON file.
- Provide a GUI preview/editor for human review.
- Provide a CLI for agents and scripts: `init`, `validate`, `preview`, `export`, and `open`.
- Keep GitHub release publishing outside v1; DMGForge outputs artifacts and metadata, while Codex/Claude can handle commits, tags, checksums, and GitHub releases.

## V1 Scope

- Native SwiftPM macOS project using AppKit/SwiftUI.
- Shared `DMGForgeCore` library for project parsing, validation, preview rendering, and future export.
- Executable app target that can run either as GUI or CLI based on arguments.
- JSON `.dmgproject` format with app path, output path, volume name, layout positions, background style, title, description, and footer.
- CLI skeleton with working `init` and `validate`; `preview`, `export`, and `open` are wired as commands with clear placeholder status during the initial scaffold.
- README for human and agent workflows.

## Architecture

The GUI and CLI share one core model and validation engine. The CLI is the stable automation contract for agents, while the GUI is the approval station for visual review and manual tweaks.

```text
DMGForge
  Sources/DMGForgeCore
    DMGProject.swift
    ProjectValidator.swift
    ProjectFactory.swift
  Sources/DMGForge
    main.swift
    CLI.swift
    DMGForgeApp.swift
    ContentView.swift
  Tests/DMGForgeTests
    DMGProjectTests.swift
```

## Project File Contract

The project file is JSON and intentionally human-readable:

```json
{
  "schemaVersion": 1,
  "appName": "MyApp",
  "version": "1.0.0",
  "appPath": "dist/MyApp.app",
  "outputPath": "dist/MyApp-macos-arm64.dmg",
  "volumeName": "MyApp 1.0.0",
  "window": {
    "width": 680,
    "height": 420
  },
  "layout": {
    "appIcon": { "x": 190, "y": 198 },
    "applicationsIcon": { "x": 500, "y": 198 }
  },
  "background": {
    "mode": "generated",
    "imagePath": null,
    "title": "Drag to install",
    "description": "Drop the app into Applications.",
    "footer": "Packaged with DMGForge."
  }
}
```

## Error Handling

Validation reports all actionable issues instead of failing at the first one. Missing app path, non-`.app` paths, missing background image, invalid dimensions, and unwritable output locations are surfaced in CLI output and later in the GUI.

## Testing

- Unit-test project encoding/decoding.
- Unit-test default project generation.
- Unit-test validation success and failure cases.
- Unit-test CLI argument parsing for `init` and `validate`.

