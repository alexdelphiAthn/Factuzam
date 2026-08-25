"""Configuracion segura del adaptador MCP de Factuzam.

Este modulo no carga archivos ``.env`` ni contiene credenciales por defecto.
La clave puede llegar por entorno o mediante una referencia explícita al
Administrador de credenciales de Windows.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from os import environ
from typing import Mapping
import re

from .windows_credentials import (
    CredentialStoreError,
    read_windows_generic_credential,
)


class ConfigError(ValueError):
    """La configuracion no permite arrancar de forma segura."""


_SCOPE_RE = re.compile(r"^[A-Za-z][A-Za-z0-9_.:-]{0,79}$")
_CODE_RE = re.compile(r"^[^,\x00-\x1f\x7f]{1,100}$")


def _required(env: Mapping[str, str], name: str) -> str:
    value = env.get(name, "").strip()
    if not value:
        raise ConfigError(f"Falta la variable de entorno obligatoria {name}")
    return value


def _required_secret(env: Mapping[str, str], name: str) -> str:
    value = env.get(name, "")
    if not value or not value.strip():
        raise ConfigError(f"Falta la variable de entorno obligatoria {name}")
    # Una clave puede contener espacios significativos: se valida, pero nunca
    # se normaliza ni se incluye en mensajes de error.
    return value


def _database_password(env: Mapping[str, str]) -> str:
    direct = env.get("FACTUZAM_DB_PASSWORD", "")
    target = env.get("FACTUZAM_DB_CREDENTIAL_TARGET", "").strip()
    if direct and direct.strip() and target:
        raise ConfigError(
            "Configure solo FACTUZAM_DB_PASSWORD o "
            "FACTUZAM_DB_CREDENTIAL_TARGET, no ambas"
        )
    if direct and direct.strip():
        return direct
    if target:
        try:
            return read_windows_generic_credential(target)
        except CredentialStoreError as exc:
            raise ConfigError(
                "No se pudo cargar la contraseña MariaDB desde el "
                "Administrador de credenciales de Windows"
            ) from exc
    return _required_secret(env, "FACTUZAM_DB_PASSWORD")


def _integer(
    env: Mapping[str, str],
    name: str,
    default: int,
    *,
    minimum: int,
    maximum: int,
) -> int:
    raw = env.get(name, "").strip()
    if not raw:
        return default
    try:
        value = int(raw, 10)
    except ValueError as exc:
        raise ConfigError(f"{name} debe ser un numero entero") from exc
    if not minimum <= value <= maximum:
        raise ConfigError(
            f"{name} debe estar entre {minimum} y {maximum}"
        )
    return value


def _codes(
    env: Mapping[str, str],
    name: str,
    *,
    required: bool = False,
) -> tuple[str, ...]:
    raw = env.get(name, "")
    values: list[str] = []
    seen: set[str] = set()
    for part in raw.split(","):
        value = part.strip().upper()
        if not value:
            continue
        if not _CODE_RE.fullmatch(value):
            raise ConfigError(f"{name} contiene un codigo no valido")
        if value not in seen:
            seen.add(value)
            values.append(value)
    if required and not values:
        raise ConfigError(
            f"{name} debe contener al menos un codigo; el acceso se deniega "
            "si no existe una lista permitida explicita"
        )
    return tuple(values)


def _scopes(env: Mapping[str, str]) -> frozenset[str]:
    result: set[str] = set()
    for part in env.get("FACTUZAM_MCP_SCOPES", "").split(","):
        scope = part.strip()
        if not scope:
            continue
        if not _SCOPE_RE.fullmatch(scope):
            raise ConfigError("FACTUZAM_MCP_SCOPES contiene un scope no valido")
        result.add(scope)
    # Vacio significa ningun permiso: nunca se conceden permisos por defecto.
    return frozenset(result)


@dataclass(frozen=True, slots=True)
class Settings:
    """Configuracion inmutable y politica estatica de acceso.

    ``db_password`` se excluye deliberadamente de ``repr`` para evitar que un
    volcado de configuracion termine exponiendo el secreto en los logs.
    """

    db_host: str
    db_port: int
    db_name: str
    db_user: str
    db_password: str = field(repr=False)
    allowed_companies: tuple[str, ...] = ()
    allowed_warehouses: tuple[str, ...] = ()
    allowed_cash_registers: tuple[str, ...] = ()
    scopes: frozenset[str] = frozenset()
    connect_timeout_seconds: int = 5
    read_timeout_seconds: int = 30
    write_timeout_seconds: int = 30
    max_report_days: int = 366
    max_stock_page_size: int = 500
    max_stock_offset: int = 50_000
    max_report_rows: int = 5_000
    max_purchase_lookback_days: int = 3_650
    db_ssl_ca: str | None = None

    @classmethod
    def from_env(cls, env: Mapping[str, str] | None = None) -> "Settings":
        source = environ if env is None else env
        db_host = source.get("FACTUZAM_DB_HOST", "127.0.0.1").strip()
        if not db_host:
            raise ConfigError("FACTUZAM_DB_HOST no puede estar vacio")

        db_user = _required(source, "FACTUZAM_DB_USER")
        if db_user.casefold() == "root":
            raise ConfigError(
                "FACTUZAM_DB_USER no puede ser root; use un usuario dedicado "
                "con privilegios minimos"
            )

        password = _database_password(source)
        ssl_ca = source.get("FACTUZAM_DB_SSL_CA", "").strip() or None

        return cls(
            db_host=db_host,
            db_port=_integer(
                source,
                "FACTUZAM_DB_PORT",
                3306,
                minimum=1,
                maximum=65535,
            ),
            db_name=_required(source, "FACTUZAM_DB_NAME"),
            db_user=db_user,
            db_password=password,
            allowed_companies=_codes(
                source, "FACTUZAM_EMPRESAS_PERMITIDAS"
            ),
            allowed_warehouses=_codes(
                source,
                "FACTUZAM_ALMACENES_PERMITIDOS",
                required=True,
            ),
            allowed_cash_registers=_codes(
                source, "FACTUZAM_CAJAS_PERMITIDAS"
            ),
            scopes=_scopes(source),
            connect_timeout_seconds=_integer(
                source,
                "FACTUZAM_DB_CONNECT_TIMEOUT",
                5,
                minimum=1,
                maximum=120,
            ),
            read_timeout_seconds=_integer(
                source,
                "FACTUZAM_DB_READ_TIMEOUT",
                30,
                minimum=1,
                maximum=600,
            ),
            write_timeout_seconds=_integer(
                source,
                "FACTUZAM_DB_WRITE_TIMEOUT",
                30,
                minimum=1,
                maximum=600,
            ),
            max_report_days=_integer(
                source,
                "FACTUZAM_MCP_MAX_REPORT_DAYS",
                366,
                minimum=1,
                maximum=3660,
            ),
            max_stock_page_size=_integer(
                source,
                "FACTUZAM_MCP_MAX_STOCK_PAGE_SIZE",
                500,
                minimum=1,
                maximum=2000,
            ),
            max_stock_offset=_integer(
                source,
                "FACTUZAM_MCP_MAX_STOCK_OFFSET",
                50_000,
                minimum=0,
                maximum=10_000_000,
            ),
            max_report_rows=_integer(
                source,
                "FACTUZAM_MCP_MAX_REPORT_ROWS",
                5_000,
                minimum=1,
                maximum=50_000,
            ),
            max_purchase_lookback_days=_integer(
                source,
                "FACTUZAM_MCP_MAX_PURCHASE_LOOKBACK_DAYS",
                3_650,
                minimum=1,
                maximum=36_500,
            ),
            db_ssl_ca=ssl_ca,
        )

    def has_scope(self, scope: str) -> bool:
        return scope in self.scopes
