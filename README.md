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
│   ├── 09_distributed/
│   └── 10_seed/
├── docker/
│   └── init/
├── python/
│   ├── client/
│   │   └── main.py
│   ├── generators/
│   ├── hotel_config.py
│   └── tests/
│       ├── test_2pc.py
│       └── test_concurrencia.py
├── scripts/
│   ├── cargar_datos_demo.ps1
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

El cliente y las pruebas cargan primero las variables de entorno y, si no existen, los valores del archivo `.env`. Los puertos predeterminados son los del entorno original: Cancún `5541`, Tulum `5542`, Bacalar `5543` y Central `5544`.

Para ejecutar contra una copia aislada sin modificar el código, se pueden definir estas variables en la sesión de PowerShell:

```powershell
$env:HOTEL_DB_HOST = "127.0.0.1"
$env:HOTEL_DB_PORT_CANCUN = "5641"
$env:HOTEL_DB_PORT_TULUM = "5642"
$env:HOTEL_DB_PORT_BACALAR = "5643"
$env:HOTEL_DB_PORT_CENTRAL = "5644"
$env:HOTEL_DB_USER = "hotel_admin"
$env:HOTEL_ENV_NAME = "prueba-limpia"
$env:HOTEL_EXPECTED_ENV = "prueba-limpia"
```

`HOTEL_EXPECTED_ENV` es opcional y funciona como protección: si `HOTEL_ENV_NAME` no coincide, los scripts se detienen antes de conectarse. La contraseña se toma de `HOTEL_DB_PASSWORD` o de `POSTGRES_PASSWORD`; nunca se imprime en los mensajes.

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

El instalador fue validado de principio a fin el 13 de noviembre de 2026 en una copia aislada del proyecto (`proyecto-hotelero-distribuido-prueba-limpia`). Esa copia utilizó contenedores `hotel-prueba-postgres-*`, puertos `5641`–`5644`, la red `hotel-prueba-red` y volúmenes propios, sin modificar el entorno original. La validación creó las cuatro bases, tres publicaciones, tres suscripciones, 24 relaciones de suscripción en estado `r` y 24 tablas externas de FDW. Las evidencias se encuentran en `evidence/validacion_entorno_limpio_20261113/`.

La instalación estructural no carga datos de demostración. Después de instalar y comprobar la replicación, los datos demo se cargan con un paso independiente (sección 6.5).

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

Durante la configuración de las conexiones distribuidas se solicitan las contraseñas de FDW y de replicación. La captura se realiza con `Read-Host -AsSecureString`; los valores se pasan a `psql` únicamente mediante variables de entorno temporales y se eliminan al terminar. No se escriben en el repositorio, en los scripts SQL ni en la línea de comandos.

Antes de crear las suscripciones, el instalador comprueba la conectividad de los servidores FDW. Al finalizar, se deben revisar los mensajes y verificar que las publicaciones, suscripciones y tablas externas se hayan creado correctamente.

### 6.4 Verificar la instalación

Comprobar los contenedores y las relaciones de replicación:

```powershell
docker compose ps
docker exec hotel-postgres-central psql -U hotel_admin -d hotel_central -c "SELECT subname, subenabled FROM pg_subscription ORDER BY subname;"
docker exec hotel-postgres-central psql -U hotel_admin -d hotel_central -c "SELECT srsubstate::text AS estado, COUNT(*) FROM pg_subscription_rel GROUP BY srsubstate;"
```

El estado esperado es `r` para las 24 relaciones de suscripción. También se pueden contar las tablas externas:

```powershell
docker exec hotel-postgres-central psql -U hotel_admin -d hotel_central -c "SELECT COUNT(*) FROM information_schema.foreign_tables WHERE foreign_table_schema LIKE 'remoto_%';"
```

### 6.5 Cargar datos de demostración

La carga de datos demo es un paso separado de la instalación estructural. Debe ejecutarse después de crear las publicaciones y suscripciones para que los datos se repliquen al nodo central:

```powershell
.\scripts\cargar_datos_demo.ps1 -ConfirmarCargaDemo
```

El script carga datos en Cancún, Tulum y Bacalar. Es idempotente: puede ejecutarse nuevamente sin duplicar registros porque utiliza identificadores fijos y actualizaciones controladas. Al finalizar, el nodo central debe recibir los datos mediante replicación lógica.

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
| `10_seed`        | Datos de demostración idempotentes para las tres sedes.                                          |

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

La prueba busca un periodo disponible para la habitación configurada y requiere que existan los registros de sede, huésped, habitación y tarifa utilizados por el script. Antes de ejecutar, elimina las reservaciones identificadas con el marcador `PRUEBA_CONCURRENCIA_` para no acumular datos de ejecuciones anteriores.

El resultado comprobado fue:

- Una reservación aceptada.
- Una reservación rechazada por la restricción de exclusión GiST.
- Ninguna sobreventa de la habitación.

La operación rechazada produjo el código SQLSTATE `23P01`, correspondiente a una violación de restricción de exclusión. La prueba se ejecutó satisfactoriamente en tres ocasiones en el entorno original y volvió a pasar en el entorno limpio aislado. Las salidas de las tres ejecuciones están en `evidence/concurrencia_20261124/`.

Ejecutar:

```powershell
python .\python\tests\test_concurrencia.py
```

### 10.2 Prueba de transacción en dos fases

Archivo:

```text
python/tests/test_2pc.py
```

La prueba crea su propia reservación en Cancún, captura su identificador y la traslada a Tulum mediante:

- `PREPARE TRANSACTION`.
- `COMMIT PREPARED` o `ROLLBACK PREPARED` según el resultado de la fase de preparación.

Las reservaciones creadas por ejecuciones anteriores se identifican con el marcador `PRUEBA_2PC_AUTOMATICA` y se eliminan al inicio. Por ello, la prueba puede ejecutarse repetidamente sin editar identificadores. Al finalizar, deja la última reservación trasladada en Tulum como evidencia y comprueba que no queden transacciones preparadas pendientes en los nodos participantes.

La prueba comprobó que la reservación dejó de existir en el nodo de origen, se conservó en el nodo de destino con la misma identificación, la bitácora registró `DELETE` en Cancún e `INSERT` en Tulum, y no quedaron transacciones preparadas pendientes. Se ejecutó dos veces consecutivas con identificadores distintos y código de salida `0` en el entorno limpio aislado. También se ejecutó dos veces en el entorno original el 24/11/2026; las salidas están en `evidence/2pc_20261124/`.

Ejecutar:

```powershell
python .\python\tests\test_2pc.py
```

La variable opcional `HOTEL_2PC_RESERVACION_ID` permite usar una reservación existente en Cancún en lugar de crear una nueva. Este modo es manual y solo debe utilizarse con una reservación que no haya sido trasladada.

**Consideraciones para ejecutar las pruebas:**

La prueba de concurrencia requiere que existan previamente los registros de sede, huésped, habitación y tarifa utilizados por el script.

La prueba 2PC requiere una configuración válida de Cancún y Tulum. El modo automático no necesita preparar datos manualmente; el modo con `HOTEL_2PC_RESERVACION_ID` sí requiere una reservación existente y no trasladada.

Ambas pruebas devuelven código de salida `0` cuando el resultado es correcto y `1` cuando fallan. Esto permite integrarlas en verificaciones automatizadas.

Estas pruebas deben ejecutarse únicamente en el entorno destinado al proyecto, nunca sobre bases de datos de producción.

## 11. Optimización y rendimiento

Se realizaron pruebas de rendimiento con 50,000 reservaciones generadas para comparar consultas con y sin utilización de índices.

Los resultados de la ejecución del 24/11/2026, con 50,000 reservaciones, fueron:

| Consulta | Sin índice | Con índice | Mejora aproximada |
| -------- | ---------: | ---------: | ----------------: |
| B-tree   |  13.018 ms |   0.056 ms |           99.57 % |
| GiST     |   9.308 ms |   0.343 ms |           96.31 % |

Las pruebas utilizaron `EXPLAIN ANALYZE` para revisar los planes de ejecución. Las salidas completas están en `evidence/rendimiento_20261124/`.

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
- Traslado de reservaciones mediante 2PC automatizado.
- Cliente Python de demostración.
- Instalador validado en un entorno limpio aislado, con datos demo, replicación y pruebas de concurrencia y 2PC.
- Lista de cotejo 19/19 y matriz de trazabilidad en el informe (sección 9.2).
- Evidencias renovadas de concurrencia, 2PC y rendimiento en `evidence/concurrencia_20261124/`, `evidence/2pc_20261124/` y `evidence/rendimiento_20261124/`.

El instalador automatizado fue ejecutado de principio a fin en una copia aislada y sus resultados se verificaron sin modificar el entorno original. Las evidencias están en `evidence/validacion_entorno_limpio_20261113/`.

Este proyecto constituye un prototipo académico de base de datos distribuida. Sus mecanismos de replicación, consulta y coordinación permiten demostrar los conceptos solicitados, pero no equivalen a una infraestructura de producción con alta disponibilidad, aislamiento completo de sedes y recuperación automática.
