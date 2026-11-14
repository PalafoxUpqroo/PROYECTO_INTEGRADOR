# BASE DE DATOS DISTRIBUIDA PARA RESERVACIONES DE UNA CADENA HOTELERA CON SEDES EN CANCÚN, TULUM Y BACALAR {.unlisted}

## PORTADA

**Universidad Politécnica de Quintana Roo**

**Ingeniería en Software**

**Asignatura:** Bases de Datos

**Proyecto integrador:** Base de datos distribuida para reservaciones de una cadena hotelera con sedes en Cancún, Tulum y Bacalar.

**Presenta:** Alejandro Marron Palafox

**Matrícula:** 202300141


**Lugar:** Cancún, Quintana Roo, México.

**Fecha de entrega:** 26 de noviembre de 2026.

---

\newpage

# 1. Introducción

La administración de reservaciones en una cadena hotelera requiere mantener información consistente y disponible entre sus diferentes establecimientos. Cuando cada sede trabaja con información aislada, pueden presentarse problemas como duplicidad de reservaciones, dificultades para consultar la ocupación general, falta de sincronización de datos y complicaciones para recuperar la información ante fallas.

El presente proyecto consiste en el diseño e implementación de una base de datos distribuida para una cadena hotelera con establecimientos en Cancún, Tulum y Bacalar. La solución utiliza PostgreSQL como sistema gestor de bases de datos [1] y una arquitectura compuesta por tres nodos operativos, correspondientes a cada sede, y un nodo central destinado a la consolidación de información y generación de reportes. El desarrollo incorpora características relacionales y orientadas a objetos, funciones almacenadas, restricciones de integridad, mecanismos de concurrencia, respaldo, recuperación y tecnologías de distribución de datos.

# 2. Planteamiento del problema

Una cadena hotelera que administra diferentes establecimientos necesita controlar las reservaciones, huéspedes, habitaciones, tarifas, pagos y servicios de manera coordinada. Cuando cada sede mantiene su propia información sin mecanismos adecuados de comunicación, se dificulta obtener una visión consolidada de la operación y se incrementa el riesgo de inconsistencias.

Entre los principales problemas se encuentran las reservaciones simultáneas de una misma habitación, la falta de disponibilidad de información consolidada, las dificultades para consultar el comportamiento de las distintas sedes y la posibilidad de pérdida de información ante fallas del sistema. Estas situaciones pueden afectar la operación, la atención al huésped y la administración general de los establecimientos.

Por lo anterior, se propone desarrollar una base de datos distribuida que permita gestionar las operaciones en instancias independientes por sede, mantener información consolidada en un nodo central y aplicar mecanismos de integridad, concurrencia, replicación y recuperación para mejorar la confiabilidad del sistema.

# 3. Objetivos

## 3.1 Objetivo general

Diseñar e implementar una base de datos distribuida utilizando PostgreSQL para administrar las reservaciones de una cadena hotelera con sedes en Cancún, Tulum y Bacalar, mediante una arquitectura de nodos independientes y un servidor central que permita mantener la integridad de los datos, prevenir reservaciones traslapadas, facilitar las consultas consolidadas y recuperar información ante posibles fallas.

## 3.2 Objetivos específicos

- Diseñar un modelo relacional normalizado para administrar huéspedes, habitaciones, tarifas, temporadas, reservaciones, pagos y servicios.
- Implementar características orientadas a objetos mediante herencia de tablas, tipos compuestos, arreglos y campos JSONB.
- Desarrollar funciones PL/pgSQL, vistas y triggers para automatizar operaciones y mantener la integridad de la información.
- Aplicar índices B-tree, GiST y GIN para optimizar las consultas y evaluar su rendimiento mediante EXPLAIN ANALYZE.
- Implementar transacciones y mecanismos de bloqueo para controlar las reservaciones simultáneas y evitar la sobreventa de habitaciones.
- Configurar respaldos completos, archivado WAL y recuperación a un punto en el tiempo (PITR).
- Distribuir la información entre las tres sedes y un nodo central mediante particionamiento, replicación lógica y postgres_fdw.
- Implementar una demostración de transacciones distribuidas en dos fases para trasladar reservaciones entre sedes.
- Desarrollar un cliente de demostración en Python que permita ejecutar operaciones hoteleras y consultar información consolidada.

# 4. Justificación

La implementación de una base de datos distribuida permite organizar la información de una cadena hotelera mediante nodos independientes que administran las operaciones de cada establecimiento y un nodo central que concentra información para consultas generales. Esta arquitectura facilita la administración descentralizada y permite consultar información de diferentes sedes sin depender exclusivamente de una única base de datos operativa.

Asimismo, el proyecto permite aplicar conceptos fundamentales de bases de datos, como normalización, integridad referencial, herencia, transacciones, concurrencia, optimización de consultas, respaldo y recuperación. La utilización de PostgreSQL permite integrar estas características en una solución funcional que puede ser probada y evaluada mediante escenarios de operación y fallas.

# 5. Alcance del proyecto

El sistema contempla cuatro instancias independientes de PostgreSQL: una para Cancún, una para Tulum, una para Bacalar y una central para reportes. Las sedes cuentan con estructuras para administrar huéspedes, habitaciones, tarifas, temporadas, reservaciones, pagos y servicios. El nodo central recibe información mediante replicación lógica y permite consultar datos de las sedes mediante conexiones distribuidas con postgres_fdw.

El alcance técnico incluye el diseño del modelo relacional, la implementación de características orientadas a objetos, funciones PL/pgSQL, triggers de auditoría y cálculo de importes, vistas operativas, índices, pruebas de concurrencia, respaldo y recuperación PITR. También incluye el particionamiento de reservaciones en el nodo central, una demostración de traslado de reservaciones mediante transacciones preparadas en dos fases y un cliente de consola desarrollado en Python.

El proyecto se enfoca en la administración de información hotelera y en la demostración de los mecanismos de bases de datos solicitados. No contempla, en esta etapa, una plataforma comercial completa, integración con pasarelas de pago reales ni conexión con servicios externos de reservaciones.

Aunque las instancias operativas son independientes, las bases contienen un catálogo común de las tres sedes. Por ello, todavía se requieren controles adicionales de permisos y escritura para garantizar que cada nodo opere exclusivamente sobre los registros de su sede correspondiente.

# 6. Metodología de desarrollo

Para organizar el desarrollo se adoptó un enfoque ágil basado en Scrum [2], utilizando una estructura de cuatro sprints semanales. Las actividades se organizaron a partir de un conjunto de requisitos y funcionalidades relacionadas con el análisis, diseño, implementación, integración, pruebas y documentación del producto.

Debido a que la planificación se documentó después de realizar una parte importante del desarrollo, los sprints, sus actividades y retrospectivas representan una reconstrucción organizada del trabajo realizado. No se presentan reuniones, métricas históricas ni registros de seguimiento que no hayan sido documentados. El detalle del backlog, los objetivos de cada sprint y sus resultados se presenta en el apartado de planificación del proyecto.

# 7. Tecnologías utilizadas

| Tecnología              | Aplicación                                           |
| ----------------------- | ---------------------------------------------------- |
| PostgreSQL 18.6         | Sistema gestor de bases de datos.                    |
| Docker y Docker Compose | Ejecución aislada de los cuatro nodos [3].           |
| pgAdmin                 | Administración y consulta de las bases de datos.     |
| Python 3.10             | Cliente de demostración y pruebas automatizadas [4]. |
| Psycopg 3               | Conexión de Python con PostgreSQL [5].               |
| PowerShell              | Automatización de tareas del entorno e instalación.  |
| Git                     | Control de versiones del proyecto [6].               |

---

# 8. Desarrollo del proyecto por unidades de aprendizaje

## 8.1 Unidad I. Modelo relacional y características del gestor de bases de datos

Se diseñó e implementó un modelo relacional en PostgreSQL para administrar la información de una cadena hotelera con tres sedes: Cancún, Tulum y Bacalar. El modelo contempla las entidades sedes, huéspedes, habitaciones, temporadas, tarifas, reservaciones, pagos, servicios y reservacion_servicios.

Se establecieron claves primarias para identificar los registros y claves foráneas para mantener la integridad referencial entre las entidades. También se incorporaron restricciones CHECK, índices únicos y restricciones de nulabilidad para controlar los datos permitidos [7]. En las relaciones que dependen de una sede se utilizaron identificadores compuestos para reforzar la correspondencia entre los registros y su sede.

La estructura se implementó mediante scripts SQL organizados por carpetas, lo que permite separar la creación de extensiones, tipos, tablas, funciones, triggers, vistas, índices y componentes distribuidos.

### Diagrama entidad-relación

El modelo lógico de la base de datos se representa mediante un diagrama entidad-relación que muestra las nueve entidades principales, sus atributos, claves primarias, claves foráneas y relaciones. También se identifican las especializaciones implementadas mediante herencia nativa de PostgreSQL.

El diagrama entidad-relación se incluye a continuación.

![Diagrama entidad-relacion](diagrama_entidad_relacion.png){ width=6.3in }

La fuente editable del diagrama se encuentra en [09_diagrama_entidad_relacion.md](09_diagrama_entidad_relacion.md).

### Características del gestor utilizadas

- PostgreSQL como sistema gestor de bases de datos relacional.
- Tipos de datos escalares, UUID, fechas, valores monetarios y booleanos.
- Claves primarias y foráneas.
- Restricciones de integridad y unicidad.
- Índices para optimizar consultas.
- Transacciones para agrupar operaciones.
- Extensiones para habilitar funcionalidades adicionales.

**Resultado:** se implementaron las tablas principales en las tres bases de datos operativas y en el nodo central. Además, se comparó la estructura de ocho tablas operativas entre los nodos y no se encontraron diferencias en sus columnas, tipos de datos, nulabilidad, columnas generadas, expresiones o valores predeterminados.

## 8.2 Unidad II. Características orientadas a objetos en PostgreSQL

Para representar información estructurada se utilizaron características de PostgreSQL que permiten ampliar el modelo relacional tradicional.

Primero, se crearon dos tipos compuestos:

- `direccion_type`: almacena calle, número, colonia, ciudad, estado, código postal y país.
- `rango_estancia`: representa una fecha de entrada y una fecha de salida.

También se utilizaron arreglos mediante el atributo `amenidades` de las habitaciones, que permite almacenar varios elementos en una sola columna. Para las preferencias de los huéspedes se incorporó el tipo `JSONB` [8], que permite guardar información semiestructurada.

Se implementó herencia de tablas mediante `INHERITS` [9]. Se definieron las tablas padre `huesped_especializacion` y `habitacion_especializacion`, con sus respectivas tablas especializadas para huéspedes individuales, huéspedes corporativos, habitaciones estándar y suites.

Debido a que PostgreSQL no hereda automáticamente las restricciones de clave primaria, clave foránea y unicidad en las tablas hijas, se declararon explícitamente las restricciones necesarias en cada especialización.

**Resultado:** se comprobó la inserción y consulta de registros especializados mediante sus tablas padre. La prueba se realizó dentro de una transacción que terminó con `ROLLBACK`, por lo que los datos utilizados para validar el comportamiento no permanecieron en la base de datos.

## 8.3 Unidad III. Consultas, almacenamiento, procedimientos y optimización

Se implementaron vistas, funciones, triggers e índices para automatizar operaciones y facilitar la consulta de información.

### Vistas

Se crearon las siguientes vistas operativas:

- `vw_ocupacion_sede`: permite consultar información relacionada con la ocupación de las sedes.
- `vw_reservaciones_detalle`: concentra información de las reservaciones y sus entidades relacionadas.
- `vw_servicios_reservacion`: presenta los servicios asociados a las reservaciones.

En el nodo central también se creó `vw_reservaciones_distribuidas`, que permite consultar reservaciones de las tres sedes mediante conexiones distribuidas.

### Funciones almacenadas

Se desarrollaron funciones en PL/pgSQL para realizar las operaciones principales:

- `fn_crear_reservacion`: valida los datos, verifica la disponibilidad y registra una reservación.
- `fn_realizar_checkin`: valida la reservación y registra la entrada del huésped.
- `fn_realizar_checkout`: registra la salida y actualiza el estado de la habitación.
- `fn_cancelar_reservacion`: cancela reservaciones que todavía no se encuentran en proceso de estancia.
- `fn_consultar_disponibilidad`: consulta habitaciones disponibles de acuerdo con las fechas, capacidad y tarifas vigentes.

### Triggers y auditoría

Se implementó una bitácora de auditoría para registrar operaciones de inserción, actualización y eliminación en las tablas operativas configuradas. Los registros almacenan la tabla afectada, operación, identificador del registro, usuario de base de datos, fecha y datos anteriores o nuevos en formato JSONB.

También se implementaron triggers para recalcular los importes de las reservaciones cuando se agregan, modifican o eliminan servicios, así como cuando se registran pagos. El sistema calcula automáticamente el total de alojamiento, el total pagado y el saldo pendiente.

### Índices y análisis de ejecución

Se utilizaron índices B-tree para consultas por sede, estado y fecha de entrada, así como índices GiST para búsquedas por rangos de fechas. También se utilizaron índices GIN para atributos JSONB y arreglos. PostgreSQL proporciona distintos tipos de índices, entre ellos B-tree, GiST y GIN, cuyas características permiten atender diferentes patrones de consulta [10].

Se generaron 50,000 reservaciones de prueba y se analizaron consultas con `EXPLAIN ANALYZE` [11]. Los resultados comparativos fueron:

| Consulta | Sin utilizar métodos de acceso por índice | Con índice | Mejora aproximada |
| -------- | ----------------------------------------: | ---------: | ----------------: |
| B-tree   |                                  5.967 ms |   0.230 ms |           96.15 % |
| GiST     |                                  7.497 ms |   0.406 ms |           94.58 % |

En la consulta B-tree se pasó de un recorrido secuencial (`Seq Scan`) a un recorrido mediante índice (`Index Scan`). En la consulta GiST se utilizó un recorrido de índice y acceso por bloques (`Bitmap Index Scan` y `Bitmap Heap Scan`).

La comparación sin índices se realizó mediante la desactivación de los métodos de acceso por índice durante la prueba. Por lo tanto, representa una comparación controlada y no una medición histórica tomada antes de crear los índices.

**Resultado:** se comprobó el funcionamiento de las vistas, funciones, triggers e índices. Las pruebas de cálculo de importes verificaron que los servicios modifican el total de la reservación y que los pagos actualizan el saldo pendiente. También se validó que un pago superior al total permitido sea rechazado.

## 8.4 Unidad IV. Transacciones, integridad y recuperación

Esta unidad se enfocó en proteger la consistencia de las reservaciones y comprobar mecanismos de recuperación ante fallas.

### Integridad y concurrencia

Para impedir que una habitación tenga reservaciones activas cuyos periodos se traslapen, se implementó una restricción de exclusión GiST sobre la habitación y el rango de estancia. PostgreSQL permite utilizar tipos de rango y operadores de solapamiento para representar y comparar periodos [12]. La restricción considera los estados `PENDIENTE`, `CONFIRMADA` y `CHECK_IN`.

La función de creación de reservaciones también bloquea la habitación mediante `SELECT FOR UPDATE`, con el objetivo de coordinar las operaciones concurrentes sobre el mismo recurso [13].

Se desarrolló una prueba en Python utilizando dos hilos y conexiones independientes a PostgreSQL. Ambos intentaron reservar simultáneamente la misma habitación para el mismo periodo.

**Resultado de la prueba:**

- Una reservación fue aceptada.
- La segunda fue rechazada por la restricción `ex_reservacion_sin_traslape`.
- El código SQLSTATE devuelto fue `23P01`.
- No se registraron errores inesperados.
- La prueba confirmó que no se produjo una doble reservación.

### Respaldo completo

Se configuró el archivado WAL en el nodo Cancún y se utilizó `pg_basebackup` para generar una copia física de la base de datos [14].

El respaldo terminó correctamente y posteriormente se ejecutó `pg_verifybackup`, que confirmó la validez de la copia generada.

El archivado WAL se verificó mediante las estadísticas de PostgreSQL. Durante la comprobación se registraron segmentos archivados y no se reportaron fallos de archivado.

### Recuperación a un punto en el tiempo (PITR)

Se realizó una prueba de recuperación utilizando la copia física y los archivos WAL archivados. Para ello se creó un registro de prueba anterior al punto de recuperación y otro posterior.

Se configuró la recuperación con `recovery.signal`, el comando de restauración de WAL y un tiempo objetivo (`recovery_target_time`). Después de completar la recuperación se promovió la instancia restaurada. Este mecanismo corresponde al procedimiento de archivado continuo y recuperación a un punto en el tiempo documentado por PostgreSQL [15].

**Resultado:** la base restaurada conservó el registro anterior al punto objetivo y no recuperó el registro posterior. La instancia original mantuvo ambos registros, lo que permitió comprobar que la recuperación se realizó sobre una copia independiente.

La configuración de respaldo y PITR fue probada en el nodo Cancún; no se afirma que los otros dos nodos tengan actualmente el mismo procedimiento de recuperación configurado.

## 8.5 Unidad V. Bases de datos distribuidas

Se implementó una arquitectura distribuida formada por cuatro instancias PostgreSQL independientes: Cancún, Tulum, Bacalar y un nodo central de reportes.

Las tres sedes funcionan como nodos operativos y el nodo central recibe información mediante replicación lógica. Además, se configuró `postgres_fdw` para consultar información directamente en los nodos remotos.

### Diagrama de arquitectura distribuida

La arquitectura física y lógica del sistema se representa mediante un diagrama que muestra los cuatro nodos PostgreSQL, la red Docker, el cliente Python, la replicación lógica hacia el nodo central, el particionamiento y las conexiones mediante PostgreSQL FDW.

El diagrama de arquitectura distribuida se incluye a continuación.

![Diagrama de arquitectura distribuida](diagrama_arquitectura.png)

La fuente editable del diagrama se encuentra en [10_diagrama_arquitectura.md](10_diagrama_arquitectura.md).

### Particionamiento

En el nodo central se convirtió la tabla `reservaciones` en una tabla particionada mediante `PARTITION BY LIST(sede_id)` [16]. Se crearon tres particiones:

- `reservaciones_cancun`
- `reservaciones_tulum`
- `reservaciones_bacalar`

La estructura permite organizar las reservaciones consolidadas de acuerdo con la sede de origen.

### Replicación lógica

Se configuró una publicación por sede y una suscripción correspondiente en el nodo central [17]:

- `pub_central_cancun` y `sub_cancun`.
- `pub_central_tulum` y `sub_tulum`.
- `pub_central_bacalar` y `sub_bacalar`.

Cada publicación incluye ocho tablas operativas y las operaciones de inserción, actualización y eliminación. En total se configuraron 24 relaciones replicadas.

Se establecieron índices únicos compuestos y la identidad de réplica correspondiente para permitir la identificación de las filas durante las operaciones de actualización y eliminación.

**Resultado:** las 24 relaciones se encontraron en estado `Lista`. Se realizó una prueba de inserción, actualización y eliminación de un servicio desde Cancún y se verificó que los cambios se reflejaran en el nodo central.

### Consultas distribuidas mediante postgres_fdw

Se habilitó la extensión `postgres_fdw` en el nodo central. Se configuraron servidores y mapeos de usuario para conectarse con Cancún, Tulum y Bacalar. Esta extensión permite acceder a tablas ubicadas en servidores PostgreSQL externos mediante tablas foráneas [18].

Se importaron ocho tablas remotas por sede, para un total de 24 tablas externas. Con ellas se creó la vista `vw_reservaciones_distribuidas`.

El plan de ejecución obtenido mediante `EXPLAIN VERBOSE` mostró un nodo `Append` y operaciones `Foreign Scan`, confirmando que PostgreSQL consulta las fuentes remotas para integrar los resultados.

La consulta mediante FDW es independiente de la replicación lógica: la primera permite acceder a datos remotos, mientras que la segunda mantiene copias de las tablas publicadas en el nodo central.

### Transacciones distribuidas en dos fases

Se desarrolló una prueba en Python para coordinar el traslado de una reservación entre Cancún y Tulum utilizando transacciones preparadas de PostgreSQL.

El procedimiento crea una reservación en Cancún, prepara el `DELETE` en el nodo de origen y el `INSERT` en el nodo de destino mediante `PREPARE TRANSACTION`, verifica que ambas transacciones estén preparadas y posteriormente ejecuta `COMMIT PREPARED` [19]. Si la preparación falla, revierte las transacciones. La prueba limpia únicamente las reservaciones de ejecuciones anteriores identificadas con el marcador `PRUEBA_2PC_AUTOMATICA`, por lo que puede repetirse sin editar identificadores.

**Resultado:** la reservación de prueba dejó de existir en Cancún y apareció en Tulum con el mismo identificador, pero asociada al huésped y habitación de destino. La bitácora registró `DELETE` en Cancún e `INSERT` en Tulum. No quedaron transacciones preparadas pendientes. La prueba se ejecutó dos veces consecutivas con código de salida `0` en el entorno limpio aislado.

Esta implementación constituye una demostración académica de coordinación mediante transacciones preparadas. No representa un coordinador de transacciones distribuidas de producción con registro persistente de decisiones y recuperación automática ante cualquier caída durante la fase de confirmación.

## 8.6 Cliente de demostración

Se desarrolló un cliente de consola en Python utilizando Psycopg para conectarse a las cuatro bases de datos.

El menú principal permite seleccionar una sede o consultar un reporte consolidado. En cada sede se pueden consultar habitaciones disponibles, crear reservaciones, consultar información, realizar check-in, realizar check-out y cancelar reservaciones.

El cliente utiliza las funciones almacenadas de PostgreSQL para ejecutar las operaciones principales. Las credenciales se obtienen mediante una variable de entorno o una solicitud de contraseña en consola.

**Resultado:** se comprobó la conexión con las tres sedes y el nodo central. Se realizaron pruebas de disponibilidad, creación y cancelación de reservaciones, check-in, check-out y consulta de información consolidada.

# 9. Resultados generales

El proyecto permitió implementar y comprobar una solución distribuida para la administración de reservaciones hoteleras. Se construyeron cuatro instancias PostgreSQL, un modelo relacional con restricciones de integridad, estructuras orientadas a objetos, funciones, triggers, vistas e índices.

Las pruebas realizadas comprobaron los siguientes resultados:

1. Las operaciones principales de reservación funcionan mediante funciones almacenadas.
2. La restricción de exclusión evita traslapes de reservaciones activas sobre una misma habitación.
3. Los triggers registran operaciones y mantienen actualizados los importes de las reservaciones.
4. Los índices mejoraron los tiempos de las consultas evaluadas con 50,000 registros de prueba.
5. La copia física y la recuperación PITR se comprobaron en el nodo Cancún.
6. La replicación lógica permitió consolidar información de las tres sedes en el nodo central.
7. Las consultas mediante `postgres_fdw` integraron información de los nodos remotos.
8. Se comprobó el traslado de una reservación entre dos sedes mediante transacciones preparadas, con dos ejecuciones consecutivas automatizadas.
9. El cliente Python permitió ejecutar operaciones y consultar información consolidada.
10. El instalador se ejecutó de principio a fin en un entorno limpio aislado, con resultados verificables de replicación, FDW y datos demo.

Los resultados corresponden a las pruebas ejecutadas en el entorno de desarrollo. No deben interpretarse como una certificación de disponibilidad, seguridad o rendimiento en un entorno de producción.

## 9.1 Validación en un entorno limpio

Para comprobar que la instalación puede reproducirse sin depender del entorno original, se creó una copia aislada del proyecto con contenedores, red, volúmenes y puertos propios. La validación se realizó el 13 de noviembre de 2026 sin ejecutar comandos destructivos sobre el entorno original.

| Aspecto                    | Resultado comprobado                                                        |
| -------------------------- | --------------------------------------------------------------------------- |
| Contenedores               | Cuatro nodos `hotel-prueba-postgres-*` activos en los puertos 5641–5644.    |
| Publicaciones              | Una por sede, con ocho tablas cada una.                                     |
| Suscripciones              | Tres suscripciones activas en el nodo central.                              |
| Relaciones de suscripción  | 24 relaciones en estado `r`.                                                |
| Tablas externas FDW        | 24 tablas distribuidas en los esquemas `remoto_cancun`, `remoto_tulum` y `remoto_bacalar`. |
| Datos demo                 | Carga idempotente; los conteos no cambiaron al ejecutarla dos veces.        |
| Concurrencia               | Una solicitud aceptada y una rechazada con SQLSTATE `23P01`.                |
| 2PC                        | Dos ejecuciones consecutivas con código `0`; sin transacciones preparadas.  |
| Entorno original           | Sin cambios; sus conteos y suscripciones permanecieron intactos.            |

Las evidencias se encuentran en `evidence/validacion_entorno_limpio_20261113/` e incluyen la salida del instalador, el estado de las publicaciones y suscripciones, los datos demo, las pruebas y la verificación final del traslado 2PC.

# 10. Limitaciones identificadas

La solución es un prototipo académico funcional y presenta algunas limitaciones que deben considerarse:

- El respaldo físico y el procedimiento PITR se configuraron y probaron en Cancún, no en los tres nodos.
- La replicación lógica está configurada en una sola dirección, desde las sedes hacia el nodo central.
- La coordinación de transacciones preparadas se implementó como una prueba académica en Python y no como un servicio de coordinación de transacciones de producción.
- Los nodos contienen el catálogo común de las tres sedes. La aplicación permite seleccionar el nodo operativo, pero todavía se requiere reforzar el aislamiento por sede mediante controles adicionales en la base de datos.
- La recuperación automática ante la caída de un nodo y la alta disponibilidad no forman parte de las pruebas realizadas.
- El cliente de demostración funciona mediante consola y no constituye una interfaz web de producción.

Estas limitaciones delimitan el alcance real del proyecto y permiten identificar mejoras futuras sin atribuir al sistema funcionalidades que todavía no han sido implementadas.

# 11. Conclusiones

El desarrollo permitió aplicar los conceptos de bases de datos relacionales, características orientadas a objetos, optimización de consultas, integridad transaccional y distribución de datos mediante PostgreSQL.

La solución demuestra que es posible mantener bases operativas independientes por sede y consolidar información en un nodo central mediante replicación lógica y consultas distribuidas. También se comprobó que las restricciones de integridad, los bloqueos y las transacciones permiten proteger las operaciones de reservación ante intentos concurrentes.

Las pruebas de rendimiento mostraron mejoras en las consultas evaluadas mediante el uso de índices B-tree y GiST. Asimismo, el respaldo físico y la recuperación PITR demostraron la posibilidad de recuperar información hasta un punto determinado utilizando copias y archivos WAL.

Como resultado, se obtuvo un prototipo funcional que integra los principales requerimientos técnicos de la guía de proyecto. Aunque existen aspectos que requieren fortalecerse para un entorno productivo, la implementación permite demostrar los conceptos estudiados y proporciona una base para futuras mejoras, especialmente en el aislamiento por sede, la automatización de la recuperación y la coordinación robusta de transacciones distribuidas.

\newpage

# 2. REQUISITOS E HISTORIAS DE USUARIO

## 2.1 Identificación de actores

Para definir las funcionalidades del sistema se consideran los siguientes actores:

| Actor                          | Descripción                                                                         |
| ------------------------------ | ----------------------------------------------------------------------------------- |
| Personal de recepción          | Realiza consultas de disponibilidad, registra reservaciones y administra su estado. |
| Personal administrativo        | Consulta información de huéspedes, habitaciones, tarifas, pagos y servicios.        |
| Administrador de base de datos | Supervisa la infraestructura, respaldos, replicación y recuperación de información. |
| Responsable de reportes        | Consulta la información consolidada de las tres sedes desde el nodo central.        |

Estos actores representan los usuarios funcionales del sistema. No implican que se haya implementado un módulo de autenticación o administración de cuentas en el cliente de demostración.

## 2.2 Requisitos funcionales

| ID    | Requisito                               | Descripción                                                                                                                          |
| ---------------- | --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| RF-01 | Administración de huéspedes             | El esquema debe almacenar huéspedes asociados a una sede y permitir su consulta mediante SQL.                                        |
| RF-02 | Administración de habitaciones          | Debe almacenar habitaciones, capacidad, tipo, estado y amenidades, y permitir su consulta.                                           |
| RF-03 | Administración de tarifas y temporadas  | Debe almacenar tarifas y temporadas, incluyendo precios y vigencias aplicables.                                                      |
| RF-04 | Consulta de disponibilidad              | Debe identificar habitaciones disponibles según fechas y cantidad de huéspedes.                                                      |
| RF-05 | Registro de reservaciones               | Debe permitir crear reservaciones asociadas a un huésped, habitación, tarifa y sede.                                                 |
| RF-06 | Control de traslapes                    | Debe impedir que una habitación tenga reservaciones activas con periodos superpuestos.                                               |
| RF-07 | Consulta y cancelación de reservaciones | Debe permitir consultar reservaciones y cancelar aquellas que se encuentren en estados permitidos por la función implementada.       |
| RF-08 | Check-in y check-out                    | Debe proporcionar operaciones para registrar la entrada y salida de los huéspedes.                                                   |
| RF-09 | Administración de pagos y servicios     | Debe almacenar pagos y servicios asociados a las reservaciones; los triggers deben recalcular automáticamente los importes y saldos. |
| RF-10 | Auditoría                               | Debe registrar operaciones de inserción, actualización y eliminación en las tablas operativas configuradas.                          |
| RF-11 | Reportes consolidados                   | El nodo central debe permitir consultar reservaciones procedentes de Cancún, Tulum y Bacalar.                                        |
| RF-12 | Replicación de información              | Los cambios publicados por cada sede deben propagarse al nodo central mediante replicación lógica.                                   |
| RF-13 | Consultas distribuidas                  | Debe permitir consultar información remota de las tres sedes mediante `postgres_fdw`.                                                |
| RF-14 | Traslado entre sedes                    | Debe demostrar el traslado de una reservación mediante transacciones preparadas en dos fases.                                        |
| RF-15 | Respaldo y recuperación                 | En el nodo Cancún, debe permitir generar respaldos físicos y recuperar información mediante archivado WAL y PITR.                    |
| RF-16 | Cliente de demostración                 | Debe ofrecer una interfaz de consola en Python para realizar operaciones hoteleras y consultar reportes.                             |

## 2.3 Requisitos no funcionales

| ID     | Requisito                | Descripción                                                                                                                                                                                           |
| ----------- | ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| RNF-01 | Integridad               | La información debe mantener relaciones válidas mediante claves primarias, foráneas, restricciones y validaciones.                                                                                    |
| RNF-02 | Concurrencia             | Las operaciones simultáneas sobre una habitación deben evitar reservaciones incompatibles.                                                                                                            |
| RNF-03 | Separación de instancias | Cada sede debe contar con una instancia PostgreSQL independiente. Esta separación no implica que ya exista un control completo de escritura exclusivo por sede ni continuidad automática ante fallas. |
| RNF-04 | Rendimiento              | Las consultas deben optimizarse mediante índices y evaluarse con `EXPLAIN ANALYZE`.                                                                                                                   |
| RNF-05 | Recuperabilidad          | El nodo Cancún debe contar con respaldo físico, archivado WAL y un procedimiento PITR probado. La extensión de estos mecanismos a los otros nodos queda fuera del alcance implementado.               |
| RNF-06 | Distribución             | La arquitectura debe permitir intercambiar y consultar información entre los nodos.                                                                                                                   |
| RNF-07 | Mantenibilidad           | Los scripts SQL, pruebas y componentes Python deben organizarse en directorios independientes.                                                                                                        |
| RNF-08 | Portabilidad del entorno | Los servicios de PostgreSQL deben poder ejecutarse mediante Docker Compose en un entorno compatible.                                                                                                  |
| RNF-09 | Trazabilidad             | Las operaciones auditadas deben conservar información sobre el tipo de operación, fecha y datos afectados.                                                                                            |

## 2.4 Historias de usuario

### HU-01. Consultar disponibilidad

**Como** personal de recepción,
**quiero** consultar las habitaciones disponibles de una sede para determinadas fechas,
**para** ofrecer opciones de alojamiento sin generar reservaciones incompatibles.

**Criterios de aceptación:**

- Se deben proporcionar fechas de entrada y salida válidas.
- La cantidad de huéspedes debe ser compatible con la capacidad de la habitación.
- No deben mostrarse habitaciones que tengan reservaciones activas que se traslapen con el periodo solicitado.
- Solo deben considerarse habitaciones y tarifas que cumplan las condiciones de disponibilidad y vigencia.

**Verificación:** función `fn_consultar_disponibilidad`.

### HU-02. Registrar una reservación

**Como** personal de recepción,
**quiero** registrar una reservación para un huésped,
**para** almacenar formalmente su estancia en una sede.

**Criterios de aceptación:**

- La reservación debe estar asociada a un huésped, habitación, tarifa y sede válidos.
- Las fechas deben representar un periodo de estancia válido.
- El precio debe calcularse de acuerdo con la tarifa y el número de noches.
- La operación debe rechazar habitaciones que no cumplan las condiciones de disponibilidad.

**Verificación:** función `fn_crear_reservacion`.

### HU-03. Evitar reservaciones simultáneas incompatibles

**Como** administrador del sistema,
**quiero** que la base de datos controle las reservaciones simultáneas,
**para** evitar que una habitación sea asignada a dos huéspedes durante periodos superpuestos.

**Criterios de aceptación:**

- Dos operaciones concurrentes deben poder ejecutarse desde conexiones independientes.
- Si ambas intentan reservar la misma habitación en fechas incompatibles, solo una debe completarse.
- La operación rechazada debe recibir un error de integridad identificable.

**Verificación:** restricción de exclusión GiST `ex_reservacion_sin_traslape` y prueba Python con dos hilos.

### HU-04. Registrar la entrada del huésped

**Como** personal de recepción,
**quiero** registrar el check-in de una reservación confirmada,
**para** actualizar el estado de la estancia y de la habitación.

**Criterios de aceptación:**

- La reservación debe encontrarse confirmada.
- La fecha de operación debe encontrarse dentro del periodo permitido.
- La habitación debe actualizarse a estado ocupada.
- La reservación debe cambiar a estado `CHECK_IN`.

**Verificación:** función `fn_realizar_checkin`.

### HU-05. Registrar la salida del huésped

**Como** personal de recepción,
**quiero** registrar el check-out de una reservación,
**para** finalizar la estancia y actualizar la disponibilidad de la habitación.

**Criterios de aceptación:**

- La reservación debe encontrarse en estado `CHECK_IN`.
- La fecha de salida debe cumplir las validaciones de la función.
- La reservación debe cambiar a estado `FINALIZADA`.
- La habitación debe actualizarse según las demás reservaciones activas que correspondan.

**Verificación:** función `fn_realizar_checkout`.

### HU-06. Cancelar una reservación

**Como** personal de recepción,
**quiero** cancelar una reservación pendiente o confirmada,
**para** liberar el periodo reservado cuando la estancia ya no se realizará.

**Criterios de aceptación:**

- Se debe identificar una reservación existente.
- Solo se deben permitir los estados contemplados por la función de cancelación.
- Una reservación con check-in realizado no debe cancelarse mediante esta operación.
- El estado debe actualizarse a `CANCELADA`.

**Verificación:** función `fn_cancelar_reservacion`.

### HU-07. Consultar reportes consolidados

**Como** responsable de reportes,
**quiero** consultar las reservaciones de las tres sedes desde el nodo central,
**para** obtener información general de la operación hotelera.

**Criterios de aceptación:**

- La consulta debe incluir información identificable de Cancún, Tulum y Bacalar.
- Debe mostrar los datos principales de las reservaciones.
- La información debe poder consultarse mediante la vista distribuida.
- Los datos replicados deben estar disponibles en el nodo central.

**Verificación:** vista `vw_reservaciones_distribuidas` y cliente Python.

### HU-08. Trasladar una reservación entre sedes

**Como** administrador de la operación hotelera,
**quiero** trasladar una reservación de una sede a otra,
**para** conservar su información cuando sea necesario cambiar el establecimiento.

**Criterios de aceptación:**

- La operación debe utilizar conexiones independientes a las bases de datos involucradas.
- Las transacciones deben prepararse en ambos nodos antes de confirmar los cambios.
- El traslado debe crear el registro en la sede destino y retirar el registro de la sede origen.
- La operación debe contemplar confirmación o reversión de las transacciones preparadas.

**Verificación:** script `python/tests/test_2pc.py`.

### HU-09. Mantener una bitácora de operaciones

**Como** administrador de base de datos,
**quiero** conservar registros de las operaciones realizadas sobre las tablas auditadas,
**para** identificar modificaciones y consultar los datos afectados.

**Criterios de aceptación:**

- Las operaciones configuradas deben activar sus respectivos triggers.
- La bitácora debe identificar la tabla y el tipo de operación.
- Debe registrar la fecha, el usuario de base de datos y los datos anteriores o nuevos según corresponda.

**Verificación:** tabla `bitacora` y triggers de auditoría.

### HU-10. Recuperar información ante fallas

**Como** administrador de base de datos,
**quiero** disponer de respaldos y registros WAL,
**para** recuperar la información hasta un punto específico en el tiempo.

**Criterios de aceptación:**

- Debe generarse un respaldo físico mediante `pg_basebackup`.
- El respaldo debe validarse con `pg_verifybackup`.
- Deben archivarse segmentos WAL.
- Debe realizarse una recuperación PITR en un directorio independiente del nodo operativo.

**Verificación:** respaldo y prueba PITR del nodo Cancún.

## 2.5 Restricciones y consideraciones del alcance

- El proyecto utiliza cuatro instancias PostgreSQL independientes.
- La replicación lógica está configurada desde las tres sedes hacia el nodo central.
- Las consultas distribuidas se realizan mediante `postgres_fdw`.
- El traslado entre sedes se coordina desde Python mediante transacciones preparadas; no se considera que `postgres_fdw` ejecute automáticamente una transacción distribuida en dos fases.
- El respaldo físico y la prueba PITR se realizaron sobre el nodo Cancún.
- El cliente desarrollado es una aplicación de consola y no una plataforma web.
- Las pruebas realizadas corresponden a un entorno local con Docker; no representan una infraestructura hotelera desplegada en producción.
- Aunque las bases contienen un catálogo común de las tres sedes, todavía se requieren controles adicionales de escritura y permisos para restringir las operaciones de cada nodo a su sede correspondiente.
- La arquitectura no incluye un mecanismo de recuperación automática ni alta disponibilidad comprobada.

## 2.6 Relación entre requisitos y componentes implementados

| Requisitos    | Componentes principales                                                                           |
| ------------- | ------------------------------------------------------------------------------------------------- |
| RF-01 a RF-03 | Tablas de huéspedes, habitaciones, tarifas y temporadas.                                          |
| RF-04 a RF-06 | Funciones de disponibilidad y creación de reservaciones, restricciones de integridad y exclusión. |
| RF-07 y RF-08 | Consulta de reservaciones y funciones PL/pgSQL de cancelación, check-in y check-out.              |
| RF-09 y RF-10 | Tablas de pagos y servicios, triggers de totales y auditoría.                                     |
| RF-11 a RF-13 | Nodo central, replicación lógica, `postgres_fdw` y vistas distribuidas.                           |
| RF-14         | `python/tests/test_2pc.py`.                                                                       |
| RF-15         | `pg_basebackup`, archivado WAL y recuperación PITR en Cancún.                                     |
| RF-16         | `python/client/main.py`.                                                                          |

---

**Fin del documento de requisitos e historias de usuario.**

\newpage

# 3. PLANIFICACIÓN DEL PROYECTO CON SCRUM

## 3.1 Metodología

Para organizar el desarrollo se adoptó un enfoque ágil basado en Scrum, utilizando iteraciones semanales para dividir el trabajo en objetivos pequeños y verificables. El proyecto se estructuró en cuatro sprints, considerando las actividades de análisis, diseño, implementación, integración, pruebas y documentación.

Debido a que la planificación se está documentando después de realizar una parte importante del desarrollo, los sprints y sus resultados representan una reconstrucción organizada de las actividades realizadas. No se presentan reuniones, métricas históricas o registros de seguimiento que no hayan sido documentados.

## 3.2 Roles del proyecto

| Rol Scrum        | Responsable                                                                              |
| ---------------- | ---------------------------------------------------------------------------------------- |
| Product Owner    | Alumno responsable del proyecto, encargado de definir las funcionalidades y prioridades. |
| Scrum Master     | Alumno responsable de organizar las actividades y dar seguimiento al desarrollo.         |
| Development Team | Alumno responsable del análisis, diseño, programación, pruebas e integración.            |

Al tratarse de un proyecto individual, una misma persona desempeña los diferentes roles.

## 3.3 Product Backlog

| ID    | Elemento del backlog               | Prioridad | Resultado esperado                       |
| -------- | ---------------------------------- | ---------- | ---------------------------------------- |
| PB-01 | Análisis del problema y alcance    | Alta      | Definición del problema y objetivos.     |
| PB-02 | Diseño de arquitectura distribuida | Alta      | Arquitectura de cuatro nodos.            |
| PB-03 | Configuración del entorno Docker   | Alta      | Cuatro instancias PostgreSQL.            |
| PB-04 | Diseño del modelo relacional       | Alta      | Tablas y relaciones principales.         |
| PB-05 | Implementación de tipos y herencia | Media     | Características orientadas a objetos.    |
| PB-06 | Implementación de funciones        | Alta      | Operaciones de reservaciones.            |
| PB-07 | Implementación de triggers         | Alta      | Auditoría y cálculo de importes.         |
| PB-08 | Implementación de vistas e índices | Alta      | Consultas operativas y optimización.     |
| PB-09 | Pruebas de rendimiento             | Media     | Comparación de planes de ejecución.      |
| PB-10 | Pruebas de concurrencia            | Alta      | Prevención de reservaciones traslapadas. |
| PB-11 | Configuración de respaldo y WAL    | Alta      | Respaldo físico y archivado.             |
| PB-12 | Prueba de recuperación PITR        | Alta      | Recuperación a un punto temporal.        |
| PB-13 | Particionamiento central           | Alta      | Particiones por sede.                    |
| PB-14 | Replicación lógica                 | Alta      | Sincronización de las sedes con central. |
| PB-15 | Consultas distribuidas FDW         | Alta      | Acceso remoto a las tres sedes.          |
| PB-16 | Transacción distribuida 2PC        | Alta      | Traslado de reservación entre sedes.     |
| PB-17 | Cliente de demostración Python     | Media     | Interfaz de consola operativa.           |
| PB-18 | Documentación técnica y académica  | Alta      | Informe, manuales y referencias.         |
| PB-19 | Preparación de la presentación     | Alta      | Material para la defensa del proyecto.   |

## 3.4 Planificación de sprints

### Sprint 1. Análisis, arquitectura y estructura de datos

**Objetivo:** establecer la arquitectura del proyecto y construir la estructura inicial de las bases de datos.

Actividades:

- Analizar el problema de administración hotelera.
- Definir los objetivos y alcance.
- Diseñar la arquitectura con tres nodos operativos y uno central.
- Configurar Docker Compose.
- Crear los tipos compuestos.
- Crear las tablas principales y sus relaciones.
- Implementar herencia de tablas y estructuras complejas.

**Resultado:** infraestructura local con cuatro instancias PostgreSQL y estructura inicial de datos.

### Sprint 2. Operaciones, integridad y optimización

**Objetivo:** implementar las operaciones principales de reservaciones y los mecanismos de integridad.

Actividades:

- Crear funciones PL/pgSQL.
- Implementar check-in, check-out y cancelación.
- Crear triggers de auditoría.
- Implementar cálculo automático de totales.
- Crear vistas operativas.
- Crear índices B-tree, GiST y GIN.
- Generar datos de prueba para rendimiento.
- Comparar planes de ejecución.

**Resultado:** operaciones hoteleras funcionales, controles de integridad, auditoría y optimización de consultas.

### Sprint 3. Transacciones y distribución

**Objetivo:** implementar y comprobar los mecanismos de concurrencia, recuperación y distribución de información.

Actividades:

- Ejecutar pruebas de concurrencia.
- Configurar respaldo físico y archivado WAL.
- Realizar una recuperación PITR.
- Particionar las reservaciones del nodo central.
- Configurar publicaciones y suscripciones de replicación lógica.
- Configurar servidores y tablas externas mediante postgres_fdw.
- Implementar y probar el traslado de reservaciones mediante 2PC.

**Resultado:** arquitectura distribuida funcional y pruebas de integridad, replicación y recuperación.

### Sprint 4. Integración, cliente y documentación

**Resultado:** cliente Python integrado y funcionalidades principales verificadas. La documentación técnica, las evidencias de ejecución y el instalador validado en un entorno limpio están disponibles; el informe académico se integró en un PDF único y la presentación final quedó preparada.

Actividades:

- Desarrollar el cliente de consola en Python.
- Integrar operaciones de las tres sedes.
- Implementar reportes consolidados.
- Probar consultas de disponibilidad y reservaciones.
- Verificar el funcionamiento del check-in, check-out y cancelación.
- Revisar los scripts de instalación para entornos limpios.
- Actualizar README y documentación técnica.
- Preparar evidencias, informe y presentación.

**Resultado:** producto integrado con cliente de demostración, documentación técnica y preparación de entregables académicos.

## 3.5 Seguimiento y control

El avance se puede organizar mediante un tablero Kanban con los siguientes estados:

- Por hacer.
- En progreso.
- En revisión.
- Terminado.

Los cambios de estado deben reflejar el avance real de cada actividad. El historial de Git permite identificar las modificaciones y commits asociados al desarrollo.

## 3.6 Seguimiento de avance

No se cuenta con registros históricos de puntos de historia, horas estimadas por tarea o mediciones diarias de trabajo. Por esta razón, no se presenta un burndown chart histórico como si hubiera sido generado durante cada sprint.

Para un seguimiento verificable se propone registrar en cada sprint:

| Indicador          | Forma de medición                                         |
| ------------------ | --------------------------------------------------------- |
| Trabajo pendiente  | Elementos del backlog todavía no terminados.              |
| Trabajo completado | Elementos aceptados y verificados.                        |
| Incidencias        | Errores encontrados durante implementación y pruebas.     |
| Avance del sprint  | Elementos completados respecto al total comprometido.     |
| Cambios            | Modificaciones realizadas al alcance o a las prioridades. |

El porcentaje de avance se calcula mediante:

**Avance (%) = (Elementos completados / Elementos comprometidos) × 100**

### 3.6.1 Burndown Chart

Debido a que no se registraron mediciones diarias durante el desarrollo, se presenta una reconstrucción retrospectiva del avance utilizando como unidad de medida los 19 elementos del Product Backlog. El gráfico compara el trabajo pendiente ideal con el avance reconstruido al cierre de cada sprint y al corte del 11 de noviembre de 2026.

Para esta reconstrucción, los elementos se distribuyeron de la siguiente manera:

- Sprint 1: PB-01 a PB-05 (5 elementos).
- Sprint 2: PB-06 a PB-10 (5 elementos).
- Sprint 3: PB-11 a PB-16 (6 elementos).
- Sprint 4: PB-17 a PB-19 (3 elementos).

Al corte del 11 de noviembre se consideraban completados 17 elementos. Los dos entregables documentales restantes se concluyeron el 13 de noviembre, por lo que el backlog quedó completo.

| Etapa                | Trabajo ideal pendiente | Trabajo reconstruido pendiente |
| -------------------- | ----------------------: | -----------------------------: |
| Inicio               |                      19 |                             19 |
| Cierre Sprint 1      |                   14.25 |                             14 |
| Cierre Sprint 2      |                    9.50 |                              9 |
| Cierre Sprint 3      |                    4.75 |                              3 |
| Corte del 11/11/2026 |                       0 |                              2 |

La línea ideal representa una reducción uniforme del trabajo pendiente. La línea reconstruida representa el avance estimado mediante los elementos del backlog, no mediciones históricas tomadas durante la ejecución.

**Interpretación:** el desarrollo técnico y las pruebas principales se completaron antes de la integración de los entregables académicos. Al corte del 11 de noviembre quedaban dos elementos documentales; ambos se concluyeron el 13 de noviembre con la integración del PDF y la preparación de la presentación.

xychart-beta
title "Burndown Chart reconstruido"
x-axis ["Inicio", "Sprint 1", "Sprint 2", "Sprint 3", "Corte 11 nov."]
y-axis "Elementos pendientes" 0 --> 20
line [19, 14.25, 9.5, 4.75, 0]
line [19, 14, 9, 3, 2]

![Burndown Chart reconstruido](burndown_scrum.png)

## 3.7 Retrospectivas

Las siguientes retrospectivas son una evaluación retrospectiva del desarrollo, no actas de reuniones celebradas durante los sprints.

**Sprint 1**

- Aspectos positivos: se estableció una arquitectura clara y se separaron las bases de datos por sede.
- Dificultades: fue necesario considerar las particularidades de PostgreSQL, especialmente en herencia y restricciones.
- Mejora: validar los scripts desde el principio y mantener un orden de instalación.

**Sprint 2**

- Aspectos positivos: se centralizó la lógica de reservaciones en funciones y se automatizaron cálculos mediante triggers.
- Dificultades: fue necesario ajustar índices y restricciones para mantener integridad y compatibilidad.
- Mejora: probar cada función y trigger de forma aislada antes de integrarlos.

**Sprint 3**

- Aspectos positivos: se logró configurar replicación lógica, consultas distribuidas y recuperación PITR.
- Dificultades: la replicación requirió identidades adecuadas para las tablas y el traslado 2PC necesitó coordinación explícita.
- Mejora: verificar la configuración de cada nodo y registrar resultados de cada operación.

**Sprint 4**

- Aspectos positivos: se integró un cliente Python y se actualizaron los archivos de instalación y documentación.
- Dificultades: el producto técnico avanzó antes que la documentación académica.
- Mejora: reservar tiempo específico para evidencias, manuales y preparación de la defensa.

## 3.8 Conclusión de la planificación

La organización por sprints permitió dividir el proyecto en etapas relacionadas con las competencias de la asignatura. La reconstrucción del backlog facilita identificar las funcionalidades desarrolladas, sus dependencias y los resultados que deben demostrarse. Al 13 de noviembre de 2026, el producto, las evidencias técnicas, el informe integrado en PDF y la presentación para la defensa están elaborados. La instalación limpia se validó en un entorno aislado y el entorno original permaneció intacto.

\newpage

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
│   ├── 09_distributed/
│   └── 10_seed/
├── docker/
│   └── init/
├── documentation/
├── evidence/
├── python/
│   ├── client/
│   ├── generators/
│   ├── hotel_config.py
│   └── tests/
├── scripts/
│   ├── cargar_datos_demo.ps1
│   └── instalar_proyecto.ps1
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

Para las pruebas Python se utiliza la variable de entorno `HOTEL_DB_PASSWORD`. Su valor debe coincidir con `POSTGRES_PASSWORD` del archivo `.env`.

El módulo `python/hotel_config.py` centraliza la configuración. Primero consulta las variables de entorno y, si no existen, lee el archivo `.env`. Los valores predeterminados conservan los puertos del entorno original:

| Variable                | Valor predeterminado | Uso                                      |
| --------------------------- | ------------------ | ---------------------------------------- |
| `HOTEL_DB_HOST`         | `127.0.0.1`          | Host de los cuatro nodos.                |
| `HOTEL_DB_PORT_CANCUN`  | `5541`               | Puerto de `hotel_cancun`.                |
| `HOTEL_DB_PORT_TULUM`   | `5542`               | Puerto de `hotel_tulum`.                 |
| `HOTEL_DB_PORT_BACALAR` | `5543`               | Puerto de `hotel_bacalar`.               |
| `HOTEL_DB_PORT_CENTRAL` | `5544`               | Puerto de `hotel_central`.               |
| `HOTEL_DB_USER`         | `hotel_admin`        | Usuario de conexión.                     |
| `HOTEL_ENV_NAME`        | `original`           | Nombre del entorno para los mensajes.    |
| `HOTEL_EXPECTED_ENV`    | sin valor            | Protección opcional contra entornos incorrectos. |

Si `HOTEL_EXPECTED_ENV` está definida y no coincide con `HOTEL_ENV_NAME`, los scripts se detienen antes de conectarse. Esto permite ejecutar el cliente y las pruebas contra una copia aislada sin riesgo de usar el entorno original por error.

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
8. Cargar los datos de demostración con el paso independiente de la sección 4.7.1.

Durante la configuración de las conexiones distribuidas, el instalador solicita las contraseñas de FDW y de replicación mediante `Read-Host -AsSecureString`. Los valores se pasan a `psql` solo mediante variables de entorno temporales y se eliminan al finalizar. Antes de crear las suscripciones, el instalador verifica la conectividad de los servidores FDW.

El instalador fue validado de principio a fin el 13 de noviembre de 2026 en una copia aislada con contenedores `hotel-prueba-postgres-*`, puertos `5641`–`5644`, red `hotel-prueba-red` y volúmenes propios. La ejecución creó las cuatro bases, tres publicaciones de ocho tablas cada una, tres suscripciones, 24 relaciones de suscripción en estado `r` y 24 tablas externas de FDW. El entorno original no se modificó. Las evidencias están en `evidence/validacion_entorno_limpio_20261113/`.

### 4.7.1 Carga de datos de demostración

La carga de datos demo es independiente de la instalación estructural y debe ejecutarse después de crear las publicaciones y suscripciones:

```powershell
.\scripts\cargar_datos_demo.ps1 -ConfirmarCargaDemo
```

El script carga datos en Cancún, Tulum y Bacalar para que la replicación los propague al nodo central. Es idempotente: utiliza identificadores fijos y actualizaciones controladas, por lo que puede ejecutarse varias veces sin duplicar registros. En la validación se ejecutó dos veces y los conteos no cambiaron.

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

La prueba Python utiliza dos hilos y conexiones independientes. El resultado fue una reservación aceptada y otra rechazada por la restricción `ex_reservacion_sin_traslape`.

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

El script `python/tests/test_2pc.py` demuestra el traslado de una reservación de Cancún a Tulum. La prueba crea su propia reservación, captura el identificador y elimina al inicio solo las reservaciones de ejecuciones anteriores identificadas con el marcador `PRUEBA_2PC_AUTOMATICA`. Por ello, puede repetirse sin editar identificadores. La variable opcional `HOTEL_2PC_RESERVACION_ID` permite usar una reservación existente en el modo manual.

En el entorno limpio aislado, la prueba se ejecutó dos veces consecutivas con código de salida `0` y generó identificadores distintos. La última reservación trasladada quedó en Tulum como evidencia; la bitácora registró `DELETE` en Cancún e `INSERT` en Tulum, y los cuatro nodos reportaron cero transacciones preparadas pendientes.

La coordinación de las dos transacciones es responsabilidad del programa Python. No se atribuye a `postgres_fdw` la ejecución automática de 2PC.

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

Las pruebas requieren que los contenedores estén activos y que `HOTEL_DB_PASSWORD` esté configurada. La conexión se puede dirigir a otro entorno con `HOTEL_DB_HOST` y las variables `HOTEL_DB_PORT_*`.

La prueba de concurrencia requiere los registros de sede, huésped, habitación y tarifa usados por el script, y elimina las reservaciones identificadas con `PRUEBA_CONCURRENCIA_`. La prueba 2PC funciona en modo automático, crea su propia reservación en Cancún, la traslada a Tulum y limpia solo los datos con el marcador `PRUEBA_2PC_AUTOMATICA`; no requiere editar identificadores para repetirla. El modo manual con `HOTEL_2PC_RESERVACION_ID` solo debe usarse con una reservación que no haya sido trasladada.

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

\newpage

# 5. MANUAL DE USUARIO

## 5.1 Introducción

Este manual describe el uso del cliente de demostración desarrollado en Python para administrar operaciones básicas de reservaciones hoteleras en Cancún, Tulum y Bacalar.

La aplicación funciona desde una consola y se conecta a las bases de datos PostgreSQL correspondientes. También permite consultar información consolidada desde el nodo central.

## 5.2 Requisitos

- Docker Desktop activo.
- Contenedores del proyecto en ejecución.
- Python 3.10 o superior.
- Dependencias instaladas.
- Contraseña de PostgreSQL disponible mediante la variable de entorno HOTEL_DB_PASSWORD. Si no está configurada, el cliente solicita la contraseña directamente en la consola.

## 5.3 Inicio de la aplicación

Abrir PowerShell en la carpeta del proyecto y ejecutar:

```powershell
python .\python\client\main.py
```

La aplicación presenta el menú principal:

```text
SISTEMA DE RESERVACIONES HOTELERAS

1. Operaciones Cancún
2. Operaciones Tulum
3. Operaciones Bacalar
4. Reporte consolidado
0. Salir
```

## 5.4 Seleccionar una sede

Seleccionar la opción correspondiente a la sede que se desea administrar.

Cada sede presenta las siguientes opciones:

```text
1. Consultar disponibilidad
2. Crear reservación
3. Consultar reservaciones
4. Realizar check-in
5. Realizar check-out
6. Cancelar reservación
0. Regresar
```

## 5.5 Consultar disponibilidad

1. Seleccionar una sede.
2. Elegir la opción de consulta de disponibilidad.
3. Introducir la fecha de entrada.
4. Introducir la fecha de salida.
5. Introducir la cantidad de huéspedes.

El sistema consulta la función `fn_consultar_disponibilidad` y muestra las habitaciones que cumplen las condiciones de capacidad, estado, tarifa y fechas.

## 5.6 Crear una reservación

1. Seleccionar la sede.
2. Elegir crear reservación.
3. Introducir las fechas de estancia.
4. Indicar la cantidad de huéspedes.
5. Seleccionar una habitación disponible.
6. Seleccionar un huésped registrado.
7. Seleccionar una tarifa válida.
8. Introducir observaciones cuando corresponda.
9. Confirmar la operación.

La aplicación invoca `fn_crear_reservacion`, que valida la información y calcula el importe de alojamiento.

Si la operación se completa, se muestra el identificador UUID de la reservación.

## 5.7 Consultar reservaciones

Seleccionar la opción correspondiente para consultar las reservaciones de la sede.

El sistema muestra información como:

- Identificador de reservación.
- Nombre del huésped.
- Número de habitación.
- Fechas de estancia.
- Estado.
- Total.
- Importe pagado.
- Saldo pendiente.

## 5.8 Realizar check-in

1. Seleccionar la sede.
2. Elegir la opción de check-in.
3. Introducir el UUID de la reservación.
4. Confirmar la operación.

El sistema ejecuta `fn_realizar_checkin`. Si las validaciones se cumplen, la reservación cambia a `CHECK_IN` y la habitación se actualiza a ocupada.

## 5.9 Realizar check-out

1. Seleccionar la sede.
2. Elegir la opción de check-out.
3. Introducir el UUID de la reservación.
4. Confirmar la operación.

El sistema ejecuta `fn_realizar_checkout`. La reservación cambia a `FINALIZADA` y se actualiza el estado de la habitación según las reservaciones activas correspondientes.

## 5.10 Cancelar reservación

1. Seleccionar la sede.
2. Elegir la opción de cancelar.
3. Introducir el UUID de la reservación.
4. Confirmar la operación.

La aplicación ejecuta `fn_cancelar_reservacion`. Solo se permiten los estados contemplados por la función. Las reservaciones con check-in realizado no pueden cancelarse mediante esta operación.

## 5.11 Consultar reporte consolidado

En el menú principal seleccionar:

```text
4. Reporte consolidado
```

La aplicación se conecta al nodo central y consulta `vw_reservaciones_distribuidas`.

El resultado muestra información de las reservaciones procedentes de las tres sedes.

## 5.12 Mensajes y errores

La aplicación puede mostrar mensajes cuando:

- No existen habitaciones disponibles.
- Las fechas son inválidas.
- La habitación no cumple las condiciones de capacidad o disponibilidad.
- La reservación no existe.
- El estado de una reservación no permite ejecutar una operación.
- La conexión con PostgreSQL falla.
- Se produce una violación de una restricción de integridad.

Cuando se presente un error, se debe verificar que los contenedores estén activos, que la contraseña sea correcta y que los datos introducidos correspondan a los registros existentes.

## 5.13 Recomendaciones

- Utilizar fechas en el formato solicitado por el programa.
- Conservar los UUID de las reservaciones.
- No ejecutar operaciones sobre reservaciones sin verificar su estado.
- No detener los contenedores durante una operación.
- No modificar manualmente los datos de prueba mientras se realizan demostraciones.
- Utilizar el reporte consolidado para consultar información general.

## 5.14 Alcance de la aplicación

El cliente es una herramienta académica de demostración. No implementa una interfaz gráfica, autenticación de usuarios, facturación electrónica ni procesamiento de pagos reales.

---

**Fin del manual de usuario.**

\newpage

# 6. REFERENCIAS BIBLIOGRÁFICAS

[1] PostgreSQL Global Development Group, “PostgreSQL 18 Documentation.” [En línea]. Disponible en: https://www.postgresql.org/docs/18/. [Consultado: 11-nov-2026].

[2] K. Schwaber y J. Sutherland, “The Scrum Guide.” [En línea]. Disponible en: https://scrumguides.org/. [Consultado: 11-nov-2026].

[3] Docker Inc., “Docker Compose Documentation.” [En línea]. Disponible en: https://docs.docker.com/compose/. [Consultado: 11-nov-2026].

[4] Python Software Foundation, “Python 3 Documentation.” [En línea]. Disponible en: https://docs.python.org/3/. [Consultado: 11-nov-2026].

[5] Psycopg Team, “Psycopg 3 Documentation.” [En línea]. Disponible en: https://www.psycopg.org/psycopg3/docs/. [Consultado: 11-nov-2026].

[6] Git Project, “Git Documentation.” [En línea]. Disponible en: https://git-scm.com/doc. [Consultado: 11-nov-2026].

[7] PostgreSQL Global Development Group, “Constraints,” PostgreSQL 18 Documentation. [En línea]. Disponible en: https://www.postgresql.org/docs/18/ddl-constraints.html. [Consultado: 11-nov-2026].

[8] PostgreSQL Global Development Group, “JSON Types,” PostgreSQL 18 Documentation. [En línea]. Disponible en: https://www.postgresql.org/docs/18/datatype-json.html. [Consultado: 11-nov-2026].

[9] PostgreSQL Global Development Group, “Inheritance,” PostgreSQL 18 Documentation. [En línea]. Disponible en: https://www.postgresql.org/docs/18/ddl-inherit.html. [Consultado: 11-nov-2026].

[10] PostgreSQL Global Development Group, “Index Types,” PostgreSQL 18 Documentation. [En línea]. Disponible en: https://www.postgresql.org/docs/18/indexes-types.html. [Consultado: 11-nov-2026].

[11] PostgreSQL Global Development Group, “Using EXPLAIN,” PostgreSQL 18 Documentation. [En línea]. Disponible en: https://www.postgresql.org/docs/18/using-explain.html. [Consultado: 11-nov-2026].

[12] PostgreSQL Global Development Group, “Range Types,” PostgreSQL 18 Documentation. [En línea]. Disponible en: https://www.postgresql.org/docs/18/rangetypes.html. [Consultado: 11-nov-2026].

[13] PostgreSQL Global Development Group, “Explicit Locking,” PostgreSQL 18 Documentation. [En línea]. Disponible en: https://www.postgresql.org/docs/18/explicit-locking.html. [Consultado: 11-nov-2026].

[14] PostgreSQL Global Development Group, “pg_basebackup,” PostgreSQL 18 Documentation. [En línea]. Disponible en: https://www.postgresql.org/docs/18/app-pgbasebackup.html. [Consultado: 11-nov-2026].

[15] PostgreSQL Global Development Group, “Continuous Archiving and Point-in-Time Recovery (PITR),” PostgreSQL 18 Documentation. [En línea]. Disponible en: https://www.postgresql.org/docs/18/continuous-archiving.html. [Consultado: 11-nov-2026].

[16] PostgreSQL Global Development Group, “Table Partitioning,” PostgreSQL 18 Documentation. [En línea]. Disponible en: https://www.postgresql.org/docs/18/ddl-partitioning.html. [Consultado: 11-nov-2026].

[17] PostgreSQL Global Development Group, “Logical Replication,” PostgreSQL 18 Documentation. [En línea]. Disponible en: https://www.postgresql.org/docs/18/logical-replication.html. [Consultado: 11-nov-2026].

[18] PostgreSQL Global Development Group, “postgres_fdw,” PostgreSQL 18 Documentation. [En línea]. Disponible en: https://www.postgresql.org/docs/18/postgres-fdw.html. [Consultado: 11-nov-2026].

[19] PostgreSQL Global Development Group, “PREPARE TRANSACTION,” PostgreSQL 18 Documentation. [En línea]. Disponible en: https://www.postgresql.org/docs/18/sql-prepare-transaction.html. [Consultado: 11-nov-2026].

**Nota:** Las referencias fundamentan las tecnologías, conceptos y mecanismos implementados en el proyecto. Su numeración corresponde al orden de primera aparición de las citas dentro del informe académico. Las fechas de consulta indican la fecha de revisión documental y deben corresponder con las consultas efectivamente realizadas.

\newpage

# 7. DECLARACIÓN DE USO DE INTELIGENCIA ARTIFICIAL

## 7.1 Declaración

Durante el desarrollo del proyecto integrador denominado **“Base de datos distribuida para reservaciones de una cadena hotelera con sedes en Cancún, Tulum y Bacalar”**, se utilizó ChatGPT, desarrollado por OpenAI, como herramienta de apoyo académico y técnico.

La herramienta se empleó para resolver dudas técnicas, revisar fragmentos de código SQL y Python, analizar errores, proponer correcciones, organizar actividades de desarrollo y apoyar la elaboración de documentación técnica y académica.

La inteligencia artificial no sustituyó la implementación ni la verificación del proyecto. El alumno realizó las modificaciones, ejecutó los scripts y configuraciones en su entorno local y comprobó los resultados mediante PostgreSQL, Python, Docker y Git. Las propuestas generadas se revisaron antes de incorporarse al proyecto.

## 7.2 Actividades en las que se utilizó

La inteligencia artificial se utilizó como apoyo en las siguientes actividades:

- Análisis y organización de la arquitectura de base de datos distribuida.
- Diseño y revisión del modelo relacional.
- Revisión de estructuras SQL, claves, restricciones e índices.
- Desarrollo y revisión de funciones PL/pgSQL y triggers.
- Análisis y diagnóstico de errores relacionados con PostgreSQL.
- Configuración y revisión de la replicación lógica.
- Organización de consultas distribuidas mediante `postgres_fdw`.
- Diseño y revisión de pruebas de concurrencia y transacciones preparadas.
- Desarrollo y revisión del cliente de demostración en Python.
- Análisis de resultados de rendimiento mediante `EXPLAIN ANALYZE`.
- Revisión de procedimientos de respaldo y recuperación.
- Elaboración y organización de documentación técnica y académica.
- Preparación de explicaciones para la presentación y defensa del proyecto.

## 7.3 Responsabilidad académica

El alumno es responsable del contenido, diseño, implementación, funcionamiento y resultados presentados en el proyecto.

La información generada con apoyo de inteligencia artificial fue revisada y contrastada con la documentación oficial de las tecnologías y con las pruebas ejecutadas en el entorno local.

Las sugerencias que no fueron implementadas o verificadas no se presentan como funcionalidades terminadas ni como resultados comprobados.

La interpretación de los resultados, las decisiones de diseño y la validación de los componentes corresponden al alumno.

## 7.4 Herramienta utilizada

- **Desarrollador:** OpenAI.
- **Herramienta:** ChatGPT.
- **Modelo utilizado:** GPT-5.
- **Uso principal:** asistencia técnica, análisis, revisión de código, resolución de dudas y apoyo en la documentación del proyecto.

## 7.5 Compromiso de transparencia

Se reconoce expresamente el uso de inteligencia artificial como herramienta de apoyo durante el desarrollo del proyecto.

La bitácora de uso de inteligencia artificial, incluida en el archivo `08_bitacora_uso_ia.md`, registra las principales solicitudes realizadas, las propuestas obtenidas, las decisiones tomadas por el alumno y los procedimientos utilizados para verificar los resultados.

El uso de esta herramienta no sustituye la comprensión de los conceptos ni la capacidad del alumno para explicar y defender las decisiones técnicas y los resultados del proyecto.

---

**Fin de la declaración.**

\newpage

# 8. BITÁCORA DE USO DE INTELIGENCIA ARTIFICIAL

## 8.1 Registro de interacciones

| N.º | Solicitud realizada                                                                                 | Resultado de la herramienta                                                                             | Decisión del alumno                                         | Verificación                                                                                                                                                                                               |
| ---------------------------------------- | --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Proponer una arquitectura para una base de datos distribuida de una cadena hotelera con tres sedes. | Se propuso una arquitectura con tres nodos operativos y un nodo central.                                | Aceptada y adaptada al proyecto.                            | Se implementaron cuatro instancias PostgreSQL mediante Docker Compose.                                                                                                                                     |
| 2   | Diseñar la estructura relacional para huéspedes, habitaciones, tarifas y reservaciones.             | Se propusieron tablas, claves y restricciones de integridad.                                            | Aceptada con correcciones durante la implementación.        | Se ejecutaron los scripts SQL en las bases de datos y se comprobaron las estructuras.                                                                                                                      |
| 3   | Incorporar características orientadas a objetos en PostgreSQL.                                      | Se propusieron tipos compuestos, herencia, arreglos y JSONB.                                            | Aceptada.                                                   | Se realizaron inserciones y consultas de prueba sobre las estructuras especializadas.                                                                                                                      |
| 4   | Revisar las funciones de reservación y los controles para evitar traslapes.                         | Se propusieron bloqueos de fila y restricciones de exclusión GiST.                                      | Aceptada y ajustada.                                        | Se ejecutó una prueba con dos hilos y conexiones independientes; una reservación fue aceptada y otra rechazada por la restricción de exclusión.                                                            |
| 5   | Corregir la auditoría y el cálculo automático de importes.                                          | Se propusieron triggers para registrar operaciones y recalcular totales.                                | Aceptada con correcciones en los identificadores auditados. | Se verificaron inserciones, actualizaciones, pagos, servicios y saldos mediante pruebas operativas.                                                                                                        |
| 6   | Analizar la optimización de consultas con índices.                                                  | Se propusieron índices y comparaciones mediante EXPLAIN ANALYZE.                                        | Aceptada.                                                   | Se generaron 50,000 reservaciones y se midieron consultas B-tree y GiST, comparando ejecuciones con y sin utilización de índices.                                                                          |
| 7   | Configurar replicación lógica y consultas distribuidas.                                             | Se propusieron publicaciones, suscripciones y conexiones postgres_fdw.                                  | Aceptada y corregida durante la integración.                | Se verificaron 24 relaciones de replicación, operaciones INSERT, UPDATE y DELETE, y consultas remotas mediante FDW.                                                                                        |
| 8   | Implementar un traslado de reservaciones entre sedes.                                               | Se propuso coordinar transacciones preparadas mediante Python.                                          | Aceptada.                                                   | Se ejecutó la prueba 2PC automatizada dos veces consecutivas y se verificó el traslado de Cancún a Tulum, la bitácora DELETE/INSERT y la ausencia de transacciones preparadas pendientes. |
| 9   | Desarrollar un cliente de demostración para las operaciones hoteleras.                              | Se propuso un cliente de consola en Python conectado a las cuatro bases.                                | Aceptada.                                                   | Se probaron consultas, creación, cancelación, check-in, check-out y reportes consolidados.                                                                                                                 |
| 10  | Revisar la instalación y organizar la documentación del proyecto.                                   | Se propusieron mejoras al instalador, README, manuales, informe académico y documentos complementarios. | Aceptada y verificada.                                      | Se revisaron los documentos y las referencias cruzadas. El instalador se ejecutó de principio a fin en un entorno limpio aislado el 13 de noviembre de 2026; se comprobaron 24 relaciones de replicación, 24 tablas FDW y las pruebas de concurrencia y 2PC. |

## 8.2 Evaluación del uso de inteligencia artificial

La inteligencia artificial facilitó la comprensión de conceptos de PostgreSQL y permitió agilizar el análisis de errores durante la implementación. También contribuyó a organizar las actividades de desarrollo y a estructurar la documentación técnica y académica.

Sin embargo, las respuestas generadas no se consideraron automáticamente correctas. Las propuestas relacionadas con estructuras, restricciones, replicación, consultas distribuidas y transacciones fueron revisadas y sometidas a pruebas en el entorno local.

Cuando se identificaron errores o diferencias entre las propuestas y el comportamiento real de PostgreSQL, se realizaron ajustes y nuevas verificaciones.

La herramienta funcionó como apoyo para el análisis y la resolución de problemas, mientras que la implementación y la comprobación de los resultados fueron realizadas por el alumno.

## 8.3 Limitaciones identificadas

Durante el uso de inteligencia artificial y el desarrollo del proyecto se identificaron las siguientes limitaciones:

- Algunas propuestas necesitaron ajustes para ser compatibles con las características reales de PostgreSQL.
- Las configuraciones de replicación requirieron verificar las identidades de réplica de las tablas involucradas.
- Los resultados de rendimiento dependieron de las condiciones del entorno de prueba y de los métodos de acceso utilizados.
- La documentación generada necesitó revisión para evitar describir como implementadas funcionalidades que todavía no habían sido verificadas.
- La configuración de respaldo y recuperación a un punto en el tiempo se comprobó en el nodo Cancún, por lo que no se considera validada en los otros nodos.
- El instalador automatizado se ejecutó de principio a fin en una copia aislada el 13 de noviembre de 2026; la validación no modificó el entorno original.
- La inteligencia artificial no ejecutó directamente los comandos en el entorno local del alumno. Las pruebas fueron realizadas por el alumno, quien proporcionó los resultados para su análisis.

## 8.4 Conclusión

El uso de inteligencia artificial funcionó como herramienta de apoyo durante las etapas de análisis, diseño, desarrollo, depuración y documentación del proyecto.

Las respuestas permitieron explorar alternativas de implementación, comprender conceptos técnicos y agilizar la resolución de problemas. No obstante, la aceptación de las propuestas dependió de su revisión y de los resultados obtenidos durante las pruebas locales.

La responsabilidad sobre la implementación, la interpretación de los resultados y la validación final del proyecto corresponde al alumno.

---

**Fin de la bitácora.**

\newpage

# ANEXOS: EVIDENCIAS DEL DESARROLLO Y VALIDACIÓN

Este apartado reúne las capturas de pantalla obtenidas durante la implementación y las pruebas del proyecto. Las evidencias se organizan de acuerdo con las unidades de aprendizaje y el cliente de demostración.

\newpage

## ANEXO A. EVIDENCIAS DE LA UNIDAD I: MODELO RELACIONAL

Se presentan las evidencias de creación y administración del esquema relacional, incluyendo estructuras, relaciones, sentencias DDL y operaciones DML.

**Evidencia: estructura reservaciones 1**

![estructura reservaciones 1](../evidence/unidad_I_relacional/01_bases_relacionales/01_estructura_reservaciones_1.png){ width=6.3in }

\newpage

**Evidencia: estructura reservaciones 2**

![estructura reservaciones 2](../evidence/unidad_I_relacional/01_bases_relacionales/01_estructura_reservaciones_2.png){ width=6.3in }

\newpage

**Evidencia: diagrama entidad relacion**

![diagrama entidad relacion](../evidence/unidad_I_relacional/01_bases_relacionales/02_diagrama_entidad_relacion.png){ width=6.3in }

\newpage

**Evidencia: sentencias DDL**

![sentencias DDL](../evidence/unidad_I_relacional/01_bases_relacionales/03_sentencias_DDL.png){ width=6.3in }

\newpage

**Evidencia: DML insert reservacion**

![DML insert reservacion](../evidence/unidad_I_relacional/01_bases_relacionales/04_DML_insert_reservacion.png){ width=6.3in }

\newpage

**Evidencia: DML update checkin**

![DML update checkin](../evidence/unidad_I_relacional/01_bases_relacionales/05_DML_update_checkin.png){ width=6.3in }

\newpage

**Evidencia: DML select habitacion**

![DML select habitacion](../evidence/unidad_I_relacional/01_bases_relacionales/06_DML_select_habitacion.png){ width=6.3in }

\newpage

**Evidencia: caracteristicas motor postgresql**

![caracteristicas motor postgresql](../evidence/unidad_I_relacional/01_bases_relacionales/07_caracteristicas_motor_postgresql.png){ width=6.3in }

\newpage

**Evidencia: gestor pgadmin**

![gestor pgadmin](../evidence/unidad_I_relacional/01_bases_relacionales/08_gestor_pgadmin.png){ width=6.3in }

\newpage

\newpage

## ANEXO B. EVIDENCIAS DE LA UNIDAD II: BASES DE DATOS ORIENTADAS A OBJETOS

Se documenta el uso de tipos compuestos, atributos, arreglos, JSONB, herencia de tablas y operaciones sobre estructuras orientadas a objetos.

**Evidencia: tipos datos compuestos**

![tipos datos compuestos](../evidence/unidad_II_objetos/02_bases_orientadas_objetos/01_tipos_datos_compuestos.png){ width=6.3in }

\newpage

**Evidencia: atributos tipos compuestos**

![atributos tipos compuestos](../evidence/unidad_II_objetos/02_bases_orientadas_objetos/02_atributos_tipos_compuestos.png){ width=6.3in }

\newpage

**Evidencia: columnas jsonb y arreglos**

![columnas jsonb y arreglos](../evidence/unidad_II_objetos/02_bases_orientadas_objetos/03_columnas_jsonb_y_arreglos.png){ width=6.3in }

\newpage

**Evidencia: relaciones herencia tablas**

![relaciones herencia tablas](../evidence/unidad_II_objetos/02_bases_orientadas_objetos/04_relaciones_herencia_tablas.png){ width=6.3in }

\newpage

**Evidencia: estructura tabla padre huesped**

![estructura tabla padre huesped](../evidence/unidad_II_objetos/02_bases_orientadas_objetos/05_estructura_tabla_padre_huesped.png){ width=6.3in }

\newpage

**Evidencia: estructura tabla padre habitacion**

![estructura tabla padre habitacion](../evidence/unidad_II_objetos/02_bases_orientadas_objetos/06_estructura_tabla_padre_habitacion.png){ width=6.3in }

\newpage

**Evidencia: estructura huesped individual**

![estructura huesped individual](../evidence/unidad_II_objetos/02_bases_orientadas_objetos/07_estructura_huesped_individual.png){ width=6.3in }

\newpage

**Evidencia: estructura huesped corporativo**

![estructura huesped corporativo](../evidence/unidad_II_objetos/02_bases_orientadas_objetos/08_estructura_huesped_corporativo.png){ width=6.3in }

\newpage

**Evidencia: estructura habitacion estandar**

![estructura habitacion estandar](../evidence/unidad_II_objetos/02_bases_orientadas_objetos/09_estructura_habitacion_estandar.png){ width=6.3in }

\newpage

**Evidencia: estructura habitacion suite**

![estructura habitacion suite](../evidence/unidad_II_objetos/02_bases_orientadas_objetos/10_estructura_habitacion_suite.png){ width=6.3in }

\newpage

**Evidencia: sentencias herencia huespedes**

![sentencias herencia huespedes](../evidence/unidad_II_objetos/02_bases_orientadas_objetos/11_sentencias_herencia_huespedes.png){ width=6.3in }

\newpage

**Evidencia: sentencias herencia habitaciones**

![sentencias herencia habitaciones](../evidence/unidad_II_objetos/02_bases_orientadas_objetos/12_sentencias_herencia_habitaciones.png){ width=6.3in }

\newpage

**Evidencia: verificacion columnas heredadas**

![verificacion columnas heredadas](../evidence/unidad_II_objetos/02_bases_orientadas_objetos/13_verificacion_columnas_heredadas.png){ width=6.3in }

\newpage

**Evidencia: estructura arreglo amenidades**

![estructura arreglo amenidades](../evidence/unidad_II_objetos/02_bases_orientadas_objetos/14_estructura_arreglo_amenidades.png){ width=6.3in }

\newpage

**Evidencia: operaciones arreglos postgresql**

![operaciones arreglos postgresql](../evidence/unidad_II_objetos/02_bases_orientadas_objetos/15_operaciones_arreglos_postgresql.png){ width=6.3in }

\newpage

**Evidencia: unnest elementos arreglo**

![unnest elementos arreglo](../evidence/unidad_II_objetos/02_bases_orientadas_objetos/16_unnest_elementos_arreglo.png){ width=6.3in }

\newpage

**Evidencia: operaciones conjuntos sql**

![operaciones conjuntos sql](../evidence/unidad_II_objetos/02_bases_orientadas_objetos/17_operaciones_conjuntos_sql.png){ width=6.3in }

\newpage

\newpage

## ANEXO C. EVIDENCIAS DE LA UNIDAD III: CONSULTAS Y ALMACENAMIENTO

Se incluyen evidencias de vistas, índices, planes de ejecución, funciones almacenadas, triggers y registros de auditoría.

**Evidencia: plan ejecucion consulta**

![plan ejecucion consulta](../evidence/unidad_III_consultas/03_almacenamiento_consultas/01_plan_ejecucion_consulta.png){ width=6.3in }

\newpage

**Evidencia: vistas creadas**

![vistas creadas](../evidence/unidad_III_consultas/03_almacenamiento_consultas/02_vistas_creadas.png){ width=6.3in }

\newpage

**Evidencia: definicion vista ocupacion**

![definicion vista ocupacion](../evidence/unidad_III_consultas/03_almacenamiento_consultas/03_definicion_vista_ocupacion.png){ width=6.3in }

\newpage

**Evidencia: resultado vista ocupacion**

![resultado vista ocupacion](../evidence/unidad_III_consultas/03_almacenamiento_consultas/04_resultado_vista_ocupacion.png){ width=6.3in }

\newpage

**Evidencia: definicion vista reservaciones**

![definicion vista reservaciones](../evidence/unidad_III_consultas/03_almacenamiento_consultas/05_definicion_vista_reservaciones.png){ width=6.3in }

\newpage

**Evidencia: resultado vista reservaciones**

![resultado vista reservaciones](../evidence/unidad_III_consultas/03_almacenamiento_consultas/06_resultado_vista_reservaciones.png){ width=6.3in }

\newpage

**Evidencia: definicion vista servicios**

![definicion vista servicios](../evidence/unidad_III_consultas/03_almacenamiento_consultas/07_definicion_vista_servicios.png){ width=6.3in }

\newpage

**Evidencia: resultado vista servicios**

![resultado vista servicios](../evidence/unidad_III_consultas/03_almacenamiento_consultas/08_resultado_vista_servicios.png){ width=6.3in }

\newpage

**Evidencia: indices tabla reservaciones**

![indices tabla reservaciones](../evidence/unidad_III_consultas/03_almacenamiento_consultas/09_indices_tabla_reservaciones.png){ width=6.3in }

\newpage

**Evidencia: archivos fisicos indices**

![archivos fisicos indices](../evidence/unidad_III_consultas/03_almacenamiento_consultas/10_archivos_fisicos_indices.png){ width=6.3in }

\newpage

**Evidencia: ubicacion fisica tabla**

![ubicacion fisica tabla](../evidence/unidad_III_consultas/03_almacenamiento_consultas/11_ubicacion_fisica_tabla.png){ width=6.3in }

\newpage

**Evidencia: funciones almacenadas**

![funciones almacenadas](../evidence/unidad_III_consultas/03_almacenamiento_consultas/12_funciones_almacenadas.png){ width=6.3in }

\newpage

**Evidencia: codigo funcion disponibilidad**

![codigo funcion disponibilidad](../evidence/unidad_III_consultas/03_almacenamiento_consultas/13_codigo_funcion_disponibilidad.png){ width=6.3in }

\newpage

**Evidencia: resultado funcion disponibilidad**

![resultado funcion disponibilidad](../evidence/unidad_III_consultas/03_almacenamiento_consultas/14_resultado_funcion_disponibilidad.png){ width=6.3in }

\newpage

**Evidencia: triggers configurados**

![triggers configurados](../evidence/unidad_III_consultas/03_almacenamiento_consultas/15_triggers_configurados.png){ width=6.3in }

\newpage

**Evidencia: codigo funcion auditoria**

![codigo funcion auditoria](../evidence/unidad_III_consultas/03_almacenamiento_consultas/16_codigo_funcion_auditoria.png){ width=6.3in }

\newpage

**Evidencia: registros bitacora**

![registros bitacora](../evidence/unidad_III_consultas/03_almacenamiento_consultas/17_registros_bitacora.png){ width=6.3in }

\newpage

\newpage

## ANEXO D. EVIDENCIAS DE LA UNIDAD IV: TRANSACCIONES E INTEGRIDAD

Se muestran las pruebas de concurrencia, restricciones de integridad, rollback, respaldos y recuperación a un punto en el tiempo.

**Evidencia: prueba concurrencia reservaciones**

![prueba concurrencia reservaciones](../evidence/unidad_IV_transacciones/04_transacciones_integridad/01_prueba_concurrencia_reservaciones.png){ width=6.3in }

\newpage

**Evidencia: auditoria borrado reservacion**

![auditoria borrado reservacion](../evidence/unidad_IV_transacciones/04_transacciones_integridad/02_auditoria_borrado_reservacion.png){ width=6.3in }

\newpage

**Evidencia: verificacion respaldo fisico**

![verificacion respaldo fisico](../evidence/unidad_IV_transacciones/04_transacciones_integridad/03_verificacion_respaldo_fisico.png){ width=6.3in }

\newpage

**Evidencia: recuperacion pitr**

![recuperacion pitr](../evidence/unidad_IV_transacciones/04_transacciones_integridad/04_recuperacion_pitr.png){ width=6.3in }

\newpage

**Evidencia: transaccion rollback**

![transaccion rollback](../evidence/unidad_IV_transacciones/04_transacciones_integridad/05_transaccion_rollback.png){ width=6.3in }

\newpage

**Evidencia: integridad restricciones check**

![integridad restricciones check](../evidence/unidad_IV_transacciones/04_transacciones_integridad/06_integridad_restricciones_check.png){ width=6.3in }

\newpage

\newpage

## ANEXO E. EVIDENCIAS DE LA UNIDAD V: BASES DE DATOS DISTRIBUIDAS

Se presentan las pruebas de replicación lógica, publicaciones, particionamiento, consultas mediante FDW y transacciones distribuidas.

**Validación del entorno limpio (13 de noviembre de 2026).** Se instaló una copia aislada con contenedores `hotel-prueba-postgres-*`, puertos 5641–5644 y red `hotel-prueba-red`. El instalador terminó correctamente, se crearon tres publicaciones de ocho tablas, tres suscripciones, 24 relaciones de suscripción en estado `r` y 24 tablas externas de FDW. Los datos demo se cargaron dos veces sin duplicarse. La prueba de concurrencia aceptó una solicitud y rechazó otra con SQLSTATE `23P01`. La prueba 2PC se ejecutó dos veces consecutivas con código `0`, sin transacciones preparadas pendientes. El entorno original no se modificó. Las evidencias están en `evidence/validacion_entorno_limpio_20261113/`.

**Evidencia: replicacion suscripciones activas**

![replicacion suscripciones activas](../evidence/unidad_V_distribuidas/05_bases_distribuidas/01_replicacion_suscripciones_activas.png){ width=6.3in }

\newpage

**Evidencia: publicaciones tablas sedes**

![publicaciones tablas sedes](../evidence/unidad_V_distribuidas/05_bases_distribuidas/02_publicaciones_tablas_sedes.png){ width=6.3in }

\newpage

**Evidencia: fragmentacion particiones central**

![fragmentacion particiones central](../evidence/unidad_V_distribuidas/05_bases_distribuidas/03_fragmentacion_particiones_central.png){ width=6.3in }

\newpage

**Evidencia: plan consulta distribuida fdw**

![plan consulta distribuida fdw](../evidence/unidad_V_distribuidas/05_bases_distribuidas/04_plan_consulta_distribuida_fdw.png){ width=6.3in }

\newpage

**Evidencia: vista reservaciones distribuidas**

![vista reservaciones distribuidas](../evidence/unidad_V_distribuidas/05_bases_distribuidas/05_vista_reservaciones_distribuidas.png){ width=6.3in }

\newpage

**Evidencia: resultado transaccion 2pc**

![resultado transaccion 2pc](../evidence/unidad_V_distribuidas/05_bases_distribuidas/06_resultado_transaccion_2pc.png){ width=6.3in }

\newpage

\newpage

## ANEXO F. EVIDENCIAS DEL CLIENTE DE DEMOSTRACIÓN EN PYTHON

Se documenta la ejecución del cliente de consola y sus operaciones de consulta, reservaciones, disponibilidad, check-in, check-out y reportes.

**Evidencia: menu principal**

![menu principal](../evidence/06_cliente_python/01_menu_principal.png){ width=6.3in }

\newpage

**Evidencia: menu operaciones cancun**

![menu operaciones cancun](../evidence/06_cliente_python/02_menu_operaciones_cancun.png){ width=6.3in }

\newpage

**Evidencia: consulta disponibilidad**

![consulta disponibilidad](../evidence/06_cliente_python/03_consulta_disponibilidad.png){ width=6.3in }

\newpage

**Evidencia: consulta reservacion cancelada**

![consulta reservacion cancelada](../evidence/06_cliente_python/04_consulta_reservacion_cancelada.png){ width=6.3in }

\newpage

**Evidencia: checkin checkout**

![checkin checkout](../evidence/06_cliente_python/05_checkin_checkout.png){ width=6.3in }

\newpage

**Evidencia: reporte consolidado**

![reporte consolidado](../evidence/06_cliente_python/06_reporte_consolidado.png){ width=6.3in }

\newpage