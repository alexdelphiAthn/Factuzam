{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalCrearAlbaranSesion                                  }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       22/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Settings finales antes de materializar una sesion de compra:              }
{      - Serie del albaran (combo de series de la empresa, tipo 'AB';          }
{        por defecto se propone la serie que lleve el almacen elegido).        }
{      - Serie del pedido (combo analogo, tipo 'PC').                          }
{      - Fecha del albaran (default = hoy).                                    }
{      - Almacen destino (lookup, default = cabecera). Al cambiarlo se         }
{        re-propone la serie del nuevo almacen en los combos de serie.         }
{      - Tarifa de venta (lookup, default = cabecera).                         }
{      - Temporada (lookup, default = cabecera).                               }
{      - Flags: generar pedido, generar albaran.                               }
{                                                                              }
{    Devuelve los valores elegidos para que el form llamante invoque a         }
{    inLibComprasSesionesMaterializar.MaterializarSesion con ellos.            }
{    Patron analogo al modal Duplicar/Abonar Factura.                          }
{******************************************************************************}
unit inMtoModalCrearAlbaranSesion;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Data.DB,
  inMtoFrmBase, JvComponentBase, JvEnterTab,
  cxClasses, cxLocalization, cxGraphics, cxLookAndFeels,
  cxLookAndFeelPainters, Vcl.Menus, cxButtons, cxContainer, cxEdit, cxLabel,
  cxTextEdit, cxCheckBox, cxMaskEdit, cxDropDownEdit, cxCalendar,
  cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  cxRadioGroup;

type
  TfrmModalCrearAlbaranSesion = class(TfrmBase)
    pnlBody       : TPanel;
    pnlButton     : TPanel;
    lblTitulo     : TcxLabel;
    chkGenAlbaran : TcxCheckBox;
    lblSerieAlb   : TcxLabel;
    cbbSerieAlb   : TcxComboBox;
    chkGenPedido  : TcxCheckBox;
    lblSeriePed   : TcxLabel;
    cbbSeriePed   : TcxComboBox;
    lblFecha      : TcxLabel;
    dteFecha      : TcxDateEdit;
    lblAlmacen    : TcxLabel;
    cbbAlmacen    : TcxLookupComboBox;
    lblTarifa     : TcxLabel;
    cbbTarifa     : TcxLookupComboBox;
    lblTemporada  : TcxLabel;
    cbbTemporada  : TcxLookupComboBox;
    lblRefPrv     : TcxLabel;
    txtRefPrv     : TcxTextEdit;
    rgAgrupacion  : TcxRadioGroup;
    btnGenerar    : TcxButton;
    btnSalir      : TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnGenerarClick(Sender: TObject);
    procedure btnSalirClick(Sender: TObject);
    procedure chkGenAlbaranPropertiesEditValueChanged(Sender: TObject);
    procedure chkGenPedidoPropertiesEditValueChanged(Sender: TObject);
    procedure cbbAlmacenPropertiesEditValueChanged(Sender: TObject);
  private
    FConfirmed   : Boolean;
    FEmpresa     : string;
    FSerieAlbDef : string;
    FSeriePedDef : string;
    function GetSerieAlb: string;
    function GetSeriePed: string;
    function GetFecha: TDateTime;
    function GetAlmacen: string;
    function GetTarifa: string;
    function GetTemporada: Integer;
    function GetGenPedido: Boolean;
    function GetGenAlbaran: Boolean;
    function GetRefPrv: string;
    function GetUnDocPorAlmacen: Boolean;
    procedure ActualizarHabilitados;
    procedure ProponerSeriesAlmacen;
  public
    /// Conecta los lookups con las queries del DM padre.
    procedure ConfigurarLookups(ADsAlmacenes, ADsTarifas,
                                 ADsTemporadas: TDataSource);
    /// Carga los combos de serie (albaran 'AB' / pedido 'PC') con las
    /// series de la empresa y la guarda para re-proponer la serie del
    /// almacen al cambiarlo. Llamar ANTES de SetDefecto.
    procedure CargarSeries(const AEmpresa: string);
    /// Rellena los valores iniciales (vienen de la cabecera).
    procedure SetDefecto(const ASerieAlb, ASeriePed: string;
                         AFecha: TDateTime;
                         const ACodigoAlm, ACodigoTar: string;
                         AIdPvTemporada: Integer;
                         AGenPedido, AGenAlbaran: Boolean;
                         const ARefPrv: string = '');
    /// Referencia del documento del proveedor (albaran prov / pedido prov).
    property RefPrv     : string  read GetRefPrv;
    /// True si el usuario eligio 'Un documento por almacen' (solo se
    /// muestra el control cuando la sesion esta en formato distribuido).
    property UnDocPorAlmacen: Boolean read GetUnDocPorAlmacen;
    /// Visibilidad del control segun la cabecera de sesion lo necesite.
    procedure MostrarOpcionAgrupacion(AVisible: Boolean);

    /// True si el usuario pulso Generar.
    property Confirmado : Boolean read FConfirmed;
    property SerieAlb   : string  read GetSerieAlb;
    property SeriePed   : string  read GetSeriePed;
    property Fecha      : TDateTime read GetFecha;
    property Almacen    : string  read GetAlmacen;
    property Tarifa     : string  read GetTarifa;
    property Temporada  : Integer read GetTemporada;
    property GenPedido  : Boolean read GetGenPedido;
    property GenAlbaran : Boolean read GetGenAlbaran;
  end;

implementation

uses
  inLibValoresAutomaticos, inLibMsgCompras, inLibMsgVentas;

{$R *.dfm}

procedure TfrmModalCrearAlbaranSesion.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  FConfirmed   := False;
  FEmpresa     := '';
  FSerieAlbDef := '';
  FSeriePedDef := '';
end;

procedure TfrmModalCrearAlbaranSesion.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  inherited;
  Action := caFree;
end;

procedure TfrmModalCrearAlbaranSesion.ConfigurarLookups(
  ADsAlmacenes, ADsTarifas, ADsTemporadas: TDataSource);
begin
  cbbAlmacen.Properties.ListSource   := ADsAlmacenes;
  cbbTarifa.Properties.ListSource    := ADsTarifas;
  cbbTemporada.Properties.ListSource := ADsTemporadas;
end;

procedure TfrmModalCrearAlbaranSesion.CargarSeries(const AEmpresa: string);
begin
  FEmpresa := Trim(AEmpresa);
  CargarSeriesEmpresa(
    ConexionPrincipal,
    FEmpresa,
    'AB',
    cbbSerieAlb.Properties.Items);
  CargarSeriesEmpresa(
    ConexionPrincipal,
    FEmpresa,
    'PC',
    cbbSeriePed.Properties.Items);
end;

procedure TfrmModalCrearAlbaranSesion.ProponerSeriesAlmacen;
var
  sSerie: string;
begin
  // La serie acompanya al almacen: si el almacen elegido lleva serie
  // propia (fza_empresas_series.CODIGO_ALM_EMPSER) se propone esa; si
  // no, el default que paso el llamador (generica de la empresa o
  // serie de la sesion). El usuario siempre puede cambiarla en el combo.
  if FEmpresa <> '' then
  begin
    sSerie := ObtenerSeriePropiaAlmacen(
      ConexionPrincipal,
      FEmpresa,
      'AB',
      GetAlmacen);
    if sSerie = '' then
      sSerie := FSerieAlbDef;
    cbbSerieAlb.Text := sSerie;
    sSerie := ObtenerSeriePropiaAlmacen(
      ConexionPrincipal,
      FEmpresa,
      'PC',
      GetAlmacen);
    if sSerie = '' then
      sSerie := FSeriePedDef;
    cbbSeriePed.Text := sSerie;
  end;
end;

procedure TfrmModalCrearAlbaranSesion.cbbAlmacenPropertiesEditValueChanged(
  Sender: TObject);
begin
  ProponerSeriesAlmacen;
end;

procedure TfrmModalCrearAlbaranSesion.SetDefecto(
  const ASerieAlb, ASeriePed: string;
  AFecha: TDateTime;
  const ACodigoAlm, ACodigoTar: string;
  AIdPvTemporada: Integer;
  AGenPedido, AGenAlbaran: Boolean;
  const ARefPrv: string);
begin
  // Los defaults de serie se guardan como fallback ANTES de tocar el
  // combo de almacen: asignarle EditValue dispara el evento que
  // re-propone series y necesita los fallbacks ya fijados.
  FSerieAlbDef := ASerieAlb;
  FSeriePedDef := ASeriePed;
  cbbSerieAlb.Text := ASerieAlb;
  cbbSeriePed.Text := ASeriePed;
  if AFecha = 0 then dteFecha.Date := Date else dteFecha.Date := AFecha;
  cbbAlmacen.EditValue   := ACodigoAlm;
  cbbTarifa.EditValue    := ACodigoTar;
  if AIdPvTemporada > 0 then cbbTemporada.EditValue := AIdPvTemporada
  else cbbTemporada.EditValue := Null;
  chkGenPedido.Checked  := AGenPedido;
  chkGenAlbaran.Checked := AGenAlbaran;
  txtRefPrv.Text        := ARefPrv;
  // Proponer la serie que lleve el almacen por defecto (idempotente si
  // el evento del combo ya lo hizo al asignar EditValue).
  ProponerSeriesAlmacen;
  ActualizarHabilitados;
end;

function TfrmModalCrearAlbaranSesion.GetRefPrv: string;
begin
  Result := Trim(txtRefPrv.Text);
end;

function TfrmModalCrearAlbaranSesion.GetUnDocPorAlmacen: Boolean;
begin
  // ItemIndex = 0 -> agrupar; 1 -> uno por almacen.
  Result := rgAgrupacion.Visible and (rgAgrupacion.ItemIndex = 1);
end;

procedure TfrmModalCrearAlbaranSesion.MostrarOpcionAgrupacion(
                                                       AVisible: Boolean);
begin
  rgAgrupacion.Visible := AVisible;
  if AVisible and (rgAgrupacion.ItemIndex < 0) then
    rgAgrupacion.ItemIndex := 0;
end;

procedure TfrmModalCrearAlbaranSesion.ActualizarHabilitados;
begin
  // Cada combo de serie se habilita solo si su checkbox esta marcado.
  cbbSerieAlb.Enabled := chkGenAlbaran.Checked;
  cbbSeriePed.Enabled := chkGenPedido.Checked;
end;

// Pedido y albaran son mutuamente exclusivos: nunca tiene sentido
// generar los dos a la vez para la misma sesion (el pedido es
// compromiso, el albaran es entrada real de stock — se eligen uno u
// otro segun el momento de la operacion). Cuando el usuario marca uno,// desmarcamos el otro silenciosamente y refrescamos habilitados.
procedure TfrmModalCrearAlbaranSesion.chkGenAlbaranPropertiesEditValueChanged(
  Sender: TObject);
begin
  if chkGenAlbaran.Checked and chkGenPedido.Checked then
    chkGenPedido.Checked := False;
  ActualizarHabilitados;
end;

procedure TfrmModalCrearAlbaranSesion.chkGenPedidoPropertiesEditValueChanged(
  Sender: TObject);
begin
  if chkGenPedido.Checked and chkGenAlbaran.Checked then
    chkGenAlbaran.Checked := False;
  ActualizarHabilitados;
end;

function TfrmModalCrearAlbaranSesion.GetSerieAlb: string;
begin
  Result := Trim(cbbSerieAlb.Text);
end;

function TfrmModalCrearAlbaranSesion.GetSeriePed: string;
begin
  Result := Trim(cbbSeriePed.Text);
end;

function TfrmModalCrearAlbaranSesion.GetFecha: TDateTime;
begin
  Result := dteFecha.Date;
end;

function TfrmModalCrearAlbaranSesion.GetAlmacen: string;
begin
  if VarIsNull(cbbAlmacen.EditValue) or VarIsEmpty(cbbAlmacen.EditValue) then
    Result := ''
  else
    Result := VarToStr(cbbAlmacen.EditValue);
end;

function TfrmModalCrearAlbaranSesion.GetTarifa: string;
begin
  if VarIsNull(cbbTarifa.EditValue) or VarIsEmpty(cbbTarifa.EditValue) then
    Result := ''
  else
    Result := VarToStr(cbbTarifa.EditValue);
end;

function TfrmModalCrearAlbaranSesion.GetTemporada: Integer;
begin
  if VarIsNull(cbbTemporada.EditValue) or
     VarIsEmpty(cbbTemporada.EditValue) then
    Result := 0
  else
    Result := StrToIntDef(VarToStr(cbbTemporada.EditValue), 0);
end;

function TfrmModalCrearAlbaranSesion.GetGenPedido: Boolean;
begin
  Result := chkGenPedido.Checked;
end;

function TfrmModalCrearAlbaranSesion.GetGenAlbaran: Boolean;
begin
  Result := chkGenAlbaran.Checked;
end;

procedure TfrmModalCrearAlbaranSesion.btnGenerarClick(Sender: TObject);
begin
  inherited;
  if (not GetGenAlbaran) and (not GetGenPedido) then
  begin
    ShowMessage(SErrorTipoDocumentoSesionNoSeleccionado);
    Exit;
  end;
  if GetGenAlbaran and (Trim(cbbSerieAlb.Text) = '') then
  begin
    ShowMessage(SErrorSerieAlbaranSesionNoIndicada);
    if cbbSerieAlb.CanFocus then cbbSerieAlb.SetFocus;
    Exit;
  end;
  if GetGenPedido and (Trim(cbbSeriePed.Text) = '') then
  begin
    ShowMessage(SErrorSeriePedidoSesionNoIndicada);
    if cbbSeriePed.CanFocus then cbbSeriePed.SetFocus;
    Exit;
  end;
  if (GetGenAlbaran or GetGenPedido) and (GetAlmacen = '') then
  begin
    ShowMessage(SErrorAlmacenDestinoSesionNoIndicado);
    if cbbAlmacen.CanFocus then cbbAlmacen.SetFocus;
    Exit;
  end;
  FConfirmed := True;
  ModalResult := mrOk;
end;

procedure TfrmModalCrearAlbaranSesion.btnSalirClick(Sender: TObject);
begin
  inherited;
  FConfirmed := False;
  ModalResult := mrCancel;
end;

end.
