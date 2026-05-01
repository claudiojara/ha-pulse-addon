# dashboard-web-addon

Home Assistant add-on repository for [`dashboard-web`](https://github.com/neocjara/dashboard-web)
— a custom HA dashboard with chat (Claude), real-time entity control,
per-room views, camera streams and media player controls.

## Status

**Phase 6.c** — local install path is functional. Full "Add custom repository"
flow with a public `ghcr.io` image lands in phase 6.f.

## Public install (phase 6.f, not yet available)

1. **Settings → Add-ons → Add-on Store → ⋮ → Repositories**.
2. Paste this repo URL: `https://github.com/neocjara/dashboard-web-addon`.
3. Add, close, refresh.
4. Find **Dashboard Web** in the store, install, start.

## Local install (phase 6.c, current)

Until the public image is published, you install via the HAOS local add-on
mechanism using a synced source tree. Steps:

1. Clone both repos as siblings:
   ```bash
   ~/Workspace/personal/home-assistant/
   ├── dashboard-web/         # the code
   └── dashboard-web-addon/   # this repo
   ```
2. Sync the source into the add-on build context:
   ```bash
   cd dashboard-web-addon
   ./sync.sh
   ```
3. Copy the `dashboard-web/` folder of THIS repo into your HAOS at
   `/addons/dashboard-web/`. Easiest path: install the
   [Samba share add-on](https://github.com/home-assistant/addons/tree/master/samba)
   on your HA, mount `\\homeassistant.local\addons` from your Mac, drag the folder.
4. In HA: **Settings → Add-ons → ⋮ → Check for updates**. The add-on
   appears under **Local add-ons**.
5. Click **Install**, wait for the build (first time is slow), then **Start**.
6. Open `http://homeassistant.local:3001`.

## Repository layout

```
dashboard-web-addon/
├── repository.yaml          # catalog metadata
├── README.md                # this file
├── sync.sh                  # populates dashboard-web/ from ../dashboard-web
└── dashboard-web/           # the add-on slug folder
    ├── config.yaml          # add-on manifest (committed)
    ├── README.md            # end-user add-on docs (committed)
    ├── Dockerfile           # synced, gitignored
    ├── apps/, packages/...  # synced, gitignored
    └── ...
```
