{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}
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
    btAceptar: TcxButton;
    procedure JvGIFAnimator1Click(Sender: TObject);
    procedure cxLabel1Click(Sender: TObject);
    procedure btAceptarClick(Sender: TObject);
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

procedure TfrmSplash.btAceptarClick(Sender: TObject);
begin
  Self.Close;
end;

initialization
  ForceReferenceToClass(TfrmSplash);

end.
