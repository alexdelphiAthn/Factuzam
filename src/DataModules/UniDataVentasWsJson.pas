{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVentasWsJson                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.3.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC del serializador de una factura y todos sus datos        }
{    asociados para el webservice.                                             }
{******************************************************************************}
unit UniDataVentasWsJson;

interface

uses
  Uni, inLibVentasWsJsonIntf;

function CrearVentasWsJsonUniDAC(
  AConexion: TUniConnection): IVentasWsJson;

implementation

uses
  System.SysUtils, System.JSON, System.Classes,
  System.DateUtils, System.NetEncoding,
  System.Hash, System.IOUtils,
  Data.DB,
  inLibParametrosIntf, inLibFactuzamApi, inLibMsgFacturas;

type
  TVentasWsJson = class
  private
    class function ConstruirArray(AConn: TUniConnection;
      const ASql, ASerie, ANumero: string): TJSONArray; static;
    class function ConstruirCabecera(AConn: TUniConnection;
      const ASerie, ANumero: string): TJSONObject; static;
    class function ConstruirDocumentos(AConn: TUniConnection;
      AIdCola: Int64): TJSONObject; static;
    class function ConstruirFotos(
      const AParametrosApp: IParametrosAplicacion;
      AConn: TUniConnection;
      const ASerie, ANumero: string): TJSONArray; static;
  public
    class function ConstruirEvento(
      const AParametrosApp: IParametrosAplicacion;
      const AVersionApp: string;
      AConn: TUniConnection;
      AIdCola: Int64;
      const AIdEvento, ATipoEvento, AEmpresa,
        ASerie, ANumero: string): string; static;
  end;
  TVentasWsJsonUniDAC = class(TInterfacedObject, IVentasWsJson)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ConstruirEvento(
      const AParametrosApp: IParametrosAplicacion;
      const AVersionApp: string;
      AIdCola: Int64;
      const AIdEvento, ATipoEvento, AEmpresa,
        ASerie, ANumero: string): string;
  end;

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
        raise Exception.CreateFmt(SErrorFacturaWebserviceNoExiste,
          [ASerie, ANumero]);
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
    except
      FreeAndNil(Result);
      raise;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

{ Fotos de los articulos de la venta, en la version de 300 px que Factuzam
  ya tiene generada en disco. Van a nivel de venta y no de linea: si el mismo
  articulo aparece cinco veces, la foto viaja una sola vez.

  La resolucion replica la de inLibFotos (foto del SKU, si no la del prefijo
  mas largo, si no la del articulo) pero por SQL, para no arrastrar hasta
  aqui las dependencias graficas y de FastReport de aquella unidad. }
class function TVentasWsJson.ConstruirFotos(
  const AParametrosApp: IParametrosAplicacion;
  AConn: TUniConnection;
  const ASerie, ANumero: string): TJSONArray;
const
  cMaxBytesFoto = 4 * 1024 * 1024;
var
  aDatos: TBytes;
  iTamano: Int64;
  oArray: TJSONArray;
  oEnviadas: TStringList;
  oFoto: TJSONObject;
  QryFoto: TUniQuery;
  QryLin: TUniQuery;
  sArticulo: string;
  sClave: string;
  sDir300: string;
  sDirFotos: string;
  sRuta: string;
  sUnidad: string;
begin
  oArray := TJSONArray.Create;
  oEnviadas := TStringList.Create;
  QryLin := TUniQuery.Create(nil);
  QryFoto := TUniQuery.Create(nil);
  try
    try
      oEnviadas.Sorted := True;
      oEnviadas.Duplicates := dupIgnore;
      sDirFotos := '';
      if Assigned(AParametrosApp) then
        sDirFotos := Trim(AParametrosApp.GetPath('appDirFotos'));
      if sDirFotos <> '' then
      begin
        sDir300 := TPath.Combine(sDirFotos, '300');
        QryLin.Connection := AConn;
        QryLin.SQL.Text :=
          ' SELECT DISTINCT CODIGO_ART_FACLIN AS ARTICULO, ' +
          '   IFNULL(CODIGO_UNIDAD_FACLIN, '''') AS UNIDAD ' +
          ' FROM fza_facturas_lineas ' +
          ' WHERE SERIE_FAC_FACLIN = :SERIE ' +
          '   AND NUMERO_FAC_FACLIN = :NUMERO ' +
          '   AND CODIGO_ART_FACLIN IS NOT NULL';
        QryLin.ParamByName('SERIE').AsString := ASerie;
        QryLin.ParamByName('NUMERO').AsString := ANumero;
        QryLin.Open;
        QryFoto.Connection := AConn;
        QryFoto.SQL.Text :=
          ' SELECT CODIGO_UNIDAD_FOT, NOMBRE_FOT_FOT ' +
          ' FROM fza_articulos_fotos ' +
          ' WHERE CODIGO_ART_FOT = :ART ' +
          '   AND (CODIGO_UNIDAD_FOT = :SKU ' +
          '        OR :SKU LIKE CONCAT(CODIGO_UNIDAD_FOT, ''/%'') ' +
          '        OR CODIGO_UNIDAD_FOT = '''') ' +
          ' ORDER BY LENGTH(CODIGO_UNIDAD_FOT) DESC, ' +
          '          CODIGO_UNIDAD_FOT DESC ' +
          ' LIMIT 1';
        while not QryLin.Eof do
        begin
          sArticulo := QryLin.FieldByName('ARTICULO').AsString;
          sUnidad := QryLin.FieldByName('UNIDAD').AsString;
          QryFoto.Close;
          QryFoto.ParamByName('ART').AsString := sArticulo;
          QryFoto.ParamByName('SKU').AsString := sUnidad;
          QryFoto.Open;
          if not QryFoto.IsEmpty then
          begin
            sClave := sArticulo + '|' +
                      QryFoto.FieldByName('CODIGO_UNIDAD_FOT').AsString;
            sRuta := TPath.Combine(sDir300,
              QryFoto.FieldByName('NOMBRE_FOT_FOT').AsString + '.png');
            if (oEnviadas.IndexOf(sClave) < 0) and TFile.Exists(sRuta) then
            begin
              iTamano := TFile.GetSize(sRuta);
              if (iTamano > 0) and (iTamano <= cMaxBytesFoto) then
              begin
                oEnviadas.Add(sClave);
                aDatos := TFile.ReadAllBytes(sRuta);
                oFoto := TJSONObject.Create;
                oArray.AddElement(oFoto);
                oFoto.AddPair('articulo', sArticulo);
                oFoto.AddPair('clave_unidad',
                  QryFoto.FieldByName('CODIGO_UNIDAD_FOT').AsString);
                oFoto.AddPair('nombre', ExtractFileName(sRuta));
                oFoto.AddPair('mime', 'image/png');
                oFoto.AddPair('tamano', TJSONNumber.Create(iTamano));
                oFoto.AddPair('sha256',
                  UpperCase(THashSHA2.GetHashStringFromFile(sRuta)));
                oFoto.AddPair('contenido_base64',
                  TNetEncoding.Base64.EncodeBytesToString(aDatos));
              end;
            end;
          end;
          QryFoto.Close;
          QryLin.Next;
        end;
        QryLin.Close;
      end;
      Result := oArray;
    except
      // Que falle una foto no puede impedir que la venta se envie.
      FreeAndNil(oArray);
      Result := TJSONArray.Create;
    end;
  finally
    FreeAndNil(QryFoto);
    FreeAndNil(QryLin);
    FreeAndNil(oEnviadas);
  end;
end;

class function TVentasWsJson.ConstruirEvento(
  const AParametrosApp: IParametrosAplicacion;
  const AVersionApp: string;
  AConn: TUniConnection;
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
    oRaiz.AddPair('origen', oOrigen);
    oOrigen.AddPair('aplicacion', 'Factuzam');
    oOrigen.AddPair('version', AVersionApp);
    sReferencia := TClienteFactuzamApi.Referencia(AParametrosApp);
    oOrigen.AddPair('referencia', sReferencia);
    oDocumento := TJSONObject.Create;
    oDocumento.AddPair('empresa', AEmpresa);
    oDocumento.AddPair('serie', ASerie);
    oDocumento.AddPair('numero', ANumero);
    oRaiz.AddPair('documento', oDocumento);
    oVenta := TJSONObject.Create;
    oRaiz.AddPair('venta', oVenta);
    oVenta.AddPair('cabecera',
      ConstruirCabecera(AConn, ASerie, ANumero));
    // La temporada no vive en la linea: es una propiedad del articulo. Se
    // resuelve del nivel mas concreto al mas general (sku, color, articulo)
    // y viaja como TEMPORADA_CALC, que es lo que proyecta el webservice.
    oVenta.AddPair('lineas', ConstruirArray(AConn,
      ' SELECT L.*, ' +
      '   (SELECT COALESCE(V.PV, P.VALOR_LIBRE_ARTPROP) ' +
      '      FROM fza_articulos_propiedades P ' +
      '      LEFT JOIN fza_propiedades_valores V ' +
      '             ON V.ID_PV_ARTPROP = P.ID_PV_ARTPROP ' +
      '     WHERE P.CODIGO_ART_ART = L.CODIGO_ART_FACLIN ' +
      '       AND P.CODIGO_PROP_ARTPROP = ''TEMPORADA'' ' +
      '       AND P.CODIGO_UNIDAD_ARTPROP IN ( ' +
      '             IFNULL(L.CODIGO_UNIDAD_FACLIN, ''''), ' +
      '             SUBSTRING_INDEX( ' +
      '               IFNULL(L.CODIGO_UNIDAD_FACLIN, ''''), ''/'', 2), ' +
      '             '''') ' +
      '     ORDER BY LENGTH(P.CODIGO_UNIDAD_ARTPROP) DESC, ' +
      '              P.CODIGO_UNIDAD_ARTPROP DESC ' +
      '     LIMIT 1) AS TEMPORADA_CALC ' +
      ' FROM fza_facturas_lineas L ' +
      ' WHERE L.SERIE_FAC_FACLIN = :SERIE ' +
      '   AND L.NUMERO_FAC_FACLIN = :NUMERO ' +
      ' ORDER BY L.LINEA_FACLIN', ASerie, ANumero));
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
    oVenta.AddPair('fiscal', oFiscal);
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
    oVenta.AddPair('documentos', ConstruirDocumentos(AConn, AIdCola));
    oVenta.AddPair('fotos',
      ConstruirFotos(AParametrosApp, AConn, ASerie, ANumero));
    Result := oRaiz.ToJSON;
  finally
    FreeAndNil(oRaiz);
  end;
end;

constructor TVentasWsJsonUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TVentasWsJsonUniDAC.ConstruirEvento(
  const AParametrosApp: IParametrosAplicacion;
  const AVersionApp: string;
  AIdCola: Int64;
  const AIdEvento, ATipoEvento, AEmpresa,
    ASerie, ANumero: string): string;
begin
  Result := TVentasWsJson.ConstruirEvento(
    AParametrosApp, AVersionApp, FConexion, AIdCola,
    AIdEvento, ATipoEvento, AEmpresa, ASerie, ANumero);
end;

function CrearVentasWsJsonUniDAC(
  AConexion: TUniConnection): IVentasWsJson;
begin
  Result := TVentasWsJsonUniDAC.Create(AConexion);
end;

initialization
  TFabricaVentasWsJson.Registrar(CrearVentasWsJsonUniDAC);

end.
