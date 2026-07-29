{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTraducciones                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Catálogo de traducciones cargado desde fza_traducciones.                  }
{******************************************************************************}
unit inLibTraducciones;

interface

uses
  System.Classes, System.Generics.Collections, System.SyncObjs,
  inLibConexionesIntf, inLibTraduccionesIntf;

type
  TServicioTraducciones = class(
    TInterfacedObject,
    IServicioTraducciones
  )
  private
    FBloqueo: TCriticalSection;
    FConexiones: IServicioConexiones;
    FIdioma: string;
    FIdiomaBase: string;
    FTextos: TDictionary<string, string>;
    FCacheCargada: Boolean;
    function GetIdioma: string;
    function NormalizarIdioma(const AIdioma: string): string;
    function PseudoTraducir(const ATexto: string): string;
    procedure AsegurarCache;
    procedure CargarCache;
    procedure AplicarComponente(
      ARaiz, AComponente: TComponent);
    procedure AplicarPropiedad(
      ARaiz, AComponente: TComponent;
      const APropiedad: string);
  public
    constructor Create(
      const AConexiones: IServicioConexiones;
      const AIdioma: string = IDIOMA_ESPANOL;
      const AIdiomaBase: string = IDIOMA_ESPANOL);
    destructor Destroy; override;
    procedure EstablecerIdioma(const AIdioma: string);
    procedure Recargar;
    function Traducir(
      const AClave, ATextoPredeterminado: string): string;
    procedure Aplicar(AComponente: TComponent);
  end;

function ClaveTraduccionComponente(
  ARaiz, AComponente: TComponent;
  const APropiedad: string): string;
function ResolverServicioTraducciones(
  AOwner: TComponent): IServicioTraducciones;
procedure AplicarTraducciones(
  AComponente, AOwner: TComponent);

implementation

uses
  System.SysUtils, System.TypInfo, Uni, Vcl.Forms, inLibLog;

const
  PROPIEDADES_TRADUCIBLES: array[0..3] of string = (
    'Caption',
    'Hint',
    'Title',
    'DisplayName'
  );

constructor TServicioTraducciones.Create(
  const AConexiones: IServicioConexiones;
  const AIdioma, AIdiomaBase: string);
begin
  inherited Create;
  FBloqueo := TCriticalSection.Create;
  FTextos := TDictionary<string, string>.Create;
  FConexiones := AConexiones;
  FIdiomaBase := NormalizarIdioma(AIdiomaBase);
  FIdioma := NormalizarIdioma(AIdioma);
  FCacheCargada := False;
end;

destructor TServicioTraducciones.Destroy;
begin
  FConexiones := nil;
  FreeAndNil(FTextos);
  FreeAndNil(FBloqueo);
  inherited;
end;

function TServicioTraducciones.NormalizarIdioma(
  const AIdioma: string): string;
begin
  Result := Trim(AIdioma);
  if Result = '' then
    Result := IDIOMA_ESPANOL;
  Result := StringReplace(Result, '_', '-', [rfReplaceAll]);
end;

function TServicioTraducciones.GetIdioma: string;
begin
  FBloqueo.Acquire;
  try
    Result := FIdioma;
  finally
    FBloqueo.Release;
  end;
end;

procedure TServicioTraducciones.EstablecerIdioma(
  const AIdioma: string);
var
  IdiomaNormalizado: string;
begin
  IdiomaNormalizado := NormalizarIdioma(AIdioma);
  FBloqueo.Acquire;
  try
    if not SameText(FIdioma, IdiomaNormalizado) then
    begin
      FIdioma := IdiomaNormalizado;
      FTextos.Clear;
      FCacheCargada := False;
    end;
  finally
    FBloqueo.Release;
  end;
end;

procedure TServicioTraducciones.Recargar;
begin
  FBloqueo.Acquire;
  try
    FTextos.Clear;
    FCacheCargada := False;
  finally
    FBloqueo.Release;
  end;
end;

procedure TServicioTraducciones.AsegurarCache;
begin
  if not FCacheCargada then
  begin
    try
      CargarCache;
    except
      on E: Exception do
      begin
        FTextos.Clear;
        FCacheCargada := True;
        if Assigned(Log) then
          Log.LogWarning(
            'No se pudo cargar el catálogo de traducciones: ' +
            E.ClassName + ': ' + E.Message);
      end;
    end;
  end;
end;

procedure TServicioTraducciones.CargarCache;
var
  Conexion: TUniConnection;
  Consulta: TUniQuery;
  Clave: string;
begin
  FTextos.Clear;
  FCacheCargada := True;
  Conexion := nil;
  Consulta := nil;
  if Assigned(FConexiones) and FConexiones.Disponible then
  begin
    try
      Conexion := FConexiones.CrearConexion(nil, uctPrecarga);
      Consulta := TUniQuery.Create(nil);
      Consulta.Connection := Conexion;
      Consulta.SQL.Text :=
        'SELECT CLAVE_TRAD, TEXTO_TRAD ' +
        '  FROM fza_traducciones ' +
        ' WHERE ESACTIVO_TRAD = ''S'' ' +
        '   AND (IDIOMA_TRAD = :idioma ' +
        '        OR IDIOMA_TRAD = :idioma_base) ' +
        ' ORDER BY CASE WHEN IDIOMA_TRAD = :idioma_base ' +
        '               THEN 1 ELSE 2 END';
      Consulta.ParamByName('idioma').AsString := FIdioma;
      Consulta.ParamByName('idioma_base').AsString := FIdiomaBase;
      Consulta.Open;
      while not Consulta.Eof do
      begin
        Clave := LowerCase(
          Trim(Consulta.FieldByName('CLAVE_TRAD').AsString));
        if Clave <> '' then
          FTextos.AddOrSetValue(
            Clave,
            Consulta.FieldByName('TEXTO_TRAD').AsString);
        Consulta.Next;
      end;
      if Assigned(Log) then
        Log.LogInfo(
          Format(
            'Catálogo de traducciones cargado: idioma=%s, textos=%d',
            [FIdioma, FTextos.Count]));
    finally
      FreeAndNil(Consulta);
      FreeAndNil(Conexion);
    end;
  end;
end;

function TServicioTraducciones.PseudoTraducir(
  const ATexto: string): string;
var
  Relleno: Integer;
begin
  Result := ATexto;
  if (ATexto <> '') and
     (Copy(ATexto, 1, 4) <> '[!! ') then
  begin
    Relleno := Length(ATexto) div 3;
    if Relleno < 4 then
      Relleno := 4;
    Result := '[!! ' + ATexto + ' ' +
      StringOfChar('~', Relleno) + ' !!]';
  end;
end;

function TServicioTraducciones.Traducir(
  const AClave, ATextoPredeterminado: string): string;
begin
  Result := ATextoPredeterminado;
  FBloqueo.Acquire;
  try
    if SameText(FIdioma, IDIOMA_PSEUDO) then
      Result := PseudoTraducir(ATextoPredeterminado)
    else
    begin
      AsegurarCache;
      FTextos.TryGetValue(LowerCase(Trim(AClave)), Result);
      if Result = '' then
        Result := ATextoPredeterminado;
    end;
  finally
    FBloqueo.Release;
  end;
end;

procedure TServicioTraducciones.AplicarPropiedad(
  ARaiz, AComponente: TComponent;
  const APropiedad: string);
var
  Clave: string;
  InfoPropiedad: PPropInfo;
  TextoOriginal: string;
  TextoTraducido: string;
begin
  InfoPropiedad := GetPropInfo(
    AComponente.ClassInfo,
    APropiedad);
  if Assigned(InfoPropiedad) and
     Assigned(InfoPropiedad.SetProc) and
     (InfoPropiedad.PropType^.Kind in
       [tkString, tkLString, tkWString, tkUString]) then
  begin
    Clave := ClaveTraduccionComponente(
      ARaiz,
      AComponente,
      APropiedad);
    TextoOriginal := GetStrProp(
      AComponente,
      InfoPropiedad);
    TextoTraducido := Traducir(
      Clave,
      TextoOriginal);
    if TextoTraducido <> TextoOriginal then
      SetStrProp(
        AComponente,
        InfoPropiedad,
        TextoTraducido);
  end;
end;

procedure TServicioTraducciones.AplicarComponente(
  ARaiz, AComponente: TComponent);
var
  i: Integer;
  Propiedad: string;
begin
  if (AComponente = ARaiz) or
     (AComponente.Name <> '') then
    for Propiedad in PROPIEDADES_TRADUCIBLES do
      AplicarPropiedad(
        ARaiz,
        AComponente,
        Propiedad);
  for i := 0 to AComponente.ComponentCount - 1 do
    AplicarComponente(
      ARaiz,
      AComponente.Components[i]);
end;

procedure TServicioTraducciones.Aplicar(
  AComponente: TComponent);
begin
  if Assigned(AComponente) and
     not (csDesigning in AComponente.ComponentState) then
    AplicarComponente(
      AComponente,
      AComponente);
end;

function ClaveTraduccionComponente(
  ARaiz, AComponente: TComponent;
  const APropiedad: string): string;
begin
  Result := ARaiz.UnitName + '.' + ARaiz.ClassName;
  if AComponente <> ARaiz then
    Result := Result + '.' + AComponente.Name;
  Result := Result + '.' + APropiedad;
end;

function ResolverServicioTraducciones(
  AOwner: TComponent): IServicioTraducciones;
var
  Componente: TComponent;
  Proveedor: IProveedorTraducciones;
begin
  Result := nil;
  Componente := AOwner;
  while Assigned(Componente) and
        not Assigned(Result) do
  begin
    if Supports(
      Componente,
      IProveedorTraducciones,
      Proveedor) then
      Result := Proveedor.Traducciones;
    Componente := Componente.Owner;
  end;
  if not Assigned(Result) and
     Assigned(Application.MainForm) and
     Supports(
       Application.MainForm,
       IProveedorTraducciones,
       Proveedor) then
    Result := Proveedor.Traducciones;
end;

procedure AplicarTraducciones(
  AComponente, AOwner: TComponent);
var
  Servicio: IServicioTraducciones;
begin
  Servicio := ResolverServicioTraducciones(AOwner);
  if Assigned(Servicio) then
    Servicio.Aplicar(AComponente);
end;

end.
