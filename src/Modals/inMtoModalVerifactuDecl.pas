{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalVerifactuDecl                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Declaración responsable del sistema informático de facturación            }
{    (art. 13 del RD 1007/2023). Muestra el texto con los datos del SIF        }
{    (nombre, versión, productor e instalación) en un memo de solo lectura.    }
{******************************************************************************}
unit inMtoModalVerifactuDecl;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxTextEdit, cxMemo, cxButtons,
  inMtoFrmBase;

type
  TfrmModalVerifactuDecl = class(TfrmBase)
    mDeclaracion: TcxMemo;
    pnlButton: TPanel;
    btnAceptar: TcxButton;
  private
    procedure CargarTexto;
  public
    class procedure Ejecutar(AOwner: TComponent);
  end;

implementation

uses
  inLibGlobalVar, inLibAppParam;

{$R *.dfm}

class procedure TfrmModalVerifactuDecl.Ejecutar(AOwner: TComponent);
var
  frm: TfrmModalVerifactuDecl;
begin
  frm := TfrmModalVerifactuDecl.Create(AOwner);
  try
    frm.CargarTexto;
    frm.ShowModal;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalVerifactuDecl.CargarTexto;
var
  sProductor:   string;
  sNif:         string;
  sInstalacion: string;
begin
  sProductor   := oAppParams.GetString('appVerifactuSifNombreRazon',
                                       'Alejandro Laorden Hidalgo');
  sNif         := oAppParams.GetString('appVerifactuSifNif', '');
  sInstalacion := oAppParams.GetString('appVerifactuIdInstalacion', '1');
  mDeclaracion.Lines.Text :=
    'DECLARACIÓN RESPONSABLE DEL SISTEMA INFORMÁTICO DE FACTURACIÓN' +
    sLineBreak + sLineBreak +
    'Sistema informático:      Factuzam' + sLineBreak +
    'Id. del sistema (SIF):    FZ' + sLineBreak +
    'Versión:                  ' + oVersion + sLineBreak +
    'Productor:                ' + sProductor + sLineBreak +
    'NIF del productor:        ' + sNif + sLineBreak +
    'Número de instalación:    ' + sInstalacion + sLineBreak +
    'Modalidad:                VERI*FACTU (emisión de facturas ' +
    'verificables)' + sLineBreak + sLineBreak +
    'El productor arriba identificado declara, bajo su responsabilidad, ' +
    'que este sistema informático de facturación cumple con lo dispuesto ' +
    'en el artículo 29.2.j) de la Ley 58/2003, de 17 de diciembre, ' +
    'General Tributaria, en el Reglamento que establece los requisitos ' +
    'de los sistemas y programas informáticos o electrónicos que ' +
    'soporten los procesos de facturación, aprobado por el Real Decreto ' +
    '1007/2023, de 5 de diciembre, y en la Orden HAC/1177/2024, de 17 de ' +
    'octubre, que lo desarrolla.' + sLineBreak + sLineBreak +
    'En particular, el sistema garantiza la integridad, conservación, ' +
    'accesibilidad, legibilidad, trazabilidad e inalterabilidad de los ' +
    'registros de facturación: por cada factura emitida genera un ' +
    'registro de alta (y, en su caso, de anulación) con huella o «hash» ' +
    'encadenada conforme a las especificaciones técnicas publicadas por ' +
    'la Agencia Estatal de Administración Tributaria, remite dichos ' +
    'registros de forma continuada por medios electrónicos a la sede ' +
    'electrónica de la AEAT (modalidad VERI*FACTU) e incluye en las ' +
    'facturas y facturas simplificadas el código «QR tributario» de ' +
    'cotejo.' + sLineBreak + sLineBreak +
    'Fecha de consulta de esta declaración: ' +
    FormatDateTime('dd/mm/yyyy hh:nn', Now);
  mDeclaracion.SelStart := 0;
end;

end.
