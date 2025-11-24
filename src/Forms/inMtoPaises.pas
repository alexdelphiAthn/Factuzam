{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoPaises;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, dxBarBuiltInMenu, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataPaises, cxCheckBox,
  cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  inMtoPrincipal2, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs;

type
  TfrmMtoPaises = class(TfrmMtoGen)
    dbcGrdDBTabPrinCOD_PAIS: TcxGridDBColumn;
    dbcGrdDBTabPrinNOMBRE_SPA_PAIS: TcxGridDBColumn;
    dbcGrdDBTabPrinNOMBRE_ENG_PAIS: TcxGridDBColumn;
    dbcGrdDBTabPrinORDEN_PAIS: TcxGridDBColumn;
    dbcGrdDBTabPrinCOD_PAIS_ALPHA3: TcxGridDBColumn;
  private
    { Private declarations }
  public
    procedure CrearTablaPrincipal; override;
  end;

var
  frmMtoPaises: TfrmMtoPaises;
  dmmPaises:TdmPaises;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoContadores }

procedure TfrmMtoPaises.CrearTablaPrincipal;
begin
  inherited;
  dmmPaises := tdmDataModule as TdmPaises;
  pkFieldName := '`COD_PAIS';
end;

initialization
  ForceReferenceToClass(TfrmMtoPaises);
end.
