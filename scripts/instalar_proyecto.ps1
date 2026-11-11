
param(
    [switch]$ConfirmarInstalacionLimpia
)

$ErrorActionPreference = "Stop"

# ============================================================
# CONFIGURACION GENERAL
# ============================================================

$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz

$nodos = @(
    @{
        Nombre = "Cancun"
        Contenedor = "hotel-postgres-cancun"
        Base = "hotel_cancun"
        Puerto = 5541
    },
    @{
        Nombre = "Tulum"
        Contenedor = "hotel-postgres-tulum"
        Base = "hotel_tulum"
        Puerto = 5542
    },
    @{
        Nombre = "Bacalar"
        Contenedor = "hotel-postgres-bacalar"
        Base = "hotel_bacalar"
        Puerto = 5543
    },
    @{
        Nombre = "Central"
        Contenedor = "hotel-postgres-central"
        Base = "hotel_central"
        Puerto = 5544
    }
)

# ============================================================
# FUNCION: COPIAR Y EJECUTAR SQL
# ============================================================

function Copiar-Y-Ejecutar {
    param(
        [string]$Contenedor,
        [string]$Base,
        [string]$Archivo,
        [switch]$Interactivo
    )

    if (-not (Test-Path $Archivo)) {
        throw "No existe el archivo SQL: $Archivo"
    }

    $nombre = Split-Path $Archivo -Leaf
    $rutaTemporal = "/tmp/$nombre"

    Write-Host "`nEjecutando: $Archivo" -ForegroundColor Yellow

    docker cp $Archivo "${Contenedor}:$rutaTemporal"

    if ($LASTEXITCODE -ne 0) {
        throw "No se pudo copiar $Archivo al contenedor."
    }

    try {
        $argumentos = @()

        if ($Interactivo) {
            $argumentos += @("-it")
        }

        $argumentos += @(
            $Contenedor,
            "psql",
            "-U", "hotel_admin",
            "-d", $Base,
            "-v", "ON_ERROR_STOP=1",
            "-f", $rutaTemporal
        )

        docker exec @argumentos

        if ($LASTEXITCODE -ne 0) {
            throw "Error ejecutando $Archivo en $Base."
        }
    }
    finally {
        docker exec $Contenedor rm -f $rutaTemporal

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "No se pudo eliminar el archivo temporal $rutaTemporal."
        }
    }
}

# ============================================================
# FUNCION: VERIFICAR QUE UNA BASE ESTE VACIA
# ============================================================


function Verificar-BaseVacia {
    param($Nodo)

    $consulta = @"
SELECT
    (
        -- Tablas, vistas, secuencias y otros objetos de relacion.
        SELECT COUNT(*)
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
          AND n.nspname NOT LIKE 'pg_toast%'
          AND n.nspname NOT LIKE 'pg_temp_%'
          AND n.nspname NOT LIKE 'pg_toast_temp_%'
          AND c.relkind IN ('r','p','v','f','m','S')
    )
    +
    (
        -- Funciones y procedimientos definidos por el usuario.
        SELECT COUNT(*)
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
          AND n.nspname NOT LIKE 'pg_toast%'
          AND n.nspname NOT LIKE 'pg_temp_%'
    )
    +
    (
        -- Tipos definidos por el usuario.
        SELECT COUNT(*)
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
          AND n.nspname NOT LIKE 'pg_toast%'
          AND n.nspname NOT LIKE 'pg_temp_%'
          AND t.typtype IN ('c', 'd', 'e', 'r', 'm')
          AND t.typcategory <> 'A'
          AND NOT EXISTS (
              SELECT 1
              FROM pg_class c
              WHERE c.reltype = t.oid
          )
    )
    +
    (
        -- Esquemas personalizados.
        SELECT COUNT(*)
        FROM pg_namespace n
        WHERE n.nspname NOT IN ('pg_catalog', 'information_schema', 'public')
          AND n.nspname NOT LIKE 'pg_toast%'
          AND n.nspname NOT LIKE 'pg_temp_%'
          AND n.nspname NOT LIKE 'pg_toast_temp_%'
    )
    +
    (
        -- Publicaciones logicas.
        SELECT COUNT(*)
        FROM pg_publication
    )
    +
    (
        -- Suscripciones logicas.
        SELECT COUNT(*)
        FROM pg_subscription
    );
"@

    $resultado = docker exec $Nodo.Contenedor psql `
        -U hotel_admin `
        -d $Nodo.Base `
        -t `
        -A `
        -v ON_ERROR_STOP=1 `
        -c $consulta

    if ($LASTEXITCODE -ne 0) {
        throw "No se pudo comprobar $($Nodo.Base)."
    }

    $cantidadObjetos = [int]($resultado.Trim())

    if ($cantidadObjetos -ne 0) {
        throw "La base $($Nodo.Base) contiene $cantidadObjetos objetos de usuario. Instalacion cancelada."
    }

    Write-Host "Base $($Nodo.Base): sin objetos de usuario." -ForegroundColor Green
}

# ============================================================
# FUNCION: INSTALAR GRUPO DE ARCHIVOS SQL
# ============================================================

function Instalar-Grupo {
    param(
        [array]$Nodos,
        [array]$Archivos
    )

    foreach ($nodo in $Nodos) {
        foreach ($archivo in $Archivos) {
            Copiar-Y-Ejecutar `
                -Contenedor $nodo.Contenedor `
                -Base $nodo.Base `
                -Archivo $archivo
        }
    }
}

# ============================================================
# INICIO
# ============================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " INSTALADOR - BASE DE DATOS HOTELERA" -ForegroundColor Cyan
Write-Host " PostgreSQL 18.6" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (-not $ConfirmarInstalacionLimpia) {
    throw "Instalacion protegida. Para habilitarla usa -ConfirmarInstalacionLimpia. Solo en bases nuevas."
}

if (-not (Test-Path ".env")) {
    throw "No se encontro el archivo .env."
}

# ============================================================
# 1. COMPROBAR CONTENEDORES
# ============================================================

Write-Host "`n===== 1. COMPROBANDO CONTENEDORES =====" -ForegroundColor Cyan

foreach ($nodo in $nodos) {
    $estado = docker inspect `
        --format '{{.State.Running}}' `
        $nodo.Contenedor 2>$null

    if ($LASTEXITCODE -ne 0 -or $estado -ne "true") {
        throw "Contenedor inactivo: $($nodo.Contenedor)."
    }

    Write-Host "$($nodo.Nombre): activo." -ForegroundColor Green
}

# ============================================================
# 2. COMPROBAR BASES VACIAS
# ============================================================

Write-Host "`n===== 2. COMPROBANDO BASES DE DATOS =====" -ForegroundColor Cyan

foreach ($nodo in $nodos) {
    Write-Host "`nComprobando $($nodo.Nombre)..." -ForegroundColor Cyan
    Verificar-BaseVacia $nodo
}

Write-Host "`nLas cuatro bases estan vacias." -ForegroundColor Green

$confirmacion = Read-Host "Escribe INSTALAR para continuar"

if ($confirmacion -cne "INSTALAR") {
    throw "Instalacion cancelada por el usuario."
}

# ============================================================
# 3. ESTRUCTURA COMUN EN LOS CUATRO NODOS
# ============================================================

Write-Host "`n===== 3. ESTRUCTURA COMUN =====" -ForegroundColor Cyan

$comunes = @(
    ".\database\01_extensions\01_extensions.sql",
    ".\database\02_types\01_types.sql",
    ".\database\03_tables\01_sedes.sql",
    ".\database\03_tables\02_huespedes.sql",
    ".\database\03_tables\03_habitaciones.sql",
    ".\database\03_tables\04_inheritance.sql",
    ".\database\03_tables\05_tarifas_temporadas.sql"
)

Instalar-Grupo -Nodos $nodos -Archivos $comunes

# ============================================================
# 4. ESTRUCTURA OPERATIVA DE LAS TRES SEDES
# ============================================================

Write-Host "`n===== 4. ESTRUCTURA OPERATIVA =====" -ForegroundColor Cyan

$nodosSedes = @(
    $nodos | Where-Object {
        $_.Nombre -ne "Central"
    }
)

$operativos = @(
    ".\database\03_tables\06_reservaciones_pagos_servicios.sql",
    ".\database\04_functions\01_reservaciones.sql",
    ".\database\05_triggers\01_bitacora.sql",
    ".\database\05_triggers\02_triggers_auditoria.sql",
    ".\database\05_triggers\03_triggers_totales.sql",
    ".\database\06_views\01_vistas_operativas.sql",
    ".\database\07_indexes\01_indices_optimizacion.sql"
)

Instalar-Grupo -Nodos $nodosSedes -Archivos $operativos

# ============================================================
# 5. ESTRUCTURA DEL NODO CENTRAL
# ============================================================

Write-Host "`n===== 5. ESTRUCTURA CENTRAL =====" -ForegroundColor Cyan

$nodoCentral = $nodos | Where-Object {
    $_.Nombre -eq "Central"
}

$central = @(
    ".\database\08_partitions\01_particionar_reservaciones_central.sql",
    ".\database\08_partitions\02_tablas_auxiliares_central.sql",
    ".\database\06_views\01_vistas_operativas.sql",
    ".\database\07_indexes\01_indices_optimizacion.sql"
)

Instalar-Grupo -Nodos @($nodoCentral) -Archivos $central

# ============================================================
# 6. CONFIGURAR PUBLICACIONES EN LAS SEDES
# ============================================================

Write-Host "`n===== 6. PUBLICACIONES LOGICAS =====" -ForegroundColor Cyan

$publicaciones = @(
    ".\database\09_distributed\01_publicacion_cancun.sql",
    ".\database\09_distributed\02_publicacion_tulum.sql",
    ".\database\09_distributed\03_publicacion_bacalar.sql"
)

for ($i = 0; $i -lt 3; $i++) {
    Copiar-Y-Ejecutar `
        -Contenedor $nodosSedes[$i].Contenedor `
        -Base $nodosSedes[$i].Base `
        -Archivo $publicaciones[$i]
}

# ============================================================
# 7. CONFIGURAR FDW EN CENTRAL
# ============================================================

Write-Host "`n===== 7. CONFIGURACION FDW =====" -ForegroundColor Cyan
Write-Host "Se solicitara la contrasena para configurar FDW." -ForegroundColor Yellow

Copiar-Y-Ejecutar `
    -Contenedor $nodoCentral.Contenedor `
    -Base $nodoCentral.Base `
    -Archivo ".\database\09_distributed\04_configuracion_fdw_central.sql" `
    -Interactivo

# ============================================================
# 8. CREAR SUSCRIPCIONES LOGICAS
# ============================================================

Write-Host "`n===== 8. SUSCRIPCIONES LOGICAS =====" -ForegroundColor Cyan
Write-Host "Se solicitara la contrasena de replicacion." -ForegroundColor Yellow

Copiar-Y-Ejecutar `
    -Contenedor $nodoCentral.Contenedor `
    -Base $nodoCentral.Base `
    -Archivo ".\database\09_distributed\05_suscripciones_central.sql" `
    -Interactivo

# ============================================================
# FINALIZACION
# ============================================================

Write-Host "`n========================================" -ForegroundColor Green
Write-Host " INSTALACION FINALIZADA" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "Nodos configurados:" -ForegroundColor Cyan

foreach ($nodo in $nodos) {
    Write-Host "- $($nodo.Nombre): $($nodo.Base)" -ForegroundColor Green
}

Write-Host "`nLa estructura distribuida ha sido instalada." -ForegroundColor Green
