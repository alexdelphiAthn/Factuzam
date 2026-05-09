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
  inMtoPrincipal, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs;

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
