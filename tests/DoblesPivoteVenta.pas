{******************************************************************************}
{                                                                              }
{  Módulo:       DoblesPivoteVenta                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Doble en memoria del puerto IRepositorioPivoteVenta para probar el        }
{    modelo del pivote de venta sin conexión a la BBDD.                        }
{******************************************************************************}
unit DoblesPivoteVenta;

interface

uses
  System.SysUtils, System.Generics.Collections,
  inLibPivoteVentaIntf;

type
  TRepositorioPivoteVentaMemoria = class(TInterfacedObject,
                                         IRepositorioPivoteVenta)
  public
    InfoPorSku          : TDictionary<string, TInfoSkuPivoteVenta>;
    SkuPorBarras        : TDictionary<string, string>;
    SkuUnicoPorArticulo : TDictionary<string, string>;
    ConjuntoQueCubre    : Integer;
    PosicionesPorConjunto
      : TDictionary<Integer, TValoresTallaPivoteVenta>;
    TallasPorArticulo
      : TDictionary<string, TValoresTallaPivoteVenta>;
    TallasCatalogo      : TDictionary<Integer, string>;
    SkuPorAtributos     : TDictionary<string, string>;
    SkusCreados         : TList<string>;
    ArticuloBusqueda    : string;
    BusquedaAceptada    : Boolean;
    LlamadasBuscarConjunto: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure DefinirSku(const ACodigoSku: string;
                         AColorAv, ATallaAv: Integer;
                         const AColorTexto, AColorCodigo,
                         AVarSku: string);
    function ObtenerInfoSku(const ACodigoSku: string)
                            : TInfoSkuPivoteVenta;
    function ResolverSkuDesdeCodigoBarras(
      const ACodigoBarras: string): string;
    function ResolverSkuUnicoArticulo(
      const ACodigoArticulo: string): string;
    function BuscarConjuntoQueCubre(
      const AIdsTalla: TArray<Integer>): Integer;
    function PosicionesConjunto(AIdAc: Integer)
                                : TValoresTallaPivoteVenta;
    function TallasDeArticulo(const ACodigoArticulo: string)
                              : TValoresTallaPivoteVenta;
    function TallasPorIds(const AIdsTalla: TArray<Integer>)
                          : TValoresTallaPivoteVenta;
    function DescripcionTalla(AIdAvTalla: Integer): string;
    function BuscarSkuActivoPorAtributos(
      const ACodigoArticulo: string;
      ATallaAv, AColorAv: Integer): string;
    procedure CrearSkuConAtributos(const ACodigoSku, ACodigoArticulo,
                                   AVariacionSku: string;
                                   AColorAv, ATallaAv: Integer);
    function ElegirArticuloDesdeBusqueda(const AAlmacenStock: string;
                                         out ACodigoArticulo: string)
                                         : Boolean;
  end;

implementation

constructor TRepositorioPivoteVentaMemoria.Create;
begin
  inherited Create;
  InfoPorSku := TDictionary<string, TInfoSkuPivoteVenta>.Create;
  SkuPorBarras := TDictionary<string, string>.Create;
  SkuUnicoPorArticulo := TDictionary<string, string>.Create;
  PosicionesPorConjunto :=
    TDictionary<Integer, TValoresTallaPivoteVenta>.Create;
  TallasPorArticulo :=
    TDictionary<string, TValoresTallaPivoteVenta>.Create;
  TallasCatalogo := TDictionary<Integer, string>.Create;
  SkuPorAtributos := TDictionary<string, string>.Create;
  SkusCreados := TList<string>.Create;
end;

destructor TRepositorioPivoteVentaMemoria.Destroy;
begin
  FreeAndNil(SkusCreados);
  FreeAndNil(SkuPorAtributos);
  FreeAndNil(TallasCatalogo);
  FreeAndNil(TallasPorArticulo);
  FreeAndNil(PosicionesPorConjunto);
  FreeAndNil(SkuUnicoPorArticulo);
  FreeAndNil(SkuPorBarras);
  FreeAndNil(InfoPorSku);
  inherited;
end;

procedure TRepositorioPivoteVentaMemoria.DefinirSku(
  const ACodigoSku: string; AColorAv, ATallaAv: Integer;
  const AColorTexto, AColorCodigo, AVarSku: string);
var
  oInfo: TInfoSkuPivoteVenta;
begin
  oInfo := Default(TInfoSkuPivoteVenta);
  oInfo.Encontrado := True;
  oInfo.ColorAv := AColorAv;
  oInfo.TallaAv := ATallaAv;
  oInfo.ColorTexto := AColorTexto;
  oInfo.ColorCodigo := AColorCodigo;
  oInfo.VarSku := AVarSku;
  InfoPorSku.AddOrSetValue(UpperCase(ACodigoSku), oInfo);
end;

function TRepositorioPivoteVentaMemoria.ObtenerInfoSku(
  const ACodigoSku: string): TInfoSkuPivoteVenta;
begin
  if not InfoPorSku.TryGetValue(UpperCase(Trim(ACodigoSku)),
                                Result) then
    Result := Default(TInfoSkuPivoteVenta);
end;

function TRepositorioPivoteVentaMemoria.ResolverSkuDesdeCodigoBarras(
  const ACodigoBarras: string): string;
begin
  if not SkuPorBarras.TryGetValue(Trim(ACodigoBarras), Result) then
    Result := '';
end;

function TRepositorioPivoteVentaMemoria.ResolverSkuUnicoArticulo(
  const ACodigoArticulo: string): string;
begin
  if not SkuUnicoPorArticulo.TryGetValue(Trim(ACodigoArticulo),
                                         Result) then
    Result := '';
end;

function TRepositorioPivoteVentaMemoria.BuscarConjuntoQueCubre(
  const AIdsTalla: TArray<Integer>): Integer;
begin
  Inc(LlamadasBuscarConjunto);
  Result := ConjuntoQueCubre;
end;

function TRepositorioPivoteVentaMemoria.PosicionesConjunto(
  AIdAc: Integer): TValoresTallaPivoteVenta;
begin
  if not PosicionesPorConjunto.TryGetValue(AIdAc, Result) then
    Result := nil;
end;

function TRepositorioPivoteVentaMemoria.TallasDeArticulo(
  const ACodigoArticulo: string): TValoresTallaPivoteVenta;
begin
  if not TallasPorArticulo.TryGetValue(Trim(ACodigoArticulo),
                                       Result) then
    Result := nil;
end;

function TRepositorioPivoteVentaMemoria.TallasPorIds(
  const AIdsTalla: TArray<Integer>): TValoresTallaPivoteVenta;
var
  sValor: string;
  i: Integer;
begin
  Result := nil;
  for i := 0 to High(AIdsTalla) do
  begin
    if TallasCatalogo.TryGetValue(AIdsTalla[i], sValor) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)].IdAv := AIdsTalla[i];
      Result[High(Result)].Valor := sValor;
    end;
  end;
end;

function TRepositorioPivoteVentaMemoria.DescripcionTalla(
  AIdAvTalla: Integer): string;
begin
  if not TallasCatalogo.TryGetValue(AIdAvTalla, Result) then
    Result := '';
end;

function TRepositorioPivoteVentaMemoria.BuscarSkuActivoPorAtributos(
  const ACodigoArticulo: string; ATallaAv, AColorAv: Integer): string;
begin
  if not SkuPorAtributos.TryGetValue(
       Trim(ACodigoArticulo) + '|' + IntToStr(ATallaAv) + '|' +
       IntToStr(AColorAv), Result) then
    Result := '';
end;

procedure TRepositorioPivoteVentaMemoria.CrearSkuConAtributos(
  const ACodigoSku, ACodigoArticulo, AVariacionSku: string;
  AColorAv, ATallaAv: Integer);
begin
  SkusCreados.Add(ACodigoSku + '|' + ACodigoArticulo + '|' +
    AVariacionSku + '|' + IntToStr(AColorAv) + '|' +
    IntToStr(ATallaAv));
end;

function TRepositorioPivoteVentaMemoria.ElegirArticuloDesdeBusqueda(
  const AAlmacenStock: string;
  out ACodigoArticulo: string): Boolean;
begin
  ACodigoArticulo := ArticuloBusqueda;
  Result := BusquedaAceptada;
end;

end.
