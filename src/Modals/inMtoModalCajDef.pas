{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalCajDef                                              }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de seleccion de almacen/caja por defecto del usuario.               }
{    Devuelve la combinacion Empresa/Almacen/Caja elegida.                     }
{******************************************************************************}
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
  cxGrid, MemDS, DBAccess, Uni, System.Actions, Vcl.ActnList;
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
    ActionList1: TActionList;
    Action1: TAction;
    Action2: TAction;
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelar1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Action2Execute(Sender: TObject);
    procedure Action1Execute(Sender: TObject);
  private
  public
    sFicha:string;
    sEmpresa: string;
    sAlmacen: string;
    sCaja:    string;
    { Public declarations }
  end;

implementation

{$R *.dfm}

uses UniDataConn, inLibFiltroUsuario;

procedure TfrmMtoModalCajDef.Action1Execute(Sender: TObject);
begin
  inherited;
  btnAceptarClick(Sender);
end;

procedure TfrmMtoModalCajDef.Action2Execute(Sender: TObject);
begin
  inherited;
  btnCancelar1Click(Sender);
end;

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
  // Restricción por usuario (appRestringirEmpAlmCaja): la selección de
  // caja solo ofrece la empresa/almacén/caja por defecto del usuario.
  // Se inyecta aquí porque los callers abren qrySeleccion tras el Create.
  qrySeleccion.SQL.Text :=
    InyectarFiltroSql(qrySeleccion.SQL.Text,
                      SqlFiltroEmpAlmCaja(ContextoSesion, 'Empresa', 'Almacen', 'Caja'));
end;

procedure TfrmMtoModalCajDef.FormShow(Sender: TObject);
begin
  inherited;
  qrySeleccion.Locate('Empresa;Almacen;Caja',
                         VarArrayOf([sEmpresa, sAlmacen, sCaja]),
                         []);
  if btnAceptar.CanBeFocused then
    btnAceptar.SetFocus;
  tvAlmacenesCajas.ApplyBestFit(nil, True, False);
end;

end.
