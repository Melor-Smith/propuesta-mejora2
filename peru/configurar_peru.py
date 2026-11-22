# Localización Perú para la base de Odoo 18 de ABC.
# Se ejecuta con el shell de Odoo, que entrega la variable `env`:
#   odoo-bin shell -c odoo.conf --no-http < peru/configurar_peru.py
# Lo usan configurar_peru.bat (local) y docker/entrypoint.sh (Docker, en el primer arranque).
#
# Orden importante: en Odoo 18 el plan contable se elige según el PAÍS DE LA EMPRESA en el
# momento de instalar Facturación (account). Si la empresa no tiene país, se carga el plan
# genérico y después ya no se puede pasar al peruano ni cambiar la moneda. Por eso primero se
# fija Perú y PEN, y solo después se instalan los módulos.
#
# Variables de entorno opcionales:
#   EMPRESA_NOMBRE        nombre de la empresa (por defecto "ABC")
#   ODOO_ADMIN_PASSWORD   contraseña del usuario admin (si no se da, no se cambia)
#   ODOO_REPORT_URL       dirección desde la que wkhtmltopdf baja los estilos de los PDF
#                         (Docker: http://localhost:8069, la de Odoo dentro del contenedor)
import os

MODULOS = ['sale_management', 'account', 'l10n_pe']  # Ventas, Facturación, Perú - Contabilidad

company = env.ref('base.main_company')
# chart_template solo existe cuando Facturación (account) ya está instalada.
plan_actual = company.chart_template if 'chart_template' in company._fields else False
if plan_actual == 'pe':
    print('[peru] La base ya tiene la localización Perú; no se cambia nada.')
else:
    if plan_actual:
        raise SystemExit(
            f'[peru] La empresa ya tiene el plan contable "{plan_actual}". '
            'Odoo no permite cambiarlo: cree una base nueva.'
        )

    # 1. Idioma Español (Perú) con sus traducciones.
    lang = env['res.lang'].with_context(active_test=False).search([('code', '=', 'es_PE')])
    env['base.language.install'].create({'lang_ids': [(6, 0, lang.ids)]}).lang_install()

    # 2. Empresa peruana: país Perú y moneda Sol (PEN).
    pen = env.ref('base.PEN')
    pen.active = True
    company.write({
        'name': os.environ.get('EMPRESA_NOMBRE') or 'ABC',
        'country_id': env.ref('base.pe').id,
        'currency_id': pen.id,
    })
    company.partner_id.write({'lang': 'es_PE', 'tz': 'America/Lima'})
    # Contactos nuevos (clientes y proveedores) en español: Odoo imprime cada documento en el
    # idioma del contacto; sin esto un cliente nuevo puede quedar en inglés y su factura también.
    env['ir.default'].set('res.partner', 'lang', 'es_PE')

    # 3. Usuario administrador en español y hora de Lima.
    admin = env.ref('base.user_admin')
    admin.write({'lang': 'es_PE', 'tz': 'America/Lima'})
    if os.environ.get('ODOO_ADMIN_PASSWORD'):
        admin.password = os.environ['ODOO_ADMIN_PASSWORD']
    if os.environ.get('ODOO_REPORT_URL'):
        # Sin esto, wkhtmltopdf usa web.base.url (la URL del navegador, p. ej. localhost:8071),
        # que dentro del contenedor no existe: el PDF sale sin estilos (ConnectionRefusedError).
        env['ir.config_parameter'].set_param('report.url', os.environ['ODOO_REPORT_URL'])
    env.cr.commit()  # el shell de Odoo revierte todo lo que no se confirme

    # 4. Ventas, Facturación y Perú - Contabilidad (plan contable PCGE, IGV 18 %, RUC, SUNAT).
    env['ir.module.module'].search([('name', 'in', MODULOS)]).button_immediate_install()
    env.cr.commit()
    print('[peru] Empresa peruana configurada: país Perú, PEN, es_PE y módulos', ', '.join(MODULOS))
