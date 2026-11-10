
import os
import uuid
import psycopg
from psycopg.rows import dict_row


# ---------------------------------------------------------
# CONFIGURACION DE CONEXIONES
# ---------------------------------------------------------

PASSWORD = os.getenv("HOTEL_DB_PASSWORD")

if not PASSWORD:
    raise RuntimeError(
        "No se encontro HOTEL_DB_PASSWORD en las variables de entorno."
    )

ORIGEN = {
    "host": "127.0.0.1",
    "port": 5541,
    "dbname": "hotel_cancun",
    "user": "hotel_admin",
    "password": PASSWORD,
}

DESTINO = {
    "host": "127.0.0.1",
    "port": 5542,
    "dbname": "hotel_tulum",
    "user": "hotel_admin",
    "password": PASSWORD,
}


# ---------------------------------------------------------
# IDENTIFICADORES DE LA OPERACION
# ---------------------------------------------------------

RESERVACION_ID = "0bbf5d78-7504-42c6-8ec5-16dcb6f7277b"

SEDE_CANCUN = "11111111-1111-4111-8111-111111111111"
SEDE_TULUM = "22222222-2222-4222-8222-222222222222"

HUESPED_TULUM = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaad"
HABITACION_TULUM = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbe"
TARIFA_TULUM = "cccccccc-cccc-4ccc-8ccc-cccccccccccd"

GID_ORIGEN = f"hotel_2pc_origen_{uuid.uuid4().hex}"
GID_DESTINO = f"hotel_2pc_destino_{uuid.uuid4().hex}"


# ---------------------------------------------------------
# CONEXIONES Y ESTADO DEL COORDINADOR
# ---------------------------------------------------------

conn_origen = None
conn_destino = None

origen_preparado = False
destino_preparado = False

origen_activo = False
destino_activo = False

decision_commit = False


def conectar(configuracion):
    return psycopg.connect(
        **configuracion,
        autocommit=True,
        row_factory=dict_row
    )


def resolver_preparada(configuracion, gid, operacion):
    with conectar(configuracion) as conn:
        conn.execute(f"{operacion} PREPARED '{gid}'")


def revertir_preparada(configuracion, gid):
    resolver_preparada(configuracion, gid, "ROLLBACK")


# ---------------------------------------------------------
# EJECUCION DE LA TRANSACCION DISTRIBUIDA
# ---------------------------------------------------------

try:
    print("\n========================================")
    print("INICIANDO TRANSACCION DISTRIBUIDA 2PC")
    print("========================================")

    conn_origen = conectar(ORIGEN)
    conn_destino = conectar(DESTINO)

    # 1. Leer la reservacion original.
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
        (RESERVACION_ID, SEDE_CANCUN)
    ).fetchone()

    if reservacion is None:
        raise RuntimeError("La reservacion no existe en Cancun.")

    if reservacion["estado"] != "CONFIRMADA":
        raise RuntimeError(
            "Solo se permite trasladar una reservacion CONFIRMADA."
        )

    if reservacion["total_pagado"] != 0:
        raise RuntimeError(
            "La prueba requiere una reservacion sin pagos."
        )

    # 2. Verificar que el destino no tenga la misma reservacion.
    existente = conn_destino.execute(
        """
        SELECT 1
        FROM reservaciones
        WHERE reservacion_id = %s
        """,
        (RESERVACION_ID,)
    ).fetchone()

    if existente:
        raise RuntimeError(
            "La reservacion ya existe en Tulum. No se duplicara."
        )

    # 3. Verificar los recursos de destino.
    habitacion = conn_destino.execute(
        """
        SELECT 1
        FROM habitaciones
        WHERE habitacion_id = %s
          AND sede_id = %s
          AND capacidad >= %s
          AND estado = 'DISPONIBLE'
        """,
        (HABITACION_TULUM, SEDE_TULUM,
         reservacion["numero_huespedes"])
    ).fetchone()

    if not habitacion:
        raise RuntimeError(
            "La habitacion destino no esta disponible."
        )

    huesped = conn_destino.execute(
        """
        SELECT 1
        FROM huespedes
        WHERE huesped_id = %s
          AND sede_id = %s
        """,
        (HUESPED_TULUM, SEDE_TULUM)
    ).fetchone()

    if not huesped:
        raise RuntimeError("El huesped destino no existe.")

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
          AND fecha_fin >= %s
        """,
        (
            TARIFA_TULUM,
            SEDE_TULUM,
            reservacion["moneda"],
            reservacion["fecha_entrada"],
            reservacion["fecha_salida"]
        )
    ).fetchone()

    if not tarifa:
        raise RuntimeError("La tarifa destino no es compatible.")

    print("\nVALIDACIONES PREVIAS CORRECTAS")

    # 4. Iniciar ambas transacciones locales.
    conn_origen.execute("BEGIN")
    origen_activo = True

    conn_destino.execute("BEGIN")
    destino_activo = True

    # 5. Eliminar la reservacion del nodo de origen.
    eliminada = conn_origen.execute(
        """
        DELETE FROM reservaciones
        WHERE reservacion_id = %s
          AND sede_id = %s
        RETURNING reservacion_id
        """,
        (RESERVACION_ID, SEDE_CANCUN)
    ).fetchone()

    if eliminada is None:
        raise RuntimeError(
            "No se pudo retirar la reservacion de Cancun."
        )

    print("ELIMINACION PREPARADA EN CANCUN")

    # 6. Insertar la reservacion en el nodo destino.
    observaciones = (
        "PRUEBA_2PC_TRASLADO_CANCUN_TULUM_20261110"
    )

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
            observaciones
        )
    )

    print("INSERCION PREPARADA EN TULUM")

    # 7. Primera fase: preparar ambas transacciones.
    conn_origen.execute(
        f"PREPARE TRANSACTION '{GID_ORIGEN}'"
    )
    origen_preparado = True
    origen_activo = False

    print("FASE 1: CANCUN PREPARADO")

    conn_destino.execute(
        f"PREPARE TRANSACTION '{GID_DESTINO}'"
    )
    destino_preparado = True
    destino_activo = False

    print("FASE 1: TULUM PREPARADO")

    # 8. Confirmar que las dos transacciones estan preparadas.
    print("\nAMBAS TRANSACCIONES ESTAN PREPARADAS")
    print("GID ORIGEN:", GID_ORIGEN)
    print("GID DESTINO:", GID_DESTINO)

    # A partir de aqui, la decision es confirmar ambas.
    decision_commit = True

    # 9. Segunda fase: confirmar primero el destino.
    resolver_preparada(
        DESTINO, GID_DESTINO, "COMMIT"
    )
    destino_preparado = False

    print("FASE 2: COMMIT CONFIRMADO EN TULUM")

    # 10. Confirmar la eliminacion del origen.
    resolver_preparada(
        ORIGEN, GID_ORIGEN, "COMMIT"
    )
    origen_preparado = False

    print("FASE 2: COMMIT CONFIRMADO EN CANCUN")

    print("\n========================================")
    print("TRANSACCION DISTRIBUIDA COMPLETADA")
    print("========================================")
    print("La reservacion fue trasladada a Tulum.")

except Exception as error:
    print("\nERROR EN LA TRANSACCION 2PC:")
    print(str(error))

    if not decision_commit:
        # Si no se alcanzo la decision de confirmar,
        # se revierten las operaciones preparadas o activas.
        try:
            if destino_activo and conn_destino:
                conn_destino.execute("ROLLBACK")
                destino_activo = False

            if origen_activo and conn_origen:
                conn_origen.execute("ROLLBACK")
                origen_activo = False

            if destino_preparado:
                revertir_preparada(
                    DESTINO, GID_DESTINO
                )
                destino_preparado = False

            if origen_preparado:
                revertir_preparada(
                    ORIGEN, GID_ORIGEN
                )
                origen_preparado = False

            print("TRANSACCIONES REVERTIDAS.")

        except Exception as error_reversion:
            print("ERROR AL REVERTIR:")
            print(str(error_reversion))

    else:
        print(
            "ATENCION: LA DECISION FUE COMMIT. "
            "No revertir manualmente."
        )
        print("Revisar los GID pendientes antes de continuar.")
        print("GID ORIGEN:", GID_ORIGEN)
        print("GID DESTINO:", GID_DESTINO)

finally:
    if conn_origen:
        conn_origen.close()

    if conn_destino:
        conn_destino.close()
