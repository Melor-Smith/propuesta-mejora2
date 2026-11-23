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
if not exist pgpass.conf (
    echo Falta pgpass.conf con la contrasena de PostgreSQL. Copie pgpass.conf.example como
    echo pgpass.conf y ponga la contrasena del usuario odoo18.
    pause
    exit /b 1
)
rem La contrasena de PostgreSQL la lee libpq de este archivo (no se versiona).
set "PGPASSFILE=%~dp0pgpass.conf"
.venv\Scripts\python.exe fuente\odoo-bin -c odoo.conf %*
