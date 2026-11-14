
-- ============================================================
-- CONFIGURACION POSTGRES_FDW: NODO CENTRAL
-- Conecta el nodo central con Cancun, Tulum y Bacalar.
-- Importa 8 tablas remotas por sede (24 en total).
--
-- La contraseña se recibe por la variable de entorno FDW_PASSWORD.
-- El instalador la solicita de forma interactiva y segura; no se
-- almacena en este archivo ni en el historial de psql.
-- ============================================================

\set ON_ERROR_STOP on

\getenv fdw_password FDW_PASSWORD

\if :{?fdw_password}
\else
    \echo 'ERROR: defina la variable de entorno FDW_PASSWORD.'
    DO $$ BEGIN RAISE EXCEPTION 'FDW_PASSWORD no definida'; END $$;
\endif

-- 1. Extension para conexiones a bases de datos externas.

CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- 2. Servidores remotos.

CREATE SERVER IF NOT EXISTS fdw_cancun
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (
        host 'hotel-postgres-cancun',
        port '5432',
        dbname 'hotel_cancun'
    );

CREATE SERVER IF NOT EXISTS fdw_tulum
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (
        host 'hotel-postgres-tulum',
        port '5432',
        dbname 'hotel_tulum'
    );

CREATE SERVER IF NOT EXISTS fdw_bacalar
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (
        host 'hotel-postgres-bacalar',
        port '5432',
        dbname 'hotel_bacalar'
    );

-- 3. Esquemas locales para organizar las tablas externas.

CREATE SCHEMA IF NOT EXISTS remoto_cancun;
CREATE SCHEMA IF NOT EXISTS remoto_tulum;
CREATE SCHEMA IF NOT EXISTS remoto_bacalar;

-- 4. Mapeos de usuario.
-- La contraseña se proporciona mediante una variable de psql.
-- No escribir contrasenas directamente en este archivo.

CREATE USER MAPPING IF NOT EXISTS
    FOR hotel_admin
    SERVER fdw_cancun
    OPTIONS (
        user 'hotel_admin',
        password :'fdw_password'
    );

CREATE USER MAPPING IF NOT EXISTS
    FOR hotel_admin
    SERVER fdw_tulum
    OPTIONS (
        user 'hotel_admin',
        password :'fdw_password'
    );

CREATE USER MAPPING IF NOT EXISTS
    FOR hotel_admin
    SERVER fdw_bacalar
    OPTIONS (
        user 'hotel_admin',
        password :'fdw_password'
    );

-- 5. Importar las ocho tablas de Cancun si aun no existen.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.foreign_tables
        WHERE foreign_table_schema = 'remoto_cancun'
    ) THEN
        EXECUTE '
            IMPORT FOREIGN SCHEMA public
            LIMIT TO (
                huespedes,
                habitaciones,
                tarifas,
                temporadas,
                reservaciones,
                pagos,
                servicios,
                reservacion_servicios
            )
            FROM SERVER fdw_cancun
            INTO remoto_cancun
        ';
    END IF;
END
$$;

-- 6. Importar las ocho tablas de Tulum si aun no existen.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.foreign_tables
        WHERE foreign_table_schema = 'remoto_tulum'
    ) THEN
        EXECUTE '
            IMPORT FOREIGN SCHEMA public
            LIMIT TO (
                huespedes,
                habitaciones,
                tarifas,
                temporadas,
                reservaciones,
                pagos,
                servicios,
                reservacion_servicios
            )
            FROM SERVER fdw_tulum
            INTO remoto_tulum
        ';
    END IF;
END
$$;

-- 7. Importar las ocho tablas de Bacalar si aun no existen.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.foreign_tables
        WHERE foreign_table_schema = 'remoto_bacalar'
    ) THEN
        EXECUTE '
            IMPORT FOREIGN SCHEMA public
            LIMIT TO (
                huespedes,
                habitaciones,
                tarifas,
                temporadas,
                reservaciones,
                pagos,
                servicios,
                reservacion_servicios
            )
            FROM SERVER fdw_bacalar
            INTO remoto_bacalar
        ';
    END IF;
END
$$;

-- 8. Vista consolidada de reservaciones distribuidas.

CREATE OR REPLACE VIEW public.vw_reservaciones_distribuidas AS

SELECT
    'CANCUN'::text AS sede,
    sede_id,
    reservacion_id,
    fecha_entrada,
    fecha_salida,
    estado,
    total,
    moneda,
    observaciones
FROM remoto_cancun.reservaciones

UNION ALL

SELECT
    'TULUM'::text AS sede,
    sede_id,
    reservacion_id,
    fecha_entrada,
    fecha_salida,
    estado,
    total,
    moneda,
    observaciones
FROM remoto_tulum.reservaciones

UNION ALL

SELECT
    'BACALAR'::text AS sede,
    sede_id,
    reservacion_id,
    fecha_entrada,
    fecha_salida,
    estado,
    total,
    moneda,
    observaciones
FROM remoto_bacalar.reservaciones;

-- 9. Verificacion de servidores, esquemas y tablas externas.

SELECT
    srvname AS servidor,
    srvoptions AS configuracion
FROM pg_foreign_server
WHERE srvname IN (
    'fdw_cancun',
    'fdw_tulum',
    'fdw_bacalar'
)
ORDER BY srvname;

SELECT
    foreign_table_schema AS esquema,
    COUNT(*) AS tablas_externas
FROM information_schema.foreign_tables
WHERE foreign_table_schema IN (
    'remoto_cancun',
    'remoto_tulum',
    'remoto_bacalar'
)
GROUP BY foreign_table_schema
ORDER BY foreign_table_schema;

SELECT COUNT(*) AS total_tablas_externas
FROM information_schema.foreign_tables
WHERE foreign_table_schema IN (
    'remoto_cancun',
    'remoto_tulum',
    'remoto_bacalar'
);

\unset fdw_password