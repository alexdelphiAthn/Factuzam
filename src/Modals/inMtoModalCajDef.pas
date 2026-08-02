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
  cxGrid, System.Actions, Vcl.ActnList,
  inLibCajasDefectoPersistenciaIntf;
type
  TfrmMtoModalCajDef = class(TfrmBase)
    pnl1: TPanel;
    btnCancelar1: TcxButton;
    btnAceptar: TcxButton;
    cxgrdAlmacenCajas: TcxGrid;
    tvAlmacenesCajas: TcxGridDBTableView;
    lvAlmacenCajas: TcxGridLevel;
    DataSource1: TDataSource;
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
    FRepositorioPersistencia: IRepositorioCajasDefecto;
    FResultado: IResultadoCajasDefecto;
    FDatos: TDataSet;
  public
    sFicha:string;
    sEmpresa: string;
    sAlmacen: string;
    sCaja:    string;
    procedure Cargar(const AEmpresaFiltro: string = '');
    function EmpresaSeleccionada: string;
    function AlmacenSeleccionado: string;
    function CajaSeleccionada: string;
    { Public declarations }
  end;

implementation

{$R *.dfm}

uses
  inLibFiltroUsuario;

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
  FRepositorioPersistencia := ContextoRepositoriosPantalla.Caja.
    CrearRepositorioCajasDefecto;
  Cargar;
end;

procedure TfrmMtoModalCajDef.Cargar(const AEmpresaFiltro: string);
var
  Solicitud: TSolicitudCajasDefecto;
begin
  Solicitud.EmpresaFiltro := AEmpresaFiltro;
  Solicitud.EmpresaRestringida :=
    EmpresaRestringida(ContextoSesion, ParametrosApp);
  Solicitud.AlmacenRestringido :=
    AlmacenRestringido(ContextoSesion, ParametrosApp);
  Solicitud.CajaRestringida :=
    CajaRestringida(ContextoSesion, ParametrosApp);
  DataSource1.DataSet := nil;
  FDatos := nil;
  FResultado := FRepositorioPersistencia.Consultar(Solicitud);
  FDatos := FResultado.DataSet;
  DataSource1.DataSet := FDatos;
end;

function TfrmMtoModalCajDef.EmpresaSeleccionada: string;
begin
  Result := '';
  if Assigned(FDatos) and not FDatos.IsEmpty then
  begin
    Result := FDatos.FieldByName('Empresa').AsString;
  end;
end;

function TfrmMtoModalCajDef.AlmacenSeleccionado: string;
begin
  Result := '';
  if Assigned(FDatos) and not FDatos.IsEmpty then
  begin
    Result := FDatos.FieldByName('Almacen').AsString;
  end;
end;

function TfrmMtoModalCajDef.CajaSeleccionada: string;
begin
  Result := '';
  if Assigned(FDatos) and not FDatos.IsEmpty then
  begin
    Result := FDatos.FieldByName('Caja').AsString;
  end;
end;

procedure TfrmMtoModalCajDef.FormShow(Sender: TObject);
begin
  inherited;
  if Assigned(FDatos) then
  begin
    FDatos.Locate(
      'Empresa;Almacen;Caja',
      VarArrayOf([sEmpresa, sAlmacen, sCaja]),
      []);
  end;
  if btnAceptar.CanBeFocused then
    btnAceptar.SetFocus;
  tvAlmacenesCajas.ApplyBestFit(nil, True, False);
end;

end.
