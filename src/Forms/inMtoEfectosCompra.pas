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
  System.Classes, System.UITypes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataEfectosCompra,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, cxCurrencyEdit, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs;

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
    dbcGrdDBTabPrinREFERENCIA_DOCUMENTO_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinFECHA_PAGO_EFEC: TcxGridDBColumn;
    dbcGrdDBTabPrinNUMERO_REMC_EFEC: TcxGridDBColumn;
    btnRegistrarPago: TcxButton;
    btnFusionarEfectos: TcxButton;
    procedure btnRegistrarPagoClick(Sender: TObject);
    procedure btnFusionarEfectosClick(Sender: TObject);
  private
    { Private declarations }
  public
    dmmEfectosCompra: TdmEfectosCompra;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    // Restricción de la precarga a la empresa del usuario
    function SqlRestriccionUsuario: string; override;
  end;

var
  frmMtoEfectosCompra: TfrmMtoEfectosCompra;

implementation

uses
  inLibWin, inMtoPrincipal, inMtoModalRegistrarPago, inLibFiltroUsuario;

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

function TfrmMtoEfectosCompra.SqlRestriccionUsuario: string;
begin
  // Los efectos de compra llevan la empresa de la factura origen en
  // cabecera; sin almacén ni caja.
  Result := SqlFiltroEmpAlmCaja(
    ContextoSesion,
    ParametrosApp,
    'CODIGO_EMP_EFEC',
    '',
    '');
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
          ShowMessage('Efecto conciliado.')
        else
          ShowMessage('No se pudo conciliar el efecto.');
      end;
    finally
      frm.Free;
    end;
  end
  else
    ShowMessage('Selecciona un efecto en la rejilla.');
end;

procedure TfrmMtoEfectosCompra.btnFusionarEfectosClick(Sender: TObject);
var
  aClaves: TClavesEfectoCompra;
  i: Integer;
  iRec: Integer;
  iRes: Integer;
  sReferencia: string;
begin
  inherited;
  if not Assigned(dmmEfectosCompra) then
    ShowMessage('No hay cartera de efectos abierta.')
  else if cxGrdDBTabPrin.Controller.SelectedRecordCount < 2 then
    ShowMessage('Selecciona dos o más efectos impagados.')
  else if MessageDlg('¿Fusionar los efectos seleccionados en un único ' +
          'efecto pendiente?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    SetLength(aClaves, cxGrdDBTabPrin.Controller.SelectedRecordCount);
    for i := 0 to cxGrdDBTabPrin.Controller.SelectedRecordCount - 1 do
    begin
      iRec := cxGrdDBTabPrin.Controller.SelectedRecords[i].RecordIndex;
      aClaves[i].SerieFac := VarToStr(cxGrdDBTabPrin.DataController.Values[
        iRec, dbcGrdDBTabPrinSERIE_FACC_EFEC.Index]);
      aClaves[i].NumeroFac := VarToStr(cxGrdDBTabPrin.DataController.Values[
        iRec, dbcGrdDBTabPrinNUMERO_FACC_EFEC.Index]);
      aClaves[i].NumeroEfec := StrToIntDef(VarToStr(
        cxGrdDBTabPrin.DataController.Values[
          iRec, dbcGrdDBTabPrinNUMERO_EFEC.Index]), 0);
    end;
    iRes := dmmEfectosCompra.FusionarEfectosPendientes(aClaves, sReferencia);
    if iRes > 0 then
      ShowMessage(Format('Efectos conciliados en %s.', [sReferencia]))
    else
      ShowMessage('No se pudieron fusionar los efectos.');
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoEfectosCompra);
end.
