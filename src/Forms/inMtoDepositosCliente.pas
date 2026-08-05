{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoDepositosCliente                                         }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de depositos de cliente.                                    }
{    Gestion de saldos depositados a cuenta por cada cliente.                  }
{******************************************************************************}
unit inMtoDepositosCliente;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataDepositosCliente,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, cxSplitter, inLibFotos,
  inLibPermisosIntf, inLibCajaPantallaInyeccion;

type
  TfrmMtoDepositosCliente = class(TfrmMtoGen)
    cxGrdDBTabPrinID_DEPOSITO_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMPRESA_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CLIENTE_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ARTICULO_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_UNIDAD_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinPRECIO_VENTA_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinIMPORTE_ANTICIPO_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinESTADO_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_CREACION_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_IVA_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinPORCEN_IVA_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinESIMP_INCL_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinCANTIDAD_PENDIENTE_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_ENTREGA_DEP: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    splFotoDep: TcxSplitter;
    pnlFotoDep: TPanel;
    imgFotoDep: TImage;
    btnImprimirInforme: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnImprimirInformeClick(Sender: TObject);
  private
    dmmDepositosCliente: TdmDepositosCliente;
    FFotoEmb: TFotoEmbebida;
    FDependenciasInforme: TDependenciasInformeCaja;
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ADependencias: TDependenciasInformeCaja); reintroduce;
      overload;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibWin, inMtoModalImpDepositos;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoDepositosCliente }

constructor TfrmMtoDepositosCliente.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ADependencias: TDependenciasInformeCaja);
begin
  ADependencias.Validar;
  FDependenciasInforme := ADependencias;
  inherited Create(AOwner, AContexto);
end;

procedure TfrmMtoDepositosCliente.FormCreate(Sender: TObject);
begin
  inherited;
  // Foto embebida del articulo / SKU de la fila activa de dsTablaG.
  FFotoEmb := TFotoEmbebida.Create(
    FotosArticulos, imgFotoDep, dsTablaG);
end;

procedure TfrmMtoDepositosCliente.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FFotoEmb);
  inherited;
end;

procedure TfrmMtoDepositosCliente.CrearTablaPrincipal;
begin
  inherited;
  dmmDepositosCliente := tdmDataModule as TdmDepositosCliente;
  pkFieldName := 'ID_DEPOSITO_DEP';
end;

procedure TfrmMtoDepositosCliente.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoDepositosCliente.btnImprimirInformeClick(Sender: TObject);
var
  frm: TfrmPrintDepositos;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  // Informe A4 horizontal (FastReport) de los depositos de clientes. El
  // usuario filtra empresa / almacen / caja y rango de fechas en el modal.
  frm := TfrmPrintDepositos.Create(
    Application,
    FDependenciasInforme);
  try
    frm.ShowModal;
  finally
    FreeAndNil(frm);
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoDepositosCliente);
  ForceReferenceToClass(TfrmMtoDepositosCliente);
end.
