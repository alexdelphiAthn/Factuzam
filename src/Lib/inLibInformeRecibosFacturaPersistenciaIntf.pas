unit inLibInformeRecibosFacturaPersistenciaIntf;

interface

type
  TCriteriosInformeRecibosFactura = record
    ReciboActual: Boolean;
    Serie: string;
    NumeroFactura: string;
    NumeroRecibo: string;
  end;

  IPreparadorInformeRecibosFactura = interface
    ['{D76B7E76-267A-47BF-B053-32E7CF0C6391}']
    procedure Preparar(const ACriterios: TCriteriosInformeRecibosFactura);
  end;

implementation

end.
