# Diagrama entidad-relación

## Base de datos distribuida para reservaciones de una cadena hotelera

El siguiente diagrama representa las entidades principales del sistema, sus atributos y las relaciones implementadas mediante claves primarias y foráneas en PostgreSQL.

```mermaid
erDiagram
    SEDES {
        UUID sede_id PK
        VARCHAR nombre UK
        VARCHAR ciudad
        direccion_type direccion
        VARCHAR telefono
        BOOLEAN activa
    }

    HUESPEDES {
        UUID huesped_id PK
        UUID sede_id FK
        VARCHAR nombre
        VARCHAR apellido
        VARCHAR correo
        VARCHAR telefono
        direccion_type direccion
        JSONB preferencias
        VARCHAR tipo_huesped
        TIMESTAMPTZ fecha_registro
    }

    HABITACIONES {
        UUID habitacion_id PK
        UUID sede_id FK
        VARCHAR numero
        INTEGER piso
        INTEGER capacidad
        VARCHAR estado
        VARCHAR tipo_habitacion
        TEXT_ARRAY amenidades
    }

    TEMPORADAS {
        UUID temporada_id PK
        UUID sede_id FK
        VARCHAR nombre
        DATE fecha_inicio
        DATE fecha_fin
        NUMERIC multiplicador
        BOOLEAN activa
    }

    TARIFAS {
        UUID tarifa_id PK
        UUID sede_id FK
        VARCHAR tipo_habitacion
        VARCHAR nombre
        NUMERIC precio_noche
        CHAR moneda
        DATE fecha_inicio
        DATE fecha_fin
        BOOLEAN activa
    }

    RESERVACIONES {
        UUID reservacion_id PK
        UUID sede_id FK
        UUID huesped_id FK
        UUID habitacion_id FK
        UUID tarifa_id FK
        DATE fecha_entrada
        DATE fecha_salida
        DATERANGE periodo
        SMALLINT numero_huespedes
        VARCHAR estado
        NUMERIC total
        CHAR moneda
        TIMESTAMPTZ fecha_creacion
        TEXT observaciones
    }

    PAGOS {
        UUID pago_id PK
        UUID sede_id FK
        UUID reservacion_id FK
        NUMERIC monto
        CHAR moneda
        VARCHAR metodo_pago
        VARCHAR estado
        VARCHAR referencia
        TIMESTAMPTZ fecha_pago
    }

    SERVICIOS {
        UUID servicio_id PK
        UUID sede_id FK
        VARCHAR nombre
        TEXT descripcion
        NUMERIC precio
        CHAR moneda
        BOOLEAN activo
    }

    RESERVACION_SERVICIOS {
        UUID reservacion_servicio_id PK
        UUID sede_id FK
        UUID reservacion_id FK
        UUID servicio_id FK
        INTEGER cantidad
        NUMERIC precio_unitario
        NUMERIC subtotal
        TIMESTAMPTZ fecha_contratacion
    }

    HUESPED_ESPECIALIZACION {
        UUID huesped_id
        TEXT observaciones
        TIMESTAMPTZ fecha_especializacion
    }

    HUESPED_INDIVIDUAL {
        UUID huesped_id PK, FK
        TEXT observaciones
        TIMESTAMPTZ fecha_especializacion
        DATE fecha_nacimiento
        VARCHAR documento_identidad
    }

    HUESPED_CORPORATIVO {
        UUID huesped_id PK, FK
        TEXT observaciones
        TIMESTAMPTZ fecha_especializacion
        VARCHAR razon_social
        VARCHAR rfc
        VARCHAR contacto_empresa
    }

    HABITACION_ESPECIALIZACION {
        UUID habitacion_id
        TEXT descripcion
        TIMESTAMPTZ fecha_especializacion
    }

    HABITACION_ESTANDAR {
        UUID habitacion_id PK, FK
        TEXT descripcion
        TIMESTAMPTZ fecha_especializacion
        SMALLINT numero_camas
    }

    HABITACION_SUITE {
        UUID habitacion_id PK, FK
        TEXT descripcion
        TIMESTAMPTZ fecha_especializacion
        BOOLEAN tiene_sala
        BOOLEAN tiene_jacuzzi
    }

    SEDES ||--o{ HUESPEDES : registra
    SEDES ||--o{ HABITACIONES : contiene
    SEDES ||--o{ TEMPORADAS : define
    SEDES ||--o{ TARIFAS : establece
    SEDES ||--o{ RESERVACIONES : administra
    SEDES ||--o{ SERVICIOS : ofrece

    HUESPEDES ||--o{ RESERVACIONES : realiza
    HABITACIONES ||--o{ RESERVACIONES : recibe
    TARIFAS ||--o{ RESERVACIONES : determina

    RESERVACIONES ||--o{ PAGOS : registra
    RESERVACIONES ||--o{ RESERVACION_SERVICIOS : incluye
    SERVICIOS ||--o{ RESERVACION_SERVICIOS : contrata

    HUESPEDES ||--o| HUESPED_INDIVIDUAL : especializa
    HUESPEDES ||--o| HUESPED_CORPORATIVO : especializa

    HABITACIONES ||--o| HABITACION_ESTANDAR : especializa
    HABITACIONES ||--o| HABITACION_SUITE : especializa
```

## Consideraciones del modelo

1. Cada sede administra sus propios huéspedes, habitaciones, temporadas, tarifas, reservaciones y servicios.
2. Una reservación pertenece a un huésped, una habitación y una tarifa de la misma sede. Esta condición se garantiza mediante claves foráneas compuestas.
3. Una reservación puede tener varios pagos y contratar varios servicios.
4. La tabla `reservacion_servicios` resuelve la relación muchos a muchos entre reservaciones y servicios.
5. Las tablas `huesped_individual`, `huesped_corporativo`, `habitacion_estandar` y `habitacion_suite` utilizan herencia nativa de PostgreSQL mediante `INHERITS`.
6. Las tarifas y temporadas son entidades independientes en la implementación actual; no existe una clave foránea directa entre ambas.
7. El campo `periodo` se genera a partir de las fechas de entrada y salida para controlar los traslapes de reservaciones.

**Nota:** Las relaciones de especialización representan las claves foráneas existentes hacia las tablas principales. La herencia nativa de PostgreSQL es una característica adicional del modelo y no equivale a una relación de clave foránea con las tablas de especialización.
