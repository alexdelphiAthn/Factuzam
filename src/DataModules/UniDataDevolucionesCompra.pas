{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataDevolucionesCompra                                        }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de DEVOLUCIONES A PROVEEDOR (devoluciones de compra).         }
{    Espejo de UniDataAlbaranesCompra: misma cabecera + lineas sobre           }
{    proveedor y precio de compra. Sincroniza movimientos de salida DC         }
{    desde la cabecera y lineas actuales del documento.                        }
{******************************************************************************}
unit UniDataDevolucionesCompra;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Vcl.ComCtrls, cxListView,
  Data.DB, MemDS, DBAccess, Uni,
  frxClass, frxDBSet,
  UniDataGen, UniDataArticulos, inLibUser;

type
  TdmDevolucionesCompra = class(TdmBase)
    unqryDevolucionesCompraLineas: TUniQuery;
    dsDevolucionesCompraLineas:    TDataSource;
    unqryEmpDataDevc:           TUniQuery;
    unqryPrvDataDevc:           TUniQuery;
    dsPrvDataDevc:              TDataSource;
    unqryArtDataLinDevc:        TUniQuery;
    unqrySkusDevc:              TUniQuery;
    unqryAlmacenesDevc:         TUniQuery;
    dsAlmacenesDevc:            TDataSource;
    unqryMovimientosProveedor:  TUniQuery;
    dsMovimientosProveedor:     TDataSource;
    unstrdprcGetContadorDevc:   TUniStoredProc;
    // Definicion de atributos del articulo padre (para columnas
    // dinamicas ATTR1..ATTR5 en modo "atributo por columna").
    unqryDefArticuloDevc:       TUniQuery;
    // Datasets para impresion del devolucion via FastReport. Mismo patron
    // que TdmComprasSesiones (unqry*Print -> ds*Print -> fxds*). El
    // .fr3 embebido en el modal inMtoModalImpDevCompra.dfm los
    // referencia por UserName ('Devolucion', 'LineasDevolucion').
    unqryCabDevcPrint:          TUniQuery;
    dsCabDevcPrint:             TDataSource;
    fxdsCabDevc:                TfrxDBDataset;
    unqryLinDevcPrint:          TUniQuery;
    dsLinDevcPrint:             TDataSource;
    fxdsLinDevc:                TfrxDBDataset;
    unqryGuiasDevcPrint:        TUniQuery;
    dsGuiasDevcPrint:           TDataSource;
    fxdsGuiasDevc:              TfrxDBDataset;
    // Lineas "planas" (una fila por SKU sin pivotar por talla) para el
    // formato vertical estilo factura.
    unqryLinDevcSkuPrint:       TUniQuery;
    dsLinDevcSkuPrint:          TDataSource;
    fxdsLinDevcSku:             TfrxDBDataset;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryDevolucionesCompraLineasAfterInsert(DataSet: TDataSet);
    procedure unqryDevolucionesCompraLineasBeforePost(DataSet: TDataSet);
    procedure unqryDevolucionesCompraLineasAfterPost(DataSet: TDataSet);
    procedure unqryDevolucionesCompraLineasAfterDelete(DataSet: TDataSet);
  private
    // True mientras DesempaquetarAtributosLineas postea lineas: cambio
    // puramente descriptivo que NO debe disparar la logica fiscal ni
    // la sincronizacion de movimientos (cascada por linea al navegar).
    FDesempaquetandoAtributos: Boolean;
    procedure AsignarNumeroLineaDevolucionCompra(DataSet: TDataSet);
    function CampoVistaCabeceraPrintExiste(const ACampo: string): Boolean;
    function HayLineasMovimiento(const ASerie, ANumero: string): Boolean;
    procedure PrepararSQLCabeceraPrint;
    function ObtenerSkusDevolucionCsv(const ASerie, ANumero: string): string;
    procedure RefrescarMovimientosProveedor;
    procedure ValidarAlmacenSalida;
  public
    procedure GetCodigoAutoDevolucionCompra;
    procedure CalcularTotalesDevolucionCompra;
    // Numero total de prendas (suma CANTIDAD_DEVCLIN de todas las lineas).
    // Se muestra en la pestana Totales; no se persiste en BBDD.
    function TotalPrendasDevolucion: Double;
    // Contrato ColumnSKUcxGrid: desglosa el SKU ART/COLOR/TALLA en las
    // columnas reales ATTR1..5_VALOR_DEVCLIN + NUM_ATRIBUTOS_DEVCLIN
    // (idempotente por comparacion, mismo criterio que albaranes compra).
    procedure DesempaquetarAtributosLineas;
    procedure SincronizarMovimientos;
    // Abre unqryCabDevcPrint y unqryLinDevcPrint con los parametros
    // del devolucion a imprimir. Mismo nombre/firma que en sesiones.
    procedure PrepararPrint(const ASerie, ANumero: string);
    // Version SKU (lineas planas, sin pivote talla) para el modal
    // vertical estilo factura.
    procedure PrepararPrintSku(const ASerie, ANumero: string);
    // Carga en el listview los almacenes distintos que aparecen en las
    // lineas del devolucion (usado por el modal de pegatinas).
    procedure CargarAlmacenesDelDevolucion(const ASerie, ANumero: string;
                                         ALV: TObject);
    // Crea el dataset cdsEtiquetasArt del DM articulos filtrado a los
    // SKUs del devolucion. Reutiliza la query base de etiquetas anyadiendo
    // un WHERE por SKU IN (SELECT ... FROM devoluciones_compra_lineas).
    procedure CrearDataSetEtiquetasAlb(ADmArt: TObject;
                                        const ASerie, ANumero,
                                              ACodTarifa, AAlmacenesCsv: string;
                                        AFecha: TDateTime);
    procedure OpenTables;
    procedure RefrescarAlmacenes(const ACodigoEmpresa: string);
    // Override: abre las queries detalle tras unqryTablaG. Llamada
    // desde TfrmMtoGen.AbrirTablaPrincipalAsync.
    // El form empuja su dsTablaG; el DM ya no usa GetOwnerForm.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    procedure AbrirDetalles; override;
  end;

implementation

uses
  inLibValoresAutomaticos,
  System.Diagnostics, System.UITypes,
  inLibDevolucionesCompraMovimientos,
  UniDataDevolucionesCompraMovimientos,
  inLibContadorLineas,
  UniDataContadorLineasRepositorio,
  inLibComprasImpuestos,
  inLibData,
  inLibArticulosValidadorIntf,
  UniDataArticulosValidadorRepositorio,
  inLibMsgCompras, inLibDocumento, inLibDocumentoIntf;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmDevolucionesCompra.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection                := ConexionPrincipal;
  unqryDevolucionesCompraLineas.Connection := ConexionPrincipal;
  unqryDevolucionesCompraLineas.KeyFields :=
    'SERIE_DEVC_DEVCLIN;NUMERO_DEVC_DEVCLIN;LINEA_DEVCLIN';
  unqryDevolucionesCompraLineas.SQLDelete.Text :=
    'DELETE FROM fza_devoluciones_compra_lineas ' +
    ' WHERE SERIE_DEVC_DEVCLIN = :Old_SERIE_DEVC_DEVCLIN ' +
    '   AND NUMERO_DEVC_DEVCLIN = :Old_NUMERO_DEVC_DEVCLIN ' +
    '   AND LINEA_DEVCLIN = :Old_LINEA_DEVCLIN';
  unqryEmpDataDevc.Connection           := ConexionPrincipal;
  unqryPrvDataDevc.Connection           := ConexionPrincipal;
  // Lookup completo de proveedores (NOMBRE_PRV + RAZON_SOCIAL_PRV) para
  // el rotulo resuelto de la cabecera y para el combo de busqueda
  // incremental por codigo (cbbCODIGO_PRV_DEVC). Se abre una vez y se
  // recorre con Locate; no depende del proveedor de la devolucion en
  // pantalla.
  unqryPrvDataDevc.Open;
  unqryArtDataLinDevc.Connection        := ConexionPrincipal;
  unqrySkusDevc.Connection              := ConexionPrincipal;
  unqryAlmacenesDevc.Connection         := ConexionPrincipal;
  unqryMovimientosProveedor.Connection  := ConexionPrincipal;
  unstrdprcGetContadorDevc.Connection   := ConexionPrincipal;
  unqryDefArticuloDevc.Connection       := ConexionPrincipal;
  // Master-detail server-side: el WHERE del SQL toma los valores de
  // dsTablaG (master), evitando descargar fza_devoluciones_compra_lineas
  // entera y filtrar en cliente.
end;

procedure TdmDevolucionesCompra.AsignarMaestroCabecera(
  ADataSource: TDataSource);
begin
  inherited;
  unqryDevolucionesCompraLineas.MasterSource := ADataSource;
  unqryMovimientosProveedor.MasterSource := ADataSource;
end;

procedure TdmDevolucionesCompra.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(unqryDevolucionesCompraLineas) and
     unqryDevolucionesCompraLineas.Active then
    unqryDevolucionesCompraLineas.Close;
  if Assigned(unqryMovimientosProveedor) and
     unqryMovimientosProveedor.Active then
    unqryMovimientosProveedor.Close;
  inherited;
end;

procedure TdmDevolucionesCompra.OpenTables;
begin
  // Delegamos en AbrirDetalles para unificar logging y cronometro.
  AbrirDetalles;
end;

procedure TdmDevolucionesCompra.AbrirDetalles;
const
  TAG = 'DevolucionesCompra.AbrirDetalles';

  procedure AbrirConTiempo(qry: TUniQuery; const Nombre: string);
  var
    swQ: TStopwatch;
  begin
    if qry.Active then Exit;
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

var
  sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  RefrescarAlmacenes(UbicacionSesion.Empresa);
  AbrirConTiempo(unqryDevolucionesCompraLineas,
                 'unqryDevolucionesCompraLineas');
  AbrirConTiempo(unqryMovimientosProveedor,
                 'unqryMovimientosProveedor');
  RegistroLog.RegistrarRendimiento(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmDevolucionesCompra.RefrescarAlmacenes(
                                                const ACodigoEmpresa: string);
var
  sEmpresa: string;
begin
  sEmpresa := Trim(ACodigoEmpresa);
  if sEmpresa = '' then
    sEmpresa := Trim(UbicacionSesion.Empresa);
  if (not unqryAlmacenesDevc.Active) or
     (not SameText(unqryAlmacenesDevc.ParamByName('EMPRESA').AsString,
                   sEmpresa)) then
  begin
    unqryAlmacenesDevc.Close;
    unqryAlmacenesDevc.ParamByName('EMPRESA').AsString := sEmpresa;
    unqryAlmacenesDevc.Open;
  end;
  if unqryTablaG.Active and
     (unqryTablaG.State in [dsInsert, dsEdit]) then
    AjustarEmpresaAlmacenDataSet(unqryTablaG.Connection, unqryTablaG,
      'CODIGO_EMP_DEVC', 'CODIGO_ALM_DEVC');
end;

procedure TdmDevolucionesCompra.ValidarAlmacenSalida;
begin
  if Trim(unqryTablaG.FieldByName('CODIGO_ALM_DEVC').AsString) = '' then
    raise Exception.Create(SErrorAlmacenSalidaDevolucionCompra);
end;

procedure TdmDevolucionesCompra.unqryTablaGAfterInsert(DataSet: TDataSet);
var
  sSerie: string;
begin
  inherited;
  with unqryTablaG do
  begin
    FieldByName('NUMERO_DEVC').AsString := '0';
    // Serie por defecto: buscar en fza_empresas_series para TIPO_DOC='DC'
    sSerie := ObtenerSerieDefecto(
      ConexionPrincipal,
      UbicacionSesion.Empresa,
      CrearConfiguracionDocumento(
        tdDevolucion, sdCompra).TipoContador);
    if FindField('SERIE_DEVC') <> nil then
    begin
      if sSerie <> '' then
        FieldByName('SERIE_DEVC').AsString := sSerie
      else
        FieldByName('SERIE_DEVC').AsString := 'C1';
    end;
    FieldByName('FECHA_DEVC').AsDateTime := Date;
    if FindField('ESTADO_DEVC') <> nil then
      FieldByName('ESTADO_DEVC').AsString := 'ABIERTO';
    if Trim(UbicacionSesion.Empresa) <> '' then
      FieldByName('CODIGO_EMP_DEVC').AsString := UbicacionSesion.Empresa
    else
      FieldByName('CODIGO_EMP_DEVC').AsString := '0';
    FieldByName('CODIGO_PRV_DEVC').AsString := '0';
    if FindField('ESIVA_EXENTO_INTRACOMUNITARIO_DEVC') <> nil then
      FieldByName('ESIVA_EXENTO_INTRACOMUNITARIO_DEVC').AsString := 'N';
    if FindField('ESPIVOTE_HORIZONTAL_DEVC') <> nil then
      FieldByName('ESPIVOTE_HORIZONTAL_DEVC').AsString := 'N';
    AplicarRecargoComprasEmpresa(ConexionPrincipal, unqryTablaG,
      'CODIGO_EMP_DEVC', 'ESIVA_RECARGO_COMPRAS_DEVC');
    AplicarPorcentajesIvaCompra(ConexionPrincipal, unqryTablaG,
      'DEVC');
  end;
  RefrescarAlmacenes(
    DataSet.FieldByName('CODIGO_EMP_DEVC').AsString);
end;

procedure TdmDevolucionesCompra.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  ValidarAlmacenSalida;
  if (DataSet.FindField('ESPIVOTE_HORIZONTAL_DEVC') <> nil) and
     (Trim(DataSet.FieldByName('ESPIVOTE_HORIZONTAL_DEVC').AsString) = '')
  then
    DataSet.FieldByName('ESPIVOTE_HORIZONTAL_DEVC').AsString := 'N';
  if (unqryTablaG.FieldByName('NUMERO_DEVC').AsString = '0') or
     (unqryTablaG.FieldByName('NUMERO_DEVC').AsString = '') then
    GetCodigoAutoDevolucionCompra;
  AplicarPorcentajesIvaCompra(ConexionPrincipal, unqryTablaG,
    'DEVC');
  CalcularTotalesDevolucionCompra;
end;

// Tras persistir la cabecera, reconstruimos los movimientos DC desde el
// documento actual. Cualquier excepcion se propaga al usuario (el Post
// original ya quedo aplicado, por lo que debe revisar y reintentar).
procedure TdmDevolucionesCompra.unqryTablaGAfterPost(DataSet: TDataSet);
begin
  inherited;
  SincronizarMovimientos;
end;

procedure TdmDevolucionesCompra.unqryTablaGBeforeDelete(DataSet: TDataSet);
var
  q: TUniQuery;
  sNumero: string;
  sSerie: string;
  iBloqueos: Integer;

  procedure AsignarDocumento;
  begin
    q.ParamByName('s').AsString := sSerie;
    q.ParamByName('n').AsString := sNumero;
  end;

begin
  inherited;
  sSerie := DataSet.FieldByName('SERIE_DEVC').AsString;
  sNumero := DataSet.FieldByName('NUMERO_DEVC').AsString;
  if (sSerie = '') or (sNumero = '') then
  begin
    Abort;
  end;
  q := TUniQuery.Create(nil);
  try
    q.Connection := unqryTablaG.Connection;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_devoluciones_compra ' +
      ' WHERE SERIE_DEVC  = :s ' +
      '   AND NUMERO_DEVC = :n ' +
      '   AND (COALESCE(NUMERO_FAC_DEVC, '''') <> '''' ' +
      '    OR COALESCE(SERIE_FAC_DEVC, '''') <> '''')';
    AsignarDocumento;
    q.Open;
    iBloqueos := q.FieldByName('N').AsInteger;
    q.Close;
    if iBloqueos = 0 then
    begin
      q.SQL.Text :=
        'SELECT COUNT(*) AS N ' +
        '  FROM fza_devoluciones_compra_lineas ' +
        ' WHERE SERIE_DEVC_DEVCLIN  = :s ' +
        '   AND NUMERO_DEVC_DEVCLIN = :n ' +
        '   AND (COALESCE(ESFACTURADA_DEVCLIN, ''N'') = ''S'' ' +
        '    OR COALESCE(NUMERO_FAC_DEVCLIN, '''') <> '''' ' +
        '    OR COALESCE(SERIE_FAC_DEVCLIN, '''') <> '''')';
      AsignarDocumento;
      q.Open;
      iBloqueos := q.FieldByName('N').AsInteger;
      q.Close;
    end;
    if iBloqueos > 0 then
    begin
      NotificarAdvertencia(SAvisoDevolucionCompraFacturada);
      Abort;
    end;
    if not SolicitarConfirmacion(
      Format(SPreguntaBorrarDevolucionCompra,
        [sSerie, sNumero])) then
    begin
      Abort;
    end;
    inLibDevolucionesCompraMovimientos.
      RevertirMovimientosDesdeDevolucionCompra(
        CrearMovimientosDevolucionCompraUniDAC(unqryTablaG.Connection),
        sSerie, sNumero, IdentidadSesion.Usuario);
    q.SQL.Text :=
      'DELETE FROM fza_devoluciones_compra_celdas ' +
      ' WHERE SERIE_DEVC_DEVCCEL  = :s ' +
      '   AND NUMERO_DEVC_DEVCCEL = :n';
    AsignarDocumento;
    q.ExecSQL;
    q.SQL.Text :=
      'DELETE FROM fza_devoluciones_compra_lineas ' +
      ' WHERE SERIE_DEVC_DEVCLIN  = :s ' +
      '   AND NUMERO_DEVC_DEVCLIN = :n';
    AsignarDocumento;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

procedure TdmDevolucionesCompra.unqryDevolucionesCompraLineasAfterInsert(
                                                       DataSet: TDataSet);
begin
  inherited;
  with unqryDevolucionesCompraLineas do
  begin
    FieldByName('NUMERO_DEVC_DEVCLIN').AsString :=
      unqryTablaG.FieldByName('NUMERO_DEVC').AsString;
    FieldByName('SERIE_DEVC_DEVCLIN').AsString :=
      unqryTablaG.FieldByName('SERIE_DEVC').AsString;
    FieldByName('LINEA_DEVCLIN').AsString := '0000';
    FieldByName('CANTIDAD_DEVCLIN').AsFloat := 1;
    if FindField('ESFACTURADA_DEVCLIN') <> nil then
      FieldByName('ESFACTURADA_DEVCLIN').AsString := 'N';
    // Auditoria estandar: las 4 columnas del libro de estilo bbdd §3.7
    // son NOT NULL sin default; hay que rellenarlas en alta. En BeforePost
    // tambien sobrescribimos USUARIO_MODIF para que refleje la ultima edicion.
    FieldByName('USUARIO_ALTA').AsString    := IdentidadSesion.Usuario;
    FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    FieldByName('USUARIO_MODIF').AsString   := IdentidadSesion.Usuario;
    FieldByName('INSTANTE_MODIF').AsDateTime:= Now;
  end;
end;

procedure TdmDevolucionesCompra.unqryDevolucionesCompraLineasBeforePost(
                                                       DataSet: TDataSet);
var
  sSku, sArt: string;
begin
  inherited;
  // Desempaquetado ATTR en curso: post descriptivo, sin logica fiscal.
  if FDesempaquetandoAtributos then
    Exit;
  // Linea vacia (sin articulo ni SKU): cancelar silenciosamente. El cxGrid
  // hace Post automatico al navegar con flechas (OptionsData.Appending); si
  // la linea es un placeholder vacio que el usuario creo sin querer, el Post
  // fallaria con 'Field LINEA_DEVCLIN must have a value'. Cancel diferido +
  // Abort la descarta sin molestar al usuario. Mismo patron que Sesiones.
  if (Trim(unqryDevolucionesCompraLineas.FieldByName(
             'CODIGO_ART_DEVCLIN').AsString) = '') and
     (Trim(unqryDevolucionesCompraLineas.FieldByName(
             'CODIGO_UNIDAD_DEVCLIN').AsString) = '') then
  begin
    TThread.ForceQueue(nil,
      procedure
      begin
        if unqryDevolucionesCompraLineas.Active and
           (unqryDevolucionesCompraLineas.State in [dsEdit, dsInsert]) then
          unqryDevolucionesCompraLineas.Cancel;
      end);
    Abort;
  end;
  AsignarNumeroLineaDevolucionCompra(DataSet);
  with unqryDevolucionesCompraLineas do
  begin
    // Acepta articulo, SKU, codigo de barras o referencia de proveedor.
    NormalizarArticuloSkuEnDataSet(ConexionPrincipal,
      unqryDevolucionesCompraLineas, 'CODIGO_ART_DEVCLIN',
      'CODIGO_UNIDAD_DEVCLIN');
    if (Trim(FieldByName('NUMERO_DEVC_DEVCLIN').AsString) = '') or
       (Trim(FieldByName('NUMERO_DEVC_DEVCLIN').AsString) = '0') then
      raise Exception.Create(SErrorCabeceraDevolucionCompraSinGrabar);
    if (FindField('CANTIDAD_DEVCLIN') <> nil) and
       (FindField('PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN') <> nil) and
       (FindField('TOTAL_DEVCLIN') <> nil) then
      FieldByName('TOTAL_DEVCLIN').AsFloat :=
        FieldByName('CANTIDAD_DEVCLIN').AsFloat *
        FieldByName('PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN').AsFloat;
    // Refrescamos auditoria en cada Post (edicion / alta nueva).
    if FindField('USUARIO_MODIF') <> nil then
      FieldByName('USUARIO_MODIF').AsString   := IdentidadSesion.Usuario;
    if FindField('INSTANTE_MODIF') <> nil then
      FieldByName('INSTANTE_MODIF').AsDateTime:= Now;
    // En alta (State=dsInsert) tambien los campos *_ALTA por si
    // AfterInsert no los puso (p.ej. inserciones programaticas).
    if (DataSet.State = dsInsert) then
    begin
      if (FindField('USUARIO_ALTA') <> nil) and
         (FieldByName('USUARIO_ALTA').AsString = '') then
        FieldByName('USUARIO_ALTA').AsString := IdentidadSesion.Usuario;
      if (FindField('INSTANTE_ALTA') <> nil) and
         FieldByName('INSTANTE_ALTA').IsNull then
        FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    end;

    // Si el usuario tecleo un SKU pero no el articulo, lo deducimos
    // consultando fza_articulos_skus (mismo patron que en venta).
    if (FindField('CODIGO_UNIDAD_DEVCLIN') <> nil) and
       (FindField('CODIGO_ART_DEVCLIN') <> nil) then
    begin
      sSku := Trim(FieldByName('CODIGO_UNIDAD_DEVCLIN').AsString);
      sArt := Trim(FieldByName('CODIGO_ART_DEVCLIN').AsString);
      if (sSku <> '') and (sArt = '') then
      begin
        unqrySkusDevc.Close;
        unqrySkusDevc.ParamByName('pSKU').AsString := sSku;
        unqrySkusDevc.Open;
        if not unqrySkusDevc.Eof then
          FieldByName('CODIGO_ART_DEVCLIN').AsString :=
            unqrySkusDevc.FieldByName('CODIGO_ART_SKU').AsString;
        unqrySkusDevc.Close;
      end;
    end;
    PrepararLineaFiscalCompra(ConexionPrincipal, unqryTablaG,
      unqryDevolucionesCompraLineas, 'DEVC', 'DEVCLIN', 'TOTAL_DEVCLIN');
  end;
end;

procedure TdmDevolucionesCompra.AsignarNumeroLineaDevolucionCompra(
                                                       DataSet: TDataSet);
var
  iNuevaLinea: Integer;
  sLinea: string;
  sNumero: string;
  sSerie: string;
begin
  if DataSet.FindField('LINEA_DEVCLIN') <> nil then
  begin
    sLinea := Trim(DataSet.FieldByName('LINEA_DEVCLIN').AsString);
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_DEVC').AsString);
    sSerie  := Trim(unqryTablaG.FieldByName('SERIE_DEVC').AsString);
    if (sLinea = '') or (StrToIntDef(sLinea, 0) = 0) or
       ((DataSet.State = dsInsert) and
        LineaDocExiste(CrearContadorLineasDocumento(ConexionPrincipal),
          LIN_DEVOLUCIONES_COMPRA, sSerie,
          sNumero, sLinea)) then
    begin
      if (sNumero = '') or (sNumero = '0') or (sSerie = '') then
        raise Exception.Create(SErrorCabeceraDevolucionCompraSinGrabar);
      if DataSet.FindField('NUMERO_DEVC_DEVCLIN') <> nil then
        DataSet.FieldByName('NUMERO_DEVC_DEVCLIN').AsString := sNumero;
      if DataSet.FindField('SERIE_DEVC_DEVCLIN') <> nil then
        DataSet.FieldByName('SERIE_DEVC_DEVCLIN').AsString := sSerie;
      iNuevaLinea := GetSiguienteLineaDocLibre(
        CrearContadorLineasDocumento(ConexionPrincipal),
        CONT_DEVOLUCIONES_COMPRA, LIN_DEVOLUCIONES_COMPRA, sSerie, sNumero);
      if iNuevaLinea = 0 then
      begin
        iNuevaLinea := StrToIntDef(
          unqryTablaG.FieldByName('CONTADOR_LINEAS_DEVC').AsString, 0) + 10;
      end;
      if unqryTablaG.FindField('CONTADOR_LINEAS_DEVC') <> nil then
      begin
        if not (unqryTablaG.State in [dsEdit, dsInsert]) then
          unqryTablaG.Edit;
        unqryTablaG.FieldByName('CONTADOR_LINEAS_DEVC').AsString :=
          Format('%.8d', [iNuevaLinea]);
      end;
      DataSet.FieldByName('LINEA_DEVCLIN').AsString :=
        Format('%.4d', [iNuevaLinea]);
    end;
  end;
end;

procedure TdmDevolucionesCompra.unqryDevolucionesCompraLineasAfterPost(
                                                       DataSet: TDataSet);
begin
  inherited;
  CalcularTotalesDevolucionCompra;
  SincronizarMovimientos;
end;

procedure TdmDevolucionesCompra.unqryDevolucionesCompraLineasAfterDelete(
                                                       DataSet: TDataSet);
begin
  inherited;
  CalcularTotalesDevolucionCompra;
  SincronizarMovimientos;
end;

procedure TdmDevolucionesCompra.GetCodigoAutoDevolucionCompra;
var
  iNumero: Int64;
  sNumero: string;
begin
  with unstrdprcGetContadorDevc do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'pserie',            ptInput);
    Params.CreateParam(ftString, 'ptipodoc',          ptInput);
    Params.CreateParam(ftString, 'pEMPRESA_CONTADOR', ptInput);
    Params.CreateParam(ftString, 'pUSUARIOMODIF',     ptInput);
    Params.CreateParam(ftString, 'pcont',             ptOutput);
    ParamByName('pserie').AsString :=
      unqryTablaG.FieldByName('SERIE_DEVC').AsString;
    ParamByName('ptipodoc').AsString :=
      CrearConfiguracionDocumento(
        tdDevolucion, sdCompra).TipoContador;
    ParamByName('pUSUARIOMODIF').AsString := IdentidadSesion.Usuario;
    ParamByName('pEMPRESA_CONTADOR').AsString :=
      unqryTablaG.FieldByName('CODIGO_EMP_DEVC').AsString;
    ExecProc;
    sNumero := Trim(ParamByName('pcont').AsString);
    if (sNumero = '') or (not TryStrToInt64(sNumero, iNumero)) or
       (iNumero <= 0) then
      raise Exception.Create(Format(SErrorContadorDevolucionCompra,
        [unqryTablaG.FieldByName('SERIE_DEVC').AsString,
         unqryTablaG.FieldByName('CODIGO_EMP_DEVC').AsString]));
    unqryTablaG.FieldByName('NUMERO_DEVC').AsString := sNumero;
  end;
end;

procedure TdmDevolucionesCompra.CalcularTotalesDevolucionCompra;
begin
  // Los posts del desempaquetado ATTR no alteran importes: saltar el
  // recalculo por linea (cascada de consultas de IVA al navegar).
  if FDesempaquetandoAtributos then
    Exit;
  CalcularTotalesDocumentoCompra(unqryTablaG.Connection, unqryTablaG,
    unqryDevolucionesCompraLineas, 'DEVC', 'TOTAL_DEVCLIN',
    'TIPO_IVA_ARTICULO_DEVCLIN', 'PORCENTAJE_IVA_DEVCLIN');
end;

function TdmDevolucionesCompra.TotalPrendasDevolucion: Double;
begin
  Result := TotalPrendasLineasCompra(unqryDevolucionesCompraLineas,
    'TIPO_IVA_ARTICULO_DEVCLIN', 'TOTAL_UNIDADES_DEVCLIN');
end;

function TdmDevolucionesCompra.HayLineasMovimiento(const ASerie,
  ANumero: string): Boolean;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := unqryTablaG.Connection;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_devoluciones_compra_lineas ' +
      ' WHERE SERIE_DEVC_DEVCLIN  = :s ' +
      '   AND NUMERO_DEVC_DEVCLIN = :n ' +
      '   AND IFNULL(CANTIDAD_DEVCLIN, 0) > 0';
    q.ParamByName('s').AsString := ASerie;
    q.ParamByName('n').AsString := ANumero;
    q.Open;
    Result := q.FieldByName('N').AsInteger > 0;
  finally
    FreeAndNil(q);
  end;
end;

procedure TdmDevolucionesCompra.RefrescarMovimientosProveedor;
begin
  if unqryMovimientosProveedor.Active then
  begin
    unqryMovimientosProveedor.Close;
    unqryMovimientosProveedor.Open;
  end;
end;

procedure TdmDevolucionesCompra.SincronizarMovimientos;
var
  sNumero: string;
  sSerie: string;
begin
  // Los posts del desempaquetado ATTR no tocan cantidades ni SKUs:
  // saltar el borrado/recreacion de movimientos y recalculo de PMP.
  if FDesempaquetandoAtributos then
    Exit;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
  begin
    sSerie := Trim(unqryTablaG.FieldByName('SERIE_DEVC').AsString);
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_DEVC').AsString);
    if (sSerie <> '') and (sNumero <> '') and (sNumero <> '0') then
    begin
      inLibDevolucionesCompraMovimientos.
        RevertirMovimientosDesdeDevolucionCompra(
          CrearMovimientosDevolucionCompraUniDAC(unqryTablaG.Connection),
          sSerie, sNumero, IdentidadSesion.Usuario);
      if HayLineasMovimiento(sSerie, sNumero) then
        inLibDevolucionesCompraMovimientos.
          GenerarMovimientosDesdeDevolucionCompra(
            CrearMovimientosDevolucionCompraUniDAC(unqryTablaG.Connection),
            sSerie, sNumero, IdentidadSesion.Usuario);
      RefrescarMovimientosProveedor;
    end;
  end;
end;

function TdmDevolucionesCompra.CampoVistaCabeceraPrintExiste(
  const ACampo: string): Boolean;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionPrincipal;
    q.SQL.Text :=
      'SELECT 1 ' +
      '  FROM INFORMATION_SCHEMA.COLUMNS ' +
      ' WHERE TABLE_SCHEMA = DATABASE() ' +
      '   AND TABLE_NAME = ''vi_devoluciones_compra_cab_print'' ' +
      '   AND COLUMN_NAME = :campo ' +
      ' LIMIT 1';
    q.ParamByName('campo').AsString := ACampo;
    q.Open;
    Result := not q.IsEmpty;
  finally
    FreeAndNil(q);
  end;
end;

procedure TdmDevolucionesCompra.PrepararSQLCabeceraPrint;
var
  bDoc   : Boolean;
  bUds   : Boolean;
  bLineas: Boolean;
  sSql   : string;
begin
  bDoc := CampoVistaCabeceraPrintExiste('DOCUMENTO_FORMATO');
  bUds := CampoVistaCabeceraPrintExiste('TOTAL_UNIDADES_SES');
  bLineas := CampoVistaCabeceraPrintExiste('TOTAL_LINEAS_SES');
  sSql := 'SELECT V.* ';
  if not bDoc then
    sSql := sSql +
      ', CASE WHEN TRIM(COALESCE(V.SERIE_DEVC, '''')) = '''' ' +
      '       THEN TRIM(COALESCE(V.NUMERO_DEVC, '''')) ' +
      '       WHEN TRIM(COALESCE(V.NUMERO_DEVC, '''')) = '''' ' +
      '       THEN TRIM(COALESCE(V.SERIE_DEVC, '''')) ' +
      '       ELSE CONCAT(TRIM(COALESCE(V.SERIE_DEVC, '''')), ''.'', ' +
      '                   TRIM(COALESCE(V.NUMERO_DEVC, ''''))) END ' +
      '       AS DOCUMENTO_FORMATO ';
  if not bUds then
    sSql := sSql +
      ', (SELECT COALESCE(SUM(L.CANTIDAD_DEVCLIN), 0) ' +
      '     FROM fza_devoluciones_compra_lineas L ' +
      '    WHERE L.SERIE_DEVC_DEVCLIN = V.SERIE_DEVC ' +
      '      AND L.NUMERO_DEVC_DEVCLIN = V.NUMERO_DEVC) ' +
      '       AS TOTAL_UNIDADES_SES ';
  if not bLineas then
    sSql := sSql +
      ', (SELECT COALESCE(SUM(L.TOTAL_DEVCLIN), 0) ' +
      '     FROM fza_devoluciones_compra_lineas L ' +
      '    WHERE L.SERIE_DEVC_DEVCLIN = V.SERIE_DEVC ' +
      '      AND L.NUMERO_DEVC_DEVCLIN = V.NUMERO_DEVC) ' +
      '       AS TOTAL_LINEAS_SES ';
  sSql := sSql +
    '  FROM vi_devoluciones_compra_cab_print V ' +
    ' WHERE V.SERIE_DEVC = :SERIE_DEVC ' +
    '   AND V.NUMERO_DEVC = :NUMERO_DEVC';
  unqryCabDevcPrint.SQL.Text := sSql;
end;

procedure TdmDevolucionesCompra.PrepararPrint(const ASerie, ANumero: string);
begin
  unqryCabDevcPrint.Close;
  PrepararSQLCabeceraPrint;
  unqryCabDevcPrint.ParamByName('SERIE_DEVC').AsString  := ASerie;
  unqryCabDevcPrint.ParamByName('NUMERO_DEVC').AsString := ANumero;
  unqryCabDevcPrint.Open;
  unqryLinDevcPrint.Close;
  unqryLinDevcPrint.ParamByName('SERIE_DEVC').AsString  := ASerie;
  unqryLinDevcPrint.ParamByName('NUMERO_DEVC').AsString := ANumero;
  unqryLinDevcPrint.Open;
  unqryGuiasDevcPrint.Close;
  unqryGuiasDevcPrint.ParamByName('SERIE_DEVC').AsString  := ASerie;
  unqryGuiasDevcPrint.ParamByName('NUMERO_DEVC').AsString := ANumero;
  unqryGuiasDevcPrint.Open;
end;

procedure TdmDevolucionesCompra.CargarAlmacenesDelDevolucion(
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
      oQry.Connection := ConexionPrincipal;
      oQry.SQL.Text :=
        'SELECT DISTINCT L.CODIGO_ALMACEN_DEVCLIN AS COD, ' +
        '       COALESCE(A.NOMBRE_ALM_ALM, L.CODIGO_ALMACEN_DEVCLIN) AS NOM ' +
        '  FROM fza_devoluciones_compra_lineas L ' +
        '  LEFT JOIN fza_almacenes A ON A.CODIGO_ALM_ALM = L.CODIGO_ALMACEN_DEVCLIN ' +
        ' WHERE L.SERIE_DEVC_DEVCLIN = :s AND L.NUMERO_DEVC_DEVCLIN = :n ' +
        '   AND COALESCE(L.CODIGO_ALMACEN_DEVCLIN, '''') <> '''' ' +
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

procedure TdmDevolucionesCompra.CrearDataSetEtiquetasAlb(ADmArt: TObject;
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
  sSkus  := ObtenerSkusDevolucionCsv(ASerie, ANumero);
  if sSkus = '' then Exit;
  oDmArt.CrearDataSetEtiquetasArt('', ACodTarifa, AAlmacenesCsv,
                                  AFecha, sSkus);
end;

function TdmDevolucionesCompra.ObtenerSkusDevolucionCsv(
                                  const ASerie, ANumero: string): string;
var
  oQry : TUniQuery;
begin
  // Devuelve una lista de SKUs lista para inyectar en un IN (...) SQL:
  // ''SKU1'',''SKU2'',... — cada uno entrecomillado y escapado.
  Result := '';
  oQry := TUniQuery.Create(nil);
  try
    oQry.Connection := ConexionPrincipal;
    oQry.SQL.Text :=
      'SELECT DISTINCT CODIGO_UNIDAD_DEVCLIN ' +
      '  FROM fza_devoluciones_compra_lineas ' +
      ' WHERE SERIE_DEVC_DEVCLIN = :s AND NUMERO_DEVC_DEVCLIN = :n ' +
      '   AND COALESCE(CODIGO_UNIDAD_DEVCLIN, '''') <> ''''';
    oQry.ParamByName('s').AsString := ASerie;
    oQry.ParamByName('n').AsString := ANumero;
    oQry.Open;
    while not oQry.Eof do
    begin
      if Result <> '' then Result := Result + ',';
      Result := Result + QuotedStr(
        oQry.FieldByName('CODIGO_UNIDAD_DEVCLIN').AsString);
      oQry.Next;
    end;
  finally
    FreeAndNil(oQry);
  end;
end;

procedure TdmDevolucionesCompra.PrepararPrintSku(const ASerie, ANumero: string);
begin
  unqryCabDevcPrint.Close;
  PrepararSQLCabeceraPrint;
  unqryCabDevcPrint.ParamByName('SERIE_DEVC').AsString  := ASerie;
  unqryCabDevcPrint.ParamByName('NUMERO_DEVC').AsString := ANumero;
  unqryCabDevcPrint.Open;
  unqryLinDevcSkuPrint.Close;
  unqryLinDevcSkuPrint.ParamByName('SERIE_DEVC').AsString  := ASerie;
  unqryLinDevcSkuPrint.ParamByName('NUMERO_DEVC').AsString := ANumero;
  unqryLinDevcSkuPrint.Open;
end;

// Contrato ColumnSKUcxGrid: desglosa el SKU (ART/COLOR/TALLA) en las
// columnas reales ATTR1..5_VALOR_DEVCLIN + NUM_ATRIBUTOS_DEVCLIN.
// Idempotente POR COMPARACION (mismo criterio que albaranes de compra):
// solo edita la linea si algun ATTR o el numero de atributos difiere.
// Si la BBDD aun no tiene las columnas ATTR (script en DESARROLLOS EN
// CURSO/ColumnSKUcxGrid), el FindField las detecta y no hace nada.
procedure TdmDevolucionesCompra.DesempaquetarAtributosLineas;
var
  Partes: TArray<string>;
  Sku, sEsperado: string;
  i: Integer;
  Bm: TBookmark;
  bCambia: Boolean;
begin
  if unqryDevolucionesCompraLineas.Active and
     (not unqryDevolucionesCompraLineas.IsEmpty) and
     (unqryDevolucionesCompraLineas.FindField(
        'ATTR1_VALOR_DEVCLIN') <> nil) and
     (unqryDevolucionesCompraLineas.FindField(
        'NUM_ATRIBUTOS_DEVCLIN') <> nil) and
     (not unqryDevolucionesCompraLineas.ReadOnly) then
  begin
    Bm := unqryDevolucionesCompraLineas.GetBookmark;
    unqryDevolucionesCompraLineas.DisableControls;
    // Posts descriptivos: silencia la logica fiscal y de movimientos.
    FDesempaquetandoAtributos := True;
    try
      unqryDevolucionesCompraLineas.First;
      while not unqryDevolucionesCompraLineas.Eof do
      begin
        Sku := unqryDevolucionesCompraLineas.FieldByName(
          'CODIGO_UNIDAD_DEVCLIN').AsString;
        Partes := Sku.Split(['/']);
        if Length(Partes) > 1 then
        begin
          bCambia := unqryDevolucionesCompraLineas.FieldByName(
            'NUM_ATRIBUTOS_DEVCLIN').AsInteger <> Length(Partes) - 1;
          for i := 1 to 5 do
          begin
            if i < Length(Partes) then
              sEsperado := Partes[i]
            else
              sEsperado := '';
            if Trim(unqryDevolucionesCompraLineas.FieldByName('ATTR' +
                 IntToStr(i) + '_VALOR_DEVCLIN').AsString) <>
               sEsperado then
              bCambia := True;
          end;
          if bCambia then
          begin
            unqryDevolucionesCompraLineas.Edit;
            unqryDevolucionesCompraLineas.FieldByName(
              'NUM_ATRIBUTOS_DEVCLIN').AsInteger := Length(Partes) - 1;
            for i := 1 to 5 do
            begin
              if i < Length(Partes) then
                unqryDevolucionesCompraLineas.FieldByName('ATTR' +
                  IntToStr(i) + '_VALOR_DEVCLIN').AsString := Partes[i]
              else
                unqryDevolucionesCompraLineas.FieldByName('ATTR' +
                  IntToStr(i) + '_VALOR_DEVCLIN').AsString := '';
            end;
            unqryDevolucionesCompraLineas.Post;
          end;
        end;
        unqryDevolucionesCompraLineas.Next;
      end;
      if unqryDevolucionesCompraLineas.BookmarkValid(Bm) then
        unqryDevolucionesCompraLineas.GotoBookmark(Bm);
    finally
      FDesempaquetandoAtributos := False;
      unqryDevolucionesCompraLineas.EnableControls;
      unqryDevolucionesCompraLineas.FreeBookmark(Bm);
    end;
  end;
end;

initialization
  RegistrarDataModule(TdmDevolucionesCompra);
end.
