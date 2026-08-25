from __future__ import annotations

import unittest
from unittest.mock import patch

from factuzam_mcp.config import ConfigError, Settings


BASE_ENV = {
    "FACTUZAM_DB_HOST": "db.internal",
    "FACTUZAM_DB_PORT": "3307",
    "FACTUZAM_DB_NAME": "factuzam",
    "FACTUZAM_DB_USER": "mcp_factuzam_ro",
    "FACTUZAM_DB_PASSWORD": "un-secreto-inyectado",
    "FACTUZAM_ALMACENES_PERMITIDOS": "alm-1, alm-2",
}


class SettingsTests(unittest.TestCase):
    def test_from_env_requires_database_values_and_warehouse_allowlist(self) -> None:
        required = (
            "FACTUZAM_DB_NAME",
            "FACTUZAM_DB_USER",
            "FACTUZAM_DB_PASSWORD",
            "FACTUZAM_ALMACENES_PERMITIDOS",
        )
        for name in required:
            with self.subTest(name=name):
                env = dict(BASE_ENV)
                env.pop(name)
                with self.assertRaises(ConfigError):
                    Settings.from_env(env)

    def test_from_env_normalizes_allowlists_and_keeps_scopes_deny_by_default(
        self,
    ) -> None:
        settings = Settings.from_env(BASE_ENV)

        self.assertEqual(settings.allowed_warehouses, ("ALM-1", "ALM-2"))
        self.assertEqual(settings.allowed_companies, ())
        self.assertEqual(settings.allowed_cash_registers, ())
        self.assertEqual(settings.scopes, frozenset())
        self.assertEqual(settings.db_port, 3307)
        self.assertEqual(settings.max_stock_offset, 50_000)
        self.assertEqual(settings.max_purchase_lookback_days, 3_650)

    def test_from_env_parses_scopes_and_all_context_allowlists(self) -> None:
        env = {
            **BASE_ENV,
            "FACTUZAM_EMPRESAS_PERMITIDAS": "emp1,EMP1, emp2",
            "FACTUZAM_CAJAS_PERMITIDAS": "c1, c2",
            "FACTUZAM_MCP_SCOPES": "stock:read, ventas:read, caja.verCoste",
        }
        settings = Settings.from_env(env)

        self.assertEqual(settings.allowed_companies, ("EMP1", "EMP2"))
        self.assertEqual(settings.allowed_cash_registers, ("C1", "C2"))
        self.assertEqual(
            settings.scopes,
            frozenset({"stock:read", "ventas:read", "caja.verCoste"}),
        )

    def test_rejects_root_even_with_password(self) -> None:
        env = {**BASE_ENV, "FACTUZAM_DB_USER": "ROOT"}
        with self.assertRaisesRegex(ConfigError, "no puede ser root"):
            Settings.from_env(env)

    def test_password_never_appears_in_repr(self) -> None:
        secret = "  secreto-con-espacios  "
        settings = Settings.from_env(
            {**BASE_ENV, "FACTUZAM_DB_PASSWORD": secret}
        )
        self.assertEqual(settings.db_password, secret)
        self.assertNotIn(secret, repr(settings))

    @patch("factuzam_mcp.config.read_windows_generic_credential")
    def test_can_load_password_from_windows_credential_store(self, read) -> None:
        read.return_value = "secreto-desde-windows"
        env = dict(BASE_ENV)
        env.pop("FACTUZAM_DB_PASSWORD")
        env["FACTUZAM_DB_CREDENTIAL_TARGET"] = "Factuzam/MCP/lectura"

        settings = Settings.from_env(env)

        self.assertEqual(settings.db_password, "secreto-desde-windows")
        read.assert_called_once_with("Factuzam/MCP/lectura")

    def test_rejects_two_password_sources(self) -> None:
        with self.assertRaisesRegex(ConfigError, "no ambas"):
            Settings.from_env(
                {
                    **BASE_ENV,
                    "FACTUZAM_DB_CREDENTIAL_TARGET": "Factuzam/MCP/lectura",
                }
            )

    def test_rejects_invalid_port_timeout_scope_and_code(self) -> None:
        invalid_cases = (
            ("FACTUZAM_DB_PORT", "0"),
            ("FACTUZAM_DB_READ_TIMEOUT", "not-a-number"),
            ("FACTUZAM_MCP_SCOPES", "stock read"),
            ("FACTUZAM_ALMACENES_PERMITIDOS", "ALM1,mal\nvalor"),
            ("FACTUZAM_MCP_MAX_STOCK_OFFSET", "-1"),
            ("FACTUZAM_MCP_MAX_PURCHASE_LOOKBACK_DAYS", "0"),
        )
        for name, value in invalid_cases:
            with self.subTest(name=name):
                with self.assertRaises(ConfigError):
                    Settings.from_env({**BASE_ENV, name: value})


if __name__ == "__main__":
    unittest.main()
