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
  inLibRegistroPantallas,
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
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
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
    cbbID_VAR_AC: TcxDBLookupComboBox;
    lblIdVa: TcxLabel;
    cbbID_VA_AC: TcxDBLookupComboBox;
    lblIdAc: TcxLabel;
    txtID_AC: TcxDBTextEdit;
    lblIdVarDesc: TcxLabel;
    lblIdVaDesc: TcxLabel;
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
    tvValoresID_ATB_ACD: TcxGridDBColumn;
    tsArticulos: TcxTabSheet;
    cxgrdArticulos: TcxGrid;
    tvArticulos: TcxGridDBTableView;
    cxgrdlvlArticulos: TcxGridLevel;
    tvArticulosCODIGO_ART_ART: TcxGridDBColumn;
    tvArticulosDESCRIPCION_ART: TcxGridDBColumn;
    tvArticulosESACTIVO_ART: TcxGridDBColumn;
    tvArticulosCODIGO_FAM_ART: TcxGridDBColumn;
    tvArticulosNOMBRE_FAM_FAM: TcxGridDBColumn;
    alConjuntos: TActionList;
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
    procedure dsTablaGDataChange(Sender: TObject; Field: TField);
  private
    dmmAtributosConjuntos: TdmAtributosConjuntos;
    procedure ActualizarDescripciones;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

implementation

uses
  inLibWin, inLibShowMto, inLibFotos, inLibMsgArticulos;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoAtributosConjuntos }

// El articulo activo es el de la rejilla de articulos del conjunto
// (tvArticulos, CODIGO_ART_ART).
procedure TfrmMtoAtributosConjuntos.ResolverArtSkuActivo(out ACodArt,
                                                             ACodSku: string);
var
  ds: TDataSet;
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(tvArticulos.DataController.DataSource) then
  begin
    ds := tvArticulos.DataController.DataSource.DataSet;
    inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
  end;
end;

function TfrmMtoAtributosConjuntos.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmmAtributosConjuntos) then
    Result := [dsTablaG, dmmAtributosConjuntos.dsArticulosConjunto]
  else
    Result := [dsTablaG];
end;

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
  (tvValoresID_ATB_ACD.Properties as TcxLookupComboBoxProperties).ListSource :=
                                   dmmAtributosConjuntos
                                   .dsAtributosBasicosLookup;
  cbbID_VAR_AC.Properties.ListSource :=
                                     dmmAtributosConjuntos.dsVariacionesLookup;
  cbbID_VA_AC.Properties.ListSource :=
                                       dmmAtributosConjuntos.dsAtributosLookup;
  (cxGrdDBTabPrinID_VAR_AC.Properties as TcxLookupComboBoxProperties).ListSource
                                  := dmmAtributosConjuntos.dsVariacionesLookup;
  (cxGrdDBTabPrinID_VA_AC.Properties as TcxLookupComboBoxProperties).ListSource
                                    := dmmAtributosConjuntos.dsAtributosLookup;
  pkFieldName := 'ID_AC';
  ActualizarDescripciones;
end;

procedure TfrmMtoAtributosConjuntos.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoAtributosConjuntos.dsTablaGDataChange(Sender: TObject;
                                                                 Field: TField);
begin
  if (Field = nil) or
     (Field.FieldName = 'ID_VAR_AC') or
     (Field.FieldName = 'ID_VA_AC') then
    ActualizarDescripciones;
end;

procedure TfrmMtoAtributosConjuntos.ActualizarDescripciones;
var
  LIdVar, LIdVa: string;
  LValor, LNombre, LOrden: Variant;
begin
  if (dmmAtributosConjuntos = nil) or (dsTablaG = nil) or
     (dsTablaG.DataSet = nil) or (not dsTablaG.DataSet.Active) or
     (not dmmAtributosConjuntos.unqryVariacionesLookup.Active) or
     (not dmmAtributosConjuntos.unqryAtributosLookup.Active) then
    Exit;

  LIdVar := dsTablaG.DataSet.FieldByName('ID_VAR_AC').AsString;
  if LIdVar = '' then
    lblIdVarDesc.Caption := ''
  else
  begin
    LValor := dmmAtributosConjuntos.unqryVariacionesLookup.Lookup(
                                       'CODIGO_VAR', LIdVar, 'NOMBRE_VAR');
    if VarIsNull(LValor) then
      lblIdVarDesc.Caption := ''
    else
      lblIdVarDesc.Caption := VarToStr(LValor);
  end;

  LIdVa := dsTablaG.DataSet.FieldByName('ID_VA_AC').AsString;
  if (LIdVar = '') or (LIdVa = '') then
  begin
    lblIdVaDesc.Caption := '';
    Exit;
  end;

  LValor := dmmAtributosConjuntos.unqryAtributosLookup.Lookup(
                                          'ID_VAR_VA;ID_ATB_VA',
                                          VarArrayOf([LIdVar, LIdVa]),
                                          'NOMBRE_VA;ORDEN_VA');
  if not VarIsArray(LValor) then
  begin
    lblIdVaDesc.Caption := '';
    Exit;
  end;

  LNombre := LValor[0];
  LOrden  := LValor[1];
  if VarIsNull(LNombre) then
    LNombre := '';
  if VarIsNull(LOrden) then
    lblIdVaDesc.Caption := VarToStr(LNombre)
  else
    lblIdVaDesc.Caption :=
      Format(SCaptionNombreOrden, [VarToStr(LNombre), VarToStr(LOrden)]);
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
  if ((pcDetail.ActivePage = tsArticulos) and
      (not dmmAtributosConjuntos.dsArticulosConjunto.DataSet.FieldByName(
        'CODIGO_ART_ART').IsNull)) then
    ShowMto(Self.Owner, 'Articulos',
      dmmAtributosConjuntos.dsArticulosConjunto.DataSet.FieldByName(
        'CODIGO_ART_ART').AsString)
  else
    ShowMto(Self.Owner, 'Articulos');
end;

initialization
  RegistrarPantalla(TfrmMtoAtributosConjuntos);
  ForceReferenceToClass(TfrmMtoAtributosConjuntos);
end.
