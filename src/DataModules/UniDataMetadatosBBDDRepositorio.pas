{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataMetadatosBBDDRepositorio                               }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                        }
{   Fecha:       04/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                    }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Acceso UniDAC al catálogo y operaciones auxiliares de la BBDD.            }
{******************************************************************************}
unit UniDataMetadatosBBDDRepositorio;

interface

uses
  Uni,
  inLibMetadatosBBDDIntf;

function CrearCatalogoMetadatosBBDDUniDAC(
  AConexion: TUniConnection;
  AMetadatos, AEstructura, AContenido: TUniQuery;
  ARefresco: TUniStoredProc): ICatalogoMetadatosBBDD;

implementation

uses
  System.SysUtils;

type
  TCatalogoMetadatosBBDDUniDAC = class(
    TInterfacedObject,
    ICatalogoMetadatosBBDD)
  private
    FConexion: TUniConnection;
    FContenido: TUniQuery;
    FEstructura: TUniQuery;
    FMetadatos: TUniQuery;
    FRefresco: TUniStoredProc;
    function IdentificadorSeguro(const AValor: string): string;
    function ListaIdentificadores(
      const AObjetos: TArray<string>): string;
    procedure AbrirConsulta(const ASQL: string);
  public
    constructor Create(
      AConexion: TUniConnection;
      AMetadatos, AEstructura, AContenido: TUniQuery;
      ARefresco: TUniStoredProc);
    procedure Refrescar(const ABaseDatos: string);
    procedure CargarObjetos(ATipo: TTipoObjetoMetadatosBBDD);
    function CargarEstructura(
      ATipo: TTipoObjetoMetadatosBBDD;
      const ANombre: string): string;
    procedure CargarContenido(const ANombre: string);
    function GenerarLlamadaProcedimiento(
      const ANombre: string): string;
    procedure RegenerarTablas(const ATablas: TArray<string>);
    procedure RegenerarIndices(const ATablas: TArray<string>);
    procedure RegenerarVistas(const AVistas: TArray<string>);
    procedure RegenerarProcedimientos(
      const AProcedimientos: TArray<string>);
    procedure AnalizarTablas(const ATablas: TArray<string>);
    procedure ComprobarObjetos(const AObjetos: TArray<string>);
    procedure CargarEstadoTabla(const ANombre: string);
    procedure CargarPlanVista(const ANombre: string);
    procedure CargarDependencias(
      ATipo: TTipoObjetoMetadatosBBDD;
      const ANombre: string);
    procedure CalcularChecksum(const ATablas: TArray<string>);
    procedure VaciarTablas(const ATablas: TArray<string>);
    procedure BorrarTablas(const ATablas: TArray<string>);
    procedure EjecutarConsulta(const ASQL: string);
  end;

constructor TCatalogoMetadatosBBDDUniDAC.Create(
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

function TCatalogoMetadatosBBDDUniDAC.IdentificadorSeguro(
  const AValor: string): string;
var
  i: Integer;
begin
  Result := Trim(AValor);
  if Result = '' then
    raise EArgumentException.Create(
      'El identificador no puede estar vacío');
  for i := 1 to Length(Result) do
  begin
    if not CharInSet(
      Result[i],
      ['A'..'Z', 'a'..'z', '0'..'9', '_', '$']) then
      raise EArgumentException.CreateFmt(
        'Identificador de base de datos no válido: %s',
        [Result]);
  end;
end;

function TCatalogoMetadatosBBDDUniDAC.ListaIdentificadores(
  const AObjetos: TArray<string>): string;
var
  i: Integer;
begin
  Result := '';
  if Length(AObjetos) = 0 then
    raise EArgumentException.Create(
      'Debe seleccionar al menos un objeto de base de datos');
  for i := 0 to Length(AObjetos) - 1 do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + IdentificadorSeguro(AObjetos[i]);
  end;
end;

procedure TCatalogoMetadatosBBDDUniDAC.AbrirConsulta(
  const ASQL: string);
begin
  FContenido.Close;
  FContenido.SQL.Text := ASQL;
  FContenido.Open;
end;

procedure TCatalogoMetadatosBBDDUniDAC.Refrescar(
  const ABaseDatos: string);
begin
  FMetadatos.Close;
  FRefresco.ParamByName('pDATABASENAME').AsString := ABaseDatos;
  FRefresco.ExecProc;
end;

procedure TCatalogoMetadatosBBDDUniDAC.CargarObjetos(
  ATipo: TTipoObjetoMetadatosBBDD);
begin
  FMetadatos.Close;
  FMetadatos.ParamByName('pTIPO').AsInteger := Ord(ATipo) + 1;
  FMetadatos.Open;
end;

function TCatalogoMetadatosBBDDUniDAC.CargarEstructura(
  ATipo: TTipoObjetoMetadatosBBDD;
  const ANombre: string): string;
var
  sCampoResultado: string;
begin
  Result := '';
  FEstructura.Close;
  if ATipo = tombTabla then
  begin
    FEstructura.SQL.Text := 'SHOW CREATE TABLE ' +
      IdentificadorSeguro(ANombre);
    sCampoResultado := 'Create Table';
  end
  else if ATipo = tombVista then
  begin
    FEstructura.SQL.Text := 'SHOW CREATE VIEW ' +
      IdentificadorSeguro(ANombre);
    sCampoResultado := 'Create View';
  end
  else
  begin
    FEstructura.SQL.Text := 'SHOW CREATE PROCEDURE ' +
      IdentificadorSeguro(ANombre);
    sCampoResultado := 'Create Procedure';
  end;
  FEstructura.Open;
  Result := FEstructura.FieldByName(sCampoResultado).AsString;
end;

procedure TCatalogoMetadatosBBDDUniDAC.CargarContenido(
  const ANombre: string);
begin
  FContenido.Close;
  FContenido.SQL.Text := 'SELECT * FROM ' +
    IdentificadorSeguro(ANombre);
  FContenido.Open;
end;

function TCatalogoMetadatosBBDDUniDAC.GenerarLlamadaProcedimiento(
  const ANombre: string): string;
var
  oConsulta: TUniQuery;
  sNombreSeguro: string;
begin
  sNombreSeguro := IdentificadorSeguro(ANombre);
  Result := 'CALL ' + sNombreSeguro + '(';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT PARAMETER_NAME, DTD_IDENTIFIER ' +
      'FROM information_schema.parameters ' +
      'WHERE SPECIFIC_SCHEMA = :BaseDatos ' +
      'AND SPECIFIC_NAME = :Procedimiento ' +
      'AND ROUTINE_TYPE = ''PROCEDURE'' ' +
      'ORDER BY ORDINAL_POSITION';
    oConsulta.ParamByName('BaseDatos').AsString := FConexion.Database;
    oConsulta.ParamByName('Procedimiento').AsString := sNombreSeguro;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      Result := Result + '/* ' +
        oConsulta.FieldByName('PARAMETER_NAME').AsString + ' ' +
        oConsulta.FieldByName('DTD_IDENTIFIER').AsString + ' */';
      oConsulta.Next;
      if not oConsulta.Eof then
        Result := Result + ', ';
    end;
  finally
    oConsulta.Free;
  end;
  Result := Result + ');';
end;

procedure TCatalogoMetadatosBBDDUniDAC.RegenerarTablas(
  const ATablas: TArray<string>);
var
  i: Integer;
begin
  for i := 0 to Length(ATablas) - 1 do
    FConexion.ExecSQL(
      'ALTER TABLE ' + IdentificadorSeguro(ATablas[i]) + ' FORCE');
end;

procedure TCatalogoMetadatosBBDDUniDAC.RegenerarIndices(
  const ATablas: TArray<string>);
begin
  FConexion.ExecSQL(
    'OPTIMIZE TABLE ' + ListaIdentificadores(ATablas));
end;

procedure TCatalogoMetadatosBBDDUniDAC.RegenerarVistas(
  const AVistas: TArray<string>);
var
  i: Integer;
  sSQL: string;
begin
  for i := 0 to Length(AVistas) - 1 do
  begin
    sSQL := CargarEstructura(tombVista, AVistas[i]);
    sSQL := StringReplace(
      sSQL,
      'CREATE ',
      'CREATE OR REPLACE ',
      [rfIgnoreCase]);
    FConexion.ExecSQL(sSQL);
  end;
end;

procedure TCatalogoMetadatosBBDDUniDAC.RegenerarProcedimientos(
  const AProcedimientos: TArray<string>);
var
  i: Integer;
  sSQL: string;
begin
  for i := 0 to Length(AProcedimientos) - 1 do
  begin
    sSQL := CargarEstructura(
      tombProcedimiento,
      AProcedimientos[i]);
    sSQL := StringReplace(
      sSQL,
      'CREATE ',
      'CREATE OR REPLACE ',
      [rfIgnoreCase]);
    FConexion.ExecSQL(sSQL);
  end;
end;

procedure TCatalogoMetadatosBBDDUniDAC.AnalizarTablas(
  const ATablas: TArray<string>);
begin
  AbrirConsulta(
    'ANALYZE TABLE ' + ListaIdentificadores(ATablas));
end;

procedure TCatalogoMetadatosBBDDUniDAC.ComprobarObjetos(
  const AObjetos: TArray<string>);
begin
  AbrirConsulta(
    'CHECK TABLE ' + ListaIdentificadores(AObjetos));
end;

procedure TCatalogoMetadatosBBDDUniDAC.CargarEstadoTabla(
  const ANombre: string);
begin
  FContenido.Close;
  FContenido.SQL.Text :=
    'SELECT TABLE_NAME AS OBJETO, ENGINE AS MOTOR, ' +
    'TABLE_ROWS AS FILAS_ESTIMADAS, ' +
    'DATA_LENGTH AS BYTES_DATOS, ' +
    'INDEX_LENGTH AS BYTES_INDICES, ' +
    'DATA_FREE AS BYTES_LIBRES, AUTO_INCREMENT, ' +
    'TABLE_COLLATION AS INTERCALACION, CREATE_TIME, UPDATE_TIME ' +
    'FROM information_schema.tables ' +
    'WHERE TABLE_SCHEMA = :BaseDatos AND TABLE_NAME = :Objeto';
  FContenido.ParamByName('BaseDatos').AsString := FConexion.Database;
  FContenido.ParamByName('Objeto').AsString :=
    IdentificadorSeguro(ANombre);
  FContenido.Open;
end;

procedure TCatalogoMetadatosBBDDUniDAC.CargarPlanVista(
  const ANombre: string);
begin
  AbrirConsulta(
    'EXPLAIN SELECT * FROM ' + IdentificadorSeguro(ANombre));
end;

procedure TCatalogoMetadatosBBDDUniDAC.CargarDependencias(
  ATipo: TTipoObjetoMetadatosBBDD;
  const ANombre: string);
begin
  FContenido.Close;
  if ATipo = tombTabla then
    FContenido.SQL.Text :=
      'SELECT ''VISTA QUE UTILIZA LA TABLA'' AS TIPO, ' +
      'V.TABLE_NAME AS OBJETO, :Objeto AS REFERENCIA, ' +
      '''Referencia encontrada en la definición'' AS DETALLE ' +
      'FROM information_schema.views V ' +
      'WHERE V.TABLE_SCHEMA = :BaseDatos ' +
      'AND LOWER(V.VIEW_DEFINITION) LIKE ' +
      'LOWER(CONCAT(''%`.`'', :Objeto, ''`%'')) ' +
      'UNION ALL ' +
      'SELECT ''CLAVE FORANEA'', TABLE_NAME, REFERENCED_TABLE_NAME, ' +
      'CONCAT(COLUMN_NAME, '' -> '', REFERENCED_COLUMN_NAME) ' +
      'FROM information_schema.key_column_usage ' +
      'WHERE CONSTRAINT_SCHEMA = :BaseDatos ' +
      'AND (TABLE_NAME = :Objeto OR REFERENCED_TABLE_NAME = :Objeto) ' +
      'AND REFERENCED_TABLE_NAME IS NOT NULL ' +
      'UNION ALL ' +
      'SELECT ''INDICE'', TABLE_NAME, INDEX_NAME, ' +
      'CONCAT(COLUMN_NAME, '' (posicion '', SEQ_IN_INDEX, '')'') ' +
      'FROM information_schema.statistics ' +
      'WHERE TABLE_SCHEMA = :BaseDatos AND TABLE_NAME = :Objeto'
  else
    FContenido.SQL.Text :=
      'SELECT ''OBJETO UTILIZADO POR LA VISTA'' AS TIPO, ' +
      'V.TABLE_NAME AS OBJETO, T.TABLE_NAME AS REFERENCIA, ' +
      'T.TABLE_TYPE AS DETALLE ' +
      'FROM information_schema.views V ' +
      'INNER JOIN information_schema.tables T ' +
      'ON T.TABLE_SCHEMA = V.TABLE_SCHEMA ' +
      'AND T.TABLE_NAME <> V.TABLE_NAME ' +
      'AND LOWER(V.VIEW_DEFINITION) LIKE ' +
      'LOWER(CONCAT(''%`.`'', T.TABLE_NAME, ''`%'')) ' +
      'WHERE V.TABLE_SCHEMA = :BaseDatos AND V.TABLE_NAME = :Objeto ' +
      'UNION ALL ' +
      'SELECT ''VISTA QUE UTILIZA ESTA VISTA'', V.TABLE_NAME, ' +
      ':Objeto, CAST(NULL AS CHAR) ' +
      'FROM information_schema.views V ' +
      'WHERE V.TABLE_SCHEMA = :BaseDatos ' +
      'AND V.TABLE_NAME <> :Objeto ' +
      'AND LOWER(V.VIEW_DEFINITION) LIKE ' +
      'LOWER(CONCAT(''%`.`'', :Objeto, ''`%''))';
  FContenido.ParamByName('BaseDatos').AsString := FConexion.Database;
  FContenido.ParamByName('Objeto').AsString :=
    IdentificadorSeguro(ANombre);
  FContenido.Open;
end;

procedure TCatalogoMetadatosBBDDUniDAC.CalcularChecksum(
  const ATablas: TArray<string>);
begin
  AbrirConsulta(
    'CHECKSUM TABLE ' + ListaIdentificadores(ATablas));
end;

procedure TCatalogoMetadatosBBDDUniDAC.VaciarTablas(
  const ATablas: TArray<string>);
var
  i: Integer;
begin
  for i := 0 to Length(ATablas) - 1 do
    FConexion.ExecSQL(
      'TRUNCATE TABLE ' + IdentificadorSeguro(ATablas[i]));
end;

procedure TCatalogoMetadatosBBDDUniDAC.BorrarTablas(
  const ATablas: TArray<string>);
begin
  FConexion.ExecSQL(
    'DROP TABLE IF EXISTS ' + ListaIdentificadores(ATablas));
end;

procedure TCatalogoMetadatosBBDDUniDAC.EjecutarConsulta(
  const ASQL: string);
begin
  AbrirConsulta(ASQL);
end;

function CrearCatalogoMetadatosBBDDUniDAC(
  AConexion: TUniConnection;
  AMetadatos, AEstructura, AContenido: TUniQuery;
  ARefresco: TUniStoredProc): ICatalogoMetadatosBBDD;
begin
  Result := TCatalogoMetadatosBBDDUniDAC.Create(
    AConexion,
    AMetadatos,
    AEstructura,
    AContenido,
    ARefresco);
end;

end.
