{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaOperacionesHist                                      }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Historico de operaciones de caja.                                         }
{    Consulta de tickets y operaciones realizadas en el TPV.                   }
{******************************************************************************}
unit inMtoCajaOperacionesHist;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataCajaOperacionesHist,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs;

type
  TfrmMtoCajaOperacionesHist = class(TfrmMtoGen)
    cxGrdDBTabPrinCODIGO_EMPRESA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALMACEN_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CAJA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_OPERACION_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinNRO_FACTURA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_FACTURA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_OPERACION_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMPLEADO_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_OPERACION_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinIMPORTE_TOTAL_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CLIENTE_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinESTADO_DEVOLUCION_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinIMPORTE_DEVUELTO_ACUM_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCONCEPTO_GASTO_INGRESO_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_REF_ORIGEN_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_REF_ORIGEN_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinMOTIVO_DEVOLUCION_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMPRESA_CONTRA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALMACEN_CONTRA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinES_TRASPASO_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ARQUEO_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    btnImprimirInforme: TcxButton;
    procedure btnImprimirInformeClick(Sender: TObject);
  private
    dmmCajaOperacionesHist: TdmCajaOperacionesHist;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  frmMtoCajaOperacionesHist: TfrmMtoCajaOperacionesHist;

implementation

uses
  inLibWin, inMtoPrincipal, inMtoModalImpOperaciones;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoCajaOperacionesHist }

procedure TfrmMtoCajaOperacionesHist.btnImprimirInformeClick(Sender: TObject);
var
  frm: TfrmPrintOperaciones;
begin
  inherited;
  // Informe A4 horizontal (FastReport) de las operaciones de caja. El
  // usuario filtra empresa / almacen / caja y rango de fechas en el modal.
  frm := TfrmPrintOperaciones.Create(Application);
  try
    frm.ShowModal;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmMtoCajaOperacionesHist.CrearTablaPrincipal;
begin
  inherited;
  dmmCajaOperacionesHist := tdmDataModule as TdmCajaOperacionesHist;
  pkFieldName := 'CODIGO_EMP_OPCAJA;CODIGO_ALM_OPCAJA;' +
                 'CODIGO_CAJA_OPCAJA;NUMERO_OPERACION_OPCAJA';
end;

procedure TfrmMtoCajaOperacionesHist.ResetForm;
begin
  inherited;
end;

initialization
  ForceReferenceToClass(TfrmMtoCajaOperacionesHist);
end.
