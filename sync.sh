#!/usr/bin/env bash
#
# sync.sh — Copy the dashboard-web source tree into the add-on build context.
#
# Phase 6.c-6.e workflow: HA Supervisor builds the add-on from the slug folder
# `dashboard-web/`, so that folder needs to contain the full source code plus
# the Dockerfile and .dockerignore. We keep those synced from the sibling
# `dashboard-web` repo to avoid duplication.
#
# Usage (from the dashboard-web-addon repo root):
#   ./sync.sh
#
# Phase 6.f will replace this with a thin Dockerfile that does
# `FROM ghcr.io/neocjara/dashboard-web:<version>` and the sync becomes
# unnecessary.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${DASHBOARD_WEB_SRC:-$SCRIPT_DIR/../dashboard-web}"
DST="$SCRIPT_DIR/dashboard-web"

if [[ ! -d "$SRC" ]]; then
  echo "[sync] source repo not found at $SRC" >&2
  echo "[sync] set DASHBOARD_WEB_SRC=/path/to/dashboard-web to override" >&2
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
