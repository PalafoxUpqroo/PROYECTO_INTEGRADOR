
-- =========================================================
-- VISTA 1: OCUPACION POR SEDE
-- Muestra el total de habitaciones y su estado.
-- =========================================================

CREATE OR REPLACE VIEW vw_ocupacion_sede AS
SELECT
    s.sede_id,
    s.nombre AS sede,
    s.ciudad,
    COUNT(h.habitacion_id) AS total_habitaciones,
    COUNT(h.habitacion_id) FILTER (
        WHERE h.estado = 'OCUPADA'
    ) AS habitaciones_ocupadas,
    COUNT(h.habitacion_id) FILTER (
        WHERE h.estado = 'DISPONIBLE'
    ) AS habitaciones_disponibles,
    COUNT(h.habitacion_id) FILTER (
        WHERE h.estado = 'MANTENIMIENTO'
    ) AS habitaciones_mantenimiento,
    COUNT(h.habitacion_id) FILTER (
        WHERE h.estado = 'FUERA_SERVICIO'
    ) AS habitaciones_fuera_servicio
FROM sedes s
LEFT JOIN habitaciones h
    ON h.sede_id = s.sede_id
GROUP BY
    s.sede_id,
    s.nombre,
    s.ciudad;


-- =========================================================
-- VISTA 2: DETALLE DE RESERVACIONES
-- Integra huésped, habitación, tarifa y estado de cuenta.
-- =========================================================

CREATE OR REPLACE VIEW vw_reservaciones_detalle AS
SELECT
    r.reservacion_id,
    r.sede_id,
    s.nombre AS sede,
    h.huesped_id,
    h.nombre AS nombre_huesped,
    h.apellido AS apellido_huesped,
    hab.numero AS numero_habitacion,
    hab.tipo_habitacion,
    t.nombre AS tarifa,
    r.fecha_entrada,
    r.fecha_salida,
    r.numero_huespedes,
    r.estado,
    r.total_alojamiento,
    r.total,
    r.total_pagado,
    r.saldo_pendiente,
    r.moneda,
    r.fecha_creacion
FROM reservaciones r
INNER JOIN sedes s
    ON s.sede_id = r.sede_id
INNER JOIN huespedes h
    ON h.sede_id = r.sede_id
   AND h.huesped_id = r.huesped_id
INNER JOIN habitaciones hab
    ON hab.sede_id = r.sede_id
   AND hab.habitacion_id = r.habitacion_id
INNER JOIN tarifas t
    ON t.sede_id = r.sede_id
   AND t.tarifa_id = r.tarifa_id;


-- =========================================================
-- VISTA 3: RESUMEN DE SERVICIOS POR RESERVACION
-- =========================================================

CREATE OR REPLACE VIEW vw_servicios_reservacion AS
SELECT
    r.reservacion_id,
    r.sede_id,
    COUNT(rs.reservacion_servicio_id) AS cantidad_servicios,
    COALESCE(SUM(rs.subtotal), 0) AS total_servicios
FROM reservaciones r
LEFT JOIN reservacion_servicios rs
    ON rs.sede_id = r.sede_id
   AND rs.reservacion_id = r.reservacion_id
GROUP BY
    r.reservacion_id,
    r.sede_id;
