unit uAuthService;

{
  Servicio de autenticacion JWT.

  - Login(): hace POST a /login.php con usuario+password, recibe el token y lo
    guarda junto con las credenciales en uSettings.
  - ObtenerTokenValido(): devuelve un token vivo. Si el guardado caduco,
    hace login en silencio con las credenciales guardadas.
  - RefrescarToken(): fuerza un re-login (lo usa uApiClient cuando recibe 401).

  HTTPS se valida normalmente. Para instalaciones dentro de la red interna se
  admite HTTP solo si uUrlSegura clasifica el host como privado o local.
}

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Net.HttpClient,
  System.Net.URLClient, System.NetConsts, uSettings, uUrlSegura;

type
  EAuthError = class(Exception);

  TAuthService = class
  public
    class procedure Login(const Usuario, Password: string); static;
    class function ObtenerTokenValido: string; static;
    class procedure RefrescarToken; static;
  end;

implementation

class procedure TAuthService.Login(const Usuario, Password: string);
var
  Http: THTTPClient;
  Body: TStringStream;
  Resp: IHTTPResponse;
  Datos, Json, Payload: TJSONObject;
  Token: string;
  ExpiraEn: Integer;
  ErrorUrl, UrlBase, UrlLogin: string;
begin
  UrlBase := TSettings.LeerBaseUrl;
  if not ValidarUrlBasePermitida(UrlBase, ErrorUrl) then
    raise EAuthError.Create(ErrorUrl);
  UrlBase := NormalizarUrlBase(UrlBase);
  if not ConstruirUrlMismoOrigen(UrlBase, 'login.php', UrlLogin,
    ErrorUrl) then
    raise EAuthError.Create(ErrorUrl);
  if Trim(Usuario) = '' then
    raise EAuthError.Create('Introduce el usuario.');
  if Password = '' then
    raise EAuthError.Create('Introduce la contrasena.');

  Payload := TJSONObject.Create;
  Http := THTTPClient.Create;
  try
    Payload.AddPair('usuario',  Usuario);
    Payload.AddPair('password', Password);

    Body := TStringStream.Create(Payload.ToJSON, TEncoding.UTF8);
    try
      Http.ContentType := 'application/json';
      Http.SecureProtocols := [THTTPSecureProtocol.TLS12, THTTPSecureProtocol.TLS13];
      Http.HandleRedirects := False;
      Http.ConnectionTimeout := 8000;
      Http.ResponseTimeout   := 15000;

      Resp := Http.Post(UrlLogin, Body);

      if Resp.StatusCode <> 200 then
        raise EAuthError.CreateFmt('Login fallo (%d): %s',
          [Resp.StatusCode, Resp.ContentAsString(TEncoding.UTF8)]);

      Json := TJSONObject.ParseJSONValue(Resp.ContentAsString(TEncoding.UTF8)) as TJSONObject;
      try
        Datos := Json;
        if Assigned(Json) and (Json.GetValue('datos') is TJSONObject) then
          Datos := Json.GetValue('datos') as TJSONObject;
        if (Datos = nil) or (Datos.GetValue('token') = nil) then
          raise EAuthError.Create('Respuesta de login sin token');

        Token := Datos.GetValue<string>('token');
        ExpiraEn := 3600;
        Datos.TryGetValue<Integer>('expira_en', ExpiraEn);

        TSettings.GuardarCredenciales(Usuario, Password);
        TSettings.GuardarToken(Token, ExpiraEn);
      finally
        Json.Free;
      end;
    finally
      Body.Free;
    end;
  finally
    Http.Free;
    Payload.Free;
  end;
end;

class procedure TAuthService.RefrescarToken;
begin
  if not TSettings.HayCredenciales then
    raise EAuthError.Create('No hay credenciales guardadas. Inicia sesion.');
  Login(TSettings.LeerUsuario, TSettings.LeerPassword);
end;

class function TAuthService.ObtenerTokenValido: string;
begin
  if TSettings.TokenValido then
    Exit(TSettings.LeerToken);
  RefrescarToken;
  Result := TSettings.LeerToken;
end;

end.
