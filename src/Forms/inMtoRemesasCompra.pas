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
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.UITypes, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, UniDataRemesasCompra,
  cxCheckBox, cxSpinEdit, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, Vcl.AppEvnts, JvComponentBase, JvEnterTab, dxShellDialogs,
  cxDBEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxCurrencyEdit, cxMemo,
  cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox;

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
    pnlFichaCabecera: TPanel;
    lblNumero: TcxLabel;
    txtNUMERO_REMC: TcxDBTextEdit;
    lblSerie: TcxLabel;
    txtSERIE_REMC: TcxDBTextEdit;
    lblFecha: TcxLabel;
    dteFECHA_REMC: TcxDBDateEdit;
    lblEstado: TcxLabel;
    txtESTADO_REMC: TcxDBTextEdit;
    lblEmpresa: TcxLabel;
    txtCODIGO_EMP_REMC: TcxDBTextEdit;
    lblRazonSocial: TcxLabel;
    txtRAZON_SOCIAL_EMPRESA_VIEW_REMC: TcxDBTextEdit;
    lblTotal: TcxLabel;
    curTOTAL_REMC: TcxDBCurrencyEdit;
    lblContadorEfectos: TcxLabel;
    txtCONTADOR_EFECTOS_REMC: TcxDBTextEdit;
    lblFechaCargo: TcxLabel;
    dteFECHA_CARGO_REMC: TcxDBDateEdit;
    lblIBAN: TcxLabel;
    txtIBAN_REMC: TcxDBTextEdit;
    lblCargoRealizado: TcxLabel;
    curTOTAL_CARGADO_REMC: TcxDBCurrencyEdit;
    lblPendienteCargo: TcxLabel;
    curTOTAL_PENDIENTE_REMC: TcxDBCurrencyEdit;
    lblBancoPago: TcxLabel;
    cbbBancoPagoRemesa: TcxLookupComboBox;
    lblObservaciones: TcxLabel;
    memOBSERVACIONES_REMC: TcxDBMemo;
    pnlFichaDetalle: TPanel;
    pnlEfectosTitulo: TPanel;
    lblEfectosRemesa: TcxLabel;
    cxgrdEfectosRemesa: TcxGrid;
    tvEfectosRemesa: TcxGridDBTableView;
    tvEfectosRemesaNUMERO_FACC_EFEC: TcxGridDBColumn;
    tvEfectosRemesaSERIE_FACC_EFEC: TcxGridDBColumn;
    tvEfectosRemesaNUMERO_EFEC: TcxGridDBColumn;
    tvEfectosRemesaPROVEEDOR_VIEW_EFEC: TcxGridDBColumn;
    tvEfectosRemesaDESCRIPCION_TEFE_VIEW_EFEC: TcxGridDBColumn;
    tvEfectosRemesaFECHA_VENCIMIENTO_EFEC: TcxGridDBColumn;
    tvEfectosRemesaIMPORTE_EFEC: TcxGridDBColumn;
    tvEfectosRemesaIMPORTE_PAGADO_EFEC: TcxGridDBColumn;
    tvEfectosRemesaIMPORTE_PENDIENTE_EFEC: TcxGridDBColumn;
    tvEfectosRemesaESTADO_EFEC: TcxGridDBColumn;
    tvEfectosRemesaREFERENCIA_DOCUMENTO_EFEC: TcxGridDBColumn;
    tvEfectosRemesaFECHA_PAGO_EFEC: TcxGridDBColumn;
    tvEfectosRemesaDOC_EXTERNO_EFEC: TcxGridDBColumn;
    lvlEfectosRemesa: TcxGridLevel;
    btnAnadirEfecto: TcxButton;
    btnQuitarEfecto: TcxButton;
    btnPagarEfecto: TcxButton;
    btnPagarRemesa: TcxButton;
    btnAsignarBanco: TcxButton;
    btnFechaCargo: TcxButton;
    dbcGrdDBTabPrinTOTAL_CARGADO_REMC: TcxGridDBColumn;
    dbcGrdDBTabPrinTOTAL_PENDIENTE_REMC: TcxGridDBColumn;
    procedure btnAnadirEfectoClick(Sender: TObject);
    procedure btnQuitarEfectoClick(Sender: TObject);
    procedure btnPagarEfectoClick(Sender: TObject);
    procedure btnPagarRemesaClick(Sender: TObject);
    procedure btnAsignarBancoClick(Sender: TObject);
    procedure btnFechaCargoClick(Sender: TObject);
  private
    procedure ActualizarBancoPago;
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    function BancoRemesaAsignado: Boolean;
    function RemesaSeleccionada: Boolean;
  public
    dmmRemesasCompra: TdmRemesasCompra;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

var
  frmMtoRemesasCompra: TfrmMtoRemesasCompra;

implementation

uses
  inLibWin, inMtoPrincipal, inMtoModalCargarEfectosRemesa,
  inMtoModalRegistrarPago;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoRemesasCompra.CrearTablaPrincipal;
begin
  inherited;
  dmmRemesasCompra := tdmDataModule as TdmRemesasCompra;
  tvEfectosRemesa.DataController.DataSource :=
    dmmRemesasCompra.dsEfectosRemesa;
  dmmRemesasCompra.unqryEfectosRemesa.MasterSource := dsTablaG;
  dmmRemesasCompra.unqryBancosEmpresa.MasterSource := dsTablaG;
  cbbBancoPagoRemesa.Properties.ListSource :=
    dmmRemesasCompra.dsBancosEmpresa;
  cbbBancoPagoRemesa.Properties.KeyFieldNames := 'CODIGO_EMPBAN';
  cbbBancoPagoRemesa.Properties.ListFieldNames := 'BANCO_VIEW_EMPBAN';
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  pkFieldName := 'NUMERO_REMC;SERIE_REMC';
end;

procedure TfrmMtoRemesasCompra.ResetForm;
begin
  inherited;
end;

function TfrmMtoRemesasCompra.RemesaSeleccionada: Boolean;
begin
  Result := Assigned(dmmRemesasCompra) and
            dmmRemesasCompra.unqryTablaG.Active and
            (not dmmRemesasCompra.unqryTablaG.IsEmpty);
end;

function TfrmMtoRemesasCompra.BancoRemesaAsignado: Boolean;
begin
  Result := RemesaSeleccionada and
            (Trim(dmmRemesasCompra.unqryTablaG.FieldByName('IBAN_REMC')
              .AsString) <> '');
end;

procedure TfrmMtoRemesasCompra.ActualizarBancoPago;
var
  sIban: string;
begin
  cbbBancoPagoRemesa.EditValue := Null;
  if Assigned(dmmRemesasCompra) and dmmRemesasCompra.unqryBancosEmpresa.Active
     and RemesaSeleccionada then
  begin
    sIban := Trim(dmmRemesasCompra.unqryTablaG.FieldByName('IBAN_REMC')
      .AsString);
    if (sIban <> '') and
       dmmRemesasCompra.unqryBancosEmpresa.Locate('IBAN_EMPBAN', sIban, []) then
      cbbBancoPagoRemesa.EditValue :=
        dmmRemesasCompra.unqryBancosEmpresa.FieldByName('CODIGO_EMPBAN')
          .AsString
    else if (sIban = '') and
            (not dmmRemesasCompra.unqryBancosEmpresa.IsEmpty) then
    begin
      dmmRemesasCompra.unqryBancosEmpresa.First;
      cbbBancoPagoRemesa.EditValue :=
        dmmRemesasCompra.unqryBancosEmpresa.FieldByName('CODIGO_EMPBAN')
          .AsString;
    end;
  end;
end;

procedure TfrmMtoRemesasCompra.dsTablaGDataChangeHook(Sender: TObject;
  Field: TField);
begin
  if Field = nil then
    ActualizarBancoPago;
end;

procedure TfrmMtoRemesasCompra.btnAnadirEfectoClick(Sender: TObject);
var
  frm: TfrmModalCargarEfectosRemesa;
  q: TDataSet;
begin
  inherited;
  if not RemesaSeleccionada then
    ShowMessage('Selecciona una remesa.')
  else if dmmRemesasCompra.RemesaTieneCargo then
    ShowMessage('No se pueden añadir efectos a una remesa con cargo realizado.')
  else
  begin
    q := dmmRemesasCompra.unqryTablaG;
    frm := TfrmModalCargarEfectosRemesa.Create(nil);
    try
      frm.PrepararRemesaExistente(q.FieldByName('CODIGO_EMP_REMC').AsString,
        q.FieldByName('SERIE_REMC').AsString,
        q.FieldByName('NUMERO_REMC').AsString);
      if frm.ShowModal = mrOk then
      begin
        dmmRemesasCompra.RefrescarDatos;
        ActualizarBancoPago;
      end;
    finally
      frm.Free;
    end;
  end;
end;

procedure TfrmMtoRemesasCompra.btnQuitarEfectoClick(Sender: TObject);
begin
  inherited;
  if not RemesaSeleccionada then
    ShowMessage('Selecciona una remesa.')
  else if not dmmRemesasCompra.unqryEfectosRemesa.Active then
    ShowMessage('No hay efectos cargados.')
  else if dmmRemesasCompra.unqryEfectosRemesa.IsEmpty then
    ShowMessage('Selecciona un efecto de la remesa.')
  else if dmmRemesasCompra.RemesaTieneCargo then
    ShowMessage('No se pueden quitar efectos de una remesa con cargo ' +
                'realizado.')
  else if MessageDlg('¿Quitar el efecto seleccionado de la remesa?',
          mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    if dmmRemesasCompra.QuitarEfectoActual then
      ShowMessage('Efecto quitado de la remesa.')
    else
      ShowMessage('No se pudo quitar el efecto.');
    ActualizarBancoPago;
  end;
end;

procedure TfrmMtoRemesasCompra.btnPagarEfectoClick(Sender: TObject);
var
  frm: TfrmModalRegistrarPago;
  q: TDataSet;
  iRes: Integer;
  fPend: Double;
begin
  inherited;
  if not RemesaSeleccionada then
    ShowMessage('Selecciona una remesa.')
  else if not BancoRemesaAsignado then
    ShowMessage('Asigna primero el banco de pago de la remesa.')
  else if not dmmRemesasCompra.unqryEfectosRemesa.Active then
    ShowMessage('No hay efectos cargados.')
  else if dmmRemesasCompra.unqryEfectosRemesa.IsEmpty then
    ShowMessage('Selecciona un efecto de la remesa.')
  else
  begin
    q := dmmRemesasCompra.unqryEfectosRemesa;
    fPend := q.FieldByName('IMPORTE_PENDIENTE_EFEC').AsFloat;
    if fPend <= 0.0001 then
      ShowMessage('El efecto seleccionado no tiene importe pendiente.')
    else
    begin
      frm := TfrmModalRegistrarPago.Create(nil);
      try
        frm.SetDatos(Format('Efecto %d - pendiente %.2f',
          [q.FieldByName('NUMERO_EFEC').AsInteger, fPend]), fPend);
        if frm.ShowModal = mrOk then
        begin
          iRes := dmmRemesasCompra.RegistrarPagoEfectoActual(frm.Fecha,
            frm.Importe, frm.Tipo, frm.Referencia);
          if iRes > 0 then
            ShowMessage('Efecto conciliado.')
          else
            ShowMessage('No se pudo conciliar el efecto.');
          ActualizarBancoPago;
        end;
      finally
        frm.Free;
      end;
    end;
  end;
end;

procedure TfrmMtoRemesasCompra.btnPagarRemesaClick(Sender: TObject);
var
  frm: TfrmModalRegistrarPago;
  iRes: Integer;
  fPend: Double;
begin
  inherited;
  if not RemesaSeleccionada then
    ShowMessage('Selecciona una remesa.')
  else if not BancoRemesaAsignado then
    ShowMessage('Asigna primero el banco de pago de la remesa.')
  else
  begin
    fPend := dmmRemesasCompra.PendienteRemesa;
    if fPend <= 0.0001 then
      ShowMessage('La remesa no tiene importe pendiente.')
    else
    begin
      frm := TfrmModalRegistrarPago.Create(nil);
      try
        frm.SetDatos(Format('Remesa pendiente %.2f', [fPend]), fPend);
        if frm.ShowModal = mrOk then
        begin
          iRes := dmmRemesasCompra.RegistrarPagoRemesa(frm.Fecha,
            frm.Importe, frm.Tipo, frm.Referencia);
          if iRes > 0 then
            ShowMessage(Format('Conciliados %d efecto(s).', [iRes]))
          else
            ShowMessage('No se pudo conciliar la remesa.');
          ActualizarBancoPago;
        end;
      finally
        frm.Free;
      end;
    end;
  end;
end;

procedure TfrmMtoRemesasCompra.btnAsignarBancoClick(Sender: TObject);
var
  sCodigo: string;
begin
  inherited;
  if not RemesaSeleccionada then
    ShowMessage('Selecciona una remesa.')
  else
  begin
    sCodigo := VarToStr(cbbBancoPagoRemesa.EditValue);
    if sCodigo = '' then
      ShowMessage('Selecciona un banco de pago.')
    else if dmmRemesasCompra.AsignarBancoRemesa(sCodigo) then
    begin
      ShowMessage('Banco de pago asignado.');
      ActualizarBancoPago;
    end
    else
      ShowMessage('No se pudo asignar el banco de pago.');
  end;
end;

procedure TfrmMtoRemesasCompra.btnFechaCargoClick(Sender: TObject);
var
  sFecha: string;
  dFecha: TDateTime;
begin
  inherited;
  if not RemesaSeleccionada then
    ShowMessage('Selecciona una remesa.')
  else
  begin
    sFecha := FormatDateTime('dd/mm/yyyy', Date);
    if not dmmRemesasCompra.unqryTablaG.FieldByName('FECHA_CARGO_REMC')
       .IsNull then
      sFecha := FormatDateTime('dd/mm/yyyy',
        dmmRemesasCompra.unqryTablaG.FieldByName('FECHA_CARGO_REMC')
          .AsDateTime);
    if InputQuery('Fecha de cargo', 'Fecha de cargo:', sFecha) then
    begin
      if TryStrToDate(sFecha, dFecha) then
      begin
        if dmmRemesasCompra.ActualizarFechaCargo(dFecha) then
          ShowMessage('Fecha de cargo actualizada.')
        else
          ShowMessage('No se pudo actualizar la fecha de cargo.');
        ActualizarBancoPago;
      end
      else
        ShowMessage('Fecha no válida.');
    end;
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoRemesasCompra);
end.
