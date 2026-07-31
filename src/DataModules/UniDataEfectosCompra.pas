{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataEfectosCompra                                           }
{    Tipo:       Data Module                                                    }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de efectos de pago (vi_efectos_compra).                      }
{******************************************************************************}
unit UniDataEfectosCompra;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TClaveEfectoCompra = record
    SerieFac: string;
    NumeroFac: string;
    NumeroEfec: Integer;
  end;

  TClavesEfectoCompra = TArray<TClaveEfectoCompra>;

  TdmEfectosCompra = class(TdmBase)
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
  private
    { Private declarations }
  public
    // Concilia un pago sobre el efecto y refresca la cartera. Si el pago es
    // parcial, la BBDD divide el efecto en pagado y pendiente.
    function RegistrarPago(const ASerie, ANumero: string; ANumEfec: Integer;
      AFecha: TDateTime; AImporte: Double;
      const ATipo, AReferencia: string): Integer;
    // Agrupa varios efectos impagados en uno unico. Los origenes quedan en
    // estado CONCILIADO y referenciados al efecto resumen.
    function FusionarEfectosPendientes(const AClaves: TClavesEfectoCompra;
      out AReferencia: string): Integer;
  end;

implementation

uses
  inLibMsgCompras;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmEfectosCompra.unqryTablaGBeforeDelete(DataSet: TDataSet);
var
  dImportePagado: Double;
  sConciliado: string;
  sEstado: string;
  sNumeroRem: string;
  sSerieRem: string;
begin
  inherited;
  sEstado := UpperCase(Trim(DataSet.FieldByName('ESTADO_EFEC').AsString));
  sSerieRem := Trim(DataSet.FieldByName('SERIE_REMC_EFEC').AsString);
  sNumeroRem := Trim(DataSet.FieldByName('NUMERO_REMC_EFEC').AsString);
  sConciliado := Trim(DataSet.FieldByName('ESCONCILIADO_EFEC').AsString);
  dImportePagado := DataSet.FieldByName('IMPORTE_PAGADO_EFEC').AsFloat;
  if (sSerieRem <> '') or (sNumeroRem <> '') or
     (sEstado = 'REMESADO') then
    raise Exception.Create(SErrorBorrarEfectoCompraRemesado);
  if (dImportePagado > 0.0001) or (sConciliado = 'S') or
     (sEstado = 'PAGADO') or (sEstado = 'DEVUELTO') or
     (sEstado = 'CONCILIADO') then
    raise Exception.Create(SErrorBorrarEfectoCompraPagado);
end;

function TdmEfectosCompra.FusionarEfectosPendientes(
  const AClaves: TClavesEfectoCompra; out AReferencia: string): Integer;
var
  q: TUniQuery;
  bTxOwned: Boolean;
  i: Integer;
  iValidos: Integer;
  iEmpresas: Integer;
  iProveedores: Integer;
  iNuevoEfec: Integer;
  dTotal: Double;
  sSerieDestino: string;
  sNumeroDestino: string;

  procedure RefrescarCartera;
  begin
    if (unqryTablaG <> nil) and unqryTablaG.Active then
    begin
      unqryTablaG.Close;
      unqryTablaG.Open;
    end;
  end;

begin
  Result := 0;
  AReferencia := '';
  if Length(AClaves) >= 2 then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionPrincipal;
      bTxOwned := not ConexionPrincipal.InTransaction;
      if bTxOwned then
        ConexionPrincipal.StartTransaction;
      try
      q.SQL.Text :=
        'CREATE TEMPORARY TABLE IF NOT EXISTS tmp_efec_fusion (' +
        '  SERIE_FACC varchar(20) NOT NULL, ' +
        '  NUMERO_FACC varchar(20) NOT NULL, ' +
        '  NUMERO_EFEC int NOT NULL, ' +
        '  PRIMARY KEY (SERIE_FACC, NUMERO_FACC, NUMERO_EFEC)) ' +
        'ENGINE=MEMORY';
      q.ExecSQL;
      q.SQL.Text := 'DELETE FROM tmp_efec_fusion';
      q.ExecSQL;
      q.SQL.Text :=
        'INSERT INTO tmp_efec_fusion ' +
        '  (SERIE_FACC, NUMERO_FACC, NUMERO_EFEC) ' +
        'VALUES (:serie, :numero, :efecto)';
      for i := 0 to Length(AClaves) - 1 do
      begin
        q.ParamByName('serie').AsString := AClaves[i].SerieFac;
        q.ParamByName('numero').AsString := AClaves[i].NumeroFac;
        q.ParamByName('efecto').AsInteger := AClaves[i].NumeroEfec;
        q.ExecSQL;
      end;
      q.SQL.Text :=
        'SELECT COUNT(*) AS VALIDOS, ' +
        '       COUNT(DISTINCT COALESCE(E.CODIGO_EMP_EFEC, '''')) ' +
        '         AS EMPRESAS, ' +
        '       COUNT(DISTINCT COALESCE(E.CODIGO_PRV_EFEC, '''')) ' +
        '         AS PROVEEDORES, ' +
        '       COALESCE(SUM(COALESCE(E.IMPORTE_PENDIENTE_EFEC, 0)), 0) ' +
        '         AS TOTAL ' +
        '  FROM fza_efectos_compra E ' +
        '  JOIN tmp_efec_fusion T ' +
        '    ON T.SERIE_FACC = E.SERIE_FACC_EFEC ' +
        '   AND T.NUMERO_FACC = E.NUMERO_FACC_EFEC ' +
        '   AND T.NUMERO_EFEC = E.NUMERO_EFEC ' +
        ' WHERE COALESCE(E.ESTADO_EFEC, '''') IN ('''', ''PENDIENTE'') ' +
        '   AND COALESCE(E.IMPORTE_PAGADO_EFEC, 0) <= 0.0001 ' +
        '   AND COALESCE(E.IMPORTE_PENDIENTE_EFEC, 0) > 0.0001 ' +
        '   AND COALESCE(E.ESCONCILIADO_EFEC, ''N'') <> ''S'' ' +
        '   AND COALESCE(E.SERIE_REMC_EFEC, '''') = '''' ' +
        '   AND COALESCE(E.NUMERO_REMC_EFEC, '''') = '''' ' +
        '   AND COALESCE(E.SERIE_FACC_CONCILIACION_EFEC, '''') = ''''';
      q.Open;
      iValidos := q.FieldByName('VALIDOS').AsInteger;
      iEmpresas := q.FieldByName('EMPRESAS').AsInteger;
      iProveedores := q.FieldByName('PROVEEDORES').AsInteger;
      dTotal := q.FieldByName('TOTAL').AsFloat;
      q.Close;
      if iValidos <> Length(AClaves) then
        raise Exception.Create(SErrorFusionarEfectosCompraEstado);
      if (iEmpresas <> 1) or (iProveedores <> 1) then
        raise Exception.Create(SErrorFusionarEfectosCompraOrigen);
      if dTotal <= 0.0001 then
        raise Exception.Create(SErrorFusionarEfectosCompraSinPendiente);
      sSerieDestino := AClaves[0].SerieFac;
      sNumeroDestino := AClaves[0].NumeroFac;
      q.SQL.Text :=
        'SELECT NUMERO_EFEC ' +
        '  FROM fza_efectos_compra ' +
        ' WHERE SERIE_FACC_EFEC = :serie ' +
        '   AND NUMERO_FACC_EFEC = :numero ' +
        ' FOR UPDATE';
      q.ParamByName('serie').AsString := sSerieDestino;
      q.ParamByName('numero').AsString := sNumeroDestino;
      q.Open;
      q.Close;
      q.SQL.Text :=
        'SELECT COALESCE(MAX(NUMERO_EFEC), 0) + 1 AS NUEVO ' +
        '  FROM fza_efectos_compra ' +
        ' WHERE SERIE_FACC_EFEC = :serie ' +
        '   AND NUMERO_FACC_EFEC = :numero';
      q.ParamByName('serie').AsString := sSerieDestino;
      q.ParamByName('numero').AsString := sNumeroDestino;
      q.Open;
      iNuevoEfec := q.FieldByName('NUEVO').AsInteger;
      q.Close;
      AReferencia := Format('CONC %s/%s/%d',
        [sSerieDestino, sNumeroDestino, iNuevoEfec]);
      q.SQL.Text :=
        'INSERT INTO fza_efectos_compra ' +
        '  (SERIE_FACC_EFEC, NUMERO_FACC_EFEC, NUMERO_EFEC, ' +
        '   CODIGO_EMP_EFEC, CODIGO_PRV_EFEC, RAZON_SOCIAL_PRV_EFEC, ' +
        '   NIF_PRV_EFEC, CODIGO_TEFE_EFEC, ESTADO_EFEC, ' +
        '   ORDEN_PLAZO_EFEC, FECHA_EMISION_EFEC, ' +
        '   FECHA_VENCIMIENTO_EFEC, FECHA_PAGO_EFEC, TIPO_PAGO_EFEC, ' +
        '   REFERENCIA_PAGO_EFEC, ENTIDAD_PAGO_EFEC, ' +
        '   ESCONCILIADO_EFEC, IMPORTE_EFEC, IMPORTE_PAGADO_EFEC, ' +
        '   IMPORTE_PENDIENTE_EFEC, SERIE_REMC_EFEC, NUMERO_REMC_EFEC, ' +
        '   ENTIDAD_EFEC, OFICINA_EFEC, DIGITO_CONTROL_EFEC, ' +
        '   CUENTA_EFEC, IBAN_EFEC, CODIGO_EMPBAN_EFEC, IBAN_EMP_EFEC, ' +
        '   DOC_EXTERNO_EFEC, REFERENCIA_DOCUMENTO_EFEC, ' +
        '   OBSERVACIONES_EFEC, INSTANTE_ALTA, USUARIO_ALTA, ' +
        '   INSTANTE_MODIF, USUARIO_MODIF) ' +
        'SELECT H.SERIE_FACC_EFEC, H.NUMERO_FACC_EFEC, :nuevo, ' +
        '       H.CODIGO_EMP_EFEC, H.CODIGO_PRV_EFEC, ' +
        '       H.RAZON_SOCIAL_PRV_EFEC, H.NIF_PRV_EFEC, ' +
        '       H.CODIGO_TEFE_EFEC, ''PENDIENTE'', H.ORDEN_PLAZO_EFEC, ' +
        '       A.FECHA_EMISION, A.FECHA_VENCIMIENTO, NULL, NULL, NULL, ' +
        '       NULL, ''N'', A.TOTAL, 0, A.TOTAL, NULL, NULL, ' +
        '       H.ENTIDAD_EFEC, H.OFICINA_EFEC, H.DIGITO_CONTROL_EFEC, ' +
        '       H.CUENTA_EFEC, H.IBAN_EFEC, H.CODIGO_EMPBAN_EFEC, ' +
        '       H.IBAN_EMP_EFEC, H.DOC_EXTERNO_EFEC, :referencia, ' +
        '       LEFT(CONCAT(''Agrupa efectos: '', A.REFERENCIAS), 1000), ' +
        '       NOW(), :usuario, NOW(), :usuario ' +
        '  FROM fza_efectos_compra H ' +
        '  JOIN (SELECT MIN(E.FECHA_EMISION_EFEC) AS FECHA_EMISION, ' +
        '               MAX(E.FECHA_VENCIMIENTO_EFEC) AS FECHA_VENCIMIENTO, ' +
        '               SUM(COALESCE(E.IMPORTE_PENDIENTE_EFEC, 0)) ' +
        '                 AS TOTAL, ' +
        '               GROUP_CONCAT(CONCAT(E.SERIE_FACC_EFEC, ''/'', ' +
        '                 E.NUMERO_FACC_EFEC, ''/'', E.NUMERO_EFEC) ' +
        '                 ORDER BY E.FECHA_VENCIMIENTO_EFEC, ' +
        '                          E.SERIE_FACC_EFEC, E.NUMERO_FACC_EFEC, ' +
        '                          E.NUMERO_EFEC SEPARATOR '', '') ' +
        '                 AS REFERENCIAS ' +
        '          FROM fza_efectos_compra E ' +
        '          JOIN tmp_efec_fusion T ' +
        '            ON T.SERIE_FACC = E.SERIE_FACC_EFEC ' +
        '           AND T.NUMERO_FACC = E.NUMERO_FACC_EFEC ' +
        '           AND T.NUMERO_EFEC = E.NUMERO_EFEC) A ' +
        ' WHERE H.SERIE_FACC_EFEC = :serie ' +
        '   AND H.NUMERO_FACC_EFEC = :numero ' +
        '   AND H.NUMERO_EFEC = :efecto';
      q.ParamByName('nuevo').AsInteger := iNuevoEfec;
      q.ParamByName('referencia').AsString := AReferencia;
      q.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
      q.ParamByName('serie').AsString := sSerieDestino;
      q.ParamByName('numero').AsString := sNumeroDestino;
      q.ParamByName('efecto').AsInteger := AClaves[0].NumeroEfec;
      q.ExecSQL;
      q.SQL.Text :=
        'UPDATE fza_efectos_compra E ' +
        '  JOIN tmp_efec_fusion T ' +
        '    ON T.SERIE_FACC = E.SERIE_FACC_EFEC ' +
        '   AND T.NUMERO_FACC = E.NUMERO_FACC_EFEC ' +
        '   AND T.NUMERO_EFEC = E.NUMERO_EFEC ' +
        '   SET E.ESTADO_EFEC = ''CONCILIADO'', ' +
        '       E.IMPORTE_PENDIENTE_EFEC = 0, ' +
        '       E.ESCONCILIADO_EFEC = ''S'', ' +
        '       E.REFERENCIA_DOCUMENTO_EFEC = :referencia, ' +
        '       E.SERIE_FACC_CONCILIACION_EFEC = :serie_dst, ' +
        '       E.NUMERO_FACC_CONCILIACION_EFEC = :numero_dst, ' +
        '       E.NUMERO_EFEC_CONCILIACION_EFEC = :efecto_dst, ' +
        '       E.OBSERVACIONES_EFEC = LEFT(CONCAT(' +
        '         COALESCE(NULLIF(E.OBSERVACIONES_EFEC, ''''), ''''), ' +
        '         CASE WHEN COALESCE(E.OBSERVACIONES_EFEC, '''') = '''' ' +
        '              THEN '''' ELSE '' | '' END, ' +
        '         ''Conciliado en '', :referencia), 1000), ' +
        '       E.INSTANTE_MODIF = NOW(), ' +
        '       E.USUARIO_MODIF = :usuario';
      q.ParamByName('referencia').AsString := AReferencia;
      q.ParamByName('serie_dst').AsString := sSerieDestino;
      q.ParamByName('numero_dst').AsString := sNumeroDestino;
      q.ParamByName('efecto_dst').AsInteger := iNuevoEfec;
      q.ParamByName('usuario').AsString := IdentidadSesion.Usuario;
      q.ExecSQL;
      Result := q.RowsAffected;
      q.SQL.Text := 'DROP TEMPORARY TABLE IF EXISTS tmp_efec_fusion';
      q.ExecSQL;
      if bTxOwned then
        ConexionPrincipal.Commit;
      except
        if bTxOwned and ConexionPrincipal.InTransaction then
          ConexionPrincipal.Rollback;
        raise;
      end;
    finally
      FreeAndNil(q);
    end;
    RefrescarCartera;
  end;
end;

function TdmEfectosCompra.RegistrarPago(const ASerie, ANumero: string;
  ANumEfec: Integer; AFecha: TDateTime; AImporte: Double;
  const ATipo, AReferencia: string): Integer;
var
  sp: TUniStoredProc;
begin
  sp := TUniStoredProc.Create(nil);
  try
    sp.Connection     := ConexionPrincipal;
    sp.StoredProcName := 'PRC_EFEC_CONCILIAR_PAGO';
    sp.Params.Clear;
    sp.Params.CreateParam(ftString,  'p_SERIE',      ptInput);
    sp.Params.CreateParam(ftString,  'p_NUMERO',     ptInput);
    sp.Params.CreateParam(ftInteger, 'p_NUM_EFEC',   ptInput);
    sp.Params.CreateParam(ftDate,    'p_FECHA',      ptInput);
    sp.Params.CreateParam(ftFloat,   'p_IMPORTE',    ptInput);
    sp.Params.CreateParam(ftString,  'p_TIPO',       ptInput);
    sp.Params.CreateParam(ftString,  'p_REFERENCIA', ptInput);
    sp.Params.CreateParam(ftString,  'p_ENTIDAD',    ptInput);
    sp.Params.CreateParam(ftString,  'p_USUARIO',    ptInput);
    sp.Params.CreateParam(ftInteger, 'p_RESULTADO',  ptOutput);
    sp.ParamByName('p_SERIE').AsString      := ASerie;
    sp.ParamByName('p_NUMERO').AsString     := ANumero;
    sp.ParamByName('p_NUM_EFEC').AsInteger  := ANumEfec;
    sp.ParamByName('p_FECHA').AsDateTime    := AFecha;
    sp.ParamByName('p_IMPORTE').AsFloat     := AImporte;
    sp.ParamByName('p_TIPO').AsString       := ATipo;
    sp.ParamByName('p_REFERENCIA').AsString := AReferencia;
    sp.ParamByName('p_ENTIDAD').AsString    := '';
    sp.ParamByName('p_USUARIO').AsString    := IdentidadSesion.Usuario;
    sp.ExecProc;
    Result := sp.ParamByName('p_RESULTADO').AsInteger;
  finally
    FreeAndNil(sp);
  end;
  if (unqryTablaG <> nil) and unqryTablaG.Active then
  begin
    unqryTablaG.Close;
    unqryTablaG.Open;
  end;
end;

initialization
  RegistrarDataModule(TdmEfectosCompra);
  ForceReferenceToClass(TdmEfectosCompra);
end.
