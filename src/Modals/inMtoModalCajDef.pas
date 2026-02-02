{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoModalCajDef;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoFrmBase, dxCore, dxSkinsForm,
  cxClasses, cxContainer, cxEdit, cxLookAndFeels, cxLocalization, cxGraphics,
  cxControls, cxLookAndFeelPainters, cxCustomListBox, cxCheckListBox,
  cxDBCheckListBox, UniDataArticulos, Vcl.Menus, Vcl.StdCtrls, cxButtons,
  Vcl.ExtCtrls, Vcl.ComCtrls, cxListView, cxStyles, Data.DB, JvComponentBase,
  JvEnterTab, cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, cxDBData, cxGridLevel,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGridCustomView,
  cxGrid, MemDS, DBAccess, Uni;

type
  TfrmMtoModalCajDef = class(TfrmBase)
    pnl1: TPanel;
    btnCancelar1: TcxButton;
    btnAceptar: TcxButton;
    cxgrdAlmacenCajas: TcxGrid;
    tvAlmacenesCajas: TcxGridDBTableView;
    lvAlmacenCajas: TcxGridLevel;
    DataSource1: TDataSource;
    qrySeleccion: TUniQuery;
    tvAlmacenesCajasEmpresa: TcxGridDBColumn;
    tvAlmacenesCajasNombreEmpresa: TcxGridDBColumn;
    tvAlmacenesCajasAlmacn: TcxGridDBColumn;
    tvAlmacenesCajasNombreAlmacn: TcxGridDBColumn;
    tvAlmacenesCajasCaja: TcxGridDBColumn;
    tvAlmacenesCajasNombreCaja: TcxGridDBColumn;
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
  frmMtoModalCajDef: TfrmMtoModalCajDef;

implementation

{$R *.dfm}

uses UniDataConn;

procedure TfrmMtoModalCajDef.btnAceptarClick(Sender: TObject);
begin
  inherited;
  sFicha:= 'S';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmMtoModalCajDef.btnCancelar1Click(Sender: TObject);
begin
  inherited;
  sFicha := 'N';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmMtoModalCajDef.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  inherited;
  Action := caFree;
end;

procedure TfrmMtoModalCajDef.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
end;

end.
