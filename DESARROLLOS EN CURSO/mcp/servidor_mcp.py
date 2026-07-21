#!/usr/bin/env python3
"""Servidor MCP de Factuzam (transporte stdio).

Herramientas disponibles:
  - buscar_clientes: busqueda de clientes por texto libre.

Configuracion por variables de entorno (ver README.md):
  FACTUZAM_BBDD_HOST     host de MariaDB (defecto 127.0.0.1)
  FACTUZAM_BBDD_PUERTO   puerto (defecto 3306)
  FACTUZAM_BBDD_USUARIO  usuario (defecto root)
  FACTUZAM_BBDD_CLAVE    contrasena (defecto vacia)
  FACTUZAM_BBDD_NOMBRE   nombre de la BBDD (defecto factuzam)
"""
import datetime
import decimal
import os
import pymysql
from pymysql.cursors import DictCursor
from mcp.server.fastmcp import FastMCP

servidor = FastMCP('factuzam')

# Columnas contra las que compara la busqueda por texto libre
COLUMNAS_BUSQUEDA = (
    'CODIGO_CLI_CLI',
    'RAZON_SOCIAL_CLI',
    'NIF_CLI',
    'EMAIL_CLI',
    'TELEFONO_CLI',
    'MOVIL_CLI',
    'POBLACION_CLI',
    'REFERENCIA_CLI')

# Columnas que devuelve cada resultado (resumen de la ficha)
COLUMNAS_RESULTADO = (
    'CODIGO_CLI_CLI',
    'RAZON_SOCIAL_CLI',
    'NIF_CLI',
    'TELEFONO_CLI',
    'MOVIL_CLI',
    'EMAIL_CLI',
    'DIRECCION1_CLI',
    'POBLACION_CLI',
    'PROVINCIA_CLI',
    'CODIGO_POSTAL_CLI',
    'ESACTIVO_CLI',
    'TOTAL_DEUDA_CLI')


def abrir_conexion() -> pymysql.connections.Connection:
    """Abre una conexion nueva a la BBDD de Factuzam."""
    return pymysql.connect(
        host=os.environ.get('FACTUZAM_BBDD_HOST', '127.0.0.1'),
        port=int(os.environ.get('FACTUZAM_BBDD_PUERTO', '3306')),
        user=os.environ.get('FACTUZAM_BBDD_USUARIO', 'root'),
        password=os.environ.get('FACTUZAM_BBDD_CLAVE', ''),
        database=os.environ.get('FACTUZAM_BBDD_NOMBRE', 'factuzam'),
        charset='utf8mb4',
        cursorclass=DictCursor)


def valor_serializable(valor):
    """Convierte tipos SQL (Decimal, fechas) a tipos JSON basicos."""
    if isinstance(valor, decimal.Decimal):
        return float(valor)
    if isinstance(valor, (datetime.datetime, datetime.date)):
        return valor.isoformat()
    return valor


@servidor.tool()
def buscar_clientes(texto: str, solo_activos: bool = True,
                    limite: int = 20) -> list[dict]:
    """Busca clientes de Factuzam por texto libre.

    Compara el texto contra codigo, razon social, NIF, email, telefonos,
    poblacion y referencia (LIKE %texto%). Devuelve como maximo `limite`
    filas (entre 1 y 100) ordenadas por razon social. Con `solo_activos`
    a False incluye tambien los clientes dados de baja.
    """
    limite = max(1, min(int(limite), 100))
    condiciones = []
    parametros = []
    texto = texto.strip()
    if texto != '':
        patron = f'%{texto}%'
        comparaciones = [f'{col} LIKE %s' for col in COLUMNAS_BUSQUEDA]
        condiciones.append('(' + ' OR '.join(comparaciones) + ')')
        parametros.extend([patron] * len(COLUMNAS_BUSQUEDA))
    if solo_activos:
        condiciones.append("ESACTIVO_CLI = 'S'")
    sql = 'SELECT ' + ', '.join(COLUMNAS_RESULTADO) + ' FROM fza_clientes'
    if condiciones:
        sql += ' WHERE ' + ' AND '.join(condiciones)
    sql += ' ORDER BY RAZON_SOCIAL_CLI LIMIT %s'
    parametros.append(limite)
    conexion = abrir_conexion()
    try:
        with conexion.cursor() as cursor:
            cursor.execute(sql, parametros)
            filas = cursor.fetchall()
    finally:
        conexion.close()
    return [{clave: valor_serializable(valor)
             for clave, valor in fila.items()} for fila in filas]


if __name__ == '__main__':
    servidor.run()
