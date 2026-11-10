
-- Proyecto: Base de datos distribuida hotelera
-- Etapa 1: Extensiones necesarias

-- Permite utilizar operadores GiST para tipos
-- como UUID y rangos de fechas.
CREATE EXTENSION IF NOT EXISTS btree_gist;
