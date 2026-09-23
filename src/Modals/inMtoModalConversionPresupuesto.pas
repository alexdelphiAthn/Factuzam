{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalConversionPresupuesto                               }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.1.0                                                         }
{   Fecha:       23/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pasar un presupuesto a documento: tipo (pedido, albarán o factura,        }
{    solo los que el usuario puede crear), almacén, serie, numeración          }
{    (automática o un número concreto), fecha y, en las facturas, si           }
{    genera movimientos de stock. Al cambiar el tipo o el almacén se           }
{    recargan las series y se propone la del almacén.                          }
{******************************************************************************}
unit inMtoModalConversionPresupuesto;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Data.DB,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox, cxCalendar, cxLabel,
  cxCheckBox, cxButtons, dxCore, cxDateUtils, Vcl.Menus,
  inMtoFrmBase, inLibPresupuestosIntf;

type
  TDefectosConversionPresupuesto = record
    // Tipo propuesto; debe estar entre los permitidos.
    Destino: TDestinoPresupuesto;
    Permitidos: TDestinosPresupuesto;
    Empresa: string;
    Almacen: string;
  end;

  TfrmModalConversionPresupuesto = class(TfrmBase)
    lblTipoDocumento: TcxLabel;
    cbbTipoDocumento: TcxComboBox;
    lblAlmacen: TcxLabel;
    cbbAlmacen: TcxLookupComboBox;
    lblSerie: TcxLabel;
    cbbSerie: TcxComboBox;
    lblNumero: TcxLabel;
    chkNumeroAutomatico: TcxCheckBox;
    txtNumero: TcxTextEdit;
    lblFecha: TcxLabel;
    dteFecha: TcxDateEdit;
    chkMueveStock: TcxCheckBox;
    btnCancelar: TcxButton;
    btnAceptar: TcxButton;
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure cbbTipoDocumentoPropertiesEditValueChanged(Sender: TObject);
    procedure cbbAlmacenPropertiesEditValueChanged(Sender: TObject);
    procedure chkNumeroAutomaticoPropertiesEditValueChanged(
      Sender: TObject);
  private
    FAceptado: Boolean;
    FEmpresa: string;
    // Destino de cada elemento del combo de tipo, por indice.
    FDestinos: TArray<TDestinoPresupuesto>;
    function DestinoElegido(out ADestino: TDestinoPresupuesto): Boolean;
    function TipoContadorElegido: string;
    function MueveStockOpcional: Boolean;
    function AlmacenElegido: string;
    function AlmacenObligatorio: Boolean;
    function Validar: Boolean;
    procedure Preparar(ADsAlmacenes: TDataSource;
      const ADefectos: TDefectosConversionPresupuesto);
    procedure CargarTiposDocumento(const ADefectos:
      TDefectosConversionPresupuesto);
    procedure CambiarTipoDocumento;
    procedure ProponerSerieAlmacen;
    procedure ActualizarHabilitados;
    procedure EnfocarControl(AControl: TWinControl);
  public
    class function Solicitar(AOwner: TComponent;
      ADsAlmacenes: TDataSource;
      const ADefectos: TDefectosConversionPresupuesto;
      out ADestino: TDestinoPresupuesto;
      out AOpciones: TOpcionesConversionPresupuesto): Boolean; static;
  end;

implementation

uses
  inLibMensajesVcl, inLibMsgPresupuestos,
  inLibDocumento, inLibDocumentoIntf,
  UniDataValoresAutomaticosRepositorio;

{$R *.dfm}

function NombreDestinoPresupuesto(ADestino: TDestinoPresupuesto): string;
begin
  case ADestino of
    dpPedido:
      Result := SNombrePedidoVenta;
    dpAlbaran:
      Result := SNombreAlbaranVenta;
  else
    Result := SNombreFacturaVenta;
  end;
end;

class function TfrmModalConversionPresupuesto.Solicitar(
  AOwner: TComponent; ADsAlmacenes: TDataSource;
  const ADefectos: TDefectosConversionPresupuesto;
  out ADestino: TDestinoPresupuesto;
  out AOpciones: TOpcionesConversionPresupuesto): Boolean;
var
  frm: TfrmModalConversionPresupuesto;
begin
  ADestino := ADefectos.Destino;
  AOpciones := Default(TOpcionesConversionPresupuesto);
  frm := TfrmModalConversionPresupuesto.Create(AOwner);
  try
    frm.Preparar(ADsAlmacenes, ADefectos);
    frm.ShowModal;
    Result := frm.FAceptado and frm.DestinoElegido(ADestino);
    if Result then
    begin
      AOpciones.Almacen := frm.AlmacenElegido;
      AOpciones.SerieDestino := Trim(frm.cbbSerie.Text);
      if not frm.chkNumeroAutomatico.Checked then
        AOpciones.NumeroDestino := Trim(frm.txtNumero.Text);
      AOpciones.Fecha := Trunc(frm.dteFecha.Date);
      AOpciones.MueveStock := frm.chkMueveStock.Checked or
        (not DestinoPresupuestoMueveStockOpcional(ADestino));
    end;
  finally
    frm.cbbAlmacen.Properties.ListSource := nil;
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalConversionPresupuesto.Preparar(
  ADsAlmacenes: TDataSource;
  const ADefectos: TDefectosConversionPresupuesto);
begin
  // El titulo se pone aqui, despues de la traduccion de la ventana, que
  // pisaria uno asignado en el constructor.
  Caption := SCaptionPasarPresupuestoDocumento;
  lblTipoDocumento.Caption := SCaptionTipoDocumentoConversionPresupuesto;
  FEmpresa := ADefectos.Empresa;
  FAceptado := False;
  cbbAlmacen.Properties.ListSource := ADsAlmacenes;
  cbbAlmacen.EditValue := ADefectos.Almacen;
  chkNumeroAutomatico.Checked := True;
  txtNumero.Text := '';
  dteFecha.Date := Date;
  chkMueveStock.Checked := True;
  CargarTiposDocumento(ADefectos);
  CambiarTipoDocumento;
end;

procedure TfrmModalConversionPresupuesto.CargarTiposDocumento(
  const ADefectos: TDefectosConversionPresupuesto);
var
  eDestino: TDestinoPresupuesto;
  iIndice: Integer;
begin
  cbbTipoDocumento.Properties.Items.Clear;
  FDestinos := nil;
  iIndice := 0;
  for eDestino := Low(TDestinoPresupuesto) to High(TDestinoPresupuesto) do
  begin
    if eDestino in ADefectos.Permitidos then
    begin
      if eDestino = ADefectos.Destino then
        iIndice := Length(FDestinos);
      FDestinos := FDestinos + [eDestino];
      cbbTipoDocumento.Properties.Items.Add(
        NombreDestinoPresupuesto(eDestino));
    end;
  end;
  cbbTipoDocumento.ItemIndex := iIndice;
end;

function TfrmModalConversionPresupuesto.DestinoElegido(
  out ADestino: TDestinoPresupuesto): Boolean;
var
  iIndice: Integer;
begin
  iIndice := cbbTipoDocumento.ItemIndex;
  Result := (iIndice >= 0) and (iIndice < Length(FDestinos));
  if Result then
    ADestino := FDestinos[iIndice];
end;

function TfrmModalConversionPresupuesto.TipoContadorElegido: string;
var
  eDestino: TDestinoPresupuesto;
begin
  Result := '';
  if DestinoElegido(eDestino) then
    Result := CrearConfiguracionDocumento(
      TipoDestinoPresupuesto(eDestino), sdVenta).TipoContador;
end;

function TfrmModalConversionPresupuesto.MueveStockOpcional: Boolean;
var
  eDestino: TDestinoPresupuesto;
begin
  Result := DestinoElegido(eDestino) and
    DestinoPresupuestoMueveStockOpcional(eDestino);
end;

// Cada tipo tiene sus propias series; la casilla de movimientos solo
// tiene sentido en la factura.
procedure TfrmModalConversionPresupuesto.CambiarTipoDocumento;
begin
  CargarSeriesEmpresa(ConexionPrincipal, FEmpresa, TipoContadorElegido,
    cbbSerie.Properties.Items);
  ProponerSerieAlmacen;
  chkMueveStock.Visible := MueveStockOpcional;
  ActualizarHabilitados;
end;

function TfrmModalConversionPresupuesto.AlmacenElegido: string;
begin
  Result := Trim(VarToStr(cbbAlmacen.EditValue));
end;

// Una factura sin movimientos puede no llevar almacen (empresas de solo
// servicios); el resto de destinos lo necesitan.
function TfrmModalConversionPresupuesto.AlmacenObligatorio: Boolean;
begin
  Result := chkMueveStock.Checked or (not MueveStockOpcional);
end;

// La serie acompana al almacen: su serie propia si la tiene; si no, la
// generica de la empresa para el tipo de documento.
procedure TfrmModalConversionPresupuesto.ProponerSerieAlmacen;
var
  sSerie: string;
  sTipo: string;
begin
  sTipo := TipoContadorElegido;
  sSerie := '';
  if sTipo <> '' then
    sSerie := ObtenerSerieDefecto(ConexionPrincipal, FEmpresa, sTipo,
      AlmacenElegido);
  if (sSerie = '') and (cbbSerie.Properties.Items.Count > 0) then
    sSerie := cbbSerie.Properties.Items[0];
  cbbSerie.Text := sSerie;
end;

procedure TfrmModalConversionPresupuesto.ActualizarHabilitados;
begin
  txtNumero.Enabled := not chkNumeroAutomatico.Checked;
end;

procedure TfrmModalConversionPresupuesto.EnfocarControl(
  AControl: TWinControl);
begin
  if AControl.CanFocus then
    AControl.SetFocus;
end;

function TfrmModalConversionPresupuesto.Validar: Boolean;
var
  eDestino: TDestinoPresupuesto;
begin
  Result := False;
  if not DestinoElegido(eDestino) then
  begin
    ShowMessage_fza(SErrorTipoDocumentoConversionPresupuesto);
    EnfocarControl(cbbTipoDocumento);
  end
  else if AlmacenObligatorio and (AlmacenElegido = '') then
  begin
    ShowMessage_fza(SErrorAlmacenConversionPresupuesto);
    EnfocarControl(cbbAlmacen);
  end
  else if Trim(cbbSerie.Text) = '' then
  begin
    ShowMessage_fza(SErrorSerieConversionPresupuesto);
    EnfocarControl(cbbSerie);
  end
  else if (not chkNumeroAutomatico.Checked) and
          (Trim(txtNumero.Text) = '') then
  begin
    ShowMessage_fza(SErrorNumeroConversionPresupuesto);
    EnfocarControl(txtNumero);
  end
  else if dteFecha.Date <= 0 then
  begin
    ShowMessage_fza(SErrorFechaConversionPresupuesto);
    EnfocarControl(dteFecha);
  end
  else
    Result := True;
end;

procedure TfrmModalConversionPresupuesto.btnAceptarClick(Sender: TObject);
begin
  if Validar then
  begin
    FAceptado := True;
    ModalResult := mrOk;
  end;
end;

procedure TfrmModalConversionPresupuesto.btnCancelarClick(Sender: TObject);
begin
  FAceptado := False;
  ModalResult := mrCancel;
end;

procedure TfrmModalConversionPresupuesto.
  cbbTipoDocumentoPropertiesEditValueChanged(Sender: TObject);
begin
  CambiarTipoDocumento;
end;

procedure TfrmModalConversionPresupuesto.cbbAlmacenPropertiesEditValueChanged(
  Sender: TObject);
begin
  ProponerSerieAlmacen;
end;

procedure TfrmModalConversionPresupuesto.
  chkNumeroAutomaticoPropertiesEditValueChanged(Sender: TObject);
begin
  ActualizarHabilitados;
  if not chkNumeroAutomatico.Checked then
    EnfocarControl(txtNumero);
end;

end.
