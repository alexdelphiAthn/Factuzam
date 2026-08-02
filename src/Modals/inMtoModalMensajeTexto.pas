{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalMensajeTexto                                       }
{    Tipo:       Formulario modal                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Muestra información seleccionable y permite copiarla al portapapeles.     }
{******************************************************************************}
unit inMtoModalMensajeTexto;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  cxButtons,
  cxClasses,
  cxContainer,
  cxControls,
  cxEdit,
  cxGraphics,
  cxLookAndFeelPainters,
  cxLookAndFeels,
  cxMemo,
  dxCore,
  dxSkinsForm,
  inMtoFrmBase;

type
  TfrmModalMensajeTexto = class(TfrmBase)
    pnlBotones: TPanel;
    btnCopiar: TcxButton;
    btnCerrar: TcxButton;
    mTexto: TcxMemo;
    procedure btnCopiarClick(Sender: TObject);
  public
    class procedure Mostrar(
      AOwner: TComponent;
      const ATexto: string); static;
  end;

implementation

{$R *.dfm}

uses
  System.SysUtils,
  System.UITypes,
  Vcl.Clipbrd,
  Vcl.Dialogs;

procedure TfrmModalMensajeTexto.btnCopiarClick(Sender: TObject);
begin
  try
    Clipboard.AsText := mTexto.Text;
    mTexto.SetFocus;
    mTexto.SelectAll;
  except
    on E: Exception do
      MessageDlg(
        'No se pudo copiar el texto al portapapeles: ' + E.Message,
        mtWarning,
        [mbOk],
        0);
  end;
end;

class procedure TfrmModalMensajeTexto.Mostrar(
  AOwner: TComponent;
  const ATexto: string);
var
  oDialogo: TfrmModalMensajeTexto;
begin
  oDialogo := TfrmModalMensajeTexto.Create(AOwner);
  try
    oDialogo.mTexto.Text := ATexto;
    oDialogo.mTexto.SelStart := 0;
    oDialogo.mTexto.SelLength := 0;
    oDialogo.ActiveControl := oDialogo.mTexto;
    oDialogo.ShowModal;
  finally
    FreeAndNil(oDialogo);
  end;
end;

end.
