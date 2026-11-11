
-- ============================================================
-- PROYECTO: HOTEL DISTRIBUIDO
-- ARCHIVO: 01_particionar_reservaciones_central.sql
-- OBJETIVO:
-- Crear la tabla central de reservaciones particionada
-- por sede, con tres particiones: Cancun, Tulum y Bacalar.
--
-- IMPORTANTE:
-- Ejecutar solamente durante la instalacion inicial,
-- despues de crear las tablas sedes, huespedes,
-- habitaciones y tarifas.
-- No ejecutar sobre una instalacion ya configurada.
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. INDICES UNICOS PARA RELACIONES POR SEDE
-- ------------------------------------------------------------

CREATE UNIQUE INDEX IF NOT EXISTS uq_huespedes_sede_id
    ON public.huespedes (sede_id, huesped_id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_habitaciones_sede_id
    ON public.habitaciones (sede_id, habitacion_id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_tarifas_sede_id
    ON public.tarifas (sede_id, tarifa_id);

-- ------------------------------------------------------------
-- 2. TABLA PADRE PARTICIONADA
-- ------------------------------------------------------------

CREATE TABLE public.reservaciones (
    reservacion_id UUID DEFAULT gen_random_uuid() NOT NULL,
    sede_id UUID NOT NULL,
    huesped_id UUID NOT NULL,
    habitacion_id UUID NOT NULL,
    tarifa_id UUID NOT NULL,

    fecha_entrada DATE NOT NULL,
    fecha_salida DATE NOT NULL,

    periodo DATERANGE GENERATED ALWAYS AS (
        daterange(fecha_entrada, fecha_salida, '[)')
    ) STORED,

    numero_huespedes SMALLINT DEFAULT 1 NOT NULL,
    estado VARCHAR(20) DEFAULT 'PENDIENTE' NOT NULL,
    total NUMERIC(12,2) DEFAULT 0 NOT NULL,
    moneda CHAR(3) DEFAULT 'MXN' NOT NULL,
    fecha_creacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    observaciones TEXT,

    total_alojamiento NUMERIC(12,2) DEFAULT 0 NOT NULL,
    total_pagado NUMERIC(12,2) DEFAULT 0 NOT NULL,

    saldo_pendiente NUMERIC(12,2)
        GENERATED ALWAYS AS (total - total_pagado) STORED,

    CONSTRAINT reservaciones_pkey
        PRIMARY KEY (sede_id, reservacion_id),

    CONSTRAINT chk_reservacion_estado
        CHECK (estado IN (
            'PENDIENTE',
            'CONFIRMADA',
            'CHECK_IN',
            'FINALIZADA',
            'CANCELADA'
        )),

    CONSTRAINT chk_reservacion_fechas
        CHECK (fecha_salida > fecha_entrada),

    CONSTRAINT chk_reservacion_huespedes
        CHECK (numero_huespedes > 0),

    CONSTRAINT chk_reservacion_moneda
        CHECK (moneda IN ('MXN', 'USD')),

    CONSTRAINT chk_reservacion_total
        CHECK (total >= 0),

    CONSTRAINT chk_reservacion_total_alojamiento
        CHECK (total_alojamiento >= 0),

    CONSTRAINT chk_reservacion_total_pagado
        CHECK (total_pagado >= 0 AND total_pagado <= total),

    CONSTRAINT reservaciones_sede_id_fkey
        FOREIGN KEY (sede_id)
        REFERENCES public.sedes(sede_id),

    CONSTRAINT fk_reservacion_huesped
        FOREIGN KEY (sede_id, huesped_id)
        REFERENCES public.huespedes(sede_id, huesped_id),

    CONSTRAINT fk_reservacion_habitacion
        FOREIGN KEY (sede_id, habitacion_id)
        REFERENCES public.habitaciones(sede_id, habitacion_id),

    CONSTRAINT fk_reservacion_tarifa
        FOREIGN KEY (sede_id, tarifa_id)
        REFERENCES public.tarifas(sede_id, tarifa_id)
)
PARTITION BY LIST (sede_id);

-- ------------------------------------------------------------
-- 3. PARTICIONES POR SEDE
-- ------------------------------------------------------------

CREATE TABLE public.reservaciones_cancun
PARTITION OF public.reservaciones
FOR VALUES IN ('11111111-1111-4111-8111-111111111111');

CREATE TABLE public.reservaciones_tulum
PARTITION OF public.reservaciones
FOR VALUES IN ('22222222-2222-4222-8222-222222222222');

CREATE TABLE public.reservaciones_bacalar
PARTITION OF public.reservaciones
FOR VALUES IN ('33333333-3333-4333-8333-333333333333');

-- ------------------------------------------------------------
-- 4. INDICES DE LA TABLA PADRE
-- PostgreSQL crea los indices correspondientes en cada
-- particion y mantiene su asociacion.
-- ------------------------------------------------------------

CREATE INDEX idx_reservaciones_estado
ON public.reservaciones (estado);

CREATE INDEX idx_reservaciones_fechas
ON public.reservaciones USING GIST (periodo);

CREATE INDEX idx_reservaciones_huesped
ON public.reservaciones (huesped_id);

CREATE INDEX idx_reservaciones_sede_estado_entrada
ON public.reservaciones (sede_id, estado, fecha_entrada);

COMMIT;

-- ------------------------------------------------------------
-- 5. VERIFICACION DE PARTICIONES
-- ------------------------------------------------------------

SELECT
    hijo.relname AS particion,
    pg_get_expr(hijo.relpartbound, hijo.oid) AS limite
FROM pg_inherits i
JOIN pg_class padre ON padre.oid = i.inhparent
JOIN pg_class hijo ON hijo.oid = i.inhrelid
JOIN pg_namespace n ON n.oid = padre.relnamespace
WHERE n.nspname = 'public'
  AND padre.relname = 'reservaciones'
ORDER BY hijo.relname;

-- ------------------------------------------------------------
-- 6. VERIFICACION DE INDICES
-- ------------------------------------------------------------

SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'reservaciones'
ORDER BY indexname;
