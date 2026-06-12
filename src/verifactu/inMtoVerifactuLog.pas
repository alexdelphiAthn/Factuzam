{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoVerifactuLog                                             }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Log Verifactu.                                                            }
{    Consulta del registro de eventos del subsistema Verifactu                 }
{    (fza_verifactu_eventos): envíos, errores y cadena de hashes.              }
{******************************************************************************}
unit inMtoVerifactuLog;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataVerifactuLog,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs;

type
  TfrmMtoVerifactuLog = class(TfrmMtoGen)
    cxGrdDBTabPrinID_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinTIMESTAMP_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_EVENTO_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinDESCRIPCION_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinDATOS_ADICIONALES_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_FAC_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_FAC_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIO_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinVERSION_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinHASH_ANTERIOR_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinHASH_PROPIO_LOG: TcxGridDBColumn;
    cxGrdDBTabPrinFIRMA_DIGITAL_LOG: TcxGridDBColumn;
  private
    dmmVerifactuLog: TdmVerifactuLog;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  frmMtoVerifactuLog: TfrmMtoVerifactuLog;

implementation

uses
  inLibWin, inMtoPrincipal;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoVerifactuLog }

procedure TfrmMtoVerifactuLog.CrearTablaPrincipal;
begin
  inherited;
  dmmVerifactuLog := tdmDataModule as TdmVerifactuLog;
  pkFieldName := 'ID_LOG';
end;

procedure TfrmMtoVerifactuLog.ResetForm;
begin
  inherited;
end;

initialization
  ForceReferenceToClass(TfrmMtoVerifactuLog);
end.
