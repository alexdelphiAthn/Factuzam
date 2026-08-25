from __future__ import annotations

import unittest
from decimal import Decimal

from pydantic import ValidationError

from factuzam_mcp.models import CobroVenta, LineaVenta, SolicitudVenta


def venta_valida(**cambios: object) -> dict[str, object]:
    datos: dict[str, object] = {
        "empresa": "EMP01",
        "almacen": "ALM01",
        "caja": "CAJA01",
        "cliente": "CLI01",
        "tipo_documento": "SIMPLIFICADA",
        "serie": "A",
        "tarifa": "GENERAL",
        "lineas": [{"sku": "SKU-001", "cantidad": "2.500000"}],
        "cobros": [
            {"forma_pago": "TARJETA", "importe": "25.75", "referencia": "op-1"}
        ],
    }
    datos.update(cambios)
    return datos


class ModelosVentaTests(unittest.TestCase):
    def test_valida_y_conserva_decimales_exactos(self) -> None:
        venta = SolicitudVenta.model_validate(
            venta_valida(empresa="  emp01  ", tarifa="general", cliente=None)
        )

        self.assertEqual(venta.empresa, "EMP01")
        self.assertEqual(venta.tarifa, "GENERAL")
        self.assertIsNone(venta.cliente)
        self.assertEqual(venta.lineas[0].cantidad, Decimal("2.500000"))
        self.assertEqual(venta.cobros[0].importe, Decimal("25.75"))
        serializado = venta.model_dump(mode="json", exclude_none=True)
        self.assertEqual(serializado["lineas"][0]["cantidad"], "2.500000")
        self.assertEqual(serializado["cobros"][0]["importe"], "25.75")

    def test_prohibe_campos_extra_en_todos_los_niveles(self) -> None:
        with self.assertRaises(ValidationError):
            SolicitudVenta.model_validate(venta_valida(precio_forzado="0.01"))

        datos = venta_valida()
        datos["lineas"] = [{"sku": "SKU-001", "cantidad": "1", "precio": "0"}]
        with self.assertRaises(ValidationError):
            SolicitudVenta.model_validate(datos)

    def test_exige_al_menos_una_linea_y_limita_su_numero(self) -> None:
        with self.assertRaises(ValidationError):
            SolicitudVenta.model_validate(venta_valida(lineas=[]))

        demasiadas = [
            {"sku": f"SKU-{indice}", "cantidad": "1"} for indice in range(201)
        ]
        with self.assertRaises(ValidationError):
            SolicitudVenta.model_validate(venta_valida(lineas=demasiadas))

    def test_cantidad_e_importe_deben_ser_positivos_y_acotados(self) -> None:
        for cantidad in ("0", "-1", "1.0000001", "1234567890123.123456"):
            with self.subTest(cantidad=cantidad), self.assertRaises(
                ValidationError
            ):
                LineaVenta(sku="SKU", cantidad=cantidad)

        for importe in ("0", "-0.01", "1.0000001"):
            with self.subTest(importe=importe), self.assertRaises(
                ValidationError
            ):
                CobroVenta(forma_pago="EFECTIVO", importe=importe)

    def test_limita_cobros_y_rechaza_caracteres_de_control(self) -> None:
        cobros = [{"forma_pago": "EFECTIVO", "importe": "1"}] * 21
        with self.assertRaises(ValidationError):
            SolicitudVenta.model_validate(venta_valida(cobros=cobros))

        with self.assertRaises(ValidationError):
            LineaVenta(sku="SKU\nINYECTADO", cantidad="1")

    def test_modelos_son_inmutables(self) -> None:
        linea = LineaVenta(sku="SKU", cantidad="1")
        with self.assertRaises(ValidationError):
            linea.sku = "OTRO"  # type: ignore[misc]


if __name__ == "__main__":
    unittest.main()
