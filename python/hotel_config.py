"""Configuracion compartida para cliente y pruebas del proyecto hotelero.

La configuracion se toma de variables de entorno y, si no existen, del
archivo .env ubicado en la raiz del proyecto. Esto permite ejecutar los
scripts contra el entorno original (5541-5544) o contra una copia aislada
con puertos distintos sin editar el codigo.
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[1]

_NODE_DEFAULTS = {
    "cancun": ("hotel_cancun", "HOTEL_DB_PORT_CANCUN", 5541),
    "tulum": ("hotel_tulum", "HOTEL_DB_PORT_TULUM", 5542),
    "bacalar": ("hotel_bacalar", "HOTEL_DB_PORT_BACALAR", 5543),
    "central": ("hotel_central", "HOTEL_DB_PORT_CENTRAL", 5544),
}


def _leer_dotenv(ruta: Path) -> dict[str, str]:
    valores: dict[str, str] = {}

    if not ruta.exists():
        return valores

    for linea_original in ruta.read_text(encoding="utf-8").splitlines():
        linea = linea_original.strip()

        if not linea or linea.startswith("#"):
            continue

        if linea.startswith("export "):
            linea = linea[len("export "):].strip()

        if "=" not in linea:
            continue

        clave, valor = linea.split("=", 1)
        clave = clave.strip()
        valor = valor.strip()

        if len(valor) >= 2 and valor[0] == valor[-1] and valor[0] in ("'", '"'):
            valor = valor[1:-1]

        if clave:
            valores[clave] = valor

    return valores


_DOTENV = _leer_dotenv(PROJECT_ROOT / ".env")


def obtener(nombre: str, default: str | None = None) -> str | None:
    """Devuelve una variable de entorno, luego .env y finalmente default."""

    valor_entorno = os.environ.get(nombre)
    if valor_entorno is not None and valor_entorno != "":
        return valor_entorno

    valor_archivo = _DOTENV.get(nombre)
    if valor_archivo is not None and valor_archivo != "":
        return valor_archivo

    return default


def obtener_entero(nombre: str, default: int) -> int:
    valor = obtener(nombre)
    if valor is None:
        return default

    try:
        return int(valor)
    except ValueError as error:
        raise RuntimeError(
            f"El valor de {nombre} debe ser un numero entero: {valor!r}"
        ) from error


ENV_NAME = obtener("HOTEL_ENV_NAME", "original")
EXPECTED_ENV = obtener("HOTEL_EXPECTED_ENV")
HOST = obtener("HOTEL_DB_HOST", "127.0.0.1")
USER = obtener("HOTEL_DB_USER", "hotel_admin")

if EXPECTED_ENV and ENV_NAME != EXPECTED_ENV:
    raise RuntimeError(
        "Entorno incorrecto: "
        f"HOTEL_ENV_NAME={ENV_NAME!r}, se esperaba {EXPECTED_ENV!r}."
    )


def obtener_password() -> str:
    """Obtiene la contrasena sin imprimirla ni incluirla en mensajes."""

    password = obtener("HOTEL_DB_PASSWORD") or obtener("POSTGRES_PASSWORD")

    if not password:
        raise RuntimeError(
            "No se encontro HOTEL_DB_PASSWORD ni POSTGRES_PASSWORD. "
            "Define HOTEL_DB_PASSWORD o revisa el archivo .env."
        )

    return password


def configuracion_nodo(
    nodo: str,
    password: str | None = None,
) -> dict[str, Any]:
    """Construye la configuracion de conexion de un nodo."""

    clave = nodo.lower()
    if clave not in _NODE_DEFAULTS:
        raise ValueError(f"Nodo desconocido: {nodo}")

    dbname, variable_puerto, puerto_default = _NODE_DEFAULTS[clave]

    return {
        "host": HOST,
        "port": obtener_entero(variable_puerto, puerto_default),
        "dbname": dbname,
        "user": USER,
        "password": password or obtener_password(),
        "connect_timeout": 10,
    }


def descripcion_nodo(nodo: str) -> str:
    """Descripcion segura para imprimir antes de conectarse."""

    config = configuracion_nodo(nodo)
    return (
        f"entorno={ENV_NAME} host={config['host']} "
        f"puerto={config['port']} base={config['dbname']}"
    )