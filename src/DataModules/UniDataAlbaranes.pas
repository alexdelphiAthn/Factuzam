{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAlbaranes                                              }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de albaranes.                                                 }
{    Queries de cabecera y líneas, generación de facturas y movimientos de     }
{    stock asociados.                                                          }
{******************************************************************************}
unit UniDataAlbaranes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, inLibUser,
  frxClass, frxDBSet, frCoreClasses;

type
  TdmAlbaranes = class(TdmBase)
    unqryAlbaranesLineas: TUniQuery;
    dsAlbaranesLineas:    TDataSource;
    unqryEmpDataAlb:      TUniQuery;
    unqryCliDataAlb:      TUniQuery;
    unqryArtDataLinAlb:   TUniQuery;
    unqrySkusAlb:         TUniQuery;
    unqryFacturas:        TUniQuery;
    dsFacturas:           TDataSource;
    unqryMovimientosAlb:  TUniQuery;
    dsMovimientosAlb:     TDataSource;
    unqryFormasPago:      TUniQuery;
    dsFormasPago:         TDataSource;
    unqryAlmacenesAlb:    TUniQuery;
    dsAlmacenesAlb:       TDataSource;
    unqryTarifas:         TUniQuery;
    dsTarifas:            TDataSource;
    unstrdprcGetContadorAlbaran: TUniStoredProc;
    unstrdprcCrearFacturaInicio: TUniStoredProc;
    unstrdprcCrearFacturaLinea:  TUniStoredProc;
    unstrdprcCrearFacturaFin:    TUniStoredProc;
    unstrdprcInsertarMovAlb:     TUniStoredProc;
    fxdsPrintAlb:    TfrxDBDataset;
    fxdstPrintLinAlb:TfrxDBDataset;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryAlbaranesLineasAfterInsert(DataSet: TDataSet);
    procedure unqryAlbaranesLineasBeforePost(DataSet: TDataSet);
    procedure unqryAlbaranesLineasAfterPost(DataSet: TDataSet);
    procedure unqryAlbaranesLineasAfterDelete(DataSet: TDataSet);
  public
    // Contrato ColumnSKUcxGrid: rellena ATTR1..5_VALOR_ALBLIN y
    // NUM_ATRIBUTOS_ALBLIN troceando el SKU (CODIGO_UNIDAD_ALBLIN) de
    // cada linea. Idempotente POR COMPARACION: solo edita las lineas
    // cuyos ATTR no coinciden con el troceo (leccion de pedidos).
    procedure DesempaquetarAtributosLineas;
    procedure GetCodigoAutoAlbaran;
    procedure CalcularTotalesAlbaran;
    // Numero total de prendas (suma CANTIDAD_ALBLIN de todas las lineas).
    // Se muestra en la pestana Totales; no se persiste en BBDD.
    function TotalPrendasAlbaran: Double;
    procedure CopiarEmpresaaAlbaran(DataSet: TDataSet);
    procedure CopiarClienteaAlbaran(DataSet: TDataSet);
    function BuscarEmpresa(const ACodigo: string): Boolean;
    function BuscarAlmacen(const ACodigo: string): Boolean;
    function BuscarCliente(const ACodigo: string): Boolean;
    procedure OpenTables;
    procedure RefrescarAlmacenes(const ACodigoEmpresa: string);
    procedure ActualizarImpuestosTarifaCabecera(
      const ACodigoTarifa: string);
    // Override: abre las queries detalle del Mto de Albaranes tras
    // unqryTablaG. Invocada desde TfrmMtoGen.AbrirTablaPrincipalAsync
    // en el callback main thread. OpenTables delega aqui.
    procedure AbrirDetalles; override;

    // Procedimientos de facturación: instalación idempotente.
    procedure InstalarProcedimientos;

    // Genera factura del albarán cargado en pantalla con las líneas indicadas.
    // Si aLineas es nil, se facturan todas las líneas no facturadas del
    // albarán.
    function CrearFacturaDesdeAlbaran(out sNumeroFac, sSerieFac: string;
                                      aLineas: TList<string>): Boolean;

    // Procesa una lista de albaranes (formato 'SERIE|NUMERO') y genera
    // factura(s).
    // Si bAgruparPorCliente es True, agrupa los albaranes del mismo cliente
    // en una única factura. Devuelve número de facturas generadas.
    function FacturarAlbaranesLista(aListaAlbaranes: TStrings;
                                    bAgruparPorCliente: Boolean): Integer;

    // Genera los movimientos de salida de stock asociados a las líneas del
    // albarán cargado. Idempotente: prepara almacén/SKU/línea antes de
    // regenerar y salta líneas que no puedan mover stock.
    // Devuelve el número de movimientos creados.
    function GenerarMovimientosSalida: Integer;
  private
    FProcsInstalados: Boolean;
    FCalculandoTotales: Boolean;
    // True mientras DesempaquetarAtributosLineas postea lineas: cambio
    // puramente descriptivo que NO debe disparar la logica fiscal ni
    // la sincronizacion de movimientos (cascada por linea al navegar).
    FDesempaquetandoAtributos: Boolean;
    procedure ProcesarCabeceraPosteada;
    procedure ProcesarLineasPosteadas;
    procedure NegarMovimientosFacturaDesdeAlbaran(const ASerie,
                                                  ANumero: string);
    procedure AsignarNumeroLineaAlbaran(DataSet: TDataSet);
    procedure NormalizarCamposOpcionalesLinea(DataSet: TDataSet);
    function ResolverSkuMovimientoSalida(const ACodigoArticulo: string): string;
    procedure PrepararLineasMovimientoSalida(const ASerie, ANumero,
                                             AAlmacenCabecera: string);
    procedure SincronizarAlmacenLinea(DataSet: TDataSet);
    procedure SincronizarAlmacenLineasCabecera;
    procedure ValidarAlmacenCabecera;
    procedure BorrarMovimientosSalida;
    procedure SincronizarMovimientosSalida;
    // Propone la serie AV de fza_empresas_series de la empresa emisora
    // en documentos nuevos sin numerar (al cambiar la empresa en el alta)
    procedure ProponerSerieEmpresa(const AEmpresa: string);
  end;

implementation

uses
  inLibValoresAutomaticos, inLibLog, System.Diagnostics,
  System.UITypes, Vcl.Dialogs, inLibArticulosValidadorIntf,
  UniDataArticulosValidadorRepositorio,
  inLibVentasImpuestos, inLibContadorLineas, inLibData,
  inLibMsgArticulos, inLibMsgFacturas, inLibMsgVentas,
  inLibSqlSeguro;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

const
  // Columnas REALES de fza_albaranes. La cabecera se lee de
  // vi_albaranes (que anade NOMBRE_ALM_ALB por join y NO es
  // insertable): los DML se generan contra la tabla, como hace
  // pedidos con fza_pedidos en su dfm.
  COLUMNAS_ALBARAN: array[0..69] of string = (
    'NUMERO_ALB', 'SERIE_ALB', 'FECHA_ALB', 'ESCONSOLIDADO_ALB',
    'ESTADO_ALB', 'NUMERO_PED_ALB', 'SERIE_PED_ALB', 'NUMERO_FAC_ALB',
    'SERIE_FAC_ALB', 'CODIGO_EMP_ALB', 'CODIGO_ALM_ALB',
    'RAZON_SOCIAL_EMPRESA_ALB', 'NIF_EMPRESA_ALB', 'MOVIL_EMPRESA_ALB',
    'EMAIL_EMPRESA_ALB', 'DIRECCION1_EMPRESA_ALB',
    'DIRECCION2_EMPRESA_ALB', 'POBLACION_EMPRESA_ALB',
    'PROVINCIA_EMPRESA_ALB', 'CODIGO_PAI_EMPRESA_ALB',
    'NOMBRE_PAI_EMPRESA_ALB', 'CODIGO_POSTAL_EMPRESA_ALB',
    'GRUPO_ZONA_IVA_EMPRESA_ALB', 'CODIGO_CLI_ALB',
    'RAZON_SOCIAL_CLIENTE_ALB', 'NIF_CLIENTE_ALB', 'MOVIL_CLIENTE_ALB',
    'EMAIL_CLIENTE_ALB', 'DIRECCION1_CLIENTE_ALB',
    'DIRECCION2_CLIENTE_ALB', 'POBLACION_CLIENTE_ALB',
    'PROVINCIA_CLIENTE_ALB', 'CODIGO_POSTAL_CLIENTE_ALB',
    'CODIGO_PAI_CLIENTE_ALB', 'NOMBRE_PAI_CLIENTE_ALB',
    'NOMBRE_CLI_ENVIO_ALB', 'MOVIL_CLIENTE_ENVIO_ALB',
    'DIRECCION1_CLIENTE_ENVIO_ALB', 'DIRECCION2_CLIENTE_ENVIO_ALB',
    'POBLACION_CLIENTE_ENVIO_ALB', 'PROVINCIA_CLIENTE_ENVIO_ALB',
    'CODIGO_POSTAL_CLIENTE_ENVIO_ALB', 'CODIGO_PAI_CLIENTE_ENVIO_ALB',
    'NOMBRE_PAI_CLIENTE_ENVIO_ALB', 'TRANSPORTISTA_ALB',
    'CODIGO_IVA_ALB', 'ESIVA_RECARGO_CLIENTE_ALB',
    'ESIVA_EXENTO_CLIENTE_ALB', 'ESINTRACOMUNITARIO_CLIENTE_ALB',
    'TARIFA_ARTICULO_CLIENTE_ALB', 'ESIMP_INCL_TARIFA_CLIENTE_ALB',
    'PORCENTAJE_IVAN_ALB', 'TOTAL_IVAN_ALB', 'PORCENTAJE_IVAR_ALB',
    'TOTAL_IVAR_ALB', 'PORCENTAJE_IVAS_ALB', 'TOTAL_IVAS_ALB',
    'PORCENTAJE_IVAE_ALB', 'TOTAL_IVAE_ALB', 'TOTAL_BASES_ALB',
    'TOTAL_IMPUESTOS_ALB', 'TOTAL_LIQUIDO_ALB', 'FORMA_PAGO_ALB',
    'CONTADOR_LINEAS_ALB', 'COMENTARIOS_ALB', 'OBSERVACIONES_ALB',
    'INSTANTE_MODIF', 'INSTANTE_ALTA', 'USUARIO_ALTA', 'USUARIO_MODIF'
  );

// INSERT INTO fza_albaranes con todas las columnas de la tabla.
function SqlInsertAlbaran: string;
var
  i: Integer;
  sColumnaSql: string;
  sCols, sVals: string;
begin
  sCols := '';
  sVals := '';
  for i := Low(COLUMNAS_ALBARAN) to High(COLUMNAS_ALBARAN) do
  begin
    if i > Low(COLUMNAS_ALBARAN) then
    begin
      sCols := sCols + ', ';
      sVals := sVals + ', ';
    end;
    sColumnaSql := DelimitarIdentificadorSql(
      COLUMNAS_ALBARAN[i],
      COLUMNAS_ALBARAN);
    sCols := sCols + sColumnaSql;
    sVals := sVals + ':' + COLUMNAS_ALBARAN[i];
  end;
  Result := 'INSERT INTO fza_albaranes (' + sCols + ') VALUES (' +
            sVals + ')';
end;

// UPDATE de fza_albaranes por clave primaria (NUMERO+SERIE).
function SqlUpdateAlbaran: string;
var
  i: Integer;
  sColumnaSql: string;
  sSet: string;
begin
  sSet := '';
  for i := Low(COLUMNAS_ALBARAN) to High(COLUMNAS_ALBARAN) do
  begin
    if i > Low(COLUMNAS_ALBARAN) then
      sSet := sSet + ', ';
    sColumnaSql := DelimitarIdentificadorSql(
      COLUMNAS_ALBARAN[i],
      COLUMNAS_ALBARAN);
    sSet := sSet + sColumnaSql + ' = :' + COLUMNAS_ALBARAN[i];
  end;
  Result := 'UPDATE fza_albaranes SET ' + sSet +
            ' WHERE NUMERO_ALB = :Old_NUMERO_ALB' +
            '   AND SERIE_ALB = :Old_SERIE_ALB';
end;

procedure TdmAlbaranes.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection                 := ConexionPrincipal;
  unqryTablaG.KeyFields                  := 'NUMERO_ALB;SERIE_ALB';
  unqryTablaG.SQLDelete.Text             :=
    'DELETE FROM fza_albaranes ' + sLineBreak +
    'WHERE NUMERO_ALB = :Old_NUMERO_ALB ' + sLineBreak +
    '  AND SERIE_ALB = :Old_SERIE_ALB';
  // La cabecera se lee de vi_albaranes (join a almacenes): la vista NO
  // es insertable y los DML generados por UniDAC contra ella fallan
  // ('target table vi_albaranes ... not insertable-into') al crear un
  // albaran nuevo desde el form. Se escriben contra la tabla real.
  unqryTablaG.SQLInsert.Text             := SqlInsertAlbaran;
  unqryTablaG.SQLUpdate.Text             := SqlUpdateAlbaran;
  unqryTablaG.SQLRefresh.Text            :=
    'SELECT * FROM vi_albaranes ' +
    ' WHERE NUMERO_ALB = :NUMERO_ALB ' +
    '   AND SERIE_ALB = :SERIE_ALB';
  unqryAlbaranesLineas.Connection        := ConexionPrincipal;
  unqryEmpDataAlb.Connection             := ConexionPrincipal;
  unqryCliDataAlb.Connection             := ConexionPrincipal;
  unqryArtDataLinAlb.Connection          := ConexionPrincipal;
  unqrySkusAlb.Connection                := ConexionPrincipal;
  unqryFacturas.Connection               := ConexionPrincipal;
  unqryMovimientosAlb.Connection         := ConexionPrincipal;
  unqryFormasPago.Connection             := ConexionPrincipal;
  unqryAlmacenesAlb.Connection           := ConexionPrincipal;
  unqryTarifas.Connection                := ConexionPrincipal;
  unstrdprcGetContadorAlbaran.Connection := ConexionPrincipal;
  unstrdprcCrearFacturaInicio.Connection := ConexionPrincipal;
  unstrdprcCrearFacturaLinea.Connection  := ConexionPrincipal;
  unstrdprcCrearFacturaFin.Connection    := ConexionPrincipal;
  unstrdprcInsertarMovAlb.Connection     := ConexionPrincipal;
end;

procedure TdmAlbaranes.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(unqryAlbaranesLineas) and unqryAlbaranesLineas.Active then
    unqryAlbaranesLineas.Close;
  if Assigned(unqryFacturas) and unqryFacturas.Active then
    unqryFacturas.Close;
  if Assigned(unqryMovimientosAlb) and unqryMovimientosAlb.Active then
    unqryMovimientosAlb.Close;
  if Assigned(unqryFormasPago) and unqryFormasPago.Active then
    unqryFormasPago.Close;
  if Assigned(unqryAlmacenesAlb) and unqryAlmacenesAlb.Active then
    unqryAlmacenesAlb.Close;
  if Assigned(unqryTarifas) and unqryTarifas.Active then
    unqryTarifas.Close;
  inherited;
end;

procedure TdmAlbaranes.OpenTables;
begin
  // Delegar en AbrirDetalles para que el flujo (cronometro y logging)
  // sea unico independientemente de quien lo invoque.
  AbrirDetalles;
end;

procedure TdmAlbaranes.AbrirDetalles;
const
  TAG = 'Albaranes.AbrirDetalles';

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
  // Antes de abrir queries aseguramos que el esquema y los procs están al día
  // (idempotente y barato): así las nuevas columnas de seguimiento de
  // facturación están disponibles para el data-binding del formulario.
  InstalarProcedimientos;
  RefrescarAlmacenes(UbicacionSesion.Empresa);
  AbrirConTiempo(unqryAlbaranesLineas, 'unqryAlbaranesLineas');
  AbrirConTiempo(unqryFacturas,        'unqryFacturas');
  AbrirConTiempo(unqryMovimientosAlb,  'unqryMovimientosAlb');
  AbrirConTiempo(unqryFormasPago,      'unqryFormasPago');
  AbrirConTiempo(unqryTarifas,         'unqryTarifas');
  inLibLog.Log.LogPerf(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmAlbaranes.RefrescarAlmacenes(const ACodigoEmpresa: string);
var
  sEmpresa: string;
begin
  sEmpresa := Trim(ACodigoEmpresa);
  if (sEmpresa = '') and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
    sEmpresa := Trim(unqryTablaG.FieldByName('CODIGO_EMP_ALB').AsString);
  if sEmpresa = '' then
    sEmpresa := Trim(UbicacionSesion.Empresa);
  if (not unqryAlmacenesAlb.Active) or
     (not SameText(unqryAlmacenesAlb.ParamByName('EMPRESA').AsString,
                   sEmpresa)) then
  begin
    unqryAlmacenesAlb.Close;
    unqryAlmacenesAlb.ParamByName('EMPRESA').AsString := sEmpresa;
    unqryAlmacenesAlb.Open;
  end;
  if unqryTablaG.Active and
     (unqryTablaG.State in [dsInsert, dsEdit]) then
    AjustarEmpresaAlmacenDataSet(unqryTablaG.Connection, unqryTablaG,
      'CODIGO_EMP_ALB', 'CODIGO_ALM_ALB');
end;

procedure TdmAlbaranes.unqryTablaGAfterInsert(DataSet: TDataSet);
var
  sSerie: string;
begin
  inherited;
  with unqryTablaG do
  begin
    FieldByName('NUMERO_ALB').AsString  := '0';
    // Serie por defecto: buscar en fza_empresas_series para TIPO_DOC='AV'
    // (mismo criterio que compras); fallback historico 'A1'
    sSerie := ObtenerSerieDefecto(
      ConexionPrincipal,
      UbicacionSesion.Empresa,
      'AV');
    if sSerie = '' then
      sSerie := 'A1';
    if FindField('SERIE_ALB') <> nil then
      FieldByName('SERIE_ALB').AsString := sSerie;
    FieldByName('FECHA_ALB').AsDateTime := Date;
    if FindField('ESTADO_ALB') <> nil then
      FieldByName('ESTADO_ALB').AsString := 'ABIERTO';
    if FindField('ESCONSOLIDADO_ALB') <> nil then
      FieldByName('ESCONSOLIDADO_ALB').AsString := 'N';
    if Trim(UbicacionSesion.Empresa) <> '' then
      FieldByName('CODIGO_EMP_ALB').AsString := UbicacionSesion.Empresa
    else
      FieldByName('CODIGO_EMP_ALB').AsString := '0';
    if FindField('CODIGO_ALM_ALB') <> nil then
      FieldByName('CODIGO_ALM_ALB').AsString := UbicacionSesion.Almacen;
    FieldByName('CODIGO_CLI_ALB').AsString := '0';
    FieldByName('TARIFA_ARTICULO_CLIENTE_ALB').Clear;
    FieldByName('ESIMP_INCL_TARIFA_CLIENTE_ALB').Clear;
    if Trim(UbicacionSesion.Empresa) <> '' then
      BuscarEmpresa(UbicacionSesion.Empresa);
    if FindField('CODIGO_ALM_ALB') <> nil then
      FieldByName('CODIGO_ALM_ALB').AsString := UbicacionSesion.Almacen;
  end;
  RefrescarAlmacenes(
    DataSet.FieldByName('CODIGO_EMP_ALB').AsString);
end;

procedure TdmAlbaranes.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  ValidarAlmacenCabecera;
  if (unqryTablaG.FieldByName('NUMERO_ALB').AsString = '0') or
     (unqryTablaG.FieldByName('NUMERO_ALB').AsString = '') then
    GetCodigoAutoAlbaran;
  AplicarPorcentajesIvaVenta(ConexionPrincipal, unqryTablaG, 'ALB');
  CalcularTotalesAlbaran;
end;

procedure TdmAlbaranes.unqryTablaGAfterPost(DataSet: TDataSet);
begin
  inherited;
  ProcesarCabeceraPosteada;
end;

procedure TdmAlbaranes.unqryTablaGBeforeDelete(DataSet: TDataSet);
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
  sSerie  := DataSet.FieldByName('SERIE_ALB').AsString;
  sNumero := DataSet.FieldByName('NUMERO_ALB').AsString;
  if (sSerie = '') or (sNumero = '') then
  begin
    Abort;
  end;
  q := TUniQuery.Create(nil);
  try
    q.Connection := unqryTablaG.Connection;
    q.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_albaranes ' +
      ' WHERE SERIE_ALB  = :s ' +
      '   AND NUMERO_ALB = :n ' +
      '   AND (COALESCE(NUMERO_FAC_ALB, '''') <> '''' ' +
      '    OR COALESCE(SERIE_FAC_ALB, '''') <> '''' ' +
      '    OR COALESCE(ESTADO_ALB, '''') = ''FACTURADO'')';
    AsignarDocumento;
    q.Open;
    iBloqueos := q.FieldByName('N').AsInteger;
    q.Close;
    if iBloqueos = 0 then
    begin
      q.SQL.Text :=
        'SELECT COUNT(*) AS N ' +
        '  FROM fza_albaranes_lineas ' +
        ' WHERE SERIE_ALB_ALBLIN  = :s ' +
        '   AND NUMERO_ALB_ALBLIN = :n ' +
        '   AND (COALESCE(ESFACTURADA_ALBLIN, ''N'') = ''S'' ' +
        '    OR COALESCE(NUMERO_FAC_ALBLIN, '''') <> '''' ' +
        '    OR COALESCE(SERIE_FAC_ALBLIN, '''') <> '''')';
      AsignarDocumento;
      q.Open;
      iBloqueos := q.FieldByName('N').AsInteger;
      q.Close;
    end;
    if iBloqueos > 0 then
    begin
      MessageDlg(SAvisoAlbaranFacturado,
                 mtWarning, [mbOk], 0);
      Abort;
    end;
    if MessageDlg(Format(SPreguntaBorrarAlbaran,
                         [sSerie, sNumero]),
                  mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    begin
      Abort;
    end;
    q.SQL.Text := 'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :s, :n)';
    q.ParamByName('t').AsString := 'AV';
    AsignarDocumento;
    q.ExecSQL;
    q.SQL.Text :=
      'DELETE FROM fza_albaranes_lineas ' +
      ' WHERE SERIE_ALB_ALBLIN  = :s ' +
      '   AND NUMERO_ALB_ALBLIN = :n';
    AsignarDocumento;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

// Defaults de las columnas del contrato ColumnSKUcxGrid en una linea
// recien insertada (ver comentario en AfterInsert).
procedure InicializarColumnasSkuLinea(ADataSet: TDataSet);
var
  i: Integer;
begin
  if ADataSet.FindField('NUM_ATRIBUTOS_ALBLIN') <> nil then
    ADataSet.FieldByName('NUM_ATRIBUTOS_ALBLIN').AsInteger := 0;
  if ADataSet.FindField('ID_AC_PIVOT_ALBLIN') <> nil then
    ADataSet.FieldByName('ID_AC_PIVOT_ALBLIN').AsInteger := 0;
  for i := 1 to 5 do
  begin
    if ADataSet.FindField('ATTR' + IntToStr(i) + '_VALOR_ALBLIN') <> nil
    then
      ADataSet.FieldByName(
        'ATTR' + IntToStr(i) + '_VALOR_ALBLIN').AsString := '';
    if ADataSet.FindField('ATTR' + IntToStr(i) + '_NOMBRE_ALBLIN') <> nil
    then
      ADataSet.FieldByName(
        'ATTR' + IntToStr(i) + '_NOMBRE_ALBLIN').AsString := '';
  end;
end;

// Linea sin identificar el articulo: ni codigo ni SKU.
function LineaAlbaranVacia(ADataSet: TDataSet): Boolean;
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
  Result := CampoVacio('CODIGO_ART_ALBLIN') and
            CampoVacio('CODIGO_UNIDAD_ALBLIN');
end;

procedure TdmAlbaranes.unqryAlbaranesLineasAfterInsert(DataSet: TDataSet);
begin
  inherited;
  with unqryAlbaranesLineas do
  begin
    FieldByName('LINEA_ALBLIN').AsString := '0000';
    FieldByName('NUMERO_ALB_ALBLIN').AsString :=
                                  unqryTablaG.FieldByName(
                                    'NUMERO_ALB').AsString;
    FieldByName('SERIE_ALB_ALBLIN').AsString  :=
                                  unqryTablaG.FieldByName('SERIE_ALB').AsString;
    if (FindField('CODIGO_ALMACEN_ALBLIN') <> nil) and
       (unqryTablaG.FindField('CODIGO_ALM_ALB') <> nil) then
      FieldByName('CODIGO_ALMACEN_ALBLIN').AsString :=
        unqryTablaG.FieldByName('CODIGO_ALM_ALB').AsString;
    FieldByName('CANTIDAD_ALBLIN').AsFloat := 1;
    if FindField('ESFACTURADA_ALBLIN') <> nil then
      FieldByName('ESFACTURADA_ALBLIN').AsString := 'N';
    if FindField('CODIGO_TAR_ALBLIN') <> nil then
      FieldByName('CODIGO_TAR_ALBLIN').AsString :=
        unqryTablaG.FieldByName(
          'TARIFA_ARTICULO_CLIENTE_ALB').AsString;
    if FindField('ESIMP_INCL_TARIFA_ALBLIN') <> nil then
      FieldByName('ESIMP_INCL_TARIFA_ALBLIN').AsString :=
        unqryTablaG.FieldByName(
          'ESIMP_INCL_TARIFA_CLIENTE_ALB').AsString;
    // Columnas del contrato ColumnSKUcxGrid: NOT NULL en BBDD con
    // DEFAULT de servidor que el cliente no conoce; sin inicializarlas
    // el Post lanza "must have a value" (leccion de pedidos).
    InicializarColumnasSkuLinea(unqryAlbaranesLineas);
    if FindField('USUARIO_ALTA') <> nil then
      FieldByName('USUARIO_ALTA').AsString := IdentidadSesion.Usuario;
    if FindField('INSTANTE_ALTA') <> nil then
      FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    if FindField('USUARIO_MODIF') <> nil then
      FieldByName('USUARIO_MODIF').AsString := IdentidadSesion.Usuario;
    if FindField('INSTANTE_MODIF') <> nil then
      FieldByName('INSTANTE_MODIF').AsDateTime := Now;
  end;
end;

procedure TdmAlbaranes.NormalizarCamposOpcionalesLinea(DataSet: TDataSet);
var
  q: TUniQuery;
  sArticulo: string;
  bTrazable: Boolean;
  bVariacion: Boolean;
  iSkus: Integer;
begin
  sArticulo := '';
  bTrazable := False;
  bVariacion := False;
  iSkus := 0;
  if (DataSet <> nil) and DataSet.Active and
     (DataSet.FindField('CODIGO_ART_ALBLIN') <> nil) then
    sArticulo := Trim(DataSet.FieldByName('CODIGO_ART_ALBLIN').AsString);
  if sArticulo <> '' then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := unqryTablaG.Connection;
      q.SQL.Text :=
        'SELECT a.ESTRAZABLE_ART, a.ESVARIACION_ART, ' +
        '       (SELECT COUNT(*) ' +
        '          FROM fza_articulos_skus sk ' +
        '         WHERE sk.CODIGO_ART_SKU = a.CODIGO_ART_ART ' +
        '           AND COALESCE(sk.ESACTIVO_SKU, ''S'') = ''S'') AS NUM_SKUS ' +
        '  FROM fza_articulos a ' +
        ' WHERE a.CODIGO_ART_ART = :art';
      q.ParamByName('art').AsString := sArticulo;
      q.Open;
      if not q.IsEmpty then
      begin
        bTrazable := q.FieldByName('ESTRAZABLE_ART').AsString = 'S';
        bVariacion := q.FieldByName('ESVARIACION_ART').AsString = 'S';
        iSkus := q.FieldByName('NUM_SKUS').AsInteger;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
  if not bTrazable then
  begin
    if DataSet.FindField('LOTE_ALBLIN') <> nil then
      DataSet.FieldByName('LOTE_ALBLIN').Clear;
    if DataSet.FindField('FECHA_CADUCIDAD_ALBLIN') <> nil then
      DataSet.FieldByName('FECHA_CADUCIDAD_ALBLIN').Clear;
  end;
  if (not bVariacion) and (iSkus <= 1) and
     (DataSet.FindField('DESCRIPCION_VARIACION_ALBLIN') <> nil) then
    DataSet.FieldByName('DESCRIPCION_VARIACION_ALBLIN').Clear;
  if (iSkus = 0) and
     (DataSet.FindField('CODIGO_UNIDAD_ALBLIN') <> nil) then
    DataSet.FieldByName('CODIGO_UNIDAD_ALBLIN').Clear;
end;

procedure TdmAlbaranes.SincronizarAlmacenLinea(DataSet: TDataSet);
var
  sAlmacen: string;
begin
  if (DataSet <> nil) and (DataSet.FindField('CODIGO_ALMACEN_ALBLIN') <> nil) and
     (unqryTablaG.FindField('CODIGO_ALM_ALB') <> nil) then
  begin
    sAlmacen := Trim(unqryTablaG.FieldByName('CODIGO_ALM_ALB').AsString);
    DataSet.FieldByName('CODIGO_ALMACEN_ALBLIN').AsString := sAlmacen;
  end;
end;

procedure TdmAlbaranes.ValidarAlmacenCabecera;
begin
  if (unqryTablaG.FindField('CODIGO_ALM_ALB') <> nil) and
     (Trim(unqryTablaG.FieldByName('CODIGO_ALM_ALB').AsString) = '') then
  begin
    MessageDlg(SAvisoAlmacenSalidaAlbaranObligatorio,
               mtWarning, [mbOk], 0);
    Abort;
  end;
end;

procedure TdmAlbaranes.SincronizarAlmacenLineasCabecera;
var
  q: TUniQuery;
  sAlmacen: string;
  sNumero: string;
  sSerie: string;
begin
  if unqryTablaG.FindField('CODIGO_ALM_ALB') <> nil then
  begin
    sAlmacen := Trim(unqryTablaG.FieldByName('CODIGO_ALM_ALB').AsString);
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_ALB').AsString);
    sSerie := Trim(unqryTablaG.FieldByName('SERIE_ALB').AsString);
    if (sAlmacen <> '') and (sNumero <> '') and (sNumero <> '0') and
       (sSerie <> '') then
    begin
      q := TUniQuery.Create(nil);
      try
        q.Connection := unqryTablaG.Connection;
        q.SQL.Text :=
          'UPDATE fza_albaranes_lineas ' +
          '   SET CODIGO_ALMACEN_ALBLIN = :alm ' +
          ' WHERE NUMERO_ALB_ALBLIN = :num ' +
          '   AND SERIE_ALB_ALBLIN  = :ser ' +
          '   AND COALESCE(CODIGO_ALMACEN_ALBLIN, '''') <> :alm';
        q.ParamByName('alm').AsString := sAlmacen;
        q.ParamByName('num').AsString := sNumero;
        q.ParamByName('ser').AsString := sSerie;
        q.ExecSQL;
      finally
        FreeAndNil(q);
      end;
      if unqryAlbaranesLineas.Active then
      begin
        if unqryAlbaranesLineas.State in dsEditModes then
          SincronizarAlmacenLinea(unqryAlbaranesLineas)
        else
        begin
          unqryAlbaranesLineas.Close;
          unqryAlbaranesLineas.Open;
        end;
      end;
    end;
  end;
end;

procedure TdmAlbaranes.unqryAlbaranesLineasBeforePost(DataSet: TDataSet);
var
  sSku, sArt: string;
begin
  inherited;
  // Desempaquetado ATTR en curso: post descriptivo, sin logica fiscal.
  if FDesempaquetandoAtributos then
    Exit;
  // Guarda ColumnSKUcxGrid (leccion de pedidos, bucle 07/07/2026): un
  // Post de linea sin articulo ni SKU no debe llegar a BBDD ni
  // consumir contador de lineas.
  if LineaAlbaranVacia(DataSet) then
    raise Exception.Create(SErrorLineaAlbaranSinArticulo);
  AsignarNumeroLineaAlbaran(DataSet);
  SincronizarAlmacenLinea(DataSet);
  with unqryAlbaranesLineas do
  begin
    // Acepta articulo, SKU, codigo de barras o referencia de proveedor.
    NormalizarArticuloSkuEnDataSet(ConexionPrincipal,
      unqryAlbaranesLineas, 'CODIGO_ART_ALBLIN',
      'CODIGO_UNIDAD_ALBLIN');
    NormalizarCamposOpcionalesLinea(DataSet);
    if (FindField('CANTIDAD_ALBLIN') <> nil) and
       (FindField('PRECIO_VENTA_SIVA_ARTICULO_ALBLIN') <> nil) and
       (FindField('TOTAL_ALBLIN') <> nil) then
      PrepararLineaFiscalVenta(ConexionPrincipal, unqryTablaG,
        unqryAlbaranesLineas, 'ALB', 'ALBLIN', 'TOTAL_ALBLIN');

    // Si el usuario ha tecleado un SKU pero no el artículo, lo deducimos
    // consultando fza_articulos_skus.
    if (FindField('CODIGO_UNIDAD_ALBLIN') <> nil) and
       (FindField('CODIGO_ART_ALBLIN') <> nil) then
    begin
      sSku := Trim(FieldByName('CODIGO_UNIDAD_ALBLIN').AsString);
      sArt := Trim(FieldByName('CODIGO_ART_ALBLIN').AsString);
      if (sSku <> '') and (sArt = '') then
      begin
        unqrySkusAlb.Close;
        unqrySkusAlb.ParamByName('pSKU').AsString := sSku;
        unqrySkusAlb.Open;
        if not unqrySkusAlb.Eof then
          FieldByName('CODIGO_ART_ALBLIN').AsString :=
                                  unqrySkusAlb.FieldByName(
                                    'CODIGO_ART_SKU').AsString;
        unqrySkusAlb.Close;
      end;
    end;
    if FindField('USUARIO_MODIF') <> nil then
      FieldByName('USUARIO_MODIF').AsString := IdentidadSesion.Usuario;
    if FindField('INSTANTE_MODIF') <> nil then
      FieldByName('INSTANTE_MODIF').AsDateTime := Now;
    if DataSet.State = dsInsert then
    begin
      if (FindField('USUARIO_ALTA') <> nil) and
         (FieldByName('USUARIO_ALTA').AsString = '') then
        FieldByName('USUARIO_ALTA').AsString := IdentidadSesion.Usuario;
      if (FindField('INSTANTE_ALTA') <> nil) and
         FieldByName('INSTANTE_ALTA').IsNull then
        FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    end;
  end;
end;

procedure TdmAlbaranes.AsignarNumeroLineaAlbaran(DataSet: TDataSet);
var
  iNuevaLinea: Integer;
  sLinea: string;
  sNumero: string;
  sSerie: string;
begin
  if DataSet.FindField('LINEA_ALBLIN') <> nil then
  begin
    sLinea := Trim(DataSet.FieldByName('LINEA_ALBLIN').AsString);
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_ALB').AsString);
    sSerie  := Trim(unqryTablaG.FieldByName('SERIE_ALB').AsString);
    if (sLinea = '') or (StrToIntDef(sLinea, 0) = 0) or
       ((DataSet.State = dsInsert) and
        LineaDocExiste(ConexionPrincipal, LIN_ALBARANES, sSerie, sNumero,
          sLinea)) then
    begin
      if (sNumero = '') or (sNumero = '0') or (sSerie = '') then
        raise Exception.Create(SErrorCabeceraAlbaranSinGrabar);
      if DataSet.FindField('NUMERO_ALB_ALBLIN') <> nil then
        DataSet.FieldByName('NUMERO_ALB_ALBLIN').AsString := sNumero;
      if DataSet.FindField('SERIE_ALB_ALBLIN') <> nil then
        DataSet.FieldByName('SERIE_ALB_ALBLIN').AsString := sSerie;
      iNuevaLinea := GetSiguienteLineaDocLibre(ConexionPrincipal,
        CONT_ALBARANES, LIN_ALBARANES, sSerie, sNumero);
      // El helper ya persiste CONTADOR_LINEAS_ALB en BBDD dentro de su
      // propia transaccion. NO se toca unqryTablaG (leccion de
      // pedidos: el Edit dejaba la cabecera en edicion sin postear y
      // encadenaba re-Posts de cabecera + recargas del detalle). La
      // copia en memoria desfasada es inocua: el helper toma siempre
      // MAX(LINEA_ALBLIN) como suelo.
      if iNuevaLinea = 0 then
        raise Exception.Create(Format(SErrorAsignarLineaAlbaran,
                                      [sSerie, sNumero]));
      DataSet.FieldByName('LINEA_ALBLIN').AsString :=
        Format('%.4d', [iNuevaLinea]);
    end;
  end;
end;

procedure TdmAlbaranes.DesempaquetarAtributosLineas;
var
  Partes: TArray<string>;
  Sku, sEsperado: string;
  i: Integer;
  Bm: TBookmark;
  bCambia: Boolean;
begin
  if unqryAlbaranesLineas.Active and
     (not unqryAlbaranesLineas.IsEmpty) and
     (unqryAlbaranesLineas.FindField('ATTR1_VALOR_ALBLIN') <> nil) then
  begin
    Bm := unqryAlbaranesLineas.GetBookmark;
    unqryAlbaranesLineas.DisableControls;
    // Posts descriptivos: silencia la logica fiscal y de movimientos
    // en BeforePost / AfterPost.
    FDesempaquetandoAtributos := True;
    try
      unqryAlbaranesLineas.First;
      while not unqryAlbaranesLineas.Eof do
      begin
        Sku := unqryAlbaranesLineas.FieldByName(
          'CODIGO_UNIDAD_ALBLIN').AsString;
        Partes := Sku.Split(['/']);
        if Length(Partes) > 1 then
        begin
          bCambia := unqryAlbaranesLineas.FieldByName(
            'NUM_ATRIBUTOS_ALBLIN').AsInteger <> Length(Partes) - 1;
          for i := 1 to 5 do
          begin
            if i < Length(Partes) then
              sEsperado := Partes[i]
            else
              sEsperado := '';
            if Trim(unqryAlbaranesLineas.FieldByName('ATTR' +
                 IntToStr(i) + '_VALOR_ALBLIN').AsString) <> sEsperado
            then
              bCambia := True;
          end;
          if bCambia then
          begin
            unqryAlbaranesLineas.Edit;
            unqryAlbaranesLineas.FieldByName(
              'NUM_ATRIBUTOS_ALBLIN').AsInteger := Length(Partes) - 1;
            for i := 1 to 5 do
            begin
              if i < Length(Partes) then
                unqryAlbaranesLineas.FieldByName('ATTR' + IntToStr(i) +
                  '_VALOR_ALBLIN').AsString := Partes[i]
              else
                unqryAlbaranesLineas.FieldByName('ATTR' + IntToStr(i) +
                  '_VALOR_ALBLIN').AsString := '';
            end;
            unqryAlbaranesLineas.Post;
          end;
        end;
        unqryAlbaranesLineas.Next;
      end;
      if unqryAlbaranesLineas.BookmarkValid(Bm) then
        unqryAlbaranesLineas.GotoBookmark(Bm);
    finally
      FDesempaquetandoAtributos := False;
      unqryAlbaranesLineas.EnableControls;
      unqryAlbaranesLineas.FreeBookmark(Bm);
    end;
  end;
end;

procedure TdmAlbaranes.unqryAlbaranesLineasAfterPost(DataSet: TDataSet);
begin
  inherited;
  if not FDesempaquetandoAtributos then
    ProcesarLineasPosteadas;
end;

procedure TdmAlbaranes.unqryAlbaranesLineasAfterDelete(DataSet: TDataSet);
begin
  inherited;
  ProcesarLineasPosteadas;
end;

function TdmAlbaranes.TotalPrendasAlbaran: Double;
begin
  Result := TotalPrendasLineasVenta(unqryAlbaranesLineas,
    'TIPO_IVA_ARTICULO_ALBLIN');
end;

procedure TdmAlbaranes.GetCodigoAutoAlbaran;
var
  iNumero: Int64;
  sNumero: string;
begin
  with unstrdprcGetContadorAlbaran do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'pserie',            ptInput);
    Params.CreateParam(ftString, 'ptipodoc',          ptInput);
    Params.CreateParam(ftString, 'pEMPRESA_CONTADOR', ptInput);
    Params.CreateParam(ftString, 'pUSUARIOMODIF',     ptInput);
    Params.CreateParam(ftString, 'pcont',             ptOutput);
    ParamByName('pserie').AsString    :=
      unqryTablaG.FieldByName('SERIE_ALB').AsString;
    ParamByName('ptipodoc').AsString  := 'AV';
    ParamByName('pUSUARIOMODIF').AsString := IdentidadSesion.Usuario;
    ParamByName('pEMPRESA_CONTADOR').AsString :=
                                  unqryTablaG.FieldByName(
                                    'CODIGO_EMP_ALB').AsString;
    ExecProc;
    sNumero := Trim(ParamByName('pcont').AsString);
    if (sNumero = '') or (not TryStrToInt64(sNumero, iNumero)) or
       (iNumero <= 0) then
      raise Exception.Create(Format(SErrorContadorAlbaran,
        [unqryTablaG.FieldByName('SERIE_ALB').AsString,
         unqryTablaG.FieldByName('CODIGO_EMP_ALB').AsString]));
    unqryTablaG.FieldByName('NUMERO_ALB').AsString := sNumero;
  end;
end;

procedure TdmAlbaranes.CalcularTotalesAlbaran;
begin
  if not FCalculandoTotales then
  begin
    FCalculandoTotales := True;
    try
      CalcularTotalesDocumentoVenta(unqryTablaG.Connection, unqryTablaG,
        unqryAlbaranesLineas, 'ALB', 'TOTAL_ALBLIN',
        'TIPO_IVA_ARTICULO_ALBLIN', 'PORCENTAJE_IVA_ALBLIN');
    finally
      FCalculandoTotales := False;
    end;
  end;
end;

procedure TdmAlbaranes.BorrarMovimientosSalida;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := unqryTablaG.Connection;
    q.SQL.Text := 'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :s, :n)';
    q.ParamByName('t').AsString := 'AV';
    q.ParamByName('s').AsString :=
      unqryTablaG.FieldByName('SERIE_ALB').AsString;
    q.ParamByName('n').AsString :=
      unqryTablaG.FieldByName('NUMERO_ALB').AsString;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;

function TdmAlbaranes.ResolverSkuMovimientoSalida(
  const ACodigoArticulo: string): string;
var
  q: TUniQuery;
  iSkus: Integer;
  sArticulo: string;
  sUnico: string;
begin
  Result := '';
  sArticulo := Trim(ACodigoArticulo);
  if sArticulo <> '' then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := unqryTablaG.Connection;
      q.SQL.Text :=
        'SELECT CODIGO_UNIDAD_SKU ' +
        '  FROM fza_articulos_skus ' +
        ' WHERE CODIGO_ART_SKU = :art ' +
        '   AND COALESCE(ESACTIVO_SKU, ''S'') = ''S'' ' +
        ' ORDER BY CODIGO_UNIDAD_SKU';
      q.ParamByName('art').AsString := sArticulo;
      q.Open;
      iSkus := 0;
      sUnico := '';
      while not q.Eof do
      begin
        Inc(iSkus);
        if iSkus = 1 then
          sUnico := q.FieldByName('CODIGO_UNIDAD_SKU').AsString;
        q.Next;
      end;
      q.Close;
      if iSkus = 1 then
        Result := sUnico;
      if Result = '' then
      begin
        q.SQL.Text :=
          'INSERT IGNORE INTO fza_articulos_skus ' +
          '  (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
          '   ESACTIVO_SKU, INSTANTE_ALTA, USUARIO_ALTA, ' +
          '   USUARIO_MODIF) ' +
          'SELECT a.CODIGO_ART_ART, a.CODIGO_ART_ART, ''-'', ''S'', ' +
          '       CURRENT_TIMESTAMP, :usr, :usr ' +
          '  FROM fza_articulos a ' +
          ' WHERE a.CODIGO_ART_ART = :art ' +
          '   AND COALESCE(a.ESVARIACION_ART, ''N'') = ''N'' ' +
          '   AND COALESCE(a.ESACTIVO_ART, ''S'') = ''S'' ' +
          '   AND NOT EXISTS (SELECT 1 FROM fza_articulos_skus sk ' +
          '                    WHERE sk.CODIGO_ART_SKU = a.CODIGO_ART_ART)';
        q.ParamByName('usr').AsString := IdentidadSesion.Usuario;
        q.ParamByName('art').AsString := sArticulo;
        q.ExecSQL;
        q.SQL.Text :=
          'SELECT CODIGO_UNIDAD_SKU ' +
          '  FROM fza_articulos_skus ' +
          ' WHERE CODIGO_UNIDAD_SKU = :sku ' +
          '   AND CODIGO_ART_SKU = :art ' +
          '   AND COALESCE(ESACTIVO_SKU, ''S'') = ''S''';
        q.ParamByName('sku').AsString := sArticulo;
        q.ParamByName('art').AsString := sArticulo;
        q.Open;
        if not q.Eof then
          Result := q.FieldByName('CODIGO_UNIDAD_SKU').AsString;
        q.Close;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

procedure TdmAlbaranes.PrepararLineasMovimientoSalida(
  const ASerie, ANumero, AAlmacenCabecera: string);
var
  qLineas: TUniQuery;
  qUpd: TUniQuery;
  iNuevaLinea: Integer;
  sArticulo: string;
  sLineaActual: string;
  sLineaNueva: string;
  sLineaVieja: string;
  sSku: string;
begin
  if (ASerie <> '') and (ANumero <> '') then
  begin
    qLineas := TUniQuery.Create(nil);
    qUpd := TUniQuery.Create(nil);
    try
      qLineas.Connection := unqryTablaG.Connection;
      qUpd.Connection := unqryTablaG.Connection;
      if AAlmacenCabecera <> '' then
      begin
        qUpd.SQL.Text :=
          'UPDATE fza_albaranes_lineas ' +
          '   SET CODIGO_ALMACEN_ALBLIN = :alm, ' +
          '       USUARIO_MODIF = :usr, ' +
          '       INSTANTE_MODIF = CURRENT_TIMESTAMP ' +
          ' WHERE SERIE_ALB_ALBLIN = :ser ' +
          '   AND NUMERO_ALB_ALBLIN = :num ' +
          '   AND COALESCE(CODIGO_ALMACEN_ALBLIN, '''') <> :alm2';
        qUpd.ParamByName('alm').AsString := AAlmacenCabecera;
        qUpd.ParamByName('alm2').AsString := AAlmacenCabecera;
        qUpd.ParamByName('usr').AsString := IdentidadSesion.Usuario;
        qUpd.ParamByName('ser').AsString := ASerie;
        qUpd.ParamByName('num').AsString := ANumero;
        qUpd.ExecSQL;
      end;
      qLineas.SQL.Text :=
        'SELECT LINEA_ALBLIN, CODIGO_ART_ALBLIN, CODIGO_UNIDAD_ALBLIN ' +
        '  FROM fza_albaranes_lineas ' +
        ' WHERE SERIE_ALB_ALBLIN = :ser ' +
        '   AND NUMERO_ALB_ALBLIN = :num ' +
        ' ORDER BY LINEA_ALBLIN, INSTANTE_ALTA, CODIGO_ART_ALBLIN';
      qLineas.ParamByName('ser').AsString := ASerie;
      qLineas.ParamByName('num').AsString := ANumero;
      qLineas.Open;
      while not qLineas.Eof do
      begin
        sLineaVieja := Trim(qLineas.FieldByName('LINEA_ALBLIN').AsString);
        sLineaActual := sLineaVieja;
        if (sLineaVieja = '') or (StrToIntDef(sLineaVieja, 0) = 0) then
        begin
          iNuevaLinea := GetSiguienteLineaDocLibre(ConexionPrincipal,
            CONT_ALBARANES, LIN_ALBARANES, ASerie, ANumero);
          if iNuevaLinea > 0 then
          begin
            sLineaNueva := Format('%.4d', [iNuevaLinea]);
            qUpd.SQL.Text :=
              'UPDATE fza_albaranes_lineas ' +
              '   SET LINEA_ALBLIN = :lin, ' +
              '       USUARIO_MODIF = :usr, ' +
              '       INSTANTE_MODIF = CURRENT_TIMESTAMP ' +
              ' WHERE SERIE_ALB_ALBLIN = :ser ' +
              '   AND NUMERO_ALB_ALBLIN = :num ' +
              '   AND COALESCE(LINEA_ALBLIN, '''') = :lin_ant ' +
              ' ORDER BY INSTANTE_ALTA, CODIGO_ART_ALBLIN ' +
              ' LIMIT 1';
            qUpd.ParamByName('lin').AsString := sLineaNueva;
            qUpd.ParamByName('usr').AsString := IdentidadSesion.Usuario;
            qUpd.ParamByName('ser').AsString := ASerie;
            qUpd.ParamByName('num').AsString := ANumero;
            qUpd.ParamByName('lin_ant').AsString := sLineaVieja;
            qUpd.ExecSQL;
            if qUpd.RowsAffected <> 0 then
              sLineaActual := sLineaNueva;
          end;
        end;
        sArticulo := Trim(qLineas.FieldByName('CODIGO_ART_ALBLIN').AsString);
        sSku := Trim(qLineas.FieldByName('CODIGO_UNIDAD_ALBLIN').AsString);
        if (sSku = '') and (sArticulo <> '') then
        begin
          sSku := ResolverSkuMovimientoSalida(sArticulo);
          if sSku <> '' then
          begin
            qUpd.SQL.Text :=
              'UPDATE fza_albaranes_lineas ' +
              '   SET CODIGO_UNIDAD_ALBLIN = :sku, ' +
              '       USUARIO_MODIF = :usr, ' +
              '       INSTANTE_MODIF = CURRENT_TIMESTAMP ' +
              ' WHERE SERIE_ALB_ALBLIN = :ser ' +
              '   AND NUMERO_ALB_ALBLIN = :num ' +
              '   AND COALESCE(LINEA_ALBLIN, '''') = :lin ' +
              '   AND CODIGO_ART_ALBLIN = :art ' +
              '   AND COALESCE(CODIGO_UNIDAD_ALBLIN, '''') = ''''';
            qUpd.ParamByName('sku').AsString := sSku;
            qUpd.ParamByName('usr').AsString := IdentidadSesion.Usuario;
            qUpd.ParamByName('ser').AsString := ASerie;
            qUpd.ParamByName('num').AsString := ANumero;
            qUpd.ParamByName('lin').AsString := sLineaActual;
            qUpd.ParamByName('art').AsString := sArticulo;
            qUpd.ExecSQL;
          end;
        end;
        qLineas.Next;
      end;
    finally
      FreeAndNil(qLineas);
      FreeAndNil(qUpd);
    end;
    if unqryAlbaranesLineas.Active and
       (not (unqryAlbaranesLineas.State in dsEditModes)) then
    begin
      unqryAlbaranesLineas.Close;
      unqryAlbaranesLineas.Open;
    end;
  end;
end;

procedure TdmAlbaranes.SincronizarMovimientosSalida;
var
  sAlmacen: string;
  sNumero: string;
  sSerie: string;
begin
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
  begin
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_ALB').AsString);
    sSerie := Trim(unqryTablaG.FieldByName('SERIE_ALB').AsString);
    sAlmacen := '';
    if unqryTablaG.FindField('CODIGO_ALM_ALB') <> nil then
      sAlmacen := Trim(unqryTablaG.FieldByName('CODIGO_ALM_ALB').AsString);
    if (sNumero <> '') and (sNumero <> '0') and (sSerie <> '') then
    begin
      if sAlmacen <> '' then
      begin
        PrepararLineasMovimientoSalida(sSerie, sNumero, sAlmacen);
        BorrarMovimientosSalida;
        GenerarMovimientosSalida;
      end;
    end;
  end;
end;

procedure TdmAlbaranes.ProcesarCabeceraPosteada;
var
  bTransaccionPropia: Boolean;
begin
  bTransaccionPropia := not ConexionPrincipal.InTransaction;
  if bTransaccionPropia then
    ConexionPrincipal.StartTransaction;
  try
    SincronizarAlmacenLineasCabecera;
    SincronizarMovimientosSalida;
    if bTransaccionPropia and ConexionPrincipal.InTransaction then
      ConexionPrincipal.Commit;
  except
    if bTransaccionPropia and ConexionPrincipal.InTransaction then
      ConexionPrincipal.Rollback;
    raise;
  end;
end;

procedure TdmAlbaranes.ProcesarLineasPosteadas;
var
  bTransaccionPropia: Boolean;
begin
  bTransaccionPropia := not ConexionPrincipal.InTransaction;
  if bTransaccionPropia then
    ConexionPrincipal.StartTransaction;
  try
    CalcularTotalesAlbaran;
    SincronizarMovimientosSalida;
    if bTransaccionPropia and ConexionPrincipal.InTransaction then
      ConexionPrincipal.Commit;
  except
    if bTransaccionPropia and ConexionPrincipal.InTransaction then
      ConexionPrincipal.Rollback;
    raise;
  end;
end;

function TdmAlbaranes.BuscarEmpresa(const ACodigo: string): Boolean;
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
        // CopiarEmpresaaAlbaran ya repropone la serie de la empresa
        CopiarEmpresaaAlbaran(q);
        Result := True;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function TdmAlbaranes.BuscarAlmacen(const ACodigo: string): Boolean;
var
  qAlm: TUniQuery;
  qEmp: TUniQuery;
  sCodigo: string;
  sEmpresa: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if sCodigo <> '' then
  begin
    qAlm := TUniQuery.Create(nil);
    qEmp := TUniQuery.Create(nil);
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
        if not (unqryTablaG.State in [dsEdit, dsInsert]) then
          unqryTablaG.Edit;
        if unqryTablaG.FindField('CODIGO_ALM_ALB') <> nil then
          unqryTablaG.FieldByName('CODIGO_ALM_ALB').AsString := sCodigo;
        sEmpresa := qAlm.FieldByName('CODIGO_EMP_ALM').AsString;
        qEmp.Connection := unqryTablaG.Connection;
        qEmp.SQL.Text :=
          'SELECT * ' +
          '  FROM fza_empresas ' +
          ' WHERE CODIGO_EMP_EMP = :empresa';
        qEmp.ParamByName('empresa').AsString := sEmpresa;
        qEmp.Open;
        if not qEmp.IsEmpty then
          CopiarEmpresaaAlbaran(qEmp);
        if unqryTablaG.FindField('CODIGO_ALM_ALB') <> nil then
          unqryTablaG.FieldByName('CODIGO_ALM_ALB').AsString := sCodigo;
        Result := True;
      end;
    finally
      FreeAndNil(qEmp);
      FreeAndNil(qAlm);
    end;
  end;
end;

procedure TdmAlbaranes.ProponerSerieEmpresa(const AEmpresa: string);
var
  sSerie: string;
  sNumero: string;
begin
  if (unqryTablaG.State in [dsInsert, dsEdit]) then
  begin
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_ALB').AsString);
    // Solo documentos nuevos sin numerar: un documento ya numerado
    // conserva su serie aunque se retoque la empresa
    if (sNumero = '') or (sNumero = '0') then
    begin
      sSerie := ObtenerSerieDefecto(ConexionPrincipal, AEmpresa, 'AV');
      if sSerie <> '' then
        unqryTablaG.FieldByName('SERIE_ALB').AsString := sSerie;
    end;
  end;
end;

function TdmAlbaranes.BuscarCliente(const ACodigo: string): Boolean;
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
        CopiarClienteaAlbaran(q);
        Result := True;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

procedure TdmAlbaranes.CopiarEmpresaaAlbaran(DataSet: TDataSet);
var
  sAlmacen: string;
begin
  with unqryTablaG do
  begin
    if (State <> dsEdit) and (State <> dsInsert) then
      Edit;
    FindField('CODIGO_EMP_ALB').AsString             :=
      DataSet.FindField('CODIGO_EMP_EMP').AsString;
    FindField('RAZON_SOCIAL_EMPRESA_ALB').AsString   :=
      DataSet.FindField('RAZON_SOCIAL_EMP').AsString;
    FindField('NIF_EMPRESA_ALB').AsString            :=
      DataSet.FindField('NIF_EMP').AsString;
    FindField('MOVIL_EMPRESA_ALB').AsString          :=
      DataSet.FindField('MOVIL_EMP').AsString;
    FindField('EMAIL_EMPRESA_ALB').AsString          :=
      DataSet.FindField('EMAIL_EMP').AsString;
    FindField('DIRECCION1_EMPRESA_ALB').AsString     :=
      DataSet.FindField('DIRECCION1_EMP').AsString;
    FindField('DIRECCION2_EMPRESA_ALB').AsString     :=
      DataSet.FindField('DIRECCION2_EMP').AsString;
    FindField('POBLACION_EMPRESA_ALB').AsString      :=
      DataSet.FindField('POBLACION_EMP').AsString;
    FindField('PROVINCIA_EMPRESA_ALB').AsString      :=
      DataSet.FindField('PROVINCIA_EMP').AsString;
    FindField('CODIGO_POSTAL_EMPRESA_ALB').AsString  :=
      DataSet.FindField('CODIGO_POSTAL_EMP').AsString;
    FindField('NOMBRE_PAI_EMPRESA_ALB').AsString     :=
      DataSet.FindField('NOMBRE_PAI_EMP').AsString;
    FindField('CODIGO_PAI_EMPRESA_ALB').AsString     :=
      DataSet.FindField('CODIGO_PAI_EMP').AsString;
    FindField('GRUPO_ZONA_IVA_EMPRESA_ALB').AsString :=
      DataSet.FindField('GRUPO_ZONA_IVA_EMP').AsString;
    if FindField('CODIGO_ALM_ALB') <> nil then
    begin
      RefrescarAlmacenes(DataSet.FindField('CODIGO_EMP_EMP').AsString);
      sAlmacen := Trim(FieldByName('CODIGO_ALM_ALB').AsString);
      if (sAlmacen <> '') and
         unqryAlmacenesAlb.Locate('CODIGO_ALM_ALM', sAlmacen, []) then
        FieldByName('CODIGO_ALM_ALB').AsString := sAlmacen
      else if (Trim(UbicacionSesion.Almacen) <> '') and
              unqryAlmacenesAlb.Locate('CODIGO_ALM_ALM', UbicacionSesion.Almacen, []) then
        FieldByName('CODIGO_ALM_ALB').AsString := UbicacionSesion.Almacen
      else
        FieldByName('CODIGO_ALM_ALB').Clear;
    end;
  end;
  // La serie acompana a la empresa emisora (fza_empresas_series).
  // Cubre las dos rutas: codigo tecleado (BuscarEmpresa) y modal.
  ProponerSerieEmpresa(DataSet.FindField('CODIGO_EMP_EMP').AsString);
  AplicarPorcentajesIvaVenta(ConexionPrincipal, unqryTablaG, 'ALB');
end;

procedure TdmAlbaranes.ActualizarImpuestosTarifaCabecera(
  const ACodigoTarifa: string);
var
  sTarifa: string;
begin
  sTarifa := Trim(ACodigoTarifa);
  if unqryTablaG.Active and (unqryTablaG.State in dsEditModes) then
  begin
    if sTarifa = '' then
      unqryTablaG.FieldByName(
        'ESIMP_INCL_TARIFA_CLIENTE_ALB').Clear
    else
    begin
      if not unqryTarifas.Active then
        unqryTarifas.Open;
      if unqryTarifas.Locate('CODIGO_TAR_ARTTAR', sTarifa, []) then
        unqryTablaG.FieldByName(
          'ESIMP_INCL_TARIFA_CLIENTE_ALB').AsString :=
          unqryTarifas.FieldByName('ESIMP_INCL_TAR').AsString
      else
        unqryTablaG.FieldByName(
          'ESIMP_INCL_TARIFA_CLIENTE_ALB').Clear;
    end;
  end;
end;

procedure TdmAlbaranes.CopiarClienteaAlbaran(DataSet: TDataSet);
var
  sTarifa: string;
begin
  with unqryTablaG do
  begin
    if (State <> dsEdit) and (State <> dsInsert) then
      Edit;
    FindField('CODIGO_CLI_ALB').AsString          :=
      DataSet.FindField('CODIGO_CLI_CLI').AsString;
    FindField('RAZON_SOCIAL_CLIENTE_ALB').AsString:=
      DataSet.FindField('RAZON_SOCIAL_CLI').AsString;
    FindField('NIF_CLIENTE_ALB').AsString         :=
      DataSet.FindField('NIF_CLI').AsString;
    FindField('MOVIL_CLIENTE_ALB').AsString       :=
      DataSet.FindField('MOVIL_CLI').AsString;
    FindField('EMAIL_CLIENTE_ALB').AsString       :=
      DataSet.FindField('EMAIL_CLI').AsString;
    FindField('DIRECCION1_CLIENTE_ALB').AsString  :=
      DataSet.FindField('DIRECCION1_CLI').AsString;
    FindField('DIRECCION2_CLIENTE_ALB').AsString  :=
      DataSet.FindField('DIRECCION2_CLI').AsString;
    FindField('POBLACION_CLIENTE_ALB').AsString   :=
      DataSet.FindField('POBLACION_CLI').AsString;
    FindField('PROVINCIA_CLIENTE_ALB').AsString   :=
      DataSet.FindField('PROVINCIA_CLI').AsString;
    FindField('CODIGO_POSTAL_CLIENTE_ALB').AsString :=
      DataSet.FindField('CODIGO_POSTAL_CLI').AsString;
    FindField('NOMBRE_PAI_CLIENTE_ALB').AsString  :=
      DataSet.FindField('NOMBRE_PAI_CLI').AsString;
    FindField('CODIGO_PAI_CLIENTE_ALB').AsString  :=
      DataSet.FindField('CODIGO_PAI_CLI').AsString;
    FindField('ESIVA_RECARGO_CLIENTE_ALB').AsString:=
      DataSet.FindField('ESIVA_RECARGO_CLI').AsString;
    FindField('ESIVA_EXENTO_CLIENTE_ALB').AsString:=
      DataSet.FindField('ESIVA_EXENTO_CLI').AsString;
    FindField('ESINTRACOMUNITARIO_CLIENTE_ALB').AsString :=
                            DataSet.FindField(
                              'ESINTRACOMUNITARIO_CLI').AsString;
    sTarifa := Trim(DataSet.FindField('TARIFA_ARTICULO_CLI').AsString);
    if sTarifa = '' then
      sTarifa := ParametrosCaja.TarifaDefecto;
    FindField('TARIFA_ARTICULO_CLIENTE_ALB').AsString := sTarifa;
    ActualizarImpuestosTarifaCabecera(sTarifa);
  end;
  AplicarPorcentajesIvaVenta(ConexionPrincipal, unqryTablaG, 'ALB');
end;

procedure TdmAlbaranes.NegarMovimientosFacturaDesdeAlbaran(
  const ASerie, ANumero: string);
var
  qryFactura: TUniQuery;
begin
  qryFactura := TUniQuery.Create(nil);
  try
    qryFactura.Connection := ConexionPrincipal;
    qryFactura.SQL.Text :=
      'UPDATE fza_facturas ' +
      '   SET ESMUEVE_STOCK_FAC = ''N'', ' +
      '       INSTANTE_MODIF = NOW(), ' +
      '       USUARIO_MODIF = :pUSUARIO ' +
      ' WHERE SERIE_FAC = :pSERIE ' +
      '   AND NUMERO_FAC = :pNUMERO';
    qryFactura.ParamByName('pUSUARIO').AsString := IdentidadSesion.Usuario;
    qryFactura.ParamByName('pSERIE').AsString := ASerie;
    qryFactura.ParamByName('pNUMERO').AsString := ANumero;
    qryFactura.ExecSQL;
  finally
    FreeAndNil(qryFactura);
  end;
end;

procedure TdmAlbaranes.InstalarProcedimientos;
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
    q.Connection := ConexionPrincipal;

    // Columna de seguimiento de facturación a nivel de línea (idempotente).
    Run('ALTER TABLE fza_albaranes_lineas ' +
        'ADD COLUMN IF NOT EXISTS ESFACTURADA_ALBLIN VARCHAR(1) DEFAULT ''N''');
    Run('ALTER TABLE fza_albaranes_lineas ' +
        'ADD COLUMN IF NOT EXISTS NUMERO_FAC_ALBLIN VARCHAR(20) DEFAULT NULL');
    Run('ALTER TABLE fza_albaranes_lineas ' +
        'ADD COLUMN IF NOT EXISTS SERIE_FAC_ALBLIN VARCHAR(20) DEFAULT NULL');
    Run('ALTER TABLE fza_albaranes_lineas ' +
        'ADD COLUMN IF NOT EXISTS LINEA_FAC_ALBLIN VARCHAR(4) DEFAULT NULL');

    // Columnas SKU / lote / caducidad / variación (mismo nombre lógico que en
    // fza_facturas_lineas, sólo cambia el sufijo); permiten propagar la
    // información hacia la factura.
    Run('ALTER TABLE fza_albaranes_lineas ' +
        'ADD COLUMN IF NOT EXISTS CODIGO_UNIDAD_ALBLIN VARCHAR(50) DEFAULT ' +
        'NULL');
    Run('ALTER TABLE fza_albaranes_lineas ' +
        'ADD COLUMN IF NOT EXISTS LOTE_ALBLIN VARCHAR(50) DEFAULT NULL');
    Run('ALTER TABLE fza_albaranes_lineas ' +
        'ADD COLUMN IF NOT EXISTS FECHA_CADUCIDAD_ALBLIN DATE DEFAULT NULL');
    Run('ALTER TABLE fza_albaranes_lineas ' +
        'ADD COLUMN IF NOT EXISTS DESCRIPCION_VARIACION_ALBLIN VARCHAR(200) ' +
        'DEFAULT NULL');

    // PRC_ALB_CREAR_FACTURA_INICIO: cabecera factura clonando del primer
    // albarán.
    Run('DROP PROCEDURE IF EXISTS PRC_ALB_CREAR_FACTURA_INICIO');
    Run(
      'CREATE PROCEDURE PRC_ALB_CREAR_FACTURA_INICIO(' +
      '  IN  p_NUMERO_ALB varchar(20),' +
      '  IN  p_SERIE_ALB  varchar(20),' +
      '  IN  p_USUARIO    varchar(100),' +
      '  OUT p_NUMERO_FAC varchar(20),' +
      '  OUT p_SERIE_FAC  varchar(20)' +
      ') BEGIN ' +
      '  DECLARE v_serie  varchar(20); ' +
      '  DECLARE v_numero varchar(20); ' +
      '  SELECT SERIE_ALB INTO v_serie FROM fza_albaranes ' +
      '   WHERE NUMERO_ALB = p_NUMERO_ALB AND SERIE_ALB = p_SERIE_ALB; ' +
      '  SELECT LPAD(IFNULL(MAX(CAST(NUMERO_FAC AS UNSIGNED)), 0) + 1, 6, ' +
      '''0'') ' +
      '    INTO v_numero FROM fza_facturas WHERE SERIE_FAC = v_serie; ' +
      '  INSERT INTO fza_facturas ( ' +
      '    NUMERO_FAC, SERIE_FAC, FECHA_FAC, FASE_FAC, TIPO_FAC, ' +
      '    CODIGO_EMP_FAC, RAZON_SOCIAL_EMPRESA_FAC, NIF_EMPRESA_FAC, ' +
      '    MOVIL_EMPRESA_FAC, EMAIL_EMPRESA_FAC, ' +
      '    DIRECCION1_EMPRESA_FAC, DIRECCION2_EMPRESA_FAC, ' +
      '    POBLACION_EMPRESA_FAC, PROVINCIA_EMPRESA_FAC, ' +
      '    CODIGO_PAI_EMPRESA_FAC, NOMBRE_PAI_EMPRESA_FAC, ' +
      '    CODIGO_POSTAL_EMPRESA_FAC, GRUPO_ZONA_IVA_EMPRESA_FAC, ' +
      '    CODIGO_CLI_FAC, RAZON_SOCIAL_CLIENTE_FAC, NIF_CLIENTE_FAC, ' +
      '    MOVIL_CLIENTE_FAC, EMAIL_CLIENTE_FAC, ' +
      '    DIRECCION1_CLIENTE_FAC, DIRECCION2_CLIENTE_FAC, ' +
      '    POBLACION_CLIENTE_FAC, PROVINCIA_CLIENTE_FAC, ' +
      '    CODIGO_POSTAL_CLIENTE_FAC, ' +
      '    CODIGO_PAI_CLIENTE_FAC, NOMBRE_PAI_CLIENTE_FAC, ' +
      '    CODIGO_IVA_FAC, ' +
      '    ESIVA_RECARGO_CLIENTE_FAC, ESIVA_EXENTO_CLIENTE_FAC, ' +
      '    ESINTRACOMUNITARIO_CLIENTE_FAC, ' +
      '    TARIFA_ARTICULO_CLIENTE_FAC, ESIMP_INCL_TARIFA_CLIENTE_FAC, ' +
      '    PORCENTAJE_IVAN_FAC, PORCENTAJE_IVAR_FAC, ' +
      '    PORCENTAJE_IVAS_FAC, PORCENTAJE_IVAE_FAC, ' +
      '    FORMA_PAGO_FAC, CONTADOR_LINEAS_FAC, ' +
      '    INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      '  SELECT v_numero, v_serie, CURRENT_DATE(), ''BORRADOR'', ''NORMAL'', ' +
      '         A.CODIGO_EMP_ALB, A.RAZON_SOCIAL_EMPRESA_ALB, ' +
      'A.NIF_EMPRESA_ALB, ' +
      '         A.MOVIL_EMPRESA_ALB, A.EMAIL_EMPRESA_ALB, ' +
      '         A.DIRECCION1_EMPRESA_ALB, A.DIRECCION2_EMPRESA_ALB, ' +
      '         A.POBLACION_EMPRESA_ALB, A.PROVINCIA_EMPRESA_ALB, ' +
      '         A.CODIGO_PAI_EMPRESA_ALB, A.NOMBRE_PAI_EMPRESA_ALB, ' +
      '         A.CODIGO_POSTAL_EMPRESA_ALB, A.GRUPO_ZONA_IVA_EMPRESA_ALB, ' +
      '         A.CODIGO_CLI_ALB, A.RAZON_SOCIAL_CLIENTE_ALB, ' +
      'A.NIF_CLIENTE_ALB, ' +
      '         A.MOVIL_CLIENTE_ALB, A.EMAIL_CLIENTE_ALB, ' +
      '         A.DIRECCION1_CLIENTE_ALB, A.DIRECCION2_CLIENTE_ALB, ' +
      '         A.POBLACION_CLIENTE_ALB, A.PROVINCIA_CLIENTE_ALB, ' +
      '         A.CODIGO_POSTAL_CLIENTE_ALB, ' +
      '         A.CODIGO_PAI_CLIENTE_ALB, A.NOMBRE_PAI_CLIENTE_ALB, ' +
      '         A.CODIGO_IVA_ALB, ' +
      '         A.ESIVA_RECARGO_CLIENTE_ALB, A.ESIVA_EXENTO_CLIENTE_ALB, ' +
      '         A.ESINTRACOMUNITARIO_CLIENTE_ALB, ' +
      '         A.TARIFA_ARTICULO_CLIENTE_ALB, ' +
      'A.ESIMP_INCL_TARIFA_CLIENTE_ALB, ' +
      '         A.PORCENTAJE_IVAN_ALB, A.PORCENTAJE_IVAR_ALB, ' +
      '         A.PORCENTAJE_IVAS_ALB, A.PORCENTAJE_IVAE_ALB, ' +
      '         A.FORMA_PAGO_ALB, ''0'', NOW(), p_USUARIO, p_USUARIO ' +
      '    FROM fza_albaranes A ' +
      '   WHERE A.NUMERO_ALB = p_NUMERO_ALB AND A.SERIE_ALB = p_SERIE_ALB; ' +
      '  SET p_NUMERO_FAC = v_numero; ' +
      '  SET p_SERIE_FAC  = v_serie; ' +
      'END');

    // PRC_ALB_CREAR_FACTURA_LINEA: copia una línea concreta a la factura.
    Run('DROP PROCEDURE IF EXISTS PRC_ALB_CREAR_FACTURA_LINEA');
    Run(
      'CREATE PROCEDURE PRC_ALB_CREAR_FACTURA_LINEA(' +
      '  IN  p_NUMERO_FAC varchar(20),' +
      '  IN  p_SERIE_FAC  varchar(20),' +
      '  IN  p_NUMERO_ALB varchar(20),' +
      '  IN  p_SERIE_ALB  varchar(20),' +
      '  IN  p_LINEA_ALB  varchar(4),' +
      '  IN  p_USUARIO    varchar(100)' +
      ') PRC: BEGIN ' +
      '  DECLARE v_linea_fac varchar(4); ' +
      '  DECLARE v_contador_fac int DEFAULT 0; ' +
      '  DECLARE v_facturada varchar(1); ' +
      '  SELECT IFNULL(ESFACTURADA_ALBLIN, ''N'') INTO v_facturada ' +
      '    FROM fza_albaranes_lineas ' +
      '   WHERE NUMERO_ALB_ALBLIN = p_NUMERO_ALB ' +
      '     AND SERIE_ALB_ALBLIN  = p_SERIE_ALB ' +
      '     AND LINEA_ALBLIN      = p_LINEA_ALB; ' +
      '  IF v_facturada = ''S'' THEN ' +
      '    LEAVE PRC; ' +
      '  END IF; ' +
      '  SELECT IFNULL(CAST(NULLIF(CONTADOR_LINEAS_FAC, '''') ' +
      '         AS UNSIGNED), 0) + 10 ' +
      '    INTO v_contador_fac ' +
      '    FROM fza_facturas ' +
      '   WHERE NUMERO_FAC = p_NUMERO_FAC ' +
      '     AND SERIE_FAC  = p_SERIE_FAC ' +
      '   FOR UPDATE; ' +
      '  IF v_contador_fac = 0 THEN ' +
      '    LEAVE PRC; ' +
      '  END IF; ' +
      '  UPDATE fza_facturas ' +
      '     SET CONTADOR_LINEAS_FAC = LPAD(v_contador_fac, 8, ''0'') ' +
      '   WHERE NUMERO_FAC = p_NUMERO_FAC ' +
      '     AND SERIE_FAC  = p_SERIE_FAC; ' +
      '  IF ROW_COUNT() = 0 THEN ' +
      '    LEAVE PRC; ' +
      '  END IF; ' +
      '  SET v_linea_fac = LPAD(v_contador_fac, 4, ''0''); ' +
      '  INSERT INTO fza_facturas_lineas ( ' +
      '    NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, LINEA_FACLIN, ' +
      '    CODIGO_ART_FACLIN, CODIGO_UNIDAD_FACLIN, ' +
      '    LOTE_FACLIN, FECHA_CADUCIDAD_FACLIN, ' +
      '    CODIGO_FAM_FACLIN, NOMBRE_FAM_FACLIN, ' +
      '    DESCRIPCION_ARTICULO_FACLIN, DESCRIPCION_VARIACION_FACLIN, ' +
      '    TIPO_CANTIDAD_ARTICULO_FACLIN, ' +
      '    CANTIDAD_FACLIN, CODIGO_TAR_FACLIN, ESIMP_INCL_TARIFA_FACLIN, ' +
      '    TIPO_IVA_ARTICULO_FACLIN, PORCENTAJE_IVA_FACLIN, ' +
      '    PRECIO_VENTA_SIVA_ARTICULO_FACLIN, ' +
      '    PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
      '    TOTAL_FACLIN, CODIGO_ALM_FACLIN, ' +
      '    INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      '  SELECT p_NUMERO_FAC, p_SERIE_FAC, v_linea_fac, ' +
      '         AL.CODIGO_ART_ALBLIN, AL.CODIGO_UNIDAD_ALBLIN, ' +
      '         AL.LOTE_ALBLIN, AL.FECHA_CADUCIDAD_ALBLIN, ' +
      '         AL.CODIGO_FAM_ALBLIN, AL.NOMBRE_FAM_ALBLIN, ' +
      '         AL.DESCRIPCION_ARTICULO_ALBLIN, ' +
      'AL.DESCRIPCION_VARIACION_ALBLIN, ' +
      '         AL.TIPO_CANTIDAD_ARTICULO_ALBLIN, ' +
      '         AL.CANTIDAD_ALBLIN, AL.CODIGO_TAR_ALBLIN, ' +
      'AL.ESIMP_INCL_TARIFA_ALBLIN, ' +
      '         AL.TIPO_IVA_ARTICULO_ALBLIN, AL.PORCENTAJE_IVA_ALBLIN, ' +
      '         AL.PRECIO_VENTA_SIVA_ARTICULO_ALBLIN, ' +
      '         AL.PRECIO_VENTA_CIVA_ARTICULO_ALBLIN, ' +
      '         AL.TOTAL_ALBLIN, AL.CODIGO_ALMACEN_ALBLIN, ' +
      '         NOW(), p_USUARIO, p_USUARIO ' +
      '    FROM fza_albaranes_lineas AL ' +
      '   WHERE AL.NUMERO_ALB_ALBLIN = p_NUMERO_ALB ' +
      '     AND AL.SERIE_ALB_ALBLIN  = p_SERIE_ALB ' +
      '     AND AL.LINEA_ALBLIN      = p_LINEA_ALB; ' +
      '  UPDATE fza_albaranes_lineas ' +
      '     SET ESFACTURADA_ALBLIN = ''S'', ' +
      '         NUMERO_FAC_ALBLIN  = p_NUMERO_FAC, ' +
      '         SERIE_FAC_ALBLIN   = p_SERIE_FAC, ' +
      '         LINEA_FAC_ALBLIN   = v_linea_fac, ' +
      '         INSTANTE_MODIF     = NOW(), ' +
      '         USUARIO_MODIF      = p_USUARIO ' +
      '   WHERE NUMERO_ALB_ALBLIN = p_NUMERO_ALB ' +
      '     AND SERIE_ALB_ALBLIN  = p_SERIE_ALB ' +
      '     AND LINEA_ALBLIN      = p_LINEA_ALB; ' +
      'END');

    // PRC_ALB_CREAR_FACTURA_FIN: recalcula totales y marca albarán como
    // facturado
    // si todas sus líneas se han facturado.
    Run('DROP PROCEDURE IF EXISTS PRC_ALB_CREAR_FACTURA_FIN');
    Run(
      'CREATE PROCEDURE PRC_ALB_CREAR_FACTURA_FIN(' +
      '  IN p_NUMERO_FAC varchar(20),' +
      '  IN p_SERIE_FAC  varchar(20),' +
      '  IN p_NUMERO_ALB varchar(20),' +
      '  IN p_SERIE_ALB  varchar(20),' +
      '  IN p_USUARIO    varchar(100)' +
      ') BEGIN ' +
      '  DECLARE v_total_base decimal(18,6) DEFAULT 0; ' +
      '  DECLARE v_total_iva  decimal(18,6) DEFAULT 0; ' +
      '  DECLARE v_pendientes int DEFAULT 0; ' +
      '  SELECT IFNULL(SUM(CANTIDAD_FACLIN * ' +
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN), 0), ' +
      '         IFNULL(SUM(CANTIDAD_FACLIN * ' +
      '(PRECIO_VENTA_CIVA_ARTICULO_FACLIN - ' +
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN)), 0) ' +
      '    INTO v_total_base, v_total_iva ' +
      '    FROM fza_facturas_lineas ' +
      '   WHERE NUMERO_FAC_FACLIN = p_NUMERO_FAC ' +
      '     AND SERIE_FAC_FACLIN  = p_SERIE_FAC; ' +
      '  UPDATE fza_facturas ' +
      '     SET TOTAL_BASES_FAC     = v_total_base, ' +
      '         TOTAL_IMPUESTOS_FAC = v_total_iva, ' +
      '         TOTAL_LIQUIDO_FAC   = v_total_base + v_total_iva, ' +
      '         INSTANTE_MODIF      = NOW(), ' +
      '         USUARIO_MODIF       = p_USUARIO ' +
      '   WHERE NUMERO_FAC = p_NUMERO_FAC AND SERIE_FAC = p_SERIE_FAC; ' +
      '  IF p_NUMERO_ALB IS NOT NULL AND p_NUMERO_ALB <> '''' THEN ' +
      '    SELECT COUNT(*) INTO v_pendientes ' +
      '      FROM fza_albaranes_lineas ' +
      '     WHERE NUMERO_ALB_ALBLIN = p_NUMERO_ALB ' +
      '       AND SERIE_ALB_ALBLIN  = p_SERIE_ALB ' +
      '       AND IFNULL(ESFACTURADA_ALBLIN, ''N'') <> ''S''; ' +
      '    IF v_pendientes = 0 THEN ' +
      '      UPDATE fza_albaranes ' +
      '         SET ESTADO_ALB    = ''FACTURADO'', ' +
      '             NUMERO_FAC_ALB = p_NUMERO_FAC, ' +
      '             SERIE_FAC_ALB  = p_SERIE_FAC, ' +
      '             INSTANTE_MODIF = NOW(), ' +
      '             USUARIO_MODIF  = p_USUARIO ' +
      '       WHERE NUMERO_ALB = p_NUMERO_ALB AND SERIE_ALB = p_SERIE_ALB; ' +
      '    ELSE ' +
      '      UPDATE fza_albaranes ' +
      '         SET ESTADO_ALB    = ''PARCIAL'', ' +
      '             INSTANTE_MODIF= NOW(), ' +
      '             USUARIO_MODIF = p_USUARIO ' +
      '       WHERE NUMERO_ALB = p_NUMERO_ALB AND SERIE_ALB = p_SERIE_ALB; ' +
      '    END IF; ' +
      '  END IF; ' +
      'END');

    FProcsInstalados := True;
  finally
    FreeAndNil(q);
  end;
end;

function TdmAlbaranes.CrearFacturaDesdeAlbaran(out sNumeroFac,
                                               sSerieFac: string;
                                               aLineas: TList<string>): Boolean;
var
  i: Integer;
  sNumeroAlb, sSerieAlb, sLinea: string;
  ds: TDataSet;
  bUsarTodas: Boolean;
  bTransPropia: Boolean;
begin
  sNumeroFac := '';
  sSerieFac  := '';
  InstalarProcedimientos;

  sNumeroAlb := unqryTablaG.FieldByName('NUMERO_ALB').AsString;
  sSerieAlb  := unqryTablaG.FieldByName('SERIE_ALB').AsString;
  bUsarTodas := (aLineas = nil) or (aLineas.Count = 0);

  bTransPropia := not ConexionPrincipal.InTransaction;
  if bTransPropia then
    ConexionPrincipal.StartTransaction;
  try

  // 1) Cabecera de la factura
  with unstrdprcCrearFacturaInicio do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'p_NUMERO_ALB', ptInput);
    Params.CreateParam(ftString, 'p_SERIE_ALB',  ptInput);
    Params.CreateParam(ftString, 'p_USUARIO',    ptInput);
    Params.CreateParam(ftString, 'p_NUMERO_FAC', ptOutput);
    Params.CreateParam(ftString, 'p_SERIE_FAC',  ptOutput);
    ParamByName('p_NUMERO_ALB').AsString := sNumeroAlb;
    ParamByName('p_SERIE_ALB').AsString  := sSerieAlb;
    ParamByName('p_USUARIO').AsString    := IdentidadSesion.Usuario;
    ExecProc;
    sNumeroFac := ParamByName('p_NUMERO_FAC').AsString;
    sSerieFac  := ParamByName('p_SERIE_FAC').AsString;
  end;
  NegarMovimientosFacturaDesdeAlbaran(sSerieFac, sNumeroFac);

  // 2) Líneas: las indicadas, o todas las pendientes si no se pasa lista.
  if bUsarTodas then
  begin
    ds := unqryAlbaranesLineas;
    ds.DisableControls;
    try
      ds.First;
      while not ds.Eof do
      begin
        if (ds.FindField('ESFACTURADA_ALBLIN') = nil) or
           (ds.FieldByName('ESFACTURADA_ALBLIN').AsString <> 'S') then
        begin
          with unstrdprcCrearFacturaLinea do
          begin
            Params.Clear;
            Params.CreateParam(ftString, 'p_NUMERO_FAC', ptInput);
            Params.CreateParam(ftString, 'p_SERIE_FAC',  ptInput);
            Params.CreateParam(ftString, 'p_NUMERO_ALB', ptInput);
            Params.CreateParam(ftString, 'p_SERIE_ALB',  ptInput);
            Params.CreateParam(ftString, 'p_LINEA_ALB',  ptInput);
            Params.CreateParam(ftString, 'p_USUARIO',    ptInput);
            ParamByName('p_NUMERO_FAC').AsString := sNumeroFac;
            ParamByName('p_SERIE_FAC').AsString  := sSerieFac;
            ParamByName('p_NUMERO_ALB').AsString := sNumeroAlb;
            ParamByName('p_SERIE_ALB').AsString  := sSerieAlb;
            ParamByName('p_LINEA_ALB').AsString  :=
              ds.FieldByName('LINEA_ALBLIN').AsString;
            ParamByName('p_USUARIO').AsString    := IdentidadSesion.Usuario;
            ExecProc;
          end;
        end;
        ds.Next;
      end;
    finally
      ds.EnableControls;
    end;
  end
  else
  begin
    for i := 0 to aLineas.Count - 1 do
    begin
      sLinea := aLineas[i];
      if sLinea = '' then Continue;
      with unstrdprcCrearFacturaLinea do
      begin
        Params.Clear;
        Params.CreateParam(ftString, 'p_NUMERO_FAC', ptInput);
        Params.CreateParam(ftString, 'p_SERIE_FAC',  ptInput);
        Params.CreateParam(ftString, 'p_NUMERO_ALB', ptInput);
        Params.CreateParam(ftString, 'p_SERIE_ALB',  ptInput);
        Params.CreateParam(ftString, 'p_LINEA_ALB',  ptInput);
        Params.CreateParam(ftString, 'p_USUARIO',    ptInput);
        ParamByName('p_NUMERO_FAC').AsString := sNumeroFac;
        ParamByName('p_SERIE_FAC').AsString  := sSerieFac;
        ParamByName('p_NUMERO_ALB').AsString := sNumeroAlb;
        ParamByName('p_SERIE_ALB').AsString  := sSerieAlb;
        ParamByName('p_LINEA_ALB').AsString  := sLinea;
        ParamByName('p_USUARIO').AsString    := IdentidadSesion.Usuario;
        ExecProc;
      end;
    end;
  end;

  // 3) Recalcular totales y estado del albarán.
  with unstrdprcCrearFacturaFin do
  begin
    Params.Clear;
    Params.CreateParam(ftString, 'p_NUMERO_FAC', ptInput);
    Params.CreateParam(ftString, 'p_SERIE_FAC',  ptInput);
    Params.CreateParam(ftString, 'p_NUMERO_ALB', ptInput);
    Params.CreateParam(ftString, 'p_SERIE_ALB',  ptInput);
    Params.CreateParam(ftString, 'p_USUARIO',    ptInput);
    ParamByName('p_NUMERO_FAC').AsString := sNumeroFac;
    ParamByName('p_SERIE_FAC').AsString  := sSerieFac;
    ParamByName('p_NUMERO_ALB').AsString := sNumeroAlb;
    ParamByName('p_SERIE_ALB').AsString  := sSerieAlb;
    ParamByName('p_USUARIO').AsString    := IdentidadSesion.Usuario;
    ExecProc;
  end;

    if bTransPropia and ConexionPrincipal.InTransaction then
      ConexionPrincipal.Commit;
  except
    if bTransPropia and ConexionPrincipal.InTransaction then
      ConexionPrincipal.Rollback;
    raise;
  end;

  // 4) Refrescar la pantalla.
  unqryAlbaranesLineas.Close; unqryAlbaranesLineas.Open;
  if unqryFacturas.Active then
  begin
    unqryFacturas.Close;
    unqryFacturas.Open;
  end;
  unqryTablaG.RefreshRecord;
  Result := True;
end;

function TdmAlbaranes.FacturarAlbaranesLista(aListaAlbaranes: TStrings;
                                             bAgruparPorCliente: Boolean): Integer;
var
  i, iSep: Integer;
  sLin, sSer, sNum, sCliActual, sCliAlb: string;
  sNumFac, sSerFac, sNumFacActual, sSerFacActual: string;
  qCli: TUniQuery;
  qLin: TUniQuery;
  bTransPropia: Boolean;
begin
  Result := 0;
  if (aListaAlbaranes = nil) or (aListaAlbaranes.Count = 0) then Exit;
  InstalarProcedimientos;

  qCli := TUniQuery.Create(nil);
  qLin := TUniQuery.Create(nil);
  try
    qCli.Connection := ConexionPrincipal;
    qLin.Connection := ConexionPrincipal;
    qCli.SQL.Text :=
      'SELECT CODIGO_CLI_ALB FROM fza_albaranes ' +
      ' WHERE NUMERO_ALB = :pNUM AND SERIE_ALB = :pSER';
    qLin.SQL.Text :=
      'SELECT LINEA_ALBLIN FROM fza_albaranes_lineas ' +
      ' WHERE NUMERO_ALB_ALBLIN = :pNUM AND SERIE_ALB_ALBLIN = :pSER ' +
      '   AND IFNULL(ESFACTURADA_ALBLIN, ''N'') <> ''S'' ' +
      ' ORDER BY LINEA_ALBLIN';

    bTransPropia := not ConexionPrincipal.InTransaction;
    if bTransPropia then
      ConexionPrincipal.StartTransaction;
    try

    sCliActual    := '';
    sNumFacActual := '';
    sSerFacActual := '';

    for i := 0 to aListaAlbaranes.Count - 1 do
    begin
      sLin := aListaAlbaranes[i];
      iSep := Pos('|', sLin);
      if iSep <= 0 then Continue;
      sSer := Copy(sLin, 1, iSep - 1);
      sNum := Copy(sLin, iSep + 1, MaxInt);

      // Resolver cliente del albarán
      qCli.Close;
      qCli.ParamByName('pNUM').AsString := sNum;
      qCli.ParamByName('pSER').AsString := sSer;
      qCli.Open;
      if qCli.Eof then
      begin
        qCli.Close;
        Continue;
      end;
      sCliAlb := qCli.FieldByName('CODIGO_CLI_ALB').AsString;
      qCli.Close;

      // Decidir si reutilizar la factura previa o crear una nueva.
      if (not bAgruparPorCliente) or
         (sNumFacActual = '') or
         (sCliAlb <> sCliActual) then
      begin
        // Crear nueva cabecera
        with unstrdprcCrearFacturaInicio do
        begin
          Params.Clear;
          Params.CreateParam(ftString, 'p_NUMERO_ALB', ptInput);
          Params.CreateParam(ftString, 'p_SERIE_ALB',  ptInput);
          Params.CreateParam(ftString, 'p_USUARIO',    ptInput);
          Params.CreateParam(ftString, 'p_NUMERO_FAC', ptOutput);
          Params.CreateParam(ftString, 'p_SERIE_FAC',  ptOutput);
          ParamByName('p_NUMERO_ALB').AsString := sNum;
          ParamByName('p_SERIE_ALB').AsString  := sSer;
          ParamByName('p_USUARIO').AsString    := IdentidadSesion.Usuario;
          ExecProc;
          sNumFac := ParamByName('p_NUMERO_FAC').AsString;
          sSerFac := ParamByName('p_SERIE_FAC').AsString;
        end;
        NegarMovimientosFacturaDesdeAlbaran(sSerFac, sNumFac);
        sNumFacActual := sNumFac;
        sSerFacActual := sSerFac;
        sCliActual    := sCliAlb;
        Inc(Result);
      end
      else
      begin
        sNumFac := sNumFacActual;
        sSerFac := sSerFacActual;
      end;

      // Volcar todas las líneas pendientes del albarán a la factura actual.
      qLin.Close;
      qLin.ParamByName('pNUM').AsString := sNum;
      qLin.ParamByName('pSER').AsString := sSer;
      qLin.Open;
      while not qLin.Eof do
      begin
        with unstrdprcCrearFacturaLinea do
        begin
          Params.Clear;
          Params.CreateParam(ftString, 'p_NUMERO_FAC', ptInput);
          Params.CreateParam(ftString, 'p_SERIE_FAC',  ptInput);
          Params.CreateParam(ftString, 'p_NUMERO_ALB', ptInput);
          Params.CreateParam(ftString, 'p_SERIE_ALB',  ptInput);
          Params.CreateParam(ftString, 'p_LINEA_ALB',  ptInput);
          Params.CreateParam(ftString, 'p_USUARIO',    ptInput);
          ParamByName('p_NUMERO_FAC').AsString := sNumFac;
          ParamByName('p_SERIE_FAC').AsString  := sSerFac;
          ParamByName('p_NUMERO_ALB').AsString := sNum;
          ParamByName('p_SERIE_ALB').AsString  := sSer;
          ParamByName('p_LINEA_ALB').AsString  :=
            qLin.FieldByName('LINEA_ALBLIN').AsString;
          ParamByName('p_USUARIO').AsString    := IdentidadSesion.Usuario;
          ExecProc;
        end;
        qLin.Next;
      end;
      qLin.Close;

      // Cerrar el albarán: marcar como facturado si no quedan líneas
      // pendientes.
      with unstrdprcCrearFacturaFin do
      begin
        Params.Clear;
        Params.CreateParam(ftString, 'p_NUMERO_FAC', ptInput);
        Params.CreateParam(ftString, 'p_SERIE_FAC',  ptInput);
        Params.CreateParam(ftString, 'p_NUMERO_ALB', ptInput);
        Params.CreateParam(ftString, 'p_SERIE_ALB',  ptInput);
        Params.CreateParam(ftString, 'p_USUARIO',    ptInput);
        ParamByName('p_NUMERO_FAC').AsString := sNumFac;
        ParamByName('p_SERIE_FAC').AsString  := sSerFac;
        ParamByName('p_NUMERO_ALB').AsString := sNum;
        ParamByName('p_SERIE_ALB').AsString  := sSer;
        ParamByName('p_USUARIO').AsString    := IdentidadSesion.Usuario;
        ExecProc;
      end;
    end;

      if bTransPropia and ConexionPrincipal.InTransaction then
        ConexionPrincipal.Commit;
    except
      if bTransPropia and ConexionPrincipal.InTransaction then
        ConexionPrincipal.Rollback;
      raise;
    end;
  finally
    FreeAndNil(qCli);
    FreeAndNil(qLin);
  end;

  // Refrescar la pantalla del albarán activo.
  if unqryTablaG.Active then unqryTablaG.Refresh;
  if unqryAlbaranesLineas.Active then
  begin
    unqryAlbaranesLineas.Close;
    unqryAlbaranesLineas.Open;
  end;
  if unqryFacturas.Active then
  begin
    unqryFacturas.Close;
    unqryFacturas.Open;
  end;
end;

function TdmAlbaranes.GenerarMovimientosSalida: Integer;
var
  qLineas: TUniQuery;
  qExiste: TUniQuery;
  qFechaMov: TUniQuery;
  sNumeroAlb, sSerieAlb, sEmpresa, sCliente: string;
  sAlmacenCabecera: string;
  sLinea, sSku, sAlmacen, sArticulo, sNumeroMov: string;
  dFechaAlb: TDateTime;
  fCantidad: Double;
begin
  Result := 0;
  if not unqryTablaG.Active then Exit;
  sNumeroAlb := unqryTablaG.FieldByName('NUMERO_ALB').AsString;
  sSerieAlb  := unqryTablaG.FieldByName('SERIE_ALB').AsString;
  if (sNumeroAlb = '') or (sNumeroAlb = '0') then Exit;
  sEmpresa := unqryTablaG.FieldByName('CODIGO_EMP_ALB').AsString;
  sCliente := unqryTablaG.FieldByName('CODIGO_CLI_ALB').AsString;
  dFechaAlb := Date;
  if unqryTablaG.FindField('FECHA_ALB') <> nil then
    if not unqryTablaG.FieldByName('FECHA_ALB').IsNull then
      dFechaAlb := unqryTablaG.FieldByName('FECHA_ALB').AsDateTime;
  sAlmacenCabecera := '';
  if unqryTablaG.FindField('CODIGO_ALM_ALB') <> nil then
    sAlmacenCabecera := Trim(unqryTablaG.FieldByName('CODIGO_ALM_ALB').AsString);

  qLineas := TUniQuery.Create(nil);
  qExiste := TUniQuery.Create(nil);
  qFechaMov := TUniQuery.Create(nil);
  try
    qLineas.Connection := unqryTablaG.Connection;
    qLineas.SQL.Text :=
      'SELECT LINEA_ALBLIN, CODIGO_UNIDAD_ALBLIN, CODIGO_ART_ALBLIN, ' +
      '       CANTIDAD_ALBLIN, CODIGO_ALMACEN_ALBLIN ' +
      '  FROM fza_albaranes_lineas ' +
      ' WHERE NUMERO_ALB_ALBLIN = :pNUM ' +
      '   AND SERIE_ALB_ALBLIN  = :pSER ' +
      ' ORDER BY LINEA_ALBLIN';
    qLineas.ParamByName('pNUM').AsString := sNumeroAlb;
    qLineas.ParamByName('pSER').AsString := sSerieAlb;
    qLineas.Open;

    qExiste.Connection := unqryTablaG.Connection;
    qExiste.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_movimientos_almacen ' +
      ' WHERE TIPO_DOC_MOV   = ''AV'' ' +
      '   AND SERIE_DOC_MOV  = :pSER ' +
      '   AND NUMERO_DOC_MOV = :pNUM ' +
      '   AND LINEA_MOV      = :pLIN';
    qFechaMov.Connection := unqryTablaG.Connection;
    qFechaMov.SQL.Text :=
      'UPDATE fza_movimientos_almacen ' +
      '   SET FECHA_MOV = :pFECHA ' +
      ' WHERE NUMERO_MOV = :pNUMMOV';

    qLineas.First;
    while not qLineas.Eof do
    begin
      sLinea    := qLineas.FieldByName('LINEA_ALBLIN').AsString;
      sSku      := Trim(qLineas.FieldByName('CODIGO_UNIDAD_ALBLIN').AsString);
      sArticulo := qLineas.FieldByName('CODIGO_ART_ALBLIN').AsString;
      fCantidad := qLineas.FieldByName('CANTIDAD_ALBLIN').AsFloat;
      sAlmacen  := Trim(qLineas.FieldByName('CODIGO_ALMACEN_ALBLIN').AsString);
      if sAlmacen = '' then
        sAlmacen := sAlmacenCabecera;

      if (sLinea <> '') and (StrToIntDef(sLinea, 0) > 0) and
         (sSku <> '') and (sAlmacen <> '') and (fCantidad > 0) then
      begin
        // ¿Ya hay movimiento para esta línea? Si es así, saltar.
        qExiste.Close;
        qExiste.ParamByName('pSER').AsString := sSerieAlb;
        qExiste.ParamByName('pNUM').AsString := sNumeroAlb;
        qExiste.ParamByName('pLIN').AsString := sLinea;
        qExiste.Open;
        if qExiste.FieldByName('N').AsInteger = 0 then
        begin
          with unstrdprcInsertarMovAlb do
          begin
            Connection := unqryTablaG.Connection;
            Params.Clear;
            Params.CreateParam(ftString, 'p_NUMERO_MOV',          ptInput);
            Params.CreateParam(ftString, 'p_TIPO_DOC_MOV',        ptInput);
            Params.CreateParam(ftString, 'p_SERIE_DOC_MOV',       ptInput);
            Params.CreateParam(ftString, 'p_NRO_DOC_MOV',         ptInput);
            Params.CreateParam(ftString, 'p_LINEA_MOV',           ptInput);
            Params.CreateParam(ftString, 'p_CODIGO_EMPRESA_MOV',  ptInput);
            Params.CreateParam(ftString, 'p_CODIGO_ALMACEN_MOV',  ptInput);
            Params.CreateParam(ftString,
                               'p_CODIGO_ALMACEN_CONTRA_MOV',
                               ptInput);
            Params.CreateParam(ftString, 'p_CODIGO_UNIDAD_MOV',   ptInput);
            Params.CreateParam(ftString, 'p_TIPO_MOVIMIENTO_MOV', ptInput);
            Params.CreateParam(ftBCD,    'p_CANTIDAD_MOV',        ptInput);
            Params.CreateParam(ftBCD,    'p_PRECIO_MEDIO_MOV',    ptInput);
            Params.CreateParam(ftBCD,    'p_TOTAL_COSTE_MOV',     ptInput);
            Params.CreateParam(ftString, 'p_USUARIO',             ptInput);
            Params.CreateParam(ftString, 'p_ALMACEN_DOC',         ptInput);
            Params.CreateParam(ftString, 'p_NUMOP_DOC',           ptInput);
            Params.CreateParam(ftString, 'p_CODIGO_CAJA_DOC_MOV', ptInput);
            Params.CreateParam(ftString, 'p_CODCLIENTE',          ptInput);
            Params.CreateParam(ftString, 'p_CODARTICULO',         ptInput);
            sNumeroMov := ObtenerSiguienteContador(
              ConexionPrincipal,
              'MV',
              IdentidadSesion.Usuario);
            ParamByName('p_NUMERO_MOV').AsString          := sNumeroMov;
            ParamByName('p_TIPO_DOC_MOV').AsString        := 'AV';
            ParamByName('p_SERIE_DOC_MOV').AsString       := sSerieAlb;
            ParamByName('p_NRO_DOC_MOV').AsString         := sNumeroAlb;
            ParamByName('p_LINEA_MOV').AsString           := sLinea;
            ParamByName('p_CODIGO_EMPRESA_MOV').AsString  := sEmpresa;
            ParamByName('p_CODIGO_ALMACEN_MOV').AsString  := sAlmacen;
            ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').Clear;
            ParamByName('p_CODIGO_UNIDAD_MOV').AsString   := sSku;
            ParamByName('p_TIPO_MOVIMIENTO_MOV').AsString := 'S';
            ParamByName('p_CANTIDAD_MOV').AsFloat         := fCantidad;
            ParamByName('p_PRECIO_MEDIO_MOV').AsFloat     := 0;
            ParamByName('p_TOTAL_COSTE_MOV').AsFloat      := 0;
            ParamByName('p_USUARIO').AsString             := IdentidadSesion.Usuario;
            ParamByName('p_ALMACEN_DOC').AsString         := sAlmacen;
            ParamByName('p_NUMOP_DOC').AsString           := '';
            ParamByName('p_CODIGO_CAJA_DOC_MOV').AsString := '';
            ParamByName('p_CODCLIENTE').AsString          := sCliente;
            ParamByName('p_CODARTICULO').AsString         := sArticulo;
            ExecProc;
          end;
          qFechaMov.ParamByName('pFECHA').AsDateTime := dFechaAlb;
          qFechaMov.ParamByName('pNUMMOV').AsString := sNumeroMov;
          qFechaMov.ExecSQL;
          Inc(Result);
        end;
        qExiste.Close;
      end;
      if ((sLinea = '') or (StrToIntDef(sLinea, 0) = 0) or
          (sSku = '') or (sAlmacen = '')) and (fCantidad > 0) then
        inLibLog.Log.LogWarning(Format(
          'Albaran %s/%s linea %s sin movimiento AV. Articulo=%s, ' +
          'SKU=%s, almacen=%s.',
          [sSerieAlb, sNumeroAlb, sLinea, sArticulo, sSku, sAlmacen]));
      qLineas.Next;
    end;
  finally
    FreeAndNil(qLineas);
    FreeAndNil(qExiste);
    FreeAndNil(qFechaMov);
  end;

  // Refrescar el grid de movimientos si está abierto.
  if unqryMovimientosAlb.Active then
  begin
    unqryMovimientosAlb.Close;
    unqryMovimientosAlb.Open;
  end;
end;

end.
