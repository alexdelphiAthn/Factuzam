{******************************************************************************}
{                                                                              }
{  Módulo:       inLibStockConsultaPersistenciaIntf                           }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puertos de persistencia para la consulta visual de stock.                }
{******************************************************************************}
unit inLibStockConsultaPersistenciaIntf;

interface

uses
  Data.DB;

type
  TEstadoStock = (
    esExistencias,
    esEntradas,
    esSalidas,
    esVentas,
    esRegularizadas,
    esEntradaTraspaso,
    esSalidaTraspaso,
    esPdteRecibir,
    esPdteServir,
    esPrestadas,
    esTodoAlaVez,
    esEntradaCompra,
    esEntradaDeposito,
    esSalidaDeposito,
    esSalidaAlbVenta,
    esEntradaAlbEntrada);
  TInfoColumna = record
    Codigo: string;
    Texto: string;
    Hex: string;
    EsColor: Boolean;
  end;
  TDimensionFotos = (dfFamilia, dfProveedor, dfTemporada);
  TDimensionesFotos = set of TDimensionFotos;
  TSolicitudPivoteStock = record
    CodigoArticulo: string;
    Estado: TEstadoStock;
    ModoDesglosado: Boolean;
    PorColor: Boolean;
    OcultarCeros: Boolean;
    Almacenes: TArray<string>;
    Colores: TArray<string>;
  end;
  TSolicitudFotosRelacionadasStock = record
    CodigoArticulo: string;
    Dimension: TDimensionFotos;
    Filtros: TDimensionesFotos;
  end;
  IResultadoConsultaStock = interface
    ['{4CAEE753-F23F-4F5C-BBC2-53DF6F31EE29}']
    function DataSet: TDataSet;
  end;
  ILectorCatalogosStockConsulta = interface
    ['{3633201A-FF85-46A3-B729-3A03C8FC2535}']
    function ResolverTextoArticulo(
      const AEntrada: string): IResultadoConsultaStock;
    function ResolverSku(
      const ACodigoArticulo, AColor, ATalla: string;
      out ACodigoSku: string): Integer;
    function ConsultarAlmacenes: IResultadoConsultaStock;
    function ConsultarColores(
      const ACodigoArticulo, ACodigoSku: string): IResultadoConsultaStock;
    function ConsultarPropiedadesPorColor(
      const ACodigoArticulo: string): IResultadoConsultaStock;
    function ObtenerDescripcionArticulo(
      const ACodigoArticulo: string;
      out ADescripcion: string): Boolean;
    function ConsultarFotosRelacionadas(
      const ASolicitud: TSolicitudFotosRelacionadasStock
    ): IResultadoConsultaStock;
    function BuscarArticulos(
      const ACodigoTarifa: string): IResultadoConsultaStock;
  end;
  IRepositorioPivoteStock = interface
    ['{2D4F1FD5-B21B-4380-8A65-8848114FD67F}']
    function ListarTallas(
      const ACodigoArticulo: string;
      const AColores: TArray<string>): TArray<TInfoColumna>;
    function Consultar(
      const ASolicitud: TSolicitudPivoteStock;
      const ATallas: TArray<TInfoColumna>): IResultadoConsultaStock;
  end;
  TServiciosStockConsulta = record
    Catalogos: ILectorCatalogosStockConsulta;
    Pivote: IRepositorioPivoteStock;
  end;

implementation

end.
