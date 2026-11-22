@echo off
rem Deja la base "abc" lista para una empresa peruana: idioma es_PE, pais Peru, moneda PEN,
rem y los modulos Ventas, Facturacion y Peru - Contabilidad (PCGE, IGV 18 por ciento, RUC).
rem Ejecutar UNA vez, despues del primer arranque y ANTES de instalar Facturacion a mano.
rem La empresa se llama "ABC". Para otro nombre, antes de ejecutar: set EMPRESA_NOMBRE=Mi Empresa SAC
cd /d "%~dp0"
if not exist .venv\Scripts\python.exe (
    echo Falta el entorno virtual. Ejecute primero clonar_odoo.bat
    pause
    exit /b 1
)
rem El script esta en UTF-8 (tildes); sin esto Python lo leeria como cp1252, el de la consola.
set PYTHONUTF8=1
.venv\Scripts\python.exe fuente\odoo-bin shell -c odoo.conf --no-http < peru\configurar_peru.py || goto error
echo.
echo Listo. Reinicie iniciar_odoo.bat si estaba abierto y entre a http://localhost:8070
pause
exit /b 0
:error
echo.
echo No se pudo configurar la localizacion Peru. Revise los mensajes de arriba.
pause
exit /b 1
