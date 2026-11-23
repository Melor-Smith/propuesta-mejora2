@echo off
rem Crea la base "abc" en UTF8 desde template0 (ver bd\crear_base.py). Se ejecuta una vez,
rem despues de clonar_odoo.bat y antes del primer arranque. Si la base ya existe, solo la revisa.
cd /d "%~dp0"
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
set "PGPASSFILE=%~dp0pgpass.conf"
set PYTHONUTF8=1
.venv\Scripts\python.exe bd\crear_base.py %* || goto error
echo.
echo Siguiente paso (solo la primera vez): iniciar_odoo.bat -i base --stop-after-init
pause
exit /b 0
:error
echo.
echo No se pudo crear la base. Revise los mensajes de arriba.
pause
exit /b 1
