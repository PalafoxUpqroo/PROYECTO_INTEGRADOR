
-- ============================================================
-- PUBLICACION LOGICA: CANCUN
-- Destino: nodo central de reportes
-- Base de datos: hotel_cancun
-- ============================================================

BEGIN;

-- 1. Configurar identidad de replicacion mediante indices unicos.

ALTER TABLE public.huespedes
    REPLICA IDENTITY USING INDEX uq_huespedes_sede_id;

ALTER TABLE public.habitaciones
    REPLICA IDENTITY USING INDEX uq_habitaciones_sede_id;

ALTER TABLE public.tarifas
    REPLICA IDENTITY USING INDEX uq_tarifas_sede_id;

ALTER TABLE public.temporadas
    REPLICA IDENTITY USING INDEX uq_temporadas_sede_id;

ALTER TABLE public.reservaciones
    REPLICA IDENTITY USING INDEX uq_reservaciones_sede_id;

ALTER TABLE public.pagos
    REPLICA IDENTITY USING INDEX uq_pagos_sede_id;

ALTER TABLE public.servicios
    REPLICA IDENTITY USING INDEX uq_servicios_sede_id;

ALTER TABLE public.reservacion_servicios
    REPLICA IDENTITY USING INDEX uq_reservacion_servicios_sede_id;

-- 2. Crear publicacion si todavia no existe.
-- En una instalacion limpia, publicara exclusivamente
-- los registros pertenecientes a la sede Cancun.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication
        WHERE pubname = 'pub_central_cancun'
    ) THEN
        CREATE PUBLICATION pub_central_cancun
        FOR TABLE
            public.huespedes
                WHERE (sede_id = '11111111-1111-4111-8111-111111111111'),
            public.habitaciones
                WHERE (sede_id = '11111111-1111-4111-8111-111111111111'),
            public.tarifas
                WHERE (sede_id = '11111111-1111-4111-8111-111111111111'),
            public.temporadas
                WHERE (sede_id = '11111111-1111-4111-8111-111111111111'),
            public.reservaciones
                WHERE (sede_id = '11111111-1111-4111-8111-111111111111'),
            public.pagos
                WHERE (sede_id = '11111111-1111-4111-8111-111111111111'),
            public.servicios
                WHERE (sede_id = '11111111-1111-4111-8111-111111111111'),
            public.reservacion_servicios
                WHERE (sede_id = '11111111-1111-4111-8111-111111111111')
        WITH (
            publish = 'insert, update, delete'
        );
    END IF;
END
$$;

COMMIT;

-- 3. Consulta de verificacion.

SELECT
    pubname,
    schemaname,
    tablename,
    rowfilter
FROM pg_publication_tables
WHERE pubname = 'pub_central_cancun'
ORDER BY tablename;
