
-- =====================================================
-- INDICES ADICIONALES PARA OPTIMIZACION
-- Proyecto: Base de datos distribuida hotelera
-- =====================================================

-- 1. Busqueda de reservaciones por sede,
-- estado y fecha de entrada.
CREATE INDEX IF NOT EXISTS idx_reservaciones_sede_estado_entrada
ON reservaciones (sede_id, estado, fecha_entrada);

-- 2. Busqueda de servicios utilizados por sede.
CREATE INDEX IF NOT EXISTS idx_reservacion_servicios_sede_servicio
ON reservacion_servicios (sede_id, servicio_id);

-- Actualizar estadisticas del optimizador.
ANALYZE reservaciones;
ANALYZE reservacion_servicios;
