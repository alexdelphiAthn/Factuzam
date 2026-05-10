{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoAtributosConjuntos;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataAtributosConjuntos,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, inMtoPrincipal, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, cxSplitter, cxMaskEdit, cxDBEdit;

type
  TfrmMtoAtributosConjuntos = class(TfrmMtoGen)
    cxGrdDBTabPrinID_AC: TcxGridDBColumn;
    cxGrdDBTabPrinNOMBRE_AC: TcxGridDBColumn;
    cxGrdDBTabPrinID_VAR_AC: TcxGridDBColumn;
    cxGrdDBTabPrinID_VA_AC: TcxGridDBColumn;
    cxGrdDBTabPrinESACTIVO_AC: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTE_MODIF: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTE_ALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIO_ALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIO_MODIF: TcxGridDBColumn;
    pnlTopFicha: TPanel;
    pnlBodyFicha: TPanel;
    lblNombre: TcxLabel;
    txtNOMBRE_AC: TcxDBTextEdit;
    chkESACTIVO_AC: TcxDBCheckBox;
    lblIdVar: TcxLabel;
    txtID_VAR_AC: TcxDBTextEdit;
    lblIdVa: TcxLabel;
    txtID_VA_AC: TcxDBTextEdit;
    lblIdAc: TcxLabel;
    txtID_AC: TcxDBTextEdit;
    splSplitterFicha: TcxSplitter;
    pnlButtonFicha: TPanel;
    pcDetail: TcxPageControl;
    tsValores: TcxTabSheet;
    cxgrdValores: TcxGrid;
    tvValores: TcxGridDBTableView;
    cxgrdlvlValores: TcxGridLevel;
    tvValoresID_AC_ACD: TcxGridDBColumn;
    tvValoresID_AV_ACD: TcxGridDBColumn;
    tvValoresAV: TcxGridDBColumn;
    tvValoresDESCRIPCION_AV: TcxGridDBColumn;
    tvValoresESACTIVO_AV: TcxGridDBColumn;
    tvValoresORDEN_ACD: TcxGridDBColumn;
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
    dmmAtributosConjuntos: TdmAtributosConjuntos;
  public
    procedure CrearTablaPrincipal; override;
  end;

var
  frmMtoAtributosConjuntos: TfrmMtoAtributosConjuntos;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoAtributosConjuntos }

procedure TfrmMtoAtributosConjuntos.CrearTablaPrincipal;
begin
  inherited;
  dmmAtributosConjuntos := tdmDataModule as TdmAtributosConjuntos;
  tvValores.DataController.DataSource := dmmAtributosConjuntos.dsConjuntoDetalle;
  pkFieldName := 'ID_AC';
end;

procedure TfrmMtoAtributosConjuntos.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  // ID_AC es AUTO_INCREMENT, no editable.
  cxGrdDBTabPrinID_AC.Options.Editing := False;
end;

initialization
  ForceReferenceToClass(TfrmMtoAtributosConjuntos);
end.
