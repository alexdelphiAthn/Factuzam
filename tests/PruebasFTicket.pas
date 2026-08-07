{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFTicket                                                }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       07/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Comprueba el avance de papel previo al corte de tickets térmicos.         }
{******************************************************************************}
unit PruebasFTicket;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFTicket = class
  public
    [Test]
    procedure AvanzaNueveLineasAntesDelCorte;
  end;

implementation

uses
  System.SysUtils,
  inLibFTicket;

procedure TPruebasFTicket.AvanzaNueveLineasAntesDelCorte;
var
  iInicioAvance, iInicioCorte: Integer;
  oTicket: TTicketTermico;
  sComandos, sEntrePieYCorte: string;
begin
  oTicket := TTicketTermico.Create('DEBUG');
  try
    oTicket.EscribirLinea('PIE EMPRESA');
    oTicket.AvanzarYCortarPapel;
    sComandos := oTicket.ObtenerComandos;
    iInicioAvance := Pos('PIE EMPRESA' + #13#10, sComandos) +
      Length('PIE EMPRESA' + #13#10);
    iInicioCorte := Pos(#27 + 'i', sComandos);
    sEntrePieYCorte := Copy(
      sComandos,
      iInicioAvance,
      iInicioCorte - iInicioAvance);
    Assert.AreEqual(#27 + 'd' + #9, sEntrePieYCorte);
  finally
    FreeAndNil(oTicket);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFTicket);

end.
