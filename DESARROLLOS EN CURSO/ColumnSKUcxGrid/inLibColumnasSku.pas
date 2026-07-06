{******************************************************************************}
{                                                                              }
{  Modulo:       inLibColumnasSku                                              }
{    Tipo:       Libreria (factoria)                                           }
{ Version:       0.1.0                                                         }
{   Fecha:       05/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    PRUEBA ColumnSKUcxGrid: factoria de modos de entrada. El documento        }
{    construye un TConfigColumnasSku (View + cds + nombres de campos) y        }
{    recibe el IModoEntradaGrid adecuado:                                      }
{                                                                              }
{      - mcsAuto: si el cds tiene columnas de atributo (ATTR1_VALOR...)        }
{        se elige desglose; si no, modo SKU (una columna).                     }
{      - mcsSku / mcsDesglose: se respeta lo pedido.                           }
{                                                                              }
{    Expone tambien CrearProveedorValoresSku: IProveedorValoresSku sobre       }
{    inLibArticulosAtributosLookup, para que cualquier consumidor liste los    }
{    colores / tallas disponibles de un articulo sin duplicar SQL.             }
{******************************************************************************}
unit inLibColumnasSku;

interface

uses
  System.SysUtils, Data.DB, Uni,
  inLibColumnasSkuIntf, inLibGridTallasInline;

// Modo efectivo a partir de la configuracion (resuelve mcsAuto).
function DetectarModoColumnasSku(const AConfig: TConfigColumnasSku)
                                                     : TModoColumnasSku;

// Crea el modo de entrada adecuado ya construible sobre el View.
function CrearModoEntradaGrid(const AConfig: TConfigColumnasSku)
                                                     : IModoEntradaGrid;

// Modo tallas en horizontal (pivote de compras): necesita ademas la
// TGridTallasConfig del documento (tabla de celdas, campos de pivote).
// El adaptador completa Conexion, Grid y ColumnasTallas.
function CrearModoEntradaGridTallas(const AConfig: TConfigColumnasSku;
                                    const ACfgTallas: TGridTallasConfig)
                                                     : IModoEntradaGrid;

// Proveedor de valores disponibles (colores / tallas) de un articulo.
function CrearProveedorValoresSku(AConexion: TUniConnection)
                                                     : IProveedorValoresSku;

implementation

uses
  inLibArticulosAtributosLookup,
  inLibColumnasSkuModoSku,
  inLibColumnasSkuModoDesglose,
  inLibColumnasSkuModoTallas;

type
  TProveedorValoresSku = class(TInterfacedObject, IProveedorValoresSku)
  private
    FLookup: TArticulosAtributosLookup;
  public
    constructor Create(AConexion: TUniConnection);
    destructor Destroy; override;
    function ObtenerNombresAtributos(const ACodigoArticulo: string)
                                                       : TArray<string>;
    function ObtenerValoresDisponibles(const ACodigoArticulo: string;
                                       AOrden: Integer): TArray<string>;
  end;

constructor TProveedorValoresSku.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FLookup := TArticulosAtributosLookup.Create(AConexion);
end;

destructor TProveedorValoresSku.Destroy;
begin
  FreeAndNil(FLookup);
  inherited;
end;

function TProveedorValoresSku.ObtenerNombresAtributos(
  const ACodigoArticulo: string): TArray<string>;
var
  Atribs: TArray<TArticuloAtributo>;
  i: Integer;
begin
  Atribs := FLookup.ObtenerAtributos(ACodigoArticulo);
  SetLength(Result, Length(Atribs));
  for i := 0 to High(Atribs) do
    Result[i] := Atribs[i].NombreAtributo;
end;

function TProveedorValoresSku.ObtenerValoresDisponibles(
  const ACodigoArticulo: string; AOrden: Integer): TArray<string>;
var
  Avs: TArray<TArticuloAtributoValor>;
  i: Integer;
begin
  // Solo los AVs presentes en SKUs del articulo (lo realmente pedible).
  Avs := FLookup.ObtenerAvsEnSkus(ACodigoArticulo, AOrden);
  SetLength(Result, Length(Avs));
  for i := 0 to High(Avs) do
    Result[i] := Avs[i].Valor;
end;

function DetectarModoColumnasSku(const AConfig: TConfigColumnasSku)
                                                     : TModoColumnasSku;
begin
  if AConfig.Modo <> mcsAuto then
    Result := AConfig.Modo
  // Auto: hay desglose si el documento definio la primera columna de
  // atributo Y el campo existe de verdad en su cds.
  else if (AConfig.Campos.AttrValor[1] <> '') and
          (AConfig.Cds <> nil) and
          (AConfig.Cds.FindField(AConfig.Campos.AttrValor[1]) <> nil) then
    Result := mcsDesglose
  else
    Result := mcsSku;
end;

function CrearModoEntradaGrid(const AConfig: TConfigColumnasSku)
                                                     : IModoEntradaGrid;
var
  Cfg: TConfigColumnasSku;
begin
  Cfg := AConfig;
  Cfg.Modo := DetectarModoColumnasSku(AConfig);
  if Cfg.Modo = mcsTallasInline then
    // Este modo necesita la TGridTallasConfig del documento.
    raise Exception.Create(
      'mcsTallasInline requiere CrearModoEntradaGridTallas');
  if Cfg.Modo = mcsDesglose then
    Result := TModoEntradaDesglose.Create(Cfg)
  else
    Result := TModoEntradaSku.Create(Cfg);
end;

function CrearModoEntradaGridTallas(const AConfig: TConfigColumnasSku;
                                    const ACfgTallas: TGridTallasConfig)
                                                     : IModoEntradaGrid;
var
  Cfg: TConfigColumnasSku;
begin
  Cfg := AConfig;
  Cfg.Modo := mcsTallasInline;
  Result := TModoEntradaTallas.Create(Cfg, ACfgTallas);
end;

function CrearProveedorValoresSku(AConexion: TUniConnection)
                                                     : IProveedorValoresSku;
begin
  Result := TProveedorValoresSku.Create(AConexion);
end;

end.
