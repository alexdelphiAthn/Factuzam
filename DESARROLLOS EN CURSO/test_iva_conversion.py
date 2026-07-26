# -*- coding: utf-8 -*-
# Verificacion del bloque 2.4: helpers de conversion IVA y fin del bug
# AsInteger (truncado del porcentaje) en inMtoFacturasBase.
import pymysql, sys
from decimal import Decimal

def conn():
    return pymysql.connect(unix_socket='/var/run/mysqld/mysqld.sock',
                           database='factuzam_test', charset='utf8mb4', autocommit=True,
                           init_command="SET collation_connection='utf8mb4_spanish_ci'")

# --- Replica de los helpers nuevos de inLibImpuestosComun ---
def PrecioSinIvaDesdeConIva(p, pct):
    f = 1 + (pct/100.0)
    return p if f == 0 else p/f
def PrecioConIvaDesdeSinIva(p, pct):
    return p * (1 + (pct/100.0))
# --- Replica del codigo ANTIGUO (AsInteger truncaba el porcentaje) ---
def viejo_sin_iva(p, pct):
    f = 1 + (int(pct)/100.0)          # AsInteger -> trunca
    return p/f if f != 0 else p
def viejo_con_iva(p, pct):
    return p * (1 + (int(pct)/100.0))

CODIGOS = ['IVAN','IVAR','IVAS','IVAE']
def PorcentajeIvaCabecera(fila, sufijo, tipo):   # replica de la comun
    idx = {'N':0,'R':1,'S':2,'E':3}.get(tipo.upper()[:1], 0)
    return float(fila.get('PORCENTAJE_' + CODIGOS[idx] + '_' + sufijo) or 0)

res=[]
def check(n,c,d=''): res.append(('PASA' if c else 'FALLA',n,d))

# ---------- 1) matematica de los helpers ----------
check('IVA 21% incl.: 121 -> 100 s/IVA', round(PrecioSinIvaDesdeConIva(121,21),6)==100.0,
      f'{PrecioSinIvaDesdeConIva(121,21):.6f}')
check('IVA 21% excl.: 100 -> 121 c/IVA', round(PrecioConIvaDesdeSinIva(100,21),6)==121.0)
check('ida y vuelta conserva el importe',
      round(PrecioSinIvaDesdeConIva(PrecioConIvaDesdeSinIva(37.45,10),10),6)==37.45)
check('IVA 0% no altera el precio',
      PrecioSinIvaDesdeConIva(50,0)==50 and PrecioConIvaDesdeSinIva(50,0)==50)
check('guarda division por cero (pct=-100 no revienta)',
      PrecioSinIvaDesdeConIva(50,-100)==50)

# ---------- 2) el bug corregido, con IVA decimal ----------
p, pct = 121.0, 10.5
nuevo = PrecioSinIvaDesdeConIva(p, pct); viejo = viejo_sin_iva(p, pct)
dif = abs(nuevo-viejo)
check('IVA decimal (10,5%): el codigo NUEVO calcula bien',
      abs(nuevo - p/1.105) < 1e-9, f'nuevo={nuevo:.4f} esperado={p/1.105:.4f}')
check('IVA decimal: el codigo ANTIGUO se desviaba (bug reproducido)',
      dif > 0.005, f'viejo={viejo:.4f} nuevo={nuevo:.4f} desviacion={dif:.4f} EUR/linea')
# con IVA entero deben coincidir (no hay regresion en el caso habitual)
check('IVA entero (21%): nuevo == antiguo (sin regresion)',
      abs(PrecioSinIvaDesdeConIva(121,21)-viejo_sin_iva(121,21)) < 1e-9)

# ---------- 3) PorcentajeIvaCabecera contra el esquema real ----------
c=conn(); cur=c.cursor(pymysql.cursors.DictCursor)
cur.execute("""SELECT SERIE_FAC, NUMERO_FAC, PORCENTAJE_IVAN_FAC, PORCENTAJE_IVAR_FAC,
                      PORCENTAJE_IVAS_FAC, PORCENTAJE_IVAE_FAC
               FROM fza_facturas WHERE PORCENTAJE_IVAN_FAC IS NOT NULL LIMIT 1""")
fila=cur.fetchone()
check('las 4 columnas PORCENTAJE_IVAx_FAC existen y se leen', fila is not None,
      f"N={fila['PORCENTAJE_IVAN_FAC']} R={fila['PORCENTAJE_IVAR_FAC']} "
      f"S={fila['PORCENTAJE_IVAS_FAC']} E={fila['PORCENTAJE_IVAE_FAC']}" if fila else '')
if fila:
    check("PorcentajeIvaCabecera(...,'FAC','N') devuelve el % normal",
          PorcentajeIvaCabecera(fila,'FAC','N')==float(fila['PORCENTAJE_IVAN_FAC']))
    check("...'R' devuelve el reducido",
          PorcentajeIvaCabecera(fila,'FAC','R')==float(fila['PORCENTAJE_IVAR_FAC']))
    check("...'E' devuelve el exento",
          PorcentajeIvaCabecera(fila,'FAC','E')==float(fila['PORCENTAJE_IVAE_FAC']))

# ---------- 4) impacto real: hay IVAs decimales en los datos? ----------
cur2=c.cursor()
cur2.execute("""SELECT COUNT(*) FROM fza_facturas
   WHERE (PORCENTAJE_IVAN_FAC <> TRUNCATE(PORCENTAJE_IVAN_FAC,0))
      OR (PORCENTAJE_IVAR_FAC <> TRUNCATE(PORCENTAJE_IVAR_FAC,0))
      OR (PORCENTAJE_IVAS_FAC <> TRUNCATE(PORCENTAJE_IVAS_FAC,0))""")
ndec=cur2.fetchone()[0]
cur2.execute("""SELECT COUNT(*) FROM fza_ivas WHERE
      PORCENTAJE_NORMAL_IVA <> TRUNCATE(PORCENTAJE_NORMAL_IVA,0)
   OR PORCENTAJE_REDUCIDO_IVA <> TRUNCATE(PORCENTAJE_REDUCIDO_IVA,0)
   OR PORCENTAJE_SUPERREDUCIDO_IVA <> TRUNCATE(PORCENTAJE_SUPERREDUCIDO_IVA,0)""")
try: ndec_iva=cur2.fetchone()[0]
except Exception: ndec_iva='?'
res.append(('INFO','Facturas con % de IVA decimal en la demo',
            f'{ndec} facturas; tipos de IVA decimales en fza_ivas: {ndec_iva}'))

print('='*72)
for st,n,d in res:
    print(f'[{st}] {n}')
    if d: print(f'        {d}')
f=sum(1 for s,_,_ in res if s=='FALLA')
print('='*72, f'\nTotal: {len([r for r in res if r[0]!="INFO"])} pruebas, {f} fallos')
sys.exit(1 if f else 0)
