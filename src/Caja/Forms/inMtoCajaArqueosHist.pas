{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaArqueosHist                                          }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Histórico de arqueos de caja.                                             }
{    Consulta de los arqueos grabados (cierres Z) con detalle de recuento,     }
{    posibilidad de imprimir informe y exportar a Excel.                       }
{******************************************************************************}
unit inMtoCajaArqueosHist;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataCajaArqueosHist,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, cxCurrencyEdit, cxGridExportLink;

type
  TfrmMtoCajaArqueosHist = class(TfrmMtoGen)
    cxGrdDBTabPrinCODIGO_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMP_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALM_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CAJA_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_DESDE_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_HASTA_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinFASE_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinCANTIDAD_VENTAS_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_NETO_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_VENTAS_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_EFECTIVO_CAJA_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_OTROS_INGRESOS_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_SALDO_RECONTAR_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_RECUENTO_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinDIFERENCIA_TOTAL_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinOBSERVACIONES_ARQ: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTE_ALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIO_ALTA: TcxGridDBColumn;
    btnExportarExcel: TcxButton;
    btnImprimirInforme: TcxButton;
    dlgGuardar: TFileSaveDialog;
    procedure btnExportarExcelClick(Sender: TObject);
    procedure btnImprimirInformeClick(Sender: TObject);
  private
    dmmCajaArqueosHist: TdmCajaArqueosHist;
  public
    procedure CrearTablaPrincipal; override;
    // Restricción de la precarga a la empresa/almacén/caja del usuario
    function SqlRestriccionUsuario: string; override;
    procedure ResetForm; override;
  end;

var
  frmMtoCajaArqueosHist: TfrmMtoCajaArqueosHist;

implementation

uses
  inLibWin, inMtoPrincipal, inMtoModalImpArqueos, inLibFiltroUsuario;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoCajaArqueosHist }

function TfrmMtoCajaArqueosHist.SqlRestriccionUsuario: string;
begin
  // Arqueos: empresa, almacén y caja del terminal
  Result := SqlFiltroEmpAlmCaja(
    ContextoSesion,
    ParametrosApp,
    'CODIGO_EMP_ARQ',
                                'CODIGO_ALM_ARQ',
                                'CODIGO_CAJA_ARQ');
end;

procedure TfrmMtoCajaArqueosHist.CrearTablaPrincipal;
begin
  inherited;
  dmmCajaArqueosHist := tdmDataModule as TdmCajaArqueosHist;
  pkFieldName := 'CODIGO_ARQ';
end;

procedure TfrmMtoCajaArqueosHist.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoCajaArqueosHist.btnExportarExcelClick(Sender: TObject);
begin
  inherited;
  if not PuedeExportar then
    Abort;
  dlgGuardar.DefaultExtension := 'xlsx';
  dlgGuardar.FileName := 'Arqueos_' +
    FormatDateTime('yyyymmdd', Now) + '.xlsx';
  if dlgGuardar.Execute then
    ExportGridToXLSX(dlgGuardar.FileName, cxGrdPrincipal);
end;

procedure TfrmMtoCajaArqueosHist.btnImprimirInformeClick(Sender: TObject);
var
  frm: TfrmPrintArqueos;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  // Informe A4 horizontal (FastReport). El usuario puede retocar el formato
  // con el botón Editar del propio modal y guardarlo como formato propio.
  frm := TfrmPrintArqueos.Create(Application);
  try
    frm.ShowModal;
  finally
    FreeAndNil(frm);
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoCajaArqueosHist);
end.
