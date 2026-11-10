
-- ============================================================
-- GENERACION DE 50,000 RESERVACIONES PARA PRUEBAS
-- Proyecto: Base de datos distribuida hotelera
-- Nodo: Cancun
-- Identificador: PRUEBA_RENDIMIENTO_20261110
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. CREAR 100 HUESPEDES DE PRUEBA
-- ------------------------------------------------------------

INSERT INTO huespedes (
    huesped_id,
    sede_id,
    nombre,
    apellido,
    correo,
    tipo_huesped
)
SELECT
    md5('hotel-perf-guest-' || lpad(n::text, 3, '0'))::uuid,
    '11111111-1111-4111-8111-111111111111'::uuid,
    'Huesped',
    'Prueba ' || n,
    'perf' || lpad(n::text, 3, '0') || '@example.test',
    'INDIVIDUAL'
FROM generate_series(1, 100) AS n;

-- ------------------------------------------------------------
-- 2. CREAR 100 HABITACIONES DE PRUEBA
-- ------------------------------------------------------------

INSERT INTO habitaciones (
    habitacion_id,
    sede_id,
    numero,
    piso,
    capacidad,
    estado,
    tipo_habitacion,
    amenidades
)
SELECT
    md5('hotel-perf-room-' || lpad(n::text, 3, '0'))::uuid,
    '11111111-1111-4111-8111-111111111111'::uuid,
    'P' || lpad(n::text, 3, '0'),
    ((n - 1) / 20) + 1,
    2,
    'DISPONIBLE',
    'ESTANDAR',
    ARRAY['WIFI', 'AIRE_ACONDICIONADO']
FROM generate_series(1, 100) AS n;

-- ------------------------------------------------------------
-- 3. CREAR UNA TARIFA DE PRUEBA
-- ------------------------------------------------------------

INSERT INTO tarifas (
    tarifa_id,
    sede_id,
    tipo_habitacion,
    nombre,
    precio_noche,
    moneda,
    fecha_inicio,
    fecha_fin,
    activa
)
VALUES (
    md5('hotel-perf-tariff-001')::uuid,
    '11111111-1111-4111-8111-111111111111'::uuid,
    'ESTANDAR',
    'TARIFA_PRUEBA_RENDIMIENTO',
    1000.00,
    'MXN',
    '2019-01-01',
    '2025-01-01',
    TRUE
);

-- ------------------------------------------------------------
-- 4. GENERAR 50,000 RESERVACIONES
-- ------------------------------------------------------------
-- Cada habitación recibe una reservación por día.
-- Las fechas no se traslapan.
-- FINALIZADA no participa en la restricción parcial GiST.
-- ------------------------------------------------------------

INSERT INTO reservaciones (
    sede_id,
    huesped_id,
    habitacion_id,
    tarifa_id,
    fecha_entrada,
    fecha_salida,
    numero_huespedes,
    estado,
    total,
    moneda,
    observaciones,
    total_alojamiento,
    total_pagado
)
SELECT
    '11111111-1111-4111-8111-111111111111'::uuid,

    md5(
        'hotel-perf-guest-' ||
        lpad((((n - 1) % 100) + 1)::text, 3, '0')
    )::uuid,

    md5(
        'hotel-perf-room-' ||
        lpad((((n - 1) % 100) + 1)::text, 3, '0')
    )::uuid,

    md5('hotel-perf-tariff-001')::uuid,

    DATE '2020-01-01' + (((n - 1) / 100)::integer),

    DATE '2020-01-02' + (((n - 1) / 100)::integer),

    1,
    'FINALIZADA',
    1000.00,
    'MXN',
    'PRUEBA_RENDIMIENTO_20261110',
    1000.00,
    0.00

FROM generate_series(1, 50000) AS n;

-- ------------------------------------------------------------
-- 5. ACTUALIZAR ESTADISTICAS
-- ------------------------------------------------------------

ANALYZE huespedes;
ANALYZE habitaciones;
ANALYZE tarifas;
ANALYZE reservaciones;

COMMIT;

-- ------------------------------------------------------------
-- 6. COMPROBAR RESULTADO
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_reservaciones_prueba,
    MIN(fecha_entrada) AS primera_fecha,
    MAX(fecha_salida) AS ultima_fecha,
    COUNT(DISTINCT habitacion_id) AS habitaciones_utilizadas,
    COUNT(DISTINCT huesped_id) AS huespedes_utilizados
FROM reservaciones
WHERE observaciones = 'PRUEBA_RENDIMIENTO_20261110';
