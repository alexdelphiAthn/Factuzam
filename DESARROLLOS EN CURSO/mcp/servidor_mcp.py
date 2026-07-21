#!/usr/bin/env python3
"""Servidor MCP de Factuzam (transporte stdio).

Herramientas disponibles:
  - buscar_clientes: busqueda de clientes por texto libre.
  - factura_pdf: extrae a fichero el PDF archivado de una factura.

Configuracion por variables de entorno (ver README.md):
  FACTUZAM_BBDD_HOST     host de MariaDB (defecto 127.0.0.1)
  FACTUZAM_BBDD_PUERTO   puerto (defecto 3306)
  FACTUZAM_BBDD_USUARIO  usuario (defecto root)
  FACTUZAM_BBDD_CLAVE    contrasena (defecto vacia)
  FACTUZAM_BBDD_NOMBRE   nombre de la BBDD (defecto factuzam)
  FACTUZAM_DIR_PDF       carpeta donde extraer PDFs (defecto temporal)
"""
import datetime
import decimal
import os
import tempfile
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


@servidor.tool()
def factura_pdf(serie: str, numero: str) -> dict:
    """Extrae a fichero el PDF archivado de una factura de Factuzam.

    Factuzam guarda el PDF en fza_facturas.PDF_FAC al consolidar la
    factura (y lo refresca en cada exportacion manual). Esta herramienta
    lo vuelca a la carpeta FACTUZAM_DIR_PDF (o la temporal del sistema)
    y devuelve la ruta junto con nombre, tamano, huella SHA-256 e
    instante de archivado. Si la factura existe pero aun no tiene PDF
    archivado, lo indica en el resultado.
    """
    conexion = abrir_conexion()
    try:
        with conexion.cursor() as cursor:
            cursor.execute(
                'SELECT NUMERO_FAC, SERIE_FAC, ESCONSOLIDADA_FAC, '
                '       FASE_FAC, RAZON_SOCIAL_CLIENTE_FAC, PDF_FAC, '
                '       NOMBRE_PDF_FAC, TAMANO_PDF_FAC, HUELLA_PDF_FAC, '
                '       INSTANTE_PDF_FAC, FORMATO_PDF_FAC '
                '  FROM fza_facturas '
                ' WHERE SERIE_FAC = %s AND NUMERO_FAC = %s',
                (serie.strip(), numero.strip()))
            fila = cursor.fetchone()
    finally:
        conexion.close()
    if fila is None:
        return {'encontrada': False,
                'mensaje': f'No existe la factura {serie}\\{numero}'}
    if not fila['PDF_FAC']:
        return {'encontrada': True,
                'pdf_disponible': False,
                'fase': fila['FASE_FAC'],
                'consolidada': fila['ESCONSOLIDADA_FAC'] == 'S',
                'mensaje': 'La factura existe pero no tiene PDF archivado '
                           '(se archiva al consolidarla o reimprimirla)'}
    directorio = os.environ.get('FACTUZAM_DIR_PDF', tempfile.gettempdir())
    os.makedirs(directorio, exist_ok=True)
    nombre = fila['NOMBRE_PDF_FAC'] or f'Factura_{serie}_{numero}.pdf'
    nombre = os.path.basename(nombre)
    ruta = os.path.join(directorio, nombre)
    with open(ruta, 'wb') as fichero:
        fichero.write(fila['PDF_FAC'])
    return {'encontrada': True,
            'pdf_disponible': True,
            'ruta': ruta,
            'nombre': nombre,
            'tamano_bytes': fila['TAMANO_PDF_FAC'],
            'huella_sha256': fila['HUELLA_PDF_FAC'],
            'instante_archivado': valor_serializable(
                fila['INSTANTE_PDF_FAC']),
            'formato': fila['FORMATO_PDF_FAC'],
            'cliente': fila['RAZON_SOCIAL_CLIENTE_FAC'],
            'consolidada': fila['ESCONSOLIDADA_FAC'] == 'S',
            'fase': fila['FASE_FAC']}


if __name__ == '__main__':
    servidor.run()
