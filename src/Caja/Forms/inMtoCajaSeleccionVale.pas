{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaSeleccionVale                                        }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Busqueda y seleccion de vales pendientes de redencion.                    }
{    Filtra por codigo y devuelve el vale al formulario de cobro.              }
{******************************************************************************}
unit inMtoCajaSeleccionVale;

{
  Formulario modal para buscar y seleccionar un vale pendiente de redención.

  Flujo:
  - Se carga el grid con vales de estado PENDIENTE (y no caducados).
  - El usuario puede filtrar por código/barras escribiendo en el campo de búsqueda.
  - Al seleccionar un vale y pulsar Aceptar (o doble clic / Enter), se devuelve
    el vale al formulario llamante mediante el record TValeSeleccionado.
  - Se admite el paso de un PIN de seguridad (CVV) como validación extra.

  Integración en TfrmMtoCajaFaseCobro:
    if TfrmMtoCajaSeleccionVale.Ejecutar(ValeSeleccionado) then
      FDatosCobro.RegistrarValeRecogido(ValeSeleccionado.CodigoVale,
                                         ValeSeleccionado.PinSeguridad,
                                         ImporteAplicar);
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Data.DB,
  // DevExpress
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxCurrencyEdit,
  cxLabel, cxButtons, cxGroupBox,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator,
  cxDBData, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, UniDataCaja,
  // Acceso a datos
  Uni, MemDS, VirtualTable,
  inMtoFrmBase, Vcl.Menus, cxStyles, dxDateRanges,
  dxScrollbarAnnotations;

type
  // Record con los datos del vale seleccionado que se devuelve al formulario
  // padre
  TValeSeleccionado = record
    CodigoVale:   string;
    PinSeguridad: string;
    Importe:      Currency;
    Descripcion:  string;
  end;

  TfrmMtoCajaSeleccionVale = class(TfrmBase)
    pnlPrincipal:   TPanel;
    pnlSuperior:    TPanel;
    pnlBotones:     TPanel;
    lblBuscar:      TcxLabel;
    edtBuscar:      TcxTextEdit;
    btnBuscar:      TcxButton;
    cxgrdVales:     TcxGrid;
    dbtvVales:      TcxGridDBTableView;
    cxgrdlvlVales:  TcxGridLevel;
    colCodigo:      TcxGridDBColumn;
    colEstado:      TcxGridDBColumn;
    colImporte:     TcxGridDBColumn;
    colFechaEmision:TcxGridDBColumn;
    colCaducidad:   TcxGridDBColumn;
    colObservaciones:TcxGridDBColumn;
    dsVales:        TDataSource;
    btnAceptar:     TcxButton;
    btnCancelar:    TcxButton;
    lblPin: TcxLabel;
    edtPin: TcxTextEdit;
    cxLabel1: TcxLabel; // Etiqueta F2 → Cancelar / ESC
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnBuscarClick(Sender: TObject);
    procedure edtBuscarPropertiesKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure dbtvValesDblClick(Sender: TObject);
    procedure dbtvValesFocusedRecordChanged(Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure btnESCClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FMemVales: TVirtualTable;
    FValeSeleccionado: TValeSeleccionado;
    procedure CargarVales(const AFiltro: string = '');
    procedure ActualizarBotonAceptar;
    function  ValidarPinYSeleccionar: Boolean;
    procedure ConfigurarGrid;
  public
    class function Ejecutar(out AValeSeleccionado: TValeSeleccionado): Boolean;
  end;

implementation

{$R *.dfm}

uses
  inLibMsg;

{ TfrmMtoCajaSeleccionVale }

class function TfrmMtoCajaSeleccionVale.Ejecutar(
  out AValeSeleccionado: TValeSeleccionado): Boolean;
var
  Frm: TfrmMtoCajaSeleccionVale;
begin
  Result := False;
  Frm := TfrmMtoCajaSeleccionVale.Create(Application);
  try
    if Frm.ShowModal = mrOk then
    begin
      AValeSeleccionado := Frm.FValeSeleccionado;
      Result := True;
    end;
  finally
    FreeAndNil(Frm);
  end;
end;

procedure TfrmMtoCajaSeleccionVale.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_F12:
      begin
        Key := 0; // Consumimos la tecla
        // Solo ejecuta la acción si el botón aceptar está activo (hay un vale
        // válido seleccionado)
        if btnAceptar.Enabled then
          btnAceptarClick(Self);
      end;
    VK_ESCAPE:
      begin
        Key := 0; // Consumimos la tecla
        btnCancelarClick(Self);
      end;
  end;
end;

procedure TfrmMtoCajaSeleccionVale.FormCreate(Sender: TObject);
begin
  inherited;
  Self.KeyPreview := True;
  Self.OnKeyDown := FormKeyDown;
  FMemVales := TVirtualTable.Create(Self);
  with FMemVales do
  begin
    FieldDefs.Add('CODIGO_VL',           ftString,   50);
    FieldDefs.Add('PIN_SEGURIDAD_VL',    ftString,   10);
    FieldDefs.Add('ESTADO_VL',           ftString,   15);
    FieldDefs.Add('IMPORTE_NOMINAL_VL',  ftCurrency);
    FieldDefs.Add('FECHA_EMISION_VL',    ftDateTime);
    FieldDefs.Add('FECHA_CADUCIDAD_VL',  ftDate);
    FieldDefs.Add('OBSERVACIONES_VL',    ftString,  200);
    Open;
  end;
  dsVales.DataSet := FMemVales;
  ConfigurarGrid;
end;

procedure TfrmMtoCajaSeleccionVale.FormDestroy(Sender: TObject);
begin
  inherited;
  // FMemVales pertenece a Self como componente, se libera automáticamente
end;

procedure TfrmMtoCajaSeleccionVale.FormShow(Sender: TObject);
var
  bPinObligatorio: Boolean;
begin
  inherited;
  bPinObligatorio :=
    ParametrosCaja.GetBool('vgerRecuperaValePIN', False);
  lblPin.Visible := bPinObligatorio;
  edtPin.Visible := bPinObligatorio;
  CargarVales;
  ActualizarBotonAceptar;
  if edtBuscar.CanFocus then
    edtBuscar.SetFocus;
end;

procedure TfrmMtoCajaSeleccionVale.ConfigurarGrid;
begin
  colCodigo.Caption        := 'Código Vale';
  colEstado.Caption        := 'Estado';
  colImporte.Caption       := 'Importe';
  colFechaEmision.Caption  := 'Fecha emisión';
  colCaducidad.Caption     := 'Caducidad';
  colObservaciones.Caption := 'Observaciones';
  colImporte.PropertiesClassName := 'TcxCurrencyEditProperties';
end;

procedure TfrmMtoCajaSeleccionVale.CargarVales(const AFiltro: string);
var
  qry: TUniQuery;
  SQL: string;
  bUsarCaducidad: Boolean;
  sPin: string;
begin
  bUsarCaducidad :=
    ParametrosCaja.GetBool('vgerCaducidadDefVale', False);
  sPin := Trim(edtPin.Text);
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
    SQL :=
      'SELECT CODIGO_VL, PIN_SEGURIDAD_VL, ESTADO_VL,' +
      '       IMPORTE_NOMINAL_VL, FECHA_EMISION_VL,' +
      '       FECHA_CADUCIDAD_VL, OBSERVACIONES_VL' +
      '  FROM fza_caja_vales' +
      ' WHERE ESTADO_VL = ''PENDIENTE''';
    if bUsarCaducidad then
      SQL := SQL + ' AND (FECHA_CADUCIDAD_VL IS NULL ' +
                   '      OR FECHA_CADUCIDAD_VL >= CURDATE())';
    if AFiltro <> '' then
      SQL := SQL + ' AND CODIGO_VL LIKE :FILTRO';
    // Filtrar también por PIN si se ha introducido
    if sPin <> '' then
      SQL := SQL + ' AND PIN_SEGURIDAD_VL = :PIN';
    SQL := SQL + ' ORDER BY FECHA_EMISION_VL DESC';
    qry.SQL.Text := SQL;
    if AFiltro <> '' then
      qry.ParamByName('FILTRO').AsString := '%' + AFiltro + '%';
    if sPin <> '' then
      qry.ParamByName('PIN').AsString := sPin;
    qry.Open;
    FMemVales.DisableControls;
    FMemVales.Clear;
    try
      while not qry.Eof do
      begin
        FMemVales.Append;
        FMemVales.FieldByName('CODIGO_VL').AsString            :=
          qry.FieldByName('CODIGO_VL').AsString;
        FMemVales.FieldByName('PIN_SEGURIDAD_VL').AsString     :=
          qry.FieldByName('PIN_SEGURIDAD_VL').AsString;
        FMemVales.FieldByName('ESTADO_VL').AsString            :=
          qry.FieldByName('ESTADO_VL').AsString;
        FMemVales.FieldByName('IMPORTE_NOMINAL_VL').AsCurrency :=
          qry.FieldByName('IMPORTE_NOMINAL_VL').AsCurrency;
        FMemVales.FieldByName('FECHA_EMISION_VL').AsDateTime   :=
          qry.FieldByName('FECHA_EMISION_VL').AsDateTime;
        if not qry.FieldByName('FECHA_CADUCIDAD_VL').IsNull then
          FMemVales.FieldByName('FECHA_CADUCIDAD_VL').AsDateTime :=
            qry.FieldByName('FECHA_CADUCIDAD_VL').AsDateTime;
        FMemVales.FieldByName('OBSERVACIONES_VL').AsString     :=
          qry.FieldByName('OBSERVACIONES_VL').AsString;
        FMemVales.Post;
        qry.Next;
      end;
    finally
      FMemVales.EnableControls;
    end;
    FMemVales.First;
  finally
    FreeAndNil(qry);
  end;
  ActualizarBotonAceptar;
  if (sPin <> '') and (FMemVales.RecordCount = 1) then
  begin
    if ValidarPinYSeleccionar then
      ModalResult := mrOk;
  end;
end;

procedure TfrmMtoCajaSeleccionVale.ActualizarBotonAceptar;
begin
  btnAceptar.Enabled := (FMemVales.RecordCount > 0) and
                        (dbtvVales.Controller.FocusedRecord <> nil);
end;

procedure TfrmMtoCajaSeleccionVale.btnBuscarClick(Sender: TObject);
begin
  CargarVales(Trim(edtBuscar.Text));
end;

procedure TfrmMtoCajaSeleccionVale.edtBuscarPropertiesKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    // Si hay texto, filtrar; si está vacío, cargar todos
    CargarVales(Trim(edtBuscar.Text));
  end;
end;

procedure TfrmMtoCajaSeleccionVale.dbtvValesFocusedRecordChanged(
  Sender: TcxCustomGridTableView;
  APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  ActualizarBotonAceptar;
  // Limpiar el PIN cuando se cambia de registro
  edtPin.Text := '';
end;

procedure TfrmMtoCajaSeleccionVale.dbtvValesDblClick(Sender: TObject);
begin
  if btnAceptar.Enabled then
    btnAceptarClick(Sender);
end;

function TfrmMtoCajaSeleccionVale.ValidarPinYSeleccionar: Boolean;
var
  PinIntroducido: string;
  PinReal:        string;
  bPinObligatorio: Boolean;
begin
  Result := False;
  if FMemVales.IsEmpty or (FMemVales.Bof and FMemVales.Eof) then
  begin
    ShowMessage(SErrorValeCajaNoSeleccionado);
    Exit;
  end;
  bPinObligatorio :=
    ParametrosCaja.GetBool('vgerRecuperaValePIN', False);
  PinIntroducido  := Trim(edtPin.Text);
  PinReal         := FMemVales.FieldByName('PIN_SEGURIDAD_VL').AsString;
  if bPinObligatorio and (PinReal <> '') then
  begin
    if PinIntroducido = '' then
    begin
      ShowMessage(SErrorPinValeCajaNoIndicado);
      edtPin.SetFocus;
      Exit;
    end;
    if not SameText(PinIntroducido, PinReal) then
    begin
      ShowMessage(SErrorPinValeCajaIncorrecto);
      edtPin.Text := '';
      edtPin.SetFocus;
      Exit;
    end;
  end;
  // Rellenar el record de salida
  FValeSeleccionado.CodigoVale   := FMemVales.FieldByName('CODIGO_VL').AsString;
  FValeSeleccionado.PinSeguridad := PinReal;
  FValeSeleccionado.Importe      :=
    FMemVales.FieldByName('IMPORTE_NOMINAL_VL').AsCurrency;
  FValeSeleccionado.Descripcion  := FValeSeleccionado.CodigoVale;
  Result := True;
end;

procedure TfrmMtoCajaSeleccionVale.btnAceptarClick(Sender: TObject);
begin
  if ValidarPinYSeleccionar then
    ModalResult := mrOk;
end;

procedure TfrmMtoCajaSeleccionVale.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmMtoCajaSeleccionVale.btnESCClick(Sender: TObject);
begin
  inherited;
  ModalResult := mrCancel;
end;

end.
