#!/usr/bin/env bash
# Run this on the dev server *before* starting Minecraft.
# It downloads/updates packwiz-installer and syncs the pack server-side.
#
# Set PACK_URL to your repo's raw pack.toml URL, e.g.:
#   https://raw.githubusercontent.com/<user>/<repo>/master/pack.toml
set -euo pipefail

PACK_URL="${PACK_URL:-REPLACE_WITH_RAW_PACK_TOML_URL}"
BOOTSTRAP="packwiz-installer-bootstrap.jar"
BOOTSTRAP_URL="https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar"

if [ ! -f "$BOOTSTRAP" ]; then
  echo "Downloading packwiz-installer-bootstrap..."
  curl -sSL -o "$BOOTSTRAP" "$BOOTSTRAP_URL"
fi

# -g  : no GUI (headless)
# -s server : install server-side mods only (skips client-only mods)
java -jar "$BOOTSTRAP" -g -s server "$PACK_URL"
