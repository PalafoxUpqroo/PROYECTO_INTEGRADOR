
-- Tabla principal de huéspedes.

CREATE TABLE IF NOT EXISTS huespedes (
    huesped_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sede_id UUID NOT NULL REFERENCES sedes(sede_id),
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    correo VARCHAR(150),
    telefono VARCHAR(20),
    direccion direccion_type,
    preferencias JSONB NOT NULL DEFAULT '{}'::JSONB,
    tipo_huesped VARCHAR(20) NOT NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_tipo_huesped
        CHECK (tipo_huesped IN ('INDIVIDUAL', 'CORPORATIVO'))
);

CREATE INDEX IF NOT EXISTS idx_huespedes_sede
ON huespedes(sede_id);

CREATE INDEX IF NOT EXISTS idx_huespedes_preferencias
ON huespedes USING GIN (preferencias);
