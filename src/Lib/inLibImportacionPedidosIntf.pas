{******************************************************************************}
{                                                                              }
{  Módulo:       inLibImportacionPedidosIntf                                  }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos para importar pedidos desde una fuente externa.                 }
{******************************************************************************}
unit inLibImportacionPedidosIntf;

interface

uses
  System.Generics.Collections,
  inLibPresta;

type
  TResumenPedidoImportacion = record
    IdPedido: string;
    Referencia: string;
    Fecha: string;
    Cliente: string;
    Total: string;
    Estado: string;
  end;
  TResumenPedidosImportacion = TList<TResumenPedidoImportacion>;
  TIdsPedidosImportacion = TArray<string>;
  TEstadoImportacionPedido = (
    eipImportando,
    eipImportado,
    eipOmitido,
    eipError
  );
  TSolicitudImportacionPedidos = record
    BaseURL: string;
    ApiKey: string;
    IdsPedidos: TIdsPedidosImportacion;
  end;
  TResultadoImportacionPedidos = record
    Importados: Integer;
    Errores: Integer;
  end;
  TProgresoImportacionPedido = reference to procedure(
    const AIdPedido: string;
    AEstado: TEstadoImportacionPedido;
    const AError: string);
  IFuentePedidosImportacion = interface
    ['{173DB2B9-71E7-4E02-8FD3-51A6C4D8F336}']
    function ListarResumen(
      ALista: TResumenPedidosImportacion): Boolean;
    function CargarPedido(const AIdPedido: string): TOrder;
  end;
  IFabricaFuentePedidosImportacion = interface
    ['{9E4DE018-642E-414B-865B-E1875E0F60E2}']
    function Crear(
      const ABaseURL, AApiKey: string): IFuentePedidosImportacion;
  end;
  IRepositorioImportacionPedidos = interface
    ['{127C859A-CB36-458F-A14D-5816374C20C4}']
    function Existe(const AIdPedido: string): Boolean;
    function Importar(APedido: TOrder): Boolean;
  end;
  ICasoUsoImportacionPedidos = interface
    ['{AE39CCCF-D565-4CE7-AB8E-86B3007552AD}']
    function Listar(
      const ABaseURL, AApiKey: string;
      ALista: TResumenPedidosImportacion): Boolean;
    function EstaImportado(const AIdPedido: string): Boolean;
    function Ejecutar(
      const ASolicitud: TSolicitudImportacionPedidos;
      const AOnProgreso: TProgresoImportacionPedido
    ): TResultadoImportacionPedidos;
  end;

implementation

end.
