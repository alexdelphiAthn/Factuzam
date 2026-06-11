{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoEfectosCompra                                             }
{    Tipo:       Formulario (Mto)                                               }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cartera de efectos de pago a proveedor (consulta).                       }
{******************************************************************************}
unit inMtoEfectosCompra;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataEfectosCompra,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs;

type
  TfrmMtoEfectosCompra = class(TfrmMtoGen)
    dbcGrdDBTabPrinNUMERO_FACC_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinSERIE_FACC_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinNUMERO_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinNOMBRE_PRV_VIEW_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinDESCRIPCION_TEFE_VIEW_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinFECHA_VENCIMIENTO_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinIMPORTE_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinIMPORTE_PENDIENTE_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinESTADO_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinFECHA_PAGO_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinNUMERO_REMC_EFEC: TcxGridDBColumn;
  private
    { Private declarations }
  public
    dmmEfectosCompra: TdmEfectosCompra;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  frmMtoEfectosCompra: TfrmMtoEfectosCompra;

implementation

uses
  inLibWin, inMtoPrincipal;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoEfectosCompra.CrearTablaPrincipal;
begin
  inherited;
  dmmEfectosCompra := tdmDataModule as TdmEfectosCompra;
  pkFieldName := 'SERIE_FACC_EFEC;NUMERO_FACC_EFEC;NUMERO_EFEC';
end;

procedure TfrmMtoEfectosCompra.ResetForm;
begin
  inherited;
end;

initialization
  ForceReferenceToClass(TfrmMtoEfectosCompra);
end.
