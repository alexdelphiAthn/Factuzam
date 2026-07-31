{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosVariaciones                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fachada sin SQL para variaciones y SKU de artículos.                     }
{******************************************************************************}
unit inLibArticulosVariaciones;

interface

uses
  System.Generics.Collections,
  Vcl.Forms,
  cxDropDownEdit, cxCheckBox,
  Uni, inLibArticulosVariacionesIntf;

type
  TSlotVariacion = record
    IdAtributo: string;
    NombreAtributo: string;
    OrdenAtributo: Integer;
    IdConjunto: Integer;
    NombreConjunto: string;
    Ctrl: TcxComboBox;
    Opciones: TDictionary<Integer, string>;
  end;
  TSlotSku = record
    CodigoUnidad: string;
    Activo: Boolean;
    ActiveOriginal: Boolean;
    Chk: TcxCheckBox;
  end;
  TGestorVariaciones = class
  private
    FServicio: IGestorArticulosVariaciones;
    function GetCodigoArticulo: string;
    function GetModificado: Boolean;
  public
    constructor Create(
      APanelAtributos: TScrollBox;
      AConexion: TUniConnection;
      const AUsuario: string);
    destructor Destroy; override;
    procedure CargarVariaciones(const CodigoArticulo: string);
    function GuardarVariaciones: Boolean;
    function Validar: string;
    property CodigoArticulo: string read GetCodigoArticulo;
    property Modificado: Boolean read GetModificado;
  end;

procedure AsegurarSkuArticuloSinVariaciones(
  AConexion: TUniConnection;
  const ACodigoArticulo, AUsuario: string);
procedure AsegurarSkuArticuloActivo(
  AConexion: TUniConnection;
  const ACodigoArticulo, AUsuario: string);
function ArticuloTieneSkuActivo(
  AConexion: TUniConnection;
  const ACodigoArticulo: string): Boolean;

implementation

constructor TGestorVariaciones.Create(
  APanelAtributos: TScrollBox;
  AConexion: TUniConnection;
  const AUsuario: string);
begin
  inherited Create;
  FServicio := TFabricaArticulosVariaciones.Crear(AConexion).CrearGestor(
    APanelAtributos, AUsuario);
end;

destructor TGestorVariaciones.Destroy;
begin
  FServicio := nil;
  inherited;
end;

procedure TGestorVariaciones.CargarVariaciones(
  const CodigoArticulo: string);
begin
  FServicio.CargarVariaciones(CodigoArticulo);
end;

function TGestorVariaciones.GuardarVariaciones: Boolean;
begin
  Result := FServicio.GuardarVariaciones;
end;

function TGestorVariaciones.Validar: string;
begin
  Result := FServicio.Validar;
end;

function TGestorVariaciones.GetCodigoArticulo: string;
begin
  Result := FServicio.ObtenerCodigoArticulo;
end;

function TGestorVariaciones.GetModificado: Boolean;
begin
  Result := FServicio.EstaModificado;
end;

procedure AsegurarSkuArticuloSinVariaciones(
  AConexion: TUniConnection;
  const ACodigoArticulo, AUsuario: string);
begin
  TFabricaArticulosVariaciones.Crear(AConexion).AsegurarSkuSinVariaciones(
    ACodigoArticulo, AUsuario);
end;

procedure AsegurarSkuArticuloActivo(
  AConexion: TUniConnection;
  const ACodigoArticulo, AUsuario: string);
begin
  TFabricaArticulosVariaciones.Crear(AConexion).AsegurarSkuActivo(
    ACodigoArticulo, AUsuario);
end;

function ArticuloTieneSkuActivo(
  AConexion: TUniConnection;
  const ACodigoArticulo: string): Boolean;
begin
  Result := TFabricaArticulosVariaciones.Crear(AConexion).TieneSkuActivo(
    ACodigoArticulo);
end;

end.
