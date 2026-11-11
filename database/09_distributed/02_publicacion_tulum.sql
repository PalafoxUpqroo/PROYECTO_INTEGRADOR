
-- ============================================================
-- PUBLICACION LOGICA: TULUM
-- Destino: nodo central de reportes
-- Base de datos: hotel_tulum
-- ============================================================

BEGIN;

-- 1. Configurar identidad de replicacion.

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

-- 2. Crear publicacion si no existe.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication
        WHERE pubname = 'pub_central_tulum'
    ) THEN
        CREATE PUBLICATION pub_central_tulum
        FOR TABLE
            public.huespedes
                WHERE (sede_id = '22222222-2222-4222-8222-222222222222'),
            public.habitaciones
                WHERE (sede_id = '22222222-2222-4222-8222-222222222222'),
            public.tarifas
                WHERE (sede_id = '22222222-2222-4222-8222-222222222222'),
            public.temporadas
                WHERE (sede_id = '22222222-2222-4222-8222-222222222222'),
            public.reservaciones
                WHERE (sede_id = '22222222-2222-4222-8222-222222222222'),
            public.pagos
                WHERE (sede_id = '22222222-2222-4222-8222-222222222222'),
            public.servicios
                WHERE (sede_id = '22222222-2222-4222-8222-222222222222'),
            public.reservacion_servicios
                WHERE (sede_id = '22222222-2222-4222-8222-222222222222')
        WITH (
            publish = 'insert, update, delete'
        );
    END IF;
END
$$;

COMMIT;

-- 3. Verificar publicacion.

SELECT
    pubname,
    schemaname,
    tablename,
    rowfilter
FROM pg_publication_tables
WHERE pubname = 'pub_central_tulum'
ORDER BY tablename;
