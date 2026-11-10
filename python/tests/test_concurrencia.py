
import os
import threading
import uuid
from concurrent.futures import ThreadPoolExecutor
from datetime import date

import psycopg


# -----------------------------------------------------
# CONFIGURACION DE CONEXION
# -----------------------------------------------------

DB_CONFIG = {
    "host": "127.0.0.1",
    "port": 5541,
    "dbname": "hotel_cancun",
    "user": "hotel_admin",
    "password": os.getenv("HOTEL_DB_PASSWORD"),
    "connect_timeout": 10,
}

if not DB_CONFIG["password"]:
    raise RuntimeError(
        "No se encontro HOTEL_DB_PASSWORD en las variables de entorno."
    )


# -----------------------------------------------------
# DATOS DE LA PRUEBA
# -----------------------------------------------------

SEDE_ID = uuid.UUID(
    "11111111-1111-4111-8111-111111111111"
)

HUESPED_ID = uuid.UUID(
    "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
)

HABITACION_ID = uuid.UUID(
    "cccccccc-cccc-4ccc-8ccc-cccccccccccc"
)

TARIFA_ID = uuid.UUID(
    "dddddddd-dddd-4ddd-8ddd-dddddddddddd"
)

FECHA_ENTRADA = date(2026, 12, 10)
FECHA_SALIDA = date(2026, 12, 12)

NUMERO_HUESPEDES = 2
ESTADO = "CONFIRMADA"

# Sincroniza los dos hilos antes de ejecutar la funcion.
barrera = threading.Barrier(2)


# -----------------------------------------------------
# FUNCION QUE EJECUTA CADA HILO
# -----------------------------------------------------

def intentar_reservacion(numero_hilo):

    identificador = f"PRUEBA_CONCURRENCIA_HILO_{numero_hilo}"

    try:
        with psycopg.connect(**DB_CONFIG) as conexion:

            with conexion.cursor() as cursor:

                print(
                    f"[Hilo {numero_hilo}] Conexion establecida. "
                    "Esperando al otro hilo..."
                )

                barrera.wait(timeout=15)

                print(
                    f"[Hilo {numero_hilo}] Intentando reservar..."
                )

                cursor.execute(
                    """
                    SELECT fn_crear_reservacion(
                        %s::uuid,
                        %s::uuid,
                        %s::uuid,
                        %s::uuid,
                        %s::date,
                        %s::date,
                        %s::smallint,
                        %s::varchar,
                        %s::text
                    );
                    """,
                    (
                        SEDE_ID,
                        HUESPED_ID,
                        HABITACION_ID,
                        TARIFA_ID,
                        FECHA_ENTRADA,
                        FECHA_SALIDA,
                        NUMERO_HUESPEDES,
                        ESTADO,
                        identificador,
                    ),
                )

                resultado = cursor.fetchone()
                reservacion_id = resultado[0]

                # El contexto de conexion confirma la transaccion
                # cuando termina correctamente.
                print(
                    f"[Hilo {numero_hilo}] RESERVACION ACEPTADA: "
                    f"{reservacion_id}"
                )

                return {
                    "hilo": numero_hilo,
                    "resultado": "ACEPTADA",
                    "reservacion_id": str(reservacion_id),
                    "error": None,
                }

    except psycopg.Error as error:

        print(
            f"[Hilo {numero_hilo}] RESERVACION RECHAZADA: "
            f"{error.sqlstate} - {error.diag.message_primary}"
        )

        return {
            "hilo": numero_hilo,
            "resultado": "RECHAZADA",
            "reservacion_id": None,
            "error": error.sqlstate,
        }

    except Exception as error:

        print(
            f"[Hilo {numero_hilo}] ERROR: {error}"
        )

        return {
            "hilo": numero_hilo,
            "resultado": "ERROR",
            "reservacion_id": None,
            "error": str(error),
        }


# -----------------------------------------------------
# EJECUCION DE CONCURRENCIA
# -----------------------------------------------------

def main():

    print("=" * 60)
    print("PRUEBA DE CONCURRENCIA - SISTEMA HOTELERO")
    print("=" * 60)

    print(f"Sede: Cancun")
    print(f"Habitacion: 999-C")
    print(f"Entrada: {FECHA_ENTRADA}")
    print(f"Salida: {FECHA_SALIDA}")
    print("Solicitudes simultaneas: 2")
    print("=" * 60)

    with ThreadPoolExecutor(max_workers=2) as ejecutor:

        futuros = [
            ejecutor.submit(intentar_reservacion, 1),
            ejecutor.submit(intentar_reservacion, 2),
        ]

        resultados = [
            futuro.result()
            for futuro in futuros
        ]

    aceptadas = sum(
        r["resultado"] == "ACEPTADA"
        for r in resultados
    )

    rechazadas = sum(
        r["resultado"] == "RECHAZADA"
        for r in resultados
    )

    errores = sum(
        r["resultado"] == "ERROR"
        for r in resultados
    )

    print("\n" + "=" * 60)
    print("RESUMEN DE CONCURRENCIA")
    print("=" * 60)

    print(f"Solicitudes aceptadas: {aceptadas}")
    print(f"Solicitudes rechazadas: {rechazadas}")
    print(f"Errores inesperados: {errores}")

    for resultado in resultados:
        print(resultado)

    if aceptadas == 1 and rechazadas == 1 and errores == 0:
        print("\nRESULTADO: PRUEBA EXITOSA")
        print("PostgreSQL impidio la doble reservacion.")
    else:
        print("\nRESULTADO: REVISAR PRUEBA")
        print("El resultado no coincide con lo esperado.")


if __name__ == "__main__":
    main()
