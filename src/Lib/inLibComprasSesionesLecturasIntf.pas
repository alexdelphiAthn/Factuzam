{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasSesionesLecturasIntf                              }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos de lectura para materializar sesiones de compra.                }
{******************************************************************************}
unit inLibComprasSesionesLecturasIntf;
interface
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
  TSkusSesionMaterializacion = array of TSkuSesionMaterializacion;
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
  TDocumentoReversionMaterializacion = record
    Tipo: string;
    Serie: string;
    Numero: string;
  end;
  TDocumentosReversionMaterializacion =
    array of TDocumentoReversionMaterializacion;
  ILecturasArticulosMaterializacion = interface
    ['{823D7E9F-C5CB-4132-9B95-FCE88EDB9F94}']
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
  end;
  ILecturasDocumentosMaterializacion = interface
    ['{4C218CB4-28AF-4490-9619-99B879A91EED}']
    function ConsultarLineasDocumento(
      const ASerie, ANumero, AAlmacenCabecera,
      AFiltroAlmacen: string):
      TLineasDocumentoCompraMaterializacion;
  end;
  ILecturasEstadoMaterializacion = interface
    ['{B94239E4-389A-4B5D-BFA9-FC84144DE85F}']
    function ConsultarAlmacenes(
      const ASerie, ANumero,
      AAlmacenCabecera: string): TArray<string>;
  end;
  ILecturasPendientesMaterializacion = interface
    ['{31A6E4AB-9BB3-4020-9900-716551021E9C}']
    function ConsultarPendientesRecibir(
      const ASerie, ANumero,
      AAlmacenCabecera: string):
      TPendientesRecibirMaterializacion;
  end;
  ILecturasReversionMaterializacion = interface
    ['{6DD05B46-E5C9-4F89-9813-2BC8B7762A72}']
    function ExisteTabla(
      const ATabla: string): Boolean;
    function BloqueosReversionVigentes: Boolean;
    function ConsultarDocumentosSesion(
      const ASerie, ANumero: string):
      TDocumentosReversionMaterializacion;
    function ConsultarFacturasCompraAlbaran(
      const ASerie, ANumero: string): TArray<string>;
    function ConsultarSalidasPosterioresAlbaran(
      const ASerie, ANumero: string): TArray<string>;
    function ConsultarAlbaranesPedido(
      const ASerie, ANumero: string):
      TDocumentosReversionMaterializacion;
  end;
  TLecturasAlbaranesMaterializacion = record
    Articulos: ILecturasArticulosMaterializacion;
    Documentos: ILecturasDocumentosMaterializacion;
  end;
  TLecturasPedidosMaterializacion = record
    Articulos: ILecturasArticulosMaterializacion;
    Documentos: ILecturasDocumentosMaterializacion;
    Pendientes: ILecturasPendientesMaterializacion;
  end;
  TServiciosLecturasMaterializacion = record
    Articulos: ILecturasArticulosMaterializacion;
    Albaranes: TLecturasAlbaranesMaterializacion;
    Estado: ILecturasEstadoMaterializacion;
    Pedidos: TLecturasPedidosMaterializacion;
    Reversion: ILecturasReversionMaterializacion;
  end;
implementation
end.
