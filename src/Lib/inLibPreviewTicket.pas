{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPreviewTicket                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato neutral para imprimir o previsualizar tickets.                   }
{    La capa de formularios registra la implementación visual al arrancar.     }
{******************************************************************************}
unit inLibPreviewTicket;

interface

uses
  System.SysUtils,
  inLibFTicket;

type
  TEjecutorPreviewTicket = class
  public
    class procedure Ejecutar(ATicket: TTicketTermico;
                             const AComandos, ARutaPDF,
                                   ANombreImpresora: string;
                             ASoloPDF: Boolean); virtual; abstract;
  end;

  TClaseEjecutorPreviewTicket = class of TEjecutorPreviewTicket;

  TPreviewTicket = class
  private
    class var FClaseEjecutor: TClaseEjecutorPreviewTicket;
  public
    class procedure RegistrarEjecutor(
      AClase: TClaseEjecutorPreviewTicket);
    class procedure Ejecutar(ATicket: TTicketTermico;
                             const AComandos, ARutaPDF,
                                   ANombreImpresora: string;
                             ASoloPDF: Boolean);
  end;

procedure ImprimirOPrevisualizarTicket(ATicket: TTicketTermico;
                                       const AComandos, ARutaPDF,
                                             ANombreImpresora: string;
                                       ASoloPDF: Boolean = False);

implementation

uses
  inLibMsgFacturas;

class procedure TPreviewTicket.RegistrarEjecutor(
  AClase: TClaseEjecutorPreviewTicket);
begin
  FClaseEjecutor := AClase;
end;

class procedure TPreviewTicket.Ejecutar(ATicket: TTicketTermico;
  const AComandos, ARutaPDF, ANombreImpresora: string;
  ASoloPDF: Boolean);
begin
  if not Assigned(FClaseEjecutor) then
    raise Exception.Create(SErrorPreviewTicketNoRegistrado);
  FClaseEjecutor.Ejecutar(
    ATicket, AComandos, ARutaPDF, ANombreImpresora, ASoloPDF);
end;

procedure ImprimirOPrevisualizarTicket(ATicket: TTicketTermico;
  const AComandos, ARutaPDF, ANombreImpresora: string;
  ASoloPDF: Boolean);
begin
  TPreviewTicket.Ejecutar(
    ATicket, AComandos, ARutaPDF, ANombreImpresora, ASoloPDF);
end;

end.
