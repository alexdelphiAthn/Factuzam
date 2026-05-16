{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDBStructure                                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica la estructura mínima de la base de datos Factuzam antes de       }
{    permitir el login y reporta los objetos que faltan.                       }
{******************************************************************************}
unit inLibDBStructure;

interface

uses
  System.SysUtils, System.Classes, Uni, Data.DB;

type
  TDBStructureStatus = (
    dbsOK,                  // Todo correcto
    dbsDatabaseNotExists,   // El schema no existe
    dbsMissingObjects,      // El schema existe pero faltan tablas/vistas
    dbsConnectionError      // No se pudo conectar al servidor
  );

  TDBStructureCheckResult = record
    Status: TDBStructureStatus;
    DatabaseName: string;
    MissingObjects: TArray<string>;
    ErrorMessage: string;
    function IsOK: Boolean;
    function FormattedMessage: string;
  end;

  TDBStructureChecker = class
  private
    class function ObjectExists(AConn: TUniConnection;
                                const ASchema, AName, AType: string): Boolean;
  public
    /// <summary>
    /// Verifica que existan los objetos mínimos requeridos en la BBDD.
    /// La conexión debe estar abierta contra information_schema o contra
    /// el propio schema que se quiere comprobar.
    /// </summary>
    class function Check(AConn: TUniConnection;
                         const ADatabaseName: string): TDBStructureCheckResult;
  end;

const
  // Objetos mínimos imprescindibles para que el login funcione.
  // Si más adelante necesitas comprobar más objetos, añádelos aquí.
  REQUIRED_TABLES: array[0..0] of string = (
    'fza_usuarios'
  );

  REQUIRED_VIEWS: array[0..0] of string = (
    'VI_USUARIOS'
  );

implementation

{ TDBStructureCheckResult }

function TDBStructureCheckResult.IsOK: Boolean;
begin
  Result := Status = dbsOK;
end;

function TDBStructureCheckResult.FormattedMessage: string;
var
  sMissing: string;
  s: string;
begin
  case Status of
    dbsOK:
      Result := 'Estructura correcta.';
    dbsDatabaseNotExists:
      Result := Format('La base de datos "%s" no existe en el servidor.',
                       [DatabaseName]);
    dbsMissingObjects:
      begin
        sMissing := '';
        for s in MissingObjects do
          sMissing := sMissing + '  - ' + s + sLineBreak;
        Result := Format('La base de datos "%s" existe, pero faltan los ' +
                         'siguientes objetos requeridos:' + sLineBreak + '%s',
                         [DatabaseName, sMissing]);
      end;
    dbsConnectionError:
      Result := 'Error de conexión: ' + ErrorMessage;
  else
    Result := 'Estado desconocido.';
  end;
end;

{ TDBStructureChecker }

class function TDBStructureChecker.ObjectExists(AConn: TUniConnection;
  const ASchema, AName, AType: string): Boolean;
var
  qry: TUniQuery;
begin
  Result := False;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := AConn;
    if SameText(AType, 'TABLE') then
    begin
      // INFORMATION_SCHEMA.TABLES incluye tanto tablas base como vistas.
      // Filtramos por TABLE_TYPE para distinguirlas.
      qry.SQL.Text :=
        'SELECT 1 FROM INFORMATION_SCHEMA.TABLES ' +
        ' WHERE TABLE_SCHEMA = :SCH ' +
        '   AND TABLE_NAME   = :NAM ' +
        '   AND TABLE_TYPE   = ''BASE TABLE'' ';
    end
    else if SameText(AType, 'VIEW') then
    begin
      qry.SQL.Text :=
        'SELECT 1 FROM INFORMATION_SCHEMA.VIEWS ' +
        ' WHERE TABLE_SCHEMA = :SCH ' +
        '   AND TABLE_NAME   = :NAM ';
    end
    else
      Exit;

    qry.ParamByName('SCH').AsString := ASchema;
    qry.ParamByName('NAM').AsString := AName;
    qry.Open;
    Result := not qry.IsEmpty;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

class function TDBStructureChecker.Check(AConn: TUniConnection;
  const ADatabaseName: string): TDBStructureCheckResult;
var
  qrySchema: TUniQuery;
  Missing: TStringList;
  sName: string;
begin
  Result := Default(TDBStructureCheckResult);
  Result.DatabaseName := ADatabaseName;
  Result.Status := dbsOK;

  if (AConn = nil) or (not AConn.Connected) then
  begin
    Result.Status := dbsConnectionError;
    Result.ErrorMessage := 'La conexión no está activa.';
    Exit;
  end;

  try
    // 1) ¿Existe el schema?
    qrySchema := TUniQuery.Create(nil);
    try
      qrySchema.Connection := AConn;
      qrySchema.SQL.Text :=
        'SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA ' +
        ' WHERE SCHEMA_NAME = :BBDD ';
      qrySchema.ParamByName('BBDD').AsString := ADatabaseName;
      qrySchema.Open;

      if qrySchema.IsEmpty then
      begin
        Result.Status := dbsDatabaseNotExists;
        qrySchema.Close;
        Exit;
      end;
      qrySchema.Close;
    finally
      FreeAndNil(qrySchema);
    end;

    // 2) ¿Están los objetos mínimos?
    Missing := TStringList.Create;
    try
      for sName in REQUIRED_TABLES do
        if not ObjectExists(AConn, ADatabaseName, sName, 'TABLE') then
          Missing.Add('Tabla: ' + sName);

      for sName in REQUIRED_VIEWS do
        if not ObjectExists(AConn, ADatabaseName, sName, 'VIEW') then
          Missing.Add('Vista: ' + sName);

      if Missing.Count > 0 then
      begin
        Result.Status := dbsMissingObjects;
        Result.MissingObjects := Missing.ToStringArray;
      end;
    finally
      FreeAndNil(Missing);
    end;
  except
    on E: Exception do
    begin
      Result.Status := dbsConnectionError;
      Result.ErrorMessage := E.ClassName + ': ' + E.Message;
    end;
  end;
end;

end.
