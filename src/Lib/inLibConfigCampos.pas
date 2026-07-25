{******************************************************************************}
{                                                                              }
{  Modulo:       inLibConfigCampos                                             }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Cache en memoria de fza_config_campos. Provee titulo visual y ancho      }
{    por defecto para cualquier columna de cualquier tabla. Se precarga        }
{    al login y se usa como fallback cuando no hay perfil de usuario.          }
{******************************************************************************}
unit inLibConfigCampos;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  DBAccess, Uni;

type
  TConfigCampoItem = record
    Tabla: string;
    Campo: string;
    TituloVisual: string;
    AnchoColumna: Integer;
    OrdenVisual: Integer;
    Visible: Boolean;
  end;

  TConfigCamposCache = class
  private
    // Diccionario indexado por CAMPO (sin tabla) para busqueda rapida.
    // Si hay duplicados entre tablas, el ultimo gana; para resolucion
    // exacta usar ObtenerPorTablaCampo.
    FPorCampo: TDictionary<string, TConfigCampoItem>;
    // Diccionario indexado por TABLA.CAMPO para resolucion exacta.
    FPorTablaCampo: TDictionary<string, TConfigCampoItem>;
    FConexion: TUniConnection;
    FCargada: Boolean;
  public
    constructor Create(AConexion: TUniConnection);
    destructor Destroy; override;
    procedure Precargar(AConn: TUniConnection = nil);
    procedure Invalidar;
    // Busca primero por tabla+campo exacto; si no encuentra, por campo solo.
    function ObtenerTitulo(const aCampo: string;
                           const aTabla: string = ''): string;
    function ObtenerAncho(const aCampo: string;
                          const aTabla: string = ''): Integer;
    function Existe(const aCampo: string;
                    const aTabla: string = ''): Boolean;
    property Cargada: Boolean read FCargada;
  end;

var
  oConfigCampos: TConfigCamposCache;

implementation

uses
  inLibLog;

constructor TConfigCamposCache.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
  FPorCampo := TDictionary<string, TConfigCampoItem>.Create;
  FPorTablaCampo := TDictionary<string, TConfigCampoItem>.Create;
  FCargada := False;
end;

destructor TConfigCamposCache.Destroy;
begin
  FreeAndNil(FPorCampo);
  FreeAndNil(FPorTablaCampo);
  inherited;
end;

procedure TConfigCamposCache.Invalidar;
begin
  FPorCampo.Clear;
  FPorTablaCampo.Clear;
  FCargada := False;
end;

procedure TConfigCamposCache.Precargar(AConn: TUniConnection = nil);
var
  qry: TUniQuery;
  item: TConfigCampoItem;
  sKey: string;
begin
  FPorCampo.Clear;
  FPorTablaCampo.Clear;
  FCargada := False;
  if AConn = nil then
    AConn := FConexion;
  if (AConn = nil) or (not AConn.Connected) then
    Exit;
  try
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := AConn;
      qry.SQL.Text :=
        'SELECT TABLA_OBJETIVO_CC, OBJETIVO_CC, TITULO_VISUAL_CC, ' +
        '       ANCHO_COLUMNA_CC, ORDEN_VISUAL_CC, VISIBLE_CC '    +
        '  FROM fza_config_campos '                                 +
        ' ORDER BY TABLA_OBJETIVO_CC, ORDEN_VISUAL_CC';
      qry.Open;
      while not qry.Eof do
      begin
        item.Tabla        := qry.FieldByName('TABLA_OBJETIVO_CC').AsString;
        item.Campo        := qry.FieldByName('OBJETIVO_CC').AsString;
        item.TituloVisual := qry.FieldByName('TITULO_VISUAL_CC').AsString;
        item.AnchoColumna := qry.FieldByName('ANCHO_COLUMNA_CC').AsInteger;
        item.OrdenVisual  := qry.FieldByName('ORDEN_VISUAL_CC').AsInteger;
        item.Visible      := qry.FieldByName('VISIBLE_CC').AsString = 'S';
        // Indice por tabla.campo
        sKey := LowerCase(item.Tabla + '.' + item.Campo);
        FPorTablaCampo.AddOrSetValue(sKey, item);
        // Indice por campo solo (el ultimo gana si hay duplicados)
        FPorCampo.AddOrSetValue(LowerCase(item.Campo), item);
        qry.Next;
      end;
    finally
      FreeAndNil(qry);
    end;
    FCargada := True;
    Log.LogInfo(Format('ConfigCamposCache: precargados %d campos',
      [FPorTablaCampo.Count]));
  except
    on E: Exception do
    begin
      FPorCampo.Clear;
      FPorTablaCampo.Clear;
      Log.LogError('ConfigCamposCache.Precargar: ' + E.Message);
    end;
  end;
end;

function TConfigCamposCache.Existe(const aCampo: string;
                                   const aTabla: string): Boolean;
begin
  if not FCargada then
  begin
    Result := False;
    Exit;
  end;
  if aTabla <> '' then
    if FPorTablaCampo.ContainsKey(LowerCase(aTabla + '.' + aCampo)) then
    begin
      Result := True;
      Exit;
    end;
  Result := FPorCampo.ContainsKey(LowerCase(aCampo));
end;

function TConfigCamposCache.ObtenerTitulo(const aCampo: string;
                                          const aTabla: string): string;
var
  item: TConfigCampoItem;
begin
  Result := '';
  if not FCargada then
    Exit;
  // Busqueda exacta por tabla+campo
  if (aTabla <> '') and
     FPorTablaCampo.TryGetValue(LowerCase(aTabla + '.' + aCampo), item) then
  begin
    Result := item.TituloVisual;
    Exit;
  end;
  // Fallback: solo por campo
  if FPorCampo.TryGetValue(LowerCase(aCampo), item) then
    Result := item.TituloVisual;
end;

function TConfigCamposCache.ObtenerAncho(const aCampo: string;
                                         const aTabla: string): Integer;
var
  item: TConfigCampoItem;
begin
  Result := 0;
  if not FCargada then
    Exit;
  if (aTabla <> '') and
     FPorTablaCampo.TryGetValue(LowerCase(aTabla + '.' + aCampo), item) then
  begin
    Result := item.AnchoColumna;
    Exit;
  end;
  if FPorCampo.TryGetValue(LowerCase(aCampo), item) then
    Result := item.AnchoColumna;
end;

end.
