@echo off
rem Arranca Odoo 18.0 desde su codigo fuente con la configuracion odoo.conf.
rem Abrir luego http://localhost:8070  (detener: Ctrl+C o cerrar esta ventana)
cd /d "%~dp0"
if not exist fuente\odoo-bin (
    echo Falta el codigo de Odoo. Ejecute primero clonar_odoo.bat
    pause
    exit /b 1
)
if not exist .venv\Scripts\python.exe (
    echo Falta el entorno virtual. Ejecute primero clonar_odoo.bat
    pause
    exit /b 1
)
.venv\Scripts\python.exe fuente\odoo-bin -c odoo.conf %*
