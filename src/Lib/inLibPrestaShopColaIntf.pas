{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPrestaShopColaIntf                                      }
{    Tipo:       Contrato                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       13/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Contratos de la cola de cambios de catálogo por artículo.                 }
{******************************************************************************}
unit inLibPrestaShopColaIntf;

interface

uses
  System.SysUtils, inLibPrestaShopAltaArticuloIntf;

const
  CMarcaReanudacionAltaPrestaShop = '[ALTA_PRESTASHOP] ';

type
  TConfiguracionPrestaShopCola = record
    ClaveInstalacion: string;
    CodigoEmpresa: string;
    CodigoTarifa: string;
    IdTienda: Integer;
    IdIdioma: Integer;
    IdCategoriaRaiz: Integer;
    IdReglaIvaNormal: Integer;
    IdReglaIvaReducido: Integer;
    IdReglaIvaSuperreducido: Integer;
    IdReglaIvaExento: Integer;
    StockActivo: Boolean;
  end;

  TConfiguracionGlobalPrestaShop = record
    Activo: Boolean;
    SincronizarStockPrecios: Boolean;
    CrearArticulos: Boolean;
    UrlApi: string;
    ClaveApi: string;
    SegundosCiclo: Integer;
    HorasBarrido: Integer;
    MaxIntentos: Integer;
    Cola: TConfiguracionPrestaShopCola;
  end;

  TLineaArticuloPrestaShop = record
    CodigoSku: string;
    EsCombinacion: Boolean;
    TienePrecio: Boolean;
    TieneStock: Boolean;
    Precio: Double;
    Cantidad: Integer;
  end;

  TTrabajoArticuloPrestaShop = record
    IdCola: Int64;
    IdTienda: Integer;
    Intentos: Integer;
    VersionReclamada: Int64;
    CodigoArticulo: string;
    Token: string;
    EstaEnWeb: Boolean;
    EsServicio: Boolean;
    TienePrecio: Boolean;
    TieneStock: Boolean;
    TienePrecioProducto: Boolean;
    TieneProximoCambioPrecio: Boolean;
    ReanudarAlta: Boolean;
    PrecioProducto: Double;
    ProximoCambioPrecio: TDateTime;
    Lineas: TArray<TLineaArticuloPrestaShop>;
  end;

  IRepositorioPrestaShopCola = interface
    ['{D9C3F838-66D9-4B94-89F2-0BB742AD065E}']
    procedure EncolarCambio(
      const ACodigoArticulo, ACodigoUnidad: string;
      AEsPrecio, AEsStock: Boolean;
      const AUsuario: string);
    function LeerConfiguracionPerfil(
      const AUsuario, AGrupo: string): TConfiguracionGlobalPrestaShop;
    function DestinoSinConflictos(
      const AConfiguracion: TConfiguracionGlobalPrestaShop;
      const AUsuario: string): Boolean;
    procedure ReconciliarSiProcede(
      const AConfiguracion: TConfiguracionPrestaShopCola;
      AHoras: Integer;
      const AUsuario: string);
    procedure ReencolarProcesandoCaducadas(
      const AClaveInstalacion: string;
      AIdTienda: Integer;
      AMinutos: Integer);
    function BuscarPendientes(
      const AClaveInstalacion: string;
      AIdTienda: Integer;
      AMaximo: Integer): TArray<Int64>;
    function MarcarProcesando(
      AIdCola: Int64;
      const AClaveInstalacion: string;
      AIdTienda: Integer;
      const AUsuario: string;
      out AToken: string): Boolean;
    function LeerTrabajo(
      AIdCola: Int64;
      const AToken: string;
      const AConfiguracion: TConfiguracionPrestaShopCola):
      TTrabajoArticuloPrestaShop;
    function RenovarReclamacion(
      AIdCola: Int64;
      const AToken: string): Boolean;
    function MarcarAltaEnCurso(
      AIdCola: Int64;
      const AToken: string): Boolean;
    procedure MarcarEnviada(
      AIdCola: Int64;
      const AToken, AUsuario: string;
      ATieneProximoPrecio: Boolean;
      AProximoPrecio: TDateTime);
    procedure GuardarErrorIntento(
      AIdCola: Int64;
      const AToken, AEstado: string;
      AEsperaSegundos: Integer;
      const AMensaje, AUsuario: string);
  end;

  ISesionPrestaShopCola = interface
    ['{B1063C7D-9530-4B02-98B9-7BB1BD30D9BA}']
    function GetRepositorio: IRepositorioPrestaShopCola;
    function GetRepositorioAlta: IRepositorioAltaArticuloPresta;
    property Repositorio: IRepositorioPrestaShopCola read GetRepositorio;
    property RepositorioAlta: IRepositorioAltaArticuloPresta
      read GetRepositorioAlta;
  end;

  IFabricaSesionPrestaShopCola = interface
    ['{29CD2B79-0B12-49E6-B48C-39FA4506A230}']
    function CrearSesion: ISesionPrestaShopCola;
  end;

implementation

end.
