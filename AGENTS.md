# Agent Notes

## Project Shape

DMGForge is a SwiftPM macOS app with a shared core library and one executable.

- `Sources/DMGForgeCore`: deterministic project-file, validation, rendering, and packaging logic.
- `Sources/DMGForge`: GUI and CLI entrypoints.
- `Tests/DMGForgeTests`: behavior tests for the core and CLI contract.

## Commands

```bash
swift test
swift build
swift run dmgforge help
```

CLI paths inside `.dmgproject` are currently resolved relative to the caller's working directory. Agents should run `dmgforge` from the app repo root.

## Development Rules

- Keep the GUI and CLI backed by the same `DMGForgeCore` APIs.
- Add tests before changing project-file, validation, rendering, or packaging behavior.
- Keep project files JSON-compatible and human-readable.
- Do not put GitHub release publishing inside the core app flow until the user explicitly asks for it.

