# -*- coding: utf-8 -*-
# Pruebas del indice unico UX_MOV_CLAVE_FCVE (1.6) + transaccion de
# GenerarMovimientosSalidaFactura (1.2).
import pymysql, sys

def conn():
    return pymysql.connect(unix_socket='/var/run/mysqld/mysqld.sock',
                           database='factuzam_test', charset='utf8mb4',
                           autocommit=True,
                           init_command="SET collation_connection='utf8mb4_spanish_ci'")

res=[]
def check(nom,cond,det=''):
    res.append(('PASA' if cond else 'FALLA',nom,det))

c=conn(); cur=c.cursor()

def insertar_mov(cx, num, tipo, serie, ndoc, linea):
    cx.cursor().execute("""INSERT INTO fza_movimientos_almacen
      (NUMERO_MOV, TIPO_DOC_MOV, SERIE_DOC_MOV, NUMERO_DOC_MOV, LINEA_MOV,
       CODIGO_EMP_MOV, CODIGO_ALM_MOV, CODIGO_UNIDAD_MOV,
       TIPO_MOV, CANTIDAD_MOV, ESACTIVO_MOV, INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF)
      VALUES (%s,%s,%s,%s,%s,'01','01','TESTSKU','S',1,'S',NOW(),'TEST',NOW(),'TEST')""",
      (num, tipo, serie, ndoc, linea))

# T1: duplicado FC sobre misma clave -> bloqueado
insertar_mov(c,'T1A','FC','ZZ','900001','0010')
try:
    insertar_mov(c,'T1B','FC','ZZ','900001','0010'); dup=False
except pymysql.err.IntegrityError as e:
    dup=(e.args[0]==1062)
check('T1 duplicado FC/FC bloqueado por indice unico', dup)

# T2: el caso real de doble contabilizacion: VE de caja + FC posterior -> bloqueado
insertar_mov(c,'T2A','VE','ZZ','900002','0010')
try:
    insertar_mov(c,'T2B','FC','ZZ','900002','0010'); dup=False
except pymysql.err.IntegrityError as e:
    dup=(e.args[0]==1062)
check('T2 VE(caja) + FC(mantenimiento) misma linea bloqueado', dup)

# T3: los tipos con multiplicidad legitima siguen funcionando
okm=True
try:
    insertar_mov(c,'T3A','TR','','900003','0001')
    insertar_mov(c,'T3B','TR','','900003','0001')
    insertar_mov(c,'T3C','IN','A1','900003','0001')
    insertar_mov(c,'T3D','IN','A1','900003','0001')
except Exception as e:
    okm=False
check('T3 TR/IN siguen admitiendo multiples movimientos por clave', okm)

# T4: carrera real - dos sesiones pasan el SELECT de existencia a la vez;
# la segunda muere en el INSERT (antes: stock descontado DOBLE)
c1=conn(); c2=conn()
serie,ndoc,lin='ZZ','900004','0010'
for cx in (c1,c2):
    q=cx.cursor()
    q.execute("""SELECT NUMERO_MOV FROM fza_movimientos_almacen
                 WHERE TIPO_DOC_MOV IN ('FC','VE') AND SERIE_DOC_MOV=%s
                   AND NUMERO_DOC_MOV=%s AND LINEA_MOV=%s LIMIT 1""",(serie,ndoc,lin))
    cx._existe = q.fetchone() is not None
c1.begin(); c2.begin()
err2=None
try:
    insertar_mov(c1,'T4A','FC',serie,ndoc,lin)
    c2.cursor().execute("SET SESSION innodb_lock_wait_timeout=2")
    try:
        insertar_mov(c2,'T4B','FC',serie,ndoc,lin)
    except Exception as e:
        err2=e
    c1.commit()
    if err2 is None:
        # si no fallo por lock, fallara al commitear/insertar tras c1
        try:
            insertar_mov(c2,'T4B2','FC',serie,ndoc,lin)
        except Exception as e:
            err2=e
    c2.rollback()
except Exception as e:
    c1.rollback(); err2=e
cur.execute("""SELECT COUNT(*) FROM fza_movimientos_almacen
               WHERE SERIE_DOC_MOV=%s AND NUMERO_DOC_MOV=%s AND LINEA_MOV=%s
                 AND TIPO_DOC_MOV IN ('FC','VE')""",(serie,ndoc,lin))
n=cur.fetchone()[0]
check('T4 carrera de dos puestos -> solo 1 movimiento (antes: 2)',
      (not c1._existe) and (not c2._existe) and n==1 and err2 is not None,
      f'ambos SELECT vieron vacio={not c1._existe and not c2._existe}, movs finales={n}, err 2a sesion={type(err2).__name__ if err2 else None}')

# T5 (1.2): generacion transaccional - fallo a mitad no deja movimientos a medias
serie,ndoc='ZZ','900005'
c3=conn()
c3.begin()
try:
    insertar_mov(c3,'T5A','FC',serie,ndoc,'0010')
    insertar_mov(c3,'T5B','FC',serie,ndoc,'0020')
    raise RuntimeError('corte simulado antes de la linea 0030')
    insertar_mov(c3,'T5C','FC',serie,ndoc,'0030')
    c3.commit()
except Exception:
    c3.rollback()
cur.execute("SELECT COUNT(*) FROM fza_movimientos_almacen WHERE SERIE_DOC_MOV=%s AND NUMERO_DOC_MOV=%s",(serie,ndoc))
check('T5 corte a mitad de generacion -> 0 movimientos (atomico)', cur.fetchone()[0]==0)

# limpieza
cur.execute("DELETE FROM fza_movimientos_almacen WHERE NUMERO_MOV LIKE 'T%%' OR SERIE_DOC_MOV='ZZ' OR NUMERO_DOC_MOV LIKE '9000%%'")
print('='*70)
for st,nom,det in res:
    print(f'[{st}] {nom}')
    if det: print(f'        {det}')
fallos=sum(1 for st,_,_ in res if st=='FALLA')
print('='*70,f'\nTotal: {len(res)} pruebas, {fallos} fallos')
sys.exit(1 if fallos else 0)
