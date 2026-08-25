"""Cliente seguro del puente transaccional de ventas de Factuzam.

El MCP nunca escribe tablas de facturación directamente. Este módulo delega la
preparación y confirmación en un servicio local/HTTPS que debe ejecutar la misma
unidad de trabajo que la aplicación de escritorio.
"""

from __future__ import annotations

import ipaddress
import json
import os
import re
from dataclasses import dataclass, field
from datetime import datetime
from decimal import Decimal, InvalidOperation
from http.client import HTTPException
from typing import Any, Mapping
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlsplit
from urllib.request import HTTPRedirectHandler, ProxyHandler, Request, build_opener

from .models import SolicitudVenta


MAX_RESPONSE_BYTES = 1024 * 1024
_IDEMPOTENCY_MAX_LENGTH = 128
_PREPARATION_ID_MAX_LENGTH = 128
_ASCII_HEADER_VALUE = re.compile(r"^[\x20-\x7e]+$")
_DECIMAL_TEXT = re.compile(r"^(?:0|[1-9][0-9]{0,11})(?:\.[0-9]{1,6})?$")
_ESTADOS_VENTA = frozenset({"DESCONOCIDA", "PENDIENTE", "CONFIRMADA", "FALLIDA"})
_HTTP_TEMPORALES = frozenset({408, 425, 429})


class SalesBridgeError(RuntimeError):
    """Error público y saneado del puente de ventas."""


class SalesBridgeConfigurationError(SalesBridgeError):
    """La configuración no permite conectar de forma segura."""


class SalesBridgeConfirmationRequired(SalesBridgeError):
    """La operación destructiva no recibió confirmación explícita."""


class SalesBridgeUnavailableError(SalesBridgeError):
    """No fue posible contactar con el servicio transaccional."""


class SalesBridgeIndeterminateError(SalesBridgeUnavailableError):
    """La confirmación pudo haberse ejecutado aunque no llegó su respuesta."""


class SalesBridgeRejectedError(SalesBridgeError):
    """El servicio rechazó la petición con un estado HTTP conocido."""

    def __init__(self, status_code: int) -> None:
        self.status_code = status_code
        super().__init__(
            f"El puente de ventas rechazó la operación (HTTP {status_code})."
        )


class SalesBridgeProtocolError(SalesBridgeError):
    """La respuesta remota no cumple el contrato JSON esperado."""


class SalesBridgeInputError(SalesBridgeError, ValueError):
    """Un identificador aportado no cumple el contrato del puente."""


class _RechazarRedirecciones(HTTPRedirectHandler):
    """Impide que cuerpo, principal o metadatos salgan del origen fijado."""

    def redirect_request(
        self,
        req: Any,
        fp: Any,
        code: int,
        msg: str,
        headers: Any,
        newurl: str,
    ) -> None:
        raise SalesBridgeProtocolError(
            "El puente no puede responder mediante una redirección."
        )


def _abrir_sin_redireccion(request: Request, *, timeout: float) -> Any:
    # Un proxy heredado podría sacar de loopback el token y el cuerpo de la
    # venta. El destino del puente es explícito y nunca debe usar proxies.
    return build_opener(ProxyHandler({}), _RechazarRedirecciones()).open(
        request, timeout=timeout
    )


def _entorno_requerido(entorno: Mapping[str, str], nombre: str) -> str:
    valor = entorno.get(nombre, "").strip()
    if not valor:
        raise SalesBridgeConfigurationError(
            f"Falta la variable de entorno obligatoria {nombre}."
        )
    return valor


def _es_host_loopback(host: str) -> bool:
    try:
        return ipaddress.ip_address(host).is_loopback
    except ValueError:
        return False


def _normalizar_url_base(url: str) -> str:
    try:
        partes = urlsplit(url)
        # Acceder a port fuerza la validación de puertos no numéricos/fuera de rango.
        _ = partes.port
    except ValueError as exc:
        raise SalesBridgeConfigurationError(
            "FACTUZAM_VENTAS_BRIDGE_URL no es una URL válida."
        ) from exc

    esquema = partes.scheme.lower()
    host = partes.hostname
    if esquema not in {"https", "http"} or not host:
        raise SalesBridgeConfigurationError(
            "El puente de ventas debe usar HTTPS o HTTP sobre loopback."
        )
    if esquema == "http" and not _es_host_loopback(host):
        raise SalesBridgeConfigurationError(
            "HTTP solo está permitido con una dirección IP numérica de loopback."
        )
    if partes.username or partes.password or partes.query or partes.fragment:
        raise SalesBridgeConfigurationError(
            "La URL del puente no puede incluir credenciales, consulta ni fragmento."
        )
    if partes.path not in {"", "/"}:
        raise SalesBridgeConfigurationError(
            "La URL del puente debe ser el origen, sin una ruta adicional."
        )
    if any(ord(caracter) < 33 for caracter in url):
        raise SalesBridgeConfigurationError(
            "La URL del puente contiene caracteres no permitidos."
        )
    return url.rstrip("/")


def _validar_cabecera(valor: str, nombre: str, longitud_maxima: int) -> str:
    valor = valor.strip()
    if (
        not valor
        or len(valor) > longitud_maxima
        or not _ASCII_HEADER_VALUE.fullmatch(valor)
    ):
        raise SalesBridgeConfigurationError(
            f"{nombre} no es un valor de cabecera HTTP válido."
        )
    return valor


@dataclass(frozen=True, slots=True)
class BridgeConfig:
    """Configuración cerrada del servicio de dominio de ventas."""

    base_url: str
    bearer_token: str = field(repr=False)
    principal: str
    timeout_seconds: float = 10.0
    max_response_bytes: int = MAX_RESPONSE_BYTES

    def __post_init__(self) -> None:
        object.__setattr__(
            self, "base_url", _normalizar_url_base(self.base_url.strip())
        )
        object.__setattr__(
            self,
            "bearer_token",
            _validar_cabecera(self.bearer_token, "El token Bearer", 4096),
        )
        object.__setattr__(
            self,
            "principal",
            _validar_cabecera(self.principal, "El principal", 256),
        )
        if not 0.1 <= self.timeout_seconds <= 60.0:
            raise SalesBridgeConfigurationError(
                "El timeout del puente debe estar entre 0,1 y 60 segundos."
            )
        if not 1 <= self.max_response_bytes <= MAX_RESPONSE_BYTES:
            raise SalesBridgeConfigurationError(
                "La respuesta máxima debe estar entre 1 byte y 1 MiB."
            )

    @classmethod
    def from_env(cls, environ: Mapping[str, str] | None = None) -> BridgeConfig:
        entorno = os.environ if environ is None else environ
        url = _entorno_requerido(entorno, "FACTUZAM_VENTAS_BRIDGE_URL")
        token = _entorno_requerido(entorno, "FACTUZAM_VENTAS_BRIDGE_TOKEN")
        principal = _entorno_requerido(entorno, "FACTUZAM_MCP_PRINCIPAL")
        try:
            timeout = float(
                entorno.get("FACTUZAM_VENTAS_BRIDGE_TIMEOUT_SECONDS", "10")
            )
            maximo = int(
                entorno.get(
                    "FACTUZAM_VENTAS_BRIDGE_MAX_RESPONSE_BYTES",
                    str(MAX_RESPONSE_BYTES),
                )
            )
        except ValueError as exc:
            raise SalesBridgeConfigurationError(
                "Timeout o tamaño máximo del puente no es numérico."
            ) from exc
        return cls(
            base_url=url,
            bearer_token=token,
            principal=principal,
            timeout_seconds=timeout,
            max_response_bytes=maximo,
        )


def _valor_operacion(valor: str, nombre: str, longitud_maxima: int) -> str:
    valor = valor.strip()
    if not valor or len(valor) > longitud_maxima:
        raise SalesBridgeInputError(
            f"{nombre} debe tener entre 1 y {longitud_maxima} caracteres."
        )
    if not _ASCII_HEADER_VALUE.fullmatch(valor):
        raise SalesBridgeInputError(f"{nombre} contiene caracteres no permitidos.")
    return valor


def _rechazar_constante_json(_valor: str) -> None:
    raise ValueError("constante JSON no estándar")


def _campo_texto_respuesta(
    resultado: Mapping[str, Any], nombre: str, longitud_maxima: int
) -> str:
    valor = resultado.get(nombre)
    if not isinstance(valor, str):
        raise SalesBridgeProtocolError(
            f"La respuesta del puente no contiene {nombre} válido."
        )
    try:
        return _valor_operacion(valor, nombre, longitud_maxima)
    except ValueError:
        raise SalesBridgeProtocolError(
            f"La respuesta del puente no contiene {nombre} válido."
        ) from None


def _validar_preparacion(resultado: dict[str, Any]) -> None:
    resultado["preparacion_id"] = _campo_texto_respuesta(
        resultado, "preparacion_id", _PREPARATION_ID_MAX_LENGTH
    )
    caduca_en = _campo_texto_respuesta(resultado, "caduca_en", 64)
    try:
        instante = datetime.fromisoformat(caduca_en.replace("Z", "+00:00"))
    except ValueError:
        instante = None
    if instante is None or instante.tzinfo is None:
        raise SalesBridgeProtocolError(
            "La respuesta del puente no contiene caduca_en ISO-8601 con zona horaria."
        )
    if not isinstance(resultado.get("resumen"), dict):
        raise SalesBridgeProtocolError(
            "La respuesta del puente no contiene un resumen válido."
        )


def _texto_resumen(
    objeto: Mapping[str, Any], campo: str, *, maximo: int = 1000
) -> str:
    valor = objeto.get(campo)
    if (
        not isinstance(valor, str)
        or not valor.strip()
        or len(valor) > maximo
        or any(ord(caracter) < 32 or ord(caracter) == 127 for caracter in valor)
    ):
        raise SalesBridgeProtocolError(
            f"El resumen de preparación no contiene {campo} válido."
        )
    return valor


def _decimal_resumen(
    objeto: Mapping[str, Any], campo: str, *, positivo: bool = False
) -> Decimal:
    valor = objeto.get(campo)
    if not isinstance(valor, str) or not _DECIMAL_TEXT.fullmatch(valor):
        raise SalesBridgeProtocolError(
            f"El resumen de preparación no contiene {campo} decimal válido."
        )
    try:
        numero = Decimal(valor)
    except InvalidOperation:
        raise SalesBridgeProtocolError(
            f"El resumen de preparación no contiene {campo} decimal válido."
        ) from None
    if numero < 0 or (positivo and numero == 0):
        raise SalesBridgeProtocolError(
            f"El resumen de preparación no contiene {campo} decimal válido."
        )
    return numero


def _validar_resumen(
    resultado: dict[str, Any], solicitud: SolicitudVenta
) -> None:
    resumen = resultado["resumen"]
    if not isinstance(resumen, dict):
        raise SalesBridgeProtocolError(
            "La respuesta del puente no contiene un resumen válido."
        )
    for campo in (
        "empresa",
        "almacen",
        "caja",
        "tipo_documento",
        "serie",
        "tarifa",
    ):
        valor = _texto_resumen(resumen, campo, maximo=64)
        if valor != getattr(solicitud, campo):
            raise SalesBridgeProtocolError(
                "El contexto del resumen no coincide con la solicitud preparada."
            )
    if "cliente" not in resumen:
        raise SalesBridgeProtocolError(
            "El resumen de preparación no identifica al cliente efectivo."
        )
    cliente = resumen["cliente"]
    if cliente is None:
        if solicitud.cliente is not None:
            raise SalesBridgeProtocolError(
                "El cliente del resumen no coincide con la solicitud preparada."
            )
    elif isinstance(cliente, dict):
        codigo_cliente = _texto_resumen(cliente, "codigo", maximo=64)
        _texto_resumen(cliente, "nombre")
        if solicitud.cliente is not None and codigo_cliente != solicitud.cliente:
            raise SalesBridgeProtocolError(
                "El cliente del resumen no coincide con la solicitud preparada."
            )
    else:
        raise SalesBridgeProtocolError(
            "El resumen de preparación no contiene un cliente efectivo válido."
        )
    _texto_resumen(resumen, "moneda", maximo=8)

    lineas = resumen.get("lineas")
    if not isinstance(lineas, list) or not 1 <= len(lineas) <= 1_000:
        raise SalesBridgeProtocolError(
            "El resumen de preparación no contiene líneas revisables."
        )
    for linea in lineas:
        if not isinstance(linea, dict):
            raise SalesBridgeProtocolError(
                "El resumen de preparación contiene una línea no válida."
            )
        _texto_resumen(linea, "sku", maximo=100)
        _texto_resumen(linea, "descripcion")
        _decimal_resumen(linea, "cantidad", positivo=True)
        _decimal_resumen(linea, "precio_unitario_sin_impuestos")
        _decimal_resumen(linea, "porcentaje_iva")
        _decimal_resumen(linea, "base_imponible")
        _decimal_resumen(linea, "cuota_iva")
        _decimal_resumen(linea, "total_con_impuestos")

    cobros = resumen.get("cobros")
    if not isinstance(cobros, list) or len(cobros) > 100:
        raise SalesBridgeProtocolError(
            "El resumen de preparación no contiene cobros revisables."
        )
    for cobro in cobros:
        if not isinstance(cobro, dict):
            raise SalesBridgeProtocolError(
                "El resumen de preparación contiene un cobro no válido."
            )
        _texto_resumen(cobro, "forma_pago", maximo=64)
        _decimal_resumen(cobro, "importe", positivo=True)

    totales = resumen.get("totales")
    if not isinstance(totales, dict):
        raise SalesBridgeProtocolError(
            "El resumen de preparación no contiene totales revisables."
        )
    _decimal_resumen(totales, "base")
    _decimal_resumen(totales, "impuestos")
    _decimal_resumen(totales, "liquido")


def _validar_estado(resultado: dict[str, Any]) -> None:
    estado = _campo_texto_respuesta(resultado, "estado", 64)
    if estado not in _ESTADOS_VENTA:
        raise SalesBridgeProtocolError(
            "La respuesta del puente contiene un estado de venta desconocido."
        )
    resultado["estado"] = estado
    if estado == "CONFIRMADA":
        documento = resultado.get("documento")
        if not isinstance(documento, dict):
            raise SalesBridgeProtocolError(
                "Una venta confirmada debe identificar el documento creado."
            )
        for campo, maximo in (("empresa", 32), ("serie", 32), ("numero", 64)):
            _campo_texto_respuesta(documento, campo, maximo)


def _error_disponibilidad(
    idempotency_key: str | None,
) -> SalesBridgeUnavailableError:
    if idempotency_key is not None:
        return SalesBridgeIndeterminateError(
            "No se recibió un resultado concluyente al confirmar la venta. "
            "Consulte su estado con la misma idempotency_key antes de reintentar."
        )
    return SalesBridgeUnavailableError(
        "No se pudo contactar con el puente de ventas."
    )


def _error_http(
    status_code: int, idempotency_key: str | None
) -> SalesBridgeError:
    if 300 <= status_code < 400:
        return SalesBridgeProtocolError(
            "El puente no puede responder mediante una redirección."
        )
    if status_code >= 500 or status_code in _HTTP_TEMPORALES:
        return _error_disponibilidad(idempotency_key)
    return SalesBridgeRejectedError(status_code)


class SalesBridge:
    """Puente sin estado hacia la unidad de trabajo de ventas de Factuzam."""

    def __init__(self, config: BridgeConfig) -> None:
        self._config = config

    def preparar(self, venta: SolicitudVenta | Mapping[str, Any]) -> dict[str, Any]:
        solicitud = (
            venta
            if isinstance(venta, SolicitudVenta)
            else SolicitudVenta.model_validate(venta)
        )
        resultado = self._request(
            "POST",
            "/v1/ventas/preparaciones",
            solicitud.model_dump(mode="json", exclude_none=True),
        )
        _validar_preparacion(resultado)
        _validar_resumen(resultado, solicitud)
        return resultado

    def confirmar(
        self,
        preparacion_id: str,
        idempotency_key: str,
        confirmar: bool,
    ) -> dict[str, Any]:
        if confirmar is not True:
            raise SalesBridgeConfirmationRequired(
                "La venta exige confirmar=true de forma explícita."
            )
        preparacion = _valor_operacion(
            preparacion_id, "preparacion_id", _PREPARATION_ID_MAX_LENGTH
        )
        clave = _valor_operacion(
            idempotency_key, "idempotency_key", _IDEMPOTENCY_MAX_LENGTH
        )
        try:
            resultado = self._request(
                "POST",
                "/v1/ventas",
                {
                    "preparacion_id": preparacion,
                    "idempotency_key": clave,
                    "confirmar": True,
                },
                idempotency_key=clave,
            )
            _validar_estado(resultado)
        except (SalesBridgeRejectedError, SalesBridgeIndeterminateError):
            raise
        except (SalesBridgeProtocolError, SalesBridgeUnavailableError):
            # Desde que se envía la confirmación, la ausencia de una respuesta
            # concluyente nunca demuestra que la transacción no se ejecutó.
            raise _error_disponibilidad(clave) from None
        return resultado

    def consultar_estado(self, idempotency_key: str) -> dict[str, Any]:
        clave = _valor_operacion(
            idempotency_key, "idempotency_key", _IDEMPOTENCY_MAX_LENGTH
        )
        clave_url = quote(clave, safe="")
        resultado = self._request("GET", f"/v1/ventas/estado/{clave_url}")
        _validar_estado(resultado)
        return resultado

    def _request(
        self,
        method: str,
        path: str,
        payload: Mapping[str, Any] | None = None,
        *,
        idempotency_key: str | None = None,
    ) -> dict[str, Any]:
        headers = {
            "Accept": "application/json",
        }
        body: bytes | None = None
        if payload is not None:
            body = json.dumps(
                payload,
                ensure_ascii=False,
                allow_nan=False,
                separators=(",", ":"),
            ).encode("utf-8")
            headers["Content-Type"] = "application/json; charset=utf-8"
        request = Request(
            f"{self._config.base_url}{path}",
            data=body,
            headers=headers,
            method=method,
        )
        # Defensa adicional: estas cabeceras tampoco se copiarían si otro
        # transporte introdujera redirecciones en el futuro.
        request.add_unredirected_header(
            "Authorization", f"Bearer {self._config.bearer_token}"
        )
        request.add_unredirected_header(
            "X-Factuzam-Principal", self._config.principal
        )
        if idempotency_key is not None:
            request.add_unredirected_header("Idempotency-Key", idempotency_key)
        response: Any = None
        try:
            response = _abrir_sin_redireccion(
                request, timeout=self._config.timeout_seconds
            )
            obtener_url_final = getattr(response, "geturl", None)
            if (
                callable(obtener_url_final)
                and obtener_url_final() != request.full_url
            ):
                raise SalesBridgeProtocolError(
                    "El puente no puede responder mediante una redirección."
                )
            status = response.getcode()
            if status is not None and not 200 <= status < 300:
                raise _error_http(status, idempotency_key)
            content_length = response.headers.get("Content-Length")
            if content_length is not None:
                try:
                    longitud = int(content_length)
                    if longitud < 0 or longitud > self._config.max_response_bytes:
                        raise SalesBridgeProtocolError(
                            "La respuesta del puente supera el máximo permitido."
                        )
                except ValueError:
                    raise SalesBridgeProtocolError(
                        "El puente devolvió una longitud de respuesta no válida."
                    ) from None
            raw = response.read(self._config.max_response_bytes + 1)
        except SalesBridgeError:
            raise
        except HTTPError as exc:
            try:
                exc.close()
            except Exception:
                pass
            raise _error_http(exc.code, idempotency_key) from None
        except (URLError, TimeoutError, OSError, HTTPException):
            raise _error_disponibilidad(idempotency_key) from None
        except Exception:
            raise SalesBridgeProtocolError(
                "No se pudo interpretar la respuesta del puente de ventas."
            ) from None
        finally:
            if response is not None:
                try:
                    response.close()
                except Exception:
                    raise _error_disponibilidad(idempotency_key) from None

        if not isinstance(raw, (bytes, bytearray)):
            raise SalesBridgeProtocolError(
                "El puente no devolvió una respuesta binaria válida."
            )
        if len(raw) > self._config.max_response_bytes:
            raise SalesBridgeProtocolError(
                "La respuesta del puente supera el máximo permitido."
            )
        try:
            resultado = json.loads(
                raw.decode("utf-8"),
                parse_constant=_rechazar_constante_json,
            )
        except (UnicodeDecodeError, json.JSONDecodeError, ValueError, RecursionError):
            raise SalesBridgeProtocolError(
                "El puente no devolvió un objeto JSON UTF-8 válido."
            ) from None
        if not isinstance(resultado, dict):
            raise SalesBridgeProtocolError(
                "El puente debe devolver un objeto JSON."
            )
        return resultado


__all__ = [
    "BridgeConfig",
    "MAX_RESPONSE_BYTES",
    "SalesBridge",
    "SalesBridgeConfigurationError",
    "SalesBridgeConfirmationRequired",
    "SalesBridgeError",
    "SalesBridgeInputError",
    "SalesBridgeIndeterminateError",
    "SalesBridgeProtocolError",
    "SalesBridgeRejectedError",
    "SalesBridgeUnavailableError",
]
