{*******************************************************}
{                                                       }
{       FactuZam - Mantenimiento de Albaranes           }
{                                                       }
{       Copyright (C) 2026 fzam.6dvdy@slmail.me         }
{                                                       }
{*******************************************************}

unit inMtoAlbaranes;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, inMtoGen, dxSkinsCore, dxSkinBlue,
  cxClasses, cxPropertiesStore, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, dxSkinsForm, cxLabel, cxTextEdit,
  cxDBEdit, cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, DB, cxDBData,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, ExtCtrls, cxButtons, cxMaskEdit,
  cxDropDownEdit, cxCalendar, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  cxSpinEdit, cxCurrencyEdit, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, Vcl.Menus, cxBlobEdit, dxShellDialogs,
  JvComponentBase, JvEnterTab, cxLocalization, Vcl.StdCtrls, cxRadioGroup,
  cxDBNavigator, Vcl.Buttons, System.UITypes, cxMemo, cxCheckBox, cxGroupBox,
  cxDBLabel, cxButtonEdit, UniDataAlbaranes;

type
  TfrmMtoAlbaranes = class(TfrmMtoGen)
    pcAlbaran: TcxPageControl;
    tsLineasAlbaran: TcxTabSheet;
    cxgrdLineasAlbaran: TcxGrid;
    tvLineasAlbaran: TcxGridDBTableView;
    cxgrdlvlLineasAlbaran: TcxGridLevel;
    pcCab: TcxPageControl;
    tsCabecera: TcxTabSheet;
    lblNroAlbaran: TcxLabel;
    txtNUMERO_ALB: TcxDBTextEdit;
    lblSerieAlbaran: TcxLabel;
    txtSERIE_ALB: TcxDBTextEdit;
    lblFechaAlbaran: TcxLabel;
    dteFECHA_ALB: TcxDBDateEdit;
    lblEstadoAlbaran: TcxLabel;
    txtESTADO_ALB: TcxDBTextEdit;
    lblPedidoOrigen: TcxLabel;
    txtNUMERO_PED_ALB: TcxDBTextEdit;
    txtSERIE_PED_ALB: TcxDBTextEdit;
    lblCodigoEmpresa: TcxLabel;
    btnCODIGO_EMP_ALB: TcxDBButtonEdit;
    cxdblblRAZON_SOCIAL_EMPRESA_ALB: TcxDBLabel;
    lblCodigoCliente: TcxLabel;
    btnCODIGO_CLI_ALB: TcxDBButtonEdit;
    cxdblblRAZON_SOCIAL_CLIENTE_ALB: TcxDBLabel;
    pnlBottomTotales: TPanel;
    lblTotalBases: TcxLabel;
    curTOTAL_BASES_ALB: TcxDBCurrencyEdit;
    lblTotalImpuestos: TcxLabel;
    curTOTAL_IMPUESTOS_ALB: TcxDBCurrencyEdit;
    lblTotalLiquido: TcxLabel;
    curTOTAL_LIQUIDO_ALB: TcxDBCurrencyEdit;
    btnImprimir: TcxButton;
    btnFacturar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnFacturarClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
  public
    dmmAlbaranes: TdmAlbaranes;
  end;

var
  frmMtoAlbaranes: TfrmMtoAlbaranes;

implementation

{$R *.dfm}

procedure TfrmMtoAlbaranes.FormCreate(Sender: TObject);
begin
  inherited;
  dmmAlbaranes := TdmAlbaranes.Create(Self);
  dsTablaG.DataSet := dmmAlbaranes.unqryTablaG;
  tvLineasAlbaran.DataController.DataSource := dmmAlbaranes.dsAlbaranesLineas;
  dmmAlbaranes.OpenTables;
end;

procedure TfrmMtoAlbaranes.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcAlbaran.ActivePage := tsLineasAlbaran;
  pcCab.ActivePage    := tsCabecera;
end;

procedure TfrmMtoAlbaranes.btnGrabarClick(Sender: TObject);
begin
  inherited;
  if dsTablaG.State in dsEditModes then
  begin
    dmmAlbaranes.CalcularTotalesAlbaran;
    dsTablaG.DataSet.Post;
  end;
end;

procedure TfrmMtoAlbaranes.btnFacturarClick(Sender: TObject);
begin
  inherited;
  ShowMessage('La generación de factura desde albarán se realiza desde la ' +
              'pantalla de Facturas seleccionando los albaranes pendientes ' +
              'del cliente.');
end;

procedure TfrmMtoAlbaranes.btnImprimirClick(Sender: TObject);
begin
  inherited;
  // Hook para FastReport: cargar fxdsPrintAlb / fxdstPrintLinAlb y mostrar.
end;

end.
