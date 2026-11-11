# 5. MANUAL DE USUARIO

## 5.1 Introducción

Este manual describe el uso del cliente de demostración desarrollado en Python para administrar operaciones básicas de reservaciones hoteleras en Cancún, Tulum y Bacalar.

La aplicación funciona desde una consola y se conecta a las bases de datos PostgreSQL correspondientes. También permite consultar información consolidada desde el nodo central.

## 5.2 Requisitos

- Docker Desktop activo.
- Contenedores del proyecto en ejecución.
- Python 3.10 o superior.
- Dependencias instaladas.
- Variable de entorno `HOTEL_DB_PASSWORD` configurada.

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
