{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inMtoDepositosCliente;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataDepositosCliente,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, inMtoPrincipal, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs;

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
  private
    dmmDepositosCliente: TdmDepositosCliente;
  public
    procedure CrearTablaPrincipal; override;
  end;

var
  frmMtoDepositosCliente: TfrmMtoDepositosCliente;

implementation

uses
  inLibWin;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoDepositosCliente }

procedure TfrmMtoDepositosCliente.CrearTablaPrincipal;
begin
  inherited;
  dmmDepositosCliente := tdmDataModule as TdmDepositosCliente;
  pkFieldName := '`ID_DEPOSITO_DEP';
end;

initialization
  ForceReferenceToClass(TfrmMtoDepositosCliente);
end.
