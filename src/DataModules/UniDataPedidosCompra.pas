{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataPedidosCompra                                          }
{    Tipo:       Data Module                                                   }
{ Version:       1.0.0                                                         }
{   Fecha:       28/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Data module de pedidos de COMPRA.                                         }
{    Espejo simplificado de UniDataAlbaranesCompra. Diferencias clave:         }
{      - Numeracion con TIPO_DOC = 'PC' (vs 'AB' de albaranes).                }
{      - AfterPost de cabecera dispara GenerarPdteRecibirDesdePedido para      }
{        sincronizar fza_articulos_pdte_recibir con las lineas actuales.      }
{      - BeforeDelete de cabecera y lineas dispara BorrarPdteRecibir para     }
{        no dejar filas huerfanas en fza_articulos_pdte_recibir.              }
{      - NO genera movimientos de stock — el pedido es compromiso, no         }
{        entrada fisica. Los movs los genera el albaran cuando se cree        }
{        desde el pedido via inLibPedidosCompra.CrearAlbaranDesdePedido.      }
{******************************************************************************}
unit UniDataPedidosCompra;

interface

uses
  System.SysUtils, System.Classes, System.Variants,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, inLibUser, inMtoPrincipal;

type
  TdmPedidosCompra = class(TdmBase)
    unqryPedidosCompraLineas: TUniQuery;
    dsPedidosCompraLineas:    TDataSource;
    unqryEmpDataPedc:         TUniQuery;
    unqryPrvDataPedc:         TUniQuery;
    unqrySkusPedc:            TUniQuery;
    unstrdprcGetContadorPedc: TUniStoredProc;
    unqryDefArticuloPedc:     TUniQuery;
    unqryTemporadasPedc:      TUniQuery;
    dsTemporadasPedc:         TDataSource;
    unqryAlbaranesPedc:       TUniQuery;
    dsAlbaranesPedc:          TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryPedidosCompraLineasAfterInsert(DataSet: TDataSet);
    procedure unqryPedidosCompraLineasBeforePost(DataSet: TDataSet);
    procedure unqryPedidosCompraLineasAfterPost(DataSet: TDataSet);
    procedure unqryPedidosCompraLineasBeforeDelete(DataSet: TDataSet);
  private
    FCalculandoTotales: Boolean;
  public
    procedure GetCodigoAutoPedidoCompra;
    procedure CalcularTotalesPedidoCompra;
    procedure OpenTables;
    procedure AbrirDetalles; override;
  end;

implementation

uses
  inLibGlobalVar, inLibLog, inLibtb, inLibContadorLineas,
  System.Diagnostics,
  inMtoPedidosCompra,
  inLibPedidosCompra,
  inLibComprasImpuestos;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmPedidosCompra.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection              := inLibGlobalVar.oConn;
  unqryPedidosCompraLineas.Connection := inLibGlobalVar.oConn;
  unqryEmpDataPedc.Connection         := inLibGlobalVar.oConn;
  unqryPrvDataPedc.Connection         := inLibGlobalVar.oConn;
  unqrySkusPedc.Connection            := inLibGlobalVar.oConn;
  unstrdprcGetContadorPedc.Connection := inLibGlobalVar.oConn;
  unqryDefArticuloPedc.Connection     := inLibGlobalVar.oConn;
  unqryTemporadasPedc.Connection      := inLibGlobalVar.oConn;
  unqryTemporadasPedc.Open;
  unqryPedidosCompraLineas.MasterSource :=
    (GetOwnerForm<TfrmMtoPedidosCompra>).dsTablaG;
  // Albaranes de compra creados desde este pedido (master-detail por
  // NUMERO_PED_ALBC / SERIE_PED_ALBC). Solo lectura, para la pestania.
  unqryAlbaranesPedc.Connection := inLibGlobalVar.oConn;
  unqryAlbaranesPedc.MasterSource :=
    (GetOwnerForm<TfrmMtoPedidosCompra>).dsTablaG;
end;

procedure TdmPedidosCompra.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(unqryPedidosCompraLineas) and
     unqryPedidosCompraLineas.Active then
    unqryPedidosCompraLineas.Close;
  inherited;
end;

procedure TdmPedidosCompra.OpenTables;
begin
  AbrirDetalles;
end;

procedure TdmPedidosCompra.AbrirDetalles;
const
  TAG = 'PedidosCompra.AbrirDetalles';
var
  sw, swQ: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  if not unqryPedidosCompraLineas.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      unqryPedidosCompraLineas.Open;
      inLibLog.Log.LogPerf(TAG, 'unqryPedidosCompraLineas OK',
                            swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        inLibLog.Log.LogPerf(TAG,
          'unqryPedidosCompraLineas ERROR=' + E.Message,
          swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
  if not unqryAlbaranesPedc.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      unqryAlbaranesPedc.Open;
      inLibLog.Log.LogPerf(TAG, 'unqryAlbaranesPedc OK',
                            swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        inLibLog.Log.LogPerf(TAG,
          'unqryAlbaranesPedc ERROR=' + E.Message,
          swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
  inLibLog.Log.LogPerf(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmPedidosCompra.unqryTablaGAfterInsert(DataSet: TDataSet);
var
  sSerie: string;
begin
  inherited;
  with unqryTablaG do
  begin
    FieldByName('NUMERO_PEDC').AsString := '0';
    sSerie := ObtenerSerieDefecto(oEmpresa, 'PC');
    if FindField('SERIE_PEDC') <> nil then
    begin
      if sSerie <> '' then
        FieldByName('SERIE_PEDC').AsString := sSerie
      else
        FieldByName('SERIE_PEDC').AsString := 'C1';
    end;
    FieldByName('FECHA_PEDC').AsDateTime := Date;
    if FindField('ESTADO_PEDC') <> nil then
      FieldByName('ESTADO_PEDC').AsString := 'ABIERTO';
    if Trim(oEmpresa) <> '' then
      FieldByName('CODIGO_EMP_PEDC').AsString := oEmpresa
    else
      FieldByName('CODIGO_EMP_PEDC').AsString := '0';
    FieldByName('CODIGO_PRV_PEDC').AsString := '0';
    AplicarRecargoComprasEmpresa(inLibGlobalVar.oConn, unqryTablaG,
      'CODIGO_EMP_PEDC', 'ESIVA_RECARGO_COMPRAS_PEDC');
    AplicarPorcentajesIvaCompra(inLibGlobalVar.oConn, unqryTablaG,
      'PEDC');
  end;
end;

procedure TdmPedidosCompra.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  if (unqryTablaG.FieldByName('NUMERO_PEDC').AsString = '0') or
     (unqryTablaG.FieldByName('NUMERO_PEDC').AsString = '') then
    GetCodigoAutoPedidoCompra;
  AplicarPorcentajesIvaCompra(inLibGlobalVar.oConn, unqryTablaG,
    'PEDC');
  CalcularTotalesPedidoCompra;
end;

procedure TdmPedidosCompra.unqryTablaGAfterPost(DataSet: TDataSet);
var
  sSerie, sNumero: string;
begin
  inherited;
  // Sincronizar pendientes de recibir: borra y reinserta todas las
  // filas del pedido en fza_articulos_pdte_recibir. Aqui ya tenemos
  // la cabecera persistida en BBDD asi que la lectura de las lineas
  // ve el estado real.
  sSerie  := unqryTablaG.FieldByName('SERIE_PEDC').AsString;
  sNumero := unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
  if (sSerie = '') or (sNumero = '') then Exit;
  inLibPedidosCompra.GenerarPdteRecibirDesdePedido(
    inLibGlobalVar.oConn, sSerie, sNumero, oUser);
end;

procedure TdmPedidosCompra.unqryTablaGBeforeDelete(DataSet: TDataSet);
var
  sSerie, sNumero: string;
begin
  inherited;
  // Limpiar pendientes de recibir antes de borrar la cabecera para no
  // dejar filas huerfanas. Las lineas las borra el ON DELETE CASCADE
  // (no aplica aqui: no hay FK) — bueno, simplemente las lineas se
  // pueden quedar tambien huerfanas. Las borramos a mano.
  sSerie  := unqryTablaG.FieldByName('SERIE_PEDC').AsString;
  sNumero := unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
  if (sSerie = '') or (sNumero = '') then Exit;
  inLibPedidosCompra.BorrarPdteRecibirDesdePedido(
    inLibGlobalVar.oConn, sSerie, sNumero);
  // Borrar lineas asociadas para que no se queden huerfanas (no hay
  // FK con CASCADE).
  with TUniQuery.Create(nil) do
  try
    Connection := inLibGlobalVar.oConn;
    SQL.Text :=
      'DELETE FROM fza_pedidos_compra_lineas ' +
      ' WHERE SERIE_PEDC_PEDCLIN  = :s ' +
      '   AND NUMERO_PEDC_PEDCLIN = :n';
    ParamByName('s').AsString := sSerie;
    ParamByName('n').AsString := sNumero;
    ExecSQL;
  finally
    Free;
  end;
end;

procedure TdmPedidosCompra.unqryPedidosCompraLineasAfterInsert(
                                                       DataSet: TDataSet);
var
  iNuevaLinea : Integer;
  sSerie      : string;
  sNumero     : string;
begin
  inherited;
  // Asignacion de LINEA_PEDCLIN (clave secundaria, NOT NULL sin default).
  // Sin esto, cxGrid disparaba Post al navegar fuera de la nueva fila y
  // CheckRequiredFields lanzaba 'LINEA_PEDCLIN must have a value'. Mismo
  // patron que albaranes / sesiones de compra: el helper hace un UPDATE
  // atomico de CONTADOR_LINEAS_PEDC +10 sobre la cabecera y devuelve el
  // nuevo valor, sin la condicion de carrera del MAX()+10 (dos altas en
  // memoria sin Post intermedio repetian linea). La materializacion ya
  // mantiene el contador, asi que ambos caminos quedan coherentes. Formato
  // '0010','0020',... (4 digitos LPAD) para casar con las lineas
  // materializadas y respetar el ORDER BY LINEA_PEDCLIN (texto).
  sSerie  := unqryTablaG.FieldByName('SERIE_PEDC').AsString;
  sNumero := unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
  iNuevaLinea := GetSiguienteLineaDoc(CONT_PEDIDOS_COMPRA, sSerie, sNumero);
  if iNuevaLinea = 0 then
  begin
    // Cabecera aun no persistida (pedido nuevo sin NUMERO real): fallback
    // al contador en memoria +10. StrToIntDef y no AsInteger: el contador
    // es varchar NULL en alta y AsInteger sobre '' lanzaria EConvertError.
    iNuevaLinea := StrToIntDef(
      unqryTablaG.FieldByName('CONTADOR_LINEAS_PEDC').AsString, 0) + 10;
    if not (unqryTablaG.State in [dsEdit, dsInsert]) then
      unqryTablaG.Edit;
    unqryTablaG.FieldByName('CONTADOR_LINEAS_PEDC').AsString :=
      Format('%.8d', [iNuevaLinea]);
  end;
  with unqryPedidosCompraLineas do
  begin
    FieldByName('NUMERO_PEDC_PEDCLIN').AsString :=
      unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
    FieldByName('SERIE_PEDC_PEDCLIN').AsString :=
      unqryTablaG.FieldByName('SERIE_PEDC').AsString;
    FieldByName('LINEA_PEDCLIN').AsString := Format('%.4d', [iNuevaLinea]);
    FieldByName('CANTIDAD_PEDCLIN').AsFloat := 1;
    FieldByName('CANTIDAD_RECIBIDA_PEDCLIN').AsFloat := 0;
    // Por defecto la linea hereda el almacen de la cabecera; el usuario
    // puede sobreescribirlo si quiere mezclar lineas de varios almacenes.
    if FindField('CODIGO_ALMACEN_PEDCLIN') <> nil then
      FieldByName('CODIGO_ALMACEN_PEDCLIN').AsString :=
        unqryTablaG.FieldByName('CODIGO_ALM_PEDC').AsString;
    FieldByName('USUARIO_ALTA').AsString    := oUser;
    FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    FieldByName('USUARIO_MODIF').AsString   := oUser;
    FieldByName('INSTANTE_MODIF').AsDateTime:= Now;
  end;
end;

procedure TdmPedidosCompra.unqryPedidosCompraLineasBeforePost(
                                                       DataSet: TDataSet);
var
  sSku, sArt: string;
begin
  inherited;
  // Linea vacia (sin articulo ni SKU): cancelar silenciosamente. El cxGrid
  // hace Post automatico al navegar con flechas (OptionsData.Appending); si
  // la linea es un placeholder vacio que el usuario creo sin querer, se
  // descarta con Cancel diferido + Abort en vez de grabar una linea basura
  // (y disparar en AfterPost un pendiente-de-recibir bogus). Mismo patron
  // que albaranes / sesiones de compra.
  if (Trim(unqryPedidosCompraLineas.FieldByName(
             'CODIGO_ART_PEDCLIN').AsString) = '') and
     (Trim(unqryPedidosCompraLineas.FieldByName(
             'CODIGO_UNIDAD_PEDCLIN').AsString) = '') then
  begin
    TThread.ForceQueue(nil,
      procedure
      begin
        if unqryPedidosCompraLineas.Active and
           (unqryPedidosCompraLineas.State in [dsEdit, dsInsert]) then
          unqryPedidosCompraLineas.Cancel;
      end);
    Abort;
  end;
  with unqryPedidosCompraLineas do
  begin
    if (FindField('CANTIDAD_PEDCLIN') <> nil) and
       (FindField('PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN') <> nil) and
       (FindField('TOTAL_PEDCLIN') <> nil) then
      FieldByName('TOTAL_PEDCLIN').AsFloat :=
        FieldByName('CANTIDAD_PEDCLIN').AsFloat *
        FieldByName('PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN').AsFloat;
    if FindField('USUARIO_MODIF') <> nil then
      FieldByName('USUARIO_MODIF').AsString   := oUser;
    if FindField('INSTANTE_MODIF') <> nil then
      FieldByName('INSTANTE_MODIF').AsDateTime:= Now;
    if (DataSet.State = dsInsert) then
    begin
      if (FindField('USUARIO_ALTA') <> nil) and
         (FieldByName('USUARIO_ALTA').AsString = '') then
        FieldByName('USUARIO_ALTA').AsString := oUser;
      if (FindField('INSTANTE_ALTA') <> nil) and
         FieldByName('INSTANTE_ALTA').IsNull then
        FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    end;
    // Si tecleo SKU pero no articulo, lo deducimos via fza_articulos_skus.
    if (FindField('CODIGO_UNIDAD_PEDCLIN') <> nil) and
       (FindField('CODIGO_ART_PEDCLIN') <> nil) then
    begin
      sSku := Trim(FieldByName('CODIGO_UNIDAD_PEDCLIN').AsString);
      sArt := Trim(FieldByName('CODIGO_ART_PEDCLIN').AsString);
      if (sSku <> '') and (sArt = '') then
      begin
        unqrySkusPedc.Close;
        unqrySkusPedc.ParamByName('pSKU').AsString := sSku;
        unqrySkusPedc.Open;
        if not unqrySkusPedc.Eof then
          FieldByName('CODIGO_ART_PEDCLIN').AsString :=
            unqrySkusPedc.FieldByName('CODIGO_ART_SKU').AsString;
        unqrySkusPedc.Close;
      end;
    end;
    PrepararLineaFiscalCompra(inLibGlobalVar.oConn, unqryTablaG,
      unqryPedidosCompraLineas, 'PEDC', 'PEDCLIN', 'TOTAL_PEDCLIN');
  end;
end;

procedure TdmPedidosCompra.unqryPedidosCompraLineasAfterPost(
                                                       DataSet: TDataSet);
var
  sSerie, sNumero: string;
begin
  inherited;
  CalcularTotalesPedidoCompra;
  // Tras editar una linea, resincronizamos las pendientes de recibir
  // (cantidad de la linea puede haber cambiado).
  sSerie  := unqryTablaG.FieldByName('SERIE_PEDC').AsString;
  sNumero := unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
  if (sSerie = '') or (sNumero = '') then Exit;
  inLibPedidosCompra.GenerarPdteRecibirDesdePedido(
    inLibGlobalVar.oConn, sSerie, sNumero, oUser);
end;

procedure TdmPedidosCompra.unqryPedidosCompraLineasBeforeDelete(
                                                       DataSet: TDataSet);
var
  sSerie, sNumero, sLinea: string;
begin
  inherited;
  // Borrar la fila concreta de fza_articulos_pdte_recibir antes de
  // borrar la linea: la PK incluye LINEA_PDR asi que es seguro.
  sSerie  := unqryPedidosCompraLineas.FieldByName('SERIE_PEDC_PEDCLIN').AsString;
  sNumero := unqryPedidosCompraLineas.FieldByName('NUMERO_PEDC_PEDCLIN').AsString;
  sLinea  := unqryPedidosCompraLineas.FieldByName('LINEA_PEDCLIN').AsString;
  if (sSerie = '') or (sNumero = '') then Exit;
  inLibPedidosCompra.BorrarPdteRecibirDesdePedido(
    inLibGlobalVar.oConn, sSerie, sNumero, sLinea);
end;

procedure TdmPedidosCompra.GetCodigoAutoPedidoCompra;
begin
  with unstrdprcGetContadorPedc do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'pserie',            ptInput);
    Params.CreateParam(ftString, 'ptipodoc',          ptInput);
    Params.CreateParam(ftString, 'pcont',             ptOutput);
    Params.CreateParam(ftString, 'pEMPRESA_CONTADOR', ptInput);
    Params.CreateParam(ftString, 'pUSUARIOMODIF',     ptInput);
    ParamByName('pserie').AsString :=
      unqryTablaG.FieldByName('SERIE_PEDC').AsString;
    ParamByName('ptipodoc').AsString := 'PC';
    ParamByName('pUSUARIOMODIF').AsString := oUser;
    ParamByName('pEMPRESA_CONTADOR').AsString :=
      unqryTablaG.FieldByName('CODIGO_EMP_PEDC').AsString;
    ExecProc;
    unqryTablaG.FieldByName('NUMERO_PEDC').AsString :=
      ParamByName('pcont').AsString;
  end;
end;

procedure TdmPedidosCompra.CalcularTotalesPedidoCompra;
begin
  if not FCalculandoTotales then
  begin
    FCalculandoTotales := True;
    try
      CalcularTotalesDocumentoCompra(inLibGlobalVar.oConn, unqryTablaG,
        unqryPedidosCompraLineas, 'PEDC', 'TOTAL_PEDCLIN',
        'TIPO_IVA_ARTICULO_PEDCLIN', 'PORCENTAJE_IVA_PEDCLIN');
    finally
      FCalculandoTotales := False;
    end;
  end;
end;

end.
