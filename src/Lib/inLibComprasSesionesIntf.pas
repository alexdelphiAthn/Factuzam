{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasSesionesIntf                                      }
{    Tipo:       Contrato                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos de persistencia del agregado de sesiones de compra.             }
{******************************************************************************}
unit inLibComprasSesionesIntf;

interface

type
  TCantidadPivotSesion = record
    IdValorPivot: Integer;
    Cantidad: Double;
  end;
  TCantidadesPivotSesion = array of TCantidadPivotSesion;
  TIncidenciasSesionCompra = array of string;
  TResolverDuplicadoSesion = record
    Encontrado: Boolean;
    Origen: string;
    CodigoArt: string;
    DescripcionArt: string;
    CodigoFam: string;
    NombreFam: string;
    IdAcPivot: Integer;
    IdVaPivot: string;
    IdAcFila: Integer;
    IdVaFila: string;
    TipoVariacion: string;
    EsVariacion: Boolean;
    EsTrazable: Boolean;
    TipoArt: string;
    TipoIva: string;
    TipoCantidad: string;
    UltimoCoste: Double;
    PrecioVenta: Double;
    RefProveedor: string;
    LineaOrigen: Integer;
    ColorTexto: string;
    CodigoAtbColor: string;
    MargenPorcentaje: Double;
  end;
  TParametrosMaterializacionSesion = record
    Usuario: string;
    SerieAlbaran: string;
    SeriePedido: string;
    UnDocumentoPorAlmacen: Boolean;
  end;
  TDocumentoMaterializado = record
    Tipo: string;
    Serie: string;
    Numero: string;
    Almacen: string;
  end;
  TDocumentosMaterializados = array of TDocumentoMaterializado;
  TResultadoMaterializacionSesion = record
    SeriePedido: string;
    NumeroPedido: string;
    SerieAlbaran: string;
    NumeroAlbaran: string;
    MensajeError: string;
    Documentos: TDocumentosMaterializados;
  end;
  IRepositorioComprasSesiones = interface
    ['{85E32940-2F4B-4FF5-B802-9169FD111B88}']
    procedure AplicarDuplicadoEnLinea(
      const AResultado: TResolverDuplicadoSesion);
    procedure BorrarCeldasLinea(
      const ASerie, ANumero: string;
      ALinea: Integer);
    procedure CopiarCeldasDistribuidas(
      const ASerie, ANumero, AAlmacenCabecera, AUsuario: string;
      ALineaOrigen, ALineaDestino: Integer);
    function ObtenerSiguienteLinea(
      const ASerie, ANumero: string;
      ALineaActual: Integer): Integer;
    function ConsultarCantidadesLinea(
      const ASerie, ANumero: string;
      ALinea: Integer): TCantidadesPivotSesion;
    function ConsultarCodigosBasicosActivos(
      const AIdVariacion: string): TArray<string>;
    function ObtenerNombreFamilia(
      const ACodigoFamilia: string): string;
    function ResolverCodigoFamilia(
      const ACodigoTecleado, AUsuario: string;
      out ACodigoGenerado: string): Boolean;
    function ResolverDuplicado(
      const ACodigoBuscado, ACodigoProveedor: string;
      ASoloRefProveedor: Boolean;
      const ACodigoArticuloPreferido: string):
      TResolverDuplicadoSesion;
    function ResolverDuplicadoIntraSesion(
      const ASerie, ANumero: string;
      ALineaActual: Integer;
      const AModelo, ACodigoArticulo: string):
      TResolverDuplicadoSesion;
    function NormalizarDuplicadosIntraSesion(
      const AUsuario, ASerie, ANumero: string): Integer;
    function ValidarSesionDetallado:
      TIncidenciasSesionCompra;
    function EjecutarMaterializacion(
      const AParametros: TParametrosMaterializacionSesion;
      out AResultado: TResultadoMaterializacionSesion): Boolean;
    function RevertirMaterializacion(
      const AUsuario: string;
      out AMensajeError: string): Boolean;
  end;

implementation

end.
