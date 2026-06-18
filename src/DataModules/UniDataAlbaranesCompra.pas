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
{    de venta). Sin generacion de movimientos de stock ni de factura           }
{    en esta version inicial: se anadiran en hitos posteriores.                }
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
    unqryArtDataLinAlbc:        TUniQuery;
    unqrySkusAlbc:              TUniQuery;
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
    procedure unqryAlbaranesCompraLineasAfterInsert(DataSet: TDataSet);
    procedure unqryAlbaranesCompraLineasBeforePost(DataSet: TDataSet);
    procedure unqryAlbaranesCompraLineasAfterPost(DataSet: TDataSet);
  private
    // Transicion de estado detectada en BeforePost. La aplicamos en
    // AfterPost para que la cabecera ya este guardada en BBDD cuando
    // generamos/revertimos los movimientos. Valores: 'CERRAR' (mov.
    // entrada nueva), 'ABRIR' (revertir mov. existentes) o ''.
    FTransicionEstadoAlbc: string;
    function ObtenerSkusAlbaranCsv(const ASerie, ANumero: string): string;
  public
    procedure GetCodigoAutoAlbaranCompra;
    procedure CalcularTotalesAlbaranCompra;
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
  System.Diagnostics,
  inMtoAlbaranesCompra,
  inLibAlbaranesCompraMovimientos,
  inLibComprasImpuestos;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmAlbaranesCompra.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection                := inLibGlobalVar.oConn;
  unqryAlbaranesCompraLineas.Connection := inLibGlobalVar.oConn;
  unqryEmpDataAlbc.Connection           := inLibGlobalVar.oConn;
  unqryPrvDataAlbc.Connection           := inLibGlobalVar.oConn;
  unqryArtDataLinAlbc.Connection        := inLibGlobalVar.oConn;
  unqrySkusAlbc.Connection              := inLibGlobalVar.oConn;
  unstrdprcGetContadorAlbc.Connection   := inLibGlobalVar.oConn;
  unqryDefArticuloAlbc.Connection       := inLibGlobalVar.oConn;
  // Master-detail server-side: el WHERE del SQL toma los valores de
  // dsTablaG (master), evitando descargar fza_albaranes_compra_lineas
  // entera y filtrar en cliente.
  unqryAlbaranesCompraLineas.MasterSource :=
    (GetOwnerForm<TfrmMtoAlbaranesCompra>).dsTablaG;
end;

procedure TdmAlbaranesCompra.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(unqryAlbaranesCompraLineas) and
     unqryAlbaranesCompraLineas.Active then
    unqryAlbaranesCompraLineas.Close;
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
    // Por defecto el albaran NO es deposito; se marca a mano en
    // cabecera. FindField: tolera BBDD sin la migracion aplicada
    // (albaran_compra_deposito.sql).
    if FindField('ESDEPOSITO_ALBC') <> nil then
      FieldByName('ESDEPOSITO_ALBC').AsString := 'N';
    AplicarRecargoComprasEmpresa(inLibGlobalVar.oConn, unqryTablaG,
      'CODIGO_EMP_ALBC', 'ESIVA_RECARGO_COMPRAS_ALBC');
  end;
  FTransicionEstadoAlbc := '';
end;

procedure TdmAlbaranesCompra.unqryTablaGBeforePost(DataSet: TDataSet);
var
  fEstado: TField;
  sEstadoNuevo, sEstadoAnterior: string;
  qChk: TUniQuery;
begin
  inherited;
  if (unqryTablaG.FieldByName('NUMERO_ALBC').AsString = '0') or
     (unqryTablaG.FieldByName('NUMERO_ALBC').AsString = '') then
    GetCodigoAutoAlbaranCompra;
  CalcularTotalesAlbaranCompra;
  // Deteccion de transicion de ESTADO_ALBC. Solo aplica en modo Edit
  // (en Insert el albaran nace ABIERTO y los movimientos los genera
  // MaterializarSesion o un Edit posterior). Comparamos OldValue vs
  // valor actual; UniDAC garantiza que OldValue refleja el snapshot
  // previo al Edit. Guardamos la transicion para aplicarla en
  // AfterPost cuando la cabecera ya este persistida.
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

// Tras persistir la cabecera, aplicamos la transicion de estado
// detectada en BeforePost: generar movimientos al cerrar o revertir
// los movimientos al reabrir. Cualquier excepcion se propaga al
// usuario (el Post original ya quedo aplicado, por lo que el albaran
// guardara su nuevo estado aunque los movimientos fallen — el usuario
// debe revisar y reintentar o revertir manualmente).
procedure TdmAlbaranesCompra.unqryTablaGAfterPost(DataSet: TDataSet);
var
  sSerie, sNumero: string;
begin
  inherited;
  if FTransicionEstadoAlbc = '' then
    Exit;
  sSerie  := unqryTablaG.FieldByName('SERIE_ALBC').AsString;
  sNumero := unqryTablaG.FieldByName('NUMERO_ALBC').AsString;
  try
    if FTransicionEstadoAlbc = 'CERRAR' then
      inLibAlbaranesCompraMovimientos.GenerarMovimientosDesdeAlbaranCompra(
        inLibGlobalVar.oConn, sSerie, sNumero, oUser)
    else if FTransicionEstadoAlbc = 'ABRIR' then
      inLibAlbaranesCompraMovimientos.RevertirMovimientosDesdeAlbaranCompra(
        inLibGlobalVar.oConn, sSerie, sNumero, oUser);
  finally
    FTransicionEstadoAlbc := '';
  end;
end;

procedure TdmAlbaranesCompra.unqryAlbaranesCompraLineasAfterInsert(
                                                       DataSet: TDataSet);
var
  iNuevaLinea : Integer;
  sSerie      : string;
  sNumero     : string;
begin
  inherited;
  // Asignacion de LINEA_ALBCLIN (clave secundaria, NOT NULL sin default).
  // Sin esto el Post fallaba con 'Field LINEA_ALBCLIN must have a value',
  // incluso en el alta involuntaria que dispara el grid al navegar con
  // flechas (OptionsData.Appending). Mismo patron que Sesiones de compra:
  // el helper hace un UPDATE atomico de CONTADOR_LINEAS_ALBC +10 sobre la
  // cabecera y devuelve el nuevo valor. Formato '0010','0020',... (4
  // digitos LPAD) para casar con las lineas materializadas y respetar el
  // ORDER BY LINEA_ALBCLIN (comparacion de texto).
  sSerie  := unqryTablaG.FieldByName('SERIE_ALBC').AsString;
  sNumero := unqryTablaG.FieldByName('NUMERO_ALBC').AsString;
  iNuevaLinea := GetSiguienteLineaDoc(CONT_ALBARANES_COMPRA, sSerie, sNumero);
  if iNuevaLinea = 0 then
  begin
    // Cabecera aun no persistida (albaran nuevo sin NUMERO real): fallback
    // al contador en memoria +10. Lo dejamos sincronizado para que la
    // siguiente linea incremente bien antes de grabar la cabecera.
    // StrToIntDef y no AsInteger: el contador es varchar NULL en alta y
    // AsInteger sobre '' lanzaria EConvertError.
    iNuevaLinea := StrToIntDef(
      unqryTablaG.FieldByName('CONTADOR_LINEAS_ALBC').AsString, 0) + 10;
    if not (unqryTablaG.State in [dsEdit, dsInsert]) then
      unqryTablaG.Edit;
    unqryTablaG.FieldByName('CONTADOR_LINEAS_ALBC').AsString :=
      Format('%.8d', [iNuevaLinea]);
  end;
  with unqryAlbaranesCompraLineas do
  begin
    FieldByName('NUMERO_ALBC_ALBCLIN').AsString :=
      unqryTablaG.FieldByName('NUMERO_ALBC').AsString;
    FieldByName('SERIE_ALBC_ALBCLIN').AsString :=
      unqryTablaG.FieldByName('SERIE_ALBC').AsString;
    FieldByName('LINEA_ALBCLIN').AsString := Format('%.4d', [iNuevaLinea]);
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
  with unqryAlbaranesCompraLineas do
  begin
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
  end;
end;

procedure TdmAlbaranesCompra.unqryAlbaranesCompraLineasAfterPost(
                                                       DataSet: TDataSet);
begin
  inherited;
  CalcularTotalesAlbaranCompra;
end;

procedure TdmAlbaranesCompra.GetCodigoAutoAlbaranCompra;
begin
  with unstrdprcGetContadorAlbc do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'pserie',            ptInput);
    Params.CreateParam(ftString, 'ptipodoc',          ptInput);
    Params.CreateParam(ftString, 'pcont',             ptOutput);
    Params.CreateParam(ftString, 'pEMPRESA_CONTADOR', ptInput);
    Params.CreateParam(ftString, 'pUSUARIOMODIF',     ptInput);
    ParamByName('pserie').AsString :=
      unqryTablaG.FieldByName('SERIE_ALBC').AsString;
    ParamByName('ptipodoc').AsString := 'AB';
    ParamByName('pUSUARIOMODIF').AsString := oUser;
    ParamByName('pEMPRESA_CONTADOR').AsString :=
      unqryTablaG.FieldByName('CODIGO_EMP_ALBC').AsString;
    ExecProc;
    unqryTablaG.FieldByName('NUMERO_ALBC').AsString :=
      ParamByName('pcont').AsString;
  end;
end;

procedure TdmAlbaranesCompra.CalcularTotalesAlbaranCompra;
begin
  CalcularTotalesDocumentoCompra(inLibGlobalVar.oConn, unqryTablaG,
    unqryAlbaranesCompraLineas, 'ALBC', 'TOTAL_ALBCLIN',
    'TIPO_IVA_ARTICULO_ALBCLIN', 'PORCENTAJE_IVA_ALBCLIN');
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
