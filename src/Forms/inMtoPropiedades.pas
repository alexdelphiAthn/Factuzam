{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPropiedades                                              }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de propiedades de articulo.                                 }
{    Define las propiedades configurables aplicables a articulos.              }
{******************************************************************************}
unit inMtoPropiedades;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.Actions, Vcl.ActnList,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataPropiedades,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, inMtoPrincipal, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, cxDBEdit, cxDropDownEdit, cxSplitter, cxMaskEdit;

type
  TfrmMtoPropiedades = class(TfrmMtoGen)
    cxgrdbclmnGrdDBTabPrinCODIGO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNOMBRE: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinTIPO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinACTIVO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNUMARTUSOS: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;

    pnl1: TPanel;
    Panel1: TPanel;
    lblCodigo: TcxLabel;
    txtCODIGO: TcxDBTextEdit;
    lblNombre: TcxLabel;
    txtNOMBRE: TcxDBTextEdit;
    lblTipo: TcxLabel;
    cmbTIPO: TcxDBComboBox;
    chkACTIVO: TcxDBCheckBox;
    cxspltr1: TcxSplitter;
    pnl2: TPanel;
    pcPestana: TcxPageControl;

    tsValores: TcxTabSheet;
    cxgrdValores: TcxGrid;
    tvValores: TcxGridDBTableView;
    lvValores: TcxGridLevel;
    tvValoresPV: TcxGridDBColumn;
    tvValoresDESCRIPCION_PV: TcxGridDBColumn;
    tvValoresESACTIVO_PV: TcxGridDBColumn;
    tvValoresINSTANTEALTA: TcxGridDBColumn;
    tvValoresUSUARIOALTA: TcxGridDBColumn;

    tsArticulos: TcxTabSheet;
    cxgrdArticulos: TcxGrid;
    tvArticulos: TcxGridDBTableView;
    lvArticulos: TcxGridLevel;
    tvArticulosCODIGO_ART_ART: TcxGridDBColumn;
    tvArticulosDESCRIPCION_ARTICULO: TcxGridDBColumn;
    tvArticulosVALOR_LISTA: TcxGridDBColumn;
    tvArticulosVALOR_LIBRE_ARTPROP: TcxGridDBColumn;
    tvArticulosINSTANTEALTA: TcxGridDBColumn;
    tvArticulosUSUARIOALTA: TcxGridDBColumn;

    alPropiedades: TActionList;
    actGoArticulo: TAction;

    procedure dsTablaGStateChange(Sender: TObject);
    procedure actGoArticuloExecute(Sender: TObject);
    procedure actGoArticuloUpdate(Sender: TObject);
    procedure unqryValoresBeforePost(DataSet: TDataSet);
  private
    dmmPropiedades: TdmPropiedades;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  frmMtoPropiedades: TfrmMtoPropiedades;

implementation

uses
  inLibWin, inLibShowMto, inLibGlobalVar;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoPropiedades }

procedure TfrmMtoPropiedades.CrearTablaPrincipal;
begin
  inherited;
  dmmPropiedades := tdmDataModule as TdmPropiedades;
  pkFieldName := 'CODIGO_PROP_ARTPROP';

  dmmPropiedades.unqryArticulos.Connection := oConn;
  dmmPropiedades.unqryValores.Connection   := oConn;
  if not dmmPropiedades.unqryArticulos.Active then
    dmmPropiedades.unqryArticulos.Open;
  if not dmmPropiedades.unqryValores.Active then
    dmmPropiedades.unqryValores.Open;

  tvArticulos.DataController.DataSource := dmmPropiedades.dsArticulos;
  tvValores.DataController.DataSource   := dmmPropiedades.dsValores;
  dmmPropiedades.unqryValores.BeforePost := unqryValoresBeforePost;
end;

procedure TfrmMtoPropiedades.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoPropiedades.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if dsTablaG.State = dsInsert then
    txtCODIGO.Properties.ReadOnly := False
  else
    txtCODIGO.Properties.ReadOnly := True;
end;

procedure TfrmMtoPropiedades.unqryValoresBeforePost(DataSet: TDataSet);
begin
  if (DataSet.State = dsInsert) and
     Assigned(dmmPropiedades) and
     dmmPropiedades.unqryTablaG.Active and
     not dmmPropiedades.unqryTablaG.IsEmpty then
  begin
    if DataSet.FieldByName('ID_PROP_PV').IsNull then
      DataSet.FieldByName('ID_PROP_PV').AsString :=
        dmmPropiedades.unqryTablaG.FieldByName('CODIGO_PROP_ARTPROP').AsString;
    if (DataSet.FindField('ESACTIVO_PV') <> nil) and
       DataSet.FieldByName('ESACTIVO_PV').IsNull then
      DataSet.FieldByName('ESACTIVO_PV').AsString := 'S';
  end;
  oDmConn.ActualizarUserTimeModif(DataSet);
end;

procedure TfrmMtoPropiedades.actGoArticuloUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled :=
    (pcPantalla.ActivePage = tsFicha) and
    (pcPestana.ActivePage = tsArticulos) and
    Assigned(dmmPropiedades) and
    Assigned(dmmPropiedades.unqryArticulos) and
    dmmPropiedades.unqryArticulos.Active and
    not dmmPropiedades.unqryArticulos.IsEmpty;
end;

procedure TfrmMtoPropiedades.actGoArticuloExecute(Sender: TObject);
var
  sCodArt: string;
begin
  if (dmmPropiedades = nil) or (dmmPropiedades.unqryArticulos = nil) then Exit;
  if not dmmPropiedades.unqryArticulos.Active then Exit;
  if dmmPropiedades.unqryArticulos.IsEmpty then Exit;
  sCodArt :=
    dmmPropiedades.unqryArticulos.FieldByName('CODIGO_ART_ART').AsString;
  if sCodArt <> '' then
    ShowMto(Self.Owner, 'Articulos', sCodArt);
end;

initialization
  ForceReferenceToClass(TfrmMtoPropiedades);
end.
