#!/usr/bin/env bash
# Pull the mod list from a Prism instance INTO this packwiz repo, then
# commit & push so teammates (Prism) and the server pick it up.
#
#   ./import-from-prism.sh "Gear Spinned"
#
# Prism writes packwiz .pw.toml metadata to <instance>/.../mods/.index/,
# so importing is just: mirror those files into mods/, refresh, push.
set -euo pipefail

INSTANCE="${1:-}"
[ -z "$INSTANCE" ] && { echo "usage: $0 \"<prism instance name>\""; exit 1; }

# Find the Prism data dir (Flatpak first, then native install).
PRISM_BASE=""
for base in \
  "$HOME/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher/instances" \
  "$HOME/.local/share/PrismLauncher/instances"; do
  [ -d "$base/$INSTANCE" ] && PRISM_BASE="$base" && break
done
[ -z "$PRISM_BASE" ] && { echo "ERROR: Prism instance '$INSTANCE' not found"; exit 1; }

# Locate mods/.index (newer Prism uses minecraft/, older .minecraft/).
INDEX=""
for sub in minecraft .minecraft; do
  cand="$PRISM_BASE/$INSTANCE/$sub/mods/.index"
  [ -d "$cand" ] && INDEX="$cand" && break
done
[ -z "$INDEX" ] && { echo "ERROR: no mods/.index in instance '$INSTANCE'"; exit 1; }

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"
mkdir -p mods

# Mirror: clear old metadata, copy the instance's current set. Prism is the
# source of truth, so this also handles mods you removed in the UI.
echo "[import] mirroring $INDEX -> mods/"
rm -f mods/*.pw.toml
shopt -s nullglob
cp "$INDEX"/*.pw.toml mods/
shopt -u nullglob

# --- side curation ------------------------------------------------------
# Prism leaves side = '' (both) on everything, so client-only mods would
# otherwise be pushed to the server and can crash it. Maintain plain-text
# lists (one slug per line; slug = the .pw.toml filename without extension)
# and we re-apply the correct side on every import.
apply_side() {  # $1=listfile  $2=side
  [ -f "$1" ] || return 0
  while IFS= read -r slug; do
    slug="${slug%%#*}"; slug="$(echo "$slug" | xargs)"   # strip comments/space
    [ -z "$slug" ] && continue
    f="mods/${slug}.pw.toml"
    [ -f "$f" ] && sed -i "s/^side = .*/side = \"$2\"/" "$f" && echo "  side=$2: $slug"
  done < "$1"
}
apply_side client-only.txt client
apply_side server-only.txt server
# ------------------------------------------------------------------------

packwiz refresh

git add -A
if git diff --cached --quiet; then
  echo "[import] no changes to push."
else
  git commit -m "Sync mods from Prism instance '$INSTANCE'"
  git push
  echo "[import] pushed. Server: pm2 restart smp-dev | Teammates: relaunch Prism."
fi
