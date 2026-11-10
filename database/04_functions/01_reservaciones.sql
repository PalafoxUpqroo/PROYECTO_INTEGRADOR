
-- ============================================================
-- PROYECTO: BASE DE DATOS DISTRIBUIDA HOTELERA
-- ARCHIVO: 01_reservaciones.sql
-- DESCRIPCION: Funciones principales de reservaciones
-- ============================================================

-- ------------------------------------------------------------
-- 1. CREAR RESERVACION
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_crear_reservacion(
    p_sede_id UUID,
    p_huesped_id UUID,
    p_habitacion_id UUID,
    p_tarifa_id UUID,
    p_fecha_entrada DATE,
    p_fecha_salida DATE,
    p_numero_huespedes SMALLINT DEFAULT 1,
    p_estado VARCHAR DEFAULT 'CONFIRMADA',
    p_observaciones TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_capacidad INTEGER;
    v_estado_habitacion VARCHAR(20);
    v_tipo_habitacion VARCHAR(20);
    v_precio NUMERIC(10,2);
    v_moneda CHAR(3);
    v_total NUMERIC(12,2);
    v_reservacion_id UUID;
    v_noches INTEGER;
BEGIN
    -- Validar fechas.
    IF p_fecha_salida <= p_fecha_entrada THEN
        RAISE EXCEPTION
            'La fecha de salida debe ser posterior a la entrada';
    END IF;

    -- Validar numero de huespedes.
    IF p_numero_huespedes <= 0 THEN
        RAISE EXCEPTION
            'El numero de huespedes debe ser mayor que cero';
    END IF;

    -- Validar estado inicial.
    IF p_estado NOT IN ('PENDIENTE', 'CONFIRMADA') THEN
        RAISE EXCEPTION
            'Estado inicial no permitido: %', p_estado;
    END IF;

    -- Bloquear la habitacion para evitar operaciones
    -- simultaneas sobre la misma habitacion.
    SELECT capacidad, estado, tipo_habitacion
    INTO v_capacidad, v_estado_habitacion, v_tipo_habitacion
    FROM habitaciones
    WHERE habitacion_id = p_habitacion_id
      AND sede_id = p_sede_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'La habitacion no existe en la sede indicada';
    END IF;

    -- Validar disponibilidad operativa de la habitacion.
    IF v_estado_habitacion IN ('MANTENIMIENTO', 'FUERA_SERVICIO') THEN
        RAISE EXCEPTION
            'La habitacion no esta habilitada para reservaciones';
    END IF;

    -- Validar capacidad.
    IF p_numero_huespedes > v_capacidad THEN
        RAISE EXCEPTION
            'La capacidad de la habitacion es %, pero se solicitaron % huespedes',
            v_capacidad, p_numero_huespedes;
    END IF;

    -- Validar que exista el huesped en la misma sede.
    PERFORM 1
    FROM huespedes
    WHERE huesped_id = p_huesped_id
      AND sede_id = p_sede_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'El huesped no existe en la sede indicada';
    END IF;

    -- Consultar tarifa y validar vigencia y tipo.
    SELECT precio_noche, moneda
    INTO v_precio, v_moneda
    FROM tarifas
    WHERE tarifa_id = p_tarifa_id
      AND sede_id = p_sede_id
      AND tipo_habitacion = v_tipo_habitacion
      AND activa = TRUE
      AND fecha_inicio <= p_fecha_entrada
      AND fecha_fin >= p_fecha_salida - 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'No existe una tarifa activa y vigente para la habitacion y fechas indicadas';
    END IF;

    -- Calcular importe.
    v_noches := p_fecha_salida - p_fecha_entrada;
    v_total := v_precio * v_noches;

    -- Registrar reservacion.
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
        observaciones
    )
    VALUES (
        p_sede_id,
        p_huesped_id,
        p_habitacion_id,
        p_tarifa_id,
        p_fecha_entrada,
        p_fecha_salida,
        p_numero_huespedes,
        p_estado,
        v_total,
        v_moneda,
        p_observaciones
    )
    RETURNING reservacion_id INTO v_reservacion_id;

    RETURN v_reservacion_id;
END;
$$;



-- ------------------------------------------------------------
-- 2. REALIZAR CHECK-IN
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_realizar_checkin(
    p_reservacion_id UUID,
    p_fecha_checkin DATE DEFAULT CURRENT_DATE
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_sede_id UUID;
    v_habitacion_id UUID;
    v_fecha_entrada DATE;
    v_fecha_salida DATE;
    v_estado_habitacion VARCHAR(20);
BEGIN
    -- Bloquear la reservacion para evitar cambios simultaneos.
    SELECT sede_id, habitacion_id, fecha_entrada, fecha_salida
    INTO v_sede_id, v_habitacion_id, v_fecha_entrada, v_fecha_salida
    FROM reservaciones
    WHERE reservacion_id = p_reservacion_id
      AND estado = 'CONFIRMADA'
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'La reservacion no existe o no esta confirmada';
    END IF;

    -- Validar que el check-in corresponda al periodo reservado.
    IF p_fecha_checkin < v_fecha_entrada
       OR p_fecha_checkin >= v_fecha_salida THEN
        RAISE EXCEPTION
            'La fecha de check-in esta fuera del periodo reservado';
    END IF;

    -- Bloquear la habitacion y verificar su estado operativo.
    SELECT estado
    INTO v_estado_habitacion
    FROM habitaciones
    WHERE habitacion_id = v_habitacion_id
      AND sede_id = v_sede_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'No se encontro la habitacion de la reservacion';
    END IF;

    IF v_estado_habitacion IN ('MANTENIMIENTO', 'FUERA_SERVICIO') THEN
        RAISE EXCEPTION
            'No se puede realizar check-in: la habitacion no esta habilitada';
    END IF;

    -- Cambiar el estado de la reservacion.
    UPDATE reservaciones
    SET estado = 'CHECK_IN'
    WHERE reservacion_id = p_reservacion_id;

    -- Marcar la habitacion como ocupada.
    UPDATE habitaciones
    SET estado = 'OCUPADA'
    WHERE habitacion_id = v_habitacion_id
      AND sede_id = v_sede_id;

    RETURN TRUE;
END;
$$;



-- ------------------------------------------------------------
-- 3. REALIZAR CHECK-OUT
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_realizar_checkout(
    p_reservacion_id UUID,
    p_fecha_checkout DATE DEFAULT CURRENT_DATE
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_sede_id UUID;
    v_habitacion_id UUID;
    v_fecha_entrada DATE;
    v_fecha_salida DATE;
BEGIN
    -- Bloquear la reservacion.
    SELECT sede_id, habitacion_id, fecha_entrada, fecha_salida
    INTO v_sede_id, v_habitacion_id, v_fecha_entrada, v_fecha_salida
    FROM reservaciones
    WHERE reservacion_id = p_reservacion_id
      AND estado = 'CHECK_IN'
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'La reservacion no existe o no tiene check-in registrado';
    END IF;

    -- Validar que la salida este dentro del periodo reservado.
    IF p_fecha_checkout < v_fecha_entrada
       OR p_fecha_checkout > v_fecha_salida THEN
        RAISE EXCEPTION
            'La fecha de checkout debe estar entre la entrada y la salida reservadas';
    END IF;

    -- Bloquear la habitacion antes de modificar su estado.
    PERFORM 1
    FROM habitaciones
    WHERE habitacion_id = v_habitacion_id
      AND sede_id = v_sede_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'No se encontro la habitacion de la reservacion';
    END IF;

    -- Finalizar la reservacion.
    UPDATE reservaciones
    SET estado = 'FINALIZADA'
    WHERE reservacion_id = p_reservacion_id;

    -- Mantener la habitacion ocupada solamente si existe
    -- otra reservacion con check-in activo en esa fecha.
    UPDATE habitaciones h
    SET estado = CASE
        WHEN EXISTS (
            SELECT 1
            FROM reservaciones r
            WHERE r.habitacion_id = v_habitacion_id
              AND r.sede_id = v_sede_id
              AND r.estado = 'CHECK_IN'
              AND r.periodo @> p_fecha_checkout
        )
        THEN 'OCUPADA'
        ELSE 'DISPONIBLE'
    END
    WHERE h.habitacion_id = v_habitacion_id
      AND h.sede_id = v_sede_id;

    RETURN TRUE;
END;
$$;


-- ------------------------------------------------------------
-- 4. CANCELAR RESERVACION
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_cancelar_reservacion(
    p_reservacion_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE reservaciones
    SET estado = 'CANCELADA'
    WHERE reservacion_id = p_reservacion_id
      AND estado IN ('PENDIENTE', 'CONFIRMADA');

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'No se puede cancelar: la reservacion no existe o no tiene un estado cancelable';
    END IF;

    RETURN TRUE;
END;
$$;



-- ------------------------------------------------------------
-- 5. CONSULTAR DISPONIBILIDAD
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_consultar_disponibilidad(
    p_sede_id UUID,
    p_fecha_entrada DATE,
    p_fecha_salida DATE,
    p_numero_huespedes SMALLINT DEFAULT 1
)
RETURNS TABLE (
    habitacion_id UUID,
    numero VARCHAR(10),
    tipo_habitacion VARCHAR(20),
    capacidad INTEGER,
    amenidades TEXT[]
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_fecha_salida <= p_fecha_entrada THEN
        RAISE EXCEPTION
            'La fecha de salida debe ser posterior a la entrada';
    END IF;

    IF p_numero_huespedes <= 0 THEN
        RAISE EXCEPTION
            'El numero de huespedes debe ser mayor que cero';
    END IF;

    RETURN QUERY
    SELECT
        h.habitacion_id,
        h.numero,
        h.tipo_habitacion,
        h.capacidad,
        h.amenidades
    FROM habitaciones h
    WHERE h.sede_id = p_sede_id

      -- La habitacion debe estar operativamente habilitada.
      AND h.estado NOT IN ('MANTENIMIENTO', 'FUERA_SERVICIO')

      -- Debe tener capacidad suficiente.
      AND h.capacidad >= p_numero_huespedes

      -- Debe existir una tarifa activa que cubra toda la estancia.
      AND EXISTS (
          SELECT 1
          FROM tarifas t
          WHERE t.sede_id = h.sede_id
            AND t.tipo_habitacion = h.tipo_habitacion
            AND t.activa = TRUE
            AND t.fecha_inicio <= p_fecha_entrada
            AND t.fecha_fin >= p_fecha_salida - 1
      )

      -- No debe existir otra reservacion que se traslape.
      AND NOT EXISTS (
          SELECT 1
          FROM reservaciones r
          WHERE r.habitacion_id = h.habitacion_id
            AND r.sede_id = h.sede_id
            AND r.estado IN ('PENDIENTE', 'CONFIRMADA', 'CHECK_IN')
            AND r.periodo && daterange(
                p_fecha_entrada,
                p_fecha_salida,
                '[)'
            )
      )
    ORDER BY h.numero;
END;
$$;

