# ha-pulse-addon — archivado

Este repositorio fue **fusionado dentro del repo principal**:

> https://github.com/claudiojara/ha-pulse

Si tenías este repositorio agregado en tu Home Assistant
(`https://github.com/claudiojara/ha-pulse-addon`), tienes que migrar al
nuevo URL:

1. **Settings → Add-ons → Add-on Store → ⋮ → Repositories**.
2. Quita el repositorio `https://github.com/claudiojara/ha-pulse-addon`.
3. Agrega el nuevo: `https://github.com/claudiojara/ha-pulse`.
4. Reinstala el add-on **Pulse** desde el catálogo nuevo.
5. Reconfigura las opciones (ej. `anthropic_api_key`) — el cambio de URL
   crea una instalación distinta a ojos del Supervisor; los datos de la
   instalación previa quedan asociados al catálogo viejo.

A partir de ahora, todo el desarrollo, las nuevas versiones y la imagen
publicada (`ghcr.io/claudiojara/ha-pulse`) viven en el repo principal.

Este repositorio queda archivado como referencia histórica.
