param(
    [switch]$ConfirmarCargaDemo
)

$ErrorActionPreference = "Stop"

# ============================================================
# CARGA DE DATOS DEMO
# ============================================================
# Este paso es independiente de instalar_proyecto.ps1.
# Se ejecuta despues de crear publicaciones y suscripciones para
# que los datos se repliquen al nodo central.
#
# Es idempotente: puede ejecutarse varias veces sin duplicar datos.
# ============================================================

$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz

if (-not $ConfirmarCargaDemo) {
    throw "Carga protegida. Use -ConfirmarCargaDemo para habilitarla."
}

$archivo = Join-Path $raiz "database\10_seed\01_datos_demo.sql"

if (-not (Test-Path $archivo)) {
    throw "No existe el archivo de datos demo: $archivo"
}

$nodos = @(
    @{
        Nombre = "Cancun"
        Sede = "cancun"
        Contenedor = "hotel-postgres-cancun"
        Base = "hotel_cancun"
    },
    @{
        Nombre = "Tulum"
        Sede = "tulum"
        Contenedor = "hotel-postgres-tulum"
        Base = "hotel_tulum"
    },
    @{
        Nombre = "Bacalar"
        Sede = "bacalar"
        Contenedor = "hotel-postgres-bacalar"
        Base = "hotel_bacalar"
    }
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " CARGA DE DATOS DEMO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

foreach ($nodo in $nodos) {
    $estado = docker inspect --format '{{.State.Running}}' $nodo.Contenedor 2>$null

    if ($LASTEXITCODE -ne 0 -or $estado -ne "true") {
        throw "Contenedor inactivo: $($nodo.Contenedor)."
    }

    Write-Host "`nCargando datos demo en $($nodo.Nombre)..." -ForegroundColor Yellow

    $rutaTemporal = "/tmp/01_datos_demo.sql"
    docker cp $archivo "$($nodo.Contenedor):$rutaTemporal"

    if ($LASTEXITCODE -ne 0) {
        throw "No se pudo copiar el archivo SQL a $($nodo.Contenedor)."
    }

    try {
        $argumentos = @(
            "-e", "PGOPTIONS=-c hotel.sede=$($nodo.Sede)",
            $nodo.Contenedor,
            "psql",
            "-U", "hotel_admin",
            "-d", $nodo.Base,
            "-v", "ON_ERROR_STOP=1",
            "-f", $rutaTemporal
        )

        docker exec @argumentos

        if ($LASTEXITCODE -ne 0) {
            throw "Error cargando datos demo en $($nodo.Base)."
        }
    }
    finally {
        docker exec $nodo.Contenedor rm -f $rutaTemporal | Out-Null
    }

    Write-Host "Datos demo cargados en $($nodo.Nombre)." -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host " CARGA DE DATOS DEMO FINALIZADA" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green