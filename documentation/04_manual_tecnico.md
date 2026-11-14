# 4. MANUAL TÉCNICO

## 4.1 Descripción general

El proyecto implementa una base de datos distribuida para administrar reservaciones hoteleras en Cancún, Tulum y Bacalar. La arquitectura utiliza cuatro instancias independientes de PostgreSQL 18.6 ejecutadas mediante Docker Compose [1], [3].

Tres instancias funcionan como nodos operativos y una cuarta instancia funciona como nodo central de reportes.

El modelo lógico de la base de datos, sus entidades principales, atributos, claves y relaciones se representa en el [diagrama entidad-relación](09_diagrama_entidad_relacion.md). Este documento también muestra las especializaciones implementadas mediante herencia nativa de PostgreSQL [9].

## 4.2 Arquitectura

| Nodo    | Contenedor             | Base de datos | Puerto local |
| ------- | ---------------------- | ------------- | -----------: |
| Cancún  | hotel-postgres-cancun  | hotel_cancun  |         5541 |
| Tulum   | hotel-postgres-tulum   | hotel_tulum   |         5542 |
| Bacalar | hotel-postgres-bacalar | hotel_bacalar |         5543 |
| Central | hotel-postgres-central | hotel_central |         5544 |

Los puertos indicados son los valores predeterminados del entorno original. El cliente y las pruebas permiten sustituirlos con `HOTEL_DB_PORT_CANCUN`, `HOTEL_DB_PORT_TULUM`, `HOTEL_DB_PORT_BACALAR` y `HOTEL_DB_PORT_CENTRAL`, sin editar el código.

Los nodos se comunican mediante una red Docker privada denominada `hotel-proyecto-red`.

Cada nodo operativo administra sus operaciones hoteleras. El nodo central recibe información mediante replicación lógica [17] y consulta información remota mediante `postgres_fdw` [18].

La distribución de los componentes, las conexiones entre los cuatro nodos, la replicación lógica, el particionamiento [16] y las consultas mediante PostgreSQL FDW se muestran en el [diagrama de arquitectura distribuida](10_diagrama_arquitectura.md).

## 4.3 Requisitos de instalación

- Windows 11 o sistema compatible.
- Docker Desktop con soporte para contenedores Linux.
- Docker Compose.
- Python 3.10 o superior.
- Git.
- Visual Studio Code.
- pgAdmin (opcional para administración gráfica).

## 4.4 Estructura del proyecto

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
├── documentation/
├── evidence/
├── python/
│   ├── client/
│   ├── generators/
│   └── tests/
├── scripts/
├── backups/
├── docker-compose.yml
├── requirements.txt
├── README.md
└── .env
```

## 4.5 Configuración de variables de entorno

El archivo `.env` contiene las credenciales utilizadas por los contenedores.

Ejemplo de estructura:

```env
POSTGRES_USER=hotel_admin
POSTGRES_PASSWORD=REEMPLAZAR_POR_UNA_CONTRASENA_SEGURA
```

No se debe publicar el archivo `.env` en el repositorio. Las credenciales reales deben mantenerse privadas.

Para las pruebas Python se utiliza la variable de entorno `HOTEL_DB_PASSWORD`.

La variable `HOTEL_DB_PASSWORD` debe configurarse en la sesión de PowerShell antes de ejecutar el cliente Python o los scripts de prueba. Su valor debe coincidir con `POSTGRES_PASSWORD` definido en el archivo `.env`. Esta variable se utiliza para establecer las conexiones desde Python hacia las instancias PostgreSQL.

El módulo `python/hotel_config.py` centraliza la configuración. Primero consulta las variables de entorno y, si no existen, lee el archivo `.env` de la raíz del proyecto. Los valores predeterminados conservan los puertos del entorno original:

| Variable                 | Valor predeterminado | Uso                                      |
| ------------------------ | -------------------- | ---------------------------------------- |
| `HOTEL_DB_HOST`          | `127.0.0.1`          | Host de los cuatro nodos.                |
| `HOTEL_DB_PORT_CANCUN`   | `5541`               | Puerto de `hotel_cancun`.                |
| `HOTEL_DB_PORT_TULUM`    | `5542`               | Puerto de `hotel_tulum`.                 |
| `HOTEL_DB_PORT_BACALAR`  | `5543`               | Puerto de `hotel_bacalar`.               |
| `HOTEL_DB_PORT_CENTRAL`  | `5544`               | Puerto de `hotel_central`.               |
| `HOTEL_DB_USER`          | `hotel_admin`        | Usuario de conexión.                     |
| `HOTEL_ENV_NAME`         | `original`           | Nombre del entorno para los mensajes.    |
| `HOTEL_EXPECTED_ENV`     | sin valor            | Protección opcional contra entornos incorrectos. |

Si se define `HOTEL_EXPECTED_ENV` y no coincide con `HOTEL_ENV_NAME`, los scripts se detienen antes de conectarse. Esto permite evitar ejecuciones accidentales sobre el entorno original cuando se trabaja con una copia aislada.

## 4.6 Inicio de los servicios

Desde PowerShell, en la raíz del proyecto:

```powershell
docker compose up -d
```

Verificar los contenedores:

```powershell
docker compose ps
```

Consultar los registros:

```powershell
docker compose logs --tail 50
```

Para detener los servicios:

```powershell
docker compose stop
```

No se recomienda utilizar comandos que eliminen volúmenes cuando se desea conservar los datos.

## 4.7 Instalación de la estructura de bases de datos

El proyecto contiene el script:

```text
scripts/instalar_proyecto.ps1
```

Este script automatiza la instalación de los objetos de base de datos en los cuatro nodos.

**Advertencia:** el instalador está diseñado exclusivamente para bases de datos nuevas o vacías. No debe ejecutarse sobre las bases de datos actuales del proyecto, ya que contienen estructuras, configuraciones y datos de prueba.

Para una instalación limpia:

1. Preparar una instancia nueva del entorno.
2. Configurar el archivo `.env`.
3. Iniciar los servicios.
4. Verificar que las cuatro bases estén vacías.
5. Ejecutar:

```powershell
.\scripts\instalar_proyecto.ps1 -ConfirmarInstalacionLimpia
```

6. Confirmar la operación cuando el script lo solicite.
7. Verificar publicaciones, suscripciones y tablas externas.
8. Cargar los datos de demostración con el paso independiente descrito en la sección 4.7.1.

Durante la configuración de las conexiones distribuidas, el instalador solicita las contraseñas de FDW y de replicación mediante `Read-Host -AsSecureString`. Los valores se pasan a `psql` solo a través de variables de entorno temporales y se eliminan al finalizar; no se escriben en el repositorio ni en la línea de comandos. Antes de crear las suscripciones, el instalador verifica la conectividad de los servidores FDW.

El instalador fue validado de principio a fin el 13 de noviembre de 2026 en una copia aislada con contenedores `hotel-prueba-postgres-*`, puertos `5641`–`5644`, red `hotel-prueba-red` y volúmenes propios. La ejecución creó las cuatro bases, tres publicaciones de ocho tablas cada una, tres suscripciones y 24 relaciones de suscripción en estado `r`, además de 24 tablas externas de FDW. El entorno original no se modificó.

Las evidencias de esa validación se encuentran en `evidence/validacion_entorno_limpio_20261113/`.

### 4.7.1 Carga de datos de demostración

La carga de datos demo es independiente de la instalación estructural y debe ejecutarse después de crear las publicaciones y suscripciones:

```powershell
.\scripts\cargar_datos_demo.ps1 -ConfirmarCargaDemo
```

El script carga datos en Cancún, Tulum y Bacalar y permite que la replicación los propague al nodo central. Es idempotente: utiliza identificadores fijos y actualizaciones controladas, por lo que puede ejecutarse varias veces sin duplicar registros. En la validación del entorno limpio se ejecutó dos veces y los conteos permanecieron sin cambios.

## 4.8 Modelo de datos

Las principales tablas operativas son:

- `sedes`
- `huespedes`
- `habitaciones`
- `tarifas`
- `temporadas`
- `reservaciones`
- `pagos`
- `servicios`
- `reservacion_servicios`
- `bitacora`

Se utilizan claves primarias UUID, claves foráneas, restricciones CHECK, índices únicos y restricciones de exclusión para mantener la integridad de los datos [7].

## 4.9 Características orientadas a objetos

Se implementan tipos compuestos:

- `direccion_type`
- `rango_estancia`

También se utilizan:

- Herencia de tablas mediante `INHERITS` [9].
- Arreglos `TEXT[]` para amenidades.
- Campos `JSONB` para preferencias de huéspedes [8].

La herencia de PostgreSQL no transmite automáticamente las claves primarias ni las claves foráneas. Por ello, las tablas especializadas incluyen restricciones explícitas [9].

## 4.10 Funciones y triggers

Las funciones principales son:

| Función                       | Responsabilidad                     |
| ----------------------------- | ----------------------------------- |
| `fn_crear_reservacion`        | Validar y crear una reservación.    |
| `fn_realizar_checkin`         | Registrar la entrada del huésped.   |
| `fn_realizar_checkout`        | Finalizar la estancia.              |
| `fn_cancelar_reservacion`     | Cancelar reservaciones permitidas.  |
| `fn_consultar_disponibilidad` | Consultar habitaciones disponibles. |

Los triggers se dividen en dos grupos:

**Auditoría**

- Registran inserciones, actualizaciones y eliminaciones.
- Conservan datos anteriores y nuevos cuando corresponda.

**Cálculo de importes**

- Calculan el total de alojamiento y servicios.
- Actualizan el total pagado.
- Calculan el saldo pendiente.
- Validan asociaciones y monedas.

## 4.11 Índices y optimización

Se utilizan tres tipos principales de índices [10]:

- B-tree para búsquedas por identificadores, estados y fechas.
- GiST para consultas de rangos y restricciones de exclusión.
- GIN para búsquedas sobre JSONB y arreglos.

La evaluación de rendimiento utilizó 50,000 reservaciones generadas. Los planes de ejecución se analizaron mediante `EXPLAIN ANALYZE` [11].

Resultados observados:

| Consulta      |    Antes |  Después |  Mejora |
| ------------- | -------: | -------: | ------: |
| Índice B-tree | 5.967 ms | 0.230 ms | 96.15 % |
| Índice GiST   | 7.497 ms | 0.406 ms | 94.58 % |

Las mediciones representan los planes y tiempos obtenidos en el entorno local de prueba. La comparación sin índice se simuló deshabilitando los métodos de acceso por índice durante la consulta; no representa una medición histórica previa a la creación del índice.

## 4.12 Concurrencia e integridad

La función de creación de reservaciones utiliza bloqueo de fila mediante `SELECT FOR UPDATE` [13].

Además, la tabla `reservaciones` implementa una restricción de exclusión GiST basada en rangos [12] para impedir que una habitación tenga reservaciones activas con periodos superpuestos.

La prueba Python utiliza dos hilos y conexiones independientes para intentar reservar simultáneamente una misma habitación durante el mismo periodo. La prueba se ejecutó satisfactoriamente en tres ocasiones, obteniendo en cada ejecución una reservación aceptada y otra rechazada por la restricción `ex_reservacion_sin_traslape`. El rechazo produjo el código SQLSTATE `23P01`, correspondiente a una violación de restricción de exclusión. Esto demuestra que la base de datos impide la sobreventa de una habitación ante solicitudes concurrentes.

## 4.13 Respaldo y recuperación

En el nodo Cancún se configuraron:

- `archive_mode=on`.
- `archive_command`.
- `archive_timeout=60s`.
- Directorio de archivado WAL, montado desde `backups/cancun/wal` del repositorio hacia `/backups/cancun/wal` dentro del contenedor.
- Respaldo físico mediante `pg_basebackup` [14].

El respaldo se validó mediante:

```powershell
docker exec hotel-postgres-cancun pg_verifybackup /backups/cancun/basebackup/respaldo_20261110
```

La recuperación PITR se realizó en un directorio independiente, utilizando `recovery.signal`, `restore_command` y un punto temporal objetivo [15].

La prueba confirmó que se recuperó el estado anterior al registro insertado después del punto de recuperación, sin alterar la base de datos operativa original.

El procedimiento de respaldo y PITR fue comprobado en Cancún, no en los cuatro nodos.

## 4.14 Replicación lógica

Cada sede publica ocho tablas operativas:

- `huespedes`
- `habitaciones`
- `tarifas`
- `temporadas`
- `reservaciones`
- `pagos`
- `servicios`
- `reservacion_servicios`

El nodo central contiene tres suscripciones:

- `sub_cancun`
- `sub_tulum`
- `sub_bacalar`

Las publicaciones utilizan filtros por `sede_id`. Se verificó la propagación de operaciones INSERT, UPDATE y DELETE mediante replicación lógica [17].

## 4.15 Consultas distribuidas

El nodo central utiliza la extensión `postgres_fdw` para acceder a las tres sedes [18].

Los servidores configurados son:

- `fdw_cancun`
- `fdw_tulum`
- `fdw_bacalar`

Las tablas remotas se organizan en los esquemas:

- `remoto_cancun`
- `remoto_tulum`
- `remoto_bacalar`

La vista `vw_reservaciones_distribuidas` permite consultar reservaciones de las tres sedes.

## 4.16 Transacciones distribuidas

El traslado de reservaciones se implementó mediante coordinación desde Python y transacciones preparadas de PostgreSQL [19].

Se utilizan:

- `PREPARE TRANSACTION`
- `COMMIT PREPARED`
- `ROLLBACK PREPARED`

El script `python/tests/test_2pc.py` demuestra el traslado de una reservación de Cancún a Tulum. La prueba crea su propia reservación en Cancún, captura el identificador generado y utiliza el marcador `PRUEBA_2PC_AUTOMATICA` para localizar y eliminar únicamente los datos de ejecuciones anteriores. Por ello, puede ejecutarse repetidamente sin editar identificadores. La variable opcional `HOTEL_2PC_RESERVACION_ID` permite utilizar una reservación existente en el modo manual.

La prueba `python/tests/test_2pc.py` demostró el traslado de una reservación de Cancún a Tulum mediante una transacción distribuida en dos fases. Se verificó que la reservación dejó de existir en el nodo de origen y se encontró en el nodo de destino conservando su identificador. También se comprobaron los registros de auditoría correspondientes a la eliminación en Cancún y la inserción en Tulum. La operación finalizó correctamente, con ambas transacciones confirmadas y sin transacciones preparadas pendientes.

En el entorno limpio aislado, la prueba se ejecutó dos veces consecutivas con código de salida `0` y generó identificadores distintos en cada ejecución. La última reservación trasladada quedó en Tulum como evidencia; la bitácora registró `DELETE` en Cancún e `INSERT` en Tulum, y los cuatro nodos reportaron cero transacciones preparadas pendientes.

**Limitaciones y recuperación de transacciones distribuidas:**

Si el coordinador falla después de ejecutar PREPARE TRANSACTION y antes de completar la segunda fase, pueden quedar transacciones preparadas pendientes de resolución en los nodos participantes. Estas transacciones mantienen recursos y requieren intervención administrativa para decidir si deben confirmarse mediante COMMIT PREPARED o cancelarse mediante ROLLBACK PREPARED.

Para identificar transacciones pendientes se puede consultar la vista del sistema `pg_prepared_xacts`. El mecanismo implementado demuestra el traslado distribuido de reservaciones, pero no incorpora un coordinador persistente con recuperación automática ante fallos. Por ello, la resolución de transacciones en estado preparado debe realizarse de manera controlada.

## 4.17 Cliente Python

El archivo principal es:

```text
python/client/main.py
```

Para instalar dependencias:

```powershell
python -m pip install -r requirements.txt
```

Configurar la contraseña para la sesión actual de PowerShell:

```powershell
$env:HOTEL_DB_PASSWORD = "TU_CONTRASENA"
```

Ejecutar el cliente:

```powershell
python .\python\client\main.py
```

El cliente permite seleccionar una sede, consultar disponibilidad, crear reservaciones, consultar registros, realizar check-in y check-out, cancelar y consultar el reporte consolidado.

La conexión con PostgreSQL se realiza mediante Psycopg 3 [5].

## 4.18 Pruebas automatizadas

Los archivos de prueba principales son:

```text
python/tests/test_concurrencia.py
python/tests/test_2pc.py
```

Ejecutar:

```powershell
python .\python\tests\test_concurrencia.py
python .\python\tests\test_2pc.py
```

Las pruebas requieren que los contenedores estén activos y que `HOTEL_DB_PASSWORD` esté configurada. La conexión se puede dirigir a otro entorno con `HOTEL_DB_HOST` y las variables `HOTEL_DB_PORT_*` descritas en la sección 4.5.

**Consideraciones para ejecutar las pruebas:**

La prueba de concurrencia busca un periodo disponible para la habitación configurada y requiere que existan previamente los registros de sede, huésped, habitación y tarifa utilizados por el script. Antes de ejecutar, elimina las reservaciones con el marcador `PRUEBA_CONCURRENCIA_`.

La prueba 2PC funciona en modo automático: crea su propia reservación en Cancún, la traslada a Tulum y limpia solo las reservaciones identificadas con el marcador `PRUEBA_2PC_AUTOMATICA`. No es necesario preparar una reservación ni actualizar el identificador para repetirla. El modo manual con `HOTEL_2PC_RESERVACION_ID` solo debe usarse con una reservación existente que no haya sido trasladada.

Ambas pruebas devuelven `0` cuando el resultado es correcto y `1` cuando fallan. En la validación del entorno limpio, la prueba de concurrencia devolvió `0` y la prueba 2PC devolvió `0` en dos ejecuciones consecutivas.

## 4.19 Seguridad y mantenimiento

- No publicar contraseñas ni archivos `.env`.
- No ejecutar scripts destructivos sobre bases con información.
- Mantener respaldos fuera de los volúmenes operativos.
- Verificar el estado de replicación.
- Revisar periódicamente los registros de PostgreSQL.
- Probar los procedimientos de recuperación en entornos independientes.
- Utilizar credenciales con privilegios mínimos en un despliegue real.

## 4.20 Limitaciones técnicas

La solución se encuentra implementada en un entorno local de demostración. La replicación lógica y las consultas distribuidas fueron probadas, pero la arquitectura todavía requiere controles adicionales para producción, como restricciones de escritura por sede, administración de usuarios y privilegios, gestión segura de credenciales y monitoreo de disponibilidad.

El respaldo PITR está configurado en Cancún. Para una infraestructura productiva sería necesario definir una política de respaldo y recuperación para cada nodo.

---

**Fin del manual técnico.**
