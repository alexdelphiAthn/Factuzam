{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoUsuarios;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataUsuarios, cxCheckBox,
  cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  cxDBExtLookupComboBox, cxDBLookupComboBox, cxCalendar, Vcl.AppEvnts,
  JvComponentBase, JvEnterTab, dxShellDialogs, dxSkinBlue, dxSkinBasic,
  dxSkinBlack, dxSkinBlueprint, dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom,
  dxSkinDarkSide, dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier, dxSkinValentine,
  dxSkinVisualStudio2013Blue, dxSkinVisualStudio2013Dark,
  dxSkinVisualStudio2013Light, dxSkinVS2010, dxSkinWhiteprint,
  dxSkinXmas2008Blue;

type
  TfrmMtoUsuarios = class(TfrmMtoGen)
    cxGrdDBTabPrinUSUARIO_USUARIO: TcxGridDBColumn;
    cxGrdDBTabPrinPASSWORD_USUARIO: TcxGridDBColumn;
    cxGrdDBTabPrinGRUPO_USUARIO: TcxGridDBColumn;
    cxGrdDBTabPrinEMPRESADEF_USUARIO: TcxGridDBColumn;
    cxGrdDBTabPrinULTIMOLOGIN_USUARIO: TcxGridDBColumn;
    btSetPass: TcxButton;
    cxgrdbclmnGrdDBTabPrinRAZONSOCIAL_EMPRESA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinESGRUPOADMINISTRADOR_GRUPO: TcxGridDBColumn;
    procedure btSetPassClick(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
  private
    { Private declarations }
  public
    procedure CrearTablaPrincipal; override;
  end;

var
  frmMtoUsuarios: TfrmMtoUsuarios;
  dmmUsuarios:TdmUsuarios;

implementation

uses
  inLibWin, inMtoModalGenPass;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoUsuarios }

procedure TfrmMtoUsuarios.btSetPassClick(Sender: TObject);
var
  formulario: TfrmModalGenPass;
begin
  inherited;
  formulario := TfrmModalGenPass.Create(Application);
  formulario.edtUsuario.Text :=
                dmmUsuarios.unqryTablaG.FieldByName('USUARIO_USUARIO').AsString;
  formulario.ShowModal;
  if (formulario.sFicha = 'S') then
  begin
     if ((dsTablaG.DataSet.State <> dsInsert) and
         (dsTablaG.DataSet.State <> dsEdit)) then
       dsTablaG.DataSet.Edit;
     dmmUsuarios.unqryTablaG.FieldByName('PASSWORD_USUARIO').AsString :=
                                              sMd5(formulario.edtPassword.Text);
     dmmUSuarios.unqryTablaG.Post;
  end;
  FreeAndNil(formulario);
end;

procedure TfrmMtoUsuarios.CrearTablaPrincipal;
begin
  inherited;
  dmmUsuarios := tdmDataModule as TdmUsuarios;
  TcxLookupComboBoxProperties(
    cxGrdDBTabPrinGRUPO_USUARIO.Properties).ListSource := dmmUsuarios.dsGrupos;
  dmmUsuarios.unqryGrupos.Open;
  TcxLookupComboBoxProperties(
    cxGrdDBTabPrinEMPRESADEF_USUARIO.Properties).ListSource :=
                                                         dmmUsuarios.dsEmpresas;
  dmmUsuarios.unqryEmpresas.Open;
  pkFieldName := 'USUARIO_USUARIO';
end;

procedure TfrmMtoUsuarios.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if (dsTablaG.State = dsInsert) then
    cxGrdDBTabPrinUSUARIO_USUARIO.Options.Editing := True
  else
    cxGrdDBTabPrinUSUARIO_USUARIO.Options.Editing := False;
end;

initialization
  ForceReferenceToClass(TfrmMtoUsuarios);
end.
