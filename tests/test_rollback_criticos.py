"""Pruebas de rollback real sobre los cuatro flujos críticos."""

from __future__ import annotations

import os
import unittest
import uuid

import pymysql


class RollbackEsperado(Exception):
    """Fallo controlado que obliga al coordinador de prueba a deshacer."""


class PruebasRollbackCriticos(unittest.TestCase):
    CASOS = {
        "materializacion": (
            "fza_compras_sesiones",
            ("SERIE_SES", "NUMERO_SES"),
        ),
        "facturacion": (
            "fza_facturas",
            ("NUMERO_FAC", "SERIE_FAC"),
        ),
        "caja": (
            "fza_caja_operaciones",
            ("ID_OPCAJA",),
        ),
        "movimientos": (
            "fza_movimientos_almacen",
            ("NUMERO_MOV",),
        ),
    }

    @classmethod
    def setUpClass(cls) -> None:
        clave = os.getenv("FACTUZAM_TEST_DB_PASSWORD")
        if clave is None:
            raise unittest.SkipTest(
                "Falta FACTUZAM_TEST_DB_PASSWORD para la integración."
            )
        cls.conexion = pymysql.connect(
            host=os.getenv("FACTUZAM_TEST_DB_HOST", "127.0.0.1"),
            port=int(os.getenv("FACTUZAM_TEST_DB_PORT", "3306")),
            user=os.getenv("FACTUZAM_TEST_DB_USER", "root"),
            password=clave,
            database=os.getenv("FACTUZAM_TEST_DB_NAME", "factuzam_test"),
            charset="utf8mb4",
            autocommit=True,
        )

    @classmethod
    def tearDownClass(cls) -> None:
        cls.conexion.close()

    def _probar_rollback(
        self,
        tabla: str,
        columnas_clave: tuple[str, ...],
    ) -> None:
        columnas_sql = ", ".join(
            f"`{columna}`"
            for columna in columnas_clave
        )
        condiciones_sql = " AND ".join(
            f"`{columna}` <=> %s"
            for columna in columnas_clave
        )
        marca = "ROLLBACK_" + uuid.uuid4().hex[:20]
        with self.conexion.cursor() as cursor:
            cursor.execute(f"SHOW TABLE STATUS LIKE %s", (tabla,))
            estado_tabla = cursor.fetchone()
            self.assertIsNotNone(estado_tabla)
            self.assertEqual("InnoDB", estado_tabla[1])
            cursor.execute(
                f"SELECT {columnas_sql}, `USUARIO_MODIF` "
                f"FROM `{tabla}` ORDER BY {columnas_sql} LIMIT 1"
            )
            fila = cursor.fetchone()
            if fila is None:
                self.skipTest(f"La tabla {tabla} no contiene datos.")
            valores_clave = fila[: len(columnas_clave)]
            usuario_original = fila[-1]
        try:
            self.conexion.begin()
            with self.conexion.cursor() as cursor:
                cursor.execute(
                    f"SELECT `USUARIO_MODIF` FROM `{tabla}` "
                    f"WHERE {condiciones_sql} FOR UPDATE",
                    valores_clave,
                )
                self.assertIsNotNone(cursor.fetchone())
                cursor.execute(
                    f"UPDATE `{tabla}` SET `USUARIO_MODIF` = %s "
                    f"WHERE {condiciones_sql}",
                    (marca, *valores_clave),
                )
                self.assertEqual(1, cursor.rowcount)
                cursor.execute(
                    f"SELECT `USUARIO_MODIF` FROM `{tabla}` "
                    f"WHERE {condiciones_sql}",
                    valores_clave,
                )
                self.assertEqual(marca, cursor.fetchone()[0])
            raise RollbackEsperado
        except RollbackEsperado:
            self.conexion.rollback()
        except Exception:
            self.conexion.rollback()
            raise
        with self.conexion.cursor() as cursor:
            cursor.execute(
                f"SELECT `USUARIO_MODIF` FROM `{tabla}` "
                f"WHERE {condiciones_sql}",
                valores_clave,
            )
            self.assertEqual(usuario_original, cursor.fetchone()[0])

    def test_materializacion_deshace_cambio_parcial(self) -> None:
        self._probar_rollback(*self.CASOS["materializacion"])

    def test_facturacion_deshace_cambio_parcial(self) -> None:
        self._probar_rollback(*self.CASOS["facturacion"])

    def test_caja_deshace_cambio_parcial(self) -> None:
        self._probar_rollback(*self.CASOS["caja"])

    def test_movimientos_deshace_cambio_parcial(self) -> None:
        self._probar_rollback(*self.CASOS["movimientos"])


if __name__ == "__main__":
    unittest.main()
