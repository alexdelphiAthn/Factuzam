{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataGeneradorProcesosRepositorio                           }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia y ejecución del generador de procesos.                       }
{******************************************************************************}
unit UniDataGeneradorProcesosRepositorio;

interface

uses
  Data.DB,
  Uni,
  inLibGeneradorProcesosAplicacion;

procedure CrearRepositorioGeneradorProcesosUniDAC(
  AConexion: TUniConnection;
  AMetadatos, AEstructura, AContenido: TUniQuery;
  ARefresco: TUniStoredProc;
  out ARepositorio: IRepositorioGeneradorProcesos;
  out ACatalogo: ICatalogoGeneradorProcesos);
function ExtraerDatosResultadoProceso(
  const AResultado: IResultadoSentenciaProceso): TDataSet;

implementation

uses
  System.Classes,
  System.Diagnostics,
  System.SysUtils,
  inLibProteccionDatosFacturacion,
  UniScript;

type
  IResultadoSentenciaProcesoUniDAC = interface
    ['{68667238-E002-4D91-8ADC-83FEB0DB9377}']
    function ExtraerDatos: TDataSet;
  end;
  TResultadoSentenciaProcesoUniDAC = class(
    TInterfacedObject,
    IResultadoSentenciaProceso,
    IResultadoSentenciaProcesoUniDAC)
  private
    FConsulta: TUniQuery;
    FCorrecto: Boolean;
    FFilas: Integer;
    FMensajeError: string;
    FMilisegundos: Int64;
    FTieneDatos: Boolean;
  public
    destructor Destroy; override;
    function Correcto: Boolean;
    function TieneDatos: Boolean;
    function Filas: Integer;
    function Milisegundos: Int64;
    function MensajeError: string;
    function ExtraerDatos: TDataSet;
  end;
  TRepositorioGeneradorProcesosUniDAC = class(
    TInterfacedObject,
    IRepositorioGeneradorProcesos,
    ICatalogoGeneradorProcesos)
  private
    FConexion: TUniConnection;
    FContenido: TUniQuery;
    FEstructura: TUniQuery;
    FMetadatos: TUniQuery;
    FRefresco: TUniStoredProc;
    procedure EjecutarComando(
      const ASentencia: string;
      AResultado: TResultadoSentenciaProcesoUniDAC);
    procedure EjecutarConsulta(
      const ASentencia: string;
      AResultado: TResultadoSentenciaProcesoUniDAC);
  public
    constructor Create(
      AConexion: TUniConnection;
      AMetadatos, AEstructura, AContenido: TUniQuery;
      ARefresco: TUniStoredProc);
    function SepararSentencias(
      const AScript: string): TArray<string>;
    function EjecutarSentencia(
      const ASentencia: string;
      ATipo: TTipoSentenciaProceso): IResultadoSentenciaProceso;
    procedure Refrescar(const ABaseDatos: string);
    function CargarEstructura(
      const ATipo, ANombre: string): string;
    procedure CargarContenido(const ANombre: string);
    function GenerarLlamadaProcedimiento(
      const ANombre: string): string;
  end;

function IdentificadorSeguro(const AValor: string): string;
var
  I: Integer;
begin
  Result := Trim(AValor);
  if Result = '' then
    raise EArgumentException.Create('El identificador no puede estar vacío');
  for I := 1 to Length(Result) do
  begin
    if not CharInSet(Result[I], ['A'..'Z', 'a'..'z', '0'..'9', '_', '$']) then
      raise EArgumentException.CreateFmt(
        'Identificador de base de datos no válido: %s',
        [Result]);
  end;
end;

destructor TResultadoSentenciaProcesoUniDAC.Destroy;
begin
  FConsulta.Free;
  inherited;
end;

function TResultadoSentenciaProcesoUniDAC.Correcto: Boolean;
begin
  Result := FCorrecto;
end;

function TResultadoSentenciaProcesoUniDAC.TieneDatos: Boolean;
begin
  Result := FTieneDatos;
end;

function TResultadoSentenciaProcesoUniDAC.Filas: Integer;
begin
  Result := FFilas;
end;

function TResultadoSentenciaProcesoUniDAC.Milisegundos: Int64;
begin
  Result := FMilisegundos;
end;

function TResultadoSentenciaProcesoUniDAC.MensajeError: string;
begin
  Result := FMensajeError;
end;

function TResultadoSentenciaProcesoUniDAC.ExtraerDatos: TDataSet;
begin
  Result := FConsulta;
  FConsulta := nil;
end;

constructor TRepositorioGeneradorProcesosUniDAC.Create(
  AConexion: TUniConnection;
  AMetadatos, AEstructura, AContenido: TUniQuery;
  ARefresco: TUniStoredProc);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if not Assigned(AMetadatos) then
    raise EArgumentNilException.Create('AMetadatos');
  if not Assigned(AEstructura) then
    raise EArgumentNilException.Create('AEstructura');
  if not Assigned(AContenido) then
    raise EArgumentNilException.Create('AContenido');
  if not Assigned(ARefresco) then
    raise EArgumentNilException.Create('ARefresco');
  FConexion := AConexion;
  FMetadatos := AMetadatos;
  FEstructura := AEstructura;
  FContenido := AContenido;
  FRefresco := ARefresco;
end;

function TRepositorioGeneradorProcesosUniDAC.SepararSentencias(
  const AScript: string): TArray<string>;
var
  I: Integer;
  Sentencia: string;
  Script: TUniScript;
begin
  Result := nil;
  if Trim(AScript) = '' then
  begin
  end
  else if Pos('DELIMITER ', UpperCase(AScript)) > 0 then
  begin
    SetLength(Result, 1);
    Result[0] := AScript;
  end
  else
  begin
    Script := TUniScript.Create(nil);
    try
      Script.Connection := FConexion;
      Script.SQL.Text := AScript;
      for I := 0 to Script.Statements.Count - 1 do
      begin
        Sentencia := Trim(Script.Statements[I].SQL);
        if PrimeraLineaUtilProceso(Sentencia) <> '' then
        begin
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)] := Sentencia;
        end;
      end;
    except
      SetLength(Result, 1);
      Result[0] := AScript;
    end;
    Script.Free;
  end;
end;

procedure TRepositorioGeneradorProcesosUniDAC.EjecutarConsulta(
  const ASentencia: string;
  AResultado: TResultadoSentenciaProcesoUniDAC);
begin
  AResultado.FConsulta := TUniQuery.Create(nil);
  AResultado.FConsulta.Connection := FConexion;
  AResultado.FConsulta.SQL.Text := ASentencia;
  AResultado.FConsulta.ReadOnly :=
    SqlReferenciaTablaFacturacionProtegida(ASentencia);
  AResultado.FConsulta.Open;
  AResultado.FTieneDatos := AResultado.FConsulta.FieldCount > 0;
  if AResultado.FTieneDatos then
    AResultado.FFilas := AResultado.FConsulta.RecordCount
  else
    AResultado.FFilas := AResultado.FConsulta.RowsAffected;
end;

procedure TRepositorioGeneradorProcesosUniDAC.EjecutarComando(
  const ASentencia: string;
  AResultado: TResultadoSentenciaProcesoUniDAC);
var
  Script: TUniScript;
begin
  Script := TUniScript.Create(nil);
  try
    Script.Connection := FConexion;
    Script.SQL.Text := ASentencia;
    Script.Execute;
    AResultado.FFilas := Script.RowsAffected;
  finally
    Script.Free;
  end;
end;

function TRepositorioGeneradorProcesosUniDAC.EjecutarSentencia(
  const ASentencia: string;
  ATipo: TTipoSentenciaProceso): IResultadoSentenciaProceso;
var
  Cronometro: TStopwatch;
  ResultadoUniDAC: TResultadoSentenciaProcesoUniDAC;
begin
  ResultadoUniDAC := TResultadoSentenciaProcesoUniDAC.Create;
  Result := ResultadoUniDAC;
  Cronometro := TStopwatch.StartNew;
  try
    try
      if ATipo = tspConsulta then
      begin
        try
          EjecutarConsulta(ASentencia, ResultadoUniDAC);
        except
          ResultadoUniDAC.FConsulta.Free;
          ResultadoUniDAC.FConsulta := nil;
          EjecutarComando(ASentencia, ResultadoUniDAC);
        end;
      end
      else
        EjecutarComando(ASentencia, ResultadoUniDAC);
      ResultadoUniDAC.FCorrecto := True;
    except
      on E: Exception do
        ResultadoUniDAC.FMensajeError := E.Message;
    end;
  finally
    Cronometro.Stop;
    ResultadoUniDAC.FMilisegundos := Cronometro.ElapsedMilliseconds;
  end;
end;

procedure TRepositorioGeneradorProcesosUniDAC.Refrescar(
  const ABaseDatos: string);
begin
  FRefresco.ParamByName('pDATABASENAME').AsString := ABaseDatos;
  FRefresco.ExecProc;
  if FMetadatos.Active then
    FMetadatos.Refresh
  else
    FMetadatos.Open;
end;

function TRepositorioGeneradorProcesosUniDAC.CargarEstructura(
  const ATipo, ANombre: string): string;
var
  CampoResultado: string;
begin
  Result := '';
  FEstructura.Close;
  if ATipo = '1' then
  begin
    FEstructura.SQL.Text := 'SHOW CREATE TABLE ' +
      IdentificadorSeguro(ANombre);
    CampoResultado := 'Create Table';
  end
  else if ATipo = '2' then
  begin
    FEstructura.SQL.Text := 'SHOW CREATE VIEW ' +
      IdentificadorSeguro(ANombre);
    CampoResultado := 'Create View';
  end
  else if ATipo = '3' then
  begin
    FEstructura.SQL.Text := 'SHOW CREATE PROCEDURE ' +
      IdentificadorSeguro(ANombre);
    CampoResultado := 'Create Procedure';
  end
  else
    CampoResultado := '';
  if CampoResultado <> '' then
  begin
    FEstructura.Open;
    Result := FEstructura.FieldByName(CampoResultado).AsString;
  end;
end;

procedure TRepositorioGeneradorProcesosUniDAC.CargarContenido(
  const ANombre: string);
begin
  FContenido.Close;
  FContenido.ReadOnly := EsTablaFacturacionProtegida(ANombre);
  FContenido.SQL.Text := 'SELECT * FROM ' +
    IdentificadorSeguro(ANombre) + ' LIMIT 1000';
  FContenido.Open;
end;

function TRepositorioGeneradorProcesosUniDAC.
  GenerarLlamadaProcedimiento(const ANombre: string): string;
var
  Consulta: TUniQuery;
  NombreSeguro: string;
begin
  NombreSeguro := IdentificadorSeguro(ANombre);
  Result := 'CALL ' + NombreSeguro + '(';
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text :=
      'SELECT PARAMETER_NAME, DTD_IDENTIFIER ' +
      'FROM information_schema.parameters ' +
      'WHERE SPECIFIC_NAME = :ProcName ' +
      'AND ROUTINE_TYPE = ''PROCEDURE'' ' +
      'ORDER BY ORDINAL_POSITION';
    Consulta.ParamByName('ProcName').AsString := NombreSeguro;
    Consulta.Open;
    while not Consulta.Eof do
    begin
      Result := Result + '/* ' +
        Consulta.FieldByName('PARAMETER_NAME').AsString + ' ' +
        Consulta.FieldByName('DTD_IDENTIFIER').AsString + ' */';
      Consulta.Next;
      if not Consulta.Eof then
        Result := Result + ', ';
    end;
  finally
    Consulta.Free;
  end;
  Result := Result + ');';
end;

procedure CrearRepositorioGeneradorProcesosUniDAC(
  AConexion: TUniConnection;
  AMetadatos, AEstructura, AContenido: TUniQuery;
  ARefresco: TUniStoredProc;
  out ARepositorio: IRepositorioGeneradorProcesos;
  out ACatalogo: ICatalogoGeneradorProcesos);
var
  Adaptador: TRepositorioGeneradorProcesosUniDAC;
begin
  Adaptador := TRepositorioGeneradorProcesosUniDAC.Create(
    AConexion,
    AMetadatos,
    AEstructura,
    AContenido,
    ARefresco);
  ARepositorio := Adaptador;
  ACatalogo := Adaptador;
end;

function ExtraerDatosResultadoProceso(
  const AResultado: IResultadoSentenciaProceso): TDataSet;
var
  ResultadoUniDAC: IResultadoSentenciaProcesoUniDAC;
begin
  Result := nil;
  if AResultado <> nil then
  begin
    try
      ResultadoUniDAC :=
        AResultado as IResultadoSentenciaProcesoUniDAC;
      Result := ResultadoUniDAC.ExtraerDatos;
    except
      on EIntfCastError do
        Result := nil;
    end;
  end;
end;

end.
