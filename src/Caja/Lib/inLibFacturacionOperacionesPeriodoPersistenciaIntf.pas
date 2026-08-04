{******************************************************************************}
{  Módulo: inLibFacturacionOperacionesPeriodoPersistenciaIntf                 }
{  Tipo: Contrato de persistencia                                             }
{  Descripción: Lectura del informe de facturación de operaciones TPV.        }
{******************************************************************************}
unit inLibFacturacionOperacionesPeriodoPersistenciaIntf;

interface

uses
  Data.DB;

type
  TSolicitudInformeFacturacionOperacionesPeriodo = record
    Empresa: string;
    Almacen: string;
    Caja: string;
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
  end;
  IResultadoInformeFacturacionOperacionesPeriodo = interface
    ['{D07232A6-F338-49DD-ABDA-021037915BE0}']
    function DataSet: TDataSet;
  end;
  IRepositorioInformeFacturacionOperacionesPeriodo = interface
    ['{6AB0DBD3-A268-4102-A5F0-19E63DB26750}']
    function Consultar(
      const ASolicitud: TSolicitudInformeFacturacionOperacionesPeriodo
    ): IResultadoInformeFacturacionOperacionesPeriodo;
  end;

implementation

end.
