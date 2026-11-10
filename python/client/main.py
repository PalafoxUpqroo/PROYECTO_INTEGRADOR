
import os
import uuid
from datetime import date, datetime
from getpass import getpass

import psycopg
from psycopg.rows import dict_row


# =========================================================
# CONFIGURACION
# =========================================================

PASSWORD = os.getenv("HOTEL_DB_PASSWORD")

if not PASSWORD:
    PASSWORD = getpass("Contrasena de PostgreSQL: ")



SEDES = {
    "1": {
        "nombre": "CANCÚN",
        "host": "127.0.0.1",
        "port": 5541,
        "dbname": "hotel_cancun",
        "sede_id": "11111111-1111-4111-8111-111111111111",
    },
    "2": {
        "nombre": "TULUM",
        "host": "127.0.0.1",
        "port": 5542,
        "dbname": "hotel_tulum",
        "sede_id": "22222222-2222-4222-8222-222222222222",
    },
    "3": {
        "nombre": "BACALAR",
        "host": "127.0.0.1",
        "port": 5543,
        "dbname": "hotel_bacalar",
        "sede_id": "33333333-3333-4333-8333-333333333333",
    },
}


CENTRAL = {
    "host": "127.0.0.1",
    "port": 5544,
    "dbname": "hotel_central",
    "user": "hotel_admin",
    "password": PASSWORD,
}


# =========================================================
# CONEXION
# =========================================================

def conectar(config):
    return psycopg.connect(
        host=config["host"],
        port=config["port"],
        dbname=config["dbname"],
        user="hotel_admin",
        password=PASSWORD,
        row_factory=dict_row
    )


def conectar_central():
    return psycopg.connect(
        **CENTRAL,
        row_factory=dict_row
    )


# =========================================================
# FUNCIONES AUXILIARES
# =========================================================

def pausa():
    input("\nPresiona ENTER para continuar...")


def leer_fecha(mensaje):
    while True:
        valor = input(mensaje).strip()

        try:
            return date.fromisoformat(valor)
        except ValueError:
            print("Fecha invalida. Utiliza el formato YYYY-MM-DD.")


def leer_entero(mensaje, minimo=1):
    while True:
        try:
            valor = int(input(mensaje))

            if valor < minimo:
                print(f"El valor minimo es {minimo}.")
                continue

            return valor

        except ValueError:
            print("Introduce un numero entero valido.")


def leer_uuid(mensaje):
    while True:
        try:
            return str(uuid.UUID(input(mensaje).strip()))
        except ValueError:
            print("UUID invalido. Intenta nuevamente.")


def seleccionar_sede():
    print("\n========== SELECCIONAR SEDE ==========")

    for clave, sede in SEDES.items():
        print(f"{clave}. {sede['nombre']}")

    print("0. Regresar")

    opcion = input("\nSelecciona una sede: ").strip()

    if opcion == "0":
        return None

    if opcion not in SEDES:
        print("Opcion invalida.")
        return None

    return SEDES[opcion]



def obtener_sede_id(conn, sede):
    resultado = conn.execute(
        """
        SELECT sede_id, nombre, ciudad
        FROM sedes
        WHERE sede_id = %s
          AND activa = TRUE
        """,
        (sede["sede_id"],)
    ).fetchone()

    if not resultado:
        raise RuntimeError(
            f"No se encontro la sede activa: {sede['nombre']}"
        )

    return resultado["sede_id"]



def mostrar_titulo(texto):
    print("\n" + "=" * 55)
    print(texto)
    print("=" * 55)


# =========================================================
# 1. CONSULTAR DISPONIBILIDAD
# =========================================================

def consultar_disponibilidad(conn, sede_id):

    mostrar_titulo("CONSULTAR DISPONIBILIDAD")

    entrada = leer_fecha("Fecha de entrada (YYYY-MM-DD): ")
    salida = leer_fecha("Fecha de salida (YYYY-MM-DD): ")
    huespedes = leer_entero("Numero de huespedes: ")

    if salida <= entrada:
        print("La fecha de salida debe ser posterior a la entrada.")
        return

    habitaciones = conn.execute(
        """
        SELECT *
        FROM fn_consultar_disponibilidad(
            %s, %s, %s, %s
        )
        ORDER BY numero
        """,
        (sede_id, entrada, salida, huespedes)
    ).fetchall()

    if not habitaciones:
        print("\nNo hay habitaciones disponibles para esas fechas.")
        return

    print("\nHABITACIONES DISPONIBLES")

    for i, habitacion in enumerate(habitaciones, start=1):
        print(f"\n{i}. Habitacion {habitacion['numero']}")
        print(f"   ID: {habitacion['habitacion_id']}")
        print(f"   Tipo: {habitacion['tipo_habitacion']}")
        print(f"   Capacidad: {habitacion['capacidad']}")
        print(f"   Amenidades: {', '.join(habitacion['amenidades'])}")


# =========================================================
# 2. CREAR RESERVACION
# =========================================================

def crear_reservacion(conn, sede_id):

    mostrar_titulo("CREAR RESERVACION")

    entrada = leer_fecha("Fecha de entrada (YYYY-MM-DD): ")
    salida = leer_fecha("Fecha de salida (YYYY-MM-DD): ")
    numero_huespedes = leer_entero("Numero de huespedes: ")

    if salida <= entrada:
        print("La fecha de salida debe ser posterior a la entrada.")
        return

    # Consultar habitaciones disponibles.
    habitaciones = conn.execute(
        """
        SELECT *
        FROM fn_consultar_disponibilidad(
            %s, %s, %s, %s
        )
        ORDER BY numero
        """,
        (sede_id, entrada, salida, numero_huespedes)
    ).fetchall()

    if not habitaciones:
        print("No hay habitaciones disponibles.")
        return

    print("\nHABITACIONES DISPONIBLES")

    for i, habitacion in enumerate(habitaciones, start=1):
        print(
            f"{i}. {habitacion['numero']} | "
            f"{habitacion['tipo_habitacion']} | "
            f"Capacidad: {habitacion['capacidad']}"
        )

    seleccion = leer_entero(
        "\nSelecciona el numero de habitacion: "
    )

    if seleccion > len(habitaciones):
        print("Seleccion invalida.")
        return

    habitacion = habitaciones[seleccion - 1]

    # Consultar huespedes registrados en la sede.
    huespedes = conn.execute(
        """
        SELECT huesped_id, nombre, apellido, correo
        FROM huespedes
        WHERE sede_id = %s
        ORDER BY nombre, apellido
        """,
        (sede_id,)
    ).fetchall()

    if not huespedes:
        print("No existen huespedes registrados en esta sede.")
        return

    print("\nHUESPEDES REGISTRADOS")

    for i, huesped in enumerate(huespedes, start=1):
        print(
            f"{i}. {huesped['nombre']} {huesped['apellido']} "
            f"| {huesped['correo'] or 'Sin correo'}"
        )

    seleccion = leer_entero("\nSelecciona el huesped: ")

    if seleccion > len(huespedes):
        print("Seleccion invalida.")
        return

    huesped = huespedes[seleccion - 1]

    # Buscar tarifas compatibles.
    tarifas = conn.execute(
        """
        SELECT
            tarifa_id,
            nombre,
            tipo_habitacion,
            precio_noche,
            moneda
        FROM tarifas
        WHERE sede_id = %s
          AND tipo_habitacion = %s
          AND activa = TRUE
          AND fecha_inicio <= %s
          AND fecha_fin >= %s
        ORDER BY precio_noche
        """,
        (
            sede_id,
            habitacion["tipo_habitacion"],
            entrada,
            salida
        )
    ).fetchall()

    if not tarifas:
        print("No existen tarifas compatibles con esas fechas.")
        return

    print("\nTARIFAS DISPONIBLES")

    for i, tarifa in enumerate(tarifas, start=1):
        print(
            f"{i}. {tarifa['nombre']} | "
            f"${tarifa['precio_noche']} {tarifa['moneda']} por noche"
        )

    seleccion = leer_entero("\nSelecciona una tarifa: ")

    if seleccion > len(tarifas):
        print("Seleccion invalida.")
        return

    tarifa = tarifas[seleccion - 1]

    observaciones = input(
        "\nObservaciones (opcional): "
    ).strip()

    # Ejecutar funcion de PostgreSQL.
    resultado = conn.execute(
        """
        SELECT fn_crear_reservacion(
            %s, %s, %s, %s, %s, %s, %s, %s, %s
        ) AS reservacion_id
        """,
        (
            sede_id,
            huesped["huesped_id"],
            habitacion["habitacion_id"],
            tarifa["tarifa_id"],
            entrada,
            salida,
            numero_huespedes,
            "CONFIRMADA",
            observaciones
        )
    ).fetchone()

    conn.commit()

    print("\nRESERVACION CREADA CORRECTAMENTE")
    print("Identificador:", resultado["reservacion_id"])
    print("Habitacion:", habitacion["numero"])
    print("Huesped:", huesped["nombre"], huesped["apellido"])
    print("Tarifa:", tarifa["nombre"])


# =========================================================
# 3. CONSULTAR RESERVACIONES
# =========================================================

def consultar_reservaciones(conn, sede_id):

    mostrar_titulo("RESERVACIONES DE LA SEDE")

    reservaciones = conn.execute(
        """
        SELECT
            r.reservacion_id,
            r.fecha_entrada,
            r.fecha_salida,
            r.estado,
            r.total,
            r.total_pagado,
            r.saldo_pendiente,
            r.moneda,
            h.nombre,
            h.apellido,
            ha.numero
        FROM reservaciones r
        JOIN huespedes h
          ON h.huesped_id = r.huesped_id
         AND h.sede_id = r.sede_id
        JOIN habitaciones ha
          ON ha.habitacion_id = r.habitacion_id
         AND ha.sede_id = r.sede_id
        WHERE r.sede_id = %s
        ORDER BY r.fecha_creacion DESC
        LIMIT 100
        """,
        (sede_id,)
    ).fetchall()

    if not reservaciones:
        print("No hay reservaciones registradas.")
        return

    for r in reservaciones:
        print("\n---------------------------------------")
        print("ID:", r["reservacion_id"])
        print("Huesped:", r["nombre"], r["apellido"])
        print("Habitacion:", r["numero"])
        print("Entrada:", r["fecha_entrada"])
        print("Salida:", r["fecha_salida"])
        print("Estado:", r["estado"])
        print("Total:", r["total"], r["moneda"])
        print("Pagado:", r["total_pagado"])
        print("Saldo:", r["saldo_pendiente"])


# =========================================================
# 4. CHECK-IN
# =========================================================

def realizar_checkin(conn):

    mostrar_titulo("REGISTRAR CHECK-IN")

    reservacion_id = leer_uuid("ID de la reservacion: ")
    fecha = leer_fecha("Fecha de check-in (YYYY-MM-DD): ")

    resultado = conn.execute(
        """
        SELECT fn_realizar_checkin(%s, %s) AS resultado
        """,
        (reservacion_id, fecha)
    ).fetchone()

    conn.commit()

    if resultado["resultado"]:
        print("Check-in realizado correctamente.")
    else:
        print("No fue posible realizar el check-in.")


# =========================================================
# 5. CHECK-OUT
# =========================================================

def realizar_checkout(conn):

    mostrar_titulo("REGISTRAR CHECK-OUT")

    reservacion_id = leer_uuid("ID de la reservacion: ")
    fecha = leer_fecha("Fecha de check-out (YYYY-MM-DD): ")

    resultado = conn.execute(
        """
        SELECT fn_realizar_checkout(%s, %s) AS resultado
        """,
        (reservacion_id, fecha)
    ).fetchone()

    conn.commit()

    if resultado["resultado"]:
        print("Check-out realizado correctamente.")
    else:
        print("No fue posible realizar el check-out.")


# =========================================================
# 6. CANCELAR RESERVACION
# =========================================================

def cancelar_reservacion(conn):

    mostrar_titulo("CANCELAR RESERVACION")

    reservacion_id = leer_uuid("ID de la reservacion: ")

    confirmacion = input(
        "¿Confirmas la cancelacion? (S/N): "
    ).strip().upper()

    if confirmacion != "S":
        print("Operacion cancelada por el usuario.")
        return

    resultado = conn.execute(
        """
        SELECT fn_cancelar_reservacion(%s) AS resultado
        """,
        (reservacion_id,)
    ).fetchone()

    conn.commit()

    if resultado["resultado"]:
        print("Reservacion cancelada correctamente.")
    else:
        print("No fue posible cancelar la reservacion.")


# =========================================================
# 7. CONSULTA CONSOLIDADA CENTRAL
# =========================================================

def consultar_todas_las_sedes():

    mostrar_titulo("REPORTE CONSOLIDADO DE RESERVACIONES")

    with conectar_central() as conn:

        resultados = conn.execute(
            """
            SELECT
                sede,
                reservacion_id,
                fecha_entrada,
                fecha_salida,
                estado,
                total,
                moneda,
                observaciones
            FROM vw_reservaciones_distribuidas
            ORDER BY fecha_entrada DESC
            LIMIT 100
            """
        ).fetchall()

        if not resultados:
            print("No hay reservaciones disponibles.")
            return

        for r in resultados:
            print("\n---------------------------------------")
            print("Sede:", r["sede"])
            print("Reservacion:", r["reservacion_id"])
            print("Entrada:", r["fecha_entrada"])
            print("Salida:", r["fecha_salida"])
            print("Estado:", r["estado"])
            print("Total:", r["total"], r["moneda"])
            print("Observaciones:", r["observaciones"])


# =========================================================
# MENU PRINCIPAL
# =========================================================

def menu_sede(sede):

    while True:

        try:
            with conectar(sede) as conn:

                sede_id = obtener_sede_id(conn, sede)

                mostrar_titulo(
                    f"SISTEMA HOTELERO - {sede['nombre']}"
                )

                print("1. Consultar disponibilidad")
                print("2. Crear reservacion")
                print("3. Consultar reservaciones")
                print("4. Realizar check-in")
                print("5. Realizar check-out")
                print("6. Cancelar reservacion")
                print("0. Regresar al menu principal")

                opcion = input("\nSelecciona una opcion: ").strip()

                if opcion == "1":
                    consultar_disponibilidad(conn, sede_id)

                elif opcion == "2":
                    crear_reservacion(conn, sede_id)

                elif opcion == "3":
                    consultar_reservaciones(conn, sede_id)

                elif opcion == "4":
                    realizar_checkin(conn)

                elif opcion == "5":
                    realizar_checkout(conn)

                elif opcion == "6":
                    cancelar_reservacion(conn)

                elif opcion == "0":
                    return

                else:
                    print("Opcion no valida.")

        except Exception as error:
            print("\nERROR:")
            print(str(error))

        pausa()


def menu_principal():

    while True:

        mostrar_titulo("SISTEMA DISTRIBUIDO DE RESERVACIONES HOTELERAS")

        print("1. Operaciones en Cancun")
        print("2. Operaciones en Tulum")
        print("3. Operaciones en Bacalar")
        print("4. Reporte consolidado de las tres sedes")
        print("0. Salir")

        opcion = input("\nSelecciona una opcion: ").strip()

        if opcion in SEDES:
            menu_sede(SEDES[opcion])

        elif opcion == "4":
            try:
                consultar_todas_las_sedes()
            except Exception as error:
                print("\nERROR:", error)

            pausa()

        elif opcion == "0":
            print("\nCerrando sistema...")
            break

        else:
            print("Opcion no valida.")


# =========================================================
# EJECUCION
# =========================================================

if __name__ == "__main__":

    try:
        menu_principal()

    except KeyboardInterrupt:
        print("\n\nEjecucion interrumpida por el usuario.")
