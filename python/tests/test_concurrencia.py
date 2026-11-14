"""Prueba de concurrencia: dos solicitudes simultaneas por la misma habitacion.

La prueba busca un periodo libre, elimina unicamente sus propias reservaciones
de ejecuciones anteriores y comprueba que PostgreSQL acepta una solicitud y
rechaza la otra. Devuelve codigo 0 si el resultado es el esperado y 1 si no.
"""

from __future__ import annotations

import sys
import threading
import uuid
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import psycopg


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import hotel_config as config  # noqa: E402


# -----------------------------------------------------
# DATOS DE LA PRUEBA
# -----------------------------------------------------

SEDE_ID = uuid.UUID("11111111-1111-4111-8111-111111111111")
HUESPED_ID = uuid.UUID("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")
HABITACION_ID = uuid.UUID("bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")
TARIFA_ID = uuid.UUID("cccccccc-cccc-4ccc-8ccc-cccccccccccc")

NUMERO_HUESPEDES = 2
ESTADO = "CONFIRMADA"
PREFIJO_MARCADOR = "PRUEBA_CONCURRENCIA_HILO_"

DB_CONFIG = None
FECHA_ENTRADA = None
FECHA_SALIDA = None

# Sincroniza los dos hilos antes de ejecutar la funcion.
barrera = threading.Barrier(2)


def configurar_conexion() -> None:
    global DB_CONFIG

    DB_CONFIG = config.configuracion_nodo("cancun")
    print("Entorno de ejecucion:", config.ENV_NAME)
    print("Destino:", config.descripcion_nodo("cancun"))


def limpiar_reservaciones_previas() -> None:
    """Elimina solo las reservaciones creadas por esta prueba."""

    with psycopg.connect(**DB_CONFIG) as conexion:
        filas = conexion.execute(
            """
            SELECT reservacion_id
            FROM reservaciones
            WHERE sede_id = %s
              AND observaciones LIKE %s
            """,
            (SEDE_ID, f"{PREFIJO_MARCADOR}%"),
        ).fetchall()

        ids = [fila[0] for fila in filas]

        if not ids:
            print("Limpieza: sin reservaciones previas de concurrencia.")
            return

        conexion.execute(
            """
            DELETE FROM reservacion_servicios
            WHERE reservacion_id = ANY(%s::uuid[])
            """,
            (ids,),
        )
        conexion.execute(
            """
            DELETE FROM pagos
            WHERE reservacion_id = ANY(%s::uuid[])
            """,
            (ids,),
        )
        eliminadas = conexion.execute(
            """
            DELETE FROM reservaciones
            WHERE reservacion_id = ANY(%s::uuid[])
            RETURNING reservacion_id
            """,
            (ids,),
        ).fetchall()

    print(
        f"Limpieza: {len(eliminadas)} reservacion(es) previa(s) "
        "de concurrencia eliminada(s)."
    )


# Genera un periodo de prueba nuevo en cada ejecucion.
# Se buscan dos noches libres para la habitacion seleccionada.
def obtener_fechas_disponibles():
    with psycopg.connect(**DB_CONFIG) as conexion:
        with conexion.cursor() as cursor:
            cursor.execute(
                """
                SELECT
                    CURRENT_DATE + desplazamiento AS fecha_entrada,
                    CURRENT_DATE + desplazamiento + 2 AS fecha_salida
                FROM generate_series(1, 365) AS desplazamiento
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM reservaciones r
                    WHERE r.sede_id = %s
                      AND r.habitacion_id = %s
                      AND r.estado IN (
                          'PENDIENTE',
                          'CONFIRMADA',
                          'CHECK_IN'
                      )
                      AND r.periodo && daterange(
                          CURRENT_DATE + desplazamiento,
                          CURRENT_DATE + desplazamiento + 2,
                          '[)'
                      )
                )
                ORDER BY desplazamiento
                LIMIT 1;
                """,
                (SEDE_ID, HABITACION_ID),
            )

            fechas = cursor.fetchone()

            if not fechas:
                raise RuntimeError(
                    "No se encontraron fechas disponibles "
                    "para ejecutar la prueba."
                )

            return fechas[0], fechas[1]


# -----------------------------------------------------
# FUNCION QUE EJECUTA CADA HILO
# -----------------------------------------------------

def intentar_reservacion(numero_hilo):

    identificador = f"{PREFIJO_MARCADOR}{numero_hilo}"

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

def main() -> int:
    global FECHA_ENTRADA, FECHA_SALIDA

    try:
        configurar_conexion()
        limpiar_reservaciones_previas()
        FECHA_ENTRADA, FECHA_SALIDA = obtener_fechas_disponibles()
    except Exception as error:
        print("\nERROR AL PREPARAR LA PRUEBA:")
        print(str(error))
        return 1

    print("=" * 60)
    print("PRUEBA DE CONCURRENCIA - SISTEMA HOTELERO")
    print("=" * 60)

    print("Sede: Cancun")
    print("Habitacion: P-DIST-01")
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
        return 0

    print("\nRESULTADO: REVISAR PRUEBA")
    print("El resultado no coincide con lo esperado.")
    return 1


if __name__ == "__main__":
    sys.exit(main())