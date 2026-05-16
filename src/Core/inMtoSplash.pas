{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoSplash                                                   }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/02/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Este formulario es un formulario de información sobre el autor.           }
{    No tiene ningún propósito funcional, pero es importante agradecer a quien }
{    te ha dado una mano.                                                      }
{******************************************************************************}
unit inMtoSplash;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, jpeg, StdCtrls, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxLabel, JvExControls,
  JvAnimatedImage, JvGIFCtrl, cxTextEdit, cxHyperLinkEdit, Vcl.Menus, cxButtons;

type
  TfrmSplash = class(TForm)
    Panel1: TPanel;
    JvGIFAnimator1: TJvGIFAnimator;
    Panel3: TPanel;
    cxLabel1: TcxLabel;
    hlEmail: TcxHyperLinkEdit;
    cxLabel2: TcxLabel;
    btnAceptar: TcxButton;
    procedure JvGIFAnimator1Click(Sender: TObject);
    procedure cxLabel1Click(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;
var
  frmSplash: TfrmSplash;

implementation

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmSplash.cxLabel1Click(Sender: TObject);
begin
  Self.Close;
end;

procedure TfrmSplash.JvGIFAnimator1Click(Sender: TObject);
begin
  Self.Close;
end;

procedure TfrmSplash.btnAceptarClick(Sender: TObject);
begin
  Self.Close;
end;

initialization
  ForceReferenceToClass(TfrmSplash);

end.
