{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaValesHist                                            }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Historico de vales emitidos y redimidos.                                  }
{    Consulta de vales generados desde caja.                                   }
{******************************************************************************}
unit inMtoCajaValesHist;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataCajaValesHist,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs;

type
  TfrmMtoCajaValesHist = class(TfrmMtoGen)
    cxGrdDBTabPrinCODIGO_VL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_PADRE_VL: TcxGridDBColumn;
    cxGrdDBTabPrinPIN_SEGURIDAD_VL: TcxGridDBColumn;
    cxGrdDBTabPrinESTADO_VL: TcxGridDBColumn;
    cxGrdDBTabPrinIMPORTE_NOMINAL_VL: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_EMISION_VL: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_CADUCIDAD_VL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMPRESA_EMI_VL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALMACEN_EMI_VL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CAJA_EMI_VL: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_OPERACION_EMI_VL: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_FACTURA_EMI_VL: TcxGridDBColumn;
    cxGrdDBTabPrinNRO_FACTURA_EMI_VL: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_REDENCION_VL: TcxGridDBColumn;
    cxGrdDBTabPrinIMPORTE_REDIMIDO_VL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMPRESA_RED_VL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALMACEN_RED_VL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CAJA_RED_VL: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_OPERACION_RED_VL: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_FACTURA_RED_VL: TcxGridDBColumn;
    cxGrdDBTabPrinNRO_FACTURA_RED_VL: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CLIENTE_VL: TcxGridDBColumn;
    cxGrdDBTabPrinOBSERVACIONES_VL: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
  private
    dmmCajaValesHist: TdmCajaValesHist;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  frmMtoCajaValesHist: TfrmMtoCajaValesHist;

implementation

uses
  inLibWin, inMtoPrincipal;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoCajaValesHist }

procedure TfrmMtoCajaValesHist.CrearTablaPrincipal;
begin
  inherited;
  dmmCajaValesHist := tdmDataModule as TdmCajaValesHist;
  pkFieldName := 'CODIGO_VL';
end;

procedure TfrmMtoCajaValesHist.ResetForm;
begin
  inherited;
end;

initialization
  ForceReferenceToClass(TfrmMtoCajaValesHist);
end.
