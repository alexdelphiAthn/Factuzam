{******************************************************************************}
{                                                                              }
{  Modulo:       inLibInventariosAplicacion                                    }
{    Tipo:       Aplicacion                                                    }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Orquesta la entrada de inventario sin conocer formularios ni datasets.    }
{******************************************************************************}
unit inLibInventariosAplicacion;

interface

uses
  inLibArticulosValidadorIntf,
  inLibInventariosAplicacionIntf;

function CrearAplicacionEntradaInventario(
  const AValidador: IArticulosValidador;
  const AOperaciones: IOperacionesEntradaInventario):
  IAplicacionEntradaInventario;

implementation

uses
  System.SysUtils,
  inLibInventariosEntrada;

type
  TAplicacionEntradaInventario = class(
    TInterfacedObject,
    IAplicacionEntradaInventario)
  private
    FValidador: IArticulosValidador;
    FOperaciones: IOperacionesEntradaInventario;
  public
    constructor Create(
      const AValidador: IArticulosValidador;
      const AOperaciones: IOperacionesEntradaInventario);
    function Procesar(
      const AEntrada: string): TResultadoEntradaInventario;
  end;

constructor TAplicacionEntradaInventario.Create(
  const AValidador: IArticulosValidador;
  const AOperaciones: IOperacionesEntradaInventario);
begin
  inherited Create;
  if not Assigned(AValidador) then
    raise EArgumentNilException.Create('AValidador');
  if not Assigned(AOperaciones) then
    raise EArgumentNilException.Create('AOperaciones');
  FValidador := AValidador;
  FOperaciones := AOperaciones;
end;

function TAplicacionEntradaInventario.Procesar(
  const AEntrada: string): TResultadoEntradaInventario;
var
  bMuestraAtributos: Boolean;
  iNumeroAtributos: Integer;
  Resolucion: TArtResolucionEntrada;
  Decision: TDecisionEntradaInventario;
begin
  Result := Default(TResultadoEntradaInventario);
  Resolucion := FValidador.Resolver(Trim(AEntrada));
  if not Resolucion.Encontrado then
    Result.Error := eeiArticuloNoEncontrado;
  if Result.Error = eeiNinguno then
  begin
    Result.CodigoArticulo := Resolucion.CodigoArticulo;
    Result.CodigoSku := Resolucion.CodigoSku;
    Result.Descripcion := Resolucion.DescripcionArticulo;
    Result.TipoArticulo := Resolucion.TipoArticulo;
  end;
  if (Result.Error = eeiNinguno) and
     (not SameText(Resolucion.TipoArticulo, 'ESTANDAR')) then
    Result.Error := eeiTipoArticuloSinStock;
  bMuestraAtributos := FOperaciones.MuestraAtributos;
  iNumeroAtributos := 0;
  if (Result.Error = eeiNinguno) and
     (not bMuestraAtributos) and
     (Resolucion.CodigoSku = '') then
  begin
    iNumeroAtributos := FOperaciones.ObtenerNumeroAtributos(
      Resolucion.CodigoArticulo);
    if iNumeroAtributos > 0 then
      Result.Error := eeiAtributosRequierenSku;
  end;
  if Result.Error = eeiNinguno then
    Result.Error := FOperaciones.AsegurarEdicion;
  if Result.Error = eeiNinguno then
  begin
    FOperaciones.EscribirArticulo(
      Result.CodigoArticulo,
      Result.Descripcion);
    FOperaciones.ActualizarColumnas(Result.CodigoArticulo);
    if bMuestraAtributos then
      iNumeroAtributos := FOperaciones.NumeroAtributosActual;
    Result.Error := FOperaciones.AsegurarEdicion;
  end;
  if Result.Error = eeiNinguno then
  begin
    Decision := ResolverEntradaInventario(
      Result.CodigoArticulo,
      Result.CodigoSku,
      iNumeroAtributos);
    Result.CodigoUnidad := Decision.CodigoUnidad;
    FOperaciones.EscribirUnidad(Result.CodigoUnidad);
    if Decision.CargarStock then
      FOperaciones.CargarStock(Result.CodigoUnidad);
    if Decision.RellenarAtributos then
      FOperaciones.RellenarAtributos(Result.CodigoUnidad);
  end;
end;

function CrearAplicacionEntradaInventario(
  const AValidador: IArticulosValidador;
  const AOperaciones: IOperacionesEntradaInventario):
  IAplicacionEntradaInventario;
begin
  Result := TAplicacionEntradaInventario.Create(
    AValidador,
    AOperaciones);
end;

end.
