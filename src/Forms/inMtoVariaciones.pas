{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoVariaciones                                              }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de variaciones de articulo.                                 }
{    Define ejes de variacion (talla, color, etc.) y sus valores.              }
{******************************************************************************}
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
  Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs,
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
    tsAtributos: TcxTabSheet;
    cxgrdAtributos: TcxGrid;
    tvAtributos: TcxGridDBTableView;
    cxgrdlvlAtributos: TcxGridLevel;
    tvAtributosID_VAR_VA: TcxGridDBColumn;
    tvAtributosID_ATB_VA: TcxGridDBColumn;
    tvAtributosNOMBRE_VA: TcxGridDBColumn;
    tvAtributosORDEN_VA: TcxGridDBColumn;
    tsArticulos: TcxTabSheet;
    pnlArticulos: TPanel;
    cxgrdArticulos: TcxGrid;
    tvArticulos: TcxGridDBTableView;
    cxgrdlvlArticulos: TcxGridLevel;
    tvArticulosCODIGO_ART_ART: TcxGridDBColumn;
    tvArticulosDESCRIPCION_ART: TcxGridDBColumn;
    tvArticulosESACTIVO_ART: TcxGridDBColumn;
    tvArticulosCODIGO_FAM_ART: TcxGridDBColumn;
    tvArticulosNOMBRE_FAM_FAM: TcxGridDBColumn;
    tvArticulosESVARIACION_ART: TcxGridDBColumn;
    splArticulosSkus: TcxSplitter;
    pnlSkus: TPanel;
    cxgrdSkus: TcxGrid;
    tvSkus: TcxGridDBTableView;
    cxgrdlvlSkus: TcxGridLevel;
    tvSkusCODIGO_UNIDAD_SKU: TcxGridDBColumn;
    tvSkusCODIGO_ART_SKU: TcxGridDBColumn;
    tvSkusCODIGO_VAR_SKU: TcxGridDBColumn;
    tvSkusESACTIVO_SKU: TcxGridDBColumn;
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
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

var
  frmMtoVariaciones: TfrmMtoVariaciones;

implementation

uses
  inLibWin, inLibFotos;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoVariaciones }

// Las variaciones afectan a articulos (tvArticulos) y a sus SKUs
// (tvSkus). Manda el SKU enfocado (mas especifico); si no hay, el
// articulo. Asi la foto sigue al registro activo en ambas rejillas.
procedure TfrmMtoVariaciones.ResolverArtSkuActivo(out ACodArt, ACodSku: string);
var
  ds: TDataSet;
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(tvSkus.DataController.DataSource) then
  begin
    ds := tvSkus.DataController.DataSource.DataSet;
    inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
  end;
  if (ACodArt = '') and Assigned(tvArticulos.DataController.DataSource) then
  begin
    ds := tvArticulos.DataController.DataSource.DataSet;
    inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
  end;
end;

function TfrmMtoVariaciones.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmmVariaciones) then
    Result := [dsTablaG, dmmVariaciones.dsArticulosVariacion,
               dmmVariaciones.dsSkusArticulo]
  else
    Result := [dsTablaG];
end;

procedure TfrmMtoVariaciones.CrearTablaPrincipal;
begin
  inherited;
  dmmVariaciones := tdmDataModule as TdmVariaciones;
  tvAtributos.DataController.DataSource  := dmmVariaciones.dsAtributosVariacion;
  tvArticulos.DataController.DataSource  := dmmVariaciones.dsArticulosVariacion;
  tvSkus.DataController.DataSource       := dmmVariaciones.dsSkusArticulo;
  pkFieldName := 'CODIGO_VAR';
end;

procedure TfrmMtoVariaciones.ResetForm;
begin
  inherited;
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
