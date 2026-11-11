# 4. MANUAL TÉCNICO

## 4.1 Descripción general

El proyecto implementa una base de datos distribuida para administrar reservaciones hoteleras en Cancún, Tulum y Bacalar. La arquitectura utiliza cuatro instancias independientes de PostgreSQL 18.6 ejecutadas mediante Docker Compose.

Tres instancias funcionan como nodos operativos y una cuarta instancia funciona como nodo central de reportes.

El modelo lógico de la base de datos, sus entidades principales, atributos, claves y relaciones se representa en el [diagrama entidad-relación](09_diagrama_entidad_relacion.md). Este documento también muestra las especializaciones implementadas mediante herencia nativa de PostgreSQL.

## 4.2 Arquitectura

| Nodo    | Contenedor             | Base de datos | Puerto local |
| ------- | ---------------------- | ------------- | ------------ |
| Cancún  | hotel-postgres-cancun  | hotel_cancun  | 5541         |
| Tulum   | hotel-postgres-tulum   | hotel_tulum   | 5542         |
| Bacalar | hotel-postgres-bacalar | hotel_bacalar | 5543         |
| Central | hotel-postgres-central | hotel_central | 5544         |

Los nodos se comunican mediante una red Docker privada denominada `hotel-proyecto-red`.

Cada nodo operativo administra sus operaciones hoteleras. El nodo central recibe información mediante replicación lógica y consulta información remota mediante postgres_fdw.

La distribución de los componentes, las conexiones entre los cuatro nodos, la replicación lógica, el particionamiento y las consultas mediante PostgreSQL FDW se muestran en el [diagrama de arquitectura distribuida](10_diagrama_arquitectura.md).

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

La instalación debe probarse en un entorno limpio antes de considerar el procedimiento validado de extremo a extremo. La sintaxis y las referencias de archivos del instalador fueron revisadas, pero no se ejecutó sobre las bases actuales.

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

Se utilizan claves primarias UUID, claves foráneas, restricciones CHECK, índices únicos y restricciones de exclusión.

## 4.9 Características orientadas a objetos

Se implementan tipos compuestos:

- `direccion_type`
- `rango_estancia`

También se utilizan:

- Herencia de tablas mediante `INHERITS`.
- Arreglos `TEXT[]` para amenidades.
- Campos `JSONB` para preferencias de huéspedes.

La herencia de PostgreSQL no transmite automáticamente las claves primarias ni las claves foráneas. Por ello, las tablas especializadas incluyen restricciones explícitas.

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

Se utilizan tres tipos principales de índices:

- B-tree para búsquedas por identificadores, estados y fechas.
- GiST para consultas de rangos y restricciones de exclusión.
- GIN para búsquedas sobre JSONB y arreglos.

La evaluación de rendimiento utilizó 50,000 reservaciones generadas.

Resultados observados:

| Consulta      |    Antes |  Después |  Mejora |
| ------------- | -------: | -------: | ------: |
| Índice B-tree | 5.967 ms | 0.230 ms | 96.15 % |
| Índice GiST   | 7.497 ms | 0.406 ms | 94.58 % |

Las mediciones representan los planes y tiempos obtenidos en el entorno local de prueba. La comparación sin índice se simuló deshabilitando los métodos de acceso por índice durante la consulta; no representa una medición histórica previa a la creación del índice.

## 4.12 Concurrencia e integridad

La función de creación de reservaciones utiliza bloqueo de fila mediante `SELECT FOR UPDATE`.

Además, la tabla `reservaciones` implementa una restricción de exclusión GiST para impedir que una habitación tenga reservaciones activas con periodos superpuestos.

La prueba Python utiliza dos hilos y conexiones independientes. El resultado fue una reservación aceptada y otra rechazada por la restricción `ex_reservacion_sin_traslape`.

## 4.13 Respaldo y recuperación

En el nodo Cancún se configuraron:

- `archive_mode=on`.
- `archive_command`.
- `archive_timeout=60s`.
- Directorio de archivado WAL.
- Respaldo físico mediante `pg_basebackup`.

El respaldo se validó mediante:

```powershell
docker exec hotel-postgres-cancun pg_verifybackup /backups/cancun/basebackup
```

La recuperación PITR se realizó en un directorio independiente, utilizando `recovery.signal`, `restore_command` y un punto temporal objetivo.

La prueba confirmó que se recuperó el estado anterior al registro insertado después del punto de recuperación, sin alterar la base de datos operativa original.

El procedimiento de respaldo y PITR fue comprobado en Cancún, no en los cuatro nodos.

## 4.14 Replicación lógica

Cada sede publica ocho tablas operativas:

- huespedes
- habitaciones
- tarifas
- temporadas
- reservaciones
- pagos
- servicios
- reservacion_servicios

El nodo central contiene tres suscripciones:

- `sub_cancun`
- `sub_tulum`
- `sub_bacalar`

Las publicaciones utilizan filtros por `sede_id`. Se verificó la propagación de operaciones INSERT, UPDATE y DELETE.

## 4.15 Consultas distribuidas

El nodo central utiliza la extensión `postgres_fdw` para acceder a las tres sedes.

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

El traslado de reservaciones se implementó mediante coordinación desde Python y transacciones preparadas de PostgreSQL.

Se utilizan:

- `PREPARE TRANSACTION`
- `COMMIT PREPARED`
- `ROLLBACK PREPARED`

El script `python/tests/test_2pc.py` demuestra el traslado de una reservación de Cancún a Tulum.

La coordinación de las dos transacciones es responsabilidad del programa Python. No se atribuye a postgres_fdw la ejecución automática de 2PC.

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

Las pruebas requieren que los contenedores estén activos y que la variable `HOTEL_DB_PASSWORD` esté configurada.

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
