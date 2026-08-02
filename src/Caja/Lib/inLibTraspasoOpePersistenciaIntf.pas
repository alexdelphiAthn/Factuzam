{******************************************************************************}
{                                                                              }
{  Modulo:       inLibTraspasoOpePersistenciaIntf                             }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       FactuZam                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de lectura auxiliar de la operativa de traspasos.                  }
{******************************************************************************}
unit inLibTraspasoOpePersistenciaIntf;

interface

type
  TAlmacenDestinoTraspaso = record
    Codigo: string;
    Nombre: string;
  end;

  TAlmacenesDestinoTraspaso = TArray<TAlmacenDestinoTraspaso>;

  IRepositorioTraspasoOpe = interface
    ['{63C74CB2-AD1B-47B5-B405-4F750B037DF1}']
    function ListarAlmacenesDestino(
      const AAlmacenPropio: string): TAlmacenesDestinoTraspaso;
  end;

implementation

end.
