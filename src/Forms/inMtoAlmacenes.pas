{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoAlmacenes                                                }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/02/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de almacenes.                                               }
{    CRUD sobre fza_almacenes por empresa.                                     }
{******************************************************************************}
unit inMtoAlmacenes;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataAlmacenes, cxCheckBox,
  cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs,
  cxSplitter, cxMaskEdit, cxDBEdit, cxDropDownEdit;

type
  TfrmMtoAlmacenes = class(TfrmMtoGen)
    dbcGrdDBTabPrinCODIGO_ALMACEN_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_EMPRESA_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinNOMBRE_ALMACEN_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinESACTIVO_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinESWEB_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_PADRE_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinESFISICO_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinTIPO_USO_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinDIRECCION_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinPOBLACION_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_POSTAL_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinTELEFONO_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinEMAIL_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_CLIENTE_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinALMACEN_DESTINO_ACTUAL_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinALMACEN_ORIGEN_ACTUAL_ALM: TcxGridDBColumn;
    dbcGrdDBTabPrinORDEN_ALM: TcxGridDBColumn;
    pnlTopFicha: TPanel;
    pnlBodyFicha: TPanel;
    lblCodigo: TcxLabel;
    txtCODIGO_ALMACEN_ALM: TcxDBTextEdit;
    lblCodigoEmpresa: TcxLabel;
    txtCODIGO_EMPRESA_ALM: TcxDBTextEdit;
    lblNombre: TcxLabel;
    txtNOMBRE_ALMACEN_ALM: TcxDBTextEdit;
    chkESACTIVO_ALM: TcxDBCheckBox;
    chkESWEB_ALM: TcxDBCheckBox;
    chkESFISICO_ALM: TcxDBCheckBox;
    lblOrden: TcxLabel;
    spnORDEN_ALM: TcxDBSpinEdit;
    pnlButtonFicha: TPanel;
    pcDetail: TcxPageControl;
    tsAuditoria: TcxTabSheet;
    pnlAuditoria: TPanel;
    lblUsuarioAlta: TcxLabel;
    txtUSUARIOALTA: TcxDBTextEdit;
    lblInstanteAlta: TcxLabel;
    txtINSTANTEALTA: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    txtUSUARIOMODIF: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    txtINSTANTEMODIF: TcxDBTextEdit;
    splSplitterFicha: TcxSplitter;
    tsCajas: TcxTabSheet;
    pnlSeriesCli: TPanel;
    cxgrdAlmacenCajas: TcxGrid;
    tvAlmacenesCajas: TcxGridDBTableView;
    lvAlmacenCajas: TcxGridLevel;
    tsUsosAlmacen: TcxTabSheet;
    lblAlmacenDestino: TcxLabel;
    lblAlmacenOrigen: TcxLabel;
    cxdbtxtdtALMACEN_ORIGEN_ACTUAL_ALM: TcxDBTextEdit;
    cxdbtxtdtALMACEN_DESTINO_ACTUAL_ALM: TcxDBTextEdit;
    lblTipoUso: TcxLabel;
    cxdbtxtdtTIPO_USO_ALM: TcxDBComboBox;
    lblCodigoPadre: TcxLabel;
    cxdbtxtdtCODIGO_PADRE_ALM: TcxDBTextEdit;
    tsDireccion: TcxTabSheet;
    lblTelefono: TcxLabel;
    cxdbtxtdtTELEFONO_ALM: TcxDBTextEdit;
    lblEmail: TcxLabel;
    cxdbtxtdtEMAIL_ALM: TcxDBTextEdit;
    lblPoblacion: TcxLabel;
    cxdbtxtdtCODPOSTAL: TcxDBTextEdit;
    cxdbtxtdtPOBLACION_ALM: TcxDBTextEdit;
    lblDireccion: TcxLabel;
    cxdbtxtdtDIRECCION_ALM: TcxDBTextEdit;
    lblProvincia: TcxLabel;
    cxdbtxtdtPROVINCIA_ALM: TcxDBTextEdit;
    lblCodigoCliente: TcxLabel;
    cxdbtxtdtCODIGO_CLIENTE_ALM: TcxDBTextEdit;
    dbmAlmacenesCajasCODIGO_ALMACEN_ALMCAJ: TcxGridDBColumn;
    dbmAlmacenesCajasCODIGO_CAJA_ALMCAJ: TcxGridDBColumn;
    dbmAlmacenesCajasDESCRIPCION_ALMCAJ: TcxGridDBColumn;
  private
    { Private declarations }
  public
    dmmAlmacenes: TdmAlmacenes;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoAlmacenes }

procedure TfrmMtoAlmacenes.CrearTablaPrincipal;
begin
  inherited;
  dmmAlmacenes := tdmDataModule as TdmAlmacenes;
  pkFieldName := 'CODIGO_ALM_ALM';
end;

procedure TfrmMtoAlmacenes.ResetForm;
begin
  inherited;
end;

initialization
  RegistrarPantalla(TfrmMtoAlmacenes);
  ForceReferenceToClass(TfrmMtoAlmacenes);
end.
