# Base de datos distribuida para reservaciones hoteleras

Sistema de base de datos distribuida desarrollado para administrar reservaciones de una cadena hotelera con tres sedes: Cancún, Tulum y Bacalar. El proyecto utiliza PostgreSQL, Docker Compose y Python.

## 1. Objetivo

Implementar una solución distribuida que permita administrar las operaciones de cada sede de manera independiente, evitar reservaciones simultáneas sobre una misma habitación, mantener información consolidada y ofrecer mecanismos de recuperación ante fallos.

## 2. Arquitectura

El sistema utiliza cuatro instancias independientes de PostgreSQL:

| Nodo    | Base de datos   | Puerto local | Función                  |
| ------- | --------------- | -----------: | ------------------------ |
| Cancún  | `hotel_cancun`  |         5541 | Operaciones de la sede   |
| Tulum   | `hotel_tulum`   |         5542 | Operaciones de la sede   |
| Bacalar | `hotel_bacalar` |         5543 | Operaciones de la sede   |
| Central | `hotel_central` |         5544 | Consolidación y reportes |

Las tres sedes administran sus propias reservaciones, huéspedes, habitaciones, tarifas, pagos y servicios.

El nodo central recibe información mediante replicación lógica y permite consultar las sedes mediante `postgres_fdw`.

### Tecnologías

- PostgreSQL 18.6.
- Docker y Docker Compose.
- Python 3.10 o superior.
- psycopg 3.
- Git.
- PowerShell en Windows.

## 3. Estructura del proyecto

```text
proyecto-hotelero-distribuido/
├── database/
│   ├── 01_extensions/
│   ├── 02_types/
│   ├── 03_tables/
│   ├── 04_functions/
│   ├── 05_triggers/
│   ├── 06_views/
│   ├── 07_indexes/
│   └── 08_partitions/
├── docker/
│   └── init/
├── python/
│   ├── client/
│   │   └── main.py
│   ├── generators/
│   └── tests/
│       ├── test_2pc.py
│       └── test_concurrencia.py
├── backups/
├── documentation/
├── evidence/
├── .env
├── .gitignore
├── docker-compose.yml
└── README.md
```

## 4. Configuración del entorno

### Requisitos previos

Instalar:

- Docker Desktop con Docker Compose.
- Python 3.10 o superior.
- Git.

### Variables de entorno

Crear un archivo `.env` en la raíz del proyecto:

```env
POSTGRES_USER=hotel_admin
POSTGRES_PASSWORD=TU_CONTRASEÑA_SEGURA
```

No compartir ni subir este archivo al repositorio.

Para ejecutar las pruebas y el cliente Python, establecer también la variable de entorno de la contraseña en PowerShell:

```powershell
$env:HOTEL_DB_PASSWORD = "TU_CONTRASEÑA_SEGURA"
```

### Instalar dependencia Python

Desde la raíz del proyecto:

```powershell
python -m pip install "psycopg[binary]"
```

## 5. Iniciar los contenedores

Desde la raíz del proyecto:

```powershell
docker compose config
docker compose up -d
docker compose ps
```

Comprobar que los cuatro contenedores estén activos:

- `hotel-postgres-cancun`
- `hotel-postgres-tulum`
- `hotel-postgres-bacalar`
- `hotel-postgres-central`

## 6. Organización de los scripts SQL

Los scripts están organizados por responsabilidad y deben ejecutarse en el orden correspondiente:

| Directorio      | Contenido                                                                                       |
| --------------- | ----------------------------------------------------------------------------------------------- |
| `01_extensions` | Extensiones de PostgreSQL                                                                       |
| `02_types`      | Tipos compuestos                                                                                |
| `03_tables`     | Sedes, huéspedes, habitaciones, herencia, tarifas, temporadas, reservaciones, pagos y servicios |
| `04_functions`  | Funciones para gestionar reservaciones                                                          |
| `05_triggers`   | Bitácora, auditoría y cálculo automático de importes                                            |
| `06_views`      | Vistas operativas                                                                               |
| `07_indexes`    | Índices y datos para pruebas de rendimiento                                                     |
| `08_partitions` | Directorio reservado para scripts de particionamiento                                           |

Los scripts de estructura común se ejecutaron en los nodos correspondientes. Las funciones, triggers, vistas e índices operativos se instalaron en las tres sedes.

**Importante:** la configuración del particionamiento central, replicación lógica y conexiones FDW se realizó directamente en las instancias PostgreSQL durante el desarrollo. Sus instrucciones de reconstrucción deben incorporarse a scripts de instalación para facilitar una implementación desde cero.

## 7. Funcionalidades implementadas

### Administración de información

- Registro de huéspedes.
- Administración de habitaciones.
- Administración de tarifas y temporadas.
- Registro de reservaciones.
- Registro de pagos.
- Administración de servicios adicionales.

### Características avanzadas de PostgreSQL

- Tipos de datos compuestos.
- Herencia de tablas mediante `INHERITS`.
- Arreglos para amenidades.
- Campos `JSONB` para preferencias.
- Rangos `DATERANGE` para estancias.
- Restricciones de exclusión GiST para evitar traslapes.
- Funciones PL/pgSQL para crear, consultar, cancelar y gestionar reservaciones.
- Triggers para auditoría y actualización de importes.
- Vistas operativas.
- Índices B-tree, GiST y GIN.

### Distribución

- Cuatro instancias PostgreSQL independientes.
- Particionamiento de reservaciones del nodo central por sede.
- Replicación lógica de las tres sedes hacia el nodo central.
- Consultas distribuidas mediante `postgres_fdw`.
- Transacciones preparadas para traslado de reservaciones entre sedes mediante 2PC.

### Recuperación

- Archivado de registros WAL en el nodo Cancún.
- Respaldo físico mediante `pg_basebackup`.
- Verificación del respaldo con `pg_verifybackup`.
- Recuperación a un punto en el tiempo (PITR).

## 8. Cliente de demostración

El cliente Python se encuentra en:

```text
python/client/main.py
```

Ejecutar desde la raíz:

```powershell
python .\python\client\main.py
```

El menú principal permite:

1. Operaciones en Cancún.
2. Operaciones en Tulum.
3. Operaciones en Bacalar.
4. Consultar el reporte consolidado.
5. Salir.

Dentro de cada sede se puede consultar disponibilidad, crear y consultar reservaciones, realizar check-in y check-out y cancelar reservaciones.

## 9. Pruebas

### Prueba de concurrencia

Archivo:

```text
python/tests/test_concurrencia.py
```

Utiliza dos hilos y conexiones independientes para intentar reservar simultáneamente una misma habitación y periodo.

El resultado esperado es que una reservación sea aceptada y la otra rechazada por la restricción de exclusión GiST.

Ejecutar:

```powershell
python .\python\tests\test_concurrencia.py
```

### Prueba de transacción en dos fases

Archivo:

```text
python/tests/test_2pc.py
```

Comprueba el traslado de una reservación entre Cancún y Tulum mediante transacciones preparadas (`PREPARE TRANSACTION` y `COMMIT PREPARED`).

Ejecutar:

```powershell
python .\python\tests\test_2pc.py
```

Estas pruebas utilizan datos y conexiones de las instancias del proyecto. No ejecutarlas sobre bases de datos de producción.

## 10. Rendimiento

Se generaron 50,000 reservaciones de prueba en Cancún para comparar consultas antes y después de utilizar índices.

Los resultados registrados durante las pruebas fueron:

| Consulta | Sin índice | Con índice | Mejora aproximada |
| -------- | ---------: | ---------: | ----------------: |
| B-tree   |   5.967 ms |   0.230 ms |           96.15 % |
| GiST     |   7.497 ms |   0.406 ms |           94.58 % |

Los tiempos corresponden a las ejecuciones realizadas durante el desarrollo y pueden variar según el entorno.

## 11. Respaldo y recuperación

La configuración de archivado WAL se encuentra en `docker-compose.yml` para el nodo Cancún.

Los archivos de respaldo se almacenan localmente en `backups/`, directorio excluido del control de versiones.

Se realizaron pruebas de:

- Respaldo físico con `pg_basebackup`.
- Validación con `pg_verifybackup`.
- Restauración de una instancia.
- Recuperación PITR mediante `recovery.signal` y `restore_command`.

## 12. Control de versiones

El proyecto utiliza Git para registrar los cambios de implementación.

Consultar el historial:

```powershell
git --no-pager log --oneline
```

Consultar el estado:

```powershell
git status
```

## 13. Seguridad y consideraciones

- Las contraseñas se administran mediante variables de entorno.
- El archivo `.env` no debe subirse al repositorio.
- Los respaldos no se incluyen en Git.
- Los nodos utilizan contenedores y volúmenes independientes.
- Las pruebas deben ejecutarse en el entorno destinado al proyecto.

## 14. Estado del proyecto

El proyecto cuenta con las estructuras relacionales, características orientadas a objetos de PostgreSQL, funciones, triggers, vistas, índices, pruebas de concurrencia, respaldo PITR, replicación lógica, consultas distribuidas, traslado 2PC y cliente Python de demostración.

La documentación técnica y las evidencias complementarias se integrarán en el directorio `documentation/` y `evidence/`.
