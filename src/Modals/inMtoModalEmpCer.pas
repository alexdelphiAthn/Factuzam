{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoModalEmpCer;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, system.StrUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoFrmBase, dxCore, dxSkinsForm,
  cxClasses, cxContainer, cxEdit, cxLookAndFeels, cxLocalization, cxGraphics,
  cxControls, cxLookAndFeelPainters, cxCustomListBox, cxCheckListBox,
  cxDBCheckListBox, UniDataArticulos, Vcl.Menus, Vcl.StdCtrls, cxButtons,
  Vcl.ExtCtrls, Vcl.ComCtrls, cxListView, cxStyles, Data.DB, JvComponentBase,
  JvEnterTab, inLibCertificates;

type
  TfrmMtoModalEmpCer = class(TfrmBase)
    pnl1: TPanel;
    btnCancelar1: TcxButton;
    btnAceptar: TcxButton;
    lstCertificates: TcxListView;
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }

  public
    sFicha:string;
    { Public declarations }
  end;

var
  frmMtoModalEmpCer: TfrmMtoModalEmpCer;

implementation

{$R *.dfm}

procedure TfrmMtoModalEmpCer.btnAceptarClick(Sender: TObject);
begin
  inherited;
  sFicha:= 'S';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmMtoModalEmpCer.btnCancelarClick(Sender: TObject);
begin
  inherited;
  sFicha := 'N';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmMtoModalEmpCer.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  inherited;
  Action := caFree;
end;

procedure TfrmMtoModalEmpCer.FormCreate(Sender: TObject);
var i:Integer;
begin
  inherited;
  Self.Position := poScreenCenter;
  LoadCerts(lstCertificates);
  for i := 0 to lstCertificates.Columns.Count - 1 do
    lstCertificates.Columns[i].AutoSize := True;
end;

end.
