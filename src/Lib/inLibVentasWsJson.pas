{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVentasWsJson                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Serializa una factura y todos sus datos asociados para el webservice.     }
{******************************************************************************}
unit inLibVentasWsJson;

interface

uses
  System.SysUtils, System.JSON, Uni;

type
  TVentasWsJson = class
  private
    class function ConstruirArray(AConn: TUniConnection;
      const ASql, ASerie, ANumero: string): TJSONArray; static;
    class function ConstruirCabecera(AConn: TUniConnection;
      const ASerie, ANumero: string): TJSONObject; static;
    class function ConstruirDocumentos(AConn: TUniConnection;
      AIdCola: Int64): TJSONObject; static;
  public
    class function ConstruirEvento(AConn: TUniConnection;
      AIdCola: Int64; const AIdEvento, ATipoEvento, AEmpresa,
      ASerie, ANumero: string): string; static;
  end;

implementation

uses
  System.Classes, System.DateUtils, System.NetEncoding,
  Data.DB,
  inLibGlobalVar, inLibAppParam;

function LeerCampoBinario(ACampo: TField): TBytes;
var
  oFlujo: TStream;
begin
  SetLength(Result, 0);
  oFlujo := ACampo.DataSet.CreateBlobStream(ACampo, bmRead);
  try
    SetLength(Result, oFlujo.Size);
    if oFlujo.Size > 0 then
      oFlujo.ReadBuffer(Result[0], oFlujo.Size);
  finally
    FreeAndNil(oFlujo);
  end;
end;

function CampoAJson(ACampo: TField): TJSONValue;
var
  aDatos: TBytes;
  dtUtc: TDateTime;
  sNumero: string;
begin
  if ACampo.IsNull then
    Result := TJSONNull.Create
  else
  begin
    case ACampo.DataType of
      ftSmallint, ftInteger, ftWord, ftAutoInc, ftLargeint, ftLongWord,
      ftShortint, ftByte:
        Result := TJSONNumber.Create(ACampo.AsLargeInt);
      ftFloat, ftCurrency, ftBCD, ftFMTBcd, ftExtended, ftSingle:
        begin
          sNumero := FloatToStr(ACampo.AsFloat,
                                TFormatSettings.Invariant);
          Result := TJSONNumber.Create(sNumero);
        end;
      ftBoolean:
        Result := TJSONBool.Create(ACampo.AsBoolean);
      ftDate:
        Result := TJSONString.Create(
          FormatDateTime('yyyy-mm-dd', ACampo.AsDateTime));
      ftTime:
        Result := TJSONString.Create(
          FormatDateTime('hh:nn:ss.zzz', ACampo.AsDateTime));
      ftDateTime, ftTimeStamp, ftTimeStampOffset:
        begin
          dtUtc := TTimeZone.Local.ToUniversalTime(ACampo.AsDateTime);
          Result := TJSONString.Create(DateToISO8601(dtUtc, True));
        end;
      ftBlob, ftGraphic, ftOraBlob:
        begin
          aDatos := LeerCampoBinario(ACampo);
          Result := TJSONString.Create(
            TNetEncoding.Base64.EncodeBytesToString(aDatos));
        end;
      ftBytes, ftVarBytes:
        begin
          aDatos := ACampo.AsBytes;
          Result := TJSONString.Create(
            TNetEncoding.Base64.EncodeBytesToString(aDatos));
        end;
    else
      Result := TJSONString.Create(ACampo.AsString);
    end;
  end;
end;

function RegistroAJson(ADataSet: TDataSet): TJSONObject;
var
  iCampo: Integer;
begin
  Result := TJSONObject.Create;
  for iCampo := 0 to ADataSet.FieldCount - 1 do
    Result.AddPair(ADataSet.Fields[iCampo].FieldName,
                   CampoAJson(ADataSet.Fields[iCampo]));
end;

class function TVentasWsJson.ConstruirArray(AConn: TUniConnection;
  const ASql, ASerie, ANumero: string): TJSONArray;
var
  oArray: TJSONArray;
  Qry: TUniQuery;
begin
  oArray := TJSONArray.Create;
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      Qry.SQL.Text := ASql;
      if Assigned(Qry.Params.FindParam('SERIE')) then
        Qry.ParamByName('SERIE').AsString := ASerie;
      if Assigned(Qry.Params.FindParam('NUMERO')) then
        Qry.ParamByName('NUMERO').AsString := ANumero;
      Qry.Open;
      while not Qry.Eof do
      begin
        oArray.AddElement(RegistroAJson(Qry));
        Qry.Next;
      end;
      Result := oArray;
    except
      FreeAndNil(oArray);
      raise;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

class function TVentasWsJson.ConstruirCabecera(AConn: TUniConnection;
  const ASerie, ANumero: string): TJSONObject;
var
  oCabecera: TJSONObject;
  Qry: TUniQuery;
begin
  oCabecera := nil;
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      Qry.SQL.Text :=
        ' SELECT * FROM fza_facturas ' +
        ' WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO';
      Qry.ParamByName('SERIE').AsString := ASerie;
      Qry.ParamByName('NUMERO').AsString := ANumero;
      Qry.Open;
      if Qry.IsEmpty then
        raise Exception.Create('No existe la factura ' + ASerie + '\' +
                               ANumero + ' para enviarla al webservice.');
      oCabecera := RegistroAJson(Qry);
      Result := oCabecera;
    except
      FreeAndNil(oCabecera);
      raise;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

class function TVentasWsJson.ConstruirDocumentos(AConn: TUniConnection;
  AIdCola: Int64): TJSONObject;
var
  Qry: TUniQuery;

  procedure AgregarPdf(const AClave, ACampoNombre, ACampoContenido,
    ACampoTamano, ACampoHuella: string);
  var
    aPdf: TBytes;
    oPdf: TJSONObject;
  begin
    if not Qry.FieldByName(ACampoContenido).IsNull then
    begin
      aPdf := LeerCampoBinario(Qry.FieldByName(ACampoContenido));
      oPdf := TJSONObject.Create;
      oPdf.AddPair('nombre', Qry.FieldByName(ACampoNombre).AsString);
      oPdf.AddPair('mime', 'application/pdf');
      oPdf.AddPair('tamano', TJSONNumber.Create(
        Qry.FieldByName(ACampoTamano).AsLargeInt));
      oPdf.AddPair('sha256', Qry.FieldByName(ACampoHuella).AsString);
      oPdf.AddPair('contenido_base64',
        TNetEncoding.Base64.EncodeBytesToString(aPdf));
      Result.AddPair(AClave, oPdf);
    end;
  end;

begin
  Result := TJSONObject.Create;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' SELECT NOMBRE_PDF_VWSC, TICKET_PDF_VWSC, ' +
      '        TAMANO_PDF_VWSC, HUELLA_PDF_VWSC, ' +
      '        NOMBRE_FACTURA_PDF_VWSC, FACTURA_PDF_VWSC, ' +
      '        TAMANO_FACTURA_PDF_VWSC, HUELLA_FACTURA_PDF_VWSC ' +
      ' FROM fza_ventas_ws_cola WHERE ID_VWSC = :ID';
    Qry.ParamByName('ID').AsLargeInt := AIdCola;
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      AgregarPdf('ticket_pdf', 'NOMBRE_PDF_VWSC', 'TICKET_PDF_VWSC',
        'TAMANO_PDF_VWSC', 'HUELLA_PDF_VWSC');
      AgregarPdf('factura_pdf', 'NOMBRE_FACTURA_PDF_VWSC',
        'FACTURA_PDF_VWSC', 'TAMANO_FACTURA_PDF_VWSC',
        'HUELLA_FACTURA_PDF_VWSC');
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

class function TVentasWsJson.ConstruirEvento(AConn: TUniConnection;
  AIdCola: Int64; const AIdEvento, ATipoEvento, AEmpresa,
  ASerie, ANumero: string): string;
var
  oDocumento: TJSONObject;
  oFiscal: TJSONObject;
  oOrigen: TJSONObject;
  oRaiz: TJSONObject;
  oVenta: TJSONObject;
  sReferencia: string;
begin
  oRaiz := TJSONObject.Create;
  try
    oRaiz.AddPair('version_contrato', TJSONNumber.Create(1));
    oRaiz.AddPair('id_evento', AIdEvento);
    oRaiz.AddPair('secuencia_evento', TJSONNumber.Create(AIdCola));
    oRaiz.AddPair('tipo_evento', ATipoEvento);
    oRaiz.AddPair('generado_utc',
      DateToISO8601(TTimeZone.Local.ToUniversalTime(Now), True));
    oOrigen := TJSONObject.Create;
    oOrigen.AddPair('aplicacion', 'Factuzam');
    oOrigen.AddPair('version', oVersion);
    sReferencia := oAppParams.GetString('appApiReferencia', '');
    if Trim(sReferencia) = '' then
      sReferencia := oAppParams.GetString('appFotosCarpetaCliente', '');
    oOrigen.AddPair('referencia', sReferencia);
    oRaiz.AddPair('origen', oOrigen);
    oDocumento := TJSONObject.Create;
    oDocumento.AddPair('empresa', AEmpresa);
    oDocumento.AddPair('serie', ASerie);
    oDocumento.AddPair('numero', ANumero);
    oRaiz.AddPair('documento', oDocumento);
    oVenta := TJSONObject.Create;
    oVenta.AddPair('cabecera',
      ConstruirCabecera(AConn, ASerie, ANumero));
    oVenta.AddPair('lineas', ConstruirArray(AConn,
      ' SELECT * FROM fza_facturas_lineas ' +
      ' WHERE SERIE_FAC_FACLIN = :SERIE ' +
      '   AND NUMERO_FAC_FACLIN = :NUMERO ' +
      ' ORDER BY LINEA_FACLIN', ASerie, ANumero));
    oVenta.AddPair('pagos_factura', ConstruirArray(AConn,
      ' SELECT * FROM fza_facturas_pagos ' +
      ' WHERE SERIE_FAC_FACPAG = :SERIE ' +
      '   AND NUMERO_FAC_FACPAG = :NUMERO ' +
      ' ORDER BY LINEA_FACPAG', ASerie, ANumero));
    oVenta.AddPair('recibos', ConstruirArray(AConn,
      ' SELECT * FROM fza_recibos ' +
      ' WHERE SERIE_FAC_REC = :SERIE ' +
      '   AND NUMERO_FAC_REC = :NUMERO ' +
      ' ORDER BY NUMERO_PLAZO_REC', ASerie, ANumero));
    oVenta.AddPair('efectos_venta', ConstruirArray(AConn,
      ' SELECT * FROM fza_efectos_venta ' +
      ' WHERE SERIE_FAC_EFV = :SERIE ' +
      '   AND NUMERO_FAC_EFV = :NUMERO ' +
      ' ORDER BY NUMERO_EFV', ASerie, ANumero));
    oVenta.AddPair('pagos_caja', ConstruirArray(AConn,
      ' SELECT P.* FROM fza_caja_pagos P ' +
      ' INNER JOIN fza_facturas F ' +
      '   ON F.CODIGO_EMP_FAC = P.CODIGO_EMP_PAGO ' +
      '  AND F.CODIGO_ALM_FAC = P.CODIGO_ALM_PAGO ' +
      '  AND F.CODIGO_CAJA_FAC = P.CODIGO_CAJA_PAGO ' +
      '  AND F.SERIE_FAC = P.SERIE_OPERACION_PAGO ' +
      '  AND F.NUMERO_OPERACION_FAC = P.NUMERO_OPERACION_PAGO ' +
      ' WHERE F.SERIE_FAC = :SERIE AND F.NUMERO_FAC = :NUMERO ' +
      ' ORDER BY P.NUMERO_LINEA_PAGO', ASerie, ANumero));
    oVenta.AddPair('operaciones_caja', ConstruirArray(AConn,
      ' SELECT O.* FROM fza_caja_operaciones O ' +
      ' WHERE O.SERIE_FAC_OPCAJA = :SERIE ' +
      '   AND O.NUMERO_FAC_OPCAJA = :NUMERO ' +
      ' ORDER BY O.ID_OPCAJA', ASerie, ANumero));
    oVenta.AddPair('movimientos_almacen', ConstruirArray(AConn,
      ' SELECT * FROM fza_movimientos_almacen ' +
      ' WHERE SERIE_DOC_MOV = :SERIE AND NUMERO_DOC_MOV = :NUMERO ' +
      ' ORDER BY NUMERO_MOV', ASerie, ANumero));
    oVenta.AddPair('vales', ConstruirArray(AConn,
      ' SELECT * FROM fza_caja_vales ' +
      ' WHERE (SERIE_FAC_EMI_VL = :SERIE ' +
      '        AND NUMERO_FAC_EMI_VL = :NUMERO) ' +
      '    OR (SERIE_FAC_RED_VL = :SERIE ' +
      '        AND NUMERO_FAC_RED_VL = :NUMERO) ' +
      ' ORDER BY CODIGO_VL', ASerie, ANumero));
    oVenta.AddPair('depositos', ConstruirArray(AConn,
      ' SELECT DISTINCT D.* FROM fza_depositos_cliente D ' +
      ' INNER JOIN fza_caja_operaciones O ' +
      '   ON O.ID_DEPOSITO_OPCAJA = D.ID_DEPOSITO_DEP ' +
      ' WHERE O.SERIE_FAC_OPCAJA = :SERIE ' +
      '   AND O.NUMERO_FAC_OPCAJA = :NUMERO ' +
      ' ORDER BY D.ID_DEPOSITO_DEP', ASerie, ANumero));
    oVenta.AddPair('relaciones', ConstruirArray(AConn,
      ' SELECT * FROM fza_facturas_relaciones ' +
      ' WHERE (SERIE_FAC_FACREL = :SERIE ' +
      '        AND NUMERO_FAC_FACREL = :NUMERO) ' +
      '    OR (SERIE_FAC_ORIGEN_FACREL = :SERIE ' +
      '        AND NUMERO_FAC_ORIGEN_FACREL = :NUMERO) ' +
      ' ORDER BY ID_FACREL', ASerie, ANumero));
    oFiscal := TJSONObject.Create;
    oFiscal.AddPair('cola', ConstruirArray(AConn,
      ' SELECT * FROM fza_verifactu_cola ' +
      ' WHERE SERIE_FAC_VFCOLA = :SERIE ' +
      '   AND NUMERO_FAC_VFCOLA = :NUMERO ' +
      ' ORDER BY ID_VFCOLA', ASerie, ANumero));
    oFiscal.AddPair('consolidaciones', ConstruirArray(AConn,
      ' SELECT * FROM fza_facturas_consolidaciones ' +
      ' WHERE SERIE_FAC_FACCON = :SERIE ' +
      '   AND NUMERO_FAC_FACCON = :NUMERO ' +
      ' ORDER BY ID_FACCON', ASerie, ANumero));
    oFiscal.AddPair('eventos', ConstruirArray(AConn,
      ' SELECT * FROM fza_verifactu_eventos ' +
      ' WHERE SERIE_FAC_LOG = :SERIE AND NUMERO_FAC_LOG = :NUMERO ' +
      ' ORDER BY ID_LOG', ASerie, ANumero));
    oVenta.AddPair('fiscal', oFiscal);
    oVenta.AddPair('documentos', ConstruirDocumentos(AConn, AIdCola));
    oRaiz.AddPair('venta', oVenta);
    Result := oRaiz.ToJSON;
  finally
    FreeAndNil(oRaiz);
  end;
end;

end.
