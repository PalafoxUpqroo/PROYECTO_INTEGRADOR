
-- Tabla principal de habitaciones.

CREATE TABLE IF NOT EXISTS habitaciones (
    habitacion_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sede_id UUID NOT NULL REFERENCES sedes(sede_id),
    numero VARCHAR(10) NOT NULL,
    piso INTEGER NOT NULL,
    capacidad INTEGER NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'DISPONIBLE',
    tipo_habitacion VARCHAR(20) NOT NULL,
    amenidades TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],

    CONSTRAINT uq_habitacion_sede
        UNIQUE (sede_id, numero),

    CONSTRAINT chk_capacidad
        CHECK (capacidad > 0),

    CONSTRAINT chk_piso
        CHECK (piso >= 0),

    CONSTRAINT chk_estado_habitacion
        CHECK (
            estado IN (
                'DISPONIBLE',
                'OCUPADA',
                'MANTENIMIENTO',
                'FUERA_SERVICIO'
            )
        ),

    CONSTRAINT chk_tipo_habitacion
        CHECK (tipo_habitacion IN ('ESTANDAR', 'SUITE'))
);

CREATE INDEX IF NOT EXISTS idx_habitaciones_sede
ON habitaciones(sede_id);

CREATE INDEX IF NOT EXISTS idx_habitaciones_amenidades
ON habitaciones USING GIN (amenidades);
