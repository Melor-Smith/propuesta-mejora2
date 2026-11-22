# ODOO-ABC: Odoo 18 para una empresa peruana, desde su repositorio

Parcial 3 de Arquitectura de Software. Se levanta **Odoo 18.0** a partir de su código fuente
(https://github.com/odoo/odoo, rama `18.0`) para **ABC, una empresa de Perú**, de dos maneras:

1. **Local**, en Windows 11, con Python y PostgreSQL del equipo.
2. **Docker**, con una imagen propia que clona el mismo repositorio y un PostgreSQL 18 aparte.

> Proyecto personal, preparado como **propuesta de mejora para el equipo** del Parcial 3
> (complementa el repositorio del grupo, que usa WSL y la imagen oficial `odoo:18.0`).

| | Local | Docker |
|---|---|---|
| Odoo | 18.0, `fuente\` | 18.0, `/opt/odoo` en la imagen |
| Python | 3.12.10 (`.venv`) | 3.12 (`python:3.12-slim-bookworm`) |
| PostgreSQL | 18.6 del equipo, puerto 5432 | 18.7 en contenedor, puerto **5433** |
| wkhtmltopdf | 0.12.6 *patched qt*, instalado aparte | 0.12.6.1 *patched qt* en la imagen |
| URL | http://localhost:**8070** | http://localhost:**8071** |
| Base | `abc` | `abc` |
| Módulos propios | `addons\` | `addons\` montada en `/mnt/extra-addons` |

Se eligió la versión 18.0 porque el addon del Parcial 4 (`l10n_pe_accounting_pro`) es para Odoo 18.
En el equipo ya hay un Odoo 19 instalado con binarios (puerto 8069, bases BOTICA BRISAS y
Bodega_Mika); por eso se usan otros puertos y un `dbfilter` que solo ve la base `abc`.

## Localización Perú

La base se deja lista para operar en Perú con `peru\configurar_peru.py`, en este orden:

1. Idioma **Español (PE)** con sus traducciones; usuario admin con zona horaria `America/Lima`.
2. Empresa **ABC** con país **Perú** y moneda **Sol (PEN)**.
3. Módulos **Ventas** (`sale_management`), **Facturación** (`account`) y
   **Perú - Contabilidad** (`l10n_pe`): plan contable PCGE, **IGV 18 %** como impuesto por
   defecto de ventas y compras, tipos de documento de identidad (RUC, DNI) con validación del
   dígito verificador, tipos de comprobante (factura, boleta, notas) y ubigeo.

**El orden importa.** En Odoo 18 el plan contable se elige según el país de la empresa en el
momento de instalar Facturación. Si la empresa aún no es peruana, se carga el plan genérico y
después ya no se puede cambiar a PCGE ni cambiar la moneda (error *"Oh snap!"* al cambiar la
moneda). Por eso el script fija Perú y PEN antes de instalar los módulos.

- **Local:** `configurar_peru.bat` (una vez, tras el primer arranque).
- **Docker:** automático en el primer arranque (`docker\entrypoint.sh`).

Para pruebas, un RUC con dígito verificador válido es `20123456786`.

## Estructura

```
ODOO-ABC\
├── README.md
├── clonar_odoo.bat       paso 1 local: clona Odoo 18.0 y prepara .venv con sus dependencias
├── iniciar_odoo.bat      paso 2 local: arranca Odoo con odoo.conf
├── configurar_peru.bat   paso 3 local: localización Perú
├── odoo.conf             configuración local (sin contraseñas)
├── peru\
│   └── configurar_peru.py  idioma, país, moneda y módulos peruanos (local y Docker)
├── addons\               módulos propios, p. ej. el del Parcial 4
├── docker\
│   ├── Dockerfile          imagen de Odoo 18.0 construida desde el repositorio
│   ├── entrypoint.sh       contraseñas desde .env, primer arranque y localización Perú
│   ├── odoo.conf           configuración dentro del contenedor (sin contraseñas)
│   ├── docker-compose.yml  servicios db (PostgreSQL 18) y odoo
│   ├── .env.example        plantilla de contraseñas (se versiona)
│   └── .env                contraseñas reales (NO se versiona)
├── .dockerignore         la imagen solo recibe docker\ y peru\
├── evidencia\            capturas
├── presentacion\         diapositivas
├── fuente\               código de Odoo (no se versiona)
└── .venv\                entorno virtual (no se versiona)
```

## Parte 1: instalación local

### Requisitos

- Git.
- **Python 3.12** (no 3.13, ver incidencia 1): `winget install Python.Python.3.12`. Convive
  con otras versiones.
- PostgreSQL con codificación UTF8.
- **wkhtmltopdf 0.12.6** para los PDF: `winget install wkhtmltopdf.wkhtmltox`. Queda en
  `C:\Program Files\wkhtmltopdf\bin` (es el `bin_path` de `odoo.conf`).

### Pasos

1. **Usuario de PostgreSQL.** Odoo no acepta conectarse como `postgres`, así que se crea un
   usuario propio que puede crear bases pero no es superusuario:

   ```sql
   CREATE ROLE odoo18 LOGIN CREATEDB NOSUPERUSER;
   ```

2. **Código y dependencias** (`clonar_odoo.bat`):

   ```bat
   git clone --depth 1 --branch 18.0 https://github.com/odoo/odoo.git fuente
   py -3.12 -m venv .venv
   .venv\Scripts\python.exe -m pip install --upgrade pip setuptools wheel
   .venv\Scripts\python.exe -m pip install -r fuente\requirements.txt
   ```

   El clon superficial (`--depth 1`) trae solo la última versión de la rama: unos 44 000
   archivos y 1,3 GB.

3. **Configuración** (`odoo.conf`): rutas de addons (las del repositorio y `addons\`),
   conexión a PostgreSQL con `odoo18`, base `abc` con `dbfilter = ^abc$` y `list_db = False`,
   puerto 8070 solo en `127.0.0.1`, `db_template = template1`, sin datos de demostración y la
   ruta de wkhtmltopdf.

4. **Primer arranque**, que crea la base `abc` e instala el módulo `base`:

   ```bat
   iniciar_odoo.bat -i base --stop-after-init
   ```

5. **Localización Perú:** `configurar_peru.bat`.

6. **Uso normal:** `iniciar_odoo.bat` y abrir http://localhost:8070. Usuario inicial
   `admin` / `admin`: **cambiar la contraseña al entrar** (Preferencias → Seguridad).

### Contraseñas en la instalación local

`odoo.conf` se versiona, así que no guarda ninguna contraseña:

- PostgreSQL acepta al usuario `odoo18` sin contraseña solo desde este equipo (`trust` en
  `pg_hba.conf` para `127.0.0.1`), y Odoo escucha solo en `127.0.0.1`.
- Con `list_db = False` el gestor de bases web está apagado, así que no hace falta una
  contraseña maestra (`admin_passwd`).

## Parte 2: Docker

Requiere Docker Desktop encendido.

```bat
cd docker
copy .env.example .env
notepad .env
docker compose up -d --build
```

En `.env` se ponen las contraseñas propias. Si falta `.env`, `docker compose` se detiene con
un aviso en lugar de usar claves por defecto.

| Variable | Para qué |
|---|---|
| `POSTGRES_PASSWORD` | Usuario `odoo` de PostgreSQL (solo se aplica al crear el volumen) |
| `ODOO_MASTER_PASSWORD` | Contraseña maestra de Odoo (`admin_passwd`) |
| `ODOO_ADMIN_PASSWORD` | Usuario `admin` para entrar a Odoo |
| `EMPRESA_NOMBRE` | Nombre de la empresa peruana (por defecto `ABC`) |
| `ODOO_PORT`, `POSTGRES_PORT` | Puertos en este equipo (8071 y 5433) |

Qué hace cada pieza:

- `db`: `postgres:18` (misma versión mayor que el PostgreSQL de Windows), inicializado en
  UTF8 y publicado solo en `127.0.0.1:5433`. Desde la imagen 18 el volumen se monta en
  `/var/lib/postgresql` y no en `.../data`. Tiene `healthcheck`: Odoo espera a que esté listo.
- `odoo`: imagen `odoo-abc:18.0` construida con el `Dockerfile`, que:
  1. instala git, compiladores, cabeceras de PostgreSQL y LDAP, y wkhtmltopdf 0.12.6.1;
  2. clona la rama 18.0 de https://github.com/odoo/odoo en `/opt/odoo`;
  3. instala `requirements.txt` con pip;
  4. copia la configuración sin contraseñas, el script de Perú y `entrypoint.sh`;
  5. ejecuta Odoo con un usuario sin privilegios.
- `entrypoint.sh`, en cada arranque, arma la configuración efectiva con las contraseñas de
  `.env` (solo dentro del contenedor, permisos 600). La primera vez además crea la base `abc`
  y la deja peruana.
- `..\addons` se monta en `/mnt/extra-addons`: los módulos propios se editan sin reconstruir
  la imagen.

### Comandos del día a día (dentro de `docker\`)

| Acción | Comando |
|---|---|
| Ver estado | `docker compose ps` |
| Ver el log de Odoo | `docker compose logs -f odoo` |
| Detener sin borrar nada | `docker compose stop` |
| Volver a iniciar | `docker compose start` |
| Reiniciar solo Odoo (p. ej. tras copiar un módulo) | `docker compose restart odoo` |
| Reconstruir tras cambiar `Dockerfile`, `entrypoint.sh` o el script de Perú | `docker compose up -d --build` |
| Quitar los contenedores (los datos quedan) | `docker compose down` |

> **Cuidado:** `docker compose down -v` borra también los volúmenes, es decir, **la base de
> datos y los adjuntos**. Usarlo solo para empezar de cero.

### Resultado verificado (22/11/2026)

- Imagen `odoo-abc:18.0` (2,91 GB) construida desde el repositorio.
- Primer arranque: base `abc` creada y configurada sola en unos 45 s.
- Empresa **ABC**, país **PE**, moneda **PEN**, idioma **es_PE**, plan contable **`pe`**.
- Impuestos **IGV 18 %** de venta y de compra por defecto.
- Módulos `sale_management`, `account`, `l10n_pe`, `l10n_latam_invoice_document`, `base_vat`.
- Entrada con la contraseña de `.env`; `admin` / `admin` es rechazado.

### Prueba de punta a punta (local y Docker, 22/11/2026)

En las dos bases se registró la misma venta y se facturó:

- Cliente **Cliente de Prueba S.A.C.**, RUC `20123456786` (tipo de documento RUC).
- Pedido **S00001**: 10 h de consultoría × S/ 120,00 y 1 licencia anual × S/ 850,00, ambas con
  **IGV 18 %**.
- Factura **F 00000001**, tipo de comprobante **(01) Factura**, publicada:
  subtotal S/ 2 050,00 + IGV S/ 369,00 = **S/ 2 419,00**.
- PDF en español en `evidencia\` (local) y `evidencia\docker\` (Docker): cotización y factura.

Pendiente en Ajustes → Empresa: RUC, dirección y logo reales de ABC (hoy el PDF muestra
"Your logo").

## Incidencias

| # | Incidencia | Causa | Solución |
|---|---|---|---|
| 1 | `pip install -r requirements.txt` falla en `rl-renderPM` | En Windows, Odoo 18 exige `rl-renderPM 4.0.3` (códigos de barras y QR en PDF), que solo tiene versión compilada hasta Python 3.12. Con 3.13 pip intenta compilarla y no hay compilador de C | Instalar Python 3.12 junto al 3.13 y crear `.venv` con `py -3.12` |
| 2 | Texto con tildes enviado a PostgreSQL desde la consola: *"secuencia de bytes no válida para codificación UTF8"* | La consola de Windows envía el texto en otra codificación (misma familia que el problema WIN1252) | El servidor y las bases están en UTF8; no afecta a Odoo. En Docker se fija UTF8 al crear el clúster |
| 3 | Primer arranque: *"los ordenamientos (collation) con valores collate y ctype diferentes no están soportados en esta plataforma"* | Odoo crea la base desde `template0` con `LC_COLLATE 'C'`, mientras `LC_CTYPE` queda en `Spanish_Peru.1252`. PostgreSQL en Windows no admite esa mezcla | `db_template = template1` en `odoo.conf`: la base hereda UTF8 y `Spanish_Peru.1252` en ambos valores. Se borró la base fallida y se repitió el arranque. En Docker (Linux) no ocurre: la base queda con `C` / `C.UTF-8`, combinación válida allí |
| 4 | Los PDF dependían del Odoo 19 instalado | `bin_path` apuntaba al wkhtmltopdf de `C:\Program Files\Odoo 19...\thirdparty`; al desinstalar el Odoo 19 se perderían los PDF | wkhtmltopdf 0.12.6 instalado aparte con winget y `bin_path = C:\Program Files\wkhtmltopdf\bin`. Odoo lo confirma en el log: *"Will use the Wkhtmltopdf binary at ..."* |
| 5 | La localización peruana no se aplica si se instala Facturación primero | El plan contable se elige por el país de la empresa al instalar `account`; sin país se carga el genérico y no se puede cambiar después | `configurar_peru.py` fija país Perú y PEN antes de instalar los módulos |
| 6 | Factura en PDF salió en inglés ("Invoice", fecha 11/22/2026) | Odoo imprime cada documento en el idioma del cliente, y el cliente quedó en `en_US` | `configurar_peru.py` fija `es_PE` como idioma por defecto de los contactos (`ir.default`); el cliente se pasó a `es_PE` y el PDF salió como "Factura", 22/11/2026 |
| 7 | Docker: *"wkhtmltopdf: Exit with code 1 due to network error: ConnectionRefusedError"* | wkhtmltopdf baja los estilos desde `web.base.url`, que Odoo toma del navegador (`127.0.0.1:8071`); esa dirección no existe dentro del contenedor | Parámetro `report.url = http://localhost:8069` (variable `ODOO_REPORT_URL` del compose) |
| 8 | `configurar_peru.bat` podía leer mal el script (tildes) | La consola de Windows usa cp1252 y el script está en UTF-8 | `set PYTHONUTF8=1` en el `.bat`. Del mismo modo, al pasar scripts por tubería con PowerShell 5.1 se añade un BOM (`U+FEFF`): usar `cmd` o Bash |

## Binarios (Odoo 19) frente a fuentes (Odoo 18)

| | Instalador de binarios | Desde el repositorio |
|---|---|---|
| Instalación | Asistente: trae Python, PostgreSQL y wkhtmltopdf | Cada pieza por separado |
| Versión | La del instalador | Cualquier rama del repositorio |
| Servicio | Servicio de Windows | Proceso que se arranca a mano o contenedor |
| Código | Empaquetado | Visible y modificable; base para desarrollar addons |
| Actualizar | Reinstalar | `git pull` y actualizar módulos |

## Mejoras propuestas al repositorio del equipo

Comparación con `odoo-despliegue-unas` (WSL + imagen oficial `odoo:18.0`):

| Tema | Repositorio del equipo | Este proyecto |
|---|---|---|
| Docker "desde el repositorio" | Imagen oficial ya empaquetada | Imagen que clona `github.com/odoo/odoo` |
| Python | 3.14 (fuera de lo soportado por Odoo 18) | 3.12 |
| PostgreSQL en Docker | 16 | 18 |
| Puertos | Odoo publicado en todas las interfaces | Solo `127.0.0.1` |
| Gestor de bases web | Abierto, sin `dbfilter` | `list_db = False` y `dbfilter = ^abc$` |
| Espera a PostgreSQL | `depends_on` simple | `healthcheck` + `service_healthy` |
| Perú | Elegido a mano en el formulario | Script reproducible (es_PE, PEN, PCGE, IGV) |
| Contraseñas | `.env` con valores por defecto `odoo` | `.env` obligatorio, sin valores por defecto |
| Datos de demostración | Aparecen en las evidencias | Base limpia (`without_demo = all`) |
| Ideas tomadas del equipo | Carpeta `addons`, `.env`/`.env.example`, tabla de comandos, aviso de `down -v` | Incorporadas |
