{******************************************************************************}
{  Módulo: inLibFacturacionOperacionesPeriodoIntf                             }
{  Tipo: Contrato de aplicación                                               }
{  Descripción: Facturación por periodo de operaciones de TPV.                }
{******************************************************************************}
unit inLibFacturacionOperacionesPeriodoIntf;

interface

type
  TSolicitudFacturacionOperacionesPeriodo = record
    Empresa: string;
    Almacen: string;
    Caja: string;
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
    FechaDocumento: TDateTime;
    SerieFiscal: string;
    Usuario: string;
    IncluirVentasContado: Boolean;
    IncluirTraspasosEmpresas: Boolean;
  end;
  TResultadoFacturacionOperacionesPeriodo = record
    DocumentosInternos: Integer;
    FacturasFiscales: Integer;
    Ajustes: Integer;
    OperacionesProcesadas: Integer;
    function DocumentosGenerados: Integer;
  end;
  IServicioFacturacionOperacionesPeriodo = interface
    ['{ED14EF23-6AB0-4F0D-AF81-C9D077F05796}']
    function ObtenerSerieFiscalDefecto(
      const AEmpresa: string;
      AFecha: TDateTime): string;
    function ContarOperacionesPendientes(
      const ASolicitud: TSolicitudFacturacionOperacionesPeriodo): Integer;
    function Procesar(
      const ASolicitud: TSolicitudFacturacionOperacionesPeriodo
    ): TResultadoFacturacionOperacionesPeriodo;
  end;

implementation

function TResultadoFacturacionOperacionesPeriodo.DocumentosGenerados:
  Integer;
begin
  Result := DocumentosInternos + FacturasFiscales;
end;

end.
