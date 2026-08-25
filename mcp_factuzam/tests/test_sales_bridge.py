from __future__ import annotations

import io
import json
import unittest
from unittest.mock import patch
from urllib.error import HTTPError, URLError
from urllib.request import Request

from factuzam_mcp.models import SolicitudVenta
from factuzam_mcp.sales_bridge import (
    MAX_RESPONSE_BYTES,
    BridgeConfig,
    SalesBridge,
    SalesBridgeConfigurationError,
    SalesBridgeConfirmationRequired,
    SalesBridgeIndeterminateError,
    SalesBridgeProtocolError,
    SalesBridgeRejectedError,
    SalesBridgeUnavailableError,
    _abrir_sin_redireccion,
)


class FakeResponse:
    def __init__(
        self,
        body: bytes = b'{"ok":true}',
        *,
        status: int = 200,
        headers: dict[str, str] | None = None,
    ) -> None:
        self.body = body
        self.status = status
        self.headers = headers or {}
        self.closed = False

    def getcode(self) -> int:
        return self.status

    def read(self, _size: int = -1) -> bytes:
        return self.body

    def close(self) -> None:
        self.closed = True


def crear_venta() -> SolicitudVenta:
    return SolicitudVenta(
        empresa="EMP01",
        almacen="ALM01",
        caja="CAJA01",
        cliente="CLI01",
        tipo_documento="SIMPLIFICADA",
        serie="A",
        tarifa="GENERAL",
        lineas=[{"sku": "SKU-001", "cantidad": "2"}],
        cobros=[{"forma_pago": "EFECTIVO", "importe": "20.00"}],
    )


def respuesta_preparacion() -> bytes:
    return json.dumps(
        {
            "preparacion_id": "prep-1",
            "caduca_en": "2099-01-01T00:00:00Z",
            "resumen": {
                "empresa": "EMP01",
                "almacen": "ALM01",
                "caja": "CAJA01",
                "tipo_documento": "SIMPLIFICADA",
                "serie": "A",
                "tarifa": "GENERAL",
                "cliente": {"codigo": "CLI01", "nombre": "Cliente de prueba"},
                "moneda": "EUR",
                "lineas": [
                    {
                        "sku": "SKU-001",
                        "descripcion": "Artículo de prueba",
                        "cantidad": "2",
                        "precio_unitario_sin_impuestos": "8.264463",
                        "porcentaje_iva": "21.00",
                        "base_imponible": "16.53",
                        "cuota_iva": "3.47",
                        "total_con_impuestos": "20.00",
                    }
                ],
                "cobros": [{"forma_pago": "EFECTIVO", "importe": "20.00"}],
                "totales": {
                    "base": "16.53",
                    "impuestos": "3.47",
                    "liquido": "20.00",
                },
            },
        },
        ensure_ascii=False,
    ).encode("utf-8")


class BridgeConfigTests(unittest.TestCase):
    def test_from_env_exige_url_token_y_principal(self) -> None:
        with self.assertRaises(SalesBridgeConfigurationError):
            BridgeConfig.from_env({})
        with self.assertRaises(SalesBridgeConfigurationError):
            BridgeConfig.from_env(
                {
                    "FACTUZAM_VENTAS_BRIDGE_URL": "https://ventas.example.test",
                    "FACTUZAM_VENTAS_BRIDGE_TOKEN": "token",
                }
            )

    def test_acepta_https_y_http_solo_en_loopback(self) -> None:
        for url in (
            "https://ventas.example.test",
            "http://127.0.0.1:8765",
            "http://[::1]:8765",
        ):
            with self.subTest(url=url):
                config = BridgeConfig(url, "token", "operador")
                self.assertEqual(config.base_url, url)

        for url in (
            "http://ventas.example.test",
            "http://localhost:8765",
            "ftp://localhost",
            "https://usuario:clave@ventas.example.test",
            "https://ventas.example.test/prefijo",
            "https://ventas.example.test?token=secreto",
        ):
            with self.subTest(url=url), self.assertRaises(
                SalesBridgeConfigurationError
            ):
                BridgeConfig(url, "token", "operador")

    def test_rechaza_inyeccion_en_cabeceras_y_mas_de_un_mib(self) -> None:
        with self.assertRaises(SalesBridgeConfigurationError):
            BridgeConfig("https://ventas.example.test", "token\r\nX-Evil: 1", "op")
        with self.assertRaises(SalesBridgeConfigurationError):
            BridgeConfig("https://ventas.example.test", "token", "op\nadmin")
        with self.assertRaises(SalesBridgeConfigurationError):
            BridgeConfig(
                "https://ventas.example.test",
                "token",
                "op",
                max_response_bytes=MAX_RESPONSE_BYTES + 1,
            )

    def test_repr_no_expone_el_token(self) -> None:
        config = BridgeConfig(
            "https://ventas.example.test", "token-supersecreto", "operador"
        )

        self.assertNotIn("token-supersecreto", repr(config))

    @patch("factuzam_mcp.sales_bridge.build_opener")
    def test_el_transporte_nunca_hereda_proxies(self, construir) -> None:
        respuesta = FakeResponse()
        construir.return_value.open.return_value = respuesta

        resultado = _abrir_sin_redireccion(
            Request("http://127.0.0.1:8765/v1/estado"), timeout=1
        )

        self.assertIs(resultado, respuesta)
        proxy_handler = construir.call_args.args[0]
        self.assertEqual(proxy_handler.proxies, {})


class SalesBridgeTests(unittest.TestCase):
    def setUp(self) -> None:
        self.config = BridgeConfig(
            "https://ventas.example.test", "secreto", "usuario-7", timeout_seconds=3
        )
        self.bridge = SalesBridge(self.config)

    @patch("factuzam_mcp.sales_bridge._abrir_sin_redireccion")
    def test_preparar_autentica_y_envia_dto_json(self, abrir) -> None:
        respuesta = FakeResponse(respuesta_preparacion())
        abrir.return_value = respuesta

        resultado = self.bridge.preparar(crear_venta())

        self.assertEqual(resultado["preparacion_id"], "prep-1")
        self.assertEqual(resultado["resumen"]["totales"]["liquido"], "20.00")
        request = abrir.call_args.args[0]
        self.assertEqual(
            request.full_url,
            "https://ventas.example.test/v1/ventas/preparaciones",
        )
        self.assertEqual(request.method, "POST")
        self.assertEqual(request.get_header("Authorization"), "Bearer secreto")
        self.assertEqual(request.get_header("X-factuzam-principal"), "usuario-7")
        self.assertNotIn("Authorization", request.headers)
        self.assertIn("Authorization", request.unredirected_hdrs)
        self.assertIsNone(request.get_header("Idempotency-key"))
        self.assertEqual(abrir.call_args.kwargs["timeout"], 3)
        payload = json.loads(request.data.decode("utf-8"))
        self.assertEqual(payload["lineas"][0], {"sku": "SKU-001", "cantidad": "2"})
        self.assertEqual(payload["cobros"][0]["importe"], "20.00")
        self.assertTrue(respuesta.closed)

    @patch("factuzam_mcp.sales_bridge._abrir_sin_redireccion")
    def test_preparar_rechaza_contexto_distinto(self, abrir) -> None:
        contexto_distinto = json.loads(respuesta_preparacion().decode("utf-8"))
        contexto_distinto["resumen"]["empresa"] = "OTRA"
        abrir.return_value = FakeResponse(
            json.dumps(contexto_distinto, ensure_ascii=False).encode("utf-8")
        )

        with self.assertRaises(SalesBridgeProtocolError):
            self.bridge.preparar(crear_venta())

    @patch("factuzam_mcp.sales_bridge._abrir_sin_redireccion")
    def test_preparar_exige_cliente_y_decimales_contractuales(self, abrir) -> None:
        venta_sin_cliente = crear_venta().model_copy(update={"cliente": None})
        respuesta_sin_cliente = json.loads(
            respuesta_preparacion().decode("utf-8")
        )
        respuesta_sin_cliente["resumen"]["cliente"] = None
        abrir.return_value = FakeResponse(
            json.dumps(respuesta_sin_cliente, ensure_ascii=False).encode("utf-8")
        )

        resultado = self.bridge.preparar(venta_sin_cliente)
        self.assertIsNone(resultado["resumen"]["cliente"])

        respuesta_sin_campo = json.loads(
            respuesta_preparacion().decode("utf-8")
        )
        del respuesta_sin_campo["resumen"]["cliente"]
        abrir.return_value = FakeResponse(
            json.dumps(respuesta_sin_campo, ensure_ascii=False).encode("utf-8")
        )

        with self.assertRaises(SalesBridgeProtocolError):
            self.bridge.preparar(venta_sin_cliente)

        respuesta_cliente_nulo = json.loads(
            respuesta_preparacion().decode("utf-8")
        )
        respuesta_cliente_nulo["resumen"]["cliente"] = None
        abrir.return_value = FakeResponse(
            json.dumps(respuesta_cliente_nulo, ensure_ascii=False).encode("utf-8")
        )

        with self.assertRaises(SalesBridgeProtocolError):
            self.bridge.preparar(crear_venta())

        cliente_distinto = json.loads(respuesta_preparacion().decode("utf-8"))
        cliente_distinto["resumen"]["cliente"]["codigo"] = "CLI02"
        abrir.return_value = FakeResponse(
            json.dumps(cliente_distinto, ensure_ascii=False).encode("utf-8")
        )

        with self.assertRaises(SalesBridgeProtocolError):
            self.bridge.preparar(crear_venta())

        numero_binario = json.loads(respuesta_preparacion().decode("utf-8"))
        numero_binario["resumen"]["lineas"][0]["cantidad"] = 2
        abrir.return_value = FakeResponse(
            json.dumps(numero_binario, ensure_ascii=False).encode("utf-8")
        )

        with self.assertRaises(SalesBridgeProtocolError):
            self.bridge.preparar(crear_venta())

        digitos_unicode = json.loads(respuesta_preparacion().decode("utf-8"))
        digitos_unicode["resumen"]["lineas"][0]["cantidad"] = "1٢.٣"
        abrir.return_value = FakeResponse(
            json.dumps(digitos_unicode, ensure_ascii=False).encode("utf-8")
        )

        with self.assertRaises(SalesBridgeProtocolError):
            self.bridge.preparar(crear_venta())

    @patch("factuzam_mcp.sales_bridge._abrir_sin_redireccion")
    def test_confirmar_exige_confirmacion_y_propaga_idempotencia(self, abrir) -> None:
        with self.assertRaises(SalesBridgeConfirmationRequired):
            self.bridge.confirmar("prep-1", "pedido-42", False)
        abrir.assert_not_called()

        abrir.return_value = FakeResponse(
            b'{"estado":"CONFIRMADA","documento":'
            b'{"empresa":"EMP01","serie":"A","numero":"42"}}'
        )
        resultado = self.bridge.confirmar("prep-1", "pedido-42", True)

        self.assertEqual(resultado["estado"], "CONFIRMADA")
        request = abrir.call_args.args[0]
        self.assertEqual(request.full_url, "https://ventas.example.test/v1/ventas")
        self.assertEqual(request.get_header("Idempotency-key"), "pedido-42")
        self.assertEqual(request.get_header("X-factuzam-principal"), "usuario-7")
        self.assertEqual(
            json.loads(request.data.decode("utf-8")),
            {
                "preparacion_id": "prep-1",
                "idempotency_key": "pedido-42",
                "confirmar": True,
            },
        )

    @patch("factuzam_mcp.sales_bridge._abrir_sin_redireccion")
    def test_estado_codifica_idempotency_key_como_segmento_url(self, abrir) -> None:
        abrir.return_value = FakeResponse(b'{"estado":"DESCONOCIDA"}')

        self.bridge.consultar_estado("pedido/42 con espacio")

        request = abrir.call_args.args[0]
        self.assertEqual(
            request.full_url,
            "https://ventas.example.test/v1/ventas/estado/pedido%2F42%20con%20espacio",
        )
        self.assertEqual(request.method, "GET")

    @patch("factuzam_mcp.sales_bridge._abrir_sin_redireccion")
    def test_sanea_error_http_sin_exponer_cuerpo_remoto(self, abrir) -> None:
        abrir.side_effect = HTTPError(
            "https://ventas.example.test/v1/ventas",
            422,
            "fallo con secreto-interno",
            {},
            io.BytesIO(b'{"detail":"password=supersecreto"}'),
        )

        with self.assertRaises(SalesBridgeRejectedError) as capturado:
            self.bridge.confirmar("prep-1", "pedido-42", True)

        self.assertEqual(capturado.exception.status_code, 422)
        self.assertNotIn("supersecreto", str(capturado.exception))
        self.assertNotIn("secreto-interno", str(capturado.exception))

    @patch("factuzam_mcp.sales_bridge._abrir_sin_redireccion")
    def test_sanea_error_de_red(self, abrir) -> None:
        abrir.side_effect = URLError("detalle interno del socket")

        with self.assertRaises(SalesBridgeUnavailableError) as capturado:
            self.bridge.preparar(crear_venta())

        self.assertNotIn("socket", str(capturado.exception))

    @patch("factuzam_mcp.sales_bridge._abrir_sin_redireccion")
    def test_rechaza_respuestas_grandes_o_json_no_objeto(self, abrir) -> None:
        abrir.return_value = FakeResponse(b"x" * 11)
        bridge = SalesBridge(
            BridgeConfig(
                "https://ventas.example.test",
                "token",
                "op",
                max_response_bytes=10,
            )
        )
        with self.assertRaises(SalesBridgeProtocolError):
            bridge.preparar(crear_venta())

        abrir.return_value = FakeResponse(b"[]")
        with self.assertRaises(SalesBridgeProtocolError):
            self.bridge.preparar(crear_venta())

        abrir.return_value = FakeResponse(b"no es json")
        with self.assertRaises(SalesBridgeProtocolError):
            self.bridge.preparar(crear_venta())

        abrir.return_value = FakeResponse(b'{"total":NaN}')
        with self.assertRaises(SalesBridgeProtocolError):
            self.bridge.preparar(crear_venta())

        abrir.return_value = FakeResponse(b'{"sin_preparacion_id":true}')
        with self.assertRaises(SalesBridgeProtocolError):
            self.bridge.preparar(crear_venta())

        abrir.return_value = FakeResponse(
            b'{"preparacion_id":"prep-1","caduca_en":"sin-zona","resumen":{}}'
        )
        with self.assertRaises(SalesBridgeProtocolError):
            self.bridge.preparar(crear_venta())

        abrir.return_value = FakeResponse(
            b'{"preparacion_id":"prep-1",'
            b'"caduca_en":"2099-01-01T00:00:00Z","resumen":{}}'
        )
        with self.assertRaises(SalesBridgeProtocolError):
            self.bridge.preparar(crear_venta())

        abrir.return_value = FakeResponse(b'{"estado":"CONFIRMADA"}')
        with self.assertRaises(SalesBridgeIndeterminateError):
            self.bridge.confirmar("prep-1", "pedido-42", True)

        class RespuestaConCierreFallido(FakeResponse):
            def close(self) -> None:
                raise OSError("cierre roto")

        abrir.side_effect = None
        abrir.return_value = RespuestaConCierreFallido(
            b'{"estado":"PENDIENTE"}'
        )
        with self.assertRaises(SalesBridgeIndeterminateError):
            self.bridge.confirmar("prep-1", "pedido-42", True)

    @patch("factuzam_mcp.sales_bridge._abrir_sin_redireccion")
    def test_timeout_y_5xx_al_confirmar_son_resultado_indeterminado(
        self, abrir
    ) -> None:
        abrir.side_effect = URLError("timeout tras enviar")
        with self.assertRaisesRegex(
            SalesBridgeIndeterminateError, "misma idempotency_key"
        ):
            self.bridge.confirmar("prep-1", "pedido-42", True)

        abrir.side_effect = HTTPError(
            "https://ventas.example.test/v1/ventas",
            503,
            "error interno",
            {},
            io.BytesIO(b"error"),
        )
        with self.assertRaises(SalesBridgeIndeterminateError):
            self.bridge.confirmar("prep-1", "pedido-42", True)

    @patch("factuzam_mcp.sales_bridge._abrir_sin_redireccion")
    def test_rechaza_redireccion_del_origen_configurado(self, abrir) -> None:
        class RedirectResponse(FakeResponse):
            def geturl(self) -> str:
                return "https://otro.example.test/v1/ventas/preparaciones"

        abrir.return_value = RedirectResponse()

        with self.assertRaises(SalesBridgeProtocolError):
            self.bridge.preparar(crear_venta())


if __name__ == "__main__":
    unittest.main()
