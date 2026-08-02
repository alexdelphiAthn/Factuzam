{******************************************************************************}
{                                                                              }
{  Modulo:       inLibMargenPersistenciaIntf                                  }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       FactuZam                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de datos para persistir coste y precio de salida calculados.       }
{******************************************************************************}
unit inLibMargenPersistenciaIntf;

interface

type
  TSolicitudPersistenciaMargen = record
    CodigoUnicoTarifa: Integer;
    CodigoArticulo: string;
    CodigoUnidad: string;
    Usuario: string;
    PrecioCoste: Double;
    PrecioSalida: Double;
  end;

  TResultadoPersistenciaMargen = record
    Guardado: Boolean;
    FaltaProveedorPrincipal: Boolean;
    MensajeError: string;
  end;

  IRepositorioMargen = interface
    ['{0D5D05A3-71EA-4259-BAEA-97EDE3FEFCD6}']
    function Guardar(
      const ASolicitud: TSolicitudPersistenciaMargen
    ): TResultadoPersistenciaMargen;
  end;

implementation

end.
