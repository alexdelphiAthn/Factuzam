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
{      - Serie del albaran (texto libre).                                      }
{      - Fecha del albaran (default = hoy).                                    }
{      - Almacen destino (lookup, default = cabecera).                         }
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
  cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox;

type
  TfrmModalCrearAlbaranSesion = class(TfrmBase)
    pnlBody       : TPanel;
    pnlButton     : TPanel;
    lblTitulo     : TcxLabel;
    chkGenAlbaran : TcxCheckBox;
    lblSerieAlb   : TcxLabel;
    txtSerieAlb   : TcxTextEdit;
    chkGenPedido  : TcxCheckBox;
    lblSeriePed   : TcxLabel;
    txtSeriePed   : TcxTextEdit;
    lblFecha      : TcxLabel;
    dteFecha      : TcxDateEdit;
    lblAlmacen    : TcxLabel;
    cbbAlmacen    : TcxLookupComboBox;
    lblTarifa     : TcxLabel;
    cbbTarifa     : TcxLookupComboBox;
    lblTemporada  : TcxLabel;
    cbbTemporada  : TcxLookupComboBox;
    btnGenerar    : TcxButton;
    btnSalir      : TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnGenerarClick(Sender: TObject);
    procedure btnSalirClick(Sender: TObject);
    procedure chkGenAlbaranPropertiesEditValueChanged(Sender: TObject);
    procedure chkGenPedidoPropertiesEditValueChanged(Sender: TObject);
  private
    FConfirmed: Boolean;
    function GetSerieAlb: string;
    function GetSeriePed: string;
    function GetFecha: TDateTime;
    function GetAlmacen: string;
    function GetTarifa: string;
    function GetTemporada: Integer;
    function GetGenPedido: Boolean;
    function GetGenAlbaran: Boolean;
    procedure ActualizarHabilitados;
  public
    /// Conecta los lookups con las queries del DM padre.
    procedure ConfigurarLookups(ADsAlmacenes, ADsTarifas,
                                 ADsTemporadas: TDataSource);
    /// Rellena los valores iniciales (vienen de la cabecera).
    procedure SetDefecto(const ASerieAlb, ASeriePed: string;
                         AFecha: TDateTime;
                         const ACodigoAlm, ACodigoTar: string;
                         AIdPvTemporada: Integer;
                         AGenPedido, AGenAlbaran: Boolean);

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

{$R *.dfm}

procedure TfrmModalCrearAlbaranSesion.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  FConfirmed := False;
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

procedure TfrmModalCrearAlbaranSesion.SetDefecto(
  const ASerieAlb, ASeriePed: string;
  AFecha: TDateTime;
  const ACodigoAlm, ACodigoTar: string;
  AIdPvTemporada: Integer;
  AGenPedido, AGenAlbaran: Boolean);
begin
  txtSerieAlb.Text := ASerieAlb;
  txtSeriePed.Text := ASeriePed;
  if AFecha = 0 then dteFecha.Date := Date else dteFecha.Date := AFecha;
  cbbAlmacen.EditValue   := ACodigoAlm;
  cbbTarifa.EditValue    := ACodigoTar;
  if AIdPvTemporada > 0 then cbbTemporada.EditValue := AIdPvTemporada
  else cbbTemporada.EditValue := Null;
  chkGenPedido.Checked  := AGenPedido;
  chkGenAlbaran.Checked := AGenAlbaran;
  ActualizarHabilitados;
end;

procedure TfrmModalCrearAlbaranSesion.ActualizarHabilitados;
begin
  // Cada campo de serie se habilita solo si su checkbox esta marcado.
  txtSerieAlb.Enabled := chkGenAlbaran.Checked;
  txtSeriePed.Enabled := chkGenPedido.Checked;
end;

procedure TfrmModalCrearAlbaranSesion.chkGenAlbaranPropertiesEditValueChanged(
  Sender: TObject);
begin
  ActualizarHabilitados;
end;

procedure TfrmModalCrearAlbaranSesion.chkGenPedidoPropertiesEditValueChanged(
  Sender: TObject);
begin
  ActualizarHabilitados;
end;

function TfrmModalCrearAlbaranSesion.GetSerieAlb: string;
begin
  Result := Trim(txtSerieAlb.Text);
end;

function TfrmModalCrearAlbaranSesion.GetSeriePed: string;
begin
  Result := Trim(txtSeriePed.Text);
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
    ShowMessage('Marca al menos uno: Albaran y/o Pedido.');
    Exit;
  end;
  if GetGenAlbaran and (Trim(txtSerieAlb.Text) = '') then
  begin
    ShowMessage('Indica la serie del albaran.');
    if txtSerieAlb.CanFocus then txtSerieAlb.SetFocus;
    Exit;
  end;
  if GetGenPedido and (Trim(txtSeriePed.Text) = '') then
  begin
    ShowMessage('Indica la serie del pedido.');
    if txtSeriePed.CanFocus then txtSeriePed.SetFocus;
    Exit;
  end;
  if (GetGenAlbaran or GetGenPedido) and (GetAlmacen = '') then
  begin
    ShowMessage('Indica un almacen destino.');
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
