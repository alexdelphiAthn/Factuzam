{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturasCompra                                        }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de FACTURAS DE COMPRA (facturas de compra).         }
{    Espejo de UniDataAlbaranesCompra: misma cabecera + lineas sobre           }
{    proveedor y precio de compra, pero al CERRAR la cabecera                  }
{    (ABIERTA -> CERRADA) genera movimientos de SALIDA via                     }
{    inLibFacturasCompraMovimientos (la cantidad va en positivo en el      }
{    documento y RESTA del stock). Codigo de tipo de documento 'FP'.           }
{******************************************************************************}
unit UniDataFacturasCompra;

interface

uses
  System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Vcl.ComCtrls, cxListView,
  Data.DB, MemDS, DBAccess, Uni,
  frxClass, frxDBSet,
  UniDataGen, UniDataArticulos, inLibUser, inMtoPrincipal;

type
  TdmFacturasCompra = class(TdmBase)
    unqryFacturasCompraLineas: TUniQuery;
    dsFacturasCompraLineas:    TDataSource;
    unqryEfectos:              TUniQuery;
    dsEfectos:                 TDataSource;
    unqryEmpDataFacc:           TUniQuery;
    unqryPrvDataFacc:           TUniQuery;
    unqryArtDataLinFacc:        TUniQuery;
    unqrySkusFacc:              TUniQuery;
    unstrdprcGetContadorFacc:   TUniStoredProc;
    // Definicion de atributos del articulo padre (para columnas
    // dinamicas ATTR1..ATTR5 en modo "atributo por columna").
    unqryDefArticuloFacc:       TUniQuery;
    // Datasets para impresion del factura via FastReport. Mismo patron
    // que TdmComprasSesiones (unqry*Print -> ds*Print -> fxds*). El
    // .fr3 embebido en el modal inMtoModalImpFacCompra.dfm los
    // referencia por UserName ('Factura', 'LineasFactura').
    unqryCabFaccPrint:          TUniQuery;
    dsCabFaccPrint:             TDataSource;
    fxdsCabFacc:                TfrxDBDataset;
    unqryLinFaccPrint:          TUniQuery;
    dsLinFaccPrint:             TDataSource;
    fxdsLinFacc:                TfrxDBDataset;
    unqryGuiasFaccPrint:        TUniQuery;
    dsGuiasFaccPrint:           TDataSource;
    fxdsGuiasFacc:              TfrxDBDataset;
    // Lineas "planas" (una fila por SKU sin pivotar por talla) para el
    // formato vertical estilo factura.
    unqryLinFaccSkuPrint:       TUniQuery;
    dsLinFaccSkuPrint:          TDataSource;
    fxdsLinFaccSku:             TfrxDBDataset;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryFacturasCompraLineasAfterInsert(DataSet: TDataSet);
    procedure unqryFacturasCompraLineasBeforePost(DataSet: TDataSet);
    procedure unqryFacturasCompraLineasAfterPost(DataSet: TDataSet);
  private
    // Transicion de estado detectada en BeforePost. La aplicamos en
    // AfterPost para que la cabecera ya este guardada en BBDD cuando
    // generamos/revertimos los movimientos. Valores: 'CERRAR' (mov.
    // salida nueva), 'ABRIR' (revertir mov. existentes) o ''.
    FTransicionEstadoFacc: string;
    function ObtenerSkusFacturaCsv(const ASerie, ANumero: string): string;
  public
    procedure GetCodigoAutoFacturaCompra;
    procedure CalcularTotalesFacturaCompra;
    // Genera los efectos de pago de la factura activa segun su forma de pago
    // (PRC_EFEC_GENERAR_DESDE_FACTURA) y refresca la rejilla. Devuelve nº de
    // efectos generados, 0 si nada, -1 sin factura activa / error.
    function GenerarEfectos: Integer;
    // Registra un pago sobre un efecto (PRC_EFEC_REGISTRAR_PAGO) y refresca
    // la rejilla. Devuelve el nº de pago asignado (>0) o 0/-1 si no se pudo.
    function RegistrarPagoEfecto(ANumEfecto: Integer; AFecha: TDateTime;
      AImporte: Double; const ATipo, AReferencia: string): Integer;
    // Abre unqryCabFaccPrint y unqryLinFaccPrint con los parametros
    // del factura a imprimir. Mismo nombre/firma que en sesiones.
    procedure PrepararPrint(const ASerie, ANumero: string);
    // Version SKU (lineas planas, sin pivote talla) para el modal
    // vertical estilo factura.
    procedure PrepararPrintSku(const ASerie, ANumero: string);
    // Carga en el listview los almacenes distintos que aparecen en las
    // lineas del factura (usado por el modal de pegatinas).
    procedure CargarAlmacenesDelFactura(const ASerie, ANumero: string;
                                         ALV: TObject);
    // Crea el dataset cdsEtiquetasArt del DM articulos filtrado a los
    // SKUs del factura. Reutiliza la query base de etiquetas anyadiendo
    // un WHERE por SKU IN (SELECT ... FROM facturas_compra_lineas).
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
  inMtoFacturasCompra,
  inLibComprasImpuestos;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmFacturasCompra.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection                := inLibGlobalVar.oConn;
  unqryFacturasCompraLineas.Connection := inLibGlobalVar.oConn;
  unqryEmpDataFacc.Connection           := inLibGlobalVar.oConn;
  unqryPrvDataFacc.Connection           := inLibGlobalVar.oConn;
  unqryArtDataLinFacc.Connection        := inLibGlobalVar.oConn;
  unqrySkusFacc.Connection              := inLibGlobalVar.oConn;
  unstrdprcGetContadorFacc.Connection   := inLibGlobalVar.oConn;
  unqryDefArticuloFacc.Connection       := inLibGlobalVar.oConn;
  // Master-detail server-side: el WHERE del SQL toma los valores de
  // dsTablaG (master), evitando descargar fza_facturas_compra_lineas
  // entera y filtrar en cliente.
  unqryFacturasCompraLineas.MasterSource :=
    (GetOwnerForm<TfrmMtoFacturasCompra>).dsTablaG;
  unqryEfectos.Connection := inLibGlobalVar.oConn;
  unqryEfectos.MasterSource :=
    (GetOwnerForm<TfrmMtoFacturasCompra>).dsTablaG;
end;

procedure TdmFacturasCompra.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(unqryFacturasCompraLineas) and
     unqryFacturasCompraLineas.Active then
    unqryFacturasCompraLineas.Close;
  inherited;
end;

procedure TdmFacturasCompra.OpenTables;
begin
  // Delegamos en AbrirDetalles para unificar logging y cronometro.
  AbrirDetalles;
end;

procedure TdmFacturasCompra.AbrirDetalles;
const
  TAG = 'FacturasCompra.AbrirDetalles';

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
  AbrirConTiempo(unqryFacturasCompraLineas,
                 'unqryFacturasCompraLineas');
  AbrirConTiempo(unqryEfectos, 'unqryEfectos');
  inLibLog.Log.LogPerf(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

function TdmFacturasCompra.GenerarEfectos: Integer;
var
  sp: TUniStoredProc;
  sSerie, sNumero: string;
begin
  Result := -1;
  if (unqryTablaG <> nil) and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
  begin
    // El SP lee de BBDD: aseguramos la cabecera grabada antes de generar.
    if unqryTablaG.State in [dsEdit, dsInsert] then
    begin
      CalcularTotalesFacturaCompra;
      unqryTablaG.Post;
    end;
    sSerie  := unqryTablaG.FieldByName('SERIE_FACC').AsString;
    sNumero := unqryTablaG.FieldByName('NUMERO_FACC').AsString;
    sp := TUniStoredProc.Create(nil);
    try
      sp.Connection     := inLibGlobalVar.oConn;
      sp.StoredProcName := 'PRC_EFEC_GENERAR_DESDE_FACTURA';
      sp.Params.Clear;
      sp.Params.CreateParam(ftString,  'p_SERIE',     ptInput);
      sp.Params.CreateParam(ftString,  'p_NUMERO',    ptInput);
      sp.Params.CreateParam(ftString,  'p_USUARIO',   ptInput);
      sp.Params.CreateParam(ftInteger, 'p_RESULTADO', ptOutput);
      sp.ParamByName('p_SERIE').AsString   := sSerie;
      sp.ParamByName('p_NUMERO').AsString  := sNumero;
      sp.ParamByName('p_USUARIO').AsString := oUser;
      sp.ExecProc;
      Result := sp.ParamByName('p_RESULTADO').AsInteger;
    finally
      FreeAndNil(sp);
    end;
    // Refrescar la rejilla de efectos.
    if Assigned(unqryEfectos) then
    begin
      unqryEfectos.Close;
      unqryEfectos.Open;
    end;
  end;
end;

function TdmFacturasCompra.RegistrarPagoEfecto(ANumEfecto: Integer;
  AFecha: TDateTime; AImporte: Double;
  const ATipo, AReferencia: string): Integer;
var
  sp: TUniStoredProc;
  sSerie, sNumero: string;
begin
  Result := -1;
  if (unqryTablaG <> nil) and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
  begin
    sSerie  := unqryTablaG.FieldByName('SERIE_FACC').AsString;
    sNumero := unqryTablaG.FieldByName('NUMERO_FACC').AsString;
    sp := TUniStoredProc.Create(nil);
    try
      sp.Connection     := inLibGlobalVar.oConn;
      sp.StoredProcName := 'PRC_EFEC_REGISTRAR_PAGO';
      sp.Params.Clear;
      sp.Params.CreateParam(ftString,  'p_SERIE',      ptInput);
      sp.Params.CreateParam(ftString,  'p_NUMERO',     ptInput);
      sp.Params.CreateParam(ftInteger, 'p_NUM_EFEC',   ptInput);
      sp.Params.CreateParam(ftDate,    'p_FECHA',      ptInput);
      sp.Params.CreateParam(ftFloat,   'p_IMPORTE',    ptInput);
      sp.Params.CreateParam(ftString,  'p_TIPO',       ptInput);
      sp.Params.CreateParam(ftString,  'p_REFERENCIA', ptInput);
      sp.Params.CreateParam(ftString,  'p_ENTIDAD',    ptInput);
      sp.Params.CreateParam(ftString,  'p_USUARIO',    ptInput);
      sp.Params.CreateParam(ftInteger, 'p_RESULTADO',  ptOutput);
      sp.ParamByName('p_SERIE').AsString      := sSerie;
      sp.ParamByName('p_NUMERO').AsString     := sNumero;
      sp.ParamByName('p_NUM_EFEC').AsInteger  := ANumEfecto;
      sp.ParamByName('p_FECHA').AsDateTime    := AFecha;
      sp.ParamByName('p_IMPORTE').AsFloat     := AImporte;
      sp.ParamByName('p_TIPO').AsString       := ATipo;
      sp.ParamByName('p_REFERENCIA').AsString := AReferencia;
      sp.ParamByName('p_ENTIDAD').AsString    := '';
      sp.ParamByName('p_USUARIO').AsString    := oUser;
      sp.ExecProc;
      Result := sp.ParamByName('p_RESULTADO').AsInteger;
    finally
      FreeAndNil(sp);
    end;
    if Assigned(unqryEfectos) then
    begin
      unqryEfectos.Close;
      unqryEfectos.Open;
    end;
  end;
end;

procedure TdmFacturasCompra.unqryTablaGAfterInsert(DataSet: TDataSet);
var
  sSerie: string;
begin
  inherited;
  with unqryTablaG do
  begin
    FieldByName('NUMERO_FACC').AsString := '0';
    // Serie por defecto: buscar en fza_empresas_series para TIPO_DOC='FP'
    sSerie := ObtenerSerieDefecto(oEmpresa, 'FP');
    if FindField('SERIE_FACC') <> nil then
    begin
      if sSerie <> '' then
        FieldByName('SERIE_FACC').AsString := sSerie
      else
        FieldByName('SERIE_FACC').AsString := 'C1';
    end;
    FieldByName('FECHA_FACC').AsDateTime := Date;
    if FindField('ESTADO_FACC') <> nil then
      FieldByName('ESTADO_FACC').AsString := 'ABIERTA';
    if Trim(oEmpresa) <> '' then
      FieldByName('CODIGO_EMP_FACC').AsString := oEmpresa
    else
      FieldByName('CODIGO_EMP_FACC').AsString := '0';
    FieldByName('CODIGO_PRV_FACC').AsString := '0';
    AplicarRecargoComprasEmpresa(inLibGlobalVar.oConn, unqryTablaG,
      'CODIGO_EMP_FACC', 'ESIVA_RECARGO_COMPRAS_FACC');
  end;
  FTransicionEstadoFacc := '';
end;

procedure TdmFacturasCompra.unqryTablaGBeforePost(DataSet: TDataSet);
var
  fEstado: TField;
  sEstadoNuevo, sEstadoAnterior: string;
  qChk: TUniQuery;
begin
  inherited;
  if (unqryTablaG.FieldByName('NUMERO_FACC').AsString = '0') or
     (unqryTablaG.FieldByName('NUMERO_FACC').AsString = '') then
    GetCodigoAutoFacturaCompra;
  CalcularTotalesFacturaCompra;
  // Deteccion de transicion de ESTADO_FACC. Solo aplica en modo Edit
  // (en Insert la factura nace ABIERTA y los movimientos los genera
  // un Edit posterior). Comparamos OldValue vs
  // valor actual; UniDAC garantiza que OldValue refleja el snapshot
  // previo al Edit. Guardamos la transicion para aplicarla en
  // AfterPost cuando la cabecera ya este persistida.
  FTransicionEstadoFacc := '';
  if unqryTablaG.State <> dsEdit then
    Exit;
  fEstado := unqryTablaG.FindField('ESTADO_FACC');
  if fEstado = nil then
    Exit;
  sEstadoNuevo    := UpperCase(Trim(fEstado.AsString));
  sEstadoAnterior := UpperCase(Trim(VarToStr(fEstado.OldValue)));
  if sEstadoNuevo = sEstadoAnterior then
    Exit;
  if (sEstadoAnterior = 'ABIERTA') and (sEstadoNuevo = 'CERRADA') then
    FTransicionEstadoFacc := 'CERRAR'
  else if (sEstadoAnterior = 'CERRADA') and (sEstadoNuevo = 'ABIERTA') then
    FTransicionEstadoFacc := 'ABRIR';
  // Pre-validacion del cierre: si vamos a cerrar y no hay lineas con
  // cantidad > 0, abortamos el Post para no dejar la factura CERRADA
  // sin movimientos. Mejor abortar aqui que en AfterPost (donde la
  // cabecera ya estaria persistida con el estado nuevo).
  if FTransicionEstadoFacc = 'CERRAR' then
  begin
    qChk := TUniQuery.Create(nil);
    try
      qChk.Connection := inLibGlobalVar.oConn;
      qChk.SQL.Text :=
        'SELECT COUNT(*) AS N FROM fza_facturas_compra_lineas ' +
        ' WHERE SERIE_FACC_FACCLIN  = :s ' +
        '   AND NUMERO_FACC_FACCLIN = :n ' +
        '   AND IFNULL(CANTIDAD_FACCLIN, 0) > 0';
      qChk.ParamByName('s').AsString :=
        unqryTablaG.FieldByName('SERIE_FACC').AsString;
      qChk.ParamByName('n').AsString :=
        unqryTablaG.FieldByName('NUMERO_FACC').AsString;
      qChk.Open;
      if qChk.FieldByName('N').AsInteger = 0 then
        raise Exception.Create(
          'No se puede cerrar la factura: no tiene lineas con cantidad ' +
          'mayor que 0. Añade lineas antes de cerrar.');
    finally
      FreeAndNil(qChk);
    end;
  end;
end;

// Tras persistir la cabecera, aplicamos la transicion de estado
// detectada en BeforePost: generar movimientos al cerrar o revertir
// los movimientos al reabrir. Cualquier excepcion se propaga al
// usuario (el Post original ya quedo aplicado, por lo que la factura
// guardara su nuevo estado aunque los movimientos fallen — el usuario
// debe revisar y reintentar o revertir manualmente).
procedure TdmFacturasCompra.unqryTablaGAfterPost(DataSet: TDataSet);
begin
  inherited;
  // La factura de compra NO mueve stock (lo hizo el albaran). El cambio de
  // estado solo refleja el ciclo administrativo de la factura.
  FTransicionEstadoFacc := '';
end;

procedure TdmFacturasCompra.unqryFacturasCompraLineasAfterInsert(
                                                       DataSet: TDataSet);
var
  iNuevaLinea : Integer;
  sSerie      : string;
  sNumero     : string;
begin
  inherited;
  // Asignacion de LINEA_FACCLIN (clave secundaria, NOT NULL sin default).
  // Sin esto el Post fallaba con 'Field LINEA_FACCLIN must have a value',
  // incluso en el alta involuntaria que dispara el grid al navegar con
  // flechas (OptionsData.Appending). Mismo patron que Sesiones de compra:
  // el helper hace un UPDATE atomico de CONTADOR_LINEAS_FACC +10 sobre la
  // cabecera y devuelve el nuevo valor. Formato '0010','0020',... (4
  // digitos LPAD) para casar con las lineas materializadas y respetar el
  // ORDER BY LINEA_FACCLIN (comparacion de texto).
  sSerie  := unqryTablaG.FieldByName('SERIE_FACC').AsString;
  sNumero := unqryTablaG.FieldByName('NUMERO_FACC').AsString;
  iNuevaLinea := GetSiguienteLineaDoc(CONT_FACTURAS_COMPRA, sSerie, sNumero);
  if iNuevaLinea = 0 then
  begin
    // Cabecera aun no persistida (factura nuevo sin NUMERO real): fallback
    // al contador en memoria +10. Lo dejamos sincronizado para que la
    // siguiente linea incremente bien antes de grabar la cabecera.
    // StrToIntDef y no AsInteger: el contador es varchar NULL en alta y
    // AsInteger sobre '' lanzaria EConvertError.
    iNuevaLinea := StrToIntDef(
      unqryTablaG.FieldByName('CONTADOR_LINEAS_FACC').AsString, 0) + 10;
    if not (unqryTablaG.State in [dsEdit, dsInsert]) then
      unqryTablaG.Edit;
    unqryTablaG.FieldByName('CONTADOR_LINEAS_FACC').AsString :=
      Format('%.8d', [iNuevaLinea]);
  end;
  with unqryFacturasCompraLineas do
  begin
    FieldByName('NUMERO_FACC_FACCLIN').AsString :=
      unqryTablaG.FieldByName('NUMERO_FACC').AsString;
    FieldByName('SERIE_FACC_FACCLIN').AsString :=
      unqryTablaG.FieldByName('SERIE_FACC').AsString;
    FieldByName('LINEA_FACCLIN').AsString := Format('%.4d', [iNuevaLinea]);
    FieldByName('CANTIDAD_FACCLIN').AsFloat := 1;
    if FindField('ESFACTURADA_FACCLIN') <> nil then
      FieldByName('ESFACTURADA_FACCLIN').AsString := 'N';
    // Auditoria estandar: las 4 columnas del libro de estilo bbdd §3.7
    // son NOT NULL sin default; hay que rellenarlas en alta. En BeforePost
    // tambien sobrescribimos USUARIO_MODIF para que refleje la ultima edicion.
    FieldByName('USUARIO_ALTA').AsString    := oUser;
    FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    FieldByName('USUARIO_MODIF').AsString   := oUser;
    FieldByName('INSTANTE_MODIF').AsDateTime:= Now;
  end;
end;

procedure TdmFacturasCompra.unqryFacturasCompraLineasBeforePost(
                                                       DataSet: TDataSet);
var
  sSku, sArt: string;
begin
  inherited;
  // Linea vacia (sin articulo ni SKU): cancelar silenciosamente. El cxGrid
  // hace Post automatico al navegar con flechas (OptionsData.Appending); si
  // la linea es un placeholder vacio que el usuario creo sin querer, el Post
  // fallaria con 'Field LINEA_FACCLIN must have a value'. Cancel diferido +
  // Abort la descarta sin molestar al usuario. Mismo patron que Sesiones.
  if (Trim(unqryFacturasCompraLineas.FieldByName(
             'CODIGO_ART_FACCLIN').AsString) = '') and
     (Trim(unqryFacturasCompraLineas.FieldByName(
             'CODIGO_UNIDAD_FACCLIN').AsString) = '') then
  begin
    TThread.ForceQueue(nil,
      procedure
      begin
        if unqryFacturasCompraLineas.Active and
           (unqryFacturasCompraLineas.State in [dsEdit, dsInsert]) then
          unqryFacturasCompraLineas.Cancel;
      end);
    Abort;
  end;
  with unqryFacturasCompraLineas do
  begin
    if (FindField('CANTIDAD_FACCLIN') <> nil) and
       (FindField('PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN') <> nil) and
       (FindField('TOTAL_FACCLIN') <> nil) then
      FieldByName('TOTAL_FACCLIN').AsFloat :=
        FieldByName('CANTIDAD_FACCLIN').AsFloat *
        FieldByName('PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN').AsFloat;
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
    if (FindField('CODIGO_UNIDAD_FACCLIN') <> nil) and
       (FindField('CODIGO_ART_FACCLIN') <> nil) then
    begin
      sSku := Trim(FieldByName('CODIGO_UNIDAD_FACCLIN').AsString);
      sArt := Trim(FieldByName('CODIGO_ART_FACCLIN').AsString);
      if (sSku <> '') and (sArt = '') then
      begin
        unqrySkusFacc.Close;
        unqrySkusFacc.ParamByName('pSKU').AsString := sSku;
        unqrySkusFacc.Open;
        if not unqrySkusFacc.Eof then
          FieldByName('CODIGO_ART_FACCLIN').AsString :=
            unqrySkusFacc.FieldByName('CODIGO_ART_SKU').AsString;
        unqrySkusFacc.Close;
      end;
    end;
  end;
end;

procedure TdmFacturasCompra.unqryFacturasCompraLineasAfterPost(
                                                       DataSet: TDataSet);
begin
  inherited;
  CalcularTotalesFacturaCompra;
end;

procedure TdmFacturasCompra.GetCodigoAutoFacturaCompra;
begin
  with unstrdprcGetContadorFacc do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'pserie',            ptInput);
    Params.CreateParam(ftString, 'ptipodoc',          ptInput);
    Params.CreateParam(ftString, 'pcont',             ptOutput);
    Params.CreateParam(ftString, 'pEMPRESA_CONTADOR', ptInput);
    Params.CreateParam(ftString, 'pUSUARIOMODIF',     ptInput);
    ParamByName('pserie').AsString :=
      unqryTablaG.FieldByName('SERIE_FACC').AsString;
    ParamByName('ptipodoc').AsString := 'FP';
    ParamByName('pUSUARIOMODIF').AsString := oUser;
    ParamByName('pEMPRESA_CONTADOR').AsString :=
      unqryTablaG.FieldByName('CODIGO_EMP_FACC').AsString;
    ExecProc;
    unqryTablaG.FieldByName('NUMERO_FACC').AsString :=
      ParamByName('pcont').AsString;
  end;
end;

procedure TdmFacturasCompra.CalcularTotalesFacturaCompra;
begin
  CalcularTotalesDocumentoCompra(inLibGlobalVar.oConn, unqryTablaG,
    unqryFacturasCompraLineas, 'FACC', 'TOTAL_FACCLIN',
    'TIPO_IVA_ARTICULO_FACCLIN', 'PORCENTAJE_IVA_FACCLIN');
end;

procedure TdmFacturasCompra.PrepararPrint(const ASerie, ANumero: string);
begin
  unqryCabFaccPrint.Close;
  unqryCabFaccPrint.ParamByName('SERIE_FACC').AsString  := ASerie;
  unqryCabFaccPrint.ParamByName('NUMERO_FACC').AsString := ANumero;
  unqryCabFaccPrint.Open;
  unqryLinFaccPrint.Close;
  unqryLinFaccPrint.ParamByName('SERIE_FACC').AsString  := ASerie;
  unqryLinFaccPrint.ParamByName('NUMERO_FACC').AsString := ANumero;
  unqryLinFaccPrint.Open;
  unqryGuiasFaccPrint.Close;
  unqryGuiasFaccPrint.ParamByName('SERIE_FACC').AsString  := ASerie;
  unqryGuiasFaccPrint.ParamByName('NUMERO_FACC').AsString := ANumero;
  unqryGuiasFaccPrint.Open;
end;

procedure TdmFacturasCompra.CargarAlmacenesDelFactura(
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
        'SELECT DISTINCT L.CODIGO_ALMACEN_FACCLIN AS COD, ' +
        '       COALESCE(A.NOMBRE_ALM_ALM, L.CODIGO_ALMACEN_FACCLIN) AS NOM ' +
        '  FROM fza_facturas_compra_lineas L ' +
        '  LEFT JOIN fza_almacenes A ON A.CODIGO_ALM_ALM = L.CODIGO_ALMACEN_FACCLIN ' +
        ' WHERE L.SERIE_FACC_FACCLIN = :s AND L.NUMERO_FACC_FACCLIN = :n ' +
        '   AND COALESCE(L.CODIGO_ALMACEN_FACCLIN, '''') <> '''' ' +
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

procedure TdmFacturasCompra.CrearDataSetEtiquetasAlb(ADmArt: TObject;
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
  sSkus  := ObtenerSkusFacturaCsv(ASerie, ANumero);
  if sSkus = '' then Exit;
  oDmArt.CrearDataSetEtiquetasArt('', ACodTarifa, AAlmacenesCsv,
                                  AFecha, sSkus);
end;

function TdmFacturasCompra.ObtenerSkusFacturaCsv(
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
      'SELECT DISTINCT CODIGO_UNIDAD_FACCLIN ' +
      '  FROM fza_facturas_compra_lineas ' +
      ' WHERE SERIE_FACC_FACCLIN = :s AND NUMERO_FACC_FACCLIN = :n ' +
      '   AND COALESCE(CODIGO_UNIDAD_FACCLIN, '''') <> ''''';
    oQry.ParamByName('s').AsString := ASerie;
    oQry.ParamByName('n').AsString := ANumero;
    oQry.Open;
    while not oQry.Eof do
    begin
      if Result <> '' then Result := Result + ',';
      Result := Result + QuotedStr(
        oQry.FieldByName('CODIGO_UNIDAD_FACCLIN').AsString);
      oQry.Next;
    end;
  finally
    FreeAndNil(oQry);
  end;
end;

procedure TdmFacturasCompra.PrepararPrintSku(const ASerie, ANumero: string);
begin
  unqryCabFaccPrint.Close;
  unqryCabFaccPrint.ParamByName('SERIE_FACC').AsString  := ASerie;
  unqryCabFaccPrint.ParamByName('NUMERO_FACC').AsString := ANumero;
  unqryCabFaccPrint.Open;
  unqryLinFaccSkuPrint.Close;
  unqryLinFaccSkuPrint.ParamByName('SERIE_FACC').AsString  := ASerie;
  unqryLinFaccSkuPrint.ParamByName('NUMERO_FACC').AsString := ANumero;
  unqryLinFaccSkuPrint.Open;
end;

end.
