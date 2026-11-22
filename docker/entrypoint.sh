#!/bin/bash
# Arranque del contenedor de Odoo 18 para ABC (empresa peruana).
#  1. Toma las contraseñas de las variables de entorno (docker/.env), no de archivos de la imagen.
#  2. Primer arranque: crea la base y la deja peruana (peru/configurar_peru.py).
#  3. Arranca Odoo.
set -euo pipefail

: "${DB_PASSWORD:?Falta DB_PASSWORD: copie docker/.env.example a docker/.env}"
: "${ODOO_MASTER_PASSWORD:?Falta ODOO_MASTER_PASSWORD: copie docker/.env.example a docker/.env}"

BASE_CONF=/etc/odoo/odoo.conf
CONF=/tmp/odoo.conf
conf_get() { awk -F' *= *' -v k="$1" '$1 == k { print $2 }' "$BASE_CONF"; }

# Configuración efectiva = la de la imagen + las contraseñas (solo existe dentro del contenedor).
umask 077
cp "$BASE_CONF" "$CONF"
printf '\ndb_password = %s\nadmin_passwd = %s\n' "$DB_PASSWORD" "$ODOO_MASTER_PASSWORD" >> "$CONF"

DB_HOST=$(conf_get db_host)
DB_USER=$(conf_get db_user)
DB_NAME=$(conf_get db_name)
export PGPASSWORD="$DB_PASSWORD"
consulta() { psql -h "$DB_HOST" -U "$DB_USER" -d "$1" -tAXc "$2" 2>/dev/null || true; }

if [ -z "$(consulta postgres "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'")" ]; then
    echo "[entrypoint] Primer arranque: se crea la base '$DB_NAME'."
    python /opt/odoo/odoo-bin -c "$CONF" -i base --stop-after-init
fi

if [ "$(consulta "$DB_NAME" "SELECT chart_template FROM res_company WHERE id = 1")" != "pe" ]; then
    echo "[entrypoint] Configurando la localización Perú (es_PE, PEN, PCGE, IGV)."
    python /opt/odoo/odoo-bin shell -c "$CONF" --no-http < /opt/peru/configurar_peru.py
fi

unset PGPASSWORD
exec python /opt/odoo/odoo-bin -c "$CONF" "$@"
