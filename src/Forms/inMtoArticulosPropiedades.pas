{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoArticulosPropiedades;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataArticulosPropiedades,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, inMtoPrincipal, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs;

type
  TfrmMtoArticulosPropiedades = class(TfrmMtoGen)
    cxGrdDBTabPrinCODIGO_ART_ART: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_PROP_ARTPROP: TcxGridDBColumn;
    cxGrdDBTabPrinID_PV_ARTPROP: TcxGridDBColumn;
    cxGrdDBTabPrinVALOR_LIBRE_ARTPROP: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTE_ALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIO_ALTA: TcxGridDBColumn;
    procedure dsTablaGStateChange(Sender: TObject);
  private
    dmmArticulosPropiedades: TdmArticulosPropiedades;
  public
    procedure CrearTablaPrincipal; override;
  end;

var
  frmMtoArticulosPropiedades: TfrmMtoArticulosPropiedades;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoArticulosPropiedades }

procedure TfrmMtoArticulosPropiedades.CrearTablaPrincipal;
begin
  inherited;
  dmmArticulosPropiedades := tdmDataModule as TdmArticulosPropiedades;
  pkFieldName := '`CODIGO_ART_ART;CODIGO_PROP_ARTPROP';
end;

procedure TfrmMtoArticulosPropiedades.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  // En alta se permite editar las claves; en edición no.
  if dsTablaG.State = dsInsert then
  begin
    cxGrdDBTabPrinCODIGO_ART_ART.Options.Editing := True;
    cxGrdDBTabPrinCODIGO_PROP_ARTPROP.Options.Editing := True;
  end
  else
  begin
    cxGrdDBTabPrinCODIGO_ART_ART.Options.Editing := False;
    cxGrdDBTabPrinCODIGO_PROP_ARTPROP.Options.Editing := False;
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoArticulosPropiedades);
end.
