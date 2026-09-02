{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataTraspaso                                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de la operativa de traspasos entre almacenes (TPV).           }
{    El traspaso ejecutado se graba SOLO en fza_caja_operaciones (TR/AT) +     }
{    fza_movimientos_almacen (par salida+entrada). Ver                         }
{    DESARROLLOS EN CURSO/traspasos_caja.md.                                   }
{******************************************************************************}
unit UniDataTraspaso;

interface

uses
  System.SysUtils, System.Classes, Data.DB, Datasnap.DBClient, Uni, MemDS,
  DBAccess, System.Math, System.StrUtils,
  UniDataValoresAutomaticosRepositorio,
  inLibContextoSesionIntf,
  inLibTraspasoOpePersistenciaIntf;

type
  // Modo de la operativa: traspaso directo, solicitud, atención o reposición.
  TModoTraspaso = (mtTraspaso, mtSolicitar, mtAtender, mtReposicion);

  // Validación de negocio (stock insuficiente, líneas incompletas, destino
  // sin elegir...). El formulario la captura y la muestra como aviso
  // El formulario informa del fallo; no debe llegar al error no controlado.
  EValidacionTraspaso = class(Exception);

  TContextoGrabacionTraspaso = record
    Empresa: string;
    AlmacenOrigen: string;
    AlmacenDestino: string;
    Caja: string;
    Usuario: string;
    EmpresaContra: string;
    EmpresaDestino: string;
    TipoDocumento: string;
    SerieDocumento: string;
    NumeroDocumento: string;
    Empleado: string;
    NumeroOperacion: string;
    FechaOperacion: TDateTime;
  end;

  TdmTraspaso = class(TDataModule)
    cdsCabecera: TClientDataSet;
    cdsLineas: TClientDataSet;
    dsCabecera: TDataSource;
    dsLineas: TDataSource;
    qryAux: TUniQuery;
    procedure DataModuleCreate(Sender: TObject);
  private
    FConexion: TUniConnection;
    FModo: TModoTraspaso;
    FContextoSesion: IContextoSesionAplicacion;
    function GetIdentidadSesion: TIdentidadSesion;
    procedure ConfigurarEstructuraCabecera;
    procedure ConfigurarEstructuraLineas;
    procedure DesempaquetarAtributosLinea(const ASku: string);
    procedure cdsLineasNewRecord(DataSet: TDataSet);
    function ObtenerEmpresaAlmacen(const AAlmacen: string): string;
    // Devuelve el articulo padre del SKU activo. Vacio si no existe.
    function ObtenerArticuloSku(const ASku: string): string;
    // Devuelve el articulo padre aunque el SKU historico este inactivo.
    function ObtenerArticuloSkuHistorico(const ASku: string): string;
    function ObtenerIdColorBasicoSolicitud(const AArticulo, AColor: string;
                             out AIdColorBasico: Integer): Boolean;
    function BuscarSkuTcActivoUnico(const AArticulo, ATalla: string;
                             AIdColorBasico: Integer): string;
    function ResolverSkuSolicitudActivo(const AArticulo,
                             ASkuSolicitado: string): string;
    // Recorre el cds antes de grabar/imprimir: descarta lineas en blanco
    // (sin articulo) y aborta con error si una linea tiene articulo pero el
    // SKU no esta cerrado (falta color/talla).
    procedure LimpiarLineasIncompletas;
    procedure ValidarLineasReposicionAuto;
    // Aborta (raise) si un traspaso directo pide mas unidades de las que hay
    // en el almacen origen. Las solicitudes usan el mismo detalle como aviso.
    procedure ValidarStockOrigen(const AAlmacenOrigen: string);
    // Serie del documento de traspaso (fza_empresas_series + fallback) y su
    // siguiente número (PRC_GET_NEXT_CONT_FACT_SERIE, como la factura).
    function ObtenerSerieDocumento(const AEmpresa, AAlmacen, ACaja,
                             ATipoDoc: string): string;
    function SiguienteNumeroDocumento(const ASerie, ATipoDoc, AEmpresa,
                             AUsuario: string): string;
    // Replica autocontenida de los helpers de UniDataCaja (privados allí).
    function SiguienteOpCaja(const AEmpresa, AAlmacen, ACaja,
                             AEmpleado: string): string;
    procedure InsertarMovimientoAlmacen(QryTrx: TUniQuery;
                             const ATipoDoc, ASerie, ANro, ALinea, AEmpresa,
                             AAlmacen, ACaja, AAlmacenContra, ATipoMov,
                             ASku: string; ACantidad: Double; ACoste: Currency;
                             const AUsuario: string;
                             const AAlmacenDoc: string = '';
                             const ANumOperacion: string = '';
                             const ACodCliente: string = '';
                             const ACodArticulo: string = '';
                             AFechaMovimiento: TDateTime = 0);
    procedure InsertarOperacionCaja(QryTrx: TUniQuery;
                             const AEmpresa, AAlmacen, ACaja, ANumOperacion,
                             ATipoOp: string; AImporte: Currency;
                             AFechaOperacion: TDateTime;
                             const AEmpleado, AConcepto, ASerieOrigen,
                             ANroOrigen, AEmpresaContra, AAlmContra,
                             AEsTraspaso, ANroDoc, ASerieDoc: string);
    // Suma lo servido a las líneas de la solicitud y recalcula su estado.
    procedure MarcarSolicitudAtendida(QryTrx: TUniQuery;
                             const ANumero, ASerie: string);
    function CrearContextoGrabacionTraspaso(
      const AAlmacenDestino: string): TContextoGrabacionTraspaso;
    function GrabarLineasTraspaso(
      QryTrx: TUniQuery;
      const AContexto: TContextoGrabacionTraspaso): Currency;
    procedure RegistrarOperacionTraspaso(
      QryTrx: TUniQuery;
      const AContexto: TContextoGrabacionTraspaso;
      ATotal: Currency;
      const ANumSolicitud, ASerieSolicitud: string);
    function EjecutarGrabacionTraspaso(
      var AContexto: TContextoGrabacionTraspaso;
      const ANumSolicitud, ASerieSolicitud: string;
      out ANumOperacion: string): Boolean;
    procedure InsertarCabeceraReposicionAuto(
      AConsulta: TUniQuery;
      const AAlmacenOrigen, ANumero, ASerie: string;
      const ADesde, AHasta: TDateTime);
    function InsertarLineasReposicionAuto(
      AConsulta: TUniQuery;
      const ANumero, ASerie: string): Integer;
    function TieneLineasReposicionPositivas: Boolean;
  public
    constructor Create(
      AOwner: TComponent;
      AConexion: TUniConnection); reintroduce;
    property IdentidadSesion: TIdentidadSesion read GetIdentidadSesion;
    property Modo: TModoTraspaso read FModo write FModo;
    procedure PrepararNuevo(AModo: TModoTraspaso; const AEmpresa, AAlmacen,
                            ACaja: string; AFecha: TDateTime);
    function ObtenerCosteMedio(const ASku, AAlmacen: string): Currency;
    function ObtenerStock(const ASku, AAlmacen: string): Double;
    // Devuelve el detalle de las lineas que superan el stock del almacen.
    // Vacio indica que todas disponen de stock suficiente.
    function ObtenerAvisoStockOrigen(const AAlmacenOrigen: string): string;
    // Graba el traspaso directo: par salida+entrada por línea + operación
    // de caja TR/AT, todo en una transacción. Devuelve el nº de operación.
    function GrabarTraspaso(const AAlmacenDestino: string;
                            out ANumOperacion: string;
                            const ANumSolicitud: string = '';
                            const ASerieSolicitud: string = ''): Boolean;
    // --- Ciclo de solicitudes (fza_traspasos_solicitudes) ---
    // Solicitar: graba la petición (origen = a quién pido) en estado
    // PENDIENTE, sin mover stock.
    function GrabarSolicitud(const AAlmacenOrigen: string;
                             out ANumero, ASerie: string): Boolean;
    procedure CargarVentasReposicion(
      const ALineas: TLineasVentaReposicion);
    function GrabarReposicionAuto(
      const AAlmacenOrigen: string;
      const ADesde, AHasta: TDateTime;
      out ANumero, ASerie: string): Boolean;
    // Atender: lista las solicitudes pendientes que me tocan (yo, origen).
    procedure CargarSolicitudesPendientes(AItems, ACodigos: TStrings);
    // Dataset para el modal de solicitudes abiertas. El llamante lo libera.
    function QuerySolicitudesAbiertas: TDataSet;
    // Historico de MIS peticiones (yo soy el destino que pide), todos los
    // estados, para saber si se han servido/denegado. El llamante lo libera.
    function QueryMisPeticiones(const APropio: string): TDataSet;
    // Detalle maestro/detalle de los articulos de una solicitud. El llamante
    // libera el dataset devuelto.
    function QueryLineasSolicitud(
      AMaestro: TDataSource): TDataSet;
    // Carga una solicitud pendiente en cabecera/líneas para servirla.
    function CargarSolicitud(const ANumero, ASerie: string): Boolean;
    // Cierra (estado CERRADA) la solicitud cargada aunque queden lineas sin
    // atender. Devuelve False si no hay solicitud cargada.
    function CerrarSolicitud: Boolean;
    // Resuelve la solicitud cargada sin mover stock (usa cdsLineas: CANTIDAD y
    // MOTIVO por linea). Denegacion total/parcial con motivo; no crea traspaso.
    function GrabarDenegacion: Boolean;
    // Valida el empleado responsable por su código o diminutivo de ticket.
    function ValidarEmpleado(const ABusqueda: string;
                             out ACodigo, ANombre: string): Boolean;
  end;

implementation

{$R *.dfm}

uses
  inLibMsgCaja,
  inLibPrestaShopColaSenal,
  UniDataMovimientosAlmacenRecalculo;

resourcestring
  SDetalleStockTraspasoInsuficiente =
    '  %s: pides %s, hay %s'#13#10;

constructor TdmTraspaso.Create(
  AOwner: TComponent;
  AConexion: TUniConnection);
var
  ProveedorContexto: IProveedorContextoSesion;
begin
  FConexion := AConexion;
  FContextoSesion := nil;
  if Supports(AOwner, IProveedorContextoSesion, ProveedorContexto) then
    FContextoSesion := ProveedorContexto.ContextoSesion;
  inherited Create(AOwner);
end;

function TdmTraspaso.GetIdentidadSesion: TIdentidadSesion;
begin
  if not Assigned(FContextoSesion) then
    raise Exception.Create(SErrorContextoSesionTraspasoNoConfigurado);
  Result := FContextoSesion.Identidad;
end;

procedure TdmTraspaso.DataModuleCreate(Sender: TObject);
begin
  qryAux.Connection := FConexion;
  ConfigurarEstructuraCabecera;
  ConfigurarEstructuraLineas;
  cdsLineas.OnNewRecord := cdsLineasNewRecord;
end;

procedure TdmTraspaso.ConfigurarEstructuraCabecera;
  procedure Add(const ANombre: string; ATipo: TFieldType;
    ATamano: Integer = 0; ARequerido: Boolean = False);
  begin
    cdsCabecera.FieldDefs.Add(ANombre, ATipo, ATamano, ARequerido);
  end;
begin
  if cdsCabecera.Active then
    cdsCabecera.Close;
  cdsCabecera.FieldDefs.Clear;
  cdsCabecera.IndexDefs.Clear;
  Add('CODIGO_EMP', ftString, 20);
    Add('CODIGO_ALM_ORIGEN', ftString, 10);
    Add('CODIGO_ALM_DESTINO', ftString, 10);
    Add('CODIGO_CAJA', ftString, 10);
    Add('CODIGO_EMPLEADO', ftString, 20);
    Add('NUMERO_SOL', ftString, 20);
    Add('SERIE_SOL', ftString, 20);
    Add('FECHA', ftDateTime, 0);
    Add('CONTADOR_LINEAS', ftInteger, 0);
  Add('TOTAL', ftCurrency, 0);
  cdsCabecera.CreateDataSet;
end;

procedure TdmTraspaso.ConfigurarEstructuraLineas;
  procedure Add(const ANombre: string; ATipo: TFieldType;
    ATamano: Integer = 0; ARequerido: Boolean = False);
  begin
    cdsLineas.FieldDefs.Add(ANombre, ATipo, ATamano, ARequerido);
  end;
begin
  if cdsLineas.Active then
    cdsLineas.Close;
  cdsLineas.FieldDefs.Clear;
  cdsLineas.IndexDefs.Clear;
  Add('LINEA', ftString, 4);
    Add('CODIGO_ART', ftString, 20);
    Add('CODIGO_UNIDAD', ftString, 50);
    Add('DESCRIPCION', ftString, 100);
    Add('NUM_ATRIBUTOS', ftInteger, 0);
    Add('ATTR1_VALOR', ftString, 50);
    Add('ATTR2_VALOR', ftString, 50);
    Add('ATTR3_VALOR', ftString, 50);
    Add('ATTR4_VALOR', ftString, 50);
    Add('ATTR5_VALOR', ftString, 50);
    Add('ATTR1_NOMBRE', ftString, 50);
    Add('ATTR2_NOMBRE', ftString, 50);
    Add('ATTR3_NOMBRE', ftString, 50);
    Add('ATTR4_NOMBRE', ftString, 50);
    Add('ATTR5_NOMBRE', ftString, 50);
    Add('CANTIDAD', ftFloat, 0);
    // CANTIDAD_PEDIDA: lo que se pidio (referencia al atender; CANTIDAD pasa a
    // ser lo que se sirve). MOTIVO: razon del rechazo si se deniega (sirve 0).
    Add('CANTIDAD_PEDIDA', ftFloat, 0);
    Add('PRECIO_COSTE', ftCurrency, 0);
    Add('TOTAL', ftCurrency, 0);
    Add('STOCK_ORIGEN', ftFloat, 0);
    Add('STOCK_DESTINO', ftFloat, 0);
    Add('CODIGO_PROVEEDOR', ftString, 20);
    Add('NOMBRE_PROVEEDOR', ftString, 200);
  Add('MOTIVO', ftString, 255);
  cdsLineas.CreateDataSet;
  cdsLineas.FieldByName('STOCK_DESTINO').Alignment := taCenter;
  cdsLineas.FieldByName('STOCK_ORIGEN').Alignment := taCenter;
end;

procedure TdmTraspaso.DesempaquetarAtributosLinea(const ASku: string);
var
  Partes: TArray<string>;
  i: Integer;
begin
  Partes := ASku.Split(['/']);
  cdsLineas.FieldByName('NUM_ATRIBUTOS').AsInteger := 0;
  for i := 1 to 5 do
    cdsLineas.FieldByName('ATTR' + IntToStr(i) + '_VALOR').AsString := '';
  if Length(Partes) > 1 then
  begin
    cdsLineas.FieldByName('NUM_ATRIBUTOS').AsInteger :=
      Min(Length(Partes) - 1, 5);
    for i := 1 to cdsLineas.FieldByName('NUM_ATRIBUTOS').AsInteger do
      cdsLineas.FieldByName('ATTR' + IntToStr(i) + '_VALOR').AsString :=
        Partes[i];
  end;
end;

procedure TdmTraspaso.cdsLineasNewRecord(DataSet: TDataSet);
begin
  DataSet.FieldByName('CANTIDAD').AsFloat := 1;
end;

procedure TdmTraspaso.PrepararNuevo(AModo: TModoTraspaso; const AEmpresa,
                                    AAlmacen, ACaja: string; AFecha: TDateTime);
begin
  FModo := AModo;
  ConfigurarEstructuraCabecera;
  ConfigurarEstructuraLineas;
  cdsCabecera.Append;
  cdsCabecera.FieldByName('CODIGO_EMP').AsString := AEmpresa;
  // En mtTraspaso el origen es el propio; en mtSolicitar se invierte (origen
  // será otro almacén y el propio pasa a destino) — se ajusta desde el form.
  cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString := AAlmacen;
  cdsCabecera.FieldByName('CODIGO_CAJA').AsString := ACaja;
  cdsCabecera.FieldByName('FECHA').AsDateTime := AFecha;
  cdsCabecera.FieldByName('CONTADOR_LINEAS').AsInteger := 0;
  cdsCabecera.FieldByName('TOTAL').AsCurrency := 0;
  cdsCabecera.Post;
end;

procedure TdmTraspaso.CargarVentasReposicion(
  const ALineas: TLineasVentaReposicion);
var
  iLinea: Integer;
begin
  ConfigurarEstructuraLineas;
  for iLinea := 0 to High(ALineas) do
  begin
    cdsLineas.Append;
    cdsLineas.FieldByName('LINEA').AsString :=
      Format('%.4d', [(iLinea + 1) * 10]);
    cdsLineas.FieldByName('CODIGO_ART').AsString :=
      ALineas[iLinea].CodigoArticulo;
    cdsLineas.FieldByName('CODIGO_UNIDAD').AsString :=
      ALineas[iLinea].Sku;
    DesempaquetarAtributosLinea(ALineas[iLinea].Sku);
    cdsLineas.FieldByName('DESCRIPCION').AsString :=
      ALineas[iLinea].Descripcion;
    cdsLineas.FieldByName('CANTIDAD').AsFloat :=
      ALineas[iLinea].APedir;
    cdsLineas.FieldByName('CANTIDAD_PEDIDA').AsFloat :=
      ALineas[iLinea].APedir;
    cdsLineas.FieldByName('STOCK_DESTINO').AsFloat :=
      ALineas[iLinea].StockDestino;
    cdsLineas.FieldByName('STOCK_ORIGEN').AsFloat :=
      ALineas[iLinea].StockOrigen;
    cdsLineas.FieldByName('CODIGO_PROVEEDOR').AsString :=
      ALineas[iLinea].CodigoProveedor;
    cdsLineas.FieldByName('NOMBRE_PROVEEDOR').AsString :=
      ALineas[iLinea].NombreProveedor;
    cdsLineas.Post;
  end;
  if cdsCabecera.State = dsBrowse then
    cdsCabecera.Edit;
  cdsCabecera.FieldByName('CONTADOR_LINEAS').AsInteger := Length(ALineas);
  cdsCabecera.Post;
end;

function TdmTraspaso.TieneLineasReposicionPositivas: Boolean;
begin
  Result := False;
  cdsLineas.First;
  while not cdsLineas.Eof and not Result do
  begin
    Result := cdsLineas.FieldByName('CANTIDAD').AsFloat > 0;
    if not Result then
      cdsLineas.Next;
  end;
end;

function TdmTraspaso.ObtenerEmpresaAlmacen(const AAlmacen: string): string;
begin
  qryAux.SQL.Text :=
    'SELECT CODIGO_EMP_ALM FROM fza_almacenes WHERE CODIGO_ALM_ALM = :ALM';
  qryAux.ParamByName('ALM').AsString := AAlmacen;
  qryAux.Open;
  try
    if qryAux.IsEmpty then
      Result := ''
    else
      Result := qryAux.FieldByName('CODIGO_EMP_ALM').AsString;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.ObtenerArticuloSku(const ASku: string): string;
begin
  // Un SKU es valido solo si existe (activo) en fza_articulos_skus. Asi se
  // bloquea grabar un SKU incompleto tipo 'ART/COLOR' al que le falta la talla
  // (existe 'ART/COLOR/TALLA' pero no 'ART/COLOR').
  qryAux.SQL.Text :=
    'SELECT CODIGO_ART_SKU FROM fza_articulos_skus' +
    ' WHERE CODIGO_UNIDAD_SKU = :SKU AND ESACTIVO_SKU = ''S'' LIMIT 1';
  qryAux.ParamByName('SKU').AsString := ASku;
  qryAux.Open;
  try
    if qryAux.IsEmpty then
      Result := ''
    else
      Result := qryAux.FieldByName('CODIGO_ART_SKU').AsString;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.ObtenerArticuloSkuHistorico(
  const ASku: string): string;
begin
  qryAux.SQL.Text :=
    'SELECT CODIGO_ART_SKU FROM fza_articulos_skus' +
    ' WHERE CODIGO_UNIDAD_SKU = :SKU LIMIT 1';
  qryAux.ParamByName('SKU').AsString := ASku;
  qryAux.Open;
  try
    if qryAux.IsEmpty then
      Result := ''
    else
      Result := qryAux.FieldByName('CODIGO_ART_SKU').AsString;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.ObtenerIdColorBasicoSolicitud(
  const AArticulo, AColor: string;
  out AIdColorBasico: Integer): Boolean;
var
  bInvalido: Boolean;
  iIdActual: Integer;
begin
  AIdColorBasico := 0;
  bInvalido := False;
  // El valor historico puede estar inactivo. Se conserva la prioridad de la
  // vista vi_atributos_sku_basico: articulo, conjunto y valor global.
  qryAux.SQL.Text :=
    'SELECT CASE' +
    '         WHEN AAB.CODIGO_ART_AAB IS NOT NULL THEN AAB.ID_ATB_AAB' +
    '         WHEN ACD.ID_ATB_ACD IS NOT NULL THEN ACD.ID_ATB_ACD' +
    '         ELSE AV.ID_ATB_AV' +
    '       END AS ID_ATB' +
    '  FROM fza_atributos_valores AV' +
    '  LEFT JOIN fza_articulos_atributos_basicos AAB' +
    '    ON AAB.CODIGO_ART_AAB = :ART' +
    '   AND AAB.ID_AV_AAB = AV.ID_AV' +
    '  LEFT JOIN fza_articulos_conjuntos_asign ACA' +
    '    ON ACA.CODIGO_ART_ACA = :ART' +
    '   AND ACA.ID_VA_ACA = AV.ID_VA_AV' +
    '  LEFT JOIN fza_atributos_conjuntos_det ACD' +
    '    ON ACD.ID_AC_ACD = ACA.ID_AC_ACA' +
    '   AND ACD.ID_AV_ACD = AV.ID_AV' +
    ' WHERE AV.ID_VA_AV = ''CO''' +
    '   AND TRIM(AV.AV) = :COLOR';
  qryAux.ParamByName('ART').AsString := AArticulo;
  qryAux.ParamByName('COLOR').AsString := AColor;
  qryAux.Open;
  try
    while not qryAux.Eof do
    begin
      if qryAux.FieldByName('ID_ATB').IsNull then
        bInvalido := True
      else
      begin
        iIdActual := qryAux.FieldByName('ID_ATB').AsInteger;
        if AIdColorBasico = 0 then
          AIdColorBasico := iIdActual
        else if AIdColorBasico <> iIdActual then
          bInvalido := True;
      end;
      qryAux.Next;
    end;
    Result := (AIdColorBasico > 0) and not bInvalido;
  finally
    qryAux.Close;
  end;
  if not Result then
    AIdColorBasico := 0;
end;

function TdmTraspaso.BuscarSkuTcActivoUnico(
  const AArticulo, ATalla: string;
  AIdColorBasico: Integer): string;
var
  iCandidatos: Integer;
  sCandidato: string;
begin
  Result := '';
  iCandidatos := 0;
  sCandidato := '';
  qryAux.SQL.Text :=
    'SELECT DISTINCT SK.CODIGO_UNIDAD_SKU' +
    '  FROM fza_articulos_skus SK' +
    '  JOIN vi_atributos_sku_basico C' +
    '    ON C.CODIGO_UNIDAD_SKU = SK.CODIGO_UNIDAD_SKU' +
    '   AND C.ID_VA_AV = ''CO''' +
    '  JOIN fza_atributos_valores CAV' +
    '    ON CAV.ID_AV = C.ID_AV AND CAV.ESACTIVO_AV = ''S''' +
    '  JOIN fza_atributos_basicos B' +
    '    ON B.ID_ATB = C.ID_ATB_AV AND B.ESACTIVO_ATB = ''S''' +
    '  JOIN vi_atributos_sku_basico T' +
    '    ON T.CODIGO_UNIDAD_SKU = SK.CODIGO_UNIDAD_SKU' +
    '   AND T.ID_VA_AV = ''TAL''' +
    '  JOIN fza_atributos_valores TAV' +
    '    ON TAV.ID_AV = T.ID_AV AND TAV.ESACTIVO_AV = ''S''' +
    ' WHERE SK.CODIGO_ART_SKU = :ART' +
    '   AND SK.CODIGO_VAR_SKU = ''TC''' +
    '   AND SK.ESACTIVO_SKU = ''S''' +
    '   AND C.ID_ATB_AV = :ID_COLOR' +
    '   AND TRIM(T.VALOR_AV) = :TALLA' +
    ' ORDER BY SK.CODIGO_UNIDAD_SKU' +
    ' LIMIT 2';
  qryAux.ParamByName('ART').AsString := AArticulo;
  qryAux.ParamByName('ID_COLOR').AsInteger := AIdColorBasico;
  qryAux.ParamByName('TALLA').AsString := ATalla;
  qryAux.Open;
  try
    while not qryAux.Eof do
    begin
      Inc(iCandidatos);
      if iCandidatos = 1 then
        sCandidato := qryAux.FieldByName('CODIGO_UNIDAD_SKU').AsString;
      qryAux.Next;
    end;
    if iCandidatos = 1 then
      Result := sCandidato;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.ResolverSkuSolicitudActivo(
  const AArticulo, ASkuSolicitado: string): string;
var
  Partes: TArray<string>;
  iIdColorBasico: Integer;
  sArticulo, sArticuloSku, sSku: string;
begin
  Result := '';
  sArticulo := Trim(AArticulo);
  sSku := Trim(ASkuSolicitado);
  sArticuloSku := ObtenerArticuloSku(sSku);
  if sArticuloSku <> '' then
  begin
    if SameText(sArticuloSku, sArticulo) then
      Result := sSku;
  end
  else
  begin
    Partes := sSku.Split(['/']);
    if (Length(Partes) = 3) and SameText(Trim(Partes[0]), sArticulo) and
       ObtenerIdColorBasicoSolicitud(sArticulo, Trim(Partes[1]),
                                     iIdColorBasico) then
      Result := BuscarSkuTcActivoUnico(sArticulo, Trim(Partes[2]),
                                       iIdColorBasico);
  end;
end;

procedure TdmTraspaso.LimpiarLineasIncompletas;
var
  sArt, sSku, sArtSku: string;
begin
  if cdsLineas.State in [dsEdit, dsInsert] then
    cdsLineas.Post;
  cdsLineas.First;
  while not cdsLineas.Eof do
  begin
    sArt := Trim(cdsLineas.FieldByName('CODIGO_ART').AsString);
    sSku := Trim(cdsLineas.FieldByName('CODIGO_UNIDAD').AsString);
    // Linea en blanco / fantasma (sin articulo): se descarta en silencio.
    if sArt = '' then
      cdsLineas.Delete
    // Articulo tecleado pero SKU sin cerrar (falta color/talla): es un intento
    // real, no se graba a medias -> avisamos y abortamos.
    else if sSku = '' then
      raise EValidacionTraspaso.CreateFmt(
        SErrorSkuTraspasoIncompleto, [sArt, sSku])
    else
    begin
      sArtSku := ObtenerArticuloSku(sSku);
      if sArtSku = '' then
        raise EValidacionTraspaso.CreateFmt(
          SErrorSkuTraspasoNoDisponible, [sSku, sArt])
      else if not SameText(sArt, sArtSku) then
        raise EValidacionTraspaso.CreateFmt(
          SErrorArticuloSkuTraspasoNoCoincide,
          [sArt, sSku, sArtSku])
      else
        cdsLineas.Next;
    end;
  end;
end;

procedure TdmTraspaso.ValidarLineasReposicionAuto;
var
  sArt, sSku, sArtSku: string;
begin
  if cdsLineas.State in [dsEdit, dsInsert] then
    cdsLineas.Post;
  cdsLineas.First;
  while not cdsLineas.Eof do
  begin
    sArt := Trim(cdsLineas.FieldByName('CODIGO_ART').AsString);
    sSku := Trim(cdsLineas.FieldByName('CODIGO_UNIDAD').AsString);
    // El alta manual puede dejar la fila nueva sin usar. No debe impedir
    // emitir las lineas completas que ya estaban cargadas.
    if sArt = '' then
      cdsLineas.Delete
    else
    begin
      if cdsLineas.FieldByName('CANTIDAD').AsFloat > 0 then
      begin
        if sSku = '' then
          raise EValidacionTraspaso.CreateFmt(
            SErrorSkuTraspasoIncompleto, [sArt, sSku]);
        sArtSku := ObtenerArticuloSkuHistorico(sSku);
        if sArtSku = '' then
          raise EValidacionTraspaso.CreateFmt(
            SErrorSkuTraspasoNoDisponible, [sSku, sArt])
        else if not SameText(sArt, sArtSku) then
          raise EValidacionTraspaso.CreateFmt(
            SErrorArticuloSkuTraspasoNoCoincide,
            [sArt, sSku, sArtSku]);
      end;
      cdsLineas.Next;
    end;
  end;
end;

function TdmTraspaso.ObtenerAvisoStockOrigen(
  const AAlmacenOrigen: string): string;
var
  sSku, sFalta: string;
  dCant, dStock: Double;
begin
  sFalta := '';
  if cdsLineas.State in [dsEdit, dsInsert] then
    cdsLineas.Post;
  cdsLineas.First;
  while not cdsLineas.Eof do
  begin
    sSku := Trim(cdsLineas.FieldByName('CODIGO_UNIDAD').AsString);
    if sSku <> '' then
    begin
      dCant := cdsLineas.FieldByName('CANTIDAD').AsFloat;
      dStock := ObtenerStock(sSku, AAlmacenOrigen);
      if dCant > dStock then
        sFalta := sFalta + Format(SDetalleStockTraspasoInsuficiente,
          [sSku, FormatFloat('0.###', dCant), FormatFloat('0.###', dStock)]);
    end;
    cdsLineas.Next;
  end;
  if sFalta <> '' then
    Result := Format(SErrorStockTraspasoInsuficiente,
      [AAlmacenOrigen, sFalta])
  else
    Result := '';
end;

procedure TdmTraspaso.ValidarStockOrigen(const AAlmacenOrigen: string);
var
  sAviso: string;
begin
  sAviso := ObtenerAvisoStockOrigen(AAlmacenOrigen);
  if sAviso <> '' then
    raise EValidacionTraspaso.Create(sAviso);
end;

function TdmTraspaso.ValidarEmpleado(const ABusqueda: string;
                                     out ACodigo, ANombre: string): Boolean;
begin
  Result := False;
  ACodigo := '';
  ANombre := '';
  qryAux.SQL.Text :=
    'SELECT CODIGO_EMPL, DIMINUTIVO_TICKET_EMPL FROM fza_empleados' +
    ' WHERE (CODIGO_EMPL = :BUS OR DIMINUTIVO_TICKET_EMPL = :BUS)' +
    '   AND ESACTIVO_EMPL = ''S'' LIMIT 1';
  qryAux.ParamByName('BUS').AsString := ABusqueda;
  qryAux.Open;
  try
    if not qryAux.IsEmpty then
    begin
      ACodigo := qryAux.FieldByName('CODIGO_EMPL').AsString;
      ANombre := qryAux.FieldByName('DIMINUTIVO_TICKET_EMPL').AsString;
      Result := True;
    end;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.ObtenerSerieDocumento(const AEmpresa, AAlmacen, ACaja,
                                           ATipoDoc: string): string;
begin
  // Serie configurada para este tipo de documento (prefiere la de la caja /
  // almacén; si no, la de empresa). Fallback: el propio tipo de documento.
  qryAux.SQL.Text :=
    'SELECT EMPSER FROM vi_empresas_series' +
    ' WHERE CODIGO_EMP_EMPSER = :EMP AND TIPO_DOC_EMPSER = :TIPO' +
    '   AND (CODIGO_ALM_EMPSER = :ALM OR CODIGO_ALM_EMPSER IS NULL' +
    '        OR CODIGO_ALM_EMPSER = '''')' +
    '   AND (CODIGO_CAJA_EMPSER = :CAJA OR CODIGO_CAJA_EMPSER IS NULL' +
    '        OR CODIGO_CAJA_EMPSER = '''')' +
    ' ORDER BY (CODIGO_CAJA_EMPSER = :CAJA) DESC,' +
    '          (CODIGO_ALM_EMPSER = :ALM) DESC LIMIT 1';
  qryAux.ParamByName('EMP').AsString := AEmpresa;
  qryAux.ParamByName('TIPO').AsString := ATipoDoc;
  qryAux.ParamByName('ALM').AsString := AAlmacen;
  qryAux.ParamByName('CAJA').AsString := ACaja;
  qryAux.Open;
  try
    if qryAux.IsEmpty then
      Result := ATipoDoc
    else
      Result := qryAux.FieldByName('EMPSER').AsString;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.SiguienteNumeroDocumento(const ASerie, ATipoDoc, AEmpresa,
                                              AUsuario: string): string;
var
  SpTrx: TUniStoredProc;
begin
  SpTrx := TUniStoredProc.Create(nil);
  try
    SpTrx.Connection := FConexion;
    SpTrx.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
    SpTrx.Prepare;
    SpTrx.ParamByName('pserie').AsString := ASerie;
    SpTrx.ParamByName('pTipoDoc').AsString := ATipoDoc;
    SpTrx.ParamByName('pEMPRESA_CONTADOR').AsString := AEmpresa;
    SpTrx.ParamByName('pUSUARIOMODIF').AsString := AUsuario;
    SpTrx.Execute;
    Result := SpTrx.ParamByName('pcont').AsString;
  finally
    FreeAndNil(SpTrx);
  end;
end;

function TdmTraspaso.ObtenerCosteMedio(const ASku, AAlmacen: string): Currency;
begin
  // El coste es el PMP almacenado (PRECIO_MEDIO_STK), igual que usa el SP
  // PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT para valorar la salida y que muestra
  // la ficha del articulo. NO se recalcula con VALOR_TOTAL_STK (que puede
  // estar a 0 aunque el PMP exista). Con varios lotes: media ponderada por
  // cantidad; si no hay stock pero hay PMP guardado, se toma ese (MAX).
  qryAux.SQL.Text :=
    'SELECT CASE WHEN SUM(CANTIDAD_STK) > 0' +
    '            THEN SUM(PRECIO_MEDIO_STK * CANTIDAD_STK)' +
    '                 / SUM(CANTIDAD_STK)' +
    '            ELSE MAX(PRECIO_MEDIO_STK) END AS PMP ' +
    '  FROM fza_articulos_stockactual ' +
    ' WHERE CODIGO_ALM_STK = :ALM AND CODIGO_UNIDAD_STK = :SKU';
  qryAux.ParamByName('ALM').AsString := AAlmacen;
  qryAux.ParamByName('SKU').AsString := ASku;
  qryAux.Open;
  try
    Result := qryAux.FieldByName('PMP').AsCurrency;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.ObtenerStock(const ASku, AAlmacen: string): Double;
begin
  // Suma de todos los lotes del SKU en el almacen.
  qryAux.SQL.Text :=
    'SELECT COALESCE(SUM(CANTIDAD_STK),0) AS STK ' +
    '  FROM fza_articulos_stockactual ' +
    ' WHERE CODIGO_ALM_STK = :ALM AND CODIGO_UNIDAD_STK = :SKU';
  qryAux.ParamByName('ALM').AsString := AAlmacen;
  qryAux.ParamByName('SKU').AsString := ASku;
  qryAux.Open;
  try
    Result := qryAux.FieldByName('STK').AsFloat;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.SiguienteOpCaja(const AEmpresa, AAlmacen, ACaja,
                                     AEmpleado: string): string;
var
  SpTrx: TUniStoredProc;
begin
  SpTrx := TUniStoredProc.Create(nil);
  try
    SpTrx.Connection := FConexion;
    SpTrx.StoredProcName := 'PRC_GET_NEXT_OP_CAJA';
    SpTrx.Params.CreateParam(ftString, 'pEmpresa', ptInput).AsString :=
      AEmpresa;
    SpTrx.Params.CreateParam(ftString, 'pAlmacen', ptInput).AsString :=
      AAlmacen;
    SpTrx.Params.CreateParam(ftString, 'pCaja', ptInput).AsString := ACaja;
    SpTrx.Params.CreateParam(ftString, 'pUsuario', ptInput).AsString :=
      AEmpleado;
    SpTrx.Params.CreateParam(ftString, 'pSerie', ptOutput).Size := 12;
    SpTrx.Params.CreateParam(ftString, 'pcont', ptOutput).Size := 20;
    SpTrx.Prepare;
    SpTrx.Execute;
    Result := SpTrx.ParamByName('pcont').AsString;
  finally
    FreeAndNil(SpTrx);
  end;
end;

function FechaCajaConHora(AFechaCaja: TDateTime): TDateTime;
begin
  if AFechaCaja > 0 then
    Result := AFechaCaja
  else
    Result := Now;
end;

procedure TdmTraspaso.InsertarMovimientoAlmacen(QryTrx: TUniQuery;
                          const ATipoDoc, ASerie, ANro, ALinea, AEmpresa,
                          AAlmacen, ACaja, AAlmacenContra, ATipoMov,
                          ASku: string; ACantidad: Double; ACoste: Currency;
                          const AUsuario: string; const AAlmacenDoc: string;
                          const ANumOperacion: string;
                          const ACodCliente: string;
                          const ACodArticulo: string;
                          AFechaMovimiento: TDateTime);
var
  uspMov: TUniStoredProc;
  QryFecha: TUniQuery;
  sNumeroMov: string;
begin
  sNumeroMov := ObtenerSiguienteContador(FConexion, 'MV',
    IdentidadSesion.Usuario);
  uspMov := TUniStoredProc.Create(nil);
  try
    uspMov.Connection := QryTrx.Connection;
    uspMov.StoredProcName := 'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT';
    uspMov.Prepare;
    uspMov.ParamByName('p_NUMERO_MOV').AsString := sNumeroMov;
    uspMov.ParamByName('p_TIPO_DOC_MOV').AsString := ATipoDoc;
    uspMov.ParamByName('p_SERIE_DOC_MOV').AsString := ASerie;
    uspMov.ParamByName('p_NRO_DOC_MOV').AsString := ANro;
    uspMov.ParamByName('p_LINEA_MOV').AsString := ALinea;
    uspMov.ParamByName('p_CODIGO_EMPRESA_MOV').AsString := AEmpresa;
    uspMov.ParamByName('p_CODIGO_ALMACEN_MOV').AsString := AAlmacen;
    uspMov.ParamByName('p_CODIGO_CAJA_DOC_MOV').AsString := ACaja;
    if Trim(AAlmacenContra) = '' then
      uspMov.ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').Clear
    else
      uspMov.ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').AsString :=
        AAlmacenContra;
    uspMov.ParamByName('p_CODIGO_UNIDAD_MOV').AsString := ASku;
    uspMov.ParamByName('p_TIPO_MOVIMIENTO_MOV').AsString := ATipoMov;
    uspMov.ParamByName('p_CANTIDAD_MOV').AsFloat := Abs(ACantidad);
    uspMov.ParamByName('p_PRECIO_MEDIO_MOV').AsCurrency := ACoste;
    uspMov.ParamByName('p_TOTAL_COSTE_MOV').AsCurrency :=
      ACoste * Abs(ACantidad);
    uspMov.ParamByName('p_USUARIO').AsString := AUsuario;
    uspMov.ParamByName('p_ALMACEN_DOC').AsString := AAlmacenDoc;
    uspMov.ParamByName('p_NUMOP_DOC').AsString := ANumOperacion;
    uspMov.ParamByName('p_CODCLIENTE').AsString := ACodCliente;
    uspMov.ParamByName('p_CODARTICULO').AsString := ACodArticulo;
    uspMov.Execute;
    if AFechaMovimiento > 0 then
    begin
      QryFecha := TUniQuery.Create(nil);
      try
        QryFecha.Connection := QryTrx.Connection;
        QryFecha.SQL.Text :=
          'UPDATE fza_movimientos_almacen ' +
          '   SET FECHA_MOV = :FECHA ' +
          ' WHERE NUMERO_MOV = :NUMERO';
        QryFecha.ParamByName('FECHA').AsDateTime :=
          FechaCajaConHora(AFechaMovimiento);
        QryFecha.ParamByName('NUMERO').AsString := sNumeroMov;
        QryFecha.Execute;
      finally
        FreeAndNil(QryFecha);
      end;
    end;
  finally
    FreeAndNil(uspMov);
  end;
end;

procedure TdmTraspaso.InsertarOperacionCaja(QryTrx: TUniQuery;
                          const AEmpresa, AAlmacen, ACaja, ANumOperacion,
                          ATipoOp: string; AImporte: Currency;
                          AFechaOperacion: TDateTime;
                          const AEmpleado, AConcepto, ASerieOrigen,
                          ANroOrigen, AEmpresaContra, AAlmContra,
                          AEsTraspaso, ANroDoc, ASerieDoc: string);
var
  dtFechaOperacion: TDateTime;
begin
  dtFechaOperacion := FechaCajaConHora(AFechaOperacion);
  QryTrx.SQL.Text :=
    'INSERT INTO fza_caja_operaciones (' +
    '  CODIGO_EMP_OPCAJA, CODIGO_ALM_OPCAJA, CODIGO_CAJA_OPCAJA,' +
    '  NUMERO_FAC_OPCAJA, SERIE_FAC_OPCAJA,' +
    '  NUMERO_OPERACION_OPCAJA, TIPO_OPERACION_OPCAJA, IMPORTE_TOTAL_OPCAJA,' +
    '  FECHA_OPERACION_OPCAJA, FECHA_OP_DIA_OPCAJA, CODIGO_EMPLEADO_OPCAJA,' +
    '  CONCEPTO_GASTO_INGRESO_OPCAJA, SERIE_REF_ORIGEN_OPCAJA,' +
    '  NUMERO_REF_ORIGEN_OPCAJA, CODIGO_EMP_CONTRA_OPCAJA,' +
    '  CODIGO_ALM_CONTRA_OPCAJA, ESTRASPASO_OPCAJA, ESTADO_DEVOLUCION_OPCAJA,' +
    '  USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA) ' +
    'VALUES (' +
    '  :EMP, :ALM, :CAJA,' +
    '  NULLIF(:NRODOC, ''''), NULLIF(:SERIEDOC, ''''),' +
    '  :NUMOP, :TIPOOP, :IMPORTE, :FECHAOP, :FECHADIA,' +
    '  :EMPLEADO, NULLIF(:CONCEPTO, ''''), NULLIF(:SERIEORIG, ''''),' +
    '  NULLIF(:NROORIG, ''''), NULLIF(:EMPCONTRA, ''''),' +
    '  NULLIF(:ALMCONTRA, ''''), :ESTRASPASO, ''N'',' +
    '  :USUARIO, :USUARIO, NOW())';
  QryTrx.ParamByName('EMP').AsString := AEmpresa;
  QryTrx.ParamByName('ALM').AsString := AAlmacen;
  QryTrx.ParamByName('CAJA').AsString := ACaja;
  QryTrx.ParamByName('NUMOP').AsString := ANumOperacion;
  QryTrx.ParamByName('TIPOOP').AsString := ATipoOp;
  QryTrx.ParamByName('IMPORTE').AsCurrency := AImporte;
  QryTrx.ParamByName('FECHAOP').AsDateTime := dtFechaOperacion;
  QryTrx.ParamByName('FECHADIA').AsDateTime := Trunc(dtFechaOperacion);
  QryTrx.ParamByName('EMPLEADO').AsString := AEmpleado;
  QryTrx.ParamByName('CONCEPTO').AsString := AConcepto;
  QryTrx.ParamByName('SERIEORIG').AsString := ASerieOrigen;
  QryTrx.ParamByName('NROORIG').AsString := ANroOrigen;
  QryTrx.ParamByName('EMPCONTRA').AsString := AEmpresaContra;
  QryTrx.ParamByName('ALMCONTRA').AsString := AAlmContra;
  QryTrx.ParamByName('ESTRASPASO').AsString := AEsTraspaso;
  QryTrx.ParamByName('NRODOC').AsString := ANroDoc;
  QryTrx.ParamByName('SERIEDOC').AsString := ASerieDoc;
  // Auditoría con el usuario logueado; el empleado responsable va en EMPLEADO.
  QryTrx.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
  QryTrx.Execute;
end;

function TdmTraspaso.CrearContextoGrabacionTraspaso(
  const AAlmacenDestino: string): TContextoGrabacionTraspaso;
begin
  Result.Empresa := cdsCabecera.FieldByName('CODIGO_EMP').AsString;
  Result.AlmacenOrigen := cdsCabecera.FieldByName(
    'CODIGO_ALM_ORIGEN').AsString;
  Result.AlmacenDestino := AAlmacenDestino;
  Result.Caja := cdsCabecera.FieldByName('CODIGO_CAJA').AsString;
  Result.Usuario := IdentidadSesion.Usuario;
  Result.Empleado := cdsCabecera.FieldByName(
    'CODIGO_EMPLEADO').AsString;
  Result.FechaOperacion := cdsCabecera.FieldByName('FECHA').AsDateTime;
  if SameText(Result.AlmacenOrigen, Result.AlmacenDestino) then
    raise EValidacionTraspaso.Create(SErrorAlmacenesTraspasoCoincidentes);
  Result.EmpresaContra := ObtenerEmpresaAlmacen(Result.AlmacenDestino);
  if (Result.EmpresaContra = '') or
     SameText(Result.EmpresaContra, Result.Empresa) then
    Result.TipoDocumento := 'TR'
  else
    Result.TipoDocumento := 'TA';
  if Trim(Result.EmpresaContra) <> '' then
    Result.EmpresaDestino := Result.EmpresaContra
  else
    Result.EmpresaDestino := Result.Empresa;
  Result.SerieDocumento := ObtenerSerieDocumento(Result.Empresa,
    Result.AlmacenOrigen, Result.Caja, Result.TipoDocumento);
  Result.NumeroDocumento := '';
  Result.NumeroOperacion := '';
end;

function TdmTraspaso.GrabarLineasTraspaso(
  QryTrx: TUniQuery;
  const AContexto: TContextoGrabacionTraspaso): Currency;
var
  sArticulo: string;
  sLinea: string;
  sSku: string;
  dCantidad: Double;
  cCoste: Currency;
  iLinea: Integer;
begin
  iLinea := 0;
  cdsLineas.First;
  while not cdsLineas.Eof do
  begin
    sSku := cdsLineas.FieldByName('CODIGO_UNIDAD').AsString;
    dCantidad := cdsLineas.FieldByName('CANTIDAD').AsFloat;
    if (Trim(sSku) <> '') and (dCantidad > 0) then
    begin
      Inc(iLinea, 10);
      sLinea := Format('%.4d', [iLinea]);
      sArticulo := cdsLineas.FieldByName('CODIGO_ART').AsString;
      cCoste := cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency;
      InsertarMovimientoAlmacen(QryTrx, AContexto.TipoDocumento,
        AContexto.SerieDocumento, AContexto.NumeroDocumento, sLinea,
        AContexto.Empresa, AContexto.AlmacenOrigen, AContexto.Caja,
        AContexto.AlmacenDestino, 'S', sSku, dCantidad, cCoste,
        AContexto.Usuario, AContexto.AlmacenOrigen,
        AContexto.NumeroOperacion, '', sArticulo,
        AContexto.FechaOperacion);
      InsertarMovimientoAlmacen(QryTrx, AContexto.TipoDocumento,
        AContexto.SerieDocumento, AContexto.NumeroDocumento, sLinea,
        AContexto.EmpresaDestino, AContexto.AlmacenDestino,
        AContexto.Caja, AContexto.AlmacenOrigen, 'E', sSku, dCantidad,
        cCoste, AContexto.Usuario, AContexto.AlmacenOrigen,
        AContexto.NumeroOperacion, '', sArticulo,
        AContexto.FechaOperacion);
    end;
    cdsLineas.Next;
  end;
  if iLinea = 0 then
    raise EValidacionTraspaso.Create(SErrorLineasTraspasoNoDisponibles);
  RecalcularMovimientosDocumento(FConexion, AContexto.TipoDocumento,
    AContexto.SerieDocumento, AContexto.NumeroDocumento);
  QryTrx.SQL.Text :=
    'SELECT IFNULL(SUM(TOTAL_COSTE_MOV), 0) AS TOTAL ' +
    '  FROM fza_movimientos_almacen ' +
    ' WHERE TIPO_DOC_MOV = :TIPO ' +
    '   AND SERIE_DOC_MOV = :SERIE ' +
    '   AND NUMERO_DOC_MOV = :NUMERO ' +
    '   AND TIPO_MOV = ''S''';
  QryTrx.ParamByName('TIPO').AsString := AContexto.TipoDocumento;
  QryTrx.ParamByName('SERIE').AsString := AContexto.SerieDocumento;
  QryTrx.ParamByName('NUMERO').AsString := AContexto.NumeroDocumento;
  QryTrx.Open;
  Result := QryTrx.FieldByName('TOTAL').AsCurrency;
  QryTrx.Close;
end;

procedure TdmTraspaso.RegistrarOperacionTraspaso(
  QryTrx: TUniQuery;
  const AContexto: TContextoGrabacionTraspaso;
  ATotal: Currency;
  const ANumSolicitud, ASerieSolicitud: string);
begin
  InsertarOperacionCaja(QryTrx, AContexto.Empresa,
    AContexto.AlmacenOrigen, AContexto.Caja, AContexto.NumeroOperacion,
    AContexto.TipoDocumento, ATotal, AContexto.FechaOperacion,
    AContexto.Empleado, 'Traspaso a ' + AContexto.AlmacenDestino,
    ASerieSolicitud, ANumSolicitud, AContexto.EmpresaContra,
    AContexto.AlmacenDestino, 'S', AContexto.NumeroDocumento,
    AContexto.SerieDocumento);
  if Trim(ANumSolicitud) <> '' then
    MarcarSolicitudAtendida(QryTrx, ANumSolicitud, ASerieSolicitud);
end;

function TdmTraspaso.EjecutarGrabacionTraspaso(
  var AContexto: TContextoGrabacionTraspaso;
  const ANumSolicitud, ASerieSolicitud: string;
  out ANumOperacion: string): Boolean;
var
  oConsulta: TUniQuery;
  cTotal: Currency;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    AContexto.NumeroOperacion := SiguienteOpCaja(AContexto.Empresa,
      AContexto.AlmacenOrigen, AContexto.Caja, AContexto.Usuario);
    ANumOperacion := AContexto.NumeroOperacion;
    AContexto.NumeroDocumento := SiguienteNumeroDocumento(
      AContexto.SerieDocumento, AContexto.TipoDocumento,
      AContexto.Empresa, AContexto.Usuario);
    FConexion.StartTransaction;
    try
      cTotal := GrabarLineasTraspaso(oConsulta, AContexto);
      RegistrarOperacionTraspaso(oConsulta, AContexto, cTotal,
        ANumSolicitud, ASerieSolicitud);
      FConexion.Commit;
      SolicitarProcesadoPrestaShop;
      Result := True;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmTraspaso.GrabarTraspaso(const AAlmacenDestino: string;
                                    out ANumOperacion: string;
                                    const ANumSolicitud: string;
                                    const ASerieSolicitud: string): Boolean;
var
  oContexto: TContextoGrabacionTraspaso;
begin
  LimpiarLineasIncompletas;
  if cdsLineas.IsEmpty then
    raise EValidacionTraspaso.Create(SErrorLineasTraspasoNoDisponibles);
  if Trim(AAlmacenDestino) = '' then
    raise EValidacionTraspaso.Create(
      SErrorAlmacenDestinoTraspasoNoSeleccionado);
  oContexto := CrearContextoGrabacionTraspaso(AAlmacenDestino);
  // Al atender una solicitud el stock insuficiente es solo una advertencia
  // de la pantalla. El traspaso directo conserva el bloqueo para evitar
  // negativos involuntarios.
  if Trim(ANumSolicitud) = '' then
    ValidarStockOrigen(oContexto.AlmacenOrigen);
  Result := EjecutarGrabacionTraspaso(oContexto, ANumSolicitud,
    ASerieSolicitud, ANumOperacion);
end;

procedure TdmTraspaso.MarcarSolicitudAtendida(QryTrx: TUniQuery;
                          const ANumero, ASerie: string);
var
  sUsuario: string;
begin
  sUsuario := IdentidadSesion.Usuario;
  // Resolucion por linea: registra lo servido (CANTIDAD) y, si se deniega
  // (servir 0), el motivo. CANTIDAD_SERVIDA suma; ESATENDIDA = 'S' cuando se
  // cubre lo pedido. El motivo solo se guarda en las lineas denegadas.
  cdsLineas.First;
  while not cdsLineas.Eof do
  begin
    if Trim(cdsLineas.FieldByName('LINEA').AsString) <> '' then
    begin
      QryTrx.SQL.Text :=
        'UPDATE fza_traspasos_solicitudes_lineas' +
        '   SET CANTIDAD_SERVIDA_TRSOLLIN =' +
        '         CANTIDAD_SERVIDA_TRSOLLIN + :SERV,' +
        '       ESATENDIDA_TRSOLLIN =' +
        '         IF(CANTIDAD_SERVIDA_TRSOLLIN + :SERV >=' +
        '            CANTIDAD_PEDIDA_TRSOLLIN, ''S'', ''N''),' +
        '       MOTIVO_RECHAZO_TRSOLLIN = IF(:SERV = 0, :MOT, NULL),' +
        '       USUARIO_MODIF = :USU' +
        ' WHERE NUMERO_TRSOL_TRSOLLIN = :NUM' +
        '   AND SERIE_TRSOL_TRSOLLIN = :SER' +
        '   AND LINEA_TRSOLLIN = :LIN';
      QryTrx.ParamByName('SERV').AsFloat :=
        cdsLineas.FieldByName('CANTIDAD').AsFloat;
      QryTrx.ParamByName('MOT').AsString :=
        cdsLineas.FieldByName('MOTIVO').AsString;
      QryTrx.ParamByName('USU').AsString := sUsuario;
      QryTrx.ParamByName('NUM').AsString := ANumero;
      QryTrx.ParamByName('SER').AsString := ASerie;
      QryTrx.ParamByName('LIN').AsString :=
        cdsLineas.FieldByName('LINEA').AsString;
      QryTrx.Execute;
      if QryTrx.RowsAffected <> 1 then
        raise EValidacionTraspaso.CreateFmt(
          SErrorLineaSolicitudTraspasoNoActualizada,
          [cdsLineas.FieldByName('LINEA').AsString, ANumero, ASerie]);
    end;
    cdsLineas.Next;
  end;
  // Estado de la cabecera segun el reparto servido/denegado por linea:
  //   todo servido (>0)  -> COMPLETADO TOTAL
  //   todo denegado (=0) -> DENEGADO TOTAL
  //   mezcla             -> COMPLETADO PARCIAL
  QryTrx.SQL.Text :=
    'UPDATE fza_traspasos_solicitudes' +
    '   SET ESTADO_TRSOL = CASE' +
    '         WHEN (SELECT COUNT(*)' +
    '                 FROM fza_traspasos_solicitudes_lineas L' +
    '                WHERE L.NUMERO_TRSOL_TRSOLLIN = :NUM' +
    '                  AND L.SERIE_TRSOL_TRSOLLIN = :SER' +
    '                  AND L.CANTIDAD_SERVIDA_TRSOLLIN > 0) = 0' +
    '           THEN ''DENEGADO TOTAL''' +
    '         WHEN (SELECT COUNT(*)' +
    '                 FROM fza_traspasos_solicitudes_lineas L' +
    '                WHERE L.NUMERO_TRSOL_TRSOLLIN = :NUM' +
    '                  AND L.SERIE_TRSOL_TRSOLLIN = :SER' +
    '                  AND L.CANTIDAD_SERVIDA_TRSOLLIN = 0) = 0' +
    '           THEN ''COMPLETADO TOTAL''' +
    '         ELSE ''COMPLETADO PARCIAL'' END,' +
    '       USUARIO_MODIF = :USU' +
    ' WHERE NUMERO_TRSOL = :NUM AND SERIE_TRSOL = :SER';
  QryTrx.ParamByName('NUM').AsString := ANumero;
  QryTrx.ParamByName('SER').AsString := ASerie;
  QryTrx.ParamByName('USU').AsString := sUsuario;
  QryTrx.Execute;
end;

procedure TdmTraspaso.InsertarCabeceraReposicionAuto(
  AConsulta: TUniQuery;
  const AAlmacenOrigen, ANumero, ASerie: string;
  const ADesde, AHasta: TDateTime);
var
  sAlmacenDestino: string;
begin
  sAlmacenDestino :=
    cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
  AConsulta.SQL.Text :=
    'INSERT INTO fza_traspasos_solicitudes (' +
    '  NUMERO_TRSOL, SERIE_TRSOL, FECHA_TRSOL, TIPO_TRSOL,' +
    '  ESTADO_TRSOL, CODIGO_EMP_TRSOL,' +
    '  CODIGO_ALM_ORIGEN_TRSOL, CODIGO_ALM_DESTINO_TRSOL,' +
    '  CODIGO_EMP_CONTRA_TRSOL, CODIGO_CAJA_TRSOL,' +
    '  CODIGO_EMPLEADO_TRSOL, INSTANTE_VENTAS_DESDE_TRSOL,' +
    '  INSTANTE_VENTAS_HASTA_TRSOL, USUARIO_ALTA,' +
    '  USUARIO_MODIF, INSTANTE_ALTA) ' +
    'VALUES (:NUM, :SER, CURRENT_TIMESTAMP, ''AUTO'', NULL, :EMP,' +
    '  :ORI, :DES, NULLIF(:EMPC, ''''), :CAJA, :EMPLE,' +
    '  :DESDE, :HASTA, :USU, :USU, NOW())';
  AConsulta.ParamByName('NUM').AsString := ANumero;
  AConsulta.ParamByName('SER').AsString := ASerie;
  AConsulta.ParamByName('EMP').AsString :=
    cdsCabecera.FieldByName('CODIGO_EMP').AsString;
  AConsulta.ParamByName('ORI').AsString := AAlmacenOrigen;
  AConsulta.ParamByName('DES').AsString := sAlmacenDestino;
  AConsulta.ParamByName('EMPC').AsString :=
    ObtenerEmpresaAlmacen(AAlmacenOrigen);
  AConsulta.ParamByName('CAJA').AsString :=
    cdsCabecera.FieldByName('CODIGO_CAJA').AsString;
  AConsulta.ParamByName('EMPLE').AsString :=
    cdsCabecera.FieldByName('CODIGO_EMPLEADO').AsString;
  AConsulta.ParamByName('DESDE').AsDateTime := ADesde;
  AConsulta.ParamByName('HASTA').AsDateTime := AHasta;
  AConsulta.ParamByName('USU').AsString := IdentidadSesion.Usuario;
  AConsulta.Execute;
end;

function TdmTraspaso.InsertarLineasReposicionAuto(
  AConsulta: TUniQuery;
  const ANumero, ASerie: string): Integer;
var
  iLinea: Integer;
begin
  iLinea := 0;
  cdsLineas.First;
  while not cdsLineas.Eof do
  begin
    if cdsLineas.FieldByName('CANTIDAD').AsFloat > 0 then
    begin
      Inc(iLinea, 10);
      AConsulta.SQL.Text :=
        'INSERT INTO fza_traspasos_solicitudes_lineas (' +
        '  NUMERO_TRSOL_TRSOLLIN, SERIE_TRSOL_TRSOLLIN,' +
        '  LINEA_TRSOLLIN, CODIGO_ART_TRSOLLIN,' +
        '  CODIGO_UNIDAD_TRSOLLIN, DESCRIPCION_ARTICULO_TRSOLLIN,' +
        '  CANTIDAD_PEDIDA_TRSOLLIN, CANTIDAD_SERVIDA_TRSOLLIN,' +
        '  ESATENDIDA_TRSOLLIN, CODIGO_PRV_TRSOLLIN,' +
        '  RAZON_SOCIAL_PRV_TRSOLLIN, USUARIO_ALTA,' +
        '  USUARIO_MODIF, INSTANTE_ALTA) ' +
        'VALUES (:NUM, :SER, :LIN, :ART, :SKU, :DESC, :CANT, 0,' +
        '  ''N'', NULLIF(:PRV, ''''), NULLIF(:NOMPRV, ''''),' +
        '  :USU, :USU, NOW())';
      AConsulta.ParamByName('NUM').AsString := ANumero;
      AConsulta.ParamByName('SER').AsString := ASerie;
      AConsulta.ParamByName('LIN').AsString := Format('%.4d', [iLinea]);
      AConsulta.ParamByName('ART').AsString :=
        cdsLineas.FieldByName('CODIGO_ART').AsString;
      AConsulta.ParamByName('SKU').AsString :=
        cdsLineas.FieldByName('CODIGO_UNIDAD').AsString;
      AConsulta.ParamByName('DESC').AsString :=
        cdsLineas.FieldByName('DESCRIPCION').AsString;
      AConsulta.ParamByName('CANT').AsFloat :=
        cdsLineas.FieldByName('CANTIDAD').AsFloat;
      AConsulta.ParamByName('PRV').AsString :=
        cdsLineas.FieldByName('CODIGO_PROVEEDOR').AsString;
      AConsulta.ParamByName('NOMPRV').AsString :=
        cdsLineas.FieldByName('NOMBRE_PROVEEDOR').AsString;
      AConsulta.ParamByName('USU').AsString := IdentidadSesion.Usuario;
      AConsulta.Execute;
    end;
    cdsLineas.Next;
  end;
  Result := iLinea div 10;
end;

function TdmTraspaso.GrabarReposicionAuto(
  const AAlmacenOrigen: string;
  const ADesde, AHasta: TDateTime;
  out ANumero, ASerie: string): Boolean;
var
  oConsulta: TUniQuery;
  sAlmacenDestino: string;
begin
  ValidarLineasReposicionAuto;
  if ADesde >= AHasta then
    raise EValidacionTraspaso.Create(
      SErrorRangoVentasReposicionNoValido);
  if cdsLineas.IsEmpty then
    raise EValidacionTraspaso.Create(
      SErrorLineasSolicitudTraspasoNoDisponibles);
  if not TieneLineasReposicionPositivas then
    raise EValidacionTraspaso.Create(
      SErrorLineasSolicitudTraspasoNoDisponibles);
  if Trim(AAlmacenOrigen) = '' then
    raise EValidacionTraspaso.Create(
      SErrorAlmacenOrigenSolicitudNoSeleccionado);
  sAlmacenDestino :=
    cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
  if SameText(sAlmacenDestino, AAlmacenOrigen) then
    raise EValidacionTraspaso.Create(SErrorSolicitudTraspasoMismoAlmacen);
  ANumero := ObtenerSiguienteContador(
    FConexion, 'TS', IdentidadSesion.Usuario);
  ASerie := 'TS';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    FConexion.StartTransaction;
    try
      InsertarCabeceraReposicionAuto(
        oConsulta, AAlmacenOrigen, ANumero, ASerie, ADesde, AHasta);
      if InsertarLineasReposicionAuto(
        oConsulta, ANumero, ASerie) = 0 then
        raise EValidacionTraspaso.Create(
          SErrorLineasSolicitudTraspasoNoDisponibles);
      FConexion.Commit;
      Result := True;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmTraspaso.GrabarSolicitud(const AAlmacenOrigen: string;
                                     out ANumero, ASerie: string): Boolean;
var
  QryTrx: TUniQuery;
  sEmpresa, sAlmacenPropio, sCaja, sUsuario, sEmpContra, sLinea,
  sEmpleado: string;
  iLinea: Integer;
begin
  // Quita la linea en blanco y la fantasma antes de grabar la solicitud.
  LimpiarLineasIncompletas;
  if cdsLineas.IsEmpty then
    raise EValidacionTraspaso.Create(
      SErrorLineasSolicitudTraspasoNoDisponibles);
  if Trim(AAlmacenOrigen) = '' then
    raise EValidacionTraspaso.Create(
      SErrorAlmacenOrigenSolicitudNoSeleccionado);
  sEmpresa := cdsCabecera.FieldByName('CODIGO_EMP').AsString;
  // En mtSolicitar el propio (CODIGO_ALM_ORIGEN) es el DESTINO de la petición.
  sAlmacenPropio := cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
  sCaja := cdsCabecera.FieldByName('CODIGO_CAJA').AsString;
  sUsuario := IdentidadSesion.Usuario;
  sEmpleado := cdsCabecera.FieldByName('CODIGO_EMPLEADO').AsString;
  if SameText(sAlmacenPropio, AAlmacenOrigen) then
    raise EValidacionTraspaso.Create(SErrorSolicitudTraspasoMismoAlmacen);
  sEmpContra := ObtenerEmpresaAlmacen(AAlmacenOrigen);
  ANumero := ObtenerSiguienteContador(FConexion, 'TS',
    IdentidadSesion.Usuario);
  ASerie := 'TS';
  QryTrx := TUniQuery.Create(nil);
  try
    QryTrx.Connection := FConexion;
    FConexion.StartTransaction;
    try
      QryTrx.SQL.Text :=
        'INSERT INTO fza_traspasos_solicitudes (' +
        '  NUMERO_TRSOL, SERIE_TRSOL, FECHA_TRSOL, ESTADO_TRSOL,' +
        '  CODIGO_EMP_TRSOL, CODIGO_ALM_ORIGEN_TRSOL,' +
        '  CODIGO_ALM_DESTINO_TRSOL, CODIGO_EMP_CONTRA_TRSOL,' +
        '  CODIGO_CAJA_TRSOL, CODIGO_EMPLEADO_TRSOL,' +
        '  USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA) ' +
        'VALUES (:NUM, :SER, CURRENT_TIMESTAMP, ''PENDIENTE'', :EMP, :ORI,' +
        '  :DES,' +
        '  NULLIF(:EMPC, ''''), :CAJA, :EMPLE, :USU, :USU, NOW())';
      QryTrx.ParamByName('NUM').AsString := ANumero;
      QryTrx.ParamByName('SER').AsString := ASerie;
      QryTrx.ParamByName('EMP').AsString := sEmpresa;
      QryTrx.ParamByName('ORI').AsString := AAlmacenOrigen;
      QryTrx.ParamByName('DES').AsString := sAlmacenPropio;
      QryTrx.ParamByName('EMPC').AsString := sEmpContra;
      QryTrx.ParamByName('CAJA').AsString := sCaja;
      QryTrx.ParamByName('EMPLE').AsString := sEmpleado;
      QryTrx.ParamByName('USU').AsString := sUsuario;
      QryTrx.Execute;
      iLinea := 0;
      cdsLineas.First;
      while not cdsLineas.Eof do
      begin
        // Salta la linea en blanco de entrada del grid.
        if Trim(cdsLineas.FieldByName('CODIGO_UNIDAD').AsString) <> '' then
        begin
          iLinea := iLinea + 10;
          sLinea := Format('%.4d', [iLinea]);
          QryTrx.SQL.Text :=
            'INSERT INTO fza_traspasos_solicitudes_lineas (' +
            '  NUMERO_TRSOL_TRSOLLIN, SERIE_TRSOL_TRSOLLIN, LINEA_TRSOLLIN,' +
            '  CODIGO_ART_TRSOLLIN, CODIGO_UNIDAD_TRSOLLIN,' +
            '  DESCRIPCION_ARTICULO_TRSOLLIN, CANTIDAD_PEDIDA_TRSOLLIN,' +
            '  CANTIDAD_SERVIDA_TRSOLLIN, ESATENDIDA_TRSOLLIN,' +
            '  USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA) ' +
            'VALUES (:NUM, :SER, :LIN, :ART, :SKU, :DESC, :CANT, 0, ''N'',' +
            '  :USU, :USU, NOW())';
          QryTrx.ParamByName('NUM').AsString := ANumero;
          QryTrx.ParamByName('SER').AsString := ASerie;
          QryTrx.ParamByName('LIN').AsString := sLinea;
          QryTrx.ParamByName('ART').AsString :=
            cdsLineas.FieldByName('CODIGO_ART').AsString;
          QryTrx.ParamByName('SKU').AsString :=
            cdsLineas.FieldByName('CODIGO_UNIDAD').AsString;
          QryTrx.ParamByName('DESC').AsString :=
            cdsLineas.FieldByName('DESCRIPCION').AsString;
          QryTrx.ParamByName('CANT').AsFloat :=
            cdsLineas.FieldByName('CANTIDAD').AsFloat;
          QryTrx.ParamByName('USU').AsString := sUsuario;
          QryTrx.Execute;
        end;
        cdsLineas.Next;
      end;
      if iLinea = 0 then
        raise EValidacionTraspaso.Create(
          SErrorLineasSolicitudTraspasoNoDisponibles);
      FConexion.Commit;
      Result := True;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(QryTrx);
  end;
end;

procedure TdmTraspaso.CargarSolicitudesPendientes(AItems, ACodigos: TStrings);
var
  sPropio: string;
begin
  AItems.Clear;
  ACodigos.Clear;
  sPropio := cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
  qryAux.SQL.Text :=
    'SELECT S.NUMERO_TRSOL, S.SERIE_TRSOL, S.ESTADO_TRSOL,' +
    '       S.CODIGO_ALM_DESTINO_TRSOL,' +
    '       (SELECT COUNT(*) FROM fza_traspasos_solicitudes_lineas L' +
    '         WHERE L.NUMERO_TRSOL_TRSOLLIN = S.NUMERO_TRSOL' +
    '           AND L.SERIE_TRSOL_TRSOLLIN = S.SERIE_TRSOL' +
    '           AND L.ESATENDIDA_TRSOLLIN = ''N'') AS NLIN' +
    '  FROM fza_traspasos_solicitudes S' +
    ' WHERE S.CODIGO_ALM_ORIGEN_TRSOL = :PROPIO' +
    '   AND S.ESTADO_TRSOL = ''PENDIENTE''' +
    ' ORDER BY S.FECHA_TRSOL, S.NUMERO_TRSOL';
  qryAux.ParamByName('PROPIO').AsString := sPropio;
  qryAux.Open;
  try
    while not qryAux.Eof do
    begin
      AItems.Add(Format('%s/%s  ->  %s  ·  %d líneas  ·  %s',
        [qryAux.FieldByName('SERIE_TRSOL').AsString,
         qryAux.FieldByName('NUMERO_TRSOL').AsString,
         qryAux.FieldByName('CODIGO_ALM_DESTINO_TRSOL').AsString,
         qryAux.FieldByName('NLIN').AsInteger,
         qryAux.FieldByName('ESTADO_TRSOL').AsString]));
      ACodigos.Add(qryAux.FieldByName('NUMERO_TRSOL').AsString + '|' +
                   qryAux.FieldByName('SERIE_TRSOL').AsString);
      qryAux.Next;
    end;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.QuerySolicitudesAbiertas: TDataSet;
var
  oConsulta: TUniQuery;
  sPropio: string;
begin
  // Solicitudes ABIERTAS (PENDIENTE) que me tocan a mi (yo soy el origen al que
  // se pide). Una vez resueltas (COMPLETADO/DENEGADO/CERRADA) no vuelven a
  // salir. Cada fila lleva el resumen para el modal y el NUMERO/SERIE.
  sPropio := cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
  oConsulta := TUniQuery.Create(nil);
  oConsulta.Connection := FConexion;
  // Devolvemos los nombres reales de columna (sin alias) para que el
  // formateador (fza_config_campos) ponga los titulos, igual
  // que el resto de buscadores. El conteo de lineas pendientes es calculado,
  // con sufijo de la tabla para poder titularlo en config.
  oConsulta.SQL.Text :=
    'SELECT S.NUMERO_TRSOL, S.SERIE_TRSOL, S.FECHA_TRSOL,' +
    '       S.CODIGO_ALM_DESTINO_TRSOL, S.ESTADO_TRSOL,' +
    '       (SELECT COUNT(*) FROM fza_traspasos_solicitudes_lineas L' +
    '         WHERE L.NUMERO_TRSOL_TRSOLLIN = S.NUMERO_TRSOL' +
    '           AND L.SERIE_TRSOL_TRSOLLIN = S.SERIE_TRSOL' +
    '           AND L.ESATENDIDA_TRSOLLIN = ''N'') AS LINEAS_PEND_TRSOL' +
    '  FROM fza_traspasos_solicitudes S' +
    ' WHERE S.CODIGO_ALM_ORIGEN_TRSOL = :PROPIO' +
    '   AND S.ESTADO_TRSOL = ''PENDIENTE''' +
    ' ORDER BY S.FECHA_TRSOL, S.NUMERO_TRSOL';
  oConsulta.ParamByName('PROPIO').AsString := sPropio;
  Result := oConsulta;
end;

function TdmTraspaso.QueryMisPeticiones(
  const APropio: string): TDataSet;
var
  oConsulta: TUniQuery;
begin
  // Historico de MIS peticiones: yo soy el DESTINO que pidio. Salen TODOS los
  // estados (PENDIENTE / COMPLETADO TOTAL / COMPLETADO PARCIAL / DENEGADO TOTAL
  // / CERRADA) para saber si se han servido o denegado. Devolvemos los nombres
  // reales de columna (sin alias)
  // para que el formateador (fza_config_campos) ponga los titulos; el origen
  // es a quien pedi. El llamante libera el query.
  oConsulta := TUniQuery.Create(nil);
  oConsulta.Connection := FConexion;
  oConsulta.SQL.Text :=
    'SELECT S.NUMERO_TRSOL, S.SERIE_TRSOL, S.FECHA_TRSOL,' +
    '       S.CODIGO_ALM_ORIGEN_TRSOL, S.TIPO_TRSOL,' +
    '       S.ESTADO_TRSOL,' +
    '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN 0 ELSE' +
    '       (SELECT COUNT(*) FROM fza_traspasos_solicitudes_lineas L' +
    '         WHERE L.NUMERO_TRSOL_TRSOLLIN = S.NUMERO_TRSOL' +
    '           AND L.SERIE_TRSOL_TRSOLLIN = S.SERIE_TRSOL' +
    '           AND COALESCE(L.ESATENDIDA_TRSOLLIN, ''N'') <> ''S''' +
    '           AND NULLIF(TRIM(' +
    '               L.MOTIVO_RECHAZO_TRSOLLIN), '''') IS NULL)' +
    '       END' +
    '         AS LINEAS_PEND_TRSOL' +
    '  FROM fza_traspasos_solicitudes S' +
    ' WHERE S.CODIGO_ALM_DESTINO_TRSOL = :PROPIO' +
    ' ORDER BY S.FECHA_TRSOL DESC, S.NUMERO_TRSOL DESC';
  oConsulta.ParamByName('PROPIO').AsString := APropio;
  Result := oConsulta;
end;

function TdmTraspaso.QueryLineasSolicitud(
  AMaestro: TDataSource): TDataSet;
var
  oConsulta: TUniQuery;
begin
  if not Assigned(AMaestro) then
    raise EArgumentNilException.Create('AMaestro');
  if not Assigned(AMaestro.DataSet) then
    raise EArgumentNilException.Create('AMaestro.DataSet');
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT L.NUMERO_TRSOL_TRSOLLIN,' +
      '       L.SERIE_TRSOL_TRSOLLIN,' +
      '       L.LINEA_TRSOLLIN,' +
      '       L.CODIGO_ART_TRSOLLIN,' +
      '       L.CODIGO_UNIDAD_TRSOLLIN,' +
      '       COALESCE(NULLIF(TRIM(' +
      '         L.DESCRIPCION_ARTICULO_TRSOLLIN), ''''),' +
      '         A.DESCRIPCION_ART, '''') AS DESCRIPCION_ART,' +
      '       L.CANTIDAD_PEDIDA_TRSOLLIN,' +
      '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN 0 ELSE' +
      '         L.CANTIDAD_SERVIDA_TRSOLLIN END' +
      '         AS CANTIDAD_SERVIDA_TRSOLLIN,' +
      '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN 0 ELSE GREATEST(' +
      '         COALESCE(L.CANTIDAD_PEDIDA_TRSOLLIN, 0) -' +
      '         COALESCE(L.CANTIDAD_SERVIDA_TRSOLLIN, 0), 0) END' +
      '         AS CANTIDAD_PENDIENTE_TRSOLLIN,' +
      '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN NULL ELSE' +
      '         L.ESATENDIDA_TRSOLLIN END AS ESATENDIDA_TRSOLLIN,' +
      '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN NULL ELSE' +
      '         L.MOTIVO_RECHAZO_TRSOLLIN END' +
      '         AS MOTIVO_RECHAZO_TRSOLLIN,' +
      '       L.CODIGO_PRV_TRSOLLIN,' +
      '       L.RAZON_SOCIAL_PRV_TRSOLLIN' +
      '  FROM fza_traspasos_solicitudes_lineas L' +
      '  JOIN fza_traspasos_solicitudes S' +
      '    ON S.NUMERO_TRSOL = L.NUMERO_TRSOL_TRSOLLIN' +
      '   AND S.SERIE_TRSOL = L.SERIE_TRSOL_TRSOLLIN' +
      '  LEFT JOIN fza_articulos A' +
      '    ON A.CODIGO_ART_ART = L.CODIGO_ART_TRSOLLIN' +
      ' WHERE L.NUMERO_TRSOL_TRSOLLIN = :NUMERO_TRSOL' +
      '   AND L.SERIE_TRSOL_TRSOLLIN = :SERIE_TRSOL' +
      ' ORDER BY L.LINEA_TRSOLLIN';
    oConsulta.MasterFields := 'NUMERO_TRSOL;SERIE_TRSOL';
    oConsulta.DetailFields :=
      'NUMERO_TRSOL_TRSOLLIN;SERIE_TRSOL_TRSOLLIN';
    oConsulta.MasterSource := AMaestro;
    oConsulta.ReadOnly := True;
    Result := oConsulta;
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function TdmTraspaso.CerrarSolicitud: Boolean;
var
  sNum, sSer: string;
begin
  // Cierra la solicitud cargada (CERRADA) aunque queden lineas sin servir.
  sNum := cdsCabecera.FieldByName('NUMERO_SOL').AsString;
  sSer := cdsCabecera.FieldByName('SERIE_SOL').AsString;
  Result := False;
  if (Trim(sNum) <> '') and (Trim(sSer) <> '') then
  begin
    qryAux.SQL.Text :=
      'UPDATE fza_traspasos_solicitudes' +
      '   SET ESTADO_TRSOL = ''CERRADA'', USUARIO_MODIF = :USU' +
      ' WHERE NUMERO_TRSOL = :NUM AND SERIE_TRSOL = :SER';
    qryAux.ParamByName('USU').AsString := IdentidadSesion.Usuario;
    qryAux.ParamByName('NUM').AsString := sNum;
    qryAux.ParamByName('SER').AsString := sSer;
    qryAux.ExecSQL;
    Result := True;
  end;
end;

function TdmTraspaso.GrabarDenegacion: Boolean;
var
  QryTrx: TUniQuery;
  sNum, sSer: string;
begin
  // Resuelve la solicitud cargada SIN movimiento de stock, usando lo que haya
  // en cdsLineas (CANTIDAD por linea y MOTIVO). Si todo va a 0 el estado queda
  // DENEGADO TOTAL; si alguna lleva cantidad, COMPLETADO TOTAL/PARCIAL. Lo usa
  // el atender cuando no se sirve nada (denegacion total con motivo por linea).
  sNum := cdsCabecera.FieldByName('NUMERO_SOL').AsString;
  sSer := cdsCabecera.FieldByName('SERIE_SOL').AsString;
  if (Trim(sNum) = '') or (Trim(sSer) = '') then
    raise EValidacionTraspaso.Create(SErrorSolicitudTraspasoNoCargada);
  QryTrx := TUniQuery.Create(nil);
  try
    QryTrx.Connection := FConexion;
    FConexion.StartTransaction;
    try
      MarcarSolicitudAtendida(QryTrx, sNum, sSer);
      FConexion.Commit;
      Result := True;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(QryTrx);
  end;
end;

function TdmTraspaso.CargarSolicitud(const ANumero, ASerie: string): Boolean;
var
  bExiste: Boolean;
  sPropio, sSkuActivo, sSkuSolicitado, sSolicitante: string;
begin
  sPropio := '';
  sSolicitante := '';
  qryAux.SQL.Text :=
    'SELECT CODIGO_ALM_ORIGEN_TRSOL, CODIGO_ALM_DESTINO_TRSOL' +
    '  FROM fza_traspasos_solicitudes' +
    ' WHERE NUMERO_TRSOL = :NUM AND SERIE_TRSOL = :SER';
  qryAux.ParamByName('NUM').AsString := ANumero;
  qryAux.ParamByName('SER').AsString := ASerie;
  qryAux.Open;
  try
    bExiste := not qryAux.IsEmpty;
    if bExiste then
    begin
      sPropio := qryAux.FieldByName('CODIGO_ALM_ORIGEN_TRSOL').AsString;
      sSolicitante := qryAux.FieldByName('CODIGO_ALM_DESTINO_TRSOL').AsString;
    end;
  finally
    qryAux.Close;
  end;
  Result := bExiste;
  if bExiste then
  begin
    ConfigurarEstructuraLineas;
    if cdsCabecera.State = dsBrowse then
      cdsCabecera.Edit;
    cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString := sPropio;
    cdsCabecera.FieldByName('CODIGO_ALM_DESTINO').AsString := sSolicitante;
    cdsCabecera.FieldByName('NUMERO_SOL').AsString := ANumero;
    cdsCabecera.FieldByName('SERIE_SOL').AsString := ASerie;
    cdsCabecera.Post;
    // Pase 1: volcar SKU/uds pendientes (qryAux ocupado, sin coste todavía).
    qryAux.SQL.Text :=
      'SELECT LINEA_TRSOLLIN, CODIGO_ART_TRSOLLIN,' +
      '       CODIGO_UNIDAD_TRSOLLIN,' +
      '       DESCRIPCION_ARTICULO_TRSOLLIN,' +
      '       (CANTIDAD_PEDIDA_TRSOLLIN -' +
      '        CANTIDAD_SERVIDA_TRSOLLIN) AS PENDIENTE' +
      '  FROM fza_traspasos_solicitudes_lineas' +
      ' WHERE NUMERO_TRSOL_TRSOLLIN = :NUM' +
      '   AND SERIE_TRSOL_TRSOLLIN = :SER' +
      '   AND (CANTIDAD_PEDIDA_TRSOLLIN -' +
      '        CANTIDAD_SERVIDA_TRSOLLIN) > 0' +
      ' ORDER BY LINEA_TRSOLLIN';
    qryAux.ParamByName('NUM').AsString := ANumero;
    qryAux.ParamByName('SER').AsString := ASerie;
    qryAux.Open;
    try
      while not qryAux.Eof do
      begin
        cdsLineas.Append;
        cdsLineas.FieldByName('LINEA').AsString :=
          qryAux.FieldByName('LINEA_TRSOLLIN').AsString;
        cdsLineas.FieldByName('CODIGO_ART').AsString :=
          qryAux.FieldByName('CODIGO_ART_TRSOLLIN').AsString;
        cdsLineas.FieldByName('CODIGO_UNIDAD').AsString :=
          qryAux.FieldByName('CODIGO_UNIDAD_TRSOLLIN').AsString;
        DesempaquetarAtributosLinea(
          qryAux.FieldByName('CODIGO_UNIDAD_TRSOLLIN').AsString);
        cdsLineas.FieldByName('DESCRIPCION').AsString :=
          qryAux.FieldByName('DESCRIPCION_ARTICULO_TRSOLLIN').AsString;
        cdsLineas.FieldByName('CANTIDAD').AsFloat :=
          qryAux.FieldByName('PENDIENTE').AsFloat;
        // Lo pendiente es lo que se ofrece servir; el que atiende baja CANTIDAD
        // (o la deja en 0 para denegar, indicando MOTIVO).
        cdsLineas.FieldByName('CANTIDAD_PEDIDA').AsFloat :=
          qryAux.FieldByName('PENDIENTE').AsFloat;
        cdsLineas.FieldByName('MOTIVO').AsString := '';
        cdsLineas.Post;
        qryAux.Next;
      end;
    finally
      qryAux.Close;
    end;
    // Pase 2: rellenar coste y stock del almacén que sirve (el propio).
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      cdsLineas.Edit;
      sSkuSolicitado := cdsLineas.FieldByName('CODIGO_UNIDAD').AsString;
      sSkuActivo := ResolverSkuSolicitudActivo(
        cdsLineas.FieldByName('CODIGO_ART').AsString, sSkuSolicitado);
      if (sSkuActivo <> '') and not SameText(sSkuActivo, sSkuSolicitado) then
      begin
        cdsLineas.FieldByName('CODIGO_UNIDAD').AsString := sSkuActivo;
        DesempaquetarAtributosLinea(sSkuActivo);
      end;
      cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency :=
        ObtenerCosteMedio(cdsLineas.FieldByName('CODIGO_UNIDAD').AsString,
                          sPropio);
      cdsLineas.FieldByName('STOCK_ORIGEN').AsFloat :=
        ObtenerStock(cdsLineas.FieldByName('CODIGO_UNIDAD').AsString, sPropio);
      cdsLineas.FieldByName('TOTAL').AsCurrency :=
        cdsLineas.FieldByName('CANTIDAD').AsFloat *
        cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency;
      cdsLineas.Post;
      cdsLineas.Next;
    end;
  end;
end;

end.
