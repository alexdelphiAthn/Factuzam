{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

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
    cxGrdDBTabPrinCODIGO_PROP_ARTPROP: TcxGridDBColumn;
    cxGrdDBTabPrinNOMBRE_PROP_PROP: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_VALOR_PROP: TcxGridDBColumn;
    cxGrdDBTabPrinESACTIVO_PROP: TcxGridDBColumn;
    cxGrdDBTabPrinNUM_ART_USOS: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTE_MODIF: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTE_ALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIO_ALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIO_MODIF: TcxGridDBColumn;

    pnlCabFicha: TPanel;
    splFicha: TcxSplitter;
    pnlBodyFicha: TPanel;

    lblCodigo: TcxLabel;
    edtCodigo: TcxDBTextEdit;
    lblNombre: TcxLabel;
    edtNombre: TcxDBTextEdit;
    lblTipo: TcxLabel;
    cmbTipo: TcxDBComboBox;
    chkActivo: TcxDBCheckBox;

    pcDetalleFicha: TcxPageControl;
    tsValores: TcxTabSheet;
    tsArticulos: TcxTabSheet;

    cxGrdValores: TcxGrid;
    cxGrdValView: TcxGridDBTableView;
    cxGrdValLevel: TcxGridLevel;
    cxGrdValPV: TcxGridDBColumn;
    cxGrdValDESCRIPCION_PV: TcxGridDBColumn;
    cxGrdValESACTIVO_PV: TcxGridDBColumn;
    cxGrdValINSTANTE_ALTA: TcxGridDBColumn;
    cxGrdValUSUARIO_ALTA: TcxGridDBColumn;

    cxGrdArticulos: TcxGrid;
    cxGrdArtView: TcxGridDBTableView;
    cxGrdArtLevel: TcxGridLevel;
    cxGrdArtCODIGO_ART_ART: TcxGridDBColumn;
    cxGrdArtDESCRIPCION_ARTICULO: TcxGridDBColumn;
    cxGrdArtVALOR_LISTA: TcxGridDBColumn;
    cxGrdArtVALOR_LIBRE_ARTPROP: TcxGridDBColumn;
    cxGrdArtINSTANTE_ALTA: TcxGridDBColumn;
    cxGrdArtUSUARIO_ALTA: TcxGridDBColumn;

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
  end;

var
  frmMtoPropiedades: TfrmMtoPropiedades;

implementation

uses
  inLibWin, inLibShowMto;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoPropiedades }

procedure TfrmMtoPropiedades.CrearTablaPrincipal;
begin
  inherited;
  dmmPropiedades := tdmDataModule as TdmPropiedades;
  pkFieldName := '`CODIGO_PROP_ARTPROP';

  // Conexión y arranque de los datasets de detalle (master-detail vivo).
  dmmPropiedades.unqryArticulos.Connection := oConn;
  dmmPropiedades.unqryValores.Connection   := oConn;
  if not dmmPropiedades.unqryArticulos.Active then
    dmmPropiedades.unqryArticulos.Open;
  if not dmmPropiedades.unqryValores.Active then
    dmmPropiedades.unqryValores.Open;

  cxGrdArtView.DataController.DataSource := dmmPropiedades.dsArticulos;
  cxGrdValView.DataController.DataSource := dmmPropiedades.dsValores;
  dmmPropiedades.unqryValores.BeforePost := unqryValoresBeforePost;
end;

procedure TfrmMtoPropiedades.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  // El código de la propiedad solo se edita en alta.
  if dsTablaG.State = dsInsert then
    edtCodigo.Properties.ReadOnly := False
  else
    edtCodigo.Properties.ReadOnly := True;
end;

procedure TfrmMtoPropiedades.unqryValoresBeforePost(DataSet: TDataSet);
begin
  // Auto-asociar el valor a la propiedad activa al dar de alta.
  if (DataSet.State = dsInsert) and
     Assigned(dmmPropiedades) and
     dmmPropiedades.unqryTablaG.Active and
     not dmmPropiedades.unqryTablaG.IsEmpty then
  begin
    if DataSet.FieldByName('ID_PROP_PV').IsNull then
      DataSet.FieldByName('ID_PROP_PV').AsString :=
        dmmPropiedades.unqryTablaG.FieldByName('CODIGO_PROP_ARTPROP').AsString;
    if DataSet.FindField('ESACTIVO_PV') <> nil then
      if DataSet.FieldByName('ESACTIVO_PV').IsNull then
        DataSet.FieldByName('ESACTIVO_PV').AsString := 'S';
  end;
  // Audit fields (las nombres con _ los rellena el helper estándar).
  oDmConn.ActualizarUserTimeModif(DataSet);
end;

procedure TfrmMtoPropiedades.actGoArticuloUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled :=
    (pcPantalla.ActivePage = tsFicha) and
    (pcDetalleFicha.ActivePage = tsArticulos) and
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
  sCodArt := dmmPropiedades.unqryArticulos.FieldByName('CODIGO_ART_ART').AsString;
  if sCodArt <> '' then
    ShowMto(Self.Owner, 'Articulos', sCodArt);
end;

initialization
  ForceReferenceToClass(TfrmMtoPropiedades);
end.
