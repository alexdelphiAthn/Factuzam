{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoAtributosConjuntos                                       }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de conjuntos de atributos.                                  }
{    Agrupa variaciones y sus valores para usarlos en articulos.               }
{******************************************************************************}
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
  dxShellDialogs, cxSplitter, cxMaskEdit, cxDBEdit, cxDBLookupComboBox,
  cxDBLookupEdit, cxLookupEdit, cxDropDownEdit,
  System.Actions, Vcl.ActnList;

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
    tvValoresORDEN_ACD: TcxGridDBColumn;
    tsArticulos: TcxTabSheet;
    cxgrdArticulos: TcxGrid;
    tvArticulos: TcxGridDBTableView;
    cxgrdlvlArticulos: TcxGridLevel;
    tvArticulosCODIGO_ART_ART: TcxGridDBColumn;
    tvArticulosDESCRIPCION_ART: TcxGridDBColumn;
    tvArticulosESACTIVO_ART: TcxGridDBColumn;
    tvArticulosCODIGO_FAM_ART: TcxGridDBColumn;
    tvArticulosNOMBRE_FAM_FAM: TcxGridDBColumn;
    ActionListConjuntos: TActionList;
    actArticulo: TAction;
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
    procedure actArticuloExecute(Sender: TObject);
  private
    dmmAtributosConjuntos: TdmAtributosConjuntos;
  public
    procedure CrearTablaPrincipal; override;
  end;

var
  frmMtoAtributosConjuntos: TfrmMtoAtributosConjuntos;

implementation

uses
  inLibWin, inLibShowMto;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoAtributosConjuntos }

procedure TfrmMtoAtributosConjuntos.CrearTablaPrincipal;
begin
  inherited;
  dmmAtributosConjuntos := tdmDataModule as TdmAtributosConjuntos;
  tvValores.DataController.DataSource   :=
                                        dmmAtributosConjuntos.dsConjuntoDetalle;
  tvArticulos.DataController.DataSource :=
                                      dmmAtributosConjuntos.dsArticulosConjunto;
  (tvValoresID_AV_ACD.Properties as TcxLookupComboBoxProperties).ListSource :=
                                          dmmAtributosConjuntos.dsValoresLookup;
  pkFieldName := 'ID_AC';
end;

procedure TfrmMtoAtributosConjuntos.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  // ID_AC es AUTO_INCREMENT, no editable.
  cxGrdDBTabPrinID_AC.Options.Editing := False;
end;

procedure TfrmMtoAtributosConjuntos.actArticuloExecute(Sender: TObject);
begin
  inherited;
  with dmmAtributosConjuntos.dsArticulosConjunto.DataSet do
  if ((pcDetail.ActivePage = tsArticulos) and
      (not FieldByName('CODIGO_ART_ART').IsNull)) then
    ShowMto(Self.Owner, 'Articulos', FieldByName('CODIGO_ART_ART').AsString)
  else
    ShowMto(Self.Owner, 'Articulos');
end;

initialization
  ForceReferenceToClass(TfrmMtoAtributosConjuntos);
end.
