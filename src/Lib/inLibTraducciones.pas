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
  Uni, inLibConexionesIntf, inLibTraduccionesIntf;

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
    function TraducirPropiedadJerarquia(
      ARaiz: TComponent;
      const ARuta, APropiedad, ATextoPredeterminado: string): string;
    procedure AsegurarCache;
    procedure CargarCache;
    procedure AplicarComponente(
      ARaiz, AComponente: TComponent;
      AVisitados: TDictionary<TObject, Byte>);
    procedure AplicarColeccion(
      ARaiz: TComponent;
      AColeccion: TCollection;
      const ARuta: string;
      AVisitados: TDictionary<TObject, Byte>);
    procedure AplicarObjeto(
      ARaiz: TComponent;
      AObjeto: TObject;
      const ARuta: string;
      AVisitados: TDictionary<TObject, Byte>);
    procedure AplicarPropiedadObjeto(
      ARaiz: TComponent;
      AObjeto: TObject;
      const ARuta, APropiedad: string);
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
function ObtenerIdiomaConfigurado(
  AConexion: TUniConnection;
  const AUsuario: string): string;
function ResolverServicioTraducciones(
  AOwner: TComponent): IServicioTraducciones;
procedure AplicarTraducciones(
  AComponente, AOwner: TComponent);

implementation

uses
  System.SysUtils, System.TypInfo, Vcl.Forms, inLibLog;

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
        if Log() <> nil then
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
      if Log() <> nil then
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

function TServicioTraducciones.TraducirPropiedadJerarquia(
  ARaiz: TComponent;
  const ARuta, APropiedad, ATextoPredeterminado: string): string;
var
  Clave: string;
  ClaseRaiz: TClass;
  Encontrado: Boolean;
begin
  Result := ATextoPredeterminado;
  FBloqueo.Acquire;
  try
    if SameText(FIdioma, IDIOMA_PSEUDO) then
      Result := PseudoTraducir(ATextoPredeterminado)
    else
    begin
      AsegurarCache;
      Encontrado := False;
      ClaseRaiz := ARaiz.ClassType;
      while Assigned(ClaseRaiz) and
            ClaseRaiz.InheritsFrom(TComponent) and
            not Encontrado do
      begin
        Clave := ClaseRaiz.UnitName + '.' + ClaseRaiz.ClassName;
        if ARuta <> '' then
          Clave := Clave + '.' + ARuta;
        Clave := Clave + '.' + APropiedad;
        Encontrado := FTextos.TryGetValue(
          LowerCase(Trim(Clave)),
          Result);
        if not Encontrado then
          ClaseRaiz := ClaseRaiz.ClassParent;
      end;
      if not Encontrado or
         (Result = '') then
        Result := ATextoPredeterminado;
    end;
  finally
    FBloqueo.Release;
  end;
end;

procedure TServicioTraducciones.AplicarPropiedadObjeto(
  ARaiz: TComponent;
  AObjeto: TObject;
  const ARuta, APropiedad: string);
var
  InfoPropiedad: PPropInfo;
  TextoOriginal: string;
  TextoTraducido: string;
begin
  InfoPropiedad := GetPropInfo(
    AObjeto.ClassInfo,
    APropiedad);
  if Assigned(InfoPropiedad) and
     Assigned(InfoPropiedad.SetProc) and
     (InfoPropiedad.PropType^.Kind in
       [tkString, tkLString, tkWString, tkUString]) then
  begin
    TextoOriginal := GetStrProp(
      AObjeto,
      InfoPropiedad);
    TextoTraducido := TraducirPropiedadJerarquia(
      ARaiz,
      ARuta,
      APropiedad,
      TextoOriginal);
    if TextoTraducido <> TextoOriginal then
      SetStrProp(
        AObjeto,
        InfoPropiedad,
        TextoTraducido);
  end;
end;

procedure TServicioTraducciones.AplicarColeccion(
  ARaiz: TComponent;
  AColeccion: TCollection;
  const ARuta: string;
  AVisitados: TDictionary<TObject, Byte>);
var
  i: Integer;
begin
  for i := 0 to AColeccion.Count - 1 do
    AplicarObjeto(
      ARaiz,
      AColeccion.Items[i],
      ARuta + '[' + IntToStr(i) + ']',
      AVisitados);
end;

procedure TServicioTraducciones.AplicarObjeto(
  ARaiz: TComponent;
  AObjeto: TObject;
  const ARuta: string;
  AVisitados: TDictionary<TObject, Byte>);
var
  i: Integer;
  InfoPropiedad: PPropInfo;
  ListaPropiedades: PPropList;
  NumeroPropiedades: Integer;
  ObjetoPropiedad: TObject;
  Propiedad: string;
  RutaPropiedad: string;
begin
  if Assigned(AObjeto) and
     not AVisitados.ContainsKey(AObjeto) then
  begin
    AVisitados.Add(AObjeto, 0);
    for Propiedad in PROPIEDADES_TRADUCIBLES do
      AplicarPropiedadObjeto(
        ARaiz,
        AObjeto,
        ARuta,
        Propiedad);
    NumeroPropiedades := GetPropList(
      AObjeto.ClassInfo,
      [tkClass],
      nil);
    if NumeroPropiedades > 0 then
    begin
      GetMem(
        ListaPropiedades,
        NumeroPropiedades * SizeOf(Pointer));
      try
        GetPropList(
          AObjeto.ClassInfo,
          [tkClass],
          ListaPropiedades);
        for i := 0 to NumeroPropiedades - 1 do
        begin
          InfoPropiedad := ListaPropiedades^[i];
          if Assigned(InfoPropiedad.GetProc) then
          begin
            ObjetoPropiedad := GetObjectProp(
              AObjeto,
              InfoPropiedad);
            RutaPropiedad := ARuta;
            if RutaPropiedad <> '' then
              RutaPropiedad := RutaPropiedad + '.';
            RutaPropiedad := RutaPropiedad +
              string(InfoPropiedad.Name);
            if ObjetoPropiedad is TCollection then
              AplicarColeccion(
                ARaiz,
                TCollection(ObjetoPropiedad),
                RutaPropiedad,
                AVisitados)
            else if (ObjetoPropiedad is TPersistent) and
                    not (ObjetoPropiedad is TComponent) then
              AplicarObjeto(
                ARaiz,
                ObjetoPropiedad,
                RutaPropiedad,
                AVisitados);
          end;
        end;
      finally
        FreeMem(ListaPropiedades);
      end;
    end;
  end;
end;

procedure TServicioTraducciones.AplicarComponente(
  ARaiz, AComponente: TComponent;
  AVisitados: TDictionary<TObject, Byte>);
var
  i: Integer;
  Ruta: string;
begin
  if (AComponente = ARaiz) or
     (AComponente.Name <> '') then
  begin
    Ruta := AComponente.Name;
    if AComponente = ARaiz then
      Ruta := '';
    AplicarObjeto(
      ARaiz,
      AComponente,
      Ruta,
      AVisitados);
  end;
  for i := 0 to AComponente.ComponentCount - 1 do
    AplicarComponente(
      ARaiz,
      AComponente.Components[i],
      AVisitados);
end;

procedure TServicioTraducciones.Aplicar(
  AComponente: TComponent);
var
  Visitados: TDictionary<TObject, Byte>;
begin
  if Assigned(AComponente) and
     not (csDesigning in AComponente.ComponentState) then
  begin
    Visitados := TDictionary<TObject, Byte>.Create;
    try
      AplicarComponente(
        AComponente,
        AComponente,
        Visitados);
    finally
      FreeAndNil(Visitados);
    end;
  end;
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

function ObtenerIdiomaConfigurado(
  AConexion: TUniConnection;
  const AUsuario: string): string;
var
  Consulta: TUniQuery;
  Idioma: string;
begin
  Result := IDIOMA_ESPANOL;
  if Assigned(AConexion) and AConexion.Connected then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      try
        Consulta.Connection := AConexion;
        Consulta.SQL.Text :=
          'SELECT P.VALUE_USUPER ' +
          '  FROM fza_usuarios_perfiles P ' +
          '  LEFT JOIN fza_usuarios U ' +
          '    ON U.USUARIO_USU = :usuario ' +
          ' WHERE P.KEY_USUPER = ''frmMtoAppParam'' ' +
          '   AND P.SUBKEY_USUPER = ''appIdioma'' ' +
          '   AND P.USUARIO_GRUPO_USUPER IN ' +
          '       (:usuario, U.GRUPO_USU, :todos) ' +
          ' ORDER BY CASE P.USUARIO_GRUPO_USUPER ' +
          '            WHEN :usuario THEN 1 ' +
          '            WHEN U.GRUPO_USU THEN 2 ' +
          '            ELSE 3 ' +
          '          END ' +
          ' LIMIT 1';
        Consulta.ParamByName('usuario').AsString := AUsuario;
        Consulta.ParamByName('todos').AsString := 'Todos';
        Consulta.Open;
        if not Consulta.Eof then
        begin
          Idioma := Trim(
            Consulta.FieldByName('VALUE_USUPER').AsString);
          if Idioma <> '' then
            Result := Idioma;
        end;
      except
        on E: Exception do
          if Log() <> nil then
            Log.LogWarning(
              'No se pudo resolver el idioma configurado: ' +
              E.ClassName + ': ' + E.Message);
      end;
    finally
      FreeAndNil(Consulta);
    end;
  end;
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
