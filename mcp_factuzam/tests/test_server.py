from __future__ import annotations

import json
import logging
import unittest
from typing import Any

from mcp import Client

from factuzam_mcp.config import Settings
from factuzam_mcp.models import SolicitudVenta
from factuzam_mcp.sales_bridge import SalesBridgeConfirmationRequired
from factuzam_mcp.server import Runtime, create_server


class FakeService:
    def __init__(self) -> None:
        self.stock_calls: list[dict[str, Any]] = []
        self.report_calls: list[dict[str, Any]] = []

    def consultar_stock(self, **arguments: Any) -> dict[str, Any]:
        self.stock_calls.append(arguments)
        return {"origen": "stock", "articulos": [{"sku": "SKU-001"}]}

    def informe_movimientos_venta(self, **arguments: Any) -> dict[str, Any]:
        self.report_calls.append(arguments)
        return {"origen": "informe", "filas": [{"unidades": "2"}]}


class FakeBridge:
    def __init__(self) -> None:
        self.preparar_calls: list[SolicitudVenta] = []
        self.confirmar_calls: list[dict[str, Any]] = []
        self.estado_calls: list[str] = []

    def preparar(self, solicitud: SolicitudVenta) -> dict[str, Any]:
        self.preparar_calls.append(solicitud)
        return {
            "preparacion_id": "prep-1",
            "caduca_en": "2026-08-25T12:15:00+02:00",
            "resumen": {
                "empresa": solicitud.empresa,
                "almacen": solicitud.almacen,
                "caja": solicitud.caja,
                "tipo_documento": solicitud.tipo_documento,
                "serie": solicitud.serie,
                "tarifa": solicitud.tarifa,
                "cliente": {"codigo": "CLI01", "nombre": "Cliente de prueba"},
                "moneda": "EUR",
                "lineas": [
                    {
                        "sku": "SKU-001",
                        "descripcion": "Artículo de prueba",
                        "cantidad": "2",
                        "precio_unitario_sin_impuestos": "10.00",
                        "porcentaje_iva": "21",
                        "base_imponible": "20.00",
                        "cuota_iva": "4.20",
                        "total_con_impuestos": "24.20",
                    }
                ],
                "cobros": [{"forma_pago": "EFECTIVO", "importe": "24.20"}],
                "totales": {
                    "base": "20.00",
                    "impuestos": "4.20",
                    "liquido": "24.20",
                },
            },
        }

    def confirmar(
        self,
        preparacion_id: str,
        idempotency_key: str,
        confirmar: bool,
    ) -> dict[str, Any]:
        if confirmar is not True:
            raise SalesBridgeConfirmationRequired(
                "La venta exige confirmar=true de forma explicita."
            )
        self.confirmar_calls.append(
            {
                "preparacion_id": preparacion_id,
                "idempotency_key": idempotency_key,
                "confirmar": confirmar,
            }
        )
        return {
            "estado": "CONFIRMADA",
            "documento": {"empresa": "EMP01", "serie": "A", "numero": "42"},
        }

    def consultar_estado(self, idempotency_key: str) -> dict[str, Any]:
        self.estado_calls.append(idempotency_key)
        return {
            "estado": "CONFIRMADA",
            "documento": {"empresa": "EMP01", "serie": "A", "numero": "42"},
            "idempotency_key": idempotency_key,
        }


def settings_permitidos() -> Settings:
    return Settings(
        db_host="db.example.test",
        db_port=3306,
        db_name="factuzam",
        db_user="factuzam_mcp",
        db_password="clave-no-utilizada",
        allowed_companies=("EMP01",),
        allowed_warehouses=("ALM01",),
        allowed_cash_registers=("CAJA01",),
        scopes=frozenset({"stock:read", "ventas:read", "ventas:create"}),
    )


def solicitud_valida() -> dict[str, Any]:
    return {
        "empresa": "EMP01",
        "almacen": "ALM01",
        "caja": "CAJA01",
        "cliente": "CLI01",
        "tipo_documento": "SIMPLIFICADA",
        "serie": "A",
        "tarifa": "GENERAL",
        "lineas": [{"sku": "SKU-001", "cantidad": "2"}],
        "cobros": [{"forma_pago": "EFECTIVO", "importe": "24.20"}],
    }


class ServerMcpTests(unittest.IsolatedAsyncioTestCase):
    def setUp(self) -> None:
        previous_disable_level = logging.root.manager.disable
        logging.disable(logging.CRITICAL)
        self.addCleanup(logging.disable, previous_disable_level)
        self.environ = {
            "FACTUZAM_DB_HOST": "host-db-secreto.example.test",
            "FACTUZAM_DB_NAME": "base-secreta",
            "FACTUZAM_DB_USER": "usuario-secreto",
            "FACTUZAM_DB_PASSWORD": "clave-db-supersecreta",
            "FACTUZAM_MCP_PRINCIPAL": "principal-supersecreto",
            "FACTUZAM_MCP_SCOPES": "stock:read,ventas:read,ventas:create",
            "FACTUZAM_EMPRESAS_PERMITIDAS": "EMP01",
            "FACTUZAM_ALMACENES_PERMITIDOS": "ALM01",
            "FACTUZAM_CAJAS_PERMITIDAS": "CAJA01",
            "FACTUZAM_VENTAS_HABILITADAS": "SI",
            "FACTUZAM_VENTAS_BRIDGE_URL": "https://puente-secreto.example.test",
            "FACTUZAM_VENTAS_BRIDGE_TOKEN": "token-puente-supersecreto",
        }
        self.service = FakeService()
        self.bridge = FakeBridge()
        self.runtime = Runtime(
            environ=self.environ,
            settings=settings_permitidos(),
            service=self.service,  # type: ignore[arg-type]
            bridge=self.bridge,  # type: ignore[arg-type]
        )
        self.server = create_server(self.runtime)

    async def test_publica_las_seis_tools_con_esquemas_y_anotaciones(self) -> None:
        async with Client(self.server) as client:
            result = await client.list_tools()

        tools = {tool.name: tool for tool in result.tools}
        self.assertEqual(
            set(tools),
            {
                "estado_integracion_factuzam",
                "consultar_stock",
                "informe_movimientos_venta",
                "preparar_venta",
                "crear_venta",
                "consultar_estado_venta",
            },
        )

        read_only = set(tools) - {"crear_venta"}
        for name in read_only:
            with self.subTest(tool=name):
                annotations = tools[name].annotations
                self.assertIsNotNone(annotations)
                self.assertIs(annotations.read_only_hint, True)
                self.assertIs(annotations.open_world_hint, False)

        write_annotations = tools["crear_venta"].annotations
        self.assertIsNotNone(write_annotations)
        self.assertIs(write_annotations.read_only_hint, False)
        self.assertIs(write_annotations.destructive_hint, False)
        self.assertIs(write_annotations.idempotent_hint, True)
        self.assertIs(write_annotations.open_world_hint, False)

        self.assertEqual(
            tools["estado_integracion_factuzam"].input_schema["properties"], {}
        )
        stock_schema = tools["consultar_stock"].input_schema
        self.assertEqual(stock_schema["properties"]["pagina"]["minimum"], 1)
        self.assertEqual(
            stock_schema["properties"]["tamano_pagina"]["maximum"], 500
        )
        report_schema = tools["informe_movimientos_venta"].input_schema
        self.assertEqual(
            set(report_schema["required"]), {"fecha_desde", "fecha_hasta"}
        )
        self.assertEqual(
            report_schema["properties"]["fecha_desde"]["pattern"],
            r"^\d{4}-\d{2}-\d{2}$",
        )
        prepare_schema = tools["preparar_venta"].input_schema
        self.assertEqual(prepare_schema["required"], ["solicitud"])
        self.assertIn("SolicitudVenta", prepare_schema["$defs"])
        self.assertIn("LineaVenta", prepare_schema["$defs"])
        create_schema = tools["crear_venta"].input_schema
        self.assertEqual(
            set(create_schema["required"]),
            {"preparacion_id", "idempotency_key"},
        )
        self.assertIs(create_schema["properties"]["confirmar"]["default"], False)
        self.assertEqual(
            tools["consultar_estado_venta"].input_schema["required"],
            ["idempotency_key"],
        )

    async def test_diagnostico_informa_presencia_sin_revelar_secretos(self) -> None:
        async with Client(self.server) as client:
            result = await client.call_tool("estado_integracion_factuzam")

        self.assertFalse(result.is_error)
        diagnostic = result.structured_content
        self.assertTrue(diagnostic["mariadb"]["clave_configurada"])
        self.assertTrue(diagnostic["ventas"]["token_puente_configurado"])
        self.assertEqual(diagnostic["autorizacion"]["almacenes_permitidos"], 1)
        serialized = json.dumps(diagnostic, ensure_ascii=False)
        for secret in (
            "host-db-secreto.example.test",
            "base-secreta",
            "usuario-secreto",
            "clave-db-supersecreta",
            "principal-supersecreto",
            "puente-secreto.example.test",
            "token-puente-supersecreto",
            "EMP01",
            "ALM01",
            "CAJA01",
        ):
            with self.subTest(secret=secret):
                self.assertNotIn(secret, serialized)

        windows_environ = dict(self.environ)
        windows_environ.pop("FACTUZAM_DB_PASSWORD")
        windows_environ["FACTUZAM_DB_CREDENTIAL_TARGET"] = (
            "Factuzam/MCP/lectura"
        )
        self.assertTrue(
            Runtime(environ=windows_environ).diagnostic()["mariadb"][
                "clave_configurada"
            ]
        )

    async def test_delega_stock_e_informe_con_argumentos_validados(self) -> None:
        async with Client(self.server) as client:
            stock = await client.call_tool(
                "consultar_stock",
                {
                    "sku": "SKU-001",
                    "almacenes": ["ALM01"],
                    "solo_disponible": True,
                    "pagina": 2,
                    "tamano_pagina": 25,
                },
            )
            report = await client.call_tool(
                "informe_movimientos_venta",
                {
                    "fecha_desde": "2026-08-01",
                    "fecha_hasta": "2026-08-25",
                    "almacenes": ["ALM01"],
                    "nivel1": "ALM",
                    "solo_ventas": True,
                    "limite": 250,
                },
            )

        self.assertFalse(stock.is_error)
        self.assertEqual(stock.structured_content["origen"], "stock")
        self.assertEqual(self.service.stock_calls[0]["sku"], "SKU-001")
        self.assertEqual(self.service.stock_calls[0]["almacenes"], ["ALM01"])
        self.assertEqual(self.service.stock_calls[0]["pagina"], 2)
        self.assertFalse(report.is_error)
        self.assertEqual(report.structured_content["origen"], "informe")
        self.assertEqual(
            self.service.report_calls[0]["fecha_desde"], "2026-08-01"
        )
        self.assertEqual(self.service.report_calls[0]["nivel1"], "ALM")
        self.assertEqual(self.service.report_calls[0]["limite"], 250)

    async def test_ventas_deshabilitadas_no_llegan_al_puente(self) -> None:
        self.environ["FACTUZAM_VENTAS_HABILITADAS"] = "NO"

        async with Client(self.server) as client:
            prepare = await client.call_tool(
                "preparar_venta", {"solicitud": solicitud_valida()}
            )
            create = await client.call_tool(
                "crear_venta",
                {
                    "preparacion_id": "prep-1",
                    "idempotency_key": "pedido-42",
                    "confirmar": True,
                },
            )

        self.assertTrue(prepare.is_error)
        self.assertTrue(create.is_error)
        self.assertIn("ventas MCP están deshabilitadas", prepare.content[0].text)
        self.assertIn("ventas MCP están deshabilitadas", create.content[0].text)
        self.assertEqual(self.bridge.preparar_calls, [])
        self.assertEqual(self.bridge.confirmar_calls, [])

    async def test_preparacion_envia_contexto_normalizado_al_puente(self) -> None:
        solicitud = solicitud_valida()
        solicitud.update({"empresa": "emp01", "almacen": "alm01", "caja": "caja01"})

        async with Client(self.server) as client:
            result = await client.call_tool(
                "preparar_venta", {"solicitud": solicitud}
            )

        self.assertFalse(result.is_error)
        enviada = self.bridge.preparar_calls[0]
        self.assertEqual(
            (enviada.empresa, enviada.almacen, enviada.caja),
            ("EMP01", "ALM01", "CAJA01"),
        )

    async def test_crear_venta_exige_confirmacion_explicita(self) -> None:
        async with Client(self.server) as client:
            rejected = await client.call_tool(
                "crear_venta",
                {
                    "preparacion_id": "prep-1",
                    "idempotency_key": "pedido-42",
                    "confirmar": False,
                },
            )
            accepted = await client.call_tool(
                "crear_venta",
                {
                    "preparacion_id": "prep-1",
                    "idempotency_key": "pedido-42",
                    "confirmar": True,
                },
            )

        self.assertTrue(rejected.is_error)
        self.assertIn("confirmar=true", rejected.content[0].text)
        self.assertFalse(accepted.is_error)
        self.assertEqual(accepted.structured_content["estado"], "CONFIRMADA")
        self.assertEqual(
            self.bridge.confirmar_calls,
            [
                {
                    "preparacion_id": "prep-1",
                    "idempotency_key": "pedido-42",
                    "confirmar": True,
                }
            ],
        )

    async def test_estado_sigue_disponible_con_nuevas_ventas_deshabilitadas(self) -> None:
        self.environ["FACTUZAM_VENTAS_HABILITADAS"] = "NO"

        async with Client(self.server) as client:
            result = await client.call_tool(
                "consultar_estado_venta", {"idempotency_key": "pedido-42"}
            )

        self.assertFalse(result.is_error)
        self.assertEqual(result.structured_content["estado"], "CONFIRMADA")
        self.assertEqual(self.bridge.estado_calls, ["pedido-42"])


if __name__ == "__main__":
    unittest.main()
