# -*- coding: utf-8 -*-
# Flujo funcional completo del modal de remesas unificado, para las DOS
# variantes: buscar pendientes -> crear remesa -> anyadir efecto ->
# comprobar estado -> reintentar (omitido) -> listar remesas abiertas.
import pymysql, sys

def conn():
    return pymysql.connect(unix_socket='/var/run/mysqld/mysqld.sock',
                           database='factuzam_test', charset='utf8mb4',
                           autocommit=True,
                           init_command="SET collation_connection='utf8mb4_spanish_ci'")
def Q(s): return "'" + s.replace("'","''") + "'"

CFG = {
 'COMPRA': dict(tabla='fza_efectos_compra', remesas='fza_remesas_compra',
   se='EFEC', sr='REMC', serie='SERIE_FACC_EFEC', num='NUMERO_FACC_EFEC',
   tercero='RAZON_SOCIAL_PRV_EFEC', spc='PRC_REMC_CREAR',
   spa='PRC_REMC_ANYADIR_EFECTO', pnum='p_NUM_EFEC', emp='01'),
 'VENTA': dict(tabla='fza_efectos_venta', remesas='fza_remesas_venta',
   se='EFV', sr='REMV', serie='SERIE_FAC_EFV', num='NUMERO_FAC_EFV',
   tercero='RAZON_SOCIAL_CLI_EFV', spc='PRC_REMV_CREAR',
   spa='PRC_REMV_ANYADIR_EFECTO', pnum='p_NUM_EFV', emp='01'),
}
res=[]
def check(n,c,d=''): res.append(('PASA' if c else 'FALLA',n,d))

c=conn(); cur=c.cursor()
for nombre,g in CFG.items():
    se,sr = g['se'], g['sr']
    # ---- efecto de prueba pendiente y sin remesar ----
    cur.execute(f"DELETE FROM {g['tabla']} WHERE {g['serie']}='ZZ'")
    cur.execute(f"""INSERT INTO {g['tabla']}
      ({g['serie']},{g['num']},NUMERO_{se},CODIGO_EMP_{se},{g['tercero']},
       FECHA_VENCIMIENTO_{se},IMPORTE_{se},IMPORTE_PENDIENTE_{se},ESTADO_{se},
       SERIE_{sr}_{se},INSTANTE_ALTA,USUARIO_ALTA,INSTANTE_MODIF,USUARIO_MODIF)
      VALUES ('ZZ','900001',1,%s,'TERCERO PRUEBA','2026-01-31',250,250,
              'PENDIENTE',NULL,NOW(),'TEST',NOW(),'TEST')""",(g['emp'],))
    # ---- 1) el SELECT del modal lo encuentra ----
    sql=(f"SELECT {g['serie']} AS SERIE_FAC_EFECTO, {g['num']} AS NUMERO_FAC_EFECTO, "
         f"NUMERO_{se} AS NUMERO_EFECTO, {g['tercero']} AS TERCERO_EFECTO, "
         f"IMPORTE_PENDIENTE_{se} AS IMPORTE_PENDIENTE_EFECTO, ESTADO_{se} AS ESTADO_EFECTO "
         f"FROM {g['tabla']} WHERE CODIGO_EMP_{se}=%s AND SERIE_{sr}_{se} IS NULL "
         f"AND COALESCE(ESTADO_{se},'') IN ('PENDIENTE','PARCIAL') "
         f"AND COALESCE(IMPORTE_PENDIENTE_{se},0)>0 AND FECHA_VENCIMIENTO_{se}<=%s")
    cur.execute(sql,(g['emp'],'2999-12-31'))
    filas=cur.fetchall()
    check(f'{nombre}: el grid encuentra el efecto pendiente', len(filas)==1,
          f'{len(filas)} filas; tercero={filas[0][3] if filas else "-"}')
    # ---- 2) crear remesa nueva (boton Remesar, modo 0) ----
    cur.execute(f"CALL {g['spc']}(%s,'',%s,@s,@n)",(g['emp'],'TEST'))
    cur.execute("SELECT @s,@n"); serie_rem,num_rem = cur.fetchone()
    check(f'{nombre}: {g["spc"]} crea la remesa', bool(num_rem),
          f'remesa={serie_rem}/{num_rem}')
    # ---- 3) anyadir el efecto ----
    cur.execute(f"CALL {g['spa']}(%s,%s,'ZZ','900001',1,'TEST',@r)",(serie_rem,num_rem))
    cur.execute("SELECT @r"); r1=cur.fetchone()[0]
    check(f'{nombre}: {g["spa"]} devuelve 1 (cargado)', r1==1, f'p_RESULTADO={r1}')
    # ---- 4) el efecto queda ligado a la remesa ----
    cur.execute(f"SELECT SERIE_{sr}_{se},ESTADO_{se} FROM {g['tabla']} "
                f"WHERE {g['serie']}='ZZ' AND NUMERO_{se}=1")
    sr_val,est=cur.fetchone()
    check(f'{nombre}: efecto ligado a la remesa y REMESADO',
          sr_val==serie_rem and est=='REMESADO', f'serie={sr_val} estado={est}')
    # ---- 5) ya no aparece como pendiente ----
    cur.execute(sql,(g['emp'],'2999-12-31'))
    check(f'{nombre}: ya no sale en el grid de pendientes', len(cur.fetchall())==0)
    # ---- 6) reintento -> omitido (contador nSkip del mensaje) ----
    cur.execute(f"CALL {g['spa']}(%s,%s,'ZZ','900001',1,'TEST',@r)",(serie_rem,num_rem))
    cur.execute("SELECT @r"); r2=cur.fetchone()[0]
    check(f'{nombre}: reintento devuelve 0 (omitido, no duplica)', r2==0,
          f'p_RESULTADO={r2}')
    # ---- 7) la remesa aparece en el combo de abiertas ----
    sqlrem=(f"SELECT SERIE_{sr} AS SERIE_REMESA, NUMERO_{sr} AS NUMERO_REMESA, "
            f"FECHA_{sr} AS FECHA_REMESA, TOTAL_{sr} AS TOTAL_REMESA "
            f"FROM {g['remesas']} WHERE CODIGO_EMP_{sr}=%s "
            f"AND COALESCE(ESTADO_{sr},'') IN ('ABIERTA','CERRADA') "
            f"ORDER BY FECHA_{sr} DESC, NUMERO_{sr} DESC")
    cur.execute(sqlrem,(g['emp'],))
    combo=[f'{r[0]} / {r[1]}' for r in cur.fetchall()]
    check(f'{nombre}: la remesa nueva sale en el combo', f'{serie_rem} / {num_rem}' in combo,
          f'combo={combo[:3]}')
    # limpieza
    cur.execute(f"DELETE FROM {g['tabla']} WHERE {g['serie']}='ZZ'")

print('='*72)
for st,n,d in res:
    print(f'[{st}] {n}')
    if d: print(f'        {d}')
f=sum(1 for s,_,_ in res if s=='FALLA')
print('='*72, f'\nTotal: {len(res)} pruebas, {f} fallos')
sys.exit(1 if f else 0)
