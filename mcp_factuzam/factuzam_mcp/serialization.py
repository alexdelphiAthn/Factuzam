"""Conversion conservadora de tipos de base de datos a valores JSON."""

from __future__ import annotations

from datetime import date, datetime, time
from decimal import Decimal, InvalidOperation
from typing import Any, Iterable, Mapping


def decimal_text(value: Decimal) -> str:
    """Devuelve un decimal exacto, sin notacion cientifica ni ``float``."""

    return format(value, "f")


def to_decimal(value: Any) -> Decimal:
    """Convierte un valor numerico de BBDD sin pasar por punto flotante."""

    if value is None or value == "":
        return Decimal(0)
    if isinstance(value, Decimal):
        return value
    if isinstance(value, float):
        # str conserva la representacion decimal que vio el llamador y evita
        # incorporar el artefacto binario completo de Decimal(float).
        value = str(value)
    try:
        return Decimal(value)
    except (InvalidOperation, TypeError, ValueError) as exc:
        raise ValueError(f"Valor no decimal: {value!r}") from exc


def serialize(value: Any) -> Any:
    """Convierte recursivamente tipos habituales de PyMySQL a JSON seguro."""

    if isinstance(value, Decimal):
        return decimal_text(value)
    if isinstance(value, (datetime, date, time)):
        return value.isoformat()
    if isinstance(value, Mapping):
        return {str(key): serialize(item) for key, item in value.items()}
    if isinstance(value, tuple):
        return [serialize(item) for item in value]
    if isinstance(value, list):
        return [serialize(item) for item in value]
    return value


def sum_field(rows: Iterable[Mapping[str, Any]], field: str) -> Decimal:
    total = Decimal(0)
    for row in rows:
        total += to_decimal(row.get(field))
    return total

