# Crea la base de Odoo (local, Windows) en UTF8 a partir de template0.
#
# Por qué no se deja a Odoo:
#   - Con db_template = template0, Odoo 18 ejecuta
#       CREATE DATABASE ... ENCODING 'unicode' LC_COLLATE 'C' TEMPLATE template0
#     y LC_CTYPE queda con el locale del servidor (p. ej. Spanish_Peru.1252). PostgreSQL en
#     Windows rechaza collate y ctype distintos (incidencia 3 del README).
#   - Con db_template = template1, la base depende de cómo se instaló el servidor: si
#     template1 está en WIN1252, la creación falla. Además, template1 puede tener objetos
#     agregados a mano que se copiarían a la base.
#
# Este script pide todo de forma explícita: TEMPLATE template0 (la plantilla limpia de
# PostgreSQL), ENCODING 'UTF8' y el MISMO locale en LC_COLLATE y LC_CTYPE (el del servidor,
# leído de template0). En Windows, UTF8 se acepta con cualquier locale.
#
# Uso: crear_base.bat [nombre]   (por defecto, db_name de odoo.conf)
# Lee db_host, db_port, db_user y db_name de odoo.conf. La contraseña no está en el código:
# libpq la toma del archivo que indica PGPASSFILE (pgpass.conf, ver pgpass.conf.example).
# Variable opcional: BD_LOCALE para forzar otro locale (p. ej. "Spanish_Spain.1252").
import configparser
import os
import sys
from pathlib import Path

import psycopg2
from psycopg2 import sql

RAIZ = Path(__file__).resolve().parent.parent

conf = configparser.ConfigParser(interpolation=None)
conf.read(RAIZ / 'odoo.conf', encoding='utf-8')
opciones = conf['options']

nombre = sys.argv[1] if len(sys.argv) > 1 else opciones.get('db_name')
if not nombre or nombre == 'False':
    raise SystemExit('[bd] Falta el nombre de la base (db_name en odoo.conf o como argumento).')

conexion = psycopg2.connect(
    dbname='postgres',
    host=opciones.get('db_host', '127.0.0.1'),
    port=opciones.get('db_port', '5432'),
    user=opciones.get('db_user'),
)
conexion.autocommit = True  # CREATE DATABASE no puede ir dentro de una transacción
cr = conexion.cursor()

cr.execute(
    "SELECT pg_encoding_to_char(encoding), datcollate, datctype FROM pg_database WHERE datname = %s",
    (nombre,),
)
existente = cr.fetchone()
if existente:
    codificacion, collate, ctype = existente
    print(f'[bd] La base "{nombre}" ya existe: {codificacion}, collate {collate}, ctype {ctype}.')
    if codificacion != 'UTF8':
        raise SystemExit(f'[bd] ERROR: la base "{nombre}" no está en UTF8. Hay que recrearla.')
    print('[bd] Está en UTF8: no se cambia nada.')
    sys.exit(0)

cr.execute("SELECT datctype FROM pg_database WHERE datname = 'template0'")
locale = os.environ.get('BD_LOCALE') or cr.fetchone()[0]

cr.execute(sql.SQL(
    "CREATE DATABASE {} TEMPLATE template0 ENCODING 'UTF8' LC_COLLATE {} LC_CTYPE {}"
).format(sql.Identifier(nombre), sql.Literal(locale), sql.Literal(locale)))

cr.execute(
    "SELECT pg_encoding_to_char(encoding), datcollate, datctype FROM pg_database WHERE datname = %s",
    (nombre,),
)
codificacion, collate, ctype = cr.fetchone()
print(f'[bd] Base "{nombre}" creada desde template0: {codificacion}, collate {collate}, ctype {ctype}.')
conexion.close()
