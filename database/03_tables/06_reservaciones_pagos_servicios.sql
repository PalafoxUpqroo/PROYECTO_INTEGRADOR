
-- Proyecto: Base de datos distribuida hotelera
-- Etapa 5: Reservaciones, pagos y servicios

-- =========================================================
-- 1. INDICES UNICOS PARA RELACIONES POR SEDE
-- =========================================================
-- Permiten garantizar que una reservacion solo utilice
-- huespedes, habitaciones y tarifas de su propia sede.

CREATE UNIQUE INDEX IF NOT EXISTS uq_huespedes_sede_id
    ON huespedes (sede_id, huesped_id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_habitaciones_sede_id
    ON habitaciones (sede_id, habitacion_id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_tarifas_sede_id
    ON tarifas (sede_id, tarifa_id);


-- =========================================================
-- 2. TABLA DE RESERVACIONES
-- =========================================================

CREATE TABLE IF NOT EXISTS reservaciones (
    reservacion_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sede_id UUID NOT NULL REFERENCES sedes(sede_id),
    huesped_id UUID NOT NULL,
    habitacion_id UUID NOT NULL,
    tarifa_id UUID NOT NULL,

    fecha_entrada DATE NOT NULL,
    fecha_salida DATE NOT NULL,

    periodo DATERANGE GENERATED ALWAYS AS (
        daterange(fecha_entrada, fecha_salida, '[)')
    ) STORED,

    numero_huespedes SMALLINT NOT NULL DEFAULT 1,
    estado VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    total NUMERIC(12,2) NOT NULL DEFAULT 0,
    moneda CHAR(3) NOT NULL DEFAULT 'MXN',

    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT,

    CONSTRAINT chk_reservacion_fechas
        CHECK (fecha_salida > fecha_entrada),

    CONSTRAINT chk_reservacion_huespedes
        CHECK (numero_huespedes > 0),

    CONSTRAINT chk_reservacion_estado
        CHECK (estado IN (
            'PENDIENTE',
            'CONFIRMADA',
            'CHECK_IN',
            'FINALIZADA',
            'CANCELADA'
        )),

    CONSTRAINT chk_reservacion_total
        CHECK (total >= 0),

    CONSTRAINT chk_reservacion_moneda
        CHECK (moneda IN ('MXN', 'USD')),

    -- El huesped debe pertenecer a la misma sede.
    CONSTRAINT fk_reservacion_huesped
        FOREIGN KEY (sede_id, huesped_id)
        REFERENCES huespedes(sede_id, huesped_id),

    -- La habitacion debe pertenecer a la misma sede.
    CONSTRAINT fk_reservacion_habitacion
        FOREIGN KEY (sede_id, habitacion_id)
        REFERENCES habitaciones(sede_id, habitacion_id),

    -- La tarifa debe pertenecer a la misma sede.
    CONSTRAINT fk_reservacion_tarifa
        FOREIGN KEY (sede_id, tarifa_id)
        REFERENCES tarifas(sede_id, tarifa_id),

    -- Evita reservaciones activas traslapadas en una habitacion.
    CONSTRAINT ex_reservacion_sin_traslape
        EXCLUDE USING GIST (
            habitacion_id WITH =,
            periodo WITH &&
        )
        WHERE (estado IN ('PENDIENTE', 'CONFIRMADA', 'CHECK_IN'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_reservaciones_sede_id
    ON reservaciones (sede_id, reservacion_id);

CREATE INDEX IF NOT EXISTS idx_reservaciones_huesped
    ON reservaciones (huesped_id);

CREATE INDEX IF NOT EXISTS idx_reservaciones_fechas
    ON reservaciones USING GIST (periodo);

CREATE INDEX IF NOT EXISTS idx_reservaciones_estado
    ON reservaciones (estado);


-- =========================================================
-- 3. TABLA DE PAGOS
-- =========================================================

CREATE TABLE IF NOT EXISTS pagos (
    pago_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sede_id UUID NOT NULL,
    reservacion_id UUID NOT NULL,
    monto NUMERIC(12,2) NOT NULL,
    moneda CHAR(3) NOT NULL DEFAULT 'MXN',
    metodo_pago VARCHAR(30) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'APLICADO',
    referencia VARCHAR(120),
    fecha_pago TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_pago_monto
        CHECK (monto > 0),

    CONSTRAINT chk_pago_moneda
        CHECK (moneda IN ('MXN', 'USD')),

    CONSTRAINT chk_pago_metodo
        CHECK (metodo_pago IN (
            'EFECTIVO',
            'TARJETA',
            'TRANSFERENCIA',
            'OTRO'
        )),

    CONSTRAINT chk_pago_estado
        CHECK (estado IN (
            'PENDIENTE',
            'APLICADO',
            'RECHAZADO',
            'REEMBOLSADO'
        )),

    CONSTRAINT fk_pago_reservacion
        FOREIGN KEY (sede_id, reservacion_id)
        REFERENCES reservaciones(sede_id, reservacion_id)
);

-- Indice unico requerido para la identidad de replicacion.
CREATE UNIQUE INDEX IF NOT EXISTS uq_pagos_sede_id
    ON pagos (sede_id, pago_id);

CREATE INDEX IF NOT EXISTS idx_pagos_reservacion
    ON pagos (sede_id, reservacion_id);


-- =========================================================
-- 4. CATALOGO DE SERVICIOS
-- =========================================================

CREATE TABLE IF NOT EXISTS servicios (
    servicio_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sede_id UUID NOT NULL REFERENCES sedes(sede_id),
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio NUMERIC(10,2) NOT NULL,
    moneda CHAR(3) NOT NULL DEFAULT 'MXN',
    activo BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_servicio_precio
        CHECK (precio >= 0),

    CONSTRAINT chk_servicio_moneda
        CHECK (moneda IN ('MXN', 'USD')),

    CONSTRAINT uq_servicio_sede_nombre
        UNIQUE (sede_id, nombre)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_servicios_sede_id
    ON servicios (sede_id, servicio_id);


-- =========================================================
-- 5. SERVICIOS CONTRATADOS POR RESERVACION
-- =========================================================

CREATE TABLE IF NOT EXISTS reservacion_servicios (
    reservacion_servicio_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sede_id UUID NOT NULL,
    reservacion_id UUID NOT NULL,
    servicio_id UUID NOT NULL,
    cantidad INTEGER NOT NULL DEFAULT 1,
    precio_unitario NUMERIC(10,2) NOT NULL,
    subtotal NUMERIC(12,2) GENERATED ALWAYS AS (
        cantidad * precio_unitario
    ) STORED,
    fecha_contratacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_reservacion_servicio_cantidad
        CHECK (cantidad > 0),

    CONSTRAINT chk_reservacion_servicio_precio
        CHECK (precio_unitario >= 0),

    CONSTRAINT fk_detalle_reservacion
        FOREIGN KEY (sede_id, reservacion_id)
        REFERENCES reservaciones(sede_id, reservacion_id),

    CONSTRAINT fk_detalle_servicio
        FOREIGN KEY (sede_id, servicio_id)
        REFERENCES servicios(sede_id, servicio_id),

    CONSTRAINT uq_reservacion_servicio
        UNIQUE (reservacion_id, servicio_id)
);

-- Indice unico requerido para la identidad de replicacion.
CREATE UNIQUE INDEX IF NOT EXISTS uq_reservacion_servicios_sede_id
    ON reservacion_servicios (sede_id, reservacion_servicio_id);
CREATE INDEX IF NOT EXISTS idx_reservacion_servicios_reservacion
    ON reservacion_servicios (reservacion_id);
