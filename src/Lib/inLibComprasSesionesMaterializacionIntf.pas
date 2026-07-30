{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasSesionesMaterializacionIntf                       }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos del caso de uso de materialización de sesiones de compra.       }
{******************************************************************************}
unit inLibComprasSesionesMaterializacionIntf;

interface

uses
  inLibComprasSesionesIntf;

type
  TColorLineaMaterializacion = record
    Texto: string;
    CodigoBasico: string;
  end;
  TValorColorMaterializacion = record
    IdValor: Integer;
    TieneColorBasico: Boolean;
  end;
  TSkuSesionMaterializacion = record
    IdFila: Integer;
    IdAvPivot: Integer;
    CantidadTotal: Double;
    ValorPivot: string;
    ValorFila: string;
    IdAvFila: Integer;
  end;
  TSkusSesionMaterializacion =
    array of TSkuSesionMaterializacion;
  TLineaArticuloMaterializacion = record
    Linea: Integer;
    PrecioCosteProveedor: Double;
    AccionDuplicado: string;
    CodigoArticuloReusar: string;
    CodigoArticuloTentativo: string;
    TipoLinea: string;
    ReferenciaProveedor: string;
    PrecioVenta: Double;
  end;
  TLineasArticuloMaterializacion =
    array of TLineaArticuloMaterializacion;
  TLineaDocumentoCompraMaterializacion = record
    CodigoArticulo: string;
    IdAvPivot: Integer;
    IdAcPivot: Integer;
    CodigoColor: string;
    ColorTexto: string;
    Almacen: string;
    Cantidad: Double;
    PrecioCompra: Double;
    Descripcion: string;
    CodigoFamilia: string;
    TipoIva: string;
    TipoLinea: string;
    ReferenciaProveedor: string;
  end;
  TLineasDocumentoCompraMaterializacion =
    array of TLineaDocumentoCompraMaterializacion;
  TPendienteRecibirMaterializacion = record
    Linea: Integer;
    IdAvPivot: Integer;
    Cantidad: Double;
    Almacen: string;
    CodigoArticuloTentativo: string;
    CodigoArticuloReusar: string;
    AccionDuplicado: string;
    PrecioCompra: Double;
    TipoLinea: string;
    IdAvFila: Integer;
  end;
  TPendientesRecibirMaterializacion =
    array of TPendienteRecibirMaterializacion;
  TConfiguracionMaterializacionSesion = record
    GeneraPedido: Boolean;
    GeneraAlbaran: Boolean;
    Empresa: string;
    AlmacenCabecera: string;
  end;
  IUnidadTrabajoMaterializacion = interface
    ['{9E08F774-A694-4F35-AE4A-55E370D150CB}']
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;
  IControlTransaccionMaterializacion = interface
    ['{BA982679-8388-40A1-B1CC-A5A2183DFCB7}']
    function EnTransaccion: Boolean;
    procedure IniciarTransaccion;
    procedure ConfirmarTransaccion;
    procedure RevertirTransaccion;
  end;
  ILecturasMaterializacionComprasSesiones = interface
    ['{7B5E18B7-ED6F-45D8-993B-E70859791730}']
    function ObtenerSiguienteSecuenciaEan(
      const APrefijo: string;
      ALongitudSecuencia: Integer): Int64;
    function ObtenerIdColorBasico(
      const ACodigoColor: string): Integer;
    function BuscarValorColor(
      const AValor: string): TValorColorMaterializacion;
    function ObtenerColorLinea(
      const ASerie, ANumero: string;
      ALinea: Integer): TColorLineaMaterializacion;
    function ConsultarSkusSesion(
      const ASerie, ANumero: string;
      ALinea: Integer): TSkusSesionMaterializacion;
    function ExisteEan13Sku(
      const ACodigoSku: string): Boolean;
    function ExisteProveedorPrincipalDistinto(
      const ACodigoArticulo,
      ACodigoProveedor: string): Boolean;
    function ObtenerCodigoUnicoTarifa(
      const ACodigoArticulo,
      ACodigoTarifa: string): Integer;
    function ResolverCodigoSku(
      const ACodigoArticulo: string;
      AIdAvPivot, AIdAvFila: Integer): string;
    function ConsultarLineasArticulos(
      const ASerie, ANumero: string):
      TLineasArticuloMaterializacion;
    function ConsultarLineasDocumento(
      const ASerie, ANumero, AAlmacenCabecera,
      AFiltroAlmacen: string):
      TLineasDocumentoCompraMaterializacion;
    function ConsultarAlmacenes(
      const ASerie, ANumero,
      AAlmacenCabecera: string): TArray<string>;
    function ConsultarPendientesRecibir(
      const ASerie, ANumero,
      AAlmacenCabecera: string):
      TPendientesRecibirMaterializacion;
    function ExisteTabla(
      const ATabla: string): Boolean;
    function ConsultarMovimientosHuerfanos(
      const AEmpresa, AAlmacen: string): TArray<string>;
  end;
  IPersistenciaMaterializacionComprasSesiones = interface
    ['{673F12BB-E724-4C8D-918F-F15380DF44A0}']
    function ValidarMaterializacion(
      out AMensajeError: string): Boolean;
    function CargarConfiguracion:
      TConfiguracionMaterializacionSesion;
    function ConsultarAlmacenes: TArray<string>;
    function ResolverSerieDocumento(
      const AEmpresa, ATipoDocumento, AAlmacen,
      ASerieAlternativa: string): string;
    procedure MaterializarArticulos(
      const AUsuario: string);
    function MaterializarPedido(
      const AUsuario, ASerie, AAlmacen: string):
      TDocumentoMaterializado;
    function MaterializarAlbaran(
      const AUsuario, ASerie, AAlmacen: string):
      TDocumentoMaterializado;
    procedure CerrarSesion(
      const APedido, AAlbaran: TDocumentoMaterializado;
      const AUsuario: string);
    procedure RegistrarError(
      const AUsuario, AMensaje: string);
  end;
  IPersistenciaReversionComprasSesiones = interface
    ['{21314426-B962-4305-8EAC-AEADE45CD2D7}']
    function ValidarReversion(
      out AMensajeError: string): Boolean;
    procedure EjecutarReversion(
      const AUsuario: string);
  end;

implementation

end.
