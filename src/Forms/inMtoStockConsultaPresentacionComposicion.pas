{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoStockConsultaPresentacionComposicion                     }
{    Tipo:       Composicion de pantalla                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Unico punto donde la consulta de stock resuelve sus adaptadores de        }
{    persistencia. Devuelve un contexto de feature cerrado para que la         }
{    pantalla no vuelva a descubrir repositorios durante un evento.            }
{******************************************************************************}
unit inMtoStockConsultaPresentacionComposicion;

interface

uses
  System.Classes, Uni,
  inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf,
  inLibDocumentosTrabajo,
  inLibLectorScanner,
  inLibRepositoriosPantallaIntf,
  inLibStockConsultaEntradaIntf,
  inLibStockConsultaInfo,
  inLibStockConsultaPersistenciaIntf;

type
  // Resumen de cabecera (propiedades, tarifas y proveedores) detras de un
  // contrato propio: la pantalla no conoce el data module que lo lee.
  ILectorInfoCabeceraStock = interface
    ['{6E1B4C7A-0D2F-49B8-9C31-5A70F4E2D118}']
    function Cargar(
      const ACodigoArticulo: string): TInfoCabeceraStock;
  end;

  // Capacidades que la consulta de stock necesita del exterior. Los
  // adaptadores de persistencia los resuelve CrearContextoStockConsulta y
  // el lector y la aplicacion de entrada se completan al componer los
  // presentadores. La pantalla no las localiza por su cuenta durante un
  // evento: solo lee este contexto.
  TContextoDependenciasStockConsulta = record
    Catalogos: ILectorCatalogosStockConsulta;
    Pivote: IRepositorioPivoteStock;
    InfoCabecera: ILectorInfoCabeceraStock;
    Validador: IArticulosValidador;
    ResolverArticulos: IArticulosResolver;
    DocumentosTrabajo: TRepositoriosDocumentosTrabajo;
    Lector: TLectorScanner;
    Entrada: IAplicacionEntradaStock;
    procedure Liberar;
  end;

function CrearContextoStockConsulta(
  AOrigen: TComponent;
  AConexion: TUniConnection): TContextoDependenciasStockConsulta;

implementation

uses
  System.SysUtils,
  UniDataStockConsultaInfo;

type
  TLectorInfoCabeceraStockUniData = class(
    TInterfacedObject,
    ILectorInfoCabeceraStock)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function Cargar(
      const ACodigoArticulo: string): TInfoCabeceraStock;
  end;

constructor TLectorInfoCabeceraStockUniData.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TLectorInfoCabeceraStockUniData.Cargar(
  const ACodigoArticulo: string): TInfoCabeceraStock;
begin
  Result := CargarInfoCabeceraStock(FConexion, ACodigoArticulo);
end;

// El contexto es propietario del lector; el resto son contratos que solo
// hay que soltar.
procedure TContextoDependenciasStockConsulta.Liberar;
begin
  Entrada := nil;
  FreeAndNil(Lector);
  Catalogos := nil;
  Pivote := nil;
  InfoCabecera := nil;
  Validador := nil;
  ResolverArticulos := nil;
  DocumentosTrabajo.Lecturas := nil;
  DocumentosTrabajo.Escritura := nil;
  DocumentosTrabajo.Materializacion := nil;
end;

function CrearContextoStockConsulta(
  AOrigen: TComponent;
  AConexion: TUniConnection): TContextoDependenciasStockConsulta;
var
  Articulos: IRepositoriosArticulosPantalla;
  Documentos: IRepositoriosDocumentosPantalla;
  Servicios: TServiciosStockConsulta;
begin
  Result := Default(TContextoDependenciasStockConsulta);
  Articulos := ObtenerCompositorArticulosPantalla(AOrigen).
    CrearRepositoriosArticulosPantalla(AOrigen.Name);
  Documentos := ObtenerCompositorDocumentosPantalla(AOrigen).
    CrearRepositoriosDocumentosPantalla(AOrigen.Name);
  Servicios := Articulos.CrearServiciosStockConsulta(AConexion);
  Result.Catalogos := Servicios.Catalogos;
  Result.Pivote := Servicios.Pivote;
  Result.InfoCabecera :=
    TLectorInfoCabeceraStockUniData.Create(AConexion);
  Result.Validador := Articulos.CrearValidadorArticulos(
    AConexion);
  Result.ResolverArticulos :=
    Articulos.CrearResolverArticulos(AConexion);
  Result.DocumentosTrabajo :=
    Documentos.CrearRepositoriosDocumentosTrabajo(
      AConexion);
end;

end.
