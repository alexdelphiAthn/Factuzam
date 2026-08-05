{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidos                                                }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de pedidos.                                                   }
{    Cabeceras y líneas de fza_pedidos, generación de albaranes e importación  }
{    PrestaShop.                                                               }
{******************************************************************************}
unit UniDataPedidos;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, inLibUser,
  frxClass, frxDBSet,
  inLibPresta, frCoreClasses,
  inLibArticulosValidadorIntf,
  UniDataArticulosValidadorRepositorio;

type
  TdmPedidos = class(TdmBase)
    unqryPedidosLineas: TUniQuery;
    dsPedidosLineas: TDataSource;
    unqryLinPedido: TUniQuery;
    dsLinPedido: TDataSource;
    unqryEmpDataPedido: TUniQuery;
    unqryCliDataPedido: TUniQuery;
    unqryArtDataLinPedido: TUniQuery;
    unstrdprcCrearPedido: TUniStoredProc;
    unstrdprcGetContadorPedido: TUniStoredProc;
    unstrdprcGetContador: TUniStoredProc;
    unstrdprcCrearAlbaranInicio: TUniStoredProc;
    unstrdprcCrearAlbaranLinea:  TUniStoredProc;
    unstrdprcCrearAlbaranFin:    TUniStoredProc;
    fxdsPrintPed: TfrxDBDataset;
    fxdstPrintLinPed: TfrxDBDataset;
    unqryAlbaranes: TUniQuery;
    dsAlbaranes:    TDataSource;
    unqryMensajes: TUniQuery;
    dsMensajes:    TDataSource;
    unqryFormasPago: TUniQuery;
    dsFormasPago: TDataSource;
    unqryAlmacenesPed: TUniQuery;
    dsAlmacenesPed: TDataSource;
    unqryTarifas: TUniQuery;
    dsTarifas: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryPedidosLineasAfterInsert(DataSet: TDataSet);
    procedure unqryPedidosLineasBeforePost(DataSet: TDataSet);
    procedure unqryPedidosLineasAfterPost(DataSet: TDataSet);
    procedure unqryPedidosLineasBeforeDelete(DataSet: TDataSet);
  public
    // Contrato ColumnSKUcxGrid: rellena ATTR1..5_VALOR_PEDLIN y
    // NUM_ATRIBUTOS_PEDLIN troceando el SKU (CODIGO_UNIDAD_PEDLIN) de
    // cada linea que aun los tenga vacios (idempotente por linea).
    procedure DesempaquetarAtributosLineas;
    procedure GetCodigoAutoPedido;
    procedure CalcularTotalesPedido;
    // Numero total de prendas (suma CANTIDAD_PEDLIN de todas las lineas).
    // Se muestra en la pestana Totales; no se persiste en BBDD.
    function TotalPrendasPedido: Double;
    procedure CopiarEmpresaaPedido(DataSet: TDataSet);
    procedure CopiarClienteaPedido(DataSet: TDataSet);
    function BuscarEmpresa(const ACodigo: string): Boolean;
    function BuscarAlmacen(const ACodigo: string): Boolean;
    function ClienteExiste(const ACodigo: string): Boolean;
    function BuscarCliente(const ACodigo: string): Boolean;
    procedure RefrescarAlmacenes(const ACodigoEmpresa: string);
    procedure ActualizarImpuestosTarifaCabecera(
      const ACodigoTarifa: string);

    // Cantidades entregadas / pendientes
    procedure RecalcularEntregasLinea;

    // Instala los procs PRC_PED_CREAR_ALBARAN_* de forma idempotente.
    // Cada CREATE PROCEDURE se envía al servidor como una sola sentencia,
    // evitando la necesidad de DELIMITER (que TUniScript no entiende).
    procedure InstalarProcedimientos;

    // Crear albarán a partir de las cantidades entregadas pendientes.
    // ACodigoAlmacen: almacén (único) del que sale la mercancía; se fija
    // en las líneas que se añaden ahora, sobreescribiendo el almacén que
    // cada línea heredaba del pedido.
    // AAlbExistenteNum/AAlbExistenteSerie: si se indican, las líneas se
    // añaden a ese albarán existente en lugar de crear uno nuevo.
    function CrearAlbaranDesdePedido(out sNumeroAlb, sSerieAlb: string;
                                     aLineas: TList<TPair<string,
                                     Currency>>;
                                     const ACodigoAlmacen: string;
                                     const AAlbExistenteNum: string = '';
                                     const AAlbExistenteSerie: string = ''
                                    ): Boolean;

    // Importación PrestaShop
    function ImportarPedidoPrestaShop(aOrder: TOrder): Boolean;
    function ExistePedidoPrestaShop(const sIdPS: string): Boolean;
    // Localiza el cliente del pedido PS por NIF/email; si no existe lo da de
    // alta y devuelve su CODIGO_CLI_CLI. Devuelve '0' solo si no hay datos.
    function ResolverCodigoCliente(aOrder: TOrder): string;
    // Localiza el articulo de una linea PS por EAN13/referencia; si no existe
    // crea articulo sin variacion + SKU + codigo de barras y devuelve el
    // CODIGO_ART_ART. Devuelve '' solo si no hay datos para crearlo.
    function ResolverCodigoArticulo(
      const oValidador: IArticulosValidador;
                                    const lp: TLineaPed): string;

    procedure OpenTables;
    // Override: abre las queries detalle del Mto de Pedidos tras
    // unqryTablaG. Invocada desde TfrmMtoGen.AbrirTablaPrincipalAsync
    // en el callback main thread. OpenTables delega aqui.
    procedure AbrirDetalles; override;
  private
    FProcsInstalados: Boolean;
    FCalculandoTotales: Boolean;
    procedure EjecutarSqlInstalacion(
      AEjecutor: TUniSQL;
      const ASql: string);
    procedure InstalarProcedimientoAlbaranFin(AEjecutor: TUniSQL);
    procedure InstalarProcedimientoAlbaranInicio(AEjecutor: TUniSQL);
    procedure InstalarProcedimientoAlbaranLinea(AEjecutor: TUniSQL);
    procedure PrepararLineaAntesDeGuardar(DataSet: TDataSet);
    procedure AplicarEstadoLineaAntesDeGuardar(DataSet: TDataSet);
    procedure AplicarAuditoriaLineaAntesDeGuardar(DataSet: TDataSet);
    procedure AsignarNumeroLineaPedido(DataSet: TDataSet);
    procedure PersistirAlmacenCabecera;
    procedure ValidarAlmacenCabecera;
    procedure ValidarClienteCabecera;
    // Propone la serie PE de fza_empresas_series de la empresa emisora
    // en documentos nuevos sin numerar (al cambiar la empresa en el alta)
    procedure ProponerSerieEmpresa(const AEmpresa: string);
    procedure CopiarFormaPagoPedidoAAlbaran(const ASeriePed, ANumeroPed,
                                            ASerieAlb, ANumeroAlb: string;
                                            AForzar: Boolean);
    procedure RestarPdteServirPedido(const ASerie, ANumero,
                                     ALinea: string);
    // Devuelve el siguiente contador (PRC_GET_NEXT_CONT) del tipo indicado.
    function ObtenerContador(const sTipo: string): string;
  end;

implementation

uses
  inLibValoresAutomaticos, UniDataValoresAutomaticosRepositorio,
  System.Diagnostics, System.UITypes,
  inLibVentasImpuestos, UniDataImpuestosRepositorio,
  inLibContadorLineas,
  UniDataContadorLineasRepositorio, JclDebug,
  inLibData, UniDataAlmacenesEmpresaRepositorio,
  inLibMsgArticulos, inLibMsgVentas,
  inLibDocumento, inLibDocumentoIntf, inLibLogIntf,
  inLibPedidosVentaPresentacionReglas,
  UniDataPedidosPrestaShopEscrituras,
  UniDataPedidosVentaFlujoEdicion;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TdmPedidos }

procedure TdmPedidos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection           := ConexionPrincipal;
  unqryTablaG.BeforeDelete         := unqryTablaGBeforeDelete;
  unqryTablaG.AfterPost            := unqryTablaGAfterPost;
  unqryTablaG.SQLRefresh.Text      :=
    'SELECT * FROM vi_pedidos ' +
    ' WHERE NUMERO_PED = :NUMERO_PED ' +
    '   AND SERIE_PED = :SERIE_PED';
  unqryPedidosLineas.Connection    := ConexionPrincipal;
  unqryPedidosLineas.BeforeDelete  := unqryPedidosLineasBeforeDelete;
  // Contrato ColumnSKUcxGrid (pedidos_columnas_sku.sql): los SQL del
  // dfm no conocen las columnas nuevas (SKU + ATTR1..5 + pivote); se
  // reescriben aqui COMPLETOS para no editar el dfm cableado.
  unqryPedidosLineas.SQLInsert.Text :=
    'INSERT INTO fza_pedidos_lineas ' +
    ' (NUMERO_PED_PEDLIN, SERIE_PED_PEDLIN, LINEA_PEDLIN, ' +
    '  IDLINEAPS_PEDLIN, IDPRODPS_PEDLIN, CODIGOPRODPS_PEDLIN, ' +
    '  IDATRIBPRODPS_PEDLIN, CODBAR_ART_PEDLIN, CODIGO_ART_PEDLIN, ' +
    '  CODIGO_FAM_PEDLIN, NOMBRE_FAM_PEDLIN, FECHA_ENTREGA_PEDLIN, ' +
    '  TIPO_CANTIDAD_ARTICULO_PEDLIN, ESIMP_INCL_TARIFA_PEDLIN, ' +
    '  TIPO_IVA_ARTICULO_PEDLIN, DESCRIPCION_ARTICULO_PEDLIN, ' +
    '  CODIGO_TAR_PEDLIN, CANTIDAD_PEDLIN, CANTIDAD_ENTREGADA_PEDLIN, ' +
    '  CANTIDAD_A_ALBARANAR_PEDLIN, CANTIDAD_PENDIENTE_PEDLIN, ' +
    '  ESENTREGADA_PEDLIN, ' +
    '  CODIGO_ALMACEN_PEDLIN, PRECIO_VENTA_SIVA_ARTICULO_PEDLIN, ' +
    '  PORCENTAJE_IVA_PEDLIN, PRECIO_VENTA_CIVA_ARTICULO_PEDLIN, ' +
    '  TOTAL_PEDLIN, ' +
    '  CODIGO_UNIDAD_PEDLIN, ' +
    '  ATTR1_VALOR_PEDLIN, ATTR1_NOMBRE_PEDLIN, ' +
    '  ATTR2_VALOR_PEDLIN, ATTR2_NOMBRE_PEDLIN, ' +
    '  ATTR3_VALOR_PEDLIN, ATTR3_NOMBRE_PEDLIN, ' +
    '  ATTR4_VALOR_PEDLIN, ATTR4_NOMBRE_PEDLIN, ' +
    '  ATTR5_VALOR_PEDLIN, ATTR5_NOMBRE_PEDLIN, ' +
    '  NUM_ATRIBUTOS_PEDLIN, ID_AC_PIVOT_PEDLIN, ' +
    '  INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES ' +
    ' (:NUMERO_PED_PEDLIN, :SERIE_PED_PEDLIN, :LINEA_PEDLIN, ' +
    '  :IDLINEAPS_PEDLIN, :IDPRODPS_PEDLIN, :CODIGOPRODPS_PEDLIN, ' +
    '  :IDATRIBPRODPS_PEDLIN, :CODBAR_ART_PEDLIN, :CODIGO_ART_PEDLIN, ' +
    '  :CODIGO_FAM_PEDLIN, :NOMBRE_FAM_PEDLIN, :FECHA_ENTREGA_PEDLIN, ' +
    '  :TIPO_CANTIDAD_ARTICULO_PEDLIN, :ESIMP_INCL_TARIFA_PEDLIN, ' +
    '  :TIPO_IVA_ARTICULO_PEDLIN, :DESCRIPCION_ARTICULO_PEDLIN, ' +
    '  :CODIGO_TAR_PEDLIN, :CANTIDAD_PEDLIN, ' +
    '  :CANTIDAD_ENTREGADA_PEDLIN, :CANTIDAD_A_ALBARANAR_PEDLIN, ' +
    '  :CANTIDAD_PENDIENTE_PEDLIN, :ESENTREGADA_PEDLIN, ' +
    '  :CODIGO_ALMACEN_PEDLIN, ' +
    '  :PRECIO_VENTA_SIVA_ARTICULO_PEDLIN, :PORCENTAJE_IVA_PEDLIN, ' +
    '  :PRECIO_VENTA_CIVA_ARTICULO_PEDLIN, :TOTAL_PEDLIN, ' +
    '  :CODIGO_UNIDAD_PEDLIN, ' +
    '  :ATTR1_VALOR_PEDLIN, :ATTR1_NOMBRE_PEDLIN, ' +
    '  :ATTR2_VALOR_PEDLIN, :ATTR2_NOMBRE_PEDLIN, ' +
    '  :ATTR3_VALOR_PEDLIN, :ATTR3_NOMBRE_PEDLIN, ' +
    '  :ATTR4_VALOR_PEDLIN, :ATTR4_NOMBRE_PEDLIN, ' +
    '  :ATTR5_VALOR_PEDLIN, :ATTR5_NOMBRE_PEDLIN, ' +
    '  :NUM_ATRIBUTOS_PEDLIN, :ID_AC_PIVOT_PEDLIN, ' +
    '  :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, ' +
    '  :USUARIO_MODIF)';
  unqryPedidosLineas.SQLUpdate.Text :=
    'UPDATE fza_pedidos_lineas SET ' +
    '  NUMERO_PED_PEDLIN = :NUMERO_PED_PEDLIN, ' +
    '  SERIE_PED_PEDLIN = :SERIE_PED_PEDLIN, ' +
    '  LINEA_PEDLIN = :LINEA_PEDLIN, ' +
    '  IDLINEAPS_PEDLIN = :IDLINEAPS_PEDLIN, ' +
    '  IDPRODPS_PEDLIN = :IDPRODPS_PEDLIN, ' +
    '  CODIGOPRODPS_PEDLIN = :CODIGOPRODPS_PEDLIN, ' +
    '  IDATRIBPRODPS_PEDLIN = :IDATRIBPRODPS_PEDLIN, ' +
    '  CODBAR_ART_PEDLIN = :CODBAR_ART_PEDLIN, ' +
    '  CODIGO_ART_PEDLIN = :CODIGO_ART_PEDLIN, ' +
    '  CODIGO_FAM_PEDLIN = :CODIGO_FAM_PEDLIN, ' +
    '  NOMBRE_FAM_PEDLIN = :NOMBRE_FAM_PEDLIN, ' +
    '  FECHA_ENTREGA_PEDLIN = :FECHA_ENTREGA_PEDLIN, ' +
    '  TIPO_CANTIDAD_ARTICULO_PEDLIN = :TIPO_CANTIDAD_ARTICULO_PEDLIN, ' +
    '  ESIMP_INCL_TARIFA_PEDLIN = :ESIMP_INCL_TARIFA_PEDLIN, ' +
    '  TIPO_IVA_ARTICULO_PEDLIN = :TIPO_IVA_ARTICULO_PEDLIN, ' +
    '  DESCRIPCION_ARTICULO_PEDLIN = :DESCRIPCION_ARTICULO_PEDLIN, ' +
    '  CODIGO_TAR_PEDLIN = :CODIGO_TAR_PEDLIN, ' +
    '  CANTIDAD_PEDLIN = :CANTIDAD_PEDLIN, ' +
    '  CANTIDAD_ENTREGADA_PEDLIN = :CANTIDAD_ENTREGADA_PEDLIN, ' +
    '  CANTIDAD_A_ALBARANAR_PEDLIN = :CANTIDAD_A_ALBARANAR_PEDLIN, ' +
    '  CANTIDAD_PENDIENTE_PEDLIN = :CANTIDAD_PENDIENTE_PEDLIN, ' +
    '  ESENTREGADA_PEDLIN = :ESENTREGADA_PEDLIN, ' +
    '  CODIGO_ALMACEN_PEDLIN = :CODIGO_ALMACEN_PEDLIN, ' +
    '  PRECIO_VENTA_SIVA_ARTICULO_PEDLIN = ' +
    '    :PRECIO_VENTA_SIVA_ARTICULO_PEDLIN, ' +
    '  PORCENTAJE_IVA_PEDLIN = :PORCENTAJE_IVA_PEDLIN, ' +
    '  PRECIO_VENTA_CIVA_ARTICULO_PEDLIN = ' +
    '    :PRECIO_VENTA_CIVA_ARTICULO_PEDLIN, ' +
    '  TOTAL_PEDLIN = :TOTAL_PEDLIN, ' +
    '  CODIGO_UNIDAD_PEDLIN = :CODIGO_UNIDAD_PEDLIN, ' +
    '  ATTR1_VALOR_PEDLIN = :ATTR1_VALOR_PEDLIN, ' +
    '  ATTR1_NOMBRE_PEDLIN = :ATTR1_NOMBRE_PEDLIN, ' +
    '  ATTR2_VALOR_PEDLIN = :ATTR2_VALOR_PEDLIN, ' +
    '  ATTR2_NOMBRE_PEDLIN = :ATTR2_NOMBRE_PEDLIN, ' +
    '  ATTR3_VALOR_PEDLIN = :ATTR3_VALOR_PEDLIN, ' +
    '  ATTR3_NOMBRE_PEDLIN = :ATTR3_NOMBRE_PEDLIN, ' +
    '  ATTR4_VALOR_PEDLIN = :ATTR4_VALOR_PEDLIN, ' +
    '  ATTR4_NOMBRE_PEDLIN = :ATTR4_NOMBRE_PEDLIN, ' +
    '  ATTR5_VALOR_PEDLIN = :ATTR5_VALOR_PEDLIN, ' +
    '  ATTR5_NOMBRE_PEDLIN = :ATTR5_NOMBRE_PEDLIN, ' +
    '  NUM_ATRIBUTOS_PEDLIN = :NUM_ATRIBUTOS_PEDLIN, ' +
    '  ID_AC_PIVOT_PEDLIN = :ID_AC_PIVOT_PEDLIN, ' +
    '  INSTANTE_MODIF = :INSTANTE_MODIF, ' +
    '  INSTANTE_ALTA = :INSTANTE_ALTA, ' +
    '  USUARIO_ALTA = :USUARIO_ALTA, ' +
    '  USUARIO_MODIF = :USUARIO_MODIF ' +
    'WHERE NUMERO_PED_PEDLIN = :Old_NUMERO_PED_PEDLIN ' +
    '  AND SERIE_PED_PEDLIN = :Old_SERIE_PED_PEDLIN ' +
    '  AND LINEA_PEDLIN = :Old_LINEA_PEDLIN';
  unqryPedidosLineas.SQLRefresh.Text :=
    'SELECT * FROM vi_pedidos_lineas ' +
    ' WHERE NUMERO_PED_PEDLIN = :NUMERO_PED_PEDLIN ' +
    '   AND SERIE_PED_PEDLIN = :SERIE_PED_PEDLIN ' +
    '   AND LINEA_PEDLIN = :LINEA_PEDLIN';
  unqryPedidosLineas.SQLLock.Text :=
    'SELECT * FROM fza_pedidos_lineas ' +
    ' WHERE NUMERO_PED_PEDLIN = :Old_NUMERO_PED_PEDLIN ' +
    '   AND SERIE_PED_PEDLIN = :Old_SERIE_PED_PEDLIN ' +
    '   AND LINEA_PEDLIN = :Old_LINEA_PEDLIN ' +
    ' FOR UPDATE';
  unqryLinPedido.Connection        := ConexionPrincipal;
  unqryEmpDataPedido.Connection    := ConexionPrincipal;
  unqryCliDataPedido.Connection    := ConexionPrincipal;
  unqryArtDataLinPedido.Connection := ConexionPrincipal;
  unstrdprcCrearPedido.Connection            := ConexionPrincipal;
  unstrdprcGetContadorPedido.Connection      := ConexionPrincipal;
  unstrdprcGetContador.Connection            := ConexionPrincipal;
  unstrdprcCrearAlbaranInicio.Connection     := ConexionPrincipal;
  unstrdprcCrearAlbaranLinea.Connection      := ConexionPrincipal;
  unstrdprcCrearAlbaranFin.Connection        := ConexionPrincipal;
  unqryPerfiles.Connection         := ConexionPrincipal;
  unqryAlbaranes.Connection        := ConexionPrincipal;
  unqryMensajes.Connection         := ConexionPrincipal;
  unqryFormasPago.Connection       := ConexionPrincipal;
  unqryAlmacenesPed.Connection     := ConexionPrincipal;
  unqryTarifas.Connection          := ConexionPrincipal;
end;

procedure TdmPedidos.DesempaquetarAtributosLineas;
begin
  DesempaquetarAtributosPedidoVenta(unqryPedidosLineas);
end;

procedure TdmPedidos.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(unqryPedidosLineas) and unqryPedidosLineas.Active then
    unqryPedidosLineas.Close;
  if Assigned(unqryAlbaranes) and unqryAlbaranes.Active then
    unqryAlbaranes.Close;
  if Assigned(unqryMensajes) and unqryMensajes.Active then
    unqryMensajes.Close;
  if Assigned(unqryFormasPago) and unqryFormasPago.Active then
    unqryFormasPago.Close;
  if Assigned(unqryAlmacenesPed) and unqryAlmacenesPed.Active then
    unqryAlmacenesPed.Close;
  if Assigned(unqryTarifas) and unqryTarifas.Active then
    unqryTarifas.Close;
  inherited;
end;

procedure TdmPedidos.OpenTables;
begin
  // Delegar en AbrirDetalles para que el flujo (cronometro y logging)
  // sea unico independientemente de quien lo invoque.
  AbrirDetalles;
end;

procedure TdmPedidos.RefrescarAlmacenes(const ACodigoEmpresa: string);
var
  sEmpresa: string;
begin
  sEmpresa := Trim(ACodigoEmpresa);
  if (sEmpresa = '') and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
    sEmpresa := Trim(unqryTablaG.FieldByName('CODIGO_EMP_PED').AsString);
  if sEmpresa = '' then
    sEmpresa := Trim(UbicacionSesion.Empresa);
  if (not unqryAlmacenesPed.Active) or
     (not SameText(unqryAlmacenesPed.ParamByName('EMPRESA').AsString,
                   sEmpresa)) then
  begin
    unqryAlmacenesPed.Close;
    unqryAlmacenesPed.ParamByName('EMPRESA').AsString := sEmpresa;
    unqryAlmacenesPed.Open;
  end;
  if unqryTablaG.Active and
     (unqryTablaG.State in [dsInsert, dsEdit]) then
    AjustarEmpresaAlmacenDataSet(unqryTablaG.Connection, unqryTablaG,
      'CODIGO_EMP_PED', 'CODIGO_ALM_PED');
end;

procedure TdmPedidos.AbrirDetalles;
const
  TAG = 'Pedidos.AbrirDetalles';

  procedure AbrirConTiempo(qry: TUniQuery; const Nombre: string);
  var
    swQ: TStopwatch;
  begin
    if not qry.Active then
    begin
      swQ := TStopwatch.StartNew;
      try
        qry.Open;
        RegistroLog.RegistrarRendimiento(
          TAG, Nombre + ' OK', swQ.ElapsedMilliseconds);
      except
        on E: Exception do
        begin
          RegistroLog.RegistrarRendimiento(TAG,
            Nombre + ' ERROR=' + E.Message,
            swQ.ElapsedMilliseconds);
          raise;
        end;
      end;
    end;
  end;

var
  sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  AbrirConTiempo(unqryPedidosLineas, 'unqryPedidosLineas');
  AbrirConTiempo(unqryAlbaranes,     'unqryAlbaranes');
  AbrirConTiempo(unqryMensajes,      'unqryMensajes');
  AbrirConTiempo(unqryFormasPago,    'unqryFormasPago');
  AbrirConTiempo(unqryAlmacenesPed,  'unqryAlmacenesPed');
  AbrirConTiempo(unqryTarifas,       'unqryTarifas');
  RegistroLog.RegistrarRendimiento(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmPedidos.unqryTablaGAfterInsert(DataSet: TDataSet);
var
  sSerie: string;
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FindField(ANombre);
  end;
begin
  inherited;
  FieldByName('FECHA_PED').AsDateTime := Date;
    if Trim(UbicacionSesion.Empresa) <> '' then
      FieldByName('CODIGO_EMP_PED').AsString := UbicacionSesion.Empresa
    else
      FieldByName('CODIGO_EMP_PED').AsString := '0';
    FieldByName('CODIGO_CLI_PED').Clear;
    FieldByName('TARIFA_ARTICULO_CLIENTE_PED').Clear;
    FieldByName('ESIMP_INCL_TARIFA_CLIENTE_PED').Clear;
    FieldByName('NUMERO_PED').AsString     := '0';
    // Serie por defecto: buscar en fza_empresas_series para TIPO_DOC='PE'
    // (mismo criterio que compras); fallback historico 'A1'
    sSerie := ObtenerSerieDefecto(
      ConexionPrincipal,
      UbicacionSesion.Empresa,
      CrearConfiguracionDocumento(
        tdPedido, sdVenta).TipoContador);
    if sSerie = '' then
      sSerie := 'A1';
    if FindField('SERIE_PED') <> nil then
      FieldByName('SERIE_PED').AsString    := sSerie;
    if FindField('ESTADO_PED') <> nil then
      FieldByName('ESTADO_PED').AsString   := 'ABIERTO';
    if FindField('ESCONSOLIDADO_PED') <> nil then
      FieldByName('ESCONSOLIDADO_PED').AsString := 'N';
    if Trim(UbicacionSesion.Empresa) <> '' then
      BuscarEmpresa(UbicacionSesion.Empresa);
  if FindField('CODIGO_ALM_PED') <> nil then
    FieldByName('CODIGO_ALM_PED').AsString := UbicacionSesion.Almacen;
  RefrescarAlmacenes(
    DataSet.FieldByName('CODIGO_EMP_PED').AsString);
end;

procedure TdmPedidos.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  ValidarAlmacenCabecera;
  ValidarClienteCabecera;
  if (unqryTablaG.FieldByName('NUMERO_PED').AsString = '0') or
     (unqryTablaG.FieldByName('NUMERO_PED').AsString = '') then
    GetCodigoAutoPedido;
  AplicarPorcentajesIvaVenta(
    CrearLecturasImpuestos(ConexionPrincipal), unqryTablaG, 'PED');
  CalcularTotalesPedido;
end;

procedure TdmPedidos.unqryTablaGAfterPost(DataSet: TDataSet);
begin
  inherited;
  PersistirAlmacenCabecera;
end;

procedure TdmPedidos.unqryTablaGBeforeDelete(DataSet: TDataSet);
var
  q: TUniQuery;
  sSerie: string;
  sNumero: string;
begin
  inherited;
  sSerie  := DataSet.FieldByName('SERIE_PED').AsString;
  sNumero := DataSet.FieldByName('NUMERO_PED').AsString;
  if (sSerie = '') or (sNumero = '') then
  begin
    Abort;
  end;
  if not SolicitarConfirmacion(
    Format(SPreguntaBorrarPedidoVenta,
      [sSerie, sNumero])) then
  begin
    Abort;
  end;
  RestarPdteServirPedido(sSerie, sNumero, '');
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionPrincipal;
    q.SQL.Text :=
      'DELETE FROM fza_pedidos_lineas ' +
      ' WHERE SERIE_PED_PEDLIN  = :s ' +
      '   AND NUMERO_PED_PEDLIN = :n';
    q.ParamByName('s').AsString := sSerie;
    q.ParamByName('n').AsString := sNumero;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure TdmPedidos.unqryPedidosLineasAfterInsert(DataSet: TDataSet);
begin
  inherited;
  InicializarLineaPedidoVenta(
    DataSet, unqryTablaG, IdentidadSesion.Usuario, Now);
end;

var
  // Instrumentacion temporal (bucle contador 07/07/2026): numero de
  // volcados de pila ya escritos en el log, para no inundarlo.
  iVolcadosPilaLineaVacia: Integer = 0;

// Linea sin identificar el articulo por ninguna via: ni codigo de
// articulo, ni SKU, ni codigo PrestaShop, ni codigo de barras.
function LineaPedidoVacia(ADataSet: TDataSet): Boolean;
  function CampoVacio(const ANombre: string): Boolean;
  var
    Campo: TField;
  begin
    Result := True;
    Campo := ADataSet.FindField(ANombre);
    if Campo <> nil then
      Result := Trim(Campo.AsString) = '';
  end;
begin
  Result := CampoVacio('CODIGO_ART_PEDLIN') and
            CampoVacio('CODIGO_UNIDAD_PEDLIN') and
            CampoVacio('CODIGOPRODPS_PEDLIN') and
            CampoVacio('CODBAR_ART_PEDLIN');
end;

// Instrumentacion TEMPORAL: vuelca la pila de llamadas al log para
// identificar QUIEN esta posteando lineas vacias en bucle (el sintoma
// del 07/07/2026: trio de contador repetido ~13 veces/segundo sin
// ningun INSERT y sin excepcion visible). Maximo 3 volcados por sesion.
procedure VolcarPilaPostLineaVacia(
  const ARegistroLog: IRegistroLog);
var
  Pila: TJclStackInfoList;
  Lineas: TStringList;
begin
  if (iVolcadosPilaLineaVacia < 3) and
     Assigned(ARegistroLog) then
  begin
    Inc(iVolcadosPilaLineaVacia);
    Lineas := TStringList.Create;
    try
      try
        Pila := JclCreateStackList(True, 0, nil);
        try
          Pila.AddToStrings(Lineas, True, True, True, True);
        finally
          FreeAndNil(Pila);
        end;
      except
        // La pila es diagnostico: si JclDebug falla, el aviso sale igual.
        on E: Exception do
          Lineas.Add('(no se pudo capturar la pila: ' + E.Message + ')');
      end;
      ARegistroLog.RegistrarAviso(
        'Post de linea de pedido VACIA rechazado. Pila del llamador:' +
        sLineBreak + Lineas.Text);
    finally
      FreeAndNil(Lineas);
    end;
  end;
end;

procedure TdmPedidos.unqryPedidosLineasBeforePost(DataSet: TDataSet);
begin
  inherited;
  PrepararLineaAntesDeGuardar(DataSet);
end;

procedure TdmPedidos.PrepararLineaAntesDeGuardar(DataSet: TDataSet);
begin
  // Guarda ColumnSKUcxGrid (bucle 07/07/2026): un Post de linea sin
  // articulo no debe llegar a BBDD. Antes de esta guarda, cada intento
  // consumia contador en GetSiguienteLineaDocLibre y el reintento del
  // grid quemaba CONTADOR_LINEAS_PED en bucle (log 17:03 y 17:16).
  if LineaPedidoVacia(DataSet) then
  begin
    VolcarPilaPostLineaVacia(RegistroLog);
    raise Exception.Create(SErrorLineaPedidoSinArticulo);
  end;
  AsignarNumeroLineaPedido(DataSet);
  NormalizarArticuloSkuEnDataSet(ConexionPrincipal, unqryPedidosLineas,
    'CODIGO_ART_PEDLIN', 'CODIGOPRODPS_PEDLIN', 'CODBAR_ART_PEDLIN');
  RecalcularEntregasLinea;
  AplicarEstadoLineaAntesDeGuardar(DataSet);
  PrepararLineaFiscalVenta(CrearLecturasImpuestos(ConexionPrincipal),
    unqryTablaG,
    unqryPedidosLineas, 'PED', 'PEDLIN', 'TOTAL_PEDLIN');
  AplicarAuditoriaLineaAntesDeGuardar(DataSet);
end;

procedure TdmPedidos.AplicarEstadoLineaAntesDeGuardar(
  DataSet: TDataSet);
var
  oEntrada: TEntradaEstadoLineaPedidoVenta;
  oEstado: TEstadoLineaPedidoVenta;
begin
  oEntrada := Default(TEntradaEstadoLineaPedidoVenta);
  oEntrada.Cantidad := DataSet.FieldByName('CANTIDAD_PEDLIN').AsFloat;
  if DataSet.FindField('CANTIDAD_ENTREGADA_PEDLIN') <> nil then
    oEntrada.CantidadEntregada := DataSet.FieldByName(
      'CANTIDAD_ENTREGADA_PEDLIN').AsFloat;
  if DataSet.FindField('CANTIDAD_A_ALBARANAR_PEDLIN') <> nil then
    oEntrada.CantidadAAlbaranar := DataSet.FieldByName(
      'CANTIDAD_A_ALBARANAR_PEDLIN').AsFloat;
  oEstado := CalcularEstadoLineaPedidoVenta(oEntrada);
  AplicarEstadoLineaPedidoVenta(DataSet, oEstado);
end;

procedure TdmPedidos.AplicarAuditoriaLineaAntesDeGuardar(
  DataSet: TDataSet);
begin
  if DataSet.FindField('USUARIO_MODIF') <> nil then
    DataSet.FieldByName('USUARIO_MODIF').AsString :=
      IdentidadSesion.Usuario;
  if DataSet.FindField('INSTANTE_MODIF') <> nil then
    DataSet.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
  if DataSet.State = dsInsert then
  begin
    if (DataSet.FindField('USUARIO_ALTA') <> nil) and
       (DataSet.FieldByName('USUARIO_ALTA').AsString = '') then
      DataSet.FieldByName('USUARIO_ALTA').AsString :=
        IdentidadSesion.Usuario;
    if (DataSet.FindField('INSTANTE_ALTA') <> nil) and
       DataSet.FieldByName('INSTANTE_ALTA').IsNull then
      DataSet.FieldByName('INSTANTE_ALTA').AsDateTime := Now;
  end;
end;

procedure TdmPedidos.AsignarNumeroLineaPedido(DataSet: TDataSet);
var
  iNuevaLinea: Integer;
  sLinea: string;
  sNumero: string;
  sSerie: string;
begin
  if DataSet.FindField('LINEA_PEDLIN') <> nil then
  begin
    sLinea := Trim(DataSet.FieldByName('LINEA_PEDLIN').AsString);
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_PED').AsString);
    sSerie  := Trim(unqryTablaG.FieldByName('SERIE_PED').AsString);
    if (sLinea = '') or (StrToIntDef(sLinea, 0) = 0) or
       ((DataSet.State = dsInsert) and
        LineaDocExiste(CrearContadorLineasDocumento(ConexionPrincipal),
          LIN_PEDIDOS, sSerie, sNumero,
          sLinea)) then
    begin
      if (sNumero = '') or (sNumero = '0') or (sSerie = '') then
        raise Exception.Create(SErrorCabeceraPedidoSinGrabar);
      if DataSet.FindField('NUMERO_PED_PEDLIN') <> nil then
        DataSet.FieldByName('NUMERO_PED_PEDLIN').AsString := sNumero;
      if DataSet.FindField('SERIE_PED_PEDLIN') <> nil then
        DataSet.FieldByName('SERIE_PED_PEDLIN').AsString := sSerie;
      iNuevaLinea := GetSiguienteLineaDocLibre(
        CrearContadorLineasDocumento(ConexionPrincipal),
        CONT_PEDIDOS, LIN_PEDIDOS, sSerie, sNumero);
      // El helper ya persiste CONTADOR_LINEAS_PED en BBDD dentro de su
      // propia transaccion. NO se toca unqryTablaG: el Edit anterior
      // dejaba la cabecera en edicion sin postear, y eso disparaba el
      // re-Post de cabecera + recarga del detalle en cada linea. Si la
      // copia en memoria queda desfasada no pasa nada: el helper toma
      // siempre MAX(LINEA_PEDLIN) como suelo.
      if iNuevaLinea = 0 then
        raise Exception.Create(Format(SErrorAsignarLineaPedido,
                                      [sSerie, sNumero]));
      DataSet.FieldByName('LINEA_PEDLIN').AsString :=
        Format('%.4d', [iNuevaLinea]);
    end;
  end;
end;

procedure TdmPedidos.unqryPedidosLineasAfterPost(DataSet: TDataSet);
begin
  inherited;
  CalcularTotalesPedido;
end;

procedure TdmPedidos.unqryPedidosLineasBeforeDelete(DataSet: TDataSet);
var
  sSerie: string;
  sNumero: string;
  sLinea: string;
begin
  inherited;
  sSerie  := DataSet.FieldByName('SERIE_PED_PEDLIN').AsString;
  sNumero := DataSet.FieldByName('NUMERO_PED_PEDLIN').AsString;
  sLinea  := DataSet.FieldByName('LINEA_PEDLIN').AsString;
  if (sSerie <> '') and (sNumero <> '') and (sLinea <> '') then
  begin
    RestarPdteServirPedido(sSerie, sNumero, sLinea);
  end;
end;

procedure TdmPedidos.RestarPdteServirPedido(const ASerie, ANumero,
                                            ALinea: string);
var
  q: TUniQuery;
  sFiltroLinea: string;
begin
  if (Trim(ASerie) <> '') and (Trim(ANumero) <> '') then
  begin
    sFiltroLinea := '';
    if Trim(ALinea) <> '' then
    begin
      sFiltroLinea := '   AND L.LINEA_PEDLIN = :l ';
    end;
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionPrincipal;
      q.SQL.Text :=
        'UPDATE fza_articulos_stockactual STK ' +
        'JOIN ( ' +
        '  SELECT X.SKU_EFE AS SKU, X.ALM_EFE AS ALM, ' +
        '         SUM(X.PENDIENTE) AS PENDIENTE ' +
        '    FROM ( ' +
        '      SELECT COALESCE(NULLIF(CB.CODIGO_UNIDAD_CB, ''''), ' +
        '                    NULLIF(SREF.CODIGO_UNIDAD_SKU, ''''), ' +
        '                    NULLIF(SART.CODIGO_UNIDAD_SKU, ''''), ' +
        '                    NULLIF(L.CODIGOPRODPS_PEDLIN, ''''), ' +
        '                    NULLIF(L.CODIGO_ART_PEDLIN, '''')) AS SKU_EFE, ' +
        '             NULLIF(L.CODIGO_ALMACEN_PEDLIN, '''') AS ALM_EFE, ' +
        '             GREATEST(IFNULL(L.CANTIDAD_PEDLIN, 0) - ' +
        '                      IFNULL(L.CANTIDAD_ENTREGADA_PEDLIN, 0), ' +
        '                      0) AS PENDIENTE ' +
        '        FROM fza_pedidos_lineas L ' +
        '        LEFT JOIN ( ' +
        '          SELECT CODIGO_BARRAS_CB, ' +
        '                 MIN(CODIGO_UNIDAD_CB) AS CODIGO_UNIDAD_CB ' +
        '            FROM fza_codigos_barras ' +
        '           WHERE CODIGO_BARRAS_CB <> '''' ' +
        '           GROUP BY CODIGO_BARRAS_CB ' +
        '        ) CB ON CB.CODIGO_BARRAS_CB = L.CODBAR_ART_PEDLIN ' +
        '        LEFT JOIN fza_articulos_skus SREF ' +
        '          ON SREF.CODIGO_UNIDAD_SKU = L.CODIGOPRODPS_PEDLIN ' +
        '        LEFT JOIN ( ' +
        '          SELECT CODIGO_ART_SKU, ' +
        '                 MIN(CODIGO_UNIDAD_SKU) AS CODIGO_UNIDAD_SKU ' +
        '            FROM fza_articulos_skus ' +
        '           GROUP BY CODIGO_ART_SKU ' +
        '          HAVING COUNT(*) = 1 ' +
        '        ) SART ON SART.CODIGO_ART_SKU = L.CODIGO_ART_PEDLIN ' +
        '       WHERE L.SERIE_PED_PEDLIN  = :s ' +
        '         AND L.NUMERO_PED_PEDLIN = :n ' +
        sFiltroLinea +
        '    ) X ' +
        '   WHERE X.SKU_EFE IS NOT NULL ' +
        '     AND X.SKU_EFE <> '''' ' +
        '     AND X.ALM_EFE IS NOT NULL ' +
        '     AND X.ALM_EFE <> '''' ' +
        '     AND X.PENDIENTE > 0 ' +
        '   GROUP BY X.SKU_EFE, X.ALM_EFE ' +
        ') P ON P.SKU = STK.CODIGO_UNIDAD_STK ' +
        '   AND P.ALM = STK.CODIGO_ALM_STK ' +
        '   AND STK.LOTE_STK = '''' ' +
        '   SET STK.CANTIDAD_PTE_SERVIR_STK = ' +
        '       GREATEST(IFNULL(STK.CANTIDAD_PTE_SERVIR_STK, 0) - ' +
        '                P.PENDIENTE, 0), ' +
        '       STK.INSTANTE_MODIF = NOW()';
      q.ParamByName('s').AsString := ASerie;
      q.ParamByName('n').AsString := ANumero;
      if Trim(ALinea) <> '' then
      begin
        q.ParamByName('l').AsString := ALinea;
      end;
      q.ExecSQL;
    finally
      FreeAndNil(q);
    end;
  end;
end;

procedure TdmPedidos.RecalcularEntregasLinea;
var
  fCant, fEntr, fPend, fAAlbaranar: Double;
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqryPedidosLineas.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryPedidosLineas.FindField(ANombre);
  end;
begin
  fCant := FieldByName('CANTIDAD_PEDLIN').AsFloat;
    if FindField('CANTIDAD_ENTREGADA_PEDLIN') <> nil then
    begin
      fEntr := FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsFloat;
      if fEntr > fCant then
      begin
        FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsFloat := fCant;
        fEntr := fCant;
      end;
      fPend := fCant - fEntr;
      if fPend < 0 then
        fPend := 0;
      if FindField('CANTIDAD_A_ALBARANAR_PEDLIN') <> nil then
      begin
        fAAlbaranar := FieldByName('CANTIDAD_A_ALBARANAR_PEDLIN').AsFloat;
        if fAAlbaranar < 0 then
          fAAlbaranar := 0;
        if fAAlbaranar > fPend then
          fAAlbaranar := fPend;
        FieldByName('CANTIDAD_A_ALBARANAR_PEDLIN').AsFloat := fAAlbaranar;
      end;
      if FindField('CANTIDAD_PENDIENTE_PEDLIN') <> nil then
        FieldByName('CANTIDAD_PENDIENTE_PEDLIN').AsFloat := fPend;
      if FindField('ESENTREGADA_PEDLIN') <> nil then
      begin
        if fPend <= 0 then
          FieldByName('ESENTREGADA_PEDLIN').AsString := 'S'
        else
          FieldByName('ESENTREGADA_PEDLIN').AsString := 'N';
    end;
  end;
end;

procedure TdmPedidos.GetCodigoAutoPedido;
begin
  unstrdprcGetContadorPedido.Params.Clear;
  unstrdprcGetContadorPedido.Params.CreateParam(
    ftString, 'pserie', ptInput);
  unstrdprcGetContadorPedido.Params.CreateParam(
    ftString, 'ptipodoc', ptInput);
  unstrdprcGetContadorPedido.Params.CreateParam(
    ftString, 'pcont', ptOutput);
  unstrdprcGetContadorPedido.Params.CreateParam(
    ftString, 'pEMPRESA_CONTADOR', ptInput);
  unstrdprcGetContadorPedido.Params.CreateParam(
    ftString, 'pUSUARIOMODIF', ptInput);
  unstrdprcGetContadorPedido.ParamByName('pserie').AsString :=
    unqryTablaG.FieldByName('SERIE_PED').AsString;
  unstrdprcGetContadorPedido.ParamByName('ptipodoc').AsString :=
    CrearConfiguracionDocumento(tdPedido, sdVenta).TipoContador;
  unstrdprcGetContadorPedido.ParamByName('pUSUARIOMODIF').AsString :=
    IdentidadSesion.Usuario;
  unstrdprcGetContadorPedido.ParamByName(
    'pEMPRESA_CONTADOR').AsString :=
    unqryTablaG.FieldByName('CODIGO_EMP_PED').AsString;
  unstrdprcGetContadorPedido.ExecProc;
  unqryTablaG.FieldByName('NUMERO_PED').AsString :=
    unstrdprcGetContadorPedido.ParamByName('pcont').AsString;
end;

procedure TdmPedidos.CalcularTotalesPedido;
begin
  if not FCalculandoTotales then
  begin
    FCalculandoTotales := True;
    try
      CalcularTotalesDocumentoVenta(
        CrearLecturasImpuestos(ConexionPrincipal), unqryTablaG,
        unqryPedidosLineas, 'PED', 'TOTAL_PEDLIN',
        'TIPO_IVA_ARTICULO_PEDLIN', 'PORCENTAJE_IVA_PEDLIN');
    finally
      FCalculandoTotales := False;
    end;
  end;
end;

function TdmPedidos.TotalPrendasPedido: Double;
begin
  Result := TotalPrendasLineasVenta(unqryPedidosLineas,
    'TIPO_IVA_ARTICULO_PEDLIN');
end;

function TdmPedidos.BuscarEmpresa(const ACodigo: string): Boolean;
var
  q: TUniQuery;
  sCodigo: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if (sCodigo <> '') and (sCodigo <> '0') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := unqryTablaG.Connection;
      q.SQL.Text := 'SELECT * ' +
                    '  FROM fza_empresas ' +
                    ' WHERE CODIGO_EMP_EMP = :empresa';
      q.ParamByName('empresa').AsString := sCodigo;
      q.Open;
      if not q.IsEmpty then
      begin
        // CopiarEmpresaaPedido ya repropone la serie de la empresa
        CopiarEmpresaaPedido(q);
        Result := True;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function TdmPedidos.BuscarAlmacen(const ACodigo: string): Boolean;
var
  qAlm: TUniQuery;
  sCodigo: string;
  sEmpresa: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if sCodigo <> '' then
  begin
    qAlm := TUniQuery.Create(nil);
    try
      qAlm.Connection := unqryTablaG.Connection;
      qAlm.SQL.Text :=
        'SELECT CODIGO_ALM_ALM, CODIGO_EMP_ALM ' +
        '  FROM fza_almacenes ' +
        ' WHERE CODIGO_ALM_ALM = :alm ' +
        '   AND COALESCE(ESACTIVO_ALM, ''S'') = ''S''';
      qAlm.ParamByName('alm').AsString := sCodigo;
      qAlm.Open;
      if not qAlm.IsEmpty then
      begin
        sEmpresa := qAlm.FieldByName('CODIGO_EMP_ALM').AsString;
        if sEmpresa <> '' then
          BuscarEmpresa(sEmpresa);
        if not (unqryTablaG.State in [dsEdit, dsInsert]) then
          unqryTablaG.Edit;
        if unqryTablaG.FindField('CODIGO_ALM_PED') <> nil then
          unqryTablaG.FieldByName('CODIGO_ALM_PED').AsString := sCodigo;
        Result := True;
      end;
    finally
      FreeAndNil(qAlm);
    end;
  end;
end;

procedure TdmPedidos.ValidarAlmacenCabecera;
begin
  if (unqryTablaG.FindField('CODIGO_ALM_PED') <> nil) and
     (Trim(unqryTablaG.FieldByName('CODIGO_ALM_PED').AsString) = '') then
  begin
    NotificarAdvertencia(SAvisoAlmacenSalidaPedidoObligatorio);
    Abort;
  end;
end;

procedure TdmPedidos.ValidarClienteCabecera;
var
  sCliente: string;
begin
  sCliente := '';
  if unqryTablaG.FindField('CODIGO_CLI_PED') <> nil then
    sCliente := Trim(unqryTablaG.FieldByName('CODIGO_CLI_PED').AsString);
  if (sCliente = '') or (sCliente = '0') then
  begin
    NotificarAdvertencia(SAvisoClientePedidoObligatorio);
    Abort;
  end;
  if not ClienteExiste(sCliente) then
  begin
    NotificarAdvertencia(
      Format(SAvisoClientePedidoNoExiste, [sCliente]));
    Abort;
  end;
end;

procedure TdmPedidos.PersistirAlmacenCabecera;
var
  q: TUniQuery;
  sAlmacen: string;
  sNumero: string;
  sSerie: string;
begin
  if unqryTablaG.FindField('CODIGO_ALM_PED') <> nil then
  begin
    sAlmacen := Trim(unqryTablaG.FieldByName('CODIGO_ALM_PED').AsString);
    sNumero  := Trim(unqryTablaG.FieldByName('NUMERO_PED').AsString);
    sSerie   := Trim(unqryTablaG.FieldByName('SERIE_PED').AsString);
    if (sAlmacen <> '') and (sNumero <> '') and (sSerie <> '') then
    begin
      q := TUniQuery.Create(nil);
      try
        q.Connection := unqryTablaG.Connection;
        q.SQL.Text :=
          'UPDATE fza_pedidos ' +
          '   SET CODIGO_ALM_PED = :alm ' +
          ' WHERE NUMERO_PED = :num ' +
          '   AND SERIE_PED = :ser';
        q.ParamByName('alm').AsString := sAlmacen;
        q.ParamByName('num').AsString := sNumero;
        q.ParamByName('ser').AsString := sSerie;
        q.ExecSQL;
      finally
        FreeAndNil(q);
      end;
    end;
  end;
end;

procedure TdmPedidos.ProponerSerieEmpresa(const AEmpresa: string);
var
  sSerie: string;
  sNumero: string;
begin
  if (unqryTablaG.State in [dsInsert, dsEdit]) then
  begin
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_PED').AsString);
    // Solo documentos nuevos sin numerar: un documento ya numerado
    // conserva su serie aunque se retoque la empresa
    if (sNumero = '') or (sNumero = '0') then
    begin
      sSerie := ObtenerSerieDefecto(
        ConexionPrincipal,
        AEmpresa,
        CrearConfiguracionDocumento(
          tdPedido, sdVenta).TipoContador);
      if sSerie <> '' then
        unqryTablaG.FieldByName('SERIE_PED').AsString := sSerie;
    end;
  end;
end;

function TdmPedidos.BuscarCliente(const ACodigo: string): Boolean;
var
  q: TUniQuery;
  sCodigo: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if (sCodigo <> '') and (sCodigo <> '0') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := unqryTablaG.Connection;
      q.SQL.Text := 'SELECT * ' +
                    '  FROM fza_clientes ' +
                    ' WHERE CODIGO_CLI_CLI = :cliente';
      q.ParamByName('cliente').AsString := sCodigo;
      q.Open;
      if not q.IsEmpty then
      begin
        CopiarClienteaPedido(q);
        Result := True;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function TdmPedidos.ClienteExiste(const ACodigo: string): Boolean;
var
  q: TUniQuery;
  sCodigo: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if (sCodigo <> '') and (sCodigo <> '0') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := unqryTablaG.Connection;
      q.SQL.Text :=
        'SELECT 1 ' +
        '  FROM fza_clientes ' +
        ' WHERE CODIGO_CLI_CLI = :cliente ' +
        ' LIMIT 1';
      q.ParamByName('cliente').AsString := sCodigo;
      q.Open;
      Result := not q.IsEmpty;
    finally
      FreeAndNil(q);
    end;
  end;
end;

procedure TdmPedidos.CopiarEmpresaaPedido(DataSet: TDataSet);
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FindField(ANombre);
  end;
begin
  if (unqryTablaG.State <> dsEdit) and
     (unqryTablaG.State <> dsInsert) then
    unqryTablaG.Edit;
    FindField('CODIGO_EMP_PED').AsString             :=
      DataSet.FindField('CODIGO_EMP_EMP').AsString;
    FindField('RAZON_SOCIAL_EMPRESA_PED').AsString   :=
      DataSet.FindField('RAZON_SOCIAL_EMP').AsString;
    FindField('NIF_EMPRESA_PED').AsString            :=
      DataSet.FindField('NIF_EMP').AsString;
    FindField('MOVIL_EMPRESA_PED').AsString          :=
      DataSet.FindField('MOVIL_EMP').AsString;
    FindField('EMAIL_EMPRESA_PED').AsString          :=
      DataSet.FindField('EMAIL_EMP').AsString;
    FindField('DIRECCION1_EMPRESA_PED').AsString     :=
      DataSet.FindField('DIRECCION1_EMP').AsString;
    FindField('DIRECCION2_EMPRESA_PED').AsString     :=
      DataSet.FindField('DIRECCION2_EMP').AsString;
    FindField('POBLACION_EMPRESA_PED').AsString      :=
      DataSet.FindField('POBLACION_EMP').AsString;
    FindField('PROVINCIA_EMPRESA_PED').AsString      :=
      DataSet.FindField('PROVINCIA_EMP').AsString;
    FindField('CODIGO_POSTAL_EMPRESA_PED').AsString  :=
      DataSet.FindField('CODIGO_POSTAL_EMP').AsString;
    FindField('NOMBRE_PAI_EMPRESA_PED').AsString     :=
      DataSet.FindField('NOMBRE_PAI_EMP').AsString;
    FindField('CODIGO_PAI_EMPRESA_PED').AsString     :=
      DataSet.FindField('CODIGO_PAI_EMP').AsString;
    FindField('GRUPO_ZONA_IVA_EMPRESA_PED').AsString :=
      DataSet.FindField('GRUPO_ZONA_IVA_EMP').AsString;
    FindField('ESRETENCIONES_EMPRESA_PED').AsString  :=
      DataSet.FindField('ESRETENCIONES_EMP').AsString;
  FindField('ESREGIMENESPECIALAGRICOLA_EMPRESA_PED').AsString :=
    DataSet.FindField('ESREGIMENESPECIALAGRICOLA_EMP').AsString;
  // La serie acompana a la empresa emisora (fza_empresas_series).
  // Cubre las dos rutas: codigo tecleado (BuscarEmpresa) y modal.
  ProponerSerieEmpresa(DataSet.FindField('CODIGO_EMP_EMP').AsString);
  AplicarPorcentajesIvaVenta(
    CrearLecturasImpuestos(ConexionPrincipal), unqryTablaG, 'PED');
end;

procedure TdmPedidos.ActualizarImpuestosTarifaCabecera(
  const ACodigoTarifa: string);
var
  sTarifa: string;
begin
  sTarifa := Trim(ACodigoTarifa);
  if unqryTablaG.Active and (unqryTablaG.State in dsEditModes) then
  begin
    if sTarifa = '' then
      unqryTablaG.FieldByName(
        'ESIMP_INCL_TARIFA_CLIENTE_PED').Clear
    else
    begin
      if not unqryTarifas.Active then
        unqryTarifas.Open;
      if unqryTarifas.Locate('CODIGO_TAR_ARTTAR', sTarifa, []) then
        unqryTablaG.FieldByName(
          'ESIMP_INCL_TARIFA_CLIENTE_PED').AsString :=
          unqryTarifas.FieldByName('ESIMP_INCL_TAR').AsString
      else
        unqryTablaG.FieldByName(
          'ESIMP_INCL_TARIFA_CLIENTE_PED').Clear;
    end;
  end;
end;

procedure TdmPedidos.CopiarClienteaPedido(DataSet: TDataSet);
var
  sTarifa: string;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FindField(ANombre);
  end;
begin
  if (unqryTablaG.State <> dsEdit) and
     (unqryTablaG.State <> dsInsert) then
    unqryTablaG.Edit;
    FindField('CODIGO_CLI_PED').AsString                  :=
      DataSet.FindField('CODIGO_CLI_CLI').AsString;
    FindField('RAZON_SOCIAL_CLIENTE_FISCAL_PED').AsString :=
      DataSet.FindField('RAZON_SOCIAL_CLI').AsString;
    FindField('NIF_CLIENTE_PED').AsString                 :=
      DataSet.FindField('NIF_CLI').AsString;
    FindField('MOVIL_CLIENTE_FISCAL_PED').AsString        :=
      DataSet.FindField('MOVIL_CLI').AsString;
    FindField('EMAIL_CLIENTE_PED').AsString               :=
      DataSet.FindField('EMAIL_CLI').AsString;
    FindField('DIRECCION1_CLIENTE_FISCAL_PED').AsString   :=
      DataSet.FindField('DIRECCION1_CLI').AsString;
    FindField('DIRECCION2_CLIENTE_FISCAL_PED').AsString   :=
      DataSet.FindField('DIRECCION2_CLI').AsString;
    FindField('POBLACION_CLIENTE_FISCAL_PED').AsString    :=
      DataSet.FindField('POBLACION_CLI').AsString;
    FindField('PROVINCIA_CLIENTE_FISCAL_PED').AsString    :=
      DataSet.FindField('PROVINCIA_CLI').AsString;
    FindField('CODIGO_POSTAL_CLIENTE_FISCAL_PED').AsString:=
      DataSet.FindField('CODIGO_POSTAL_CLI').AsString;
    FindField('NOMBRE_PAI_CLIENTE_FISCAL_PED').AsString   :=
      DataSet.FindField('NOMBRE_PAI_CLI').AsString;
    FindField('CODIGO_PAI_CLIENTE_FISCAL_PED').AsString   :=
      DataSet.FindField('CODIGO_PAI_CLI').AsString;
    FindField('ESIVA_RECARGO_CLIENTE_PED').AsString       :=
      DataSet.FindField('ESIVA_RECARGO_CLI').AsString;
    FindField('ESIVA_EXENTO_CLIENTE_PED').AsString        :=
      DataSet.FindField('ESIVA_EXENTO_CLI').AsString;
    FindField('ESREGIMENESPECIALAGRICOLA_CLIENTE_PED').AsString :=
      DataSet.FindField(
        'ESREGIMENESPECIALAGRICOLA_CLI').AsString;
    FindField('ESRETENCIONES_CLIENTE_PED').AsString       :=
      DataSet.FindField('ESRETENCIONES_CLI').AsString;
    FindField('ESINTRACOMUNITARIO_CLIENTE_PED').AsString  :=
      DataSet.FindField('ESINTRACOMUNITARIO_CLI').AsString;
    sTarifa := Trim(DataSet.FindField('TARIFA_ARTICULO_CLI').AsString);
    if sTarifa = '' then
      sTarifa := ParametrosCaja.TarifaDefecto;
    FindField('TARIFA_ARTICULO_CLIENTE_PED').AsString := sTarifa;
    ActualizarImpuestosTarifaCabecera(sTarifa);
  if (FindField('FORMA_PAGO_PED') <> nil) and
     (DataSet.FindField('CODIGO_FP_CLI') <> nil) and
     (Trim(DataSet.FindField('CODIGO_FP_CLI').AsString) <> '') then
    FindField('FORMA_PAGO_PED').AsString :=
      Trim(DataSet.FindField('CODIGO_FP_CLI').AsString);
  AplicarPorcentajesIvaVenta(
    CrearLecturasImpuestos(ConexionPrincipal), unqryTablaG, 'PED');
end;

procedure TdmPedidos.CopiarFormaPagoPedidoAAlbaran(const ASeriePed,
                                                   ANumeroPed, ASerieAlb,
                                                   ANumeroAlb: string;
                                                   AForzar: Boolean);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionPrincipal;
    q.SQL.Text :=
      'UPDATE fza_albaranes A ' +
      '  JOIN fza_pedidos P ' +
      '    ON P.SERIE_PED = :sped ' +
      '   AND P.NUMERO_PED = :nped ' +
      '   SET A.FORMA_PAGO_ALB = NULLIF(P.FORMA_PAGO_PED, ''''), ' +
      '       A.INSTANTE_MODIF = NOW(), ' +
      '       A.USUARIO_MODIF = :u ' +
      ' WHERE A.SERIE_ALB = :salb ' +
      '   AND A.NUMERO_ALB = :nalb ' +
      '   AND TRIM(IFNULL(P.FORMA_PAGO_PED, '''')) <> '''' ' +
      '   AND (:forzar = ''S'' ' +
      '        OR TRIM(IFNULL(A.FORMA_PAGO_ALB, '''')) = '''')';
    q.ParamByName('sped').AsString := ASeriePed;
    q.ParamByName('nped').AsString := ANumeroPed;
    q.ParamByName('salb').AsString := ASerieAlb;
    q.ParamByName('nalb').AsString := ANumeroAlb;
    q.ParamByName('u').AsString := IdentidadSesion.Usuario;
    if AForzar then
      q.ParamByName('forzar').AsString := 'S'
    else
      q.ParamByName('forzar').AsString := 'N';
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure TdmPedidos.EjecutarSqlInstalacion(
  AEjecutor: TUniSQL;
  const ASql: string);
begin
  AEjecutor.SQL.Text := ASql;
  AEjecutor.Execute;
end;

procedure TdmPedidos.InstalarProcedimientoAlbaranFin(
  AEjecutor: TUniSQL);
begin
  EjecutarSqlInstalacion(
    AEjecutor,
    'DROP PROCEDURE IF EXISTS PRC_PED_CREAR_ALBARAN_FIN');
  EjecutarSqlInstalacion(
    AEjecutor,
    'CREATE PROCEDURE PRC_PED_CREAR_ALBARAN_FIN(' +
        '  IN p_NUMERO_ALB varchar(20), ' +
        '  IN p_SERIE_ALB varchar(20), ' +
        '  IN p_NUMERO_PED varchar(20), ' +
        '  IN p_SERIE_PED varchar(20), ' +
        '  IN p_USUARIO varchar(100)) ' +
        'BEGIN ' +
        '  DECLARE v_total_base decimal(18,6) DEFAULT 0; ' +
        '  DECLARE v_total_iva decimal(18,6) DEFAULT 0; ' +
        '  DECLARE v_pendientes int DEFAULT 0; ' +
        '  SELECT IFNULL(SUM(CANTIDAD_ALBLIN * ' +
        '                    PRECIO_VENTA_SIVA_ARTICULO_ALBLIN), 0), ' +
        '         IFNULL(SUM(CANTIDAD_ALBLIN * ' +
        '              (PRECIO_VENTA_CIVA_ARTICULO_ALBLIN - ' +
        '               PRECIO_VENTA_SIVA_ARTICULO_ALBLIN)), 0) ' +
        '    INTO v_total_base, v_total_iva ' +
        '    FROM fza_albaranes_lineas ' +
        '   WHERE NUMERO_ALB_ALBLIN = p_NUMERO_ALB ' +
        '     AND SERIE_ALB_ALBLIN = p_SERIE_ALB; ' +
        '  UPDATE fza_albaranes ' +
        '     SET TOTAL_BASES_ALB = v_total_base, ' +
        '         TOTAL_IMPUESTOS_ALB = v_total_iva, ' +
        '         TOTAL_LIQUIDO_ALB = v_total_base + v_total_iva, ' +
        '         INSTANTE_MODIF = NOW(), ' +
        '         USUARIO_MODIF = p_USUARIO ' +
        '   WHERE NUMERO_ALB = p_NUMERO_ALB ' +
        '     AND SERIE_ALB = p_SERIE_ALB; ' +
        '  SELECT COUNT(*) INTO v_pendientes ' +
        '    FROM fza_pedidos_lineas ' +
        '   WHERE NUMERO_PED_PEDLIN = p_NUMERO_PED ' +
        '     AND SERIE_PED_PEDLIN = p_SERIE_PED ' +
        '     AND IFNULL(CANTIDAD_PEDLIN, 0) > ' +
        '         IFNULL(CANTIDAD_ENTREGADA_PEDLIN, 0); ' +
        '  IF v_pendientes = 0 THEN ' +
        '    UPDATE fza_pedidos ' +
        '       SET ESTADO_PED = ''ENTREGADO'', ' +
        '           INSTANTE_MODIF = NOW(), ' +
        '           USUARIO_MODIF = p_USUARIO ' +
        '     WHERE NUMERO_PED = p_NUMERO_PED ' +
        '       AND SERIE_PED = p_SERIE_PED; ' +
        '  ELSE ' +
        '    UPDATE fza_pedidos ' +
        '       SET ESTADO_PED = ''PARCIAL'', ' +
        '           INSTANTE_MODIF = NOW(), ' +
        '           USUARIO_MODIF = p_USUARIO ' +
        '     WHERE NUMERO_PED = p_NUMERO_PED ' +
        '       AND SERIE_PED = p_SERIE_PED; ' +
        '  END IF; ' +
        'END');
end;

procedure TdmPedidos.InstalarProcedimientoAlbaranInicio(
  AEjecutor: TUniSQL);
begin
  EjecutarSqlInstalacion(
    AEjecutor,
    'DROP PROCEDURE IF EXISTS PRC_PED_CREAR_ALBARAN_INICIO');
  EjecutarSqlInstalacion(
    AEjecutor,
    'CREATE PROCEDURE PRC_PED_CREAR_ALBARAN_INICIO(' +
        '  IN p_NUMERO_PED varchar(20), ' +
        '  IN p_SERIE_PED varchar(20), ' +
        '  IN p_USUARIO varchar(100), ' +
        '  OUT p_NUMERO_ALB varchar(20), ' +
        '  OUT p_SERIE_ALB varchar(20)) ' +
        'BEGIN ' +
        '  DECLARE v_serie varchar(20); ' +
        '  DECLARE v_numero varchar(20); ' +
        '  SELECT SERIE_PED INTO v_serie ' +
        '    FROM fza_pedidos ' +
        '   WHERE NUMERO_PED = p_NUMERO_PED ' +
        '     AND SERIE_PED = p_SERIE_PED; ' +
        '  SELECT LPAD(IFNULL(MAX(CAST(NUMERO_ALB AS UNSIGNED)), 0) ' +
        '              + 1, 6, ''0'') ' +
        '    INTO v_numero ' +
        '    FROM fza_albaranes ' +
        '   WHERE SERIE_ALB = v_serie; ' +
        '  INSERT INTO fza_albaranes (' +
        '    NUMERO_ALB, SERIE_ALB, FECHA_ALB, ' +
        '    INSTANTE_MOVIMIENTO_ALB, ESTADO_ALB, ' +
        '    NUMERO_PED_ALB, SERIE_PED_ALB, ' +
        '    CODIGO_EMP_ALB, CODIGO_ALM_ALB, ' +
        '    RAZON_SOCIAL_EMPRESA_ALB, NIF_EMPRESA_ALB, ' +
        '    MOVIL_EMPRESA_ALB, EMAIL_EMPRESA_ALB, ' +
        '    DIRECCION1_EMPRESA_ALB, DIRECCION2_EMPRESA_ALB, ' +
        '    POBLACION_EMPRESA_ALB, PROVINCIA_EMPRESA_ALB, ' +
        '    CODIGO_PAI_EMPRESA_ALB, NOMBRE_PAI_EMPRESA_ALB, ' +
        '    CODIGO_POSTAL_EMPRESA_ALB, GRUPO_ZONA_IVA_EMPRESA_ALB, ' +
        '    CODIGO_CLI_ALB, RAZON_SOCIAL_CLIENTE_ALB, ' +
        '    NIF_CLIENTE_ALB, MOVIL_CLIENTE_ALB, EMAIL_CLIENTE_ALB, ' +
        '    DIRECCION1_CLIENTE_ALB, DIRECCION2_CLIENTE_ALB, ' +
        '    POBLACION_CLIENTE_ALB, PROVINCIA_CLIENTE_ALB, ' +
        '    CODIGO_POSTAL_CLIENTE_ALB, CODIGO_PAI_CLIENTE_ALB, ' +
        '    NOMBRE_PAI_CLIENTE_ALB, NOMBRE_CLI_ENVIO_ALB, ' +
        '    MOVIL_CLIENTE_ENVIO_ALB, DIRECCION1_CLIENTE_ENVIO_ALB, ' +
        '    DIRECCION2_CLIENTE_ENVIO_ALB, POBLACION_CLIENTE_ENVIO_ALB, ' +
        '    PROVINCIA_CLIENTE_ENVIO_ALB, CODIGO_POSTAL_CLIENTE_ENVIO_ALB, ' +
        '    CODIGO_PAI_CLIENTE_ENVIO_ALB, NOMBRE_PAI_CLIENTE_ENVIO_ALB, ' +
        '    TRANSPORTISTA_ALB, CODIGO_IVA_ALB, ' +
        '    ESIVA_RECARGO_CLIENTE_ALB, ESIVA_EXENTO_CLIENTE_ALB, ' +
        '    ESINTRACOMUNITARIO_CLIENTE_ALB, TARIFA_ARTICULO_CLIENTE_ALB, ' +
        '    ESIMP_INCL_TARIFA_CLIENTE_ALB, PORCENTAJE_IVAN_ALB, ' +
        '    PORCENTAJE_IVAR_ALB, PORCENTAJE_IVAS_ALB, PORCENTAJE_IVAE_ALB, ' +
        '    FORMA_PAGO_ALB, CONTADOR_LINEAS_ALB, ' +
        '    INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
        '  SELECT v_numero, v_serie, CURRENT_DATE(), NOW(), ''ABIERTO'', ' +
        '         p_NUMERO_PED, p_SERIE_PED, ' +
        '         P.CODIGO_EMP_PED, P.CODIGO_ALM_PED, ' +
        '         P.RAZON_SOCIAL_EMPRESA_PED, P.NIF_EMPRESA_PED, ' +
        '         P.MOVIL_EMPRESA_PED, P.EMAIL_EMPRESA_PED, ' +
        '         P.DIRECCION1_EMPRESA_PED, P.DIRECCION2_EMPRESA_PED, ' +
        '         P.POBLACION_EMPRESA_PED, P.PROVINCIA_EMPRESA_PED, ' +
        '         P.CODIGO_PAI_EMPRESA_PED, P.NOMBRE_PAI_EMPRESA_PED, ' +
        '         P.CODIGO_POSTAL_EMPRESA_PED, P.GRUPO_ZONA_IVA_EMPRESA_PED, ' +
        '         P.CODIGO_CLI_PED, P.RAZON_SOCIAL_CLIENTE_FISCAL_PED, ' +
        '         P.NIF_CLIENTE_PED, P.MOVIL_CLIENTE_FISCAL_PED, ' +
        '         P.EMAIL_CLIENTE_PED, P.DIRECCION1_CLIENTE_FISCAL_PED, ' +
        '         P.DIRECCION2_CLIENTE_FISCAL_PED, ' +
        '         P.POBLACION_CLIENTE_FISCAL_PED, ' +
        '         P.PROVINCIA_CLIENTE_FISCAL_PED, ' +
        '         P.CODIGO_POSTAL_CLIENTE_FISCAL_PED, ' +
        '         P.CODIGO_PAI_CLIENTE_FISCAL_PED, ' +
        '         P.NOMBRE_PAI_CLIENTE_FISCAL_PED, ' +
        '         P.NOMBRE_CLI_ENVIO_PED, P.MOVIL_CLIENTE_ENVIO_PED, ' +
        '         P.DIRECCION1_CLIENTE_ENVIO_PED, ' +
        '         P.DIRECCION2_CLIENTE_ENVIO_PED, ' +
        '         P.POBLACION_CLIENTE_ENVIO_PED, ' +
        '         P.PROVINCIA_CLIENTE_ENVIO_PED, ' +
        '         P.CODIGO_POSTAL_CLIENTE_ENVIO_PED, ' +
        '         P.CODIGO_PAI_CLIENTE_ENVIO_PED, ' +
        '         P.NOMBRE_PAI_CLIENTE_ENVIO_PED, ' +
        '         P.TRANSPORTISTAPS_PED, P.CODIGO_IVA_PED, ' +
        '         P.ESIVA_RECARGO_CLIENTE_PED, P.ESIVA_EXENTO_CLIENTE_PED, ' +
        '         P.ESINTRACOMUNITARIO_CLIENTE_PED, ' +
        '         P.TARIFA_ARTICULO_CLIENTE_PED, ' +
        '         P.ESIMP_INCL_TARIFA_CLIENTE_PED, P.PORCENTAJE_IVAN_PED, ' +
        '         P.PORCENTAJE_IVAR_PED, P.PORCENTAJE_IVAS_PED, ' +
        '         P.PORCENTAJE_IVAE_PED, P.FORMA_PAGO_PED, ''0'', ' +
        '         NOW(), p_USUARIO, p_USUARIO ' +
        '    FROM fza_pedidos P ' +
        '   WHERE P.NUMERO_PED = p_NUMERO_PED ' +
        '     AND P.SERIE_PED = p_SERIE_PED; ' +
        '  SET p_NUMERO_ALB = v_numero; ' +
        '  SET p_SERIE_ALB = v_serie; ' +
        'END');
end;

procedure TdmPedidos.InstalarProcedimientoAlbaranLinea(
  AEjecutor: TUniSQL);
begin
  EjecutarSqlInstalacion(
    AEjecutor,
    'DROP PROCEDURE IF EXISTS PRC_PED_CREAR_ALBARAN_LINEA');
  EjecutarSqlInstalacion(
    AEjecutor,
    'CREATE PROCEDURE PRC_PED_CREAR_ALBARAN_LINEA(' +
        '  IN p_NUMERO_ALB varchar(20), ' +
        '  IN p_SERIE_ALB varchar(20), ' +
        '  IN p_NUMERO_PED varchar(20), ' +
        '  IN p_SERIE_PED varchar(20), ' +
        '  IN p_LINEA_PED varchar(4), ' +
        '  IN p_CANTIDAD decimal(19,6), ' +
        '  IN p_CODIGO_ALM varchar(10), ' +
        '  IN p_USUARIO varchar(100)) ' +
        'PRC: BEGIN ' +
        '  DECLARE v_linea varchar(4); ' +
        '  DECLARE v_pedida decimal(19,6) DEFAULT 0; ' +
        '  DECLARE v_albaranada decimal(19,6) DEFAULT 0; ' +
        '  DECLARE v_objetivo decimal(19,6) DEFAULT 0; ' +
        '  DECLARE v_pendiente decimal(19,6) DEFAULT 0; ' +
        '  DECLARE v_cantidad decimal(19,6) DEFAULT 0; ' +
        '  SELECT IFNULL(CANTIDAD_PEDLIN, 0) INTO v_pedida ' +
        '    FROM fza_pedidos_lineas ' +
        '   WHERE NUMERO_PED_PEDLIN = p_NUMERO_PED ' +
        '     AND SERIE_PED_PEDLIN = p_SERIE_PED ' +
        '     AND LINEA_PEDLIN = p_LINEA_PED; ' +
        '  SELECT IFNULL(SUM(CANTIDAD_ALBLIN), 0) INTO v_albaranada ' +
        '    FROM fza_albaranes_lineas ' +
        '   WHERE NUMERO_PED_ALBLIN = p_NUMERO_PED ' +
        '     AND SERIE_PED_ALBLIN = p_SERIE_PED ' +
        '     AND LINEA_PED_ALBLIN = p_LINEA_PED; ' +
        '  SET v_objetivo = LEAST(IFNULL(p_CANTIDAD, 0), v_pedida); ' +
        '  SET v_pendiente = v_pedida - v_albaranada; ' +
        '  SET v_cantidad = v_objetivo - v_albaranada; ' +
        '  IF v_pedida <= 0 OR v_pendiente <= 0 OR v_cantidad <= 0 THEN ' +
        '    LEAVE PRC; ' +
        '  END IF; ' +
        '  IF v_cantidad > v_pendiente THEN ' +
        '    SET v_cantidad = v_pendiente; ' +
        '  END IF; ' +
        '  UPDATE fza_albaranes ' +
        '     SET CONTADOR_LINEAS_ALB = LPAD(LAST_INSERT_ID(' +
        '           IFNULL(CAST(NULLIF(CONTADOR_LINEAS_ALB, '''') ' +
        '           AS UNSIGNED), 0) + 10), 8, ''0'') ' +
        '   WHERE NUMERO_ALB = p_NUMERO_ALB ' +
        '     AND SERIE_ALB = p_SERIE_ALB; ' +
        '  IF ROW_COUNT() = 0 THEN ' +
        '    LEAVE PRC; ' +
        '  END IF; ' +
        '  SET v_linea = LPAD(LAST_INSERT_ID(), 4, ''0''); ' +
        '  INSERT INTO fza_albaranes_lineas (' +
        '    NUMERO_ALB_ALBLIN, SERIE_ALB_ALBLIN, LINEA_ALBLIN, ' +
        '    NUMERO_PED_ALBLIN, SERIE_PED_ALBLIN, LINEA_PED_ALBLIN, ' +
        '    CODIGO_ART_ALBLIN, CODIGO_UNIDAD_ALBLIN, ' +
        '    CODIGO_FAM_ALBLIN, NOMBRE_FAM_ALBLIN, ' +
        '    DESCRIPCION_ARTICULO_ALBLIN, TIPO_CANTIDAD_ARTICULO_ALBLIN, ' +
        '    CANTIDAD_ALBLIN, CODIGO_TAR_ALBLIN, ESIMP_INCL_TARIFA_ALBLIN, ' +
        '    TIPO_IVA_ARTICULO_ALBLIN, PORCENTAJE_IVA_ALBLIN, ' +
        '    PRECIO_VENTA_SIVA_ARTICULO_ALBLIN, ' +
        '    PRECIO_VENTA_CIVA_ARTICULO_ALBLIN, TOTAL_ALBLIN, ' +
        '    CODIGO_ALMACEN_ALBLIN, INSTANTE_ALTA, USUARIO_ALTA, ' +
        '    USUARIO_MODIF) ' +
        '  SELECT p_NUMERO_ALB, p_SERIE_ALB, v_linea, ' +
        '         p_NUMERO_PED, p_SERIE_PED, p_LINEA_PED, ' +
        '         PL.CODIGO_ART_PEDLIN, ' +
        '         COALESCE(NULLIF(PL.CODIGOPRODPS_PEDLIN, ''''), ' +
        '                  NULLIF(PL.CODIGO_UNIDAD_PEDLIN, ''''), ' +
        '                  PL.CODIGO_ART_PEDLIN), ' +
        '         PL.CODIGO_FAM_PEDLIN, PL.NOMBRE_FAM_PEDLIN, ' +
        '         PL.DESCRIPCION_ARTICULO_PEDLIN, ' +
        '         PL.TIPO_CANTIDAD_ARTICULO_PEDLIN, ' +
        '         v_cantidad, PL.CODIGO_TAR_PEDLIN, ' +
        '         PL.ESIMP_INCL_TARIFA_PEDLIN, ' +
        '         PL.TIPO_IVA_ARTICULO_PEDLIN, PL.PORCENTAJE_IVA_PEDLIN, ' +
        '         PL.PRECIO_VENTA_SIVA_ARTICULO_PEDLIN, ' +
        '         PL.PRECIO_VENTA_CIVA_ARTICULO_PEDLIN, ' +
        '         (v_cantidad * PL.PRECIO_VENTA_SIVA_ARTICULO_PEDLIN), ' +
        '         COALESCE(NULLIF(p_CODIGO_ALM, ''''), ' +
        '                  PL.CODIGO_ALMACEN_PEDLIN), ' +
        '         NOW(), p_USUARIO, p_USUARIO ' +
        '    FROM fza_pedidos_lineas PL ' +
        '   WHERE PL.NUMERO_PED_PEDLIN = p_NUMERO_PED ' +
        '     AND PL.SERIE_PED_PEDLIN = p_SERIE_PED ' +
        '     AND PL.LINEA_PEDLIN = p_LINEA_PED; ' +
        '  UPDATE fza_pedidos_lineas ' +
        '     SET CANTIDAD_ENTREGADA_PEDLIN = v_albaranada + v_cantidad, ' +
        '         CANTIDAD_PENDIENTE_PEDLIN = ' +
        '           GREATEST(CANTIDAD_PEDLIN - ' +
        '                    (v_albaranada + v_cantidad), 0), ' +
        '         CANTIDAD_A_ALBARANAR_PEDLIN = 0, ' +
        '         ESENTREGADA_PEDLIN = CASE ' +
        '           WHEN CANTIDAD_PEDLIN <= v_albaranada + v_cantidad ' +
        '           THEN ''S'' ELSE ''N'' END, ' +
        '         INSTANTE_MODIF = NOW(), ' +
        '         USUARIO_MODIF = p_USUARIO ' +
        '   WHERE NUMERO_PED_PEDLIN = p_NUMERO_PED ' +
        '     AND SERIE_PED_PEDLIN = p_SERIE_PED ' +
        '     AND LINEA_PEDLIN = p_LINEA_PED; ' +
        'END');
end;

procedure TdmPedidos.InstalarProcedimientos;
var
  Ejecutor: TUniSQL;
begin
  if not FProcsInstalados then
  begin
    Ejecutor := TUniSQL.Create(nil);
    try
      Ejecutor.Connection := ConexionPrincipal;
      InstalarProcedimientoAlbaranFin(Ejecutor);
      InstalarProcedimientoAlbaranInicio(Ejecutor);
      InstalarProcedimientoAlbaranLinea(Ejecutor);
      FProcsInstalados := True;
    finally
      FreeAndNil(Ejecutor);
    end;
  end;
end;

function TdmPedidos.CrearAlbaranDesdePedido(out sNumeroAlb, sSerieAlb: string;
                                            aLineas: TList<TPair<string,
                                            Currency>>;
                                            const ACodigoAlmacen: string;
                                            const AAlbExistenteNum: string;
                                            const AAlbExistenteSerie: string)
                                            : Boolean;
var
  i: Integer;
  sNumeroPed, sSeriePed: string;
  bTransPropia: Boolean;
  par: TPair<string, Currency>;
begin
  Result := False;
  sNumeroAlb := ''; sSerieAlb := '';
  if (aLineas <> nil) and (aLineas.Count > 0) then
  begin
  // Asegura que los procedimientos existen (idempotente y barato).
  // OJO: es DDL (CREATE PROCEDURE) y debe quedar FUERA de la
  // transaccion: el DDL hace commit implicito en MySQL/MariaDB.
  InstalarProcedimientos;

  sNumeroPed := unqryTablaG.FieldByName('NUMERO_PED').AsString;
  sSeriePed  := unqryTablaG.FieldByName('SERIE_PED').AsString;

  // Alta atomica: cabecera + lineas + totales/estado del pedido se
  // confirman o se deshacen juntos (mismo patron bTransPropia que
  // TdmAlbaranes).
  bTransPropia := not ConexionPrincipal.InTransaction;
  if bTransPropia then
    ConexionPrincipal.StartTransaction;
  try
    // 1) Cabecera del albarán. Si el llamador pasa un albarán existente
    //    (AAlbExistenteNum), las líneas se añaden a ese albarán y se omite
    //    crear cabecera; si no, se crea uno nuevo desde el pedido.
    if Trim(AAlbExistenteNum) <> '' then
    begin
      sNumeroAlb := AAlbExistenteNum;
      sSerieAlb  := AAlbExistenteSerie;
      CopiarFormaPagoPedidoAAlbaran(sSeriePed, sNumeroPed, sSerieAlb,
        sNumeroAlb, False);
    end
    else
    begin
      unstrdprcCrearAlbaranInicio.Params.Clear;
      unstrdprcCrearAlbaranInicio.Params.CreateParam(
        ftString, 'p_NUMERO_PED', ptInput);
      unstrdprcCrearAlbaranInicio.Params.CreateParam(
        ftString, 'p_SERIE_PED', ptInput);
      unstrdprcCrearAlbaranInicio.Params.CreateParam(
        ftString, 'p_USUARIO', ptInput);
      unstrdprcCrearAlbaranInicio.Params.CreateParam(
        ftString, 'p_NUMERO_ALB', ptOutput);
      unstrdprcCrearAlbaranInicio.Params.CreateParam(
        ftString, 'p_SERIE_ALB', ptOutput);
      unstrdprcCrearAlbaranInicio.ParamByName(
        'p_NUMERO_PED').AsString := sNumeroPed;
      unstrdprcCrearAlbaranInicio.ParamByName(
        'p_SERIE_PED').AsString := sSeriePed;
      unstrdprcCrearAlbaranInicio.ParamByName('p_USUARIO').AsString :=
        IdentidadSesion.Usuario;
      unstrdprcCrearAlbaranInicio.ExecProc;
      sNumeroAlb := unstrdprcCrearAlbaranInicio.ParamByName(
        'p_NUMERO_ALB').AsString;
      sSerieAlb := unstrdprcCrearAlbaranInicio.ParamByName(
        'p_SERIE_ALB').AsString;
      CopiarFormaPagoPedidoAAlbaran(sSeriePed, sNumeroPed, sSerieAlb,
        sNumeroAlb, True);
    end;

    // 2) Por cada línea con cantidad > 0 generamos línea de albarán
    for i := 0 to aLineas.Count - 1 do
    begin
      par := aLineas[i];
      if par.Value > 0 then
      begin
        unstrdprcCrearAlbaranLinea.Params.Clear;
        unstrdprcCrearAlbaranLinea.Params.CreateParam(
          ftString, 'p_NUMERO_ALB', ptInput);
        unstrdprcCrearAlbaranLinea.Params.CreateParam(
          ftString, 'p_SERIE_ALB', ptInput);
        unstrdprcCrearAlbaranLinea.Params.CreateParam(
          ftString, 'p_NUMERO_PED', ptInput);
        unstrdprcCrearAlbaranLinea.Params.CreateParam(
          ftString, 'p_SERIE_PED', ptInput);
        unstrdprcCrearAlbaranLinea.Params.CreateParam(
          ftString, 'p_LINEA_PED', ptInput);
        unstrdprcCrearAlbaranLinea.Params.CreateParam(
          ftBCD, 'p_CANTIDAD', ptInput);
        unstrdprcCrearAlbaranLinea.Params.CreateParam(
          ftString, 'p_CODIGO_ALM', ptInput);
        unstrdprcCrearAlbaranLinea.Params.CreateParam(
          ftString, 'p_USUARIO', ptInput);
        unstrdprcCrearAlbaranLinea.ParamByName(
          'p_NUMERO_ALB').AsString := sNumeroAlb;
        unstrdprcCrearAlbaranLinea.ParamByName(
          'p_SERIE_ALB').AsString := sSerieAlb;
        unstrdprcCrearAlbaranLinea.ParamByName(
          'p_NUMERO_PED').AsString := sNumeroPed;
        unstrdprcCrearAlbaranLinea.ParamByName(
          'p_SERIE_PED').AsString := sSeriePed;
        unstrdprcCrearAlbaranLinea.ParamByName(
          'p_LINEA_PED').AsString := par.Key;
        unstrdprcCrearAlbaranLinea.ParamByName(
          'p_CANTIDAD').AsCurrency := par.Value;
        unstrdprcCrearAlbaranLinea.ParamByName(
          'p_CODIGO_ALM').AsString := ACodigoAlmacen;
        unstrdprcCrearAlbaranLinea.ParamByName('p_USUARIO').AsString :=
          IdentidadSesion.Usuario;
        unstrdprcCrearAlbaranLinea.ExecProc;
      end;
    end;

    // 3) Recalcular totales del albarán y refrescar estado del pedido
    unstrdprcCrearAlbaranFin.Params.Clear;
    unstrdprcCrearAlbaranFin.Params.CreateParam(
      ftString, 'p_NUMERO_ALB', ptInput);
    unstrdprcCrearAlbaranFin.Params.CreateParam(
      ftString, 'p_SERIE_ALB', ptInput);
    unstrdprcCrearAlbaranFin.Params.CreateParam(
      ftString, 'p_NUMERO_PED', ptInput);
    unstrdprcCrearAlbaranFin.Params.CreateParam(
      ftString, 'p_SERIE_PED', ptInput);
    unstrdprcCrearAlbaranFin.Params.CreateParam(
      ftString, 'p_USUARIO', ptInput);
    unstrdprcCrearAlbaranFin.ParamByName(
      'p_NUMERO_ALB').AsString := sNumeroAlb;
    unstrdprcCrearAlbaranFin.ParamByName(
      'p_SERIE_ALB').AsString := sSerieAlb;
    unstrdprcCrearAlbaranFin.ParamByName(
      'p_NUMERO_PED').AsString := sNumeroPed;
    unstrdprcCrearAlbaranFin.ParamByName(
      'p_SERIE_PED').AsString := sSeriePed;
    unstrdprcCrearAlbaranFin.ParamByName('p_USUARIO').AsString :=
      IdentidadSesion.Usuario;
    unstrdprcCrearAlbaranFin.ExecProc;

    if bTransPropia then
      ConexionPrincipal.Commit;
  except
    on E: Exception do
    begin
      if bTransPropia then
        ConexionPrincipal.Rollback;
      raise;
    end;
  end;
  // 4) Refrescar las queries del pedido en pantalla (fuera de la
  // transaccion: solo lectura para la UI)

  unqryPedidosLineas.Close; unqryPedidosLineas.Open;
  unqryAlbaranes.Close;     unqryAlbaranes.Open;
  unqryTablaG.RefreshRecord;
  Result := True;
  end;
end;

function TdmPedidos.ExistePedidoPrestaShop(const sIdPS: string): Boolean;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionPrincipal;
    q.SQL.Text := 'SELECT 1 FROM fza_pedidos WHERE IDPS_PED = :id LIMIT 1';
    q.ParamByName('id').AsString := sIdPS;
    q.Open;
    Result := q.RecordCount > 0;
    q.Close;
  finally
    FreeAndNil(q);
  end;
end;

function TdmPedidos.ObtenerContador(const sTipo: string): string;
begin
  unstrdprcGetContador.Params.Clear;
  unstrdprcGetContador.Params.CreateParam(
    ftString, 'ptipodoc', ptInput);
  unstrdprcGetContador.Params.CreateParam(
    ftString, 'pcont', ptOutput);
  unstrdprcGetContador.Params.CreateParam(
    ftString, 'pUSUARIO_MODIF', ptInput);
  unstrdprcGetContador.ParamByName('ptipodoc').AsString := sTipo;
  unstrdprcGetContador.ParamByName('pUSUARIO_MODIF').AsString :=
    IdentidadSesion.Usuario;
  unstrdprcGetContador.ExecProc;
  Result := unstrdprcGetContador.ParamByName('pcont').AsString;
end;

function TdmPedidos.ResolverCodigoCliente(aOrder: TOrder): string;
var
  q: TUniQuery;
  sNif, sEmail, sRazon: string;
  sDir1, sDir2, sPobl, sProv, sCP, sMovil, sOrden: string;
begin
  Result := '0';
  if aOrder <> nil then
  begin
  // Identificadores de busqueda: se prioriza el domicilio fiscal (Bil)
  sNif := aOrder.Vat_numberBil;
  if sNif = '' then
    sNif := aOrder.DniBil;
  if sNif = '' then
    sNif := aOrder.Vat_numberDel;
  if sNif = '' then
    sNif := aOrder.DniDel;
  sEmail := aOrder.custMail;
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionPrincipal;
    // 1) Buscar por NIF
    if sNif <> '' then
    begin
      q.SQL.Text :=
        'SELECT CODIGO_CLI_CLI FROM fza_clientes WHERE NIF_CLI = :nif LIMIT 1';
      q.ParamByName('nif').AsString := sNif;
      q.Open;
      if q.RecordCount > 0 then
        Result := q.Fields[0].AsString;
      q.Close;
    end;
    // 2) Si no hay match por NIF, buscar por email
    if (Result = '0') and (sEmail <> '') then
    begin
      q.SQL.Text :=
        'SELECT CODIGO_CLI_CLI FROM fza_clientes WHERE EMAIL_CLI = :ema ' +
        'LIMIT 1';
      q.ParamByName('ema').AsString := sEmail;
      q.Open;
      if q.RecordCount > 0 then
        Result := q.Fields[0].AsString;
      q.Close;
    end;
    // 3) Si sigue sin encontrarse, dar de alta el cliente nuevo
    if Result = '0' then
    begin
      // Datos del nuevo cliente (domicilio fiscal con fallback a envio)
      sRazon := aOrder.CompanyBil;
      if sRazon = '' then
        sRazon := Trim(aOrder.FirstnameBil + ' ' + aOrder.LastNameBil);
      if sRazon = '' then
        sRazon := aOrder.custName;
      sDir1 := aOrder.Address1Bil;
      if sDir1 = '' then
        sDir1 := aOrder.Address1Del;
      sDir2 := aOrder.Address2Bil;
      if sDir2 = '' then
        sDir2 := aOrder.Address2Del;
      sPobl := aOrder.CityBil;
      if sPobl = '' then
        sPobl := aOrder.CityDel;
      sProv := aOrder.NameStateBil;
      if sProv = '' then
        sProv := aOrder.NameStateDel;
      sCP := aOrder.PostcodeBil;
      if sCP = '' then
        sCP := aOrder.PostcodeDel;
      sMovil := aOrder.PhoneBil;
      if sMovil = '' then
        sMovil := aOrder.PhoneDel;
      // Contadores (PRC_GET_NEXT_CONT hace COMMIT propio: fuera de la tx)
      Result := ObtenerContador('CL');
      sOrden := ObtenerContador('CO');
      q.SQL.Text :=
        'INSERT INTO fza_clientes (CODIGO_CLI_CLI, ORDEN_CLI, ' +
        ' RAZON_SOCIAL_CLI, NIF_CLI, EMAIL_CLI, MOVIL_CLI, ' +
        ' DIRECCION1_CLI, DIRECCION2_CLI, POBLACION_CLI, PROVINCIA_CLI, ' +
        ' CODIGO_POSTAL_CLI, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (:cod, :ord, :raz, :nif, :ema, :mov, ' +
        '        :dir1, :dir2, :pob, :prov, :cp, NOW(), :usu, :usu)';
      q.ParamByName('cod').AsString  := Result;
      q.ParamByName('ord').AsInteger := StrToIntDef(sOrden, 0);
      q.ParamByName('raz').AsString  := sRazon;
      q.ParamByName('nif').AsString  := sNif;
      q.ParamByName('ema').AsString  := sEmail;
      q.ParamByName('mov').AsString  := sMovil;
      q.ParamByName('dir1').AsString := sDir1;
      q.ParamByName('dir2').AsString := sDir2;
      q.ParamByName('pob').AsString  := sPobl;
      q.ParamByName('prov').AsString := sProv;
      q.ParamByName('cp').AsString   := sCP;
      q.ParamByName('usu').AsString  := IdentidadSesion.Usuario;
      q.Execute;
    end;
  finally
    FreeAndNil(q);
  end;
  end;
end;

function TdmPedidos.ResolverCodigoArticulo(
  const oValidador: IArticulosValidador;
  const lp: TLineaPed): string;
var
  res: TArtResolucionEntrada;
  q: TUniQuery;
  sOrden, sDesc: string;
  bTx: Boolean;
begin
  Result := '';
  // 1) Match: primero por EAN13, luego por referencia PS
  res := oValidador.ResolverCodigoBarras(lp.sCodEAN13);
  if (not res.Encontrado) and (lp.sRefProd <> '') then
    res := oValidador.Resolver(lp.sRefProd);
  if res.Encontrado then
    Result := res.CodigoArticulo
  else
  begin
    // 2) Alta rapida: articulo sin variacion + SKU + codigo de barras.
    //    PS no aporta familia, por lo que se numera con el contador 'AR'.
    //    El IVA por defecto es 'N' (Normal); revisar si fuera reducido.
    Result := ObtenerContador('AR');
    sOrden := ObtenerContador('AO');
    sDesc  := lp.sDescripcion;
    if sDesc = '' then
      sDesc := 'Articulo PrestaShop ' + Result;
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionPrincipal;
      // Las 3 altas (articulo + SKU + barras) deben ser atomicas entre si
      bTx := not ConexionPrincipal.InTransaction;
      if bTx then
        ConexionPrincipal.StartTransaction;
      try
        // Articulo padre (ESVARIACION_ART = 'N', IVA Normal por defecto)
        q.SQL.Text :=
          'INSERT INTO fza_articulos (CODIGO_ART_ART, ORDEN_ART, ' +
          ' ESACTIVO_ART, TIPO_ART, DESCRIPCION_ART, TIPO_IVA_ART, ' +
          ' ESACTIVO_FIJO_ART, TIPO_CANTIDAD_ART, ESVARIACION_ART, ' +
          ' ESTRAZABLE_ART, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
          'VALUES (:cod, :ord, ''S'', ''ESTANDAR'', :des, ''N'', ' +
          '        ''N'', ''Uds'', ''N'', ''N'', NOW(), :usu, :usu)';
        q.ParamByName('cod').AsString  := Result;
        q.ParamByName('ord').AsInteger := StrToIntDef(sOrden, 0);
        q.ParamByName('des').AsString  := sDesc;
        q.ParamByName('usu').AsString  := IdentidadSesion.Usuario;
        q.Execute;
        // SKU unico (sin variacion: CODIGO_VAR_SKU = '-')
        q.SQL.Text :=
          'INSERT INTO fza_articulos_skus (CODIGO_UNIDAD_SKU, ' +
          ' CODIGO_ART_SKU, CODIGO_VAR_SKU, ESACTIVO_SKU, ' +
          ' INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
          'VALUES (:cod, :cod, ''-'', ''S'', NOW(), :usu, :usu)';
        q.ParamByName('cod').AsString := Result;
        q.ParamByName('usu').AsString := IdentidadSesion.Usuario;
        q.Execute;
        // Codigo de barras (solo si la linea trae EAN13)
        if lp.sCodEAN13 <> '' then
        begin
          q.SQL.Text :=
            'INSERT INTO fza_codigos_barras (CODIGO_BARRAS_CB, ' +
            ' CODIGO_UNIDAD_CB, TIPO_CODIGO_CB, ESPRINCIPAL_CB, ' +
            ' INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
            'VALUES (:ean, :cod, ''EAN13'', ''S'', NOW(), :usu, :usu)';
          q.ParamByName('ean').AsString := lp.sCodEAN13;
          q.ParamByName('cod').AsString := Result;
          q.ParamByName('usu').AsString := IdentidadSesion.Usuario;
          q.Execute;
        end;
        if bTx then
          ConexionPrincipal.Commit;
      except
        if bTx and ConexionPrincipal.InTransaction then
          ConexionPrincipal.Rollback;
        raise;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function TdmPedidos.ImportarPedidoPrestaShop(aOrder: TOrder): Boolean;
var
  aCodArt: TArray<string>;
  i: Integer;
  oEntrada: TEntradaPedidoPrestaShop;
  oEscrituras: TPedidosPrestaShopEscrituras;
  oValidador: IArticulosValidador;
  sAlmacen: string;
  sCodigoCli: string;
  sEmpresa: string;
  sNumero: string;
  sSerie: string;
begin
  Result := False;
  if Assigned(aOrder) and not ExistePedidoPrestaShop(aOrder.idPedido) then
  begin
    sEmpresa := Trim(UbicacionSesion.Empresa);
    if sEmpresa = '' then
      sEmpresa := '0';
    sAlmacen := Trim(UbicacionSesion.Almacen);
    if sAlmacen = '' then
    begin
      NotificarAdvertencia(SAvisoAlmacenSalidaPedidoObligatorio);
      Abort;
    end;
    unqryTablaG.Insert;
    try
      unqryTablaG.FieldByName('FECHA_PED').AsDateTime := Date;
      if Assigned(unqryTablaG.FindField('ESTADO_PED')) then
        unqryTablaG.FieldByName('ESTADO_PED').AsString := 'IMPORTADO';
      unqryTablaG.FieldByName('CODIGO_EMP_PED').AsString := sEmpresa;
      if Assigned(unqryTablaG.FindField('CODIGO_ALM_PED')) then
        unqryTablaG.FieldByName('CODIGO_ALM_PED').AsString := sAlmacen;
      unqryTablaG.FieldByName('CODIGO_CLI_PED').AsString := '0';
      GetCodigoAutoPedido;
      sNumero := unqryTablaG.FieldByName('NUMERO_PED').AsString;
      sSerie := unqryTablaG.FieldByName('SERIE_PED').AsString;
      unqryTablaG.Cancel;
    except
      unqryTablaG.Cancel;
      raise;
    end;
    sCodigoCli := ResolverCodigoCliente(aOrder);
    oValidador := TRepositorioArticulosValidador.Create(
      ConexionPrincipal);
    SetLength(aCodArt, aOrder.LineasPedido.Count);
    for i := 0 to aOrder.LineasPedido.Count - 1 do
      aCodArt[i] := ResolverCodigoArticulo(
        oValidador,
        aOrder.LineasPedido[i]);
    oValidador := nil;
    oEntrada := Default(TEntradaPedidoPrestaShop);
    oEntrada.Pedido := aOrder;
    oEntrada.Numero := sNumero;
    oEntrada.Serie := sSerie;
    oEntrada.CodigoCliente := sCodigoCli;
    oEntrada.Empresa := sEmpresa;
    oEntrada.Almacen := sAlmacen;
    oEntrada.CodigosArticulo := aCodArt;
    oEscrituras := TPedidosPrestaShopEscrituras.Create(
      ConexionPrincipal,
      IdentidadSesion.Usuario,
      RegistroLog);
    try
      oEscrituras.Ejecutar(oEntrada);
      Result := True;
    finally
      FreeAndNil(oEscrituras);
    end;
  end;
end;

initialization
  RegistrarDataModule(TdmPedidos);
  ForceReferenceToClass(TdmPedidos);

end.
