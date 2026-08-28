unit inLibInformeMovimientosVentasArticuloPersistenciaIntf;

interface

uses
  Data.DB;

type
  TOrdenMovVentasArt = (
    omvaUnidadesVenta,
    omvaImporteVenta,
    omvaImporteCoste,
    omvaBeneficio,
    omvaPorcentajeBeneficio,
    omvaImporteVentaCompras
  );

  TCriteriosInformeMovimientosVentasArticulo = record
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
    UsarInicioCompras: Boolean;
    InicioCompras: TDateTime;
    Almacenes: string;
    Familias: string;
    Proveedores: string;
    Temporadas: string;
    Articulos: string;
    Nivel1: string;
    Nivel2: string;
    Nivel3: string;
    NivelFamilia: Integer;
    SoloVentas: Boolean;
    ConImpuestos: Boolean;
    UsarOrden: Boolean;
    Orden: TOrdenMovVentasArt;
    OrdenDescendente: Boolean;
  end;

  IResultadoInformeMovimientosVentasArticulo = interface
    ['{24EDBA9F-6521-4BFB-8028-30EDE48CDE81}']
    function DataSet: TDataSet;
  end;

  IRepositorioInformeMovimientosVentasArticulo = interface
    ['{16CF59D7-5FD5-4A2E-AFD8-06FF2F541A82}']
    function Preparar(
      const ACriterios: TCriteriosInformeMovimientosVentasArticulo
    ): IResultadoInformeMovimientosVentasArticulo;
  end;

implementation

end.
