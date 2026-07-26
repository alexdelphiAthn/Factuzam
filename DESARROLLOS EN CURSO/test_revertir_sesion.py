# -*- coding: utf-8 -*-
# Prueba del refactor 1.5: RevertirMaterializacion sin except silenciados.
# Replica el flujo NUEVO: TablaExiste una vez + pasos guardados + fallo
# real del DELETE de fza_compras_sesiones_documentos -> aborta con rollback.
import pymysql, sys

def conn():
    return pymysql.connect(unix_socket='/var/run/mysqld/mysqld.sock',
                           database='factuzam_test', charset='utf8mb4',
                           autocommit=True,
                           init_command="SET collation_connection='utf8mb4_spanish_ci'")

def tabla_existe(c, t):
    cur = c.cursor()
    cur.execute("SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=%s", (t,))
    return cur.fetchone()[0] > 0

def foto_sesion(c, s, n):
    cur = c.cursor()
    cur.execute("SELECT ESTADO_SES, COALESCE(NUMERO_PEDC_SES,''), COALESCE(NUMERO_ALBC_SES,'') FROM fza_compras_sesiones WHERE SERIE_SES=%s AND NUMERO_SES=%s", (s, n))
    est = cur.fetchone()
    cur.execute("SELECT COUNT(*) FROM fza_compras_sesiones_documentos WHERE SERIE_SES_SESDOC=%s AND NUMERO_SES_SESDOC=%s", (s, n))
    docs = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM fza_movimientos_almacen WHERE TIPO_DOC_MOV='AC' AND NUMERO_DOC_MOV=%s", (n,))
    movs = cur.fetchone()[0]
    return dict(estado=est[0], ped=est[1], alb=est[2], docs=docs, movs=movs)

def revertir(c, s, n, usuario='TEST'):
    """Flujo nuevo simplificado: pasos clave con guards, transaccion, rollback."""
    tiene_docs = tabla_existe(c, 'fza_compras_sesiones_documentos')
    tiene_pdr  = tabla_existe(c, 'fza_articulos_pdte_recibir')
    cur = c.cursor()
    c.begin()
    try:
        if tiene_docs:                            # 0j-bis: CRITICO, sin trago
            cur.execute("DELETE FROM fza_compras_sesiones_documentos WHERE SERIE_SES_SESDOC=%s AND NUMERO_SES_SESDOC=%s", (s, n))
        cur.execute("DELETE FROM fza_movimientos_almacen WHERE TIPO_DOC_MOV='AC' AND NUMERO_DOC_MOV=%s", (n,))
        if tiene_pdr:
            cur.execute("DELETE FROM fza_articulos_pdte_recibir WHERE NUMERO_DOC_PDR=%s", (n,))
        cur.execute("""UPDATE fza_compras_sesiones SET ESTADO_SES='BORRADOR',
                       INSTANTE_MATERIALIZA_SES=NULL, USUARIO_MATERIALIZA_SES=NULL,
                       SERIE_PEDC_SES=NULL, NUMERO_PEDC_SES=NULL,
                       SERIE_ALBC_SES=NULL, NUMERO_ALBC_SES=NULL,
                       MENSAJE_ERROR_SES=NULL, INSTANTE_MODIF=NOW(), USUARIO_MODIF=%s
                       WHERE SERIE_SES=%s AND NUMERO_SES=%s""", (usuario, s, n))
        c.commit()
        return None
    except Exception as e:
        c.rollback()
        return e

res = []
def check(nom, cond, det=''):
    res.append(('PASA' if cond else 'FALLA', nom, det))

c = conn()

# T1: TablaExiste
check('T1 TablaExiste true/false',
      tabla_existe(c, 'fza_compras_sesiones_documentos') and not tabla_existe(c, 'tabla_inexistente_xyz'))

# T2: reversion feliz de una sesion CERRADA con documentos
cur = c.cursor()
cur.execute("""SELECT SERIE_SES_SESDOC, NUMERO_SES_SESDOC FROM fza_compras_sesiones_documentos d
               JOIN fza_compras_sesiones s ON s.SERIE_SES=d.SERIE_SES_SESDOC AND s.NUMERO_SES=d.NUMERO_SES_SESDOC
               WHERE s.ESTADO_SES='CERRADA' LIMIT 1""")
row = cur.fetchone()
if row:
    s, n = row
    antes = foto_sesion(c, s, n)
    err = revertir(c, s, n)
    despues = foto_sesion(c, s, n)
    check('T2 reversion feliz -> BORRADOR y docs/movs a 0',
          err is None and despues['estado'] == 'BORRADOR' and despues['docs'] == 0 and despues['movs'] == 0,
          f'{s}/{n} antes={antes} despues={despues}')
else:
    check('T2 reversion feliz', False, 'sin sesion CERRADA con documentos en demo')

# T3: DELETE de documentos bloqueado -> aborta TODO (antes se tragaba y seguia)
cur.execute("""SELECT SERIE_SES_SESDOC, NUMERO_SES_SESDOC FROM fza_compras_sesiones_documentos d
               JOIN fza_compras_sesiones s ON s.SERIE_SES=d.SERIE_SES_SESDOC AND s.NUMERO_SES=d.NUMERO_SES_SESDOC
               WHERE s.ESTADO_SES='CERRADA' LIMIT 1""")
row = cur.fetchone()
if row:
    s, n = row
    antes = foto_sesion(c, s, n)
    bloq = conn(); bloq.begin()
    bloq.cursor().execute("SELECT * FROM fza_compras_sesiones_documentos WHERE SERIE_SES_SESDOC=%s AND NUMERO_SES_SESDOC=%s FOR UPDATE", (s, n))
    c.cursor().execute("SET SESSION innodb_lock_wait_timeout = 2")
    err = revertir(c, s, n)
    bloq.rollback(); bloq.close()
    despues = foto_sesion(c, s, n)
    check('T3 fallo en 0j-bis -> reversion abortada, sesion sigue CERRADA e integra',
          err is not None and antes == despues and despues['estado'] == 'CERRADA',
          f'{s}/{n} error={type(err).__name__} antes={antes} despues={despues}')
else:
    check('T3', False, 'sin datos')

# T4: comportamiento ANTIGUO ante el mismo fallo: el except vacio seguia
# adelante -> sesion BORRADOR pero documentos vivos (duplicaria al rematerializar)
cur.execute("""SELECT SERIE_SES_SESDOC, NUMERO_SES_SESDOC FROM fza_compras_sesiones_documentos d
               JOIN fza_compras_sesiones s ON s.SERIE_SES=d.SERIE_SES_SESDOC AND s.NUMERO_SES=d.NUMERO_SES_SESDOC
               WHERE s.ESTADO_SES='CERRADA' LIMIT 1""")
row = cur.fetchone()
if row:
    s, n = row
    bloq = conn(); bloq.begin()
    bloq.cursor().execute("SELECT * FROM fza_compras_sesiones_documentos WHERE SERIE_SES_SESDOC=%s AND NUMERO_SES_SESDOC=%s FOR UPDATE", (s, n))
    cur2 = c.cursor()
    c.begin()
    try:
        try:
            cur2.execute("SET SESSION innodb_lock_wait_timeout = 2")
            cur2.execute("DELETE FROM fza_compras_sesiones_documentos WHERE SERIE_SES_SESDOC=%s AND NUMERO_SES_SESDOC=%s", (s, n))
        except Exception:
            pass                                   # el except vacio antiguo
        cur2.execute("UPDATE fza_compras_sesiones SET ESTADO_SES='BORRADOR' WHERE SERIE_SES=%s AND NUMERO_SES=%s", (s, n))
        c.commit()
    except Exception as e:
        c.rollback()
    bloq.rollback(); bloq.close()
    despues = foto_sesion(c, s, n)
    check('T4 codigo antiguo: sesion BORRADOR con documentos vivos (bug demostrado)',
          despues['estado'] == 'BORRADOR' and despues['docs'] > 0,
          f'{s}/{n} despues={despues}')
else:
    check('T4', False, 'sin datos')

print('=' * 70)
for st, nom, det in res:
    print(f'[{st}] {nom}')
    if det:
        print(f'        {det}')
fallos = sum(1 for st, _, _ in res if st == 'FALLA')
print('=' * 70, f'\nTotal: {len(res)} pruebas, {fallos} fallos')
sys.exit(1 if fallos else 0)
