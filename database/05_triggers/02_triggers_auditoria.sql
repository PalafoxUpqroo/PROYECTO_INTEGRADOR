
-- ============================================================
-- PROYECTO: BASE DE DATOS DISTRIBUIDA HOTELERA
-- ARCHIVO: 02_triggers_auditoria.sql
-- DESCRIPCION: Triggers automaticos de auditoria
-- ============================================================

-- HUESPEDES
DROP TRIGGER IF EXISTS trg_auditoria_huespedes ON huespedes;

CREATE TRIGGER trg_auditoria_huespedes
AFTER INSERT OR UPDATE OR DELETE ON huespedes
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_bitacora();


-- HABITACIONES
DROP TRIGGER IF EXISTS trg_auditoria_habitaciones ON habitaciones;

CREATE TRIGGER trg_auditoria_habitaciones
AFTER INSERT OR UPDATE OR DELETE ON habitaciones
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_bitacora();


-- TARIFAS
DROP TRIGGER IF EXISTS trg_auditoria_tarifas ON tarifas;

CREATE TRIGGER trg_auditoria_tarifas
AFTER INSERT OR UPDATE OR DELETE ON tarifas
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_bitacora();


-- TEMPORADAS
DROP TRIGGER IF EXISTS trg_auditoria_temporadas ON temporadas;

CREATE TRIGGER trg_auditoria_temporadas
AFTER INSERT OR UPDATE OR DELETE ON temporadas
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_bitacora();


-- RESERVACIONES
DROP TRIGGER IF EXISTS trg_auditoria_reservaciones ON reservaciones;

CREATE TRIGGER trg_auditoria_reservaciones
AFTER INSERT OR UPDATE OR DELETE ON reservaciones
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_bitacora();


-- PAGOS
DROP TRIGGER IF EXISTS trg_auditoria_pagos ON pagos;

CREATE TRIGGER trg_auditoria_pagos
AFTER INSERT OR UPDATE OR DELETE ON pagos
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_bitacora();


-- SERVICIOS
DROP TRIGGER IF EXISTS trg_auditoria_servicios ON servicios;

CREATE TRIGGER trg_auditoria_servicios
AFTER INSERT OR UPDATE OR DELETE ON servicios
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_bitacora();


-- SERVICIOS CONTRATADOS EN RESERVACIONES
DROP TRIGGER IF EXISTS trg_auditoria_reservacion_servicios
ON reservacion_servicios;

CREATE TRIGGER trg_auditoria_reservacion_servicios
AFTER INSERT OR UPDATE OR DELETE ON reservacion_servicios
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_bitacora();
