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
| ----- | --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
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
| ------ | ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
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
