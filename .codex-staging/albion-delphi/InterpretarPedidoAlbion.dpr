program InterpretarPedidoAlbion;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  AlbionPedidoParser in 'AlbionPedidoParser.pas';

function BuscarEntradaAutomatica: string;
var
  Carpeta: string;
  Archivos, Candidatos: TArray<string>;
  Archivo: string;
  Cantidad: Integer;
begin
  Carpeta := ExtractFilePath(ParamStr(0));
  Archivos := TDirectory.GetFiles(Carpeta, '*.azure-ocr.*.json');
  SetLength(Candidatos, Length(Archivos));
  Cantidad := 0;
  for Archivo in Archivos do
    if not Archivo.ToLower.EndsWith('.albion-simple.json') then
    begin
      Candidatos[Cantidad] := Archivo;
      Inc(Cantidad);
    end;
  SetLength(Candidatos, Cantidad);

  if Length(Candidatos) = 0 then
    raise Exception.CreateFmt('No hay ningun JSON de Azure OCR en %s', [Carpeta]);
  if Length(Candidatos) > 1 then
    raise Exception.Create(
      'Hay varios JSON de Azure OCR. Indica la ruta de entrada como primer parametro.');
  Result := Candidatos[0];
end;

procedure GuardarJson(const ARuta: string; AJson: TJSONObject);
var
  Codificacion: TEncoding;
begin
  Codificacion := TUTF8Encoding.Create(False);
  try
    TFile.WriteAllText(ARuta, AJson.Format(2), Codificacion);
  finally
    Codificacion.Free;
  end;
end;

var
  RutaEntrada, RutaSalida: string;
  Salida: TJSONObject;
begin
  try
    if ParamCount >= 1 then
      RutaEntrada := TPath.GetFullPath(ParamStr(1))
    else
      RutaEntrada := BuscarEntradaAutomatica;

    if ParamCount >= 2 then
      RutaSalida := TPath.GetFullPath(ParamStr(2))
    else
      RutaSalida := TPath.ChangeExtension(RutaEntrada, '.albion-simple.json');

    Salida := TAlbionPedidoParser.ConvertirArchivo(RutaEntrada);
    try
      GuardarJson(RutaSalida, Salida);
    finally
      Salida.Free;
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

