
-- Proyecto: Base de datos distribuida hotelera
-- Etapa 1: Tipos de datos compuestos

-- Tipo compuesto para almacenar direcciones.
DO $$
BEGIN
    CREATE TYPE direccion_type AS (
        calle VARCHAR(120),
        numero VARCHAR(20),
        colonia VARCHAR(100),
        ciudad VARCHAR(80),
        estado VARCHAR(80),
        codigo_postal VARCHAR(10),
        pais VARCHAR(60)
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END
$$;

-- Tipo compuesto para representar una estancia.
DO $$
BEGIN
    CREATE TYPE rango_estancia AS (
        fecha_entrada DATE,
        fecha_salida DATE
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END
$$;
