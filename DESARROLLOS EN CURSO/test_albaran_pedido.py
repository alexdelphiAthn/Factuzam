# -*- coding: utf-8 -*-
# Replica la secuencia de TdmPedidos.CrearAlbaranDesdePedido tras el
# refactor 1.3: transaccion bTransPropia alrededor de INICIO+LINEA*+FIN.
import pymysql, sys

def conn():
    return pymysql.connect(unix_socket='/var/run/mysqld/mysqld.sock',
                           database='factuzam_test', charset='utf8mb4',
                           autocommit=True,
                           init_command="SET collation_connection='utf8mb4_spanish_ci'")

def estado(c, sped, nped):
    cur = c.cursor()
    cur.execute("SELECT COUNT(*) FROM fza_albaranes WHERE NUMERO_PED_ALB=%s AND SERIE_PED_ALB=%s", (nped, sped))
    nalb_cab = cur.fetchone()[0]
    cur.execute("""SELECT COUNT(*) FROM fza_albaranes_lineas al
                   JOIN fza_albaranes a ON a.SERIE_ALB=al.SERIE_ALB_ALBLIN AND a.NUMERO_ALB=al.NUMERO_ALB_ALBLIN
                   WHERE a.NUMERO_PED_ALB=%s AND a.SERIE_PED_ALB=%s""", (nped, sped))
    nalb_lin = cur.fetchone()[0]
    cur.execute("SELECT ESTADO_PED FROM fza_pedidos WHERE SERIE_PED=%s AND NUMERO_PED=%s", (sped, nped))
    est = cur.fetchone()[0]
    cur.execute("SELECT COALESCE(SUM(CANTIDAD_ENTREGADA_PEDLIN),0) FROM fza_pedidos_lineas WHERE SERIE_PED_PEDLIN=%s AND NUMERO_PED_PEDLIN=%s", (sped, nped))
    servida = float(cur.fetchone()[0])
    return dict(alb_cab=nalb_cab, alb_lin=nalb_lin, estado=est, servida=servida)

def lineas_pendientes(c, sped, nped):
    cur = c.cursor()
    cur.execute("""SELECT LINEA_PEDLIN, COALESCE(CANTIDAD_PENDIENTE_PEDLIN, CANTIDAD_PEDLIN - COALESCE(CANTIDAD_ENTREGADA_PEDLIN,0))
                   FROM fza_pedidos_lineas
                   WHERE SERIE_PED_PEDLIN=%s AND NUMERO_PED_PEDLIN=%s""", (sped, nped))
    return [(l, float(q)) for l, q in cur.fetchall() if float(q) > 0]

def crear_albaran(c, sped, nped, lineas, alm='01', usuario='TEST', fallar_en_fin=False, adm=None):
    """Secuencia NUEVA con transaccion. fallar_en_fin simula caida a mitad."""
    cur = c.cursor()
    c.begin()                                   # StartTransaction
    try:
        cur.execute("CALL PRC_PED_CREAR_ALBARAN_INICIO(%s,%s,%s,@nalb,@salb)", (nped, sped, usuario))
        cur.execute("SELECT @nalb,@salb"); nalb, salb = cur.fetchone()
        for lin, cant in lineas:
            cur.execute("CALL PRC_PED_CREAR_ALBARAN_LINEA(%s,%s,%s,%s,%s,%s,%s,%s)",
                        (nalb, salb, nped, sped, lin, cant, alm, usuario))
        if fallar_en_fin:
            adm.cursor().execute("RENAME TABLE fza_albaranes_lineas TO fza_albaranes_lineas_x")
        try:
            cur.execute("CALL PRC_PED_CREAR_ALBARAN_FIN(%s,%s,%s,%s,%s)", (nalb, salb, nped, sped, usuario))
        finally:
            if fallar_en_fin:
                adm.cursor().execute("RENAME TABLE fza_albaranes_lineas_x TO fza_albaranes_lineas")
        c.commit()                              # Commit
        return None, (nalb, salb)
    except Exception as e:
        c.rollback()                            # Rollback + raise
        return e, (None, None)

res = []
def check(nombre, cond, det=''):
    res.append(('PASA' if cond else 'FALLA', nombre, det))

c = conn(); adm = conn()

# ---------- T1: creacion feliz de albaran desde pedido ----------
sped, nped = 'PED', '000001'
antes = estado(c, sped, nped)
pend = lineas_pendientes(c, sped, nped)
err, (nalb, salb) = crear_albaran(c, sped, nped, pend)
despues = estado(c, sped, nped)
check('T1 albaran creado atomicamente',
      err is None and despues['alb_cab'] == antes['alb_cab'] + 1 and
      despues['alb_lin'] == antes['alb_lin'] + len(pend),
      f'albaran={salb}/{nalb} lineas={len(pend)} antes={antes} despues={despues}')

# ---------- T2: fallo en el paso FIN -> ni cabecera ni lineas ni estado ----------
sped, nped = 'PED', '000002'
antes = estado(c, sped, nped)
pend = lineas_pendientes(c, sped, nped)
err, _ = crear_albaran(c, sped, nped, pend, fallar_en_fin=True, adm=adm)
despues = estado(c, sped, nped)
check('T2 fallo a mitad -> rollback total (sin albaran fantasma)',
      err is not None and antes == despues,
      f'error={type(err).__name__} antes={antes} despues={despues}')

# ---------- T3: contador de albaranes no se corrompe tras el rollback ----------
# tras T2, crear otro albaran valido: el numero no debe chocar con el que se
# reservo dentro de la transaccion abortada
err, (nalb2, salb2) = crear_albaran(c, sped, nped, pend)
despues = estado(c, sped, nped)
check('T3 tras rollback, la siguiente creacion funciona',
      err is None and despues['alb_cab'] == antes['alb_cab'] + 1,
      f'albaran={salb2}/{nalb2} err={err} despues={despues}')

# ---------- T4: dos creaciones concurrentes no duplican numero ----------
c2 = conn()
sped, nped = 'PED', '000003'
pend = lineas_pendientes(c, sped, nped)
if len(pend) >= 2:
    l1, l2 = [pend[0]], [pend[1]]
else:
    l1 = l2 = pend
e1, (na1, sa1) = crear_albaran(c, sped, nped, l1)
e2, (na2, sa2) = crear_albaran(c2, sped, nped, l2)
check('T4 dos albaranes seguidos con numeros distintos',
      e1 is None and e2 is None and (na1, sa1) != (na2, sa2),
      f'alb1={sa1}/{na1} alb2={sa2}/{na2}')

print('=' * 70)
for st, nom, det in res:
    print(f'[{st}] {nom}')
    if det:
        print(f'        {det}')
fallos = sum(1 for st, _, _ in res if st == 'FALLA')
print('=' * 70, f'\nTotal parcial: {len(res)} pruebas, {fallos} fallos')

# ---------- T5: fallo en FIN con lineas YA insertadas -> lineas y contadores del pedido revertidos ----------
def contadores_pedido(c, sped, nped):
    cur = c.cursor()
    cur.execute("""SELECT LINEA_PEDLIN, CANTIDAD_ENTREGADA_PEDLIN, ESENTREGADA_PEDLIN
                   FROM fza_pedidos_lineas WHERE SERIE_PED_PEDLIN=%s AND NUMERO_PED_PEDLIN=%s ORDER BY 1""", (sped, nped))
    return cur.fetchall()

sped, nped = 'PED', '000002'
cur = c.cursor()
cur.execute("SELECT LINEA_PEDLIN, CANTIDAD_PEDLIN FROM fza_pedidos_lineas WHERE SERIE_PED_PEDLIN=%s AND NUMERO_PED_PEDLIN=%s", (sped, nped))
todas = [(l, float(q)) for l, q in cur.fetchall()]          # el SP recalcula pendiente el mismo
antes_e  = estado(c, sped, nped)
antes_ct = contadores_pedido(c, sped, nped)
# inyeccion de fallo: otra sesion bloquea la fila del pedido; el UPDATE
# fza_pedidos del paso FIN caduca por lock wait (igual que la B6)
bloq = conn()
bloq.begin()
bloq.cursor().execute("SELECT * FROM fza_pedidos WHERE SERIE_PED=%s AND NUMERO_PED=%s FOR UPDATE", (sped, nped))
c.cursor().execute("SET SESSION innodb_lock_wait_timeout = 2")
err, _ = crear_albaran(c, sped, nped, todas)
bloq.rollback(); bloq.close()
despues_e  = estado(c, sped, nped)
despues_ct = contadores_pedido(c, sped, nped)
check('T5 fallo con lineas insertadas -> lineas de albaran y contadores del pedido revertidos',
      err is not None and antes_e == despues_e and antes_ct == despues_ct,
      f'error={type(err).__name__} alb_lin {antes_e["alb_lin"]}=={despues_e["alb_lin"]} entregadas intactas={antes_ct == despues_ct}')

print('=' * 70)
st, nom, det = res[-1]
print(f'[{st}] {nom}')
print(f'        {det}')
sys.exit(1 if st == 'FALLA' else 0)
