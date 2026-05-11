unit inMtoModalAltaRapida;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls,
  cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxControls, cxContainer,
  cxEdit, cxLabel, cxTextEdit, cxButtons, cxClasses;

type
  TfrmMtoModalAltaRapida = class(TForm)
    ScrollBox: TScrollBox;
    pnlBotones: TPanel;
    btnOk: TcxButton;
    btnCancel: TcxButton;
    lblCod: TcxLabel;
    edtCod: TcxTextEdit;
    lblDesc: TcxLabel;
    edtDesc: TcxTextEdit;
    BevelSep: TBevel;
  public
    const DynStartTop = 140;
    const ColMargin   = 25;
    const ColWidth    = 380;
    const FieldStep   = 55;
  end;

var
  frmMtoModalAltaRapida: TfrmMtoModalAltaRapida;

implementation

{$R *.dfm}

end.
