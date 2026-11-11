
-- ============================================================
-- PROYECTO: HOTEL DISTRIBUIDO
-- ARCHIVO: 02_tablas_auxiliares_central.sql
-- OBJETIVO:
-- Crear las tablas auxiliares del nodo central despues
-- de crear reservaciones particionada.
--
-- PREREQUISITOS:
-- 1. sedes, huespedes, habitaciones y tarifas.
-- 2. reservaciones particionada por sede_id.
-- ============================================================

BEGIN;
-- ------------------------------------------------------------
-- 1. TABLA DE PAGOS
-- ------------------------------------------------------------

CREATE TABLE public.pagos (
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
        REFERENCES public.reservaciones(sede_id, reservacion_id)
);

CREATE INDEX idx_pagos_reservacion
    ON public.pagos (sede_id, reservacion_id);

-- ------------------------------------------------------------
-- 2. CATALOGO DE SERVICIOS
-- ------------------------------------------------------------

CREATE TABLE public.servicios (
    servicio_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sede_id UUID NOT NULL REFERENCES public.sedes(sede_id),
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

CREATE UNIQUE INDEX uq_servicios_sede_id
    ON public.servicios (sede_id, servicio_id);

-- ------------------------------------------------------------
-- 3. SERVICIOS CONTRATADOS POR RESERVACION
-- ------------------------------------------------------------

CREATE TABLE public.reservacion_servicios (
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
        REFERENCES public.reservaciones(sede_id, reservacion_id),

    CONSTRAINT fk_detalle_servicio
        FOREIGN KEY (sede_id, servicio_id)
        REFERENCES public.servicios(sede_id, servicio_id),

    CONSTRAINT uq_reservacion_servicio
        UNIQUE (reservacion_id, servicio_id)
);

CREATE INDEX idx_reservacion_servicios_reservacion
    ON public.reservacion_servicios (reservacion_id);

COMMIT;

-- ------------------------------------------------------------
-- 4. VERIFICACION
-- ------------------------------------------------------------

SELECT
    tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
      'pagos',
      'servicios',
      'reservacion_servicios'
  )
ORDER BY tablename;
