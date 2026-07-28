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
  UniDataGen, inLibUser;

type
  TdmPedidosCompra = class(TdmBase)
    unqryPedidosCompraLineas: TUniQuery;
    dsPedidosCompraLineas:    TDataSource;
    unqryEmpDataPedc:         TUniQuery;
    unqryPrvDataPedc:         TUniQuery;
    dsPrvDataPedc:            TDataSource;
    unqrySkusPedc:            TUniQuery;
    unstrdprcGetContadorPedc: TUniStoredProc;
    unqryDefArticuloPedc:     TUniQuery;
    unqryTemporadasPedc:      TUniQuery;
    dsTemporadasPedc:         TDataSource;
    unqryAlbaranesPedc:       TUniQuery;
    dsAlbaranesPedc:          TDataSource;
    unqryFormasPago:          TUniQuery;
    dsFormasPago:             TDataSource;
    unqryAlmacenesPedc:       TUniQuery;
    dsAlmacenesPedc:          TDataSource;
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
    // True mientras DesempaquetarAtributosLineas postea lineas: cambio
    // puramente descriptivo que NO debe disparar la logica fiscal
    // (cascada por linea al navegar).
    FDesempaquetandoAtributos: Boolean;
    // >0 mientras el modo de entrada expande/consolida lineas en bloque
    // (una linea por SKU): totales y pendientes de recibir se posponen
    // a FinalizarReorganizacionLineas para no regenerarlos por linea.
    FReorganizandoLineas: Integer;
    FReorganizacionPendiente: Boolean;
    procedure AsignarNumeroLineaPedidoCompra(DataSet: TDataSet);
    procedure ConfigurarSqlCabecera;
    // Construye el SQLInsert contra fza_pedidos_compra: la vista
    // vi_pedidos_compra tiene columnas calculadas y no es insertable
    procedure ConfigurarSqlInsertCabecera;
    function ObtenerAlmacenesSql(const AAlmacenesCsv: string): string;
    function ObtenerSkusPedidoCsv(const ASerie, ANumero,
                                  AAlmacenesCsv: string): string;
    procedure CopiarEmpresaaPedidoCompra(DataSet: TDataSet);
    procedure ValidarAlmacenCabecera;
  public
    procedure GetCodigoAutoPedidoCompra;
    procedure CalcularTotalesPedidoCompra;
    // Bracket de reorganizacion masiva de lineas (construccion del modo
    // de entrada): entre Iniciar y Finalizar los posts de linea no
    // recalculan totales ni regeneran fza_articulos_pdte_recibir; se
    // hace UNA vez al Finalizar si hubo posts.
    procedure IniciarReorganizacionLineas;
    procedure FinalizarReorganizacionLineas;
    function EnReorganizacionLineas: Boolean;
    // True si el pedido enfocado tiene lineas con SKU sin celdas de
    // pivote: necesitan la primera fusion del modo tallas inline.
    function HayLineasSinPivotar: Boolean;
    // Cierra el bracket SIN recalculos ni reapertura del detalle (para
    // el teardown de FormDestroy, con el form muriendo). Devuelve True
    // si quedaron posts pospuestos (la expansion cambio lineas).
    function AbortarReorganizacionLineas: Boolean;
    // Regenera fza_articulos_pdte_recibir del pedido enfocado (borra y
    // reinserta): la expansion del teardown cambia la composicion de
    // lineas y los pendientes deben reflejarla.
    procedure SincronizarPdteRecibir;
    // Contrato ColumnSKUcxGrid: trocea CODIGO_UNIDAD_PEDCLIN en las
    // columnas reales ATTR1..5_VALOR_PEDCLIN + NUM_ATRIBUTOS_PEDCLIN
    // para el modo Desglose/Tallas. Idempotente por comparacion. No
    // hace nada si pedidos_compra_columnas_sku.sql no esta aplicado.
    procedure DesempaquetarAtributosLineas;
    function BuscarEmpresa(const ACodigo: string): Boolean;
    procedure RefrescarAlmacenes(const ACodigoEmpresa: string);
    procedure CargarAlmacenesDelPedido(const ASerie, ANumero: string;
                                       ALV: TObject);
    procedure CrearDataSetEtiquetasPed(ADmArt: TObject;
                                        const ASerie, ANumero,
                                              ACodTarifa,
                                              AAlmacenesCsv: string;
                                        AFecha: TDateTime);
    procedure ExpandirEtiquetasPorCantidadPed(ADmArt: TObject;
                                               const ASerie, ANumero,
                                                     AAlmacenesCsv: string);
    procedure OpenTables;
    // El form empuja su dsTablaG; el DM ya no usa GetOwnerForm.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    procedure AbrirDetalles; override;
  end;

implementation

uses
  inLibLog, inLibValoresAutomaticos, inLibContadorLineas,
  System.Diagnostics, System.UITypes, System.Generics.Collections,
  Vcl.Dialogs, ComCtrls, cxListView,
  inLibPedidosCompra,
  inLibComprasImpuestos,
  inLibData,
  inLibArticulosValidador,
  UniDataArticulos,
  inLibMsg;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmPedidosCompra.ConfigurarSqlInsertCabecera;
const
  // Mismas columnas de fza_pedidos_compra que usa el SQLUpdate
  CAMPOS: string =
    'NUMERO_PEDC;SERIE_PEDC;FECHA_PEDC;FECHA_PREVISTA_PEDC;' +
    'FECHA_TOPE_RECEPCION_PEDC;ESTADO_PEDC;CODIGO_EMP_PEDC;' +
    'RAZON_SOCIAL_EMPRESA_PEDC;NIF_EMPRESA_PEDC;MOVIL_EMPRESA_PEDC;' +
    'EMAIL_EMPRESA_PEDC;DIRECCION1_EMPRESA_PEDC;DIRECCION2_EMPRESA_PEDC;' +
    'POBLACION_EMPRESA_PEDC;PROVINCIA_EMPRESA_PEDC;' +
    'CODIGO_PAI_EMPRESA_PEDC;NOMBRE_PAI_EMPRESA_PEDC;' +
    'CODIGO_POSTAL_EMPRESA_PEDC;CODIGO_PRV_PEDC;RAZON_SOCIAL_PRV_PEDC;' +
    'NIF_PRV_PEDC;MOVIL_PRV_PEDC;EMAIL_PRV_PEDC;DIRECCION1_PRV_PEDC;' +
    'DIRECCION2_PRV_PEDC;POBLACION_PRV_PEDC;PROVINCIA_PRV_PEDC;' +
    'CODIGO_PAI_PRV_PEDC;NOMBRE_PAI_PRV_PEDC;CODIGO_POSTAL_PRV_PEDC;' +
    'REF_PROVEEDOR_PEDC;CODIGO_ALM_PEDC;TRANSPORTISTA_PEDC;' +
    'CODIGO_IVA_PEDC;ESIVA_RECARGO_COMPRAS_PEDC;' +
    'ESIVA_EXENTO_INTRACOMUNITARIO_PEDC;PORCENTAJE_IVAN_PEDC;' +
    'TOTAL_BASEI_IVAN_PEDC;TOTAL_IVAN_PEDC;PORCENTAJE_REN_PEDC;' +
    'TOTAL_REN_PEDC;PORCENTAJE_IVAR_PEDC;TOTAL_BASEI_IVAR_PEDC;' +
    'TOTAL_IVAR_PEDC;PORCENTAJE_RER_PEDC;TOTAL_RER_PEDC;' +
    'PORCENTAJE_IVAS_PEDC;TOTAL_BASEI_IVAS_PEDC;TOTAL_IVAS_PEDC;' +
    'PORCENTAJE_RES_PEDC;TOTAL_RES_PEDC;PORCENTAJE_IVAE_PEDC;' +
    'TOTAL_BASEI_IVAE_PEDC;TOTAL_IVAE_PEDC;PORCENTAJE_REE_PEDC;' +
    'TOTAL_REE_PEDC;TOTAL_BRUTO_PEDC;PORCENTAJE_DTO_COMERCIAL_PEDC;' +
    'TOTAL_DTO_COMERCIAL_PEDC;PORCENTAJE_DTO_FINANCIERO_PEDC;' +
    'TOTAL_DTO_FINANCIERO_PEDC;TOTAL_BASES_PEDC;TOTAL_IMPUESTOS_PEDC;' +
    'PORCENTAJE_RETENCION_PEDC;TOTAL_RETENCION_PEDC;TOTAL_LIQUIDO_PEDC;' +
    'FORMA_PAGO_PEDC;CONTADOR_LINEAS_PEDC;COMENTARIOS_PEDC;' +
    'OBSERVACIONES_PEDC;ESPIVOTE_HORIZONTAL_PEDC;INSTANTE_MODIF;' +
    'INSTANTE_ALTA;USUARIO_ALTA;USUARIO_MODIF;ID_PV_TEMPORADA_PEDC';
var
  lst: TStringList;
  sCols: string;
  sVals: string;
  i: Integer;
begin
  lst := TStringList.Create;
  try
    lst.Delimiter := ';';
    lst.StrictDelimiter := True;
    lst.DelimitedText := CAMPOS;
    sCols := '';
    sVals := '';
    for i := 0 to lst.Count - 1 do
    begin
      if sCols <> '' then
      begin
        sCols := sCols + ', ';
        sVals := sVals + ', ';
      end;
      sCols := sCols + lst[i];
      sVals := sVals + ':' + lst[i];
    end;
    unqryTablaG.SQLInsert.Text :=
      'INSERT INTO fza_pedidos_compra (' + sCols + ') ' + sLineBreak +
      'VALUES (' + sVals + ')';
  finally
    FreeAndNil(lst);
  end;
end;

procedure TdmPedidosCompra.ConfigurarSqlCabecera;
begin
  ConfigurarSqlInsertCabecera;
  unqryTablaG.SQLDelete.Text :=
    'DELETE FROM fza_pedidos_compra ' + sLineBreak +
    'WHERE NUMERO_PEDC = :Old_NUMERO_PEDC ' + sLineBreak +
    '  AND SERIE_PEDC = :Old_SERIE_PEDC';
  unqryTablaG.SQLUpdate.Text :=
    'UPDATE fza_pedidos_compra ' + sLineBreak +
    '   SET NUMERO_PEDC = :NUMERO_PEDC, ' + sLineBreak +
    '       SERIE_PEDC = :SERIE_PEDC, ' + sLineBreak +
    '       FECHA_PEDC = :FECHA_PEDC, ' + sLineBreak +
    '       FECHA_PREVISTA_PEDC = :FECHA_PREVISTA_PEDC, ' + sLineBreak +
    '       FECHA_TOPE_RECEPCION_PEDC = :FECHA_TOPE_RECEPCION_PEDC, ' +
      sLineBreak +
    '       ESTADO_PEDC = :ESTADO_PEDC, ' + sLineBreak +
    '       CODIGO_EMP_PEDC = :CODIGO_EMP_PEDC, ' + sLineBreak +
    '       RAZON_SOCIAL_EMPRESA_PEDC = :RAZON_SOCIAL_EMPRESA_PEDC, ' +
      sLineBreak +
    '       NIF_EMPRESA_PEDC = :NIF_EMPRESA_PEDC, ' + sLineBreak +
    '       MOVIL_EMPRESA_PEDC = :MOVIL_EMPRESA_PEDC, ' + sLineBreak +
    '       EMAIL_EMPRESA_PEDC = :EMAIL_EMPRESA_PEDC, ' + sLineBreak +
    '       DIRECCION1_EMPRESA_PEDC = :DIRECCION1_EMPRESA_PEDC, ' +
      sLineBreak +
    '       DIRECCION2_EMPRESA_PEDC = :DIRECCION2_EMPRESA_PEDC, ' +
      sLineBreak +
    '       POBLACION_EMPRESA_PEDC = :POBLACION_EMPRESA_PEDC, ' + sLineBreak +
    '       PROVINCIA_EMPRESA_PEDC = :PROVINCIA_EMPRESA_PEDC, ' +
      sLineBreak +
    '       CODIGO_PAI_EMPRESA_PEDC = :CODIGO_PAI_EMPRESA_PEDC, ' +
      sLineBreak +
    '       NOMBRE_PAI_EMPRESA_PEDC = :NOMBRE_PAI_EMPRESA_PEDC, ' +
      sLineBreak +
    '       CODIGO_POSTAL_EMPRESA_PEDC = :CODIGO_POSTAL_EMPRESA_PEDC, ' +
      sLineBreak +
    '       CODIGO_PRV_PEDC = :CODIGO_PRV_PEDC, ' + sLineBreak +
    '       RAZON_SOCIAL_PRV_PEDC = :RAZON_SOCIAL_PRV_PEDC, ' + sLineBreak +
    '       NIF_PRV_PEDC = :NIF_PRV_PEDC, ' + sLineBreak +
    '       MOVIL_PRV_PEDC = :MOVIL_PRV_PEDC, ' + sLineBreak +
    '       EMAIL_PRV_PEDC = :EMAIL_PRV_PEDC, ' + sLineBreak +
    '       DIRECCION1_PRV_PEDC = :DIRECCION1_PRV_PEDC, ' + sLineBreak +
    '       DIRECCION2_PRV_PEDC = :DIRECCION2_PRV_PEDC, ' + sLineBreak +
    '       POBLACION_PRV_PEDC = :POBLACION_PRV_PEDC, ' + sLineBreak +
    '       PROVINCIA_PRV_PEDC = :PROVINCIA_PRV_PEDC, ' + sLineBreak +
    '       CODIGO_PAI_PRV_PEDC = :CODIGO_PAI_PRV_PEDC, ' + sLineBreak +
    '       NOMBRE_PAI_PRV_PEDC = :NOMBRE_PAI_PRV_PEDC, ' + sLineBreak +
    '       CODIGO_POSTAL_PRV_PEDC = :CODIGO_POSTAL_PRV_PEDC, ' +
      sLineBreak +
    '       REF_PROVEEDOR_PEDC = :REF_PROVEEDOR_PEDC, ' + sLineBreak +
    '       CODIGO_ALM_PEDC = :CODIGO_ALM_PEDC, ' + sLineBreak +
    '       TRANSPORTISTA_PEDC = :TRANSPORTISTA_PEDC, ' + sLineBreak +
    '       CODIGO_IVA_PEDC = :CODIGO_IVA_PEDC, ' + sLineBreak +
    '       ESIVA_RECARGO_COMPRAS_PEDC = :ESIVA_RECARGO_COMPRAS_PEDC, ' +
      sLineBreak +
    '       ESIVA_EXENTO_INTRACOMUNITARIO_PEDC = ' +
      ':ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ' + sLineBreak +
    '       PORCENTAJE_IVAN_PEDC = :PORCENTAJE_IVAN_PEDC, ' + sLineBreak +
    '       TOTAL_BASEI_IVAN_PEDC = :TOTAL_BASEI_IVAN_PEDC, ' + sLineBreak +
    '       TOTAL_IVAN_PEDC = :TOTAL_IVAN_PEDC, ' + sLineBreak +
    '       PORCENTAJE_REN_PEDC = :PORCENTAJE_REN_PEDC, ' + sLineBreak +
    '       TOTAL_REN_PEDC = :TOTAL_REN_PEDC, ' + sLineBreak +
    '       PORCENTAJE_IVAR_PEDC = :PORCENTAJE_IVAR_PEDC, ' + sLineBreak +
    '       TOTAL_BASEI_IVAR_PEDC = :TOTAL_BASEI_IVAR_PEDC, ' + sLineBreak +
    '       TOTAL_IVAR_PEDC = :TOTAL_IVAR_PEDC, ' + sLineBreak +
    '       PORCENTAJE_RER_PEDC = :PORCENTAJE_RER_PEDC, ' + sLineBreak +
    '       TOTAL_RER_PEDC = :TOTAL_RER_PEDC, ' + sLineBreak +
    '       PORCENTAJE_IVAS_PEDC = :PORCENTAJE_IVAS_PEDC, ' + sLineBreak +
    '       TOTAL_BASEI_IVAS_PEDC = :TOTAL_BASEI_IVAS_PEDC, ' + sLineBreak +
    '       TOTAL_IVAS_PEDC = :TOTAL_IVAS_PEDC, ' + sLineBreak +
    '       PORCENTAJE_RES_PEDC = :PORCENTAJE_RES_PEDC, ' + sLineBreak +
    '       TOTAL_RES_PEDC = :TOTAL_RES_PEDC, ' + sLineBreak +
    '       PORCENTAJE_IVAE_PEDC = :PORCENTAJE_IVAE_PEDC, ' + sLineBreak +
    '       TOTAL_BASEI_IVAE_PEDC = :TOTAL_BASEI_IVAE_PEDC, ' + sLineBreak +
    '       TOTAL_IVAE_PEDC = :TOTAL_IVAE_PEDC, ' + sLineBreak +
    '       PORCENTAJE_REE_PEDC = :PORCENTAJE_REE_PEDC, ' + sLineBreak +
    '       TOTAL_REE_PEDC = :TOTAL_REE_PEDC, ' + sLineBreak +
    '       TOTAL_BRUTO_PEDC = :TOTAL_BRUTO_PEDC, ' + sLineBreak +
    '       PORCENTAJE_DTO_COMERCIAL_PEDC = ' +
      ':PORCENTAJE_DTO_COMERCIAL_PEDC, ' + sLineBreak +
    '       TOTAL_DTO_COMERCIAL_PEDC = :TOTAL_DTO_COMERCIAL_PEDC, ' +
      sLineBreak +
    '       PORCENTAJE_DTO_FINANCIERO_PEDC = ' +
      ':PORCENTAJE_DTO_FINANCIERO_PEDC, ' + sLineBreak +
    '       TOTAL_DTO_FINANCIERO_PEDC = :TOTAL_DTO_FINANCIERO_PEDC, ' +
      sLineBreak +
    '       TOTAL_BASES_PEDC = :TOTAL_BASES_PEDC, ' + sLineBreak +
    '       TOTAL_IMPUESTOS_PEDC = :TOTAL_IMPUESTOS_PEDC, ' + sLineBreak +
    '       PORCENTAJE_RETENCION_PEDC = :PORCENTAJE_RETENCION_PEDC, ' +
      sLineBreak +
    '       TOTAL_RETENCION_PEDC = :TOTAL_RETENCION_PEDC, ' + sLineBreak +
    '       TOTAL_LIQUIDO_PEDC = :TOTAL_LIQUIDO_PEDC, ' + sLineBreak +
    '       FORMA_PAGO_PEDC = :FORMA_PAGO_PEDC, ' + sLineBreak +
    '       CONTADOR_LINEAS_PEDC = :CONTADOR_LINEAS_PEDC, ' + sLineBreak +
    '       COMENTARIOS_PEDC = :COMENTARIOS_PEDC, ' + sLineBreak +
    '       OBSERVACIONES_PEDC = :OBSERVACIONES_PEDC, ' + sLineBreak +
    '       ESPIVOTE_HORIZONTAL_PEDC = :ESPIVOTE_HORIZONTAL_PEDC, ' +
      sLineBreak +
    '       INSTANTE_MODIF = :INSTANTE_MODIF, ' + sLineBreak +
    '       INSTANTE_ALTA = :INSTANTE_ALTA, ' + sLineBreak +
    '       USUARIO_ALTA = :USUARIO_ALTA, ' + sLineBreak +
    '       USUARIO_MODIF = :USUARIO_MODIF, ' + sLineBreak +
    '       ID_PV_TEMPORADA_PEDC = :ID_PV_TEMPORADA_PEDC ' + sLineBreak +
    ' WHERE NUMERO_PEDC = :Old_NUMERO_PEDC ' + sLineBreak +
    '   AND SERIE_PEDC = :Old_SERIE_PEDC';
  unqryTablaG.SQLRefresh.Text :=
    'SELECT * ' + sLineBreak +
    '  FROM vi_pedidos_compra ' + sLineBreak +
    ' WHERE NUMERO_PEDC = :NUMERO_PEDC ' + sLineBreak +
    '   AND SERIE_PEDC = :SERIE_PEDC';
end;

procedure TdmPedidosCompra.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection              := ConexionPrincipal;
  unqryTablaG.KeyFields               := 'NUMERO_PEDC;SERIE_PEDC';
  ConfigurarSqlCabecera;
  unqryPedidosCompraLineas.Connection := ConexionPrincipal;
  unqryEmpDataPedc.Connection         := ConexionPrincipal;
  unqryPrvDataPedc.Connection         := ConexionPrincipal;
  // Lookup completo de proveedores (NOMBRE_PRV + RAZON_SOCIAL_PRV) para
  // el rotulo resuelto de la cabecera y para el combo de busqueda
  // incremental por codigo (cbbCODIGO_PRV_PEDC). Se abre una vez y se
  // recorre con Locate; no depende del proveedor del pedido en pantalla.
  unqryPrvDataPedc.Open;
  unqrySkusPedc.Connection            := ConexionPrincipal;
  unstrdprcGetContadorPedc.Connection := ConexionPrincipal;
  unqryDefArticuloPedc.Connection     := ConexionPrincipal;
  unqryTemporadasPedc.Connection      := ConexionPrincipal;
  unqryTemporadasPedc.Open;
  unqryFormasPago.Connection          := ConexionPrincipal;
  unqryAlmacenesPedc.Connection       := ConexionPrincipal;
  unqryAlbaranesPedc.Connection := ConexionPrincipal;
end;

procedure TdmPedidosCompra.AsignarMaestroCabecera(
  ADataSource: TDataSource);
begin
  inherited;
  unqryPedidosCompraLineas.MasterSource := ADataSource;
  // Albaranes de compra creados desde este pedido (master-detail por
  // NUMERO_PED_ALBC / SERIE_PED_ALBC). Solo lectura, para la pestania.
  unqryAlbaranesPedc.MasterSource := ADataSource;
end;

procedure TdmPedidosCompra.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(unqryPedidosCompraLineas) and
     unqryPedidosCompraLineas.Active then
    unqryPedidosCompraLineas.Close;
  if Assigned(unqryFormasPago) and unqryFormasPago.Active then
    unqryFormasPago.Close;
  if Assigned(unqryAlmacenesPedc) and unqryAlmacenesPedc.Active then
    unqryAlmacenesPedc.Close;
  inherited;
end;

procedure TdmPedidosCompra.OpenTables;
begin
  AbrirDetalles;
end;

procedure TdmPedidosCompra.RefrescarAlmacenes(
  const ACodigoEmpresa: string);
var
  sEmpresa: string;
begin
  sEmpresa := Trim(ACodigoEmpresa);
  if (sEmpresa = '') and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
    sEmpresa := Trim(unqryTablaG.FieldByName('CODIGO_EMP_PEDC').AsString);
  if sEmpresa = '' then
    sEmpresa := Trim(UbicacionSesion.Empresa);
  if (not unqryAlmacenesPedc.Active) or
     (not SameText(unqryAlmacenesPedc.ParamByName('EMPRESA').AsString,
                   sEmpresa)) then
  begin
    unqryAlmacenesPedc.Close;
    unqryAlmacenesPedc.ParamByName('EMPRESA').AsString := sEmpresa;
    unqryAlmacenesPedc.Open;
  end;
  if unqryTablaG.Active and
     (unqryTablaG.State in [dsInsert, dsEdit]) then
    AjustarEmpresaAlmacenDataSet(unqryTablaG.Connection, unqryTablaG,
      'CODIGO_EMP_PEDC', 'CODIGO_ALM_PEDC');
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
  if not unqryFormasPago.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      unqryFormasPago.Open;
      inLibLog.Log.LogPerf(TAG, 'unqryFormasPago OK',
                            swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        inLibLog.Log.LogPerf(TAG,
          'unqryFormasPago ERROR=' + E.Message,
          swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
  if not unqryAlmacenesPedc.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      unqryAlmacenesPedc.Open;
      inLibLog.Log.LogPerf(TAG, 'unqryAlmacenesPedc OK',
                            swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        inLibLog.Log.LogPerf(TAG,
          'unqryAlmacenesPedc ERROR=' + E.Message,
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
    sSerie := ObtenerSerieDefecto(
      ConexionPrincipal,
      UbicacionSesion.Empresa,
      'PC');
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
    if Trim(UbicacionSesion.Empresa) <> '' then
      FieldByName('CODIGO_EMP_PEDC').AsString := UbicacionSesion.Empresa
    else
      FieldByName('CODIGO_EMP_PEDC').AsString := '0';
    if Trim(UbicacionSesion.Empresa) <> '' then
      BuscarEmpresa(UbicacionSesion.Empresa);
    if FindField('CODIGO_ALM_PEDC') <> nil then
      FieldByName('CODIGO_ALM_PEDC').AsString := UbicacionSesion.Almacen;
    FieldByName('CODIGO_PRV_PEDC').AsString := '0';
    if FindField('ESPIVOTE_HORIZONTAL_PEDC') <> nil then
      FieldByName('ESPIVOTE_HORIZONTAL_PEDC').AsString := 'N';
    if FindField('ESIVA_EXENTO_INTRACOMUNITARIO_PEDC') <> nil then
      FieldByName('ESIVA_EXENTO_INTRACOMUNITARIO_PEDC').AsString := 'N';
    AplicarRecargoComprasEmpresa(ConexionPrincipal, unqryTablaG,
      'CODIGO_EMP_PEDC', 'ESIVA_RECARGO_COMPRAS_PEDC');
    AplicarPorcentajesIvaCompra(ConexionPrincipal, unqryTablaG,
      'PEDC');
  end;
  RefrescarAlmacenes(
    DataSet.FieldByName('CODIGO_EMP_PEDC').AsString);
end;

function TdmPedidosCompra.BuscarEmpresa(const ACodigo: string): Boolean;
var
  sCodigo: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if (sCodigo <> '') and (sCodigo <> '0') then
  begin
    if not unqryEmpDataPedc.Active then
      unqryEmpDataPedc.Open;
    if unqryEmpDataPedc.Locate('CODIGO_EMP_EMP', sCodigo, []) then
    begin
      CopiarEmpresaaPedidoCompra(unqryEmpDataPedc);
      Result := True;
    end;
  end;
end;

procedure TdmPedidosCompra.CopiarEmpresaaPedidoCompra(DataSet: TDataSet);
begin
  with unqryTablaG do
  begin
    if (State <> dsEdit) and (State <> dsInsert) then
      Edit;
    FindField('CODIGO_EMP_PEDC').AsString :=
      DataSet.FindField('CODIGO_EMP_EMP').AsString;
    FindField('RAZON_SOCIAL_EMPRESA_PEDC').AsString :=
      DataSet.FindField('RAZON_SOCIAL_EMP').AsString;
    FindField('NIF_EMPRESA_PEDC').AsString :=
      DataSet.FindField('NIF_EMP').AsString;
    FindField('MOVIL_EMPRESA_PEDC').AsString :=
      DataSet.FindField('MOVIL_EMP').AsString;
    FindField('EMAIL_EMPRESA_PEDC').AsString :=
      DataSet.FindField('EMAIL_EMP').AsString;
    FindField('DIRECCION1_EMPRESA_PEDC').AsString :=
      DataSet.FindField('DIRECCION1_EMP').AsString;
    FindField('DIRECCION2_EMPRESA_PEDC').AsString :=
      DataSet.FindField('DIRECCION2_EMP').AsString;
    FindField('POBLACION_EMPRESA_PEDC').AsString :=
      DataSet.FindField('POBLACION_EMP').AsString;
    FindField('PROVINCIA_EMPRESA_PEDC').AsString :=
      DataSet.FindField('PROVINCIA_EMP').AsString;
    FindField('CODIGO_PAI_EMPRESA_PEDC').AsString :=
      DataSet.FindField('CODIGO_PAI_EMP').AsString;
    FindField('NOMBRE_PAI_EMPRESA_PEDC').AsString :=
      DataSet.FindField('NOMBRE_PAI_EMP').AsString;
    FindField('CODIGO_POSTAL_EMPRESA_PEDC').AsString :=
      DataSet.FindField('CODIGO_POSTAL_EMP').AsString;
  end;
end;

procedure TdmPedidosCompra.ValidarAlmacenCabecera;
begin
  if (unqryTablaG.FindField('CODIGO_ALM_PEDC') <> nil) and
     (Trim(unqryTablaG.FieldByName('CODIGO_ALM_PEDC').AsString) = '') then
  begin
    MessageDlg(SAvisoAlmacenDestinoPedidoCompraObligatorio,
               mtWarning, [mbOk], 0);
    Abort;
  end;
end;

procedure TdmPedidosCompra.unqryTablaGBeforePost(DataSet: TDataSet);
var
  i: Integer;
begin
  inherited;
  // Los campos calculados de vi_pedidos_compra (CANTIDAD_PEDIDA_PEDC,
  // TOTAL_LINEAS_PEDC...) llegan NOT NULL sin default y UniDAC los marca
  // Required: en el alta manual bloquean el Post con "must have a value".
  // No pertenecen a fza_pedidos_compra, asi que se apagan aqui (mismo
  // cinturon que usa Inventarios en su BeforePost).
  for i := 0 to DataSet.FieldCount - 1 do
    DataSet.Fields[i].Required := False;
  // En alta manual el pivote arranca vertical; se activa tras elegir
  // una linea con sistema de tallas.
  if (DataSet.FindField('ESPIVOTE_HORIZONTAL_PEDC') <> nil) and
     (Trim(DataSet.FieldByName('ESPIVOTE_HORIZONTAL_PEDC').AsString) = '') then
    DataSet.FieldByName('ESPIVOTE_HORIZONTAL_PEDC').AsString := 'N';
  ValidarAlmacenCabecera;
  if (unqryTablaG.FieldByName('NUMERO_PEDC').AsString = '0') or
     (unqryTablaG.FieldByName('NUMERO_PEDC').AsString = '') then
    GetCodigoAutoPedidoCompra;
  AplicarPorcentajesIvaCompra(ConexionPrincipal, unqryTablaG,
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
  // Reorganizacion en bloque en curso: se pospone al Finalizar.
  if FReorganizandoLineas > 0 then
    FReorganizacionPendiente := True
  else
    inLibPedidosCompra.GenerarPdteRecibirDesdePedido(
      ConexionPrincipal, sSerie, sNumero, IdentidadSesion.Usuario);
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
  if MessageDlg(Format(SPreguntaBorrarPedidoCompra,
                       [sSerie, sNumero]),
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
  begin
    Abort;
  end;
  inLibPedidosCompra.BorrarPdteRecibirDesdePedido(
    ConexionPrincipal, sSerie, sNumero);
  // Borrar lineas asociadas para que no se queden huerfanas (no hay
  // FK con CASCADE).
  with TUniQuery.Create(nil) do
  try
    Connection := ConexionPrincipal;
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
begin
  inherited;
  with unqryPedidosCompraLineas do
  begin
    FieldByName('NUMERO_PEDC_PEDCLIN').AsString :=
      unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
    FieldByName('SERIE_PEDC_PEDCLIN').AsString :=
      unqryTablaG.FieldByName('SERIE_PEDC').AsString;
    FieldByName('LINEA_PEDCLIN').AsString := '0000';
    FieldByName('CANTIDAD_PEDCLIN').AsFloat := 1;
    FieldByName('CANTIDAD_RECIBIDA_PEDCLIN').AsFloat := 0;
    // NOT NULL DEFAULT 0 en BBDD pero UniDAC la marca Required: sin
    // inicializarla, el Post de una linea nueva casca con "Field
    // CANTIDAD_A_RECIBIR_PEDCLIN must have a value" (p.ej. el post
    // forzado del detalle al grabar la cabecera al salir).
    if FindField('CANTIDAD_A_RECIBIR_PEDCLIN') <> nil then
      FieldByName('CANTIDAD_A_RECIBIR_PEDCLIN').AsFloat := 0;
    // Por defecto la linea hereda el almacen de la cabecera; el usuario
    // puede sobreescribirlo si quiere mezclar lineas de varios almacenes.
    if FindField('CODIGO_ALMACEN_PEDCLIN') <> nil then
      FieldByName('CODIGO_ALMACEN_PEDCLIN').AsString :=
        unqryTablaG.FieldByName('CODIGO_ALM_PEDC').AsString;
    FieldByName('USUARIO_ALTA').AsString    := IdentidadSesion.Usuario;
    FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    FieldByName('USUARIO_MODIF').AsString   := IdentidadSesion.Usuario;
    FieldByName('INSTANTE_MODIF').AsDateTime:= Now;
  end;
end;

procedure TdmPedidosCompra.unqryPedidosCompraLineasBeforePost(
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
  AsignarNumeroLineaPedidoCompra(DataSet);
  with unqryPedidosCompraLineas do
  begin
    // Acepta articulo, SKU, codigo de barras o referencia de proveedor.
    NormalizarArticuloSkuEnDataSet(ConexionPrincipal,
      unqryPedidosCompraLineas, 'CODIGO_ART_PEDCLIN',
      'CODIGO_UNIDAD_PEDCLIN');
    if (FindField('CANTIDAD_PEDCLIN') <> nil) and
       (FindField('PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN') <> nil) and
       (FindField('TOTAL_PEDCLIN') <> nil) then
      FieldByName('TOTAL_PEDCLIN').AsFloat :=
        FieldByName('CANTIDAD_PEDCLIN').AsFloat *
        FieldByName('PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN').AsFloat;
    if FindField('USUARIO_MODIF') <> nil then
      FieldByName('USUARIO_MODIF').AsString   := IdentidadSesion.Usuario;
    if FindField('INSTANTE_MODIF') <> nil then
      FieldByName('INSTANTE_MODIF').AsDateTime:= Now;
    if (DataSet.State = dsInsert) then
    begin
      if (FindField('USUARIO_ALTA') <> nil) and
         (FieldByName('USUARIO_ALTA').AsString = '') then
        FieldByName('USUARIO_ALTA').AsString := IdentidadSesion.Usuario;
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
    PrepararLineaFiscalCompra(ConexionPrincipal, unqryTablaG,
      unqryPedidosCompraLineas, 'PEDC', 'PEDCLIN', 'TOTAL_PEDCLIN');
  end;
end;

procedure TdmPedidosCompra.AsignarNumeroLineaPedidoCompra(DataSet: TDataSet);
var
  iNuevaLinea: Integer;
  sLinea: string;
  sNumero: string;
  sSerie: string;
begin
  if DataSet.FindField('LINEA_PEDCLIN') <> nil then
  begin
    sLinea := Trim(DataSet.FieldByName('LINEA_PEDCLIN').AsString);
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_PEDC').AsString);
    sSerie  := Trim(unqryTablaG.FieldByName('SERIE_PEDC').AsString);
    if (sLinea = '') or (StrToIntDef(sLinea, 0) = 0) or
       ((DataSet.State = dsInsert) and
        LineaDocExiste(ConexionPrincipal, LIN_PEDIDOS_COMPRA, sSerie,
          sNumero, sLinea)) then
    begin
      if (sNumero = '') or (sNumero = '0') or (sSerie = '') then
        raise Exception.Create(SErrorCabeceraPedidoSinGrabar);
      if DataSet.FindField('NUMERO_PEDC_PEDCLIN') <> nil then
        DataSet.FieldByName('NUMERO_PEDC_PEDCLIN').AsString := sNumero;
      if DataSet.FindField('SERIE_PEDC_PEDCLIN') <> nil then
        DataSet.FieldByName('SERIE_PEDC_PEDCLIN').AsString := sSerie;
      iNuevaLinea := GetSiguienteLineaDocLibre(ConexionPrincipal,
        CONT_PEDIDOS_COMPRA, LIN_PEDIDOS_COMPRA, sSerie, sNumero);
      if iNuevaLinea = 0 then
      begin
        iNuevaLinea := StrToIntDef(
          unqryTablaG.FieldByName('CONTADOR_LINEAS_PEDC').AsString, 0) + 10;
      end;
      if unqryTablaG.FindField('CONTADOR_LINEAS_PEDC') <> nil then
      begin
        if not (unqryTablaG.State in [dsEdit, dsInsert]) then
          unqryTablaG.Edit;
        unqryTablaG.FieldByName('CONTADOR_LINEAS_PEDC').AsString :=
          Format('%.8d', [iNuevaLinea]);
      end;
      DataSet.FieldByName('LINEA_PEDCLIN').AsString :=
        Format('%.4d', [iNuevaLinea]);
    end;
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
  // (cantidad de la linea puede haber cambiado). Durante la
  // reorganizacion del modo de entrada se pospone al Finalizar:
  // regenerar TODO el pedido por cada linea multiplica el coste.
  sSerie  := unqryTablaG.FieldByName('SERIE_PEDC').AsString;
  sNumero := unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
  if (sSerie = '') or (sNumero = '') then Exit;
  if FReorganizandoLineas > 0 then
    FReorganizacionPendiente := True
  else
    inLibPedidosCompra.GenerarPdteRecibirDesdePedido(
      ConexionPrincipal, sSerie, sNumero, IdentidadSesion.Usuario);
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
    ConexionPrincipal, sSerie, sNumero, sLinea);
end;

function TdmPedidosCompra.ObtenerAlmacenesSql(
                                            const AAlmacenesCsv: string):
                                            string;
var
  i: Integer;
  lstCod: TStringList;
  sCod: string;
begin
  Result := '';
  if Trim(AAlmacenesCsv) <> '' then
  begin
    lstCod := TStringList.Create;
    try
      lstCod.StrictDelimiter := True;
      lstCod.Delimiter       := ',';
      lstCod.DelimitedText   := AAlmacenesCsv;
      for i := 0 to lstCod.Count - 1 do
      begin
        sCod := Trim(lstCod[i]);
        if sCod <> '' then
        begin
          if Result <> '' then
            Result := Result + ',';
          Result := Result + QuotedStr(sCod);
        end;
      end;
    finally
      FreeAndNil(lstCod);
    end;
  end;
end;

procedure TdmPedidosCompra.CargarAlmacenesDelPedido(
                                      const ASerie, ANumero: string;
                                      ALV: TObject);
const
  cAlmacenEf =
    'COALESCE(NULLIF(C.CODIGO_ALM_PEDCCEL, ''''), ' +
    '         NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), ' +
    '         NULLIF(P.CODIGO_ALM_PEDC, ''''))';
var
  oQry: TUniQuery;
  oLv: TcxListView;
  oItem: TListItem;
begin
  if not (ALV is TcxListView) then
    Exit;
  oLv := TcxListView(ALV);
  oLv.Items.BeginUpdate;
  try
    oLv.Items.Clear;
    oQry := TUniQuery.Create(nil);
    try
      oQry.Connection := ConexionPrincipal;
      oQry.SQL.Text :=
        'SELECT X.COD, COALESCE(A.NOMBRE_ALM_ALM, X.COD) AS NOM ' +
        '  FROM ( ' +
        '        SELECT DISTINCT ' + cAlmacenEf + ' AS COD ' +
        '          FROM fza_pedidos_compra_lineas L ' +
        '          JOIN fza_pedidos_compra P ' +
        '            ON P.SERIE_PEDC  = L.SERIE_PEDC_PEDCLIN ' +
        '           AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
        // LINEA de celda sin relleno ('10') vs LINEA de linea rellena
        // ('0010'): el cruce varchar-varchar fallaba como texto, el
        // valor se compara en numerico (cantidades desorbitadas,
        // 10/07/26).
        '          LEFT JOIN fza_pedidos_compra_celdas C ' +
        '            ON C.SERIE_PEDC_PEDCCEL = L.SERIE_PEDC_PEDCLIN ' +
        '           AND C.NUMERO_PEDC_PEDCCEL = L.NUMERO_PEDC_PEDCLIN ' +
        '           AND CAST(C.LINEA_PEDC_PEDCCEL AS UNSIGNED) = ' +
        '               CAST(L.LINEA_PEDCLIN AS UNSIGNED) ' +
        '         WHERE L.SERIE_PEDC_PEDCLIN = :s ' +
        '           AND L.NUMERO_PEDC_PEDCLIN = :n ' +
        '       ) X ' +
        '  LEFT JOIN fza_almacenes A ON A.CODIGO_ALM_ALM = X.COD ' +
        ' WHERE COALESCE(X.COD, '''') <> '''' ' +
        ' ORDER BY X.COD';
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

function TdmPedidosCompra.ObtenerSkusPedidoCsv(const ASerie, ANumero,
                                               AAlmacenesCsv: string):
                                               string;
const
  cAlmacenEf =
    'COALESCE(NULLIF(C.CODIGO_ALM_PEDCCEL, ''''), ' +
    '         NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), ' +
    '         NULLIF(P.CODIGO_ALM_PEDC, ''''))';
var
  oQry: TUniQuery;
  sAlmacenes: string;
begin
  Result := '';
  sAlmacenes := ObtenerAlmacenesSql(AAlmacenesCsv);
  oQry := TUniQuery.Create(nil);
  try
    oQry.Connection := ConexionPrincipal;
    oQry.SQL.Text :=
      'SELECT DISTINCT L.CODIGO_UNIDAD_PEDCLIN ' +
      '  FROM fza_pedidos_compra_lineas L ' +
      '  JOIN fza_pedidos_compra P ' +
      '    ON P.SERIE_PEDC  = L.SERIE_PEDC_PEDCLIN ' +
      '   AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
      // Cruce de LINEA en numerico: celda '10' vs linea '0010'.
      '  LEFT JOIN fza_pedidos_compra_celdas C ' +
      '    ON C.SERIE_PEDC_PEDCCEL = L.SERIE_PEDC_PEDCLIN ' +
      '   AND C.NUMERO_PEDC_PEDCCEL = L.NUMERO_PEDC_PEDCLIN ' +
      '   AND CAST(C.LINEA_PEDC_PEDCCEL AS UNSIGNED) = ' +
      '       CAST(L.LINEA_PEDCLIN AS UNSIGNED) ' +
      ' WHERE L.SERIE_PEDC_PEDCLIN = :s ' +
      '   AND L.NUMERO_PEDC_PEDCLIN = :n ' +
      '   AND COALESCE(L.CODIGO_UNIDAD_PEDCLIN, '''') <> ''''';
    if sAlmacenes <> '' then
      oQry.SQL.Add('   AND ' + cAlmacenEf + ' IN (' + sAlmacenes + ')');
    oQry.SQL.Add(' ORDER BY L.CODIGO_UNIDAD_PEDCLIN');
    oQry.ParamByName('s').AsString := ASerie;
    oQry.ParamByName('n').AsString := ANumero;
    oQry.Open;
    while not oQry.Eof do
    begin
      if Result <> '' then
        Result := Result + ',';
      Result := Result + QuotedStr(
        oQry.FieldByName('CODIGO_UNIDAD_PEDCLIN').AsString);
      oQry.Next;
    end;
  finally
    FreeAndNil(oQry);
  end;
end;

procedure TdmPedidosCompra.ExpandirEtiquetasPorCantidadPed(ADmArt: TObject;
                                  const ASerie, ANumero,
                                        AAlmacenesCsv: string);
const
  cAlmacenCel =
    'COALESCE(NULLIF(C.CODIGO_ALM_PEDCCEL, ''''), ' +
    '         NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), ' +
    '         NULLIF(P.CODIGO_ALM_PEDC, ''''))';
  cAlmacenLin =
    'COALESCE(NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), ' +
    '         NULLIF(P.CODIGO_ALM_PEDC, ''''))';
var
  oQry: TUniQuery;
  oDmArt: TdmArticulos;
  oCantidades: TDictionary<string, Integer>;
  Filas: array of array of Variant;
  i, j, k, iOriginales, iSkuIdx, iStockIdx, iCantidad: Integer;
  sAlmacenes, sSku: string;
begin
  if ADmArt is TdmArticulos then
  begin
    oDmArt := TdmArticulos(ADmArt);
    oCantidades := TDictionary<string, Integer>.Create;
    try
      oQry := TUniQuery.Create(nil);
      try
        oQry.Connection := ConexionPrincipal;
        sAlmacenes := ObtenerAlmacenesSql(AAlmacenesCsv);
        oQry.SQL.Text :=
          'SELECT X.SKU, SUM(X.CANTIDAD) AS CANTIDAD ' +
          '  FROM ( ' +
          '        SELECT L.CODIGO_UNIDAD_PEDCLIN AS SKU, ' +
          '               COALESCE(C.CANTIDAD_PEDCCEL, 0) AS CANTIDAD ' +
          '          FROM fza_pedidos_compra_lineas L ' +
          '          JOIN fza_pedidos_compra P ' +
          '            ON P.SERIE_PEDC  = L.SERIE_PEDC_PEDCLIN ' +
          '           AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
          // Cruce de LINEA en numerico: celda '10' vs linea '0010'.
          '          JOIN fza_pedidos_compra_celdas C ' +
          '            ON C.SERIE_PEDC_PEDCCEL = L.SERIE_PEDC_PEDCLIN ' +
          '           AND C.NUMERO_PEDC_PEDCCEL = L.NUMERO_PEDC_PEDCLIN ' +
          '           AND CAST(C.LINEA_PEDC_PEDCCEL AS UNSIGNED) = ' +
          '               CAST(L.LINEA_PEDCLIN AS UNSIGNED) ' +
          '         WHERE L.SERIE_PEDC_PEDCLIN = :s ' +
          '           AND L.NUMERO_PEDC_PEDCLIN = :n ' +
          '           AND COALESCE(L.CODIGO_UNIDAD_PEDCLIN, '''') <> '''' ' +
          '           AND COALESCE(C.CANTIDAD_PEDCCEL, 0) > 0 ';
        if sAlmacenes <> '' then
          oQry.SQL.Add('           AND ' + cAlmacenCel +
                       ' IN (' + sAlmacenes + ')');
        oQry.SQL.Add(
          '        UNION ALL ' +
          '        SELECT L.CODIGO_UNIDAD_PEDCLIN AS SKU, ' +
          '               COALESCE(L.CANTIDAD_PEDCLIN, 0) AS CANTIDAD ' +
          '          FROM fza_pedidos_compra_lineas L ' +
          '          JOIN fza_pedidos_compra P ' +
          '            ON P.SERIE_PEDC  = L.SERIE_PEDC_PEDCLIN ' +
          '           AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
          '         WHERE L.SERIE_PEDC_PEDCLIN = :s ' +
          '           AND L.NUMERO_PEDC_PEDCLIN = :n ' +
          '           AND COALESCE(L.CODIGO_UNIDAD_PEDCLIN, '''') <> '''' ' +
          '           AND COALESCE(L.CANTIDAD_PEDCLIN, 0) > 0 ' +
          '           AND NOT EXISTS ( ' +
          '             SELECT 1 ' +
          '               FROM fza_pedidos_compra_celdas C0 ' +
          '              WHERE C0.SERIE_PEDC_PEDCCEL = ' +
          '                    L.SERIE_PEDC_PEDCLIN ' +
          '                AND C0.NUMERO_PEDC_PEDCCEL = ' +
          '                    L.NUMERO_PEDC_PEDCLIN ' +
          '                AND CAST(C0.LINEA_PEDC_PEDCCEL AS UNSIGNED) ' +
          '                    = CAST(L.LINEA_PEDCLIN AS UNSIGNED) ' +
          '           ) ');
        if sAlmacenes <> '' then
          oQry.SQL.Add('           AND ' + cAlmacenLin +
                       ' IN (' + sAlmacenes + ')');
        oQry.SQL.Add(
          '       ) X ' +
          ' GROUP BY X.SKU');
        oQry.ParamByName('s').AsString := ASerie;
        oQry.ParamByName('n').AsString := ANumero;
        oQry.Open;
        while not oQry.Eof do
        begin
          iCantidad := Trunc(oQry.FieldByName('CANTIDAD').AsFloat);
          sSku := oQry.FieldByName('SKU').AsString;
          if (sSku <> '') and (iCantidad > 0) then
            oCantidades.AddOrSetValue(sSku, iCantidad);
          oQry.Next;
        end;
      finally
        FreeAndNil(oQry);
      end;
      if oDmArt.cdsEtiquetasArt.Active then
      begin
        if (not oDmArt.cdsEtiquetasArt.IsEmpty) and
           (oDmArt.cdsEtiquetasArt.FindField('CODIGO_UNIDAD_SKU') <> nil) then
        begin
          iSkuIdx := oDmArt.cdsEtiquetasArt.FieldByName(
            'CODIGO_UNIDAD_SKU').Index;
          iStockIdx := -1;
          if oDmArt.cdsEtiquetasArt.FindField('STOCK_FILTRADO') <> nil then
            iStockIdx := oDmArt.cdsEtiquetasArt.FieldByName(
              'STOCK_FILTRADO').Index;
          oDmArt.cdsEtiquetasArt.DisableControls;
          oDmArt.cdsEtiquetasArt.DisableConstraints;
          try
            for j := 0 to oDmArt.cdsEtiquetasArt.FieldCount - 1 do
            begin
              oDmArt.cdsEtiquetasArt.Fields[j].ReadOnly := False;
              oDmArt.cdsEtiquetasArt.Fields[j].Required := False;
            end;
            iOriginales := oDmArt.cdsEtiquetasArt.RecordCount;
            SetLength(Filas, iOriginales);
            oDmArt.cdsEtiquetasArt.First;
            for i := 0 to iOriginales - 1 do
            begin
              SetLength(Filas[i], oDmArt.cdsEtiquetasArt.FieldCount);
              for j := 0 to oDmArt.cdsEtiquetasArt.FieldCount - 1 do
                Filas[i][j] := oDmArt.cdsEtiquetasArt.Fields[j].Value;
              oDmArt.cdsEtiquetasArt.Next;
            end;
            oDmArt.cdsEtiquetasArt.EmptyDataSet;
            for i := 0 to iOriginales - 1 do
            begin
              sSku := VarToStr(Filas[i][iSkuIdx]);
              if oCantidades.TryGetValue(sSku, iCantidad) then
              begin
                for k := 1 to iCantidad do
                begin
                  oDmArt.cdsEtiquetasArt.Append;
                  for j := 0 to oDmArt.cdsEtiquetasArt.FieldCount - 1 do
                    oDmArt.cdsEtiquetasArt.Fields[j].Value := Filas[i][j];
                  if iStockIdx >= 0 then
                    oDmArt.cdsEtiquetasArt.Fields[iStockIdx].AsInteger :=
                      iCantidad;
                  oDmArt.cdsEtiquetasArt.Post;
                end;
              end;
            end;
          finally
            oDmArt.cdsEtiquetasArt.EnableConstraints;
            oDmArt.cdsEtiquetasArt.EnableControls;
          end;
        end
        else
          oDmArt.cdsEtiquetasArt.EmptyDataSet;
      end;
    finally
      oCantidades.Free;
    end;
  end;
end;

procedure TdmPedidosCompra.CrearDataSetEtiquetasPed(ADmArt: TObject;
                                  const ASerie, ANumero,
                                        ACodTarifa, AAlmacenesCsv: string;
                                  AFecha: TDateTime);
var
  oDmArt: TdmArticulos;
  sSkus: string;
begin
  if ADmArt is TdmArticulos then
  begin
    oDmArt := TdmArticulos(ADmArt);
    sSkus := ObtenerSkusPedidoCsv(ASerie, ANumero, AAlmacenesCsv);
    if sSkus <> '' then
    begin
      oDmArt.CrearDataSetEtiquetasArt('', ACodTarifa, '', AFecha, sSkus);
      ExpandirEtiquetasPorCantidadPed(oDmArt, ASerie, ANumero,
                                       AAlmacenesCsv);
    end
    else
      oDmArt.CrearDataSetEtiquetasArt('DUMMY_SIN_LINEAS',
                                      ACodTarifa, '', AFecha);
  end;
end;

procedure TdmPedidosCompra.GetCodigoAutoPedidoCompra;
var
  iNumero: Int64;
  sNumero: string;
begin
  with unstrdprcGetContadorPedc do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'pserie',            ptInput);
    Params.CreateParam(ftString, 'ptipodoc',          ptInput);
    Params.CreateParam(ftString, 'pEMPRESA_CONTADOR', ptInput);
    Params.CreateParam(ftString, 'pUSUARIOMODIF',     ptInput);
    Params.CreateParam(ftString, 'pcont',             ptOutput);
    ParamByName('pserie').AsString :=
      unqryTablaG.FieldByName('SERIE_PEDC').AsString;
    ParamByName('ptipodoc').AsString := 'PC';
    ParamByName('pUSUARIOMODIF').AsString := IdentidadSesion.Usuario;
    ParamByName('pEMPRESA_CONTADOR').AsString :=
      unqryTablaG.FieldByName('CODIGO_EMP_PEDC').AsString;
    ExecProc;
    sNumero := Trim(ParamByName('pcont').AsString);
    if (sNumero = '') or (not TryStrToInt64(sNumero, iNumero)) or
       (iNumero <= 0) then
      raise Exception.Create(Format(SErrorContadorPedidoCompra,
        [unqryTablaG.FieldByName('SERIE_PEDC').AsString,
         unqryTablaG.FieldByName('CODIGO_EMP_PEDC').AsString]));
    unqryTablaG.FieldByName('NUMERO_PEDC').AsString := sNumero;
  end;
end;

procedure TdmPedidosCompra.DesempaquetarAtributosLineas;
var
  Partes: TArray<string>;
  Sku, sEsperado: string;
  i: Integer;
  Bm: TBookmark;
  bCambia: Boolean;
begin
  if unqryPedidosCompraLineas.Active and
     (not unqryPedidosCompraLineas.IsEmpty) and
     (unqryPedidosCompraLineas.FindField('ATTR1_VALOR_PEDCLIN') <> nil) and
     (unqryPedidosCompraLineas.FindField('NUM_ATRIBUTOS_PEDCLIN') <> nil) and
     (not unqryPedidosCompraLineas.ReadOnly) then
  begin
    Bm := unqryPedidosCompraLineas.GetBookmark;
    unqryPedidosCompraLineas.DisableControls;
    // Posts descriptivos: silencia la logica fiscal en BeforePost y
    // CalcularTotales.
    FDesempaquetandoAtributos := True;
    try
      unqryPedidosCompraLineas.First;
      while not unqryPedidosCompraLineas.Eof do
      begin
        Sku := unqryPedidosCompraLineas.FieldByName(
          'CODIGO_UNIDAD_PEDCLIN').AsString;
        Partes := Sku.Split(['/']);
        if Length(Partes) > 1 then
        begin
          // Idempotente POR COMPARACION (mismo criterio que ventas).
          bCambia := unqryPedidosCompraLineas.FieldByName(
            'NUM_ATRIBUTOS_PEDCLIN').AsInteger <> Length(Partes) - 1;
          for i := 1 to 5 do
          begin
            if i < Length(Partes) then
              sEsperado := Partes[i]
            else
              sEsperado := '';
            if Trim(unqryPedidosCompraLineas.FieldByName('ATTR' +
                 IntToStr(i) + '_VALOR_PEDCLIN').AsString) <>
               sEsperado then
              bCambia := True;
          end;
          if bCambia then
          begin
            unqryPedidosCompraLineas.Edit;
            unqryPedidosCompraLineas.FieldByName(
              'NUM_ATRIBUTOS_PEDCLIN').AsInteger := Length(Partes) - 1;
            for i := 1 to 5 do
            begin
              if i < Length(Partes) then
                unqryPedidosCompraLineas.FieldByName('ATTR' +
                  IntToStr(i) + '_VALOR_PEDCLIN').AsString := Partes[i]
              else
                unqryPedidosCompraLineas.FieldByName('ATTR' +
                  IntToStr(i) + '_VALOR_PEDCLIN').AsString := '';
            end;
            unqryPedidosCompraLineas.Post;
          end;
        end;
        unqryPedidosCompraLineas.Next;
      end;
      if unqryPedidosCompraLineas.BookmarkValid(Bm) then
        unqryPedidosCompraLineas.GotoBookmark(Bm);
    finally
      FDesempaquetandoAtributos := False;
      unqryPedidosCompraLineas.EnableControls;
      unqryPedidosCompraLineas.FreeBookmark(Bm);
    end;
  end;
end;

procedure TdmPedidosCompra.CalcularTotalesPedidoCompra;
var
  oCampoPrendas: TField;
  rPrendas: Double;
begin
  // Los posts del desempaquetado ATTR no alteran importes: saltar el
  // recalculo por linea (cascada de consultas de IVA al navegar).
  if FDesempaquetandoAtributos then
    Exit;
  // Reorganizacion en bloque en curso: un unico recalculo al Finalizar
  // (cada pasada consulta el IVA articulo a articulo y edita la
  // cabecera, forzando posts encadenados del master-detail).
  if FReorganizandoLineas > 0 then
  begin
    FReorganizacionPendiente := True;
    Exit;
  end;
  if not FCalculandoTotales then
  begin
    FCalculandoTotales := True;
    try
      CalcularTotalesDocumentoCompra(ConexionPrincipal, unqryTablaG,
        unqryPedidosCompraLineas, 'PEDC', 'TOTAL_PEDCLIN',
        'TIPO_IVA_ARTICULO_PEDCLIN', 'PORCENTAJE_IVA_PEDCLIN');
      // Nº de prendas: TOTAL_PRENDAS_PEDC es columna calculada de la
      // vista (SUM de CANTIDAD_PEDCLIN) y solo se lee al abrir la
      // cabecera. Se replica aqui en cliente para refrescarla al
      // momento. No esta en el SQLUpdate explicito de la cabecera,
      // asi que nunca viaja a BBDD.
      oCampoPrendas := unqryTablaG.FindField('TOTAL_PRENDAS_PEDC');
      if oCampoPrendas <> nil then
      begin
        rPrendas := TotalPrendasLineasCompra(unqryPedidosCompraLineas,
          'TIPO_IVA_ARTICULO_PEDCLIN');
        if oCampoPrendas.IsNull or
           (Abs(oCampoPrendas.AsFloat - rPrendas) > 0.000001) then
        begin
          if not (unqryTablaG.State in [dsEdit, dsInsert]) then
            unqryTablaG.Edit;
          oCampoPrendas.AsFloat := rPrendas;
        end;
      end;
    finally
      FCalculandoTotales := False;
    end;
  end;
end;

procedure TdmPedidosCompra.IniciarReorganizacionLineas;
begin
  Inc(FReorganizandoLineas);
end;

procedure TdmPedidosCompra.FinalizarReorganizacionLineas;
var
  sSerie, sNumero: string;
begin
  if FReorganizandoLineas > 0 then
    Dec(FReorganizandoLineas);
  if FReorganizandoLineas = 0 then
  begin
    // La reorganizacion escribe lineas y celdas por SQL directo: sin
    // reabrir el detalle, el grid y el pivote publican datos rancios
    // (tallas vacias hasta reconstruir el modo con F1). Antes lo
    // "arreglaban" las reaperturas en cascada del master-detail.
    if unqryPedidosCompraLineas.Active then
    begin
      unqryPedidosCompraLineas.Close;
      unqryPedidosCompraLineas.Open;
    end;
    // Si hubo posts pospuestos, recalcular totales y regenerar los
    // pendientes de recibir UNA sola vez (ya con datos frescos).
    if FReorganizacionPendiente then
    begin
      FReorganizacionPendiente := False;
      CalcularTotalesPedidoCompra;
      sSerie  := unqryTablaG.FieldByName('SERIE_PEDC').AsString;
      sNumero := unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
      if (sSerie <> '') and (sNumero <> '') then
        inLibPedidosCompra.GenerarPdteRecibirDesdePedido(
          ConexionPrincipal, sSerie, sNumero, IdentidadSesion.Usuario);
    end;
  end;
end;

function TdmPedidosCompra.EnReorganizacionLineas: Boolean;
begin
  Result := FReorganizandoLineas > 0;
end;

function TdmPedidosCompra.AbortarReorganizacionLineas: Boolean;
begin
  if FReorganizandoLineas > 0 then
    Dec(FReorganizandoLineas);
  Result := FReorganizacionPendiente;
  FReorganizacionPendiente := False;
end;

procedure TdmPedidosCompra.SincronizarPdteRecibir;
var
  sSerie, sNumero: string;
begin
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
  begin
    sSerie  := unqryTablaG.FieldByName('SERIE_PEDC').AsString;
    sNumero := unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
    if (sSerie <> '') and (sNumero <> '') then
      inLibPedidosCompra.GenerarPdteRecibirDesdePedido(
        ConexionPrincipal, sSerie, sNumero, IdentidadSesion.Usuario);
  end;
end;

function TdmPedidosCompra.HayLineasSinPivotar: Boolean;
var
  q: TUniQuery;
begin
  Result := False;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionPrincipal;
      // El cruce de LINEA va en NUMERICO: la celda guarda '10' (el
      // parametro entra como entero) y la linea '0010'; como texto
      // nunca casaban, TODA linea con SKU contaba como sin pivotar y
      // cada entrada al grid reconstruia el documento entero
      // (expansion + fusion: tormenta de SQL por click, 10/07/26).
      // Solo cuentan articulos CON variacion: uno sin tallas jamas
      // tendra celdas y forzaria la reconstruccion eterna.
      q.SQL.Text :=
        'SELECT 1 ' +
        '  FROM fza_pedidos_compra_lineas L ' +
        '  JOIN fza_articulos A ' +
        '    ON A.CODIGO_ART_ART = L.CODIGO_ART_PEDCLIN ' +
        ' WHERE L.SERIE_PEDC_PEDCLIN  = :s ' +
        '   AND L.NUMERO_PEDC_PEDCLIN = :n ' +
        '   AND COALESCE(L.CODIGO_UNIDAD_PEDCLIN, '''') <> '''' ' +
        '   AND IFNULL(A.ESVARIACION_ART, ''N'') = ''S'' ' +
        '   AND NOT EXISTS (SELECT 1 ' +
        '                     FROM fza_pedidos_compra_celdas C ' +
        '                    WHERE C.SERIE_PEDC_PEDCCEL  = ' +
        '                          L.SERIE_PEDC_PEDCLIN ' +
        '                      AND C.NUMERO_PEDC_PEDCCEL = ' +
        '                          L.NUMERO_PEDC_PEDCLIN ' +
        '                      AND CAST(C.LINEA_PEDC_PEDCCEL ' +
        '                               AS UNSIGNED) = ' +
        '                          CAST(L.LINEA_PEDCLIN AS UNSIGNED)) ' +
        ' LIMIT 1';
      q.ParamByName('s').AsString :=
        unqryTablaG.FieldByName('SERIE_PEDC').AsString;
      q.ParamByName('n').AsString :=
        unqryTablaG.FieldByName('NUMERO_PEDC').AsString;
      q.Open;
      Result := not q.Eof;
    finally
      FreeAndNil(q);
    end;
  end;
end;

end.
