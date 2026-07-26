#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
test_albaran_pedido_compra.py
------------------------------------------------------------------------
Prueba de datos del refactor de COMPRAS: la fusion de
CrearAlbaranDesdePedido (flujo "todo lo pendiente") dentro de
CrearAlbaranDesdePedidoConCantidades (flujo celda a celda del pivote),
en src/Lib/inLibPedidosCompra.pas (-278 lineas).

Portamos a Python el SQL exacto de las dos funciones y comprobamos:

  1. Que el wrapper produce EXACTAMENTE el mismo albaran que la llamada
     directa con celdas (esa es la afirmacion del refactor).
  2. Que el tope por linea (dPdteLinea) impide recibir mas que el
     pendiente cuando varias celdas apuntan a la misma linea.
  3. Que el filtro de almacen deja fuera las lineas de otro almacen.
  4. Que sin pendiente no se crea nada y no queda cabecera huerfana.
  5. Que el estado del pedido se recalcula (ABIERTO/PARCIAL/RECIBIDO)
     y que CANCELADO no se pisa.
  6. Que la numeracion de lineas y CONTADOR_LINEAS_ALBC son correctos.
  7. Que envuelto en transaccion (lo que hace ahora UniDataPedidos con
     bTransPropia) un fallo posterior no deja rastro.
  8. Que el exento intracomunitario fuerza tipo IVA 'E' al 0 %.

NO se ejecutan los pasos posteriores que el refactor no toca
(GenerarMovimientosDesdeAlbaranCompra y GenerarPdteRecibirDesdePedido):
quedan fuera del alcance a proposito y se indican como STUB.

BBDD: factuzam_test local (copia de la demo). No toca datos del usuario.
"""

import sys
import pymysql

USUARIO = 'PRUEBAS'
ALM = 'GEN'
ALM_OTRO = 'ZZTEST'
SERIE_ALBC = 'T1'

_ok = 0
_ko = 0


def conn():
    return pymysql.connect(unix_socket='/var/run/mysqld/mysqld.sock',
                           database='factuzam_test', charset='utf8mb4',
                           autocommit=True,
                           init_command="SET collation_connection="
                                        "'utf8mb4_spanish_ci'",
                           cursorclass=pymysql.cursors.DictCursor)


def check(nombre, cond, detalle=''):
    global _ok, _ko
    if cond:
        _ok += 1
        print('  OK   %s' % nombre)
    else:
        _ko += 1
        print('  FALLO %s  %s' % (nombre, detalle))


# ---------------------------------------------------------------------
# Puertos fieles del codigo Delphi refactorizado
# ---------------------------------------------------------------------

SQL_PENDIENTES = """
SELECT L.LINEA_PEDCLIN, L.CODIGO_UNIDAD_PEDCLIN,
       L.CANTIDAD_PEDCLIN - IFNULL(L.CANTIDAD_RECIBIDA_PEDCLIN,0) AS PENDIENTE
  FROM fza_pedidos_compra_lineas L
  JOIN fza_pedidos_compra P
    ON P.SERIE_PEDC  = L.SERIE_PEDC_PEDCLIN
   AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN
 WHERE L.SERIE_PEDC_PEDCLIN  = %s
   AND L.NUMERO_PEDC_PEDCLIN = %s
   AND IFNULL(NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''), P.CODIGO_ALM_PEDC) = %s
   AND L.CANTIDAD_PEDCLIN - IFNULL(L.CANTIDAD_RECIBIDA_PEDCLIN,0) > 0
 ORDER BY L.LINEA_PEDCLIN
"""


def obtener_siguiente_contador(cn, tipo_doc, usuario):
    """Puerto de inLibtb.ObtenerSiguienteContador (PRC_GET_NEXT_CONT)."""
    with cn.cursor() as c:
        c.execute("CALL PRC_GET_NEXT_CONT(%s, %s, @cont)", (tipo_doc, usuario))
        c.execute("SELECT @cont AS c")
        return (c.fetchone()['c'] or '').strip()


def crear_albaran_desde_pedido(cn, serie_pedc, num_pedc, alm, serie_albc,
                               usuario, ref_prv='', fecha=None, id_pv=0):
    """Puerto de CrearAlbaranDesdePedido (el wrapper nuevo)."""
    celdas = []
    with cn.cursor() as c:
        c.execute(SQL_PENDIENTES, (serie_pedc, num_pedc, alm))
        for r in c.fetchall():
            celdas.append({'LineaPedido': r['LINEA_PEDCLIN'],
                           'CodigoSku': r['CODIGO_UNIDAD_PEDCLIN'] or '',
                           'CodigoAlmacen': alm,
                           'Cantidad': float(r['PENDIENTE'])})
    if not celdas:
        return (False, '', 'No hay lineas pendientes de recibir para el '
                           'almacen "%s" en el pedido %s/%s.'
                           % (alm, serie_pedc, num_pedc))
    return crear_albaran_con_cantidades(cn, serie_pedc, num_pedc, alm,
                                        serie_albc, usuario, celdas,
                                        ref_prv, fecha, id_pv)


SQL_CAB = """
INSERT INTO fza_albaranes_compra
  (NUMERO_ALBC, SERIE_ALBC, FECHA_ALBC, ESTADO_ALBC,
   NUMERO_PED_ALBC, SERIE_PED_ALBC,
   CODIGO_EMP_ALBC, RAZON_SOCIAL_EMPRESA_ALBC, NIF_EMPRESA_ALBC,
   CODIGO_IVA_ALBC, ESIVA_RECARGO_COMPRAS_ALBC,
   ESIVA_EXENTO_INTRACOMUNITARIO_ALBC,
   PORCENTAJE_IVAN_ALBC, PORCENTAJE_IVAR_ALBC,
   PORCENTAJE_IVAS_ALBC, PORCENTAJE_IVAE_ALBC,
   PORCENTAJE_RETENCION_ALBC,
   CODIGO_PRV_ALBC, RAZON_SOCIAL_PRV_ALBC, NIF_PRV_ALBC,
   REF_PROVEEDOR_ALBC, FORMA_PAGO_ALBC,
   ID_PV_TEMPORADA_ALBC, CODIGO_ALM_ALBC,
   TOTAL_BRUTO_ALBC, PORCENTAJE_DTO_COMERCIAL_ALBC,
   TOTAL_DTO_COMERCIAL_ALBC, PORCENTAJE_DTO_FINANCIERO_ALBC,
   TOTAL_DTO_FINANCIERO_ALBC, TOTAL_BASES_ALBC,
   TOTAL_IMPUESTOS_ALBC, TOTAL_LIQUIDO_ALBC,
   CONTADOR_LINEAS_ALBC,
   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF)
SELECT %s, %s,
       CASE WHEN %s = 'S' THEN %s
            ELSE IFNULL(P.FECHA_PEDC, CURDATE()) END,
       'ABIERTO',
       P.NUMERO_PEDC, P.SERIE_PEDC,
       P.CODIGO_EMP_PEDC, P.RAZON_SOCIAL_EMPRESA_PEDC, P.NIF_EMPRESA_PEDC,
       P.CODIGO_IVA_PEDC, IFNULL(P.ESIVA_RECARGO_COMPRAS_PEDC, 'N'),
       IFNULL(P.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, 'N'),
       P.PORCENTAJE_IVAN_PEDC, P.PORCENTAJE_IVAR_PEDC,
       P.PORCENTAJE_IVAS_PEDC, P.PORCENTAJE_IVAE_PEDC,
       P.PORCENTAJE_RETENCION_PEDC,
       P.CODIGO_PRV_PEDC, P.RAZON_SOCIAL_PRV_PEDC, P.NIF_PRV_PEDC,
       IFNULL(NULLIF(%s,''), P.REF_PROVEEDOR_PEDC),
       NULLIF(P.FORMA_PAGO_PEDC, ''), NULLIF(%s, 0), %s,
       0, IFNULL(P.PORCENTAJE_DTO_COMERCIAL_PEDC, 0),
       0, IFNULL(P.PORCENTAJE_DTO_FINANCIERO_PEDC, 0),
       0, 0, 0, 0, '0',
       NOW(), %s, NOW(), %s
  FROM fza_pedidos_compra P
 WHERE P.SERIE_PEDC = %s AND P.NUMERO_PEDC = %s
"""

SQL_LIN_ORIGEN = """
SELECT L.CODIGO_ART_PEDCLIN, L.CODIGO_UNIDAD_PEDCLIN,
       L.REF_PRV_PEDCLIN, L.ID_AC_PIVOT_PEDCLIN,
       L.CODIGO_FAM_PEDCLIN, L.NOMBRE_FAM_PEDCLIN,
       L.DESCRIPCION_ARTICULO_PEDCLIN,
       L.TIPO_CANTIDAD_ARTICULO_PEDCLIN,
       L.TIPO_IVA_ARTICULO_PEDCLIN, L.PORCENTAJE_IVA_PEDCLIN,
       IFNULL(P.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, 'N') AS EXENTO_INTRACOM,
       L.PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN,
       L.PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN,
       L.CANTIDAD_PEDCLIN, L.CANTIDAD_RECIBIDA_PEDCLIN
  FROM fza_pedidos_compra_lineas L
  JOIN fza_pedidos_compra P
    ON P.SERIE_PEDC = L.SERIE_PEDC_PEDCLIN
   AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN
 WHERE L.SERIE_PEDC_PEDCLIN  = %s
   AND L.NUMERO_PEDC_PEDCLIN = %s
   AND L.LINEA_PEDCLIN       = %s
"""

SQL_INS_LIN = """
INSERT INTO fza_albaranes_compra_lineas
  (NUMERO_ALBC_ALBCLIN, SERIE_ALBC_ALBCLIN, LINEA_ALBCLIN,
   NUMERO_PEDC_ALBCLIN, SERIE_PEDC_ALBCLIN, LINEA_PEDC_ALBCLIN,
   CODIGO_ART_ALBCLIN, CODIGO_UNIDAD_ALBCLIN, REF_PRV_ALBCLIN,
   ID_AC_PIVOT_ALBCLIN, CODIGO_FAM_ALBCLIN, NOMBRE_FAM_ALBCLIN,
   DESCRIPCION_ARTICULO_ALBCLIN, TIPO_CANTIDAD_ARTICULO_ALBCLIN,
   CANTIDAD_ALBCLIN, TOTAL_UNIDADES_ALBCLIN,
   TIPO_IVA_ARTICULO_ALBCLIN, PORCENTAJE_IVA_ALBCLIN,
   PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN,
   PRECIO_COMPRA_CIVA_ARTICULO_ALBCLIN,
   TOTAL_ALBCLIN, CODIGO_ALMACEN_ALBCLIN, ESFACTURADA_ALBCLIN,
   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF)
VALUES (%s, %s, %s, %s, %s, %s,
        %s, %s, %s, %s, %s, %s,
        %s, %s,
        %s, %s, %s, %s, %s, %s,
        %s * %s, %s, 'N',
        NOW(), %s, NOW(), %s)
"""


def crear_albaran_con_cantidades(cn, serie_pedc, num_pedc, alm, serie_albc,
                                 usuario, celdas, ref_prv='', fecha=None,
                                 id_pv=0):
    """Puerto de CrearAlbaranDesdePedidoConCantidades."""
    if not (alm or '').strip():
        return (False, '', 'Debes seleccionar un almacen.')
    total_celdas = sum(c['Cantidad'] for c in celdas
                       if c['CodigoAlmacen'].lower() == alm.lower()
                       and c['Cantidad'] > 0)
    if total_celdas <= 0:
        return (False, '', 'No hay cantidades "A recibir" tecleadas para el '
                           'almacen "%s" en el pedido %s/%s.'
                           % (alm, serie_pedc, num_pedc))
    num_albc = obtener_siguiente_contador(cn, 'AB', usuario)
    if not num_albc:
        return (False, '', 'No se pudo obtener un numero de albaran del '
                           'contador "AB".')
    with cn.cursor() as c:
        c.execute(SQL_CAB, (num_albc, serie_albc,
                            'S' if fecha else 'N', fecha,
                            ref_prv, id_pv, alm, usuario, usuario,
                            serie_pedc, num_pedc))
    # 3. Una linea de albaran por celda valida, con tope por linea.
    pdte_linea = {}
    i_linea = 0
    with cn.cursor() as c:
        for cel in celdas:
            if cel['CodigoAlmacen'].lower() != alm.lower():
                continue
            if cel['Cantidad'] <= 0:
                continue
            c.execute(SQL_LIN_ORIGEN, (serie_pedc, num_pedc,
                                       cel['LineaPedido']))
            org = c.fetchone()
            if not org:
                continue
            if cel['LineaPedido'] not in pdte_linea:
                p = (float(org['CANTIDAD_PEDCLIN'] or 0) -
                     float(org['CANTIDAD_RECIBIDA_PEDCLIN'] or 0))
                pdte_linea[cel['LineaPedido']] = max(p, 0.0)
            rp = pdte_linea[cel['LineaPedido']]
            cant = min(cel['Cantidad'], rp)
            pdte_linea[cel['LineaPedido']] = rp - cant
            if cant <= 0:
                continue
            i_linea += 10
            s_linea = '%04d' % i_linea
            if (org['EXENTO_INTRACOM'] or 'N') == 'S':
                tiva, piva = 'E', 0.0
            else:
                tiva = org['TIPO_IVA_ARTICULO_PEDCLIN']
                piva = float(org['PORCENTAJE_IVA_PEDCLIN'] or 0)
            pre = float(org['PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN'] or 0)
            c.execute(SQL_INS_LIN, (
                num_albc, serie_albc, s_linea,
                num_pedc, serie_pedc, cel['LineaPedido'],
                org['CODIGO_ART_PEDCLIN'], cel['CodigoSku'],
                org['REF_PRV_PEDCLIN'], org['ID_AC_PIVOT_PEDCLIN'],
                org['CODIGO_FAM_PEDCLIN'], org['NOMBRE_FAM_PEDCLIN'],
                org['DESCRIPCION_ARTICULO_PEDCLIN'],
                org['TIPO_CANTIDAD_ARTICULO_PEDCLIN'],
                cant, cant, tiva, piva, pre,
                float(org['PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN'] or 0),
                cant, pre, alm, usuario, usuario))
            c.execute("""UPDATE fza_pedidos_compra_lineas
                            SET CANTIDAD_RECIBIDA_PEDCLIN =
                                  IFNULL(CANTIDAD_RECIBIDA_PEDCLIN,0) + %s,
                                USUARIO_MODIF = %s, INSTANTE_MODIF = NOW()
                          WHERE SERIE_PEDC_PEDCLIN  = %s
                            AND NUMERO_PEDC_PEDCLIN = %s
                            AND LINEA_PEDCLIN       = %s""",
                      (cant, usuario, serie_pedc, num_pedc,
                       cel['LineaPedido']))
    if i_linea == 0:
        with cn.cursor() as c:
            c.execute("""DELETE FROM fza_albaranes_compra
                          WHERE SERIE_ALBC = %s AND NUMERO_ALBC = %s""",
                      (serie_albc, num_albc))
        return (False, '', 'No se pudo crear ninguna linea del albaran '
                           '(lineas origen no encontradas o sin pendiente '
                           'de recibir).')
    recalcular_totales(cn, serie_albc, num_albc, usuario)
    # STUB: GenerarMovimientosDesdeAlbaranCompra (no tocado por el refactor)
    with cn.cursor() as c:
        c.execute("""UPDATE fza_albaranes_compra
                        SET ESTADO_ALBC = 'CERRADO', USUARIO_MODIF = %s,
                            INSTANTE_MODIF = NOW()
                      WHERE SERIE_ALBC = %s AND NUMERO_ALBC = %s""",
                  (usuario, serie_albc, num_albc))
    # STUB: GenerarPdteRecibirDesdePedido (no tocado por el refactor)
    recalcular_estado_pedido(cn, serie_pedc, num_pedc, usuario)
    return (True, num_albc,
            'Albaran %s/%s creado correctamente (%d lineas).'
            % (serie_albc, num_albc, i_linea // 10))


def recalcular_totales(cn, serie_albc, num_albc, usuario):
    """Puerto reducido de RecalcularTotalesAlbaranCompra (sin recargo)."""
    with cn.cursor() as c:
        c.execute("""
UPDATE fza_albaranes_compra C
  JOIN (SELECT L.NUMERO_ALBC_ALBCLIN, L.SERIE_ALBC_ALBCLIN,
               IFNULL(SUM(L.TOTAL_ALBCLIN),0) AS BASE,
               IFNULL(SUM(L.TOTAL_ALBCLIN * L.PORCENTAJE_IVA_ALBCLIN/100),0)
                 AS IVA,
               COUNT(*) AS NLIN
          FROM fza_albaranes_compra_lineas L
         WHERE L.NUMERO_ALBC_ALBCLIN = %s AND L.SERIE_ALBC_ALBCLIN = %s
         GROUP BY L.NUMERO_ALBC_ALBCLIN, L.SERIE_ALBC_ALBCLIN) T
    ON T.NUMERO_ALBC_ALBCLIN = C.NUMERO_ALBC
   AND T.SERIE_ALBC_ALBCLIN = C.SERIE_ALBC
   SET C.TOTAL_BRUTO_ALBC = T.BASE,
       C.TOTAL_BASES_ALBC = T.BASE *
         GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC,0)/100),
       C.TOTAL_IMPUESTOS_ALBC = T.IVA *
         GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC,0)/100),
       C.TOTAL_LIQUIDO_ALBC = (T.BASE + T.IVA) *
         GREATEST(0, 1 - IFNULL(C.PORCENTAJE_DTO_COMERCIAL_ALBC,0)/100),
       C.CONTADOR_LINEAS_ALBC = LPAD(T.NLIN*10, 8, '0'),
       C.USUARIO_MODIF = %s, C.INSTANTE_MODIF = NOW()
 WHERE C.SERIE_ALBC = %s AND C.NUMERO_ALBC = %s""",
                  (num_albc, serie_albc, usuario, serie_albc, num_albc))


def recalcular_estado_pedido(cn, serie_pedc, num_pedc, usuario):
    """Puerto de RecalcularEstadoPedido."""
    with cn.cursor() as c:
        c.execute("""SELECT IFNULL(SUM(CANTIDAD_PEDCLIN),0) PEDIDA,
                            IFNULL(SUM(CANTIDAD_RECIBIDA_PEDCLIN),0) RECIBIDA
                       FROM fza_pedidos_compra_lineas
                      WHERE SERIE_PEDC_PEDCLIN = %s
                        AND NUMERO_PEDC_PEDCLIN = %s""",
                  (serie_pedc, num_pedc))
        r = c.fetchone()
        pedida, recibida = float(r['PEDIDA']), float(r['RECIBIDA'])
        c.execute("""SELECT ESTADO_PEDC FROM fza_pedidos_compra
                      WHERE SERIE_PEDC = %s AND NUMERO_PEDC = %s""",
                  (serie_pedc, num_pedc))
        h = c.fetchone()
        if not h:
            return
        actual = (h['ESTADO_PEDC'] or '').strip().upper()
        if actual == 'CANCELADO':
            return
        if pedida <= 0:
            nuevo = 'ABIERTO'
        elif recibida + 0.000001 >= pedida:
            nuevo = 'RECIBIDO'
        elif recibida > 0:
            nuevo = 'PARCIAL'
        else:
            nuevo = 'ABIERTO'
        if nuevo == actual:
            return
        c.execute("""UPDATE fza_pedidos_compra
                        SET ESTADO_PEDC = %s, USUARIO_MODIF = %s,
                            INSTANTE_MODIF = NOW()
                      WHERE SERIE_PEDC = %s AND NUMERO_PEDC = %s""",
                  (nuevo, usuario, serie_pedc, num_pedc))


# ---------------------------------------------------------------------
# Utilidades de escenario
# ---------------------------------------------------------------------

def clonar_pedido_simple(cn, num_dst, con_linea_otro_almacen=False):
    """Clon robusto: lee filas y las reinserta con la clave nueva."""
    with cn.cursor() as c:
        c.execute("DELETE FROM fza_pedidos_compra_lineas "
                  "WHERE SERIE_PEDC_PEDCLIN='ZZ' AND NUMERO_PEDC_PEDCLIN=%s",
                  (num_dst,))
        c.execute("DELETE FROM fza_pedidos_compra "
                  "WHERE SERIE_PEDC='ZZ' AND NUMERO_PEDC=%s", (num_dst,))
        c.execute("SELECT * FROM fza_pedidos_compra "
                  "WHERE SERIE_PEDC='A1' AND NUMERO_PEDC='000002'")
        cab = c.fetchone()
        cab['SERIE_PEDC'] = 'ZZ'
        cab['NUMERO_PEDC'] = num_dst
        cab['ESTADO_PEDC'] = 'ABIERTO'
        cols = ','.join('`%s`' % k for k in cab)
        vals = ','.join(['%s'] * len(cab))
        c.execute("INSERT INTO fza_pedidos_compra (%s) VALUES (%s)"
                  % (cols, vals), tuple(cab.values()))
        c.execute("SELECT * FROM fza_pedidos_compra_lineas "
                  "WHERE SERIE_PEDC_PEDCLIN='A1' "
                  "  AND NUMERO_PEDC_PEDCLIN='000002' "
                  "ORDER BY LINEA_PEDCLIN")
        lineas = c.fetchall()
        for i, ln in enumerate(lineas):
            ln['SERIE_PEDC_PEDCLIN'] = 'ZZ'
            ln['NUMERO_PEDC_PEDCLIN'] = num_dst
            ln['CANTIDAD_RECIBIDA_PEDCLIN'] = 0
            ln['CODIGO_ALMACEN_PEDCLIN'] = ALM
            if con_linea_otro_almacen and i == len(lineas) - 1:
                ln['CODIGO_ALMACEN_PEDCLIN'] = ALM_OTRO
            cols = ','.join('`%s`' % k for k in ln)
            vals = ','.join(['%s'] * len(ln))
            c.execute("INSERT INTO fza_pedidos_compra_lineas (%s) VALUES (%s)"
                      % (cols, vals), tuple(ln.values()))
        return len(lineas)


def limpiar(cn):
    with cn.cursor() as c:
        c.execute("DELETE FROM fza_albaranes_compra_lineas "
                  "WHERE SERIE_ALBC_ALBCLIN=%s", (SERIE_ALBC,))
        c.execute("DELETE FROM fza_albaranes_compra WHERE SERIE_ALBC=%s",
                  (SERIE_ALBC,))
        c.execute("DELETE FROM fza_pedidos_compra_lineas "
                  "WHERE SERIE_PEDC_PEDCLIN='ZZ'")
        c.execute("DELETE FROM fza_pedidos_compra WHERE SERIE_PEDC='ZZ'")


def lineas_albaran(cn, num_albc):
    with cn.cursor() as c:
        c.execute("""SELECT LINEA_ALBCLIN, LINEA_PEDC_ALBCLIN,
                            CODIGO_ART_ALBCLIN, CODIGO_UNIDAD_ALBCLIN,
                            CANTIDAD_ALBCLIN, PORCENTAJE_IVA_ALBCLIN,
                            TIPO_IVA_ARTICULO_ALBCLIN,
                            PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN,
                            TOTAL_ALBCLIN, CODIGO_ALMACEN_ALBCLIN
                       FROM fza_albaranes_compra_lineas
                      WHERE SERIE_ALBC_ALBCLIN=%s AND NUMERO_ALBC_ALBCLIN=%s
                      ORDER BY LINEA_ALBCLIN""", (SERIE_ALBC, num_albc))
        return c.fetchall()


def cab_albaran(cn, num_albc):
    with cn.cursor() as c:
        c.execute("""SELECT ESTADO_ALBC, CONTADOR_LINEAS_ALBC,
                            TOTAL_BRUTO_ALBC, TOTAL_BASES_ALBC,
                            TOTAL_IMPUESTOS_ALBC, TOTAL_LIQUIDO_ALBC,
                            CODIGO_ALM_ALBC, SERIE_PED_ALBC, NUMERO_PED_ALBC
                       FROM fza_albaranes_compra
                      WHERE SERIE_ALBC=%s AND NUMERO_ALBC=%s""",
                  (SERIE_ALBC, num_albc))
        return c.fetchone()


def recibidas(cn, num_pedc):
    with cn.cursor() as c:
        c.execute("""SELECT LINEA_PEDCLIN, CANTIDAD_PEDCLIN,
                            CANTIDAD_RECIBIDA_PEDCLIN, CODIGO_ALMACEN_PEDCLIN
                       FROM fza_pedidos_compra_lineas
                      WHERE SERIE_PEDC_PEDCLIN='ZZ'
                        AND NUMERO_PEDC_PEDCLIN=%s
                      ORDER BY LINEA_PEDCLIN""", (num_pedc,))
        return {r['LINEA_PEDCLIN']: r for r in c.fetchall()}


def estado_pedido(cn, num_pedc):
    with cn.cursor() as c:
        c.execute("SELECT ESTADO_PEDC FROM fza_pedidos_compra "
                  "WHERE SERIE_PEDC='ZZ' AND NUMERO_PEDC=%s", (num_pedc,))
        r = c.fetchone()
        return r['ESTADO_PEDC'] if r else None


# ---------------------------------------------------------------------
# Pruebas
# ---------------------------------------------------------------------

def t1_wrapper_equivale_a_celdas(cn):
    print('\nT1 — El wrapper "todo lo pendiente" == llamada con celdas')
    n1 = clonar_pedido_simple(cn, '900001')
    clonar_pedido_simple(cn, '900002')
    ok1, alb1, msg1 = crear_albaran_desde_pedido(
        cn, 'ZZ', '900001', ALM, SERIE_ALBC, USUARIO)
    # Camino B: construimos las celdas a mano (lo que hace el pivote
    # cuando el usuario teclea "todo lo pendiente" celda a celda).
    with cn.cursor() as c:
        c.execute(SQL_PENDIENTES, ('ZZ', '900002', ALM))
        celdas = [{'LineaPedido': r['LINEA_PEDCLIN'],
                   'CodigoSku': r['CODIGO_UNIDAD_PEDCLIN'],
                   'CodigoAlmacen': ALM,
                   'Cantidad': float(r['PENDIENTE'])} for r in c.fetchall()]
    ok2, alb2, msg2 = crear_albaran_con_cantidades(
        cn, 'ZZ', '900002', ALM, SERIE_ALBC, USUARIO, celdas)
    check('ambos caminos devuelven exito', ok1 and ok2,
          '%s / %s' % (msg1, msg2))
    l1, l2 = lineas_albaran(cn, alb1), lineas_albaran(cn, alb2)
    check('mismo numero de lineas (%d)' % len(l1), len(l1) == len(l2) == n1,
          '%d vs %d vs %d' % (len(l1), len(l2), n1))
    iguales = all(
        (a['LINEA_ALBCLIN'], a['LINEA_PEDC_ALBCLIN'], a['CODIGO_ART_ALBCLIN'],
         a['CODIGO_UNIDAD_ALBCLIN'], a['CANTIDAD_ALBCLIN'],
         a['PORCENTAJE_IVA_ALBCLIN'], a['TIPO_IVA_ARTICULO_ALBCLIN'],
         a['TOTAL_ALBCLIN'], a['CODIGO_ALMACEN_ALBCLIN']) ==
        (b['LINEA_ALBCLIN'], b['LINEA_PEDC_ALBCLIN'], b['CODIGO_ART_ALBCLIN'],
         b['CODIGO_UNIDAD_ALBCLIN'], b['CANTIDAD_ALBCLIN'],
         b['PORCENTAJE_IVA_ALBCLIN'], b['TIPO_IVA_ARTICULO_ALBCLIN'],
         b['TOTAL_ALBCLIN'], b['CODIGO_ALMACEN_ALBCLIN'])
        for a, b in zip(l1, l2))
    check('lineas identicas campo a campo', iguales)
    c1, c2 = cab_albaran(cn, alb1), cab_albaran(cn, alb2)
    check('totales de cabecera identicos',
          (c1['TOTAL_BRUTO_ALBC'], c1['TOTAL_BASES_ALBC'],
           c1['TOTAL_IMPUESTOS_ALBC'], c1['TOTAL_LIQUIDO_ALBC'],
           c1['CONTADOR_LINEAS_ALBC']) ==
          (c2['TOTAL_BRUTO_ALBC'], c2['TOTAL_BASES_ALBC'],
           c2['TOTAL_IMPUESTOS_ALBC'], c2['TOTAL_LIQUIDO_ALBC'],
           c2['CONTADOR_LINEAS_ALBC']),
          '%s vs %s' % (c1, c2))
    check('recibidas identicas en los dos pedidos',
          [(k, v['CANTIDAD_RECIBIDA_PEDCLIN'])
           for k, v in recibidas(cn, '900001').items()] ==
          [(k, v['CANTIDAD_RECIBIDA_PEDCLIN'])
           for k, v in recibidas(cn, '900002').items()])
    check('estado del pedido = RECIBIDO en ambos',
          estado_pedido(cn, '900001') == 'RECIBIDO' ==
          estado_pedido(cn, '900002'),
          '%s / %s' % (estado_pedido(cn, '900001'),
                       estado_pedido(cn, '900002')))
    return alb1


def t2_tope_por_linea(cn):
    print('\nT2 — Tope por linea: varias celdas sobre la misma linea')
    clonar_pedido_simple(cn, '900003')
    with cn.cursor() as c:
        c.execute(SQL_PENDIENTES, ('ZZ', '900003', ALM))
        filas = c.fetchall()
    prim = filas[0]
    pend = float(prim['PENDIENTE'])
    # Tres celdas sobre la MISMA linea que suman el triple del pendiente.
    celdas = [{'LineaPedido': prim['LINEA_PEDCLIN'],
               'CodigoSku': prim['CODIGO_UNIDAD_PEDCLIN'],
               'CodigoAlmacen': ALM, 'Cantidad': pend} for _ in range(3)]
    ok, alb, msg = crear_albaran_con_cantidades(
        cn, 'ZZ', '900003', ALM, SERIE_ALBC, USUARIO, celdas)
    check('se crea el albaran', ok, msg)
    lin = lineas_albaran(cn, alb)
    total = sum(float(x['CANTIDAD_ALBCLIN']) for x in lin)
    check('cantidad total recibida == pendiente (%.2f), no el triple' % pend,
          abs(total - pend) < 1e-6, 'recibido %.4f' % total)
    check('solo se crea 1 linea de albaran (las otras 2 celdas caen a 0)',
          len(lin) == 1, '%d lineas' % len(lin))
    rec = recibidas(cn, '900003')[prim['LINEA_PEDCLIN']]
    check('CANTIDAD_RECIBIDA no supera CANTIDAD_PEDCLIN',
          float(rec['CANTIDAD_RECIBIDA_PEDCLIN']) <=
          float(rec['CANTIDAD_PEDCLIN']) + 1e-9,
          '%s > %s' % (rec['CANTIDAD_RECIBIDA_PEDCLIN'],
                       rec['CANTIDAD_PEDCLIN']))


def t3_filtro_almacen(cn):
    print('\nT3 — Filtro de almacen')
    n = clonar_pedido_simple(cn, '900004', con_linea_otro_almacen=True)
    ok, alb, msg = crear_albaran_desde_pedido(
        cn, 'ZZ', '900004', ALM, SERIE_ALBC, USUARIO)
    check('se crea el albaran', ok, msg)
    lin = lineas_albaran(cn, alb)
    check('la linea de %s queda fuera (%d de %d lineas)'
          % (ALM_OTRO, len(lin), n), len(lin) == n - 1,
          '%d lineas' % len(lin))
    rec = recibidas(cn, '900004')
    otras = [v for v in rec.values()
             if v['CODIGO_ALMACEN_PEDCLIN'] == ALM_OTRO]
    check('la linea de otro almacen sigue con recibida 0',
          all(float(v['CANTIDAD_RECIBIDA_PEDCLIN']) == 0 for v in otras))
    check('el pedido queda PARCIAL (queda pendiente en otro almacen)',
          estado_pedido(cn, '900004') == 'PARCIAL',
          estado_pedido(cn, '900004'))
    check('todas las lineas del albaran llevan almacen %s' % ALM,
          all(x['CODIGO_ALMACEN_ALBCLIN'] == ALM for x in lin))


def t4_sin_pendiente(cn):
    print('\nT4 — Sin pendiente: ni albaran ni cabecera huerfana')
    clonar_pedido_simple(cn, '900005')
    ok1, alb1, _ = crear_albaran_desde_pedido(
        cn, 'ZZ', '900005', ALM, SERIE_ALBC, USUARIO)
    with cn.cursor() as c:
        c.execute("SELECT COUNT(*) n FROM fza_albaranes_compra "
                  "WHERE SERIE_ALBC=%s", (SERIE_ALBC,))
        antes = c.fetchone()['n']
    ok2, alb2, msg2 = crear_albaran_desde_pedido(
        cn, 'ZZ', '900005', ALM, SERIE_ALBC, USUARIO)
    with cn.cursor() as c:
        c.execute("SELECT COUNT(*) n FROM fza_albaranes_compra "
                  "WHERE SERIE_ALBC=%s", (SERIE_ALBC,))
        despues = c.fetchone()['n']
    check('la primera vez crea albaran', ok1)
    check('la segunda vez devuelve False', not ok2)
    check('mensaje "No hay lineas pendientes"',
          'No hay lineas pendientes' in msg2, msg2)
    check('no se crea ninguna cabecera nueva', antes == despues,
          '%d -> %d' % (antes, despues))


def t5_cabecera_huerfana_se_borra(cn):
    print('\nT5 — Celdas con pendiente 0: cabecera creada y borrada')
    clonar_pedido_simple(cn, '900006')
    with cn.cursor() as c:
        c.execute(SQL_PENDIENTES, ('ZZ', '900006', ALM))
        filas = c.fetchall()
    celdas = [{'LineaPedido': r['LINEA_PEDCLIN'],
               'CodigoSku': r['CODIGO_UNIDAD_PEDCLIN'],
               'CodigoAlmacen': ALM,
               'Cantidad': float(r['PENDIENTE'])} for r in filas]
    crear_albaran_con_cantidades(cn, 'ZZ', '900006', ALM, SERIE_ALBC,
                                 USUARIO, celdas)
    with cn.cursor() as c:
        c.execute("SELECT COUNT(*) n FROM fza_albaranes_compra "
                  "WHERE SERIE_ALBC=%s", (SERIE_ALBC,))
        antes = c.fetchone()['n']
    # Segunda pasada con las MISMAS celdas: ya no hay pendiente, asi que
    # la cabecera se crea y debe borrarse sola.
    ok, alb, msg = crear_albaran_con_cantidades(
        cn, 'ZZ', '900006', ALM, SERIE_ALBC, USUARIO, celdas)
    with cn.cursor() as c:
        c.execute("SELECT COUNT(*) n FROM fza_albaranes_compra "
                  "WHERE SERIE_ALBC=%s", (SERIE_ALBC,))
        despues = c.fetchone()['n']
        c.execute("SELECT COUNT(*) n FROM fza_albaranes_compra a "
                  "WHERE a.SERIE_ALBC=%s AND NOT EXISTS ("
                  "  SELECT 1 FROM fza_albaranes_compra_lineas l "
                  "   WHERE l.SERIE_ALBC_ALBCLIN=a.SERIE_ALBC "
                  "     AND l.NUMERO_ALBC_ALBCLIN=a.NUMERO_ALBC)",
                  (SERIE_ALBC,))
        huerfanas = c.fetchone()['n']
    check('devuelve False', not ok, msg)
    check('el numero de albaranes no cambia', antes == despues,
          '%d -> %d' % (antes, despues))
    check('no queda ninguna cabecera sin lineas', huerfanas == 0,
          '%d huerfanas' % huerfanas)


def t6_estados_y_cancelado(cn):
    print('\nT6 — Estados del pedido y respeto a CANCELADO')
    clonar_pedido_simple(cn, '900007')
    check('arranca ABIERTO', estado_pedido(cn, '900007') == 'ABIERTO',
          estado_pedido(cn, '900007'))
    with cn.cursor() as c:
        c.execute(SQL_PENDIENTES, ('ZZ', '900007', ALM))
        filas = c.fetchall()
    # Recepcion parcial: solo la primera linea, mitad de cantidad.
    prim = filas[0]
    celdas = [{'LineaPedido': prim['LINEA_PEDCLIN'],
               'CodigoSku': prim['CODIGO_UNIDAD_PEDCLIN'],
               'CodigoAlmacen': ALM,
               'Cantidad': float(prim['PENDIENTE']) / 2.0}]
    crear_albaran_con_cantidades(cn, 'ZZ', '900007', ALM, SERIE_ALBC,
                                 USUARIO, celdas)
    check('tras recepcion parcial queda PARCIAL',
          estado_pedido(cn, '900007') == 'PARCIAL',
          estado_pedido(cn, '900007'))
    crear_albaran_desde_pedido(cn, 'ZZ', '900007', ALM, SERIE_ALBC, USUARIO)
    check('tras recibir el resto queda RECIBIDO',
          estado_pedido(cn, '900007') == 'RECIBIDO',
          estado_pedido(cn, '900007'))
    # CANCELADO no se pisa
    clonar_pedido_simple(cn, '900008')
    with cn.cursor() as c:
        c.execute("UPDATE fza_pedidos_compra SET ESTADO_PEDC='CANCELADO' "
                  "WHERE SERIE_PEDC='ZZ' AND NUMERO_PEDC='900008'")
    crear_albaran_desde_pedido(cn, 'ZZ', '900008', ALM, SERIE_ALBC, USUARIO)
    check('un pedido CANCELADO no se reescribe a RECIBIDO',
          estado_pedido(cn, '900008') == 'CANCELADO',
          estado_pedido(cn, '900008'))


def t7_numeracion(cn, num_albc):
    print('\nT7 — Numeracion de lineas y contador de cabecera')
    lin = lineas_albaran(cn, num_albc)
    esperado = ['%04d' % (10 * (i + 1)) for i in range(len(lin))]
    check('lineas numeradas 0010, 0020, ... (%d)' % len(lin),
          [x['LINEA_ALBCLIN'] for x in lin] == esperado,
          str([x['LINEA_ALBCLIN'] for x in lin][:5]))
    cab = cab_albaran(cn, num_albc)
    check('CONTADOR_LINEAS_ALBC = LPAD(n*10, 8)',
          cab['CONTADOR_LINEAS_ALBC'] == '%08d' % (len(lin) * 10),
          cab['CONTADOR_LINEAS_ALBC'])
    check('el albaran queda CERRADO', cab['ESTADO_ALBC'] == 'CERRADO',
          cab['ESTADO_ALBC'])
    check('la cabecera apunta al pedido origen',
          cab['SERIE_PED_ALBC'] == 'ZZ' and cab['NUMERO_PED_ALBC'],
          str(cab['SERIE_PED_ALBC']))


def t8_atomicidad(cn):
    print('\nT8 — Atomicidad (bTransPropia de UniDataPedidos)')
    clonar_pedido_simple(cn, '900009')
    rec_antes = {k: float(v['CANTIDAD_RECIBIDA_PEDCLIN'])
                 for k, v in recibidas(cn, '900009').items()}
    with cn.cursor() as c:
        c.execute("SELECT COUNT(*) n FROM fza_albaranes_compra "
                  "WHERE SERIE_ALBC=%s", (SERIE_ALBC,))
        alb_antes = c.fetchone()['n']
    cn.autocommit(False)
    try:
        crear_albaran_desde_pedido(cn, 'ZZ', '900009', ALM, SERIE_ALBC,
                                   USUARIO)
        # Fallo inyectado DESPUES de crear el albaran, como si reventara
        # GenerarMovimientosDesdeAlbaranCompra.
        raise RuntimeError('fallo simulado en movimientos')
    except RuntimeError:
        cn.rollback()
    finally:
        cn.autocommit(True)
    rec_despues = {k: float(v['CANTIDAD_RECIBIDA_PEDCLIN'])
                   for k, v in recibidas(cn, '900009').items()}
    with cn.cursor() as c:
        c.execute("SELECT COUNT(*) n FROM fza_albaranes_compra "
                  "WHERE SERIE_ALBC=%s", (SERIE_ALBC,))
        alb_despues = c.fetchone()['n']
    check('el rollback no deja albaran', alb_antes == alb_despues,
          '%d -> %d' % (alb_antes, alb_despues))
    check('el rollback no deja cantidades recibidas',
          rec_antes == rec_despues)
    check('el pedido sigue ABIERTO', estado_pedido(cn, '900009') == 'ABIERTO',
          estado_pedido(cn, '900009'))


def t9_exento_intracomunitario(cn):
    print('\nT9 — Exento intracomunitario fuerza IVA E al 0 %')
    clonar_pedido_simple(cn, '900010')
    with cn.cursor() as c:
        c.execute("UPDATE fza_pedidos_compra "
                  "   SET ESIVA_EXENTO_INTRACOMUNITARIO_PEDC='S' "
                  " WHERE SERIE_PEDC='ZZ' AND NUMERO_PEDC='900010'")
    ok, alb, msg = crear_albaran_desde_pedido(
        cn, 'ZZ', '900010', ALM, SERIE_ALBC, USUARIO)
    check('se crea el albaran', ok, msg)
    lin = lineas_albaran(cn, alb)
    check('todas las lineas con TIPO_IVA = E',
          all(x['TIPO_IVA_ARTICULO_ALBCLIN'] == 'E' for x in lin))
    check('todas las lineas con PORCENTAJE_IVA = 0',
          all(float(x['PORCENTAJE_IVA_ALBCLIN']) == 0 for x in lin))
    cab = cab_albaran(cn, alb)
    check('la cabecera no lleva impuestos',
          float(cab['TOTAL_IMPUESTOS_ALBC']) == 0,
          str(cab['TOTAL_IMPUESTOS_ALBC']))
    check('liquido == bases', abs(float(cab['TOTAL_LIQUIDO_ALBC']) -
                                  float(cab['TOTAL_BASES_ALBC'])) < 1e-6)


def main():
    cn = conn()
    try:
        limpiar(cn)
        alb1 = t1_wrapper_equivale_a_celdas(cn)
        t2_tope_por_linea(cn)
        t3_filtro_almacen(cn)
        t4_sin_pendiente(cn)
        t5_cabecera_huerfana_se_borra(cn)
        t6_estados_y_cancelado(cn)
        t7_numeracion(cn, alb1)
        t8_atomicidad(cn)
        t9_exento_intracomunitario(cn)
    finally:
        limpiar(cn)
        cn.close()
    print('\n%s' % ('-' * 60))
    print('Resultado: %d OK, %d FALLOS' % (_ok, _ko))
    return 0 if _ko == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
