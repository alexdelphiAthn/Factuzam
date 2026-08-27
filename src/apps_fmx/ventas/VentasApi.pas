{******************************************************************************}
{                                                                              }
{  Módulo:       VentasApi                                                     }
{    Tipo:       Librería (App FMX)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cliente REST contra ventas/lineas.php y fotos/imagen.php. Mismo stack     }
{    que RecuentoApi (System.Net.HttpClient + System.JSON), pero con           }
{    credencial Bearer, que es lo que exige la API de ventas.                  }
{******************************************************************************}
unit VentasApi;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  System.Net.HttpClient, System.Net.URLClient,
  VentasModelo, VentasTicket;

type
  TVentasApi = class
  private
    FUltimoError: string;
    function ComponerUrl(const ARuta: string): string;
    function CrearCliente: THTTPClient;
    function LeerError(const ACuerpo: string; AEstado: Integer): string;
  public
    function ConsultarLineas(const AFiltro: TFiltroLineas;
      out ARespuesta: TRespuestaLineas): Boolean;
    function DescargarFoto(const ARutaRelativa: string;
      const ARutaDestino: string): Boolean;
    function DescargarTicket(const APeticion: TPeticionTicketVenta;
      const ACancelacion: ICancelacionTicketVenta):
      TResultadoTicketVenta;
    property UltimoError: string read FUltimoError;
  end;

implementation

uses
  System.NetEncoding, System.IOUtils, System.DateUtils,
  System.Generics.Collections, VentasConfig;

// ============================================================================
//   Ayudas JSON
// ============================================================================

function JObj(AValor: TJSONValue): TJSONObject;
begin
  if AValor is TJSONObject then
    Result := TJSONObject(AValor)
  else
    Result := nil;
end;

function JStr(AObj: TJSONObject; const AClave: string): string;
var
  oValor: TJSONValue;
begin
  Result := '';
  if Assigned(AObj) then
  begin
    oValor := AObj.GetValue(AClave);
    if Assigned(oValor) and not (oValor is TJSONNull) then
      Result := oValor.Value;
  end;
end;

function JNum(AObj: TJSONObject; const AClave: string): Double;
var
  sValor: string;
begin
  Result := 0;
  sValor := JStr(AObj, AClave);
  if sValor <> '' then
    Result := StrToFloatDef(sValor, 0, TFormatSettings.Invariant);
end;

function JEnt(AObj: TJSONObject; const AClave: string): Integer;
begin
  Result := Trunc(JNum(AObj, AClave));
end;

function JBool(AObj: TJSONObject; const AClave: string): Boolean;
var
  oValor: TJSONValue;
begin
  Result := False;
  if Assigned(AObj) then
  begin
    oValor := AObj.GetValue(AClave);
    if oValor is TJSONBool then
      Result := TJSONBool(oValor).AsBoolean;
  end;
end;

{ El servidor guarda y devuelve los instantes en UTC. La hora que se pinta
  es la local del teléfono, que es la del negocio salvo que se consulte
  desde otro huso. }
function HoraLocal(const AInstanteUtc: string): string;
var
  dtUtc: TDateTime;
  oFormato: TFormatSettings;
begin
  Result := '';
  if Length(AInstanteUtc) >= 19 then
  begin
    oFormato := TFormatSettings.Invariant;
    oFormato.DateSeparator := '-';
    oFormato.TimeSeparator := ':';
    oFormato.ShortDateFormat := 'yyyy-mm-dd';
    oFormato.LongTimeFormat := 'hh:nn:ss';
    if TryStrToDateTime(Copy(AInstanteUtc, 1, 19), dtUtc, oFormato) then
      Result := FormatDateTime('hh:nn',
        TTimeZone.Local.ToLocalTime(dtUtc));
  end;
end;

function ParametroUrl(const ANombre, AValor: string): string;
begin
  Result := '';
  if Trim(AValor) <> '' then
    Result := '&' + ANombre + '=' +
              TNetEncoding.URL.Encode(Trim(AValor));
end;

function LeerTotales(AObj: TJSONObject): TTotalesVenta;
begin
  Result := Default(TTotalesVenta);
  if Assigned(AObj) then
  begin
    Result.Fecha := JStr(AObj, 'fecha');
    Result.Lineas := JEnt(AObj, 'lineas');
    Result.Unidades := JNum(AObj, 'unidades');
    Result.TotalVenta := JNum(AObj, 'total_venta');
    Result.TotalVentaSiva := JNum(AObj, 'total_venta_siva');
    Result.TotalCoste := JNum(AObj, 'total_coste');
    Result.TotalMargen := JNum(AObj, 'total_margen');
    Result.PorcentajeMargen := JNum(AObj, 'porcentaje_margen');
    Result.TotalDescuento := JNum(AObj, 'total_descuento');
  end;
end;

function LeerLinea(AObj: TJSONObject): TLineaVenta;
begin
  Result := Default(TLineaVenta);
  Result.Fecha := JStr(AObj, 'fecha');
  Result.Hora := HoraLocal(JStr(AObj, 'instante_venta'));
  if Result.Hora = '' then
    Result.Hora := JStr(AObj, 'hora');
  Result.Empresa := JStr(AObj, 'empresa');
  Result.Serie := JStr(AObj, 'serie');
  Result.Numero := JStr(AObj, 'numero');
  Result.Linea := JStr(AObj, 'linea');
  Result.Articulo := JStr(AObj, 'articulo');
  Result.Sku := JStr(AObj, 'sku');
  Result.Color := JStr(AObj, 'color');
  Result.Descripcion := JStr(AObj, 'descripcion');
  Result.Variacion := JStr(AObj, 'variacion');
  Result.CodigoFamilia := JStr(AObj, 'codigo_familia');
  Result.Familia := JStr(AObj, 'familia');
  Result.Temporada := JStr(AObj, 'temporada');
  Result.CodigoProveedor := JStr(AObj, 'codigo_proveedor');
  Result.Proveedor := JStr(AObj, 'proveedor');
  Result.Cantidad := JNum(AObj, 'cantidad');
  Result.PrecioCoste := JNum(AObj, 'precio_coste');
  Result.Pvp := JNum(AObj, 'pvp');
  Result.PorcentajeDescuento := JNum(AObj, 'porcentaje_descuento');
  Result.PrecioConDescuento := JNum(AObj, 'precio_con_descuento');
  Result.ImporteDescuento := JNum(AObj, 'importe_descuento');
  Result.PrecioVenta := JNum(AObj, 'precio_venta');
  Result.TotalLinea := JNum(AObj, 'total_linea');
  Result.TotalLineaSiva := JNum(AObj, 'total_linea_siva');
  Result.TotalCoste := JNum(AObj, 'total_coste');
  Result.Anulada := JBool(AObj, 'anulada');
  Result.FotoRuta := JStr(AObj, 'foto_ruta');
end;

// ============================================================================
//   TVentasApi
// ============================================================================

function TVentasApi.ComponerUrl(const ARuta: string): string;
var
  sBase: string;
  sRuta: string;
begin
  sBase := Trim(oConfig.UrlBase);
  if (sBase <> '') and (sBase[Length(sBase)] <> '/') then
    sBase := sBase + '/';
  sRuta := Trim(ARuta);
  while (sRuta <> '') and (sRuta[1] = '/') do
    Delete(sRuta, 1, 1);
  Result := sBase + sRuta;
end;

function TVentasApi.CrearCliente: THTTPClient;
begin
  Result := THTTPClient.Create;
  Result.ConnectionTimeout := 10000;
  Result.ResponseTimeout := 40000;
  Result.CustomHeaders['Authorization'] := 'Bearer ' + Trim(oConfig.Token);
end;

function TVentasApi.LeerError(const ACuerpo: string;
  AEstado: Integer): string;
var
  oError: TJSONObject;
  oRaiz: TJSONValue;
begin
  Result := 'Respuesta HTTP ' + IntToStr(AEstado);
  oRaiz := TJSONObject.ParseJSONValue(ACuerpo);
  try
    if Assigned(JObj(oRaiz)) then
    begin
      oError := JObj(JObj(oRaiz).GetValue('error'));
      if Assigned(oError) and (JStr(oError, 'mensaje') <> '') then
        Result := JStr(oError, 'mensaje');
    end;
  finally
    FreeAndNil(oRaiz);
  end;
end;

function TVentasApi.ConsultarLineas(const AFiltro: TFiltroLineas;
  out ARespuesta: TRespuestaLineas): Boolean;
var
  iElemento: Integer;
  oArray: TJSONArray;
  oDatos: TJSONObject;
  oHttp: THTTPClient;
  oRaiz: TJSONValue;
  oRespuesta: IHTTPResponse;
  sConsulta: string;
  sCuerpo: string;
begin
  Result := False;
  FUltimoError := '';
  ARespuesta := Default(TRespuestaLineas);
  if not oConfig.EstaConfigurado then
    FUltimoError := 'Falta configurar el servidor, el token o la referencia.'
  else
  begin
    sConsulta := 'fecha=' + TNetEncoding.URL.Encode(AFiltro.Fecha) +
      ParametroUrl('empresa', AFiltro.Empresa) +
      ParametroUrl('familia', AFiltro.Familia) +
      ParametroUrl('proveedor', AFiltro.Proveedor) +
      ParametroUrl('temporada', AFiltro.Temporada) +
      ParametroUrl('texto', AFiltro.Texto) +
      ParametroUrl('limite', IntToStr(AFiltro.Limite));
    oHttp := CrearCliente;
    try
      try
        oRespuesta := oHttp.Get(
          ComponerUrl('ventas/lineas.php') + '?' + sConsulta, nil,
          [TNetHeader.Create('Accept', 'application/json')]);
        sCuerpo := oRespuesta.ContentAsString(TEncoding.UTF8);
        if (oRespuesta.StatusCode < 200) or
           (oRespuesta.StatusCode >= 300) then
          FUltimoError := LeerError(sCuerpo, oRespuesta.StatusCode)
        else
        begin
          oRaiz := TJSONObject.ParseJSONValue(sCuerpo);
          try
            oDatos := nil;
            if Assigned(JObj(oRaiz)) then
              oDatos := JObj(JObj(oRaiz).GetValue('datos'));
            if not Assigned(oDatos) then
              FUltimoError := 'La respuesta del servidor no es válida.'
            else
            begin
              ARespuesta.Desde := JStr(oDatos, 'desde');
              ARespuesta.Hasta := JStr(oDatos, 'hasta');
              ARespuesta.TotalLineas := JEnt(oDatos, 'total_lineas');
              ARespuesta.Devueltas := JEnt(oDatos, 'devueltas');
              ARespuesta.Totales :=
                LeerTotales(JObj(oDatos.GetValue('totales')));
              if oDatos.GetValue('lineas') is TJSONArray then
              begin
                oArray := oDatos.GetValue('lineas') as TJSONArray;
                SetLength(ARespuesta.Lineas, oArray.Count);
                for iElemento := 0 to oArray.Count - 1 do
                  ARespuesta.Lineas[iElemento] :=
                    LeerLinea(JObj(oArray.Items[iElemento]));
              end;
              if oDatos.GetValue('totales_dia') is TJSONArray then
              begin
                oArray := oDatos.GetValue('totales_dia') as TJSONArray;
                SetLength(ARespuesta.TotalesDia, oArray.Count);
                for iElemento := 0 to oArray.Count - 1 do
                  ARespuesta.TotalesDia[iElemento] :=
                    LeerTotales(JObj(oArray.Items[iElemento]));
              end;
              Result := True;
            end;
          finally
            FreeAndNil(oRaiz);
          end;
        end;
      except
        on E: Exception do
          FUltimoError := 'No se pudo conectar: ' + E.Message;
      end;
    finally
      FreeAndNil(oHttp);
    end;
  end;
end;

{ La foto se guarda en disco y no en memoria: así sobrevive al cierre de la
  app y el listado del día siguiente no la vuelve a pedir. }
function TVentasApi.DescargarFoto(const ARutaRelativa: string;
  const ARutaDestino: string): Boolean;
var
  oDestino: TFileStream;
  oHttp: THTTPClient;
  oMemoria: TMemoryStream;
  oRespuesta: IHTTPResponse;
  sTemporal: string;
begin
  Result := False;
  FUltimoError := '';
  if Trim(ARutaRelativa) = '' then
    FUltimoError := 'La línea no tiene foto asociada.'
  else
  begin
    oHttp := CrearCliente;
    try
      try
        oMemoria := TMemoryStream.Create;
        try
          oRespuesta := oHttp.Get(ComponerUrl(ARutaRelativa), oMemoria,
            [TNetHeader.Create('Accept', 'image/png')]);
          if (oRespuesta.StatusCode >= 200) and
             (oRespuesta.StatusCode < 300) and (oMemoria.Size > 0) then
          begin
            // Se escribe aparte y se renombra al final: si no, el hilo de
            // la UI puede toparse con un PNG a medio escribir.
            oMemoria.Position := 0;
            sTemporal := ARutaDestino + '.tmp';
            oDestino := TFileStream.Create(sTemporal, fmCreate);
            try
              oDestino.CopyFrom(oMemoria, 0);
            finally
              FreeAndNil(oDestino);
            end;
            if TFile.Exists(ARutaDestino) then
              TFile.Delete(ARutaDestino);
            TFile.Move(sTemporal, ARutaDestino);
            Result := True;
          end
          else
            FUltimoError := 'Sin foto (HTTP ' +
              IntToStr(oRespuesta.StatusCode) + ')';
        finally
          FreeAndNil(oMemoria);
        end;
      except
        on E: Exception do
          FUltimoError := 'No se pudo descargar la foto: ' + E.Message;
      end;
    finally
      FreeAndNil(oHttp);
    end;
  end;
end;

function TVentasApi.DescargarTicket(const APeticion: TPeticionTicketVenta;
  const ACancelacion: ICancelacionTicketVenta): TResultadoTicketVenta;
begin
  Result := TClienteTicketVenta.Descargar(APeticion, ACancelacion);
end;

end.
