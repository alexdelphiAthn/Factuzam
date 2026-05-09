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
  dxShellDialogs;

type
  TfrmMtoAtributosConjuntos = class(TfrmMtoGen)
    cxGrdDBTabPrinID_CONJUNTO_AC: TcxGridDBColumn;
    cxGrdDBTabPrinNOMBRE_AC: TcxGridDBColumn;
    cxGrdDBTabPrinID_VARIACION_AC: TcxGridDBColumn;
    cxGrdDBTabPrinID_ATRIBUTO_AC: TcxGridDBColumn;
    cxGrdDBTabPrinESACTIVO_AC: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
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
  pkFieldName := '`ID_CONJUNTO_AC';
end;

procedure TfrmMtoAtributosConjuntos.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  // ID_CONJUNTO_AC es AUTO_INCREMENT, no editable.
  cxGrdDBTabPrinID_CONJUNTO_AC.Options.Editing := False;
end;

initialization
  ForceReferenceToClass(TfrmMtoAtributosConjuntos);
end.
