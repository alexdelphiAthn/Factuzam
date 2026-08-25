{******************************************************************************}
{                                                                              }
{  Módulo:       inLibInventarioNube                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Sincroniza recuentos con el servidor sin conocer su persistencia UniDAC.  }
{******************************************************************************}
unit inLibInventarioNube;

interface

uses
  System.Classes,
  inLibInventarioNubePersistenciaIntf,
  inLibParametrosIntf;

function InventarioNubeConfigurado(
  const AParametrosApp: IParametrosAplicacion;
  out AMensaje: string): Boolean;

function EnviarInventario(
  const AParametrosApp: IParametrosAplicacion;
  const APersistencia: IInventarioNubePersistencia;
  const AEmp, AAlm, ASerie, ANumero, ADescripcion, AModo: string;
  out AIdRecuento: Int64;
  out AMensaje: string): Boolean;

function RecogerRecuento(
  const AParametrosApp: IParametrosAplicacion;
  const APersistencia: IInventarioNubePersistencia;
  const AEmp, AAlm, ASerie, ANumero, AUsuario: string;
  AIdRecuento: Int64;
  AAgregado: TStringList;
  out ANumEventos: Integer;
  out AMensaje: string): Boolean;

function AplicarRespuestaRecuento(
  const ARespuesta: string;
  const APersistencia: IInventarioNubePersistencia;
  const AClave: TClaveInventarioNube;
  const AUsuario: string;
  AAgregado: TStrings;
  out ANumEventos: Integer): Boolean;

implementation

uses
  System.Generics.Collections,
  System.JSON,
  System.Net.HttpClient,
  System.SysUtils,
  inLibFactuzamApi,
  inLibMsgArticulos;

function InventarioNubeConfigurado(
  const AParametrosApp: IParametrosAplicacion;
  out AMensaje: string): Boolean;
var
  oFaltan: TStringList;
begin
  AMensaje := '';
  oFaltan := TStringList.Create;
  try
    if TClienteFactuzamApi.UrlBase(AParametrosApp) = '' then
      oFaltan.Add(STextoParametroUrlInventarioNube);
    if TClienteFactuzamApi.Token(AParametrosApp) = '' then
      oFaltan.Add(STextoParametroTokenInventarioNube);
    if TClienteFactuzamApi.Referencia(AParametrosApp) = '' then
      oFaltan.Add(STextoParametroReferenciaInventarioNube);
    Result := oFaltan.Count = 0;
    if not Result then
    begin
      AMensaje := Format(
        SErrorParametrosInventarioNubeFaltantes,
        [oFaltan.Text]);
    end;
  finally
    FreeAndNil(oFaltan);
  end;
end;

function LeerStream(AStream: TStream): string;
var
  oTexto: TStringStream;
begin
  oTexto := TStringStream.Create('', TEncoding.UTF8);
  try
    AStream.Position := 0;
    if AStream.Size > 0 then
      oTexto.CopyFrom(AStream, AStream.Size);
    Result := oTexto.DataString;
  finally
    FreeAndNil(oTexto);
  end;
end;

function MensajeError(const ACuerpo: string; AEstado: Integer): string;
var
  oJson: TJSONValue;
  oMensaje: TJSONValue;
begin
  Result := '';
  oJson := TJSONObject.ParseJSONValue(ACuerpo);
  try
    if oJson <> nil then
    begin
      oMensaje := oJson.FindValue('message');
      if oMensaje <> nil then
        Result := oMensaje.Value;
    end;
  finally
    FreeAndNil(oJson);
  end;
  if Result = '' then
    Result := Format(SErrorServidorInventarioNubeHttp, [AEstado]);
end;

function PostNube(
  const AParametrosApp: IParametrosAplicacion;
  const ARuta, ACuerpo: string;
  out ARespuesta: string;
  out AMensaje: string): Integer;
var
  oHttp: THTTPClient;
  oPeticion: TStringStream;
  oRespuesta: TMemoryStream;
  oRespuestaHttp: IHTTPResponse;
begin
  Result := 0;
  ARespuesta := '';
  oHttp := THTTPClient.Create;
  oPeticion := TStringStream.Create(ACuerpo, TEncoding.UTF8);
  oRespuesta := TMemoryStream.Create;
  try
    oHttp.CustomHeaders['X-API-Key'] :=
      TClienteFactuzamApi.Token(AParametrosApp);
    oHttp.CustomHeaders['Content-Type'] := 'application/json';
    try
      oRespuestaHttp := oHttp.Post(
        TClienteFactuzamApi.ComponerUrl(AParametrosApp, ARuta),
        oPeticion,
        oRespuesta);
      Result := oRespuestaHttp.StatusCode;
      ARespuesta := LeerStream(oRespuesta);
    except
      on E: Exception do
      begin
        AMensaje := Format(
          SErrorConexionServidorInventarioNube,
          [E.Message]);
      end;
    end;
  finally
    FreeAndNil(oRespuesta);
    FreeAndNil(oPeticion);
    FreeAndNil(oHttp);
  end;
end;

function GetNube(
  const AParametrosApp: IParametrosAplicacion;
  const ARuta: string;
  out ARespuesta: string;
  out AMensaje: string): Integer;
var
  oHttp: THTTPClient;
  oRespuesta: TMemoryStream;
  oRespuestaHttp: IHTTPResponse;
begin
  Result := 0;
  ARespuesta := '';
  oHttp := THTTPClient.Create;
  oRespuesta := TMemoryStream.Create;
  try
    oHttp.CustomHeaders['X-API-Key'] :=
      TClienteFactuzamApi.Token(AParametrosApp);
    try
      oRespuestaHttp := oHttp.Get(
        TClienteFactuzamApi.ComponerUrl(AParametrosApp, ARuta),
        oRespuesta);
      Result := oRespuestaHttp.StatusCode;
      ARespuesta := LeerStream(oRespuesta);
    except
      on E: Exception do
      begin
        AMensaje := Format(
          SErrorConexionServidorInventarioNube,
          [E.Message]);
      end;
    end;
  finally
    FreeAndNil(oRespuesta);
    FreeAndNil(oHttp);
  end;
end;

function CrearClaveInventario(
  const AEmp, AAlm, ASerie, ANumero: string): TClaveInventarioNube;
begin
  Result := Default(TClaveInventarioNube);
  Result.Empresa := AEmp;
  Result.Almacen := AAlm;
  Result.Serie := ASerie;
  Result.Numero := ANumero;
end;

function CrearJsonLinea(
  const ALinea: TLineaInventarioNube): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('codigo_articulo', ALinea.CodigoArticulo);
  Result.AddPair('codigo_unidad', ALinea.CodigoUnidad);
  Result.AddPair('descripcion', ALinea.Descripcion);
  Result.AddPair('codigo_barras', ALinea.CodigoBarras);
  Result.AddPair(
    'cantidad_teorica',
    TJSONNumber.Create(ALinea.CantidadTeorica));
  Result.AddPair('estrazable', ALinea.EsTrazable);
end;

function ConstruirCuerpoEnvio(
  const APersistencia: IInventarioNubePersistencia;
  const AClave: TClaveInventarioNube;
  const AReferencia, ADescripcion, AModo: string): string;
var
  oRaiz: TJSONObject;
  oLineasJson: TJSONArray;
  aLineas: TLineasInventarioNube;
  iLinea: Integer;
begin
  oRaiz := TJSONObject.Create;
  try
    oRaiz.AddPair('carpeta_cliente', AReferencia);
    oRaiz.AddPair('codigo_emp', AClave.Empresa);
    oRaiz.AddPair('codigo_alm', AClave.Almacen);
    oRaiz.AddPair('serie', AClave.Serie);
    oRaiz.AddPair('numero', AClave.Numero);
    oRaiz.AddPair('descripcion', ADescripcion);
    oRaiz.AddPair('modo', AModo);
    oLineasJson := TJSONArray.Create;
    oRaiz.AddPair('lineas', oLineasJson);
    aLineas := APersistencia.ListarLineas(AClave);
    for iLinea := Low(aLineas) to High(aLineas) do
    begin
      oLineasJson.AddElement(CrearJsonLinea(aLineas[iLinea]));
    end;
    Result := oRaiz.ToString;
  finally
    FreeAndNil(oRaiz);
  end;
end;

function EnviarInventario(
  const AParametrosApp: IParametrosAplicacion;
  const APersistencia: IInventarioNubePersistencia;
  const AEmp, AAlm, ASerie, ANumero, ADescripcion, AModo: string;
  out AIdRecuento: Int64;
  out AMensaje: string): Boolean;
var
  oClave: TClaveInventarioNube;
  oRespuestaJson: TJSONValue;
  sCuerpo: string;
  sRespuesta: string;
  iEstado: Integer;
begin
  Result := False;
  AIdRecuento := 0;
  AMensaje := '';
  if not Assigned(APersistencia) then
    raise EArgumentNilException.Create('APersistencia');
  if InventarioNubeConfigurado(AParametrosApp, AMensaje) then
  begin
    oClave := CrearClaveInventario(AEmp, AAlm, ASerie, ANumero);
    sCuerpo := ConstruirCuerpoEnvio(
      APersistencia,
      oClave,
      TClienteFactuzamApi.Referencia(AParametrosApp),
      ADescripcion,
      AModo);
    iEstado := PostNube(
      AParametrosApp,
      'inv_enviar.php',
      sCuerpo,
      sRespuesta,
      AMensaje);
    if iEstado = 200 then
    begin
      oRespuestaJson := TJSONObject.ParseJSONValue(sRespuesta);
      try
        if oRespuestaJson is TJSONObject then
        begin
          AIdRecuento := Trunc(
            TJSONObject(oRespuestaJson).GetValue<Double>(
              'id_recuento',
              0));
        end;
      finally
        FreeAndNil(oRespuestaJson);
      end;
      Result := AIdRecuento > 0;
      if not Result then
        AMensaje := SErrorInventarioNubeSinIdRecuento;
    end
    else if iEstado <> 0 then
      AMensaje := MensajeError(sRespuesta, iEstado);
  end;
end;

function LeerEvento(
  AJson: TJSONObject): TEventoInventarioNube;
begin
  Result := Default(TEventoInventarioNube);
  Result.Uuid := AJson.GetValue<string>('uuid_evento', '');
  Result.CodigoArticulo :=
    AJson.GetValue<string>('codigo_articulo', '');
  Result.CodigoUnidad := AJson.GetValue<string>('codigo_unidad', '');
  Result.CodigoBarras := AJson.GetValue<string>('codigo_barras', '');
  Result.Cantidad := AJson.GetValue<Double>('cantidad', 0);
  Result.Lote := AJson.GetValue<string>('lote', '');
  Result.FechaCaducidad :=
    AJson.GetValue<string>('fecha_caducidad', '');
  Result.InstanteRecuento :=
    AJson.GetValue<string>('instante_recuento', '');
  Result.Operario := AJson.GetValue<string>('operario', '');
  Result.Dispositivo := AJson.GetValue<string>('dispositivo', '');
  Result.Zona := AJson.GetValue<string>('zona', '');
end;

procedure AplicarEventos(
  ARaiz: TJSONObject;
  const APersistencia: IInventarioNubePersistencia;
  const AClave: TClaveInventarioNube;
  const AUsuario: string;
  out ANumEventos: Integer);
var
  oEventos: TJSONArray;
  oEvento: TEventoInventarioNube;
  iEvento: Integer;
begin
  ANumEventos := 0;
  if ARaiz.GetValue('eventos') is TJSONArray then
  begin
    oEventos := ARaiz.GetValue('eventos') as TJSONArray;
    for iEvento := 0 to oEventos.Count - 1 do
    begin
      if oEventos.Items[iEvento] is TJSONObject then
      begin
        oEvento := LeerEvento(TJSONObject(oEventos.Items[iEvento]));
        if APersistencia.GuardarEventoSiNuevo(
             AClave,
             oEvento,
             AUsuario) then
        begin
          Inc(ANumEventos);
        end;
      end;
    end;
  end;
end;

procedure AplicarAgregado(
  ARaiz: TJSONObject;
  AAgregado: TStrings);
var
  oAgregadoJson: TJSONArray;
  oLinea: TJSONObject;
  sCodigoUnidad: string;
  dCantidad: Double;
  iLinea: Integer;
begin
  if Assigned(AAgregado) and
     (ARaiz.GetValue('agregado') is TJSONArray) then
  begin
    oAgregadoJson := ARaiz.GetValue('agregado') as TJSONArray;
    for iLinea := 0 to oAgregadoJson.Count - 1 do
    begin
      if oAgregadoJson.Items[iLinea] is TJSONObject then
      begin
        oLinea := TJSONObject(oAgregadoJson.Items[iLinea]);
        sCodigoUnidad :=
          oLinea.GetValue<string>('codigo_unidad', '');
        dCantidad := oLinea.GetValue<Double>('cantidad', 0);
        AAgregado.Add(sCodigoUnidad + '=' + FloatToStr(dCantidad));
      end;
    end;
  end;
end;

function AplicarRespuestaRecuento(
  const ARespuesta: string;
  const APersistencia: IInventarioNubePersistencia;
  const AClave: TClaveInventarioNube;
  const AUsuario: string;
  AAgregado: TStrings;
  out ANumEventos: Integer): Boolean;
var
  oRespuestaJson: TJSONValue;
  oRaiz: TJSONObject;
begin
  if not Assigned(APersistencia) then
    raise EArgumentNilException.Create('APersistencia');
  ANumEventos := 0;
  if Assigned(AAgregado) then
    AAgregado.Clear;
  Result := False;
  oRespuestaJson := TJSONObject.ParseJSONValue(ARespuesta);
  try
    if oRespuestaJson is TJSONObject then
    begin
      oRaiz := TJSONObject(oRespuestaJson);
      AplicarEventos(
        oRaiz,
        APersistencia,
        AClave,
        AUsuario,
        ANumEventos);
      AplicarAgregado(oRaiz, AAgregado);
      Result := True;
    end;
  finally
    FreeAndNil(oRespuestaJson);
  end;
end;

function RecogerRecuento(
  const AParametrosApp: IParametrosAplicacion;
  const APersistencia: IInventarioNubePersistencia;
  const AEmp, AAlm, ASerie, ANumero, AUsuario: string;
  AIdRecuento: Int64;
  AAgregado: TStringList;
  out ANumEventos: Integer;
  out AMensaje: string): Boolean;
var
  oClave: TClaveInventarioNube;
  sRespuesta: string;
  iEstado: Integer;
begin
  Result := False;
  ANumEventos := 0;
  AMensaje := '';
  if Assigned(AAgregado) then
    AAgregado.Clear;
  if not Assigned(APersistencia) then
    raise EArgumentNilException.Create('APersistencia');
  if InventarioNubeConfigurado(AParametrosApp, AMensaje) then
  begin
    iEstado := GetNube(
      AParametrosApp,
      'inv_recoger.php?id_recuento=' +
        IntToStr(AIdRecuento) + '&marcar=1',
      sRespuesta,
      AMensaje);
    if iEstado = 200 then
    begin
      oClave := CrearClaveInventario(AEmp, AAlm, ASerie, ANumero);
      Result := AplicarRespuestaRecuento(
        sRespuesta,
        APersistencia,
        oClave,
        AUsuario,
        AAgregado,
        ANumEventos);
    end
    else if iEstado <> 0 then
      AMensaje := MensajeError(sRespuesta, iEstado);
  end;
end;

end.
