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
  dxShellDialogs;

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
    tsArticulos: TcxTabSheet;
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
  cxGrdArtView.DataController.DataSource := dmmPropiedades.dsArticulos;
  if not dmmPropiedades.unqryArticulos.Active then
    dmmPropiedades.unqryArticulos.Open;
end;

procedure TfrmMtoPropiedades.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if dsTablaG.State = dsInsert then
    cxGrdDBTabPrinCODIGO_PROP_ARTPROP.Options.Editing := True
  else
    cxGrdDBTabPrinCODIGO_PROP_ARTPROP.Options.Editing := False;
end;

procedure TfrmMtoPropiedades.actGoArticuloUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled :=
    (pcPantalla.ActivePage = tsArticulos) and
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
