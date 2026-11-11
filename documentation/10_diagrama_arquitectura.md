# Diagrama de arquitectura distribuida

## Base de datos distribuida para reservaciones de una cadena hotelera

El sistema utiliza cuatro instancias independientes de PostgreSQL 18.6 desplegadas mediante Docker. Cada sede administra sus operaciones localmente y envía información al nodo central mediante replicación lógica. El nodo central también consulta las bases de las sedes mediante PostgreSQL Foreign Data Wrapper (FDW).

```mermaid
flowchart TB
    CLIENTE["Cliente Python<br/>Sistema de reservaciones y reportes"]

    subgraph RED["Red Docker: hotel-proyecto-red"]
        subgraph CUN["Nodo Cancún - Puerto 5541"]
            DB_CUN[("PostgreSQL 18.6<br/>hotel_cancun")]
            PUB_CUN["Publicación lógica<br/>pub_central_cancun"]
        end

        subgraph TUL["Nodo Tulum - Puerto 5542"]
            DB_TUL[("PostgreSQL 18.6<br/>hotel_tulum")]
            PUB_TUL["Publicación lógica<br/>pub_central_tulum"]
        end

        subgraph BAC["Nodo Bacalar - Puerto 5543"]
            DB_BAC[("PostgreSQL 18.6<br/>hotel_bacalar")]
            PUB_BAC["Publicación lógica<br/>pub_central_bacalar"]
        end

        subgraph CENTRAL["Nodo Central - Puerto 5544"]
            DB_CENTRAL[("PostgreSQL 18.6<br/>hotel_central")]
            SUBS["Suscripciones lógicas<br/>sub_cancun<br/>sub_tulum<br/>sub_bacalar"]
            PART["Particionamiento LIST<br/>por sede_id"]
            FDW["Foreign Data Wrappers<br/>fdw_cancun<br/>fdw_tulum<br/>fdw_bacalar"]
            VIEW["Vista consolidada<br/>vw_reservaciones_distribuidas"]
        end
    end

    CLIENTE -->|"Operaciones locales"| DB_CUN
    CLIENTE -->|"Operaciones locales"| DB_TUL
    CLIENTE -->|"Operaciones locales"| DB_BAC
    CLIENTE -->|"Consultas y reportes"| DB_CENTRAL

    DB_CUN --> PUB_CUN
    DB_TUL --> PUB_TUL
    DB_BAC --> PUB_BAC

    PUB_CUN -->|"Replicación lógica"| SUBS
    PUB_TUL -->|"Replicación lógica"| SUBS
    PUB_BAC -->|"Replicación lógica"| SUBS

    SUBS --> DB_CENTRAL
    DB_CENTRAL --> PART
    DB_CENTRAL --> FDW
    FDW -->|"Consulta remota"| DB_CUN
    FDW -->|"Consulta remota"| DB_TUL
    FDW -->|"Consulta remota"| DB_BAC
    PART --> VIEW
    FDW --> VIEW
```

## Componentes de la arquitectura

| Componente            | Función                                                                       |
| --------------------- | ----------------------------------------------------------------------------- |
| Nodo Cancún           | Administra las reservaciones y operaciones de la sede Cancún.                 |
| Nodo Tulum            | Administra las reservaciones y operaciones de la sede Tulum.                  |
| Nodo Bacalar          | Administra las reservaciones y operaciones de la sede Bacalar.                |
| Nodo Central          | Recibe la replicación lógica y consolida información de las sedes.            |
| Replicación lógica    | Transfiere cambios de las tablas publicadas hacia el nodo central.            |
| Particionamiento LIST | Organiza las reservaciones centrales de acuerdo con el identificador de sede. |
| PostgreSQL FDW        | Permite consultar tablas remotas de las tres sedes.                           |
| Cliente Python        | Permite realizar operaciones locales y consultar reportes consolidados.       |

## Consideraciones técnicas

- Cada instancia PostgreSQL funciona como un nodo independiente.
- Las sedes realizan operaciones directamente sobre sus respectivas bases de datos.
- La replicación lógica transmite los cambios de las tablas publicadas al nodo central.
- El nodo central utiliza particionamiento LIST para organizar las reservaciones por sede.
- FDW permite consultar información remota sin copiarla mediante una consulta convencional.
- El traslado de reservaciones entre sedes se realiza mediante transacciones preparadas y coordinación desde Python (2PC).
- La recuperación PITR fue configurada y probada únicamente en el nodo Cancún.

**Nota:** La arquitectura implementada es una solución académica distribuida. No cuenta con alta disponibilidad ni recuperación automática ante fallos.
