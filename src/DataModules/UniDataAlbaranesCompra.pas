{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAlbaranesCompra                                        }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de albaranes de COMPRA.                                       }
{    Espejo simplificado de UniDataAlbaranes adaptado a documentos de          }
{    compra (proveedor en lugar de cliente, precio de compra en lugar          }
{    de venta). Sincroniza movimientos de stock AC desde la cabecera y         }
{    lineas actuales del documento.                                            }
{******************************************************************************}
unit UniDataAlbaranesCompra;

interface

uses
  System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Vcl.ComCtrls, cxListView,
  Data.DB, MemDS, DBAccess, Uni,
  frxClass, frxDBSet,
  UniDataGen, UniDataArticulos, inLibUser, inMtoPrincipal;

type
  TdmAlbaranesCompra = class(TdmBase)
    unqryAlbaranesCompraLineas: TUniQuery;
    dsAlbaranesCompraLineas:    TDataSource;
    unqryEmpDataAlbc:           TUniQuery;
    unqryPrvDataAlbc:           TUniQuery;
    dsPrvDataAlbc:              TDataSource;
    unqryArtDataLinAlbc:        TUniQuery;
    unqrySkusAlbc:              TUniQuery;
    unqryMovimientosProveedor:  TUniQuery;
    dsMovimientosProveedor:     TDataSource;
    unqryFormasPago:            TUniQuery;
    dsFormasPago:               TDataSource;
    unstrdprcGetContadorAlbc:   TUniStoredProc;
    // Definicion de atributos del articulo padre (para columnas
    // dinamicas ATTR1..ATTR5 en modo "atributo por columna").
    unqryDefArticuloAlbc:       TUniQuery;
    // Datasets para impresion del albaran via FastReport. Mismo patron
    // que TdmComprasSesiones (unqry*Print -> ds*Print -> fxds*). El
    // .fr3 embebido en el modal inMtoModalImpAlbCompra.dfm los
    // referencia por UserName ('Albaran', 'LineasAlbaran').
    unqryCabAlbcPrint:          TUniQuery;
    dsCabAlbcPrint:             TDataSource;
    fxdsCabAlbc:                TfrxDBDataset;
    unqryLinAlbcPrint:          TUniQuery;
    dsLinAlbcPrint:             TDataSource;
    fxdsLinAlbc:                TfrxDBDataset;
    unqryGuiasAlbcPrint:        TUniQuery;
    dsGuiasAlbcPrint:           TDataSource;
    fxdsGuiasAlbc:              TfrxDBDataset;
    // Lineas "planas" (una fila por SKU sin pivotar por talla) para el
    // formato vertical estilo factura.
    unqryLinAlbcSkuPrint:       TUniQuery;
    dsLinAlbcSkuPrint:          TDataSource;
    fxdsLinAlbcSku:             TfrxDBDataset;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryAlbaranesCompraLineasAfterInsert(DataSet: TDataSet);
    procedure unqryAlbaranesCompraLineasBeforePost(DataSet: TDataSet);
    procedure unqryAlbaranesCompraLineasAfterPost(DataSet: TDataSet);
    procedure unqryAlbaranesCompraLineasAfterDelete(DataSet: TDataSet);
  private
    // Transicion detectada en BeforePost. Se conserva para validar el
    // cierre, pero AfterPost sincroniza movimientos desde el documento
    // actual sin depender del estado final.
    FTransicionEstadoAlbc: string;
    procedure AsignarNumeroLineaAlbaranCompra(DataSet: TDataSet);
    procedure ConfigurarSqlCabecera;
    function HayLineasMovimiento(const ASerie, ANumero: string): Boolean;
    function ObtenerSkusAlbaranCsv(const ASerie, ANumero: string): string;
    procedure RefrescarMovimientosProveedor;
  public
    procedure GetCodigoAutoAlbaranCompra;
    procedure CalcularTotalesAlbaranCompra;
    procedure SincronizarMovimientos;
    // Abre unqryCabAlbcPrint y unqryLinAlbcPrint con los parametros
    // del albaran a imprimir. Mismo nombre/firma que en sesiones.
    procedure PrepararPrint(const ASerie, ANumero: string);
    // Version SKU (lineas planas, sin pivote talla) para el modal
    // vertical estilo factura.
    procedure PrepararPrintSku(const ASerie, ANumero: string);
    // Carga en el listview los almacenes distintos que aparecen en las
    // lineas del albaran (usado por el modal de pegatinas).
    procedure CargarAlmacenesDelAlbaran(const ASerie, ANumero: string;
                                         ALV: TObject);
    // Crea el dataset cdsEtiquetasArt del DM articulos filtrado a los
    // SKUs del albaran. Reutiliza la query base de etiquetas anyadiendo
    // un WHERE por SKU IN (SELECT ... FROM albaranes_compra_lineas).
    procedure CrearDataSetEtiquetasAlb(ADmArt: TObject;
                                        const ASerie, ANumero,
                                              ACodTarifa, AAlmacenesCsv: string;
                                        AFecha: TDateTime);
    procedure OpenTables;
    // Override: abre las queries detalle tras unqryTablaG. Llamada
    // desde TfrmMtoGen.AbrirTablaPrincipalAsync.
    procedure AbrirDetalles; override;
  end;

implementation

uses
  inLibGlobalVar, inLibAppParam, inLibLog, inLibtb, inLibContadorLineas,
  System.Diagnostics, System.UITypes, Vcl.Dialogs,
  inMtoAlbaranesCompra,
  inLibAlbaranesCompraMovimientos,
  inLibComprasImpuestos,
  inLibArticulosValidador;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmAlbaranesCompra.ConfigurarSqlCabecera;
const
  CAMPOS_ALBC: array[0..78] of string = (
    'NUMERO_ALBC',
    'SERIE_ALBC',
    'FECHA_ALBC',
    'ESTADO_ALBC',
    'NUMERO_PED_ALBC',
    'SERIE_PED_ALBC',
    'NUMERO_FAC_ALBC',
    'SERIE_FAC_ALBC',
    'CODIGO_EMP_ALBC',
    'RAZON_SOCIAL_EMPRESA_ALBC',
    'NIF_EMPRESA_ALBC',
    'MOVIL_EMPRESA_ALBC',
    'EMAIL_EMPRESA_ALBC',
    'DIRECCION1_EMPRESA_ALBC',
    'DIRECCION2_EMPRESA_ALBC',
    'POBLACION_EMPRESA_ALBC',
    'PROVINCIA_EMPRESA_ALBC',
    'CODIGO_PAI_EMPRESA_ALBC',
    'NOMBRE_PAI_EMPRESA_ALBC',
    'CODIGO_POSTAL_EMPRESA_ALBC',
    'CODIGO_PRV_ALBC',
    'RAZON_SOCIAL_PRV_ALBC',
    'NIF_PRV_ALBC',
    'MOVIL_PRV_ALBC',
    'EMAIL_PRV_ALBC',
    'DIRECCION1_PRV_ALBC',
    'DIRECCION2_PRV_ALBC',
    'POBLACION_PRV_ALBC',
    'PROVINCIA_PRV_ALBC',
    'CODIGO_PAI_PRV_ALBC',
    'NOMBRE_PAI_PRV_ALBC',
    'CODIGO_POSTAL_PRV_ALBC',
    'REF_PROVEEDOR_ALBC',
    'CODIGO_ALM_ALBC',
    'TRANSPORTISTA_ALBC',
    'CODIGO_IVA_ALBC',
    'ESIVA_RECARGO_COMPRAS_ALBC',
    'ESIVA_EXENTO_INTRACOMUNITARIO_ALBC',
    'PORCENTAJE_IVAN_ALBC',
    'TOTAL_BASEI_IVAN_ALBC',
    'TOTAL_IVAN_ALBC',
    'PORCENTAJE_REN_ALBC',
    'TOTAL_REN_ALBC',
    'PORCENTAJE_IVAR_ALBC',
    'TOTAL_BASEI_IVAR_ALBC',
    'TOTAL_IVAR_ALBC',
    'PORCENTAJE_RER_ALBC',
    'TOTAL_RER_ALBC',
    'PORCENTAJE_IVAS_ALBC',
    'TOTAL_BASEI_IVAS_ALBC',
    'TOTAL_IVAS_ALBC',
    'PORCENTAJE_RES_ALBC',
    'TOTAL_RES_ALBC',
    'PORCENTAJE_IVAE_ALBC',
    'TOTAL_BASEI_IVAE_ALBC',
    'TOTAL_IVAE_ALBC',
    'PORCENTAJE_REE_ALBC',
    'TOTAL_REE_ALBC',
    'TOTAL_BRUTO_ALBC',
    'PORCENTAJE_DTO_COMERCIAL_ALBC',
    'TOTAL_DTO_COMERCIAL_ALBC',
    'PORCENTAJE_DTO_FINANCIERO_ALBC',
    'TOTAL_DTO_FINANCIERO_ALBC',
    'TOTAL_BASES_ALBC',
    'TOTAL_IMPUESTOS_ALBC',
    'PORCENTAJE_RETENCION_ALBC',
    'TOTAL_RETENCION_ALBC',
    'TOTAL_LIQUIDO_ALBC',
    'FORMA_PAGO_ALBC',
    'CONTADOR_LINEAS_ALBC',
    'COMENTARIOS_ALBC',
    'OBSERVACIONES_ALBC',
    'ESPIVOTE_HORIZONTAL_ALBC',
    'CODIGO_TAR_ALBC',
    'ESDEPOSITO_ALBC',
    'INSTANTE_MODIF',
    'INSTANTE_ALTA',
    'USUARIO_ALTA',
    'USUARIO_MODIF');
var
  i: Integer;
  sSet: string;
  sCols: string;
  sVals: string;

  procedure AgregarCampoUpdate(const ACampo: string);
  begin
    if sSet = '' then
      sSet := '       ' + ACampo + ' = :' + ACampo
    else
      sSet := sSet + ',' + sLineBreak +
        '       ' + ACampo + ' = :' + ACampo;
  end;

  procedure AgregarCampoInsert(const ACampo: string);
  begin
    if sCols = '' then
    begin
      sCols := ACampo;
      sVals := ':' + ACampo;
    end
    else
    begin
      sCols := sCols + ', ' + ACampo;
      sVals := sVals + ', :' + ACampo;
    end;
  end;

begin
  unqryTablaG.SQLDelete.Text :=
    'DELETE FROM fza_albaranes_compra ' + sLineBreak +
    'WHERE NUMERO_ALBC = :Old_NUMERO_ALBC ' + sLineBreak +
    '  AND SERIE_ALBC = :Old_SERIE_ALBC';
  sSet := '';
  for i := Low(CAMPOS_ALBC) to High(CAMPOS_ALBC) do
    AgregarCampoUpdate(CAMPOS_ALBC[i]);
  unqryTablaG.SQLUpdate.Text :=
    'UPDATE fza_albaranes_compra ' + sLineBreak +
    '   SET ' + sLineBreak +
    sSet + sLineBreak +
    ' WHERE NUMERO_ALBC = :Old_NUMERO_ALBC ' + sLineBreak +
    '   AND SERIE_ALBC = :Old_SERIE_ALBC';
  // SQLInsert explicito contra la tabla base: vi_albaranes_compra tiene
  // columnas calculadas y no es insertable-into (MySQL 1471). Mismo
  // patron que el SQLInsert de pedidos de compra.
  sCols := '';
  sVals := '';
  for i := Low(CAMPOS_ALBC) to High(CAMPOS_ALBC) do
    AgregarCampoInsert(CAMPOS_ALBC[i]);
  unqryTablaG.SQLInsert.Text :=
    'INSERT INTO fza_albaranes_compra (' + sCols + ') ' + sLineBreak +
    'VALUES (' + sVals + ')';
  unqryTablaG.SQLRefresh.Text :=
    'SELECT * ' + sLineBreak +
    '  FROM vi_albaranes_compra ' + sLineBreak +
    ' WHERE NUMERO_ALBC = :NUMERO_ALBC ' + sLineBreak +
    '   AND SERIE_ALBC = :SERIE_ALBC';
end;

procedure TdmAlbaranesCompra.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection                := inLibGlobalVar.oConn;
  unqryTablaG.KeyFields                 := 'NUMERO_ALBC;SERIE_ALBC';
  ConfigurarSqlCabecera;
  unqryAlbaranesCompraLineas.Connection := inLibGlobalVar.oConn;
  unqryEmpDataAlbc.Connection           := inLibGlobalVar.oConn;
  unqryPrvDataAlbc.Connection           := inLibGlobalVar.oConn;
  // Lookup completo de proveedores (NOMBRE_PRV + RAZON_SOCIAL_PRV) para
  // el rotulo resuelto de la cabecera y para el combo de busqueda
  // incremental por codigo (cbbCODIGO_PRV_ALBC). Se abre una vez y se
  // recorre con Locate; no depende del proveedor del albaran en pantalla.
  unqryPrvDataAlbc.Open;
  unqryArtDataLinAlbc.Connection        := inLibGlobalVar.oConn;
  unqrySkusAlbc.Connection              := inLibGlobalVar.oConn;
  unqryMovimientosProveedor.Connection  := inLibGlobalVar.oConn;
  unqryFormasPago.Connection            := inLibGlobalVar.oConn;
  unstrdprcGetContadorAlbc.Connection   := inLibGlobalVar.oConn;
  unqryDefArticuloAlbc.Connection       := inLibGlobalVar.oConn;
  // Master-detail server-side: el WHERE del SQL toma los valores de
  // dsTablaG (master), evitando descargar fza_albaranes_compra_lineas
  // entera y filtrar en cliente.
  unqryAlbaranesCompraLineas.MasterSource :=
    (GetOwnerForm<TfrmMtoAlbaranesCompra>).dsTablaG;
  unqryMovimientosProveedor.MasterSource :=
    (GetOwnerForm<TfrmMtoAlbaranesCompra>).dsTablaG;
end;

procedure TdmAlbaranesCompra.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(unqryAlbaranesCompraLineas) and
     unqryAlbaranesCompraLineas.Active then
    unqryAlbaranesCompraLineas.Close;
  if Assigned(unqryMovimientosProveedor) and
     unqryMovimientosProveedor.Active then
    unqryMovimientosProveedor.Close;
  if Assigned(unqryFormasPago) and unqryFormasPago.Active then
    unqryFormasPago.Close;
  inherited;
end;

procedure TdmAlbaranesCompra.OpenTables;
begin
  // Delegamos en AbrirDetalles para unificar logging y cronometro.
  AbrirDetalles;
end;

procedure TdmAlbaranesCompra.AbrirDetalles;
const
  TAG = 'AlbaranesCompra.AbrirDetalles';

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
  AbrirConTiempo(unqryAlbaranesCompraLineas,
                 'unqryAlbaranesCompraLineas');
  AbrirConTiempo(unqryMovimientosProveedor,
                 'unqryMovimientosProveedor');
  AbrirConTiempo(unqryFormasPago, 'unqryFormasPago');
  inLibLog.Log.LogPerf(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmAlbaranesCompra.unqryTablaGAfterInsert(DataSet: TDataSet);
var
  sSerie: string;
begin
  inherited;
  with unqryTablaG do
  begin
    FieldByName('NUMERO_ALBC').AsString := '0';
    // Serie por defecto: buscar en fza_empresas_series para TIPO_DOC='AB'
    sSerie := ObtenerSerieDefecto(oEmpresa, 'AB');
    if FindField('SERIE_ALBC') <> nil then
    begin
      if sSerie <> '' then
        FieldByName('SERIE_ALBC').AsString := sSerie
      else
        FieldByName('SERIE_ALBC').AsString := 'C1';
    end;
    FieldByName('FECHA_ALBC').AsDateTime := Date;
    if FindField('ESTADO_ALBC') <> nil then
      FieldByName('ESTADO_ALBC').AsString := 'ABIERTO';
    if Trim(oEmpresa) <> '' then
      FieldByName('CODIGO_EMP_ALBC').AsString := oEmpresa
    else
      FieldByName('CODIGO_EMP_ALBC').AsString := '0';
    FieldByName('CODIGO_PRV_ALBC').AsString := '0';
    if FindField('ESPIVOTE_HORIZONTAL_ALBC') <> nil then
      FieldByName('ESPIVOTE_HORIZONTAL_ALBC').AsString := 'N';
    // Por defecto el albaran NO es deposito; se marca a mano en
    // cabecera. FindField: tolera BBDD sin la migracion aplicada
    // (albaran_compra_deposito.sql).
    if FindField('ESDEPOSITO_ALBC') <> nil then
      FieldByName('ESDEPOSITO_ALBC').AsString := 'N';
    if FindField('ESIVA_EXENTO_INTRACOMUNITARIO_ALBC') <> nil then
      FieldByName('ESIVA_EXENTO_INTRACOMUNITARIO_ALBC').AsString := 'N';
    AplicarRecargoComprasEmpresa(inLibGlobalVar.oConn, unqryTablaG,
      'CODIGO_EMP_ALBC', 'ESIVA_RECARGO_COMPRAS_ALBC');
    AplicarPorcentajesIvaCompra(inLibGlobalVar.oConn, unqryTablaG,
      'ALBC');
  end;
  FTransicionEstadoAlbc := '';
end;

procedure TdmAlbaranesCompra.unqryTablaGBeforePost(DataSet: TDataSet);
var
  fEstado: TField;
  sEstadoNuevo, sEstadoAnterior: string;
  qChk: TUniQuery;
  i: Integer;
begin
  inherited;
  // Cinturon: los campos NOT NULL con default en BBDD (p. ej.
  // ESPIVOTE_HORIZONTAL_ALBC) llegan como Required a UniDAC y bloquean
  // el Post del alta manual con "must have a value". Mismo criterio
  // que Inventarios / Pedidos de compra.
  for i := 0 to DataSet.FieldCount - 1 do
    DataSet.Fields[i].Required := False;
  // En alta manual el pivote arranca vertical; se activa tras elegir
  // una linea con sistema de tallas.
  if (DataSet.FindField('ESPIVOTE_HORIZONTAL_ALBC') <> nil) and
     (Trim(DataSet.FieldByName('ESPIVOTE_HORIZONTAL_ALBC').AsString) = '')
  then
    DataSet.FieldByName('ESPIVOTE_HORIZONTAL_ALBC').AsString := 'N';
  if (unqryTablaG.FieldByName('NUMERO_ALBC').AsString = '0') or
     (unqryTablaG.FieldByName('NUMERO_ALBC').AsString = '') then
    GetCodigoAutoAlbaranCompra;
  AplicarPorcentajesIvaCompra(inLibGlobalVar.oConn, unqryTablaG,
    'ALBC');
  CalcularTotalesAlbaranCompra;
  // Deteccion de transicion de ESTADO_ALBC. Solo aplica en modo Edit.
  // Se usa para prevalidar cierres vacios; los movimientos se
  // sincronizan siempre tras persistir la cabecera.
  FTransicionEstadoAlbc := '';
  if unqryTablaG.State <> dsEdit then
    Exit;
  fEstado := unqryTablaG.FindField('ESTADO_ALBC');
  if fEstado = nil then
    Exit;
  sEstadoNuevo    := UpperCase(Trim(fEstado.AsString));
  sEstadoAnterior := UpperCase(Trim(VarToStr(fEstado.OldValue)));
  if sEstadoNuevo = sEstadoAnterior then
    Exit;
  if (sEstadoAnterior = 'ABIERTO') and (sEstadoNuevo = 'CERRADO') then
    FTransicionEstadoAlbc := 'CERRAR'
  else if (sEstadoAnterior = 'CERRADO') and (sEstadoNuevo = 'ABIERTO') then
    FTransicionEstadoAlbc := 'ABRIR';
  // Pre-validacion del cierre: si vamos a cerrar y no hay lineas con
  // cantidad > 0, abortamos el Post para no dejar el albaran CERRADO
  // sin movimientos. Mejor abortar aqui que en AfterPost (donde la
  // cabecera ya estaria persistida con el estado nuevo).
  if FTransicionEstadoAlbc = 'CERRAR' then
  begin
    qChk := TUniQuery.Create(nil);
    try
      qChk.Connection := inLibGlobalVar.oConn;
      qChk.SQL.Text :=
        'SELECT COUNT(*) AS N FROM fza_albaranes_compra_lineas ' +
        ' WHERE SERIE_ALBC_ALBCLIN  = :s ' +
        '   AND NUMERO_ALBC_ALBCLIN = :n ' +
        '   AND IFNULL(CANTIDAD_ALBCLIN, 0) > 0';
      qChk.ParamByName('s').AsString :=
        unqryTablaG.FieldByName('SERIE_ALBC').AsString;
      qChk.ParamByName('n').AsString :=
        unqryTablaG.FieldByName('NUMERO_ALBC').AsString;
      qChk.Open;
      if qChk.FieldByName('N').AsInteger = 0 then
        raise Exception.Create(
          'No se puede cerrar el albaran: no tiene lineas con cantidad ' +
          'mayor que 0. Añade lineas antes de cerrar.');
    finally
      FreeAndNil(qChk);
    end;
  end;
end;

// Tras persistir la cabecera, reconstruimos los movimientos AC desde el
// documento actual. Cualquier excepcion se propaga al usuario (el Post
// original ya quedo aplicado, por lo que debe revisar y reintentar).
procedure TdmAlbaranesCompra.unqryTablaGAfterPost(DataSet: TDataSet);
begin
  inherited;
  try
    SincronizarMovimientos;
  finally
    FTransicionEstadoAlbc := '';
  end;
end;

procedure TdmAlbaranesCompra.unqryTablaGBeforeDelete(DataSet: TDataSet);
var
  q: TUniQuery;
  sSerie: string;
  sNumero: string;
  iBloqueos: Integer;

  procedure AsignarDocumento;
  begin
    q.ParamByName('s').AsString := sSerie;
    q.ParamByName('n').AsString := sNumero;
  end;

begin
  inherited;
  sSerie  := DataSet.FieldByName('SERIE_ALBC').AsString;
  sNumero := DataSet.FieldByName('NUMERO_ALBC').AsString;
  if (sSerie = '') or (sNumero = '') then
  begin
    Abort;
  end;
  q := TUniQuery.Create(nil);
  try
    q.Connection := unqryTablaG.Connection;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_albaranes_compra ' +
      ' WHERE SERIE_ALBC  = :s ' +
      '   AND NUMERO_ALBC = :n ' +
      '   AND (COALESCE(NUMERO_FAC_ALBC, '''') <> '''' ' +
      '    OR COALESCE(SERIE_FAC_ALBC, '''') <> '''' ' +
      '    OR COALESCE(ESTADO_ALBC, '''') = ''FACTURADO'')';
    AsignarDocumento;
    q.Open;
    iBloqueos := q.FieldByName('N').AsInteger;
    q.Close;
    if iBloqueos = 0 then
    begin
      q.SQL.Text :=
        'SELECT COUNT(*) AS N ' +
        '  FROM fza_albaranes_compra_lineas ' +
        ' WHERE SERIE_ALBC_ALBCLIN  = :s ' +
        '   AND NUMERO_ALBC_ALBCLIN = :n ' +
        '   AND (COALESCE(ESFACTURADA_ALBCLIN, ''N'') = ''S'' ' +
        '    OR COALESCE(NUMERO_FAC_ALBCLIN, '''') <> '''' ' +
        '    OR COALESCE(SERIE_FAC_ALBCLIN, '''') <> '''')';
      AsignarDocumento;
      q.Open;
      iBloqueos := q.FieldByName('N').AsInteger;
      q.Close;
    end;
    if iBloqueos = 0 then
    begin
      q.SQL.Text :=
        'SELECT COUNT(*) AS N ' +
        '  FROM fza_facturas_compra_lineas ' +
        ' WHERE SERIE_ALBC_FACCLIN  = :s ' +
        '   AND NUMERO_ALBC_FACCLIN = :n';
      AsignarDocumento;
      q.Open;
      iBloqueos := q.FieldByName('N').AsInteger;
      q.Close;
    end;
    if iBloqueos > 0 then
    begin
      MessageDlg('No se puede borrar el albaran de compra: ya esta ' +
                 'facturado. Borra o deshaz primero la factura de compra ' +
                 'vinculada.',
                 mtWarning, [mbOk], 0);
      Abort;
    end;
    if MessageDlg(Format('¿Borrar el albaran de compra %s / %s?' +
                         sLineBreak +
                         'Se eliminaran sus lineas y se revertiran los ' +
                         'movimientos de stock.',
                         [sSerie, sNumero]),
                  mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    begin
      Abort;
    end;
    inLibAlbaranesCompraMovimientos.RevertirMovimientosDesdeAlbaranCompra(
      unqryTablaG.Connection, sSerie, sNumero, oUser);
    q.SQL.Text :=
      'DELETE FROM fza_albaranes_compra_celdas ' +
      ' WHERE SERIE_ALBC_ALBCCEL  = :s ' +
      '   AND NUMERO_ALBC_ALBCCEL = :n';
    AsignarDocumento;
    q.ExecSQL;
    q.SQL.Text :=
      'DELETE FROM fza_albaranes_compra_lineas ' +
      ' WHERE SERIE_ALBC_ALBCLIN  = :s ' +
      '   AND NUMERO_ALBC_ALBCLIN = :n';
    AsignarDocumento;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure TdmAlbaranesCompra.unqryAlbaranesCompraLineasAfterInsert(
                                                       DataSet: TDataSet);
begin
  inherited;
  with unqryAlbaranesCompraLineas do
  begin
    FieldByName('NUMERO_ALBC_ALBCLIN').AsString :=
      unqryTablaG.FieldByName('NUMERO_ALBC').AsString;
    FieldByName('SERIE_ALBC_ALBCLIN').AsString :=
      unqryTablaG.FieldByName('SERIE_ALBC').AsString;
    FieldByName('LINEA_ALBCLIN').AsString := '0000';
    FieldByName('CANTIDAD_ALBCLIN').AsFloat := 1;
    if FindField('ESFACTURADA_ALBCLIN') <> nil then
      FieldByName('ESFACTURADA_ALBCLIN').AsString := 'N';
    // Auditoria estandar: las 4 columnas del libro de estilo bbdd §3.7
    // son NOT NULL sin default; hay que rellenarlas en alta. En BeforePost
    // tambien sobrescribimos USUARIO_MODIF para que refleje la ultima edicion.
    FieldByName('USUARIO_ALTA').AsString    := oUser;
    FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    FieldByName('USUARIO_MODIF').AsString   := oUser;
    FieldByName('INSTANTE_MODIF').AsDateTime:= Now;
  end;
end;

procedure TdmAlbaranesCompra.unqryAlbaranesCompraLineasBeforePost(
                                                       DataSet: TDataSet);
var
  sSku, sArt: string;
begin
  inherited;
  // Linea vacia (sin articulo ni SKU): cancelar silenciosamente. El cxGrid
  // hace Post automatico al navegar con flechas (OptionsData.Appending); si
  // la linea es un placeholder vacio que el usuario creo sin querer, el Post
  // fallaria con 'Field LINEA_ALBCLIN must have a value'. Cancel diferido +
  // Abort la descarta sin molestar al usuario. Mismo patron que Sesiones.
  if (Trim(unqryAlbaranesCompraLineas.FieldByName(
             'CODIGO_ART_ALBCLIN').AsString) = '') and
     (Trim(unqryAlbaranesCompraLineas.FieldByName(
             'CODIGO_UNIDAD_ALBCLIN').AsString) = '') then
  begin
    TThread.ForceQueue(nil,
      procedure
      begin
        if unqryAlbaranesCompraLineas.Active and
           (unqryAlbaranesCompraLineas.State in [dsEdit, dsInsert]) then
          unqryAlbaranesCompraLineas.Cancel;
      end);
    Abort;
  end;
  AsignarNumeroLineaAlbaranCompra(DataSet);
  with unqryAlbaranesCompraLineas do
  begin
    // Acepta articulo, SKU, codigo de barras o referencia de proveedor.
    NormalizarArticuloSkuEnDataSet(inLibGlobalVar.oConn,
      unqryAlbaranesCompraLineas, 'CODIGO_ART_ALBCLIN',
      'CODIGO_UNIDAD_ALBCLIN');
    if (FindField('CANTIDAD_ALBCLIN') <> nil) and
       (FindField('PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN') <> nil) and
       (FindField('TOTAL_ALBCLIN') <> nil) then
      FieldByName('TOTAL_ALBCLIN').AsFloat :=
        FieldByName('CANTIDAD_ALBCLIN').AsFloat *
        FieldByName('PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN').AsFloat;
    // Refrescamos auditoria en cada Post (edicion / alta nueva).
    if FindField('USUARIO_MODIF') <> nil then
      FieldByName('USUARIO_MODIF').AsString   := oUser;
    if FindField('INSTANTE_MODIF') <> nil then
      FieldByName('INSTANTE_MODIF').AsDateTime:= Now;
    // En alta (State=dsInsert) tambien los campos *_ALTA por si
    // AfterInsert no los puso (p.ej. inserciones programaticas).
    if (DataSet.State = dsInsert) then
    begin
      if (FindField('USUARIO_ALTA') <> nil) and
         (FieldByName('USUARIO_ALTA').AsString = '') then
        FieldByName('USUARIO_ALTA').AsString := oUser;
      if (FindField('INSTANTE_ALTA') <> nil) and
         FieldByName('INSTANTE_ALTA').IsNull then
        FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    end;

    // Si el usuario tecleo un SKU pero no el articulo, lo deducimos
    // consultando fza_articulos_skus (mismo patron que en venta).
    if (FindField('CODIGO_UNIDAD_ALBCLIN') <> nil) and
       (FindField('CODIGO_ART_ALBCLIN') <> nil) then
    begin
      sSku := Trim(FieldByName('CODIGO_UNIDAD_ALBCLIN').AsString);
      sArt := Trim(FieldByName('CODIGO_ART_ALBCLIN').AsString);
      if (sSku <> '') and (sArt = '') then
      begin
        unqrySkusAlbc.Close;
        unqrySkusAlbc.ParamByName('pSKU').AsString := sSku;
        unqrySkusAlbc.Open;
        if not unqrySkusAlbc.Eof then
          FieldByName('CODIGO_ART_ALBCLIN').AsString :=
            unqrySkusAlbc.FieldByName('CODIGO_ART_SKU').AsString;
        unqrySkusAlbc.Close;
      end;
    end;
    PrepararLineaFiscalCompra(inLibGlobalVar.oConn, unqryTablaG,
      unqryAlbaranesCompraLineas, 'ALBC', 'ALBCLIN', 'TOTAL_ALBCLIN');
  end;
end;

procedure TdmAlbaranesCompra.AsignarNumeroLineaAlbaranCompra(
                                                       DataSet: TDataSet);
var
  iNuevaLinea: Integer;
  sLinea: string;
  sNumero: string;
  sSerie: string;
begin
  if DataSet.FindField('LINEA_ALBCLIN') <> nil then
  begin
    sLinea := Trim(DataSet.FieldByName('LINEA_ALBCLIN').AsString);
    if (sLinea = '') or (StrToIntDef(sLinea, 0) = 0) then
    begin
      sNumero := Trim(unqryTablaG.FieldByName('NUMERO_ALBC').AsString);
      sSerie  := Trim(unqryTablaG.FieldByName('SERIE_ALBC').AsString);
      if (sNumero = '') or (sNumero = '0') or (sSerie = '') then
        raise Exception.Create(
          'Graba la cabecera del albaran antes de guardar lineas.');
      if DataSet.FindField('NUMERO_ALBC_ALBCLIN') <> nil then
        DataSet.FieldByName('NUMERO_ALBC_ALBCLIN').AsString := sNumero;
      if DataSet.FindField('SERIE_ALBC_ALBCLIN') <> nil then
        DataSet.FieldByName('SERIE_ALBC_ALBCLIN').AsString := sSerie;
      iNuevaLinea := GetSiguienteLineaDoc(CONT_ALBARANES_COMPRA, sSerie,
        sNumero);
      if iNuevaLinea = 0 then
      begin
        iNuevaLinea := StrToIntDef(
          unqryTablaG.FieldByName('CONTADOR_LINEAS_ALBC').AsString, 0) + 10;
      end;
      if unqryTablaG.FindField('CONTADOR_LINEAS_ALBC') <> nil then
      begin
        if not (unqryTablaG.State in [dsEdit, dsInsert]) then
          unqryTablaG.Edit;
        unqryTablaG.FieldByName('CONTADOR_LINEAS_ALBC').AsString :=
          Format('%.8d', [iNuevaLinea]);
      end;
      DataSet.FieldByName('LINEA_ALBCLIN').AsString :=
        Format('%.4d', [iNuevaLinea]);
    end;
  end;
end;

procedure TdmAlbaranesCompra.unqryAlbaranesCompraLineasAfterPost(
                                                       DataSet: TDataSet);
begin
  inherited;
  CalcularTotalesAlbaranCompra;
  SincronizarMovimientos;
end;

procedure TdmAlbaranesCompra.unqryAlbaranesCompraLineasAfterDelete(
                                                       DataSet: TDataSet);
begin
  inherited;
  CalcularTotalesAlbaranCompra;
  SincronizarMovimientos;
end;

procedure TdmAlbaranesCompra.GetCodigoAutoAlbaranCompra;
var
  iNumero: Int64;
  sNumero: string;
begin
  with unstrdprcGetContadorAlbc do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'pserie',            ptInput);
    Params.CreateParam(ftString, 'ptipodoc',          ptInput);
    Params.CreateParam(ftString, 'pEMPRESA_CONTADOR', ptInput);
    Params.CreateParam(ftString, 'pUSUARIOMODIF',     ptInput);
    Params.CreateParam(ftString, 'pcont',             ptOutput);
    ParamByName('pserie').AsString :=
      unqryTablaG.FieldByName('SERIE_ALBC').AsString;
    ParamByName('ptipodoc').AsString := 'AB';
    ParamByName('pUSUARIOMODIF').AsString := oUser;
    ParamByName('pEMPRESA_CONTADOR').AsString :=
      unqryTablaG.FieldByName('CODIGO_EMP_ALBC').AsString;
    ExecProc;
    sNumero := Trim(ParamByName('pcont').AsString);
    if (sNumero = '') or (not TryStrToInt64(sNumero, iNumero)) or
       (iNumero <= 0) then
      raise Exception.Create(
        'No se pudo obtener un numero de albaran de compra valido. ' +
        'Revise el contador AB de la serie ' +
        unqryTablaG.FieldByName('SERIE_ALBC').AsString +
        ' y empresa ' +
        unqryTablaG.FieldByName('CODIGO_EMP_ALBC').AsString + '.');
    unqryTablaG.FieldByName('NUMERO_ALBC').AsString := sNumero;
  end;
end;

procedure TdmAlbaranesCompra.CalcularTotalesAlbaranCompra;
begin
  CalcularTotalesDocumentoCompra(unqryTablaG.Connection, unqryTablaG,
    unqryAlbaranesCompraLineas, 'ALBC', 'TOTAL_ALBCLIN',
    'TIPO_IVA_ARTICULO_ALBCLIN', 'PORCENTAJE_IVA_ALBCLIN');
end;

function TdmAlbaranesCompra.HayLineasMovimiento(const ASerie,
  ANumero: string): Boolean;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := unqryTablaG.Connection;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_albaranes_compra_lineas ' +
      ' WHERE SERIE_ALBC_ALBCLIN  = :s ' +
      '   AND NUMERO_ALBC_ALBCLIN = :n ' +
      '   AND IFNULL(CANTIDAD_ALBCLIN, 0) > 0';
    q.ParamByName('s').AsString := ASerie;
    q.ParamByName('n').AsString := ANumero;
    q.Open;
    Result := q.FieldByName('N').AsInteger > 0;
  finally
    FreeAndNil(q);
  end;
end;

procedure TdmAlbaranesCompra.RefrescarMovimientosProveedor;
begin
  if unqryMovimientosProveedor.Active then
  begin
    unqryMovimientosProveedor.Close;
    unqryMovimientosProveedor.Open;
  end;
end;

procedure TdmAlbaranesCompra.SincronizarMovimientos;
var
  sNumero: string;
  sSerie: string;
begin
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
  begin
    sSerie := Trim(unqryTablaG.FieldByName('SERIE_ALBC').AsString);
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_ALBC').AsString);
    if (sSerie <> '') and (sNumero <> '') and (sNumero <> '0') then
    begin
      inLibAlbaranesCompraMovimientos.RevertirMovimientosDesdeAlbaranCompra(
        unqryTablaG.Connection, sSerie, sNumero, oUser);
      if HayLineasMovimiento(sSerie, sNumero) then
        inLibAlbaranesCompraMovimientos.GenerarMovimientosDesdeAlbaranCompra(
          unqryTablaG.Connection, sSerie, sNumero, oUser);
      RefrescarMovimientosProveedor;
    end;
  end;
end;

procedure TdmAlbaranesCompra.PrepararPrint(const ASerie, ANumero: string);
begin
  unqryCabAlbcPrint.Close;
  unqryCabAlbcPrint.ParamByName('SERIE_ALBC').AsString  := ASerie;
  unqryCabAlbcPrint.ParamByName('NUMERO_ALBC').AsString := ANumero;
  unqryCabAlbcPrint.Open;
  unqryLinAlbcPrint.Close;
  unqryLinAlbcPrint.ParamByName('SERIE_ALBC').AsString  := ASerie;
  unqryLinAlbcPrint.ParamByName('NUMERO_ALBC').AsString := ANumero;
  unqryLinAlbcPrint.Open;
  unqryGuiasAlbcPrint.Close;
  unqryGuiasAlbcPrint.ParamByName('SERIE_ALBC').AsString  := ASerie;
  unqryGuiasAlbcPrint.ParamByName('NUMERO_ALBC').AsString := ANumero;
  unqryGuiasAlbcPrint.Open;
end;

procedure TdmAlbaranesCompra.CargarAlmacenesDelAlbaran(
                                      const ASerie, ANumero: string;
                                      ALV: TObject);
var
  oQry  : TUniQuery;
  oLv   : TcxListView;
  oItem : TListItem;
begin
  if not (ALV is TcxListView) then Exit;
  oLv := TcxListView(ALV);
  oLv.Items.BeginUpdate;
  try
    oLv.Items.Clear;
    oQry := TUniQuery.Create(nil);
    try
      oQry.Connection := inLibGlobalVar.oConn;
      oQry.SQL.Text :=
        'SELECT DISTINCT L.CODIGO_ALMACEN_ALBCLIN AS COD, ' +
        '       COALESCE(A.NOMBRE_ALM_ALM, L.CODIGO_ALMACEN_ALBCLIN) AS NOM ' +
        '  FROM fza_albaranes_compra_lineas L ' +
        '  LEFT JOIN fza_almacenes A ON A.CODIGO_ALM_ALM = L.CODIGO_ALMACEN_ALBCLIN ' +
        ' WHERE L.SERIE_ALBC_ALBCLIN = :s AND L.NUMERO_ALBC_ALBCLIN = :n ' +
        '   AND COALESCE(L.CODIGO_ALMACEN_ALBCLIN, '''') <> '''' ' +
        ' ORDER BY COD';
      oQry.ParamByName('s').AsString := ASerie;
      oQry.ParamByName('n').AsString := ANumero;
      oQry.Open;
      while not oQry.Eof do
      begin
        oItem := oLv.Items.Add;
        oItem.Caption := oQry.FieldByName('COD').AsString;
        oItem.SubItems.Add(oQry.FieldByName('NOM').AsString);
        oItem.Checked := True;
        oQry.Next;
      end;
    finally
      FreeAndNil(oQry);
    end;
  finally
    oLv.Items.EndUpdate;
  end;
end;

procedure TdmAlbaranesCompra.CrearDataSetEtiquetasAlb(ADmArt: TObject;
                                  const ASerie, ANumero,
                                        ACodTarifa, AAlmacenesCsv: string;
                                  AFecha: TDateTime);
var
  oDmArt  : TdmArticulos;
  sSkus   : string;
begin
  // Reutilizamos el dataset / lookup de etiquetas del DM de articulos
  // (cdsEtiquetasArt, unqryArtPrint, fxdsEtiquetasArt) para que el
  // mismo .fr3 sirva en ambos modales. La query base filtra YA en
  // servidor por SKU IN (...) — la version anterior cargaba todos y
  // filtraba en cliente, tardaba 10 s sobre una BBDD con muchos SKUs.
  if not (ADmArt is TdmArticulos) then Exit;
  oDmArt := TdmArticulos(ADmArt);
  sSkus  := ObtenerSkusAlbaranCsv(ASerie, ANumero);
  if sSkus = '' then Exit;
  oDmArt.CrearDataSetEtiquetasArt('', ACodTarifa, AAlmacenesCsv,
                                  AFecha, sSkus);
end;

function TdmAlbaranesCompra.ObtenerSkusAlbaranCsv(
                                  const ASerie, ANumero: string): string;
var
  oQry : TUniQuery;
begin
  // Devuelve una lista de SKUs lista para inyectar en un IN (...) SQL:
  // ''SKU1'',''SKU2'',... — cada uno entrecomillado y escapado.
  Result := '';
  oQry := TUniQuery.Create(nil);
  try
    oQry.Connection := inLibGlobalVar.oConn;
    oQry.SQL.Text :=
      'SELECT DISTINCT CODIGO_UNIDAD_ALBCLIN ' +
      '  FROM fza_albaranes_compra_lineas ' +
      ' WHERE SERIE_ALBC_ALBCLIN = :s AND NUMERO_ALBC_ALBCLIN = :n ' +
      '   AND COALESCE(CODIGO_UNIDAD_ALBCLIN, '''') <> ''''';
    oQry.ParamByName('s').AsString := ASerie;
    oQry.ParamByName('n').AsString := ANumero;
    oQry.Open;
    while not oQry.Eof do
    begin
      if Result <> '' then Result := Result + ',';
      Result := Result + QuotedStr(
        oQry.FieldByName('CODIGO_UNIDAD_ALBCLIN').AsString);
      oQry.Next;
    end;
  finally
    FreeAndNil(oQry);
  end;
end;

procedure TdmAlbaranesCompra.PrepararPrintSku(const ASerie, ANumero: string);
begin
  unqryCabAlbcPrint.Close;
  unqryCabAlbcPrint.ParamByName('SERIE_ALBC').AsString  := ASerie;
  unqryCabAlbcPrint.ParamByName('NUMERO_ALBC').AsString := ANumero;
  unqryCabAlbcPrint.Open;
  unqryLinAlbcSkuPrint.Close;
  unqryLinAlbcSkuPrint.ParamByName('SERIE_ALBC').AsString  := ASerie;
  unqryLinAlbcSkuPrint.ParamByName('NUMERO_ALBC').AsString := ANumero;
  unqryLinAlbcSkuPrint.Open;
end;

end.
