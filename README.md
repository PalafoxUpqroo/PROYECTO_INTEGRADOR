# Base de datos distribuida para reservaciones hoteleras

Sistema de base de datos distribuida para administrar las reservaciones de una cadena hotelera con tres sedes: Cancún, Tulum y Bacalar. El proyecto utiliza PostgreSQL 18.6, Docker Compose y Python.

## 1. Objetivo

Implementar una solución distribuida que permita administrar las operaciones de cada sede, evitar reservaciones simultáneas sobre una misma habitación, consolidar información en un nodo central y ofrecer mecanismos de respaldo y recuperación ante fallos.

## 2. Arquitectura

El sistema utiliza cuatro instancias independientes de PostgreSQL:

| Nodo    | Base de datos   | Puerto local | Función                  |
| ------- | --------------- | -----------: | ------------------------ |
| Cancún  | `hotel_cancun`  |         5541 | Operaciones de la sede   |
| Tulum   | `hotel_tulum`   |         5542 | Operaciones de la sede   |
| Bacalar | `hotel_bacalar` |         5543 | Operaciones de la sede   |
| Central | `hotel_central` |         5544 | Consolidación y reportes |

Las tres sedes administran sus propias reservaciones, huéspedes, habitaciones, tarifas, temporadas, pagos y servicios.

El nodo central recibe información de las sedes mediante replicación lógica y permite consultar sus datos mediante `postgres_fdw`.

Las reservaciones del nodo central están particionadas por sede. El traslado de reservaciones entre nodos se implementa mediante coordinación desde Python y transacciones preparadas de PostgreSQL (2PC).

La arquitectura detallada se encuentra en [10_diagrama_arquitectura.md](documentation/10_diagrama_arquitectura.md).

### Tecnologías

- PostgreSQL 18.6.
- Docker Desktop y Docker Compose.
- Python 3.10 o superior.
- psycopg 3.
- Git.
- PowerShell en Windows.
- Visual Studio Code.

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
│   ├── 08_partitions/
│   └── 09_distributed/
├── docker/
│   └── init/
├── python/
│   ├── client/
│   │   └── main.py
│   ├── generators/
│   └── tests/
│       ├── test_2pc.py
│       └── test_concurrencia.py
├── scripts/
│   └── instalar_proyecto.ps1
├── backups/
├── documentation/
├── evidence/
├── .env
├── .gitignore
├── docker-compose.yml
├── requirements.txt
└── README.md
```

## 4. Requisitos previos

Para instalar y ejecutar el proyecto se necesita:

- Windows 10 u 11.
- Docker Desktop con Docker Compose.
- Python 3.10 o superior.
- Git.
- Visual Studio Code (recomendado).

Docker Desktop debe estar iniciado antes de ejecutar los comandos.

## 5. Configuración del entorno

### 5.1 Variables de entorno

Crear un archivo `.env` en la raíz del proyecto con las siguientes variables:

```env
POSTGRES_USER=hotel_admin
POSTGRES_PASSWORD=TU_CONTRASEÑA_SEGURA
```

La contraseña debe sustituirse por una propia. No se debe compartir ni subir el archivo `.env` al repositorio.

Para ejecutar el cliente y las pruebas Python, configurar también la variable de entorno en PowerShell:

```powershell
$env:HOTEL_DB_PASSWORD = "TU_CONTRASEÑA_SEGURA"
```

El valor debe coincidir con `POSTGRES_PASSWORD`.

### 5.2 Instalar dependencias Python

Desde la raíz del proyecto:

```powershell
python -m pip install -r requirements.txt
```

La dependencia principal es `psycopg[binary]`, utilizada para conectar Python con PostgreSQL.

## 6. Instalación del proyecto

El repositorio incluye un instalador automatizado:

```text
scripts/instalar_proyecto.ps1
```

Este script organiza la instalación de las estructuras, funciones y configuraciones de los cuatro nodos.

### 6.1 Advertencia sobre la instalación limpia

El instalador está diseñado para bases de datos nuevas y vacías. Comprueba que los contenedores estén activos y que las bases no contengan objetos de usuario antes de instalar.

**No ejecutar el instalador sobre bases de datos que ya contienen información del proyecto.** No es un actualizador ni un mecanismo para reconstruir una instalación existente.

El instalador fue revisado, pero todavía no se ha validado de principio a fin en un entorno limpio independiente. Por ello, su ejecución en una instalación nueva requiere verificar los resultados de cada etapa.

### 6.2 Levantar los cuatro nodos

Desde la raíz del proyecto:

```powershell
docker compose config
docker compose up -d
docker compose ps
```

Verificar que estén activos los siguientes contenedores:

- `hotel-postgres-cancun`
- `hotel-postgres-tulum`
- `hotel-postgres-bacalar`
- `hotel-postgres-central`

Estos comandos corresponden al entorno del proyecto. No eliminar volúmenes ni contenedores de otros proyectos Docker.

### 6.3 Ejecutar el instalador

En una instalación nueva, ejecutar:

```powershell
.\scripts\instalar_proyecto.ps1 -ConfirmarInstalacionLimpia
```

El instalador solicita confirmación antes de proceder. También realiza comprobaciones de los contenedores, las bases de datos y los archivos SQL necesarios.

Durante la configuración de las conexiones distribuidas pueden solicitarse datos de conexión mediante la terminal.

Al finalizar, se deben revisar los mensajes de instalación y verificar que los objetos y las conexiones se hayan creado correctamente.

## 7. Organización de los scripts SQL

Los scripts están separados por responsabilidad:

| Directorio       | Contenido                                                                                        |
| ---------------- | ------------------------------------------------------------------------------------------------ |
| `01_extensions`  | Extensiones de PostgreSQL, incluyendo `btree_gist`.                                              |
| `02_types`       | Tipos compuestos para direcciones y estancias.                                                   |
| `03_tables`      | Sedes, huéspedes, habitaciones, herencia, tarifas, temporadas, reservaciones, pagos y servicios. |
| `04_functions`   | Funciones PL/pgSQL para gestionar reservaciones.                                                 |
| `05_triggers`    | Bitácora, auditoría y cálculo automático de importes.                                            |
| `06_views`       | Vistas operativas.                                                                               |
| `07_indexes`     | Índices de optimización y elementos para pruebas de rendimiento.                                 |
| `08_partitions`  | Particionamiento de reservaciones y tablas auxiliares centrales.                                 |
| `09_distributed` | Publicaciones de replicación, configuración FDW y suscripciones.                                 |

El instalador organiza la ejecución de los scripts en los nodos correspondientes. No es necesario ejecutar manualmente cada archivo SQL cuando se realiza una instalación limpia mediante el instalador.

## 8. Funcionalidades implementadas

### 8.1 Administración de información

- Registro y consulta de huéspedes.
- Administración de habitaciones.
- Administración de tarifas y temporadas.
- Creación y consulta de reservaciones.
- Registro de pagos.
- Administración de servicios adicionales.

El modelo entidad-relación se encuentra en [09_diagrama_entidad_relacion.md](documentation/09_diagrama_entidad_relacion.md).

### 8.2 Características orientadas a objetos de PostgreSQL

- Tipos de datos compuestos.
- Herencia de tablas mediante `INHERITS`.
- Arreglos para almacenar amenidades.
- Campos `JSONB` para preferencias.
- Rangos `DATERANGE` para representar estancias.

### 8.3 Integridad y operaciones

- Restricciones de exclusión GiST para evitar traslapes de reservaciones.
- Funciones PL/pgSQL para crear reservaciones, consultar disponibilidad, cancelar y gestionar operaciones.
- Bloqueo de habitaciones mediante `SELECT FOR UPDATE` en las operaciones correspondientes.
- Triggers para auditoría y bitácora.
- Cálculo automático de importes, pagos y saldos.
- Vistas operativas.
- Índices B-tree, GiST y GIN.

### 8.4 Distribución

- Cuatro instancias PostgreSQL independientes.
- Particionamiento de reservaciones centrales por sede.
- Replicación lógica de las tres sedes hacia el nodo central.
- Consultas distribuidas mediante `postgres_fdw`.
- Traslado de reservaciones entre sedes mediante transacciones preparadas (2PC).

El traslado 2PC utiliza coordinación desde Python. `postgres_fdw` se utiliza para consultas distribuidas y no realiza automáticamente la coordinación de la transacción en dos fases.

## 9. Cliente Python de demostración

El cliente se encuentra en:

```text
python/client/main.py
```

Ejecutar desde la raíz del proyecto:

```powershell
python .\python\client\main.py
```

El menú principal permite:

1. Realizar operaciones en Cancún.
2. Realizar operaciones en Tulum.
3. Realizar operaciones en Bacalar.
4. Consultar el reporte consolidado.
5. Salir.

Dentro de cada sede se pueden realizar las siguientes operaciones:

- Consultar disponibilidad.
- Crear reservaciones.
- Consultar reservaciones.
- Realizar check-in.
- Realizar check-out.
- Cancelar reservaciones.

El reporte consolidado consulta la información distribuida mediante la vista central correspondiente.

## 10. Pruebas

Los scripts de prueba se encuentran en:

```text
python/tests/
```

### 10.1 Prueba de concurrencia

Archivo:

```text
python/tests/test_concurrencia.py
```

Utiliza dos hilos y conexiones independientes para intentar reservar simultáneamente una misma habitación y periodo.

El resultado comprobado fue:

- Una reservación aceptada.
- Una reservación rechazada por la restricción de exclusión GiST.
- Ninguna sobreventa de la habitación.

La operación rechazada produjo el código SQLSTATE `23P01`, correspondiente a una violación de restricción de exclusión.

Ejecutar:

```powershell
python .\python\tests\test_concurrencia.py
```

### 10.2 Prueba de transacción en dos fases

Archivo:

```text
python/tests/test_2pc.py
```

Comprueba el traslado de una reservación entre Cancún y Tulum mediante:

- `PREPARE TRANSACTION`.
- `COMMIT PREPARED`.

La prueba comprobó que la reservación dejó de existir en el nodo de origen, se conservó en el nodo de destino con la misma identificación y no quedaron transacciones preparadas pendientes.

Ejecutar:

```powershell
python .\python\tests\test_2pc.py
```

Estas pruebas utilizan conexiones y datos de las instancias del proyecto. Antes de ejecutarlas en una instalación nueva, se deben revisar sus datos de prueba y requisitos. No deben ejecutarse sobre bases de datos de producción.

## 11. Optimización y rendimiento

Se realizaron pruebas de rendimiento con 50,000 reservaciones generadas para comparar consultas con y sin utilización de índices.

Los resultados registrados durante el desarrollo fueron:

| Consulta | Sin índice | Con índice | Mejora aproximada |
| -------- | ---------: | ---------: | ----------------: |
| B-tree   |   5.967 ms |   0.230 ms |           96.15 % |
| GiST     |   7.497 ms |   0.406 ms |           94.58 % |

Las pruebas utilizaron `EXPLAIN ANALYZE` para revisar los planes de ejecución.

Para obtener la comparación sin índices se simularon las condiciones de ejecución deshabilitando los métodos de acceso por índices. Por tanto, los valores representan las ejecuciones medidas durante las pruebas y no una comparación histórica entre dos bases de datos diferentes.

Los tiempos pueden variar según el equipo y las condiciones de ejecución.

## 12. Respaldo y recuperación

El archivado WAL se configura para el nodo Cancún.

La configuración contempla:

- `archive_mode=on`.
- `archive_command` para almacenar los segmentos WAL.
- `archive_timeout=60s`.
- Un directorio persistente en `backups/cancun/wal`.

Se realizaron pruebas de:

- Respaldo físico mediante `pg_basebackup`.
- Verificación mediante `pg_verifybackup`.
- Restauración de una instancia independiente.
- Recuperación a un punto en el tiempo (PITR) mediante `recovery.signal` y `restore_command`.

El procedimiento de archivado y recuperación se demostró en Cancún. No se debe asumir que los otros nodos de sede tienen archivado WAL habilitado.

Los respaldos se almacenan localmente en `backups/`, directorio excluido del control de versiones.

## 13. Control de versiones

El proyecto utiliza Git para registrar los cambios de implementación.

Consultar el historial:

```powershell
git --no-pager log --oneline
```

Consultar el estado del repositorio:

```powershell
git status
```

Comprobar que los cambios no tengan errores de espacios o formato:

```powershell
git diff --check
```

## 14. Seguridad y consideraciones

- Las credenciales se administran mediante variables de entorno.
- El archivo `.env` no debe subirse al repositorio.
- Los respaldos no se incluyen en Git.
- Cada nodo utiliza un volumen independiente.
- Las pruebas deben ejecutarse en el entorno destinado al proyecto.
- El instalador está destinado exclusivamente a bases nuevas y vacías.
- La configuración de archivado WAL documentada corresponde al nodo Cancún.
- La arquitectura implementada no proporciona alta disponibilidad ni recuperación automática ante la caída de un nodo.
- La replicación lógica centraliza información, pero no sustituye una política completa de respaldo y recuperación para todas las sedes.
- La configuración actual no debe considerarse un aislamiento de escritura completo por sede para un entorno de producción.

## 15. Documentación complementaria

Los documentos del proyecto se encuentran en `documentation/`:

| Archivo                              | Descripción                                                    |
| ------------------------------------ | -------------------------------------------------------------- |
| `01_informe_academico.md`            | Informe académico del proyecto.                                |
| `02_requisitos_historias_usuario.md` | Requisitos funcionales, no funcionales e historias de usuario. |
| `03_planificacion_scrum.md`          | Planificación y organización del desarrollo.                   |
| `04_manual_tecnico.md`               | Arquitectura, implementación y procedimientos técnicos.        |
| `05_manual_usuario.md`               | Instrucciones de uso del cliente.                              |
| `06_referencias_ieee.md`             | Referencias bibliográficas.                                    |
| `07_declaracion_uso_ia.md`           | Declaración del uso de inteligencia artificial.                |
| `08_bitacora_uso_ia.md`              | Registro de interacciones y apoyo de IA.                       |
| `09_diagrama_entidad_relacion.md`    | Diagrama del modelo de datos.                                  |
| `10_diagrama_arquitectura.md`        | Diagrama de la arquitectura distribuida.                       |

## 16. Estado del proyecto

El proyecto cuenta con los siguientes componentes implementados y probados:

- Estructuras relacionales y características orientadas a objetos de PostgreSQL.
- Funciones, triggers, bitácora y vistas.
- Índices y pruebas de rendimiento con 50,000 reservaciones.
- Pruebas de concurrencia.
- Respaldo físico y recuperación PITR en Cancún.
- Particionamiento central.
- Replicación lógica desde las tres sedes.
- Consultas distribuidas mediante FDW.
- Traslado de reservaciones mediante 2PC.
- Cliente Python de demostración.

El instalador automatizado está preparado para instalaciones limpias, pero su ejecución integral en un entorno nuevo todavía requiere validación.

Este proyecto constituye un prototipo académico de base de datos distribuida. Sus mecanismos de replicación, consulta y coordinación permiten demostrar los conceptos solicitados, pero no equivalen a una infraestructura de producción con alta disponibilidad, aislamiento completo de sedes y recuperación automática.
