{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalInformesGuias                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       0.1.0                                                         }
{   Fecha:       19/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Mantenimiento ligero de fza_informes_guias filtrado por el informe que    }
{    lo invoca. Permite alta/baja/edicion de las guias que enganchan datasets  }
{    auxiliares a un informe FastReport (estilo MasterSource/MasterFields/     }
{    DetailFields de UniDAC) sin recompilar.                                   }
{                                                                              }
{    Diseño en                                                                 }
{    DESARROLLOS EN CURSO/informes_guias_ampliacion_runtime.md.                }
{******************************************************************************}
unit inMtoModalInformesGuias;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, System.Actions, Vcl.ActnList,
  Data.DB, MemDS, DBAccess, Uni,
  inMtoFrmBase, dxCore, dxSkinsForm, dxSkinsCore, dxSkinBlue,
  cxClasses, cxContainer, cxEdit, cxControls, cxLookAndFeels, cxLocalization,
  cxGraphics, cxLookAndFeelPainters, cxButtons, cxStyles, cxLabel, cxTextEdit,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, dxDateRanges,
  dxScrollbarAnnotations, cxDBData, cxGridLevel, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGridCustomView, cxGrid,
  JvComponentBase, JvEnterTab;

type
  TfrmModalInformesGuias = class(TfrmBase)
    pnlBotones: TPanel;
    btnCerrar: TcxButton;
    grdGuias: TcxGrid;
    tvGuias: TcxGridDBTableView;
    lvGuias: TcxGridLevel;
    unqryGuias: TUniQuery;
    dsGuias: TDataSource;
    tvGuiasCODIGO: TcxGridDBColumn;
    tvGuiasMASTER_DS: TcxGridDBColumn;
    tvGuiasTIPO: TcxGridDBColumn;
    tvGuiasTABLA: TcxGridDBColumn;
    tvGuiasSQL: TcxGridDBColumn;
    tvGuiasMASTER_FIELDS: TcxGridDBColumn;
    tvGuiasDETAIL_FIELDS: TcxGridDBColumn;
    tvGuiasORDEN: TcxGridDBColumn;
    tvGuiasACTIVO: TcxGridDBColumn;
    lblInfo: TcxLabel;
    ActionList1: TActionList;
    actSalir: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCerrarClick(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);
    procedure unqryGuiasBeforePost(DataSet: TDataSet);
  public
    // Nombre del informe (Self.Name del TfrmPrint que invoca) por el que
    // filtramos fza_informes_guias. Lo setea el invocador antes del
    // ShowModal.
    sInforme: string;
  end;

implementation

{$R *.dfm}

uses
  UniDataConn, inLibUser;

procedure TfrmModalInformesGuias.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
end;

procedure TfrmModalInformesGuias.FormShow(Sender: TObject);
begin
  inherited;
  unqryGuias.Connection := oConn;
  unqryGuias.Close;
  unqryGuias.ParamByName('INF').AsString := sInforme;
  unqryGuias.Open;
  lblInfo.Caption := Format('Guias activas para el informe "%s"', [sInforme]);
end;

procedure TfrmModalInformesGuias.FormClose(Sender: TObject;
                                           var Action: TCloseAction);
begin
  inherited;
  if unqryGuias.State in [dsEdit, dsInsert] then
    unqryGuias.Post;
  unqryGuias.Close;
end;

procedure TfrmModalInformesGuias.btnCerrarClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TfrmModalInformesGuias.actSalirExecute(Sender: TObject);
begin
  btnCerrarClick(Sender);
end;

procedure TfrmModalInformesGuias.unqryGuiasBeforePost(DataSet: TDataSet);
begin
  // Cuando el usuario inserta una guia nueva, prefijamos el INFORME para
  // que la fila quede ya filtrada al refresh sin tener que escribirlo en
  // el grid, y rellenamos los flags por defecto.
  if DataSet.State = dsInsert then
  begin
    if DataSet.FieldByName('INFORME_INFGUI').IsNull or
       (DataSet.FieldByName('INFORME_INFGUI').AsString = '') then
      DataSet.FieldByName('INFORME_INFGUI').AsString := sInforme;
    if DataSet.FieldByName('ESACTIVO_INFGUI').IsNull or
       (DataSet.FieldByName('ESACTIVO_INFGUI').AsString = '') then
      DataSet.FieldByName('ESACTIVO_INFGUI').AsString := 'S';
    if DataSet.FieldByName('TIPO_INFGUI').IsNull or
       (DataSet.FieldByName('TIPO_INFGUI').AsString = '') then
      DataSet.FieldByName('TIPO_INFGUI').AsString := 'TABLA';
    DataSet.FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    DataSet.FieldByName('USUARIO_ALTA').AsString    := oUser;
  end;
  DataSet.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
  DataSet.FieldByName('USUARIO_MODIF').AsString    := oUser;
end;

end.
