unit inLibInformeFacturaPersistenciaIntf;

interface

type
  TCriteriosInformeFactura = record
    FacturaActual: Boolean;
    Serie: string;
    Numero: string;
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
  end;

  IPreparadorInformeFactura = interface
    ['{66F296F6-FD03-4172-85E5-2CA49E4C5AF6}']
    procedure Preparar(const ACriterios: TCriteriosInformeFactura);
  end;

implementation

end.
