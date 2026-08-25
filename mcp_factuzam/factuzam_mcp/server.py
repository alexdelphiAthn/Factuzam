"""Servidor MCP v2 de Factuzam.

Las dependencias sensibles se construyen de forma perezosa: el servidor puede
publicar su contrato y explicar qué configuración falta sin abrir MariaDB ni
contactar con el puente de ventas durante el arranque.
"""

from __future__ import annotations

import os
from threading import RLock
from typing import Annotated, Any, Callable, Mapping, TypeVar

from mcp.server import MCPServer
from mcp.server.mcpserver.exceptions import ToolError
from mcp.types import ToolAnnotations
from pydantic import Field

from . import __version__
from .config import ConfigError, Settings
from .models import SolicitudVenta
from .repository import RepositoryError
from .sales_bridge import BridgeConfig, SalesBridge, SalesBridgeError
from .service import (
    AccessDeniedError,
    FactuzamService,
    FactuzamServiceError,
    StaticAccessPolicy,
    build_service,
)


INSTRUCCIONES = (
    "Factuzam: usa consultar_stock para existencias e "
    "informe_movimientos_venta para el informe nativo. Para vender, llama "
    "primero a preparar_venta, muestra al usuario el resultado y no llames a "
    "crear_venta sin una confirmación humana explícita. Conserva la misma "
    "idempotency_key en reintentos y consulta su estado si hay timeout o una "
    "respuesta no concluyente. "
    "Nunca inventes precios, impuestos, empresa, almacén, caja ni cobros. "
    "Los costes están ocultos salvo permiso específico."
)

LECTURA = ToolAnnotations(read_only_hint=True, open_world_hint=False)
ESCRITURA_IDEMPOTENTE = ToolAnnotations(
    read_only_hint=False,
    destructive_hint=False,
    idempotent_hint=True,
    open_world_hint=False,
)

_T = TypeVar("_T")
_ERRORES_PREVISTOS = (
    ConfigError,
    FactuzamServiceError,
    RepositoryError,
    SalesBridgeError,
)


def _ejecutar_tool(operacion: Callable[[], _T]) -> _T:
    """Hace visibles solo errores previstos cuyas clases ya los saneaban."""

    try:
        return operacion()
    except _ERRORES_PREVISTOS as exc:
        raise ToolError(str(exc)) from exc


class Runtime:
    """Contenedor perezoso e inyectable para producción y pruebas."""

    def __init__(
        self,
        *,
        environ: Mapping[str, str] | None = None,
        settings: Settings | None = None,
        service: FactuzamService | None = None,
        bridge: SalesBridge | None = None,
    ) -> None:
        self.environ = os.environ if environ is None else environ
        self._settings = settings
        self._service = service
        self._bridge = bridge
        # ``service()`` y ``bridge()`` pueden resolver otras dependencias
        # perezosas mientras mantienen este bloqueo.
        self._lock = RLock()

    def settings(self) -> Settings:
        if self._settings is None:
            with self._lock:
                if self._settings is None:
                    self._settings = Settings.from_env(self.environ)
        return self._settings

    def service(self) -> FactuzamService:
        if self._service is None:
            with self._lock:
                if self._service is None:
                    self._service = build_service(self.settings())
        return self._service

    def bridge(self) -> SalesBridge:
        if self._bridge is None:
            with self._lock:
                if self._bridge is None:
                    self._bridge = SalesBridge(BridgeConfig.from_env(self.environ))
        return self._bridge

    def require_sales_access(self) -> StaticAccessPolicy:
        """Comprueba el permiso y los ámbitos, incluso para recuperación."""

        policy = StaticAccessPolicy(self.settings())
        policy.require_scope("ventas:create")
        settings = self.settings()
        if not (
            settings.allowed_companies
            and settings.allowed_warehouses
            and settings.allowed_cash_registers
        ):
            raise AccessDeniedError(
                "Las ventas exigen allowlists no vacías de empresa, almacén y caja"
            )
        return policy

    def require_sales_enabled(self) -> StaticAccessPolicy:
        value = self.environ.get("FACTUZAM_VENTAS_HABILITADAS", "").strip().upper()
        if value != "SI":
            raise AccessDeniedError(
                "Las ventas MCP están deshabilitadas; "
                "FACTUZAM_VENTAS_HABILITADAS debe ser SI"
            )
        return self.require_sales_access()

    def diagnostic(self) -> dict[str, Any]:
        """Estado seguro: solo presencia y recuentos, nunca valores secretos."""

        env = self.environ

        def values(name: str) -> list[str]:
            return [item.strip() for item in env.get(name, "").split(",") if item.strip()]

        scopes = values("FACTUZAM_MCP_SCOPES")
        return {
            "version": __version__,
            "transporte": "stdio",
            "mariadb": {
                "host_configurado": bool(env.get("FACTUZAM_DB_HOST", "").strip()),
                "base_configurada": bool(env.get("FACTUZAM_DB_NAME", "").strip()),
                "usuario_configurado": bool(env.get("FACTUZAM_DB_USER", "").strip()),
                "clave_configurada": bool(
                    env.get("FACTUZAM_DB_PASSWORD", "")
                    or env.get("FACTUZAM_DB_CREDENTIAL_TARGET", "").strip()
                ),
            },
            "autorizacion": {
                "principal_configurado": bool(
                    env.get("FACTUZAM_MCP_PRINCIPAL", "").strip()
                ),
                "scopes": sorted(scopes),
                "empresas_permitidas": len(values("FACTUZAM_EMPRESAS_PERMITIDAS")),
                "almacenes_permitidos": len(
                    values("FACTUZAM_ALMACENES_PERMITIDOS")
                ),
                "cajas_permitidas": len(values("FACTUZAM_CAJAS_PERMITIDAS")),
            },
            "ventas": {
                "habilitadas": env.get("FACTUZAM_VENTAS_HABILITADAS", "")
                .strip()
                .upper()
                == "SI",
                "url_puente_configurada": bool(
                    env.get("FACTUZAM_VENTAS_BRIDGE_URL", "").strip()
                ),
                "token_puente_configurado": bool(
                    env.get("FACTUZAM_VENTAS_BRIDGE_TOKEN", "")
                ),
                "nota": (
                    "La configuración no demuestra que el puente Delphi exista "
                    "ni que esté operativo."
                ),
            },
        }


def create_server(runtime: Runtime | None = None) -> MCPServer:
    """Construye un servidor aislado; útil también para pruebas en memoria."""

    current = Runtime() if runtime is None else runtime
    server = MCPServer(
        "factuzam",
        title="Factuzam",
        description="Stock, informes de venta y venta segura mediante el dominio Delphi.",
        instructions=INSTRUCCIONES,
        version=__version__,
    )

    @server.tool(title="Estado de la integración Factuzam", annotations=LECTURA)
    def estado_integracion_factuzam() -> dict[str, Any]:
        """Indica qué partes están configuradas sin revelar credenciales."""

        return current.diagnostic()

    @server.tool(title="Consultar stock de Factuzam", annotations=LECTURA)
    def consultar_stock(
        articulo: Annotated[str | None, Field(max_length=20)] = None,
        sku: Annotated[str | None, Field(max_length=50)] = None,
        buscar: Annotated[str | None, Field(max_length=100)] = None,
        almacenes: Annotated[list[str] | None, Field(max_length=100)] = None,
        solo_disponible: bool = False,
        incluir_inactivos: bool = False,
        pagina: Annotated[int, Field(ge=1, le=1_000_000)] = 1,
        tamano_pagina: Annotated[int, Field(ge=1, le=500)] = 100,
    ) -> dict[str, Any]:
        """Consulta existencias, reservas y pendiente de recibir por SKU.

        Sin filtros lista, paginado, el ámbito permitido. ``disponible`` es
        stock físico menos pendiente de servir. Los costes solo aparecen con
        el scope ``caja.verCoste``.
        """

        return _ejecutar_tool(
            lambda: current.service().consultar_stock(
                articulo=articulo,
                sku=sku,
                buscar=buscar,
                almacenes=almacenes,
                solo_disponible=solo_disponible,
                incluir_inactivos=incluir_inactivos,
                pagina=pagina,
                tamano_pagina=tamano_pagina,
            )
        )

    @server.tool(title="Informe de movimientos de venta", annotations=LECTURA)
    def informe_movimientos_venta(
        fecha_desde: Annotated[str, Field(pattern=r"^\d{4}-\d{2}-\d{2}$")],
        fecha_hasta: Annotated[str, Field(pattern=r"^\d{4}-\d{2}-\d{2}$")],
        inicio_compras: Annotated[
            str | None, Field(pattern=r"^\d{4}-\d{2}-\d{2}$")
        ] = None,
        almacenes: Annotated[list[str] | None, Field(max_length=100)] = None,
        familias: Annotated[list[str] | None, Field(max_length=100)] = None,
        proveedores: Annotated[list[str] | None, Field(max_length=100)] = None,
        temporadas: Annotated[list[str] | None, Field(max_length=100)] = None,
        articulos: Annotated[list[str] | None, Field(max_length=200)] = None,
        nivel1: Annotated[str, Field(pattern=r"^(|PRV|FAM|TMP|ALM|COL)$")] = "",
        nivel2: Annotated[str, Field(pattern=r"^(|PRV|FAM|TMP|ALM|COL)$")] = "",
        nivel3: Annotated[str, Field(pattern=r"^(|PRV|FAM|TMP|ALM|COL)$")] = "",
        nivel_familia: Annotated[int, Field(ge=0, le=20)] = 0,
        solo_ventas: bool = True,
        limite: Annotated[int | None, Field(ge=1, le=5_000)] = None,
    ) -> dict[str, Any]:
        """Ejecuta ``PRC_GET_MOV_VENTAS_ART`` con sus reglas fiscales nativas.

        Las fechas son inclusivas. Los niveles válidos son proveedor (PRV),
        familia (FAM), temporada (TMP), almacén (ALM) y color (COL), sin
        repetir. El resultado avisa si fue truncado.
        """

        return _ejecutar_tool(
            lambda: current.service().informe_movimientos_venta(
                fecha_desde=fecha_desde,
                fecha_hasta=fecha_hasta,
                inicio_compras=inicio_compras,
                almacenes=almacenes,
                familias=familias,
                proveedores=proveedores,
                temporadas=temporadas,
                articulos=articulos,
                nivel1=nivel1,
                nivel2=nivel2,
                nivel3=nivel3,
                nivel_familia=nivel_familia,
                solo_ventas=solo_ventas,
                limite=limite,
            )
        )

    @server.tool(title="Preparar una venta de Factuzam", annotations=LECTURA)
    def preparar_venta(solicitud: SolicitudVenta) -> dict[str, Any]:
        """Solicita al dominio Delphi una valoración sin crear la venta.

        El puente debe resolver precios, IVA, tarifa, cliente, política de
        stock y cobros, y devolver un ``preparacion_id`` temporal. Revisar el
        resultado con el usuario antes de invocar ``crear_venta``.
        """

        def preparar() -> dict[str, Any]:
            policy = current.require_sales_enabled()
            empresa, almacen, caja = policy.require_sale_context(
                company=solicitud.empresa,
                warehouse=solicitud.almacen,
                cash_register=solicitud.caja,
            )
            normalizada = solicitud.model_copy(
                update={"empresa": empresa, "almacen": almacen, "caja": caja}
            )
            return current.bridge().preparar(normalizada)

        return _ejecutar_tool(preparar)

    @server.tool(title="Crear una venta de Factuzam", annotations=ESCRITURA_IDEMPOTENTE)
    def crear_venta(
        preparacion_id: Annotated[str, Field(min_length=1, max_length=128)],
        idempotency_key: Annotated[str, Field(min_length=1, max_length=128)],
        confirmar: bool = False,
    ) -> dict[str, Any]:
        """Confirma una preparación mediante la transacción Delphi de Caja.

        Es una escritura fiscal. Requiere ``confirmar=true`` y una clave de
        idempotencia estable. Ante timeout, consultar el estado con esa misma
        clave; nunca reintentar con una nueva.
        """

        def confirmar_venta() -> dict[str, Any]:
            current.require_sales_enabled()
            return current.bridge().confirmar(
                preparacion_id=preparacion_id,
                idempotency_key=idempotency_key,
                confirmar=confirmar,
            )

        return _ejecutar_tool(confirmar_venta)

    @server.tool(title="Consultar estado de una venta", annotations=LECTURA)
    def consultar_estado_venta(
        idempotency_key: Annotated[str, Field(min_length=1, max_length=128)],
    ) -> dict[str, Any]:
        """Consulta el resultado de una confirmación sin repetir la venta."""

        # La recuperación debe seguir disponible aunque se cierre después el
        # interruptor de nuevas ventas (por ejemplo, tras un timeout).
        def consultar_estado() -> dict[str, Any]:
            current.require_sales_access()
            return current.bridge().consultar_estado(idempotency_key)

        return _ejecutar_tool(consultar_estado)

    return server


mcp = create_server()
server = mcp


def main() -> None:
    """Arranca el servidor local por stdio."""

    transport = os.environ.get("FACTUZAM_MCP_TRANSPORTE", "stdio").strip().lower()
    if transport != "stdio":
        raise ConfigError(
            "Esta versión solo habilita transporte stdio. Para acceso remoto, "
            "sitúe un MCP autenticado delante del servicio y revise el modelo de identidad."
        )
    mcp.run(transport="stdio")


__all__ = ["Runtime", "create_server", "main", "mcp", "server"]
