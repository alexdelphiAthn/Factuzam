from __future__ import annotations

from contextlib import contextmanager
from datetime import date, datetime
from decimal import Decimal
from typing import Any, Iterator
import unittest

from factuzam_mcp.config import Settings
from factuzam_mcp.repository import (
    FactuzamRepository,
    ReportResult,
    StockPage,
)
from factuzam_mcp.service import (
    AccessDeniedError,
    FactuzamService,
    StaticAccessPolicy,
    ValidationError,
)


def settings(
    *scopes: str,
    max_days: int = 366,
    max_offset: int = 50_000,
    max_lookback: int = 3_650,
) -> Settings:
    return Settings(
        db_host="127.0.0.1",
        db_port=3306,
        db_name="factuzam",
        db_user="mcp_ro",
        db_password="secret",
        allowed_companies=("EMP1",),
        allowed_warehouses=("A1", "A2"),
        allowed_cash_registers=("C1",),
        scopes=frozenset(scopes),
        max_report_days=max_days,
        max_stock_page_size=100,
        max_stock_offset=max_offset,
        max_report_rows=1000,
        max_purchase_lookback_days=max_lookback,
    )


class FakeRepository:
    def __init__(self) -> None:
        self.stock_calls: list[dict[str, Any]] = []
        self.report_calls: list[dict[str, Any]] = []
        self.stock_result = StockPage(rows=[], total=0)
        self.report_result = ReportResult(rows=[], truncated=False)

    def consultar_stock(self, **kwargs: Any) -> StockPage:
        self.stock_calls.append(kwargs)
        return self.stock_result

    def informe_movimientos_venta(self, **kwargs: Any) -> ReportResult:
        self.report_calls.append(kwargs)
        return self.report_result


class ServiceStockTests(unittest.TestCase):
    def test_stock_is_denied_without_scope_before_repository_call(self) -> None:
        repository = FakeRepository()
        service = FactuzamService(settings(), repository)  # type: ignore[arg-type]

        with self.assertRaisesRegex(AccessDeniedError, "stock:read"):
            service.consultar_stock()
        self.assertEqual(repository.stock_calls, [])

    def test_stock_rejects_warehouse_outside_allowlist(self) -> None:
        repository = FakeRepository()
        service = FactuzamService(
            settings("stock:read"), repository  # type: ignore[arg-type]
        )

        with self.assertRaises(AccessDeniedError):
            service.consultar_stock(almacenes=["A3"])
        self.assertEqual(repository.stock_calls, [])

    def test_stock_uses_all_allowed_warehouses_and_hides_costs(self) -> None:
        repository = FakeRepository()
        repository.stock_result = StockPage(
            rows=[
                {
                    "ALMACEN": "A1",
                    "SKU": "SKU-1",
                    "STOCK_FISICO": Decimal("3.000000"),
                    "DISPONIBLE": Decimal("2.000000"),
                    "VALOR_TOTAL": Decimal("15.00"),
                    "PRECIO_MEDIO": Decimal("5.00"),
                    "ACTUALIZADO_EN": datetime(2026, 8, 25, 8, 30),
                }
            ],
            total=11,
        )
        service = FactuzamService(
            settings("stock:read"), repository  # type: ignore[arg-type]
        )

        result = service.consultar_stock(pagina=1, tamano_pagina=10)

        call = repository.stock_calls[0]
        self.assertEqual(call["warehouses"], ("A1", "A2"))
        self.assertFalse(call["include_costs"])
        self.assertEqual(result["stock"][0]["stock_fisico"], "3.000000")
        self.assertEqual(result["stock"][0]["actualizado_en"], "2026-08-25T08:30:00")
        self.assertNotIn("valor_total", result["stock"][0])
        self.assertNotIn("precio_medio", result["stock"][0])
        self.assertTrue(result["pagina"]["hay_mas"])

    def test_stock_includes_costs_only_with_explicit_scope(self) -> None:
        repository = FakeRepository()
        repository.stock_result = StockPage(
            rows=[{"valor_total": Decimal("15.50"), "precio_medio": Decimal("5.00")}],
            total=1,
        )
        service = FactuzamService(
            settings("stock:read", "caja.verCoste"),
            repository,  # type: ignore[arg-type]
        )

        result = service.consultar_stock(almacenes="a1")

        self.assertTrue(repository.stock_calls[0]["include_costs"])
        self.assertEqual(result["stock"][0]["valor_total"], "15.50")
        self.assertEqual(result["stock"][0]["precio_medio"], "5.00")

    def test_stock_rejects_deep_offset_before_query(self) -> None:
        repository = FakeRepository()
        service = FactuzamService(
            settings("stock:read", max_offset=100),
            repository,  # type: ignore[arg-type]
        )

        with self.assertRaisesRegex(ValidationError, "desplazamiento máximo"):
            service.consultar_stock(pagina=3, tamano_pagina=100)
        self.assertEqual(repository.stock_calls, [])


class ServiceReportTests(unittest.TestCase):
    def test_report_validates_dates_range_and_levels_before_query(self) -> None:
        repository = FakeRepository()
        service = FactuzamService(
            settings("ventas:read", max_days=31),
            repository,  # type: ignore[arg-type]
        )
        invalid = (
            {"fecha_desde": "25-08-2026", "fecha_hasta": "2026-08-25"},
            {"fecha_desde": "2026-08-26", "fecha_hasta": "2026-08-25"},
            {"fecha_desde": "2026-01-01", "fecha_hasta": "2026-08-25"},
            {
                "fecha_desde": "2026-08-01",
                "fecha_hasta": "2026-08-25",
                "nivel1": "ALM",
                "nivel2": "alm",
            },
            {
                "fecha_desde": "2026-08-01",
                "fecha_hasta": "2026-08-25",
                "inicio_compras": "2010-01-01",
            },
        )
        for arguments in invalid:
            with self.subTest(arguments=arguments):
                with self.assertRaises(ValidationError):
                    service.informe_movimientos_venta(**arguments)
        self.assertEqual(repository.report_calls, [])

    def test_report_delegates_to_native_contract_summarizes_and_redacts_costs(
        self,
    ) -> None:
        repository = FakeRepository()
        repository.report_result = ReportResult(
            rows=[
                {
                    "CODIGO_ART_ART": "ART-1",
                    "UNI_ENT_TOT": Decimal("4.00"),
                    "UDS_VENTA": Decimal("2.00"),
                    "IMP_VENTA": Decimal("19.99"),
                    "IMP_COSTE": Decimal("7.50"),
                    "BENEFICIO": Decimal("12.49"),
                    "MARGEN1": Decimal("62.48"),
                },
                {
                    "CODIGO_ART_ART": "ART-2",
                    "UNI_ENT_TOT": Decimal("1.00"),
                    "UDS_VENTA": Decimal("0.10"),
                    "IMP_VENTA": Decimal("0.01"),
                    "IMP_COSTE": Decimal("0.005"),
                    "BENEFICIO": Decimal("0.005"),
                },
            ],
            truncated=True,
        )
        service = FactuzamService(
            settings("ventas:read"), repository  # type: ignore[arg-type]
        )

        result = service.informe_movimientos_venta(
            fecha_desde="2026-08-01",
            fecha_hasta="2026-08-25",
            inicio_compras="2026-01-01",
            almacenes=["a1"],
            familias=["ropa"],
            proveedores=["prv1"],
            temporadas=["verano 2026"],
            articulos=["art-1"],
            nivel1="alm",
            nivel2="fam",
            solo_ventas=True,
            limite=100,
        )

        call = repository.report_calls[0]
        self.assertEqual(call["date_from"], date(2026, 8, 1))
        self.assertEqual(call["warehouses"], ("A1",))
        self.assertEqual(call["families"], ("ROPA",))
        self.assertEqual(call["seasons"], ("VERANO 2026",))
        self.assertEqual(call["level1"], "ALM")
        self.assertEqual(call["level2"], "FAM")
        self.assertEqual(call["limit"], 100)
        self.assertEqual(result["resumen"]["unidades_vendidas"], "2.10")
        self.assertEqual(result["resumen"]["importe_ventas"], "20.00")
        self.assertTrue(result["resumen"]["parcial"])
        self.assertNotIn("imp_coste", result["movimientos"][0])
        self.assertNotIn("beneficio", result["movimientos"][0])
        self.assertNotIn("margen1", result["movimientos"][0])

    def test_report_exposes_cost_totals_with_cost_scope(self) -> None:
        repository = FakeRepository()
        repository.report_result = ReportResult(
            rows=[
                {
                    "IMP_ENT_TOT": Decimal("10.00"),
                    "IMP_COSTE": Decimal("7.50"),
                    "BENEFICIO": Decimal("12.49"),
                }
            ],
            truncated=False,
        )
        service = FactuzamService(
            settings("ventas:read", "caja.verCoste"),
            repository,  # type: ignore[arg-type]
        )

        result = service.informe_movimientos_venta(
            fecha_desde="2026-08-01", fecha_hasta="2026-08-25"
        )

        self.assertEqual(result["resumen"]["importe_entrada"], "10.00")
        self.assertEqual(result["resumen"]["importe_coste"], "7.50")
        self.assertEqual(result["resumen"]["beneficio"], "12.49")
        self.assertEqual(result["movimientos"][0]["imp_coste"], "7.50")

    def test_sale_context_requires_scope_and_three_nonempty_allowlists(self) -> None:
        no_scope = StaticAccessPolicy(settings())
        with self.assertRaises(AccessDeniedError):
            no_scope.require_sale_context(company="EMP1", warehouse="A1", cash_register="C1")

        configured = StaticAccessPolicy(settings("ventas:create"))
        self.assertEqual(
            configured.require_sale_context(
                company="emp1", warehouse="a1", cash_register="c1"
            ),
            ("EMP1", "A1", "C1"),
        )


class FakeCursor:
    def __init__(self, *, report_rows: list[dict[str, Any]] | None = None) -> None:
        self.report_rows = report_rows or []
        self.executions: list[tuple[str, Any]] = []
        self.fetchmany_calls = 0
        self.nextset_calls = 0

    def __enter__(self) -> "FakeCursor":
        return self

    def __exit__(self, *_args: Any) -> None:
        return None

    def execute(self, sql: str, params: Any) -> None:
        self.executions.append((sql, params))

    def fetchmany(self, _size: int) -> list[dict[str, Any]]:
        self.fetchmany_calls += 1
        if self.fetchmany_calls == 1:
            return self.report_rows
        return []

    def nextset(self) -> bool:
        self.nextset_calls += 1
        return self.nextset_calls == 1


class FakeConnection:
    def __init__(self, cursor: FakeCursor) -> None:
        self._cursor = cursor

    def cursor(self) -> FakeCursor:
        return self._cursor


class FakeStockCursor(FakeCursor):
    def __init__(self) -> None:
        super().__init__()
        self._stage = 0

    def execute(self, sql: str, params: Any) -> None:
        super().execute(sql, params)
        self._stage += 1

    def fetchone(self) -> dict[str, Any]:
        return {"total": 3}

    def fetchall(self) -> list[dict[str, Any]]:
        return [
            {
                "almacen": "A1",
                "sku": "SKU1",
                "stock_fisico": Decimal("2"),
                "pendiente_recibir": Decimal("4"),
                "disponible": Decimal("2"),
            }
        ]


class FakeDatabase:
    def __init__(self, connection: FakeConnection) -> None:
        self._connection = connection
        self.connection_calls = 0

    @contextmanager
    def connection(self) -> Iterator[FakeConnection]:
        self.connection_calls += 1
        yield self._connection


class RepositoryContractTests(unittest.TestCase):
    def test_stock_joins_pending_receipts_paginates_and_omits_cost_projection(
        self,
    ) -> None:
        cursor = FakeStockCursor()
        database = FakeDatabase(FakeConnection(cursor))
        repository = FactuzamRepository(database)

        result = repository.consultar_stock(
            warehouses=("A1", "A2"),
            article="ART1",
            sku_code=None,
            search=None,
            only_available=True,
            include_inactive=False,
            page=2,
            page_size=25,
            include_costs=False,
        )

        self.assertEqual(result.total, 3)
        self.assertEqual(result.rows[0]["pendiente_recibir"], Decimal("4"))
        self.assertEqual(len(cursor.executions), 2)
        count_sql, count_params = cursor.executions[0]
        data_sql, data_params = cursor.executions[1]
        self.assertIn("fza_articulos_stockactual", count_sql)
        self.assertIn("fza_articulos_pdte_recibir", count_sql)
        self.assertIn("CANTIDAD_STK, 0) > 0", count_sql)
        self.assertIn("AS disponible", data_sql)
        self.assertNotIn("AS precio_medio", data_sql)
        self.assertEqual(count_params[:4], ["A1", "A2", "A1", "A2"])
        self.assertEqual(data_params[-2:], [25, 25])
        self.assertEqual(database.connection_calls, 1)

    def test_report_calls_native_procedure_with_bound_parameters_and_drains_sets(
        self,
    ) -> None:
        cursor = FakeCursor(
            report_rows=[
                {"CODIGO_ART_ART": "A1"},
                {"CODIGO_ART_ART": "A2"},
                {"CODIGO_ART_ART": "A3"},
            ]
        )
        database = FakeDatabase(FakeConnection(cursor))
        repository = FactuzamRepository(database)

        result = repository.informe_movimientos_venta(
            date_from=date(2026, 8, 1),
            date_to=date(2026, 8, 25),
            purchases_from=None,
            warehouses=("A1",),
            families=("ROPA",),
            suppliers=(),
            seasons=(),
            articles=("ART1",),
            level1="ALM",
            level2="",
            level3="",
            family_level=0,
            only_sales=True,
            limit=2,
        )

        sql, params = cursor.executions[0]
        self.assertIn("CALL PRC_GET_MOV_VENTAS_ART", sql)
        self.assertEqual(sql.count("%s"), 13)
        self.assertEqual(params[3], "A1")
        self.assertEqual(params[4], "ROPA")
        self.assertEqual(params[7], "ART1")
        self.assertEqual(params[-1], "S")
        self.assertEqual(len(result.rows), 2)
        self.assertTrue(result.truncated)
        self.assertGreaterEqual(cursor.fetchmany_calls, 3)
        self.assertEqual(cursor.nextset_calls, 2)
        self.assertEqual(database.connection_calls, 1)


if __name__ == "__main__":
    unittest.main()
