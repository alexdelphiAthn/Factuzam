{******************************************************************************}
{                                                                              }
{  Módulo:       UMigCatalogo                                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Catálogo extensible y grafo de dependencias de las migraciones.           }
{******************************************************************************}
unit UMigCatalogo;

interface

uses
  System.Generics.Collections, UMigContratos;

procedure RegistrarMigracion(
  const AMigracion: IMigracion); overload;
procedure RegistrarMigracion(
  const sCodigo, sNombre, sDescripcion: string;
  const aDependencias: array of string;
  const AProcedimiento: TMigProc;
  bIndependiente: Boolean = False); overload;

function CrearCatalogoMigraciones: TList<IMigracion>;
function BuscarMigracion(
  AItems: TList<IMigracion>;
  const sCodigo: string): IMigracion;
function NivelMigracion(
  AItems: TList<IMigracion>;
  const sCodigo: string): Integer;
function NivelMaximoMigraciones(
  AItems: TList<IMigracion>): Integer;

implementation

uses
  System.SysUtils, System.Classes;

type
  TMigracionProcedimiento = class(
    TInterfacedObject,
    IMigracion)
  private
    FCodigo: string;
    FNombre: string;
    FDescripcion: string;
    FDependencias: TArray<string>;
    FProcedimiento: TMigProc;
    FIndependiente: Boolean;
  public
    constructor Create(
      const sCodigo, sNombre, sDescripcion: string;
      const aDependencias: array of string;
      const AProcedimiento: TMigProc;
      bIndependiente: Boolean);
    function Codigo: string;
    function Nombre: string;
    function Descripcion: string;
    function Dependencias: TArray<string>;
    function EsIndependiente: Boolean;
    procedure Ejecutar(
      const AContexto: IContextoMigracion;
      var AEstadisticas: TMigStats);
  end;

var
  GMigraciones: TList<IMigracion>;

constructor TMigracionProcedimiento.Create(
  const sCodigo, sNombre, sDescripcion: string;
  const aDependencias: array of string;
  const AProcedimiento: TMigProc;
  bIndependiente: Boolean);
var
  i: Integer;
begin
  inherited Create;
  FCodigo := sCodigo;
  FNombre := sNombre;
  FDescripcion := sDescripcion;
  SetLength(FDependencias, Length(aDependencias));
  for i := Low(aDependencias) to High(aDependencias) do
    FDependencias[i] := aDependencias[i];
  FProcedimiento := AProcedimiento;
  FIndependiente := bIndependiente;
end;

function TMigracionProcedimiento.Codigo: string;
begin
  Result := FCodigo;
end;

function TMigracionProcedimiento.Nombre: string;
begin
  Result := FNombre;
end;

function TMigracionProcedimiento.Descripcion: string;
begin
  Result := FDescripcion;
end;

function TMigracionProcedimiento.Dependencias: TArray<string>;
begin
  Result := Copy(FDependencias);
end;

function TMigracionProcedimiento.EsIndependiente: Boolean;
begin
  Result := FIndependiente;
end;

procedure TMigracionProcedimiento.Ejecutar(
  const AContexto: IContextoMigracion;
  var AEstadisticas: TMigStats);
begin
  FProcedimiento(AContexto, AEstadisticas);
end;

procedure RegistrarMigracion(
  const AMigracion: IMigracion);
begin
  if not Assigned(AMigracion) then
  begin
    raise EArgumentNilException.Create('AMigracion');
  end;
  if not Assigned(GMigraciones) then
    GMigraciones := TList<IMigracion>.Create;
  if Assigned(BuscarMigracion(GMigraciones, AMigracion.Codigo)) then
  begin
    raise EInvalidOpException.CreateFmt(
      'La migración "%s" ya está registrada.',
      [AMigracion.Codigo]);
  end;
  GMigraciones.Add(AMigracion);
end;

procedure RegistrarMigracion(
  const sCodigo, sNombre, sDescripcion: string;
  const aDependencias: array of string;
  const AProcedimiento: TMigProc;
  bIndependiente: Boolean);
begin
  RegistrarMigracion(
    TMigracionProcedimiento.Create(
      sCodigo,
      sNombre,
      sDescripcion,
      aDependencias,
      AProcedimiento,
      bIndependiente) as IMigracion);
end;

function CrearCatalogoMigraciones: TList<IMigracion>;
var
  Migracion: IMigracion;
begin
  Result := TList<IMigracion>.Create;
  if Assigned(GMigraciones) then
  begin
    for Migracion in GMigraciones do
      Result.Add(Migracion);
  end;
end;

function BuscarMigracion(
  AItems: TList<IMigracion>;
  const sCodigo: string): IMigracion;
var
  Migracion: IMigracion;
begin
  Result := nil;
  if Assigned(AItems) then
  begin
    for Migracion in AItems do
    begin
      if SameText(Migracion.Codigo, sCodigo) then
      begin
        Result := Migracion;
        Break;
      end;
    end;
  end;
end;

function CalcularNivel(
  AItems: TList<IMigracion>;
  const sCodigo: string;
  AVisitando: TStringList;
  ACalculados: TStringList): Integer;
var
  Migracion: IMigracion;
  Dependencias: TArray<string>;
  Dependencia: string;
  iNivel: Integer;
  iNivelDependencia: Integer;
  iIndice: Integer;
begin
  iIndice := ACalculados.IndexOfName(sCodigo);
  if iIndice >= 0 then
  begin
    Result := StrToIntDef(ACalculados.ValueFromIndex[iIndice], 0);
  end
  else
  begin
    if AVisitando.IndexOf(sCodigo) >= 0 then
    begin
      raise EInvalidOpException.CreateFmt(
        'Dependencia circular detectada en "%s".',
        [sCodigo]);
    end;
    Migracion := BuscarMigracion(AItems, sCodigo);
    if not Assigned(Migracion) then
    begin
      raise EInvalidOpException.CreateFmt(
        'No existe la migración requerida "%s".',
        [sCodigo]);
    end;
    AVisitando.Add(sCodigo);
    iNivel := 0;
    Dependencias := Migracion.Dependencias;
    for Dependencia in Dependencias do
    begin
      iNivelDependencia := CalcularNivel(
        AItems,
        Dependencia,
        AVisitando,
        ACalculados) + 1;
      if iNivelDependencia > iNivel then
        iNivel := iNivelDependencia;
    end;
    AVisitando.Delete(AVisitando.IndexOf(sCodigo));
    ACalculados.Values[sCodigo] := IntToStr(iNivel);
    Result := iNivel;
  end;
end;

function NivelMigracion(
  AItems: TList<IMigracion>;
  const sCodigo: string): Integer;
var
  Visitando: TStringList;
  Calculados: TStringList;
begin
  Visitando := TStringList.Create;
  Calculados := TStringList.Create;
  try
    Visitando.CaseSensitive := False;
    Calculados.CaseSensitive := False;
    Result := CalcularNivel(
      AItems,
      sCodigo,
      Visitando,
      Calculados);
  finally
    FreeAndNil(Calculados);
    FreeAndNil(Visitando);
  end;
end;

function NivelMaximoMigraciones(
  AItems: TList<IMigracion>): Integer;
var
  Migracion: IMigracion;
  iNivel: Integer;
begin
  Result := 0;
  for Migracion in AItems do
  begin
    if not Migracion.EsIndependiente then
    begin
      iNivel := NivelMigracion(AItems, Migracion.Codigo);
      if iNivel > Result then
        Result := iNivel;
    end;
  end;
end;

initialization
  GMigraciones := TList<IMigracion>.Create;

finalization
  FreeAndNil(GMigraciones);

end.
