
-- ============================================================
-- PROYECTO: BASE DE DATOS DISTRIBUIDA HOTELERA
-- ARCHIVO: 03_triggers_totales.sql
-- DESCRIPCION: Calculo automatico de importes y pagos
-- ============================================================

-- ============================================================
-- 1. COLUMNAS DE IMPORTES
-- ============================================================

ALTER TABLE reservaciones
ADD COLUMN IF NOT EXISTS total_alojamiento
NUMERIC(12,2) NOT NULL DEFAULT 0;

UPDATE reservaciones
SET total_alojamiento = total
WHERE total_alojamiento = 0
  AND total > 0;

ALTER TABLE reservaciones
ADD COLUMN IF NOT EXISTS total_pagado
NUMERIC(12,2) NOT NULL DEFAULT 0;

ALTER TABLE reservaciones
ADD COLUMN IF NOT EXISTS saldo_pendiente
NUMERIC(12,2)
GENERATED ALWAYS AS (total - total_pagado) STORED;


-- ============================================================
-- 2. RESTRICCIONES DE IMPORTES
-- ============================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_reservacion_total_alojamiento'
          AND conrelid = 'reservaciones'::regclass
    ) THEN
        ALTER TABLE reservaciones
        ADD CONSTRAINT chk_reservacion_total_alojamiento
        CHECK (total_alojamiento >= 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_reservacion_total_pagado'
          AND conrelid = 'reservaciones'::regclass
    ) THEN
        ALTER TABLE reservaciones
        ADD CONSTRAINT chk_reservacion_total_pagado
        CHECK (total_pagado >= 0 AND total_pagado <= total);
    END IF;
END;
$$;


-- ============================================================
-- 3. RECALCULAR TOTAL DE UNA RESERVACION
-- ============================================================

CREATE OR REPLACE FUNCTION fn_recalcular_total_reservacion(
    p_reservacion_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE reservaciones r
    SET total = r.total_alojamiento + COALESCE(
        (
            SELECT SUM(rs.subtotal)
            FROM reservacion_servicios rs
            WHERE rs.reservacion_id = r.reservacion_id
              AND rs.sede_id = r.sede_id
        ),
        0
    )
    WHERE r.reservacion_id = p_reservacion_id;
END;
$$;


-- ============================================================
-- 4. VALIDAR SERVICIOS CONTRATADOS
-- ============================================================

CREATE OR REPLACE FUNCTION fn_validar_detalle_servicio()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_moneda_reservacion CHAR(3);
    v_moneda_servicio CHAR(3);
    v_estado_reservacion VARCHAR(20);
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF NEW.reservacion_id <> OLD.reservacion_id
           OR NEW.sede_id <> OLD.sede_id THEN
            RAISE EXCEPTION
                'No se puede cambiar la reservacion o sede de un servicio contratado';
        END IF;
    END IF;

    SELECT moneda, estado
    INTO v_moneda_reservacion, v_estado_reservacion
    FROM reservaciones
    WHERE reservacion_id = NEW.reservacion_id
      AND sede_id = NEW.sede_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'La reservacion indicada no existe';
    END IF;

    IF v_estado_reservacion IN ('FINALIZADA', 'CANCELADA') THEN
        RAISE EXCEPTION
            'No se pueden agregar o modificar servicios en una reservacion finalizada o cancelada';
    END IF;

    SELECT moneda
    INTO v_moneda_servicio
    FROM servicios
    WHERE servicio_id = NEW.servicio_id
      AND sede_id = NEW.sede_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'El servicio no existe en la sede indicada';
    END IF;

    IF NEW.precio_unitario < 0 OR NEW.cantidad <= 0 THEN
        RAISE EXCEPTION
            'La cantidad debe ser positiva y el precio no puede ser negativo';
    END IF;

    IF v_moneda_reservacion <> v_moneda_servicio THEN
        RAISE EXCEPTION
            'La moneda del servicio no coincide con la moneda de la reservacion';
    END IF;

    RETURN NEW;
END;
$$;


-- ============================================================
-- 5. TRIGGER PARA RECALCULAR TOTAL POR SERVICIOS
-- ============================================================

CREATE OR REPLACE FUNCTION fn_trigger_recalcular_total_servicios()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM fn_recalcular_total_reservacion(OLD.reservacion_id);
        RETURN OLD;
    END IF;

    PERFORM fn_recalcular_total_reservacion(NEW.reservacion_id);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validar_detalle_servicio
ON reservacion_servicios;

CREATE TRIGGER trg_validar_detalle_servicio
BEFORE INSERT OR UPDATE ON reservacion_servicios
FOR EACH ROW
EXECUTE FUNCTION fn_validar_detalle_servicio();

DROP TRIGGER IF EXISTS trg_recalcular_total_servicios
ON reservacion_servicios;

CREATE TRIGGER trg_recalcular_total_servicios
AFTER INSERT OR UPDATE OR DELETE ON reservacion_servicios
FOR EACH ROW
EXECUTE FUNCTION fn_trigger_recalcular_total_servicios();


-- ============================================================
-- 6. VALIDAR PAGOS
-- ============================================================

CREATE OR REPLACE FUNCTION fn_validar_pago()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_moneda_reservacion CHAR(3);
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF NEW.reservacion_id <> OLD.reservacion_id
           OR NEW.sede_id <> OLD.sede_id THEN
            RAISE EXCEPTION
                'No se puede cambiar la reservacion o sede de un pago';
        END IF;
    END IF;

    SELECT moneda
    INTO v_moneda_reservacion
    FROM reservaciones
    WHERE reservacion_id = NEW.reservacion_id
      AND sede_id = NEW.sede_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'La reservacion asociada al pago no existe';
    END IF;

    IF NEW.moneda <> v_moneda_reservacion THEN
        RAISE EXCEPTION
            'La moneda del pago no coincide con la moneda de la reservacion';
    END IF;

    RETURN NEW;
END;
$$;


-- ============================================================
-- 7. RECALCULAR IMPORTE PAGADO
-- ============================================================

CREATE OR REPLACE FUNCTION fn_recalcular_total_pagado(
    p_reservacion_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE reservaciones r
    SET total_pagado = COALESCE(
        (
            SELECT SUM(p.monto)
            FROM pagos p
            WHERE p.reservacion_id = r.reservacion_id
              AND p.sede_id = r.sede_id
              AND p.estado = 'APLICADO'
        ),
        0
    )
    WHERE r.reservacion_id = p_reservacion_id;
END;
$$;


-- ============================================================
-- 8. TRIGGER PARA RECALCULAR PAGOS
-- ============================================================

CREATE OR REPLACE FUNCTION fn_trigger_recalcular_total_pagado()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM fn_recalcular_total_pagado(OLD.reservacion_id);
        RETURN OLD;
    END IF;

    PERFORM fn_recalcular_total_pagado(NEW.reservacion_id);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validar_pago
ON pagos;

CREATE TRIGGER trg_validar_pago
BEFORE INSERT OR UPDATE ON pagos
FOR EACH ROW
EXECUTE FUNCTION fn_validar_pago();

DROP TRIGGER IF EXISTS trg_recalcular_total_pagado
ON pagos;

CREATE TRIGGER trg_recalcular_total_pagado
AFTER INSERT OR UPDATE OR DELETE ON pagos
FOR EACH ROW
EXECUTE FUNCTION fn_trigger_recalcular_total_pagado();
