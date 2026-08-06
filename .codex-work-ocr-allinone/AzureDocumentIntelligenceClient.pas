unit AzureDocumentIntelligenceClient;

interface

uses
  System.SysUtils;

type
  EAzureDocumentIntelligence = class(Exception);

  TCredencialesAzure = record
    Endpoint: string;
    ApiKey: string;
  end;

  TAzureDocumentIntelligenceClient = class
  private
    FEndpoint: string;
    FApiKey: string;
    FTimeoutSeconds: Integer;
    FOnEstado: TProc<string>;
    procedure Notificar(const AMensaje: string);
  public
    constructor Create(const ACredenciales: TCredencialesAzure);
    destructor Destroy; override;
    function AnalizarPdf(const ARutaPdf: string;
      const AModelo: string = 'prebuilt-layout'): string;
    property TimeoutSeconds: Integer read FTimeoutSeconds write FTimeoutSeconds;
    property OnEstado: TProc<string> read FOnEstado write FOnEstado;
  end;

function CargarCredencialesAzure(
  const ARutaConfiguracion: string = ''): TCredencialesAzure;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.JSON,
  System.StrUtils,
  System.Math,
  System.Diagnostics,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.NetEncoding;

const
  CApiVersion = '2024-11-30';
  CModeloDefecto = 'prebuilt-layout';
  CEsperaDefectoSegundos = 2;
  CEsperaMaximaSegundos = 30;

function QuitarComillas(const AValor: string): string;
begin
  Result := Trim(AValor);
  if (Length(Result) >= 2) and
     (((Result[1] = '"') and (Result[Length(Result)] = '"')) or
      ((Result[1] = '''') and (Result[Length(Result)] = ''''))) then
    Result := Copy(Result, 2, Length(Result) - 2);
end;

function ValorTrasEtiqueta(const ALinea: string;
  const AEtiquetas: array of string): string;
var
  Texto, Etiqueta: string;
  I: Integer;
begin
  Texto := Trim(ALinea);
  for I := Low(AEtiquetas) to High(AEtiquetas) do
  begin
    Etiqueta := AEtiquetas[I];
    if StartsText(Etiqueta, Texto) then
    begin
      Result := Trim(Copy(Texto, Length(Etiqueta) + 1, MaxInt));
      while (Result <> '') and CharInSet(Result[1], [' ', ':', '=']) do
        Delete(Result, 1, 1);
      Exit(QuitarComillas(Result));
    end;
  end;
  Result := '';
end;

function LeerConfiguracion(const ARuta: string;
  var ACredenciales: TCredencialesAzure): Boolean;
var
  Lineas: TArray<string>;
  Linea, Valor: string;
  Codificacion: TEncoding;
begin
  Result := False;
  if (ARuta = '') or not TFile.Exists(ARuta) then
    Exit;

  Codificacion := TUTF8Encoding.Create(False);
  try
    Lineas := TFile.ReadAllLines(ARuta, Codificacion);
  finally
    Codificacion.Free;
  end;

  for Linea in Lineas do
  begin
    if ACredenciales.ApiKey = '' then
    begin
      Valor := ValorTrasEtiqueta(Linea,
        ['AZURE_DOCUMENT_INTELLIGENCE_KEY', 'AZURE_OCR_KEY',
         'KEY 1', 'KEY1', 'CLAVE 1']);
      if Valor <> '' then
        ACredenciales.ApiKey := Valor;
    end;

    if ACredenciales.Endpoint = '' then
    begin
      Valor := ValorTrasEtiqueta(Linea,
        ['AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT', 'AZURE_OCR_ENDPOINT',
         'ENDPOINT']);
      if Valor <> '' then
        ACredenciales.Endpoint := Valor;
    end;
  end;

  Result := (ACredenciales.Endpoint <> '') and
    (ACredenciales.ApiKey <> '');
end;

function CargarCredencialesAzure(
  const ARutaConfiguracion: string): TCredencialesAzure;
var
  Ruta: string;
begin
  Result.Endpoint := Trim(GetEnvironmentVariable(
    'AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT'));
  if Result.Endpoint = '' then
    Result.Endpoint := Trim(GetEnvironmentVariable('AZURE_OCR_ENDPOINT'));

  Result.ApiKey := Trim(GetEnvironmentVariable(
    'AZURE_DOCUMENT_INTELLIGENCE_KEY'));
  if Result.ApiKey = '' then
    Result.ApiKey := Trim(GetEnvironmentVariable('AZURE_OCR_KEY'));

  Ruta := Trim(ARutaConfiguracion);
  if Ruta = '' then
    Ruta := Trim(GetEnvironmentVariable('AZURE_OCR_CONFIG'));
  if (Ruta = '') and TFile.Exists(TPath.Combine(GetCurrentDir, 'azure.txt')) then
    Ruta := TPath.Combine(GetCurrentDir, 'azure.txt');

  if Ruta <> '' then
  begin
    Ruta := TPath.GetFullPath(Ruta);
    if not TFile.Exists(Ruta) then
      raise EAzureDocumentIntelligence.Create(
        'No existe el archivo de configuracion de Azure indicado.');
    LeerConfiguracion(Ruta, Result);
  end;

  Result.Endpoint := QuitarComillas(Result.Endpoint);
  Result.ApiKey := QuitarComillas(Result.ApiKey);
  while EndsText('/', Result.Endpoint) do
    Delete(Result.Endpoint, Length(Result.Endpoint), 1);

  if Result.Endpoint = '' then
    raise EAzureDocumentIntelligence.Create(
      'Falta el endpoint de Azure Document Intelligence.');
  if Result.ApiKey = '' then
    raise EAzureDocumentIntelligence.Create(
      'Falta la clave de Azure Document Intelligence.');
end;

function MensajeErrorAzure(const ACuerpo: string;
  ACodigoHttp: Integer): string;
var
  RaizValor, ErrorValor, CodigoValor, MensajeValor: TJSONValue;
  Detalle: string;
begin
  Detalle := '';
  RaizValor := TJSONObject.ParseJSONValue(ACuerpo);
  try
    if RaizValor is TJSONObject then
    begin
      ErrorValor := TJSONObject(RaizValor).GetValue('error');
      if ErrorValor is TJSONObject then
      begin
        CodigoValor := TJSONObject(ErrorValor).GetValue('code');
        MensajeValor := TJSONObject(ErrorValor).GetValue('message');
        if CodigoValor <> nil then
          Detalle := Trim(CodigoValor.Value);
        if MensajeValor <> nil then
        begin
          if Detalle <> '' then
            Detalle := Detalle + ': ';
          Detalle := Detalle + Trim(MensajeValor.Value);
        end;
      end;
    end;
  finally
    RaizValor.Free;
  end;

  Result := Format('Azure devolvio HTTP %d', [ACodigoHttp]);
  if Detalle <> '' then
    Result := Result + ' (' + Detalle + ')';
end;

function EstadoResultado(const ACuerpo: string): string;
var
  ValorRaiz, ValorEstado: TJSONValue;
begin
  ValorRaiz := TJSONObject.ParseJSONValue(ACuerpo);
  try
    if not (ValorRaiz is TJSONObject) then
      raise EAzureDocumentIntelligence.Create(
        'Azure devolvio una respuesta que no es JSON valido.');
    ValorEstado := TJSONObject(ValorRaiz).GetValue('status');
    if ValorEstado = nil then
      raise EAzureDocumentIntelligence.Create(
        'La respuesta de Azure no contiene status.');
    Result := Trim(ValorEstado.Value);
  finally
    ValorRaiz.Free;
  end;
end;

function EsperaSegundos(ARespuesta: IHTTPResponse;
  ADefecto: Integer): Integer;
begin
  Result := ADefecto;
  if ARespuesta <> nil then
    Result := StrToIntDef(Trim(ARespuesta.HeaderValue['Retry-After']), ADefecto);
  Result := EnsureRange(Result, 1, CEsperaMaximaSegundos);
end;

function EsCodigoTemporal(ACodigo: Integer): Boolean;
begin
  Result := (ACodigo = 408) or (ACodigo = 429) or
    ((ACodigo >= 500) and (ACodigo <= 599));
end;

function ResolverOperationLocation(const AEndpoint, AAnalyzeUrl,
  AOperationLocation: string): string;
var
  UriEndpoint, UriAnalyze, UriOperacion: TURI;
begin
  if Trim(AOperationLocation) = '' then
    raise EAzureDocumentIntelligence.Create(
      'Azure no devolvio la cabecera Operation-Location.');

  UriEndpoint := TURI.Create(AEndpoint);
  if ContainsText(AOperationLocation, '://') then
    Result := Trim(AOperationLocation)
  else
  begin
    UriAnalyze := TURI.Create(AAnalyzeUrl);
    Result := TURI.PathRelativeToAbs(Trim(AOperationLocation), UriAnalyze);
  end;

  UriOperacion := TURI.Create(Result);
  if not SameText(UriEndpoint.Scheme, 'https') then
    raise EAzureDocumentIntelligence.Create(
      'El endpoint de Azure debe usar HTTPS.');
  if not SameText(UriOperacion.Scheme, UriEndpoint.Scheme) or
     not SameText(UriOperacion.Host, UriEndpoint.Host) or
     (UriOperacion.Port <> UriEndpoint.Port) or
     (UriOperacion.Username <> '') or (UriOperacion.Password <> '') then
    raise EAzureDocumentIntelligence.Create(
      'Operation-Location apunta a otro origen; se cancela para proteger la clave.');
end;

procedure ValidarEndpoint(const AEndpoint: string);
var
  Uri: TURI;
begin
  try
    Uri := TURI.Create(AEndpoint);
  except
    on E: Exception do
      raise EAzureDocumentIntelligence.Create(
        'El endpoint de Azure no es una URL valida.');
  end;

  if not SameText(Uri.Scheme, 'https') then
    raise EAzureDocumentIntelligence.Create(
      'El endpoint de Azure debe usar HTTPS.');
  if Trim(Uri.Host) = '' then
    raise EAzureDocumentIntelligence.Create(
      'El endpoint de Azure no contiene un host valido.');
  if (Uri.Username <> '') or (Uri.Password <> '') or
     (Uri.Query <> '') or (Uri.Fragment <> '') or
     ((Uri.Path <> '') and (Uri.Path <> '/')) then
    raise EAzureDocumentIntelligence.Create(
      'El endpoint debe ser solamente la URL base del recurso de Azure.');
end;

procedure ValidarPdf(const ARutaPdf: string);
var
  Flujo: TFileStream;
  Firma: array[0..4] of Byte;
begin
  if not TFile.Exists(ARutaPdf) then
    raise EAzureDocumentIntelligence.CreateFmt(
      'No existe el PDF: %s', [ARutaPdf]);
  if not SameText(TPath.GetExtension(ARutaPdf), '.pdf') then
    raise EAzureDocumentIntelligence.Create(
      'Azure espera un archivo con extension PDF.');

  Flujo := TFileStream.Create(ARutaPdf, fmOpenRead or fmShareDenyWrite);
  try
    if (Flujo.Size < Length(Firma)) or
       (Flujo.Read(Firma, Length(Firma)) <> Length(Firma)) or
       (Firma[0] <> Ord('%')) or (Firma[1] <> Ord('P')) or
       (Firma[2] <> Ord('D')) or (Firma[3] <> Ord('F')) or
       (Firma[4] <> Ord('-')) then
      raise EAzureDocumentIntelligence.Create(
        'El archivo no contiene una cabecera PDF valida.');
  finally
    Flujo.Free;
  end;
end;

constructor TAzureDocumentIntelligenceClient.Create(
  const ACredenciales: TCredencialesAzure);
begin
  inherited Create;
  FEndpoint := ACredenciales.Endpoint;
  FApiKey := ACredenciales.ApiKey;
  ValidarEndpoint(FEndpoint);
  if FApiKey = '' then
    raise EAzureDocumentIntelligence.Create('La clave de Azure esta vacia.');
  FTimeoutSeconds := 300;
end;

destructor TAzureDocumentIntelligenceClient.Destroy;
begin
  FApiKey := '';
  FEndpoint := '';
  FOnEstado := nil;
  inherited Destroy;
end;

procedure TAzureDocumentIntelligenceClient.Notificar(const AMensaje: string);
begin
  if Assigned(FOnEstado) then
    FOnEstado(AMensaje);
end;

function TAzureDocumentIntelligenceClient.AnalizarPdf(const ARutaPdf,
  AModelo: string): string;
var
  Http: THTTPClient;
  Pdf: TFileStream;
  Respuesta: IHTTPResponse;
  AnalyzeUrl, OperationLocation, Cuerpo, Estado, Modelo: string;
  Espera, ErroresConsecutivos: Integer;
  Cronometro: TStopwatch;
begin
  ValidarPdf(ARutaPdf);

  Modelo := Trim(AModelo);
  if Modelo = '' then
    Modelo := CModeloDefecto;
  AnalyzeUrl := FEndpoint + '/documentintelligence/documentModels/' +
    TNetEncoding.URL.Encode(Modelo) + ':analyze?api-version=' + CApiVersion;

  Http := THTTPClient.Create;
  try
    Http.ConnectionTimeout := 15000;
    Http.SendTimeout := 120000;
    Http.ResponseTimeout := 60000;
    Http.HandleRedirects := False;
    Http.AllowCookies := False;
    Http.UseDefaultCredentials := False;

    Pdf := TFileStream.Create(ARutaPdf, fmOpenRead or fmShareDenyWrite);
    try
      Notificar('Enviando PDF a Azure...');
      try
        Respuesta := Http.Post(AnalyzeUrl, Pdf, nil,
          [TNetHeader.Create('Content-Type', 'application/pdf'),
           TNetHeader.Create('Accept', 'application/json'),
           TNetHeader.Create('Ocp-Apim-Subscription-Key', FApiKey)]);
      except
        on E: Exception do
          raise EAzureDocumentIntelligence.Create(
            'No se pudo enviar el PDF a Azure: ' + E.Message);
      end;
    finally
      Pdf.Free;
    end;

    if Respuesta.StatusCode <> 202 then
      raise EAzureDocumentIntelligence.Create(
        MensajeErrorAzure(Respuesta.ContentAsString(TEncoding.UTF8),
          Respuesta.StatusCode));

    OperationLocation := ResolverOperationLocation(FEndpoint, AnalyzeUrl,
      Respuesta.HeaderValue['Operation-Location']);
    Espera := EsperaSegundos(Respuesta, CEsperaDefectoSegundos);
    ErroresConsecutivos := 0;
    Cronometro := TStopwatch.StartNew;

    while Cronometro.Elapsed.TotalSeconds < FTimeoutSeconds do
    begin
      TThread.Sleep(Espera * 1000);
      try
        Respuesta := Http.Get(OperationLocation, nil,
          [TNetHeader.Create('Accept', 'application/json'),
           TNetHeader.Create('Ocp-Apim-Subscription-Key', FApiKey)]);
      except
        on E: Exception do
        begin
          Inc(ErroresConsecutivos);
          if (ErroresConsecutivos >= 5) or
             (Cronometro.Elapsed.TotalSeconds >= FTimeoutSeconds) then
            raise EAzureDocumentIntelligence.Create(
              'No se pudo consultar el resultado de Azure tras varios reintentos.');
          Espera := Min(CEsperaMaximaSegundos, Max(2, Espera * 2));
          Notificar('Error temporal de red; reintentando consulta...');
          Continue;
        end;
      end;

      if EsCodigoTemporal(Respuesta.StatusCode) then
      begin
        Inc(ErroresConsecutivos);
        if ErroresConsecutivos >= 5 then
          raise EAzureDocumentIntelligence.Create(
            'Azure rechazo temporalmente demasiadas consultas consecutivas.');
        Espera := EsperaSegundos(Respuesta,
          Min(CEsperaMaximaSegundos, Max(2, Espera * 2)));
        Notificar(Format('Azure HTTP %d; reintentando consulta...',
          [Respuesta.StatusCode]));
        Continue;
      end;

      if Respuesta.StatusCode <> 200 then
        raise EAzureDocumentIntelligence.Create(
          MensajeErrorAzure(Respuesta.ContentAsString(TEncoding.UTF8),
            Respuesta.StatusCode));

      ErroresConsecutivos := 0;
      Cuerpo := Respuesta.ContentAsString(TEncoding.UTF8);
      Estado := EstadoResultado(Cuerpo);
      Notificar('Estado Azure: ' + Estado);

      if SameText(Estado, 'succeeded') then
        Exit(Cuerpo);
      if SameText(Estado, 'failed') or SameText(Estado, 'canceled') or
         SameText(Estado, 'skipped') then
        raise EAzureDocumentIntelligence.Create(
          'El analisis de Azure termino con estado ' + Estado + '.');
      if not SameText(Estado, 'running') and
         not SameText(Estado, 'notStarted') then
        raise EAzureDocumentIntelligence.Create(
          'Azure devolvio un estado desconocido: ' + Estado);

      Espera := EsperaSegundos(Respuesta, CEsperaDefectoSegundos);
    end;

    raise EAzureDocumentIntelligence.CreateFmt(
      'Tiempo de espera agotado despues de %d segundos.', [FTimeoutSeconds]);
  finally
    Http.Free;
  end;
end;

end.
