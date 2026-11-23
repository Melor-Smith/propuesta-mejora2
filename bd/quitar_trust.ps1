# Pasa al usuario odoo18 de "trust" (entrar sin contrasena) a scram-sha-256 con contrasena.
# Solo hace falta en equipos donde pg_hba.conf quedo en trust. Se ejecuta una vez, desde ODOO-ABC:
#   powershell -ExecutionPolicy Bypass -File bd\quitar_trust.ps1
#
# 1. Genera una contrasena aleatoria y se la pone a odoo18 (mientras trust todavia deja entrar).
# 2. La guarda en pgpass.conf (no se versiona); los .bat la pasan a Odoo con PGPASSFILE.
# 3. Copia de respaldo de pg_hba.conf y agrega reglas scram-sha-256 para odoo18 ANTES de las
#    de trust (PostgreSQL usa la primera regla que coincide). Las demas reglas no se tocan.
# 4. Recarga la configuracion de PostgreSQL y comprueba que sin contrasena ya no entra.
# El script esta en ASCII a proposito: PowerShell 5.1 lee los .ps1 sin BOM como cp1252.
param([string]$PgDir = 'C:\Program Files\PostgreSQL\18')
$ErrorActionPreference = 'Stop'

$raiz   = Split-Path $PSScriptRoot -Parent
$pgpass = Join-Path $raiz 'pgpass.conf'
$datos  = Join-Path $PgDir 'data'
$hba    = Join-Path $datos 'pg_hba.conf'
$psql   = Join-Path $PgDir 'bin\psql.exe'
$pgctl  = Join-Path $PgDir 'bin\pg_ctl.exe'

if (Test-Path $pgpass) { throw "Ya existe $pgpass. Borrelo solo si quiere generar otra contrasena." }
foreach ($f in @($hba, $psql)) { if (-not (Test-Path $f)) { throw "No se encuentra $f (parametro -PgDir)." } }

# 1. Contrasena aleatoria de 32 caracteres (64 simbolos posibles: sin sesgo al usar modulo 64).
$simbolos = [char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_'
$bytes = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$clave = -join ($bytes | ForEach-Object { $simbolos[$_ % 64] })

# La orden va en un archivo temporal (no en la linea de comandos, que otros procesos pueden ver).
$sql = Join-Path $env:TEMP ("odoo18-" + [guid]::NewGuid() + '.sql')
[System.IO.File]::WriteAllText($sql, "SET password_encryption = 'scram-sha-256';`nALTER ROLE odoo18 PASSWORD '$clave';`n")
try {
    & $psql -h 127.0.0.1 -p 5432 -U odoo18 -d postgres -w -q -v ON_ERROR_STOP=1 -f $sql
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo poner la contrasena a odoo18.' }
} finally {
    Remove-Item $sql -Force
}
Write-Host '[1/4] Contrasena de odoo18 cambiada (scram-sha-256).'

# 2. pgpass.conf (formato de libpq: servidor:puerto:base:usuario:contrasena)
[System.IO.File]::WriteAllText($pgpass, "# Generado por bd\quitar_trust.ps1. No se versiona.`n127.0.0.1:5432:*:odoo18:$clave`n")
Write-Host "[2/4] Contrasena guardada en $pgpass"

# 3. pg_hba.conf
$lineas = [System.IO.File]::ReadAllLines($hba)
if ($lineas -match '^\s*host\s+all\s+odoo18\s') {
    Write-Host '[3/4] pg_hba.conf ya tenia reglas para odoo18: no se cambia.'
} else {
    $respaldo = "$hba.antes-de-quitar-trust"
    Copy-Item $hba $respaldo -Force
    $nuevo = New-Object System.Collections.Generic.List[string]
    $puesto = $false
    foreach ($l in $lineas) {
        if (-not $puesto -and $l -match '^\s*(local|host)\s') {
            $nuevo.Add('# odoo18 (Odoo 18 de ODOO-ABC): siempre con contrasena, antes de cualquier regla trust')
            $nuevo.Add('host    all             odoo18          127.0.0.1/32            scram-sha-256')
            $nuevo.Add('host    all             odoo18          ::1/128                 scram-sha-256')
            $puesto = $true
        }
        $nuevo.Add($l)
    }
    [System.IO.File]::WriteAllLines($hba, $nuevo)
    Write-Host "[3/4] pg_hba.conf actualizado (respaldo: $respaldo)"
}

# 4. Recargar y comprobar. Aqui se esperan errores de psql (el intento sin contrasena debe
# fallar): con 'Stop', PowerShell 5.1 cortaria el script al ver texto en stderr.
$ErrorActionPreference = 'Continue'
& $pgctl reload -D $datos | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'pg_ctl reload no pudo; se recarga desde SQL con el usuario postgres.'
    & $psql -h 127.0.0.1 -U postgres -d postgres -w -q -c 'SELECT pg_reload_conf()' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo recargar PostgreSQL. Reinicie el servicio postgresql-x64-18 como administrador.' }
}
Start-Sleep -Seconds 1

$antes = $env:PGPASSFILE
$env:PGPASSFILE = Join-Path $env:TEMP 'no-existe.pgpass'
& $psql -h 127.0.0.1 -U odoo18 -d postgres -w -Atc 'SELECT 1' 2>$null | Out-Null
$sinClave = $LASTEXITCODE
$env:PGPASSFILE = $pgpass
$usuario = & $psql -h 127.0.0.1 -U odoo18 -d postgres -w -Atc 'SELECT current_user'
$conClave = $LASTEXITCODE
$env:PGPASSFILE = $antes

if ($sinClave -ne 0 -and $conClave -eq 0) {
    Write-Host "[4/4] Comprobado: sin contrasena se rechaza; con pgpass.conf entra como $usuario."
    Write-Host 'Reinicie Odoo local: cierre la ventana de iniciar_odoo.bat y abralo de nuevo.'
} else {
    throw "Comprobacion fallida (sin contrasena: codigo $sinClave; con contrasena: codigo $conClave)."
}
