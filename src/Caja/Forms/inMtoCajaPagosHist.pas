{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaPagosHist                                            }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Historico de pagos de caja.                                               }
{    Consulta de pagos asociados a operaciones del TPV.                        }
{******************************************************************************}
unit inMtoCajaPagosHist;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataCajaPagosHist,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs;

type
  TfrmMtoCajaPagosHist = class(TfrmMtoGen)
    cxGrdDBTabPrinCODIGO_EMPRESA_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALMACEN_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CAJA_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_OPERACION_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_OPERACION_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_LINEA_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_FORMAP: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_DIVISA_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinRED_BLOCKCHAIN: TcxGridDBColumn;
    cxGrdDBTabPrinFACTOR_CAMBIO_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinIMPORTE_DIVISA_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinIMPORTE_ENTREGADO_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinIMPORTE_CAMBIO_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinREFERENCIA_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinOBSERVACIONES_PAGO: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    btnImprimirInforme: TcxButton;
    procedure btnImprimirInformeClick(Sender: TObject);
  private
    dmmCajaPagosHist: TdmCajaPagosHist;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  frmMtoCajaPagosHist: TfrmMtoCajaPagosHist;

implementation

uses
  inLibWin, inMtoPrincipal, inMtoModalImpPagos;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoCajaPagosHist }

procedure TfrmMtoCajaPagosHist.btnImprimirInformeClick(Sender: TObject);
var
  frm: TfrmPrintPagos;
begin
  inherited;
  // Informe A4 horizontal (FastReport) de los pagos de caja. El usuario
  // filtra empresa / almacen / caja y rango de fechas en el modal.
  frm := TfrmPrintPagos.Create(Application);
  try
    frm.ShowModal;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmMtoCajaPagosHist.CrearTablaPrincipal;
begin
  inherited;
  dmmCajaPagosHist := tdmDataModule as TdmCajaPagosHist;
  pkFieldName := 'CODIGO_EMP_PAGO;CODIGO_ALM_PAGO;CODIGO_CAJA_PAGO;' +
                 'SERIE_OPERACION_PAGO;NUMERO_OPERACION_PAGO;NUMERO_LINEA_PAGO';
end;

procedure TfrmMtoCajaPagosHist.ResetForm;
begin
  inherited;
end;

initialization
  ForceReferenceToClass(TfrmMtoCajaPagosHist);
end.
