{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoUsuariosPerfiles;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, inmtoprincipal,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataUsuariosPerfiles, cxCheckBox,
  cxSpinEdit, cxDBEdit, cxCalendar, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs;

type
  TfrmMtoUsuariosPerfiles = class(TfrmMtoGen)
    cxGrdDBTabPrinUSUARIO_GRUPO_PERFILES: TcxGridDBColumn;
    cxGrdDBTabPrinKEY_PERFILES: TcxGridDBColumn;
    cxGrdDBTabPrinSUBKEY_PERFILES: TcxGridDBColumn;
    cxGrdDBTabPrinVALUE_PERFILES: TcxGridDBColumn;
    cxGrdDBTabPrinVALUE_TEXT_PERFILES: TcxGridDBColumn;
    cxGrdDBTabPrinTYPE_BLOB_PERFILES: TcxGridDBColumn;
    cxGrdDBTabPrinVALUE_BLOB_PERFILES: TcxGridDBColumn;
  private
    { Private declarations }
  public
    procedure CrearTablaPrincipal; override;
  end;

var
  frmMtoUsuariosPerfiles: TfrmMtoUsuariosPerfiles;
  dmmUsuariosPerfiles:TdmUsuariosPerfiles;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoUsuariosPerfiles }

procedure TfrmMtoUsuariosPerfiles.CrearTablaPrincipal;
begin
  inherited;
  dmmUsuariosPerfiles := tdmDataModule as TdmUsuariosPerfiles;
  dsTablaG.DataSet := dmmUsuariosPerfiles.unqryTablaG;
  pkFieldName := 'USUARIO_GRUPO_PERFILES;KEY_PERFILES;SUBKEY_PERFILES';
end;

initialization
  ForceReferenceToClass(TfrmMtoUsuariosPerfiles);
end.
