# -*- coding: utf-8 -*-
# Replica la secuencia SQL EXACTA de TdmFacturas.unqryTablaGBeforeDelete
# (tras el refactor 1.1) y verifica atomicidad como en el plan de pruebas.
import pymysql, sys

def conn():
    return pymysql.connect(unix_socket='/var/run/mysqld/mysqld.sock',
                           db='factuzam_test', charset='utf8mb4', autocommit=True, init_command="SET collation_connection='utf8mb4_spanish_ci'")

def counts(c, s, n):
    q = {}
    cur = c.cursor()
    for k, sql in [
      ('cab',  "SELECT COUNT(*) FROM fza_facturas WHERE SERIE_FAC=%s AND NUMERO_FAC=%s"),
      ('lin',  "SELECT COUNT(*) FROM fza_facturas_lineas WHERE SERIE_FAC_FACLIN=%s AND NUMERO_FAC_FACLIN=%s"),
      ('rec',  "SELECT COUNT(*) FROM fza_recibos WHERE SERIE_FAC_REC=%s AND NUMERO_FAC_REC=%s"),
      ('efv',  "SELECT COUNT(*) FROM fza_efectos_venta WHERE SERIE_FAC_EFV=%s AND NUMERO_FAC_EFV=%s"),
      ('mov',  "SELECT COUNT(*) FROM fza_movimientos_almacen WHERE SERIE_DOC_MOV=%s AND NUMERO_DOC_MOV=%s AND TIPO_DOC_MOV IN ('VE','FC')")]:
        cur.execute(sql, (s, n)); q[k] = cur.fetchone()[0]
    return q

def secuencia_borrado(c, s, n):
    """La secuencia del codigo NUEVO: transaccion + hijos + cabecera."""
    cur = c.cursor()
    c.begin()                                  # StartTransaction (BeforeDelete)
    try:
        cur.execute("DELETE FROM fza_efectos_venta WHERE SERIE_FAC_EFV=%s AND NUMERO_FAC_EFV=%s", (s, n))
        cur.execute("DELETE FROM fza_facturas_lineas WHERE SERIE_FAC_FACLIN=%s AND NUMERO_FAC_FACLIN=%s", (s, n))
        cur.execute("DELETE FROM fza_recibos WHERE SERIE_FAC_REC=%s AND NUMERO_FAC_REC=%s", (s, n))
        cur.execute("CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC('VE',%s,%s)", (s, n))
        cur.execute("CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC('FC',%s,%s)", (s, n))
        cur.execute("DELETE FROM fza_facturas WHERE NUMERO_FAC=%s AND SERIE_FAC=%s", (n, s))  # SQLDelete del dataset
        c.commit()                             # AfterDeleteTx
        return None
    except Exception as e:
        c.rollback()                           # DeleteErrorTx / except
        return e

def secuencia_borrado_VIEJA(c, s, n):
    """La secuencia ANTIGUA: autocommit, sin transaccion."""
    cur = c.cursor()
    cur.execute("DELETE FROM fza_efectos_venta WHERE SERIE_FAC_EFV=%s AND NUMERO_FAC_EFV=%s", (s, n))
    cur.execute("DELETE FROM fza_facturas_lineas WHERE SERIE_FAC_FACLIN=%s AND NUMERO_FAC_FACLIN=%s", (s, n))
    cur.execute("DELETE FROM fza_recibos WHERE SERIE_FAC_REC=%s AND NUMERO_FAC_REC=%s", (s, n))  # <- aqui falla
    cur.execute("CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC('VE',%s,%s)", (s, n))
    cur.execute("CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC('FC',%s,%s)", (s, n))
    cur.execute("DELETE FROM fza_facturas WHERE NUMERO_FAC=%s AND SERIE_FAC=%s", (n, s))

res = []
def check(nombre, cond, detalle=''):
    res.append(('PASA' if cond else 'FALLA', nombre, detalle))

c = conn(); adm = conn()

# ---------- T1 (B1): borrado feliz, todo desaparece ----------
s, n = 'A1', '000028'
antes = counts(c, s, n)
err = secuencia_borrado(c, s, n)
despues = counts(c, s, n)
check('T1/B1 borrado completo atomico', err is None and all(v == 0 for v in despues.values()),
      f'antes={antes} despues={despues}')

# ---------- T2 (B5): fallo a mitad (tabla renombrada) -> TODO intacto ----------
s, n = 'A1', '000030'
antes = counts(c, s, n)
adm.cursor().execute("RENAME TABLE fza_recibos TO fza_recibos_x")
err = secuencia_borrado(c, s, n)
adm.cursor().execute("RENAME TABLE fza_recibos_x TO fza_recibos")
despues = counts(c, s, n)
check('T2/B5 fallo a mitad -> rollback integro', err is not None and antes == despues,
      f'error={type(err).__name__} antes={antes} despues={despues}')

# ---------- T3 (B6): cabecera bloqueada por otra sesion -> rollback ----------
s, n = 'A1', '000027'
antes = counts(c, s, n)
otra = conn()
otra.begin()
otra.cursor().execute("SELECT * FROM fza_facturas WHERE SERIE_FAC=%s AND NUMERO_FAC=%s FOR UPDATE", (s, n))
c.cursor().execute("SET SESSION innodb_lock_wait_timeout = 2")
err = secuencia_borrado(c, s, n)
otra.rollback(); otra.close()
despues = counts(c, s, n)
check('T3/B6 lock en cabecera -> rollback integro', err is not None and antes == despues,
      f'error={type(err).__name__}: {err} | antes={antes} despues={despues}')

# ---------- T4: demostracion del bug ANTIGUO (sin transaccion) ----------
s, n = '2026.A1', '000135'
antes = counts(c, s, n)
adm.cursor().execute("RENAME TABLE fza_recibos TO fza_recibos_x")
try:
    secuencia_borrado_VIEJA(c, s, n)
    err = None
except Exception as e:
    err = e
adm.cursor().execute("RENAME TABLE fza_recibos_x TO fza_recibos")
despues = counts(c, s, n)
# el bug: cabecera viva pero lineas/efectos ya borrados
check('T4 codigo antiguo corrompe (esperado: cabecera viva sin lineas)',
      err is not None and despues['cab'] == 1 and despues['lin'] == 0,
      f'antes={antes} despues={despues}')

# ---------- T5 (B7): dos borrados consecutivos misma sesion ----------
s, n = 'A1', '000035'
e1 = secuencia_borrado(c, s, n)
d1 = counts(c, s, n)
s2, n2 = 'A1', '000031'
e2 = secuencia_borrado(c, s2, n2)
d2 = counts(c, s2, n2)
check('T5/B7 dos borrados seguidos', e1 is None and e2 is None and
      all(v == 0 for v in d1.values()) and all(v == 0 for v in d2.values()), '')

# ---------- T6: rollback tambien restaura lo borrado por el SP (cursor+SP anidado) ----------
s, n = '2026.A1', '000166'
antes = counts(c, s, n)
c.begin()
cur = c.cursor()
cur.execute("CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC('VE',%s,%s)", (s, n))
cur.execute("CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC('FC',%s,%s)", (s, n))
mid = counts(c, s, n)
c.rollback()
despues = counts(c, s, n)
check('T6 SP de movimientos respeta el rollback', mid['mov'] == 0 and despues == antes,
      f'antes={antes["mov"]} durante={mid["mov"]} despues={despues["mov"]}')

print(f'{"":=^70}')
for st, nom, det in res:
    print(f'[{st}] {nom}')
    if det:
        print(f'        {det}')
fallos = sum(1 for st, _, _ in res if st == 'FALLA')
print(f'{"":=^70}\nTotal: {len(res)} pruebas, {fallos} fallos')
sys.exit(1 if fallos else 0)
