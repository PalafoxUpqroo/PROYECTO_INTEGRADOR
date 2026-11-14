-- ============================================================
-- DATOS DEMO REPRODUCIBLES
--
-- Este archivo se ejecuta una vez por sede. La sede se indica con
-- la variable de sesion hotel.sede, por ejemplo:
--
--   PGOPTIONS="-c hotel.sede=cancun" psql -f 01_datos_demo.sql
--
-- El script es idempotente: se puede ejecutar varias veces sin
-- duplicar huespedes, habitaciones, tarifas ni reservaciones.
-- No se debe mezclar con la instalacion estructural.
-- ============================================================

\set ON_ERROR_STOP on

DO $$
DECLARE
    v_sede TEXT := COALESCE(current_setting('hotel.sede', true), '');
BEGIN
    IF v_sede NOT IN ('cancun', 'tulum', 'bacalar') THEN
        RAISE EXCEPTION
            'Sede no valida. Use PGOPTIONS="-c hotel.sede=cancun|tulum|bacalar".';
    END IF;

    -- ========================================================
    -- CANCUN
    -- ========================================================
    IF v_sede = 'cancun' THEN

        INSERT INTO huespedes (
            huesped_id, sede_id, nombre, apellido, correo,
            preferencias, tipo_huesped
        )
        VALUES (
            'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
            '11111111-1111-4111-8111-111111111111',
            'Huesped', 'Prueba CANCUN', 'prueba.distribuida.cancun@hotel.test',
            '{"origen": "datos_demo"}'::jsonb, 'INDIVIDUAL'
        )
        ON CONFLICT (huesped_id) DO NOTHING;

        INSERT INTO huesped_individual (
            huesped_id, fecha_nacimiento, documento_identidad, observaciones
        )
        VALUES (
            'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
            '1990-05-15', 'DEMO-CANCUN-001', 'Huesped individual de demostracion'
        )
        ON CONFLICT (huesped_id) DO NOTHING;

        INSERT INTO huespedes (
            huesped_id, sede_id, nombre, apellido, correo,
            preferencias, tipo_huesped
        )
        VALUES (
            'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaae',
            '11111111-1111-4111-8111-111111111111',
            'Empresa', 'Demo Cancun', 'empresa.demo.cancun@hotel.test',
            '{"origen": "datos_demo"}'::jsonb, 'CORPORATIVO'
        )
        ON CONFLICT (huesped_id) DO NOTHING;

        INSERT INTO huesped_corporativo (
            huesped_id, razon_social, rfc, contacto_empresa, observaciones
        )
        VALUES (
            'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaae',
            'Empresa Demo Cancun SA de CV', 'EDC010101ABC',
            'Contacto Corporativo', 'Huesped corporativo de demostracion'
        )
        ON CONFLICT (huesped_id) DO NOTHING;

        INSERT INTO habitaciones (
            habitacion_id, sede_id, numero, piso, capacidad,
            estado, tipo_habitacion, amenidades
        )
        VALUES (
            'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
            '11111111-1111-4111-8111-111111111111',
            'P-DIST-01', 1, 2, 'DISPONIBLE', 'ESTANDAR',
            ARRAY['WIFI', 'AIRE_ACONDICIONADO']::text[]
        )
        ON CONFLICT (habitacion_id) DO NOTHING;

        INSERT INTO habitacion_estandar (
            habitacion_id, numero_camas, descripcion
        )
        VALUES (
            'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 2,
            'Habitacion estandar de demostracion'
        )
        ON CONFLICT (habitacion_id) DO NOTHING;

        INSERT INTO habitaciones (
            habitacion_id, sede_id, numero, piso, capacidad,
            estado, tipo_habitacion, amenidades
        )
        VALUES (
            'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbf',
            '11111111-1111-4111-8111-111111111111',
            'P-SUITE-01', 2, 3, 'DISPONIBLE', 'SUITE',
            ARRAY['WIFI', 'AIRE_ACONDICIONADO', 'JACUZZI']::text[]
        )
        ON CONFLICT (habitacion_id) DO NOTHING;

        INSERT INTO habitacion_suite (
            habitacion_id, tiene_sala, tiene_jacuzzi, descripcion
        )
        VALUES (
            'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbf',
            TRUE, TRUE, 'Suite de demostracion'
        )
        ON CONFLICT (habitacion_id) DO NOTHING;

        INSERT INTO tarifas (
            tarifa_id, sede_id, tipo_habitacion, nombre,
            precio_noche, moneda, fecha_inicio, fecha_fin, activa
        )
        VALUES (
            'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
            '11111111-1111-4111-8111-111111111111',
            'ESTANDAR', 'TARIFA PRUEBA DISTRIBUIDA',
            1200.00, 'MXN', '2026-01-01', '2027-12-31', TRUE
        )
        ON CONFLICT (tarifa_id) DO NOTHING;

        INSERT INTO tarifas (
            tarifa_id, sede_id, tipo_habitacion, nombre,
            precio_noche, moneda, fecha_inicio, fecha_fin, activa
        )
        VALUES (
            'cccccccc-cccc-4ccc-8ccc-cccccccccccf',
            '11111111-1111-4111-8111-111111111111',
            'SUITE', 'TARIFA SUITE DEMO CANCUN',
            2500.00, 'MXN', '2026-01-01', '2027-12-31', TRUE
        )
        ON CONFLICT (tarifa_id) DO NOTHING;

        INSERT INTO reservaciones (
            reservacion_id, sede_id, huesped_id, habitacion_id, tarifa_id,
            fecha_entrada, fecha_salida, numero_huespedes, estado,
            total, total_alojamiento, total_pagado, moneda, observaciones
        )
        SELECT
            'd0000000-0000-4000-8000-000000000001',
            '11111111-1111-4111-8111-111111111111',
            'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
            'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
            'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
            DATE '2027-06-10', DATE '2027-06-13', 2, 'CONFIRMADA',
            3600.00, 3600.00, 0, 'MXN', 'DEMO_SEED_CANCUN'
        WHERE NOT EXISTS (
            SELECT 1
            FROM reservaciones r
            WHERE r.sede_id = '11111111-1111-4111-8111-111111111111'
              AND r.habitacion_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
              AND r.estado IN ('PENDIENTE', 'CONFIRMADA', 'CHECK_IN')
              AND r.periodo && daterange(DATE '2027-06-10', DATE '2027-06-13', '[)')
        )
        ON CONFLICT (reservacion_id) DO NOTHING;

        INSERT INTO reservaciones (
            reservacion_id, sede_id, huesped_id, habitacion_id, tarifa_id,
            fecha_entrada, fecha_salida, numero_huespedes, estado,
            total, total_alojamiento, total_pagado, moneda, observaciones
        )
        SELECT
            'd0000000-0000-4000-8000-000000000004',
            '11111111-1111-4111-8111-111111111111',
            'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaae',
            'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbf',
            'cccccccc-cccc-4ccc-8ccc-cccccccccccf',
            DATE '2027-09-10', DATE '2027-09-12', 2, 'CONFIRMADA',
            5000.00, 5000.00, 0, 'MXN', 'DEMO_SEED_CANCUN_SUITE'
        WHERE NOT EXISTS (
            SELECT 1
            FROM reservaciones r
            WHERE r.sede_id = '11111111-1111-4111-8111-111111111111'
              AND r.habitacion_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbf'
              AND r.estado IN ('PENDIENTE', 'CONFIRMADA', 'CHECK_IN')
              AND r.periodo && daterange(DATE '2027-09-10', DATE '2027-09-12', '[)')
        )
        ON CONFLICT (reservacion_id) DO NOTHING;

    -- ========================================================
    -- TULUM
    -- ========================================================
    ELSIF v_sede = 'tulum' THEN

        INSERT INTO huespedes (
            huesped_id, sede_id, nombre, apellido, correo,
            preferencias, tipo_huesped
        )
        VALUES (
            'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaab',
            '22222222-2222-4222-8222-222222222222',
            'Huesped', 'Prueba TULUM', 'prueba.distribuida.tulum@hotel.test',
            '{"origen": "datos_demo"}'::jsonb, 'INDIVIDUAL'
        )
        ON CONFLICT (huesped_id) DO NOTHING;

        INSERT INTO huesped_individual (
            huesped_id, fecha_nacimiento, documento_identidad, observaciones
        )
        VALUES (
            'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaab',
            '1988-08-20', 'DEMO-TULUM-001', 'Huesped individual de demostracion'
        )
        ON CONFLICT (huesped_id) DO NOTHING;

        INSERT INTO huespedes (
            huesped_id, sede_id, nombre, apellido, correo,
            preferencias, tipo_huesped
        )
        VALUES (
            'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaad',
            '22222222-2222-4222-8222-222222222222',
            'Huesped', 'Traslado 2PC', 'traslado.2pc@hotel.test',
            '{"origen": "datos_demo"}'::jsonb, 'INDIVIDUAL'
        )
        ON CONFLICT (huesped_id) DO NOTHING;

        INSERT INTO huesped_individual (
            huesped_id, fecha_nacimiento, documento_identidad, observaciones
        )
        VALUES (
            'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaad',
            '1992-03-10', 'DEMO-TULUM-002', 'Huesped para traslado 2PC'
        )
        ON CONFLICT (huesped_id) DO NOTHING;

        INSERT INTO habitaciones (
            habitacion_id, sede_id, numero, piso, capacidad,
            estado, tipo_habitacion, amenidades
        )
        VALUES
        (
            'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbc',
            '22222222-2222-4222-8222-222222222222',
            'P-DIST-01', 1, 2, 'DISPONIBLE', 'ESTANDAR',
            ARRAY['WIFI', 'AIRE_ACONDICIONADO']::text[]
        ),
        (
            'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbe',
            '22222222-2222-4222-8222-222222222222',
            'P-2PC-01', 1, 2, 'DISPONIBLE', 'ESTANDAR',
            ARRAY['WIFI', 'AIRE_ACONDICIONADO']::text[]
        )
        ON CONFLICT (habitacion_id) DO NOTHING;

        INSERT INTO habitacion_estandar (
            habitacion_id, numero_camas, descripcion
        )
        VALUES
        (
            'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbc',
            2, 'Habitacion estandar de demostracion'
        ),
        (
            'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbe',
            2, 'Habitacion destino para prueba 2PC'
        )
        ON CONFLICT (habitacion_id) DO NOTHING;

        INSERT INTO tarifas (
            tarifa_id, sede_id, tipo_habitacion, nombre,
            precio_noche, moneda, fecha_inicio, fecha_fin, activa
        )
        VALUES (
            'cccccccc-cccc-4ccc-8ccc-cccccccccccd',
            '22222222-2222-4222-8222-222222222222',
            'ESTANDAR', 'TARIFA PRUEBA DISTRIBUIDA',
            1200.00, 'MXN', '2026-01-01', '2027-12-31', TRUE
        )
        ON CONFLICT (tarifa_id) DO NOTHING;

        INSERT INTO reservaciones (
            reservacion_id, sede_id, huesped_id, habitacion_id, tarifa_id,
            fecha_entrada, fecha_salida, numero_huespedes, estado,
            total, total_alojamiento, total_pagado, moneda, observaciones
        )
        SELECT
            'd0000000-0000-4000-8000-000000000002',
            '22222222-2222-4222-8222-222222222222',
            'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaab',
            'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbc',
            'cccccccc-cccc-4ccc-8ccc-cccccccccccd',
            DATE '2027-07-01', DATE '2027-07-04', 2, 'CONFIRMADA',
            3600.00, 3600.00, 0, 'MXN', 'DEMO_SEED_TULUM'
        WHERE NOT EXISTS (
            SELECT 1
            FROM reservaciones r
            WHERE r.sede_id = '22222222-2222-4222-8222-222222222222'
              AND r.habitacion_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbc'
              AND r.estado IN ('PENDIENTE', 'CONFIRMADA', 'CHECK_IN')
              AND r.periodo && daterange(DATE '2027-07-01', DATE '2027-07-04', '[)')
        )
        ON CONFLICT (reservacion_id) DO NOTHING;

    -- ========================================================
    -- BACALAR
    -- ========================================================
    ELSIF v_sede = 'bacalar' THEN

        INSERT INTO huespedes (
            huesped_id, sede_id, nombre, apellido, correo,
            preferencias, tipo_huesped
        )
        VALUES (
            'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaac',
            '33333333-3333-4333-8333-333333333333',
            'Huesped', 'Prueba BACALAR', 'prueba.distribuida.bacalar@hotel.test',
            '{"origen": "datos_demo"}'::jsonb, 'INDIVIDUAL'
        )
        ON CONFLICT (huesped_id) DO NOTHING;

        INSERT INTO huesped_individual (
            huesped_id, fecha_nacimiento, documento_identidad, observaciones
        )
        VALUES (
            'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaac',
            '1985-11-02', 'DEMO-BACALAR-001', 'Huesped individual de demostracion'
        )
        ON CONFLICT (huesped_id) DO NOTHING;

        INSERT INTO habitaciones (
            habitacion_id, sede_id, numero, piso, capacidad,
            estado, tipo_habitacion, amenidades
        )
        VALUES (
            'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbd',
            '33333333-3333-4333-8333-333333333333',
            'P-DIST-01', 1, 2, 'DISPONIBLE', 'ESTANDAR',
            ARRAY['WIFI', 'AIRE_ACONDICIONADO']::text[]
        )
        ON CONFLICT (habitacion_id) DO NOTHING;

        INSERT INTO habitacion_estandar (
            habitacion_id, numero_camas, descripcion
        )
        VALUES (
            'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbd',
            2, 'Habitacion estandar de demostracion'
        )
        ON CONFLICT (habitacion_id) DO NOTHING;

        INSERT INTO tarifas (
            tarifa_id, sede_id, tipo_habitacion, nombre,
            precio_noche, moneda, fecha_inicio, fecha_fin, activa
        )
        VALUES (
            'cccccccc-cccc-4ccc-8ccc-ccccccccccce',
            '33333333-3333-4333-8333-333333333333',
            'ESTANDAR', 'TARIFA PRUEBA DISTRIBUIDA',
            1200.00, 'MXN', '2026-01-01', '2027-12-31', TRUE
        )
        ON CONFLICT (tarifa_id) DO NOTHING;

        INSERT INTO reservaciones (
            reservacion_id, sede_id, huesped_id, habitacion_id, tarifa_id,
            fecha_entrada, fecha_salida, numero_huespedes, estado,
            total, total_alojamiento, total_pagado, moneda, observaciones
        )
        SELECT
            'd0000000-0000-4000-8000-000000000003',
            '33333333-3333-4333-8333-333333333333',
            'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaac',
            'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbd',
            'cccccccc-cccc-4ccc-8ccc-ccccccccccce',
            DATE '2027-08-01', DATE '2027-08-04', 2, 'CONFIRMADA',
            3600.00, 3600.00, 0, 'MXN', 'DEMO_SEED_BACALAR'
        WHERE NOT EXISTS (
            SELECT 1
            FROM reservaciones r
            WHERE r.sede_id = '33333333-3333-4333-8333-333333333333'
              AND r.habitacion_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbd'
              AND r.estado IN ('PENDIENTE', 'CONFIRMADA', 'CHECK_IN')
              AND r.periodo && daterange(DATE '2027-08-01', DATE '2027-08-04', '[)')
        )
        ON CONFLICT (reservacion_id) DO NOTHING;

    END IF;
END
$$;

-- Resumen de control de la sede cargada.
SELECT current_setting('hotel.sede', true) AS sede,
       (SELECT COUNT(*) FROM huespedes) AS huespedes,
       (SELECT COUNT(*) FROM habitaciones) AS habitaciones,
       (SELECT COUNT(*) FROM tarifas) AS tarifas,
       (SELECT COUNT(*) FROM reservaciones) AS reservaciones;