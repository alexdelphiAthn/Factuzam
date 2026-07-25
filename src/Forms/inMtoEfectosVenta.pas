{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoEfectosVenta                                             }
{    Tipo:       Formulario (Mto)                                               }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cartera de efectos de cobro a cliente (consulta).                       }
{******************************************************************************}
unit inMtoEfectosVenta;

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
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataEfectosVenta,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, cxCurrencyEdit, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs;

type
  TfrmMtoEfectosVenta = class(TfrmMtoGen)
    dbcGrdDBTabPrinNUMERO_FAC_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinSERIE_FAC_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinNUMERO_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinNOMBRE_CLI_VIEW_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinDESCRIPCION_TEFE_VIEW_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinFECHA_VENCIMIENTO_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinIMPORTE_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinIMPORTE_PENDIENTE_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinESTADO_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinREFERENCIA_DOCUMENTO_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinFECHA_COBRO_EFV: TcxGridDBColumn;
    dbcGrdDBTabPrinNUMERO_REMV_EFV: TcxGridDBColumn;
    btnRegistrarCobro: TcxButton;
    btnFusionarEfectos: TcxButton;
    procedure btnRegistrarCobroClick(Sender: TObject);
    procedure btnFusionarEfectosClick(Sender: TObject);
  private
    { Private declarations }
  public
    dmmEfectosVenta: TdmEfectosVenta;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    // Restricción de la precarga a la empresa del usuario
    function SqlRestriccionUsuario: string; override;
  end;

var
  frmMtoEfectosVenta: TfrmMtoEfectosVenta;

implementation

uses
  inLibWin, inMtoPrincipal, inMtoModalRegistrarPago, inLibFiltroUsuario;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoEfectosVenta.CrearTablaPrincipal;
begin
  inherited;
  dmmEfectosVenta := tdmDataModule as TdmEfectosVenta;
  pkFieldName := 'SERIE_FAC_EFV;NUMERO_FAC_EFV;NUMERO_EFV';
end;

procedure TfrmMtoEfectosVenta.ResetForm;
begin
  inherited;
end;

function TfrmMtoEfectosVenta.SqlRestriccionUsuario: string;
begin
  // Los efectos de venta llevan la empresa de la factura origen en
  // cabecera; sin almacén ni caja.
  Result := SqlFiltroEmpAlmCaja(ContextoSesion, 'CODIGO_EMP_EFV', '', '');
end;

procedure TfrmMtoEfectosVenta.btnRegistrarCobroClick(Sender: TObject);
var
  frm: TfrmModalRegistrarPago;
  q: TDataSet;
  iEfe, iRes: Integer;
  fPend: Double;
begin
  inherited;
  if Assigned(dmmEfectosVenta) and dmmEfectosVenta.unqryTablaG.Active and
     (not dmmEfectosVenta.unqryTablaG.IsEmpty) then
  begin
    q     := dmmEfectosVenta.unqryTablaG;
    iEfe  := q.FieldByName('NUMERO_EFV').AsInteger;
    fPend := q.FieldByName('IMPORTE_PENDIENTE_EFV').AsFloat;
    frm := TfrmModalRegistrarPago.Create(nil);
    try
      frm.SetDatos(Format('Efecto %d - pendiente %.2f', [iEfe, fPend]), fPend);
      if frm.ShowModal = mrOk then
      begin
        iRes := dmmEfectosVenta.RegistrarCobro(
          q.FieldByName('SERIE_FAC_EFV').AsString,
          q.FieldByName('NUMERO_FAC_EFV').AsString,
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

procedure TfrmMtoEfectosVenta.btnFusionarEfectosClick(Sender: TObject);
var
  aClaves: TClavesEfectoVenta;
  i: Integer;
  iRec: Integer;
  iRes: Integer;
  sReferencia: string;
begin
  inherited;
  if not Assigned(dmmEfectosVenta) then
    ShowMessage('No hay cartera de efectos abierta.')
  else if cxGrdDBTabPrin.Controller.SelectedRecordCount < 2 then
    ShowMessage('Selecciona dos o más efectos imcobrados.')
  else if MessageDlg('¿Fusionar los efectos seleccionados en un único ' +
          'efecto pendiente?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    SetLength(aClaves, cxGrdDBTabPrin.Controller.SelectedRecordCount);
    for i := 0 to cxGrdDBTabPrin.Controller.SelectedRecordCount - 1 do
    begin
      iRec := cxGrdDBTabPrin.Controller.SelectedRecords[i].RecordIndex;
      aClaves[i].SerieFac := VarToStr(cxGrdDBTabPrin.DataController.Values[
        iRec, dbcGrdDBTabPrinSERIE_FAC_EFV.Index]);
      aClaves[i].NumeroFac := VarToStr(cxGrdDBTabPrin.DataController.Values[
        iRec, dbcGrdDBTabPrinNUMERO_FAC_EFV.Index]);
      aClaves[i].NumeroEfec := StrToIntDef(VarToStr(
        cxGrdDBTabPrin.DataController.Values[
          iRec, dbcGrdDBTabPrinNUMERO_EFV.Index]), 0);
    end;
    iRes := dmmEfectosVenta.FusionarEfectosPendientes(aClaves, sReferencia);
    if iRes > 0 then
      ShowMessage(Format('Efectos conciliados en %s.', [sReferencia]))
    else
      ShowMessage('No se pudieron fusionar los efectos.');
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoEfectosVenta);
end.


