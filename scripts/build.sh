#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '%s\n' "Usage: scripts/build.sh [--debug] [--skip-tests] [--no-codesign] [--dmg] [--arch <arm64|x86_64>]"
}

CONFIGURATION="release"
ARCHITECTURE="${ARCHITECTURE:-arm64}"
RUN_TESTS=1
CODESIGN=1
PACKAGE_DMG=0
VERSION="${VERSION:-0.1.1}"
BUNDLE_ID="${BUNDLE_ID:-com.dmgforge.app}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug)
      CONFIGURATION="debug"
      shift
      ;;
    --skip-tests)
      RUN_TESTS=0
      shift
      ;;
    --no-codesign)
      CODESIGN=0
      shift
      ;;
    --dmg)
      PACKAGE_DMG=1
      shift
      ;;
    --arch)
      if [[ $# -lt 2 ]]; then
        usage
        exit 2
      fi
      ARCHITECTURE="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$ARCHITECTURE" in
  arm64|x86_64) ;;
  *)
    printf 'Unsupported architecture: %s\n' "$ARCHITECTURE" >&2
    exit 2
    ;;
esac

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

DIST_DIR="$REPO_ROOT/dist"
APP_NAME="DMGForge"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_BUNDLE_RELATIVE="dist/$APP_NAME.app"
ICON_SOURCE="$REPO_ROOT/Sources/DMGForge/Resources/AppIcon.icns"
ICON_NAME="AppIcon.icns"
PROJECT_DIR="$REPO_ROOT/packaging"
PROJECT_PATH="$PROJECT_DIR/$APP_NAME.dmgproject"
DMG_PATH="$DIST_DIR/$APP_NAME-macos-$ARCHITECTURE.dmg"
BUILD_NUMBER="${BUILD_NUMBER:-$(git rev-list --count HEAD 2>/dev/null || printf '1')}"

if [[ ! -f "$ICON_SOURCE" ]]; then
  printf 'App icon is missing: %s\n' "$ICON_SOURCE" >&2
  printf 'Run scripts/generate-app-icon.swift and try again.\n' >&2
  exit 1
fi

if [[ "$RUN_TESTS" -eq 1 ]]; then
  swift test
fi

swift build -c "$CONFIGURATION" --arch "$ARCHITECTURE"
BUILD_DIR="$(swift build -c "$CONFIGURATION" --arch "$ARCHITECTURE" --show-bin-path)"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources" "$PROJECT_DIR" "$DIST_DIR"
cp "$BUILD_DIR/dmgforge" "$APP_BUNDLE/Contents/MacOS/dmgforge"
cp "$ICON_SOURCE" "$APP_BUNDLE/Contents/Resources/$ICON_NAME"
chmod 755 "$APP_BUNDLE/Contents/MacOS/dmgforge"

/usr/libexec/PlistBuddy -c "Clear dict" "$APP_BUNDLE/Contents/Info.plist" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c "Add :CFBundleDevelopmentRegion string en" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string dmgforge" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string $ICON_NAME" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleInfoDictionaryVersion string 6.0" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string $APP_NAME" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $VERSION" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $BUILD_NUMBER" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 13.0" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSHighResolutionCapable bool true" "$APP_BUNDLE/Contents/Info.plist"

if [[ "$CODESIGN" -eq 1 ]]; then
  /usr/bin/codesign --force --deep --sign "$CODESIGN_IDENTITY" "$APP_BUNDLE"
fi

"$BUILD_DIR/dmgforge" init \
  --app "$APP_BUNDLE_RELATIVE" \
  --name "$APP_NAME" \
  --version "$VERSION" \
  --output "$PROJECT_PATH" >/dev/null
"$BUILD_DIR/dmgforge" first-launch "$PROJECT_PATH" --enable >/dev/null

if [[ "$PACKAGE_DMG" -eq 1 ]]; then
  "$BUILD_DIR/dmgforge" export "$PROJECT_PATH" --output "$DMG_PATH"
fi

printf 'Built app: %s\n' "$APP_BUNDLE"
printf 'Wrote project: %s\n' "$PROJECT_PATH"
if [[ "$PACKAGE_DMG" -eq 1 ]]; then
  printf 'Built DMG: %s\n' "$DMG_PATH"
fi
