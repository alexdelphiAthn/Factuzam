{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoVerifactuCola                                            }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cola de envíos Verifactu.                                                 }
{    Consulta del estado de fza_verifactu_cola (pendientes, enviadas y         }
{    errores del envío de registros de facturación a la AEAT).                 }
{******************************************************************************}
unit inMtoVerifactuCola;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataVerifactuCola,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs;

type
  TfrmMtoVerifactuCola = class(TfrmMtoGen)
    cxGrdDBTabPrinID_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_FAC_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_FAC_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_OPERACION_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinESTADO_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinCONTADOR_INTENTOS_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTE_PROXIMO_INTENTO_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTE_ENVIO_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinMENSAJE_ERROR_VFCOLA: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
  private
    dmmVerifactuCola: TdmVerifactuCola;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  frmMtoVerifactuCola: TfrmMtoVerifactuCola;

implementation

uses
  inLibWin, inMtoPrincipal;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoVerifactuCola }

procedure TfrmMtoVerifactuCola.CrearTablaPrincipal;
begin
  inherited;
  dmmVerifactuCola := tdmDataModule as TdmVerifactuCola;
  pkFieldName := 'ID_VFCOLA';
end;

procedure TfrmMtoVerifactuCola.ResetForm;
begin
  inherited;
end;

initialization
  ForceReferenceToClass(TfrmMtoVerifactuCola);
end.
