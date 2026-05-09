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
    cxGrdDBTabPrinCODIGO_ARTICULO_AP: TcxGridDBColumn;
    cxGrdDBTabPrinID_VALOR_AP: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
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
  pkFieldName := '`CODIGO_ARTICULO_AP;ID_VALOR_AP';
end;

initialization
  ForceReferenceToClass(TfrmMtoArticulosPropiedades);
end.
