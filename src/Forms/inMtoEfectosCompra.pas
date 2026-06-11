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
    btnRegistrarPago: TcxButton;
    btnVerPagos: TcxButton;
    procedure btnRegistrarPagoClick(Sender: TObject);
    procedure btnVerPagosClick(Sender: TObject);
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
  inLibWin, inMtoPrincipal, inMtoModalRegistrarPago, inMtoModalVerPagosEfecto;

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

procedure TfrmMtoEfectosCompra.btnRegistrarPagoClick(Sender: TObject);
var
  frm: TfrmModalRegistrarPago;
  q: TDataSet;
  iEfe, iRes: Integer;
  fPend: Double;
begin
  inherited;
  if Assigned(dmmEfectosCompra) and dmmEfectosCompra.unqryTablaG.Active and
     (not dmmEfectosCompra.unqryTablaG.IsEmpty) then
  begin
    q     := dmmEfectosCompra.unqryTablaG;
    iEfe  := q.FieldByName('NUMERO_EFEC').AsInteger;
    fPend := q.FieldByName('IMPORTE_PENDIENTE_EFEC').AsFloat;
    frm := TfrmModalRegistrarPago.Create(nil);
    try
      frm.SetDatos(Format('Efecto %d - pendiente %.2f', [iEfe, fPend]), fPend);
      if frm.ShowModal = mrOk then
      begin
        iRes := dmmEfectosCompra.RegistrarPago(
          q.FieldByName('SERIE_FACC_EFEC').AsString,
          q.FieldByName('NUMERO_FACC_EFEC').AsString,
          iEfe, frm.Fecha, frm.Importe, frm.Tipo, frm.Referencia);
        if iRes > 0 then
          ShowMessage('Pago registrado.')
        else
          ShowMessage('No se pudo registrar el pago.');
      end;
    finally
      frm.Free;
    end;
  end
  else
    ShowMessage('Selecciona un efecto en la rejilla.');
end;

procedure TfrmMtoEfectosCompra.btnVerPagosClick(Sender: TObject);
var
  frm: TfrmModalVerPagosEfecto;
  q: TDataSet;
  iEfe: Integer;
begin
  inherited;
  if Assigned(dmmEfectosCompra) and dmmEfectosCompra.unqryTablaG.Active and
     (not dmmEfectosCompra.unqryTablaG.IsEmpty) then
  begin
    q    := dmmEfectosCompra.unqryTablaG;
    iEfe := q.FieldByName('NUMERO_EFEC').AsInteger;
    frm := TfrmModalVerPagosEfecto.Create(nil);
    try
      frm.Cargar(q.FieldByName('SERIE_FACC_EFEC').AsString,
                 q.FieldByName('NUMERO_FACC_EFEC').AsString, iEfe,
                 Format('Pagos del efecto %d', [iEfe]));
      frm.ShowModal;
    finally
      frm.Free;
    end;
  end
  else
    ShowMessage('Selecciona un efecto en la rejilla.');
end;

initialization
  ForceReferenceToClass(TfrmMtoEfectosCompra);
end.
