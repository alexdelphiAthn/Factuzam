{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoContadores                                               }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de contadores de numeracion.                                }
{    Series y numeros para facturas, albaranes, pedidos y tickets.             }
{******************************************************************************}
unit inMtoContadores;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataContadores, cxCheckBox,
  cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs,
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
    cxGrdDBTabPrinTABLAORIGEN_TIPODOCUMENTO: TcxGridDBColumn;
    btnAjustar: TcxButton;
    procedure btnAjustarClick(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
  private
    procedure FinalizarAjusteContadores(const AError: string);
  public
    dmmContadores: TdmContadores;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibWin, inLibMsgConfiguracion, inLibPermisosIntf;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoContadores }

procedure TfrmMtoContadores.btnAjustarClick(Sender: TObject);
begin
  inherited;
  if not PuedeAccionMto(apmModificar) then
    ShowMessage(SErrorPermisoModificarRegistro)
  else if MessageDlg(SPreguntaAjustarContadores, mtConfirmation,
    [mbYes, mbNo], 0) = mrYes then
    EjecutarEnBackground(
      procedure
      begin
        dmmContadores.AjustarContadores;
      end,
      procedure(AError: string)
      begin
        FinalizarAjusteContadores(AError);
      end);
end;

procedure TfrmMtoContadores.CrearTablaPrincipal;
begin
  inherited;
  dmmContadores := tdmDataModule as TdmContadores;
  pkFieldName := 'TIPO_DOC_CON;SERIE_CON;EMPRESA_CON';
end;

procedure TfrmMtoContadores.ResetForm;
begin
  inherited;
  btnAjustar.Enabled :=
    PuedeAccionMto(apmModificar) and (dsTablaG.State = dsBrowse);
end;

procedure TfrmMtoContadores.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  btnAjustar.Enabled :=
    PuedeAccionMto(apmModificar) and (dsTablaG.State = dsBrowse);
  if dsTablaG.State = dsInsert then
    cxgrdbclmnGrdDBTabPrinTIPODOC_CONTADOR.Options.Editing := True
  else
    cxgrdbclmnGrdDBTabPrinTIPODOC_CONTADOR.Options.Editing := False;
end;

procedure TfrmMtoContadores.FinalizarAjusteContadores(
  const AError: string);
begin
  if AError <> '' then
    ShowMessage(Format(SErrorAjustarContadores, [AError]))
  else
  begin
    dmmContadores.RefrescarContadores;
    ShowMessage(SInfoContadoresAjustados);
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoContadores);
  ForceReferenceToClass(TfrmMtoContadores);
end.
