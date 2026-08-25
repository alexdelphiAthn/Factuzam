"""Casos de uso puros que el servidor MCP expone como herramientas."""

from __future__ import annotations

from datetime import date
from decimal import Decimal
from typing import Any, Iterable, Sequence

from .config import Settings
from .repository import Database, FactuzamRepository
from .serialization import decimal_text, serialize, sum_field


class FactuzamServiceError(RuntimeError):
    """Error controlado apto para traducir a un error de herramienta MCP."""


class ValidationError(FactuzamServiceError, ValueError):
    pass


class AccessDeniedError(FactuzamServiceError, PermissionError):
    pass


class StaticAccessPolicy:
    """Politica local, explicita y cerrada por defecto."""

    def __init__(self, settings: Settings):
        self._settings = settings

    def has_scope(self, scope: str) -> bool:
        return self._settings.has_scope(scope)

    def require_scope(self, scope: str) -> None:
        if not self.has_scope(scope):
            raise AccessDeniedError(f"Falta el permiso {scope}")

    def resolve_warehouses(
        self, requested: Sequence[str] | str | None
    ) -> tuple[str, ...]:
        allowed = self._settings.allowed_warehouses
        if not allowed:
            # Tambien protege instancias Settings construidas a mano sin pasar
            # por from_env().
            raise AccessDeniedError("No hay almacenes permitidos configurados")
        values = _code_list(requested, "almacenes", maximum_items=100)
        if not values:
            return allowed
        allowed_set = set(allowed)
        unauthorized = [value for value in values if value not in allowed_set]
        if unauthorized:
            raise AccessDeniedError(
                "La consulta solicita uno o mas almacenes no autorizados"
            )
        return values

    def require_sale_context(
        self, *, company: str, warehouse: str, cash_register: str
    ) -> tuple[str, str, str]:
        """Valida el ambito minimo que debera usar cualquier venta futura."""

        self.require_scope("ventas:create")
        companies = self._settings.allowed_companies
        warehouses = self._settings.allowed_warehouses
        cash_registers = self._settings.allowed_cash_registers
        if not companies or not warehouses or not cash_registers:
            raise AccessDeniedError(
                "Crear ventas exige allowlists no vacias de empresa, almacen y caja"
            )
        company_code = _code(company, "empresa", maximum_length=100)
        warehouse_code = _code(warehouse, "almacen", maximum_length=100)
        cash_code = _code(cash_register, "caja", maximum_length=100)
        if (
            company_code not in companies
            or warehouse_code not in warehouses
            or cash_code not in cash_registers
        ):
            raise AccessDeniedError("Empresa, almacen o caja no autorizados")
        return company_code, warehouse_code, cash_code


def _code(value: Any, name: str, *, maximum_length: int) -> str:
    if not isinstance(value, str):
        raise ValidationError(f"{name} debe ser texto")
    cleaned = value.strip().upper()
    if not cleaned:
        raise ValidationError(f"{name} no puede estar vacio")
    if len(cleaned) > maximum_length:
        raise ValidationError(f"{name} supera {maximum_length} caracteres")
    if "," in cleaned or any(ord(char) < 32 or ord(char) == 127 for char in cleaned):
        raise ValidationError(f"{name} contiene caracteres no validos")
    return cleaned


def _optional_text(value: Any, name: str, *, maximum_length: int) -> str | None:
    if value is None:
        return None
    if not isinstance(value, str):
        raise ValidationError(f"{name} debe ser texto")
    cleaned = value.strip()
    if not cleaned:
        return None
    if len(cleaned) > maximum_length:
        raise ValidationError(f"{name} supera {maximum_length} caracteres")
    if "\x00" in cleaned or any(ord(char) < 32 and char not in "\t" for char in cleaned):
        raise ValidationError(f"{name} contiene caracteres no validos")
    return cleaned


def _code_list(
    values: Sequence[str] | str | None,
    name: str,
    *,
    maximum_items: int,
    maximum_length: int = 255,
) -> tuple[str, ...]:
    if values is None:
        return ()
    source: Iterable[Any]
    if isinstance(values, str):
        source = values.split(",")
    else:
        source = values
    result: list[str] = []
    seen: set[str] = set()
    for value in source:
        cleaned = _code(value, name, maximum_length=maximum_length)
        if cleaned not in seen:
            result.append(cleaned)
            seen.add(cleaned)
    if len(result) > maximum_items:
        raise ValidationError(f"{name} admite como maximo {maximum_items} valores")
    return tuple(result)


def _iso_date(value: Any, name: str, *, optional: bool = False) -> date | None:
    if value is None and optional:
        return None
    if isinstance(value, date) and not hasattr(value, "hour"):
        return value
    if not isinstance(value, str):
        raise ValidationError(f"{name} debe tener formato AAAA-MM-DD")
    try:
        # fromisoformat es estricto respecto a componentes y dias validos.
        parsed = date.fromisoformat(value)
    except ValueError as exc:
        raise ValidationError(f"{name} debe tener formato AAAA-MM-DD") from exc
    if value != parsed.isoformat():
        raise ValidationError(f"{name} debe tener formato AAAA-MM-DD")
    return parsed


def _integer(value: Any, name: str, minimum: int, maximum: int) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        raise ValidationError(f"{name} debe ser un entero")
    if not minimum <= value <= maximum:
        raise ValidationError(f"{name} debe estar entre {minimum} y {maximum}")
    return value


def _boolean(value: Any, name: str) -> bool:
    if not isinstance(value, bool):
        raise ValidationError(f"{name} debe ser booleano")
    return value


def _level(value: Any, name: str) -> str:
    if value is None:
        return ""
    if not isinstance(value, str):
        raise ValidationError(f"{name} debe ser texto")
    level = value.strip().upper()
    if level not in {"", "PRV", "FAM", "TMP", "ALM", "COL"}:
        raise ValidationError(
            f"{name} debe ser PRV, FAM, TMP, ALM, COL o vacio"
        )
    return level


_COST_FIELDS = {
    "coste_art",
    "imp_ent_tot",
    "imp_coste",
    "beneficio",
    "venta_ent",
    "pct_bnfco",
    "vent_ent",
    "margen1",
    "margen2",
    "pct_vlast",
}


def _lower_keys(row: dict[str, Any]) -> dict[str, Any]:
    return {str(key).lower(): value for key, value in row.items()}


class FactuzamService:
    def __init__(self, settings: Settings, repository: FactuzamRepository):
        self.settings = settings
        self.repository = repository
        self.access = StaticAccessPolicy(settings)

    def consultar_stock(
        self,
        *,
        articulo: str | None = None,
        sku: str | None = None,
        buscar: str | None = None,
        almacenes: Sequence[str] | str | None = None,
        solo_disponible: bool = False,
        incluir_inactivos: bool = False,
        pagina: int = 1,
        tamano_pagina: int = 100,
    ) -> dict[str, Any]:
        self.access.require_scope("stock:read")
        selected_warehouses = self.access.resolve_warehouses(almacenes)
        page = _integer(pagina, "pagina", 1, 1_000_000)
        page_size = _integer(
            tamano_pagina,
            "tamano_pagina",
            1,
            self.settings.max_stock_page_size,
        )
        if (page - 1) * page_size > self.settings.max_stock_offset:
            raise ValidationError(
                "La página solicitada supera el desplazamiento máximo de stock"
            )
        article = _optional_text(articulo, "articulo", maximum_length=20)
        sku_code = _optional_text(sku, "sku", maximum_length=50)
        search = _optional_text(buscar, "buscar", maximum_length=100)
        only_available = _boolean(solo_disponible, "solo_disponible")
        include_inactive = _boolean(incluir_inactivos, "incluir_inactivos")
        include_costs = self.access.has_scope("caja.verCoste")

        result = self.repository.consultar_stock(
            warehouses=selected_warehouses,
            article=article,
            sku_code=sku_code,
            search=search,
            only_available=only_available,
            include_inactive=include_inactive,
            page=page,
            page_size=page_size,
            include_costs=include_costs,
        )
        rows = [_lower_keys(dict(row)) for row in result.rows]
        if not include_costs:
            for row in rows:
                row.pop("valor_total", None)
                row.pop("precio_medio", None)
        last_item = min(page * page_size, result.total)
        return serialize(
            {
                "almacenes": list(selected_warehouses),
                "pagina": {
                    "numero": page,
                    "tamano": page_size,
                    "total_filas": result.total,
                    "hay_mas": last_item < result.total,
                },
                "stock": rows,
            }
        )

    def informe_movimientos_venta(
        self,
        *,
        fecha_desde: str | date,
        fecha_hasta: str | date,
        inicio_compras: str | date | None = None,
        almacenes: Sequence[str] | str | None = None,
        familias: Sequence[str] | str | None = None,
        proveedores: Sequence[str] | str | None = None,
        temporadas: Sequence[str] | str | None = None,
        articulos: Sequence[str] | str | None = None,
        nivel1: str = "",
        nivel2: str = "",
        nivel3: str = "",
        nivel_familia: int = 0,
        solo_ventas: bool = True,
        limite: int | None = None,
    ) -> dict[str, Any]:
        self.access.require_scope("ventas:read")
        date_from = _iso_date(fecha_desde, "fecha_desde")
        date_to = _iso_date(fecha_hasta, "fecha_hasta")
        assert date_from is not None and date_to is not None
        if date_from > date_to:
            raise ValidationError("fecha_desde no puede ser posterior a fecha_hasta")
        days = (date_to - date_from).days + 1
        if days > self.settings.max_report_days:
            raise ValidationError(
                f"El rango no puede superar {self.settings.max_report_days} dias"
            )
        purchases_from = _iso_date(
            inicio_compras, "inicio_compras", optional=True
        )
        if purchases_from is not None and purchases_from > date_to:
            raise ValidationError("inicio_compras no puede ser posterior a fecha_hasta")
        if (
            purchases_from is not None
            and (date_to - purchases_from).days + 1
            > self.settings.max_purchase_lookback_days
        ):
            raise ValidationError(
                "inicio_compras supera la antigüedad máxima configurada"
            )

        selected_warehouses = self.access.resolve_warehouses(almacenes)
        family_codes = _code_list(familias, "familias", maximum_items=100)
        supplier_codes = _code_list(
            proveedores, "proveedores", maximum_items=100
        )
        season_codes = _code_list(
            temporadas,
            "temporadas",
            maximum_items=100,
            maximum_length=255,
        )
        article_codes = _code_list(
            articulos,
            "articulos",
            maximum_items=200,
            maximum_length=20,
        )
        levels = (
            _level(nivel1, "nivel1"),
            _level(nivel2, "nivel2"),
            _level(nivel3, "nivel3"),
        )
        non_empty_levels = [level for level in levels if level]
        if len(non_empty_levels) != len(set(non_empty_levels)):
            raise ValidationError("Los niveles de agrupacion no pueden repetirse")
        family_group_level = _integer(
            nivel_familia, "nivel_familia", 0, 20
        )
        only_sales = _boolean(solo_ventas, "solo_ventas")
        row_limit = self.settings.max_report_rows if limite is None else _integer(
            limite, "limite", 1, self.settings.max_report_rows
        )

        result = self.repository.informe_movimientos_venta(
            date_from=date_from,
            date_to=date_to,
            purchases_from=purchases_from,
            warehouses=selected_warehouses,
            families=family_codes,
            suppliers=supplier_codes,
            seasons=season_codes,
            articles=article_codes,
            level1=levels[0],
            level2=levels[1],
            level3=levels[2],
            family_level=family_group_level,
            only_sales=only_sales,
            limit=row_limit,
        )
        rows = [_lower_keys(dict(row)) for row in result.rows]
        include_costs = self.access.has_scope("caja.verCoste")
        if not include_costs:
            for row in rows:
                for field in _COST_FIELDS:
                    row.pop(field, None)

        summary: dict[str, Any] = {
            "filas_devueltas": len(rows),
            "parcial": result.truncated,
            "unidades_entrada": decimal_text(sum_field(rows, "uni_ent_tot")),
            "unidades_vendidas": decimal_text(sum_field(rows, "uds_venta")),
            "importe_ventas": decimal_text(sum_field(rows, "imp_venta")),
        }
        if include_costs:
            summary.update(
                {
                    "importe_entrada": decimal_text(
                        sum_field(rows, "imp_ent_tot")
                    ),
                    "importe_coste": decimal_text(sum_field(rows, "imp_coste")),
                    "beneficio": decimal_text(sum_field(rows, "beneficio")),
                }
            )

        return serialize(
            {
                "criterios": {
                    "fecha_desde": date_from,
                    "fecha_hasta": date_to,
                    "inicio_compras": purchases_from,
                    "almacenes": list(selected_warehouses),
                    "niveles": list(levels),
                    "solo_ventas": only_sales,
                },
                "limite": row_limit,
                "resumen": summary,
                "movimientos": rows,
            }
        )


def build_service(settings: Settings | None = None) -> FactuzamService:
    configured = Settings.from_env() if settings is None else settings
    database = Database(configured)
    repository = FactuzamRepository(database)
    return FactuzamService(configured, repository)


__all__ = [
    "AccessDeniedError",
    "FactuzamService",
    "FactuzamServiceError",
    "StaticAccessPolicy",
    "ValidationError",
    "build_service",
]
