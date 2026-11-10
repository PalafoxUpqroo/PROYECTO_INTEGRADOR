
-- ============================================================
-- PROYECTO: BASE DE DATOS DISTRIBUIDA HOTELERA
-- ARCHIVO: 01_bitacora.sql
-- DESCRIPCION: Registro de auditoria de operaciones
-- ============================================================

CREATE TABLE IF NOT EXISTS bitacora (
    bitacora_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tabla_afectada VARCHAR(100) NOT NULL,
    operacion VARCHAR(10) NOT NULL,
    registro_id TEXT,
    usuario_bd VARCHAR(100) NOT NULL DEFAULT CURRENT_USER,
    fecha_operacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    datos_anteriores JSONB,
    datos_nuevos JSONB,

    CONSTRAINT chk_bitacora_operacion
        CHECK (operacion IN ('INSERT', 'UPDATE', 'DELETE'))
);

CREATE INDEX IF NOT EXISTS idx_bitacora_tabla_fecha
    ON bitacora (tabla_afectada, fecha_operacion DESC);

CREATE INDEX IF NOT EXISTS idx_bitacora_registro
    ON bitacora (registro_id);

CREATE OR REPLACE FUNCTION fn_registrar_bitacora()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_anterior JSONB;
    v_nuevo JSONB;
    v_registro_id TEXT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_nuevo := TO_JSONB(NEW);
        v_registro_id := COALESCE(
            v_nuevo ->> 'reservacion_id',
            v_nuevo ->> 'huesped_id',
            v_nuevo ->> 'habitacion_id',
            v_nuevo ->> 'pago_id',
            v_nuevo ->> 'servicio_id',
            v_nuevo ->> 'reservacion_servicio_id'
        );

    ELSIF TG_OP = 'UPDATE' THEN
        v_anterior := TO_JSONB(OLD);
        v_nuevo := TO_JSONB(NEW);
        v_registro_id := COALESCE(
            v_nuevo ->> 'reservacion_id',
            v_nuevo ->> 'huesped_id',
            v_nuevo ->> 'habitacion_id',
            v_nuevo ->> 'pago_id',
            v_nuevo ->> 'servicio_id',
            v_nuevo ->> 'reservacion_servicio_id'
        );

    ELSIF TG_OP = 'DELETE' THEN
        v_anterior := TO_JSONB(OLD);
        v_registro_id := COALESCE(
            v_anterior ->> 'reservacion_id',
            v_anterior ->> 'huesped_id',
            v_anterior ->> 'habitacion_id',
            v_anterior ->> 'pago_id',
            v_anterior ->> 'servicio_id',
            v_anterior ->> 'reservacion_servicio_id'
        );
    END IF;

    INSERT INTO bitacora (
        tabla_afectada,
        operacion,
        registro_id,
        usuario_bd,
        datos_anteriores,
        datos_nuevos
    )
    VALUES (
        TG_TABLE_NAME,
        TG_OP,
        v_registro_id,
        CURRENT_USER,
        v_anterior,
        v_nuevo
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$;
