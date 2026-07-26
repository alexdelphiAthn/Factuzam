# -*- coding: utf-8 -*-
# Verificacion funcional del modal de remesas unificado (Fase 2, bloque 2):
# reproduce la concatenacion EXACTA de Configurar() y CargarRemesasAbiertas()
# para las dos variantes, ejecuta el SQL y comprueba que los alias que
# devuelve son EXACTAMENTE los que el .dfm enlaza por FieldName.
import pymysql, sys

def conn():
    return pymysql.connect(unix_socket='/var/run/mysqld/mysqld.sock',
                           database='factuzam_test', charset='utf8mb4',
                           autocommit=True,
                           init_command="SET collation_connection='utf8mb4_spanish_ci'")

def Q(s): return "'" + s.replace("'", "''") + "'"   # QuotedStr de Pascal

COMPRA = dict(TablaEfectos='fza_efectos_compra', TablaRemesas='fza_remesas_compra',
    SufEfecto='EFEC', SufRemesa='REMC', CampoSerieFac='SERIE_FACC_EFEC',
    CampoNumeroFac='NUMERO_FACC_EFEC', CampoTercero='RAZON_SOCIAL_PRV_EFEC',
    TituloTercero='Proveedor', SPCrear='PRC_REMC_CREAR',
    SPAnyadir='PRC_REMC_ANYADIR_EFECTO', ParamNumEfecto='p_NUM_EFEC',
    TextoOmitidos='pagados')
VENTA = dict(TablaEfectos='fza_efectos_venta', TablaRemesas='fza_remesas_venta',
    SufEfecto='EFV', SufRemesa='REMV', CampoSerieFac='SERIE_FAC_EFV',
    CampoNumeroFac='NUMERO_FAC_EFV', CampoTercero='RAZON_SOCIAL_CLI_EFV',
    TituloTercero='Cliente', SPCrear='PRC_REMV_CREAR',
    SPAnyadir='PRC_REMV_ANYADIR_EFECTO', ParamNumEfecto='p_NUM_EFV',
    TextoOmitidos='cobrados')

def sql_efectos(c):   # == Configurar()
    return ('SELECT ' + c['CampoSerieFac'] + ' AS SERIE_FAC_EFECTO, ' +
    '       ' + c['CampoNumeroFac'] + ' AS NUMERO_FAC_EFECTO, ' +
    '       NUMERO_' + c['SufEfecto'] + ' AS NUMERO_EFECTO, ' +
    '       ' + c['CampoTercero'] + ' AS TERCERO_EFECTO, ' +
    '       FECHA_VENCIMIENTO_' + c['SufEfecto'] +
    '         AS FECHA_VENCIMIENTO_EFECTO, ' +
    '       IMPORTE_PENDIENTE_' + c['SufEfecto'] +
    '         AS IMPORTE_PENDIENTE_EFECTO, ' +
    '       ESTADO_' + c['SufEfecto'] + ' AS ESTADO_EFECTO ' +
    '  FROM ' + c['TablaEfectos'] + ' ' +
    ' WHERE CODIGO_EMP_' + c['SufEfecto'] + ' = :emp ' +
    '   AND SERIE_' + c['SufRemesa'] + '_' + c['SufEfecto'] +
    '       IS NULL ' +
    '   AND COALESCE(ESTADO_' + c['SufEfecto'] + ', ' +
    Q('') + ') IN (' + Q('PENDIENTE') + ', ' + Q('PARCIAL') + ') ' +
    '   AND COALESCE(IMPORTE_PENDIENTE_' + c['SufEfecto'] + ', 0) > 0 ' +
    '   AND FECHA_VENCIMIENTO_' + c['SufEfecto'] + ' <= :hasta ' +
    ' ORDER BY FECHA_VENCIMIENTO_' + c['SufEfecto'] + ', ' + c['CampoTercero'])

def sql_remesas(c):   # == CargarRemesasAbiertas()
    return ('SELECT SERIE_' + c['SufRemesa'] + ' AS SERIE_REMESA, ' +
    '       NUMERO_' + c['SufRemesa'] + ' AS NUMERO_REMESA, ' +
    '       FECHA_' + c['SufRemesa'] + ' AS FECHA_REMESA, ' +
    '       TOTAL_' + c['SufRemesa'] + ' AS TOTAL_REMESA ' +
    '  FROM ' + c['TablaRemesas'] + ' ' +
    ' WHERE CODIGO_EMP_' + c['SufRemesa'] + ' = :emp ' +
    '   AND COALESCE(ESTADO_' + c['SufRemesa'] + ', ' + Q('') + ') IN (' +
    Q('ABIERTA') + ', ' + Q('CERRADA') + ') ' +
    ' ORDER BY FECHA_' + c['SufRemesa'] + ' DESC, ' +
    '          NUMERO_' + c['SufRemesa'] + ' DESC')

ALIAS_DFM_EFECTOS = ['SERIE_FAC_EFECTO','NUMERO_FAC_EFECTO','NUMERO_EFECTO',
                     'TERCERO_EFECTO','FECHA_VENCIMIENTO_EFECTO',
                     'IMPORTE_PENDIENTE_EFECTO','ESTADO_EFECTO']
ALIAS_CODIGO_REMESAS = ['SERIE_REMESA','NUMERO_REMESA','FECHA_REMESA','TOTAL_REMESA']

res=[]
def check(n,c,d=''): res.append(('PASA' if c else 'FALLA',n,d))

c=conn(); cur=c.cursor()

for nombre, cfg in [('COMPRA',COMPRA),('VENTA',VENTA)]:
    # --- SELECT de efectos ---
    sql=sql_efectos(cfg).replace(':emp','%s').replace(':hasta','%s')
    try:
        cur.execute(sql, ('01','2999-12-31'))
        cols=[d[0] for d in cur.description]; cur.fetchall(); err=None
    except Exception as e:
        cols=[]; err=e
    check(f'{nombre}: SELECT de efectos ejecuta contra el esquema', err is None,
          f'error={err}' if err else f'{len(cols)} columnas')
    check(f'{nombre}: alias == FieldName del .dfm', cols==ALIAS_DFM_EFECTOS,
          f'sql={cols} dfm={ALIAS_DFM_EFECTOS}')
    # --- SELECT de remesas abiertas ---
    sql=sql_remesas(cfg).replace(':emp','%s')
    try:
        cur.execute(sql, ('01',))
        cols2=[d[0] for d in cur.description]; cur.fetchall(); err=None
    except Exception as e:
        cols2=[]; err=e
    check(f'{nombre}: SELECT de remesas abiertas ejecuta', err is None,
          f'error={err}' if err else '')
    check(f'{nombre}: alias usados por el codigo presentes', cols2==ALIAS_CODIGO_REMESAS,
          f'sql={cols2}')
    # --- SPs y nombres de parametro ---
    for sp, params in [(cfg['SPCrear'], ['p_EMPRESA','p_IBAN','p_USUARIO','p_SERIE_OUT','p_NUMERO_OUT']),
                       (cfg['SPAnyadir'], ['p_SERIE_REM','p_NUMERO_REM','p_SERIE_FAC','p_NUMERO_FAC',
                                           cfg['ParamNumEfecto'],'p_USUARIO','p_RESULTADO'])]:
        cur.execute("""SELECT PARAMETER_NAME FROM INFORMATION_SCHEMA.PARAMETERS
                       WHERE SPECIFIC_SCHEMA=DATABASE() AND SPECIFIC_NAME=%s
                       ORDER BY ORDINAL_POSITION""",(sp,))
        reales=[r[0] for r in cur.fetchall()]
        faltan=[p for p in params if p not in reales]
        check(f'{nombre}: {sp} acepta los parametros del codigo', reales and not faltan,
              f'faltan={faltan} reales={reales}' if (faltan or not reales) else '')

print('='*72)
for st,n,d in res:
    print(f'[{st}] {n}')
    if d: print(f'        {d}')
f=sum(1 for s,_,_ in res if s=='FALLA')
print('='*72, f'\nTotal: {len(res)} comprobaciones, {f} fallos')
sys.exit(1 if f else 0)
