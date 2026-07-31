"""Exporta un idioma de fza_traducciones como SQL descargable."""

from __future__ import annotations

import argparse
import os
from pathlib import Path

import pymysql


USUARIO_GENERACION = "D26"
TAMANO_BLOQUE = 400


def argumentos() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--idioma", required=True)
    parser.add_argument("--salida", required=True, type=Path)
    parser.add_argument("--servidor", default="127.0.0.1")
    parser.add_argument("--puerto", default=3306, type=int)
    parser.add_argument("--usuario", default="root")
    parser.add_argument("--base-datos", default="factuzam")
    parser.add_argument("--aplicar", action="store_true")
    return parser.parse_args()


def conectar(opciones: argparse.Namespace):
    clave = os.environ.get("FACTUZAM_DB_PASSWORD")
    if clave is None:
        raise RuntimeError("Falta la variable FACTUZAM_DB_PASSWORD.")
    return pymysql.connect(
        host=opciones.servidor,
        port=opciones.puerto,
        user=opciones.usuario,
        password=clave,
        database=opciones.base_datos,
        charset="utf8mb4",
        autocommit=False,
    )


def cargar_catalogo(conexion, idioma: str) -> list[tuple]:
    consulta = """
SELECT CLAVE_TRAD, TEXTO_TRAD, CONTEXTO_TRAD, ESACTIVO_TRAD
  FROM fza_traducciones
 WHERE IDIOMA_TRAD = %s
 ORDER BY CLAVE_TRAD
"""
    with conexion.cursor() as cursor:
        cursor.execute(consulta, (idioma,))
        return list(cursor.fetchall())


def valor_hexadecimal(valor: str | None) -> str:
    if valor is None:
        return "NULL"
    return "CONVERT(0x" + valor.encode("utf-8").hex() + " USING utf8mb4)"


def escribir_sql(
    ruta: Path,
    idioma: str,
    catalogo: list[tuple],
) -> None:
    lineas = [
        f"-- D26: catalogo descargable {idioma}.",
        "-- Generado desde fza_traducciones; no editar a mano.",
        "START TRANSACTION;",
    ]
    for inicio in range(0, len(catalogo), TAMANO_BLOQUE):
        bloque = catalogo[inicio:inicio + TAMANO_BLOQUE]
        lineas.extend(
            [
                "INSERT INTO fza_traducciones (",
                "  CLAVE_TRAD, IDIOMA_TRAD, TEXTO_TRAD, CONTEXTO_TRAD,",
                "  ESACTIVO_TRAD, ESDESCARGADA_TRAD,",
                "  INSTANTE_ALTA, USUARIO_ALTA",
                ") VALUES",
            ]
        )
        for indice, fila in enumerate(bloque):
            clave, texto, contexto, activo = fila
            separador = "," if indice < len(bloque) - 1 else ""
            lineas.extend(
                [
                    f"  ({valor_hexadecimal(clave)},",
                    f"   {valor_hexadecimal(idioma)},",
                    f"   {valor_hexadecimal(texto)},",
                    f"   {valor_hexadecimal(contexto)},",
                    f"   {valor_hexadecimal(activo)}, 'S',",
                    "   CURRENT_TIMESTAMP,",
                    f"   '{USUARIO_GENERACION}'){separador}",
                ]
            )
        lineas.extend(
            [
                "ON DUPLICATE KEY UPDATE",
                "  TEXTO_TRAD = VALUES(TEXTO_TRAD),",
                "  CONTEXTO_TRAD = VALUES(CONTEXTO_TRAD),",
                "  ESACTIVO_TRAD = VALUES(ESACTIVO_TRAD),",
                "  ESDESCARGADA_TRAD = 'S',",
                "  INSTANTE_MODIF = CURRENT_TIMESTAMP,",
                "  USUARIO_MODIF = VALUES(USUARIO_ALTA);",
            ]
        )
    lineas.extend(
        [
            "COMMIT;",
            "SELECT COUNT(*) AS TRADUCCIONES_DESCARGADAS",
            "  FROM fza_traducciones",
            f" WHERE IDIOMA_TRAD = '{idioma}'",
            "   AND ESDESCARGADA_TRAD = 'S';",
        ]
    )
    ruta.write_text("\n".join(lineas) + "\n", encoding="utf-8")


def marcar_descargado(conexion, idioma: str) -> None:
    sentencia = """
UPDATE fza_traducciones
   SET ESDESCARGADA_TRAD = 'S',
       INSTANTE_MODIF = CURRENT_TIMESTAMP,
       USUARIO_MODIF = %s
 WHERE IDIOMA_TRAD = %s
"""
    try:
        with conexion.cursor() as cursor:
            cursor.execute(sentencia, (USUARIO_GENERACION, idioma))
        conexion.commit()
    except Exception:
        conexion.rollback()
        raise


def principal() -> None:
    opciones = argumentos()
    if opciones.idioma == "es-ES":
        raise RuntimeError("El idioma base es-ES no se exporta.")
    conexion = conectar(opciones)
    try:
        catalogo = cargar_catalogo(conexion, opciones.idioma)
        if not catalogo:
            raise RuntimeError(
                f"No hay traducciones para {opciones.idioma}."
            )
        escribir_sql(opciones.salida, opciones.idioma, catalogo)
        print(
            f"SQL generado: {opciones.salida} ({len(catalogo)} claves)",
            flush=True,
        )
        if opciones.aplicar:
            marcar_descargado(conexion, opciones.idioma)
            print("Catálogo marcado como descargado.", flush=True)
    finally:
        conexion.close()


if __name__ == "__main__":
    principal()
