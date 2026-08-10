{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasComparacionCopias                                      }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Caracteriza la comparación en flujo sin modificar los datos leídos.       }
{******************************************************************************}
unit PruebasComparacionCopias;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasComparacionCopias = class
  public
    [Test]
    procedure TablaVacia_NoGeneraCambios;
    [Test]
    procedure Diferencias_GeneranInsertUpdateDelete;
    [Test]
    procedure LoteGrande_ProcesaTodasLasFilasSinModificarOrigen;
    [Test]
    procedure EntradaSinClave_PropagaErrorDeCampo;
    [Test]
    procedure Cancelacion_DetieneElFlujoSinModificarOrigen;
  end;

implementation

uses
  System.Classes,
  System.StrUtils,
  System.SysUtils,
  Data.DB,
  Datasnap.DBClient,
  Backup.Types,
  Core_Engine,
  Core_Interfaces,
  Providers_MySQL_Helpers,
  ScriptWriters;

type
  TFilaComparacionPrueba = record
    Id: Integer;
    Nombre: string;
  end;

  TLectorComparacionPrueba = class(
    TInterfacedObject,
    ILectorEsquemaBBDD,
    ILectorObjetosBBDD,
    ILectorDatosBBDD)
  private
    FFilas: TArray<TFilaComparacionPrueba>;
    FTieneCampoClave: Boolean;
    function CrearDataSet(const AFilter: string): TDataSet;
    function CoincideFiltro(
      const AFila: TFilaComparacionPrueba;
      const AFilter: string): Boolean;
  public
    constructor Create(
      const AFilas: TArray<TFilaComparacionPrueba>;
      ATieneCampoClave: Boolean = True);
    function GetDatabaseName: string;
    function GetTables: TStringList;
    function GetTableStructure(const TableName: string): TTableInfo;
    function GetTableIndexes(
      const TableName: string): TArray<TIndexInfo>;
    function GetViews: TStringList;
    function GetViewDefinition(const ViewName: string): string;
    function GetTriggers: TArray<TTriggerInfo>;
    function GetTriggerDefinition(const TriggerName: string): string;
    function GetProcedures: TStringList;
    function GetProcedureDefinition(const ProcedureName: string): string;
    function GetFunctions: TStringList;
    function GetFunctionDefinition(const FunctionName: string): string;
    function GetData(
      const TableName: string;
      const Filter: string = ''): TDataSet;
    function GetRowCount(
      const TableName: string;
      const Filter: string = ''): Integer;
    function NumeroFilas: Integer;
    function NombreFila(AIndice: Integer): string;
  end;

  TCanceladorComparacionPrueba = class
  private
    FComprobaciones: Integer;
    FLimite: Integer;
  public
    constructor Create(ALimite: Integer);
    procedure Comprobar;
    property Comprobaciones: Integer read FComprobaciones;
  end;

function CrearFila(
  AId: Integer;
  const ANombre: string): TFilaComparacionPrueba;
begin
  Result.Id := AId;
  Result.Nombre := ANombre;
end;

function CrearLote(AFilas: Integer): TArray<TFilaComparacionPrueba>;
var
  i: Integer;
begin
  SetLength(Result, AFilas);
  for i := 0 to AFilas - 1 do
  begin
    Result[i] := CrearFila(i + 1, 'Fila ' + IntToStr(i + 1));
  end;
end;

function ContarTexto(
  const ATexto, AFragmento: string): Integer;
var
  iPosicion: Integer;
begin
  Result := 0;
  iPosicion := Pos(AFragmento, ATexto);
  while iPosicion > 0 do
  begin
    Inc(Result);
    iPosicion := PosEx(
      AFragmento,
      ATexto,
      iPosicion + Length(AFragmento));
  end;
end;

function CrearServiciosLectura(
  ALector: TLectorComparacionPrueba): TServiciosLecturaBBDD;
begin
  Result := Default(TServiciosLecturaBBDD);
  Result.Esquema := ALector;
  Result.Objetos := ALector;
  Result.Datos := ALector;
end;

function EjecutarComparacion(
  AOrigen, ADestino: TLectorComparacionPrueba;
  ANoEliminar: Boolean;
  AComprobarCancelacion: TThreadMethod = nil): string;
var
  oComparador: TDBComparerEngine;
  oExcluidas: TStringList;
  oIncluidas: TStringList;
  oOpciones: TComparerOptions;
  oSql: TServiciosSqlBBDD;
  oWriter: IScriptWriter;
begin
  oIncluidas := TStringList.Create;
  try
    oExcluidas := TStringList.Create;
    try
      oOpciones := Default(TComparerOptions);
      oOpciones.IncludeTables := oIncluidas;
      oOpciones.ExcludeTables := oExcluidas;
      oOpciones.WithDataDiff := True;
      oOpciones.NoDelete := ANoEliminar;
      oSql := CrearServiciosSqlMySQL;
      oWriter := TScriptWriter.Create;
      oComparador := TDBComparerEngine.Create(
        CrearServiciosLectura(AOrigen),
        CrearServiciosLectura(ADestino),
        oWriter,
        oSql,
        oOpciones);
      try
        oComparador.OnComprobarCancelacion := AComprobarCancelacion;
        oComparador.GenerateScript;
        Result := oWriter.GetScript;
      finally
        FreeAndNil(oComparador);
      end;
    finally
      FreeAndNil(oExcluidas);
    end;
  finally
    FreeAndNil(oIncluidas);
  end;
end;

constructor TLectorComparacionPrueba.Create(
  const AFilas: TArray<TFilaComparacionPrueba>;
  ATieneCampoClave: Boolean);
begin
  inherited Create;
  FFilas := Copy(AFilas);
  FTieneCampoClave := ATieneCampoClave;
end;

function TLectorComparacionPrueba.CoincideFiltro(
  const AFila: TFilaComparacionPrueba;
  const AFilter: string): Boolean;
var
  iIgual: Integer;
  iValor: Integer;
begin
  Result := AFilter = '';
  if not Result then
  begin
    iIgual := LastDelimiter('=', AFilter);
    iValor := StrToIntDef(Trim(Copy(AFilter, iIgual + 1, MaxInt)), -1);
    Result := AFila.Id = iValor;
  end;
end;

function TLectorComparacionPrueba.CrearDataSet(
  const AFilter: string): TDataSet;
var
  cdsDatos: TClientDataSet;
  oFila: TFilaComparacionPrueba;
begin
  cdsDatos := TClientDataSet.Create(nil);
  if FTieneCampoClave then
  begin
    cdsDatos.FieldDefs.Add('ID', ftInteger);
  end;
  cdsDatos.FieldDefs.Add('NOMBRE', ftString, 80);
  cdsDatos.CreateDataSet;
  for oFila in FFilas do
  begin
    if CoincideFiltro(oFila, AFilter) then
    begin
      cdsDatos.Append;
      if FTieneCampoClave then
      begin
        cdsDatos.FieldByName('ID').AsInteger := oFila.Id;
      end;
      cdsDatos.FieldByName('NOMBRE').AsString := oFila.Nombre;
      cdsDatos.Post;
    end;
  end;
  cdsDatos.First;
  Result := cdsDatos;
end;

function TLectorComparacionPrueba.GetDatabaseName: string;
begin
  Result := 'PRUEBAS';
end;

function TLectorComparacionPrueba.GetTables: TStringList;
begin
  Result := TStringList.Create;
  Result.Add('PRUEBA');
end;

function TLectorComparacionPrueba.GetTableStructure(
  const TableName: string): TTableInfo;
var
  oColumna: TColumnInfo;
begin
  Result := TTableInfo.Create;
  Result.TableName := TableName;
  oColumna := Default(TColumnInfo);
  oColumna.ColumnName := 'ID';
  oColumna.DataType := 'INT';
  oColumna.IsNullable := 'NO';
  oColumna.ColumnKey := 'PRI';
  Result.Columns.Add(oColumna);
  oColumna := Default(TColumnInfo);
  oColumna.ColumnName := 'NOMBRE';
  oColumna.DataType := 'VARCHAR';
  oColumna.IsNullable := 'YES';
  oColumna.CharMaxLength := '80';
  Result.Columns.Add(oColumna);
end;

function TLectorComparacionPrueba.GetTableIndexes(
  const TableName: string): TArray<TIndexInfo>;
begin
  Result := nil;
end;

function TLectorComparacionPrueba.GetViews: TStringList;
begin
  Result := TStringList.Create;
end;

function TLectorComparacionPrueba.GetViewDefinition(
  const ViewName: string): string;
begin
  Result := '';
end;

function TLectorComparacionPrueba.GetTriggers: TArray<TTriggerInfo>;
begin
  Result := nil;
end;

function TLectorComparacionPrueba.GetTriggerDefinition(
  const TriggerName: string): string;
begin
  Result := '';
end;

function TLectorComparacionPrueba.GetProcedures: TStringList;
begin
  Result := TStringList.Create;
end;

function TLectorComparacionPrueba.GetProcedureDefinition(
  const ProcedureName: string): string;
begin
  Result := '';
end;

function TLectorComparacionPrueba.GetFunctions: TStringList;
begin
  Result := TStringList.Create;
end;

function TLectorComparacionPrueba.GetFunctionDefinition(
  const FunctionName: string): string;
begin
  Result := '';
end;

function TLectorComparacionPrueba.GetData(
  const TableName, Filter: string): TDataSet;
begin
  Result := CrearDataSet(Filter);
end;

function TLectorComparacionPrueba.GetRowCount(
  const TableName, Filter: string): Integer;
var
  oFila: TFilaComparacionPrueba;
begin
  Result := 0;
  for oFila in FFilas do
  begin
    if CoincideFiltro(oFila, Filter) then
    begin
      Inc(Result);
    end;
  end;
end;

function TLectorComparacionPrueba.NumeroFilas: Integer;
begin
  Result := Length(FFilas);
end;

function TLectorComparacionPrueba.NombreFila(AIndice: Integer): string;
begin
  Result := FFilas[AIndice].Nombre;
end;

procedure TPruebasComparacionCopias.TablaVacia_NoGeneraCambios;
var
  oDestino: TLectorComparacionPrueba;
  oOrigen: TLectorComparacionPrueba;
  sScript: string;
begin
  oOrigen := TLectorComparacionPrueba.Create(nil);
  oDestino := TLectorComparacionPrueba.Create(nil);
  sScript := EjecutarComparacion(oOrigen, oDestino, False);
  Assert.Contains(sScript, 'Sincronizar datos de: PRUEBA');
  Assert.AreEqual(0, ContarTexto(sScript, 'Insertar registro'));
  Assert.AreEqual(0, ContarTexto(sScript, 'Actualizar registro'));
  Assert.AreEqual(0, ContarTexto(sScript, 'Eliminar registro'));
end;

procedure TPruebasComparacionCopias.
  Diferencias_GeneranInsertUpdateDelete;
var
  aDestino: TArray<TFilaComparacionPrueba>;
  aOrigen: TArray<TFilaComparacionPrueba>;
  oDestino: TLectorComparacionPrueba;
  oOrigen: TLectorComparacionPrueba;
  oRetencionDestino: ILectorDatosBBDD;
  oRetencionOrigen: ILectorDatosBBDD;
  sScript: string;
begin
  aOrigen := [
    CrearFila(1, 'Sin cambios'),
    CrearFila(2, 'Nueva'),
    CrearFila(3, 'Modificada')];
  aDestino := [
    CrearFila(1, 'Sin cambios'),
    CrearFila(3, 'Anterior'),
    CrearFila(4, 'Obsoleta')];
  oOrigen := TLectorComparacionPrueba.Create(aOrigen);
  oDestino := TLectorComparacionPrueba.Create(aDestino);
  oRetencionOrigen := oOrigen;
  oRetencionDestino := oDestino;
  sScript := EjecutarComparacion(oOrigen, oDestino, False);
  Assert.AreEqual(1, ContarTexto(sScript, 'Insertar registro'));
  Assert.AreEqual(1, ContarTexto(sScript, 'Actualizar registro'));
  Assert.AreEqual(1, ContarTexto(sScript, 'Eliminar registro'));
  Assert.Contains(sScript, '`ID` = 2');
  Assert.Contains(sScript, '`ID` = 3');
  Assert.Contains(sScript, '`ID` = 4');
  Assert.AreEqual('Modificada', oOrigen.NombreFila(2));
  Assert.AreEqual('Anterior', oDestino.NombreFila(1));
  Assert.IsTrue(Assigned(oRetencionOrigen));
  Assert.IsTrue(Assigned(oRetencionDestino));
end;

procedure TPruebasComparacionCopias.
  LoteGrande_ProcesaTodasLasFilasSinModificarOrigen;
const
  FILAS_LOTE = 2000;
var
  aOrigen: TArray<TFilaComparacionPrueba>;
  oDestino: TLectorComparacionPrueba;
  oOrigen: TLectorComparacionPrueba;
  oRetencionOrigen: ILectorDatosBBDD;
  sScript: string;
begin
  aOrigen := CrearLote(FILAS_LOTE);
  oOrigen := TLectorComparacionPrueba.Create(aOrigen);
  oDestino := TLectorComparacionPrueba.Create(nil);
  oRetencionOrigen := oOrigen;
  sScript := EjecutarComparacion(oOrigen, oDestino, True);
  Assert.AreEqual(
    FILAS_LOTE,
    ContarTexto(sScript, 'Insertar registro'));
  Assert.AreEqual(FILAS_LOTE, oOrigen.NumeroFilas);
  Assert.AreEqual('Fila 1', oOrigen.NombreFila(0));
  Assert.AreEqual('Fila 2000', oOrigen.NombreFila(FILAS_LOTE - 1));
  Assert.IsTrue(Assigned(oRetencionOrigen));
end;

constructor TCanceladorComparacionPrueba.Create(ALimite: Integer);
begin
  inherited Create;
  FLimite := ALimite;
end;

procedure TCanceladorComparacionPrueba.Comprobar;
begin
  Inc(FComprobaciones);
  if FComprobaciones >= FLimite then
  begin
    raise EAbort.Create('Comparación cancelada por la prueba');
  end;
end;

procedure TPruebasComparacionCopias.EntradaSinClave_PropagaErrorDeCampo;
var
  bErrorCampo: Boolean;
  oDestino: TLectorComparacionPrueba;
  oOrigen: TLectorComparacionPrueba;
begin
  oOrigen := TLectorComparacionPrueba.Create(
    [CrearFila(1, 'Inválida')],
    False);
  oDestino := TLectorComparacionPrueba.Create(nil);
  bErrorCampo := False;
  try
    EjecutarComparacion(oOrigen, oDestino, True);
  except
    on E: EDatabaseError do
    begin
      bErrorCampo := Pos('ID', UpperCase(E.Message)) > 0;
    end;
  end;
  Assert.IsTrue(bErrorCampo);
end;

procedure TPruebasComparacionCopias.
  Cancelacion_DetieneElFlujoSinModificarOrigen;
var
  aOrigen: TArray<TFilaComparacionPrueba>;
  bCancelada: Boolean;
  oCancelador: TCanceladorComparacionPrueba;
  oDestino: TLectorComparacionPrueba;
  oOrigen: TLectorComparacionPrueba;
  oRetencionOrigen: ILectorDatosBBDD;
begin
  aOrigen := CrearLote(20);
  oOrigen := TLectorComparacionPrueba.Create(aOrigen);
  oRetencionOrigen := oOrigen;
  oDestino := TLectorComparacionPrueba.Create(nil);
  oCancelador := TCanceladorComparacionPrueba.Create(5);
  try
    bCancelada := False;
    try
      EjecutarComparacion(
        oOrigen,
        oDestino,
        True,
        oCancelador.Comprobar);
    except
      on E: EAbort do
      begin
        bCancelada := True;
      end;
    end;
    Assert.IsTrue(bCancelada);
    Assert.AreEqual(5, oCancelador.Comprobaciones);
    Assert.AreEqual(20, oOrigen.NumeroFilas);
    Assert.AreEqual('Fila 1', oOrigen.NombreFila(0));
    Assert.IsTrue(Assigned(oRetencionOrigen));
  finally
    FreeAndNil(oCancelador);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasComparacionCopias);

end.
