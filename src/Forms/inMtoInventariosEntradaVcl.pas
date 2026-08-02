{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoInventariosEntradaVcl                                    }
{    Tipo:       Adaptador VCL                                                 }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Adapta operaciones concretas del grid al puerto de entrada de inventario. }
{    No recibe ni conserva el formulario.                                      }
{******************************************************************************}
unit inMtoInventariosEntradaVcl;

interface

uses
  inLibInventariosAplicacionIntf;

type
  TMuestraAtributosInventario = reference to function: Boolean;
  TObtenerNumeroAtributosInventario = reference to function(
    const ACodigoArticulo: string): Integer;
  TAsegurarEdicionInventario = reference to function:
    TErrorEntradaInventario;
  TEscribirArticuloInventario = reference to procedure(
    const ACodigoArticulo, ADescripcion: string);
  TActualizarColumnasInventario = reference to procedure(
    const ACodigoArticulo: string);
  TNumeroAtributosActualInventario = reference to function: Integer;
  TEscribirUnidadInventario = reference to procedure(
    const ACodigoUnidad: string);
  TCargarStockInventario = reference to procedure(
    const ACodigoUnidad: string);
  TRellenarAtributosInventario = reference to procedure(
    const ACodigoSku: string);

  TCallbacksEntradaInventario = record
    MuestraAtributos: TMuestraAtributosInventario;
    ObtenerNumeroAtributos: TObtenerNumeroAtributosInventario;
    AsegurarEdicion: TAsegurarEdicionInventario;
    EscribirArticulo: TEscribirArticuloInventario;
    ActualizarColumnas: TActualizarColumnasInventario;
    NumeroAtributosActual: TNumeroAtributosActualInventario;
    EscribirUnidad: TEscribirUnidadInventario;
    CargarStock: TCargarStockInventario;
    RellenarAtributos: TRellenarAtributosInventario;
  end;

  TAdaptadorEntradaInventarioVcl = class(
    TInterfacedObject,
    IOperacionesEntradaInventario)
  private
    FCallbacks: TCallbacksEntradaInventario;
  public
    constructor Create(const ACallbacks: TCallbacksEntradaInventario);
    function MuestraAtributos: Boolean;
    function ObtenerNumeroAtributos(
      const ACodigoArticulo: string): Integer;
    function AsegurarEdicion: TErrorEntradaInventario;
    procedure EscribirArticulo(
      const ACodigoArticulo, ADescripcion: string);
    procedure ActualizarColumnas(const ACodigoArticulo: string);
    function NumeroAtributosActual: Integer;
    procedure EscribirUnidad(const ACodigoUnidad: string);
    procedure CargarStock(const ACodigoUnidad: string);
    procedure RellenarAtributos(const ACodigoSku: string);
  end;

implementation

constructor TAdaptadorEntradaInventarioVcl.Create(
  const ACallbacks: TCallbacksEntradaInventario);
begin
  inherited Create;
  FCallbacks := ACallbacks;
end;

function TAdaptadorEntradaInventarioVcl.MuestraAtributos: Boolean;
begin
  Result := FCallbacks.MuestraAtributos();
end;

function TAdaptadorEntradaInventarioVcl.ObtenerNumeroAtributos(
  const ACodigoArticulo: string): Integer;
begin
  Result := FCallbacks.ObtenerNumeroAtributos(ACodigoArticulo);
end;

function TAdaptadorEntradaInventarioVcl.AsegurarEdicion:
  TErrorEntradaInventario;
begin
  Result := FCallbacks.AsegurarEdicion();
end;

procedure TAdaptadorEntradaInventarioVcl.EscribirArticulo(
  const ACodigoArticulo, ADescripcion: string);
begin
  FCallbacks.EscribirArticulo(ACodigoArticulo, ADescripcion);
end;

procedure TAdaptadorEntradaInventarioVcl.ActualizarColumnas(
  const ACodigoArticulo: string);
begin
  FCallbacks.ActualizarColumnas(ACodigoArticulo);
end;

function TAdaptadorEntradaInventarioVcl.NumeroAtributosActual: Integer;
begin
  Result := FCallbacks.NumeroAtributosActual();
end;

procedure TAdaptadorEntradaInventarioVcl.EscribirUnidad(
  const ACodigoUnidad: string);
begin
  FCallbacks.EscribirUnidad(ACodigoUnidad);
end;

procedure TAdaptadorEntradaInventarioVcl.CargarStock(
  const ACodigoUnidad: string);
begin
  FCallbacks.CargarStock(ACodigoUnidad);
end;

procedure TAdaptadorEntradaInventarioVcl.RellenarAtributos(
  const ACodigoSku: string);
begin
  FCallbacks.RellenarAtributos(ACodigoSku);
end;

end.
