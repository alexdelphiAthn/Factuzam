{******************************************************************************}
{                                                                              }
{  Módulo:       inLibEmisionFiscalIntf                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos para emitir facturas mediante una estrategia fiscal.            }
{******************************************************************************}
unit inLibEmisionFiscalIntf;

interface

uses
  inLibVerifactu;

type
  TFlujoEmisionFiscal = (
    fefOperacion,
    fefConsolidacion);
  TSolicitudEmisionFiscal = record
    Serie: string;
    Numero: string;
    Usuario: string;
    TipoOperacion: string;
    Accion: string;
    DescripcionEvento: string;
    BorrarMovimientos: Boolean;
    Flujo: TFlujoEmisionFiscal;
    class function ParaOperacion(
      const ASerie, ANumero, AUsuario,
      ATipoOperacion, AAccion: string;
      ABorrarMovimientos: Boolean
    ): TSolicitudEmisionFiscal; static;
    class function ParaConsolidacion(
      const ASerie, ANumero, AUsuario: string
    ): TSolicitudEmisionFiscal; static;
  end;
  TResultadoEmisionFiscal = record
    Modo: TModoVerifactu;
    Mensaje: string;
  end;
  IServicioEmisionFiscal = interface
    ['{513E78E8-7755-413F-A033-7D5BC02C29C9}']
    function Emitir(
      const ASolicitud: TSolicitudEmisionFiscal
    ): TResultadoEmisionFiscal;
    function Modo: TModoVerifactu;
  end;

implementation

class function TSolicitudEmisionFiscal.ParaOperacion(
  const ASerie, ANumero, AUsuario,
  ATipoOperacion, AAccion: string;
  ABorrarMovimientos: Boolean
): TSolicitudEmisionFiscal;
begin
  Result.Serie := ASerie;
  Result.Numero := ANumero;
  Result.Usuario := AUsuario;
  Result.TipoOperacion := ATipoOperacion;
  Result.Accion := AAccion;
  Result.DescripcionEvento :=
    AAccion + ' encolada desde Borradores';
  Result.BorrarMovimientos := ABorrarMovimientos;
  Result.Flujo := fefOperacion;
end;

class function TSolicitudEmisionFiscal.ParaConsolidacion(
  const ASerie, ANumero, AUsuario: string
): TSolicitudEmisionFiscal;
begin
  Result.Serie := ASerie;
  Result.Numero := ANumero;
  Result.Usuario := AUsuario;
  Result.TipoOperacion := 'ALTA';
  Result.Accion := '';
  Result.DescripcionEvento :=
    'Lanzamiento manual (Consolidar) desde Borradores';
  Result.BorrarMovimientos := True;
  Result.Flujo := fefConsolidacion;
end;

end.
