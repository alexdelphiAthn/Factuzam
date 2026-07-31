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
{    La implementación visual se recibe desde la raíz de composición.          }
{******************************************************************************}
unit inLibPreviewTicket;

interface

uses
  inLibFTicket;

type
  IPreviewTicket = interface
    ['{29DD4A66-34B6-4AA5-92D3-F2593146D3BE}']
    procedure Ejecutar(ATicket: TTicketTermico;
                       const AComandos, ARutaPDF,
                             ANombreImpresora: string;
                       ASoloPDF: Boolean);
  end;
  IProveedorPreviewTicket = interface
    ['{6688736E-FA46-4B5D-8D9D-051114636743}']
    function GetPreviewTicket: IPreviewTicket;
    property PreviewTicket: IPreviewTicket read GetPreviewTicket;
  end;

procedure ImprimirOPrevisualizarTicket(const APreview: IPreviewTicket;
                                       ATicket: TTicketTermico;
                                       const AComandos, ARutaPDF,
                                             ANombreImpresora: string;
                                       ASoloPDF: Boolean = False);

implementation
procedure ImprimirOPrevisualizarTicket(const APreview: IPreviewTicket;
  ATicket: TTicketTermico;
  const AComandos, ARutaPDF, ANombreImpresora: string;
  ASoloPDF: Boolean);
begin
  APreview.Ejecutar(
    ATicket, AComandos, ARutaPDF, ANombreImpresora, ASoloPDF);
end;

end.
