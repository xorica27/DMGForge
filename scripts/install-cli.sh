#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${DMGFORGE_APP_PATH:-/Applications/DMGForge.app}"
LINK_PATH="${DMGFORGE_CLI_LINK_PATH:-/usr/local/bin/dmgforge}"
BINARY_PATH="$APP_PATH/Contents/MacOS/dmgforge"
LINK_DIR="$(dirname "$LINK_PATH")"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  printf '%s\n' "Usage: scripts/install-cli.sh"
  printf '%s\n' "Installs dmgforge CLI link at ${LINK_PATH}."
  exit 0
fi

if [[ ! -d "$APP_PATH" ]]; then
  printf 'DMGForge.app was not found at %s\n' "$APP_PATH" >&2
  printf 'Install the app first, or set DMGFORGE_APP_PATH=/path/to/DMGForge.app.\n' >&2
  exit 1
fi

if [[ ! -x "$BINARY_PATH" ]]; then
  printf 'DMGForge CLI binary is missing or not executable: %s\n' "$BINARY_PATH" >&2
  exit 1
fi

mkdir -p "$LINK_DIR"

if [[ ! -w "$LINK_DIR" ]]; then
  printf 'Cannot write to %s.\n' "$LINK_DIR" >&2
  printf 'Run with sudo, or set DMGFORGE_CLI_LINK_PATH to a writable location.\n' >&2
  exit 1
fi

ln -sfn "$BINARY_PATH" "$LINK_PATH"

if [[ ! -x "$LINK_PATH" ]]; then
  printf 'CLI link was created but is not executable: %s\n' "$LINK_PATH" >&2
  exit 1
fi

"$LINK_PATH" help >/dev/null

printf 'Installed dmgforge CLI: %s -> %s\n' "$LINK_PATH" "$BINARY_PATH"
printf 'Verified dmgforge help.\n'
