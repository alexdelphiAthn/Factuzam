#!/usr/bin/env python3
"""Servidor MCP de Factuzam.

Herramientas disponibles:
  - buscar_clientes: busqueda de clientes por texto libre.
  - buscar_facturas: busqueda de facturas por cliente y fechas.
  - ventas_por_fecha: resumen de ventas de un periodo (articulos y totales).
  - ventas_agrupadas: ventas de un periodo por familia o temporada.
  - comparar_ventas: comparativa de ventas entre dos periodos.
  - stock_articulos: consulta del stock actual (por SKU o por articulo).
  - deuda_clientes: deuda actual y depositos pendientes de abonar.
  - factura_pdf: extrae a fichero el PDF archivado de una factura.

Transportes:
  - stdio (defecto): para clientes locales (Claude Desktop / Claude Code).
  - http: servidor HTTP (streamable) en /mcp para clientes remotos
    (claude.ai, ChatGPT, moviles) a traves de un proxy HTTPS o tunel.

Configuracion por variables de entorno (ver README.md):
  FACTUZAM_BBDD_HOST       host de MariaDB (defecto 127.0.0.1)
  FACTUZAM_BBDD_PUERTO     puerto (defecto 3306)
  FACTUZAM_BBDD_USUARIO    usuario (defecto root)
  FACTUZAM_BBDD_CLAVE      contrasena (defecto vacia)
  FACTUZAM_BBDD_NOMBRE     nombre de la BBDD (defecto factuzam)
  FACTUZAM_DIR_PDF         carpeta donde extraer PDFs (defecto temporal)
  FACTUZAM_DIR_FOTOS       carpeta de fotos de articulos (defecto: el
                           parametro appDirFotos guardado en la BBDD)
  FACTUZAM_MCP_TRANSPORTE  'stdio' (defecto) o 'http'
  FACTUZAM_MCP_HOST        escucha HTTP (defecto 127.0.0.1)
  FACTUZAM_MCP_PUERTO      puerto HTTP (defecto 8974)
  FACTUZAM_MCP_TOKEN       si se define, exige Authorization: Bearer <token>
"""
import datetime
import decimal
import os
import tempfile
import pymysql
from pymysql.cursors import DictCursor
from mcp.server.fastmcp import FastMCP, Image

servidor = FastMCP('factuzam',
                   host=os.environ.get('FACTUZAM_MCP_HOST', '127.0.0.1'),
                   port=int(os.environ.get('FACTUZAM_MCP_PUERTO', '8974')))

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
def buscar_facturas(cliente: str = '', desde: str = '', hasta: str = '',
                    solo_consolidadas: bool = True,
                    limite: int = 10) -> list[dict]:
    """Busca facturas de venta de Factuzam, las mas recientes primero.

    `cliente` compara contra el codigo de cliente (exacto) y contra
    razon social y NIF (contiene). `desde`/`hasta` acotan la fecha de
    la factura (formato AAAA-MM-DD). `solo_consolidadas` (defecto True)
    limita a facturas emitidas; con False incluye borradores. Devuelve
    hasta `limite` filas (1-100) con serie, numero, fecha, tipo, fase,
    cliente, total y si tienen PDF archivado (extraible despues con
    factura_pdf). Para "la ultima factura de X": cliente='X', limite=1.
    """
    limite = max(1, min(int(limite), 100))
    condiciones = []
    parametros = []
    cliente = cliente.strip()
    if cliente != '':
        condiciones.append('(CODIGO_CLI_FAC = %s '
                           'OR RAZON_SOCIAL_CLIENTE_FAC LIKE %s '
                           'OR NIF_CLIENTE_FAC LIKE %s)')
        parametros.extend([cliente, f'%{cliente}%', f'%{cliente}%'])
    if desde.strip() != '':
        condiciones.append('FECHA_FAC >= %s')
        parametros.append(desde.strip())
    if hasta.strip() != '':
        condiciones.append('FECHA_FAC <= %s')
        parametros.append(hasta.strip())
    if solo_consolidadas:
        condiciones.append("ESCONSOLIDADA_FAC = 'S'")
    sql = ('SELECT SERIE_FAC, NUMERO_FAC, FECHA_FAC, TIPO_FAC, FASE_FAC, '
           '       ESCONSOLIDADA_FAC, CODIGO_CLI_FAC, '
           '       RAZON_SOCIAL_CLIENTE_FAC, NIF_CLIENTE_FAC, '
           '       TOTAL_LIQUIDO_FAC, '
           '       PDF_FAC IS NOT NULL AS PDF_DISPONIBLE, '
           '       FORMATO_PDF_FAC, INSTANTE_PDF_FAC '
           '  FROM fza_facturas')
    if condiciones:
        sql += ' WHERE ' + ' AND '.join(condiciones)
    sql += (' ORDER BY FECHA_FAC DESC, INSTANTECONSO_FAC DESC, '
            '          NUMERO_FAC DESC LIMIT %s')
    parametros.append(limite)
    conexion = abrir_conexion()
    try:
        with conexion.cursor() as cursor:
            cursor.execute(sql, parametros)
            filas = cursor.fetchall()
    finally:
        conexion.close()
    resultado = []
    for fila in filas:
        fila = {clave: valor_serializable(valor)
                for clave, valor in fila.items()}
        fila['PDF_DISPONIBLE'] = bool(fila['PDF_DISPONIBLE'])
        resultado.append(fila)
    return resultado


def filtro_ventas(desde: str, hasta: str, cliente: str,
                  solo_consolidadas: bool, incluir_canceladas: bool):
    """Construye el WHERE comun de ventas sobre fza_facturas (alias f).

    Devuelve (desde, hasta, filtro_sql, parametros). Fechas vacias:
    `desde` toma el dia de hoy y `hasta` toma el valor de `desde`.
    """
    desde = desde.strip()
    hasta = hasta.strip()
    if desde == '':
        desde = datetime.date.today().isoformat()
    if hasta == '':
        hasta = desde
    condiciones = ['f.FECHA_FAC >= %s', 'f.FECHA_FAC <= %s']
    parametros = [desde, hasta]
    cliente = cliente.strip()
    if cliente != '':
        condiciones.append('(f.CODIGO_CLI_FAC = %s '
                           'OR f.RAZON_SOCIAL_CLIENTE_FAC LIKE %s '
                           'OR f.NIF_CLIENTE_FAC LIKE %s)')
        parametros.extend([cliente, f'%{cliente}%', f'%{cliente}%'])
    if solo_consolidadas:
        condiciones.append("f.ESCONSOLIDADA_FAC = 'S'")
    if not incluir_canceladas:
        condiciones.append("(f.FASE_FAC IS NULL "
                           "OR f.FASE_FAC <> 'CANCELADA')")
    return desde, hasta, ' WHERE ' + ' AND '.join(condiciones), parametros


def resumen_ventas(cursor, filtro: str, parametros: list) -> dict:
    """Totales de ventas del filtro dado: facturas, unidades e importes."""
    cursor.execute(
        'SELECT COUNT(*) AS NUMERO_FACTURAS, '
        '       COALESCE(SUM(f.TOTAL_BASES_FAC), 0) AS BASES, '
        '       COALESCE(SUM(f.TOTAL_IMPUESTOS_FAC), 0) AS IMPUESTOS, '
        '       COALESCE(SUM(f.TOTAL_RETENCION_FAC), 0) AS RETENCIONES, '
        '       COALESCE(SUM(f.TOTAL_LIQUIDO_FAC), 0) AS LIQUIDO '
        '  FROM fza_facturas f' + filtro, parametros)
    totales = cursor.fetchone()
    cursor.execute(
        'SELECT COALESCE(SUM(l.CANTIDAD_FACLIN), 0) AS UNIDADES '
        '  FROM fza_facturas_lineas l '
        '  JOIN fza_facturas f '
        '    ON f.SERIE_FAC = l.SERIE_FAC_FACLIN '
        '   AND f.NUMERO_FAC = l.NUMERO_FAC_FACLIN' + filtro, parametros)
    unidades = cursor.fetchone()['UNIDADES']
    return {
        'numero_facturas': int(totales['NUMERO_FACTURAS']),
        'unidades_vendidas': valor_serializable(unidades),
        'total_bases': valor_serializable(totales['BASES']),
        'total_impuestos': valor_serializable(totales['IMPUESTOS']),
        'total_retenciones': valor_serializable(totales['RETENCIONES']),
        'total_liquido': valor_serializable(totales['LIQUIDO'])}


def grupos_ventas(cursor, filtro: str, parametros: list,
                  agrupar: str) -> list[dict]:
    """Ventas del filtro agrupadas por 'familia' o 'temporada'.

    Familia: directamente de las columnas de familia de la linea.
    Temporada: propiedad TEMPORADA (fza_articulos_propiedades, nivel
    COLOR con herencia del articulo): gana la fila cuyo
    CODIGO_UNIDAD_ARTPROP sea el prefijo mas especifico del SKU vendido.
    """
    if agrupar == 'familia':
        cursor.execute(
            'SELECT COALESCE(l.NOMBRE_FAM_FACLIN, '
            "                l.CODIGO_FAM_FACLIN, '(sin familia)') "
            '           AS GRUPO, '
            '       COALESCE(SUM(l.CANTIDAD_FACLIN), 0) AS CANTIDAD, '
            '       COALESCE(SUM(l.TOTAL_FAC_SIVA_FACLIN), 0) '
            '           AS TOTAL_SIN_IVA, '
            '       COALESCE(SUM(l.TOTAL_FACLIN), 0) AS TOTAL '
            '  FROM fza_facturas_lineas l '
            '  JOIN fza_facturas f '
            '    ON f.SERIE_FAC = l.SERIE_FAC_FACLIN '
            '   AND f.NUMERO_FAC = l.NUMERO_FAC_FACLIN'
            + filtro +
            ' GROUP BY GRUPO ORDER BY TOTAL DESC', parametros)
        return [{clave.lower(): valor_serializable(valor)
                 for clave, valor in fila.items()}
                for fila in cursor.fetchall()]
    # agrupar == 'temporada': lineas por (articulo, sku) y resolucion
    cursor.execute(
        'SELECT l.CODIGO_ART_FACLIN AS ART, '
        "       COALESCE(l.CODIGO_UNIDAD_FACLIN, '') AS SKU, "
        '       COALESCE(SUM(l.CANTIDAD_FACLIN), 0) AS CANTIDAD, '
        '       COALESCE(SUM(l.TOTAL_FAC_SIVA_FACLIN), 0) '
        '           AS TOTAL_SIN_IVA, '
        '       COALESCE(SUM(l.TOTAL_FACLIN), 0) AS TOTAL '
        '  FROM fza_facturas_lineas l '
        '  JOIN fza_facturas f '
        '    ON f.SERIE_FAC = l.SERIE_FAC_FACLIN '
        '   AND f.NUMERO_FAC = l.NUMERO_FAC_FACLIN'
        + filtro +
        ' GROUP BY ART, SKU', parametros)
    lineas = cursor.fetchall()
    codigos = sorted({fila['ART'] for fila in lineas if fila['ART']})
    temporadas = {}
    if codigos:
        marcadores = ', '.join(['%s'] * len(codigos))
        cursor.execute(
            'SELECT p.CODIGO_ART_ART AS ART, '
            '       p.CODIGO_UNIDAD_ARTPROP AS UNIDAD, v.PV '
            '  FROM fza_articulos_propiedades p '
            '  JOIN fza_propiedades_valores v '
            '    ON v.ID_PV_ARTPROP = p.ID_PV_ARTPROP '
            " WHERE p.CODIGO_PROP_ARTPROP = 'TEMPORADA' "
            '   AND p.CODIGO_ART_ART IN (' + marcadores + ')', codigos)
        for fila in cursor.fetchall():
            temporadas.setdefault(fila['ART'], []).append(
                (fila['UNIDAD'], fila['PV']))
    grupos = {}
    for fila in lineas:
        nombre = '(sin temporada)'
        mejor = -1
        for unidad, pv in temporadas.get(fila['ART'], ()):
            if (unidad == '' or fila['SKU'] == unidad
                    or fila['SKU'].startswith(unidad + '/')):
                if len(unidad) > mejor:
                    mejor = len(unidad)
                    nombre = pv
        grupo = grupos.setdefault(nombre, {
            'grupo': nombre, 'cantidad': decimal.Decimal(0),
            'total_sin_iva': decimal.Decimal(0),
            'total': decimal.Decimal(0)})
        grupo['cantidad'] += fila['CANTIDAD']
        grupo['total_sin_iva'] += fila['TOTAL_SIN_IVA']
        grupo['total'] += fila['TOTAL']
    resultado = sorted(grupos.values(),
                       key=lambda g: g['total'], reverse=True)
    return [{clave: valor_serializable(valor)
             for clave, valor in fila.items()} for fila in resultado]


def directorio_fotos(cursor) -> str:
    """Devuelve la carpeta base de fotos de articulos.

    Prioridad: variable FACTUZAM_DIR_FOTOS; en su defecto, el parametro
    appDirFotos de fza_usuarios_perfiles (el mismo que usa Factuzam),
    expandiendo $(PUBLICO) como hace la aplicacion.
    """
    directorio = os.environ.get('FACTUZAM_DIR_FOTOS', '').strip()
    if directorio == '':
        cursor.execute(
            "SELECT VALUE_USUPER "
            "  FROM fza_usuarios_perfiles "
            " WHERE KEY_USUPER = 'frmMtoAppParam' "
            "   AND SUBKEY_USUPER = 'appDirFotos' "
            "   AND COALESCE(VALUE_USUPER, '') <> '' "
            " LIMIT 1")
        fila = cursor.fetchone()
        if fila is not None:
            directorio = (fila['VALUE_USUPER'] or '').strip()
    if directorio != '':
        publico = os.environ.get('PUBLIC', r'C:\Users\Public')
        directorio = directorio.replace(
            '$(PUBLICO)', os.path.join(publico, 'Documents'))
    return directorio


def fotos_de_articulos(cursor, codigos: list[str]) -> dict[str, str]:
    """Resuelve la foto 300 px de cada articulo (ruta del PNG en disco).

    Reglas (ver DESARROLLOS EN CURSO/fotos_articulos.md): gana la foto
    a nivel articulo (CODIGO_UNIDAD_FOT = ''); si no la hay pero el
    articulo tiene exactamente una foto (de un SKU), se usa esa. Solo
    devuelve entradas cuyo fichero <dir>/300/<nombre>.png existe.
    """
    resultado = {}
    if not codigos:
        return resultado
    directorio = directorio_fotos(cursor)
    if directorio == '':
        return resultado
    marcadores = ', '.join(['%s'] * len(codigos))
    cursor.execute(
        'SELECT CODIGO_ART_FOT, CODIGO_UNIDAD_FOT, NOMBRE_FOT_FOT '
        '  FROM fza_articulos_fotos '
        ' WHERE CODIGO_ART_FOT IN (' + marcadores + ')', codigos)
    por_articulo = {}
    for fila in cursor.fetchall():
        por_articulo.setdefault(fila['CODIGO_ART_FOT'], []).append(fila)
    for codigo, filas in por_articulo.items():
        elegida = None
        for fila in filas:
            if fila['CODIGO_UNIDAD_FOT'] == '':
                elegida = fila
        if elegida is None and len(filas) == 1:
            elegida = filas[0]
        if elegida is not None:
            ruta = os.path.join(directorio, '300',
                                elegida['NOMBRE_FOT_FOT'] + '.png')
            if os.path.isfile(ruta):
                resultado[codigo] = ruta
    return resultado


@servidor.tool()
def ventas_por_fecha(desde: str = '', hasta: str = '', cliente: str = '',
                     solo_consolidadas: bool = True,
                     incluir_canceladas: bool = False,
                     limite_articulos: int = 100,
                     con_fotos: bool = True,
                     limite_fotos: int = 12) -> list:
    """Resumen de ventas de Factuzam entre dos fechas: articulos y totales.

    Pensada para preguntas tipo "las ventas de hoy / de ayer / de julio".
    `desde`/`hasta` acotan la fecha de factura (formato AAAA-MM-DD);
    vacios equivalen al dia de hoy, y `hasta` vacio toma el valor de
    `desde` (un solo dia). `cliente` filtra opcionalmente igual que en
    buscar_facturas (codigo exacto, o razon social/NIF contiene).
    `solo_consolidadas` (defecto True) limita a facturas emitidas;
    `incluir_canceladas` (defecto False) permite incluir las de fase
    CANCELADA. Devuelve `resumen` (numero de facturas, unidades, bases,
    impuestos y total liquido), `articulos` (agregado por articulo, con
    cantidad y totales sin/con IVA, ordenado de mayor a menor venta,
    hasta `limite_articulos` filas) y `facturas` (lista breve de las
    facturas del periodo). Las rectificativas/abonos entran con su
    signo, por lo que el total refleja la venta neta del periodo.
    Con `con_fotos` (defecto True) acompania la foto 300 px de cada
    articulo vendido (hasta `limite_fotos` imagenes, en el mismo orden
    que el listado); requiere que el servidor MCP vea la carpeta de
    fotos de Factuzam (appDirFotos o FACTUZAM_DIR_FOTOS).
    """
    limite_articulos = max(1, min(int(limite_articulos), 500))
    desde, hasta, filtro, parametros = filtro_ventas(
        desde, hasta, cliente, solo_consolidadas, incluir_canceladas)
    conexion = abrir_conexion()
    try:
        with conexion.cursor() as cursor:
            resumen = resumen_ventas(cursor, filtro, parametros)
            # Articulos vendidos, agregados por codigo y descripcion
            cursor.execute(
                'SELECT l.CODIGO_ART_FACLIN AS CODIGO_ARTICULO, '
                '       l.DESCRIPCION_ARTICULO_FACLIN AS DESCRIPCION, '
                '       COALESCE(SUM(l.CANTIDAD_FACLIN), 0) AS CANTIDAD, '
                '       COALESCE(SUM(l.TOTAL_FAC_SIVA_FACLIN), 0) '
                '           AS TOTAL_SIN_IVA, '
                '       COALESCE(SUM(l.TOTAL_FACLIN), 0) AS TOTAL '
                '  FROM fza_facturas_lineas l '
                '  JOIN fza_facturas f '
                '    ON f.SERIE_FAC = l.SERIE_FAC_FACLIN '
                '   AND f.NUMERO_FAC = l.NUMERO_FAC_FACLIN'
                + filtro +
                ' GROUP BY l.CODIGO_ART_FACLIN, '
                '          l.DESCRIPCION_ARTICULO_FACLIN '
                ' ORDER BY TOTAL DESC, CANTIDAD DESC '
                ' LIMIT %s', parametros + [limite_articulos])
            articulos = cursor.fetchall()
            # Facturas del periodo (lista breve)
            cursor.execute(
                'SELECT f.SERIE_FAC, f.NUMERO_FAC, f.FECHA_FAC, '
                '       f.TIPO_FAC, f.CODIGO_CLI_FAC, '
                '       f.RAZON_SOCIAL_CLIENTE_FAC, f.TOTAL_LIQUIDO_FAC '
                '  FROM fza_facturas f' + filtro +
                ' ORDER BY f.FECHA_FAC, f.SERIE_FAC, f.NUMERO_FAC',
                parametros)
            facturas = cursor.fetchall()
            # Fotos 300 px de los articulos vendidos (si se piden)
            fotos = {}
            if con_fotos:
                codigos = [fila['CODIGO_ARTICULO'] for fila in articulos
                           if fila['CODIGO_ARTICULO']]
                fotos = fotos_de_articulos(cursor, codigos)
    finally:
        conexion.close()
    limite_fotos = max(0, min(int(limite_fotos), 50))
    resultado = {
        'desde': desde,
        'hasta': hasta,
        'resumen': resumen,
        'articulos': [
            {clave.lower(): valor_serializable(valor)
             for clave, valor in fila.items()} for fila in articulos],
        'facturas': [
            {clave: valor_serializable(valor)
             for clave, valor in fila.items()} for fila in facturas]}
    for fila in resultado['articulos']:
        fila['foto_disponible'] = fila['codigo_articulo'] in fotos
    contenidos = [resultado]
    numero_fotos = 0
    for fila in resultado['articulos']:
        if numero_fotos >= limite_fotos:
            break
        ruta = fotos.get(fila['codigo_articulo'])
        if ruta is not None:
            contenidos.append(f"Foto de {fila['codigo_articulo']} "
                              f"({fila['descripcion']}):")
            contenidos.append(Image(path=ruta))
            numero_fotos = numero_fotos + 1
    return contenidos


@servidor.tool()
def ventas_agrupadas(desde: str = '', hasta: str = '',
                     agrupar: str = 'familia', cliente: str = '',
                     solo_consolidadas: bool = True,
                     incluir_canceladas: bool = False) -> dict:
    """Ventas de Factuzam de un periodo agrupadas por familia o temporada.

    `agrupar` es 'familia' (defecto) o 'temporada'. `desde`/`hasta` en
    formato AAAA-MM-DD (vacios = hoy; `hasta` vacio = mismo dia que
    `desde`); `cliente` y el resto de filtros funcionan igual que en
    ventas_por_fecha. Devuelve `resumen` del periodo y `grupos` con
    cantidad, total sin IVA, total con IVA y porcentaje sobre la venta,
    ordenados de mayor a menor. La temporada es la propiedad TEMPORADA
    del articulo/color vendido (p. ej. "Primavera/Verano 2026"); lo que
    no tiene temporada asignada sale como "(sin temporada)".
    """
    agrupar = agrupar.strip().lower()
    if agrupar not in ('familia', 'temporada'):
        return {'error': "agrupar debe ser 'familia' o 'temporada'"}
    desde, hasta, filtro, parametros = filtro_ventas(
        desde, hasta, cliente, solo_consolidadas, incluir_canceladas)
    conexion = abrir_conexion()
    try:
        with conexion.cursor() as cursor:
            resumen = resumen_ventas(cursor, filtro, parametros)
            grupos = grupos_ventas(cursor, filtro, parametros, agrupar)
    finally:
        conexion.close()
    total = sum(grupo['total'] for grupo in grupos)
    for grupo in grupos:
        grupo['porcentaje'] = (round(100 * grupo['total'] / total, 2)
                               if total else 0.0)
    return {'desde': desde, 'hasta': hasta, 'agrupado_por': agrupar,
            'resumen': resumen, 'grupos': grupos}


@servidor.tool()
def comparar_ventas(desde1: str, hasta1: str,
                    desde2: str = '', hasta2: str = '',
                    agrupar: str = '', cliente: str = '',
                    solo_consolidadas: bool = True,
                    incluir_canceladas: bool = False) -> dict:
    """Compara las ventas de Factuzam entre dos periodos.

    Periodo 1: `desde1`/`hasta1` (AAAA-MM-DD). Periodo 2:
    `desde2`/`hasta2`; si se dejan vacios se toma automaticamente el
    periodo inmediatamente anterior de la misma duracion (util para
    "compara esta semana con la anterior"). Para comparar con el mismo
    periodo del año pasado, pasar las fechas explicitas. `agrupar`
    opcional ('familia' o 'temporada') añade la comparativa por grupos.
    Devuelve el resumen de cada periodo y `diferencias` con variacion
    absoluta y porcentual (None si el periodo 2 esta a cero).
    """
    desde1, hasta1, filtro1, parametros1 = filtro_ventas(
        desde1, hasta1, cliente, solo_consolidadas, incluir_canceladas)
    if desde2.strip() == '':
        fecha_desde1 = datetime.date.fromisoformat(desde1)
        fecha_hasta1 = datetime.date.fromisoformat(hasta1)
        duracion = fecha_hasta1 - fecha_desde1
        fecha_hasta2 = fecha_desde1 - datetime.timedelta(days=1)
        desde2 = (fecha_hasta2 - duracion).isoformat()
        hasta2 = fecha_hasta2.isoformat()
    desde2, hasta2, filtro2, parametros2 = filtro_ventas(
        desde2, hasta2, cliente, solo_consolidadas, incluir_canceladas)
    agrupar = agrupar.strip().lower()
    conexion = abrir_conexion()
    try:
        with conexion.cursor() as cursor:
            resumen1 = resumen_ventas(cursor, filtro1, parametros1)
            resumen2 = resumen_ventas(cursor, filtro2, parametros2)
            grupos1 = grupos2 = None
            if agrupar in ('familia', 'temporada'):
                grupos1 = grupos_ventas(cursor, filtro1, parametros1,
                                        agrupar)
                grupos2 = grupos_ventas(cursor, filtro2, parametros2,
                                        agrupar)
    finally:
        conexion.close()
    diferencias = {}
    for clave in resumen1:
        d1, d2 = resumen1[clave], resumen2[clave]
        diferencias[clave] = {
            'absoluta': round(d1 - d2, 2),
            'porcentual': (round(100 * (d1 - d2) / d2, 2)
                           if d2 else None)}
    resultado = {
        'periodo1': {'desde': desde1, 'hasta': hasta1,
                     'resumen': resumen1},
        'periodo2': {'desde': desde2, 'hasta': hasta2,
                     'resumen': resumen2},
        'diferencias': diferencias}
    if grupos1 is not None:
        indice2 = {grupo['grupo']: grupo for grupo in grupos2}
        comparados = []
        vistos = set()
        for grupo in grupos1 + grupos2:
            nombre = grupo['grupo']
            if nombre in vistos:
                continue
            vistos.add(nombre)
            total1 = next((g['total'] for g in grupos1
                           if g['grupo'] == nombre), 0.0)
            total2 = indice2.get(nombre, {}).get('total', 0.0)
            comparados.append({
                'grupo': nombre,
                'total_periodo1': total1,
                'total_periodo2': total2,
                'absoluta': round(total1 - total2, 2),
                'porcentual': (round(100 * (total1 - total2) / total2, 2)
                               if total2 else None)})
        comparados.sort(key=lambda g: g['total_periodo1'], reverse=True)
        resultado['agrupado_por'] = agrupar
        resultado['grupos'] = comparados
    return resultado


@servidor.tool()
def stock_articulos(texto: str = '', almacen: str = '',
                    solo_con_stock: bool = True,
                    por_articulo: bool = False,
                    limite: int = 100) -> dict:
    """Consulta el stock actual de Factuzam (fza_articulos_stockactual).

    `texto` filtra por codigo de articulo, descripcion o SKU (contiene);
    `almacen` limita a un almacen concreto (codigo exacto).
    `solo_con_stock` (defecto True) oculta filas a cero; con False
    muestra tambien las agotadas. Con `por_articulo` True agrega por
    articulo y almacen (sin desglose de tallas/colores). Devuelve hasta
    `limite` filas (1-500) ordenadas por valor de stock, con cantidad,
    pendiente de recibir/servir, precio medio y valor, mas `totales`
    (unidades y valor de TODO lo filtrado, no solo de las filas
    mostradas).
    """
    limite = max(1, min(int(limite), 500))
    condiciones = []
    parametros = []
    texto = texto.strip()
    if texto != '':
        patron = f'%{texto}%'
        condiciones.append('(k.CODIGO_ART_SKU LIKE %s '
                           'OR a.DESCRIPCION_ART LIKE %s '
                           'OR s.CODIGO_UNIDAD_STK LIKE %s)')
        parametros.extend([patron, patron, patron])
    almacen = almacen.strip()
    if almacen != '':
        condiciones.append('s.CODIGO_ALM_STK = %s')
        parametros.append(almacen)
    if solo_con_stock:
        condiciones.append('s.CANTIDAD_STK <> 0')
    filtro = (' WHERE ' + ' AND '.join(condiciones)) if condiciones \
        else ''
    base = ('  FROM fza_articulos_stockactual s '
            '  LEFT JOIN fza_articulos_skus k '
            '    ON k.CODIGO_UNIDAD_SKU = s.CODIGO_UNIDAD_STK '
            '  LEFT JOIN fza_articulos a '
            '    ON a.CODIGO_ART_ART = k.CODIGO_ART_SKU')
    if por_articulo:
        seleccion = ('SELECT s.CODIGO_ALM_STK AS ALMACEN, '
                     '       k.CODIGO_ART_SKU AS CODIGO_ARTICULO, '
                     '       a.DESCRIPCION_ART AS DESCRIPCION, '
                     '       SUM(s.CANTIDAD_STK) AS CANTIDAD, '
                     '       SUM(s.CANTIDAD_PTE_RECIBIR_STK) '
                     '           AS PTE_RECIBIR, '
                     '       SUM(s.CANTIDAD_PTE_SERVIR_STK) '
                     '           AS PTE_SERVIR, '
                     '       SUM(s.VALOR_TOTAL_STK) AS VALOR ')
        agrupado = (' GROUP BY s.CODIGO_ALM_STK, k.CODIGO_ART_SKU, '
                    '          a.DESCRIPCION_ART')
    else:
        seleccion = ('SELECT s.CODIGO_ALM_STK AS ALMACEN, '
                     '       k.CODIGO_ART_SKU AS CODIGO_ARTICULO, '
                     '       a.DESCRIPCION_ART AS DESCRIPCION, '
                     '       s.CODIGO_UNIDAD_STK AS SKU, s.LOTE_STK, '
                     '       s.CANTIDAD_STK AS CANTIDAD, '
                     '       s.CANTIDAD_PTE_RECIBIR_STK AS PTE_RECIBIR, '
                     '       s.CANTIDAD_PTE_SERVIR_STK AS PTE_SERVIR, '
                     '       s.PRECIO_MEDIO_STK AS PRECIO_MEDIO, '
                     '       s.VALOR_TOTAL_STK AS VALOR ')
        agrupado = ''
    conexion = abrir_conexion()
    try:
        with conexion.cursor() as cursor:
            cursor.execute(seleccion + base + filtro + agrupado +
                           ' ORDER BY VALOR DESC, CANTIDAD DESC '
                           ' LIMIT %s', parametros + [limite])
            filas = cursor.fetchall()
            cursor.execute(
                'SELECT COALESCE(SUM(s.CANTIDAD_STK), 0) AS UNIDADES, '
                '       COALESCE(SUM(s.VALOR_TOTAL_STK), 0) AS VALOR '
                + base + filtro, parametros)
            totales = cursor.fetchone()
    finally:
        conexion.close()
    return {
        'totales': {
            'unidades': valor_serializable(totales['UNIDADES']),
            'valor': valor_serializable(totales['VALOR'])},
        'filas': [{clave.lower(): valor_serializable(valor)
                   for clave, valor in fila.items()} for fila in filas]}


@servidor.tool()
def deuda_clientes(cliente: str = '', solo_con_deuda: bool = True,
                   con_depositos: bool = True,
                   limite: int = 50) -> dict:
    """Deuda actual de los clientes de Factuzam.

    La deuda se calcula en vivo con la misma formula que la aplicacion:
    suma de (precio venta x cantidad pendiente - anticipos entregados)
    de los depositos/prestamos en estado PENDIENTE de cada cliente
    (fza_depositos_cliente). `cliente` filtra por codigo, razon social
    o NIF (contiene); `solo_con_deuda` (defecto True) oculta clientes
    al dia. Devuelve hasta `limite` clientes (1-200) ordenados de mayor
    a menor deuda, cada uno con su total adeudado, anticipos entregados
    y, con `con_depositos` True, el detalle de los depositos pendientes
    de abonar (articulo, cantidad, precio, anticipo y pendiente). El
    campo `deuda_ficha` es el TOTAL_DEUDA_CLI guardado en la ficha (por
    si estuviera desactualizado respecto al calculo en vivo).
    """
    limite = max(1, min(int(limite), 200))
    condiciones = []
    parametros = []
    cliente = cliente.strip()
    if cliente != '':
        patron = f'%{cliente}%'
        condiciones.append('(c.CODIGO_CLI_CLI = %s '
                           'OR c.RAZON_SOCIAL_CLI LIKE %s '
                           'OR c.NIF_CLI LIKE %s)')
        parametros.extend([cliente, patron, patron])
    if solo_con_deuda:
        condiciones.append('(COALESCE(d.DEUDA, 0) > 0 '
                           'OR c.TOTAL_DEUDA_CLI > 0)')
    filtro = (' WHERE ' + ' AND '.join(condiciones)) if condiciones \
        else ''
    sql = (
        'SELECT c.CODIGO_CLI_CLI, c.RAZON_SOCIAL_CLI, c.NIF_CLI, '
        '       c.TELEFONO_CLI, c.MOVIL_CLI, '
        '       c.TOTAL_DEUDA_CLI AS DEUDA_FICHA, '
        '       COALESCE(d.DEUDA, 0) AS DEUDA, '
        '       COALESCE(d.ANTICIPOS, 0) AS ANTICIPOS, '
        '       COALESCE(d.NUMERO, 0) AS DEPOSITOS_PENDIENTES '
        '  FROM fza_clientes c '
        '  LEFT JOIN ('
        '       SELECT CODIGO_CLI_DEP, COUNT(*) AS NUMERO, '
        '              SUM(PRECIO_VENTA_DEP '
        '                  * COALESCE(CANTIDAD_PENDIENTE_DEP, 1) '
        '                  - IMPORTE_ANTICIPO_DEP) AS DEUDA, '
        '              SUM(IMPORTE_ANTICIPO_DEP) AS ANTICIPOS '
        '         FROM fza_depositos_cliente '
        "        WHERE ESTADO_DEP = 'PENDIENTE' "
        '          AND COALESCE(CANTIDAD_PENDIENTE_DEP, 1) > 0 '
        '        GROUP BY CODIGO_CLI_DEP'
        '  ) d ON d.CODIGO_CLI_DEP = c.CODIGO_CLI_CLI'
        + filtro +
        ' ORDER BY DEUDA DESC, c.RAZON_SOCIAL_CLI LIMIT %s')
    conexion = abrir_conexion()
    try:
        with conexion.cursor() as cursor:
            cursor.execute(sql, parametros + [limite])
            clientes = [{clave.lower(): valor_serializable(valor)
                         for clave, valor in fila.items()}
                        for fila in cursor.fetchall()]
            if con_depositos and clientes:
                codigos = [fila['codigo_cli_cli'] for fila in clientes]
                marcadores = ', '.join(['%s'] * len(codigos))
                cursor.execute(
                    'SELECT CODIGO_CLI_DEP, ID_DEPOSITO_DEP, '
                    '       CODIGO_ART_DEP, CODIGO_UNIDAD_DEP, '
                    '       CODIGO_ALM_DEP, FECHA_CREACION_DEP, '
                    '       CANTIDAD_PENDIENTE_DEP, PRECIO_VENTA_DEP, '
                    '       IMPORTE_ANTICIPO_DEP, '
                    '       (PRECIO_VENTA_DEP '
                    '        * COALESCE(CANTIDAD_PENDIENTE_DEP, 1) '
                    '        - IMPORTE_ANTICIPO_DEP) AS PENDIENTE '
                    '  FROM fza_depositos_cliente '
                    " WHERE ESTADO_DEP = 'PENDIENTE' "
                    '   AND COALESCE(CANTIDAD_PENDIENTE_DEP, 1) > 0 '
                    '   AND CODIGO_CLI_DEP IN (' + marcadores + ') '
                    ' ORDER BY FECHA_CREACION_DEP', codigos)
                depositos = {}
                for fila in cursor.fetchall():
                    depositos.setdefault(
                        fila['CODIGO_CLI_DEP'], []).append(
                        {clave.lower(): valor_serializable(valor)
                         for clave, valor in fila.items()
                         if clave != 'CODIGO_CLI_DEP'})
                for fila in clientes:
                    fila['depositos'] = depositos.get(
                        fila['codigo_cli_cli'], [])
    finally:
        conexion.close()
    return {
        'totales': {
            'numero_clientes': len(clientes),
            'deuda_total': round(sum(fila['deuda']
                                     for fila in clientes), 2),
            'anticipos_total': round(sum(fila['anticipos']
                                         for fila in clientes), 2)},
        'clientes': clientes}


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


def ejecutar_http():
    """Arranca el transporte HTTP (endpoint /mcp) con token opcional."""
    import uvicorn
    from starlette.middleware.base import BaseHTTPMiddleware
    from starlette.responses import JSONResponse
    token = os.environ.get('FACTUZAM_MCP_TOKEN', '').strip()
    aplicacion = servidor.streamable_http_app()
    if token != '':
        class ComprobarToken(BaseHTTPMiddleware):
            async def dispatch(self, peticion, siguiente):
                esperado = f'Bearer {token}'
                if peticion.headers.get('authorization') != esperado:
                    return JSONResponse({'error': 'No autorizado'},
                                        status_code=401)
                return await siguiente(peticion)
        aplicacion.add_middleware(ComprobarToken)
    uvicorn.run(aplicacion,
                host=servidor.settings.host,
                port=servidor.settings.port)


if __name__ == '__main__':
    if os.environ.get('FACTUZAM_MCP_TRANSPORTE', 'stdio') == 'http':
        ejecutar_http()
    else:
        servidor.run()
