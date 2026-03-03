unit UniDataCaja;

interface

uses
  System.SysUtils, System.Classes, Vcl.ExtCtrls, Data.DB, Datasnap.Provider,
  Datasnap.DBClient, Uni, MemDS, DBAccess, system.Math, UniDataGen,
  inLibGlobalVar, system.StrUtils, inLibFaseCobro;

type
  TOnUpdateTotalEvent =
                     procedure(Sender: TObject; NuevoTotal: Currency) of object;
  TdmCajaOpe = class(TDataModule)
    cdsLineas:TClientDataSet;
    cdsCabecera:TClientDataSet;
    DataSetProviderLineas:TDataSetProvider;
    DataSetProviderCabecera:TDataSetProvider;
    dsCabecera:TDataSource;
    dsLineas:TDataSource;
    qryDefinicionArticulo: TUniQuery;
    qryStock: TUniQuery;
    qryVales: TUniQuery;
    procedure DataModuleCreate(Sender: TObject);
    procedure cdsLineasBeforePost(DataSet: TDataSet);
    procedure cdsLineasAfterInsert(DataSet: TDataSet);
    procedure cdsCabeceraAfterInsert(DataSet: TDataSet);
    procedure cdsLineasAfterPost(DataSet: TDataSet);
    procedure cdsLineasAfterDelete(DataSet: TDataSet);
  private
    FOnUpdateTotal: TOnUpdateTotalEvent;
    procedure ConfigurarEstructuraLineas;
    procedure ConfigurarEstructuraCabecera;
    function GetTipoIVA(sTipoIVA: string): Currency;
    function CuadrarFacturaEnMemoria(dsCabecera, dsLineas: TDataSet): Boolean;
    function EmitirNuevoVale(const AEmpresa, AAlmacen, ACaja: string;
                             ANumOperacion: Integer;
                             ASerieFactura, ANumFactura: string;
                             AImporte: Currency): string;
    function ObtenerAlmacenDepositoEmpresa(const AEmpresa: string): string;
    procedure CrearNuevoDepositoCliente(QryTrx: TUniQuery;
                                        const AEmpresa, ACliente,
                                        AArticulo, ASku, AUsuario: string;
                                        APrecioVenta, AAnticipo: Currency;
                                        const AAlmacenOrigen,
                                              AAlmacenDestino: string;
                                        ACantidad: Double;
                                        ATipoIVA: string;
                                        APorcIVA: Currency;
                                        AEsImpIncl: string);
    procedure CerrarDepositoCliente(QryTrx: TUniQuery;
                                    const ASku, AUsuario: string);
    procedure AumentarAnticipoDeposito(QryTrx: TUniQuery;
                                       const ASku, AUsuario: string;
                                       ANuevoAbono: Currency);
    procedure AnularDepositoCliente(QryTrx: TUniQuery;
                                    const ASku, AUsuario,
                                          AAlmacenTienda,
                                          AAlmacenDeposito: string;
                                    out ImporteADevolver: Currency;
                                    ACantidad: Double);
    procedure CargarDepositosCliente(const ACodigoCliente: string);
    procedure TransformarLineasParaCobroParcial(cdsLineas: TDataSet;
                                                DineroEntregado: Currency);
  public
    function GenerarSkuFinal(ArticuloBase: string): string;
    procedure MarcarValeComoCanjeado(const ACodigoVale: string;
                                 ACodigoCaja: string;
                                 ACodigoAlmacen: string;
                                 ANumOperacion: Integer;
                                 ASerie: string;
                                 ANumFactura: String);
    function BuscarYMostrarNombre(TipoEntidad, Codigo: string;
                                  var LabelDestino: String):Boolean;
    function GetTarifaDefault : string;
    function GrabarFacturaSimplificada(const AEmpresa, AAlmacen, ACaja, ASerieElegida: string;
                                     DatosCobro: TDatosFaseCobro;
                                     out SerieGenerada: string;
                                     out NumeroGenerado: String;
                                     out ValeGenerado:String): Boolean;
//    procedure CalcularTotalesLinea(MantenerImporteDto: Boolean = False);
//    procedure CalcularTotalesCabecera;
    property OnUpdateTotal: TOnUpdateTotalEvent read FOnUpdateTotal
                                                write FOnUpdateTotal;
  end;

var
  dmCajaOpe: TdmCajaOpe;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses inLibtb, inMtoCajaOpe, inLibDevExp, inLibFacturas;

{$R *.dfm}

// =============================================================================
// MÓDULO: GESTIÓN DE CUENTAS Y DEPÓSITOS DE CLIENTES
// =============================================================================

procedure TdmCajaOpe.CargarDepositosCliente(const ACodigoCliente: string);
var
  QryDep: TUniQuery;
  Sku, Articulo: string;
  PrecioOriginal, AnticipoDado: Currency;
  CantidadPendiente: Double;
begin
  QryDep := TUniQuery.Create(nil);
  try
    QryDep.Connection := inLibGlobalVar.oConn;
    QryDep.SQL.Text :=
      'SELECT CODIGO_ARTICULO_DEP, ' +
      '       CODIGO_UNIDAD_DEP, ' +
      '       CANTIDAD_PENDIENTE_DEP, ' +
      '       PRECIO_VENTA_DEP, ' +
      '       IMPORTE_ANTICIPO_DEP,'+
      '       TIPO_IVA_DEP, '+
      '       PORCEN_IVA_DEP, '+
      '       ESIMP_INCL_DEP ' +
      '  FROM fza_depositos_cliente ' +
      ' WHERE CODIGO_CLIENTE_DEP = :CLI ' +
      '   AND ESTADO_DEP = ''PENDIENTE''';
    QryDep.ParamByName('CLI').AsString := ACodigoCliente;
    QryDep.Open;
    if QryDep.IsEmpty then
      Exit;
    cdsLineas.DisableControls;
    try
      while not QryDep.Eof do
      begin
        Articulo         := QryDep.FieldByName('CODIGO_ARTICULO_DEP').AsString;
        Sku              := QryDep.FieldByName('CODIGO_UNIDAD_DEP').AsString;
        CantidadPendiente:= QryDep.FieldByName('CANTIDAD_PENDIENTE_DEP').AsFloat;
        PrecioOriginal   := QryDep.FieldByName('PRECIO_VENTA_DEP').AsCurrency;
        AnticipoDado     := QryDep.FieldByName('IMPORTE_ANTICIPO_DEP').AsCurrency;

        // Leer el IVA del artículo para poder descomponer el anticipo
        // (necesitamos saber si el precio incluye IVA y qué tipo es)
        var TipoIVA   := QryDep.FieldByName('TIPO_IVA_DEP').AsString;
        var PorcIVA   := QryDep.FieldByName('PORCEN_IVA_DEP').AsCurrency;
        var EsImpIncl := QryDep.FieldByName('ESIMP_INCL_DEP').AsString;

      // ---------------------------------------------------------
      // LÍNEA 1: LA PRENDA ORIGINAL (A precio completo)
      // ---------------------------------------------------------
      cdsLineas.Append;
      cdsLineas.FieldByName('CODIGO_ARTICULO_FACTURA_LINEA').AsString  := Articulo;
      cdsLineas.FieldByName('CODIGO_UNIDAD_FACTURA_LINEA').AsString    := Sku;
      cdsLineas.FieldByName('CANTIDAD_FACTURA_LINEA').AsFloat          := CantidadPendiente;
      cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString              := 'S';
      cdsLineas.FieldByName('ACCION_DEPOSITO').AsString                := 'COBRAR';
      cdsLineas.FieldByName('TIPOIVA_ARTICULO_FACTURA_LINEA').AsString := TipoIVA;
      cdsLineas.FieldByName('PORCEN_IVA_FACTURA_LINEA').AsCurrency     := PorcIVA;
      cdsLineas.FieldByName('ESIMP_INCL_TARIFA_FACTURA_LINEA').AsString:= EsImpIncl;
      cdsLineas.FieldByName('PRECIOSALIDA_FACTURA_LINEA').AsCurrency   := PrecioOriginal;
      cdsLineas.FieldByName('PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA').AsCurrency := PrecioOriginal;
      if PorcIVA = 0 then
        cdsLineas.FieldByName('PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency := PrecioOriginal
      else
        cdsLineas.FieldByName('PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency :=
                                              PrecioOriginal / (1 + (PorcIVA / 100));
      cdsLineas.FieldByName('PRECIOSALIDA_FACTURA_LINEA').AsCurrency   := PrecioOriginal;
      cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency          :=
                                                   PrecioOriginal * CantidadPendiente;
      cdsLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency      :=
        cdsLineas.FieldByName('PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency
                                                                  * CantidadPendiente;
      cdsLineas.FieldByName('ANTICIPO_PREVIO').AsCurrency := AnticipoDado;
      cdsLineas.Post;

      // ---------------------------------------------------------
      // LÍNEA 2: EL ABONO DEL ANTICIPO (En negativo)
      // ---------------------------------------------------------
      if AnticipoDado > 0 then
      begin
        var AnticipoSinIVA: Currency;
        if PorcIVA = 0 then
          AnticipoSinIVA := AnticipoDado
        else
          AnticipoSinIVA := AnticipoDado / (1 + (PorcIVA / 100));

        cdsLineas.Append;
        cdsLineas.FieldByName('CODIGO_ARTICULO_FACTURA_LINEA').AsString  := 'ANTICIPO';
        cdsLineas.FieldByName('CODIGO_UNIDAD_FACTURA_LINEA').AsString    := 'ANTICIPO';
        cdsLineas.FieldByName('DESCRIPCION_ARTICULO_FACTURA_LINEA').AsString :=
                                                              'Abono anticipo ' + Sku;
        cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString              := 'ABONO_ANTICIPO';
        cdsLineas.FieldByName('CANTIDAD_FACTURA_LINEA').AsFloat          := -1;

        // Tipo IVA heredado de la prenda
        cdsLineas.FieldByName('TIPOIVA_ARTICULO_FACTURA_LINEA').AsString := TipoIVA;
        cdsLineas.FieldByName('PORCEN_IVA_FACTURA_LINEA').AsCurrency     := PorcIVA;
        cdsLineas.FieldByName('ESIMP_INCL_TARIFA_FACTURA_LINEA').AsString:= EsImpIncl;

        // Precio unitario positivo, la cantidad negativa hace el total negativo
        cdsLineas.FieldByName('PRECIOSALIDA_FACTURA_LINEA').AsCurrency   := AnticipoDado;
        cdsLineas.FieldByName('PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA').AsCurrency := AnticipoDado;
        cdsLineas.FieldByName('PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency := AnticipoSinIVA;

        // Totales negativos
        cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency     := -AnticipoDado;
        cdsLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency := -AnticipoSinIVA;

        cdsLineas.Post;
      end;

      QryDep.Next;
    end;
    finally
      cdsLineas.EnableControls;
    end;
  finally
    QryDep.Free;
  end;
end;

procedure TdmCajaOpe.AnularDepositoCliente(QryTrx: TUniQuery; const ASku, AUsuario,
                                           AAlmacenTienda, AAlmacenDeposito: string;
                                           out ImporteADevolver: Currency;
                                           ACantidad: Double);
begin
  ImporteADevolver := 0;

  // 1. Averiguar cuánto dinero tenía entregado a cuenta esta prenda
  QryTrx.SQL.Text :=
    'SELECT IMPORTE_ANTICIPO_DEP FROM fza_depositos_cliente ' +
    ' WHERE CODIGO_UNIDAD_DEP = :SKU AND ESTADO_DEP = ''PENDIENTE''';
  QryTrx.ParamByName('SKU').AsString := ASku;
  QryTrx.Open;

  if not QryTrx.IsEmpty then
    ImporteADevolver := QryTrx.FieldByName('IMPORTE_ANTICIPO_DEP').AsCurrency;
  QryTrx.Close;

  // 2. Marcar el depósito como cancelado
  QryTrx.SQL.Text :=
    'UPDATE fza_depositos_cliente ' +
    '   SET ESTADO_DEP = ''CANCELADO'', ' +
    '       USUARIOMODIF = :USUARIO ' +
    ' WHERE CODIGO_UNIDAD_DEP = :SKU ' +
    '   AND ESTADO_DEP = ''PENDIENTE''';
  QryTrx.ParamByName('USUARIO').AsString := AUsuario;
  QryTrx.ParamByName('SKU').AsString := ASku;
  QryTrx.Execute;

  // 3. Devolver el stock a la tienda (Salida de Depósito, Entrada a Tienda)
  QryTrx.SQL.Text :=
    'INSERT INTO fza_movimientos_almacen (CODIGO_ALMACEN_MOV, CODIGO_UNIDAD_MOV, TIPO_MOVIMIENTO_MOV, CANTIDAD_MOV, FECHA_MOV) ' +
    'VALUES (:ALMDEP, :SKU, ''S'', :CANT, :FECHA)';
  QryTrx.ParamByName('ALMDEP').AsString := AAlmacenDeposito;
  QryTrx.ParamByName('SKU').AsString := ASku;
  QryTrx.ParamByName('CANT').AsFloat := ACantidad;
  QryTrx.ParamByName('FECHA').AsDateTime := Now;
  QryTrx.Execute;

  QryTrx.SQL.Text :=
    'INSERT INTO fza_movimientos_almacen (CODIGO_ALMACEN_MOV, CODIGO_UNIDAD_MOV, TIPO_MOVIMIENTO_MOV, CANTIDAD_MOV, FECHA_MOV) ' +
    'VALUES (:ALMTIENDA, :SKU, ''E'', :CANT, :FECHA)';
  QryTrx.ParamByName('ALMTIENDA').AsString := AAlmacenTienda;
  QryTrx.ParamByName('SKU').AsString := ASku;
  QryTrx.ParamByName('CANT').AsFloat := ACantidad;
  QryTrx.ParamByName('FECHA').AsDateTime := Now;
  QryTrx.Execute;
end;

procedure TdmCajaOpe.CerrarDepositoCliente(QryTrx: TUniQuery; const ASku, AUsuario: string);
begin
  // Cuando una prenda en depósito se paga al 100%, se cierra el préstamo.
  // Nota: El stock no se toca aquí porque ya salió físicamente del depósito en la Venta (VE)
  QryTrx.SQL.Text :=
    'UPDATE fza_depositos_cliente ' +
    '   SET ESTADO_DEP = ''CERRADO'', ' +
    '       USUARIOMODIF = :USUARIO ' +
    ' WHERE CODIGO_UNIDAD_DEP = :SKU ' +
    '   AND ESTADO_DEP = ''PENDIENTE''';
  QryTrx.ParamByName('USUARIO').AsString := AUsuario;
  QryTrx.ParamByName('SKU').AsString := ASku;
  QryTrx.Execute;
end;

procedure TdmCajaOpe.AumentarAnticipoDeposito(QryTrx: TUniQuery; const ASku, AUsuario: string;
                                              ANuevoAbono: Currency);
begin
  // Cuando el cliente da un cobro parcial sobre una prenda que YA estaba en depósito
  if ANuevoAbono <= 0 then Exit;

  QryTrx.SQL.Text :=
    'UPDATE fza_depositos_cliente ' +
    '   SET IMPORTE_ANTICIPO_DEP = IMPORTE_ANTICIPO_DEP + :NUEVO_ABONO, ' +
    '       USUARIOMODIF = :USUARIO ' +
    ' WHERE CODIGO_UNIDAD_DEP = :SKU ' +
    '   AND ESTADO_DEP = ''PENDIENTE''';
  QryTrx.ParamByName('NUEVO_ABONO').AsCurrency := ANuevoAbono;
  QryTrx.ParamByName('USUARIO').AsString := AUsuario;
  QryTrx.ParamByName('SKU').AsString := ASku;
  QryTrx.Execute;
end;

procedure TdmCajaOpe.CrearNuevoDepositoCliente(QryTrx: TUniQuery;
                                               const AEmpresa, ACliente,
                                                     AArticulo,
                                                     ASku,
                                                     AUsuario: string;
                                               APrecioVenta,
                                               AAnticipo: Currency;
                                               const AAlmacenOrigen,
                                                     AAlmacenDestino: string;
                                               ACantidad: Double;
                                               ATipoIVA: string;
                                               APorcIVA: Currency;
                                               AEsImpIncl: string);
var
  NuevoIdDep: string;
begin
  // 1. Traspaso de Stock: Salida de Tienda (AAlmacenOrigen)
  QryTrx.SQL.Text :=
    'INSERT INTO fza_movimientos_almacen (CODIGO_ALMACEN_MOV, CODIGO_UNIDAD_MOV, TIPO_MOVIMIENTO_MOV, CANTIDAD_MOV, FECHA_MOV) ' +
    'VALUES (:ALM, :SKU, ''S'', :CANT, :FECHA)';
  QryTrx.ParamByName('ALM').AsString := AAlmacenOrigen;
  QryTrx.ParamByName('SKU').AsString := ASku;
  QryTrx.ParamByName('CANT').AsFloat := ACantidad;
  QryTrx.ParamByName('FECHA').AsDateTime := Now;
  QryTrx.Execute;

  // 2. Traspaso de Stock: Entrada al Almacén de Depósitos (AAlmacenDestino)
  QryTrx.SQL.Text :=
    'INSERT INTO fza_movimientos_almacen (CODIGO_ALMACEN_MOV, CODIGO_UNIDAD_MOV, TIPO_MOVIMIENTO_MOV, CANTIDAD_MOV, FECHA_MOV) ' +
    'VALUES (:ALMDEP, :SKU, ''E'', :CANT, :FECHA)';
  QryTrx.ParamByName('ALMDEP').AsString := AAlmacenDestino;
  QryTrx.ParamByName('SKU').AsString := ASku;
  QryTrx.ParamByName('CANT').AsFloat := ACantidad;
  QryTrx.ParamByName('FECHA').AsDateTime := Now;
  QryTrx.Execute;
  NuevoIdDep := 'DP' + FormatDateTime('yymmddhhnnsszzz', Now) + RightStr(ASku, 3); // Max 20 chars
  QryTrx.SQL.Text :=
    'INSERT INTO fza_depositos_cliente (' +
    '                                     ID_DEPOSITO_DEP, ' +
    '                                     CODIGO_EMPRESA_DEP, ' +
    '                                     CODIGO_CLIENTE_DEP, ' +
    '                                     CODIGO_ARTICULO_DEP, ' +
    '                                     CODIGO_UNIDAD_DEP, ' +
    '                                     PRECIO_VENTA_DEP, ' +
    '                                     IMPORTE_ANTICIPO_DEP, ' +
    '                                     ESTADO_DEP, ' +
    '                                     TIPO_IVA_DEP, '+
    '                                     PORCEN_IVA_DEP, '+
    '                                     ESIMP_INCL_DEP, ' +
    '                                     INSTANTEALTA, '+
    '                                     USUARIOALTA, USUARIOMODIF) ' +
    'VALUES (' +
    '  :ID_DEP, :EMP, :CLI, :ART, :SKU, :PRECIO, ' +
    '  :ABONO, ''PENDIENTE'', :TIPOIVA, :PORCIVA, :IMPINCL, ' +
    '  NOW(), :USUARIO, :USUARIO)';
  QryTrx.ParamByName('ID_DEP').AsString := Copy(NuevoIdDep, 1, 20);
  QryTrx.ParamByName('EMP').AsString := AEmpresa;
  QryTrx.ParamByName('CLI').AsString := ACliente;
  QryTrx.ParamByName('ART').AsString := AArticulo;
  QryTrx.ParamByName('SKU').AsString := ASku;
  QryTrx.ParamByName('PRECIO').AsCurrency := APrecioVenta;
  QryTrx.ParamByName('ABONO').AsCurrency := AAnticipo;
  QryTrx.ParamByName('USUARIO').AsString := AUsuario;
  QryTrx.ParamByName('TIPOIVA').AsString  := ATipoIVA;
  QryTrx.ParamByName('PORCIVA').AsCurrency:= APorcIVA;
  QryTrx.ParamByName('IMPINCL').AsString  := AEsImpIncl;
  QryTrx.Execute;
end;

procedure TdmCajaOpe.TransformarLineasParaCobroParcial(cdsLineas: TDataSet; DineroEntregado: Currency);
var
  TotalLinea, DineroDisponible: Currency;
  PorcIva: Double;
  VieneDeDep, AccionDep: string;

  procedure ProcesarLinea;
  begin
    TotalLinea := cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency;
    // Guardar el valor real de la prenda antes de que la toquemos
    if cdsLineas.FindField('PRECIO_ORIGINAL_DEP') <> nil then
      cdsLineas.FieldByName('PRECIO_ORIGINAL_DEP').AsCurrency := TotalLinea;
    if DineroDisponible >= TotalLinea then
    begin
      // Pagado entero
      DineroDisponible := DineroDisponible - TotalLinea;
    end
    else
    begin
      // Cobro parcial -> Transformar en anticipo
      cdsLineas.Edit;
      if cdsLineas.FindField('VIENE_DE_DEPOSITO') <> nil then
      begin
        if cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString = 'S' then
          cdsLineas.FieldByName('ACCION_DEPOSITO').AsString := 'AUMENTAR_DEP'
        else
          cdsLineas.FieldByName('ACCION_DEPOSITO').AsString := 'NUEVO_DEP';
      end;
      cdsLineas.FieldByName('DESCRIPCION_ARTICULO_FACTURA_LINEA').AsString :=
                                                                   'Anticipo ' +
           cdsLineas.FieldByName('DESCRIPCION_ARTICULO_FACTURA_LINEA').AsString;
      PorcIva := cdsLineas.FieldByName('PORCEN_IVA_FACTURA_LINEA').AsFloat;
      // El importe de esta línea pasa a ser únicamente el dinero que ha dado
      cdsLineas.FieldByName(
                        'PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA').AsCurrency :=
                                                               DineroDisponible;
      if PorcIva = 0 then
        cdsLineas.FieldByName(
                        'PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency :=
                                                                DineroDisponible
      else
        cdsLineas.FieldByName(
                        'PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency :=
                                       DineroDisponible / (1 + (PorcIva / 100));
      cdsLineas.FieldByName('PRECIOSALIDA_FACTURA_LINEA').AsCurrency :=
                                                          cdsLineas.FieldByName(
                          'PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency;
      cdsLineas.FieldByName('CANTIDAD_FACTURA_LINEA').AsFloat := 1;
      cdsLineas.FieldByName('PORCEN_DTO_FACTURA_LINEA').AsFloat := 0;
      cdsLineas.FieldByName('PRECIO_DTO_FACTURA_LINEA').AsCurrency := 0;
      cdsLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency :=
                                                          cdsLineas.FieldByName(
                          'PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency;
      cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency :=
                                                               DineroDisponible;
      cdsLineas.Post;
      DineroDisponible := 0; // Se consumió todo el dinero
    end;
  end;

begin
  DineroDisponible := DineroEntregado;
  cdsLineas.DisableControls;
  try
    // PASO 0: Sumar dinero a favor (Abonos de anticipos y devoluciones)
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      if cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency < 0 then
        DineroDisponible := DineroDisponible -
                        cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency;
      cdsLineas.Next;
    end;
    // PASO 1: PRIORIDAD ABSOLUTA - Pagar primero las prendas del pasado (Depósitos)
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      VieneDeDep := '';
      if cdsLineas.FindField('VIENE_DE_DEPOSITO') <> nil then VieneDeDep :=
                            cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
      AccionDep := '';
      if cdsLineas.FindField('ACCION_DEPOSITO') <> nil then
        AccionDep := cdsLineas.FieldByName('ACCION_DEPOSITO').AsString;

      if (VieneDeDep = 'S') and
         (AccionDep = 'COBRAR') and
         (cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency > 0) then
        ProcesarLinea;

      cdsLineas.Next;
    end;

    // PASO 2: EL RESTO DEL DINERO - Para las prendas nuevas de hoy
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      VieneDeDep := '';
      if cdsLineas.FindField('VIENE_DE_DEPOSITO') <> nil then
        VieneDeDep := cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
      AccionDep := '';
      if cdsLineas.FindField('ACCION_DEPOSITO') <> nil then
        AccionDep := cdsLineas.FieldByName('ACCION_DEPOSITO').AsString;
      if (VieneDeDep <> 'S') and
         (VieneDeDep <> 'ABONO_ANTICIPO') and
         (AccionDep = 'COBRAR') and
         (cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency > 0) then
        ProcesarLinea;
      cdsLineas.Next;
    end;

  finally
    cdsLineas.EnableControls;
  end;
end;

function TdmCajaOpe.GrabarFacturaSimplificada(const AEmpresa,
                                                    AAlmacen,
                                                    ACaja,
                                                    ASerieElegida: string;
                                              DatosCobro: TDatosFaseCobro;
                                              out SerieGenerada: string;
                                              out NumeroGenerado: String;
                                              out ValeGenerado:String): Boolean;
var
  QryTrx: TUniQuery;
  NumOperacionVE: Integer;
  DineroDisponible, TotalFactura, TotalLinea, DineroEntregado: Currency;
  PorcIva: Double;
  PrecioSinIva, ImporteDevuelto: Currency;
  AlmacenDeposito, AlmacenOrigenSalida, AccionDep, SkuLinea, VieneDeDeposito, TipoMov: string;
  CodigoCliente, UsuarioCaja: string;
begin
  Result := False;
  SerieGenerada := ASerieElegida;
  NumeroGenerado := '0';
  ValeGenerado := '';

  AlmacenDeposito := ObtenerAlmacenDepositoEmpresa(AEmpresa);
  UsuarioCaja := inLibGlobalVar.oConn.Username;

  if cdsCabecera.State in [dsEdit, dsInsert] then cdsCabecera.Post;
  if cdsLineas.State in [dsEdit, dsInsert] then cdsLineas.Post;
  if cdsLineas.IsEmpty then
    raise Exception.Create('No se puede grabar una operación sin líneas.');
  if DatosCobro.ImporteEntregado <
                cdsCabecera.FieldByName('TOTAL_LIQUIDO_FACTURA').AsCurrency then
  begin
    TransformarLineasParaCobroParcial(cdsLineas, DatosCobro.ImporteEntregado);
    if not CuadrarFacturaEnMemoria(cdsCabecera, cdsLineas) then
      raise Exception.Create('No se pudo cuadrar tras cobro parcial.');
  end;
  CodigoCliente := cdsCabecera.FieldByName('CODIGO_CLIENTE_FACTURA').AsString;

  QryTrx := TUniQuery.Create(nil);
  try
    QryTrx.Connection := inLibGlobalVar.oConn;
    inLibGlobalVar.oConn.StartTransaction;
    try
      // =======================================================================
      // PASO 1: DINERO DISPONIBLE (Sumando abonos a favor del cliente)
      // =======================================================================
      DineroDisponible := DatosCobro.ImporteEntregado;

      // El dinero de las líneas negativas (abonos) suma a nuestro favor
      cdsLineas.DisableControls;
      try
        cdsLineas.First;
        while not cdsLineas.Eof do
        begin
          TotalLinea := cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency;
          if TotalLinea < 0 then
            DineroDisponible := DineroDisponible - TotalLinea; // Ej: -(-30) = +30 disponible
          cdsLineas.Next;
        end;
      finally
        cdsLineas.EnableControls;
      end;

      // Todo lo que sea "pagable" formará el total real de la operación (TotalFactura)
      TotalFactura := DatosCobro.ImporteEntregado;

      // =======================================================================
      // PASO 2: CREAR CABECERA DE FACTURA Y OPERACIÓN 'VE' ÚNICA
      // =======================================================================
      // 1. Obtener Contador
      QryTrx.SQL.Text := 'CALL PRC_GET_NEXT_CONT_FACT_SERIE(:pserie, :pTipoDoc, :pEMP, :pUSUARIO, :pcont)';
      QryTrx.ParamByName('pserie').AsString := SerieGenerada;
      QryTrx.ParamByName('pTipoDoc').AsString := 'FC';
      QryTrx.ParamByName('pEMP').AsString := AEmpresa;
      QryTrx.ParamByName('pUSUARIO').AsString := UsuarioCaja;
      QryTrx.ParamByName('pcont').ParamType := ptOutput;
      QryTrx.ParamByName('pcont').DataType := ftString;
      QryTrx.ParamByName('pcont').Size := 12;
      QryTrx.Execute;
      NumeroGenerado := QryTrx.ParamByName('pcont').AsString;

      // 2. Insertar Cabecera (Inicialmente insertamos los datos brutos del Grid)
      QryTrx.SQL.Text :=
        'INSERT INTO fza_facturas ' +
        '(CODIGO_EMPRESA_FACTURA, SERIE_FACTURA, NRO_FACTURA, FECHA_FACTURA, ' +
        ' CODIGO_CLIENTE_FACTURA, TIPO_FACTURA, TOTAL_BASES_FACTURA, TOTAL_IMPUESTOS_FACTURA, ' +
        ' PORCEN_IVAN_FACTURA, TOTAL_IVAN_FACTURA, PORCEN_REN_FACTURA, TOTAL_REN_FACTURA, TOTAL_BASEI_IVAN_FACTURA, ' +
        ' PORCEN_IVAR_FACTURA, TOTAL_IVAR_FACTURA, PORCEN_RER_FACTURA, TOTAL_RER_FACTURA, TOTAL_BASEI_IVAR_FACTURA, ' +
        ' PORCEN_IVAS_FACTURA, TOTAL_IVAS_FACTURA, PORCEN_RES_FACTURA, TOTAL_RES_FACTURA, TOTAL_BASEI_IVAS_FACTURA, ' +
        ' PORCEN_IVAE_FACTURA, TOTAL_IVAE_FACTURA, PORCEN_REE_FACTURA, TOTAL_REE_FACTURA, TOTAL_BASEI_IVAE_FACTURA) ' +
        'VALUES ' +
        '(:EMP, :SERIE, :NRO, :FECHA, :CLI, :TIPO, :BASES, :IMPUESTOS, ' +
        ' :PIVAN, :TIVAN, :PREN, :TREN, :BASEIN, :PIVAR, :TIVAR, :PRER, :TRER, :BASEIR, ' +
        ' :PIVAS, :TIVAS, :PRES, :TRES, :BASEIS, :PIVAE, :TIVAE, :PREE, :TREE, :BASEIE)';

      QryTrx.ParamByName('EMP').AsString     := AEmpresa;
      QryTrx.ParamByName('SERIE').AsString   := SerieGenerada;
      QryTrx.ParamByName('NRO').AsString     := NumeroGenerado;
      QryTrx.ParamByName('FECHA').AsDateTime := cdsCabecera.FieldByName('FECHA_FACTURA').AsDateTime;
      QryTrx.ParamByName('CLI').AsString     := CodigoCliente;
      QryTrx.ParamByName('TIPO').AsString    := 'SIMPLIFICADA';
      QryTrx.ParamByName('BASES').AsCurrency     := cdsCabecera.FieldByName('TOTAL_BASES_FACTURA').AsCurrency;
      QryTrx.ParamByName('IMPUESTOS').AsCurrency := cdsCabecera.FieldByName('TOTAL_IMPUESTOS_FACTURA').AsCurrency;
      QryTrx.ParamByName('PIVAN').AsFloat    := cdsCabecera.FieldByName('PORCEN_IVAN_FACTURA').AsFloat;
      QryTrx.ParamByName('TIVAN').AsCurrency := cdsCabecera.FieldByName('TOTAL_IVAN_FACTURA').AsCurrency;
      QryTrx.ParamByName('PREN').AsFloat     := cdsCabecera.FieldByName('PORCEN_REN_FACTURA').AsFloat;
      QryTrx.ParamByName('TREN').AsCurrency  := cdsCabecera.FieldByName('TOTAL_REN_FACTURA').AsCurrency;
      QryTrx.ParamByName('BASEIN').AsCurrency:= cdsCabecera.FieldByName('TOTAL_BASEI_IVAN_FACTURA').AsCurrency;
      QryTrx.ParamByName('PIVAR').AsFloat    := cdsCabecera.FieldByName('PORCEN_IVAR_FACTURA').AsFloat;
      QryTrx.ParamByName('TIVAR').AsCurrency := cdsCabecera.FieldByName('TOTAL_IVAR_FACTURA').AsCurrency;
      QryTrx.ParamByName('PRER').AsFloat     := cdsCabecera.FieldByName('PORCEN_RER_FACTURA').AsFloat;
      QryTrx.ParamByName('TRER').AsCurrency  := cdsCabecera.FieldByName('TOTAL_RER_FACTURA').AsCurrency;
      QryTrx.ParamByName('BASEIR').AsCurrency:= cdsCabecera.FieldByName('TOTAL_BASEI_IVAR_FACTURA').AsCurrency;
      QryTrx.ParamByName('PIVAS').AsFloat    := cdsCabecera.FieldByName('PORCEN_IVAS_FACTURA').AsFloat;
      QryTrx.ParamByName('TIVAS').AsCurrency := cdsCabecera.FieldByName('TOTAL_IVAS_FACTURA').AsCurrency;
      QryTrx.ParamByName('PRES').AsFloat     := cdsCabecera.FieldByName('PORCEN_RES_FACTURA').AsFloat;
      QryTrx.ParamByName('TRES').AsCurrency  := cdsCabecera.FieldByName('TOTAL_RES_FACTURA').AsCurrency;
      QryTrx.ParamByName('BASEIS').AsCurrency:= cdsCabecera.FieldByName('TOTAL_BASEI_IVAS_FACTURA').AsCurrency;
      QryTrx.ParamByName('PIVAE').AsFloat    := cdsCabecera.FieldByName('PORCEN_IVAE_FACTURA').AsFloat;
      QryTrx.ParamByName('TIVAE').AsCurrency := cdsCabecera.FieldByName('TOTAL_IVAE_FACTURA').AsCurrency;
      QryTrx.ParamByName('PREE').AsFloat     := cdsCabecera.FieldByName('PORCEN_REE_FACTURA').AsFloat;
      QryTrx.ParamByName('TREE').AsCurrency  := cdsCabecera.FieldByName('TOTAL_REE_FACTURA').AsCurrency;
      QryTrx.ParamByName('BASEIE').AsCurrency:= cdsCabecera.FieldByName('TOTAL_BASEI_IVAE_FACTURA').AsCurrency;
      QryTrx.Execute;

      // 3. Operación de Caja 'VE'
      QryTrx.SQL.Text := 'SELECT GET_NEXT_OP_CAJA(:CAJA) AS NUEVO_OP';
      QryTrx.ParamByName('CAJA').AsString := ACaja;
      QryTrx.Open;
      NumOperacionVE := QryTrx.FieldByName('NUEVO_OP').AsInteger;
      QryTrx.Close;

      QryTrx.SQL.Text :=
        'INSERT INTO fza_caja_operaciones (CODIGO_CAJA_OP, NUMERO_OPERACION_OP, TIPO_OPERACION_OP, IMPORTE_OP, FECHA_OP) ' +
        'VALUES (:CAJA, :NUMOP, ''VE'', :IMPORTE, :FECHA)';
      QryTrx.ParamByName('CAJA').AsString := ACaja;
      QryTrx.ParamByName('NUMOP').AsInteger := NumOperacionVE;
      QryTrx.ParamByName('IMPORTE').AsCurrency := TotalFactura;
      QryTrx.ParamByName('FECHA').AsDateTime := Now;
      QryTrx.Execute;

      // =======================================================================
      // PASO 3: PROCESAR LÍNEAS (Los 4 Casos Posibles)
      // =======================================================================
      cdsLineas.DisableControls;
      try
        cdsLineas.First;
        while not cdsLineas.Eof do
        begin
          TotalLinea := cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency;
          SkuLinea := cdsLineas.FieldByName('CODIGO_UNIDAD_FACTURA_LINEA').AsString;

          VieneDeDeposito := '';
          if cdsLineas.FindField('VIENE_DE_DEPOSITO') <> nil then
            VieneDeDeposito := cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;

          AccionDep := '';
          if cdsLineas.FindField('ACCION_DEPOSITO') <> nil then
            AccionDep := cdsLineas.FieldByName('ACCION_DEPOSITO').AsString;

          // Preparamos la SQL común de Inserción de Línea
          QryTrx.SQL.Text :=
            'INSERT INTO fza_facturas_lineas ' +
            '(CODIGO_EMPRESA_FACTURA_LINEA, SERIE_FACTURA_LINEA, NRO_FACTURA_LINEA, LINEA_FACTURA_LINEA, ' +
            ' CODIGO_ARTICULO_FACTURA_LINEA, DESCRIPCION_ARTICULO_FACTURA_LINEA, CODIGO_UNIDAD_FACTURA_LINEA, ' +
            ' CANTIDAD_FACTURA_LINEA, PRECIOSALIDA_FACTURA_LINEA, PORCEN_DTO_FACTURA_LINEA, ' +
            ' PRECIO_DTO_FACTURA_LINEA, PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA, ' +
            ' TIPOIVA_ARTICULO_FACTURA_LINEA, PORCEN_IVA_FACTURA_LINEA, PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA, ' +
            ' TOTAL_FACTURASIVA_LINEA, TOTAL_FACTURA_LINEA) ' +
            'VALUES ' +
            '(:EMP, :SERIE, :NRO, :LINEA, :ART, :DESC, :SKU, :CANT, ' +
            ' :PRECSALIDA, :PORCDTO, :PRECDTO, :PRECSIVA, :TIPOIVA, :PORCIVA, :PRECCIVA, :TOTALSIVA, :TOTALCIVA)';

          QryTrx.ParamByName('EMP').AsString     := AEmpresa;
          QryTrx.ParamByName('SERIE').AsString   := SerieGenerada;
          QryTrx.ParamByName('NRO').AsString     := NumeroGenerado;
          QryTrx.ParamByName('LINEA').AsInteger  := cdsLineas.FieldByName('LINEA_FACTURA_LINEA').AsInteger;

          // -------------------------------------------------------------------
          // CASO A: LÍNEA VIRTUAL DE ABONO DE ANTICIPO PREVIO
          // -------------------------------------------------------------------
          if VieneDeDeposito = 'ABONO_ANTICIPO' then
          begin
            QryTrx.ParamByName('ART').AsString := cdsLineas.FieldByName('CODIGO_ARTICULO_FACTURA_LINEA').AsString;
            QryTrx.ParamByName('DESC').AsString := cdsLineas.FieldByName('DESCRIPCION_ARTICULO_FACTURA_LINEA').AsString;
            QryTrx.ParamByName('SKU').AsString := cdsLineas.FieldByName('CODIGO_UNIDAD_FACTURA_LINEA').AsString;
            QryTrx.ParamByName('CANT').AsFloat := cdsLineas.FieldByName('CANTIDAD_FACTURA_LINEA').AsFloat;
            QryTrx.ParamByName('PRECSALIDA').AsCurrency := cdsLineas.FieldByName('PRECIOSALIDA_FACTURA_LINEA').AsCurrency;
            QryTrx.ParamByName('PORCDTO').AsFloat := cdsLineas.FieldByName('PORCEN_DTO_FACTURA_LINEA').AsFloat;
            QryTrx.ParamByName('PRECDTO').AsCurrency := cdsLineas.FieldByName('PRECIO_DTO_FACTURA_LINEA').AsCurrency;
            QryTrx.ParamByName('PRECSIVA').AsCurrency := cdsLineas.FieldByName('PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency;
            QryTrx.ParamByName('PRECCIVA').AsCurrency := cdsLineas.FieldByName('PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA').AsCurrency;
            QryTrx.ParamByName('TIPOIVA').AsString := cdsLineas.FieldByName('TIPOIVA_ARTICULO_FACTURA_LINEA').AsString;
            QryTrx.ParamByName('PORCIVA').AsFloat := cdsLineas.FieldByName('PORCEN_IVA_FACTURA_LINEA').AsFloat;
            QryTrx.ParamByName('TOTALSIVA').AsCurrency := cdsLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency;
            QryTrx.ParamByName('TOTALCIVA').AsCurrency := TotalLinea;
            QryTrx.Execute;

            // NO hay stock, continuamos
            cdsLineas.Next;
            Continue;
          end;

          // -------------------------------------------------------------------
          // CASO B: CANCELACIÓN DE UN DEPÓSITO
          // -------------------------------------------------------------------
          if AccionDep = 'CANCELAR' then
          begin
            QryTrx.ParamByName('ART').AsString := cdsLineas.FieldByName('CODIGO_ARTICULO_FACTURA_LINEA').AsString;
            QryTrx.ParamByName('DESC').AsString := 'Devolución anticipo ' + cdsLineas.FieldByName('DESCRIPCION_ARTICULO_FACTURA_LINEA').AsString;
            QryTrx.ParamByName('SKU').AsString := cdsLineas.FieldByName('CODIGO_UNIDAD_FACTURA_LINEA').AsString;
            QryTrx.ParamByName('CANT').AsFloat := cdsLineas.FieldByName('CANTIDAD_FACTURA_LINEA').AsFloat;
            QryTrx.ParamByName('PRECSALIDA').AsCurrency := cdsLineas.FieldByName('PRECIOSALIDA_FACTURA_LINEA').AsCurrency;
            QryTrx.ParamByName('PORCDTO').AsFloat := cdsLineas.FieldByName('PORCEN_DTO_FACTURA_LINEA').AsFloat;
            QryTrx.ParamByName('PRECDTO').AsCurrency := cdsLineas.FieldByName('PRECIO_DTO_FACTURA_LINEA').AsCurrency;
            QryTrx.ParamByName('PRECSIVA').AsCurrency := cdsLineas.FieldByName('PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency;
            QryTrx.ParamByName('PRECCIVA').AsCurrency := cdsLineas.FieldByName('PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA').AsCurrency;
            QryTrx.ParamByName('TIPOIVA').AsString := cdsLineas.FieldByName('TIPOIVA_ARTICULO_FACTURA_LINEA').AsString;
            QryTrx.ParamByName('PORCIVA').AsFloat := cdsLineas.FieldByName('PORCEN_IVA_FACTURA_LINEA').AsFloat;
            QryTrx.ParamByName('TOTALSIVA').AsCurrency := cdsLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency;
            QryTrx.ParamByName('TOTALCIVA').AsCurrency := TotalLinea;
            QryTrx.Execute;

            AnularDepositoCliente(QryTrx, SkuLinea, UsuarioCaja,
                                  AAlmacen, AlmacenDeposito,
                                  ImporteDevuelto, Abs(cdsLineas.FieldByName('CANTIDAD_FACTURA_LINEA').AsFloat));

            DineroDisponible := DineroDisponible - TotalLinea;
            cdsLineas.Next;
            Continue;
          end;

          // -------------------------------------------------------------------
          // CASO C: VENTA O DEVOLUCIÓN NORMAL (100% Pagado)
          // -------------------------------------------------------------------
          if (TotalLinea <= 0) or (DineroDisponible >= TotalLinea) then
          begin
            QryTrx.ParamByName('ART').AsString := cdsLineas.FieldByName('CODIGO_ARTICULO_FACTURA_LINEA').AsString;
            QryTrx.ParamByName('DESC').AsString := cdsLineas.FieldByName('DESCRIPCION_ARTICULO_FACTURA_LINEA').AsString;
            QryTrx.ParamByName('SKU').AsString := cdsLineas.FieldByName('CODIGO_UNIDAD_FACTURA_LINEA').AsString;
            QryTrx.ParamByName('CANT').AsFloat := cdsLineas.FieldByName('CANTIDAD_FACTURA_LINEA').AsFloat;
            QryTrx.ParamByName('PRECSALIDA').AsCurrency := cdsLineas.FieldByName('PRECIOSALIDA_FACTURA_LINEA').AsCurrency;
            QryTrx.ParamByName('PORCDTO').AsFloat := cdsLineas.FieldByName('PORCEN_DTO_FACTURA_LINEA').AsFloat;
            QryTrx.ParamByName('PRECDTO').AsCurrency := cdsLineas.FieldByName('PRECIO_DTO_FACTURA_LINEA').AsCurrency;
            QryTrx.ParamByName('PRECSIVA').AsCurrency := cdsLineas.FieldByName('PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA').AsCurrency;
            QryTrx.ParamByName('PRECCIVA').AsCurrency := cdsLineas.FieldByName('PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA').AsCurrency;
            QryTrx.ParamByName('TIPOIVA').AsString := cdsLineas.FieldByName('TIPOIVA_ARTICULO_FACTURA_LINEA').AsString;
            QryTrx.ParamByName('PORCIVA').AsFloat := cdsLineas.FieldByName('PORCEN_IVA_FACTURA_LINEA').AsFloat;
            QryTrx.ParamByName('TOTALSIVA').AsCurrency := cdsLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency;
            QryTrx.ParamByName('TOTALCIVA').AsCurrency := TotalLinea;
            QryTrx.Execute;

            if VieneDeDeposito = 'S' then
            begin
              AlmacenOrigenSalida := AlmacenDeposito;
              CerrarDepositoCliente(QryTrx, SkuLinea, UsuarioCaja);
            end
            else
            begin
              AlmacenOrigenSalida := AAlmacen;
            end;

            TipoMov := 'S';
            if cdsLineas.FieldByName('CANTIDAD_FACTURA_LINEA').AsFloat < 0 then TipoMov := 'E';

            QryTrx.SQL.Text :=
              'INSERT INTO fza_movimientos_almacen (CODIGO_ALMACEN_MOV, CODIGO_UNIDAD_MOV, TIPO_MOVIMIENTO_MOV, CANTIDAD_MOV, FECHA_MOV) ' +
              'VALUES (:ALM, :SKU, :TIPOMOV, :CANT, :FECHA)';
            QryTrx.ParamByName('ALM').AsString := AlmacenOrigenSalida;
            QryTrx.ParamByName('SKU').AsString := SkuLinea;
            QryTrx.ParamByName('TIPOMOV').AsString := TipoMov;
            QryTrx.ParamByName('CANT').AsFloat := Abs(cdsLineas.FieldByName('CANTIDAD_FACTURA_LINEA').AsFloat);
            QryTrx.ParamByName('FECHA').AsDateTime := Now;
            QryTrx.Execute;

            DineroDisponible := DineroDisponible - TotalLinea;
          end
          // -------------------------------------------------------------------
          // CASO D: NUEVO ANTICIPO (Cobro Parcial a cuenta)
          // -------------------------------------------------------------------
          else if (AccionDep = 'NUEVO_DEP') or (AccionDep = 'AUMENTAR_DEP') then
          begin
            DineroEntregado    := TotalLinea;
            var PrecioOriginalReal := cdsLineas.FieldByName('PRECIO_ORIGINAL_DEP').AsCurrency;
            var TipoIVALinea   := cdsLineas.FieldByName('TIPOIVA_ARTICULO_FACTURA_LINEA').AsString;
            var PorcIVALinea   := cdsLineas.FieldByName('PORCEN_IVA_FACTURA_LINEA').AsCurrency;
            var EsImpInclLinea := cdsLineas.FieldByName('ESIMP_INCL_TARIFA_FACTURA_LINEA').AsString;
            // Calcular PrecioSinIva sobre el dinero entregado
            if PorcIVALinea = 0 then
              PrecioSinIva := DineroEntregado
            else
              PrecioSinIva := DineroEntregado / (1 + (PorcIVALinea / 100));
            QryTrx.ParamByName('ART').AsString      := 'ANTICIPO';
            QryTrx.ParamByName('DESC').AsString     := 'Anticipo ' +
                                    cdsLineas.FieldByName('DESCRIPCION_ARTICULO_FACTURA_LINEA').AsString;
            QryTrx.ParamByName('SKU').AsString      := 'ANTICIPO';
            QryTrx.ParamByName('CANT').AsFloat      := 1;
            QryTrx.ParamByName('PRECSALIDA').AsCurrency  := PrecioSinIva;
            QryTrx.ParamByName('PORCDTO').AsFloat        := 0;
            QryTrx.ParamByName('PRECDTO').AsCurrency     := 0;
            QryTrx.ParamByName('PRECSIVA').AsCurrency    := PrecioSinIva;
            QryTrx.ParamByName('PRECCIVA').AsCurrency    := DineroEntregado;
            QryTrx.ParamByName('TIPOIVA').AsString       := TipoIVALinea;
            QryTrx.ParamByName('PORCIVA').AsFloat        := PorcIVALinea;
            QryTrx.ParamByName('TOTALSIVA').AsCurrency   := PrecioSinIva;
            QryTrx.ParamByName('TOTALCIVA').AsCurrency   := DineroEntregado;
            QryTrx.Execute;
            if AccionDep = 'AUMENTAR_DEP' then
            begin
              var AnticipoPrevio    :=
                            cdsLineas.FieldByName('ANTICIPO_PREVIO').AsCurrency;
              var AnticipoRealNuevo := DineroEntregado - AnticipoPrevio;
              AumentarAnticipoDeposito(QryTrx, SkuLinea, UsuarioCaja, AnticipoRealNuevo);
            end
            else // NUEVO_DEP
            begin
              CrearNuevoDepositoCliente(QryTrx, AEmpresa, CodigoCliente,
                                        cdsLineas.FieldByName(
                                      'CODIGO_ARTICULO_FACTURA_LINEA').AsString,
                                        SkuLinea, UsuarioCaja,
                                        PrecioOriginalReal,
                                        DineroEntregado,
                                        AAlmacen, AlmacenDeposito,
                                        1,
                                        TipoIVALinea,
                                        PorcIVALinea,
                                        EsImpInclLinea);
            end;
          end;
          cdsLineas.Next;
        end;
      finally
        cdsLineas.EnableControls;
      end;
      // =======================================================================
      // PASO 4: GUARDAR FORMAS DE PAGO ENTREGADAS (Contra Operación 'VE')
      // =======================================================================
      DatosCobro.MemTablePagos.First;
      while not DatosCobro.MemTablePagos.Eof do
      begin
        var CodigoFP := DatosCobro.MemTablePagos.FieldByName('CODIGO_FORMAP').AsString;
        var ImporteEntregado := DatosCobro.MemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat;

        if Abs(ImporteEntregado) > 0.001 then
        begin
          QryTrx.SQL.Text :=
            'INSERT INTO fza_caja_pagos (CODIGO_CAJA_PAGO, NUMERO_OPERACION_PAGO, CODIGO_FORMAP_PAGO, IMPORTE_ENTREGADO_PAGO, CAMBIO_PAGO) ' +
            'VALUES (:CAJA, :NUMOP, :FORMAP, :IMPORTE, :CAMBIO)';
          QryTrx.ParamByName('CAJA').AsString := ACaja;
          QryTrx.ParamByName('NUMOP').AsInteger := NumOperacionVE;
          QryTrx.ParamByName('FORMAP').AsString := CodigoFP;
          QryTrx.ParamByName('IMPORTE').AsFloat := ImporteEntregado;
          QryTrx.ParamByName('CAMBIO').AsCurrency := DatosCobro.MemTablePagos.FieldByName('IMPORTE_CAMBIO').AsCurrency;
          QryTrx.Execute;
        end;
        DatosCobro.MemTablePagos.Next;
      end;

      // =======================================================================
      // PASO 5: GESTIÓN DE VALES (Canjes y Emisiones)
      // =======================================================================
      for var i := 0 to DatosCobro.ValesRecogidos.Count - 1 do
      begin
        MarcarValeComoCanjeado(DatosCobro.ValesRecogidos[i].CodigoVale,
                               ACaja, AAlmacen, NumOperacionVE,
                               SerieGenerada, NumeroGenerado);
      end;

      if DatosCobro.ImporteValeEmitido > 0 then
      begin
         ValeGenerado := EmitirNuevoVale(AEmpresa, AAlmacen, ACaja, NumOperacionVE,
                                         SerieGenerada, NumeroGenerado,
                                         DatosCobro.ImporteValeEmitido);
      end;


      // =======================================================================
      // CONFIRMAR TRANSACCIÓN
      // =======================================================================
      inLibGlobalVar.oConn.Commit;
      Result := True;
    except
      on E: Exception do
      begin
        inLibGlobalVar.oConn.Rollback;
        raise Exception.Create('Error al guardar el ticket. No se ha registrado la operación.' + sLineBreak + 'Motivo: ' + E.Message);
      end;
    end;
  finally
    QryTrx.Free;
  end;
end;

function TdmCajaOpe.CuadrarFacturaEnMemoria(dsCabecera, dsLineas: TDataSet): Boolean;
var
  CalculadorFiscal: TFacturaTotales;
begin
  Result := False;
  // Instanciamos tu clase pasándole los datasets de la caja
  CalculadorFiscal := TFacturaTotales.Create(dsCabecera, dsLineas);
  try
    // ProcesarFacturaCompleta se encarga de leer configuración, recorrer líneas y sumarizar
    Result := CalculadorFiscal.ProcesarFacturaCompleta;

    if not Result then
      raise Exception.Create('Error al cuadrar la factura: ' + CalculadorFiscal.MensajeError);
  finally
    CalculadorFiscal.Free;
  end;
end;

function TdmCajaOpe.EmitirNuevoVale(const AEmpresa, AAlmacen, ACaja: string;
                                    ANumOperacion: Integer;
                                    ASerieFactura, ANumFactura: string;
                                    AImporte: Currency): string;
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := inLibGlobalVar.oConn;
    // =======================================================================
    // 1. OBTENER EL CÓDIGO FORMATEADO DESDE EL NUEVO PROCEDURE
    // =======================================================================
    qry.SQL.Text := 'CALL PRC_GENERAR_CODIGO_VALE(:pEmp, :pAlm, :pCaja, :pOp, :pUsu, :pCodigo)';
    qry.ParamByName('pEmp').AsString   := AEmpresa;
    qry.ParamByName('pAlm').AsString   := AAlmacen;
    qry.ParamByName('pCaja').AsString  := ACaja;
    qry.ParamByName('pOp').AsInteger   := ANumOperacion;
    // Le pasamos el nombre del cajero. Si quieres puedes leerlo del cdsCabecera:
    // cdsCabecera.FieldByName('CODIGO_CAJERO_FACTURA').AsString
    qry.ParamByName('pUsu').AsString   := oUser;
    // Parámetro de salida (OUT) para recoger el código generado (VARCHAR 100)
    qry.ParamByName('pCodigo').ParamType := ptOutput;
    qry.ParamByName('pCodigo').DataType  := ftString;
    qry.ParamByName('pCodigo').Size      := 100;
    qry.Execute;
    Result := qry.ParamByName('pCodigo').AsString;
    // =======================================================================
    // 2. INSERTAR EL NUEVO VALE EN LA BASE DE DATOS
    // =======================================================================
    qry.SQL.Text :=
      'INSERT INTO fza_caja_vales ' +
      '(CODIGO_VL, IMPORTE_VL, FECHA_EMISION_VL, ESTADO_VL, ' +
      ' CODIGO_CAJA_EMISION_VL, CODIGO_ALMACEN_EMISION_VL, ' +
      ' NUMERO_OPERACION_EMISION_VL, SERIE_FACTURA_EMISION_VL, NRO_FACTURA_EMISION_VL) ' +
      'VALUES ' +
      '(:COD, :IMPORTE, :FECHA, ''PENDIENTE'', ' +
      ' :CAJA, :ALMACEN, :NUMOP, :SERIE, :NUMFAC)';
    qry.ParamByName('COD').AsString        := Result;
    qry.ParamByName('IMPORTE').AsCurrency  := AImporte;
    qry.ParamByName('FECHA').AsDateTime    := Now;
    qry.ParamByName('CAJA').AsString       := ACaja;
    qry.ParamByName('ALMACEN').AsString    := AAlmacen;
    qry.ParamByName('NUMOP').AsInteger     := ANumOperacion;
    qry.ParamByName('SERIE').AsString      := ASerieFactura;
    qry.ParamByName('NUMFAC').AsString     := ANumFactura;
    qry.Execute;
  finally
    qry.Free;
  end;
end;

function TdmCajaOpe.ObtenerAlmacenDepositoEmpresa(const AEmpresa: string): string;
var
  QryAlm: TUniQuery;
begin
  Result := '';
  QryAlm := TUniQuery.Create(nil);
  try
    // Usamos la conexión global del sistema
    QryAlm.Connection := inLibGlobalVar.oConn;

    QryAlm.SQL.Text :=
      'SELECT CODIGO_ALMACEN_ALM ' +
      '  FROM fza_almacenes ' +
      ' WHERE CODIGO_EMPRESA_ALM = :EMP ' +
      '   AND ESACTIVO_ALM = ''S'' ' +
      '   AND TIPO_USO_ALM = ''DEPÓSITO'' ' + // <-- Usando tu flag real
      ' LIMIT 1';

    QryAlm.ParamByName('EMP').AsString := AEmpresa;
    QryAlm.Open;

    if not QryAlm.IsEmpty then
      Result := QryAlm.FieldByName('CODIGO_ALMACEN_ALM').AsString
    else
      // Lanzamos excepción para que la transacción de caja se detenga si hay un error de configuración
      raise Exception.Create('No se ha encontrado un almacén de depósitos (TIPO_USO_ALM = ''DEPÓSITO'') activo para la empresa ' + AEmpresa + '.');

  finally
    QryAlm.Free;
  end;
end;

//procedure TdmCajaOpe.CalcularTotalesCabecera;
//var
//  Clon: TClientDataSet;
//  TotalLiquido, TotalBase, TotalImpuestos: Currency;
//  EstaEditando: Boolean;
//  RecNoActivo: Integer;
//begin
//  TotalLiquido := 0;
//  TotalBase := 0;
//  if cdsLineas.Active then
//  begin
//    RecNoActivo := cdsLineas.RecNo;
//    EstaEditando := (cdsLineas.State in [dsEdit, dsInsert]);
//    Clon := TClientDataSet.Create(nil);
//    try
//      Clon.CloneCursor(cdsLineas, True);
//      Clon.DisableControls;
//      Clon.First;
//      while not Clon.Eof do
//      begin
//        if EstaEditando and (Clon.RecNo = RecNoActivo) then
//        begin
//          TotalLiquido := TotalLiquido +
//		                cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency;
//          TotalBase    := TotalBase    +
//		            cdsLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency;
//        end
//        else
//        begin
//          TotalLiquido := TotalLiquido +
//		                     Clon.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency;
//          TotalBase := TotalBase +
//		                 Clon.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency;
//        end;
//        Clon.Next;
//      end;
//    finally
//      Clon.EnableControls;
//      Clon.Free;
//    end;
//  end;
//  TotalImpuestos := TotalLiquido - TotalBase;
//  cdsCabecera.Edit;
//  cdsCabecera.FieldByName('TOTAL_BASES_FACTURA').AsCurrency := TotalBase;
//  cdsCabecera.FieldByName('TOTAL_IMPUESTOS_FACTURA').AsCurrency :=
//                                                                 TotalImpuestos;
//  cdsCabecera.FieldByName('TOTAL_LIQUIDO_FACTURA').AsCurrency := TotalLiquido;
//  cdsCabecera.Post;
//  if Assigned(FOnUpdateTotal) then
//    FOnUpdateTotal(Self, TotalLiquido);
//end;

//procedure TdmCajaOpe.CalcularTotalesLinea(MantenerImporteDto: Boolean = False);
//var
//  PrecioUnitario, Cantidad, PorcenDto, PorcenIVA: Currency;
//  TotalBruto, MontoDescuentoTotal, TotalNeto: Currency;
//  TotalBase, TotalImpuestos: Currency;
//  EsImpuestosIncluidos: Boolean;
//begin
//  if not cdsLineas.Active then Exit;
//  if cdsLineas.State = dsBrowse then cdsLineas.Edit;
//  Cantidad := cdsLineas.FieldByName('CANTIDAD_FACTURA_LINEA').AsCurrency;
//  PrecioUnitario := cdsLineas.FieldByName(
//                                       'PRECIOSALIDA_FACTURA_LINEA').AsCurrency;
//  PorcenIVA := cdsLineas.FieldByName('PORCEN_IVA_FACTURA_LINEA').AsCurrency;
//  EsImpuestosIncluidos := (cdsLineas.FieldByName(
//                             'ESIMP_INCL_TARIFA_FACTURA_LINEA').AsString = 'S');
//  TotalBruto := RoundTo(PrecioUnitario * Cantidad, -2);
//  if MantenerImporteDto then
//  begin
//    MontoDescuentoTotal := cdsLineas.FieldByName(
//                                         'PRECIO_DTO_FACTURA_LINEA').AsCurrency;
//    if TotalBruto <> 0 then
//      cdsLineas.FieldByName('PORCEN_DTO_FACTURA_LINEA').AsFloat :=
//                                        (MontoDescuentoTotal * 100) / TotalBruto
//    else
//      cdsLineas.FieldByName('PORCEN_DTO_FACTURA_LINEA').AsFloat := 0;
//  end
//  else
//  begin
//    // MODO B: Cambio normal. El % manda.
//    PorcenDto := cdsLineas.FieldByName('PORCEN_DTO_FACTURA_LINEA').AsFloat;
//    // Calculamos el descuento sobre el Total Bruto
//    MontoDescuentoTotal := RoundTo(TotalBruto * (PorcenDto / 100), -2);
//    cdsLineas.FieldByName('PRECIO_DTO_FACTURA_LINEA').AsCurrency := MontoDescuentoTotal;
//  end;
//  // 4. Aplicar el Descuento (Resta Global)
//  // Aquí está la corrección: TotalBruto - DescuentoTotal
//  TotalNeto := TotalBruto - MontoDescuentoTotal;
//  // 5. Desglose de Impuestos
//  if EsImpuestosIncluidos then
//  begin
//    // Si el precio incluye IVA, TotalNeto es el Total a Pagar
//    // Desglosamos hacia atrás
//    if (1 + (PorcenIVA / 100)) <> 0 then
//      TotalBase := RoundTo(TotalNeto / (1 + (PorcenIVA / 100)), -2)
//    else
//      TotalBase := TotalNeto;
//    // El total final es lo que dio la resta
//    cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency := TotalNeto;
//    cdsLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency := TotalBase;
//  end
//  else
//  begin
//    // Si el precio NO incluye IVA, TotalNeto es la Base Imponible Total
//    TotalBase := TotalNeto;
//    TotalImpuestos := RoundTo(TotalBase * (PorcenIVA / 100), -2);
//    cdsLineas.FieldByName('TOTAL_FACTURASIVA_LINEA').AsCurrency := TotalBase;
//    cdsLineas.FieldByName('TOTAL_FACTURA_LINEA').AsCurrency := TotalBase + TotalImpuestos;
//  end;
//  CalcularTotalesCabecera;
//end;

function TdmCajaOpe.BuscarYMostrarNombre(TipoEntidad, Codigo: string;
                                         var LabelDestino: String): Boolean;
var
  unqry: TUniQuery;
  FieldToGet: string;
  SQLStr: string;
begin
  LabelDestino := '';
  Result := False;
  if Trim(Codigo) = '' then
    Exit;
  if TipoEntidad = 'EMPLEADOS' then
  begin
    SQLStr := 'SELECT DIMINUTIVO_TICKET_USUARIO ' +
              '  FROM fza_usuarios ' +
              ' WHERE CODIGO_EMPLEADO_USUARIO = :COD';
    FieldToGet := 'DIMINUTIVO_TICKET_USUARIO';
  end
  else if TipoEntidad = 'CLIENTES' then
  begin
    SQLStr := 'SELECT RAZONSOCIAL_CLIENTE ' +
              '  FROM fza_clientes ' +
              ' WHERE CODIGO_CLIENTE = :COD';
    FieldToGet := 'RAZONSOCIAL_CLIENTE';
  end
  else
    Exit;
  unqry := TUniQuery.Create(nil);
  try
    unqry.Connection := oConn;
    unqry.SQL.Text := SQLStr;
    unqry.ParamByName('COD').AsString := Codigo;
    unqry.Open;
    if not unqry.IsEmpty then
    begin
      LabelDestino := unqry.FieldByName(FieldToGet).AsString;
      Result := True;
    end;
  finally
    unqry.Free;
  end;
end;

function TdmCajaOpe.GenerarSkuFinal(ArticuloBase: string): string;
var
  i: Integer;
  ValorAttr: string;
  SkuBuilder: string;
  NumAttr:Integer;
begin
  NumAttr := cdsLineas.FieldByName(
                         'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
  SkuBuilder := ArticuloBase;
  for i := 1 to NumAttr do
  begin
    ValorAttr := cdsLineas.FieldByName('ATTR' + IntToStr(i) +
	                                                         '_VALOR').AsString;
    if ValorAttr <> '' then
       SkuBuilder := SkuBuilder + '/' + ValorAttr;
  end;
  Result := SkuBuilder;
end;

function TdmCajaOpe.GetTarifaDefault: string;
begin
  var sql := TUniQuery.Create(nil);
  try
    sql.Connection := oConn;
    sql.SQL.Text := 'SELECT CODIGO_TARIFA ' +
                    ' FROM fza_tarifas ' +
                    'WHERE ESDEFAULT_TARIFA = ' + QuotedStr('S') +
                    ' LIMIT 1 ' ;
    sql.Open;
    Result := sql.FieldByName('CODIGO_TARIFA').AsString;
    sql.Close;
  finally
    FreeAndNil(sql);
  end;
end;

//procedure TdmCajaOpe.InicializarNuevaFactura(const ASerieFactura,
//                                                   ANroFactura: string);
//begin
//  // Limpiar datos anteriores
//  if cdsLineas.Active then cdsLineas.EmptyDataSet;
//  if cdsCabecera.Active then cdsCabecera.EmptyDataSet;
//  // Crear nuevo registro de cabecera
//  cdsCabecera.Append;
////  cdsCabecera.FieldByName('SERIE_FACTURA').AsString := ASerieFactura;
////  cdsCabecera.FieldByName('NRO_FACTURA').AsString := ANroFactura;
////  cdsCabecera.FieldByName('FECHA_FACTURA').AsDateTime := Date;
////  cdsCabecera.FieldByName('ESCONSOLIDADA_FACTURA').AsString := 'N';
////
////  cdsCabecera.FieldByName('FASE_FACTURA').AsString := 'BORRADOR';
////  cdsCabecera.FieldByName('CONTADOR_LINEAS_FACTURA').AsInteger := 0;
////  cdsCabecera.FieldByName('INSTANTEALTA').AsDateTime := Now;
////  cdsCabecera.FieldByName('USUARIOALTA').AsString := 'SISTEMA';
////  // Inicializar totales a 0
////  cdsCabecera.FieldByName('TOTAL_BASES_FACTURA').AsCurrency := 0;
////  cdsCabecera.FieldByName('TOTAL_IMPUESTOS_FACTURA').AsCurrency := 0;
////  cdsCabecera.FieldByName('TOTAL_LIQUIDO_FACTURA').AsCurrency := 0;
//
//  cdsCabecera.Post;
//end;

procedure TdmCajaOpe.cdsCabeceraAfterInsert(DataSet: TDataSet);
begin
  AplicarValoresPorDefecto(cdsCabecera, 'fza_facturas');
  cdsCabecera.FieldByName('SERIE_FACTURA').AsString := '0';
  cdsCabecera.FieldByName('TIPO_FACTURA').AsString := 'SIMPLIFICADA';
end;

procedure TdmCajaOpe.cdsLineasAfterDelete(DataSet: TDataSet);
begin
  GridRecalc(nil,
             (Owner as TfrmMtoOpeCaja).cxGrid1DBTableView1,
             cdsLineas,
             cdsCabecera,
             OnUpdateTotal);
end;

procedure TdmCajaOpe.cdsLineasAfterInsert(DataSet: TDataSet);
var
  NuevoNumero: Integer;
begin
  with cdsLineas do
  begin
    AplicarValoresPorDefecto(cdsLineas, 'fza_facturas_lineas');
    FieldByName('SERIE_FACTURA_LINEA').AsString := '0';
    FieldByName('NRO_FACTURA_LINEA').AsString := '0';
    NuevoNumero := cdsCabecera.FieldByName('CONTADOR_LINEAS_FACTURA').AsInteger
                                                                          + 10 ;
    cdsCabecera.Edit;
    cdsCabecera.FieldByName('CONTADOR_LINEAS_FACTURA').AsInteger := NuevoNumero;
    FieldByName('LINEA_FACTURA_LINEA').AsString :=
                                                  Format('%.4d', [NuevoNumero]);
    FieldByName('CODIGO_VENDEDOR_FACTURA_LINEA').AsString :=
                      cdsCabecera.FieldByName('CODIGO_CAJERO_FACTURA').AsString;
    FindField('PORCEN_IVA_FACTURA_LINEA').AsCurrency := GetTipoIVA(
          FieldByName('TIPOIVA_ARTICULO_FACTURA_LINEA').AsString);
  end;
end;

function TdmCajaOpe.GetTipoIVA(sTipoIVA: string): Currency;
var
  fPorcen:Currency;
begin
  with cdsCabecera do
  begin
  case IndexStr(sTipoIVA, ['N', 'R', 'S', 'E']) of
    0: fPorcen := FindField('PORCEN_IVAN_FACTURA').AsCurrency;
    1: fPorcen := FindField('PORCEN_IVAR_FACTURA').AsCurrency;
    2: fPorcen := FindField('PORCEN_IVAS_FACTURA').AsCurrency;
    3: fPorcen := FindField('PORCEN_IVAE_FACTURA').AsCurrency;
    else
    begin
      fPorcen := FindField('PORCEN_IVAN_FACTURA').AsCurrency;
      cdsLineas.FindField('TIPOIVA_ARTICULO_FACTURA_LINEA').AsString := 'N';
    end;
  end;
  end;
  Result := fPorcen;
end;

procedure TdmCajaOpe.cdsLineasAfterPost(DataSet: TDataSet);
begin
//         GridRecalc(nil,
//             (Owner as TfrmMtoOpeCaja).cxGrid1DBTableView1,
//             cdsLineas,
//             cdsCabecera,
//             OnUpdateTotal);
end;

procedure TdmCajaOpe.cdsLineasBeforePost(DataSet: TDataSet);
var
  Requeridos: Integer;
  SkuActual: string;
begin
  // 1. Validar descripción
  if DataSet.FieldByName('DESCRIPCION_ARTICULO_FACTURA_LINEA').AsString = '' then
    Abort;
  // 2. Si no requiere atributos, OK
  Requeridos := DataSet.FieldByName('NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
  if Requeridos = 0 then
    Exit;
  // 3. Si requiere atributos pero el SKU no tiene "/" → ABORTAR
  SkuActual := Trim(DataSet.FieldByName('CODIGO_UNIDAD_FACTURA_LINEA').AsString);
  if Pos('/', SkuActual) = 0 then
    Abort; // No permite grabar hasta que se complete el SKU
end;

procedure TdmCajaOpe.ConfigurarEstructuraCabecera;
begin
  if cdsCabecera.Active then cdsCabecera.Close;
  cdsCabecera.FieldDefs.Clear;
  cdsCabecera.IndexDefs.Clear;
  with cdsCabecera.FieldDefs do
  begin
    Add('SERIE_FACTURA', ftString, 20, True);
    Add('NRO_FACTURA', ftString, 20, True);
    Add('FECHA_FACTURA', ftDate, 0);
    Add('ESCONSOLIDADA_FACTURA', ftString, 1);
    Add('INSTANTECONSO_FACTURA', ftDateTime, 0);
    Add('TIPO_FACTURA', ftString, 20); // NORMAL, SIMPLIFICADA...
    Add('FASE_FACTURA', ftString, 20); // BORRADOR, ONLINE...
    Add('CODIGO_EMPRESA_FACTURA', ftString, 8);
    Add('RAZONSOCIAL_EMPRESA_FACTURA', ftString, 200);
    Add('NIF_EMPRESA_FACTURA', ftString, 50);
    Add('MOVIL_EMPRESA_FACTURA', ftString, 40);
    Add('EMAIL_EMPRESA_FACTURA', ftString, 200);
    Add('DIRECCION1_EMPRESA_FACTURA', ftString, 200);
    Add('DIRECCION2_EMPRESA_FACTURA', ftString, 200);
    Add('POBLACION_EMPRESA_FACTURA', ftString, 200);
    Add('PROVINCIA_EMPRESA_FACTURA', ftString, 200);
    Add('CODIGO_PAIS_EMPRESA_FACTURA', ftString, 3);
    Add('NOMBRE_PAIS_EMPRESA_FACTURA', ftString, 150);
    Add('CPOSTAL_EMPRESA_FACTURA', ftString, 15);
    Add('ESRETENCIONES_EMPRESA_FACTURA', ftString, 1);
    Add('GRUPO_ZONA_IVA_EMPRESA_FACTURA', ftString, 10);
    Add('ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA', ftString, 1);
    Add('CODIGO_CLIENTE_FACTURA', ftString, 10);
    Add('RAZONSOCIAL_CLIENTE_FACTURA', ftString, 200);
    Add('NIF_CLIENTE_FACTURA', ftString, 50);
    Add('MOVIL_CLIENTE_FACTURA', ftString, 40);
    Add('EMAIL_CLIENTE_FACTURA', ftString, 200);
    Add('DIRECCION1_CLIENTE_FACTURA', ftString, 200);
    Add('DIRECCION2_CLIENTE_FACTURA', ftString, 200);
    Add('POBLACION_CLIENTE_FACTURA', ftString, 200);
    Add('PROVINCIA_CLIENTE_FACTURA', ftString, 200);
    Add('CPOSTAL_CLIENTE_FACTURA', ftString, 15);
    Add('CODIGO_PAIS_CLIENTE_FACTURA', ftString, 3);
    Add('NOMBRE_PAIS_CLIENTE_FACTURA', ftString, 150);
    Add('CODIGO_CAJERO_FACTURA', ftString, 20);
    Add('CODIGO_IVA_FACTURA', ftString, 20);
    Add('ESIVA_RECARGO_CLIENTE_FACTURA', ftString, 1);
    Add('ESIVA_EXENTO_CLIENTE_FACTURA', ftString, 1);
    Add('ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA', ftString, 1);
    Add('ESRETENCIONES_CLIENTE_FACTURA', ftString, 1);
    Add('TARIFA_ARTICULO_CLIENTE_FACTURA', ftString, 10);
    Add('ESIMP_INCL_TARIFA_CLIENTE_FACTURA', ftString, 1);
    Add('ESINTRACOMUNITARIO_CLIENTE_FACTURA', ftString, 1);
    Add('ESIRPF_IMP_INCL_ZONA_IVA_FACTURA', ftString, 1);
    Add('ESAPLICA_RE_ZONA_IVA_FACTURA', ftString, 1);
    Add('ESIVAAGRICOLA_ZONA_IVA_FACTURA', ftString, 1);
    Add('PALABRA_REPORTS_ZONA_IVA_FACTURA', ftString, 10);
    Add('ESVENTA_ACTIVO_FIJO_FACTURA', ftString, 1);
    Add('PORCEN_IVAN_FACTURA', ftBCD, 0);
    Add('TOTAL_IVAN_FACTURA', ftBCD, 0);
    Add('PORCEN_REN_FACTURA', ftBCD, 0);
    Add('TOTAL_REN_FACTURA', ftBCD, 0);
    Add('TOTAL_BASEI_IVAN_FACTURA', ftBCD, 0);
    Add('PORCEN_IVAR_FACTURA', ftBCD, 0);
    Add('TOTAL_IVAR_FACTURA', ftBCD, 0);
    Add('PORCEN_RER_FACTURA', ftBCD, 0);
    Add('TOTAL_RER_FACTURA', ftBCD, 0);
    Add('TOTAL_BASEI_IVAR_FACTURA', ftBCD, 0);
    Add('PORCEN_IVAS_FACTURA', ftBCD, 0);
    Add('TOTAL_IVAS_FACTURA', ftBCD, 0);
    Add('PORCEN_RES_FACTURA', ftBCD, 0);
    Add('TOTAL_RES_FACTURA', ftBCD, 0);
    Add('TOTAL_BASEI_IVAS_FACTURA', ftBCD, 0);
    Add('PORCEN_IVAE_FACTURA', ftBCD, 0);
    Add('TOTAL_IVAE_FACTURA', ftBCD, 0);
    Add('PORCEN_REE_FACTURA', ftBCD, 0);
    Add('TOTAL_REE_FACTURA', ftBCD, 0);
    Add('TOTAL_BASEI_IVAE_FACTURA', ftBCD, 0);
    Add('TOTAL_BASES_FACTURA', ftBCD, 0);
    Add('TOTAL_IMPUESTOS_FACTURA', ftBCD, 0);
    Add('PORCEN_RETENCION_FACTURA', ftBCD, 0);
    Add('TOTAL_RETENCION_FACTURA', ftBCD, 0);
    Add('TOTAL_LIQUIDO_FACTURA', ftBCD, 0); // Lo que paga el cliente
    Add('FORMA_PAGO_FACTURA', ftString, 200);
    Add('NRO_FACTURA_ABONO_FACTURA', ftString, 8);
    Add('SERIE_FACTURA_ABONO_FACTURA', ftString, 8);
    Add('TEXTO_LEGAL_FACTURA_CLIENTE_FACTURA', ftString, 1000);
    Add('TEXTO_LEGAL_FACTURA_EMPRESA_FACTURA', ftString, 1000);
    Add('COMENTARIOS_FACTURA', ftString, 1000);
    Add('XML_FACTURA', ftMemo, 0); // Para VeriFactu
    Add('DOCUMENTO_FACTURA', ftBlob, 0);
    Add('CONTADOR_LINEAS_FACTURA', ftString, 8);
    Add('ESCREARARTICULOS_FACTURA', ftString, 1);
    Add('ESDESCRIPCIONES_AMP_FACTURA', ftString, 1);
    Add('ESFECHADEENTREGA_FACTURA', ftString, 1);
    Add('INSTANTEMODIF', ftDateTime, 0);
    Add('INSTANTEALTA', ftDateTime, 0);
    Add('USUARIOALTA', ftString, 100);
    Add('USUARIOMODIF', ftString, 100);
  end;
  with cdsCabecera.IndexDefs.AddIndexDef do
  begin
    Name := 'PK_CABECERA';
    Fields := 'SERIE_FACTURA;NRO_FACTURA';
    Options := [ixPrimary, ixUnique];
  end;
  cdsCabecera.CreateDataSet;
end;

procedure TdmCajaOpe.ConfigurarEstructuraLineas;
begin
  if cdsLineas.Active then cdsLineas.Close;
  cdsLineas.FieldDefs.Clear;
  cdsLineas.IndexDefs.Clear;
  with cdsLineas.FieldDefs do
  begin
    Add('VIENE_DE_DEPOSITO', ftString, 1);
    Add('PRECIO_ORIGINAL_DEP', ftCurrency);
    Add('ACCION_DEPOSITO', ftString, 15); // Valores: 'COBRAR' o 'CANCELAR'
    Add('ANTICIPO_PREVIO', ftCurrency);   // Memoria del dinero adelantado
    // -- CLAVES DE ENLACE CON CABECERA (Foreign Keys) --
    Add('SERIE_FACTURA_LINEA', ftString, 20, True);
    Add('NRO_FACTURA_LINEA', ftString, 20, True);
    Add('LINEA_FACTURA_LINEA', ftString, 4, True);
    Add('CODIGO_VENDEDOR_FACTURA_LINEA', ftString, 20);
    // -- DATOS DEL ARTÍCULO (PADRE) --
    Add('CODIGO_ARTICULO_FACTURA_LINEA', ftString, 50);
    Add('CODIGO_FAMILIA_FACTURA_LINEA', ftString, 20);
    Add('NOMBRE_FAMILIA_FACTURA_LINEA', ftString, 200);
    Add('DESCRIPCION_ARTICULO_FACTURA_LINEA', ftString, 100);
    // El SKU exacto que descuenta stock (ej: ZAP-OXFORD/42/NEGRO)
    Add('CODIGO_UNIDAD_FACTURA_LINEA', ftString, 50);
    Add('TIPO_ARTICULO_FACTURA_LINEA', ftString, 10); // 'ESTANDAR' o 'SERVICIO'
    Add('NUM_ATRIBUTOS_REQ_FACTURA_LINEA', ftInteger, 0);
    for var I := 1 to 5 do
    begin
      Add('ATTR' + IntToStr(i) + '_NOMBRE', ftString, 50);
      Add('ATTR' + IntToStr(i) + '_VALOR', ftString, 50);
    end;
    // DATOS DE TRAZABILIDAD (Si el artículo lo requiere)
    Add('LOTE_FACTURA_LINEA', ftString, 50);
    Add('FECHA_CADUCIDAD_FACTURA_LINEA', ftDate, 0);
    Add('PRECIO_ULT_COMPRA_FACTURA_LINEA', ftBCD, 0);
    Add('CODIGO_PROVEEDOR_FACTURA_LINEA', ftString, 20);
    Add('RAZONSOCIAL_PROVEEDOR_FACTURA_LINEA', ftString, 200);
    Add('ESPROVEEDORPRINCIPAL_FACTURA_LINEA', ftString, 1);
    Add('FECHA_ENTREGA_FACTURA_LINEA', ftDateTime, 0);
    // -- CANTIDADES Y TARIFAS --
    Add('TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA', ftString, 20); // 'Uds', 'Kg'
    Add('ESIMP_INCL_TARIFA_FACTURA_LINEA', ftString, 1);
    Add('CODIGO_TARIFA_FACTURA_LINEA', ftString, 10);
    // IMPORTANTE: ftBCD maneja bien los decimales de MySQL (Decimal 19,6)
    Add('CANTIDAD_FACTURA_LINEA', ftBCD, 0);
    // -- PRECIOS Y DESCUENTOS --
    Add('PRECIOSALIDA_FACTURA_LINEA', ftBCD, 0);
    Add('PORCEN_DTO_FACTURA_LINEA', ftBCD, 0);
    Add('PRECIO_DTO_FACTURA_LINEA', ftBCD, 0);
    // -- IMPORTES Y TOTALES --
    Add('PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA', ftBCD, 0);
    Add('TIPOIVA_ARTICULO_FACTURA_LINEA', ftString, 2);
    Add('PORCEN_IVA_FACTURA_LINEA', ftBCD, 0);
    Add('PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA', ftBCD, 0);
    Add('TOTAL_FACTURA_LINEA', ftBCD, 0);
    Add('TOTAL_FACTURASIVA_LINEA', ftBCD, 0);
    // -- CAMPOS DE AUDITORÍA --
    Add('INSTANTEMODIF', ftDateTime, 0);
    Add('INSTANTEALTA', ftDateTime, 0);
    Add('USUARIOALTA', ftString, 100);
    Add('USUARIOMODIF', ftString, 100);
  end;
  with cdsLineas.IndexDefs.AddIndexDef do
  begin
    Name := 'PRIMARY_KEY';
    Fields := 'SERIE_FACTURA_LINEA;NRO_FACTURA_LINEA;LINEA_FACTURA_LINEA';
    Options := [ixPrimary, ixUnique];
  end;
  cdsLineas.CreateDataSet;
  cdsLineas.IndexName := 'PRIMARY_KEY';
end;

procedure TdmCajaOpe.DataModuleCreate(Sender: TObject);
begin
  qryDefinicionArticulo.Connection := oConn;
  qryVales.Connection := oConn;
  qryStock.Connection := oConn;
  ConfigurarEstructuraCabecera;
  ConfigurarEstructuraLineas;
end;

procedure TdmCajaOpe.MarcarValeComoCanjeado(const ACodigoVale: string;
                                 ACodigoCaja: string;
                                 ACodigoAlmacen: string;
                                 ANumOperacion: Integer;
                                 ASerie: string;
                                 ANumFactura: String);
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'UPDATE fza_caja_vales ' +
      '   SET ESTADO_VL = ''CANJEADO'', ' +
      '       FECHA_CANJE_VL = NOW(), ' +
      '       CODIGO_CAJA_CANJE_VL = :caja, ' +
      '       CODIGO_ALMACEN_CANJE_VL = :almacen, ' +
      '       NUMERO_OPERACION_CANJE_VL = :numop, ' +
      '       SERIE_FACTURA_CANJE_VL = :serie, ' +
      '       NRO_FACTURA_CANJE_VL = :numfac ' +
      ' WHERE CODIGO_VL = :codigo ' +
      '   AND ESTADO_VL = ''PENDIENTE''';
    qry.ParamByName('codigo').AsString := ACodigoVale;
    qry.ParamByName('caja').AsString := ACodigoCaja;
    qry.ParamByName('almacen').AsString := ACodigoAlmacen;
    qry.ParamByName('numop').AsInteger := ANumOperacion;
    qry.ParamByName('serie').AsString := ASerie;
    qry.ParamByName('numfac').AsString := ANumFactura;
    qry.ExecSQL;
  finally
    qry.Free;
  end;
end;

end.
