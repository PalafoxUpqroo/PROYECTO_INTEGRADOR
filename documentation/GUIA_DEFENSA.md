# GUÍA DE DEFENSA
## Proyecto Integrador: Base de datos distribuida para reservaciones hoteleras
**Alejandro Marron Palafox — Matrícula 202300141**

---

## 0. Cómo usar esta guía

Esta guía está pensada para tres cosas:

1. **Ensayar la presentación de 20 minutos**, diapositiva por diapositiva.
2. **Practicar la demostración en vivo** y el cambio de 10 minutos.
3. **Responder las preguntas del jurado** sin improvisar y sin contradecir el informe.

No memorices todo palabra por palabra. Memoriza:
- La idea central del proyecto.
- El orden de las diapositivas.
- Las 8–10 respuestas clave.
- Los comandos que vas a ejecutar en vivo.

---

## 1. El formato y la rúbrica

La guía del proyecto establece:

- **20 minutos de presentación** (solo Bases de Datos).
- **15 minutos de preguntas** del jurado.
- **10 minutos de cambio en vivo**.
- Jurado: Jonathan Moreno (Director) y Manuel Flores (PTC).

La calificación se compone así:

| Componente | Peso | Qué te evalúan |
|---|---:|---|
| Producto | 50 % | P1 evidencias 19/19, P2 funcionamiento en vivo, P3 calidad técnica |
| Documentación | 10 % | D1 evidencias explicadas, D2 Scrum, D3 manuales/README, D4 formato y IEEE |
| Presentación y defensa | 40 % | E1 estructura/tiempo, E2 dominio y cambio en vivo, E3 comunicación |

**La materia no se acredita si falta una unidad o si P1 queda en Insuficiente.** Tu proyecto tiene las 5 unidades y 19 evidencias; la sección 9.2 del informe lo demuestra.

---

## 2. El pitch de 30 segundos

> “Mi proyecto es una base de datos distribuida para una cadena hotelera con sedes en Cancún, Tulum y Bacalar. Usa cuatro instancias PostgreSQL: tres sedes operativas y un nodo central de reportes. La base evita la sobreventa con una restricción de exclusión GiST sobre rangos de fechas, consolida información con replicación lógica y consultas con postgres_fdw, y mueve reservaciones entre sedes con transacciones en dos fases. Incluye respaldo físico, WAL y recuperación PITR, además de un cliente Python para demostrar las operaciones.”

Si te piden una versión de 2 minutos, agrega:

- El problema: sistemas aislados, sobreventa y falta de consolidación.
- La solución: cuatro nodos, integridad, distribución y recuperación.
- La evidencia: pruebas de concurrencia, 2PC, 50,000 registros y entorno limpio validado.

---

## 3. Guion de 20 minutos, diapositiva por diapositiva

### Diapositiva 1 — Portada (0:00–1:00)

Di:
- Tu nombre, matrícula y el nombre del proyecto.
- Una frase de contexto: “Es una base distribuida para tres sedes hoteleras con un nodo central de reportes”.

No te detengas en el logo ni en la universidad; son 10 segundos.

### Diapositiva 2 — Problema y motivación (1:00–3:00)

Di:
- Cada sede operaba aislada.
- Dos canales podían reservar la misma habitación al mismo tiempo.
- No había una visión consolidada de la ocupación.
- No había respaldos confiables ni recuperación ante fallas.

Cierra con: “El proyecto ataca esos cuatro problemas: sobreventa, consolidación, distribución y recuperación”.

### Diapositiva 3 — Objetivo y alcance (3:00–5:00)

Di:
- Objetivo general: diseñar e implementar la base distribuida en PostgreSQL.
- Alcance: modelo relacional, objetos, funciones, triggers, índices, concurrencia, respaldo/PITR, distribución y cliente.
- Aclara lo que **no** es: no es una plataforma comercial, no tiene pasarela de pagos real, no es alta disponibilidad.

### Diapositiva 4 — Arquitectura distribuida (5:00–7:00)

Di:
- Cuatro nodos: Cancún 5541, Tulum 5542, Bacalar 5543, Central 5544.
- Cada sede tiene su propia base y su propio volumen.
- Central recibe replicación lógica y consulta las sedes con FDW.
- El cliente Python se conecta a las sedes y al central.

Señala el diagrama y di: “La separación es por base de datos, no por esquema; cada sede conserva sus registros operativos”.

### Diapositiva 5 — Tecnologías (7:00–8:30)

Di:
- PostgreSQL 18.6: herencia, JSONB, arreglos, GiST, FDW, replicación lógica, PITR.
- Docker Compose: cuatro instancias aisladas.
- Python 3.10 + psycopg 3: cliente y pruebas.
- Git/GitHub: control de versiones.
- pgAdmin: administración.

No leas la tabla completa; menciona las tres o cuatro tecnologías que sostienen la arquitectura.

### Diapositiva 6 — Mecanismos de distribución y consistencia (8:30–10:30)

Di:
- Particionamiento central por sede.
- FDW para consultas remotas.
- Replicación lógica para consolidar.
- Auditoría con triggers y bitácora.
- Restricciones de integridad y exclusión.

Frase clave: “La replicación mantiene una copia central; FDW sirve para consultas en vivo. No son lo mismo y no se sustituyen”.

### Diapositiva 7 — Evidencias por unidad I–V (10:30–12:30)

Di:
- I: diagrama ER, DDL/DML, características de PostgreSQL.
- II: herencia, tipos compuestos, arreglos, JSONB, conjuntos.
- III: vistas, planes, archivos, funciones, triggers.
- IV: concurrencia, rollback, respaldo, PITR.
- V: replicación, fragmentación, FDW, 2PC.
- Cierra: “La lista de cotejo 19/19 está en la sección 9.2 del informe y cada evidencia remite a su anexo”.

Esta diapositiva es tu mapa para el jurado. Si te preguntan por una evidencia, di el anexo exacto.

### Diapositiva 8 — Prueba de concurrencia (12:30–14:30)

Di:
- Dos hilos, dos conexiones independientes, misma habitación y mismas fechas.
- La función bloquea la habitación con `SELECT FOR UPDATE`.
- La restricción GiST `ex_reservacion_sin_traslape` impide el traslape.
- Resultado: una aceptada y una rechazada con SQLSTATE `23P01`.
- Se ejecutó tres veces; los logs están en `evidence/concurrencia_20261124/`.
- No hubo sobreventa.

Frase clave: “El bloqueo serializa; la restricción es la garantía final”.

### Diapositiva 9 — Transacción distribuida 2PC (14:30–16:30)

Di:
- Se crea una reservación en Cancún.
- Se prepara el DELETE en Cancún y el INSERT en Tulum con `PREPARE TRANSACTION`.
- Se verifican ambas transacciones preparadas.
- Se ejecuta `COMMIT PREPARED` en Tulum y Cancún.
- La bitácora registra DELETE e INSERT.
- Cero transacciones preparadas pendientes.
- Se ejecutó dos veces con IDs distintos; logs en `evidence/2pc_20261124/`.

Aclara: “La coordinación es desde Python; `postgres_fdw` no hace 2PC automáticamente. Es una demostración académica, no un coordinador de producción”.

### Diapositiva 10 — Cliente Python (16:30–17:30)

Di:
- Menú por sede: disponibilidad, reservar, consultar, check-in, check-out, cancelar.
- Reporte consolidado con la vista central.
- El cliente usa variables de entorno; no tiene contraseñas en el código.

No hagas un recorrido largo; muestra una operación y el reporte.

### Diapositiva 11 — Resultados de las pruebas (17:30–19:00)

Di:
- 50,000 reservaciones generadas.
- B-tree: 13.018 ms → 0.056 ms (99.57 %).
- GiST: 9.308 ms → 0.343 ms (96.31 %).
- Instalación limpia: 4 bases, 3 publicaciones, 3 suscripciones, 24 relaciones, 24 tablas FDW, concurrencia y 2PC con código 0.
- Conclusión: el producto funciona y es reproducible.

Aclara: “La comparación sin índice se hizo deshabilitando los métodos de acceso, no borrando índices”.

### Diapositiva 12 — Limitaciones y consideraciones (19:00–19:45)

Di sin rodeos:
- Replicación en una dirección, no alta disponibilidad.
- Respaldo/PITR comprobado en Cancún, no en las tres sedes.
- 2PC coordinado desde Python, sin registro persistente de decisiones.
- Catálogo de sedes común; falta reforzar permisos por sede.
- Cliente de consola, no interfaz web.

Frase clave: “Son limitaciones declaradas; no las presento como funcionalidades terminadas”.

### Diapositiva 13 — Cierre (19:45–20:00)

Di:
- “El proyecto demuestra integridad, concurrencia, recuperación y distribución con PostgreSQL”.
- “Las evidencias están en el informe y en el repositorio”.
- “Quedo atento a sus preguntas”.

---

## 4. Demo en vivo: checklist y guion

### Antes de entrar

- Docker Desktop iniciado.
- Cuatro contenedores activos: `hotel-postgres-cancun`, `-tulum`, `-bacalar`, `-central`.
- Datos demo cargados.
- Cliente Python funcionando.
- Terminal con fuente grande (14–16 pt) y fondo oscuro.
- Notificaciones de Windows desactivadas.
- PDF del informe abierto en la sección 9.2 y en los anexos D/E.
- Logs de evidencia abiertos por si falla la red.

Comandos de verificación:

```powershell
cd O:\proyecto-hotelero-distribuido
docker compose ps
docker exec hotel-postgres-central psql -U hotel_admin -d hotel_central -c "SELECT subname, subenabled FROM pg_subscription ORDER BY subname;"
docker exec hotel-postgres-central psql -U hotel_admin -d hotel_central -c "SELECT srsubstate::text AS estado, COUNT(*) FROM pg_subscription_rel GROUP BY srsubstate;"
```

Debe salir `r` para las 24 relaciones.

### Guion de demo (5–7 minutos)

1. **Disponibilidad**: muestra `fn_consultar_disponibilidad` con fechas y huéspedes.
2. **Reservación**: crea una reservación en Cancún; muestra el ID.
3. **Concurrencia**: ejecuta `python .\python\tests\test_concurrencia.py`; muestra una aceptada y una rechazada con `23P01`.
4. **2PC**: ejecuta `python .\python\tests\test_2pc.py`; muestra el traslado, la bitácora y cero preparadas.
5. **Reporte consolidado**: abre el cliente y muestra la vista central.
6. **Evidencia**: muestra el PDF en la sección 9.2 y el anexo E.

### Si algo falla

- No te disculpes repetidamente ni improvises cambios.
- Di: “La corrida está documentada en el anexo; la muestro en el PDF”.
- Si un contenedor está caído, muestra el log de la última corrida y explica el resultado.
- Nunca inventes una salida; usa la evidencia guardada.

---

## 5. Cambio en vivo de 10 minutos

El jurado pedirá una modificación pequeña. Ten preparadas tres opciones; te recomiendo la **A** porque demuestra replicación y DDL al mismo tiempo.

### Opción A (recomendada): agregar un campo y verlo replicar

**Qué demuestra:** DDL, compatibilidad de esquema en replicación lógica y consulta en el nodo central.

**Regla de oro:** como `habitaciones` se publica, el campo debe existir en el nodo central **antes** de que la sede empiece a enviar el cambio. Agrega primero en central y luego en las sedes.

```powershell
# 1. Central primero
docker exec hotel-postgres-central psql -U hotel_admin -d hotel_central -c "ALTER TABLE habitaciones ADD COLUMN IF NOT EXISTS telefono VARCHAR(20);"

# 2. Sedes
docker exec hotel-postgres-cancun psql -U hotel_admin -d hotel_cancun -c "ALTER TABLE habitaciones ADD COLUMN IF NOT EXISTS telefono VARCHAR(20);"
docker exec hotel-postgres-tulum psql -U hotel_admin -d hotel_tulum -c "ALTER TABLE habitaciones ADD COLUMN IF NOT EXISTS telefono VARCHAR(20);"
docker exec hotel-postgres-bacalar psql -U hotel_admin -d hotel_bacalar -c "ALTER TABLE habitaciones ADD COLUMN IF NOT EXISTS telefono VARCHAR(20);"

# 3. Actualizar en Cancún
docker exec hotel-postgres-cancun psql -U hotel_admin -d hotel_cancun -c "UPDATE habitaciones SET telefono = '998-123-4567' WHERE numero = 'P-DIST-01';"

# 4. Verificar en Central (puede tardar 1–2 segundos)
docker exec hotel-postgres-central psql -U hotel_admin -d hotel_central -c "SELECT numero, telefono FROM habitaciones WHERE numero = 'P-DIST-01';"

# 5. Revertir al terminar: primero las sedes, al final central
docker exec hotel-postgres-cancun psql -U hotel_admin -d hotel_cancun -c "ALTER TABLE habitaciones DROP COLUMN IF EXISTS telefono;"
docker exec hotel-postgres-tulum psql -U hotel_admin -d hotel_tulum -c "ALTER TABLE habitaciones DROP COLUMN IF EXISTS telefono;"
docker exec hotel-postgres-bacalar psql -U hotel_admin -d hotel_bacalar -c "ALTER TABLE habitaciones DROP COLUMN IF EXISTS telefono;"
docker exec hotel-postgres-central psql -U hotel_admin -d hotel_central -c "ALTER TABLE habitaciones DROP COLUMN IF EXISTS telefono;"
```

Al revertir se hace al contrario: primero las sedes y al final central, para que la replicación no intente aplicar cambios sobre una columna que ya no existe en el suscriptor.

Mientras corre, explica:
- “Agrego el campo en el suscriptor primero para que la replicación no falle cuando el publicador envíe la nueva columna”.
- “La replicación es asíncrona; por eso espero un segundo antes de consultar central”.
- “El campo no está en el informe porque es un cambio en vivo; si se quedara, actualizaría el DDL y el modelo”.

### Opción B: cambiar una regla de negocio

Si el jurado pide una regla, puedes cambiar la validación de capacidad en `fn_crear_reservacion` para permitir un huésped adicional y volver a compilar la función. Es más riesgoso porque hay que editar una función larga; si no la tienes preparada, no la elijas.

### Opción C: ajustar una consulta o vista

Crea una vista filtrada en central:

```sql
CREATE OR REPLACE VIEW vw_reservaciones_confirmadas AS
SELECT sede, reservacion_id, fecha_entrada, fecha_salida, total
FROM vw_reservaciones_distribuidas
WHERE estado = 'CONFIRMADA';
```

Luego:

```sql
SELECT COUNT(*) FROM vw_reservaciones_confirmadas;
```

Explica que es una vista sobre FDW, no una copia, y que el filtro se ejecuta en la consulta distribuida.

### Opción D: mover un elemento del cliente

Abre `python/client/main.py`, mueve “Reporte consolidado” al inicio del menú y muestra el cambio. Es la opción más simple, pero demuestra menos base de datos.

---

## 6. Preguntas del jurado y respuestas

### Unidad I — Modelo relacional

**1. ¿Por qué cuatro bases y no una sola?**
Porque cada sede opera localmente y el central consolida. Eso demuestra fragmentación, replicación y consultas distribuidas. La desventaja es la complejidad de sincronización y la consistencia eventual.

**2. ¿Cómo evitas que una reservación use una habitación de otra sede?**
Con claves foráneas compuestas `(sede_id, huesped_id)`, `(sede_id, habitacion_id)` y `(sede_id, tarifa_id)`, más índices únicos por sede. La reservación solo puede apuntar a registros de su misma sede.

**3. ¿El modelo está normalizado?**
Sí, en tercera forma normal para las entidades operativas. Hay columnas derivadas (`periodo`, `subtotal`, `saldo_pendiente`) y totales calculados por triggers para evitar recalcular en cada consulta; es una desnormalización controlada.

**4. ¿Por qué UUID y no enteros?**
UUID permite generar identificadores únicos en nodos distintos sin coordinación. El costo es un índice más grande; para este prototipo es aceptable.

**5. ¿Qué pasa si dos sedes generan el mismo UUID?**
La probabilidad es prácticamente nula; además, el nodo central usa la clave compuesta `(sede_id, reservacion_id)`, así que el mismo UUID en sedes distintas no colisiona.

### Unidad II — Objetos

**6. ¿Cómo funciona `INHERITS`?**
Las tablas hijas heredan columnas del padre. `huesped_individual` y `huesped_corporativo` heredan de `huesped_especializacion`; `habitacion_estandar` y `habitacion_suite` de `habitacion_especializacion`. PostgreSQL no hereda PK, FK ni unique, por eso se declaran explícitamente en cada hija.

**7. ¿Qué pasa si consultas la tabla padre?**
Por defecto incluye las filas de las hijas. Si quieres solo el padre, usas `ONLY`. Eso es una diferencia importante frente a una tabla normal.

**8. ¿Por qué definiste `rango_estancia` y luego usaste `DATERANGE`?**
`rango_estancia` es un tipo compuesto de demostración; para la restricción de traslapes usé el tipo nativo `DATERANGE`, que tiene operadores de solapamiento e índices GiST. Es una decisión de diseño: el tipo compuesto no tiene esos operadores.

**9. ¿Dónde usas JSONB y arreglos?**
`huespedes.preferencias` es JSONB con índice GIN; `habitaciones.amenidades` es `TEXT[]` con índice GIN. Sirven para datos variables; si necesitara joins o restricciones fuertes, los normalizaría.

**10. ¿Qué operaciones de conjuntos usaste?**
`UNION`, `INTERSECT` y `EXCEPT` sobre las amenidades; también operadores de arreglos como `@>` y `&&`.

### Unidad III — Consultas, almacenamiento, funciones y triggers

**11. ¿Cómo se ve el plan B-tree?**
`Index Scan Backward using idx_reservaciones_sede_estado_entrada`, con `Execution Time: 0.056 ms`. Sin índices, `Seq Scan + Sort`, con `13.018 ms`.

**12. ¿Cómo se ve el plan GiST?**
`Bitmap Index Scan on idx_reservaciones_fechas` + `Bitmap Heap Scan`, con `0.343 ms`. Sin índices, `Seq Scan`, con `9.308 ms`.

**13. ¿Por qué la comparación “sin índice” es válida?**
Porque se deshabilitaron `enable_indexscan`, `enable_bitmapscan` e `enable_indexonlyscan` en la misma sesión y con los mismos datos; no se borraron índices ni se cambió la base.

**14. ¿Por qué 50,000 reservaciones?**
Para salir del tamaño de juguete y que el optimizador tenga suficiente información; además, la guía lo pide. Se generaron con `generate_series`, 100 habitaciones por 500 días.

**15. ¿Por qué las reservaciones de prueba están `FINALIZADA`?**
Porque la restricción de exclusión es parcial: solo aplica a estados activos. Así se pueden generar 50,000 sin violar traslapes y sin bloquear la prueba.

**16. ¿Qué vistas creaste?**
`vw_ocupacion_sede`, `vw_reservaciones_detalle`, `vw_servicios_reservacion` y `vw_reservaciones_distribuidas`. La disponibilidad es una función porque recibe fechas y número de huéspedes.

**17. ¿Dónde está la estructura física?**
La evidencia muestra `pg_relation_filepath`, `pg_class.relfilenode` y `pg_relation_size`. La tabla `reservaciones` de Cancún está en `/var/lib/postgresql/18/docker/base/16384/17513`, con archivos separados para sus índices.

**18. ¿Cómo funcionan los triggers de totales?**
Cuando insertas, actualizas o borras un servicio, se recalcula `total_alojamiento + servicios`; cuando insertas o borras un pago aplicado, se recalcula `total_pagado` y `saldo_pendiente`. La bitácora guarda `OLD`/`NEW` en JSONB.

**19. ¿No hay recursión de triggers?**
No: los triggers de servicios y pagos actualizan `reservaciones`, no `reservacion_servicios` ni `pagos`; la bitácora es otra tabla. Están separados por responsabilidad.

### Unidad IV — Transacciones, concurrencia y recuperación

**20. ¿Cómo evitas la sobreventa?**
Con dos capas: `SELECT FOR UPDATE` sobre la habitación para serializar, y la restricción de exclusión GiST `(habitacion_id WITH =, periodo WITH &&)` para los estados activos. La restricción es la garantía; el bloqueo reduce conflictos.

**21. ¿Qué significa SQLSTATE 23P01?**
`exclusion_violation`: otra transacción insertó un periodo que se traslapa con la misma habitación.

**22. ¿Qué pasa si las dos transacciones empiezan al mismo tiempo?**
Una obtiene el lock de la habitación y la otra espera; cuando la primera confirma, la segunda intenta insertar y la restricción la rechaza. En la prueba, una fue aceptada y la otra rechazada.

**23. ¿Por qué no usaste `SERIALIZABLE`?**
Con `READ COMMITTED` y la restricción de exclusión es suficiente para este caso; `SERIALIZABLE` aumentaría los abortos y la complejidad. La restricción es atómica y específica del invariante.

**24. ¿Cómo probaste el rollback?**
Con `BEGIN`, `INSERT`, `SELECT` y `ROLLBACK`; después del rollback la tabla temporal quedó con 0 registros. La evidencia está en el anexo D.

**25. ¿Cómo funciona el respaldo?**
`pg_basebackup` genera una copia física; `pg_verifybackup` la valida; el archivado WAL guarda segmentos; para PITR se usa `recovery.signal`, `restore_command` y `recovery_target_time` en una instancia separada.

**26. ¿Por qué el PITR solo está en Cancún?**
Porque la guía pedía demostrar el procedimiento y se documentó en un nodo; extenderlo a los otros tres es trabajo futuro. El informe lo declara como limitación.

**27. ¿Qué es RPO y RTO en tu solución?**
RPO aproximado: lo que se haya archivado; `archive_timeout=60s` acota la ventana. RTO: manual, depende de restaurar la copia y aplicar WAL; no es alta disponibilidad.

### Unidad V — Distribuidas

**28. ¿Cómo configuraste la replicación lógica?**
Cada sede publica 8 tablas con `CREATE PUBLICATION`; central crea 3 suscripciones. Las tablas usan `REPLICA IDENTITY USING INDEX` con índices únicos `(sede_id, id)`. Son 24 relaciones en estado `r`.

**29. ¿Por qué usaste filtros por `sede_id` en las publicaciones?**
Para publicar solo los registros de la sede; es una fragmentación lógica adicional. La base de cada sede ya contiene sus datos, pero el filtro deja explícita la intención.

**30. ¿La replicación es bidireccional?**
No; es de las sedes hacia el central. Es asíncrona y no es alta disponibilidad. Está declarado en las limitaciones.

**31. ¿Cómo funciona el FDW?**
Central tiene `postgres_fdw`, servidores para Cancún/Tulum/Bacalar, mapeos de usuario y 24 tablas externas en `remoto_*`. La vista `vw_reservaciones_distribuidas` hace `UNION ALL` y el plan muestra `Append` + `Foreign Scan`.

**32. ¿Por qué replicación y FDW a la vez?**
La replicación mantiene una copia central (tabla particionada) para consolidación; FDW consulta datos vivos en las sedes. No son excluyentes: uno copia, el otro consulta en el momento.

**33. ¿Cómo se fragmentan los datos?**
Fragmentación horizontal por sede: cada base operativa conserva sus registros; el central particiona `reservaciones` por `sede_id`. El catálogo de sedes es común; por eso falta reforzar permisos por sede.

**34. ¿Cómo funciona el 2PC?**
Python abre dos transacciones, una en Cancún y otra en Tulum; ejecuta `PREPARE TRANSACTION` en ambas; si ambas están preparadas, hace `COMMIT PREPARED`; si algo falla, hace `ROLLBACK PREPARED`. `max_prepared_transactions=20` en Docker.

**35. ¿Qué pasa si el coordinador Python muere después del prepare?**
Las transacciones quedan preparadas y hay que resolverlas manualmente con `COMMIT PREPARED` o `ROLLBACK PREPARED`. Por eso es una demostración académica, no un coordinador de producción.

**36. ¿`postgres_fdw` hace 2PC automáticamente?**
No. `postgres_fdw` sirve para consultas remotas; el 2PC se coordina desde Python. El informe lo aclara.

**37. ¿Qué es el particionamiento central?**
`reservaciones` en central es `PARTITION BY LIST (sede_id)`, con tres particiones: Cancún, Tulum y Bacalar. La PK es `(sede_id, reservacion_id)`.

**38. ¿La tabla particionada central tiene restricción de exclusión?**
No; es una copia de reportes. La integridad de las reservaciones se garantiza en las sedes operativas, que son donde se escriben.

### Preguntas generales

**39. ¿Qué fue lo más difícil?**
Configurar la identidad de réplica con índices únicos compuestos para que UPDATE/DELETE se replicaran, y coordinar el 2PC sin dejar transacciones preparadas. También la consistencia de la evidencia y la paginación del informe.

**40. ¿Qué mejorarías?**
Permisos por sede, replicación bidireccional o alta disponibilidad con Patroni, respaldo/PITR en los cuatro nodos, un coordinador 2PC con registro persistente, pool de conexiones, monitoreo y migraciones versionadas.

**41. ¿Qué fue lo que hizo la IA?**
La declaración y la bitácora están en el informe: 10 interacciones con ChatGPT, con lo solicitado, lo obtenido, la decisión y la verificación. La IA apoyó análisis y redacción; las pruebas y la validación fueron mías.

**42. ¿Por qué PostgreSQL?**
Porque ofrece en un solo motor herencia, JSONB, arreglos, GiST, restricciones de exclusión, FDW, replicación lógica, PL/pgSQL y PITR. No necesité cinco tecnologías distintas.

**43. ¿Cómo sé que funciona?**
Porque hay tres ejecuciones de concurrencia, dos de 2PC, 50,000 registros con planes medidos y una instalación limpia validada con 24 relaciones y 24 tablas FDW. Las evidencias están en el repo y en el informe.

**44. ¿Qué no es producción?**
La alta disponibilidad, el aislamiento estricto por sede, el coordinador 2PC, el cliente web y el respaldo de los cuatro nodos. Todo está en limitaciones.

---

## 7. Trampas: lo que NO debes decir

- ❌ “Nunca habrá sobreventa en ningún caso”.  
  ✅ “La restricción evita traslapes en estados activos; canceladas y finalizadas liberan el periodo”.

- ❌ “Los cuatro nodos tienen PITR”.  
  ✅ “El PITR se comprobó en Cancún; los otros nodos no lo tienen configurado”.

- ❌ “El 2PC es de nivel producción”.  
  ✅ “Es una demostración académica coordinada desde Python, sin registro persistente de decisiones”.

- ❌ “FDW hace 2PC”.  
  ✅ “FDW consulta; el 2PC lo coordina Python”.

- ❌ “La replicación es alta disponibilidad”.  
  ✅ “Es replicación lógica asíncrona y en una dirección”.

- ❌ “Cada sede está completamente aislada”.  
  ✅ “Hay fragmentación por base, pero el catálogo de sedes es común; falta reforzar permisos”.

- ❌ “La tabla particionada central es la que usa el reporte”.  
  ✅ “El reporte usa `vw_reservaciones_distribuidas` con FDW; la tabla particionada es la copia replicada”.

- ❌ “La restricción de exclusión es un trigger”.  
  ✅ “Es una restricción `EXCLUDE USING GIST`”.

- ❌ “`SELECT FOR UPDATE` por sí solo evita la sobreventa”.  
  ✅ “El bloqueo serializa; la restricción GiST es la garantía”.

- ❌ “Los 50,000 registros se compararon borrando índices”.  
  ✅ “Se deshabilitaron los métodos de acceso en la sesión”.

- ❌ “El tablero es histórico”.  
  ✅ “Es una reconstrucción retrospectiva; el informe lo declara”.

- ❌ Fechas exactas de IA inventadas.  
  ✅ “El informe usa 2026-11 como mes de desarrollo porque no se conservó registro diario”.

---

## 8. Mapa de archivos y líneas clave

| Tema | Archivo | Qué mostrar |
|---|---|---|
| Restricción de exclusión | `database/03_tables/06_reservaciones_pagos_servicios.sql` | `EXCLUDE USING GIST` (aprox. líneas 83–90) |
| Bloqueo de habitación | `database/04_functions/01_reservaciones.sql` | `SELECT ... FOR UPDATE` (aprox. líneas 54–61) |
| Concurrencia | `python/tests/test_concurrencia.py` | Hilos, barrera, dos conexiones |
| 2PC | `python/tests/test_2pc.py` | `PREPARE TRANSACTION` / `COMMIT PREPARED` (aprox. líneas 656–680) |
| Particiones | `database/08_partitions/01_particionar_reservaciones_central.sql` | `PARTITION BY LIST (sede_id)` |
| Publicaciones | `database/09_distributed/01_publicacion_cancun.sql` | 8 tablas, filtro por sede |
| Suscripciones | `database/09_distributed/05_suscripciones_central.sql` | 3 suscripciones |
| FDW | `database/09_distributed/04_configuracion_fdw_central.sql` | Servidores, 24 tablas, vista |
| Cliente | `python/client/main.py` | Menú y operaciones |
| Informe | `Proyecto_Integrador_BD_Distribuida.pdf` | Sección 9.2 y anexos A–F |
| Evidencias | `evidence/` | 19 evidencias y logs nuevos |

Comandos útiles:

```powershell
cd O:\proyecto-hotelero-distribuido
docker compose ps
python .\python\tests\test_concurrencia.py
python .\python\tests\test_2pc.py
python .\python\client\main.py
git log --oneline
```

---

## 9. Checklist: 24 horas, 1 hora y durante

### 24 horas antes

- [ ] Abrir el PDF y el PPTX en otro equipo.
- [ ] Verificar que el logo se vea bien.
- [ ] Ejecutar una vez la concurrencia y el 2PC.
- [ ] Revisar que los cuatro contenedores estén activos.
- [ ] Cargar el celular y llevar cargador.
- [ ] Llevar el PDF en USB y en la nube.
- [ ] Ensayar el cambio en vivo al menos dos veces.

### 1 hora antes

- [ ] Iniciar Docker Desktop.
- [ ] `docker compose up -d`.
- [ ] Verificar 4 contenedores.
- [ ] Abrir el cliente y probar una consulta.
- [ ] Cerrar notificaciones y pestañas.
- [ ] Abrir la terminal con fuente grande.
- [ ] Abrir el PDF en la sección 9.2.
- [ ] Abrir los logs de evidencia.
- [ ] Probar el proyector y el audio.

### Durante la presentación

- [ ] No leer las diapositivas.
- [ ] Mirar al jurado.
- [ ] Marcar el tiempo: 20 minutos.
- [ ] Mostrar evidencia, no solo decir que existe.
- [ ] Si algo falla, usar el PDF y explicar.
- [ ] Al cerrar, decir las limitaciones con seguridad.

### Después

- [ ] Responder con calma; si no sabes, dilo.
- [ ] En el cambio en vivo, explicar cada comando.
- [ ] Agradecer y ofrecer el repositorio.

---

## 10. Cómo se mapea tu proyecto a la rúbrica

| Criterio | Evidencia que debes mostrar |
|---|---|
| P1. Evidencias 19/19 | Sección 9.2 y anexos A–F |
| P2. Funcionamiento | Demo de disponibilidad, reserva, concurrencia y 2PC |
| P3. Calidad técnica | Código por carpetas, README, historial de Git |
| D1. Evidencias explicadas | Secciones 8.1–8.5 y bitácora de IA |
| D2. Scrum | Sección 13: backlog, mapeo HU, sprints, burndown, retrospectivas |
| D3. Manuales | Secciones 14 y 15; README |
| D4. Formato y IEEE | Portada, índice, referencias [1]–[19] |
| E1. Estructura y tiempo | 13 diapositivas, 20 minutos |
| E2. Dominio y cambio | Respuestas y cambio en vivo |
| E3. Comunicación | Tono, claridad, apoyo visual |

---

## 11. Plan de ensayo

### Pasada 1 — Leer y cronometrar

- Lee el guion completo en voz alta.
- Marca dónde te pasas de tiempo.
- Ajusta: si te sobra tiempo, agrega un ejemplo; si te falta, recorta las diapositivas 5–6.

### Pasada 2 — Sin notas

- Presenta solo con las diapositivas.
- Grábate con el celular.
- Revisa muletillas, velocidad y contacto visual.

### Pasada 3 — Simulación de jurado

- Pide a alguien que te haga 10 preguntas de la sección 6.
- Haz el cambio en vivo cronometrado.
- Si falla algo, practica la respuesta de contingencia.

### Ensayo del cambio en vivo

- Opción A: 3 veces, midiendo 5–7 minutos.
- Si te toma más de 10, simplifica: solo agrega el campo en central y Cancún, muestra la consulta y explica que en producción se haría en las cuatro bases.

---

## 12. Frases de cierre y manejo de nervios

- “Lo que no está implementado está declarado en limitaciones; no lo presento como terminado”.
- “Esa parte no la trabajé; la dejaría como trabajo futuro”.
- “La evidencia está en el anexo; si gustan, la abro”.
- “El producto es un prototipo académico; demuestra los conceptos, no es una plataforma comercial”.
- Respira antes de responder. Una pausa de dos segundos no es un error; es control.

---

## 13. Cheat sheet de una página

**Arquitectura:** Cancún 5541, Tulum 5542, Bacalar 5543, Central 5544.

**Concurrencia:** `SELECT FOR UPDATE` + `EXCLUDE USING GIST (habitacion_id WITH =, periodo WITH &&) WHERE estado IN (...)`.

**2PC:** `PREPARE TRANSACTION` → verificar → `COMMIT PREPARED`; si falla, `ROLLBACK PREPARED`; `max_prepared_transactions=20`.

**Replicación:** 3 publicaciones × 8 tablas = 24 relaciones; 3 suscripciones; estado `r`.

**FDW:** 3 servidores, 24 tablas externas, `vw_reservaciones_distribuidas`; plan `Append + Foreign Scan`.

**Particiones:** `reservaciones` central `PARTITION BY LIST (sede_id)`; 3 particiones.

**Rendimiento:** B-tree 13.018 → 0.056 ms (99.57 %); GiST 9.308 → 0.343 ms (96.31 %); 50,000 registros.

**Respaldo:** `pg_basebackup` + `pg_verifybackup` + WAL + PITR; solo Cancún.

**Limitaciones:** una dirección, sin HA, 2PC académico, catálogo común, cliente de consola.

**Comandos:**
```powershell
docker compose ps
python .\python\tests\test_concurrencia.py
python .\python\tests\test_2pc.py
python .\python\client\main.py
```
