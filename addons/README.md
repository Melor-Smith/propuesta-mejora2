# addons: módulos propios

Carpeta para los módulos que no vienen en el repositorio de Odoo, por ejemplo el addon del
Parcial 4 (`l10n_pe_accounting_pro`). Cada módulo va en su propia subcarpeta, con
`__init__.py` y `__manifest__.py`.

Odoo la lee en las dos instalaciones:

- **Local:** última ruta de `addons_path` en `odoo.conf`.
- **Docker:** montada en `/mnt/extra-addons` (ver `docker/docker-compose.yml`), así que un
  cambio aquí se ve en el contenedor sin reconstruir la imagen.

Después de copiar un módulo: reiniciar Odoo, activar el modo desarrollador y, en
Aplicaciones, usar **Actualizar lista de aplicaciones**.
