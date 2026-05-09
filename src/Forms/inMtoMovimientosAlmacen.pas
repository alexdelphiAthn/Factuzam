{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoMovimientosAlmacen;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataMovimientosAlmacen,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, inMtoPrincipal, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs;

type
  TfrmMtoMovimientosAlmacen = class(TfrmMtoGen)
    cxGrdDBTabPrinNUMERO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_DOC_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_DOC_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinNRO_DOC_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinLINEA_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMPRESA_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALMACEN_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ARTICULO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_UNIDAD_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinDESCRIPCION_ARTICULO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_MOVIMIENTO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCANTIDAD_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinPRECIO_COSTE_UNITARIO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinTOTAL_COSTE_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinPRECIO_MEDIO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALMACEN_CONTRA_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CLIENTE_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_PROVEEDOR_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinESACTIVO_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_DOC_REF_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_DOC_REF_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinNRO_DOC_REF_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinLINEA_REF_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinLOTE_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_CADUCIDAD_MOV: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
  private
    dmmMovimientosAlmacen: TdmMovimientosAlmacen;
  public
    procedure CrearTablaPrincipal; override;
  end;

var
  frmMtoMovimientosAlmacen: TfrmMtoMovimientosAlmacen;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoMovimientosAlmacen }

procedure TfrmMtoMovimientosAlmacen.CrearTablaPrincipal;
begin
  inherited;
  dmmMovimientosAlmacen := tdmDataModule as TdmMovimientosAlmacen;
  pkFieldName := '`NUMERO_MOV';
end;

initialization
  ForceReferenceToClass(TfrmMtoMovimientosAlmacen);
end.
