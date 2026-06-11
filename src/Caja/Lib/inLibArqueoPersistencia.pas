{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArqueoPersistencia                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia del arqueo de caja: graba un TArqueoCaja completo en         }
{    fza_caja_arqueos + fza_caja_arqueos_recuento, marca las operaciones       }
{    del rango con CODIGO_ARQUEO_OPCAJA, y lee arqueos previos.                }
{******************************************************************************}
unit inLibArqueoPersistencia;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, Uni, DBAccess,
  inLibArqueo;

type
  TArqueoRecuentoLinea = record
    CodigoFP    : string;
    Descripcion : string;
    EsCajon     : string;
    Sistema     : Currency;
    Recuento    : Currency;
    Diferencia  : Currency;
  end;

  TArqueoPersistencia = class
  public
    class function GenerarCodigoArqueo(
      AConn: TUniConnection;
      const AEmpresa, AAlmacen, ACaja: string;
      AFecha: TDate): string;

    class procedure GrabarArqueo(
      AConn: TUniConnection;
      const AArqueo: TArqueoCaja;
      const ALineasRecuento: TArray<TArqueoRecuentoLinea>;
      ATotalRecuento: Currency;
      ADiferenciaTotal: Currency;
      AEfectivoDejado: Currency;
      AImporteRetirada: Currency;
      const AConceptoRetirada: string;
      const ADesgloseBilletes: string;
      const AObservaciones: string;
      const ACodigoEmpleado: string;
      const AUsuario: string);
  end;

implementation

uses
  System.DateUtils;

{ --------------------------------------------------------------------------- }
{   Genera CODIGO_ARQ: EMP-ALM-CAJA-YYYYMMDD-NNN                             }
{ --------------------------------------------------------------------------- }
class function TArqueoPersistencia.GenerarCodigoArqueo(
  AConn: TUniConnection;
  const AEmpresa, AAlmacen, ACaja: string;
  AFecha: TDate): string;
var
  Query: TUniQuery;
  sBase: string;
  iSeq: Integer;
begin
  { Formato compacto para caber en varchar(20):
    YYYYMMDD-NN  (8+1+2 = 11 fijo, resto para secuencia).
    Ejemplo: 20260526-01  Si hay más de uno el mismo día: -02, -03... }
  sBase := FormatDateTime('yyyymmdd', AFecha);
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := AConn;
    Query.SQL.Text :=
      'SELECT COUNT(*) AS TOTAL' +
      '  FROM fza_caja_arqueos' +
      ' WHERE CODIGO_EMP_ARQ  = :pEMP' +
      '   AND CODIGO_ALM_ARQ  = :pALM' +
      '   AND CODIGO_CAJA_ARQ = :pCAJA' +
      '   AND CODIGO_ARQ LIKE :pBASE';
    Query.ParamByName('pEMP').AsString  := AEmpresa;
    Query.ParamByName('pALM').AsString  := AAlmacen;
    Query.ParamByName('pCAJA').AsString := ACaja;
    Query.ParamByName('pBASE').AsString := sBase + '%';
    Query.Open;
    iSeq := Query.FieldByName('TOTAL').AsInteger + 1;
  finally
    FreeAndNil(Query);
  end;
  Result := sBase + '-' + Format('%.2d', [iSeq]);
end;

{ --------------------------------------------------------------------------- }
{   Graba cabecera + detalle del recuento en una transacción                  }
{ --------------------------------------------------------------------------- }
class procedure TArqueoPersistencia.GrabarArqueo(
  AConn: TUniConnection;
  const AArqueo: TArqueoCaja;
  const ALineasRecuento: TArray<TArqueoRecuentoLinea>;
  ATotalRecuento: Currency;
  ADiferenciaTotal: Currency;
  AEfectivoDejado: Currency;
  AImporteRetirada: Currency;
  const AConceptoRetirada: string;
  const ADesgloseBilletes: string;
  const AObservaciones: string;
  const ACodigoEmpleado: string;
  const AUsuario: string);
var
  sCodigo: string;
  sSetOpcional: string;
  Query: TUniQuery;
  i: Integer;
  SpNum: TUniStoredProc;
  sNumOpRetirada: string;
begin
  sCodigo := GenerarCodigoArqueo(AConn,
    AArqueo.Empresa, AArqueo.Almacen, AArqueo.Caja,
    AArqueo.FechaDesde);
  // Si hay retirada, reservamos su numero de operacion con el contador
  // centralizado (PRC_GET_NEXT_OP_CAJA, serie 'OV') igual que el resto de
  // operaciones de caja: asi es correlativo y formateado (8 digitos) y no
  // colisiona. Se hace ANTES de StartTransaction porque el SP gestiona su
  // propia transaccion (START TRANSACTION / COMMIT) y llamarlo dentro
  // provocaria un commit implicito. Si el cierre se revierte despues, el
  // unico efecto es un hueco en la numeracion, como en cualquier operacion
  // anulada.
  sNumOpRetirada := '';
  if AImporteRetirada > 0 then
  begin
    SpNum := TUniStoredProc.Create(nil);
    try
      SpNum.Connection := AConn;
      SpNum.StoredProcName := 'PRC_GET_NEXT_OP_CAJA';
      SpNum.Params.CreateParam(ftString, 'pEmpresa', ptInput).AsString :=
        AArqueo.Empresa;
      SpNum.Params.CreateParam(ftString, 'pAlmacen', ptInput).AsString :=
        AArqueo.Almacen;
      SpNum.Params.CreateParam(ftString, 'pCaja', ptInput).AsString :=
        AArqueo.Caja;
      SpNum.Params.CreateParam(ftString, 'pUsuario', ptInput).AsString :=
        AUsuario;
      SpNum.Params.CreateParam(ftString, 'pSerie', ptOutput).Size := 12;
      SpNum.Params.CreateParam(ftString, 'pcont', ptOutput).Size := 20;
      SpNum.Prepare;
      SpNum.Execute;
      sNumOpRetirada := SpNum.ParamByName('pcont').AsString;
    finally
      FreeAndNil(SpNum);
    end;
  end;
  AConn.StartTransaction;
  try
    { -- Cabecera: solo columnas del esquema base (factuzam_original)
         + las que añade arqueo_recuento.sql (ya ejecutado). Columnas
         nuevas como TOTAL_PRESTAMOS_ARQ se graban aparte si existen. }
    Query := TUniQuery.Create(nil);
    try
      Query.Connection := AConn;
      { Solo columnas que existen en factuzam_original.sql (esquema
        base). Las columnas añadidas por migración van en un UPDATE
        aparte para no fallar si la migración no se ejecutó aún. }
      Query.SQL.Text :=
        'INSERT INTO fza_caja_arqueos (' +
        '  CODIGO_ARQ,' +
        '  CODIGO_EMP_ARQ,' +
        '  CODIGO_ALM_ARQ,' +
        '  CODIGO_CAJA_ARQ,' +
        '  FECHA_DESDE_ARQ,' +
        '  FECHA_HASTA_ARQ,' +
        '  FASE_ARQ,' +
        '  CODIGO_EMPLEADO_ARQ,' +
        '  CANTIDAD_VENTAS_ARQ,' +
        '  CANTIDAD_OPERACIONES_ARQ,' +
        '  TOTAL_BRUTO_LINEAS_ARQ,' +
        '  TOTAL_DESCUENTOS_LINEAS_ARQ,' +
        '  TOTAL_BRUTO_OPERACIONES_ARQ,' +
        '  TOTAL_DESCUENTOS_OPERACIONES_ARQ,' +
        '  TOTAL_NETO_ARQ,' +
        '  TOTAL_VALES_RECOGIDOS_ARQ,' +
        '  TOTAL_VALES_EMITIDOS_ARQ,' +
        '  TOTAL_COBROS_CLIENTES_ARQ,' +
        '  TOTAL_PENDIENTE_COBRO_ARQ,' +
        '  TOTAL_INGRESOS_CAJA_ARQ,' +
        '  TOTAL_EFECTIVO_INGRESOS_ARQ,' +
        '  TOTAL_EFECTIVO_ENTRADAS_ARQ,' +
        '  TOTAL_EFECTIVO_SALIDAS_ARQ,' +
        '  TOTAL_EFECTIVO_ANTERIOR_ARQ,' +
        '  TOTAL_EFECTIVO_CAJA_ARQ,' +
        '  TOTAL_OTROS_INGRESOS_ARQ,' +
        '  TOTAL_SALDO_RECONTAR_ARQ,' +
        '  OBSERVACIONES_ARQ,' +
        '  INSTANTE_ALTA,' +
        '  USUARIO_ALTA,' +
        '  USUARIO_MODIF' +
        ') VALUES (' +
        '  :pCODIGO,' +
        '  :pEMP,' +
        '  :pALM,' +
        '  :pCAJA,' +
        '  :pFDESDE,' +
        '  :pFHASTA,' +
        '  ''CERRADO'',' +
        '  :pEMPLEADO,' +
        '  :pCNT_VENTAS,' +
        '  :pCNT_OPE,' +
        '  :pBRUTO_LIN,' +
        '  :pDESC_LIN,' +
        '  :pBRUTO_OPE,' +
        '  :pDESC_OPE,' +
        '  :pNETO,' +
        '  :pVALES_REC,' +
        '  :pVALES_EMI,' +
        '  :pCOBROS_CLI,' +
        '  :pPEND_COB,' +
        '  :pING_CAJA,' +
        '  :pEFT_ING,' +
        '  :pEFT_ENT,' +
        '  :pEFT_SAL,' +
        '  :pEFT_ANT,' +
        '  :pEFT_CAJA,' +
        '  :pOTROS_ING,' +
        '  :pSALDO_REC,' +
        '  :pOBS,' +
        '  NOW(),' +
        '  :pUSUARIO,' +
        '  :pUSUARIO2' +
        ')';
      Query.ParamByName('pCODIGO').AsString     := sCodigo;
      Query.ParamByName('pEMP').AsString         := AArqueo.Empresa;
      Query.ParamByName('pALM').AsString         := AArqueo.Almacen;
      Query.ParamByName('pCAJA').AsString        := AArqueo.Caja;
      Query.ParamByName('pFDESDE').AsDate        := AArqueo.FechaDesde;
      Query.ParamByName('pFHASTA').AsDate        := AArqueo.FechaHasta;
      Query.ParamByName('pEMPLEADO').AsString    := ACodigoEmpleado;
      Query.ParamByName('pCNT_VENTAS').AsInteger := AArqueo.CantidadVentas;
      Query.ParamByName('pCNT_OPE').AsInteger    := AArqueo.CantidadOperaciones;
      Query.ParamByName('pBRUTO_LIN').AsCurrency := AArqueo.BrutoLineas;
      Query.ParamByName('pDESC_LIN').AsCurrency  := AArqueo.DescuentosLineas;
      Query.ParamByName('pBRUTO_OPE').AsCurrency := AArqueo.BrutoOperaciones;
      Query.ParamByName('pDESC_OPE').AsCurrency  := AArqueo.DescuentosOperaciones;
      Query.ParamByName('pNETO').AsCurrency      := AArqueo.Neto;
      Query.ParamByName('pVALES_REC').AsCurrency := AArqueo.ValesRecogidos;
      Query.ParamByName('pVALES_EMI').AsCurrency := AArqueo.ValesEmitidos;
      Query.ParamByName('pCOBROS_CLI').AsCurrency := AArqueo.CobrosClientes;
      Query.ParamByName('pPEND_COB').AsCurrency  := AArqueo.PendienteCobro;
      Query.ParamByName('pING_CAJA').AsCurrency  := AArqueo.IngresosCaja;
      Query.ParamByName('pEFT_ING').AsCurrency   := AArqueo.EfectivoIngresos;
      Query.ParamByName('pEFT_ENT').AsCurrency   := AArqueo.EfectivoEntradas;
      Query.ParamByName('pEFT_SAL').AsCurrency   := AArqueo.EfectivoSalidas;
      Query.ParamByName('pEFT_ANT').AsCurrency   := AArqueo.EfectivoAnterior;
      Query.ParamByName('pEFT_CAJA').AsCurrency  := AArqueo.EfectivoCaja;
      Query.ParamByName('pOTROS_ING').AsCurrency := AArqueo.OtrosIngresos;
      Query.ParamByName('pSALDO_REC').AsCurrency := AArqueo.SaldoRecontar;
      Query.ParamByName('pOBS').AsString         := AObservaciones;
      Query.ParamByName('pUSUARIO').AsString     := AUsuario;
      Query.ParamByName('pUSUARIO2').AsString    := AUsuario;
      Query.Execute;
    finally
      FreeAndNil(Query);
    end;
    { -- Columnas opcionales (añadidas por arqueo_recuento.sql) ----------- }
    { Construir UPDATE dinámico solo con las columnas que existen.
      UniDAC propaga errores SQL a través de OnError antes de que un
      except local los capture, así que no podemos usar try/except. }
    Query := TUniQuery.Create(nil);
    try
      Query.Connection := AConn;
      Query.SQL.Text :=
        'SELECT COLUMN_NAME' +
        '  FROM INFORMATION_SCHEMA.COLUMNS' +
        ' WHERE TABLE_SCHEMA = DATABASE()' +
        '   AND TABLE_NAME   = ''fza_caja_arqueos''' +
        '   AND COLUMN_NAME IN (' +
        '     ''TOTAL_PRESTAMOS_ARQ'',' +
        '     ''TOTAL_VENTAS_NORMALES_ARQ'',' +
        '     ''TOTAL_VENTAS_PRESTAMOS_ARQ'',' +
        '     ''TOTAL_DEVOLUCIONES_ARQ'',' +
        '     ''TOTAL_VENTAS_ARQ'',' +
        '     ''TOTAL_RECUENTO_ARQ'',' +
        '     ''DIFERENCIA_TOTAL_ARQ'',' +
        '     ''EFECTIVO_DEJADO_CAJA_ARQ'',' +
        '     ''DESGLOSE_BILLETES_ARQ'',' +
        '     ''IMPORTE_RETIRADA_ARQ'',' +
        '     ''CONCEPTO_RETIRADA_ARQ'')';
      Query.Open;
      if not Query.Eof then
      begin
        { Hay columnas opcionales: montar SET dinámico }
        sSetOpcional := '';
        while not Query.Eof do
        begin
          if sSetOpcional <> '' then
            sSetOpcional := sSetOpcional + ', ';
          sSetOpcional := sSetOpcional +
            Query.FieldByName('COLUMN_NAME').AsString +
            ' = :p' +
            Query.FieldByName('COLUMN_NAME').AsString;
          Query.Next;
        end;
      end;
    finally
      FreeAndNil(Query);
    end;
    if sSetOpcional <> '' then
    begin
      Query := TUniQuery.Create(nil);
      try
        Query.Connection := AConn;
        Query.SQL.Text :=
          'UPDATE fza_caja_arqueos SET ' + sSetOpcional +
          ' WHERE CODIGO_ARQ = :pCODIGO';
        Query.ParamByName('pCODIGO').AsString := sCodigo;
        if Query.FindParam('pTOTAL_PRESTAMOS_ARQ') <> nil then
          Query.ParamByName('pTOTAL_PRESTAMOS_ARQ').AsCurrency :=
            AArqueo.Prestamos;
        if Query.FindParam('pTOTAL_VENTAS_NORMALES_ARQ') <> nil then
          Query.ParamByName('pTOTAL_VENTAS_NORMALES_ARQ').AsCurrency :=
            AArqueo.VentasNormales;
        if Query.FindParam('pTOTAL_VENTAS_PRESTAMOS_ARQ') <> nil then
          Query.ParamByName('pTOTAL_VENTAS_PRESTAMOS_ARQ').AsCurrency :=
            AArqueo.VentasPrestamos;
        if Query.FindParam('pTOTAL_DEVOLUCIONES_ARQ') <> nil then
          Query.ParamByName('pTOTAL_DEVOLUCIONES_ARQ').AsCurrency :=
            AArqueo.Devoluciones;
        if Query.FindParam('pTOTAL_VENTAS_ARQ') <> nil then
          Query.ParamByName('pTOTAL_VENTAS_ARQ').AsCurrency :=
            AArqueo.TotalVentas;
        if Query.FindParam('pTOTAL_RECUENTO_ARQ') <> nil then
          Query.ParamByName('pTOTAL_RECUENTO_ARQ').AsCurrency :=
            ATotalRecuento;
        if Query.FindParam('pDIFERENCIA_TOTAL_ARQ') <> nil then
          Query.ParamByName('pDIFERENCIA_TOTAL_ARQ').AsCurrency :=
            ADiferenciaTotal;
        if Query.FindParam('pEFECTIVO_DEJADO_CAJA_ARQ') <> nil then
          Query.ParamByName('pEFECTIVO_DEJADO_CAJA_ARQ').AsCurrency :=
            AEfectivoDejado;
        if Query.FindParam('pDESGLOSE_BILLETES_ARQ') <> nil then
          Query.ParamByName('pDESGLOSE_BILLETES_ARQ').AsString :=
            ADesgloseBilletes;
        if Query.FindParam('pIMPORTE_RETIRADA_ARQ') <> nil then
          Query.ParamByName('pIMPORTE_RETIRADA_ARQ').AsCurrency :=
            AImporteRetirada;
        if Query.FindParam('pCONCEPTO_RETIRADA_ARQ') <> nil then
          Query.ParamByName('pCONCEPTO_RETIRADA_ARQ').AsString :=
            AConceptoRetirada;
        Query.Execute;
      finally
        FreeAndNil(Query);
      end;
    end;

    { -- Detalle por forma de pago ------------------------------------------ }
    for i := 0 to High(ALineasRecuento) do
    begin
      Query := TUniQuery.Create(nil);
      try
        Query.Connection := AConn;
        Query.SQL.Text :=
          'INSERT INTO fza_caja_arqueos_recuento (' +
          '  CODIGO_ARQ_ARQR,' +
          '  CODIGO_FP_CFP_ARQR,' +
          '  DESCRIPCION_FP_ARQR,' +
          '  ESCAJON_ARQR,' +
          '  IMPORTE_SISTEMA_ARQR,' +
          '  IMPORTE_RECUENTO_ARQR,' +
          '  DIFERENCIA_ARQR,' +
          '  INSTANTE_ALTA,' +
          '  USUARIO_ALTA,' +
          '  USUARIO_MODIF' +
          ') VALUES (' +
          '  :pARQ,' +
          '  :pFP,' +
          '  :pDESC,' +
          '  :pCAJON,' +
          '  :pSIST,' +
          '  :pREC,' +
          '  :pDIF,' +
          '  NOW(),' +
          '  :pUSUARIO,' +
          '  :pUSUARIO2' +
          ')';
        Query.ParamByName('pARQ').AsString     := sCodigo;
        Query.ParamByName('pFP').AsString      := ALineasRecuento[i].CodigoFP;
        Query.ParamByName('pDESC').AsString    := ALineasRecuento[i].Descripcion;
        Query.ParamByName('pCAJON').AsString   := ALineasRecuento[i].EsCajon;
        Query.ParamByName('pSIST').AsCurrency  := ALineasRecuento[i].Sistema;
        Query.ParamByName('pREC').AsCurrency   := ALineasRecuento[i].Recuento;
        Query.ParamByName('pDIF').AsCurrency   := ALineasRecuento[i].Diferencia;
        Query.ParamByName('pUSUARIO').AsString := AUsuario;
        Query.ParamByName('pUSUARIO2').AsString := AUsuario;
        Query.Execute;
      finally
        FreeAndNil(Query);
      end;
    end;

    { -- Marca las operaciones del rango con el código de arqueo ------------ }
    Query := TUniQuery.Create(nil);
    try
      Query.Connection := AConn;
      Query.SQL.Text :=
        'UPDATE fza_caja_operaciones' +
        '   SET CODIGO_ARQUEO_OPCAJA = :pARQ' +
        ' WHERE CODIGO_EMP_OPCAJA    = :pEMP' +
        '   AND CODIGO_ALM_OPCAJA    = :pALM' +
        '   AND CODIGO_CAJA_OPCAJA   = :pCAJA' +
        '   AND FECHA_OPERACION_OPCAJA >= :pFDESDE' +
        '   AND FECHA_OPERACION_OPCAJA < DATE_ADD(:pFHASTA, INTERVAL 1 DAY)' +
        '   AND (CODIGO_ARQUEO_OPCAJA IS NULL' +
        '        OR CODIGO_ARQUEO_OPCAJA = '''')';
      Query.ParamByName('pARQ').AsString      := sCodigo;
      Query.ParamByName('pEMP').AsString      := AArqueo.Empresa;
      Query.ParamByName('pALM').AsString      := AArqueo.Almacen;
      Query.ParamByName('pCAJA').AsString     := AArqueo.Caja;
      Query.ParamByName('pFDESDE').AsDateTime := AArqueo.FechaDesde;
      Query.ParamByName('pFHASTA').AsDateTime := AArqueo.FechaHasta;
      Query.Execute;
    finally
      FreeAndNil(Query);
    end;

    { -- Retirada: crear operación GC si hay importe ---------------------- }
    if AImporteRetirada > 0 then
    begin
      Query := TUniQuery.Create(nil);
      try
        Query.Connection := AConn;
        Query.SQL.Text :=
          'INSERT INTO fza_caja_operaciones (' +
          '  CODIGO_EMP_OPCAJA, CODIGO_ALM_OPCAJA,' +
          '  CODIGO_CAJA_OPCAJA, NUMERO_OPERACION_OPCAJA,' +
          '  TIPO_OPERACION_OPCAJA, IMPORTE_TOTAL_OPCAJA,' +
          '  FECHA_OPERACION_OPCAJA, FECHA_OP_DIA_OPCAJA,' +
          '  CODIGO_EMPLEADO_OPCAJA,' +
          '  CONCEPTO_GASTO_INGRESO_OPCAJA,' +
          '  ESTADO_DEVOLUCION_OPCAJA,' +
          '  CODIGO_ARQUEO_OPCAJA,' +
          '  USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA' +
          ') VALUES (' +
          '  :EMP, :ALM, :CAJA, :NUMOP,' +
          '  ''GC'', :IMP, NOW(), CURRENT_DATE,' +
          '  :USR, :CONCEPTO, ''N'', :ARQ,' +
          '  :USR2, :USR3, NOW())';
        Query.ParamByName('EMP').AsString   := AArqueo.Empresa;
        Query.ParamByName('ALM').AsString   := AArqueo.Almacen;
        Query.ParamByName('CAJA').AsString  := AArqueo.Caja;
        Query.ParamByName('NUMOP').AsString := sNumOpRetirada;
        Query.ParamByName('IMP').AsCurrency := AImporteRetirada;
        Query.ParamByName('USR').AsString   := AUsuario;
        Query.ParamByName('CONCEPTO').AsString := AConceptoRetirada;
        Query.ParamByName('ARQ').AsString   := sCodigo;
        Query.ParamByName('USR2').AsString  := AUsuario;
        Query.ParamByName('USR3').AsString  := AUsuario;
        Query.Execute;
      finally
        FreeAndNil(Query);
      end;
    end;

    AConn.Commit;
  except
    AConn.Rollback;
    raise;
  end;
end;

end.
