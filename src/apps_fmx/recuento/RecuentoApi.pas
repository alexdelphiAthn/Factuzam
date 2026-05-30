{******************************************************************************}
{                                                                              }
{  Módulo:       RecuentoApi                                                   }
{    Tipo:       Librería (App FMX)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cliente REST de la app contra el servidor PHP de recuentos. Calca el      }
{    stack de inLibFotosNube (System.Net.HttpClient + System.JSON). Cabeceras  }
{    X-API-Key (token del dispositivo) y X-Carpeta (carpeta_cliente).          }
{    Contrato en DESARROLLOS EN CURSO/recuento_inventarios_php.md.             }
{******************************************************************************}
unit RecuentoApi;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.NetEncoding,
  System.Net.HttpClient, System.Net.URLClient,
  RecuentoModelo, RecuentoConfig;

type
  TRecuentoApi = class
  private
    FUltimoError: string;
    procedure PrepararCabeceras(AHttp: THTTPClient; AConToken: Boolean);
    function MensajeError(const ABody: string; AStatus: Integer): string;
    function GetJson(const ARuta: string; out ABody: string): Integer;
    function PostJson(const ARuta, ABody: string; out ARespuesta: string;
                      AConToken: Boolean = True): Integer;
  public
    function RegistrarDispositivo(const ANombre, AOperario,
      AClaveAlta: string; out AToken: string): Boolean;
    function ListarAlmacenes(out ALista: TArrAlmacen): Boolean;
    function ListarPlantillas(out ALista: TArrPlantilla): Boolean;
    function CrearRecuentoLibre(const ACodigoEmp, ACodigoAlm,
      ADescripcion: string; out AIdRecuento: Int64): Boolean;
    function CrearTraspaso(const ACodigoEmp, AOrigen, ADestino: string;
      out AIdRecuento: Int64): Boolean;
    function DescargarCatalogo(AIdRecuento: Int64;
      out ALista: TArrCatalogo): Boolean;
    function SubirEventos(AIdRecuento: Int64; const AEventos: TArrEvento;
      out AAceptados, ADuplicados: Integer): Boolean;
    function Finalizar(AIdRecuento: Int64): Boolean;
    function Reabrir(AIdRecuento: Int64): Boolean;
    property UltimoError: string read FUltimoError;
  end;

implementation

// ============================================================================
//   Helpers JSON
// ============================================================================

function JStr(AObj: TJSONObject; const AClave: string): string;
var
  oVal: TJSONValue;
begin
  Result := '';
  if AObj <> nil then
  begin
    oVal := AObj.GetValue(AClave);
    if (oVal <> nil) and not (oVal is TJSONNull) then
      Result := oVal.Value;
  end;
end;

function JNum(AObj: TJSONObject; const AClave: string): Double;
var
  oVal: TJSONValue;
begin
  Result := 0;
  if AObj <> nil then
  begin
    oVal := AObj.GetValue(AClave);
    if oVal is TJSONNumber then
      Result := TJSONNumber(oVal).AsDouble
    else if (oVal <> nil) and not (oVal is TJSONNull) then
      Result := StrToFloatDef(oVal.Value, 0);
  end;
end;

function StreamAString(AStream: TStream): string;
var
  oSS: TStringStream;
begin
  oSS := TStringStream.Create('', TEncoding.UTF8);
  try
    AStream.Position := 0;
    if AStream.Size > 0 then
      oSS.CopyFrom(AStream, AStream.Size);
    Result := oSS.DataString;
  finally
    FreeAndNil(oSS);
  end;
end;

// ============================================================================
//   Transporte HTTP
// ============================================================================

procedure TRecuentoApi.PrepararCabeceras(AHttp: THTTPClient;
  AConToken: Boolean);
begin
  AHttp.CustomHeaders['X-Carpeta'] := oConfig.Carpeta;
  if AConToken and (Trim(oConfig.Token) <> '') then
    AHttp.CustomHeaders['X-API-Key'] := oConfig.Token;
end;

function TRecuentoApi.MensajeError(const ABody: string;
  AStatus: Integer): string;
var
  oJson: TJSONValue;
  sMsg: string;
begin
  sMsg := '';
  oJson := TJSONObject.ParseJSONValue(ABody);
  try
    if oJson is TJSONObject then
      sMsg := JStr(TJSONObject(oJson), 'message');
  finally
    FreeAndNil(oJson);
  end;
  if sMsg = '' then
    sMsg := Format('Error del servidor (HTTP %d)', [AStatus]);
  Result := sMsg;
end;

function TRecuentoApi.GetJson(const ARuta: string; out ABody: string): Integer;
var
  oHttp: THTTPClient;
  oResp: TMemoryStream;
  oRespHttp: IHTTPResponse;
begin
  Result := 0;
  ABody := '';
  oHttp := THTTPClient.Create;
  oResp := TMemoryStream.Create;
  try
    PrepararCabeceras(oHttp, True);
    try
      oRespHttp := oHttp.Get(oConfig.UrlBase + ARuta, oResp);
      Result := oRespHttp.StatusCode;
      ABody := StreamAString(oResp);
    except
      on E: Exception do
      begin
        FUltimoError := 'No se pudo conectar: ' + E.Message;
        Result := 0;
      end;
    end;
  finally
    FreeAndNil(oResp);
    FreeAndNil(oHttp);
  end;
end;

function TRecuentoApi.PostJson(const ARuta, ABody: string;
  out ARespuesta: string; AConToken: Boolean): Integer;
var
  oHttp: THTTPClient;
  oReq: TStringStream;
  oResp: TMemoryStream;
  oRespHttp: IHTTPResponse;
begin
  Result := 0;
  ARespuesta := '';
  oHttp := THTTPClient.Create;
  oReq := TStringStream.Create(ABody, TEncoding.UTF8);
  oResp := TMemoryStream.Create;
  try
    PrepararCabeceras(oHttp, AConToken);
    oHttp.CustomHeaders['Content-Type'] := 'application/json';
    try
      oRespHttp := oHttp.Post(oConfig.UrlBase + ARuta, oReq, oResp);
      Result := oRespHttp.StatusCode;
      ARespuesta := StreamAString(oResp);
    except
      on E: Exception do
      begin
        FUltimoError := 'No se pudo conectar: ' + E.Message;
        Result := 0;
      end;
    end;
  finally
    FreeAndNil(oResp);
    FreeAndNil(oReq);
    FreeAndNil(oHttp);
  end;
end;

// ============================================================================
//   API pública
// ============================================================================

function TRecuentoApi.RegistrarDispositivo(const ANombre, AOperario,
  AClaveAlta: string; out AToken: string): Boolean;
var
  oReq: TJSONObject;
  sResp: string;
  iStatus: Integer;
  oRespJson: TJSONValue;
begin
  Result := False;
  AToken := '';
  oReq := TJSONObject.Create;
  try
    oReq.AddPair('nombre', ANombre);
    oReq.AddPair('operario', AOperario);
    oReq.AddPair('clave_alta', AClaveAlta);
    iStatus := PostJson('disp_registrar.php', oReq.ToString, sResp, False);
  finally
    FreeAndNil(oReq);
  end;
  if iStatus = 200 then
  begin
    oRespJson := TJSONObject.ParseJSONValue(sResp);
    try
      if oRespJson is TJSONObject then
        AToken := JStr(TJSONObject(oRespJson), 'token');
    finally
      FreeAndNil(oRespJson);
    end;
    Result := AToken <> '';
    if not Result then
      FUltimoError := 'El servidor no devolvió token';
  end
  else if iStatus <> 0 then
    FUltimoError := MensajeError(sResp, iStatus);
end;

function TRecuentoApi.ListarAlmacenes(out ALista: TArrAlmacen): Boolean;
var
  sBody: string;
  iStatus, i: Integer;
  oJson: TJSONValue;
  oArr: TJSONArray;
  oIt: TJSONObject;
  Rec: TAlmacenRec;
begin
  Result := False;
  SetLength(ALista, 0);
  iStatus := GetJson('inv_almacenes.php', sBody);
  if iStatus = 200 then
  begin
    oJson := TJSONObject.ParseJSONValue(sBody);
    try
      if oJson is TJSONArray then
      begin
        oArr := TJSONArray(oJson);
        for i := 0 to oArr.Count - 1 do
          if oArr.Items[i] is TJSONObject then
          begin
            oIt := TJSONObject(oArr.Items[i]);
            Rec.CodigoEmp := JStr(oIt, 'codigo_emp');
            Rec.CodigoAlm := JStr(oIt, 'codigo_alm');
            Rec.Nombre    := JStr(oIt, 'nombre');
            ALista := ALista + [Rec];
          end;
        Result := True;
      end;
    finally
      FreeAndNil(oJson);
    end;
  end
  else if iStatus <> 0 then
    FUltimoError := MensajeError(sBody, iStatus);
end;

function TRecuentoApi.ListarPlantillas(out ALista: TArrPlantilla): Boolean;
var
  sBody: string;
  iStatus, i: Integer;
  oJson: TJSONValue;
  oArr: TJSONArray;
  oIt: TJSONObject;
  Rec: TPlantillaRec;
begin
  Result := False;
  SetLength(ALista, 0);
  iStatus := GetJson('inv_recuentos.php', sBody);
  if iStatus = 200 then
  begin
    oJson := TJSONObject.ParseJSONValue(sBody);
    try
      if oJson is TJSONArray then
      begin
        oArr := TJSONArray(oJson);
        for i := 0 to oArr.Count - 1 do
          if oArr.Items[i] is TJSONObject then
          begin
            oIt := TJSONObject(oArr.Items[i]);
            Rec.IdRecuento  := Trunc(JNum(oIt, 'id'));
            Rec.CodigoEmp   := JStr(oIt, 'codigo_emp');
            Rec.CodigoAlm   := JStr(oIt, 'codigo_alm');
            Rec.Serie       := JStr(oIt, 'serie');
            Rec.Numero      := JStr(oIt, 'numero');
            Rec.Descripcion := JStr(oIt, 'descripcion');
            ALista := ALista + [Rec];
          end;
        Result := True;
      end;
    finally
      FreeAndNil(oJson);
    end;
  end
  else if iStatus <> 0 then
    FUltimoError := MensajeError(sBody, iStatus);
end;

function TRecuentoApi.CrearRecuentoLibre(const ACodigoEmp, ACodigoAlm,
  ADescripcion: string; out AIdRecuento: Int64): Boolean;
var
  oReq: TJSONObject;
  sResp: string;
  iStatus: Integer;
  oRespJson: TJSONValue;
begin
  Result := False;
  AIdRecuento := 0;
  oReq := TJSONObject.Create;
  try
    oReq.AddPair('codigo_emp', ACodigoEmp);
    oReq.AddPair('codigo_alm', ACodigoAlm);
    oReq.AddPair('descripcion', ADescripcion);
    iStatus := PostJson('inv_recuentos.php', oReq.ToString, sResp);
  finally
    FreeAndNil(oReq);
  end;
  if iStatus = 200 then
  begin
    oRespJson := TJSONObject.ParseJSONValue(sResp);
    try
      if oRespJson is TJSONObject then
        AIdRecuento := Trunc(JNum(TJSONObject(oRespJson), 'id_recuento'));
    finally
      FreeAndNil(oRespJson);
    end;
    Result := AIdRecuento > 0;
    if not Result then
      FUltimoError := 'El servidor no devolvió id_recuento';
  end
  else if iStatus <> 0 then
    FUltimoError := MensajeError(sResp, iStatus);
end;

function TRecuentoApi.CrearTraspaso(const ACodigoEmp, AOrigen,
  ADestino: string; out AIdRecuento: Int64): Boolean;
var
  oReq: TJSONObject;
  sResp: string;
  iStatus: Integer;
  oRespJson: TJSONValue;
begin
  Result := False;
  AIdRecuento := 0;
  oReq := TJSONObject.Create;
  try
    oReq.AddPair('tipo', 'TRASPASO');
    oReq.AddPair('codigo_emp', ACodigoEmp);
    oReq.AddPair('codigo_alm', AOrigen);
    oReq.AddPair('codigo_alm_destino', ADestino);
    iStatus := PostJson('inv_recuentos.php', oReq.ToString, sResp);
  finally
    FreeAndNil(oReq);
  end;
  if iStatus = 200 then
  begin
    oRespJson := TJSONObject.ParseJSONValue(sResp);
    try
      if oRespJson is TJSONObject then
        AIdRecuento := Trunc(JNum(TJSONObject(oRespJson), 'id_recuento'));
    finally
      FreeAndNil(oRespJson);
    end;
    Result := AIdRecuento > 0;
    if not Result then
      FUltimoError := 'El servidor no devolvió id_recuento';
  end
  else if iStatus <> 0 then
    FUltimoError := MensajeError(sResp, iStatus);
end;

function TRecuentoApi.DescargarCatalogo(AIdRecuento: Int64;
  out ALista: TArrCatalogo): Boolean;
var
  sBody: string;
  iStatus, i: Integer;
  oJson: TJSONValue;
  oArr: TJSONArray;
  oIt: TJSONObject;
  Rec: TItemCatalogoRec;
begin
  Result := False;
  SetLength(ALista, 0);
  iStatus := GetJson('inv_catalogo.php?id_recuento=' +
                     IntToStr(AIdRecuento), sBody);
  if iStatus = 200 then
  begin
    oJson := TJSONObject.ParseJSONValue(sBody);
    try
      if oJson is TJSONArray then
      begin
        oArr := TJSONArray(oJson);
        for i := 0 to oArr.Count - 1 do
          if oArr.Items[i] is TJSONObject then
          begin
            oIt := TJSONObject(oArr.Items[i]);
            Rec.CodigoArticulo  := JStr(oIt, 'codigo_articulo');
            Rec.CodigoUnidad    := JStr(oIt, 'codigo_unidad');
            Rec.Descripcion     := JStr(oIt, 'descripcion');
            Rec.CodigoBarras    := JStr(oIt, 'codigo_barras');
            Rec.CantidadTeorica := JNum(oIt, 'cantidad_teorica');
            Rec.EsTrazable      := JStr(oIt, 'estrazable') = 'S';
            ALista := ALista + [Rec];
          end;
        Result := True;
      end;
    finally
      FreeAndNil(oJson);
    end;
  end
  else if iStatus <> 0 then
    FUltimoError := MensajeError(sBody, iStatus);
end;

function TRecuentoApi.SubirEventos(AIdRecuento: Int64;
  const AEventos: TArrEvento; out AAceptados, ADuplicados: Integer): Boolean;
var
  oReq, oEv: TJSONObject;
  oArr: TJSONArray;
  i, iStatus: Integer;
  sResp: string;
  oRespJson: TJSONValue;
begin
  Result := False;
  AAceptados := 0;
  ADuplicados := 0;
  oReq := TJSONObject.Create;
  try
    oReq.AddPair('id_recuento', TJSONNumber.Create(AIdRecuento));
    oReq.AddPair('dispositivo', oConfig.Dispositivo);
    oReq.AddPair('operario', oConfig.Operario);
    oArr := TJSONArray.Create;
    for i := 0 to High(AEventos) do
    begin
      oEv := TJSONObject.Create;
      oEv.AddPair('uuid', AEventos[i].Uuid);
      oEv.AddPair('codigo_barras', AEventos[i].CodigoBarras);
      oEv.AddPair('codigo_articulo', AEventos[i].CodigoArticulo);
      oEv.AddPair('codigo_unidad', AEventos[i].CodigoUnidad);
      oEv.AddPair('cantidad', TJSONNumber.Create(AEventos[i].Cantidad));
      oEv.AddPair('lote', AEventos[i].Lote);
      oEv.AddPair('fecha_caducidad', AEventos[i].FechaCaducidad);
      oEv.AddPair('instante_recuento', AEventos[i].InstanteRecuento);
      oEv.AddPair('zona', AEventos[i].Zona);
      oArr.AddElement(oEv);
    end;
    oReq.AddPair('eventos', oArr);
    iStatus := PostJson('inv_eventos.php', oReq.ToString, sResp);
  finally
    FreeAndNil(oReq);
  end;
  if iStatus = 200 then
  begin
    oRespJson := TJSONObject.ParseJSONValue(sResp);
    try
      if oRespJson is TJSONObject then
      begin
        AAceptados  := Trunc(JNum(TJSONObject(oRespJson), 'aceptados'));
        ADuplicados := Trunc(JNum(TJSONObject(oRespJson), 'duplicados'));
        Result := True;
      end;
    finally
      FreeAndNil(oRespJson);
    end;
  end
  else if iStatus <> 0 then
    FUltimoError := MensajeError(sResp, iStatus);
end;

function TRecuentoApi.Finalizar(AIdRecuento: Int64): Boolean;
var
  oReq: TJSONObject;
  sResp: string;
  iStatus: Integer;
begin
  oReq := TJSONObject.Create;
  try
    oReq.AddPair('id_recuento', TJSONNumber.Create(AIdRecuento));
    iStatus := PostJson('inv_finalizar.php', oReq.ToString, sResp);
  finally
    FreeAndNil(oReq);
  end;
  Result := iStatus = 200;
  if (not Result) and (iStatus <> 0) then
    FUltimoError := MensajeError(sResp, iStatus);
end;

function TRecuentoApi.Reabrir(AIdRecuento: Int64): Boolean;
var
  oReq: TJSONObject;
  sResp: string;
  iStatus: Integer;
begin
  oReq := TJSONObject.Create;
  try
    oReq.AddPair('id_recuento', TJSONNumber.Create(AIdRecuento));
    iStatus := PostJson('inv_reabrir.php', oReq.ToString, sResp);
  finally
    FreeAndNil(oReq);
  end;
  Result := iStatus = 200;
  if (not Result) and (iStatus <> 0) then
    FUltimoError := MensajeError(sResp, iStatus);
end;

end.
