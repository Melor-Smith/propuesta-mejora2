# Odoo 18.0 construido desde su repositorio oficial (https://github.com/odoo/odoo),
# los mismos pasos que en la instalación local, pero dentro de un contenedor Linux.
FROM python:3.12-slim-bookworm

ARG ODOO_BRANCH=18.0
ARG WKHTMLTOX_URL=https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# 1. Paquetes del sistema: git para clonar, compiladores y cabeceras para psycopg2 y
#    python-ldap, cliente de PostgreSQL, fuentes y wkhtmltopdf 0.12.6 (PDF de facturas).
RUN apt-get update && apt-get install -y --no-install-recommends \
        git ca-certificates curl build-essential \
        libpq-dev libldap2-dev libsasl2-dev postgresql-client \
        fontconfig fonts-dejavu-core xfonts-75dpi xfonts-base \
    && curl -fsSL -o /tmp/wkhtmltox.deb "$WKHTMLTOX_URL" \
    && apt-get install -y --no-install-recommends /tmp/wkhtmltox.deb \
    && rm -rf /tmp/wkhtmltox.deb /var/lib/apt/lists/*

# 2. Código de Odoo: clon superficial de la rama 18.0.
RUN git clone --depth 1 --branch "$ODOO_BRANCH" https://github.com/odoo/odoo.git /opt/odoo

# 3. Dependencias de Python del propio repositorio.
RUN pip install -r /opt/odoo/requirements.txt

# 4. Usuario sin privilegios, carpeta de datos (adjuntos y sesiones) y carpeta de módulos
#    propios (se monta desde ODOO-ABC/addons).
RUN useradd --system --create-home --home-dir /var/lib/odoo --shell /usr/sbin/nologin odoo \
    && mkdir -p /etc/odoo /mnt/extra-addons && chown odoo: /var/lib/odoo /mnt/extra-addons

# 5. Configuración sin contraseñas, localización Perú y script de arranque.
#    (El contexto de construcción es ODOO-ABC/; ver .dockerignore.)
COPY docker/odoo.conf /etc/odoo/odoo.conf
COPY peru/configurar_peru.py /opt/peru/configurar_peru.py
COPY --chmod=755 docker/entrypoint.sh /usr/local/bin/entrypoint.sh

USER odoo
VOLUME ["/var/lib/odoo"]
EXPOSE 8069

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
