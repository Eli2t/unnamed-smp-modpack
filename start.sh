#!/usr/bin/env bash
# Dev server entrypoint (Magma-Neo: NeoForge mods + Bukkit/Spigot plugins).
#
#   ./start.sh --init    Build the server from scratch in the working dir,
#                        accept the EULA, sync the pack, then exit.
#   ./start.sh           Sync the pack and run the server (this is what pm2 runs).
#
# Run --init once manually, then:  pm2 start ./start.sh --name smp-dev
set -euo pipefail

# --- config -------------------------------------------------------------
PACK_URL="https://raw.githubusercontent.com/Eli2t/unnamed-smp-modpack/main/pack.toml"
MAGMA_JAR="magma.jar"
# Override if the default 404s (grab the current beta URL from magmafoundation.org / Discord):
MAGMA_JAR_URL="${MAGMA_JAR_URL:-https://magmafoundation.org/downloads/magma.jar}"
JVM_ARGS="${JVM_ARGS:--Xms4G -Xmx4G}"
# ------------------------------------------------------------------------

BOOTSTRAP="packwiz-installer-bootstrap.jar"
BOOTSTRAP_URL="https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar"

get_magma() {
  if [ ! -f "$MAGMA_JAR" ]; then
    echo "[magma] downloading launcher from $MAGMA_JAR_URL"
    curl -fSL -o "$MAGMA_JAR" "$MAGMA_JAR_URL"
  fi
}

sync_pack() {
  if [ ! -f "$BOOTSTRAP" ]; then
    echo "[sync] downloading packwiz-installer-bootstrap..."
    curl -fSL -o "$BOOTSTRAP" "$BOOTSTRAP_URL"
  fi
  echo "[sync] syncing pack from $PACK_URL"
  # -g headless, -s server => skip client-only mods
  java -jar "$BOOTSTRAP" -g -s server "$PACK_URL"
}

# Idempotently accept the EULA. Running a server requires agreeing to
# Mojang's EULA (https://aka.ms/MinecraftEULA); this flips the flag once
# the file exists so a missed --init can't cause a restart loop.
ensure_eula() {
  if [ -f eula.txt ] && grep -q '^eula=false' eula.txt; then
    sed -i 's/^eula=false/eula=true/' eula.txt
    echo "[eula] accepted (eula.txt)"
  fi
}

if [ "${1:-}" = "--init" ]; then
  echo "[init] building Magma server from scratch in $(pwd)"
  get_magma
  echo "[init] first run: generating server files (self-stops on EULA)..."
  java $JVM_ARGS -jar "$MAGMA_JAR" nogui || true
  ensure_eula
  [ -f eula.txt ] || echo "[init] WARNING: eula.txt not generated — check the Magma launcher output above"
  sync_pack
  echo "[init] done. Launch with:  pm2 start ./start.sh --name smp-dev"
  exit 0
fi

# --- normal run (pm2 target) --------------------------------------------
get_magma
sync_pack
ensure_eula
echo "[start] launching Magma"
exec java $JVM_ARGS -jar "$MAGMA_JAR" nogui
