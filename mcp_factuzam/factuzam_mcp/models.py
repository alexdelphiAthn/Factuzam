"""Modelos validados del contrato MCP de ventas de Factuzam.

Estos DTO describen una intención de venta. No contienen campos de precio,
impuestos ni numeración fiscal: esos datos los calcula y valida el dominio
transaccional de Factuzam durante la preparación.
"""

from __future__ import annotations

from decimal import Decimal
from typing import Annotated

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    StringConstraints,
    field_validator,
)


CodigoCorto = Annotated[
    str,
    StringConstraints(
        strip_whitespace=True, to_upper=True, min_length=1, max_length=32
    ),
]
CodigoCliente = Annotated[
    str,
    StringConstraints(strip_whitespace=True, min_length=1, max_length=64),
]
CodigoSku = Annotated[
    str,
    StringConstraints(strip_whitespace=True, min_length=1, max_length=100),
]
ReferenciaCobro = Annotated[
    str,
    StringConstraints(strip_whitespace=True, min_length=1, max_length=120),
]
Cantidad = Annotated[
    Decimal,
    Field(gt=Decimal("0"), max_digits=18, decimal_places=6),
]
Importe = Annotated[
    Decimal,
    Field(gt=Decimal("0"), max_digits=18, decimal_places=6),
]


class _ModeloContrato(BaseModel):
    """Base estricta compartida por los DTO expuestos al modelo."""

    model_config = ConfigDict(
        extra="forbid",
        frozen=True,
        str_strip_whitespace=True,
        allow_inf_nan=False,
    )

    @field_validator("*", mode="after")
    @classmethod
    def _sin_caracteres_de_control(cls, valor: object) -> object:
        if isinstance(valor, str) and any(ord(caracter) < 32 for caracter in valor):
            raise ValueError("no se permiten caracteres de control")
        return valor


class LineaVenta(_ModeloContrato):
    """Artículo y cantidad solicitada; el dominio resuelve precio e impuestos."""

    sku: CodigoSku
    cantidad: Cantidad


class CobroVenta(_ModeloContrato):
    """Importe a cobrar mediante una forma de pago reconocida por Factuzam."""

    forma_pago: CodigoCorto
    importe: Importe
    referencia: ReferenciaCobro | None = None


class SolicitudVenta(_ModeloContrato):
    """Solicitud limitada que primero debe pasar por ``preparar_venta``."""

    empresa: CodigoCorto
    almacen: CodigoCorto
    caja: CodigoCorto
    cliente: CodigoCliente | None = None
    tipo_documento: CodigoCorto
    serie: CodigoCorto
    tarifa: CodigoCorto
    lineas: Annotated[list[LineaVenta], Field(min_length=1, max_length=200)]
    cobros: Annotated[list[CobroVenta], Field(max_length=20)] = Field(
        default_factory=list
    )


__all__ = ["CobroVenta", "LineaVenta", "SolicitudVenta"]
