# ha-pulse-addon

Catálogo de Home Assistant para
[`ha-pulse`](https://github.com/claudiojara/ha-pulse) — un dashboard
custom para HA con chat (Claude), control de entidades en tiempo real, vistas
por habitación, streams de cámaras y controles de media player.

## Instalación (usuarios)

1. **Settings → Add-ons → Add-on Store → ⋮ → Repositories**.
2. Pegar la URL: `https://github.com/claudiojara/ha-pulse-addon`.
3. **Add**, cerrar el diálogo y refrescar.
4. Buscar **Pulse** en el store, click **Install**.
5. Una vez instalado, **Configuration** → setear `anthropic_api_key`
   (opcional; si se deja vacío, el chat queda deshabilitado pero el resto
   del dashboard funciona).
6. **Save** → **Start**.
7. El panel **Dashboard** aparece en el sidebar de Home Assistant.

### Opciones del add-on

| Opción              | Tipo       | Default                | Notas                                              |
|---------------------|------------|------------------------|----------------------------------------------------|
| `log_level`         | enum       | `info`                 | `debug`, `info`, `warn`, `error`                   |
| `anthropic_api_key` | password   | `""`                   | API key de Anthropic. Vacío deshabilita el chat    |
| `anthropic_model`   | string     | `claude-sonnet-4-6`    | Slug del modelo. Permite override por usuario      |

Cambios de opciones requieren restart del add-on (estándar de HA).

## Desarrollo (mantenedores)

Para iterar contra un HAOS local sin pasar por `ghcr.io`:

```bash
# Repos como hermanos:
~/Workspace/personal/home-assistant/
├── ha-pulse/         # código
└── ha-pulse-addon/   # este repo

# Deploy contra el HAOS de dev (Tailscale + ha apps update/rebuild):
cd ha-pulse-addon
./deploy-local.sh
```

`deploy-local.sh` sincroniza el código fuente, lo copia al HAOS por SSH y
fuerza un build local del add-on. Strip-ea la línea `image:` del catálogo
para que Supervisor compile en lugar de bajar la imagen pública.

Para publicar una versión nueva al público (CI multi-arch + bump del
catálogo) ver [`../ha-dashboard/RELEASING.md`](../ha-dashboard/RELEASING.md).

## Estructura del repo

```
ha-pulse-addon/
├── repository.yaml          # metadata del catálogo (name, url, maintainer)
├── README.md                # este archivo
├── deploy-local.sh          # deploy a HAOS de dev (build local)
├── sync.sh                  # mirror del código fuente al build context
└── pulse/                  # carpeta del add-on (slug)
    ├── config.yaml          # manifest del add-on (committeado)
    ├── README.md            # docs del add-on para el usuario final
    └── (apps/, packages/, Dockerfile sincronizados, gitignored)
```

## Referencias

- Código: <https://github.com/claudiojara/ha-pulse>
- Imagen publicada: `ghcr.io/claudiojara/ha-pulse:<version>` y `:latest`
- Lecciones acumuladas (HA Supervisor + Ingress + deploy):
  [`../ha-dashboard/LESSONS.md`](../ha-dashboard/LESSONS.md)
- Workflow de publicación:
  [`../ha-dashboard/RELEASING.md`](../ha-dashboard/RELEASING.md)
