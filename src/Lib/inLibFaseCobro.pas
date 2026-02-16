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
  // Estructura para datos de cliente
  TDatosCliente = record
    CodigoCliente: string;
    NombreCliente: string;
    PermiteDeuda: Boolean;
    LimiteCredito: Currency;
    DeudaActual: Currency;
    procedure Clear;
  end;

  // Estructura para forma de pago
  TFormaPagoInfo = record
    Codigo: string;
    Descripcion: string;
    DevuelveCambio: Boolean;
    RequiereReferencia: Boolean;
    OrdenPrioridad: Integer;
  end;

  // Estructura para item de pago (para grabar en BD)
  TFormaPagoItem = record
    NumeroLinea: Integer;
    CodigoFormaPago: string;
    DescripcionFormaPago: string;
    CodigoDivisa: string;
    RedBlockchain: string;
    FactorCambio: Currency;
    ImporteDivisa: Currency;
    ImporteEntregado: Currency;
    ImporteCambio: Currency;
    Referencia: string;
    Observaciones: string;
  end;

  // Resultado de validación
  TResultadoValidacion = record
    Valido: Boolean;
    Mensaje: string;
    PermitirContinuar: Boolean;
    class function OK: TResultadoValidacion; static;
    class function Error(const AMensaje: string): TResultadoValidacion; static;
    class function Advertencia(const AMensaje: string): TResultadoValidacion; static;
  end;

  // Datos para referencia de pago
  TDatosReferencia = record
    Referencia: string;
    CodigoDivisa: string;
    FactorCambio: Currency;
    ImporteDivisa: Currency;
    RedBlockchain: string;
    HashBlockchain: string;
    procedure Init;
  end;

  // Clase principal para gestión de fase de cobro
  TDatosFaseCobro = class
  private
    // Datos básicos
    FTotalesFactura: TFacturaTotales;
    FDatosCliente: TDatosCliente;
    FMemTablePagos: TVirtualTable;

    // Importes calculados
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

    // Estado
    FHayCliente: Boolean;
    FPermiteDeuda: Boolean;

    // Eventos
    FOnRecalculado: TNotifyEvent;
    FOnRequiereReferencia: TFunc<TFormaPagoInfo, TDatosReferencia, Boolean>;

    procedure CalcularTotales;
    function ValidarDeuda: TResultadoValidacion;
    function ValidarVale: TResultadoValidacion;
    function ObtenerFormaPagoInfo(const ACodigo: string): TFormaPagoInfo;

  public
    constructor Create(AMemTable: TVirtualTable);
    destructor Destroy; override;

    // Inicialización
    procedure CargarDatosFactura(ATotales: TFacturaTotales);
    procedure EstablecerCliente(const ACodigo, ANombre: string;
                                APermiteDeuda: Boolean;
                                ALimiteCredito, ADeudaActual: Currency);
    procedure QuitarCliente;

    // Gestión de formas de pago
    procedure CargarFormasPagoDisponibles(AFormasPago: TArray<TFormaPagoInfo>);
    function ActualizarImportePago(ALineaPago: Integer; AImporte: Currency;
                                   ADatosRef: TDatosReferencia): Boolean;

    // Descuentos
    procedure AplicarDescuentoGlobal(APorcentaje: Currency); overload;
    procedure AplicarDescuentoGlobal(APorcentaje: Currency;
                                     AImporte: Currency); overload;

    // Dejar en cuenta (deuda)
    function PuedeDejarEnCuenta: Boolean;
    function EstablecerDejarEnCuenta(AImporte: Currency): TResultadoValidacion;

    // Vales
    function PuedeEmitirVale: Boolean;
    function EmitirVale(AImporte: Currency): TResultadoValidacion;
    procedure RegistrarValeRecogido(ACodigoVale: string; AImporte: Currency);

    // Validación final
    function ValidarParaCobro: TResultadoValidacion;
    function ObtenerDatosPagosParaGrabar: TArray<TFormaPagoItem>;

    // Recálculo manual
    procedure Recalcular;

    // Propiedades de lectura para UI
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

    // Eventos
    property OnRecalculado: TNotifyEvent read FOnRecalculado write FOnRecalculado;
    property OnRequiereReferencia: TFunc<TFormaPagoInfo, TDatosReferencia, Boolean>
      read FOnRequiereReferencia write FOnRequiereReferencia;
  end;

implementation

uses
  Vcl.Dialogs, System.UITypes;

{ TDatosCliente }

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

  // Inicializar valores
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
  // La tabla pertenece al formulario, no la liberamos aquí
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
  
  // Si había deuda pendiente, limpiarla
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
      FMemTablePagos.FieldByName('NUMERO_LINEA').AsInteger :=
        FMemTablePagos.RecordCount;
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
    
  if not FMemTablePagos.Locate('NUMERO_LINEA', ALineaPago, []) then
    Exit;
    
  // Obtener info de la forma de pago
  CodigoFormaPago := FMemTablePagos.FieldByName('CODIGO_FORMAP').AsString;
  FormaPagoInfo := ObtenerFormaPagoInfo(CodigoFormaPago);
  
  DatosRef := ADatosRef;
  
  // Si requiere referencia y no se proporcionó, solicitar
  if FormaPagoInfo.RequiereReferencia and DatosRef.Referencia.IsEmpty then
  begin
    if Assigned(FOnRequiereReferencia) then
    begin
      if not FOnRequiereReferencia(FormaPagoInfo, DatosRef) then
        Exit; // Usuario canceló
    end
    else
    begin
      // Si no hay handler, permitir continuar sin referencia
      DatosRef.Init;
    end;
  end;
  
  // Actualizar registro
  FMemTablePagos.Edit;
  FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency := AImporte;
  FMemTablePagos.FieldByName('CODIGO_DIVISA').AsString := DatosRef.CodigoDivisa;
  FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsCurrency := DatosRef.FactorCambio;
  FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsCurrency := DatosRef.ImporteDivisa;
  FMemTablePagos.FieldByName('RED_BLOCKCHAIN').AsString := DatosRef.RedBlockchain;
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
  
  BaseImponible := FImporteBruto - FImporteDescuentoLineal;
  FImporteDescuentoGlobal := BaseImponible * (APorcentaje / 100);
  
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
  // Validar que hay cliente
  if not FHayCliente then
  begin
    Result := TResultadoValidacion.Error(
      'No se puede dejar en cuenta sin cliente asignado.');
    Exit;
  end;
  
  // Validar que el cliente permite deuda
  if not FPermiteDeuda then
  begin
    Result := TResultadoValidacion.Error(
      'El cliente no tiene permitido dejar cantidades en cuenta.');
    Exit;
  end;
  
  // Validar límite de crédito
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
               [FDatosCliente.DeudaActual, NuevaDeuda, FDatosCliente.LimiteCredito]));
      Exit;
    end;
  end;
  
  FImporteDejarCuenta := AImporte;
  Recalcular;
  
  Result := TResultadoValidacion.OK;
end;

function TDatosFaseCobro.PuedeEmitirVale: Boolean;
begin
  // Se puede emitir vale cuando hay un importe negativo (devolución)
  Result := FImportePendiente < 0;
end;

function TDatosFaseCobro.EmitirVale(AImporte: Currency): TResultadoValidacion;
begin
  if AImporte >= 0 then
  begin
    Result := TResultadoValidacion.Error(
      'Solo se pueden emitir vales por importes negativos (devoluciones).');
    Exit;
  end;
  
  FImporteValeEmitido := Abs(AImporte);
  Recalcular;
  
  Result := TResultadoValidacion.OK;
end;

procedure TDatosFaseCobro.RegistrarValeRecogido(ACodigoVale: string;
  AImporte: Currency);
begin
  FImporteValeRecogido := FImporteValeRecogido + AImporte;

  // Agregar el vale como forma de pago
  if Assigned(FMemTablePagos) then
  begin
    FMemTablePagos.Append;
//    FMemTablePagos.FieldByName('NUMERO_LINEA').AsInteger :=
//      FMemTablePagos.RecordCount;
    FMemTablePagos.FieldByName('CODIGO_FORMAP').AsString := 'VALE';
    FMemTablePagos.FieldByName('DESCRIPCION_FORMAP').AsString :=
      'Vale ' + ACodigoVale;
//    FMemTablePagos.FieldByName('TIPO_COMPORTAMIENTO').AsString := 'VALE';
    FMemTablePagos.FieldByName('ES_DEVUELVE_CAMBIO_FORMAP').AsString := 'N';
    FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency := AImporte;
    FMemTablePagos.FieldByName('REFERENCIA').AsString := ACodigoVale;
    FMemTablePagos.Post;
  end;

  Recalcular;
end;

procedure TDatosFaseCobro.CalcularTotales;
var
  BaseImponible: Currency;
  TotalEntregado: Currency;
  bookmark: TBookmark;
begin
  // 1. Base imponible después de descuentos de línea
  BaseImponible := FImporteBruto - FImporteDescuentoLineal;
  
  // 2. Aplicar descuento global
  if FPorcentajeDescuentoGlobal <> 0 then
    FImporteDescuentoGlobal := BaseImponible * (FPorcentajeDescuentoGlobal / 100);
  
  // 3. Total a pagar
  FImporteTotalPagar := BaseImponible - FImporteDescuentoGlobal;
  
  // 4. Calcular total entregado
  TotalEntregado := 0;
  
  if Assigned(FMemTablePagos) and FMemTablePagos.Active then
  begin
    FMemTablePagos.DisableControls;
    try
      bookmark := FMemTablePagos.GetBookmark;
      try
        FMemTablePagos.First;
        while not FMemTablePagos.Eof do
        begin
          TotalEntregado := TotalEntregado + 
            FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency;
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
  end;
  
  FImporteEntregado := TotalEntregado + FImporteValeRecogido;
  
  // 5. Calcular pendiente y cambio
  if FImporteEntregado >= FImporteTotalPagar then
  begin
    FImportePendiente := 0;
    FImporteCambio := FImporteEntregado - FImporteTotalPagar;
  end
  else
  begin
    FImportePendiente := FImporteTotalPagar - FImporteEntregado - FImporteDejarCuenta;
    FImporteCambio := 0;
  end;
  
  // Disparar evento de recalculado
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
  // TODO: Implementar validación de vales si es necesario
  Result := TResultadoValidacion.OK;
end;

function TDatosFaseCobro.ValidarParaCobro: TResultadoValidacion;
var
  TotalCobrado: Currency;
begin
  // Recalcular antes de validar
  CalcularTotales;
  
  // Validar deuda
  Result := ValidarDeuda;
  if not Result.Valido then
    Exit;
  
  // Validar vales
  Result := ValidarVale;
  if not Result.Valido then
    Exit;
  
  // Verificar que se ha cobrado algo o hay deuda permitida
  TotalCobrado := FImporteEntregado + FImporteDejarCuenta;
  
  if (TotalCobrado = 0) and (FImporteTotalPagar > 0) then
  begin
    Result := TResultadoValidacion.Error(
      'No se ha indicado ningún pago.');
    Exit;
  end;
  
  // Si hay pendiente sin dejar en cuenta
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
            Item.NumeroLinea := FMemTablePagos.FieldByName('NUMERO_LINEA').AsInteger;
            Item.CodigoFormaPago := FMemTablePagos.FieldByName('CODIGO_FORMAP').AsString;
            Item.DescripcionFormaPago := FMemTablePagos.FieldByName('DESCRIPCION_FORMAP').AsString;
            Item.CodigoDivisa := FMemTablePagos.FieldByName('CODIGO_DIVISA').AsString;
            Item.RedBlockchain := FMemTablePagos.FieldByName('RED_BLOCKCHAIN').AsString;
            Item.FactorCambio := FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsCurrency;
            Item.ImporteDivisa := FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsCurrency;
            Item.ImporteEntregado := FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency;
            Item.Referencia := FMemTablePagos.FieldByName('REFERENCIA').AsString;
            Item.Observaciones := '';
            
            // Calcular cambio específico para esta línea
            Item.ImporteCambio := 0;
            EsDevuelveCambio := FMemTablePagos.FieldByName('ES_DEVUELVE_CAMBIO').AsString = 'S';
            
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
    
    // Si hay deuda, agregar línea de DEUDA
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
  // Intentamos leer de la tabla en memoria si estamos posicionados en ella
  if Assigned(FMemTablePagos) and (FMemTablePagos.Active) and
     (FMemTablePagos.FieldByName('CODIGO_FORMAP').AsString = ACodigo) then
  begin
    Result.Codigo := ACodigo;
    Result.Descripcion :=
                      FMemTablePagos.FieldByName('DESCRIPCION_FORMAP').AsString;

    // Asumiendo que cargaste estos campos en CargarFormasPago
    // Necesitas asegurarte que estos campos existan en tu query original
    if FMemTablePagos.FindField('ES_DEVUELVE_CAMBIO_FORMAP') <> nil then
       Result.DevuelveCambio :=
        (FMemTablePagos.FieldByName('ES_DEVUELVE_CAMBIO_FORMAP').AsString = 'S')
    else
       Result.DevuelveCambio := True;

    // Aquí está la clave para que salte la ventana modal
    if FMemTablePagos.FindField('ES_REQ_REFERENCIA_FORMAP') <> nil then
       Result.RequiereReferencia :=
         (FMemTablePagos.FieldByName('ES_REQ_REFERENCIA_FORMAP').AsString = 'S')
    else
       Result.RequiereReferencia := False;

    // Mapear comportamiento para Crypto/Tarjeta
//    if FMemTablePagos.FindField('TIPO_COMPORTAMIENTO') <> nil then
//       Result.TipoComportamiento := FMemTablePagos.FieldByName('TIPO_COMPORTAMIENTO').AsString;
  end
  else
  begin
    // Fallback por defecto
    Result.Codigo := ACodigo;
    Result.Descripcion := ACodigo;
    Result.DevuelveCambio := True;
    Result.RequiereReferencia := False;
  end;
end;

end.
