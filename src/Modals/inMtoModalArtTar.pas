{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoModalArtTar;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoFrmBase, dxCore, dxSkinsForm,
  cxClasses, cxContainer, cxEdit, cxLookAndFeels, cxLocalization, cxGraphics,
  cxControls, cxLookAndFeelPainters, cxCustomListBox, cxCheckListBox,
  cxDBCheckListBox, UniDataArticulos, Vcl.Menus, Vcl.StdCtrls, cxButtons,
  Vcl.ExtCtrls, Vcl.ComCtrls, cxListView, cxStyles, Data.DB, JvComponentBase,
  JvEnterTab;

type
  TfrmMtoModalArtTar = class(TfrmBase)
    pnl1: TPanel;
    btnCancelar1: TcxButton;
    btnAceptar: TcxButton;
    lstTarifas: TcxListView;
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelar1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }

  public
    sFicha:string;
    { Public declarations }
  end;

var
  frmMtoModalArtTar: TfrmMtoModalArtTar;

implementation

{$R *.dfm}

procedure TfrmMtoModalArtTar.btnAceptarClick(Sender: TObject);
begin
  inherited;
  sFicha:= 'S';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmMtoModalArtTar.btnCancelar1Click(Sender: TObject);
begin
  inherited;
  sFicha := 'N';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmMtoModalArtTar.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  inherited;
  Action := caFree;
end;

procedure TfrmMtoModalArtTar.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
end;

end.
