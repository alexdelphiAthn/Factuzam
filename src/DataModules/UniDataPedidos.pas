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
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, inLibUser, inMtoPrincipal,
  frxClass, frxDBSet,
  inLibPresta, frCoreClasses,
  inLibArticulosValidador;

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
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryPedidosLineasAfterInsert(DataSet: TDataSet);
    procedure unqryPedidosLineasBeforePost(DataSet: TDataSet);
    procedure unqryPedidosLineasAfterPost(DataSet: TDataSet);
    procedure unqryPedidosLineasBeforeDelete(DataSet: TDataSet);
  public
    procedure GetCodigoAutoPedido;
    procedure GetCodigoAutoCliente;
    procedure CalcularTotalesPedido;
    procedure CopiarEmpresaaPedido(DataSet: TDataSet);
    procedure CopiarClienteaPedido(DataSet: TDataSet);

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
    function ResolverCodigoArticulo(oValidador: TArticulosValidador;
                                    const lp: TLineaPed): string;

    procedure OpenTables;
    // Override: abre las queries detalle del Mto de Pedidos tras
    // unqryTablaG. Invocada desde TfrmMtoGen.AbrirTablaPrincipalAsync
    // en el callback main thread. OpenTables delega aqui.
    procedure AbrirDetalles; override;
  private
    FProcsInstalados: Boolean;
    FCalculandoTotales: Boolean;
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
  inLibGlobalVar, inLibLog, System.Diagnostics, System.UITypes, Vcl.Dialogs,
  inLibVentasImpuestos;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TdmPedidos }

procedure TdmPedidos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection           := inLibGlobalVar.oConn;
  unqryTablaG.BeforeDelete         := unqryTablaGBeforeDelete;
  unqryPedidosLineas.Connection    := inLibGlobalVar.oConn;
  unqryPedidosLineas.BeforeDelete  := unqryPedidosLineasBeforeDelete;
  unqryLinPedido.Connection        := inLibGlobalVar.oConn;
  unqryEmpDataPedido.Connection    := inLibGlobalVar.oConn;
  unqryCliDataPedido.Connection    := inLibGlobalVar.oConn;
  unqryArtDataLinPedido.Connection := inLibGlobalVar.oConn;
  unstrdprcCrearPedido.Connection            := inLibGlobalVar.oConn;
  unstrdprcGetContadorPedido.Connection      := inLibGlobalVar.oConn;
  unstrdprcGetContador.Connection            := inLibGlobalVar.oConn;
  unstrdprcCrearAlbaranInicio.Connection     := inLibGlobalVar.oConn;
  unstrdprcCrearAlbaranLinea.Connection      := inLibGlobalVar.oConn;
  unstrdprcCrearAlbaranFin.Connection        := inLibGlobalVar.oConn;
  unqryPerfiles.Connection         := inLibGlobalVar.oConn;
  unqryAlbaranes.Connection        := inLibGlobalVar.oConn;
  unqryMensajes.Connection         := inLibGlobalVar.oConn;
  unqryFormasPago.Connection       := inLibGlobalVar.oConn;
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
  inherited;
end;

procedure TdmPedidos.OpenTables;
begin
  // Delegar en AbrirDetalles para que el flujo (cronometro y logging)
  // sea unico independientemente de quien lo invoque.
  AbrirDetalles;
end;

procedure TdmPedidos.AbrirDetalles;
const
  TAG = 'Pedidos.AbrirDetalles';

  procedure AbrirConTiempo(qry: TUniQuery; const Nombre: string);
  var
    swQ: TStopwatch;
  begin
    if qry.Active then Exit;
    swQ := TStopwatch.StartNew;
    try
      qry.Open;
      inLibLog.Log.LogPerf(TAG, Nombre + ' OK', swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        inLibLog.Log.LogPerf(TAG,
          Nombre + ' ERROR=' + E.Message,
          swQ.ElapsedMilliseconds);
        raise;
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
  inLibLog.Log.LogPerf(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmPedidos.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  with unqryTablaG do
  begin
    FieldByName('FECHA_PED').AsDateTime := Date;
    FieldByName('CODIGO_EMP_PED').AsString := '0';
    FieldByName('CODIGO_CLI_PED').AsString := '0';
    FieldByName('NUMERO_PED').AsString     := '0';
    if FindField('SERIE_PED') <> nil then
      FieldByName('SERIE_PED').AsString    := 'A1';
    if FindField('ESTADO_PED') <> nil then
      FieldByName('ESTADO_PED').AsString   := 'ABIERTO';
    if FindField('ESCONSOLIDADO_PED') <> nil then
      FieldByName('ESCONSOLIDADO_PED').AsString := 'N';
  end;
end;

procedure TdmPedidos.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  if (unqryTablaG.FieldByName('NUMERO_PED').AsString = '0') or
     (unqryTablaG.FieldByName('NUMERO_PED').AsString = '') then
    GetCodigoAutoPedido;
  if (unqryTablaG.FieldByName('CODIGO_CLI_PED').AsString = '0') then
    GetCodigoAutoCliente;
  AplicarPorcentajesIvaVenta(inLibGlobalVar.oConn, unqryTablaG, 'PED');
  CalcularTotalesPedido;
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
  if MessageDlg(Format('¿Borrar el pedido de venta %s / %s?' +
                       sLineBreak +
                       'Se eliminaran sus lineas y se descontara el ' +
                       'pendiente de servir en stock.',
                       [sSerie, sNumero]),
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
  begin
    Abort;
  end;
  RestarPdteServirPedido(sSerie, sNumero, '');
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
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
  with unqryPedidosLineas do
  begin
    FieldByName('NUMERO_PED_PEDLIN').AsString :=
                                 unqryTablaG.FieldByName('NUMERO_PED').AsString;
    FieldByName('SERIE_PED_PEDLIN').AsString :=
                                  unqryTablaG.FieldByName('SERIE_PED').AsString;
    FieldByName('CANTIDAD_PEDLIN').AsFloat := 1;
    if FindField('CANTIDAD_ENTREGADA_PEDLIN') <> nil then
      FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsFloat := 0;
    if FindField('CANTIDAD_PENDIENTE_PEDLIN') <> nil then
      FieldByName('CANTIDAD_PENDIENTE_PEDLIN').AsFloat := 1;
    if FindField('ESENTREGADA_PEDLIN') <> nil then
      FieldByName('ESENTREGADA_PEDLIN').AsString := 'N';
  end;
end;

procedure TdmPedidos.unqryPedidosLineasBeforePost(DataSet: TDataSet);
var
  fCantidad, fEntregada, fPendiente: Double;
begin
  inherited;
  NormalizarArticuloSkuEnDataSet(inLibGlobalVar.oConn, unqryPedidosLineas,
    'CODIGO_ART_PEDLIN', '', 'CODBAR_ART_PEDLIN');
  RecalcularEntregasLinea;
  // El total de la línea siempre se mantiene coherente
  with unqryPedidosLineas do
  begin
    fCantidad  := FieldByName('CANTIDAD_PEDLIN').AsFloat;
    if FindField('CANTIDAD_ENTREGADA_PEDLIN') <> nil then
      fEntregada := FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsFloat
    else
      fEntregada := 0;
    fPendiente := fCantidad - fEntregada;
    if FindField('CANTIDAD_PENDIENTE_PEDLIN') <> nil then
      FieldByName('CANTIDAD_PENDIENTE_PEDLIN').AsFloat := fPendiente;
    if FindField('ESENTREGADA_PEDLIN') <> nil then
    begin
      if fPendiente <= 0 then
        FieldByName('ESENTREGADA_PEDLIN').AsString := 'S'
      else
        FieldByName('ESENTREGADA_PEDLIN').AsString := 'N';
    end;
    PrepararLineaFiscalVenta(inLibGlobalVar.oConn, unqryTablaG,
      unqryPedidosLineas, 'PED', 'PEDLIN', 'TOTAL_PEDLIN');
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
      q.Connection := inLibGlobalVar.oConn;
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
  fCant, fEntr: Double;
begin
  with unqryPedidosLineas do
  begin
    fCant := FieldByName('CANTIDAD_PEDLIN').AsFloat;
    if FindField('CANTIDAD_ENTREGADA_PEDLIN') = nil then Exit;
    fEntr := FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsFloat;
    if fEntr > fCant then
      FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsFloat := fCant;
    if FindField('CANTIDAD_PENDIENTE_PEDLIN') <> nil then
      FieldByName('CANTIDAD_PENDIENTE_PEDLIN').AsFloat := fCant - fEntr;
    if FindField('ESENTREGADA_PEDLIN') <> nil then
    begin
      if (fCant - fEntr) <= 0 then
        FieldByName('ESENTREGADA_PEDLIN').AsString := 'S'
      else
        FieldByName('ESENTREGADA_PEDLIN').AsString := 'N';
    end;
  end;
end;

procedure TdmPedidos.GetCodigoAutoPedido;
begin
  with unstrdprcGetContadorPedido do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'pserie',            ptInput);
    Params.CreateParam(ftString, 'ptipodoc',          ptInput);
    Params.CreateParam(ftString, 'pcont',             ptOutput);
    Params.CreateParam(ftString, 'pEMPRESA_CONTADOR', ptInput);
    Params.CreateParam(ftString, 'pUSUARIOMODIF',     ptInput);
    ParamByName('pserie').AsString    :=
      unqryTablaG.FieldByName('SERIE_PED').AsString;
    ParamByName('ptipodoc').AsString  := 'PE';
    ParamByName('pUSUARIOMODIF').AsString := oUser;
    ParamByName('pEMPRESA_CONTADOR').AsString :=
                                 unqryTablaG.FieldByName(
                                   'CODIGO_EMP_PED').AsString;
    ExecProc;
    unqryTablaG.FieldByName('NUMERO_PED').AsString :=
                                                  ParamByName('pcont').AsString;
  end;
end;

procedure TdmPedidos.GetCodigoAutoCliente;
begin
  with unstrdprcGetContador do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'ptipodoc',     ptInput);
    Params.CreateParam(ftString, 'pcont',        ptOutput);
    Params.CreateParam(ftString, 'pUSUARIO',     ptInput);
    ParamByName('ptipodoc').AsString := 'CL';
    ParamByName('pUSUARIO').AsString  := oUser;
    ExecProc;
    unqryTablaG.FieldByName('CODIGO_CLI_PED').AsString :=
                            ParamByName('pcont').AsString;
  end;
end;

procedure TdmPedidos.CalcularTotalesPedido;
begin
  if not FCalculandoTotales then
  begin
    FCalculandoTotales := True;
    try
      CalcularTotalesDocumentoVenta(inLibGlobalVar.oConn, unqryTablaG,
        unqryPedidosLineas, 'PED', 'TOTAL_PEDLIN',
        'TIPO_IVA_ARTICULO_PEDLIN', 'PORCENTAJE_IVA_PEDLIN');
    finally
      FCalculandoTotales := False;
    end;
  end;
end;

procedure TdmPedidos.CopiarEmpresaaPedido(DataSet: TDataSet);
begin
  with unqryTablaG do
  begin
    if (State <> dsEdit) and (State <> dsInsert) then
      Edit;
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
                            DataSet.FindField(
                              'ESREGIMENESPECIALAGRICOLA_EMP').AsString;
  end;
  AplicarPorcentajesIvaVenta(inLibGlobalVar.oConn, unqryTablaG, 'PED');
end;

procedure TdmPedidos.CopiarClienteaPedido(DataSet: TDataSet);
begin
  with unqryTablaG do
  begin
    if (State <> dsEdit) and (State <> dsInsert) then
      Edit;
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
    FindField('TARIFA_ARTICULO_CLIENTE_PED').AsString     :=
      DataSet.FindField('TARIFA_ARTICULO_CLI').AsString;
    if (FindField('FORMA_PAGO_PED') <> nil) and
       (DataSet.FindField('CODIGO_FP_CLI') <> nil) and
       (Trim(DataSet.FindField('CODIGO_FP_CLI').AsString) <> '') then
      FindField('FORMA_PAGO_PED').AsString :=
        Trim(DataSet.FindField('CODIGO_FP_CLI').AsString);
  end;
  AplicarPorcentajesIvaVenta(inLibGlobalVar.oConn, unqryTablaG, 'PED');
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
    q.Connection := inLibGlobalVar.oConn;
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
    q.ParamByName('u').AsString := oUser;
    if AForzar then
      q.ParamByName('forzar').AsString := 'S'
    else
      q.ParamByName('forzar').AsString := 'N';
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure TdmPedidos.InstalarProcedimientos;
var
  q: TUniSQL;

  procedure Run(const sSql: string);
  begin
    q.SQL.Text := sSql;
    q.Execute;
  end;

begin
  if FProcsInstalados then Exit;
  q := TUniSQL.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
    FProcsInstalados := True;
  finally
    FreeAndNil(q);
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
  par: TPair<string, Currency>;
  qAlm: TUniQuery;
  nMaxLineaPrev: Int64;
begin
  Result := False;
  sNumeroAlb := ''; sSerieAlb := '';
  if (aLineas = nil) or (aLineas.Count = 0) then Exit;

  // Asegura que los procedimientos existen (idempotente y barato).
  InstalarProcedimientos;

  sNumeroPed := unqryTablaG.FieldByName('NUMERO_PED').AsString;
  sSeriePed  := unqryTablaG.FieldByName('SERIE_PED').AsString;

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
    with unstrdprcCrearAlbaranInicio do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'p_NUMERO_PED', ptInput);
      Params.CreateParam(ftString, 'p_SERIE_PED',  ptInput);
      Params.CreateParam(ftString, 'p_USUARIO',    ptInput);
      Params.CreateParam(ftString, 'p_NUMERO_ALB', ptOutput);
      Params.CreateParam(ftString, 'p_SERIE_ALB',  ptOutput);
      ParamByName('p_NUMERO_PED').AsString := sNumeroPed;
      ParamByName('p_SERIE_PED').AsString  := sSeriePed;
      ParamByName('p_USUARIO').AsString    := oUser;
      ExecProc;
      sNumeroAlb := ParamByName('p_NUMERO_ALB').AsString;
      sSerieAlb  := ParamByName('p_SERIE_ALB').AsString;
    end;
    CopiarFormaPagoPedidoAAlbaran(sSeriePed, sNumeroPed, sSerieAlb,
      sNumeroAlb, True);
  end;

  // Mayor número de línea ya presente en el albarán destino. En un
  // albarán nuevo es 0; al añadir a uno existente sirve para fijar el
  // almacén sólo en las líneas que añadimos ahora (paso 2b).
  nMaxLineaPrev := 0;
  qAlm := TUniQuery.Create(nil);
  try
    qAlm.Connection := inLibGlobalVar.oConn;
    qAlm.SQL.Text :=
      'SELECT IFNULL(MAX(CAST(LINEA_ALBLIN AS UNSIGNED)), 0) AS MAXLIN ' +
      '  FROM fza_albaranes_lineas ' +
      ' WHERE NUMERO_ALB_ALBLIN = :n ' +
      '   AND SERIE_ALB_ALBLIN  = :s';
    qAlm.ParamByName('n').AsString := sNumeroAlb;
    qAlm.ParamByName('s').AsString := sSerieAlb;
    qAlm.Open;
    nMaxLineaPrev := qAlm.FieldByName('MAXLIN').AsLargeInt;
    qAlm.Close;
  finally
    FreeAndNil(qAlm);
  end;

  // 2) Por cada línea con cantidad > 0 generamos línea de albarán
  for i := 0 to aLineas.Count - 1 do
  begin
    par := aLineas[i];
    if par.Value <= 0 then Continue;
    with unstrdprcCrearAlbaranLinea do
    begin
      Params.Clear;
      Params.CreateParam(ftString,    'p_NUMERO_ALB', ptInput);
      Params.CreateParam(ftString,    'p_SERIE_ALB',  ptInput);
      Params.CreateParam(ftString,    'p_NUMERO_PED', ptInput);
      Params.CreateParam(ftString,    'p_SERIE_PED',  ptInput);
      Params.CreateParam(ftString,    'p_LINEA_PED',  ptInput);
      Params.CreateParam(ftBCD,       'p_CANTIDAD',   ptInput);
      Params.CreateParam(ftString,    'p_USUARIO',    ptInput);
      ParamByName('p_NUMERO_ALB').AsString := sNumeroAlb;
      ParamByName('p_SERIE_ALB').AsString  := sSerieAlb;
      ParamByName('p_NUMERO_PED').AsString := sNumeroPed;
      ParamByName('p_SERIE_PED').AsString  := sSeriePed;
      ParamByName('p_LINEA_PED').AsString  := par.Key;
      ParamByName('p_CANTIDAD').AsCurrency := par.Value;
      ParamByName('p_USUARIO').AsString    := oUser;
      ExecProc;
    end;
  end;

  // 2b) Fijar el almacén elegido en las líneas recién añadidas. La SP
  //     PRC_PED_CREAR_ALBARAN_LINEA copia el almacén de cada línea del
  //     pedido; aquí lo unificamos al almacén único escogido al emitir
  //     (de ahí salen también los movimientos de salida). Sólo tocamos
  //     las líneas nuevas (LINEA_ALBLIN > nMaxLineaPrev) para no alterar
  //     el almacén de las que ya hubiera en un albarán existente.
  if Trim(ACodigoAlmacen) <> '' then
  begin
    qAlm := TUniQuery.Create(nil);
    try
      qAlm.Connection := inLibGlobalVar.oConn;
      qAlm.SQL.Text :=
        'UPDATE fza_albaranes_lineas ' +
        '   SET CODIGO_ALMACEN_ALBLIN = :alm, ' +
        '       INSTANTE_MODIF        = NOW(), ' +
        '       USUARIO_MODIF         = :u ' +
        ' WHERE NUMERO_ALB_ALBLIN = :n ' +
        '   AND SERIE_ALB_ALBLIN  = :s ' +
        '   AND CAST(LINEA_ALBLIN AS UNSIGNED) > :maxlin';
      qAlm.ParamByName('alm').AsString      := ACodigoAlmacen;
      qAlm.ParamByName('u').AsString        := oUser;
      qAlm.ParamByName('n').AsString        := sNumeroAlb;
      qAlm.ParamByName('s').AsString        := sSerieAlb;
      qAlm.ParamByName('maxlin').AsLargeInt := nMaxLineaPrev;
      qAlm.ExecSQL;
    finally
      FreeAndNil(qAlm);
    end;
  end;

  // 3) Recalcular totales del albarán y refrescar estado del pedido
  with unstrdprcCrearAlbaranFin do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'p_NUMERO_ALB', ptInput);
    Params.CreateParam(ftString, 'p_SERIE_ALB',  ptInput);
    Params.CreateParam(ftString, 'p_NUMERO_PED', ptInput);
    Params.CreateParam(ftString, 'p_SERIE_PED',  ptInput);
    Params.CreateParam(ftString, 'p_USUARIO',    ptInput);
    ParamByName('p_NUMERO_ALB').AsString := sNumeroAlb;
    ParamByName('p_SERIE_ALB').AsString  := sSerieAlb;
    ParamByName('p_NUMERO_PED').AsString := sNumeroPed;
    ParamByName('p_SERIE_PED').AsString  := sSeriePed;
    ParamByName('p_USUARIO').AsString    := oUser;
    ExecProc;
  end;

  // 4) Refrescar las queries del pedido en pantalla
  unqryPedidosLineas.Close; unqryPedidosLineas.Open;
  unqryAlbaranes.Close;     unqryAlbaranes.Open;
  unqryTablaG.RefreshRecord;
  Result := True;
end;

function TdmPedidos.ExistePedidoPrestaShop(const sIdPS: string): Boolean;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
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
  with unstrdprcGetContador do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'ptipodoc', ptInput);
    Params.CreateParam(ftString, 'pcont',    ptOutput);
    Params.CreateParam(ftString, 'pUSUARIO', ptInput);
    ParamByName('ptipodoc').AsString := sTipo;
    ParamByName('pUSUARIO').AsString  := oUser;
    ExecProc;
    Result := ParamByName('pcont').AsString;
  end;
end;

function TdmPedidos.ResolverCodigoCliente(aOrder: TOrder): string;
var
  q: TUniQuery;
  sNif, sEmail, sRazon: string;
  sDir1, sDir2, sPobl, sProv, sCP, sMovil, sOrden: string;
begin
  Result := '0';
  if aOrder = nil then
    Exit;
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
    q.Connection := inLibGlobalVar.oConn;
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
      q.ParamByName('usu').AsString  := oUser;
      q.Execute;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function TdmPedidos.ResolverCodigoArticulo(oValidador: TArticulosValidador;
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
      q.Connection := inLibGlobalVar.oConn;
      // Las 3 altas (articulo + SKU + barras) deben ser atomicas entre si
      bTx := not inLibGlobalVar.oConn.InTransaction;
      if bTx then
        inLibGlobalVar.oConn.StartTransaction;
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
        q.ParamByName('usu').AsString  := oUser;
        q.Execute;
        // SKU unico (sin variacion: CODIGO_VAR_SKU = '-')
        q.SQL.Text :=
          'INSERT INTO fza_articulos_skus (CODIGO_UNIDAD_SKU, ' +
          ' CODIGO_ART_SKU, CODIGO_VAR_SKU, ESACTIVO_SKU, ' +
          ' INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
          'VALUES (:cod, :cod, ''-'', ''S'', NOW(), :usu, :usu)';
        q.ParamByName('cod').AsString := Result;
        q.ParamByName('usu').AsString := oUser;
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
          q.ParamByName('usu').AsString := oUser;
          q.Execute;
        end;
        if bTx then
          inLibGlobalVar.oConn.Commit;
      except
        if bTx and inLibGlobalVar.oConn.InTransaction then
          inLibGlobalVar.oConn.Rollback;
        raise;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function TdmPedidos.ImportarPedidoPrestaShop(aOrder: TOrder): Boolean;
var
  qIns: TUniQuery;
  qLin: TUniQuery;
  qMsg: TUniQuery;
  i: Integer;
  sNumero, sSerie, sCodigoCli: string;
  lp: TLineaPed;
  tm: TMensaje;
  bTxOwned: Boolean;
  oValidador: TArticulosValidador;
  aCodArt: TArray<string>;
begin
  Result := False;
  if aOrder = nil then Exit;
  if ExistePedidoPrestaShop(aOrder.idPedido) then Exit;

  // Reservar número usando el procedimiento de contadores
  unqryTablaG.Insert;
  try
    unqryTablaG.FieldByName('SERIE_PED').AsString          := 'A1';
    unqryTablaG.FieldByName('FECHA_PED').AsDateTime        := Date;
    if unqryTablaG.FindField('ESTADO_PED') <> nil then
      unqryTablaG.FieldByName('ESTADO_PED').AsString       := 'IMPORTADO';
    unqryTablaG.FieldByName('CODIGO_EMP_PED').AsString     := '0';
    unqryTablaG.FieldByName('CODIGO_CLI_PED').AsString     := '0';
    GetCodigoAutoPedido;
    sNumero := unqryTablaG.FieldByName('NUMERO_PED').AsString;
    sSerie  := unqryTablaG.FieldByName('SERIE_PED').AsString;
    unqryTablaG.Cancel;
  except
    unqryTablaG.Cancel;
    raise;
  end;

  // Resolver/crear cliente y articulos ANTES de la tx: los contadores
  // (PRC_GET_NEXT_CONT) hacen COMMIT propio y romperian la tx del pedido.
  sCodigoCli := ResolverCodigoCliente(aOrder);
  oValidador := TArticulosValidador.Create(inLibGlobalVar.oConn);
  try
    SetLength(aCodArt, aOrder.LineasPedido.Count);
    for i := 0 to aOrder.LineasPedido.Count - 1 do
      aCodArt[i] := ResolverCodigoArticulo(oValidador, aOrder.LineasPedido[i]);
  finally
    FreeAndNil(oValidador);
  end;

  qIns := TUniQuery.Create(nil);
  qLin := TUniQuery.Create(nil);
  qMsg := TUniQuery.Create(nil);
  try
    // Importacion atomica: cabecera + lineas + mensajes, todo o nada
    bTxOwned := not inLibGlobalVar.oConn.InTransaction;
    if bTxOwned then
      inLibGlobalVar.oConn.StartTransaction;
    try
      qIns.Connection := inLibGlobalVar.oConn;
      qIns.SQL.Text :=
        'INSERT INTO fza_pedidos (NUMERO_PED, SERIE_PED, FECHA_PED, '
          +
        'ESTADO_PED, CODIGO_CLI_PED, ' +
        ' IDPS_PED, FECHAPS_PED, REFERENCIAPS_PED, ' +
        ' FORMAPAGOPS_PED, TRANSPORTISTAPS_PED, ESTADOPEDIDOPS_PED, ' +
        ' EMAIL_CLIENTE_PED, NIF_CLIENTE_PED, ' +
        ' NOMBRE_CLI_ENVIO_PED, MOVIL_CLIENTE_ENVIO_PED, ' +
        ' DIRECCION1_CLIENTE_ENVIO_PED, DIRECCION2_CLIENTE_ENVIO_PED, ' +
        ' POBLACION_CLIENTE_ENVIO_PED, PROVINCIA_CLIENTE_ENVIO_PED, ' +
        ' CODIGO_POSTAL_CLIENTE_ENVIO_PED, ' +
        ' RAZON_SOCIAL_CLIENTE_FISCAL_PED, MOVIL_CLIENTE_FISCAL_PED, ' +
        ' DIRECCION1_CLIENTE_FISCAL_PED, DIRECCION2_CLIENTE_FISCAL_PED, ' +
        ' POBLACION_CLIENTE_FISCAL_PED, PROVINCIA_CLIENTE_FISCAL_PED, ' +
        ' CODIGO_POSTAL_CLIENTE_FISCAL_PED, ' +
        ' TOTAL_LIQUIDO_PED, TOTAL_PAGADOREALPS_PED, ' +
        ' INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (:NUMERO, :SERIE, :FECHA, :ESTADO, :CODCLI, ' +
        '        :IDPS, :FECHAPS, :REFPS, ' +
        '        :FORMAPAGO, :TRANSP, :ESTADOPS, ' +
        '        :EMAILCLI, :NIFCLI, ' +
        '        :NOMENV, :MOVENV, :DIR1ENV, :DIR2ENV, ' +
        '        :POBLENV, :PROVENV, :CPENV, ' +
        '        :RSFIS, :MOVFIS, :DIR1FIS, :DIR2FIS, ' +
        '        :POBLFIS, :PROVFIS, :CPFIS, ' +
        '        :TOTAL, :PAGADO, ' +
        '        NOW(), :USU, :USU)';
      qIns.ParamByName('NUMERO').AsString  := sNumero;
      qIns.ParamByName('SERIE').AsString   := sSerie;
      qIns.ParamByName('FECHA').AsDateTime := Date;
      qIns.ParamByName('ESTADO').AsString  := 'IMPORTADO';
      qIns.ParamByName('CODCLI').AsString  := sCodigoCli;
      qIns.ParamByName('IDPS').AsString    := aOrder.idPedido;
      qIns.ParamByName('FECHAPS').AsString := aOrder.FechaCreacion;
      qIns.ParamByName('REFPS').AsString   := aOrder.ReferenciaCliente;
      qIns.ParamByName('FORMAPAGO').AsString := aOrder.FormaPago;
      qIns.ParamByName('TRANSP').AsString    := aOrder.Transportista;
      qIns.ParamByName('ESTADOPS').AsString  := aOrder.EstadoPedido;
      qIns.ParamByName('EMAILCLI').AsString  := aOrder.custMail;
      qIns.ParamByName('NIFCLI').AsString    := aOrder.DniDel;
      qIns.ParamByName('NOMENV').AsString    :=
        aOrder.FirstnameDel + ' ' + aOrder.LastNameDel;
      qIns.ParamByName('MOVENV').AsString    := aOrder.PhoneDel;
      qIns.ParamByName('DIR1ENV').AsString   := aOrder.Address1Del;
      qIns.ParamByName('DIR2ENV').AsString   := aOrder.Address2Del;
      qIns.ParamByName('POBLENV').AsString   := aOrder.CityDel;
      qIns.ParamByName('PROVENV').AsString   := aOrder.NameStateDel;
      qIns.ParamByName('CPENV').AsString     := aOrder.PostcodeDel;
      qIns.ParamByName('RSFIS').AsString     := aOrder.CompanyBil;
      qIns.ParamByName('MOVFIS').AsString    := aOrder.PhoneBil;
      qIns.ParamByName('DIR1FIS').AsString   := aOrder.Address1Bil;
      qIns.ParamByName('DIR2FIS').AsString   := aOrder.Address2Bil;
      qIns.ParamByName('POBLFIS').AsString   := aOrder.CityBil;
      qIns.ParamByName('PROVFIS').AsString   := aOrder.NameStateBil;
      qIns.ParamByName('CPFIS').AsString     := aOrder.PostcodeBil;
      qIns.ParamByName('TOTAL').AsCurrency   := aOrder.TotalPedCIVA;
      qIns.ParamByName('PAGADO').AsCurrency  := aOrder.TotalPagadoReal;
      qIns.ParamByName('USU').AsString       := oUser;
      qIns.Execute;
      // Lineas
      qLin.Connection := inLibGlobalVar.oConn;
      qLin.SQL.Text :=
        'INSERT INTO fza_pedidos_lineas (NUMERO_PED_PEDLIN, ' +
        'SERIE_PED_PEDLIN, LINEA_PEDLIN, ' +
        ' IDLINEAPS_PEDLIN, IDPRODPS_PEDLIN, CODIGOPRODPS_PEDLIN, ' +
        'IDATRIBPRODPS_PEDLIN, ' +
        ' CODIGO_ART_PEDLIN, CODBAR_ART_PEDLIN, ' +
        'DESCRIPCION_ARTICULO_PEDLIN, ' +
        ' CANTIDAD_PEDLIN, CANTIDAD_ENTREGADA_PEDLIN, ' +
        'CANTIDAD_PENDIENTE_PEDLIN, ESENTREGADA_PEDLIN, ' +
        ' PRECIO_VENTA_SIVA_ARTICULO_PEDLIN, ' +
        'PRECIO_VENTA_CIVA_ARTICULO_PEDLIN, TOTAL_PEDLIN, ' +
        ' INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (:NUMERO, :SERIE, :LIN, ' +
        '        :IDLPS, :IDPPS, :REFPROD, :IDATRIB, ' +
        '        :CODART, :EAN13, :DESCR, ' +
        '        :CANT, 0, :CANT, ''N'', ' +
        '        :PSIVA, :PCIVA, :TOT, ' +
        '        NOW(), :USU, :USU)';
      for i := 0 to aOrder.LineasPedido.Count - 1 do
      begin
        lp := aOrder.LineasPedido[i];
        qLin.ParamByName('NUMERO').AsString  := sNumero;
        qLin.ParamByName('SERIE').AsString   := sSerie;
        qLin.ParamByName('LIN').AsString     := Format('%.4d', [(i + 1) * 10]);
        qLin.ParamByName('IDLPS').AsString   := lp.idLinea;
        qLin.ParamByName('IDPPS').AsString   := lp.idProducto;
        qLin.ParamByName('REFPROD').AsString := lp.sRefProd;
        qLin.ParamByName('IDATRIB').AsString := lp.sRefAtrib;
        qLin.ParamByName('CODART').AsString  := aCodArt[i];
        qLin.ParamByName('EAN13').AsString   := lp.sCodEAN13;
        qLin.ParamByName('DESCR').AsString   := lp.sDescripcion;
        qLin.ParamByName('CANT').AsFloat     := StrToFloatDef(lp.sCantidad, 1);
        qLin.ParamByName('PSIVA').AsCurrency := lp.cPrecioSIVA;
        qLin.ParamByName('PCIVA').AsCurrency := lp.cPrecioCIVA;
        qLin.ParamByName('TOT').AsCurrency   :=
          lp.cPrecioCIVA * StrToFloatDef(lp.sCantidad, 1);
        qLin.ParamByName('USU').AsString     := oUser;
        qLin.Execute;
      end;
      // Mensajes (si hay)
      qMsg.Connection := inLibGlobalVar.oConn;
      qMsg.SQL.Text :=
        'INSERT INTO fza_pedidos_mensajes (IDPS_MENSAJES_PEDMSG, ' +
        'IDMENSAJEPS_PEDMSG, ' +
        ' IDEMPLEADOPS_PEDMSG, MENSAJEPS_PEDMSG, FECHAPS_PEDMSG, ' +
        ' INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (:HILO, :IDM, :IDE, :MSG, :FECHA, NOW(), :USU, :USU)';
      for tm in aOrder.MensajesPedido.LMensajes do
      begin
        qMsg.ParamByName('HILO').AsString  :=
          aOrder.MensajesPedido.idCustomer_Threat;
        qMsg.ParamByName('IDM').AsString   := tm.idMensaje;
        qMsg.ParamByName('IDE').AsString   := tm.idEmpleado;
        qMsg.ParamByName('MSG').AsString   := tm.Texto;
        qMsg.ParamByName('FECHA').AsDateTime := tm.InstanteMsg;
        qMsg.ParamByName('USU').AsString   := oUser;
        // El error de duplicado (mismo mensaje) no aborta la tx en InnoDB
        try
          qMsg.Execute;
        except
          // Si el mensaje ya existe (hilo PK), saltar
        end;
      end;
      if bTxOwned then
        inLibGlobalVar.oConn.Commit;
      Result := True;
    except
      if bTxOwned and inLibGlobalVar.oConn.InTransaction then
        inLibGlobalVar.oConn.Rollback;
      raise;
    end;
  finally
    FreeAndNil(qIns);
    FreeAndNil(qLin);
    FreeAndNil(qMsg);
  end;
end;

initialization
  ForceReferenceToClass(TdmPedidos);

end.
