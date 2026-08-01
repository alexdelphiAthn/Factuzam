{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGastoCaja                                           }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       4.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal F7 del menú de caja: gastos por caja y retiradas de efectivo.       }
{    Tipos: Pago proveedor, Gastos limpieza, Retirada banco, Retirada         }
{    encargado, Caja fuerte. Campo empleado con búsqueda (...).               }
{******************************************************************************}
unit inMtoModalGastoCaja;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ActnList, System.Actions,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxTextEdit, cxButtons, cxCurrencyEdit,
  cxRadioGroup, cxButtonEdit, Uni,
  inMtoFrmBase, dxCoreGraphics, Vcl.Menus, cxMaskEdit, cxGroupBox,
  JvComponentBase, JvEnterTab, cxClasses, cxLocalization;

type
  TfrmModalGastoCaja = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlBotones: TPanel;
    lblTitulo: TcxLabel;
    lblTipoLbl: TcxLabel;
    rgTipo: TcxRadioGroup;
    lblEmpleadoLbl: TcxLabel;
    btnEmpleado: TcxButtonEdit;
    lblEmpleadoNombre: TcxLabel;
    lblImporteLbl: TcxLabel;
    txtImporte: TcxCurrencyEdit;
    lblConceptoLbl: TcxLabel;
    txtConcepto: TcxTextEdit;
    btnAceptar: TcxButton;
    btnCancelar: TcxButton;
    alAcciones: TActionList;
    actAceptar: TAction;
    actCancelar: TAction;
    procedure actAceptarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnEmpleadoPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure btnEmpleadoPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption;
      var Error: Boolean);
  private
    FConn: TUniConnection;
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    FFechaOperacion: TDateTime;
    procedure BuscarEmpleados;
    procedure ValidarEmpleado;
    procedure Grabar;
    function ObtenerTipoTexto: string;
  public
    class function Ejecutar(
      AOwner: TComponent;
      AConn: TUniConnection;
      const AEmpresa, AAlmacen, ACaja: string;
      AFechaOperacion: TDateTime = 0): Boolean;
    class function EjecutarConImporte(
      AOwner: TComponent;
      AConn: TUniConnection;
      const AEmpresa, AAlmacen, ACaja: string;
      AImporte: Currency;
      AFechaOperacion: TDateTime = 0): Boolean;
  end;

implementation

{$R *.dfm}

uses
  UniDataCaja, inLibGenerarTicketCaja,
  UniDataGenerarTicketRepositorio,
  inMtoGenSearch, Data.DB, inLibMsgCaja, inLibMsgComun;

procedure ForceReferenceToClass(C: TClass); begin end;

class function TfrmModalGastoCaja.Ejecutar(
  AOwner: TComponent;
  AConn: TUniConnection;
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaOperacion: TDateTime = 0): Boolean;
var
  frm: TfrmModalGastoCaja;
begin
  Result := False;
  frm := TfrmModalGastoCaja.Create(AOwner);
  try
    frm.FConn    := AConn;
    frm.FEmpresa := AEmpresa;
    frm.FAlmacen := AAlmacen;
    frm.FCaja    := ACaja;
    frm.FFechaOperacion := AFechaOperacion;
    frm.btnEmpleado.Text := frm.IdentidadSesion.Usuario;
    frm.ValidarEmpleado;
    if frm.ShowModal = mrOk then
      Result := True;
  finally
    FreeAndNil(frm);
  end;
end;

class function TfrmModalGastoCaja.EjecutarConImporte(
  AOwner: TComponent;
  AConn: TUniConnection;
  const AEmpresa, AAlmacen, ACaja: string;
  AImporte: Currency;
  AFechaOperacion: TDateTime = 0): Boolean;
var
  frm: TfrmModalGastoCaja;
begin
  Result := False;
  frm := TfrmModalGastoCaja.Create(AOwner);
  try
    frm.FConn    := AConn;
    frm.FEmpresa := AEmpresa;
    frm.FAlmacen := AAlmacen;
    frm.FCaja    := ACaja;
    frm.FFechaOperacion := AFechaOperacion;
    frm.btnEmpleado.Text := frm.IdentidadSesion.Usuario;
    frm.ValidarEmpleado;
    frm.txtImporte.Value := Double(AImporte);
    frm.lblTitulo.Caption := SCaptionRetirarSobranteRecuento;
    if frm.ShowModal = mrOk then
      Result := True;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalGastoCaja.FormCreate(Sender: TObject);
begin
  inherited;
  KeyPreview := True;
  Position := poScreenCenter;
end;

procedure TfrmModalGastoCaja.btnEmpleadoPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  BuscarEmpleados;
end;

procedure TfrmModalGastoCaja.btnEmpleadoPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant;
  var ErrorText: TCaption; var Error: Boolean);
begin
  ValidarEmpleado;
end;

procedure TfrmModalGastoCaja.BuscarEmpleados;
var
  formulario: TfrmMtoSearch;
  unqry: TUniQuery;
begin
  unqry := TUniQuery.Create(nil);
  try
    unqry.Connection := FConn;
    unqry.SQL.Text :=
      'SELECT CODIGO_EMPL AS `Código`,' +
      '       DIMINUTIVO_TICKET_EMPL AS `Nombre`' +
      '  FROM fza_empleados' +
      ' WHERE ESACTIVO_EMPL = ''S''' +
      '   AND CODIGO_EMPL IS NOT NULL' +
      ' ORDER BY CODIGO_EMPL';
    formulario := TfrmMtoSearch.Create(nil);
    try
      formulario.Caption := STituloBusquedaEmpleados;
      formulario.dsTablaG.DataSet := unqry;
      unqry.Open;
      formulario.ProcesarPerfiles;
      formulario.ShowModal;
      if formulario.sFicha = 'S' then
      begin
        btnEmpleado.Text := unqry.Fields[0].AsString;
        ValidarEmpleado;
      end;
    finally
      FreeAndNil(formulario);
    end;
  finally
    FreeAndNil(unqry);
  end;
end;

procedure TfrmModalGastoCaja.ValidarEmpleado;
var
  Q: TUniQuery;
begin
  lblEmpleadoNombre.Caption := '';
  if (FConn = nil) or (Trim(btnEmpleado.Text) = '') then
    Exit;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT DIMINUTIVO_TICKET_EMPL' +
      '  FROM fza_empleados' +
      ' WHERE (CODIGO_EMPL = :pCOD' +
      '    OR DIMINUTIVO_TICKET_EMPL = :pCOD2)';
    Q.ParamByName('pCOD').AsString  := Trim(btnEmpleado.Text);
    Q.ParamByName('pCOD2').AsString := Trim(btnEmpleado.Text);
    Q.Open;
    if not Q.Eof then
      lblEmpleadoNombre.Caption :=
        Q.FieldByName('DIMINUTIVO_TICKET_EMPL').AsString;
  finally
    FreeAndNil(Q);
  end;
end;

function TfrmModalGastoCaja.ObtenerTipoTexto: string;
begin
  case rgTipo.ItemIndex of
    0: Result := 'Pago proveedor';
    1: Result := 'Gastos limpieza';
    2: Result := 'Retirada banco';
    3: Result := 'Retirada encargado';
    4: Result := 'Caja fuerte';
  else
    Result := '';
  end;
end;

procedure TfrmModalGastoCaja.actAceptarExecute(Sender: TObject);
begin
  if Trim(btnEmpleado.Text) = '' then
  begin
    Application.MessageBox(
      PChar(SErrorEmpleadoGastoCajaNoIndicado),
      PChar(STituloAvisoCaja), MB_OK or MB_ICONWARNING);
    btnEmpleado.SetFocus;
    Exit;
  end;
  if txtImporte.Value <= 0 then
  begin
    Application.MessageBox(
      PChar(SErrorImporteGastoCajaNoValido),
      PChar(STituloAvisoCaja), MB_OK or MB_ICONWARNING);
    txtImporte.SetFocus;
    Exit;
  end;
  Grabar;
  ModalResult := mrOk;
end;

procedure TfrmModalGastoCaja.actCancelarExecute(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmModalGastoCaja.Grabar;
var
  dm: TdmCajaOpe;
  sNumOp: string;
  QryTrx: TUniQuery;
  dImporte: Currency;
  sConcepto, sTipo, sEmpleado: string;
begin
  dm := TdmCajaOpe.Create(
    nil, FConn, ParametrosApp, ParametrosCaja, PreviewTicket);
  try
    dm.AsignarContextoSesion(ContextoSesion);
    dImporte  := Currency(txtImporte.Value);
    sEmpleado := Trim(btnEmpleado.Text);
    sTipo     := ObtenerTipoTexto;
    sConcepto := Trim(txtConcepto.Text);
    if sConcepto <> '' then
      sConcepto := sTipo + ': ' + sConcepto
    else
      sConcepto := sTipo;
    sNumOp := dm.SiguienteOpCaja(
      FEmpresa, FAlmacen, FCaja, sEmpleado);
    FConn.StartTransaction;
    try
      QryTrx := TUniQuery.Create(nil);
      try
        QryTrx.Connection := FConn;
        dm.InsertarOperacionCaja(
          QryTrx,
          FEmpresa, FAlmacen, FCaja,
          sNumOp, 'GC', dImporte, sEmpleado,
          FFechaOperacion,
          '', '', '', sConcepto);
        dm.InsertarPagoCaja(
          QryTrx,
          FEmpresa, FAlmacen, FCaja,
          '', sNumOp, 1, 'EFE', dImporte, 0);
      finally
        FreeAndNil(QryTrx);
      end;
      FConn.Commit;
    except
      FConn.Rollback;
      raise;
    end;
    ImprimirTicketOperacionCaja(
      PreviewTicket,
      ConexionPrincipal,
      CrearLecturasImpresionTicket(ConexionPrincipal),
      FEmpresa,
      FAlmacen,
      FCaja,
      sNumOp,
      ParametrosCaja.ImpresoraCaja);
  finally
    FreeAndNil(dm);
  end;
end;

initialization
  ForceReferenceToClass(TfrmModalGastoCaja);
end.
