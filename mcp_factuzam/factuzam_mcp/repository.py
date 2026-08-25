"""Acceso de solo lectura a MariaDB para las herramientas de Factuzam."""

from __future__ import annotations

from contextlib import contextmanager
from dataclasses import dataclass
from datetime import date
from typing import Any, ContextManager, Iterator, Protocol, Sequence

import pymysql
from pymysql.cursors import DictCursor

from .config import Settings


class RepositoryError(RuntimeError):
    """Fallo de persistencia sin exponer detalles de conexion al cliente."""


class ConnectionProvider(Protocol):
    def connection(self) -> ContextManager[Any]: ...


class Database:
    """Abre una conexion independiente por operacion y siempre la cierra."""

    def __init__(self, settings: Settings):
        self._settings = settings

    @contextmanager
    def connection(self) -> Iterator[Any]:
        settings = self._settings
        options: dict[str, Any] = {
            "host": settings.db_host,
            "port": settings.db_port,
            "user": settings.db_user,
            "password": settings.db_password,
            "database": settings.db_name,
            "charset": "utf8mb4",
            "cursorclass": DictCursor,
            "autocommit": True,
            "connect_timeout": settings.connect_timeout_seconds,
            "read_timeout": settings.read_timeout_seconds,
            "write_timeout": settings.write_timeout_seconds,
        }
        if settings.db_ssl_ca:
            options["ssl"] = {"ca": settings.db_ssl_ca}
        connection = pymysql.connect(**options)
        try:
            yield connection
        finally:
            connection.close()


@dataclass(frozen=True, slots=True)
class StockPage:
    rows: list[dict[str, Any]]
    total: int


@dataclass(frozen=True, slots=True)
class ReportResult:
    rows: list[dict[str, Any]]
    truncated: bool


_STOCK_CTE = """
WITH stock AS (
    SELECT
        s.CODIGO_ALM_STK AS almacen,
        s.CODIGO_UNIDAD_STK AS sku,
        SUM(COALESCE(s.CANTIDAD_STK, 0)) AS stock_fisico,
        SUM(COALESCE(s.CANTIDAD_PTE_SERVIR_STK, 0)) AS pendiente_servir,
        SUM(COALESCE(s.VALOR_TOTAL_STK, 0)) AS valor_total,
        COUNT(DISTINCT CASE
            WHEN COALESCE(s.CANTIDAD_STK, 0) > 0
            THEN NULLIF(s.LOTE_STK, '')
        END) AS numero_lotes,
        MIN(CASE
            WHEN COALESCE(s.CANTIDAD_STK, 0) > 0
            THEN s.FECHA_CADUCIDAD_STK
        END) AS caducidad_mas_proxima,
        MAX(s.INSTANTE_MODIF) AS actualizado_en
    FROM fza_articulos_stockactual s
    WHERE s.CODIGO_ALM_STK IN ({warehouses})
    GROUP BY s.CODIGO_ALM_STK, s.CODIGO_UNIDAD_STK
), pendientes AS (
    SELECT
        p.CODIGO_ALM_PDR AS almacen,
        p.CODIGO_UNIDAD_PDR AS sku,
        SUM(COALESCE(p.CANTIDAD_PDR, 0)) AS pendiente_recibir,
        MIN(p.FECHA_PREVISTA_PDR) AS recepcion_prevista_mas_proxima
    FROM fza_articulos_pdte_recibir p
    WHERE p.CODIGO_ALM_PDR IN ({warehouses})
    GROUP BY p.CODIGO_ALM_PDR, p.CODIGO_UNIDAD_PDR
), claves AS (
    SELECT almacen, sku FROM stock
    UNION
    SELECT almacen, sku FROM pendientes
)
"""


_STOCK_FROM = """
FROM claves k
JOIN fza_articulos_skus sku
  ON sku.CODIGO_UNIDAD_SKU = k.sku
JOIN fza_articulos art
  ON art.CODIGO_ART_ART = sku.CODIGO_ART_SKU
LEFT JOIN stock s
  ON s.almacen = k.almacen AND s.sku = k.sku
LEFT JOIN pendientes p
  ON p.almacen = k.almacen AND p.sku = k.sku
"""


_REPORT_SQL = """
CALL PRC_GET_MOV_VENTAS_ART(
    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
)
"""


class FactuzamRepository:
    def __init__(self, database: ConnectionProvider):
        self._database = database

    def consultar_stock(
        self,
        *,
        warehouses: Sequence[str],
        article: str | None,
        sku_code: str | None,
        search: str | None,
        only_available: bool,
        include_inactive: bool,
        page: int,
        page_size: int,
        include_costs: bool,
    ) -> StockPage:
        placeholders = ", ".join(["%s"] * len(warehouses))
        cte = _STOCK_CTE.format(warehouses=placeholders)
        where: list[str] = []
        filter_params: list[Any] = []
        if not include_inactive:
            where.extend(["sku.ESACTIVO_SKU = 'S'", "art.ESACTIVO_ART = 'S'"])
        if article:
            where.append("sku.CODIGO_ART_SKU = %s")
            filter_params.append(article)
        if sku_code:
            where.append("k.sku = %s")
            filter_params.append(sku_code)
        if search:
            where.append(
                "(k.sku LIKE %s OR sku.CODIGO_ART_SKU LIKE %s "
                "OR art.DESCRIPCION_ART LIKE %s)"
            )
            term = f"%{search}%"
            filter_params.extend([term, term, term])
        if only_available:
            where.append(
                "COALESCE(s.stock_fisico, 0) - "
                "COALESCE(s.pendiente_servir, 0) > 0"
            )
        where_sql = "\nWHERE " + " AND ".join(where) if where else ""
        base_params = [*warehouses, *warehouses, *filter_params]

        if include_costs:
            cost_columns = """
    COALESCE(s.valor_total, 0) AS valor_total,
    CASE
      WHEN COALESCE(s.stock_fisico, 0) <> 0
      THEN COALESCE(s.valor_total, 0) / s.stock_fisico
      ELSE 0
    END AS precio_medio,
"""
        else:
            # Los datos sensibles no viajan desde MariaDB si falta el scope.
            cost_columns = ""

        count_sql = cte + "SELECT COUNT(*) AS total\n" + _STOCK_FROM + where_sql
        data_sql = (
            cte
            + """
SELECT
    k.almacen,
    k.sku,
    sku.CODIGO_ART_SKU AS articulo,
    art.DESCRIPCION_ART AS descripcion,
    COALESCE(s.stock_fisico, 0) AS stock_fisico,
    COALESCE(s.pendiente_servir, 0) AS pendiente_servir,
    COALESCE(p.pendiente_recibir, 0) AS pendiente_recibir,
    COALESCE(s.stock_fisico, 0) - COALESCE(s.pendiente_servir, 0)
        AS disponible,
    COALESCE(s.stock_fisico, 0) - COALESCE(s.pendiente_servir, 0)
        + COALESCE(p.pendiente_recibir, 0) AS disponible_proyectado,
"""
            + cost_columns
            + """
    COALESCE(s.numero_lotes, 0) AS numero_lotes,
    s.caducidad_mas_proxima,
    p.recepcion_prevista_mas_proxima,
    s.actualizado_en
"""
            + _STOCK_FROM
            + where_sql
            + "\nORDER BY art.DESCRIPCION_ART, k.sku, k.almacen"
            + "\nLIMIT %s OFFSET %s"
        )
        offset = (page - 1) * page_size

        try:
            with self._database.connection() as connection:
                with connection.cursor() as cursor:
                    cursor.execute(count_sql, base_params)
                    total_row = cursor.fetchone() or {}
                    total = int(total_row.get("total", 0))
                    cursor.execute(data_sql, [*base_params, page_size, offset])
                    rows = [dict(row) for row in cursor.fetchall()]
            return StockPage(rows=rows, total=total)
        except pymysql.MySQLError as exc:
            raise RepositoryError("No se pudo consultar el stock") from exc

    def informe_movimientos_venta(
        self,
        *,
        date_from: date,
        date_to: date,
        purchases_from: date | None,
        warehouses: Sequence[str],
        families: Sequence[str],
        suppliers: Sequence[str],
        seasons: Sequence[str],
        articles: Sequence[str],
        level1: str,
        level2: str,
        level3: str,
        family_level: int,
        only_sales: bool,
        limit: int,
    ) -> ReportResult:
        params = (
            date_from,
            date_to,
            purchases_from,
            ",".join(warehouses),
            ",".join(families),
            ",".join(suppliers),
            ",".join(seasons),
            ",".join(articles),
            level1,
            level2,
            level3,
            family_level,
            "S" if only_sales else "N",
        )
        try:
            with self._database.connection() as connection:
                with connection.cursor() as cursor:
                    cursor.execute(_REPORT_SQL, params)
                    fetched = cursor.fetchmany(limit + 1)
                    truncated = len(fetched) > limit
                    rows = [dict(row) for row in fetched[:limit]]

                    # Un CALL de MySQL puede dejar varios result sets. Hay que
                    # consumirlos antes de reutilizar/cerrar la conexion.
                    while cursor.fetchmany(1000):
                        pass
                    while cursor.nextset():
                        while cursor.fetchmany(1000):
                            pass
            return ReportResult(rows=rows, truncated=truncated)
        except pymysql.MySQLError as exc:
            raise RepositoryError(
                "No se pudo generar el informe de movimientos de venta"
            ) from exc
