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
  Uni, inLibConexionesIntf, inLibTraduccionesIntf, inLibLogIntf;

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
    FTextosInforme: TDictionary<string, string>;
    FCacheCargada: Boolean;
    FRegistroLog: IRegistroLog;
    function GetIdioma: string;
    function NormalizarIdioma(const AIdioma: string): string;
    function PseudoTraducir(const ATexto: string): string;
    function PseudoTraducirInforme(
      const ATexto: string): string;
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
      const AIdiomaBase: string = IDIOMA_ESPANOL); overload;
    constructor Create(
      const AConexiones: IServicioConexiones;
      const ARegistroLog: IRegistroLog;
      const AIdioma: string = IDIOMA_ESPANOL;
      const AIdiomaBase: string = IDIOMA_ESPANOL); overload;
    destructor Destroy; override;
    procedure EstablecerIdioma(const AIdioma: string);
    procedure Recargar;
    function ExisteTraduccion(
      const AClave: string): Boolean;
    function Traducir(
      const AClave, ATextoPredeterminado: string): string;
    function TraducirTextoInforme(
      const ATexto: string): string;
    procedure Aplicar(AComponente: TComponent);
  end;

function ClaveTraduccionComponente(
  ARaiz, AComponente: TComponent;
  const APropiedad: string): string;
function NormalizarIdiomaAplicacion(
  const AIdioma: string): string;
function ObtenerIdiomaConfigurado(
  AConexion: TUniConnection;
  const AUsuario: string;
  const ARegistroLog: IRegistroLog = nil): string;
function ResolverServicioTraducciones(
  AOwner: TComponent): IServicioTraducciones;
procedure ActivarTraduccionResourcestrings(
  const ATraducciones: IServicioTraducciones);
function ProtegerDocumentoVentaEspanol: IInterface;
procedure AplicarTraducciones(
  AComponente, AOwner: TComponent);

implementation

uses
  System.Character, System.SysUtils, System.TypInfo, Vcl.Forms,
  inLibRegistroResourcestringTraducciones, inLibRegistroLogNulo;

const
  PROPIEDADES_TRADUCIBLES: array[0..3] of string = (
    'Caption',
    'Hint',
    'Title',
    'DisplayName'
  );

function EsAtajoTecladoPuro(const ATexto: string): Boolean;
var
  iFuncion: Integer;
  sTexto: string;
begin
  sTexto := UpperCase(Trim(ATexto));
  Result :=
    (sTexto = 'ESC') or
    (sTexto = 'ESCAPE');
  if (not Result) and
     (Length(sTexto) >= 2) and
     (sTexto[1] = 'F') then
  begin
    Result :=
      TryStrToInt(Copy(sTexto, 2, MaxInt), iFuncion) and
      (iFuncion >= 1) and
      (iFuncion <= 12);
  end;
end;

type
  TFuncionCargaResourcestring = function(
    ARecurso: PResStringRec): string;

  TProteccionDocumentoVentaEspanol = class(TInterfacedObject)
  public
    constructor Create;
    destructor Destroy; override;
  end;

var
  BloqueoResourcestrings: TCriticalSection;
  ClavesResourcestrings: TDictionary<NativeUInt, string>;
  FuncionCargaResourcestringAnterior: TFuncionCargaResourcestring;
  ServicioResourcestrings: IServicioTraducciones;
  TraduccionResourcestringsActiva: Boolean;

threadvar
  TraduciendoResourcestring: Boolean;
  NivelDocumentoVentaEspanol: Integer;

constructor TProteccionDocumentoVentaEspanol.Create;
begin
  inherited Create;
  Inc(NivelDocumentoVentaEspanol);
end;

destructor TProteccionDocumentoVentaEspanol.Destroy;
begin
  if NivelDocumentoVentaEspanol > 0 then
    Dec(NivelDocumentoVentaEspanol);
  inherited Destroy;
end;

function CargarResourcestringPredeterminado(
  ARecurso: PResStringRec): string;
begin
  Result := '';
  if Assigned(FuncionCargaResourcestringAnterior) then
    Result := FuncionCargaResourcestringAnterior(ARecurso)
  else if Assigned(ARecurso) and
          (ARecurso.Identifier >= 64 * 1024) then
    Result := PChar(ARecurso.Identifier);
end;

function CargarResourcestringTraducido(
  ARecurso: PResStringRec): string;
var
  Clave: string;
  Servicio: IServicioTraducciones;
begin
  Result := CargarResourcestringPredeterminado(ARecurso);
  if (NivelDocumentoVentaEspanol = 0) and
     not TraduciendoResourcestring and
     Assigned(ARecurso) and
     Assigned(ClavesResourcestrings) and
     ClavesResourcestrings.TryGetValue(
       NativeUInt(ARecurso),
       Clave) then
  begin
    Servicio := nil;
    BloqueoResourcestrings.Acquire;
    try
      Servicio := ServicioResourcestrings;
    finally
      BloqueoResourcestrings.Release;
    end;
    if Assigned(Servicio) then
    begin
      TraduciendoResourcestring := True;
      try
        Result := Servicio.Traducir(
          Clave,
          Result);
      finally
        TraduciendoResourcestring := False;
      end;
    end;
  end;
end;

procedure PrepararRegistroResourcestrings;
begin
  if not Assigned(ClavesResourcestrings) then
  begin
    ClavesResourcestrings :=
      TDictionary<NativeUInt, string>.Create;
    EnumerarResourcestringsTraduccion(
      procedure(
        const AClave, AContexto: string;
        ARecurso: PResStringRec)
      begin
        ClavesResourcestrings.AddOrSetValue(
          NativeUInt(ARecurso),
          AClave);
      end);
  end;
end;

procedure ActivarTraduccionResourcestrings(
  const ATraducciones: IServicioTraducciones);
begin
  if Assigned(ATraducciones) then
  begin
    BloqueoResourcestrings.Acquire;
    try
      PrepararRegistroResourcestrings;
      ServicioResourcestrings := ATraducciones;
      if not TraduccionResourcestringsActiva then
      begin
        FuncionCargaResourcestringAnterior :=
          System.LoadResStringFunc;
        System.LoadResStringFunc :=
          CargarResourcestringTraducido;
        TraduccionResourcestringsActiva := True;
      end;
    finally
      BloqueoResourcestrings.Release;
    end;
  end;
end;

procedure DesactivarTraduccionResourcestrings;
begin
  if Assigned(BloqueoResourcestrings) then
  begin
    BloqueoResourcestrings.Acquire;
    try
      if TraduccionResourcestringsActiva then
        System.LoadResStringFunc :=
          FuncionCargaResourcestringAnterior;
      TraduccionResourcestringsActiva := False;
      ServicioResourcestrings := nil;
    finally
      BloqueoResourcestrings.Release;
    end;
  end;
end;

constructor TServicioTraducciones.Create(
  const AConexiones: IServicioConexiones;
  const AIdioma, AIdiomaBase: string);
begin
  Create(
    AConexiones,
    CrearRegistroLogNulo,
    AIdioma,
    AIdiomaBase);
end;

constructor TServicioTraducciones.Create(
  const AConexiones: IServicioConexiones;
  const ARegistroLog: IRegistroLog;
  const AIdioma, AIdiomaBase: string);
begin
  inherited Create;
  if not Assigned(ARegistroLog) then
    raise EArgumentNilException.Create('ARegistroLog');
  FRegistroLog := ARegistroLog;
  FBloqueo := TCriticalSection.Create;
  FTextos := TDictionary<string, string>.Create;
  FTextosInforme := TDictionary<string, string>.Create;
  FConexiones := AConexiones;
  FIdiomaBase := NormalizarIdioma(AIdiomaBase);
  FIdioma := NormalizarIdioma(AIdioma);
  FCacheCargada := False;
end;

destructor TServicioTraducciones.Destroy;
begin
  FRegistroLog := nil;
  FConexiones := nil;
  FreeAndNil(FTextos);
  FreeAndNil(FTextosInforme);
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

function NormalizarIdiomaAplicacion(
  const AIdioma: string): string;
begin
  Result := StringReplace(
    Trim(AIdioma),
    '_',
    '-',
    [rfReplaceAll]);
  if Result = '' then
    Result := IDIOMA_ESPANOL;
end;

function ProtegerDocumentoVentaEspanol: IInterface;
begin
  Result := TProteccionDocumentoVentaEspanol.Create;
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
      FTextosInforme.Clear;
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
    FTextosInforme.Clear;
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
        FTextosInforme.Clear;
        FCacheCargada := True;
        FRegistroLog.RegistrarAviso(
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
  TextoBase: string;
begin
  FTextos.Clear;
  FTextosInforme.Clear;
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
      if not SameText(FIdioma, FIdiomaBase) then
      begin
        // Mapa texto base -> texto traducido de los informes
        // FastReport. Lo usan los formatos personalizados, que
        // no tienen clave propia (D22-B).
        Consulta.Close;
        Consulta.SQL.Text :=
          'SELECT B.TEXTO_TRAD AS TEXTO_BASE, ' +
          '       T.TEXTO_TRAD AS TEXTO_IDIOMA ' +
          '  FROM fza_traducciones B ' +
          '  JOIN fza_traducciones T ' +
          '    ON T.CLAVE_TRAD = B.CLAVE_TRAD ' +
          '   AND T.IDIOMA_TRAD = :idioma ' +
          '   AND T.ESACTIVO_TRAD = ''S'' ' +
          ' WHERE B.IDIOMA_TRAD = :idioma_base ' +
          '   AND B.ESACTIVO_TRAD = ''S'' ' +
          '   AND B.CLAVE_TRAD LIKE ''FastReport.%'' ' +
          ' ORDER BY B.CLAVE_TRAD';
        Consulta.ParamByName('idioma').AsString := FIdioma;
        Consulta.ParamByName('idioma_base').AsString :=
          FIdiomaBase;
        Consulta.Open;
        while not Consulta.Eof do
        begin
          TextoBase :=
            Consulta.FieldByName('TEXTO_BASE').AsString;
          if (TextoBase <> '') and
             not FTextosInforme.ContainsKey(TextoBase) then
            FTextosInforme.Add(
              TextoBase,
              Consulta.FieldByName('TEXTO_IDIOMA').AsString);
          Consulta.Next;
        end;
      end;
      FRegistroLog.RegistrarInformacion(
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

function TieneTextoVisibleInforme(
  const ATexto: string): Boolean;
var
  i: Integer;
  Nivel: Integer;
begin
  // Letras fuera de corchetes: las expresiones [..] del memo
  // no cuentan como texto visible traducible.
  Result := False;
  Nivel := 0;
  for i := 1 to Length(ATexto) do
  begin
    if ATexto[i] = '[' then
      Inc(Nivel)
    else if ATexto[i] = ']' then
    begin
      if Nivel > 0 then
        Dec(Nivel);
    end
    else if (Nivel = 0) and
            ATexto[i].IsLetter then
      Result := True;
  end;
end;

function TServicioTraducciones.PseudoTraducirInforme(
  const ATexto: string): string;
var
  Relleno: Integer;
begin
  // Sin el marcador '[!! ... !!]': FastReport interpretaría los
  // corchetes como una expresión del memo. Solo se alarga.
  Result := ATexto;
  if (ATexto <> '') and
     (ATexto[Length(ATexto)] <> '~') and
     TieneTextoVisibleInforme(ATexto) then
  begin
    Relleno := Length(ATexto) div 3;
    if Relleno < 4 then
      Relleno := 4;
    if Relleno > 20 then
      Relleno := 20;
    Result := ATexto + ' ' + StringOfChar('~', Relleno);
  end;
end;

function TServicioTraducciones.ExisteTraduccion(
  const AClave: string): Boolean;
begin
  FBloqueo.Acquire;
  try
    if SameText(FIdioma, IDIOMA_PSEUDO) then
      Result := True
    else
    begin
      AsegurarCache;
      Result := FTextos.ContainsKey(
        LowerCase(Trim(AClave)));
    end;
  finally
    FBloqueo.Release;
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

function TServicioTraducciones.TraducirTextoInforme(
  const ATexto: string): string;
begin
  Result := ATexto;
  FBloqueo.Acquire;
  try
    if SameText(FIdioma, IDIOMA_PSEUDO) then
      Result := PseudoTraducirInforme(ATexto)
    else if not SameText(FIdioma, FIdiomaBase) then
    begin
      AsegurarCache;
      if not FTextosInforme.TryGetValue(ATexto, Result) or
         (Result = '') then
        Result := ATexto;
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
    TextoTraducido := TextoOriginal;
    if not (
         SameText(APropiedad, 'Caption') and
         EsAtajoTecladoPuro(TextoOriginal)) then
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
  const AUsuario: string;
  const ARegistroLog: IRegistroLog): string;
var
  Consulta: TUniQuery;
  Idioma: string;
  Registro: IRegistroLog;
begin
  Registro := ARegistroLog;
  if not Assigned(Registro) then
  begin
    Registro := CrearRegistroLogNulo;
  end;
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
            Result := NormalizarIdiomaAplicacion(Idioma);
        end;
      except
        on E: Exception do
          Registro.RegistrarAviso(
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

initialization
  BloqueoResourcestrings := TCriticalSection.Create;
  ClavesResourcestrings := nil;
  FuncionCargaResourcestringAnterior := nil;
  ServicioResourcestrings := nil;
  TraduccionResourcestringsActiva := False;

finalization
  DesactivarTraduccionResourcestrings;
  FreeAndNil(ClavesResourcestrings);
  FreeAndNil(BloqueoResourcestrings);

end.
