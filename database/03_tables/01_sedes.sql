
-- Tabla: sedes
-- Catálogo compartido por los cuatro nodos.

CREATE TABLE IF NOT EXISTS sedes (
    sede_id UUID PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL UNIQUE,
    ciudad VARCHAR(80) NOT NULL,
    direccion direccion_type,
    telefono VARCHAR(20),
    activa BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO sedes (sede_id, nombre, ciudad, telefono)
VALUES
(
    '11111111-1111-4111-8111-111111111111',
    'Cancún',
    'Cancún',
    '9980000001'
),
(
    '22222222-2222-4222-8222-222222222222',
    'Tulum',
    'Tulum',
    '9840000002'
),
(
    '33333333-3333-4333-8333-333333333333',
    'Bacalar',
    'Bacalar',
    '9830000003'
)
ON CONFLICT (sede_id) DO NOTHING;
