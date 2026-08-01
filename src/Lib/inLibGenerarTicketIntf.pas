unit inLibGenerarTicketIntf;

interface

type
  ILecturasImpresionTicket = interface
    ['{5BCB5644-7BB8-4B3A-A14D-0091E7C44B09}']
    function ListarPieCaja(
      const ACodigoEmpresa: string): TArray<string>;
    function ObtenerDiminutivoVendedor(
      const ACodigoEmpleado: string): string;
    function ObtenerCodigoBarras(
      const ASerie, ANumero: string): string;
  end;

implementation

end.
