# DMGForge

DMGForge is a native macOS DMG designer and packager for indie app releases and agent-assisted workflows.

The idea is simple: your app repo keeps a small `.dmgproject` file, DMGForge opens it for visual review, and then exports the same polished drag-to-install DMG every time.

## Why It Exists

When Codex, Claude, or another agent finishes building a macOS app, the packaging step still needs a human eye. DMGForge gives that handoff a clean shape:

1. Agent builds the `.app`.
2. Agent creates or updates `packaging/MyApp.dmgproject`.
3. DMGForge opens the design for review.
4. You keep the default design or tweak it manually.
5. DMGForge exports the DMG.
6. The agent can release the final artifact to GitHub.

## CLI Contract

```bash
dmgforge init --app dist/MyApp.app --name MyApp --version 1.0.0 --output packaging/MyApp.dmgproject
dmgforge validate packaging/MyApp.dmgproject
dmgforge preview packaging/MyApp.dmgproject --output dist/MyApp-dmg-preview.png
dmgforge export packaging/MyApp.dmgproject --dry-run
dmgforge export packaging/MyApp.dmgproject
dmgforge open packaging/MyApp.dmgproject
```

The current build implements the project format, `init`, `validate`, `preview`, and `export`. GUI editing is the next implementation slice.

Run CLI commands from the app repo root so relative paths such as `dist/MyApp.app` and `dist/MyApp-macos-arm64.dmg` resolve predictably.

## Project Files

DMGForge project files are JSON so agents can generate them and humans can review them:

```json
{
  "schemaVersion": 1,
  "appName": "MyApp",
  "version": "1.0.0",
  "appPath": "dist/MyApp.app",
  "outputPath": "dist/MyApp-macos-arm64.dmg",
  "volumeName": "MyApp 1.0.0"
}
```

## Development

```bash
swift test
swift run dmgforge --help
```
