{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoGrupos;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, inMtoPrincipal,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, dxBarBuiltInMenu, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataGrupos, cxCheckBox,
  cxSpinEdit, cxDBEdit, cxCalendar, dxScrollbarAnnotations, cxBlobEdit, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs;

type
  TfrmMtoGrupos = class(TfrmMtoGen)
    cxGrdDBTabPrinGRUPO_USUARIO: TcxGridDBColumn;
    cxGrdDBTabPrinESGRUPOADMINISTRADOR: TcxGridDBColumn;
    Panel1: TPanel;
    cxLabel1: TcxLabel;
    cxLabel2: TcxLabel;
    txtNOMBRE_GRUPO: TcxDBTextEdit;
    cxDBCheckBox1: TcxDBCheckBox;
    cxgrdUsuarios: TcxGrid;
    tvUsuarios: TcxGridDBTableView;
    cxgrdlvlUsuarios: TcxGridLevel;
    tvUsuariosUSUARIO_USUARIO: TcxGridDBColumn;
    tvUsuariosGRUPO_USUARIO: TcxGridDBColumn;
    tvUsuariosEMPRESADEF_USUARIO: TcxGridDBColumn;
    tvUsuariosULTIMOLOGIN_USUARIO: TcxGridDBColumn;
    procedure dsTablaGStateChange(Sender: TObject);
  private
    { Private declarations }
  public
    procedure CrearTablaPrincipal; override;
  end;

var
  frmMtoGrupos: TfrmMtoGrupos;
  dmmGrupos:TdmGrupos;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoGrupos }

procedure TfrmMtoGrupos.CrearTablaPrincipal;
begin
  inherited;
  dmmGrupos :=  tdmDataModule as TdmGrupos;
  dsTablaG.DataSet := dmmGrupos.unqryTablaG;
  tvUsuarios.DataController.DataSource := dmmGrupos.dsUsuariosGrupo;
  pkFieldName := 'GRUPO_USUARIO';
end;

procedure TfrmMtoGrupos.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if (dsTablaG.State = dsInsert) then
    txtNOMBRE_GRUPO.Enabled := True
  else
    txtNOMBRE_GRUPO.Enabled := False;
end;

initialization
  ForceReferenceToClass(TfrmMtoGrupos);
end.
