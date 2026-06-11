{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalSelAlmacenPedido                                    }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.1.0                                                         }
{   Fecha:       28/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de "Crear albaran desde pedido". Estilo similar al modal de         }
{    materializar sesion de compras (inMtoModalCrearAlbaranSesion):            }
{                                                                              }
{    1. Selector de almacen destino: combo libre con TODOS los almacenes      }
{       activos. El almacen escogido es definitivo — el albaran y los         }
{       movimientos se generan contra el, independientemente del que          }
{       figure en las lineas del pedido.                                       }
{    2. Serie del albaran (combo con las series tipo 'AB' de la empresa).     }
{       La serie acompanya al almacen: al elegir almacen se propone la         }
{       serie que este lleve (CODIGO_ALM_EMPSER); fallback = serie del         }
{       pedido. El usuario puede cambiarla en el combo.                        }
{    3. Ref. proveedor (texto, default = ref del pedido).                      }
{    4. Temporada (lookup, de fza_propiedades_valores filtrado a               }
{       ID_PROP_PV='TEMPORADA').                                               }
{    5. Fecha de recepcion (default = hoy).                                    }
{                                                                              }
{    El usuario elige + completa y pulsa Aceptar. El form de pedidos          }
{    de compra lee los properties y crea el albaran via                       }
{    inLibPedidosCompra.CrearAlbaranDesdePedido.                              }
{******************************************************************************}
unit inMtoModalSelAlmacenPedido;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Menus,
  inMtoFrmBase,
  cxClasses, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  cxLocalization, cxButtons, cxControls, cxContainer, cxEdit,
  cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxNavigator, cxTextEdit, cxLabel, cxCalendar,
  cxMaskEdit, cxDropDownEdit, cxLookupEdit, cxDBLookupEdit,
  cxDBLookupComboBox,
  System.Actions, Vcl.ActnList,
  Data.DB, MemDS, DBAccess, Uni;

type
  TfrmModalSelAlmacenPedido = class(TfrmBase)
    pnlButton:   TPanel;
    btnCancelar: TcxButton;
    btnAceptar:  TcxButton;
    pnlBody:     TPanel;
    lblPedido:   TLabel;
    lblAlmacen:  TcxLabel;
    cbbAlmacen:     TcxLookupComboBox;
    unqryAlmacenes: TUniQuery;
    dsAlmacenes:    TDataSource;
    lblSerieAlb:    TcxLabel;
    cbbSerieAlb:    TcxComboBox;
    lblRefPrv:      TcxLabel;
    txtRefPrv:      TcxTextEdit;
    lblTemporada:   TcxLabel;
    cbbTemporada:   TcxLookupComboBox;
    dsTemporadas:   TDataSource;
    unqryTemporadas: TUniQuery;
    lblFecha:       TcxLabel;
    dteFecha:       TcxDateEdit;
    ActionList1: TActionList;
    actAceptar:  TAction;
    actCancelar: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAceptarClick(Sender: TObject);
    procedure actAceptarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
    procedure cbbAlmacenPropertiesEditValueChanged(Sender: TObject);
  private
    procedure CargarAlmacenes;
    procedure ConfigurarLookupTemporada;
    procedure ProponerSerieAlmacen;
  public
    SeriePedc, NumPedc      : string;
    CodigoEmpresa           : string;  // empresa del pedido (series 'AB')
    SerieAlbDefecto         : string;  // fallback si el almacen no lleva serie
    RefProveedorDefecto     : string;
    IdPvTemporadaDefecto    : Integer;
    CodigoAlmacenDefecto    : string;  // default seleccion combo
    // Devueltos al cerrar con Aceptado=True:
    CodigoAlmacen           : string;
    SerieAlbaran            : string;
    RefProveedor            : string;
    IdPvTemporada           : Integer;
    FechaRecepcion          : TDateTime;
    Aceptado                : Boolean;
  end;

implementation

uses
  inLibGlobalVar, inLibtb;

{$R *.dfm}

procedure TfrmModalSelAlmacenPedido.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  Aceptado             := False;
  CodigoEmpresa        := '';
  CodigoAlmacen        := '';
  CodigoAlmacenDefecto := '';
  SerieAlbaran         := '';
  RefProveedor         := '';
  IdPvTemporada        := 0;
  FechaRecepcion       := Date;
  // Conexion de la query de temporadas (esta unica que la lib usa).
  unqryTemporadas.Connection := inLibGlobalVar.oConn;
end;

procedure TfrmModalSelAlmacenPedido.FormShow(Sender: TObject);
begin
  inherited;
  lblPedido.Caption := Format(
    'Crear albaran desde pedido %s/%s',
    [SeriePedc, NumPedc]);
  CargarAlmacenes;
  ConfigurarLookupTemporada;
  // Defaults. El combo de serie ofrece las series 'AB' de la empresa.
  CargarSeriesEmpresa(CodigoEmpresa, 'AB', cbbSerieAlb.Properties.Items);
  cbbSerieAlb.Text := SerieAlbDefecto;
  txtRefPrv.Text   := RefProveedorDefecto;
  if IdPvTemporadaDefecto > 0 then
    cbbTemporada.EditValue := IdPvTemporadaDefecto
  else
    cbbTemporada.EditValue := Null;
  dteFecha.Date := Date;
  // Default del almacen: lo que pase el llamador (almacen efectivo de
  // una linea del pedido). Si no manda nada, dejamos el combo vacio
  // para forzar al usuario a elegirlo.
  if Trim(CodigoAlmacenDefecto) <> '' then
    cbbAlmacen.EditValue := CodigoAlmacenDefecto
  else
    cbbAlmacen.EditValue := Null;
  // Proponer la serie que lleve el almacen por defecto (idempotente si
  // el evento del combo de almacen ya la propuso al asignar EditValue).
  ProponerSerieAlmacen;
  if cbbAlmacen.CanFocus then
    cbbAlmacen.SetFocus;
end;

procedure TfrmModalSelAlmacenPedido.FormClose(Sender: TObject;
                                              var Action: TCloseAction);
begin
  inherited;
  // No usar caFree: el llamador (btnCrearAlbaranClick) hace
  // FreeAndNil(form) en su finally. Si la cerramos aqui dejamos un
  // puntero colgante que provoca double-free AV al leer Aceptado /
  // CodigoAlmacen / etc tras ShowModal.
  Action := caHide;
end;

procedure TfrmModalSelAlmacenPedido.CargarAlmacenes;
begin
  // Combo libre: el usuario elige cualquier almacen activo, no solo
  // los que tienen pendientes en el pedido. Asi el destinatario final
  // (que en el modal es definitivo) puede ser distinto del que figura
  // en las lineas — util cuando el pedido se generaliza al almacen
  // central y el albaran se hace contra una tienda concreta.
  unqryAlmacenes.Connection := inLibGlobalVar.oConn;
  if not unqryAlmacenes.Active then
    unqryAlmacenes.Open
  else
  begin
    unqryAlmacenes.Close;
    unqryAlmacenes.Open;
  end;
  cbbAlmacen.Properties.ListSource := dsAlmacenes;
end;

procedure TfrmModalSelAlmacenPedido.ProponerSerieAlmacen;
var
  vAlm   : Variant;
  sAlm   : string;
  sSerie : string;
begin
  // La serie acompanya al almacen: si el almacen elegido lleva serie
  // propia (fza_empresas_series.CODIGO_ALM_EMPSER) se propone esa; si
  // no, se mantiene el default historico (SerieAlbDefecto = serie del
  // pedido). El usuario puede cambiarla en el combo.
  vAlm := cbbAlmacen.EditValue;
  if VarIsNull(vAlm) or VarIsEmpty(vAlm) then
    sAlm := ''
  else
    sAlm := Trim(VarToStr(vAlm));
  sSerie := ObtenerSeriePropiaAlmacen(CodigoEmpresa, 'AB', sAlm);
  if sSerie = '' then
    sSerie := SerieAlbDefecto;
  cbbSerieAlb.Text := sSerie;
end;

procedure TfrmModalSelAlmacenPedido.cbbAlmacenPropertiesEditValueChanged(
  Sender: TObject);
begin
  ProponerSerieAlmacen;
end;

procedure TfrmModalSelAlmacenPedido.ConfigurarLookupTemporada;
begin
  // El SQL ya esta en el DFM. Lo abrimos al show.
  if not unqryTemporadas.Active then
    unqryTemporadas.Open;
  cbbTemporada.Properties.ListSource    := dsTemporadas;
  cbbTemporada.Properties.KeyFieldNames := 'ID_PV_ARTPROP';
  cbbTemporada.Properties.ListColumns.Clear;
  with cbbTemporada.Properties.ListColumns.Add do
  begin
    FieldName := 'PV';
    Caption   := 'Temporada';
    Width     := 240;
  end;
end;

procedure TfrmModalSelAlmacenPedido.actAceptarExecute(Sender: TObject);
begin
  inherited;
  btnAceptarClick(Sender);
end;

procedure TfrmModalSelAlmacenPedido.actCancelarExecute(Sender: TObject);
begin
  inherited;
  Aceptado := False;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmModalSelAlmacenPedido.btnAceptarClick(Sender: TObject);
var
  vAlm: Variant;
  vTmp: Variant;
begin
  inherited;
  // Validaciones minimas.
  vAlm := cbbAlmacen.EditValue;
  if VarIsNull(vAlm) or VarIsEmpty(vAlm) or (Trim(VarToStr(vAlm)) = '') then
  begin
    MessageDlg('Selecciona un almacen.', mtInformation, [mbOk], 0);
    if cbbAlmacen.CanFocus then cbbAlmacen.SetFocus;
    Exit;
  end;
  if Trim(cbbSerieAlb.Text) = '' then
  begin
    MessageDlg('Indica la serie del albaran.', mtInformation, [mbOk], 0);
    if cbbSerieAlb.CanFocus then cbbSerieAlb.SetFocus;
    Exit;
  end;
  // Captura resultado.
  CodigoAlmacen := VarToStr(vAlm);
  SerieAlbaran  := Trim(cbbSerieAlb.Text);
  RefProveedor  := Trim(txtRefPrv.Text);
  vTmp := cbbTemporada.EditValue;
  if VarIsNull(vTmp) or VarIsEmpty(vTmp) then
    IdPvTemporada := 0
  else
    IdPvTemporada := StrToIntDef(VarToStr(vTmp), 0);
  FechaRecepcion := dteFecha.Date;
  Aceptado := True;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

end.
