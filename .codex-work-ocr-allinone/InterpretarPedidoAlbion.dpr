program InterpretarPedidoAlbion;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  System.StrUtils,
  AlbionPedidoParser in 'AlbionPedidoParser.pas',
  AzureDocumentIntelligenceClient in 'AzureDocumentIntelligenceClient.pas';

type
  TOpciones = record
    Entrada: string;
    Salida: string;
    SalidaOcr: string;
    ConfigAzure: string;
    Modelo: string;
    TimeoutSeconds: Integer;
    Force: Boolean;
    Ayuda: Boolean;
    SalidaExplicita: Boolean;
    SalidaOcrExplicita: Boolean;
  end;

procedure MostrarAyuda;
begin
  Writeln('Uso:');
  Writeln('  InterpretarPedidoAlbion.exe [entrada.pdf|resultado-azure.json] [opciones]');
  Writeln;
  Writeln('Opciones:');
  Writeln('  --config <azure.txt>      Archivo con KEY 1 y ENDPOINT');
  Writeln('  --output <salida.json>    JSON simplificado');
  Writeln('  --raw-output <ocr.json>   JSON tecnico de Azure');
  Writeln('  --model <modelo>          Por defecto prebuilt-layout');
  Writeln('  --timeout <segundos>      Por defecto 300');
  Writeln('  --force                   Permite sobrescribir salidas');
  Writeln('  --help                    Muestra esta ayuda');
  Writeln;
  Writeln('Sin entrada selecciona automaticamente el unico PDF de la carpeta.');
  Writeln('Tambien acepta un JSON de Azure ya generado para trabajar sin consumir Azure.');
end;

function SiguienteValor(var AIndice: Integer; const AOpcion: string): string;
begin
  Inc(AIndice);
  if AIndice > ParamCount then
    raise Exception.Create('Falta el valor de ' + AOpcion + '.');
  Result := ParamStr(AIndice);
end;

function LeerOpciones: TOpciones;
var
  I, Timeout: Integer;
  Parametro: string;
begin
  Result.Entrada := '';
  Result.Salida := '';
  Result.SalidaOcr := '';
  Result.ConfigAzure := '';
  Result.Modelo := 'prebuilt-layout';
  Result.TimeoutSeconds := 300;
  Result.Force := False;
  Result.Ayuda := False;
  Result.SalidaExplicita := False;
  Result.SalidaOcrExplicita := False;

  I := 1;
  while I <= ParamCount do
  begin
    Parametro := ParamStr(I);
    if SameText(Parametro, '--help') or SameText(Parametro, '-h') then
      Result.Ayuda := True
    else if SameText(Parametro, '--force') then
      Result.Force := True
    else if SameText(Parametro, '--config') then
      Result.ConfigAzure := SiguienteValor(I, Parametro)
    else if SameText(Parametro, '--output') then
    begin
      Result.Salida := SiguienteValor(I, Parametro);
      Result.SalidaExplicita := True;
    end
    else if SameText(Parametro, '--raw-output') then
    begin
      Result.SalidaOcr := SiguienteValor(I, Parametro);
      Result.SalidaOcrExplicita := True;
    end
    else if SameText(Parametro, '--model') then
      Result.Modelo := SiguienteValor(I, Parametro)
    else if SameText(Parametro, '--timeout') then
    begin
      Parametro := SiguienteValor(I, Parametro);
      if not TryStrToInt(Parametro, Timeout) or
         (Timeout < 10) or (Timeout > 3600) then
        raise Exception.Create('--timeout debe estar entre 10 y 3600 segundos.');
      Result.TimeoutSeconds := Timeout;
    end
    else if StartsText('--', Parametro) then
      raise Exception.Create('Opcion desconocida: ' + Parametro)
    else if Result.Entrada = '' then
      Result.Entrada := Parametro
    else
      raise Exception.Create('Solo se admite un archivo de entrada.');
    Inc(I);
  end;
end;

function UnirNombres(const AArchivos: TArray<string>): string;
var
  Archivo: string;
begin
  Result := '';
  for Archivo in AArchivos do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + TPath.GetFileName(Archivo);
  end;
end;

function BuscarJsonAzureUnico(const ACarpeta: string): string;
var
  Archivos, Candidatos: TArray<string>;
  Archivo: string;
  Cantidad: Integer;
begin
  Archivos := TDirectory.GetFiles(ACarpeta, '*.azure-ocr.*.json');
  SetLength(Candidatos, Length(Archivos));
  Cantidad := 0;
  for Archivo in Archivos do
    if not EndsText('.albion-simple.json', Archivo) then
    begin
      Candidatos[Cantidad] := Archivo;
      Inc(Cantidad);
    end;
  SetLength(Candidatos, Cantidad);

  if Length(Candidatos) = 0 then
    Exit('');
  if Length(Candidatos) > 1 then
    raise Exception.Create('Hay varios JSON de Azure: ' +
      UnirNombres(Candidatos) + '. Indica uno como entrada.');
  Result := Candidatos[0];
end;

function BuscarEntradaAutomatica: string;
var
  Carpeta: string;
  Pdfs: TArray<string>;
begin
  Carpeta := IncludeTrailingPathDelimiter(GetCurrentDir);
  Pdfs := TDirectory.GetFiles(Carpeta, '*.pdf');
  if Length(Pdfs) = 1 then
    Exit(Pdfs[0]);
  if Length(Pdfs) > 1 then
    raise Exception.Create('Hay varios PDF: ' + UnirNombres(Pdfs) +
      '. Indica uno como entrada.');

  Result := BuscarJsonAzureUnico(Carpeta);
  if Result = '' then
    raise Exception.CreateFmt('No hay ningun PDF ni JSON de Azure en %s',
      [Carpeta]);
end;

function EtiquetaSegura(const ATexto: string): string;
var
  C: Char;
begin
  Result := '';
  for C in ATexto do
    if CharInSet(C, ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.']) then
      Result := Result + C
    else
      Result := Result + '-';
end;

function RutaConMarcaTemporal(const ARuta: string): string;
var
  Base, Extension, Marca: string;
  Numero: Integer;
begin
  Extension := TPath.GetExtension(ARuta);
  Base := TPath.ChangeExtension(ARuta, '');
  Marca := FormatDateTime('yyyymmdd-hhnnss', Now);
  Result := Base + '.' + Marca + Extension;
  Numero := 2;
  while TFile.Exists(Result) do
  begin
    Result := Base + '.' + Marca + '-' + Numero.ToString + Extension;
    Inc(Numero);
  end;
end;

function PrepararRutaSalida(const ARuta: string; AForce,
  AExplicita: Boolean): string;
begin
  Result := TPath.GetFullPath(ARuta);
  if not TFile.Exists(Result) or AForce then
    Exit;
  if AExplicita then
    raise Exception.Create('La salida ya existe; usa --force: ' + Result);
  Result := RutaConMarcaTemporal(Result);
end;

procedure GuardarTextoUtf8(const ARuta, AContenido: string);
var
  Codificacion: TEncoding;
  Carpeta: string;
begin
  Carpeta := TPath.GetDirectoryName(ARuta);
  if (Carpeta <> '') and not TDirectory.Exists(Carpeta) then
    TDirectory.CreateDirectory(Carpeta);
  Codificacion := TUTF8Encoding.Create(False);
  try
    TFile.WriteAllText(ARuta, AContenido, Codificacion);
  finally
    Codificacion.Free;
  end;
end;

procedure GuardarJson(const ARuta: string; AJson: TJSONObject);
begin
  GuardarTextoUtf8(ARuta, AJson.Format(2));
end;

procedure ProcesarPdf(var AOpciones: TOpciones; const ARutaPdf: string;
  out AJsonAzure: string; out ARutaJsonAzure, ARutaSalida: string);
var
  Credenciales: TCredencialesAzure;
  Cliente: TAzureDocumentIntelligenceClient;
  BasePdf, NombreOcr: string;
begin
  BasePdf := TPath.ChangeExtension(ARutaPdf, '');
  if AOpciones.SalidaOcr = '' then
  begin
    NombreOcr := BasePdf + '.azure-ocr.' +
      EtiquetaSegura(AOpciones.Modelo) + '.json';
    ARutaJsonAzure := PrepararRutaSalida(NombreOcr, AOpciones.Force, False);
  end
  else
    ARutaJsonAzure := PrepararRutaSalida(AOpciones.SalidaOcr,
      AOpciones.Force, AOpciones.SalidaOcrExplicita);

  if AOpciones.Salida = '' then
    ARutaSalida := TPath.ChangeExtension(ARutaJsonAzure,
      '.albion-simple.json')
  else
    ARutaSalida := PrepararRutaSalida(AOpciones.Salida,
      AOpciones.Force, AOpciones.SalidaExplicita);

  if (AOpciones.Salida = '') and TFile.Exists(ARutaSalida) and
     not AOpciones.Force then
    ARutaSalida := RutaConMarcaTemporal(ARutaSalida);

  Credenciales := CargarCredencialesAzure(AOpciones.ConfigAzure);
  Cliente := TAzureDocumentIntelligenceClient.Create(Credenciales);
  try
    Cliente.TimeoutSeconds := AOpciones.TimeoutSeconds;
    Cliente.OnEstado :=
      procedure(AMensaje: string)
      begin
        Writeln(AMensaje);
      end;
    AJsonAzure := Cliente.AnalizarPdf(ARutaPdf, AOpciones.Modelo);
  finally
    Cliente.Free;
    Credenciales.ApiKey := '';
    Credenciales.Endpoint := '';
  end;

  GuardarTextoUtf8(ARutaJsonAzure, AJsonAzure);
  Writeln('JSON Azure: ', ARutaJsonAzure);
end;

var
  Opciones: TOpciones;
  RutaEntrada, RutaSalida, RutaJsonAzure, JsonAzure: string;
  Salida: TJSONObject;
begin
  try
    Opciones := LeerOpciones;
    if Opciones.Ayuda then
    begin
      MostrarAyuda;
      Exit;
    end;

    if Opciones.Entrada = '' then
      RutaEntrada := BuscarEntradaAutomatica
    else
      RutaEntrada := TPath.GetFullPath(Opciones.Entrada);
    if not TFile.Exists(RutaEntrada) then
      raise Exception.Create('No existe la entrada: ' + RutaEntrada);

    JsonAzure := '';
    RutaJsonAzure := '';
    if SameText(TPath.GetExtension(RutaEntrada), '.pdf') then
      ProcesarPdf(Opciones, RutaEntrada, JsonAzure, RutaJsonAzure, RutaSalida)
    else if SameText(TPath.GetExtension(RutaEntrada), '.json') then
    begin
      if Opciones.SalidaOcr <> '' then
        raise Exception.Create('--raw-output solo se usa al procesar un PDF.');
      if Opciones.Salida = '' then
        RutaSalida := PrepararRutaSalida(
          TPath.ChangeExtension(RutaEntrada, '.albion-simple.json'),
          Opciones.Force, False)
      else
        RutaSalida := PrepararRutaSalida(Opciones.Salida,
          Opciones.Force, Opciones.SalidaExplicita);
    end
    else
      raise Exception.Create('La entrada debe ser PDF o JSON.');

    if JsonAzure <> '' then
      Salida := TAlbionPedidoParser.ConvertirTexto(JsonAzure)
    else
      Salida := TAlbionPedidoParser.ConvertirArchivo(RutaEntrada);
    try
      GuardarJson(RutaSalida, Salida);
    finally
      Salida.Free;
      JsonAzure := '';
    end;

    Writeln('Pedido interpretado correctamente.');
    Writeln('Entrada: ', RutaEntrada);
    Writeln('Salida:  ', RutaSalida);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, 'ERROR: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
