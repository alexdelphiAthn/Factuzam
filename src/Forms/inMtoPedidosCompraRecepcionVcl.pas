{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoPedidosCompraRecepcionVcl                                }
{    Tipo:       Presentacion (sin formulario)                                 }
{ Version:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Presentacion completa de la recepcion de pedidos de compra: cantidades,  }
{    creacion de albaranes, avisos y estilo de recepciones vencidas.           }
{******************************************************************************}
unit inMtoPedidosCompraRecepcionVcl;

interface

uses
  System.Classes,
  Data.DB,
  cxCurrencyEdit,
  cxGridCustomTableView,
  cxGridDBTableView,
  cxStyles,
  inLibGridPivoteCompra,
  inLibComprasPantallaIntf,
  inLibPedidosCompraIntf;

type
  TAccionRecepcionPedidoCompraVcl = procedure of object;

  TConfigRecepcionPedidoCompraVcl = record
    Cabecera: TDataSet;
    Lineas: TDataSet;
    Albaranes: TDataSet;
    PropietarioPantallas: TComponent;
    Usuario: string;
    Consultas: IConsultasPedidoCompraPantalla;
    Recepcion: IRecepcionPedidoCompra;
    Vista: TcxGridDBTableView;
    ColumnaVertical: TcxGridDBColumn;
    Pivote: TGridPivoteCompra;
    TotalAAlbaranar: TcxCurrencyEdit;
    BestFit: TAccionRecepcionPedidoCompraVcl;
  end;

  IRecepcionPedidoCompraVcl = interface
    ['{0AA9359D-AC2A-45DD-A904-D387BF3DC3B1}']
    procedure ActualizarTotal(AUsarCampoCantidades: Boolean);
    procedure AplicarEstiloLista(
      Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord;
      AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
    procedure RecibirFilaEntera(AUsarCampoCantidades: Boolean);
    procedure RecibirTodo(AUsarCampoCantidades: Boolean);
    procedure LimitarVertical(
      Sender: TObject; AUsarCampoCantidades: Boolean);
    procedure LimitarCampo(
      Sender: TObject; AUsarCampoCantidades: Boolean);
    procedure CrearAlbaran(AUsarCampoCantidades: Boolean);
  end;

function CrearRecepcionPedidoCompraVcl(
  const AConfig: TConfigRecepcionPedidoCompraVcl):
  IRecepcionPedidoCompraVcl;

implementation

uses
  System.SysUtils,
  System.UITypes,
  System.Variants,
  Vcl.Dialogs,
  Vcl.Forms,
  Vcl.Graphics,
  inLibMsgCompras,
  inLibPedidosCompraPresentacionCantidades,
  inLibPedidosCompraPresentacionRecepcion,
  inLibShowMto,
  inMtoModalDocsCreados,
  inMtoModalSelAlmacenPedido;

type
  IControladorRecepcionPedidoCompraVcl = interface
    ['{FF9D62EF-CDAF-4DBE-A19D-28EE7865FEC6}']
    procedure Ejecutar(AUsarCampoCantidades: Boolean);
  end;

  TConfigControladorRecepcionPedidoCompraVcl = record
    Cabecera: TDataSet;
    Lineas: TDataSet;
    Albaranes: TDataSet;
    PropietarioPantallas: TComponent;
    Usuario: string;
    Consultas: IConsultasPedidoCompraPantalla;
    Recepcion: IRecepcionPedidoCompra;
    Cantidades: ISeleccionCantidadesRecepcionPedidoCompra;
  end;

  TVisualizacionRecepcionPedidoCompraVcl = class(
    TInterfacedObject, IVisualizacionRecepcionPedidoCompra)
  private
    FCabecera: TDataSet;
    FLineas: TDataSet;
    FAlbaranes: TDataSet;
    FPropietarioPantallas: TComponent;
    procedure RefrescarDatos;
    procedure MostrarDocumentoCreado(
      const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
      const ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra;
      const AResultado: TResultadoRecepcionPedidoCompra);
  public
    constructor Create(
      const AConfig: TConfigControladorRecepcionPedidoCompraVcl);
    function Solicitar(
      const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
      out ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra):
      Boolean;
    procedure MostrarAviso(const AMensaje: string);
    procedure MostrarError(const AMensaje: string);
    procedure PresentarRecepcion(
      const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
      const ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra;
      const AResultado: TResultadoRecepcionPedidoCompra);
  end;

  TControladorRecepcionPedidoCompraVcl = class(
    TInterfacedObject, IControladorRecepcionPedidoCompraVcl)
  private
    FCabecera: TDataSet;
    FLineas: TDataSet;
    FUsuario: string;
    FConsultas: IConsultasPedidoCompraPantalla;
    FFlujo: TFlujoPresentacionRecepcionPedidoCompra;
    function CrearEntrada(
      AUsarCampoCantidades: Boolean):
      TEntradaPresentacionRecepcionPedidoCompra;
  public
    constructor Create(
      const AConfig: TConfigControladorRecepcionPedidoCompraVcl);
    destructor Destroy; override;
    procedure Ejecutar(AUsarCampoCantidades: Boolean);
  end;

  TRecepcionPedidoCompraVcl = class(
    TInterfacedObject, IRecepcionPedidoCompraVcl)
  private
    FCantidades: ISeleccionCantidadesRecepcionPedidoCompra;
    FControlador: IControladorRecepcionPedidoCompraVcl;
    FPivote: TGridPivoteCompra;
    FTotalAAlbaranar: TcxCurrencyEdit;
    FBestFit: TAccionRecepcionPedidoCompraVcl;
    FEstiloVencida: TcxStyle;
  public
    constructor Create(const AConfig: TConfigRecepcionPedidoCompraVcl);
    destructor Destroy; override;
    procedure ActualizarTotal(AUsarCampoCantidades: Boolean);
    procedure AplicarEstiloLista(
      Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord;
      AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
    procedure RecibirFilaEntera(AUsarCampoCantidades: Boolean);
    procedure RecibirTodo(AUsarCampoCantidades: Boolean);
    procedure LimitarVertical(
      Sender: TObject; AUsarCampoCantidades: Boolean);
    procedure LimitarCampo(
      Sender: TObject; AUsarCampoCantidades: Boolean);
    procedure CrearAlbaran(AUsarCampoCantidades: Boolean);
  end;

function CrearRecepcionPedidoCompraVcl(
  const AConfig: TConfigRecepcionPedidoCompraVcl):
  IRecepcionPedidoCompraVcl;
begin
  Result := TRecepcionPedidoCompraVcl.Create(AConfig);
end;

constructor TVisualizacionRecepcionPedidoCompraVcl.Create(
  const AConfig: TConfigControladorRecepcionPedidoCompraVcl);
begin
  inherited Create;
  FCabecera := AConfig.Cabecera;
  FLineas := AConfig.Lineas;
  FAlbaranes := AConfig.Albaranes;
  FPropietarioPantallas := AConfig.PropietarioPantallas;
end;

function TVisualizacionRecepcionPedidoCompraVcl.Solicitar(
  const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
  out ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra): Boolean;
var
  Formulario: TfrmModalSelAlmacenPedido;
begin
  ASolicitud := Default(TSolicitudPresentacionRecepcionPedidoCompra);
  Formulario := TfrmModalSelAlmacenPedido.Create(Application);
  try
    Formulario.SeriePedc := AEntrada.SeriePedido;
    Formulario.NumPedc := AEntrada.NumeroPedido;
    Formulario.CodigoEmpresa := AEntrada.CodigoEmpresa;
    Formulario.SerieAlbDefecto := AEntrada.SeriePedido;
    Formulario.RefProveedorDefecto := AEntrada.ReferenciaProveedor;
    Formulario.IdPvTemporadaDefecto := AEntrada.IdPvTemporada;
    Formulario.CodigoAlmacenDefecto := AEntrada.AlmacenSugerido;
    Formulario.ShowModal;
    Result := Formulario.Aceptado and
      (Trim(Formulario.CodigoAlmacen) <> '');
    if Result then
    begin
      ASolicitud.CodigoAlmacen := Formulario.CodigoAlmacen;
      ASolicitud.SerieAlbaran := Formulario.SerieAlbaran;
      ASolicitud.SerieAlbaranDestino := Formulario.AlbaranSerieDestino;
      ASolicitud.NumeroAlbaranDestino := Formulario.AlbaranNumDestino;
      ASolicitud.ReferenciaProveedor := Formulario.RefProveedor;
      ASolicitud.FechaRecepcion := Formulario.FechaRecepcion;
      ASolicitud.IdPvTemporada := Formulario.IdPvTemporada;
      ASolicitud.Incorporar := Formulario.Incorporar;
    end;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure TVisualizacionRecepcionPedidoCompraVcl.MostrarAviso(
  const AMensaje: string);
begin
  MessageDlg(AMensaje, mtWarning, [mbOk], 0);
end;

procedure TVisualizacionRecepcionPedidoCompraVcl.MostrarError(
  const AMensaje: string);
begin
  MessageDlg(
    Format(SErrorCrearAlbaranDesdePedidoCompra, [AMensaje]),
    mtError, [mbOk], 0);
end;

procedure TVisualizacionRecepcionPedidoCompraVcl.RefrescarDatos;
begin
  FCabecera.Refresh;
  FLineas.Refresh;
  if FAlbaranes.Active then
    FAlbaranes.Close;
  FAlbaranes.Open;
end;

procedure TVisualizacionRecepcionPedidoCompraVcl.MostrarDocumentoCreado(
  const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
  const ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra;
  const AResultado: TResultadoRecepcionPedidoCompra);
var
  Formulario: TfrmModalDocsCreados;
begin
  Formulario := TfrmModalDocsCreados.Create(Application);
  Formulario.OnClose := nil;
  try
    Formulario.lblTitulo.Caption := Format(
      'Albarán creado desde el pedido %s/%s',
      [AEntrada.SeriePedido, AEntrada.NumeroPedido]);
    Formulario.Agregar(
      'Albarán', AResultado.SerieAlbaran,
      AResultado.NumeroAlbaran, ASolicitud.CodigoAlmacen);
    Formulario.ShowModal;
    if Formulario.Confirmado then
      ShowMto(
        FPropietarioPantallas,
        'AlbaranesCompra',
        AResultado.SerieAlbaran + ',' + AResultado.NumeroAlbaran);
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure TVisualizacionRecepcionPedidoCompraVcl.PresentarRecepcion(
  const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
  const ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra;
  const AResultado: TResultadoRecepcionPedidoCompra);
begin
  RefrescarDatos;
  MostrarDocumentoCreado(AEntrada, ASolicitud, AResultado);
end;

constructor TControladorRecepcionPedidoCompraVcl.Create(
  const AConfig: TConfigControladorRecepcionPedidoCompraVcl);
var
  Visualizacion: IVisualizacionRecepcionPedidoCompra;
begin
  inherited Create;
  FCabecera := AConfig.Cabecera;
  FLineas := AConfig.Lineas;
  FUsuario := AConfig.Usuario;
  FConsultas := AConfig.Consultas;
  Visualizacion := TVisualizacionRecepcionPedidoCompraVcl.Create(AConfig);
  FFlujo := TFlujoPresentacionRecepcionPedidoCompra.Create(
    AConfig.Recepcion,
    AConfig.Cantidades,
    Visualizacion);
end;

destructor TControladorRecepcionPedidoCompraVcl.Destroy;
begin
  FreeAndNil(FFlujo);
  FConsultas := nil;
  inherited;
end;

function TControladorRecepcionPedidoCompraVcl.CrearEntrada(
  AUsarCampoCantidades: Boolean):
  TEntradaPresentacionRecepcionPedidoCompra;
begin
  if FCabecera.State in dsEditModes then
    FCabecera.Post;
  if FLineas.State in dsEditModes then
    FLineas.Post;
  Result := Default(TEntradaPresentacionRecepcionPedidoCompra);
  Result.SeriePedido := FCabecera.FieldByName('SERIE_PEDC').AsString;
  Result.NumeroPedido := FCabecera.FieldByName('NUMERO_PEDC').AsString;
  Result.CodigoEmpresa :=
    FCabecera.FieldByName('CODIGO_EMP_PEDC').AsString;
  Result.ReferenciaProveedor :=
    FCabecera.FieldByName('REF_PROVEEDOR_PEDC').AsString;
  Result.IdPvTemporada :=
    FCabecera.FieldByName('ID_PV_TEMPORADA_PEDC').AsInteger;
  Result.Usuario := FUsuario;
  Result.AlmacenAlternativo :=
    FConsultas.AlmacenEfectivoPrimeraLinea(
      Result.SeriePedido,
      Result.NumeroPedido);
  Result.UsarCampoCantidades := AUsarCampoCantidades;
end;

procedure TControladorRecepcionPedidoCompraVcl.Ejecutar(
  AUsarCampoCantidades: Boolean);
var
  Entrada: TEntradaPresentacionRecepcionPedidoCompra;
begin
  if FCabecera.IsEmpty then
    ShowMessage(SErrorPedidoCompraNoActivoCrearAlbaran)
  else
  begin
    Entrada := CrearEntrada(AUsarCampoCantidades);
    FFlujo.Ejecutar(Entrada);
  end;
end;

constructor TRecepcionPedidoCompraVcl.Create(
  const AConfig: TConfigRecepcionPedidoCompraVcl);
var
  ConfigCantidades: TConfigCantidadesRecepcionPedidoCompra;
  ConfigControlador: TConfigControladorRecepcionPedidoCompraVcl;
begin
  inherited Create;
  FPivote := AConfig.Pivote;
  FTotalAAlbaranar := AConfig.TotalAAlbaranar;
  FBestFit := AConfig.BestFit;
  FEstiloVencida := TcxStyle.Create(nil);
  FEstiloVencida.AssignedValues := [svTextColor];
  FEstiloVencida.TextColor := clRed;
  ConfigCantidades := Default(TConfigCantidadesRecepcionPedidoCompra);
  ConfigCantidades.Cabecera := AConfig.Cabecera;
  ConfigCantidades.Lineas := AConfig.Lineas;
  ConfigCantidades.Vista := AConfig.Vista;
  ConfigCantidades.ColumnaVertical := AConfig.ColumnaVertical;
  ConfigCantidades.Pivote := AConfig.Pivote;
  FCantidades := TCantidadesRecepcionPedidoCompra.Create(ConfigCantidades);
  ConfigControlador :=
    Default(TConfigControladorRecepcionPedidoCompraVcl);
  ConfigControlador.Cabecera := AConfig.Cabecera;
  ConfigControlador.Lineas := AConfig.Lineas;
  ConfigControlador.Albaranes := AConfig.Albaranes;
  ConfigControlador.PropietarioPantallas := AConfig.PropietarioPantallas;
  ConfigControlador.Usuario := AConfig.Usuario;
  ConfigControlador.Consultas := AConfig.Consultas;
  ConfigControlador.Recepcion := AConfig.Recepcion;
  ConfigControlador.Cantidades := FCantidades;
  FControlador := TControladorRecepcionPedidoCompraVcl.Create(
    ConfigControlador);
end;

destructor TRecepcionPedidoCompraVcl.Destroy;
begin
  FControlador := nil;
  FCantidades := nil;
  FreeAndNil(FEstiloVencida);
  inherited;
end;

procedure TRecepcionPedidoCompraVcl.ActualizarTotal(
  AUsarCampoCantidades: Boolean);
begin
  if Assigned(FTotalAAlbaranar) and Assigned(FCantidades) then
    FTotalAAlbaranar.EditValue :=
      FCantidades.Total(AUsarCampoCantidades);
end;

procedure TRecepcionPedidoCompraVcl.AplicarEstiloLista(
  Sender: TcxCustomGridTableView;
  ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem;
  var AStyle: TcxStyle);
var
  ColFecha: TcxGridDBColumn;
  ColPendiente: TcxGridDBColumn;
  ValorFecha: Variant;
  ValorPendiente: Variant;
  Fecha: TDateTime;
  Pendiente: Double;
begin
  if (ARecord <> nil) and (Sender is TcxGridDBTableView) then
  begin
    ColFecha := TcxGridDBTableView(Sender).GetColumnByFieldName(
      'FECHA_TOPE_RECEPCION_PEDC');
    ColPendiente := TcxGridDBTableView(Sender).GetColumnByFieldName(
      'CANTIDAD_PENDIENTE_RECEPCION_PEDC');
    if Assigned(ColFecha) and Assigned(ColPendiente) then
    begin
      ValorFecha := ARecord.Values[ColFecha.Index];
      ValorPendiente := ARecord.Values[ColPendiente.Index];
      if not (VarIsNull(ValorFecha) or VarIsEmpty(ValorFecha) or
              VarIsNull(ValorPendiente) or
              VarIsEmpty(ValorPendiente)) then
      begin
        Fecha := VarToDateTime(ValorFecha);
        if VarIsNumeric(ValorPendiente) then
          Pendiente := ValorPendiente
        else
          Pendiente := StrToFloatDef(VarToStr(ValorPendiente), 0);
        if (Pendiente > 0) and (Trunc(Fecha) < Date) then
          AStyle := FEstiloVencida;
      end;
    end;
  end;
end;

procedure TRecepcionPedidoCompraVcl.RecibirFilaEntera(
  AUsarCampoCantidades: Boolean);
var
  Celdas: Integer;
begin
  if not Assigned(FPivote) or not FPivote.Activo or
     not FPivote.Expandido then
    MessageDlg(SErrorExpandirRecibidosNoActivo,
      mtInformation, [mbOk], 0)
  else
  begin
    Celdas := FPivote.RecibirFilaEntera;
    ActualizarTotal(AUsarCampoCantidades);
    if Celdas = 0 then
      MessageDlg(SInfoTallasPendientesRecibirNoDisponibles,
        mtInformation, [mbOk], 0);
  end;
end;

procedure TRecepcionPedidoCompraVcl.RecibirTodo(
  AUsarCampoCantidades: Boolean);
var
  Rellenadas: Integer;
begin
  if Assigned(FCantidades) then
  begin
    Rellenadas := FCantidades.RellenarTodo(AUsarCampoCantidades);
    if Assigned(FPivote) and FPivote.Activo and Assigned(FBestFit) then
      FBestFit;
    ActualizarTotal(AUsarCampoCantidades);
    if Rellenadas = 0 then
      MessageDlg(SInfoPedidoCompraSinPendientesRecibir,
        mtInformation, [mbOk], 0);
  end;
end;

procedure TRecepcionPedidoCompraVcl.LimitarVertical(
  Sender: TObject; AUsarCampoCantidades: Boolean);
begin
  if Assigned(FCantidades) then
    FCantidades.LimitarVertical(Sender);
  ActualizarTotal(AUsarCampoCantidades);
end;

procedure TRecepcionPedidoCompraVcl.LimitarCampo(
  Sender: TObject; AUsarCampoCantidades: Boolean);
begin
  if Assigned(FCantidades) then
    FCantidades.LimitarCampo(Sender);
  ActualizarTotal(AUsarCampoCantidades);
end;

procedure TRecepcionPedidoCompraVcl.CrearAlbaran(
  AUsarCampoCantidades: Boolean);
begin
  if Assigned(FControlador) then
    FControlador.Ejecutar(AUsarCampoCantidades);
  ActualizarTotal(AUsarCampoCantidades);
end;

end.
