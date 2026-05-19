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
  cxGridTableView, cxGridDBTableView, cxGridCustomView, cxGrid, cxMemo,
  cxDropDownEdit, cxBlobEdit,
  frxClass, frxDBSet,
  JvComponentBase, JvEnterTab;

type
  TfrmModalInformesGuias = class(TfrmBase)
    pnlCabecera: TPanel;
    lblTitulo: TcxLabel;
    lblInfo: TcxLabel;
    pnlAyuda: TPanel;
    lblAyuda: TcxLabel;
    mmoDatasets: TcxMemo;
    pnlBotones: TPanel;
    btnCerrar: TcxButton;
    grdGuias: TcxGrid;
    tvGuias: TcxGridDBTableView;
    lvGuias: TcxGridLevel;
    unqryGuias: TUniQuery;
    dsGuias: TDataSource;
    tvGuiasCODIGO: TcxGridDBColumn;
    tvGuiasFORMATO: TcxGridDBColumn;
    tvGuiasMASTER_DS: TcxGridDBColumn;
    tvGuiasTIPO: TcxGridDBColumn;
    tvGuiasTABLA: TcxGridDBColumn;
    tvGuiasSQL: TcxGridDBColumn;
    tvGuiasMASTER_FIELDS: TcxGridDBColumn;
    tvGuiasDETAIL_FIELDS: TcxGridDBColumn;
    tvGuiasORDEN: TcxGridDBColumn;
    tvGuiasACTIVO: TcxGridDBColumn;
    ActionList1: TActionList;
    actSalir: TAction;
    cxStyleRepo: TcxStyleRepository;
    cxsHeader: TcxStyle;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCerrarClick(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);
    procedure unqryGuiasBeforePost(DataSet: TDataSet);
  private
    procedure ListarDatasetsDelReport;
  public
    // Nombre del informe (Self.Name del TfrmPrint que invoca) por el que
    // filtramos fza_informes_guias. Lo setea el invocador antes del
    // ShowModal.
    sInforme: string;
    // Formato (VALUE_USUPER) actual del informe. Si esta relleno, las
    // guias nuevas insertadas desde el grid se prerrellenan con este
    // valor en FORMATO_INFGUI; si esta vacio la guia nueva queda como
    // "global" al informe (FORMATO_INFGUI = '').
    sFormatoSugerido: string;
    // Report del TfrmPrint invocador. Si esta asignado, mostramos en el
    // panel de ayuda los datasets disponibles (cabecera y detalle) con
    // sus campos para que el usuario sepa que escribir en
    // DATASET_MASTER_INFGUI y MASTER_FIELDS_INFGUI / DETAIL_FIELDS_INFGUI.
    FReport: TfrxReport;
  end;

implementation

{$R *.dfm}

uses
  UniDataConn, inLibUser, inLibGlobalVar;

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
  if sFormatoSugerido = '' then
    lblInfo.Caption :=
      Format('Informe: %s   ·   Formato sugerido: (global)', [sInforme])
  else
    lblInfo.Caption :=
      Format('Informe: %s   ·   Formato sugerido: %s',
             [sInforme, sFormatoSugerido]);
  ListarDatasetsDelReport;
end;

procedure TfrmModalInformesGuias.ListarDatasetsDelReport;
var
  i, j: Integer;
  oFrx: TfrxDBDataset;
  oDS: TDataSet;
  sLine, sUserName: string;
begin
  // Recorre TfrxReport.Datasets para que el usuario vea, en el panel de
  // ayuda, todos los datasets que el informe tiene a su disposicion
  // (cabecera + detalles). Para cada uno se listan los nombres de campo
  // del TDataSet subyacente. El usuario solo tiene que copiar:
  //   - el UserName -> DATASET_MASTER_INFGUI
  //   - los nombres de campo -> MASTER_FIELDS_INFGUI
  mmoDatasets.Lines.BeginUpdate;
  try
    mmoDatasets.Lines.Clear;
    if FReport = nil then
    begin
      mmoDatasets.Lines.Add('(El report no se ha pasado al modal: ' +
                            'no hay info de datasets disponible.)');
      Exit;
    end;
    mmoDatasets.Lines.Add(Format(
      'Datasets disponibles en el informe %s', [sInforme]));
    mmoDatasets.Lines.Add('');
    if FReport.Datasets.Count = 0 then
    begin
      mmoDatasets.Lines.Add('(El report no tiene datasets registrados.)');
      Exit;
    end;
    for i := 0 to FReport.Datasets.Count - 1 do
    begin
      if not (FReport.Datasets[i].DataSet is TfrxDBDataset) then Continue;
      oFrx := TfrxDBDataset(FReport.Datasets[i].DataSet);
      sUserName := oFrx.UserName;
      if sUserName = '' then sUserName := '(sin UserName)';
      mmoDatasets.Lines.Add('• ' + sUserName);
      oDS := oFrx.DataSet;
      if (oDS = nil) or (not oDS.Active) or (oDS.FieldCount = 0) then
      begin
        mmoDatasets.Lines.Add('    (sin campos disponibles ' +
                              '— dataset cerrado o vacio)');
        mmoDatasets.Lines.Add('');
        Continue;
      end;
      sLine := '    ';
      for j := 0 to oDS.FieldCount - 1 do
      begin
        if Length(sLine) + Length(oDS.Fields[j].FieldName) > 95 then
        begin
          mmoDatasets.Lines.Add(sLine);
          sLine := '    ';
        end;
        if sLine <> '    ' then sLine := sLine + ', ';
        sLine := sLine + oDS.Fields[j].FieldName;
      end;
      if sLine <> '    ' then
        mmoDatasets.Lines.Add(sLine);
      mmoDatasets.Lines.Add('');
    end;
    mmoDatasets.Lines.Add(
      'Tip: copia el UserName a "Dataset master" y los campos a ' +
      '"Master fields" / "Detail fields" separados por '';''.');
  finally
    mmoDatasets.Lines.EndUpdate;
  end;
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
    // Si el usuario abrio el modal estando sobre un formato concreto,
    // las guias nuevas se atan a ese formato por defecto. Si quiere
    // que sean globales basta con vaciar la celda FORMATO_INFGUI.
    if DataSet.FieldByName('FORMATO_INFGUI').IsNull then
      DataSet.FieldByName('FORMATO_INFGUI').AsString := sFormatoSugerido;
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
