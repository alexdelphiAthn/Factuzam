{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoVariaciones;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataVariaciones, cxCheckBox,
  cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  inMtoPrincipal, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs,
  cxSplitter, cxMaskEdit, cxDBEdit;

type
  TfrmMtoVariaciones = class(TfrmMtoGen)
    cxGrdDBTabPrinCODIGO_VAR: TcxGridDBColumn;
    cxGrdDBTabPrinNOMBRE_VAR: TcxGridDBColumn;
    cxGrdDBTabPrinESACTIVO_VAR: TcxGridDBColumn;
    cxGrdDBTabPrinORDEN_VAR: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    pnlTopFicha: TPanel;
    pnlBodyFicha: TPanel;
    lblCodigo: TcxLabel;
    txtCODIGO_VAR: TcxDBTextEdit;
    lblNombre: TcxLabel;
    txtNOMBRE_VAR: TcxDBTextEdit;
    chkESACTIVO_VAR: TcxDBCheckBox;
    lblOrden: TcxLabel;
    spnORDEN_VAR: TcxDBSpinEdit;
    splSplitterFicha: TcxSplitter;
    pnlButtonFicha: TPanel;
    pcDetail: TcxPageControl;
    tsArticulos: TcxTabSheet;
    cxgrdArticulos: TcxGrid;
    tvArticulos: TcxGridDBTableView;
    cxgrdlvlArticulos: TcxGridLevel;
    tvArticulosCODIGO_ARTICULO: TcxGridDBColumn;
    tvArticulosDESCRIPCION_ARTICULO: TcxGridDBColumn;
    tvArticulosACTIVO_ARTICULO: TcxGridDBColumn;
    tvArticulosCODIGO_FAMILIA_ARTICULO: TcxGridDBColumn;
    tvArticulosNOMBRE_FAMILIA: TcxGridDBColumn;
    tvArticulosESVARIACION_ARTICULO: TcxGridDBColumn;
    tsAuditoria: TcxTabSheet;
    pnlAuditoria: TPanel;
    lblUsuarioAlta: TcxLabel;
    txtUSUARIOALTA: TcxDBTextEdit;
    lblInstanteAlta: TcxLabel;
    txtINSTANTEALTA: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    txtUSUARIOMODIF: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    txtINSTANTEMODIF: TcxDBTextEdit;
    procedure dsTablaGStateChange(Sender: TObject);
  private
    dmmVariaciones: TdmVariaciones;
  public
    procedure CrearTablaPrincipal; override;
  end;

var
  frmMtoVariaciones: TfrmMtoVariaciones;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoVariaciones }

procedure TfrmMtoVariaciones.CrearTablaPrincipal;
begin
  inherited;
  dmmVariaciones := tdmDataModule as TdmVariaciones;
  tvArticulos.DataController.DataSource := dmmVariaciones.dsArticulosVariacion;
  pkFieldName := '`CODIGO_VAR';
end;

procedure TfrmMtoVariaciones.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if dsTablaG.State = dsInsert then
    cxGrdDBTabPrinCODIGO_VAR.Options.Editing := True
  else
    cxGrdDBTabPrinCODIGO_VAR.Options.Editing := False;
end;

initialization
  ForceReferenceToClass(TfrmMtoVariaciones);
end.
