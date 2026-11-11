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
| ----- | ---------------------------------- | --------- | ---------------------------------------- |
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
| PB-19 | Evidencias y presentación          | Alta      | Material de evaluación y defensa.        |

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

**Objetivo:** integrar las funcionalidades y preparar el producto para su demostración y evaluación.

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

La organización por sprints permitió dividir el proyecto en etapas relacionadas con las competencias de la asignatura. La reconstrucción del backlog facilita identificar las funcionalidades desarrolladas, sus dependencias y los resultados que deben demostrarse. Para la entrega final se complementará esta planificación con evidencias de ejecución y el historial de versiones del repositorio.
