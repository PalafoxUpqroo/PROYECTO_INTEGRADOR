# 8. BITÁCORA DE USO DE INTELIGENCIA ARTIFICIAL

## 8.1 Registro de interacciones

| N.º | Solicitud realizada                                                                                 | Resultado de la herramienta                                                                             | Decisión del alumno                                         | Verificación                                                                                                                                                                                               |
| --- | --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
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
