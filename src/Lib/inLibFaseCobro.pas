unit inLibFaseCobro;

{
  Biblioteca para gestión de fase de cobro en punto de venta

  Funcionalidades:
  - Cálculo automático de totales, pendientes y cambios
  - Validación de deudas según cliente
  - Emisión de vales por importes negativos
  - Gestión de referencias y divisas en formas de pago
  - Integración con VirtualTable para grid de pagos

  Autor: Sistema Factuzam
  Fecha: 2026-02-15
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Math,
  Data.DB, VirtualTable, inLibFacturas;

type
  TDatosCliente = record
    CodigoCliente: string;
    NombreCliente: string;
    PermiteDeuda: Boolean;
    LimiteCredito: Currency;
    DeudaActual: Currency;
    procedure Clear;
  end;

  TFormaPagoInfo = record
    Codigo: string;
    Descripcion: string;
    DevuelveCambio: Boolean;
    RequiereReferencia: Boolean;
    OrdenPrioridad: Integer;
  end;

  TFormaPagoItem = record
    NumeroLinea: Integer;
    CodigoFormaPago: string;
    DescripcionFormaPago: string;
    CodigoDivisa: string;
    RedBlockchain: string;
    FactorCambio: Currency;
    ImporteDivisa: Double;
    ImporteEntregado: Currency;
    ImporteCambio: Currency;
    Referencia: string;
    Observaciones: string;
  end;

  TResultadoValidacion = record
    Valido: Boolean;
    Mensaje: string;
    PermitirContinuar: Boolean;
    class function OK: TResultadoValidacion; static;
    class function Error(const AMensaje: string): TResultadoValidacion; static;
    class function Advertencia(const AMensaje: string): TResultadoValidacion; static;
  end;

  TDatosReferencia = record
    Referencia: string;
    CodigoDivisa: string;
    EsCripto: boolean;
    EsDivisa: boolean;
    Pendiente:Double;
    FactorCambio: Double;
    ImporteDivisa: Double;
    ImporteEuros:Currency;
    RedBlockchain: string;
    HashBlockchain: string;
    procedure Init;
  end;

  TValeAplicado = record
    CodigoVale: string;
    PinSeguridad: string;
    ImporteAplicado: Currency;
  end;

  TDatosFaseCobro = class
  private
    FTotalesFactura: TFacturaTotales;
    FDatosCliente: TDatosCliente;
    FMemTablePagos: TVirtualTable;
    FValesRecogidos: TList<TValeAplicado>;
    FImporteBruto: Currency;
    FImporteDescuentoLineal: Currency;
    FPorcentajeDescuentoGlobal: Currency;
    FImporteDescuentoGlobal: Currency;
    FImporteTotalPagar: Currency;
    FImporteEntregado: Currency;
    FImportePendiente: Currency;
    FImporteCambio: Currency;
    FImporteDejarCuenta: Currency;
    FImporteValeRecogido: Currency;
    FImporteValeEmitido: Currency;
    FHayCliente: Boolean;
    FPermiteDeuda: Boolean;
    FOnRecalculado: TNotifyEvent;
    FOnRequiereReferencia: TFunc<TFormaPagoInfo, TDatosReferencia, Boolean>;
    procedure CalcularTotales;
    procedure InicializarTotalesPorDefecto;
    function ValidarDeuda: TResultadoValidacion;
    function ValidarVale: TResultadoValidacion;
    function ObtenerFormaPagoInfo(const ACodigo: string): TFormaPagoInfo;
    function ObtenerCurrencySafe(const ANombreCampo: string;
                                 const ADefault: Currency = 0): Currency;
    function ObtenerStringSafe(const ANombreCampo: string;
                               const ADefault: string = ''): string;
    function ObtenerIntegerSafe(const ANombreCampo: string;
                                const ADefault: Integer = 0): Integer;
  public
    constructor Create(AMemTable: TVirtualTable);
    destructor Destroy; override;
    procedure CargarDatosFactura(ATotales: TFacturaTotales);
    procedure EstablecerCliente(const ACodigo, ANombre: string;
                                APermiteDeuda: Boolean;
                                ALimiteCredito, ADeudaActual: Currency);
    procedure QuitarCliente;
    procedure CargarFormasPagoDisponibles(AFormasPago: TArray<TFormaPagoInfo>);
    function ActualizarImportePago(ALineaPago: Integer; AImporte: Currency;
                                   ADatosRef: TDatosReferencia): Boolean;
    procedure AplicarDescuentoGlobal(APorcentaje: Currency); overload;
    procedure AplicarDescuentoGlobal(APorcentaje: Currency;
                                     AImporte: Currency); overload;
    function PuedeDejarEnCuenta: Boolean;
    function EstablecerDejarEnCuenta(AImporte: Currency): TResultadoValidacion;
    function PuedeEmitirVale: Boolean;
    function EmitirVale(AImporte: Currency): TResultadoValidacion;
    procedure RegistrarValeRecogido(ACodigoVale: string; AImporte: Currency);
    function EsDevolucion: Boolean;
    function ValidarParaCobro: TResultadoValidacion;
    function ObtenerDatosPagosParaGrabar: TArray<TFormaPagoItem>;
    procedure Recalcular;
    property ImporteBruto: Currency read FImporteBruto;
    property ImporteDescuentoLineal: Currency read FImporteDescuentoLineal;
    property PorcentajeDescuentoGlobal: Currency read FPorcentajeDescuentoGlobal;
    property ImporteDescuentoGlobal: Currency read FImporteDescuentoGlobal;
    property ImporteTotalPagar: Currency read FImporteTotalPagar;
    property ImporteEntregado: Currency read FImporteEntregado;
    property ImportePendiente: Currency read FImportePendiente;
    property ImporteCambio: Currency read FImporteCambio;
    property ImporteDejarCuenta: Currency read FImporteDejarCuenta;
    property ImporteValeRecogido: Currency read FImporteValeRecogido;
    property ImporteValeEmitido: Currency read FImporteValeEmitido;
    property HayCliente: Boolean read FHayCliente;
    property PermiteDeuda: Boolean read FPermiteDeuda;
    property ImporteDevolucionPendiente: Currency read FImportePendiente;
    property OnRecalculado: TNotifyEvent read FOnRecalculado
                                         write FOnRecalculado;
    property OnRequiereReferencia: TFunc<TFormaPagoInfo,
                                         TDatosReferencia,
                                         Boolean>
                                   read FOnRequiereReferencia
                                   write FOnRequiereReferencia;
  end;

implementation

uses
  Vcl.Dialogs, System.UITypes;

{ TDatosCliente }

//procedure TDatosFaseCobro.RegistrarValeRecogido(const ACodigoVale,
//  APinSeguridad: string; AImporte: Currency);
//var
//  Vale: TValeAplicado;
//begin
//  Vale.CodigoVale := ACodigoVale;
//  Vale.PinSeguridad := APinSeguridad;
//  Vale.ImporteAplicado := AImporte;
//
//  if not Assigned(FValesRecogidos) then
//    FValesRecogidos := TList<TValeAplicado>.Create;
//
//  FValesRecogidos.Add(Vale);
//
//  // Actualizar el importe de vale recogido
//  FImporteValeRecogido := FImporteValeRecogido + AImporte;
//
//  // Recalcular automáticamente
//  Recalcular;
//end;

//procedure TDatosFaseCobro.EliminarValeRecogido(const ACodigoVale: string);
//var
//  BookMark: TBookmark;
//  Encontrado: Boolean;
//begin
//  if not Assigned(FMemTablePagos) then Exit;
//  if not FMemTablePagos.Active then Exit;
//
//  Encontrado := False;
//  FMemTablePagos.DisableControls;
//  try
//    BookMark := FMemTablePagos.GetBookmark;
//    try
//      FMemTablePagos.First;
//      while not FMemTablePagos.Eof do
//      begin
//        // Buscamos el vale por su código en el campo REFERENCIA
//        if (FMemTablePagos.FieldByName('CODIGO_FORMAP').AsString = 'VALE') and
//           (FMemTablePagos.FieldByName('REFERENCIA').AsString = ACodigoVale) then
//        begin
//          FMemTablePagos.Delete;
//          Encontrado := True;
//          Break;
//        end;
//        FMemTablePagos.Next;
//      end;
//    finally
//      if not Encontrado and FMemTablePagos.BookmarkValid(BookMark) then
//        FMemTablePagos.GotoBookmark(BookMark);
//      FMemTablePagos.FreeBookmark(BookMark);
//    end;
//  finally
//    FMemTablePagos.EnableControls;
//  end;
//
//  if Encontrado then
//    Recalcular;
//end;

procedure TDatosCliente.Clear;
begin
  CodigoCliente := '';
  NombreCliente := '';
  PermiteDeuda := False;
  LimiteCredito := 0;
  DeudaActual := 0;
end;

{ TDatosReferencia }

procedure TDatosReferencia.Init;
begin
  Referencia := '';
  CodigoDivisa := 'EUR';
  FactorCambio := 1;
  ImporteDivisa := 0;
  RedBlockchain := '';
  HashBlockchain := '';
  EsCripto := False;
  EsDivisa := False;
end;

{ TResultadoValidacion }

class function TResultadoValidacion.OK: TResultadoValidacion;
begin
  Result.Valido := True;
  Result.Mensaje := '';
  Result.PermitirContinuar := True;
end;

class function TResultadoValidacion.Error(const AMensaje: string): TResultadoValidacion;
begin
  Result.Valido := False;
  Result.Mensaje := AMensaje;
  Result.PermitirContinuar := False;
end;

class function TResultadoValidacion.Advertencia(const AMensaje: string): TResultadoValidacion;
begin
  Result.Valido := False;
  Result.Mensaje := AMensaje;
  Result.PermitirContinuar := True;
end;

{ TDatosFaseCobro }

constructor TDatosFaseCobro.Create(AMemTable: TVirtualTable);
begin
  inherited Create;
  FMemTablePagos := AMemTable;
  FImporteBruto := 0;
  FImporteDescuentoLineal := 0;
  FPorcentajeDescuentoGlobal := 0;
  FImporteDescuentoGlobal := 0;
  FImporteTotalPagar := 0;
  FImporteEntregado := 0;
  FImportePendiente := 0;
  FImporteCambio := 0;
  FImporteDejarCuenta := 0;
  FImporteValeRecogido := 0;
  FImporteValeEmitido := 0;
  FHayCliente := False;
  FPermiteDeuda := False;
  FDatosCliente.Clear;
end;

destructor TDatosFaseCobro.Destroy;
begin
  inherited;
end;

procedure TDatosFaseCobro.CargarDatosFactura(ATotales: TFacturaTotales);
begin
  FTotalesFactura := ATotales;
  if Assigned(ATotales) then
  begin
    FImporteBruto := ATotales.Totales.TotalBruto;
    FImporteDescuentoLineal := ATotales.Totales.TotalDescuentosLineas;
  end
  else
  begin
    FImporteBruto := 0;
    FImporteDescuentoLineal := 0;
  end;
  Recalcular;
end;

procedure TDatosFaseCobro.EstablecerCliente(const ACodigo, ANombre: string;
  APermiteDeuda: Boolean; ALimiteCredito, ADeudaActual: Currency);
begin
  FDatosCliente.CodigoCliente := ACodigo;
  FDatosCliente.NombreCliente := ANombre;
  FDatosCliente.PermiteDeuda := APermiteDeuda;
  FDatosCliente.LimiteCredito := ALimiteCredito;
  FDatosCliente.DeudaActual := ADeudaActual;
  FHayCliente := not ACodigo.IsEmpty;
  FPermiteDeuda := FHayCliente and APermiteDeuda;
  Recalcular;
end;

procedure TDatosFaseCobro.QuitarCliente;
begin
  FDatosCliente.Clear;
  FHayCliente := False;
  FPermiteDeuda := False;
  if FImporteDejarCuenta > 0 then
  begin
    FImporteDejarCuenta := 0;
    Recalcular;
  end;
end;

procedure TDatosFaseCobro.CargarFormasPagoDisponibles(AFormasPago: TArray<TFormaPagoInfo>);
var
  FormaPago: TFormaPagoInfo;
begin
  if not Assigned(FMemTablePagos) then
    Exit;
  FMemTablePagos.DisableControls;
  try
    FMemTablePagos.Close;
    FMemTablePagos.Open;
    FMemTablePagos.Clear;
    for FormaPago in AFormasPago do
    begin
      FMemTablePagos.Append;
//      FMemTablePagos.FieldByName('NUMERO_LINEA').AsInteger :=
//        FMemTablePagos.RecordCount;
      FMemTablePagos.FieldByName('CODIGO_FORMAP').AsString := FormaPago.Codigo;
      FMemTablePagos.FieldByName('DESCRIPCION_FORMAP').AsString :=
                                                          FormaPago.Descripcion;
      FMemTablePagos.FieldByName('ES_DEVUELVE_CAMBIO_FORMAP').AsString :=
        IfThen(FormaPago.DevuelveCambio, 'S', 'N');
      FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency := 0;
      FMemTablePagos.FieldByName('IMPORTE_CAMBIO').AsCurrency := 0;
      FMemTablePagos.FieldByName('CODIGO_DIVISA').AsString := 'EUR';
      FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsCurrency := 1;
      FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsCurrency := 0;
      FMemTablePagos.FieldByName('REFERENCIA').AsString := '';
      FMemTablePagos.Post;
    end;
    FMemTablePagos.First;
  finally
    FMemTablePagos.EnableControls;
  end;
end;

function TDatosFaseCobro.ActualizarImportePago(ALineaPago: Integer;
  AImporte: Currency; ADatosRef: TDatosReferencia): Boolean;
var
  FormaPagoInfo: TFormaPagoInfo;
  CodigoFormaPago: string;
  DatosRef: TDatosReferencia;
begin
  Result := False;
  if not Assigned(FMemTablePagos) then
    Exit;
//  if not FMemTablePagos.Locate('NUMERO_LINEA', ALineaPago, []) then
//    Exit;
  CodigoFormaPago := FMemTablePagos.FieldByName('CODIGO_FORMAP').AsString;
  FormaPagoInfo := ObtenerFormaPagoInfo(CodigoFormaPago);
  DatosRef := ADatosRef;
  if FormaPagoInfo.RequiereReferencia and DatosRef.Referencia.IsEmpty then
  begin
    if Assigned(FOnRequiereReferencia) then
    begin
      if not FOnRequiereReferencia(FormaPagoInfo, DatosRef) then
        Exit;
    end
    else
    begin
      DatosRef.Init;
    end;
  end;
  FMemTablePagos.Edit;
  FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency := AImporte;
  FMemTablePagos.FieldByName('CODIGO_DIVISA').AsString := DatosRef.CodigoDivisa;
  FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsCurrency := DatosRef.FactorCambio;
  FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsCurrency := DatosRef.ImporteDivisa;
//  FMemTablePagos.FieldByName('RED_BLOCKCHAIN').AsString := DatosRef.RedBlockchain;
  FMemTablePagos.FieldByName('REFERENCIA').AsString := DatosRef.Referencia;
  FMemTablePagos.Post;
  Recalcular;
  Result := True;
end;

procedure TDatosFaseCobro.AplicarDescuentoGlobal(APorcentaje: Currency);
var
  BaseImponible: Currency;
begin
  FPorcentajeDescuentoGlobal := APorcentaje;

//  BaseImponible := FImporteBruto - FImporteDescuentoLineal;
//  FImporteDescuentoGlobal := BaseImponible * (APorcentaje / 100);
//
  Recalcular;
end;

procedure TDatosFaseCobro.AplicarDescuentoGlobal(APorcentaje, AImporte: Currency);
begin
  FPorcentajeDescuentoGlobal := APorcentaje;
  FImporteDescuentoGlobal := AImporte;
  Recalcular;
end;

function TDatosFaseCobro.PuedeDejarEnCuenta: Boolean;
begin
  Result := FHayCliente and FPermiteDeuda;
end;

function TDatosFaseCobro.EstablecerDejarEnCuenta(AImporte: Currency): TResultadoValidacion;
var
  NuevaDeuda: Currency;
begin
  if not FHayCliente then
  begin
    Result := TResultadoValidacion.Error(
      'No se puede dejar en cuenta sin cliente asignado.');
    Exit;
  end;
  if not FPermiteDeuda then
  begin
    Result := TResultadoValidacion.Error(
      'El cliente no tiene permitido dejar cantidades en cuenta.');
    Exit;
  end;
  if FDatosCliente.LimiteCredito > 0 then
  begin
    NuevaDeuda := FDatosCliente.DeudaActual + AImporte;
    if NuevaDeuda > FDatosCliente.LimiteCredito then
    begin
      Result := TResultadoValidacion.Error(
        Format('Límite de crédito excedido.' + sLineBreak +
               'Deuda actual: %m' + sLineBreak +
               'Nueva deuda: %m' + sLineBreak +
               'Límite: %m',
               [FDatosCliente.DeudaActual, NuevaDeuda,
                FDatosCliente.LimiteCredito]));
      Exit;
    end;
  end;

  FImporteDejarCuenta := AImporte;
  Recalcular;

  Result := TResultadoValidacion.OK;
end;

function TDatosFaseCobro.EsDevolucion: Boolean;
begin
  Result := FImporteTotalPagar < 0;
end;

function TDatosFaseCobro.PuedeEmitirVale: Boolean;
begin
  Result := EsDevolucion or (FImportePendiente < 0) or
            (FImporteValeEmitido > 0);
end;

function TDatosFaseCobro.EmitirVale(AImporte: Currency): TResultadoValidacion;
begin
  if AImporte <= 0 then
  begin
    Result := TResultadoValidacion.Error('El importe del vale no puede ser' +
                                         ' cero o menor que cero.');
    Exit;
  end;
  FImporteValeEmitido := Abs(AImporte);
  Recalcular;
  Result := TResultadoValidacion.OK;
end;

procedure TDatosFaseCobro.RegistrarValeRecogido(ACodigoVale: string;
  AImporte: Currency);
begin
  if not Assigned(FMemTablePagos) then Exit;
  FMemTablePagos.Append;
//  FMemTablePagos.FieldByName('NUMERO_LINEA').AsInteger :=
//                                                FMemTablePagos.RecordCount *100;
  FMemTablePagos.FieldByName('CODIGO_FORMAP').AsString := 'VALE';
  FMemTablePagos.FieldByName('DESCRIPCION_FORMAP').AsString :=
                                                         'Vale: ' + ACodigoVale;
  FMemTablePagos.FieldByName('ES_DEVUELVE_CAMBIO_FORMAP').AsString := 'N';
  FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency := AImporte;
  FMemTablePagos.FieldByName('CODIGO_DIVISA').AsString := 'EUR';
  FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsCurrency := 1;
  FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsCurrency := 0;
  FMemTablePagos.FieldByName('REFERENCIA').AsString := ACodigoVale;
  FMemTablePagos.FieldByName('IMPORTE_CAMBIO').AsCurrency := 0;
  FMemTablePagos.Post;
  Recalcular;
end;

function TDatosFaseCobro.ObtenerCurrencySafe(const ANombreCampo: string;
  const ADefault: Currency = 0): Currency;
var
  Field: TField;
begin
  Result := ADefault;

  if not Assigned(FMemTablePagos) then Exit;
  if not FMemTablePagos.Active then Exit;

  Field := FMemTablePagos.FindField(ANombreCampo);
  if Assigned(Field) and not Field.IsNull then
    Result := Field.AsCurrency
  else
    Result := ADefault;
end;

function TDatosFaseCobro.ObtenerStringSafe(const ANombreCampo: string;
  const ADefault: string = ''): string;
var
  Field: TField;
begin
  Result := ADefault;

  if not Assigned(FMemTablePagos) then Exit;
  if not FMemTablePagos.Active then Exit;

  Field := FMemTablePagos.FindField(ANombreCampo);
  if Assigned(Field) and not Field.IsNull then
    Result := Field.AsString
  else
    Result := ADefault;
end;

function TDatosFaseCobro.ObtenerIntegerSafe(const ANombreCampo: string;
  const ADefault: Integer = 0): Integer;
var
  Field: TField;
begin
  Result := ADefault;

  if not Assigned(FMemTablePagos) then Exit;
  if not FMemTablePagos.Active then Exit;

  Field := FMemTablePagos.FindField(ANombreCampo);
  if Assigned(Field) and not Field.IsNull then
    Result := Field.AsInteger
  else
    Result := ADefault;
end;

procedure TDatosFaseCobro.CalcularTotales;
var
  BaseImponible: Currency;
  TotalEntregado: Currency;
  TotalValesRecogidos: Currency;
  bookmark: TBookmark;
  HayFormaPagoQueDevuelveCambio: Boolean;
  CambioCalculado: Currency;
  CodigoForma: string;
  ImporteEntregado: Currency;
begin
  // PROTECCIÓN INICIAL MEJORADA
  if not Assigned(FMemTablePagos) then
  begin
    InicializarTotalesPorDefecto;
    Exit;
  end;

  if not FMemTablePagos.Active then
  begin
    InicializarTotalesPorDefecto;
    Exit;
  end;

  if FMemTablePagos.FieldCount = 0 then
  begin
    InicializarTotalesPorDefecto;
    Exit;
  end;

  // Cálculos básicos
  BaseImponible := FImporteBruto - FImporteDescuentoLineal;

  if Abs(FPorcentajeDescuentoGlobal) > 0.001 then
    FImporteDescuentoGlobal := BaseImponible * (FPorcentajeDescuentoGlobal / 100)
  else
    FImporteDescuentoGlobal := 0;

  FImporteTotalPagar := BaseImponible - FImporteDescuentoGlobal;

  TotalEntregado := 0;
  TotalValesRecogidos := 0;
  HayFormaPagoQueDevuelveCambio := False;

  // Si la tabla está vacía, inicializar y salir
  if FMemTablePagos.IsEmpty then
  begin
    FImporteValeRecogido := 0;
    FImporteEntregado := 0;
    FImportePendiente := FImporteTotalPagar;
    FImporteCambio := 0;

    if Assigned(FOnRecalculado) then
      FOnRecalculado(Self);
    Exit;
  end;

  // Recorrer formas de pago de manera segura
  FMemTablePagos.DisableControls;
  try
    bookmark := FMemTablePagos.GetBookmark;
    try
      FMemTablePagos.First;
      while not FMemTablePagos.Eof do
      begin
        CodigoForma := ObtenerStringSafe('CODIGO_FORMAP', '');

        if CodigoForma.IsEmpty then
        begin
          FMemTablePagos.Next;
          Continue;
        end;

        ImporteEntregado := ObtenerCurrencySafe('IMPORTE_ENTREGADO', 0);

        if CodigoForma = 'VALE' then
        begin
          TotalValesRecogidos := TotalValesRecogidos + ImporteEntregado;
        end
        else
        begin
          TotalEntregado := TotalEntregado + ImporteEntregado;

          if (Abs(ImporteEntregado) > 0.001) and
             (ObtenerStringSafe('ES_DEVUELVE_CAMBIO_FORMAP', 'N') = 'S') then
            HayFormaPagoQueDevuelveCambio := True;
        end;

        FMemTablePagos.Next;
      end;
    finally
      if FMemTablePagos.BookmarkValid(bookmark) then
        FMemTablePagos.GotoBookmark(bookmark);
      FMemTablePagos.FreeBookmark(bookmark);
    end;
  finally
    FMemTablePagos.EnableControls;
  end;

  FImporteValeRecogido := TotalValesRecogidos;

  // Lógica de cálculo de totales
  if FImporteTotalPagar < -0.001 then  // Es devolución
  begin
    FImporteEntregado := 0;
    FImporteCambio    := 0;

    var ImporteADevolver: Currency := Abs(FImporteTotalPagar);
    var DevueltoPorFormas: Currency := 0;

    if TotalEntregado < -0.001 then
      DevueltoPorFormas := Abs(TotalEntregado);

    if DevueltoPorFormas >= ImporteADevolver then
    begin
      FImporteValeEmitido := 0;
      FImportePendiente   := 0;
    end
    else
    begin
      var RestanteSinFormas: Currency := ImporteADevolver - DevueltoPorFormas;
      if FImporteValeEmitido >= RestanteSinFormas then
        FImportePendiente := 0
      else
        FImportePendiente := RestanteSinFormas - FImporteValeEmitido;
    end;
  end
  else  // Es cobro normal
  begin
    FImporteEntregado := TotalEntregado + FImporteValeRecogido;

    if FImporteEntregado >= FImporteTotalPagar - 0.001 then  // Tolerancia
    begin
      FImportePendiente := 0;
      CambioCalculado := FImporteEntregado - FImporteTotalPagar;

      // Normalizar valores muy pequeños a 0
      if Abs(CambioCalculado) < 0.01 then
        CambioCalculado := 0;

      if (CambioCalculado > 0.01) and (not HayFormaPagoQueDevuelveCambio) then
      begin
        FImporteCambio      := 0;
        FImporteValeEmitido := CambioCalculado;
      end
      else
      begin
        FImporteCambio := CambioCalculado;
        FImporteValeEmitido := 0;
      end;
    end
    else
    begin
      FImportePendiente := FImporteTotalPagar - FImporteEntregado - FImporteDejarCuenta;

      // Normalizar valores muy pequeños a 0
      if Abs(FImportePendiente) < 0.01 then
        FImportePendiente := 0;

      FImporteCambio := 0;
    end;
  end;

  if Assigned(FOnRecalculado) then
    FOnRecalculado(Self);
end;

procedure TDatosFaseCobro.InicializarTotalesPorDefecto;
begin
  FImporteDescuentoGlobal := 0;
  FImporteTotalPagar := FImporteBruto - FImporteDescuentoLineal;
  FImporteEntregado := 0;
  FImportePendiente := FImporteTotalPagar;
  FImporteCambio := 0;
  FImporteValeRecogido := 0;
  FImporteValeEmitido := 0;

  if Assigned(FOnRecalculado) then
    FOnRecalculado(Self);
end;

procedure TDatosFaseCobro.Recalcular;
begin
  CalcularTotales;
end;

function TDatosFaseCobro.ValidarDeuda: TResultadoValidacion;
begin
  if FImporteDejarCuenta > 0 then
  begin
    if not FHayCliente then
    begin
      Result := TResultadoValidacion.Error(
        'No se puede dejar importe en cuenta sin cliente.');
      Exit;
    end;
    if not FPermiteDeuda then
    begin
      Result := TResultadoValidacion.Error(
        'El cliente no permite dejar cantidades en cuenta.');
      Exit;
    end;
  end;
  Result := TResultadoValidacion.OK;
end;

function TDatosFaseCobro.ValidarVale: TResultadoValidacion;
begin
  Result := TResultadoValidacion.OK;
end;

function TDatosFaseCobro.ValidarParaCobro: TResultadoValidacion;
var
  TotalCobrado: Currency;
begin
  CalcularTotales;
  if EsDevolucion then
  begin
    if FImportePendiente > 0.01 then
      Result := TResultadoValidacion.Error(
        Format('Devolución incompleta. Falta por devolver al cliente: %m',
               [FImportePendiente]))
    else
      Result := TResultadoValidacion.OK;
    Exit;
  end;
  Result := ValidarDeuda;
  if not Result.Valido then
    Exit;
  Result := ValidarVale;
  if not Result.Valido then
    Exit;
  TotalCobrado := FImporteEntregado + FImporteDejarCuenta;
  if (TotalCobrado = 0) and (FImporteTotalPagar > 0) then
  begin
    Result := TResultadoValidacion.Error('No se ha indicado ningún pago.');
    Exit;
  end;
  if (FImportePendiente > 0.01) and (FImporteDejarCuenta = 0) then
  begin
    Result := TResultadoValidacion.Advertencia(
      Format('Cobro incompleto. Pendiente: %m' + sLineBreak +
             '¿Desea dejarlo en cuenta?', [FImportePendiente]));
    Exit;
  end;
  Result := TResultadoValidacion.OK;
end;

function TDatosFaseCobro.ObtenerDatosPagosParaGrabar: TArray<TFormaPagoItem>;
var
  Lista: TList<TFormaPagoItem>;
  Item: TFormaPagoItem;
  RestanteCambio: Currency;
  EsDevuelveCambio: Boolean;
begin
  CalcularTotales;

  RestanteCambio := FImporteCambio;
  Lista := TList<TFormaPagoItem>.Create;
  try
    if Assigned(FMemTablePagos) and FMemTablePagos.Active then
    begin
      FMemTablePagos.DisableControls;
      try
        FMemTablePagos.First;
        while not FMemTablePagos.Eof do
        begin
          // Solo procesar líneas con importe > 0
          if FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency > 0 then
          begin
            Item.CodigoFormaPago := FMemTablePagos.FieldByName('CODIGO_FORMAP').AsString;
            Item.DescripcionFormaPago := FMemTablePagos.FieldByName('DESCRIPCION_FORMAP').AsString;
            Item.CodigoDivisa := FMemTablePagos.FieldByName('CODIGO_DIVISA').AsString;
            Item.FactorCambio := FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsCurrency;
            Item.ImporteDivisa := FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsCurrency;
            Item.ImporteEntregado := FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency;
            Item.Referencia := FMemTablePagos.FieldByName('REFERENCIA').AsString;
            Item.Observaciones := '';
            Item.ImporteCambio := 0;
            EsDevuelveCambio := FMemTablePagos.FieldByName(
                                    'ES_DEVUELVE_CAMBIO_FORMAP').AsString = 'S';
            if (RestanteCambio > 0) and EsDevuelveCambio then
            begin
              Item.ImporteCambio := RestanteCambio;
              RestanteCambio := 0;
            end;
            Lista.Add(Item);
          end;
          FMemTablePagos.Next;
        end;
      finally
        FMemTablePagos.EnableControls;
      end;
    end;
    if FImporteDejarCuenta > 0 then
    begin
      Item.NumeroLinea := Lista.Count + 1;
      Item.CodigoFormaPago := 'DEUDA';
      Item.DescripcionFormaPago := 'Dejar en cuenta';
      Item.CodigoDivisa := 'EUR';
      Item.RedBlockchain := '';
      Item.FactorCambio := 1;
      Item.ImporteDivisa := 0;
      Item.ImporteEntregado := FImporteDejarCuenta;
      Item.ImporteCambio := 0;
      Item.Referencia := FDatosCliente.CodigoCliente;
      Item.Observaciones := 'Pendiente cliente: ' + FDatosCliente.NombreCliente;
      Lista.Add(Item);
    end;
    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

function TDatosFaseCobro.ObtenerFormaPagoInfo(
                                         const ACodigo: string): TFormaPagoInfo;
begin
  if Assigned(FMemTablePagos) and (FMemTablePagos.Active) and
     (FMemTablePagos.FieldByName('CODIGO_FORMAP').AsString = ACodigo) then
  begin
    Result.Codigo := ACodigo;
    Result.Descripcion :=
                      FMemTablePagos.FieldByName('DESCRIPCION_FORMAP').AsString;
    if FMemTablePagos.FindField('ES_DEVUELVE_CAMBIO_FORMAP') <> nil then
       Result.DevuelveCambio :=
        (FMemTablePagos.FieldByName('ES_DEVUELVE_CAMBIO_FORMAP').AsString = 'S')
    else
       Result.DevuelveCambio := True;
    if FMemTablePagos.FindField('ES_REQ_REFERENCIA_FORMAP') <> nil then
       Result.RequiereReferencia :=
         (FMemTablePagos.FieldByName('ES_REQ_REFERENCIA_FORMAP').AsString = 'S')
    else
       Result.RequiereReferencia := False;
  end
  else
  begin
    Result.Codigo := ACodigo;
    Result.Descripcion := ACodigo;
    Result.DevuelveCambio := True;
    Result.RequiereReferencia := False;
  end;
end;

end.
