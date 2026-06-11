{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoRemesasCompra                                             }
{    Tipo:       Formulario (Mto)                                               }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Remesas de pago que agrupan efectos (consulta).                          }
{******************************************************************************}
unit inMtoRemesasCompra;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataRemesasCompra,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs;

type
  TfrmMtoRemesasCompra = class(TfrmMtoGen)
    dbcGrdDBTabPrinNUMERO_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinSERIE_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinFECHA_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinESTADO_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinCODIGO_EMP_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinRAZON_SOCIAL_EMPRESA_VIEW_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinCONTADOR_EFECTOS_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinFECHA_CARGO_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinIBAN_REMC: TcxGridDBColumn;
    btnVerEfectos: TcxButton;
    procedure btnVerEfectosClick(Sender: TObject);
  private
    { Private declarations }
  public
    dmmRemesasCompra: TdmRemesasCompra;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  frmMtoRemesasCompra: TfrmMtoRemesasCompra;

implementation

uses
  inLibWin, inMtoPrincipal, inMtoModalVerEfectosRemesa;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoRemesasCompra.CrearTablaPrincipal;
begin
  inherited;
  dmmRemesasCompra := tdmDataModule as TdmRemesasCompra;
  pkFieldName := 'NUMERO_REMC;SERIE_REMC';
end;

procedure TfrmMtoRemesasCompra.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoRemesasCompra.btnVerEfectosClick(Sender: TObject);
var
  frm: TfrmModalVerEfectosRemesa;
  q: TDataSet;
  sSerie, sNum: string;
begin
  inherited;
  if Assigned(dmmRemesasCompra) and dmmRemesasCompra.unqryTablaG.Active and
     (not dmmRemesasCompra.unqryTablaG.IsEmpty) then
  begin
    q      := dmmRemesasCompra.unqryTablaG;
    sSerie := q.FieldByName('SERIE_REMC').AsString;
    sNum   := q.FieldByName('NUMERO_REMC').AsString;
    frm := TfrmModalVerEfectosRemesa.Create(nil);
    try
      frm.Cargar(sSerie, sNum,
        Format('Efectos de la remesa %s / %s', [sSerie, sNum]));
      frm.ShowModal;
    finally
      frm.Free;
    end;
  end
  else
    ShowMessage('Selecciona una remesa.');
end;

initialization
  ForceReferenceToClass(TfrmMtoRemesasCompra);
end.
