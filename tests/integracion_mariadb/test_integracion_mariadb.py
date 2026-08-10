"""Pruebas IA-S30 contra un servidor MariaDB real y desechable."""

from __future__ import annotations

import contextlib
import os
import re
import sys
import time
import unittest
import uuid
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from decimal import Decimal
from pathlib import Path

import pymysql


RAIZ_REPOSITORIO = Path(__file__).resolve().parents[2]
RAIZ_HISTORICA = RAIZ_REPOSITORIO.parent / "factuzam_web"
PATRON_ESQUEMA = re.compile(r"^fzam_it_[0-9a-f]{8}_[0-9a-f]{12}$")


@dataclass(frozen=True)
class ConfiguracionMariaDb:
    host: str
    port: int
    user: str
    password: str

    @classmethod
    def desde_entorno(cls) -> "ConfiguracionMariaDb":
        if os.environ.get("FACTUZAM_TEST_DB_ALLOW_DISPOSABLE") != "SI":
            raise RuntimeError(
                "FACTUZAM_TEST_DB_ALLOW_DISPOSABLE debe valer SI."
            )
        nombres = (
            "FACTUZAM_TEST_DB_HOST",
            "FACTUZAM_TEST_DB_PORT",
            "FACTUZAM_TEST_DB_USER",
            "FACTUZAM_TEST_DB_PASSWORD",
        )
        ausentes = [nombre for nombre in nombres if nombre not in os.environ]
        if ausentes:
            raise RuntimeError(
                "Faltan variables de entorno: " + ", ".join(ausentes)
            )
        return cls(
            host=os.environ["FACTUZAM_TEST_DB_HOST"],
            port=int(os.environ["FACTUZAM_TEST_DB_PORT"]),
            user=os.environ["FACTUZAM_TEST_DB_USER"],
            password=os.environ["FACTUZAM_TEST_DB_PASSWORD"],
        )

    def conectar(
        self,
        database: str | None = None,
        autocommit: bool = True,
    ) -> pymysql.Connection:
        parametros = {
            "host": self.host,
            "port": self.port,
            "user": self.user,
            "password": self.password,
            "charset": "utf8mb4",
            "autocommit": autocommit,
            "connect_timeout": 5,
            "read_timeout": 15,
            "write_timeout": 15,
        }
        if database is not None:
            parametros["database"] = database
        return pymysql.connect(**parametros)


class EsquemaDesechable:
    def __init__(self, configuracion: ConfiguracionMariaDb) -> None:
        self.configuracion = configuracion
        ejecucion = os.environ.get(
            "FACTUZAM_TEST_DB_RUN_ID",
            uuid.uuid4().hex[:8],
        ).lower()
        if not re.fullmatch(r"[0-9a-f]{8}", ejecucion):
            raise RuntimeError("FACTUZAM_TEST_DB_RUN_ID no es seguro.")
        self.nombre = f"fzam_it_{ejecucion}_{uuid.uuid4().hex[:12]}"

    def __enter__(self) -> str:
        self._validar_nombre()
        with contextlib.closing(self.configuracion.conectar()) as conexion:
            with conexion.cursor() as cursor:
                cursor.execute(
                    f"CREATE DATABASE `{self.nombre}` "
                    "CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci"
                )
        return self.nombre

    def __exit__(self, exc_type, exc_value, traceback) -> None:
        self.eliminar()

    def eliminar(self) -> None:
        self._validar_nombre()
        with contextlib.closing(self.configuracion.conectar()) as conexion:
            with conexion.cursor() as cursor:
                cursor.execute(f"DROP DATABASE IF EXISTS `{self.nombre}`")

    def _validar_nombre(self) -> None:
        if not PATRON_ESQUEMA.fullmatch(self.nombre):
            raise RuntimeError(
                f"Se rechazó operar sobre un esquema inesperado: {self.nombre}"
            )


def dividir_script_sql(contenido: str) -> list[str]:
    """Divide scripts MariaDB respetando las directivas DELIMITER."""
    delimitador = ";"
    acumulado: list[str] = []
    sentencias: list[str] = []
    for linea in contenido.splitlines():
        limpia = linea.strip()
        if limpia.upper().startswith("DELIMITER "):
            if any(parte.strip() for parte in acumulado):
                raise ValueError("DELIMITER apareció dentro de una sentencia.")
            delimitador = limpia.split(maxsplit=1)[1]
            continue
        acumulado.append(linea)
        if limpia.endswith(delimitador):
            sentencia = "\n".join(acumulado).rstrip()
            sentencia = sentencia[: -len(delimitador)].rstrip()
            if sentencia:
                sentencias.append(sentencia)
            acumulado.clear()
    if any(parte.strip() for parte in acumulado):
        raise ValueError("El script termina con una sentencia incompleta.")
    return sentencias


def rutas_migraciones_ia_s01() -> list[Path]:
    configuradas = os.environ.get("FACTUZAM_IA_S01_MIGRATIONS")
    if configuradas:
        rutas = [Path(valor) for valor in configuradas.split(os.pathsep)]
    else:
        desarrollos = RAIZ_HISTORICA / "DESARROLLOS EN CURSO"
        rutas = [
            desarrollos / "albaranes_facturacion_procs.sql",
            desarrollos / "pedidos_albaran_procs.sql",
        ]
    for ruta in rutas:
        if not ruta.is_file():
            raise FileNotFoundError(f"Falta la migración real IA-S01: {ruta}")
    if len(rutas) != 2:
        raise RuntimeError("IA-S01 debe aportar exactamente dos migraciones.")
    return rutas


def ruta_migracion_verifactu() -> Path:
    configurada = os.environ.get("FACTUZAM_VERIFACTU_MIGRATION")
    ruta = (
        Path(configurada)
        if configurada
        else RAIZ_HISTORICA
        / "DESARROLLOS EN CURSO"
        / "verifactu_cola.sql"
    )
    if not ruta.is_file():
        raise FileNotFoundError(
            f"Falta la migración real de la cola VeriFactu: {ruta}"
        )
    return ruta


class PruebaMariaDbBase(unittest.TestCase):
    configuracion: ConfiguracionMariaDb
    esquema: EsquemaDesechable
    nombre_esquema: str
    conexion: pymysql.Connection

    @classmethod
    def setUpClass(cls) -> None:
        cls.configuracion = ConfiguracionMariaDb.desde_entorno()
        with contextlib.closing(cls.configuracion.conectar()) as conexion:
            with conexion.cursor() as cursor:
                cursor.execute("SELECT VERSION(), @@version_comment")
                version, comentario = cursor.fetchone()
        if "MariaDB" not in f"{version} {comentario}":
            raise RuntimeError("La suite IA-S30 requiere MariaDB real.")

    def setUp(self) -> None:
        self.esquema = EsquemaDesechable(self.configuracion)
        self.nombre_esquema = self.esquema.__enter__()
        try:
            self.conexion = self.configuracion.conectar(self.nombre_esquema)
        except BaseException:
            self.esquema.eliminar()
            raise

    def tearDown(self) -> None:
        try:
            if hasattr(self, "conexion"):
                self.conexion.close()
        finally:
            if hasattr(self, "esquema"):
                self.esquema.eliminar()

    def ejecutar_script(self, ruta: Path) -> None:
        contenido = ruta.read_text(encoding="utf-8-sig")
        with self.conexion.cursor() as cursor:
            for sentencia in dividir_script_sql(contenido):
                cursor.execute(sentencia)
                while cursor.nextset():
                    pass

    def valor_escalar(self, sql: str, parametros=None):
        with self.conexion.cursor() as cursor:
            cursor.execute(sql, parametros)
            return cursor.fetchone()[0]


class PruebasIntegracionMariaDb(PruebaMariaDbBase):
    def test_01_migraciones_ia_s01_son_idempotentes(self) -> None:
        with self.conexion.cursor() as cursor:
            cursor.execute(
                "CREATE TABLE fza_albaranes ("
                "ID int NOT NULL PRIMARY KEY, "
                "TOTAL_IMPUESTOS_ALB decimal(18,6) NULL, "
                "CODIGO_ALM_ALB varchar(10) NULL) ENGINE=InnoDB"
            )
            cursor.execute(
                "CREATE TABLE fza_albaranes_lineas ("
                "ID int NOT NULL PRIMARY KEY) ENGINE=InnoDB"
            )
            cursor.execute(
                "CREATE TABLE fza_almacenes ("
                "CODIGO_ALM_ALM varchar(10) NOT NULL PRIMARY KEY, "
                "NOMBRE_ALM_ALM varchar(100) NULL) ENGINE=InnoDB"
            )
        migraciones = rutas_migraciones_ia_s01()
        for ruta in migraciones:
            self.ejecutar_script(ruta)
        huella_primera = self._huella_ia_s01()
        for ruta in migraciones:
            self.ejecutar_script(ruta)
        self.assertEqual(huella_primera, self._huella_ia_s01())
        columnas = {
            fila[0]: fila[1]
            for fila in huella_primera[0]
            if fila[0]
            in {"PORCENTAJE_RETENCION_ALB", "TOTAL_RETENCION_ALB"}
        }
        self.assertEqual("decimal(19,6)", columnas["PORCENTAJE_RETENCION_ALB"])
        self.assertEqual("decimal(18,6)", columnas["TOTAL_RETENCION_ALB"])
        self.assertEqual(6, len(huella_primera[1]))

    def _huella_ia_s01(self):
        with self.conexion.cursor() as cursor:
            cursor.execute(
                "SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, "
                "COALESCE(COLUMN_DEFAULT, '<NULL>') "
                "FROM information_schema.COLUMNS "
                "WHERE TABLE_SCHEMA = DATABASE() "
                "AND TABLE_NAME IN ('fza_albaranes', "
                "'fza_albaranes_lineas') ORDER BY TABLE_NAME, ORDINAL_POSITION"
            )
            columnas = cursor.fetchall()
            cursor.execute(
                "SELECT ROUTINE_NAME, ROUTINE_DEFINITION "
                "FROM information_schema.ROUTINES "
                "WHERE ROUTINE_SCHEMA = DATABASE() "
                "AND ROUTINE_NAME LIKE 'PRC\\_%\\_CREAR\\_%' "
                "ORDER BY ROUTINE_NAME"
            )
            procedimientos = cursor.fetchall()
            cursor.execute(
                "SELECT VIEW_DEFINITION FROM information_schema.VIEWS "
                "WHERE TABLE_SCHEMA = DATABASE() "
                "AND TABLE_NAME = 'vi_albaranes'"
            )
            vista = cursor.fetchone()
        self.assertIsNotNone(vista)
        return columnas, procedimientos, vista

    def test_02_commit_y_fallo_entre_cabecera_y_lineas(self) -> None:
        with self.conexion.cursor() as cursor:
            cursor.execute(
                "CREATE TABLE fza_it_documentos ("
                "SERIE varchar(20) NOT NULL, NUMERO varchar(20) NOT NULL, "
                "DESCRIPCION varchar(100) NOT NULL, "
                "TOTAL decimal(18,6) NOT NULL, "
                "PRIMARY KEY (SERIE, NUMERO)) ENGINE=InnoDB"
            )
            cursor.execute(
                "CREATE TABLE fza_it_documentos_lineas ("
                "SERIE varchar(20) NOT NULL, NUMERO varchar(20) NOT NULL, "
                "LINEA varchar(4) NOT NULL, CANTIDAD decimal(19,6) NOT NULL, "
                "PRIMARY KEY (SERIE, NUMERO, LINEA), "
                "FOREIGN KEY (SERIE, NUMERO) REFERENCES "
                "fza_it_documentos (SERIE, NUMERO)) ENGINE=InnoDB"
            )
        self.conexion.begin()
        with self.conexion.cursor() as cursor:
            cursor.execute(
                "INSERT INTO fza_it_documentos VALUES (%s, %s, %s, %s)",
                ("A", "1", "Artículo ñ", Decimal("12.345678")),
            )
            cursor.execute(
                "INSERT INTO fza_it_documentos_lineas VALUES "
                "(%s, %s, %s, %s)",
                ("A", "1", "0010", Decimal("1.250000")),
            )
        self.conexion.commit()
        with self.conexion.cursor() as cursor:
            cursor.execute(
                "SELECT DESCRIPCION, TOTAL FROM fza_it_documentos "
                "WHERE SERIE = 'A' AND NUMERO = '1'"
            )
            self.assertEqual(("Artículo ñ", Decimal("12.345678")), cursor.fetchone())
        self.conexion.begin()
        try:
            with self.conexion.cursor() as cursor:
                cursor.execute(
                    "INSERT INTO fza_it_documentos VALUES "
                    "('A', '2', 'Debe revertirse', 9.5)"
                )
                cursor.execute(
                    "INSERT INTO fza_it_documentos_lineas VALUES "
                    "('A', '2', '0010', 1)"
                )
                cursor.execute(
                    "INSERT INTO fza_it_documentos_lineas VALUES "
                    "('A', '2', '0020', NULL)"
                )
            self.fail("MariaDB aceptó una línea inválida.")
        except pymysql.IntegrityError:
            self.conexion.rollback()
        self.assertEqual(
            0,
            self.valor_escalar(
                "SELECT COUNT(*) FROM fza_it_documentos WHERE NUMERO = '2'"
            ),
        )
        self.assertEqual(
            0,
            self.valor_escalar(
                "SELECT COUNT(*) FROM fza_it_documentos_lineas "
                "WHERE NUMERO = '2'"
            ),
        )

    def test_03_contador_serializa_accesos_concurrentes(self) -> None:
        with self.conexion.cursor() as cursor:
            cursor.execute(
                "CREATE TABLE fza_facturas ("
                "SERIE_FAC varchar(20) NOT NULL, "
                "NUMERO_FAC varchar(20) NOT NULL, "
                "CONTADOR_LINEAS_FAC varchar(8) NOT NULL DEFAULT '00000000', "
                "PRIMARY KEY (SERIE_FAC, NUMERO_FAC)) ENGINE=InnoDB"
            )
            cursor.execute(
                "INSERT INTO fza_facturas VALUES ('A', '1', '00000000')"
            )

        def siguiente() -> int:
            conexion = self.configuracion.conectar(
                self.nombre_esquema,
                autocommit=False,
            )
            try:
                conexion.begin()
                with conexion.cursor() as cursor:
                    cursor.execute(
                        "SELECT CAST(CONTADOR_LINEAS_FAC AS UNSIGNED) "
                        "FROM fza_facturas WHERE SERIE_FAC = 'A' "
                        "AND NUMERO_FAC = '1' FOR UPDATE"
                    )
                    valor = int(cursor.fetchone()[0]) + 10
                    time.sleep(0.01)
                    cursor.execute(
                        "UPDATE fza_facturas SET CONTADOR_LINEAS_FAC = %s "
                        "WHERE SERIE_FAC = 'A' AND NUMERO_FAC = '1'",
                        (f"{valor:08d}",),
                    )
                conexion.commit()
                return valor
            except BaseException:
                conexion.rollback()
                raise
            finally:
                conexion.close()

        with ThreadPoolExecutor(max_workers=6) as ejecutor:
            resultados = list(ejecutor.map(lambda _: siguiente(), range(12)))
        self.assertEqual(list(range(10, 121, 10)), sorted(resultados))
        self.assertEqual(
            "00000120",
            self.valor_escalar(
                "SELECT CONTADOR_LINEAS_FAC FROM fza_facturas "
                "WHERE SERIE_FAC = 'A' AND NUMERO_FAC = '1'"
            ),
        )

    def test_04_cola_verifactu_comparte_transaccion_y_reencola(self) -> None:
        with self.conexion.cursor() as cursor:
            cursor.execute(
                "CREATE TABLE fza_facturas ("
                "SERIE_FAC varchar(20) NOT NULL, "
                "NUMERO_FAC varchar(20) NOT NULL, "
                "FASE_FAC varchar(30) NULL, "
                "INSTANTE_MODIF datetime NULL, USUARIO_MODIF varchar(50) NULL, "
                "PRIMARY KEY (SERIE_FAC, NUMERO_FAC)) ENGINE=InnoDB"
            )
        self.ejecutar_script(ruta_migracion_verifactu())
        self.conexion.begin()
        with self.conexion.cursor() as cursor:
            cursor.execute(
                "INSERT INTO fza_facturas VALUES "
                "('A', '1', 'BORRADOR', NULL, NULL)"
            )
            self._encolar(cursor, "A", "1")
            cursor.execute(
                "UPDATE fza_facturas SET FASE_FAC = 'VERIFACTU_PENDIENTE' "
                "WHERE SERIE_FAC = 'A' AND NUMERO_FAC = '1'"
            )
        self.conexion.commit()
        with self.conexion.cursor() as cursor:
            cursor.execute(
                "UPDATE fza_verifactu_cola SET ESTADO_VFCOLA = 'ERROR', "
                "CONTADOR_INTENTOS_VFCOLA = 3, "
                "INSTANTE_PROXIMO_INTENTO_VFCOLA = NOW(), "
                "MENSAJE_ERROR_VFCOLA = 'temporal'"
            )
            self._encolar(cursor, "A", "1")
            cursor.execute(
                "SELECT ESTADO_VFCOLA, CONTADOR_INTENTOS_VFCOLA, "
                "INSTANTE_PROXIMO_INTENTO_VFCOLA, MENSAJE_ERROR_VFCOLA "
                "FROM fza_verifactu_cola"
            )
            self.assertEqual(("PENDIENTE", 0, None, None), cursor.fetchone())
        self.conexion.begin()
        try:
            with self.conexion.cursor() as cursor:
                cursor.execute(
                    "INSERT INTO fza_facturas VALUES "
                    "('A', '2', 'BORRADOR', NULL, NULL)"
                )
                self._encolar(cursor, "A", "2")
                raise RuntimeError("fallo después de encolar")
        except RuntimeError:
            self.conexion.rollback()
        self.assertEqual(
            0,
            self.valor_escalar(
                "SELECT COUNT(*) FROM fza_facturas WHERE NUMERO_FAC = '2'"
            ),
        )
        self.assertEqual(
            0,
            self.valor_escalar(
                "SELECT COUNT(*) FROM fza_verifactu_cola "
                "WHERE NUMERO_FAC_VFCOLA = '2'"
            ),
        )

    @staticmethod
    def _encolar(cursor, serie: str, numero: str) -> None:
        cursor.execute(
            "INSERT INTO fza_verifactu_cola "
            "(SERIE_FAC_VFCOLA, NUMERO_FAC_VFCOLA, "
            "TIPO_OPERACION_VFCOLA, ESTADO_VFCOLA, "
            "CONTADOR_INTENTOS_VFCOLA, INSTANTE_ALTA, USUARIO_ALTA) "
            "VALUES (%s, %s, 'ALTA', 'PENDIENTE', 0, NOW(), 'IA-S30') "
            "ON DUPLICATE KEY UPDATE ESTADO_VFCOLA = 'PENDIENTE', "
            "CONTADOR_INTENTOS_VFCOLA = 0, "
            "INSTANTE_PROXIMO_INTENTO_VFCOLA = NULL, "
            "MENSAJE_ERROR_VFCOLA = NULL, INSTANTE_MODIF = NOW(), "
            "USUARIO_MODIF = 'IA-S30'",
            (serie, numero),
        )

    def test_05_operacion_y_pago_de_caja_son_atomicos(self) -> None:
        with self.conexion.cursor() as cursor:
            cursor.execute(
                "CREATE TABLE fza_caja_operaciones ("
                "CODIGO_EMP_OPCAJA varchar(10) NOT NULL, "
                "CODIGO_ALM_OPCAJA varchar(10) NOT NULL, "
                "CODIGO_CAJA_OPCAJA varchar(10) NOT NULL, "
                "NUMERO_OPERACION_OPCAJA varchar(20) NOT NULL, "
                "TIPO_OPERACION_OPCAJA varchar(5) NOT NULL, "
                "IMPORTE_TOTAL_OPCAJA decimal(18,6) NOT NULL, "
                "FECHA_OPERACION_OPCAJA datetime NOT NULL, "
                "USUARIO_ALTA varchar(50) NOT NULL, "
                "PRIMARY KEY (CODIGO_EMP_OPCAJA, CODIGO_ALM_OPCAJA, "
                "CODIGO_CAJA_OPCAJA, NUMERO_OPERACION_OPCAJA)) ENGINE=InnoDB"
            )
            cursor.execute(
                "CREATE TABLE fza_caja_pagos ("
                "CODIGO_EMP_PAGO varchar(10) NOT NULL, "
                "CODIGO_ALM_PAGO varchar(10) NOT NULL, "
                "CODIGO_CAJA_PAGO varchar(10) NOT NULL, "
                "NUMERO_OPERACION_PAGO varchar(20) NOT NULL, "
                "NUMERO_LINEA_PAGO int NOT NULL, CODIGO_FP_CFP varchar(10) NOT NULL, "
                "IMPORTE_ENTREGADO_PAGO decimal(18,6) NOT NULL, "
                "PRIMARY KEY (CODIGO_EMP_PAGO, CODIGO_ALM_PAGO, "
                "CODIGO_CAJA_PAGO, NUMERO_OPERACION_PAGO, NUMERO_LINEA_PAGO), "
                "FOREIGN KEY (CODIGO_EMP_PAGO, CODIGO_ALM_PAGO, "
                "CODIGO_CAJA_PAGO, NUMERO_OPERACION_PAGO) REFERENCES "
                "fza_caja_operaciones (CODIGO_EMP_OPCAJA, CODIGO_ALM_OPCAJA, "
                "CODIGO_CAJA_OPCAJA, NUMERO_OPERACION_OPCAJA)) ENGINE=InnoDB"
            )
        self._guardar_operacion_caja("1", False)
        self.assertEqual(
            Decimal("15.250000"),
            self.valor_escalar(
                "SELECT IMPORTE_ENTREGADO_PAGO FROM fza_caja_pagos "
                "WHERE NUMERO_OPERACION_PAGO = '1'"
            ),
        )
        with self.assertRaises(pymysql.IntegrityError):
            self._guardar_operacion_caja("2", True)
        self.assertEqual(
            0,
            self.valor_escalar(
                "SELECT COUNT(*) FROM fza_caja_operaciones "
                "WHERE NUMERO_OPERACION_OPCAJA = '2'"
            ),
        )

    def _guardar_operacion_caja(self, numero: str, forzar_fallo: bool) -> None:
        self.conexion.begin()
        try:
            with self.conexion.cursor() as cursor:
                cursor.execute(
                    "INSERT INTO fza_caja_operaciones VALUES "
                    "('EMP', 'ALM', 'CAJA', %s, 'GC', %s, NOW(), 'IA-S30')",
                    (numero, Decimal("15.250000")),
                )
                forma_pago = None if forzar_fallo else "EFE"
                cursor.execute(
                    "INSERT INTO fza_caja_pagos VALUES "
                    "('EMP', 'ALM', 'CAJA', %s, 1, %s, %s)",
                    (numero, forma_pago, Decimal("15.250000")),
                )
            self.conexion.commit()
        except BaseException:
            self.conexion.rollback()
            raise

    def test_06_limpia_esquema_aunque_falle_una_asercion(self) -> None:
        esquema_secundario = EsquemaDesechable(self.configuracion)
        nombre = esquema_secundario.nombre
        try:
            with esquema_secundario:
                raise AssertionError("fallo deliberado para probar finally")
        except AssertionError:
            pass
        with contextlib.closing(self.configuracion.conectar()) as conexion:
            with conexion.cursor() as cursor:
                cursor.execute(
                    "SELECT COUNT(*) FROM information_schema.SCHEMATA "
                    "WHERE SCHEMA_NAME = %s",
                    (nombre,),
                )
                self.assertEqual(0, cursor.fetchone()[0])


if __name__ == "__main__":
    unittest.main(verbosity=2)
