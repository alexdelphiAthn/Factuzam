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

function TryFechaHoraRecuentoMovil(
  const ATexto: string;
  out AFechaHora: TDateTime): Boolean;

function TryFechaHoraRecuentoNegocio(
  const ATexto: string;
  out AFechaHora: TDateTime): Boolean;

function ObtenerSkuRecuento(
  ALista: TStrings;
  AIndice: Integer): string;

procedure ValidarInstantesRecuentoMovil(
  ALista: TStrings;
  AInstantesRecuento: TStrings);

function EsInstanteRecuentoPosterior(
  const AInstanteLocalNuevo, AInstanteUtcNuevo: string;
  const AInstanteLocalActual, AInstanteUtcActual: string): Boolean;

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
  out AMensaje: string;
  AInstantes: TStringList = nil): Boolean;

function AplicarRespuestaRecuento(
  const ARespuesta: string;
  const APersistencia: IInventarioNubePersistencia;
  const AClave: TClaveInventarioNube;
  const AUsuario: string;
  AAgregado: TStrings;
  out ANumEventos: Integer;
  AInstantes: TStrings = nil): Boolean;

implementation

uses
  System.DateUtils,
  System.Generics.Collections,
  System.JSON,
  System.Math,
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

function TryFechaHoraFija(
  const ATexto: string;
  out AFechaHora: TDateTime): Boolean;
var
  Ano: Integer;
  Dia: Integer;
  Hora: Integer;
  Mes: Integer;
  Minuto: Integer;
  Segundo: Integer;
begin
  AFechaHora := 0;
  Ano := 0;
  Mes := 0;
  Dia := 0;
  Hora := 0;
  Minuto := 0;
  Segundo := 0;
  Result := (Length(ATexto) = 19) and
    (ATexto[5] = '-') and (ATexto[8] = '-') and
    (ATexto[11] = ' ') and (ATexto[14] = ':') and
    (ATexto[17] = ':') and
    TryStrToInt(Copy(ATexto, 1, 4), Ano) and
    TryStrToInt(Copy(ATexto, 6, 2), Mes) and
    TryStrToInt(Copy(ATexto, 9, 2), Dia) and
    TryStrToInt(Copy(ATexto, 12, 2), Hora) and
    TryStrToInt(Copy(ATexto, 15, 2), Minuto) and
    TryStrToInt(Copy(ATexto, 18, 2), Segundo);
  if Result then
    Result := TryEncodeDateTime(
      Ano, Mes, Dia, Hora, Minuto, Segundo, 0, AFechaHora);
  if not Result then
    AFechaHora := 0;
end;

function TryFechaHoraUtc(
  const ATexto: string;
  out AFechaHoraUtc: TDateTime): Boolean;
var
  Texto: string;
begin
  Texto := Trim(ATexto);
  Result := (Length(Texto) = 20) and
    (Texto[11] = 'T') and (Texto[20] = 'Z');
  if Result then
  begin
    Texto := Copy(Texto, 1, 10) + ' ' + Copy(Texto, 12, 8);
    Result := TryFechaHoraFija(Texto, AFechaHoraUtc);
  end;
  if Result then
    Result := (AFechaHoraUtc >= EncodeDate(2000, 1, 1)) and
      (AFechaHoraUtc <= TDateTime.NowUTC + EncodeTime(0, 5, 0, 0));
  if not Result then
    AFechaHoraUtc := 0;
end;

function TryFechaHoraRecuentoMovil(
  const ATexto: string;
  out AFechaHora: TDateTime): Boolean;
var
  EsUtc: Boolean;
  FechaUtc: TDateTime;
  Texto: string;
begin
  Texto := Trim(ATexto);
  EsUtc := (Length(Texto) = 20) and
    (Texto[11] = 'T') and (Texto[20] = 'Z');
  if EsUtc then
  begin
    Result := TryFechaHoraUtc(Texto, FechaUtc);
    if Result then
      AFechaHora := TTimeZone.Local.ToLocalTime(FechaUtc);
  end
  else
  begin
    Texto := StringReplace(Texto, 'T', ' ', []);
    Result := TryFechaHoraFija(Texto, AFechaHora);
    if Result then
      Result := (AFechaHora >= EncodeDate(2000, 1, 1)) and
        (AFechaHora <= Now + EncodeTime(0, 5, 0, 0));
  end;
  if not Result then
    AFechaHora := 0;
end;

function TryFechaHoraRecuentoNegocio(
  const ATexto: string;
  out AFechaHora: TDateTime): Boolean;
var
  Texto: string;
begin
  Texto := StringReplace(Trim(ATexto), 'T', ' ', []);
  Result := TryFechaHoraFija(Texto, AFechaHora);
  if Result then
    Result := AFechaHora >= EncodeDate(2000, 1, 1);
  if not Result then
    AFechaHora := 0;
end;

function ObtenerSkuRecuento(
  ALista: TStrings;
  AIndice: Integer): string;
begin
  Result := Trim(ALista.Names[AIndice]);
  if Result = '' then
    Result := Trim(ALista[AIndice]);
end;

procedure ValidarInstantesRecuentoMovil(
  ALista: TStrings;
  AInstantesRecuento: TStrings);
var
  FechaRecuento: TDateTime;
  i: Integer;
  Sku: string;
begin
  for i := 0 to ALista.Count - 1 do
  begin
    Sku := ObtenerSkuRecuento(ALista, i);
    if not TryFechaHoraRecuentoNegocio(
         AInstantesRecuento.Values[Sku],
         FechaRecuento) then
      FechaRecuento := 0;
    if (Sku <> '') and (FechaRecuento <= 0) then
      raise EConvertError.CreateFmt(
        SErrorRecuentoInventarioSinInstanteSku,
        [Sku]);
  end;
end;

function LeerDesfaseRecuento(
  AJson: TJSONObject;
  out ADesfaseMinutos: Integer): Boolean;
var
  Numero: Double;
  Valor: TJSONValue;
begin
  ADesfaseMinutos := 0;
  Valor := AJson.GetValue('desfase_recuento_minutos');
  Result := Valor is TJSONNumber;
  if Result then
  begin
    Numero := TJSONNumber(Valor).AsDouble;
    ADesfaseMinutos := Trunc(Numero);
    Result := SameValue(Numero, ADesfaseMinutos) and
      (ADesfaseMinutos >= -840) and (ADesfaseMinutos <= 840);
  end;
end;

function FechaHoraEvento(const ATexto: string): TDateTime;
begin
  if not TryFechaHoraRecuentoNegocio(ATexto, Result) then
    Result := 0;
end;

function NormalizarInstanteEvento(
  AJson: TJSONObject;
  var AEvento: TEventoInventarioNube): Boolean;
var
  DesfaseMinutos: Integer;
  FechaLocal: TDateTime;
  FechaUtc: TDateTime;
  Texto: string;
begin
  Texto := Trim(AEvento.InstanteRecuento);
  Result := (Length(Texto) = 20) and
    (Texto[11] = 'T') and (Texto[20] = 'Z');
  if Result then
  begin
    Result := LeerDesfaseRecuento(AJson, DesfaseMinutos) and
      TryFechaHoraUtc(Texto, FechaUtc);
    if Result then
    begin
      FechaLocal := IncMinute(FechaUtc, DesfaseMinutos);
      AEvento.InstanteRecuento := FormatDateTime(
        'yyyy-mm-dd hh":"nn":"ss', FechaLocal);
      AEvento.InstanteRecuentoUtc := FormatDateTime(
        'yyyy-mm-dd hh":"nn":"ss', FechaUtc);
    end;
  end
  else
  begin
    Result := TryFechaHoraRecuentoNegocio(Texto, FechaLocal);
    if Result then
    begin
      AEvento.InstanteRecuento := FormatDateTime(
        'yyyy-mm-dd hh":"nn":"ss', FechaLocal);
      AEvento.InstanteRecuentoUtc := '';
    end;
  end;
end;

type
  TOrdenInstanteEvento = record
    FechaLocal: TDateTime;
    FechaUtc: TDateTime;
    TieneUtc: Boolean;
  end;

function OrdenInstanteEvento(
  const AEvento: TEventoInventarioNube): TOrdenInstanteEvento;
begin
  Result := Default(TOrdenInstanteEvento);
  TryFechaHoraFija(AEvento.InstanteRecuento, Result.FechaLocal);
  Result.TieneUtc := TryFechaHoraFija(
    AEvento.InstanteRecuentoUtc,
    Result.FechaUtc);
end;

function EsInstantePosterior(
  const ANuevo, AActual: TOrdenInstanteEvento): Boolean;
begin
  if ANuevo.TieneUtc and AActual.TieneUtc then
    Result := ANuevo.FechaUtc > AActual.FechaUtc
  else
    Result := ANuevo.FechaLocal > AActual.FechaLocal;
end;

function EsInstanteRecuentoPosterior(
  const AInstanteLocalNuevo, AInstanteUtcNuevo: string;
  const AInstanteLocalActual, AInstanteUtcActual: string): Boolean;
var
  Actual: TOrdenInstanteEvento;
  Nuevo: TOrdenInstanteEvento;
begin
  Actual := Default(TOrdenInstanteEvento);
  Nuevo := Default(TOrdenInstanteEvento);
  TryFechaHoraFija(AInstanteLocalNuevo, Nuevo.FechaLocal);
  TryFechaHoraFija(AInstanteLocalActual, Actual.FechaLocal);
  Nuevo.TieneUtc := TryFechaHoraFija(
    AInstanteUtcNuevo,
    Nuevo.FechaUtc);
  Actual.TieneUtc := TryFechaHoraFija(
    AInstanteUtcActual,
    Actual.FechaUtc);
  Result := EsInstantePosterior(Nuevo, Actual);
end;

procedure RegistrarUltimoInstante(
  const AEvento: TEventoInventarioNube;
  AInstantes: TStrings;
  AOrdenes: TDictionary<string, TOrdenInstanteEvento>);
var
  Actual: TOrdenInstanteEvento;
  Nuevo: TOrdenInstanteEvento;
  Sku: string;
begin
  Sku := Trim(AEvento.CodigoUnidad);
  if Assigned(AInstantes) and (Sku <> '') then
  begin
    Nuevo := OrdenInstanteEvento(AEvento);
    if (not AOrdenes.TryGetValue(Sku, Actual)) or
       EsInstantePosterior(Nuevo, Actual) then
    begin
      AInstantes.Values[Sku] := AEvento.InstanteRecuento;
      AOrdenes.AddOrSetValue(Sku, Nuevo);
    end;
  end;
end;

type
  TEventosInventarioNube = TArray<TEventoInventarioNube>;

function LeerEventosRespuesta(
  ARaiz: TJSONObject;
  out AEventos: TEventosInventarioNube): Boolean;
var
  EventosJson: TJSONArray;
  Evento: TEventoInventarioNube;
  iEvento: Integer;
  iResultado: Integer;
begin
  SetLength(AEventos, 0);
  Result := ARaiz.GetValue('eventos') is TJSONArray;
  if Result then
  begin
    EventosJson := ARaiz.GetValue('eventos') as TJSONArray;
    iEvento := 0;
    while Result and (iEvento < EventosJson.Count) do
    begin
      Result := EventosJson.Items[iEvento] is TJSONObject;
      if Result then
      begin
        Evento := LeerEvento(TJSONObject(EventosJson.Items[iEvento]));
        Result := (Trim(Evento.Uuid) <> '') and
          (Trim(Evento.CodigoUnidad) <> '') and
          NormalizarInstanteEvento(
            TJSONObject(EventosJson.Items[iEvento]),
            Evento);
      end;
      if Result then
      begin
        iResultado := Length(AEventos);
        SetLength(AEventos, iResultado + 1);
        AEventos[iResultado] := Evento;
      end;
      Inc(iEvento);
    end;
  end;
  if not Result then
    SetLength(AEventos, 0);
end;

procedure AplicarEventos(
  const AEventos: TEventosInventarioNube;
  const APersistencia: IInventarioNubePersistencia;
  const AClave: TClaveInventarioNube;
  const AUsuario: string;
  out ANumEventos: Integer);
var
  iEvento: Integer;
begin
  ANumEventos := 0;
  for iEvento := 0 to High(AEventos) do
  begin
    if APersistencia.GuardarEventoSiNuevo(
         AClave,
         AEventos[iEvento],
         AUsuario) then
    begin
      Inc(ANumEventos);
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

procedure RegistrarCantidadEvento(
  const AEvento: TEventoInventarioNube;
  ACantidades: TStrings);
var
  Cantidad: Double;
  Sku: string;
begin
  Sku := Trim(AEvento.CodigoUnidad);
  if Sku <> '' then
  begin
    Cantidad := StrToFloatDef(ACantidades.Values[Sku], 0);
    Cantidad := Cantidad + AEvento.Cantidad;
    ACantidades.Values[Sku] := FloatToStr(Cantidad);
  end;
end;

function RespuestaRecuentoCoherente(
  const AEventos: TEventosInventarioNube;
  AAgregado, AInstantes: TStrings): Boolean;
var
  CantidadesEventos: TStringList;
  CantidadAgregada: Double;
  CantidadEventos: Double;
  iEvento: Integer;
  iLinea: Integer;
  Sku: string;
begin
  CantidadesEventos := TStringList.Create;
  try
    for iEvento := 0 to High(AEventos) do
      RegistrarCantidadEvento(AEventos[iEvento], CantidadesEventos);
    Result := True;
    iLinea := 0;
    while Result and (iLinea < AAgregado.Count) do
    begin
      Sku := Trim(AAgregado.Names[iLinea]);
      CantidadAgregada := StrToFloatDef(
        AAgregado.ValueFromIndex[iLinea],
        0);
      CantidadEventos := StrToFloatDef(
        CantidadesEventos.Values[Sku],
        0);
      Result := (Sku <> '') and
        (CantidadesEventos.IndexOfName(Sku) >= 0) and
        SameValue(CantidadAgregada, CantidadEventos, 0.000001) and
        (FechaHoraEvento(AInstantes.Values[Sku]) > 0);
      Inc(iLinea);
    end;
    iLinea := 0;
    while Result and (iLinea < CantidadesEventos.Count) do
    begin
      Sku := CantidadesEventos.Names[iLinea];
      Result := AAgregado.IndexOfName(Sku) >= 0;
      Inc(iLinea);
    end;
  finally
    FreeAndNil(CantidadesEventos);
  end;
end;

function AplicarRespuestaRecuento(
  const ARespuesta: string;
  const APersistencia: IInventarioNubePersistencia;
  const AClave: TClaveInventarioNube;
  const AUsuario: string;
  AAgregado: TStrings;
  out ANumEventos: Integer;
  AInstantes: TStrings): Boolean;
var
  AgregadoTemporal: TStringList;
  Eventos: TEventosInventarioNube;
  InstantesTemporales: TStringList;
  OrdenesTemporales: TDictionary<string, TOrdenInstanteEvento>;
  iEvento: Integer;
  oRespuestaJson: TJSONValue;
  oRaiz: TJSONObject;
begin
  if not Assigned(APersistencia) then
    raise EArgumentNilException.Create('APersistencia');
  ANumEventos := 0;
  if Assigned(AAgregado) then
    AAgregado.Clear;
  if Assigned(AInstantes) then
    AInstantes.Clear;
  Result := False;
  AgregadoTemporal := TStringList.Create;
  InstantesTemporales := TStringList.Create;
  OrdenesTemporales :=
    TDictionary<string, TOrdenInstanteEvento>.Create;
  oRespuestaJson := TJSONObject.ParseJSONValue(ARespuesta);
  try
    if oRespuestaJson is TJSONObject then
    begin
      oRaiz := TJSONObject(oRespuestaJson);
      Result := LeerEventosRespuesta(oRaiz, Eventos);
      if Result then
      begin
        AplicarAgregado(oRaiz, AgregadoTemporal);
        for iEvento := 0 to High(Eventos) do
          RegistrarUltimoInstante(
            Eventos[iEvento],
            InstantesTemporales,
            OrdenesTemporales);
        Result := RespuestaRecuentoCoherente(
          Eventos,
          AgregadoTemporal,
          InstantesTemporales);
      end;
      if Result then
      begin
        AplicarEventos(
          Eventos,
          APersistencia,
          AClave,
          AUsuario,
          ANumEventos);
        if Assigned(AAgregado) then
          AAgregado.Assign(AgregadoTemporal);
        if Assigned(AInstantes) then
          AInstantes.Assign(InstantesTemporales);
      end;
    end;
  finally
    FreeAndNil(oRespuestaJson);
    FreeAndNil(OrdenesTemporales);
    FreeAndNil(InstantesTemporales);
    FreeAndNil(AgregadoTemporal);
  end;
end;

function RecogerRecuento(
  const AParametrosApp: IParametrosAplicacion;
  const APersistencia: IInventarioNubePersistencia;
  const AEmp, AAlm, ASerie, ANumero, AUsuario: string;
  AIdRecuento: Int64;
  AAgregado: TStringList;
  out ANumEventos: Integer;
  out AMensaje: string;
  AInstantes: TStringList): Boolean;
var
  iLinea: Integer;
  oClave: TClaveInventarioNube;
  sSku: string;
  sRespuesta: string;
  iEstado: Integer;
begin
  Result := False;
  ANumEventos := 0;
  AMensaje := '';
  if Assigned(AAgregado) then
    AAgregado.Clear;
  if Assigned(AInstantes) then
    AInstantes.Clear;
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
        ANumEventos,
        AInstantes);
      if (not Result) and (AMensaje = '') then
        AMensaje := SErrorRespuestaRecuentoInventarioIncoherente;
      iLinea := 0;
      while Result and Assigned(AInstantes) and
            Assigned(AAgregado) and (iLinea < AAgregado.Count) do
      begin
        sSku := Trim(AAgregado.Names[iLinea]);
        if (sSku <> '') and
           (FechaHoraEvento(AInstantes.Values[sSku]) <= 0) then
        begin
          Result := False;
          AMensaje := Format(
            SErrorRecuentoInventarioSinInstanteSku,
            [sSku]);
        end;
        Inc(iLinea);
      end;
    end
    else if iEstado <> 0 then
      AMensaje := MensajeError(sRespuesta, iEstado);
  end;
end;

end.
