{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoGenSearch;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxBarBuiltInMenu, cxGraphics,
  cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData,
  cxFilter, cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB,
  cxDBData, cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization,
  cxDBNavigator, Vcl.Buttons, dxBevel, Vcl.StdCtrls, cxButtons, cxLabel,
  cxTextEdit, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, MemDS,
  DBAccess, Uni, UniDataConn, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, JvComponentBase, JvEnterTab, dxShellDialogs;

type
  TfrmMtoSearch = class(TfrmMtoGen)
    pnl1: TPanel;
    unqryPerfiles: TUniQuery;
    dsPerfiles: TDataSource;
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure cxGrdDBTabPrinCellDblClick(Sender: TcxCustomGridTableView;
      ACellViewInfo: TcxGridTableDataCellViewInfo; AButton: TMouseButton;
      AShift: TShiftState; var AHandled: Boolean);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    sFicha:string;
    procedure AplicarEtiquetas; override;
    procedure CrearTablaPrincipal; override;
    { Public declarations }
  end;

var
  frmMtoSearch: TfrmMtoSearch;

implementation

{$R *.dfm}

procedure TfrmMtoSearch.AplicarEtiquetas;
begin
  inherited;
  //AbrirPerfiles(tsPerfil.TabVisible);
end;

procedure TfrmMtoSearch.btnAceptarClick(Sender: TObject);
begin
  //inherited;
  sFicha:= 'S';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmMtoSearch.btnCancelarClick(Sender: TObject);
begin
  //inherited;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmMtoSearch.CrearTablaPrincipal;
begin
  inherited;
  //
  cxGrdDBTabPrin.DataController.CreateAllItems;
  cxGrdDBTabPrin.ApplyBestFit();
end;

procedure TfrmMtoSearch.cxGrdDBTabPrinCellDblClick(
                                    Sender: TcxCustomGridTableView;
                                    ACellViewInfo: TcxGridTableDataCellViewInfo;
                                    AButton: TMouseButton;
                                    AShift: TShiftState; var AHandled: Boolean);
begin
  inherited;
  btnAceptarClick(Self);
end;

procedure TfrmMtoSearch.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  Action := caFree;
end;

procedure TfrmMtoSearch.FormCreate(Sender: TObject);
begin
  //inherited;
  Self.Position := poScreenCenter;
  sUso := 'Busq';
end;

procedure TfrmMtoSearch.FormShow(Sender: TObject);
begin
  inherited;
  edtBusqGlobal.SetFocus;
end;

end.
