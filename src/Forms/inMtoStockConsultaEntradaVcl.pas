{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoStockConsultaEntradaVcl                                  }
{    Tipo:       Adaptador VCL                                                 }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Adapta repositorio y vista mediante callbacks, sin recibir el formulario.}
{******************************************************************************}
unit inMtoStockConsultaEntradaVcl;

interface

uses
  inLibStockConsultaEntradaIntf;

type
  TResolverTextoEntradaStock = reference to function(
    const AEntrada: string): TCoincidenciasEntradaStock;
  TAplicarArticuloEntradaStock = reference to procedure(
    const ACodigoArticulo, ACodigoSku: string);
  TMostrarCoincidenciasEntradaStock = reference to procedure(
    const ACoincidencias: TCoincidenciasEntradaStock;
    const AEntrada: string);
  TMostrarEntradaStockNoEncontrada = reference to procedure(
    const AEntrada: string);

  TCallbacksEntradaStock = record
    ResolverTexto: TResolverTextoEntradaStock;
    AplicarArticulo: TAplicarArticuloEntradaStock;
    MostrarCoincidencias: TMostrarCoincidenciasEntradaStock;
    MostrarTextoNoEncontrado: TMostrarEntradaStockNoEncontrada;
    MostrarCodigoBarrasNoEncontrado: TMostrarEntradaStockNoEncontrada;
  end;

  TAdaptadorEntradaStockVcl = class(
    TInterfacedObject,
    IRepositorioEntradaStock,
    IVistaEntradaStock)
  private
    FCallbacks: TCallbacksEntradaStock;
  public
    constructor Create(const ACallbacks: TCallbacksEntradaStock);
    function ResolverTexto(
      const AEntrada: string): TCoincidenciasEntradaStock;
    procedure AplicarArticulo(
      const ACodigoArticulo, ACodigoSku: string);
    procedure MostrarCoincidencias(
      const ACoincidencias: TCoincidenciasEntradaStock;
      const AEntrada: string);
    procedure MostrarTextoNoEncontrado(const AEntrada: string);
    procedure MostrarCodigoBarrasNoEncontrado(const ACodigo: string);
  end;

implementation

constructor TAdaptadorEntradaStockVcl.Create(
  const ACallbacks: TCallbacksEntradaStock);
begin
  inherited Create;
  FCallbacks := ACallbacks;
end;

function TAdaptadorEntradaStockVcl.ResolverTexto(
  const AEntrada: string): TCoincidenciasEntradaStock;
begin
  Result := FCallbacks.ResolverTexto(AEntrada);
end;

procedure TAdaptadorEntradaStockVcl.AplicarArticulo(
  const ACodigoArticulo, ACodigoSku: string);
begin
  FCallbacks.AplicarArticulo(ACodigoArticulo, ACodigoSku);
end;

procedure TAdaptadorEntradaStockVcl.MostrarCoincidencias(
  const ACoincidencias: TCoincidenciasEntradaStock;
  const AEntrada: string);
begin
  FCallbacks.MostrarCoincidencias(ACoincidencias, AEntrada);
end;

procedure TAdaptadorEntradaStockVcl.MostrarTextoNoEncontrado(
  const AEntrada: string);
begin
  FCallbacks.MostrarTextoNoEncontrado(AEntrada);
end;

procedure TAdaptadorEntradaStockVcl.MostrarCodigoBarrasNoEncontrado(
  const ACodigo: string);
begin
  FCallbacks.MostrarCodigoBarrasNoEncontrado(ACodigo);
end;

end.
