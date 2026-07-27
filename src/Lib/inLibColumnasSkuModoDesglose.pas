{******************************************************************************}
{                                                                              }
{  Modulo:       inLibColumnasSkuModoDesglose                                  }
{    Tipo:       Libreria                                                      }
{ Version:       0.1.0                                                         }
{   Fecha:       05/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    PRUEBA ColumnSKUcxGrid: implementacion de IModoEntradaGrid en modo        }
{    desglose (columna articulo + columnas color / talla).                     }
{                                                                              }
{    Es un ADAPTADOR: delega toda la operativa en TGridArticulosLineas         }
{    (inLibGridArticulos), el desarrollo ya en produccion en caja y            }
{    traspasos (busqueda incremental, lector, paleta de swatches,              }
{    autocompletado de atributos unicos). Aqui solo se traduce el contrato     }
{    IModoEntradaGrid a su API y se reexpone el evento OnResuelto.             }
{******************************************************************************}
unit inLibColumnasSkuModoDesglose;

interface

uses
  System.SysUtils, System.Classes,
  inLibColumnasSkuIntf, inLibGridArticulos;

type
  TModoEntradaDesglose = class(TInterfacedObject, IModoEntradaGrid)
  private
    FConfig: TConfigColumnasSku;
    FGrid: TGridArticulosLineas;
    FOnResuelto: TSkuResueltoEvent;
    function GetModo: TModoColumnasSku;
    function GetOnResuelto: TSkuResueltoEvent;
    procedure SetOnResuelto(const AValue: TSkuResueltoEvent);
    function GetOnEntrarEdicion: TNotifyEvent;
    procedure SetOnEntrarEdicion(const AValue: TNotifyEvent);
    function GetOnSalirEdicion: TNotifyEvent;
    procedure SetOnSalirEdicion(const AValue: TNotifyEvent);
    procedure SetAlmacenStock(const AValue: string);
    // Reenvia el aviso de TGridArticulosLineas al documento.
    procedure GridResuelto(const ACodArt, ASku, ADescripcion: string;
                           ACompleto: Boolean);
  public
    constructor Create(const AConfig: TConfigColumnasSku);
    destructor Destroy; override;
    procedure Construir;
    procedure Desmontar;
    procedure MostrarEditor;
    function ResolverEntrada(const AEntrada: string): Boolean;
  end;

implementation

constructor TModoEntradaDesglose.Create(const AConfig: TConfigColumnasSku);
var
  Campos: TCamposGridArt;
  i: Integer;
begin
  inherited Create;
  FConfig := AConfig;
  // Traduccion del record de campos del contrato al de la controladora.
  Campos.CodigoArt := AConfig.Campos.CodigoArt;
  Campos.CodigoUnidad := AConfig.Campos.CodigoUnidad;
  Campos.Descripcion := AConfig.Campos.Descripcion;
  Campos.Cantidad := AConfig.Campos.Cantidad;
  Campos.NumAtributos := AConfig.Campos.NumAtributos;
  for i := 1 to 5 do
  begin
    Campos.AttrValor[i] := AConfig.Campos.AttrValor[i];
    Campos.AttrNombre[i] := AConfig.Campos.AttrNombre[i];
  end;
  FGrid := TGridArticulosLineas.Create(
    AConfig.Conexion,
    AConfig.View,
    AConfig.Cds,
    Campos,
    AConfig.ContextoSesion);
  FGrid.OnResuelto := GridResuelto;
  FGrid.AlmacenStock := AConfig.AlmacenStock;
  FGrid.AceptarNoCatalogo := AConfig.AceptarNoCatalogo;
end;

destructor TModoEntradaDesglose.Destroy;
begin
  FreeAndNil(FGrid);
  inherited;
end;

function TModoEntradaDesglose.GetModo: TModoColumnasSku;
begin
  Result := mcsDesglose;
end;

function TModoEntradaDesglose.GetOnResuelto: TSkuResueltoEvent;
begin
  Result := FOnResuelto;
end;

procedure TModoEntradaDesglose.SetOnResuelto(
  const AValue: TSkuResueltoEvent);
begin
  FOnResuelto := AValue;
end;

function TModoEntradaDesglose.GetOnEntrarEdicion: TNotifyEvent;
begin
  Result := FGrid.OnEntrarEdicion;
end;

procedure TModoEntradaDesglose.SetOnEntrarEdicion(
  const AValue: TNotifyEvent);
begin
  FGrid.OnEntrarEdicion := AValue;
end;

function TModoEntradaDesglose.GetOnSalirEdicion: TNotifyEvent;
begin
  Result := FGrid.OnSalirEdicion;
end;

procedure TModoEntradaDesglose.SetOnSalirEdicion(
  const AValue: TNotifyEvent);
begin
  FGrid.OnSalirEdicion := AValue;
end;

procedure TModoEntradaDesglose.SetAlmacenStock(const AValue: string);
begin
  FGrid.AlmacenStock := AValue;
end;

procedure TModoEntradaDesglose.GridResuelto(const ACodArt, ASku,
  ADescripcion: string; ACompleto: Boolean);
begin
  if Assigned(FOnResuelto) then
    FOnResuelto(ACodArt, ASku, ADescripcion, ACompleto);
end;

procedure TModoEntradaDesglose.Construir;
begin
  FGrid.Construir;
end;

procedure TModoEntradaDesglose.Desmontar;
begin
  // Sin estado externo que convertir: las lineas del cds YA llevan su
  // SKU y su cantidad.
end;

procedure TModoEntradaDesglose.MostrarEditor;
begin
  FGrid.MostrarEditorArticulo;
end;

function TModoEntradaDesglose.ResolverEntrada(
  const AEntrada: string): Boolean;
begin
  Result := FGrid.ResolverEntrada(AEntrada);
end;

end.
