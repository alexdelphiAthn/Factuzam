{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoContadores;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataContadores, cxCheckBox,
  cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  inMtoPrincipal, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs,
  dxSkinBasic, dxSkinBlack, dxSkinBlue, dxSkinBlueprint, dxSkinCaramel,
  dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide, dxSkinDevExpressDarkStyle,
  dxSkinDevExpressStyle, dxSkinFoggy, dxSkinGlassOceans, dxSkinHighContrast,
  dxSkiniMaginary, dxSkinLilian, dxSkinLiquidSky, dxSkinLondonLiquidSky,
  dxSkinMcSkin, dxSkinMetropolis, dxSkinMetropolisDark, dxSkinMoneyTwins,
  dxSkinOffice2007Black, dxSkinOffice2007Blue, dxSkinOffice2007Green,
  dxSkinOffice2007Pink, dxSkinOffice2007Silver, dxSkinOffice2010Black,
  dxSkinOffice2010Blue, dxSkinOffice2010Silver, dxSkinOffice2013DarkGray,
  dxSkinOffice2013LightGray, dxSkinOffice2013White, dxSkinOffice2016Colorful,
  dxSkinOffice2016Dark, dxSkinOffice2019Black, dxSkinOffice2019Colorful,
  dxSkinOffice2019DarkGray, dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven,
  dxSkinSevenClassic, dxSkinSharp, dxSkinSharpPlus, dxSkinSilver,
  dxSkinSpringtime, dxSkinStardust, dxSkinSummer2008, dxSkinTheAsphaltWorld,
  dxSkinTheBezier, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinXmas2008Blue;

type
  TfrmMtoContadores = class(TfrmMtoGen)
    cxgrdbclmnGrdDBTabPrinTIPODOC_CONTADOR: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinSERIE_CONTADOR: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinCONTADOR_CONTADOR: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinDEFAULT_CONTADOR: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinNUMDIGIT_CONTADOR: TcxGridDBColumn;
    cxGrdDBTabPrinACTIVO_CONTADOR: TcxGridDBColumn;
    cxGrdDBTabPrinEMPRESA_CONTADOR: TcxGridDBColumn;
    cxGrdDBTabPrinDESCRIPCION_TIPODOCUMENTO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinSUBTIPODOC_CONTADOR: TcxGridDBColumn;
    procedure dsTablaGStateChange(Sender: TObject);
  private
    { Private declarations }
  public
    procedure CrearTablaPrincipal; override;
  end;

var
  frmMtoContadores: TfrmMtoContadores;
  dmmContadores:TdmContadores;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoContadores }

procedure TfrmMtoContadores.CrearTablaPrincipal;
begin
  inherited;
  dmmContadores := tdmDataModule as TdmContadores;
  pkFieldName := '`TIPODOC_CONTADOR;SERIE_CONTADOR;EMPRESA_CONTADOR';
end;

procedure TfrmMtoContadores.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  if dsTablaG.State = dsInsert then
    cxgrdbclmnGrdDBTabPrinTIPODOC_CONTADOR.Options.Editing := True
  else
    cxgrdbclmnGrdDBTabPrinTIPODOC_CONTADOR.Options.Editing := False;
end;

initialization
  ForceReferenceToClass(TfrmMtoContadores);
end.
