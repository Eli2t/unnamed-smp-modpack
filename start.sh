#!/usr/bin/env bash
# pm2 entrypoint for the dev server.
# Copy this (and it will fetch its own bootstrap jar) into your Minecraft
# server's working directory, then run it under pm2.
#
# It (1) syncs the pack from GitHub, then (2) exec's the server so pm2
# tracks the real Java process (clean restarts/stops).
set -euo pipefail

# --- config -------------------------------------------------------------
PACK_URL="https://raw.githubusercontent.com/Eli2t/unnamed-smp-modpack/main/pack.toml"
NEOFORGE_VERSION="21.1.233"
JVM_ARGS="-Xms4G -Xmx4G"
# ------------------------------------------------------------------------

BOOTSTRAP="packwiz-installer-bootstrap.jar"
BOOTSTRAP_URL="https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar"

if [ ! -f "$BOOTSTRAP" ]; then
  echo "[start] downloading packwiz-installer-bootstrap..."
  curl -sSL -o "$BOOTSTRAP" "$BOOTSTRAP_URL"
fi

echo "[start] syncing pack from $PACK_URL"
# -g headless, -s server => skip client-only mods
java -jar "$BOOTSTRAP" -g -s server "$PACK_URL"

echo "[start] launching NeoForge $NEOFORGE_VERSION"
exec java $JVM_ARGS @libraries/net/neoforged/neoforge/${NEOFORGE_VERSION}/unix_args.txt nogui
