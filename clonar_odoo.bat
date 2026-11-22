@echo off
rem Prepara Odoo 18.0 desde su repositorio oficial: descarga el codigo y sus dependencias.
rem Requisitos: Git y Python 3.12. Se ejecuta una sola vez.
rem (Con Python 3.13 falla rl-renderPM 4.0.3: en Windows solo hay rueda compilada hasta 3.12.)
cd /d "%~dp0"
if not exist fuente\odoo-bin (
    echo Descargando Odoo 18.0 desde https://github.com/odoo/odoo ...
    git clone --depth 1 --branch 18.0 https://github.com/odoo/odoo.git fuente || goto error
)
if not exist .venv\Scripts\python.exe (
    echo Creando el entorno virtual .venv ...
    py -3.12 -m venv .venv || goto error
)
echo Instalando dependencias de Odoo (requirements.txt) ...
.venv\Scripts\python.exe -m pip install --upgrade pip setuptools wheel || goto error
.venv\Scripts\python.exe -m pip install -r fuente\requirements.txt || goto error
echo.
echo Listo. Ahora ejecute iniciar_odoo.bat
pause
exit /b 0
:error
echo.
echo No se pudo completar la preparacion. Revise los mensajes de arriba.
pause
exit /b 1
