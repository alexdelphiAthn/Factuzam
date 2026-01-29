{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoAlmacenes;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, dxBarBuiltInMenu, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataAlmacenes, cxCheckBox,
  cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  inMtoPrincipal, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs,
  cxSplitter, cxMaskEdit, cxDBEdit;

type
  TfrmMtoAlmacenes = class(TfrmMtoGen)
    dbcGrdDBTabPrinCODIGO_ALMACEN_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_EMPRESA_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinNOMBRE_ALMACEN_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinESACTIVO_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_PADRE_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinESFISICO_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinTIPO_USO_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinDIRECCION_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinPOBLACION_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_POSTAL_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinTELEFONO_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinEMAIL_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_CLIENTE_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinALMACEN_DESTINO_ACTUAL_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinALMACEN_ORIGEN_ACTUAL_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinORDEN_ALM: TcxGridDBColumn;
    pnlTopFicha: TPanel;
    pnlBodyFicha: TPanel;
    lblCodigo: TcxLabel;
    txtCODIGO_ALMACEN_ALM: TcxDBTextEdit;
    lblCodigoEmpresa: TcxLabel;
    txtCODIGO_EMPRESA_ALM: TcxDBTextEdit;
    lblNombre: TcxLabel;
    txtNOMBRE_ALMACEN_ALM: TcxDBTextEdit;
    chkESACTIVO_ALM: TcxDBCheckBox;
    chkESFISICO_ALM: TcxDBCheckBox;
    lblCodigoPadre: TcxLabel;
    txtCODIGO_PADRE_ALM: TcxDBTextEdit;
    lblTipoUso: TcxLabel;
    txtTIPO_USO_ALM: TcxDBTextEdit;
    lblDireccion: TcxLabel;
    txtDIRECCION_ALM: TcxDBTextEdit;
    lblPoblacion: TcxLabel;
    txtPOBLACION_ALM: TcxDBTextEdit;
    lblCodigoPostal: TcxLabel;
    txtCODIGO_POSTAL_ALM: TcxDBTextEdit;
    lblTelefono: TcxLabel;
    txtTELEFONO_ALM: TcxDBTextEdit;
    lblEmail: TcxLabel;
    txtEMAIL_ALM: TcxDBTextEdit;
    lblCodigoCliente: TcxLabel;
    txtCODIGO_CLIENTE_ALM: TcxDBTextEdit;
    lblAlmacenDestino: TcxLabel;
    txtALMACEN_DESTINO_ACTUAL_ALM: TcxDBTextEdit;
    lblAlmacenOrigen: TcxLabel;
    txtALMACEN_ORIGEN_ACTUAL_ALM: TcxDBTextEdit;
    lblOrden: TcxLabel;
    spnORDEN_ALM: TcxDBSpinEdit;
    pnlButtonFicha: TPanel;
    pcDetail: TcxPageControl;
    tsAuditoria: TcxTabSheet;
    pnl3: TPanel;
    lblUsuarioAlta: TcxLabel;
    txtUSUARIOALTA: TcxDBTextEdit;
    lblInstanteAlta: TcxLabel;
    txtINSTANTEALTA: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    txtUSUARIOMODIF: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    txtINSTANTEMODIF: TcxDBTextEdit;
    splSplitterFicha: TcxSplitter;
    tsCajas: TcxTabSheet;
  private
    { Private declarations }
  public
    procedure CrearTablaPrincipal; override;
  end;

var
  frmMtoAlmacenes: TfrmMtoAlmacenes;
  dmmAlmacenes: TdmAlmacenes;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoAlmacenes }

procedure TfrmMtoAlmacenes.CrearTablaPrincipal;
begin
  inherited;
  dmmAlmacenes := tdmDataModule as TdmAlmacenes;
  pkFieldName := 'CODIGO_ALMACEN_ALM';
end;

initialization
  ForceReferenceToClass(TfrmMtoAlmacenes);
end.
