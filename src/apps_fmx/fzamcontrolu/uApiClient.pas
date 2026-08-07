unit uApiClient;

{
  Cliente HTTP para consultar el endpoint de stock de FzamControlU.

  Caracteristicas:
  - Auto re-autenticacion: si el servidor responde 401, refresca el token
    automaticamente y reintenta una vez.
  - Login, stock y foto usan una unica URL base y el mismo origen.
  - Admite la foto de 300 px como URL o Base64 opcional en el JSON.
  - HTTPS acepta cualquier host con certificado valido. HTTP queda limitado a
    hosts privados o locales por uUrlSegura.
}

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.NetEncoding,
  System.Net.HttpClient, System.Net.URLClient, System.NetConsts,
  uAuthService, uSettings, uUrlSegura;

type
  EApiError = class(Exception);

  TStockItem = record
    Color: string;
    Talla: string;
    Almacen: string;
    Unidades: Double;
  end;

  TStockResultado = record
    Articulo: string;
    Descripcion: string;
    Total: Double;
    Items: TArray<TStockItem>;
    FotoUrl300: string;
    FotoBase64300: string;
    BaseUrl: string;
  end;

  TApiClient = class
  private
    class function GetJson(const Url: string): TJSONObject; static;
  public
    class function ConsultarStock(const Articulo: string): TStockResultado; static;
    class function DescargarFoto300(
      const Stock: TStockResultado): TBytes; static;
  end;

implementation

uses
  System.Generics.Collections;

const
  MAX_BYTES_FOTO = 4 * 1024 * 1024;
  MAX_CARACTERES_BASE64_FOTO = ((MAX_BYTES_FOTO + 2) div 3) * 4 + 128;

type
  TStreamFotoLimitado = class(TMemoryStream)
  private
    FLimite: Int64;
  public
    constructor Create(ALimite: Int64);
    function Write(const Buffer; Count: Longint): Longint; override;
  end;

constructor TStreamFotoLimitado.Create(ALimite: Int64);
begin
  inherited Create;
  FLimite := ALimite;
end;

function TStreamFotoLimitado.Write(
  const Buffer; Count: Longint): Longint;
begin
  if (Count > 0) and (Size + Count > FLimite) then
    raise EStreamError.CreateFmt(
      'La foto supera el limite de %d bytes.', [FLimite]);
  Result := inherited Write(Buffer, Count);
end;

function JsonString(Json: TJSONObject; const Clave: string): string;
var
  Valor: TJSONValue;
begin
  Result := '';
  if Json = nil then
    Exit;
  Valor := Json.GetValue(Clave);
  if Assigned(Valor) and not (Valor is TJSONNull) then
    Result := Valor.Value;
end;

function DecodificarFotoBase64(const Texto: string): TBytes;
var
  Base64: string;
  PosicionComa: Integer;
begin
  Result := nil;
  Base64 := Trim(Texto);
  if Base64 = '' then
    Exit;
  if Base64.StartsWith('data:', True) then
  begin
    PosicionComa := Base64.IndexOf(',');
    if PosicionComa < 0 then
      Exit;
    Base64 := Base64.Substring(PosicionComa + 1);
  end;
  if Length(Base64) > MAX_CARACTERES_BASE64_FOTO then
    Exit;
  try
    Result := TNetEncoding.Base64.DecodeStringToBytes(Base64);
    if Length(Result) > MAX_BYTES_FOTO then
      Result := nil;
  except
    Result := nil;
  end;
end;

function FotoBase64Factuzam(
  Json: TJSONObject; const Articulo: string): string;
var
  Candidato: string;
  Foto: TJSONObject;
  Fotos: TJSONArray;
  Valor: TJSONValue;
begin
  Result := '';
  if Json = nil then
    Exit;

  Result := JsonString(Json, 'contenido_base64');
  if Result <> '' then
    Exit;

  if Json.GetValue('foto') is TJSONObject then
  begin
    Result := JsonString(Json.GetValue('foto') as TJSONObject,
      'contenido_base64');
    if Result <> '' then
      Exit;
  end;

  if not (Json.GetValue('fotos') is TJSONArray) then
    Exit;
  Fotos := Json.GetValue('fotos') as TJSONArray;
  Candidato := '';
  for Valor in Fotos do
    if Valor is TJSONObject then
    begin
      Foto := Valor as TJSONObject;
      if Candidato = '' then
        Candidato := JsonString(Foto, 'contenido_base64');
      if SameText(JsonString(Foto, 'articulo'), Articulo) then
      begin
        Result := JsonString(Foto, 'contenido_base64');
        if Result <> '' then
          Exit;
      end;
    end;
  Result := Candidato;
end;

class function TApiClient.GetJson(const Url: string): TJSONObject;
var
  BaseUrl, ErrorUrl: string;
  Http: THTTPClient;
  Resp: IHTTPResponse;
  Token, Body: string;
  Headers: TNetHeaders;

  function HacerPeticion: IHTTPResponse;
  begin
    // Header Authorization como argumento del Get (mas fiable que CustHeaders)
    SetLength(Headers, 1);
    Headers[0] := TNetHeader.Create('Authorization', 'Bearer ' + Token);
    Result := Http.Get(Url, nil, Headers);
  end;

begin
  BaseUrl := TSettings.LeerBaseUrl;
  if not ValidarUrlBasePermitida(BaseUrl, ErrorUrl) then
    raise EApiError.Create(ErrorUrl);
  if not MismoOrigen(BaseUrl, Url) then
    raise EApiError.Create(
      'La consulta no pertenece al servidor configurado.');
  Http := THTTPClient.Create;
  try
    Http.SecureProtocols := [THTTPSecureProtocol.TLS12, THTTPSecureProtocol.TLS13];
    Http.HandleRedirects := False;
    Http.ConnectionTimeout := 8000;
    Http.ResponseTimeout   := 15000;

    Token := TAuthService.ObtenerTokenValido;

    if Trim(Token) = '' then
      raise EApiError.Create('No se pudo obtener un token valido.');

    Resp := HacerPeticion;

    // Si el servidor invalido el token (401), refrescar y reintentar UNA vez
    if Resp.StatusCode = 401 then
    begin
      TAuthService.RefrescarToken;
      Token := TSettings.LeerToken;
      if Trim(Token) = '' then
        raise EApiError.Create('No se pudo refrescar el token.');
      Resp := HacerPeticion;
    end;

    Body := Resp.ContentAsString(TEncoding.UTF8);

    if Resp.StatusCode = 404 then
      raise EApiError.Create('No hay stock para ese articulo.');

    if (Resp.StatusCode < 200) or (Resp.StatusCode >= 300) then
      raise EApiError.CreateFmt('Error HTTP %d: %s', [Resp.StatusCode, Body]);

    Result := TJSONObject.ParseJSONValue(Body) as TJSONObject;
    if Result = nil then
      raise EApiError.Create('Respuesta JSON invalida');
  finally
    Http.Free;
  end;
end;

class function TApiClient.ConsultarStock(const Articulo: string): TStockResultado;
var
  Json, Datos: TJSONObject;
  Detalle, Tallas, Almacenes: TJSONObject;
  ColorPair, TallaPair, AlmPair: TJSONPair;
  Items: TList<TStockItem>;
  Item: TStockItem;
  ErrorUrl, Url, UrlBase: string;
begin
  Result := Default(TStockResultado);
  UrlBase := TSettings.LeerBaseUrl;
  if not ValidarUrlBasePermitida(UrlBase, ErrorUrl) then
    raise EApiError.Create(ErrorUrl);
  UrlBase := NormalizarUrlBase(UrlBase);
  if not ConstruirUrlMismoOrigen(UrlBase,
    'stock.php?articulo=' + TNetEncoding.URL.Encode(Articulo), Url,
    ErrorUrl) then
    raise EApiError.Create(ErrorUrl);

  Json := GetJson(Url);
  Items := TList<TStockItem>.Create;
  try
    Datos := Json;
    if Json.GetValue('datos') is TJSONObject then
      Datos := Json.GetValue('datos') as TJSONObject;

    Result.Articulo := JsonString(Datos, 'articulo');
    Result.Descripcion := JsonString(Datos, 'descripcion');
    Result.Total := StrToFloatDef(JsonString(Datos, 'stock_total'), 0,
      TFormatSettings.Invariant);
    Result.FotoUrl300 := JsonString(Datos, 'foto_300_url');
    if Result.FotoUrl300 = '' then
      Result.FotoUrl300 := JsonString(Datos, 'foto_url');
    if Result.FotoUrl300 = '' then
      Result.FotoUrl300 := JsonString(Datos, 'foto_ruta');
    Result.FotoBase64300 := JsonString(Datos, 'foto_300_base64');
    if Result.FotoBase64300 = '' then
      Result.FotoBase64300 := FotoBase64Factuzam(Datos, Result.Articulo);
    if (Result.FotoBase64300 = '') and (Datos <> Json) then
      Result.FotoBase64300 := FotoBase64Factuzam(Json, Result.Articulo);

    if Result.Articulo = '' then
      Result.Articulo := Articulo;
    Result.BaseUrl := UrlBase;

    Detalle := Datos.GetValue('detalle') as TJSONObject;
    if Detalle = nil then
      raise EApiError.Create('La respuesta no contiene el detalle de stock.');

    // detalle = { color: { talla: { Almacen_X: unidades } } }
    for ColorPair in Detalle do
    begin
      Tallas := ColorPair.JsonValue as TJSONObject;
      for TallaPair in Tallas do
      begin
        Almacenes := TallaPair.JsonValue as TJSONObject;
        for AlmPair in Almacenes do
        begin
          Item.Color    := ColorPair.JsonString.Value;
          Item.Talla    := TallaPair.JsonString.Value;
          Item.Almacen  := AlmPair.JsonString.Value;
          Item.Unidades := (AlmPair.JsonValue as TJSONNumber).AsDouble;
          Items.Add(Item);
        end;
      end;
    end;

    Result.Items := Items.ToArray;
  finally
    Items.Free;
    Json.Free;
  end;
end;

class function TApiClient.DescargarFoto300(
  const Stock: TStockResultado): TBytes;
var
  Headers: TNetHeaders;
  Http: THTTPClient;
  Memoria: TStreamFotoLimitado;
  Respuesta: IHTTPResponse;
  BaseUrl, ErrorUrl, Token, Url: string;
begin
  Result := DecodificarFotoBase64(Stock.FotoBase64300);
  if Length(Result) > 0 then
    Exit;
  if Trim(Stock.FotoUrl300) = '' then
    Exit(nil);

  BaseUrl := NormalizarUrlBase(Stock.BaseUrl);
  if (BaseUrl = '') or
     not SameText(BaseUrl, NormalizarUrlBase(TSettings.LeerBaseUrl)) then
    Exit(nil);
  if not ConstruirUrlMismoOrigen(BaseUrl, Stock.FotoUrl300, Url,
    ErrorUrl) then
    Exit(nil);

  Token := TAuthService.ObtenerTokenValido;
  if Trim(Token) = '' then
    Exit(nil);

  Http := THTTPClient.Create;
  try
    try
      Http.SecureProtocols := [THTTPSecureProtocol.TLS12,
        THTTPSecureProtocol.TLS13];
      Http.HandleRedirects := False;
      Http.ConnectionTimeout := 8000;
      Http.ResponseTimeout := 15000;
      Memoria := TStreamFotoLimitado.Create(MAX_BYTES_FOTO);
      try
        SetLength(Headers, 2);
        Headers[0] := TNetHeader.Create('Authorization', 'Bearer ' + Token);
        Headers[1] := TNetHeader.Create('Accept', 'image/png,image/*');
        Respuesta := Http.Get(Url, Memoria, Headers);
        if Respuesta.StatusCode = 401 then
        begin
          TAuthService.RefrescarToken;
          Token := TSettings.LeerToken;
          if Trim(Token) = '' then
            Exit(nil);
          Headers[0] := TNetHeader.Create('Authorization', 'Bearer ' + Token);
          Memoria.Size := 0;
          Respuesta := Http.Get(Url, Memoria, Headers);
        end;
        if (Respuesta.StatusCode < 200) or
           (Respuesta.StatusCode >= 300) or (Memoria.Size = 0) then
          Exit(nil);
        SetLength(Result, Memoria.Size);
        Memoria.Position := 0;
        Memoria.ReadBuffer(Result[0], Length(Result));
      finally
        Memoria.Free;
      end;
    except
      Result := nil;
    end;
  finally
    Http.Free;
  end;
end;

end.
