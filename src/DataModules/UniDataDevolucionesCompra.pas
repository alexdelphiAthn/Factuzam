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
{    proveedor y precio de compra, pero al CERRAR la cabecera                  }
{    (ABIERTO -> CERRADO) genera movimientos de SALIDA via                     }
{    inLibDevolucionesCompraMovimientos (la cantidad va en positivo en el      }
{    documento y RESTA del stock). Codigo de tipo de documento 'DC'.           }
{******************************************************************************}
unit UniDataDevolucionesCompra;

interface

uses
  System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Vcl.ComCtrls, cxListView,
  Data.DB, MemDS, DBAccess, Uni,
  frxClass, frxDBSet,
  UniDataGen, UniDataArticulos, inLibUser, inMtoPrincipal;

type
  TdmDevolucionesCompra = class(TdmBase)
    unqryDevolucionesCompraLineas: TUniQuery;
    dsDevolucionesCompraLineas:    TDataSource;
    unqryEmpDataDevc:           TUniQuery;
    unqryPrvDataDevc:           TUniQuery;
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
    procedure unqryDevolucionesCompraLineasAfterInsert(DataSet: TDataSet);
    procedure unqryDevolucionesCompraLineasBeforePost(DataSet: TDataSet);
    procedure unqryDevolucionesCompraLineasAfterPost(DataSet: TDataSet);
  private
    // Transicion de estado detectada en BeforePost. La aplicamos en
    // AfterPost para que la cabecera ya este guardada en BBDD cuando
    // generamos/revertimos los movimientos. Valores: 'CERRAR' (mov.
    // salida nueva), 'ABRIR' (revertir mov. existentes) o ''.
    FTransicionEstadoDevc: string;
    function CampoVistaCabeceraPrintExiste(const ACampo: string): Boolean;
    procedure PrepararSQLCabeceraPrint;
    function ObtenerSkusDevolucionCsv(const ASerie, ANumero: string): string;
    function SiguienteLineaDevolucionCompra(const ASerie,
              ANumero: string): Integer;
    procedure ValidarAlmacenSalida;
  public
    procedure GetCodigoAutoDevolucionCompra;
    procedure CalcularTotalesDevolucionCompra;
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
    procedure AbrirDetalles; override;
  end;

implementation

uses
  inLibGlobalVar, inLibAppParam, inLibLog, inLibtb,
  System.Diagnostics,
  inMtoDevolucionesCompra,
  inLibDevolucionesCompraMovimientos,
  inLibComprasImpuestos;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmDevolucionesCompra.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection                := inLibGlobalVar.oConn;
  unqryDevolucionesCompraLineas.Connection := inLibGlobalVar.oConn;
  unqryDevolucionesCompraLineas.KeyFields :=
    'SERIE_DEVC_DEVCLIN;NUMERO_DEVC_DEVCLIN;LINEA_DEVCLIN';
  unqryDevolucionesCompraLineas.SQLDelete.Text :=
    'DELETE FROM fza_devoluciones_compra_lineas ' +
    ' WHERE SERIE_DEVC_DEVCLIN = :Old_SERIE_DEVC_DEVCLIN ' +
    '   AND NUMERO_DEVC_DEVCLIN = :Old_NUMERO_DEVC_DEVCLIN ' +
    '   AND LINEA_DEVCLIN = :Old_LINEA_DEVCLIN';
  unqryEmpDataDevc.Connection           := inLibGlobalVar.oConn;
  unqryPrvDataDevc.Connection           := inLibGlobalVar.oConn;
  unqryArtDataLinDevc.Connection        := inLibGlobalVar.oConn;
  unqrySkusDevc.Connection              := inLibGlobalVar.oConn;
  unqryAlmacenesDevc.Connection         := inLibGlobalVar.oConn;
  unqryMovimientosProveedor.Connection  := inLibGlobalVar.oConn;
  unstrdprcGetContadorDevc.Connection   := inLibGlobalVar.oConn;
  unqryDefArticuloDevc.Connection       := inLibGlobalVar.oConn;
  // Master-detail server-side: el WHERE del SQL toma los valores de
  // dsTablaG (master), evitando descargar fza_devoluciones_compra_lineas
  // entera y filtrar en cliente.
  unqryDevolucionesCompraLineas.MasterSource :=
    (GetOwnerForm<TfrmMtoDevolucionesCompra>).dsTablaG;
  unqryMovimientosProveedor.MasterSource :=
    (GetOwnerForm<TfrmMtoDevolucionesCompra>).dsTablaG;
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
  RefrescarAlmacenes(oEmpresa);
  AbrirConTiempo(unqryDevolucionesCompraLineas,
                 'unqryDevolucionesCompraLineas');
  AbrirConTiempo(unqryMovimientosProveedor,
                 'unqryMovimientosProveedor');
  inLibLog.Log.LogPerf(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmDevolucionesCompra.RefrescarAlmacenes(
                                                const ACodigoEmpresa: string);
var
  sEmpresa: string;
begin
  sEmpresa := Trim(ACodigoEmpresa);
  if sEmpresa = '' then
    sEmpresa := Trim(oEmpresa);
  if unqryAlmacenesDevc.Active and
     (unqryAlmacenesDevc.ParamByName('EMPRESA').AsString = sEmpresa) then
    Exit;
  unqryAlmacenesDevc.Close;
  unqryAlmacenesDevc.ParamByName('EMPRESA').AsString := sEmpresa;
  unqryAlmacenesDevc.Open;
end;

procedure TdmDevolucionesCompra.ValidarAlmacenSalida;
begin
  if Trim(unqryTablaG.FieldByName('CODIGO_ALM_DEVC').AsString) = '' then
    raise Exception.Create(
      'Debe seleccionar el almacen de salida de la devolucion.');
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
    sSerie := ObtenerSerieDefecto(oEmpresa, 'DC');
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
    if Trim(oEmpresa) <> '' then
      FieldByName('CODIGO_EMP_DEVC').AsString := oEmpresa
    else
      FieldByName('CODIGO_EMP_DEVC').AsString := '0';
    FieldByName('CODIGO_PRV_DEVC').AsString := '0';
    if FindField('ESPIVOTE_HORIZONTAL_DEVC') <> nil then
      FieldByName('ESPIVOTE_HORIZONTAL_DEVC').AsString := 'S';
    AplicarRecargoComprasEmpresa(inLibGlobalVar.oConn, unqryTablaG,
      'CODIGO_EMP_DEVC', 'ESIVA_RECARGO_COMPRAS_DEVC');
    AplicarPorcentajesIvaCompra(inLibGlobalVar.oConn, unqryTablaG,
      'DEVC');
  end;
  FTransicionEstadoDevc := '';
end;

procedure TdmDevolucionesCompra.unqryTablaGBeforePost(DataSet: TDataSet);
var
  fEstado: TField;
  sEstadoNuevo, sEstadoAnterior: string;
  qChk: TUniQuery;
begin
  inherited;
  ValidarAlmacenSalida;
  if (unqryTablaG.FieldByName('NUMERO_DEVC').AsString = '0') or
     (unqryTablaG.FieldByName('NUMERO_DEVC').AsString = '') then
    GetCodigoAutoDevolucionCompra;
  AplicarPorcentajesIvaCompra(inLibGlobalVar.oConn, unqryTablaG,
    'DEVC');
  CalcularTotalesDevolucionCompra;
  // Deteccion de transicion de ESTADO_DEVC. Solo aplica en modo Edit
  // (en Insert la devolucion nace ABIERTA y los movimientos los genera
  // un Edit posterior). Comparamos OldValue vs
  // valor actual; UniDAC garantiza que OldValue refleja el snapshot
  // previo al Edit. Guardamos la transicion para aplicarla en
  // AfterPost cuando la cabecera ya este persistida.
  FTransicionEstadoDevc := '';
  if unqryTablaG.State <> dsEdit then
    Exit;
  fEstado := unqryTablaG.FindField('ESTADO_DEVC');
  if fEstado = nil then
    Exit;
  sEstadoNuevo    := UpperCase(Trim(fEstado.AsString));
  sEstadoAnterior := UpperCase(Trim(VarToStr(fEstado.OldValue)));
  if sEstadoNuevo = sEstadoAnterior then
    Exit;
  if (sEstadoAnterior = 'ABIERTO') and (sEstadoNuevo = 'CERRADO') then
    FTransicionEstadoDevc := 'CERRAR'
  else if (sEstadoAnterior = 'CERRADO') and (sEstadoNuevo = 'ABIERTO') then
    FTransicionEstadoDevc := 'ABRIR';
  // Pre-validacion del cierre: si vamos a cerrar y no hay lineas con
  // cantidad > 0, abortamos el Post para no dejar la devolucion CERRADA
  // sin movimientos. Mejor abortar aqui que en AfterPost (donde la
  // cabecera ya estaria persistida con el estado nuevo).
  if FTransicionEstadoDevc = 'CERRAR' then
  begin
    qChk := TUniQuery.Create(nil);
    try
      qChk.Connection := inLibGlobalVar.oConn;
      qChk.SQL.Text :=
        'SELECT COUNT(*) AS N FROM fza_devoluciones_compra_lineas ' +
        ' WHERE SERIE_DEVC_DEVCLIN  = :s ' +
        '   AND NUMERO_DEVC_DEVCLIN = :n ' +
        '   AND IFNULL(CANTIDAD_DEVCLIN, 0) > 0';
      qChk.ParamByName('s').AsString :=
        unqryTablaG.FieldByName('SERIE_DEVC').AsString;
      qChk.ParamByName('n').AsString :=
        unqryTablaG.FieldByName('NUMERO_DEVC').AsString;
      qChk.Open;
      if qChk.FieldByName('N').AsInteger = 0 then
        raise Exception.Create(
          'No se puede cerrar la devolucion: no tiene lineas con cantidad ' +
          'mayor que 0. Añade lineas antes de cerrar.');
    finally
      FreeAndNil(qChk);
    end;
  end;
end;

// Tras persistir la cabecera, aplicamos la transicion de estado
// detectada en BeforePost: generar movimientos al cerrar o revertir
// los movimientos al reabrir. Cualquier excepcion se propaga al
// usuario (el Post original ya quedo aplicado, por lo que la devolucion
// guardara su nuevo estado aunque los movimientos fallen — el usuario
// debe revisar y reintentar o revertir manualmente).
procedure TdmDevolucionesCompra.unqryTablaGAfterPost(DataSet: TDataSet);
var
  sSerie, sNumero: string;
begin
  inherited;
  if FTransicionEstadoDevc = '' then
    Exit;
  sSerie  := unqryTablaG.FieldByName('SERIE_DEVC').AsString;
  sNumero := unqryTablaG.FieldByName('NUMERO_DEVC').AsString;
  try
    if FTransicionEstadoDevc = 'CERRAR' then
      inLibDevolucionesCompraMovimientos.GenerarMovimientosDesdeDevolucionCompra(
        inLibGlobalVar.oConn, sSerie, sNumero, oUser)
    else if FTransicionEstadoDevc = 'ABRIR' then
      inLibDevolucionesCompraMovimientos.RevertirMovimientosDesdeDevolucionCompra(
        inLibGlobalVar.oConn, sSerie, sNumero, oUser);
  finally
    FTransicionEstadoDevc := '';
  end;
  if unqryMovimientosProveedor.Active then
  begin
    unqryMovimientosProveedor.Close;
    unqryMovimientosProveedor.Open;
  end;
end;

function TdmDevolucionesCompra.SiguienteLineaDevolucionCompra(
  const ASerie, ANumero: string): Integer;
var
  qry: TUniQuery;
begin
  Result := 10;
  if (Trim(ASerie) <> '') and (Trim(ANumero) <> '') then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := inLibGlobalVar.oConn;
      qry.SQL.Text :=
        'SELECT COALESCE(MAX(CAST(NULLIF(LINEA_DEVCLIN, '''') ' +
        '       AS UNSIGNED)), 0) + 10 AS NV ' +
        '  FROM fza_devoluciones_compra_lineas ' +
        ' WHERE SERIE_DEVC_DEVCLIN = :serie ' +
        '   AND NUMERO_DEVC_DEVCLIN = :numero';
      qry.ParamByName('serie').AsString := ASerie;
      qry.ParamByName('numero').AsString := ANumero;
      qry.Open;
      if not qry.IsEmpty then
        Result := qry.FieldByName('NV').AsInteger;
    finally
      FreeAndNil(qry);
    end;
  end;
  if Result <= 0 then
    Result := 10;
end;

procedure TdmDevolucionesCompra.unqryDevolucionesCompraLineasAfterInsert(
                                                       DataSet: TDataSet);
var
  iNuevaLinea : Integer;
  sSerie      : string;
  sNumero     : string;
begin
  inherited;
  // Asignacion de LINEA_DEVCLIN (clave secundaria, NOT NULL sin default).
  // Sin esto el Post fallaba con 'Field LINEA_DEVCLIN must have a value',
  // incluso en el alta involuntaria que dispara el grid al navegar con
  // flechas (OptionsData.Appending). En devoluciones se toma el ultimo
  // LINEA_DEVCLIN grabado del documento y se suma 10.
  sSerie  := unqryTablaG.FieldByName('SERIE_DEVC').AsString;
  sNumero := unqryTablaG.FieldByName('NUMERO_DEVC').AsString;
  iNuevaLinea := SiguienteLineaDevolucionCompra(sSerie, sNumero);
  with unqryDevolucionesCompraLineas do
  begin
    FieldByName('NUMERO_DEVC_DEVCLIN').AsString :=
      unqryTablaG.FieldByName('NUMERO_DEVC').AsString;
    FieldByName('SERIE_DEVC_DEVCLIN').AsString :=
      unqryTablaG.FieldByName('SERIE_DEVC').AsString;
    FieldByName('LINEA_DEVCLIN').AsString := Format('%.4d', [iNuevaLinea]);
    FieldByName('CANTIDAD_DEVCLIN').AsFloat := 1;
    if FindField('ESFACTURADA_DEVCLIN') <> nil then
      FieldByName('ESFACTURADA_DEVCLIN').AsString := 'N';
    // Auditoria estandar: las 4 columnas del libro de estilo bbdd §3.7
    // son NOT NULL sin default; hay que rellenarlas en alta. En BeforePost
    // tambien sobrescribimos USUARIO_MODIF para que refleje la ultima edicion.
    FieldByName('USUARIO_ALTA').AsString    := oUser;
    FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    FieldByName('USUARIO_MODIF').AsString   := oUser;
    FieldByName('INSTANTE_MODIF').AsDateTime:= Now;
  end;
end;

procedure TdmDevolucionesCompra.unqryDevolucionesCompraLineasBeforePost(
                                                       DataSet: TDataSet);
var
  sSku, sArt: string;
begin
  inherited;
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
  with unqryDevolucionesCompraLineas do
  begin
    if (Trim(FieldByName('NUMERO_DEVC_DEVCLIN').AsString) = '') or
       (Trim(FieldByName('NUMERO_DEVC_DEVCLIN').AsString) = '0') then
      raise Exception.Create(
        'Graba la cabecera de la devolucion antes de guardar lineas.');
    if (FindField('CANTIDAD_DEVCLIN') <> nil) and
       (FindField('PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN') <> nil) and
       (FindField('TOTAL_DEVCLIN') <> nil) then
      FieldByName('TOTAL_DEVCLIN').AsFloat :=
        FieldByName('CANTIDAD_DEVCLIN').AsFloat *
        FieldByName('PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN').AsFloat;
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
    PrepararLineaFiscalCompra(inLibGlobalVar.oConn, unqryTablaG,
      unqryDevolucionesCompraLineas, 'DEVC', 'DEVCLIN', 'TOTAL_DEVCLIN');
  end;
end;

procedure TdmDevolucionesCompra.unqryDevolucionesCompraLineasAfterPost(
                                                       DataSet: TDataSet);
begin
  inherited;
  CalcularTotalesDevolucionCompra;
end;

procedure TdmDevolucionesCompra.GetCodigoAutoDevolucionCompra;
begin
  with unstrdprcGetContadorDevc do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'pserie',            ptInput);
    Params.CreateParam(ftString, 'ptipodoc',          ptInput);
    Params.CreateParam(ftString, 'pcont',             ptOutput);
    Params.CreateParam(ftString, 'pEMPRESA_CONTADOR', ptInput);
    Params.CreateParam(ftString, 'pUSUARIOMODIF',     ptInput);
    ParamByName('pserie').AsString :=
      unqryTablaG.FieldByName('SERIE_DEVC').AsString;
    ParamByName('ptipodoc').AsString := 'DC';
    ParamByName('pUSUARIOMODIF').AsString := oUser;
    ParamByName('pEMPRESA_CONTADOR').AsString :=
      unqryTablaG.FieldByName('CODIGO_EMP_DEVC').AsString;
    ExecProc;
    unqryTablaG.FieldByName('NUMERO_DEVC').AsString :=
      ParamByName('pcont').AsString;
  end;
end;

procedure TdmDevolucionesCompra.CalcularTotalesDevolucionCompra;
begin
  CalcularTotalesDocumentoCompra(inLibGlobalVar.oConn, unqryTablaG,
    unqryDevolucionesCompraLineas, 'DEVC', 'TOTAL_DEVCLIN',
    'TIPO_IVA_ARTICULO_DEVCLIN', 'PORCENTAJE_IVA_DEVCLIN');
end;

function TdmDevolucionesCompra.CampoVistaCabeceraPrintExiste(
  const ACampo: string): Boolean;
var
  q: TUniQuery;
begin
  Result := False;
  q := TUniQuery.Create(nil);
  try
    q.Connection := inLibGlobalVar.oConn;
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
      oQry.Connection := inLibGlobalVar.oConn;
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
    oQry.Connection := inLibGlobalVar.oConn;
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

end.
