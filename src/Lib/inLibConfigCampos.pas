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
  inLibConfigCamposIntf, inLibLogIntf,
  inLibConfigCamposPersistenciaIntf;

type
  TConfigCampoItem = TConfigCampoPersistido;

  TConfigCamposCache = class(TInterfacedObject, IConfiguracionCampos)
  private
    // Diccionario indexado por CAMPO (sin tabla) para busqueda rapida.
    // Si hay duplicados entre tablas, el ultimo gana; para resolucion
    // exacta usar ObtenerPorTablaCampo.
    FPorCampo: TDictionary<string, TConfigCampoItem>;
    // Diccionario indexado por TABLA.CAMPO para resolucion exacta.
    FPorTablaCampo: TDictionary<string, TConfigCampoItem>;
    FRepositorio: IRepositorioConfigCampos;
    FCargada: Boolean;
    FRegistroLog: IRegistroLog;
    function GetCargada: Boolean;
  public
    constructor Create(
      const ARepositorio: IRepositorioConfigCampos;
      const ARegistroLog: IRegistroLog);
    destructor Destroy; override;
    procedure Precargar(
      const ARepositorio: IRepositorioConfigCampos = nil);
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

implementation

constructor TConfigCamposCache.Create(
  const ARepositorio: IRepositorioConfigCampos;
  const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  if not Assigned(ARegistroLog) then
    raise EArgumentNilException.Create('ARegistroLog');
  FRepositorio := ARepositorio;
  FRegistroLog := ARegistroLog;
  FPorCampo := TDictionary<string, TConfigCampoItem>.Create;
  FPorTablaCampo := TDictionary<string, TConfigCampoItem>.Create;
  FCargada := False;
end;

destructor TConfigCamposCache.Destroy;
begin
  FRepositorio := nil;
  FRegistroLog := nil;
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

procedure TConfigCamposCache.Precargar(
  const ARepositorio: IRepositorioConfigCampos);
var
  i: Integer;
  item: TConfigCampoItem;
  oRepositorio: IRepositorioConfigCampos;
  oResultado: TResultadoConfigCampos;
  sKey: string;
begin
  FPorCampo.Clear;
  FPorTablaCampo.Clear;
  FCargada := False;
  oRepositorio := ARepositorio;
  if not Assigned(oRepositorio) then
    oRepositorio := FRepositorio;
  if Assigned(oRepositorio) then
  begin
    try
      oResultado := oRepositorio.CargarCampos;
      if oResultado.Exito then
      begin
        for i := 0 to Length(oResultado.Elementos) - 1 do
        begin
          item := oResultado.Elementos[i];
          sKey := LowerCase(item.Tabla + '.' + item.Campo);
          FPorTablaCampo.AddOrSetValue(sKey, item);
          FPorCampo.AddOrSetValue(LowerCase(item.Campo), item);
        end;
        FCargada := True;
        FRegistroLog.RegistrarInformacion(
          Format(
            'ConfigCamposCache: precargados %d campos',
            [FPorTablaCampo.Count]));
      end
      else
      begin
        FRegistroLog.RegistrarError(
          'ConfigCamposCache.Precargar: ' +
          oResultado.Detalle);
      end;
    except
      on E: Exception do
      begin
        FPorCampo.Clear;
        FPorTablaCampo.Clear;
        FRegistroLog.RegistrarError(
          'ConfigCamposCache.Precargar: ' + E.Message);
      end;
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

function TConfigCamposCache.GetCargada: Boolean;
begin
  Result := FCargada;
end;

end.
