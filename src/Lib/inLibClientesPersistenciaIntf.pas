{******************************************************************************}
{                                                                              }
{  Modulo:       inLibClientesPersistenciaIntf                                }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de persistencia para operaciones propias de clientes.             }
{******************************************************************************}
unit inLibClientesPersistenciaIntf;

interface

type
  IRepositorioClientes = interface
    ['{1F2BA840-C1E2-4353-B5FF-712B3ECF1BBB}']
    function ContarDocumentos(const ACodigoCliente: string): Integer;
  end;

implementation

end.
