
-- Proyecto: Base de datos distribuida hotelera
-- Etapa 4: Tarifas y temporadas

-- =========================================================
-- 1. TEMPORADAS
-- =========================================================

CREATE TABLE IF NOT EXISTS temporadas (
    temporada_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sede_id UUID NOT NULL REFERENCES sedes(sede_id),
    nombre VARCHAR(80) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    multiplicador NUMERIC(5,2) NOT NULL DEFAULT 1.00,
    activa BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_temporada_fechas
        CHECK (fecha_fin > fecha_inicio),

    CONSTRAINT chk_temporada_multiplicador
        CHECK (multiplicador > 0),

    CONSTRAINT uq_temporada_sede_nombre
        UNIQUE (sede_id, nombre, fecha_inicio)
);

-- Indice unico requerido para la identidad de replicacion.
CREATE UNIQUE INDEX IF NOT EXISTS uq_temporadas_sede_id
    ON temporadas (sede_id, temporada_id);

CREATE INDEX IF NOT EXISTS idx_temporadas_sede_fechas
    ON temporadas (sede_id, fecha_inicio, fecha_fin);


-- =========================================================
-- 2. TARIFAS
-- =========================================================

CREATE TABLE IF NOT EXISTS tarifas (
    tarifa_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sede_id UUID NOT NULL REFERENCES sedes(sede_id),
    tipo_habitacion VARCHAR(20) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    precio_noche NUMERIC(10,2) NOT NULL,
    moneda CHAR(3) NOT NULL DEFAULT 'MXN',
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    activa BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_tarifa_tipo
        CHECK (tipo_habitacion IN ('ESTANDAR', 'SUITE')),

    CONSTRAINT chk_tarifa_precio
        CHECK (precio_noche > 0),

    CONSTRAINT chk_tarifa_fechas
        CHECK (fecha_fin > fecha_inicio),

    CONSTRAINT chk_tarifa_moneda
        CHECK (moneda IN ('MXN', 'USD'))
);

CREATE INDEX IF NOT EXISTS idx_tarifas_busqueda
    ON tarifas (sede_id, tipo_habitacion, fecha_inicio, fecha_fin);
