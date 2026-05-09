{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

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
  cxRadioGroup, inMtoPrincipal, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
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
  private
    dmmCajaOperacionesHist: TdmCajaOperacionesHist;
  public
    procedure CrearTablaPrincipal; override;
  end;

var
  frmMtoCajaOperacionesHist: TfrmMtoCajaOperacionesHist;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoCajaOperacionesHist }

procedure TfrmMtoCajaOperacionesHist.CrearTablaPrincipal;
begin
  inherited;
  dmmCajaOperacionesHist := tdmDataModule as TdmCajaOperacionesHist;
  pkFieldName := '`CODIGO_EMPRESA_OPCAJA;CODIGO_ALMACEN_OPCAJA;' +
                 'CODIGO_CAJA_OPCAJA;NUMERO_OPERACION_OPCAJA';
end;

initialization
  ForceReferenceToClass(TfrmMtoCajaOperacionesHist);
end.
