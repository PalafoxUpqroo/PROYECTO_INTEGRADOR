"""Prueba automatizada de traslado de una reservacion mediante 2PC.

La prueba crea su propia reservacion en Cancun, la traslada a Tulum usando
PREPARE TRANSACTION / COMMIT PREPARED y verifica el estado final. Se puede
ejecutar repetidamente sin editar identificadores: las reservaciones creadas
por ejecuciones anteriores se identifican por el marcador
PRUEBA_2PC_AUTOMATICA y se eliminan al inicio.

Variables opcionales:
    HOTEL_2PC_RESERVACION_ID  Usa una reservacion existente en Cancun en
                              lugar de crear una nueva (modo manual).
"""

from __future__ import annotations

import sys
import uuid
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

import psycopg
from psycopg.rows import dict_row


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import hotel_config as config  # noqa: E402


# ---------------------------------------------------------
# DATOS SEMILLA
# ---------------------------------------------------------

SEDE_CANCUN = "11111111-1111-4111-8111-111111111111"
SEDE_TULUM = "22222222-2222-4222-8222-222222222222"

HUESPED_CANCUN = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
HABITACION_CANCUN = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb"
TARIFA_CANCUN = "cccccccc-cccc-4ccc-8ccc-cccccccccccc"

HUESPED_TULUM = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaad"
HABITACION_TULUM = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbe"
TARIFA_TULUM = "cccccccc-cccc-4ccc-8ccc-cccccccccccd"

PREFIJO_MARCADOR = "PRUEBA_2PC_AUTOMATICA"
FECHA_PREFERIDA = date(2027, 3, 1)
NOCHES = 2


class ErrorPrueba(RuntimeError):
    """Error controlado de la prueba."""


# ---------------------------------------------------------
# CONEXIONES
# ---------------------------------------------------------

def conectar(nodo: str):
    return psycopg.connect(
        **config.configuracion_nodo(nodo),
        autocommit=True,
        row_factory=dict_row,
    )


def imprimir_destinos() -> None:
    print("Entorno de ejecucion:", config.ENV_NAME)
    for nodo in ("cancun", "tulum"):
        print(f"  {nodo:8s}: {config.descripcion_nodo(nodo)}")


# ---------------------------------------------------------
# VALIDACIONES PREVIAS
# ---------------------------------------------------------

def consultar_transacciones_preparadas() -> dict[str, list[dict]]:
    pendientes: dict[str, list[dict]] = {}

    for nodo in ("cancun", "tulum"):
        with conectar(nodo) as conexion:
            filas = conexion.execute(
                """
                SELECT gid, database, prepared
                FROM pg_prepared_xacts
                ORDER BY prepared
                """
            ).fetchall()

        if filas:
            pendientes[nodo] = filas

    return pendientes


def abortar_si_hay_transacciones_preparadas() -> None:
    pendientes = consultar_transacciones_preparadas()

    if not pendientes:
        return

    lineas = [
        "Existen transacciones preparadas pendientes. "
        "No se ejecutara la prueba para no revertir operaciones ajenas."
    ]

    for nodo, filas in pendientes.items():
        for fila in filas:
            lineas.append(
                f"  {nodo}: gid={fila['gid']} base={fila['database']} "
                f"preparada={fila['prepared']}"
            )

    raise ErrorPrueba("\n".join(lineas))


def limpiar_reservaciones_previas(excluir: str | None = None) -> None:
    """Elimina solo reservaciones creadas por este mismo tipo de prueba."""

    for nodo in ("cancun", "tulum"):
        with conectar(nodo) as conexion:
            filas = conexion.execute(
                """
                SELECT reservacion_id
                FROM reservaciones
                WHERE observaciones LIKE %s
                """,
                (f"{PREFIJO_MARCADOR}%",),
            ).fetchall()

            ids = [
                fila["reservacion_id"]
                for fila in filas
                if excluir is None or str(fila["reservacion_id"]) != excluir
            ]

            if not ids:
                print(f"Limpieza {nodo}: sin reservaciones previas.")
                continue

            # Eliminar primero los detalles que pudieran existir.
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
                f"Limpieza {nodo}: {len(eliminadas)} reservacion(es) "
                f"de pruebas anteriores eliminada(s)."
            )


def obtener_datos_seed() -> dict:
    with conectar("cancun") as cancun:
        huesped_cancun = cancun.execute(
            """
            SELECT huesped_id, sede_id
            FROM huespedes
            WHERE huesped_id = %s
              AND sede_id = %s
            """,
            (HUESPED_CANCUN, SEDE_CANCUN),
        ).fetchone()

        habitacion_cancun = cancun.execute(
            """
            SELECT habitacion_id, sede_id, estado, tipo_habitacion, capacidad
            FROM habitaciones
            WHERE habitacion_id = %s
              AND sede_id = %s
            """,
            (HABITACION_CANCUN, SEDE_CANCUN),
        ).fetchone()

        tarifa_cancun = cancun.execute(
            """
            SELECT tarifa_id, sede_id, tipo_habitacion, moneda, activa,
                   fecha_inicio, fecha_fin
            FROM tarifas
            WHERE tarifa_id = %s
              AND sede_id = %s
            """,
            (TARIFA_CANCUN, SEDE_CANCUN),
        ).fetchone()

    with conectar("tulum") as tulum:
        huesped_tulum = tulum.execute(
            """
            SELECT huesped_id, sede_id
            FROM huespedes
            WHERE huesped_id = %s
              AND sede_id = %s
            """,
            (HUESPED_TULUM, SEDE_TULUM),
        ).fetchone()

        habitacion_tulum = tulum.execute(
            """
            SELECT habitacion_id, sede_id, estado, tipo_habitacion, capacidad
            FROM habitaciones
            WHERE habitacion_id = %s
              AND sede_id = %s
            """,
            (HABITACION_TULUM, SEDE_TULUM),
        ).fetchone()

        tarifa_tulum = tulum.execute(
            """
            SELECT tarifa_id, sede_id, tipo_habitacion, moneda, activa,
                   fecha_inicio, fecha_fin
            FROM tarifas
            WHERE tarifa_id = %s
              AND sede_id = %s
            """,
            (TARIFA_TULUM, SEDE_TULUM),
        ).fetchone()

    if not huesped_cancun:
        raise ErrorPrueba(
            "No existe el huesped semilla de Cancun. "
            "Ejecute scripts/cargar_datos_demo.ps1."
        )
    if not habitacion_cancun:
        raise ErrorPrueba(
            "No existe la habitacion semilla de Cancun. "
            "Ejecute scripts/cargar_datos_demo.ps1."
        )
    if not tarifa_cancun:
        raise ErrorPrueba(
            "No existe la tarifa semilla de Cancun. "
            "Ejecute scripts/cargar_datos_demo.ps1."
        )
    if not huesped_tulum:
        raise ErrorPrueba(
            "No existe el huesped semilla de Tulum. "
            "Ejecute scripts/cargar_datos_demo.ps1."
        )
    if not habitacion_tulum:
        raise ErrorPrueba(
            "No existe la habitacion semilla de Tulum. "
            "Ejecute scripts/cargar_datos_demo.ps1."
        )
    if not tarifa_tulum:
        raise ErrorPrueba(
            "No existe la tarifa semilla de Tulum. "
            "Ejecute scripts/cargar_datos_demo.ps1."
        )

    if habitacion_cancun["estado"] != "DISPONIBLE":
        raise ErrorPrueba("La habitacion de Cancun no esta DISPONIBLE.")
    if habitacion_tulum["estado"] != "DISPONIBLE":
        raise ErrorPrueba("La habitacion de Tulum no esta DISPONIBLE.")

    if tarifa_cancun["tipo_habitacion"] != "ESTANDAR":
        raise ErrorPrueba("La tarifa de Cancun no es ESTANDAR.")
    if tarifa_tulum["tipo_habitacion"] != "ESTANDAR":
        raise ErrorPrueba("La tarifa de Tulum no es ESTANDAR.")
    if not tarifa_cancun["activa"] or not tarifa_tulum["activa"]:
        raise ErrorPrueba("Una de las tarifas semilla no esta activa.")
    if tarifa_cancun["moneda"] != "MXN" or tarifa_tulum["moneda"] != "MXN":
        raise ErrorPrueba("Las tarifas semilla deben estar en MXN.")

    return {
        "huesped_cancun": huesped_cancun,
        "habitacion_cancun": habitacion_cancun,
        "tarifa_cancun": tarifa_cancun,
        "huesped_tulum": huesped_tulum,
        "habitacion_tulum": habitacion_tulum,
        "tarifa_tulum": tarifa_tulum,
    }


def buscar_periodo_disponible(datos: dict) -> tuple[date, date]:
    inicio = max(
        FECHA_PREFERIDA,
        date.today() + timedelta(days=1),
        datos["tarifa_cancun"]["fecha_inicio"],
        datos["tarifa_tulum"]["fecha_inicio"],
    )
    limite = min(
        datos["tarifa_cancun"]["fecha_fin"],
        datos["tarifa_tulum"]["fecha_fin"],
    ) - timedelta(days=1)

    if inicio > limite:
        raise ErrorPrueba(
            "Las tarifas semilla no cubren un periodo futuro disponible."
        )

    with conectar("cancun") as conexion:
        fila = conexion.execute(
            """
            WITH candidatos AS (
                SELECT
                    (%s::date + desplazamiento)::date AS fecha_entrada,
                    (
                        %s::date + desplazamiento + %s::int
                    )::date AS fecha_salida
                FROM generate_series(0, 365) AS desplazamiento
                WHERE (%s::date + desplazamiento) <= %s::date
            )
            SELECT c.fecha_entrada, c.fecha_salida
            FROM candidatos c
            WHERE NOT EXISTS (
                SELECT 1
                FROM reservaciones r
                WHERE r.sede_id = %s
                  AND r.habitacion_id = %s
                  AND r.estado IN ('PENDIENTE', 'CONFIRMADA', 'CHECK_IN')
                  AND r.periodo && daterange(
                      c.fecha_entrada,
                      c.fecha_salida,
                      '[)'
                  )
            )
            ORDER BY c.fecha_entrada
            LIMIT 1
            """,
            (
                inicio,
                inicio,
                NOCHES,
                inicio,
                limite,
                SEDE_CANCUN,
                HABITACION_CANCUN,
            ),
        ).fetchone()

    if not fila:
        raise ErrorPrueba(
            "No se encontro un periodo de dos noches disponible "
            "para la habitacion semilla de Cancun."
        )

    return fila["fecha_entrada"], fila["fecha_salida"]


def validar_disponibilidad(entrada: date, salida: date) -> None:
    with conectar("cancun") as cancun:
        disponibles = cancun.execute(
            """
            SELECT habitacion_id
            FROM fn_consultar_disponibilidad(%s::uuid, %s, %s, 2::smallint)
            """,
            (SEDE_CANCUN, entrada, salida),
        ).fetchall()

    if HABITACION_CANCUN not in {str(f["habitacion_id"]) for f in disponibles}:
        raise ErrorPrueba(
            "La habitacion de Cancun no aparece disponible para el periodo."
        )

    with conectar("tulum") as tulum:
        disponibles = tulum.execute(
            """
            SELECT habitacion_id
            FROM fn_consultar_disponibilidad(%s::uuid, %s, %s, 2::smallint)
            """,
            (SEDE_TULUM, entrada, salida),
        ).fetchall()

    if HABITACION_TULUM not in {str(f["habitacion_id"]) for f in disponibles}:
        raise ErrorPrueba(
            "La habitacion de Tulum no aparece disponible para el periodo."
        )


# ---------------------------------------------------------
# 2PC
# ---------------------------------------------------------

def esta_preparada(nodo: str, gid: str) -> bool:
    with conectar(nodo) as conexion:
        fila = conexion.execute(
            "SELECT 1 FROM pg_prepared_xacts WHERE gid = %s",
            (gid,),
        ).fetchone()
    return fila is not None


def ejecutar_2pc() -> bool:
    inicio_ejecucion = datetime.now(timezone.utc)
    id_externo = config.obtener("HOTEL_2PC_RESERVACION_ID")
    reservacion_id = str(id_externo).strip() if id_externo else None
    marcador_id = uuid.uuid4().hex[:12]
    marcador = f"{PREFIJO_MARCADOR}_{marcador_id}"

    gid_origen = f"hotel_2pc_origen_{uuid.uuid4().hex}"
    gid_destino = f"hotel_2pc_destino_{uuid.uuid4().hex}"

    conn_origen = None
    conn_destino = None

    origen_activo = False
    destino_activo = False
    origen_preparado = False
    destino_preparado = False
    decision_commit = False

    try:
        imprimir_destinos()

        print("\n========================================")
        print("INICIANDO TRANSACCION DISTRIBUIDA 2PC")
        print("========================================")

        abortar_si_hay_transacciones_preparadas()
        limpiar_reservaciones_previas(excluir=reservacion_id)

        datos = obtener_datos_seed()
        entrada, salida = buscar_periodo_disponible(datos)
        validar_disponibilidad(entrada, salida)

        # Validar la tarifa de destino con la misma regla que usa la base:
        # fecha_fin >= fecha_salida - 1.
        if datos["tarifa_tulum"]["fecha_fin"] < salida - timedelta(days=1):
            raise ErrorPrueba(
                "La tarifa de Tulum no cubre la ultima noche de la estancia."
            )

        print(f"\nPeriodo seleccionado: {entrada} a {salida}")
        print(f"Marcador de prueba: {marcador}")

        if reservacion_id:
            print(f"Modo manual: se usara la reservacion {reservacion_id}")
        else:
            with conectar("cancun") as conexion:
                creada = conexion.execute(
                    """
                    SELECT fn_crear_reservacion(
                        %s::uuid, %s::uuid, %s::uuid, %s::uuid,
                        %s::date, %s::date, %s::smallint,
                        %s::varchar, %s::text
                    ) AS reservacion_id
                    """,
                    (
                        SEDE_CANCUN,
                        HUESPED_CANCUN,
                        HABITACION_CANCUN,
                        TARIFA_CANCUN,
                        entrada,
                        salida,
                        2,
                        "CONFIRMADA",
                        marcador,
                    ),
                ).fetchone()

            reservacion_id = str(creada["reservacion_id"])
            print(f"Reservacion creada en Cancun: {reservacion_id}")

        conn_origen = conectar("cancun")
        conn_destino = conectar("tulum")

        reservacion = conn_origen.execute(
            """
            SELECT
                reservacion_id,
                sede_id,
                huesped_id,
                habitacion_id,
                tarifa_id,
                fecha_entrada,
                fecha_salida,
                numero_huespedes,
                estado,
                total,
                total_alojamiento,
                total_pagado,
                moneda,
                fecha_creacion,
                observaciones
            FROM reservaciones
            WHERE reservacion_id = %s
              AND sede_id = %s
            """,
            (reservacion_id, SEDE_CANCUN),
        ).fetchone()

        if reservacion is None:
            raise ErrorPrueba(
                f"La reservacion {reservacion_id} no existe en Cancun."
            )

        if reservacion["estado"] != "CONFIRMADA":
            raise ErrorPrueba(
                "Solo se permite trasladar una reservacion CONFIRMADA."
            )

        if reservacion["total_pagado"] != 0:
            raise ErrorPrueba(
                "La prueba requiere una reservacion sin pagos."
            )

        existente = conn_destino.execute(
            """
            SELECT 1
            FROM reservaciones
            WHERE reservacion_id = %s
            """,
            (reservacion_id,),
        ).fetchone()

        if existente:
            raise ErrorPrueba(
                "La reservacion ya existe en Tulum. No se duplicara."
            )

        habitacion = conn_destino.execute(
            """
            SELECT 1
            FROM habitaciones
            WHERE habitacion_id = %s
              AND sede_id = %s
              AND capacidad >= %s
              AND estado = 'DISPONIBLE'
            """,
            (
                HABITACION_TULUM,
                SEDE_TULUM,
                reservacion["numero_huespedes"],
            ),
        ).fetchone()

        if not habitacion:
            raise ErrorPrueba("La habitacion destino no esta disponible.")

        huesped = conn_destino.execute(
            """
            SELECT 1
            FROM huespedes
            WHERE huesped_id = %s
              AND sede_id = %s
            """,
            (HUESPED_TULUM, SEDE_TULUM),
        ).fetchone()

        if not huesped:
            raise ErrorPrueba("El huesped destino no existe.")

        tarifa = conn_destino.execute(
            """
            SELECT 1
            FROM tarifas
            WHERE tarifa_id = %s
              AND sede_id = %s
              AND tipo_habitacion = 'ESTANDAR'
              AND moneda = %s
              AND activa = TRUE
              AND fecha_inicio <= %s
              AND fecha_fin >= %s - 1
            """,
            (
                TARIFA_TULUM,
                SEDE_TULUM,
                reservacion["moneda"],
                reservacion["fecha_entrada"],
                reservacion["fecha_salida"],
            ),
        ).fetchone()

        if not tarifa:
            raise ErrorPrueba("La tarifa destino no es compatible.")

        print("\nVALIDACIONES PREVIAS CORRECTAS")

        # Fase 1: eliminar en origen e insertar en destino.
        conn_origen.execute("BEGIN")
        origen_activo = True

        conn_destino.execute("BEGIN")
        destino_activo = True

        eliminada = conn_origen.execute(
            """
            DELETE FROM reservaciones
            WHERE reservacion_id = %s
              AND sede_id = %s
            RETURNING reservacion_id
            """,
            (reservacion_id, SEDE_CANCUN),
        ).fetchone()

        if eliminada is None:
            raise ErrorPrueba(
                "No se pudo retirar la reservacion de Cancun."
            )

        print("ELIMINACION PREPARADA EN CANCUN")

        conn_destino.execute(
            """
            INSERT INTO reservaciones (
                reservacion_id,
                sede_id,
                huesped_id,
                habitacion_id,
                tarifa_id,
                fecha_entrada,
                fecha_salida,
                numero_huespedes,
                estado,
                total,
                total_alojamiento,
                total_pagado,
                moneda,
                fecha_creacion,
                observaciones
            )
            VALUES (
                %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s
            )
            """,
            (
                reservacion["reservacion_id"],
                SEDE_TULUM,
                HUESPED_TULUM,
                HABITACION_TULUM,
                TARIFA_TULUM,
                reservacion["fecha_entrada"],
                reservacion["fecha_salida"],
                reservacion["numero_huespedes"],
                reservacion["estado"],
                reservacion["total"],
                reservacion["total_alojamiento"],
                reservacion["total_pagado"],
                reservacion["moneda"],
                reservacion["fecha_creacion"],
                reservacion["observaciones"],
            ),
        )

        print("INSERCION PREPARADA EN TULUM")

        conn_origen.execute(f"PREPARE TRANSACTION '{gid_origen}'")
        origen_preparado = True
        origen_activo = False

        print("FASE 1: CANCUN PREPARADO")

        conn_destino.execute(f"PREPARE TRANSACTION '{gid_destino}'")
        destino_preparado = True
        destino_activo = False

        print("FASE 1: TULUM PREPARADO")
        print("\nAMBAS TRANSACCIONES ESTAN PREPARADAS")
        print("GID ORIGEN:", gid_origen)
        print("GID DESTINO:", gid_destino)

        # A partir de este punto la decision es COMMIT y no se revierte.
        decision_commit = True

        conn_destino.execute(f"COMMIT PREPARED '{gid_destino}'")
        destino_preparado = False
        print("FASE 2: COMMIT CONFIRMADO EN TULUM")

        conn_origen.execute(f"COMMIT PREPARED '{gid_origen}'")
        origen_preparado = False
        print("FASE 2: COMMIT CONFIRMADO EN CANCUN")

        print("\n========================================")
        print("TRANSACCION DISTRIBUIDA COMPLETADA")
        print("========================================")

    except Exception as error:
        print("\nERROR EN LA TRANSACCION 2PC:")
        print(str(error))

        if decision_commit:
            print(
                "ATENCION: LA DECISION FUE COMMIT. "
                "No se revierte ninguna transaccion."
            )

            # Reintentar unicamente los COMMIT que sigan preparados.
            for nodo, gid, preparado in (
                ("tulum", gid_destino, destino_preparado),
                ("cancun", gid_origen, origen_preparado),
            ):
                if not preparado:
                    continue

                try:
                    if esta_preparada(nodo, gid):
                        with conectar(nodo) as conexion:
                            conexion.execute(f"COMMIT PREPARED '{gid}'")
                        print(f"COMMIT reintentado correctamente en {nodo}.")
                    else:
                        print(
                            f"La transaccion {gid} ya no esta preparada "
                            f"en {nodo}; se considera confirmada."
                        )
                except Exception as error_commit:
                    print(
                        f"No se pudo confirmar {gid} en {nodo}: "
                        f"{error_commit}"
                    )

            pendientes = consultar_transacciones_preparadas()
            if pendientes:
                print("QUEDAN TRANSACCIONES PREPARADAS:")
                for nodo, filas in pendientes.items():
                    for fila in filas:
                        print(f"  {nodo}: {fila['gid']}")
                print(
                    "No ejecute ROLLBACK PREPARED. "
                    "La decision ya fue COMMIT."
                )
                return False

            print("No quedan transacciones preparadas.")
            return False

        # Sin decision de COMMIT: revertir lo activo y lo preparado.
        try:
            if destino_activo and conn_destino:
                conn_destino.execute("ROLLBACK")
                destino_activo = False

            if origen_activo and conn_origen:
                conn_origen.execute("ROLLBACK")
                origen_activo = False

            if destino_preparado:
                if esta_preparada("tulum", gid_destino):
                    with conectar("tulum") as conexion:
                        conexion.execute(
                            f"ROLLBACK PREPARED '{gid_destino}'"
                        )
                destino_preparado = False

            if origen_preparado:
                if esta_preparada("cancun", gid_origen):
                    with conectar("cancun") as conexion:
                        conexion.execute(
                            f"ROLLBACK PREPARED '{gid_origen}'"
                        )
                origen_preparado = False

            print("TRANSACCIONES REVERTIDAS.")

        except Exception as error_reversion:
            print("ERROR AL REVERTIR:")
            print(str(error_reversion))
            print("GID ORIGEN:", gid_origen)
            print("GID DESTINO:", gid_destino)

        return False

    finally:
        if conn_origen:
            conn_origen.close()
        if conn_destino:
            conn_destino.close()

    # -----------------------------------------------------
    # VERIFICACION FINAL
    # -----------------------------------------------------

    try:
        with conectar("cancun") as origen:
            en_origen = origen.execute(
                """
                SELECT 1
                FROM reservaciones
                WHERE reservacion_id = %s
                  AND sede_id = %s
                """,
                (reservacion_id, SEDE_CANCUN),
            ).fetchone()

        with conectar("tulum") as destino:
            en_destino = destino.execute(
                """
                SELECT reservacion_id, sede_id, observaciones
                FROM reservaciones
                WHERE reservacion_id = %s
                  AND sede_id = %s
                """,
                (reservacion_id, SEDE_TULUM),
            ).fetchone()

        if en_origen is not None:
            raise ErrorPrueba(
                "La reservacion sigue existiendo en Cancun."
            )
        if en_destino is None:
            raise ErrorPrueba(
                "La reservacion no existe en Tulum despues del traslado."
            )
        if str(en_destino["reservacion_id"]) != reservacion_id:
            raise ErrorPrueba(
                "El UUID de la reservacion no coincide en Tulum."
            )

        with conectar("cancun") as origen:
            bitacora_origen = origen.execute(
                """
                SELECT operacion, datos_anteriores
                FROM bitacora
                WHERE tabla_afectada = 'reservaciones'
                  AND registro_id = %s
                  AND fecha_operacion >= %s
                  AND operacion = 'DELETE'
                ORDER BY bitacora_id DESC
                LIMIT 1
                """,
                (reservacion_id, inicio_ejecucion),
            ).fetchone()

        with conectar("tulum") as destino:
            bitacora_destino = destino.execute(
                """
                SELECT operacion, datos_nuevos
                FROM bitacora
                WHERE tabla_afectada = 'reservaciones'
                  AND registro_id = %s
                  AND fecha_operacion >= %s
                  AND operacion = 'INSERT'
                ORDER BY bitacora_id DESC
                LIMIT 1
                """,
                (reservacion_id, inicio_ejecucion),
            ).fetchone()

        if bitacora_origen is None:
            raise ErrorPrueba(
                "No se encontro el evento DELETE en la bitacora de Cancun."
            )
        if bitacora_destino is None:
            raise ErrorPrueba(
                "No se encontro el evento INSERT en la bitacora de Tulum."
            )

        pendientes = consultar_transacciones_preparadas()
        if pendientes:
            raise ErrorPrueba(
                "Quedaron transacciones preparadas despues de la prueba: "
                f"{pendientes}"
            )

        print("\n========================================")
        print("VERIFICACION FINAL CORRECTA")
        print("========================================")
        print(f"Reservacion: {reservacion_id}")
        print("Origen: Cancun (sin registro)")
        print("Destino: Tulum (registro presente)")
        print("Bitacora: DELETE en Cancun, INSERT en Tulum")
        print("Transacciones preparadas: 0")
        return True

    except Exception as error:
        print("\nERROR EN LA VERIFICACION FINAL:")
        print(str(error))
        return False


def main() -> int:
    try:
        return 0 if ejecutar_2pc() else 1
    except Exception as error:
        print("\nERROR NO CONTROLADO:")
        print(str(error))
        return 1


if __name__ == "__main__":
    sys.exit(main())