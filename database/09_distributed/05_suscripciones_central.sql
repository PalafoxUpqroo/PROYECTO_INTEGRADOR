
-- ============================================================
-- SUSCRIPCIONES LOGICAS: NODO CENTRAL
-- Recibe cambios de Cancun, Tulum y Bacalar.
--
-- La contrasena se solicita de forma interactiva y no se
-- almacena directamente en el archivo.
--
-- CREATE SUBSCRIPTION se ejecuta fuera de una transaccion.
-- ============================================================

\set ON_ERROR_STOP on

-- 1. Solicitar contrasena sin mostrarla en pantalla.

\prompt -s 'Contrasena de replicacion: ' replication_password

-- 2. Construir cadenas de conexion para cada sede.



SELECT format(
    'host=hotel-postgres-cancun port=5432 dbname=hotel_cancun user=hotel_admin password=%L',
    :'replication_password'
) AS conninfo_cancun
\gset

SELECT format(
    'host=hotel-postgres-tulum port=5432 dbname=hotel_tulum user=hotel_admin password=%L',
    :'replication_password'
) AS conninfo_tulum
\gset

SELECT format(
    'host=hotel-postgres-bacalar port=5432 dbname=hotel_bacalar user=hotel_admin password=%L',
    :'replication_password'
) AS conninfo_bacalar
\gset



-- 3. Crear suscripcion de Cancun si no existe.

SELECT NOT EXISTS (
    SELECT 1 FROM pg_subscription
    WHERE subname = 'sub_cancun'
) AS crear_cancun
\gset

\if :crear_cancun
    CREATE SUBSCRIPTION sub_cancun
    CONNECTION :'conninfo_cancun'
    PUBLICATION pub_central_cancun
    WITH (
        copy_data = true,
        create_slot = true,
        enabled = true,
        slot_name = 'sub_cancun'
    );
\endif

-- 4. Crear suscripcion de Tulum si no existe.

SELECT NOT EXISTS (
    SELECT 1 FROM pg_subscription
    WHERE subname = 'sub_tulum'
) AS crear_tulum
\gset

\if :crear_tulum
    CREATE SUBSCRIPTION sub_tulum
    CONNECTION :'conninfo_tulum'
    PUBLICATION pub_central_tulum
    WITH (
        copy_data = true,
        create_slot = true,
        enabled = true,
        slot_name = 'sub_tulum'
    );
\endif

-- 5. Crear suscripcion de Bacalar si no existe.

SELECT NOT EXISTS (
    SELECT 1 FROM pg_subscription
    WHERE subname = 'sub_bacalar'
) AS crear_bacalar
\gset

\if :crear_bacalar
    CREATE SUBSCRIPTION sub_bacalar
    CONNECTION :'conninfo_bacalar'
    PUBLICATION pub_central_bacalar
    WITH (
        copy_data = true,
        create_slot = true,
        enabled = true,
        slot_name = 'sub_bacalar'
    );
\endif

-- 6. Verificar el estado de las suscripciones.

SELECT
    s.subname AS suscripcion,
    s.subenabled AS habilitada,
    s.subslotname AS slot,
    s.subpublications AS publicaciones,
    r.srsubstate AS estado,
    COUNT(r.srrelid) AS tablas
FROM pg_subscription s
LEFT JOIN pg_subscription_rel r
    ON r.srsubid = s.oid
GROUP BY
    s.subname,
    s.subenabled,
    s.subslotname,
    s.subpublications,
    r.srsubstate
ORDER BY s.subname, r.srsubstate;

-- 7. Limpiar variables de contrasena y conexion.

\unset replication_password
\unset conninfo_cancun
\unset conninfo_tulum
\unset conninfo_bacalar
