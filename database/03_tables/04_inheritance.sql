
-- Proyecto: Base de datos distribuida hotelera
-- Etapa 3: Herencia nativa de PostgreSQL (INHERITS)
--
-- Las tablas principales huespedes y habitaciones conservan
-- sus claves primarias y relaciones.
--
-- Las tablas de especializacion heredan atributos comunes
-- y mantienen sus propias PK y FK.

-- =========================================================
-- 1. HERENCIA DE HUESPEDES
-- =========================================================

-- Tabla padre: contiene atributos comunes.
CREATE TABLE IF NOT EXISTS huesped_especializacion (
    huesped_id UUID NOT NULL,
    observaciones TEXT,
    fecha_especializacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Huesped individual hereda las columnas del padre.
CREATE TABLE IF NOT EXISTS huesped_individual (
    fecha_nacimiento DATE,
    documento_identidad VARCHAR(30),
    CONSTRAINT pk_huesped_individual
        PRIMARY KEY (huesped_id),
    CONSTRAINT fk_huesped_individual
        FOREIGN KEY (huesped_id)
        REFERENCES huespedes(huesped_id)
) INHERITS (huesped_especializacion);

-- Huesped corporativo hereda las columnas del padre.
CREATE TABLE IF NOT EXISTS huesped_corporativo (
    razon_social VARCHAR(150) NOT NULL,
    rfc VARCHAR(13),
    contacto_empresa VARCHAR(120),
    CONSTRAINT pk_huesped_corporativo
        PRIMARY KEY (huesped_id),
    CONSTRAINT fk_huesped_corporativo
        FOREIGN KEY (huesped_id)
        REFERENCES huespedes(huesped_id)
) INHERITS (huesped_especializacion);


-- =========================================================
-- 2. HERENCIA DE HABITACIONES
-- =========================================================

-- Tabla padre: atributos comunes de especializacion.
CREATE TABLE IF NOT EXISTS habitacion_especializacion (
    habitacion_id UUID NOT NULL,
    descripcion TEXT,
    fecha_especializacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Habitacion estandar.
CREATE TABLE IF NOT EXISTS habitacion_estandar (
    numero_camas SMALLINT NOT NULL DEFAULT 1,
    CONSTRAINT pk_habitacion_estandar
        PRIMARY KEY (habitacion_id),
    CONSTRAINT fk_habitacion_estandar
        FOREIGN KEY (habitacion_id)
        REFERENCES habitaciones(habitacion_id),
    CONSTRAINT chk_numero_camas_estandar
        CHECK (numero_camas BETWEEN 1 AND 4)
) INHERITS (habitacion_especializacion);

-- Habitacion suite.
CREATE TABLE IF NOT EXISTS habitacion_suite (
    tiene_sala BOOLEAN NOT NULL DEFAULT TRUE,
    tiene_jacuzzi BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_habitacion_suite
        PRIMARY KEY (habitacion_id),
    CONSTRAINT fk_habitacion_suite
        FOREIGN KEY (habitacion_id)
        REFERENCES habitaciones(habitacion_id)
) INHERITS (habitacion_especializacion);
