#!/usr/bin/env bash
#
# deploy-local.sh — Sync, push and (re)build the dashboard-web add-on on the
# local HAOS box. Used during phases 6.c-6.e to iterate against real Home
# Assistant before the public ghcr.io image exists (Phase 6.f).
#
# Pipeline:
#   1. ./sync.sh           refresh add-on build context from the source repo
#   2. rsync over SSH      push to /addons/dashboard-web on HAOS
#   3. ha apps reload      Supervisor rescans /addons
#   4. install OR rebuild  first time vs iteration (auto-detected)
#   5. (optional) tail     ha apps logs -f
#
# Auth: SSH key (~/.ssh/id_ed25519, already authorized on HAOS).
# Connectivity: Tailscale by default, override via HAOS_HOST.
#
# Usage:
#   ./deploy-local.sh                  full deploy + rebuild + restart
#   ./deploy-local.sh --no-restart     push only (frontend live-reload cases)
#   ./deploy-local.sh --logs           tail logs after deploy finishes
#   HAOS_HOST=192.168.100.190 ./deploy-local.sh   override host
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

HAOS_HOST="${HAOS_HOST:-ha-c.tail49f016.ts.net}"
HAOS_USER="${HAOS_USER:-root}"
# Internal slug from config.yaml — used for the on-disk path under /addons/.
SLUG="dashboard-web"
# Supervisor app slug — local repo prefixes the internal slug with `local_`.
APP="local_${SLUG}"
REMOTE_PATH="/addons/${SLUG}"
SSH_TARGET="${HAOS_USER}@${HAOS_HOST}"

NO_RESTART=0
TAIL_LOGS=0

usage() {
  cat <<'EOF'
deploy-local.sh — push the dashboard-web add-on to a local HAOS box.

Usage:
  ./deploy-local.sh [--no-restart] [--logs]

Flags:
  --no-restart   Skip ha apps rebuild/restart (frontend HMR iterations).
  --logs         Follow add-on logs after deploy finishes.
  -h, --help     Show this help.

Environment:
  HAOS_HOST      SSH host (default: ha-c.tail49f016.ts.net).
  HAOS_USER      SSH user (default: root).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-restart) NO_RESTART=1; shift ;;
    --logs)       TAIL_LOGS=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *)
      echo "[deploy-local] unknown flag: $1" >&2
      usage >&2
      exit 2 ;;
  esac
done

log() { printf '[deploy-local] %s\n' "$*"; }

log "target: ${SSH_TARGET}:${REMOTE_PATH}"

# 1. Refresh build context (sync.sh excludes node_modules/dist already).
log "running sync.sh"
"${SCRIPT_DIR}/sync.sh"

# 2. Push to HAOS. --delete so removals upstream propagate. Defensive excludes
#    in case someone ran pnpm install inside the build context by accident.
log "rsync → ${SSH_TARGET}:${REMOTE_PATH}"
# --no-owner --no-group: receiver (root on HAOS) recreates files as root.
# Otherwise rsync preserves macOS UID 501, which breaks Supervisor scanning.
rsync -av --delete \
  --no-owner --no-group \
  --exclude='node_modules' \
  --exclude='dist' \
  --exclude='.git' \
  -e "ssh -o ConnectTimeout=10" \
  "${SCRIPT_DIR}/${SLUG}/" \
  "${SSH_TARGET}:${REMOTE_PATH}/"

if [[ $NO_RESTART -eq 1 ]]; then
  log "--no-restart: source pushed, skipping rebuild"
  exit 0
fi

# 3+4. Rescan local store + install/rebuild on the HAOS side. Single SSH session.
log "running ha lifecycle on HAOS (app=${APP})"
ssh "$SSH_TARGET" APP="$APP" 'bash -se' <<'REMOTE'
set -euo pipefail
rlog() { printf '[ha-remote] %s\n' "$*"; }

rlog "ha store reload"
ha store reload >/dev/null

# Detect installation state via `ha apps list` (only returns installed apps).
# `ha apps info` succeeds for store-only entries too, so it can't be used.
if ha apps list --raw-json 2>/dev/null \
     | jq -e --arg s "$APP" '.data.addons[]? | select(.slug == $s)' >/dev/null; then
  # Already installed. If config.yaml version differs from installed, the
  # Supervisor refuses `rebuild` ("Version changed, use Update instead") and
  # only re-reads the full config schema (panel_*, schema, options) on
  # `update`. So branch on update_available.
  UPDATE_AVAILABLE=$(ha apps info "$APP" --raw-json 2>/dev/null \
                       | jq -r '.data.update_available // false')
  if [[ "$UPDATE_AVAILABLE" == "true" ]]; then
    rlog "updating $APP (config version changed)"
    ha apps update "$APP"
  else
    rlog "rebuilding $APP (same version)"
    ha apps rebuild "$APP"
  fi
  rlog "restarting $APP"
  ha apps restart "$APP"
else
  rlog "installing $APP (first time)"
  ha apps install "$APP"
  # `install` only registers the add-on; the initial Docker build is
  # triggered by `start`.
  rlog "starting $APP (initial build, may take 5-8 min)"
  ha apps start "$APP"
fi

# Sidebar panel registration. For STORE add-ons the HA frontend POSTs
# `{ingress_panel: true}` automatically on first install. For LOCAL add-ons
# in /addons/ that auto-POST never fires, so the add-on stays accessible
# only via Settings → Add-ons. We force it whenever ingress is enabled.
INGRESS=$(ha apps info "$APP" --raw-json 2>/dev/null | jq -r '.data.ingress // false')
PANEL=$(ha apps info "$APP" --raw-json 2>/dev/null | jq -r '.data.ingress_panel // false')
if [[ "$INGRESS" == "true" && "$PANEL" != "true" ]]; then
  rlog "registering sidebar panel (POST /addons/$APP/options ingress_panel=true)"
  curl -fsS -X POST \
    -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"ingress_panel": true}' \
    "http://supervisor/addons/$APP/options" >/dev/null
fi

rlog "done"
REMOTE

if [[ $TAIL_LOGS -eq 1 ]]; then
  log "tailing logs — Ctrl-C to stop"
  exec ssh -t "$SSH_TARGET" "ha apps logs ${APP} -f"
fi

log "done"
