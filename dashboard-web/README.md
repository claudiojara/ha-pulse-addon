# Dashboard Web — Home Assistant Add-on

Custom HA dashboard with chat (Claude), real-time entity control, per-room
views, camera streams and media player controls.

> **Phase 6.c notice.** Right now this add-on is intended for **local install**
> (Samba copy into `/addons/dashboard-web/`) using a synced source tree built by
> `sync.sh` in the parent folder. The full "Add custom repository" public flow
> goes live in phase 6.f when the multi-arch image is published to `ghcr.io`.

## Configuration

No configuration options yet. The add-on reads the `SUPERVISOR_TOKEN` injected
by Home Assistant (via `homeassistant_api: true`) to talk to your HA instance.

Anthropic API key for chat will be exposed as an option in phase 6.e.

## Network

The web UI is exposed on port **3001**. After starting the add-on, open
`http://homeassistant.local:3001` (or use your HA's IP).

In phase 6.d the add-on will move into the HA sidebar via Ingress so you don't
need to expose the port manually.

## Logs

Standard HA add-on log panel. Watch for:

- `[config] modo supervised — HA en http://supervisor/core` — confirms it
  picked up the supervisor token and is talking to HA via the internal API.
- `[HA] conectado` — WebSocket auth successful.
- `[web] sirviendo statics desde /app/apps/web/dist` — frontend bundle present.
- `API escuchando en http://0.0.0.0:3001` — server is up.
