#!/usr/bin/env bash
#
# sync.sh — Copia el árbol de código de ha-pulse al build context del add-on.
#
# Workflow de phases 6.c-6.e: HA Supervisor buildea el add-on desde la carpeta
# del slug (`pulse/`), así que esa carpeta tiene que tener el código completo +
# Dockerfile + .dockerignore. Los mantenemos sincronizados desde el repo
# hermano `ha-pulse` para evitar duplicación.
#
# Uso (desde el root del repo ha-pulse-addon):
#   ./sync.sh
#
# Phase 6.f reemplaza el Dockerfile syncado por uno thin que hace
# `FROM ghcr.io/claudiojara/ha-pulse:<version>`. Cuando se publica vía
# imagen, el sync deja de ser necesario.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${HA_PULSE_SRC:-$SCRIPT_DIR/../ha-pulse}"
DST="$SCRIPT_DIR/pulse"

if [[ ! -d "$SRC" ]]; then
  echo "[sync] source repo not found at $SRC" >&2
  echo "[sync] set HA_PULSE_SRC=/path/to/ha-pulse to override" >&2
  exit 1
fi

echo "[sync] source: $SRC"
echo "[sync] dest:   $DST"

# Wipe stale source-controlled subdirs (so deletes upstream propagate).
# Add-on metadata files (config.yaml, README.md) at $DST root are NOT touched.
rm -rf "$DST/apps" "$DST/packages"

mkdir -p "$DST"

rsync -a \
  --exclude='node_modules' \
  --exclude='dist' \
  --exclude='.tanstack' \
  --exclude='data' \
  --exclude='.env' \
  --exclude='.env.*' \
  --exclude='.playwright-mcp' \
  --exclude='playwright-report' \
  --exclude='test-results' \
  "$SRC/apps/"     "$DST/apps/"

rsync -a \
  --exclude='node_modules' \
  --exclude='dist' \
  "$SRC/packages/" "$DST/packages/"

# Single-file copies (workspace manifests + build files).
for f in package.json pnpm-lock.yaml pnpm-workspace.yaml tsconfig.base.json biome.json Dockerfile .dockerignore; do
  cp "$SRC/$f" "$DST/$f"
done

echo "[sync] done."
