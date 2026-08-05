{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturas                                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de facturas.                                                  }
{    Cabeceras y líneas de fza_facturas, series, recibos, abonos y procesos de }
{    cálculo.                                                                  }
{******************************************************************************}
unit UniDataFacturas;

interface

uses
  inLibRegistroPantallas,
  SysUtils, Classes,  DB,
   DBClient, Provider, frxClass, frxDBSet, inLibUser,
   System.StrUtils, Windows, System.Variants,
   MemDS, DBAccess, Uni,
   UniDataGen, frCoreClasses, inLibArticulosResolverIntf,
   inLibFacturasServiciosIntf;

procedure RevertirBorradoFactura(
  const AServicio: IServicioBorradoFactura);

type
  TdmFacturas = class(TdmBase)
    dsLinFac: TDataSource;
    dsFacPrint: TDataSource;
    dsLinFacPrint: TDataSource;
    dsSeries: TDataSource;
    fxdsPrintFac: TfrxDBDataset;
    fxdstPrintLinFac: TfrxDBDataset;
    unqryFacPrint: TUniQuery;
    unqryLinFacPrint: TUniQuery;
    unqrySeries: TUniQuery;
    unqryCliDataFac: TUniQuery;
    unqryArtDataLinFac: TUniQuery;
    unqryLinFac: TUniQuery;
    unstrdprcCrearFacturaAbono: TUniStoredProc;
    unstrdprcDuplicarFactura: TUniStoredProc;
    unstrdprcGetDataArticulo: TUniStoredProc;
    unstrdprcGetDataCliente: TUniStoredProc;
    dsFormasPago: TDataSource;
    unqryFormaPago: TUniQuery;
    dsVerifactuOpe: TDataSource;
    unqryVerifactuOpe: TUniQuery;
    dsRecibos: TDataSource;
    unqryRecibos: TUniQuery;
    dsRecibosPrint: TDataSource;
    fxdsRecibos: TfrxDBDataset;
    unqryRecibosPrint: TUniQuery;
    unstrdprcGetRecibos: TUniStoredProc;
    unqryIvas: TUniQuery;
    dsIvas: TDataSource;
    unqryEmpDataFac: TUniQuery;
    dsTarifas: TDataSource;
    unqryTarifas: TUniQuery;
    unstdGetContadorLinea: TUniStoredProc;
    unstdCalcularFactura: TUniStoredProc;
    dsSeriesEditCombo: TDataSource;
    unqrySeriesEditCombo: TUniQuery;
    unstrdprcGetContadorFactura: TUniStoredProc;
    unqryIvasTipos: TUniQuery;
    dsIvasTipos: TDataSource;
    dsFactura: TDataSource;
    unstdCrearArticuloLin: TUniStoredProc;
    dsPaisesCli: TDataSource;
    unqryPaisesCli: TUniQuery;
    unqryPaisesEmp: TUniQuery;
    dsPaisesEmp: TDataSource;
    dsConsolidacion: TDataSource;
    unqryConsolidacion: TUniQuery;
    dsErrores: TDataSource;
    unqryErrores: TUniQuery;
    unqryMovimientosFac: TUniQuery;
    dsMovimientosFac:    TDataSource;
    unqryAlmacenesFac:   TUniQuery;
    dsAlmacenesFac:      TDataSource;
    unqryEfectosVenta:   TUniQuery;
    dsEfectosVenta:      TDataSource;
    unstrdprcInsertarMovFac: TUniStoredProc;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryLinFacBeforeInsert(DataSet: TDataSet);
    procedure unqryFacBeforePost(DataSet: TDataSet);
    procedure unqryLinFacAfterPost(DataSet: TDataSet);
    procedure unqryFacAfterPost(DataSet: TDataSet);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryLinFacAfterInsert(DataSet: TDataSet);
    procedure unqryLinFacBeforePost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryTablaGAfterDeleteTx(DataSet: TDataSet);
    procedure unqryTablaGDeleteErrorTx(DataSet: TDataSet;
      E: EDatabaseError; var Action: TDataAction);
    procedure unqryLinFacAfterDelete(DataSet: TDataSet);
    procedure dsLinFacStateChange(Sender: TObject);
    procedure unqryLinFacBeforeEdit(DataSet: TDataSet);
private
    // Guarda de re-entrancia del BeforePost de la cabecera.
    FValidandoPost: Boolean;
    // Evita que los Post internos del motor disparen otro cálculo completo.
    FCalculandoFactura: Boolean;
    // Agrupa los cambios del editor y recalcula el documento una vez al Post.
    FRecalculoFacturaPendiente: Boolean;
    // True mientras DesempaquetarAtributosLineas postea lineas: cambio
    // puramente descriptivo que NO debe disparar numeracion, creacion
    // de articulos ni recalculos (cascada por linea al navegar).
    FDesempaquetandoAtributos: Boolean;
    FRepositorio: IRepositorioFacturas;
    FArticulosResolver: IArticulosResolver;
    FValidadorFiscal: IValidadorFiscalFactura;
    FCalculador: ICalculadorFactura;
    FServicioBorrado: IServicioBorradoFactura;
    FServicioEfectos: IServicioEfectosFactura;
    FAdvertenciasPendientes: TStringList;
    FOnResultadoOperacion: TResultadoOperacionFacturaEvent;
    FOnResultadoBorrado: TResultadoBorradoFacturaEvent;
    FOnAdvertencia: TAdvertenciaFacturaEvent;
    FOnValidacion: TValidacionFacturaEvent;
    FOnConfirmarBorrado: TConfirmarBorradoFacturaEvent;
    FOnNuevaFactura: TNotifyEvent;
    FOnSeriesCambiadas: TNotifyEvent;
    FOnLinFacEstado: TNotifyEvent;
    // Tipo de las facturas nuevas (NORMAL / SIMPLIFICADA); lo fija el
    // form al crear el DM (antes se leia del form en el AfterInsert).
    FTipoFacturaDefecto: string;
    // Copia a los parámetros de la query los valores de los campos del
    // maestro (MasterSource) que se llamen igual. UniDAC solo rellena
    // los parámetros al hacer scroll del maestro con el detail ya
    // abierto; en la apertura perezosa (pestañas lazy) la query se abre
    // después de posicionar el maestro y se quedaba con parámetros NULL
    // (pestañas Verifactu y Movimientos vacías).
    procedure RellenarParamsDesdeMaestro(AQry: TUniQuery);
    // Helpers de validacion de coherencia en el BeforePost de la cabecera.
    function UltimaFechaSerie(const ASerie, AEmpresa,
                              ANumero: string): TDateTime;
    function HayHuecoNumeracion(const ASerie, AEmpresa,
                                ANumero: string): Boolean;
    procedure ValidarOperacionVfactu;
    // Cuerpo real del BeforePost de la cabecera. Lo invoca el wrapper
    // unqryFacBeforePost dentro de la guarda de re-entrancia.
    procedure ValidarCabeceraBeforePost(DataSet: TDataSet);
    procedure RequerirServiciosFactura;
    procedure NotificarResultadoOperacion(
      const AResultado: TResultadoOperacionFactura);
    procedure NotificarResultadoBorrado(
      const AResultado: TResultadoBorradoFactura);
    procedure RegistrarAdvertencia(
      const AMensaje: string;
      ADiferir: Boolean);
    procedure NotificarAdvertenciasPendientes;
    procedure GuardarParametrosEDocFactura(ADataSet: TDataSet);
    procedure GuardarOpcionMovimientosFactura(ADataSet: TDataSet);
    procedure ProcesarFacturaPosteada(ADataSet: TDataSet);
    function FacturaPermiteRecalcularLineas: Boolean;
    // True si el borrador genera movimientos de stock al consolidar:
    // SIMPLIFICADA siempre; NORMAL solo con el check ESMUEVE_STOCK_FAC.
    // Si no los genera, el almacen de la factura es OPCIONAL.
    function FacturaGeneraMovimientos: Boolean;
    // True si facturas_columnas_sku.sql esta aplicado (ATTR1..5 +
    // NUM_ATRIBUTOS en fza_facturas_lineas). Sin la migracion, los
    // SQL de lineas se quedan como en el dfm: incluir los parametros
    // ATTR* sin campo daba 'Not found field corresponding parameter'.
    function ColumnasSkuLineasAplicadas: Boolean;
    procedure PrepararCabeceraSinCamposComplejos;
    procedure QuitarCampoComplejoCabecera(ALista: TStrings;
                                          const ACampo: string);
public
    procedure ConfigurarServicios(
      const AServicios: TServiciosFactura);
    procedure GetCodigoAutoFactura;
    // Numero total de prendas (suma CANTIDAD_FACLIN de todas las lineas).
    // Se muestra en la pestana Totales; no se persiste en BBDD.
    function TotalPrendasFactura: Double;
    // Contrato ColumnSKUcxGrid: trocea CODIGO_UNIDAD_FACLIN en las
    // columnas reales ATTR1..5_VALOR_FACLIN + NUM_ATRIBUTOS_FACLIN para
    // que el modo Desglose/Tallas pinte Color/Talla. Idempotente por
    // comparacion (mismo criterio que TdmPedidos). No hace nada si la
    // migracion facturas_columnas_sku.sql no esta aplicada.
    procedure DesempaquetarAtributosLineas;
    procedure GetCodigoAutoCliente;
    procedure GetCodigoAutoEmpresa;
    procedure CrearCliente;
    procedure CrearEmpresa;
    procedure CalcularRetencionesEmpresa;
    procedure CrearTablaSeries(sEmpresa, sCliente:string; dtFecha:TDateTime);
    procedure CopiarEmpresaaFactura(DataSet:TDataSet);
    procedure CopiarClienteaFactura(DataSet:TDataSet);
    procedure CopiarArticuloaLinea(DataSet:TDataSet);
    procedure MarcarRecalculoFacturaPendiente;
    function FormaPagoDefault:String;
    function TarifaDefault:string;
    function BuscarCliente(s: string):Boolean;
    procedure AsignarIVA(s:string; unqryT:TUniQuery);
    function GetCodigoGrupoIVAAGricola:String;
    function GetUserEmpresaDef:String;
    function CalcularFactura: TResultadoOperacionFactura;
    procedure RefrescarAlmacenes(const ACodigoEmpresa: string);
    function GetTipoIVA(sTipoIVA:string):Currency;
    function ExisteSerieEmpresa(sSerie,
                                sEmpresa,
                                sTipoDoc:string): Boolean;
    function GetSubtipoSerieEmpresa(sSerie,
                                    sEmpresa:string;
                                    dtFecha:TDateTime): string;
    procedure OpenTables;
    // Override: abre las queries lookup + la query de la pestaña detail
    // por defecto (LineasFactura). Las queries de las pestañas Recibos,
    // Verifactu/Consolidacion, Registro/Errores y MovimientosFac son
    // lazy: solo se abren al activarse esa pestaña (ver
    // TfrmMtoFacturasBase.PcDetailChange).
    procedure AbrirDetalles; override;
    // Carga perezosa de sub-pestañas detail de la ficha de factura.
    procedure AsegurarRecibosAbierta;
    procedure AsegurarEfectosVentaAbierta;
    procedure AsegurarConsolidacionAbierta;
    procedure AsegurarErroresAbierta;
    procedure AsegurarMovimientosFacAbierta;
    // Estampa la cuenta de la empresa (ingreso) elegida en los recibos de
    // la factura (serie/numero) despues de generarlos.
    procedure EstamparBancoRecibos(const ASerie, ANumero,
                                   ACodEmpban, AIban: string);
    // Cuenta de la empresa (ingreso) por defecto del cliente
    // (CODIGO_EMPBAN_CLI) para pre-seleccionarla en el modal de banco al
    // generar recibos. '' si no tiene.
    function GetBancoDefectoCliente(const ACodigoCli: string): string;
    function GenerarEfectosVenta(const ACodEmpban: string = '';
                                 const AIbanEmp: string = ''): Integer;
    function RegistrarCobroEfectoVenta(ANumEfecto: Integer;
      AFecha: TDateTime; AImporte: Double;
      const ATipo, AReferencia: string): Integer;
    function CambiarEstadoEfectoVenta(const AEstado: string): Boolean;

    // Cablea los detalles (lineas, recibos, efectos, consolidacion,
    // errores, movimientos) al datasource de cabecera que aporta el
    // form. Antes DataModuleCreate lo tomaba del form directamente.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    property OnResultadoOperacion: TResultadoOperacionFacturaEvent
      read FOnResultadoOperacion write FOnResultadoOperacion;
    property OnResultadoBorrado: TResultadoBorradoFacturaEvent
      read FOnResultadoBorrado write FOnResultadoBorrado;
    property OnAdvertencia: TAdvertenciaFacturaEvent
      read FOnAdvertencia write FOnAdvertencia;
    property OnValidacion: TValidacionFacturaEvent
      read FOnValidacion write FOnValidacion;
    property OnConfirmarBorrado: TConfirmarBorradoFacturaEvent
      read FOnConfirmarBorrado write FOnConfirmarBorrado;
    property OnNuevaFactura: TNotifyEvent
      read FOnNuevaFactura write FOnNuevaFactura;
    property OnSeriesCambiadas: TNotifyEvent
      read FOnSeriesCambiadas write FOnSeriesCambiadas;
    property OnLinFacEstado: TNotifyEvent
      read FOnLinFacEstado write FOnLinFacEstado;
    property TipoFacturaDefecto: string
      read FTipoFacturaDefecto write FTipoFacturaDefecto;
  end;
implementation

uses
  UniDataValoresAutomaticosRepositorio,

  System.Diagnostics,
  inLibFacturas,
  UniDataAlmacenesEmpresaRepositorio,
  inLibVerifactu,
  inLibDocumentoFiscal,
  inLibDocumento,
  inLibDocumentoIntf,
  inLibArticulosValidadorIntf,
  UniDataArticulosValidadorRepositorio,
  inLibLicenciaAplicacion,
  UniDataLicenciaAplicacionRepositorio,
  inLibVentasImpuestos,
  inLibContadorLineas,
  UniDataContadorLineasRepositorio,
  inLibFacturasValidacionCabecera,
  inLibFacturasValidacionDatos,
  inLibFacturasValidacionUniDAC,
  inLibMsgFacturas, inLibMsgVentas,
  inLibSqlSeguro;

{$R *.dfm}

const
  CAMPOS_COMPLEJOS_CABECERA: array[0..1] of string = (
    'DOCUMENTO_FAC',
    'XML_FAC'
  );

procedure RevertirBorradoFactura(
  const AServicio: IServicioBorradoFactura);
begin
  if Assigned(AServicio) then
    AServicio.Revertir;
end;

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmFacturas.ConfigurarServicios(
  const AServicios: TServiciosFactura);
begin
  FRepositorio := AServicios.Repositorio;
  FArticulosResolver := AServicios.ArticulosResolver;
  FValidadorFiscal := AServicios.ValidadorFiscal;
  FCalculador := AServicios.Calculador;
  FServicioBorrado := AServicios.Borrado;
  FServicioEfectos := AServicios.Efectos;
end;

procedure TdmFacturas.RequerirServiciosFactura;
begin
  if (not Assigned(FRepositorio)) or
     (not Assigned(FArticulosResolver)) or
     (not Assigned(FValidadorFiscal)) or
     (not Assigned(FCalculador)) or
     (not Assigned(FServicioBorrado)) or
     (not Assigned(FServicioEfectos)) then
  begin
    raise Exception.Create(
      'Los servicios de factura no están configurados');
  end;
end;

procedure TdmFacturas.NotificarResultadoOperacion(
  const AResultado: TResultadoOperacionFactura);
begin
  if Assigned(FOnResultadoOperacion) then
    FOnResultadoOperacion(AResultado);
end;

procedure TdmFacturas.NotificarResultadoBorrado(
  const AResultado: TResultadoBorradoFactura);
begin
  if Assigned(FOnResultadoBorrado) then
    FOnResultadoBorrado(AResultado);
end;

procedure TdmFacturas.RegistrarAdvertencia(
  const AMensaje: string;
  ADiferir: Boolean);
begin
  if ADiferir then
  begin
    FAdvertenciasPendientes.Add(AMensaje);
  end
  else if Assigned(FOnAdvertencia) then
  begin
    FOnAdvertencia(AMensaje);
  end;
end;

procedure TdmFacturas.NotificarAdvertenciasPendientes;
var
  Mensaje: string;
begin
  while FAdvertenciasPendientes.Count > 0 do
  begin
    Mensaje := FAdvertenciasPendientes[0];
    FAdvertenciasPendientes.Delete(0);
    if Assigned(FOnAdvertencia) then
      FOnAdvertencia(Mensaje);
  end;
end;

function  TdmFacturas.ExisteSerieEmpresa(sSerie,
                                         sEmpresa,
                                         sTipoDoc:string): Boolean;
begin
  RequerirServiciosFactura;
  Result := FRepositorio.ExisteSerieOtraEmpresa(
    sSerie,
    sEmpresa,
    sTipoDoc);
end;

// Fecha de la ultima factura ya emitida (no borrador) de la misma serie y
// empresa, excluyendo la actual. 0 si no hay ninguna.
function TdmFacturas.UltimaFechaSerie(const ASerie, AEmpresa,
  ANumero: string): TDateTime;
begin
  RequerirServiciosFactura;
  Result := FRepositorio.UltimaFechaSerie(
    ASerie,
    AEmpresa,
    ANumero);
end;

// True si entre la ultima factura de la serie y la actual queda un hueco de
// numeracion (la ley exige numeracion correlativa, ese numero debe cubrirse).
function TdmFacturas.HayHuecoNumeracion(const ASerie, AEmpresa,
  ANumero: string): Boolean;
begin
  RequerirServiciosFactura;
  Result := FRepositorio.HayHuecoNumeracion(
    ASerie,
    AEmpresa,
    ANumero);
end;

// Detecta incoherencias flagrantes entre el tipo de operacion Verifactu,
// el pais del cliente y el IVA de la factura.
procedure TdmFacturas.ValidarOperacionVfactu;
var
  Solicitud: TSolicitudValidacionFiscalFactura;
begin
  RequerirServiciosFactura;
  Solicitud.TipoOperacion :=
    unqryTablaG.FieldByName(
      'TIPO_OPER_VFACTU_FAC').AsString;
  Solicitud.CodigoPaisCliente :=
    unqryTablaG.FieldByName(
      'CODIGO_PAI_CLIENTE_FAC').AsString;
  Solicitud.NifCliente :=
    unqryTablaG.FieldByName(
      'NIF_CLIENTE_FAC').AsString;
  Solicitud.TotalImpuestos :=
    unqryTablaG.FieldByName(
      'TOTAL_IMPUESTOS_FAC').AsCurrency;
  FValidadorFiscal.Validar(Solicitud);
end;

function TdmFacturas.GetSubtipoSerieEmpresa(
  sSerie, sEmpresa: string;
  dtFecha: TDateTime): string;
var
  unqrySol: TUniQuery;
begin
  Result := '';
  if (sSerie <> '') and
     (sEmpresa <> '') then
  begin
    unqrySol := TUniQuery.Create(nil);
    try
      unqrySol.Connection := ConexionPrincipal;
      unqrySol.SQL.Text :=
        'SELECT S.SUBTIPO_EMPSER ' +
        '  FROM fza_empresas_series S ' +
        ' INNER JOIN fza_empresas E ' +
        '    ON E.CODIGO_EMP_EMP = S.CODIGO_EMP_EMPSER ' +
        ' WHERE S.CODIGO_EMP_EMPSER = :EMPRESA ' +
        '   AND (S.EMPSER = :SERIE ' +
        '        OR (E.ESTOKENS_CALENDARIO_NATURAL_EMP = ''S'' ' +
        '        AND NULLIF(TRIM(S.SERIE_TOKENIZADA_EMPSER), '''') ' +
        '            IS NOT NULL ' +
        '        AND (LOCATE(BINARY ''yyyy'', BINARY ' +
        '             TRIM(S.SERIE_TOKENIZADA_EMPSER)) > 0 ' +
        '          OR LOCATE(BINARY ''q'', BINARY ' +
        '             TRIM(S.SERIE_TOKENIZADA_EMPSER)) > 0 ' +
        '          OR LOCATE(BINARY ''mm'', BINARY ' +
        '             TRIM(S.SERIE_TOKENIZADA_EMPSER)) > 0 ' +
        '          OR LOCATE(BINARY ''dd'', BINARY ' +
        '             TRIM(S.SERIE_TOKENIZADA_EMPSER)) > 0) ' +
        '        AND CHAR_LENGTH(TRIM(S.SERIE_TOKENIZADA_EMPSER)) - ' +
        '            CHAR_LENGTH(REPLACE(' +
        '            TRIM(S.SERIE_TOKENIZADA_EMPSER), ' +
        '            ''yyyy'', '''')) IN (0, 4) ' +
        '        AND CHAR_LENGTH(TRIM(S.SERIE_TOKENIZADA_EMPSER)) - ' +
        '            CHAR_LENGTH(REPLACE(' +
        '            TRIM(S.SERIE_TOKENIZADA_EMPSER), ' +
        '            ''q'', '''')) IN (0, 1) ' +
        '        AND CHAR_LENGTH(TRIM(S.SERIE_TOKENIZADA_EMPSER)) - ' +
        '            CHAR_LENGTH(REPLACE(' +
        '            TRIM(S.SERIE_TOKENIZADA_EMPSER), ' +
        '            ''mm'', '''')) IN (0, 2) ' +
        '        AND CHAR_LENGTH(TRIM(S.SERIE_TOKENIZADA_EMPSER)) - ' +
        '            CHAR_LENGTH(REPLACE(' +
        '            TRIM(S.SERIE_TOKENIZADA_EMPSER), ' +
        '            ''dd'', '''')) IN (0, 2) ' +
        '        AND REPLACE(REPLACE(REPLACE(REPLACE(' +
        '            TRIM(S.SERIE_TOKENIZADA_EMPSER), ' +
        '            ''yyyy'', CAST(YEAR(:FECHA) AS CHAR)), ' +
        '            ''mm'', DATE_FORMAT(:FECHA, ''%m'')), ' +
        '            ''dd'', DATE_FORMAT(:FECHA, ''%d'')), ' +
        '            ''q'', CAST(QUARTER(:FECHA) AS CHAR)) = :SERIE)) ' +
        '   AND (S.FECHA_DESDE_EMPSER IS NULL ' +
        '        OR S.FECHA_DESDE_EMPSER <= :FECHA) ' +
        '   AND (S.FECHA_HASTA_EMPSER IS NULL ' +
        '        OR S.FECHA_HASTA_EMPSER >= :FECHA) ' +
        ' LIMIT 1';
      unqrySol.ParamByName('SERIE').AsString := sSerie;
      unqrySol.ParamByName('EMPRESA').AsString := sEmpresa;
      unqrySol.ParamByName('FECHA').AsDateTime := dtFecha;
      unqrySol.Open;
      if not unqrySol.IsEmpty then
      begin
        Result := unqrySol.FieldByName(
          'SUBTIPO_EMPSER').AsString;
      end;
    finally
      FreeAndNil(unqrySol);
    end;
  end;
end;

function TdmFacturas.GetUserEmpresaDef:String;
var
  unqrySol:TUniQuery;
  sResul : String;
begin
  sResul := '';
  if ( ((unqryTablaG.State = dsEdit) or
        (unqryTablaG.State = dsInsert))
    ) then
  begin
    unqrySol := TUniQuery.Create(Self);
    unqrySol.Connection := ConexionPrincipal;
    unqrySol.SQL.Text := 'SELECT EMPRESA_DEFECTO_USU ' +
                        '  FROM fza_usuarios ' +
                        ' WHERE USUARIO_USU = :Usuario ';
    unqrySol.ParamByName('Usuario').AsString := IdentidadSesion.Usuario;
    unqrySol.Open;
    if unqrySol.RecordCount <> 0 then
    begin
      sResul := unqrySol.FieldByName('EMPRESA_DEFECTO_USU').AsString;
    end;
    unqrySol.Close;
    FreeAndNil(unqrySol);
  end;
  Result := sResul;
end;

procedure TdmFacturas.CrearTablaSeries(sEmpresa,
                                       sCliente:string;
                                       dtFecha:TDateTime);
begin
  unqrySeriesEditCombo.Connection := ConexionPrincipal;
  unqrySeriesEditCombo.SQL.Text :=
                'SELECT SERIE_CON_CLI AS SERIE_CON ' +
                '  FROM vi_clientes                              ' +
                ' WHERE (SERIE_CON_CLI IS NOT NULL      ' +
                '        AND SERIE_CON_CLI <> '''')     ' +
                '   AND CODIGO_CLI_CLI = :CLIENTE                ' +
                ' UNION                                          ' +
                'SELECT EMPSER AS SERIE_CON            ' +
                '  FROM vi_empresas_series                       ' +
                ' WHERE CODIGO_EMP_EMPSER = :EMPRESA          ' +
                '   AND TIPO_DOC_EMPSER = ''FC''               ' +
                '   AND (SUBTIPO_EMPSER = :SUBTIPO             ' +
                '        OR IFNULL(SUBTIPO_EMPSER, '''') = '''') ' +
                '   AND (FECHA_DESDE_EMPSER IS NULL            ' +
                '        OR FECHA_DESDE_EMPSER <= :FECHA)      ' +
                '   AND (FECHA_HASTA_EMPSER IS NULL            ' +
                '        OR FECHA_HASTA_EMPSER >= :FECHA)      ' +
                ' UNION                                          ' +
                'SELECT SERIE_CON AS SERIE_CON         ' +
                '  FROM vi_contadores                            ' +
                ' WHERE ESACTIVO_CON = ''S''                  ' +
                '   AND TIPO_DOC_CON = ''FC''                 ' +
                '   AND EMPRESA_CON = :EMPRESA              ';
  unqrySeriesEditCombo.Prepare;
  unqrySeriesEditCombo.Params.ParamByName('EMPRESA').AsSTring := sEmpresa;
  unqrySeriesEditCombo.Params.ParamByName('FECHA').AsDateTime := dtFecha;
  unqrySeriesEditCombo.Params.ParamByName('CLIENTE').AsString := sCliente;
  unqrySeriesEditCombo.Params.ParamByName('SUBTIPO').AsString :=
    FTipoFacturaDefecto;
  if unqrySeriesEditCombo.Active then
    unqrySeriesEditCombo.Close;
  unqrySeriesEditCombo.Open;
end;

procedure TdmFacturas.AsignarIVA(s:string; unqryT:TUniQuery);
begin
  CargarConfiguracionIvaFactura(Self, ConexionPrincipal, s,
    unqryT.FieldByName('FECHA_FAC').AsDateTime, unqryT);
end;

function TdmFacturas.BuscarCliente(s: string):Boolean;
var
  unqrySol:TUniQuery;
begin
  unqrySol := TUniQuery.Create(Self);
  try
    unqrySol.Connection := ConexionPrincipal;
    unqrySol.SQL.Text := 'SELECT * ' +
                         '  FROM fza_clientes ' +
                         ' WHERE CODIGO_CLI_CLI = :cliente';
    unqrySol.ParamByName('cliente').AsString := s;
    unqrySol.Open;
    if unqrySol.RecordCount = 0 then
    begin
      Result := False;
    end
    else
    begin
      CopiarClienteaFactura(unqrySol);
      Result := True;
    end;
    unqrySol.Close;
  finally
    FreeAndNil(unqrySol);
  end;
end;

function TdmFacturas.CalcularFactura: TResultadoOperacionFactura;
var
  bReadOnlyLineas: Boolean;
begin
  Result := TResultadoOperacionFactura.Correcto;
  if not FCalculandoFactura then
  begin
    RequerirServiciosFactura;
    FCalculandoFactura := True;
    try
      if Assigned(unqryTablaG) and unqryTablaG.Active and
         Assigned(unqryLinFac) and unqryLinFac.Active then
      begin
        bReadOnlyLineas := unqryLinFac.ReadOnly;
        try
          if bReadOnlyLineas then
          begin
            unqryLinFac.ReadOnly := False;
          end;
          Result := FCalculador.Calcular(
            unqryTablaG,
            unqryLinFac,
            FacturaPermiteRecalcularLineas);
        finally
          unqryLinFac.ReadOnly := bReadOnlyLineas;
        end;
      end;
    finally
      FCalculandoFactura := False;
    end;
  end;
end;

procedure TdmFacturas.CalcularRetencionesEmpresa;
begin
  AplicarRetencionEmpresaFactura(Self, ConexionPrincipal, unqryTablaG);
end;

procedure TdmFacturas.MarcarRecalculoFacturaPendiente;
begin
  FRecalculoFacturaPendiente := True;
end;

procedure TdmFacturas.CopiarArticuloaLinea(DataSet: TDataSet);
var
  bDtoVig: Boolean;
begin
  bDtoVig := FArticulosResolver.DescuentoTarifaVigente(
    unqryTablaG.FieldByName(
      'TARIFA_ARTICULO_CLIENTE_FAC').AsString,
    unqryTablaG.FieldByName('FECHA_FAC').AsDateTime);
  CopiarArticuloSeleccionadoFactura(
    DataSet, dsLinFac.DataSet, unqryTablaG, bDtoVig);
end;

procedure TdmFacturas.CopiarClienteaFactura(DataSet:TDataSet);
var
  Resultado: TResultadoCopiaClienteFactura;
begin
  Resultado := CopiarClienteSeleccionadoFactura(DataSet, unqryTablaG);
  if Resultado.RequiereFormaPagoDefecto then
  begin
    unqryTablaG.FieldByName('FORMA_PAGO_FAC').AsString :=
      FormaPagoDefault;
  end;
  if Resultado.RequiereTarifaDefecto then
  begin
    unqryTablaG.FieldByName(
      'TARIFA_ARTICULO_CLIENTE_FAC').AsString := TarifaDefault;
  end;
  if (unqryTablaG.State = dsInsert) and
     (unqryTablaG.FieldByName(
       'TARIFA_ARTICULO_CLIENTE_FAC').AsString <> '') then
  begin
    unqryTarifas.Locate(
      'CODIGO_TAR_ARTTAR',
      unqryTablaG.FieldByName(
        'TARIFA_ARTICULO_CLIENTE_FAC').AsString, []);
    unqryTablaG.FieldByName(
      'ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString :=
      unqryTarifas.FieldByName('ESIMP_INCL_TAR').AsString;
  end;
  if Resultado.NotificarSeries and Assigned(FOnSeriesCambiadas) then
    FOnSeriesCambiadas(Self);
end;

procedure TdmFacturas.CopiarEmpresaaFactura(DataSet:TDataSet);
var
  Resultado: TResultadoCopiaEmpresaFactura;
begin
  Resultado := CopiarEmpresaSeleccionadaFactura(DataSet, unqryTablaG);
  if Resultado.CalcularRetenciones then
    CalcularRetencionesEmpresa;
  if Resultado.NotificarSeries and Assigned(FOnSeriesCambiadas) then
    FOnSeriesCambiadas(Self);
end;

procedure TdmFacturas.CrearCliente;
var
  Solicitud: TSolicitudClienteFactura;
begin
  RequerirServiciosFactura;
  Solicitud := CrearSolicitudClienteDesdeFactura(
    unqryTablaG, IdentidadSesion.Usuario);
  FRepositorio.GuardarCliente(Solicitud);
end;

procedure TdmFacturas.CrearEmpresa;
var
  Solicitud: TSolicitudEmpresaFactura;
begin
  RequerirServiciosFactura;
  Solicitud := CrearSolicitudEmpresaDesdeFactura(
    unqryTablaG, IdentidadSesion.Usuario);
  FRepositorio.GuardarEmpresa(Solicitud);
end;

procedure TdmFacturas.DataModuleCreate(Sender: TObject);
begin
  inherited;
  FAdvertenciasPendientes := TStringList.Create;
  unqryPerfiles.Connection := ConexionPrincipal;
  unqryTablaG.Connection := ConexionPrincipal;
  unqryTablaG.KeyFields := 'NUMERO_FAC;SERIE_FAC';
  unqryTablaG.SQLDelete.Text :=
    'DELETE FROM fza_facturas ' + sLineBreak +
    'WHERE NUMERO_FAC = :Old_NUMERO_FAC ' + sLineBreak +
    '  AND SERIE_FAC = :Old_SERIE_FAC';
  // Cierre de la transaccion del borrado (abierta en BeforeDelete)
  unqryTablaG.AfterDelete := unqryTablaGAfterDeleteTx;
  unqryTablaG.OnDeleteError := unqryTablaGDeleteErrorTx;
  PrepararCabeceraSinCamposComplejos;
  unqryLinFac.Connection := ConexionPrincipal;
  // Contrato ColumnSKUcxGrid (facturas_columnas_sku.sql): los SQL del
  // dfm no conocen las columnas nuevas (ATTR1..5 + NUM_ATRIBUTOS); se
  // reescriben aqui COMPLETOS para no editar el dfm cableado (mismo
  // criterio que TdmPedidos con fza_pedidos_lineas). SOLO si la
  // migracion esta aplicada: sin los campos, los parametros ATTR*
  // rompen el INSERT ('Not found field corresponding parameter').
  if ColumnasSkuLineasAplicadas then
  begin
  unqryLinFac.SQLInsert.Text :=
    'INSERT INTO fza_facturas_lineas ' +
    ' (NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, LINEA_FACLIN, ' +
    '  CODIGO_ART_FACLIN, CODIGO_UNIDAD_FACLIN, CODIGO_FAM_FACLIN, ' +
    '  NOMBRE_FAM_FACLIN, PRECIO_ULT_COMPRA_FACLIN, CODIGO_PRV_FACLIN, ' +
    '  RAZON_SOCIAL_PROVEEDOR_FACLIN, ESPROVEEDORPRINCIPAL_FACLIN, ' +
    '  FECHA_ENTREGA_FACLIN, TIPO_CANTIDAD_ARTICULO_FACLIN, ' +
    '  ESIMP_INCL_TARIFA_FACLIN, TIPO_IVA_ARTICULO_FACLIN, ' +
    '  DESCRIPCION_ARTICULO_FACLIN, DESCRIPCION_VARIACION_FACLIN, ' +
    '  CODIGO_TAR_FACLIN, CANTIDAD_FACLIN, PRECIO_SALIDA_FACLIN, ' +
    '  PORCENTAJE_DTO_FACLIN, PRECIO_DTO_FACLIN, ' +
    '  PRECIO_VENTA_SIVA_ARTICULO_FACLIN, PORCENTAJE_IVA_FACLIN, ' +
    '  PRECIO_VENTA_CIVA_ARTICULO_FACLIN, TOTAL_FACLIN, ' +
    '  TOTAL_FAC_SIVA_FACLIN, ' +
    '  ATTR1_VALOR_FACLIN, ATTR1_NOMBRE_FACLIN, ' +
    '  ATTR2_VALOR_FACLIN, ATTR2_NOMBRE_FACLIN, ' +
    '  ATTR3_VALOR_FACLIN, ATTR3_NOMBRE_FACLIN, ' +
    '  ATTR4_VALOR_FACLIN, ATTR4_NOMBRE_FACLIN, ' +
    '  ATTR5_VALOR_FACLIN, ATTR5_NOMBRE_FACLIN, ' +
    '  NUM_ATRIBUTOS_FACLIN, ' +
    '  INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES ' +
    ' (:NUMERO_FAC_FACLIN, :SERIE_FAC_FACLIN, :LINEA_FACLIN, ' +
    '  :CODIGO_ART_FACLIN, :CODIGO_UNIDAD_FACLIN, :CODIGO_FAM_FACLIN, ' +
    '  :NOMBRE_FAM_FACLIN, :PRECIO_ULT_COMPRA_FACLIN, ' +
    '  :CODIGO_PRV_FACLIN, :RAZON_SOCIAL_PROVEEDOR_FACLIN, ' +
    '  :ESPROVEEDORPRINCIPAL_FACLIN, :FECHA_ENTREGA_FACLIN, ' +
    '  :TIPO_CANTIDAD_ARTICULO_FACLIN, :ESIMP_INCL_TARIFA_FACLIN, ' +
    '  :TIPO_IVA_ARTICULO_FACLIN, :DESCRIPCION_ARTICULO_FACLIN, ' +
    '  :DESCRIPCION_VARIACION_FACLIN, :CODIGO_TAR_FACLIN, ' +
    '  :CANTIDAD_FACLIN, :PRECIO_SALIDA_FACLIN, :PORCENTAJE_DTO_FACLIN, ' +
    '  :PRECIO_DTO_FACLIN, :PRECIO_VENTA_SIVA_ARTICULO_FACLIN, ' +
    '  :PORCENTAJE_IVA_FACLIN, :PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
    '  :TOTAL_FACLIN, :TOTAL_FAC_SIVA_FACLIN, ' +
    '  :ATTR1_VALOR_FACLIN, :ATTR1_NOMBRE_FACLIN, ' +
    '  :ATTR2_VALOR_FACLIN, :ATTR2_NOMBRE_FACLIN, ' +
    '  :ATTR3_VALOR_FACLIN, :ATTR3_NOMBRE_FACLIN, ' +
    '  :ATTR4_VALOR_FACLIN, :ATTR4_NOMBRE_FACLIN, ' +
    '  :ATTR5_VALOR_FACLIN, :ATTR5_NOMBRE_FACLIN, ' +
    '  :NUM_ATRIBUTOS_FACLIN, ' +
    '  :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, :USUARIO_MODIF)';
  unqryLinFac.SQLUpdate.Text :=
    'UPDATE fza_facturas_lineas SET ' +
    '  NUMERO_FAC_FACLIN = :NUMERO_FAC_FACLIN, ' +
    '  SERIE_FAC_FACLIN = :SERIE_FAC_FACLIN, ' +
    '  LINEA_FACLIN = :LINEA_FACLIN, ' +
    '  CODIGO_ART_FACLIN = :CODIGO_ART_FACLIN, ' +
    '  CODIGO_UNIDAD_FACLIN = :CODIGO_UNIDAD_FACLIN, ' +
    '  CODIGO_FAM_FACLIN = :CODIGO_FAM_FACLIN, ' +
    '  NOMBRE_FAM_FACLIN = :NOMBRE_FAM_FACLIN, ' +
    '  PRECIO_ULT_COMPRA_FACLIN = :PRECIO_ULT_COMPRA_FACLIN, ' +
    '  CODIGO_PRV_FACLIN = :CODIGO_PRV_FACLIN, ' +
    '  RAZON_SOCIAL_PROVEEDOR_FACLIN = :RAZON_SOCIAL_PROVEEDOR_FACLIN, ' +
    '  ESPROVEEDORPRINCIPAL_FACLIN = :ESPROVEEDORPRINCIPAL_FACLIN, ' +
    '  FECHA_ENTREGA_FACLIN = :FECHA_ENTREGA_FACLIN, ' +
    '  TIPO_CANTIDAD_ARTICULO_FACLIN = :TIPO_CANTIDAD_ARTICULO_FACLIN, ' +
    '  ESIMP_INCL_TARIFA_FACLIN = :ESIMP_INCL_TARIFA_FACLIN, ' +
    '  TIPO_IVA_ARTICULO_FACLIN = :TIPO_IVA_ARTICULO_FACLIN, ' +
    '  DESCRIPCION_ARTICULO_FACLIN = :DESCRIPCION_ARTICULO_FACLIN, ' +
    '  DESCRIPCION_VARIACION_FACLIN = :DESCRIPCION_VARIACION_FACLIN, ' +
    '  CODIGO_TAR_FACLIN = :CODIGO_TAR_FACLIN, ' +
    '  CANTIDAD_FACLIN = :CANTIDAD_FACLIN, ' +
    '  PRECIO_SALIDA_FACLIN = :PRECIO_SALIDA_FACLIN, ' +
    '  PORCENTAJE_DTO_FACLIN = :PORCENTAJE_DTO_FACLIN, ' +
    '  PRECIO_DTO_FACLIN = :PRECIO_DTO_FACLIN, ' +
    '  PRECIO_VENTA_SIVA_ARTICULO_FACLIN = ' +
    '    :PRECIO_VENTA_SIVA_ARTICULO_FACLIN, ' +
    '  PORCENTAJE_IVA_FACLIN = :PORCENTAJE_IVA_FACLIN, ' +
    '  PRECIO_VENTA_CIVA_ARTICULO_FACLIN = ' +
    '    :PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
    '  TOTAL_FACLIN = :TOTAL_FACLIN, ' +
    '  TOTAL_FAC_SIVA_FACLIN = :TOTAL_FAC_SIVA_FACLIN, ' +
    '  ATTR1_VALOR_FACLIN = :ATTR1_VALOR_FACLIN, ' +
    '  ATTR1_NOMBRE_FACLIN = :ATTR1_NOMBRE_FACLIN, ' +
    '  ATTR2_VALOR_FACLIN = :ATTR2_VALOR_FACLIN, ' +
    '  ATTR2_NOMBRE_FACLIN = :ATTR2_NOMBRE_FACLIN, ' +
    '  ATTR3_VALOR_FACLIN = :ATTR3_VALOR_FACLIN, ' +
    '  ATTR3_NOMBRE_FACLIN = :ATTR3_NOMBRE_FACLIN, ' +
    '  ATTR4_VALOR_FACLIN = :ATTR4_VALOR_FACLIN, ' +
    '  ATTR4_NOMBRE_FACLIN = :ATTR4_NOMBRE_FACLIN, ' +
    '  ATTR5_VALOR_FACLIN = :ATTR5_VALOR_FACLIN, ' +
    '  ATTR5_NOMBRE_FACLIN = :ATTR5_NOMBRE_FACLIN, ' +
    '  NUM_ATRIBUTOS_FACLIN = :NUM_ATRIBUTOS_FACLIN, ' +
    '  INSTANTE_MODIF = :INSTANTE_MODIF, ' +
    '  INSTANTE_ALTA = :INSTANTE_ALTA, ' +
    '  USUARIO_ALTA = :USUARIO_ALTA, ' +
    '  USUARIO_MODIF = :USUARIO_MODIF ' +
    'WHERE NUMERO_FAC_FACLIN = :Old_NUMERO_FAC_FACLIN ' +
    '  AND SERIE_FAC_FACLIN = :Old_SERIE_FAC_FACLIN ' +
    '  AND LINEA_FACLIN = :Old_LINEA_FACLIN';
  unqryLinFac.SQLRefresh.Text :=
    'SELECT * FROM fza_facturas_lineas ' +
    ' WHERE NUMERO_FAC_FACLIN = :NUMERO_FAC_FACLIN ' +
    '   AND SERIE_FAC_FACLIN = :SERIE_FAC_FACLIN ' +
    '   AND LINEA_FACLIN = :LINEA_FACLIN';
  unqryLinFac.SQLLock.Text :=
    'SELECT * FROM fza_facturas_lineas ' +
    ' WHERE NUMERO_FAC_FACLIN = :Old_NUMERO_FAC_FACLIN ' +
    '   AND SERIE_FAC_FACLIN = :Old_SERIE_FAC_FACLIN ' +
    '   AND LINEA_FACLIN = :Old_LINEA_FACLIN ' +
    ' FOR UPDATE';
  end;
  unqrySeries.Connection := ConexionPrincipal;
  unqryIvas.Connection := ConexionPrincipal;
  unqryRecibos.Connection := ConexionPrincipal;
  unqryEmpDataFac.Connection := ConexionPrincipal;
  unqryCliDataFac.Connection := ConexionPrincipal;
  unqryArtDataLinFac.Connection := ConexionPrincipal;
  unqryTarifas.Connection := ConexionPrincipal;
  unstdCrearArticuloLin.Connection := ConexionPrincipal;
  unqryFormaPago.Connection := ConexionPrincipal;
  unstrdprcGetContadorFactura.Connection := ConexionPrincipal;
  unstdGetContadorLinea.Connection := ConexionPrincipal;
  unstdCalcularFactura.Connection := ConexionPrincipal;
  unstrdprcGetDataCliente.Connection := ConexionPrincipal;
  unstrdprcGetRecibos.Connection := ConexionPrincipal;
  unqryRecibosPrint.Connection := ConexionPrincipal;
  unqrySeriesEditCombo.Connection := ConexionPrincipal;
  unqryIvasTipos.Connection := ConexionPrincipal;
  unqryPaisesEmp.Connection := ConexionPrincipal;
  unqryPaisesCli.Connection := ConexionPrincipal;
  unqryConsolidacion.Connection := ConexionPrincipal;
  unqryErrores.Connection := ConexionPrincipal;
  unqryMovimientosFac.Connection := ConexionPrincipal;
  unqryAlmacenesFac.Connection := ConexionPrincipal;
  unstrdprcInsertarMovFac.Connection := ConexionPrincipal;
  unqryEfectosVenta := TUniQuery.Create(Self);
  unqryEfectosVenta.Connection := ConexionPrincipal;
  unqryEfectosVenta.SQL.Text :=
    'SELECT * ' +
    '  FROM vi_efectos_venta ' +
    ' WHERE NUMERO_FAC_EFV = :NUMERO_FAC ' +
    '   AND SERIE_FAC_EFV  = :SERIE_FAC ' +
    ' ORDER BY NUMERO_EFV';
  unqryEfectosVenta.MasterFields := 'NUMERO_FAC;SERIE_FAC';
  unqryEfectosVenta.DetailFields := 'NUMERO_FAC_EFV;SERIE_FAC_EFV';
  dsEfectosVenta := TDataSource.Create(Self);
  dsEfectosVenta.DataSet := unqryEfectosVenta;
  // Los MasterSource de los detalles los cablea el form via
  // AsignarMaestroCabecera (el DM ya no busca dsTablaG en el form).
end;

procedure TdmFacturas.AsignarMaestroCabecera(ADataSource: TDataSource);
begin
  inherited;
  unqryLinfac.MasterSource := ADataSource;
  unqryRecibos.MasterSource := ADataSource;
  unqryEfectosVenta.MasterSource := ADataSource;
  unqryConsolidacion.MasterSource := ADataSource;
  unqryErrores.MasterSource := ADataSource;
  unqryMovimientosFac.MasterSource := ADataSource;
end;

procedure TdmFacturas.QuitarCampoComplejoCabecera(ALista: TStrings;
                                                  const ACampo: string);
var
  sCampoSql: string;
  sSQL: string;
begin
  if ALista <> nil then
  begin
    sCampoSql := DelimitarIdentificadorSql(
      ACampo,
      CAMPOS_COMPLEJOS_CABECERA);
    sSQL := ALista.Text;
    sSQL := StringReplace(sSQL,
      ', ' + sCampoSql + ' = :' + sCampoSql,
      '', [rfReplaceAll, rfIgnoreCase]);
    sSQL := StringReplace(sSQL,
      ', ' + sCampoSql,
      '', [rfReplaceAll, rfIgnoreCase]);
    sSQL := StringReplace(sSQL,
      ', :' + sCampoSql,
      '', [rfReplaceAll, rfIgnoreCase]);
    ALista.Text := sSQL;
  end;
end;

function TdmFacturas.FacturaPermiteRecalcularLineas: Boolean;
var
  oCampoFase: TField;
  sFase: string;
begin
  Result := True;
  oCampoFase := unqryTablaG.FindField(ffasefac);
  if oCampoFase <> nil then
  begin
    sFase := Trim(oCampoFase.AsString);
    Result := (sFase = '') or SameText(sFase, 'BORRADOR') or
              (SinVerifactuActivo(ParametrosApp) and
               SameText(sFase, cFaseFacturaSinVerifactu));
  end;
end;

function TdmFacturas.ColumnasSkuLineasAplicadas: Boolean;
var
  qCol: TUniQuery;
begin
  Result := False;
  if ConexionPrincipal <> nil then
  begin
    qCol := TUniQuery.Create(nil);
    try
      try
        qCol.Connection := ConexionPrincipal;
        qCol.SQL.Text :=
          'SELECT COUNT(*) AS N ' +
          '  FROM INFORMATION_SCHEMA.COLUMNS ' +
          ' WHERE TABLE_SCHEMA = DATABASE() ' +
          '   AND TABLE_NAME = ''fza_facturas_lineas'' ' +
          '   AND COLUMN_NAME IN (''ATTR1_VALOR_FACLIN'', ' +
          '                       ''NUM_ATRIBUTOS_FACLIN'')';
        qCol.Open;
        Result := qCol.FieldByName('N').AsInteger = 2;
      except
        // Ante cualquier fallo se asume SIN migrar: los SQL del dfm
        // siguen funcionando y solo se pierde el desglose de atributos.
        Result := False;
      end;
    finally
      FreeAndNil(qCol);
    end;
  end;
end;

procedure TdmFacturas.PrepararCabeceraSinCamposComplejos;
var
  ColumnasPermitidas: TStringList;
  i: Integer;
  qCampos: TUniQuery;
  sCampo: string;
  sCampos: string;
begin
  sCampos := '';
  if ConexionPrincipal <> nil then
  begin
    ColumnasPermitidas := TStringList.Create;
    qCampos := TUniQuery.Create(nil);
    try
      qCampos.Connection := ConexionPrincipal;
      qCampos.SQL.Text := 'SHOW COLUMNS FROM vi_facturas';
      qCampos.Open;
      while not qCampos.Eof do
      begin
        sCampo := qCampos.FieldByName('Field').AsString;
        ColumnasPermitidas.Add(sCampo);
        qCampos.Next;
      end;
      i := 0;
      while i < ColumnasPermitidas.Count do
      begin
        sCampo := ColumnasPermitidas[i];
        if (not SameText(sCampo, CAMPOS_COMPLEJOS_CABECERA[0])) and
           (not SameText(sCampo, CAMPOS_COMPLEJOS_CABECERA[1])) then
        begin
          if sCampos <> '' then
            sCampos := sCampos + ', ';
          sCampos := sCampos + DelimitarIdentificadorSql(
            sCampo,
            ColumnasPermitidas);
        end;
        Inc(i);
      end;
    finally
      FreeAndNil(qCampos);
      FreeAndNil(ColumnasPermitidas);
    end;
    if sCampos <> '' then
      unqryTablaG.SQL.Text :=
        'SELECT ' + sCampos + ' FROM vi_facturas ' +
        ' ORDER BY FECHA_FAC DESC, NUMERO_FAC DESC';
  end;
  QuitarCampoComplejoCabecera(unqryTablaG.SQLInsert, 'DOCUMENTO_FAC');
  QuitarCampoComplejoCabecera(unqryTablaG.SQLInsert, 'XML_FAC');
  QuitarCampoComplejoCabecera(unqryTablaG.SQLUpdate, 'DOCUMENTO_FAC');
  QuitarCampoComplejoCabecera(unqryTablaG.SQLUpdate, 'XML_FAC');
  QuitarCampoComplejoCabecera(unqryTablaG.SQLLock, 'DOCUMENTO_FAC');
  QuitarCampoComplejoCabecera(unqryTablaG.SQLLock, 'XML_FAC');
  QuitarCampoComplejoCabecera(unqryTablaG.SQLRefresh, 'DOCUMENTO_FAC');
  QuitarCampoComplejoCabecera(unqryTablaG.SQLRefresh, 'XML_FAC');
end;

procedure TdmFacturas.OpenTables;
begin
  // Delegar en AbrirDetalles para que el flujo (cronometro y logging)
  // sea unico independientemente de quien lo invoque.
  AbrirDetalles;
end;

procedure TdmFacturas.AbrirDetalles;
const
  TAG = 'Facturas.AbrirDetalles';

  procedure AbrirSiCerrada(qry: TUniQuery);
  begin
    if not qry.Active then
      qry.Open;
  end;

var
  sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  // Lookups y pestaña por defecto. Las queries lazy (Recibos,
  // Consolidacion, Errores, MovimientosFac) se abren al activar su
  // sub-pestaña via AsegurarXxxAbierta.
  AbrirSiCerrada(unqryIvasTipos);
  RefrescarAlmacenes('');
  AbrirSiCerrada(unqryLinFac);
  AbrirSiCerrada(unqrySeries);
  AbrirSiCerrada(unqryIvas);
  AbrirSiCerrada(unqryFormaPago);
  AbrirSiCerrada(unqryVerifactuOpe);
  AbrirSiCerrada(unqryTarifas);
  AbrirSiCerrada(unqryPaisesCli);
  AbrirSiCerrada(unqryPaisesEmp);
  RegistroLog.RegistrarRendimiento(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmFacturas.RefrescarAlmacenes(const ACodigoEmpresa: string);
var
  sEmpresa: string;
begin
  sEmpresa := Trim(ACodigoEmpresa);
  if (sEmpresa = '') and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
    sEmpresa := Trim(unqryTablaG.FieldByName('CODIGO_EMP_FAC').AsString);
  if sEmpresa = '' then
    sEmpresa := Trim(UbicacionSesion.Empresa);
  if (not unqryAlmacenesFac.Active) or
     (not SameText(unqryAlmacenesFac.ParamByName('EMPRESA').AsString,
                   sEmpresa)) then
  begin
    unqryAlmacenesFac.Close;
    unqryAlmacenesFac.ParamByName('EMPRESA').AsString := sEmpresa;
    unqryAlmacenesFac.Open;
  end;
  // El almacen solo es obligatorio si el borrador genera movimientos de
  // stock: AjustarEmpresaAlmacenDataSet lanza excepcion si la empresa no
  // tiene ningun almacen activo, y una instalacion sin almacenes (solo
  // servicios) debe poder facturar sin el.
  if unqryTablaG.Active and
     (unqryTablaG.State in [dsInsert, dsEdit]) and
     FacturaGeneraMovimientos then
    AjustarEmpresaAlmacenDataSet(unqryTablaG.Connection, unqryTablaG,
      'CODIGO_EMP_FAC', 'CODIGO_ALM_FAC');
end;

procedure TdmFacturas.RellenarParamsDesdeMaestro(AQry: TUniQuery);
var
  oMaestro: TDataSet;
  oCampo:   TField;
  i:        Integer;
begin
  if (AQry.MasterSource <> nil) and
     (AQry.MasterSource.DataSet <> nil) then
  begin
    oMaestro := AQry.MasterSource.DataSet;
    if oMaestro.Active and (not oMaestro.IsEmpty) then
    begin
      for i := 0 to AQry.Params.Count - 1 do
      begin
        oCampo := oMaestro.FindField(AQry.Params[i].Name);
        if oCampo <> nil then
          AQry.Params[i].Value := oCampo.Value;
      end;
    end;
  end;
end;

procedure TdmFacturas.AsegurarRecibosAbierta;
var swQ: TStopwatch;
begin
  if not unqryRecibos.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      RellenarParamsDesdeMaestro(unqryRecibos);
      unqryRecibos.Open;
      RegistroLog.RegistrarRendimiento('Facturas.Lazy', 'unqryRecibos OK',
        swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento('Facturas.Lazy',
          'unqryRecibos ERROR=' + E.Message, swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
end;

procedure TdmFacturas.AsegurarEfectosVentaAbierta;
var swQ: TStopwatch;
begin
  if (unqryEfectosVenta <> nil) and (not unqryEfectosVenta.Active) then
  begin
    swQ := TStopwatch.StartNew;
    try
      RellenarParamsDesdeMaestro(unqryEfectosVenta);
      unqryEfectosVenta.Open;
      RegistroLog.RegistrarRendimiento('Facturas.Lazy', 'unqryEfectosVenta OK',
        swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento('Facturas.Lazy',
          'unqryEfectosVenta ERROR=' + E.Message, swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
end;

procedure TdmFacturas.EstamparBancoRecibos(const ASerie, ANumero,
                                           ACodEmpban, AIban: string);
begin
  RequerirServiciosFactura;
  FServicioEfectos.EstamparBancoRecibos(
    ASerie,
    ANumero,
    ACodEmpban,
    AIban);
end;

function TdmFacturas.GetBancoDefectoCliente(
  const ACodigoCli: string): string;
begin
  RequerirServiciosFactura;
  Result := FServicioEfectos.BancoDefectoCliente(ACodigoCli);
end;

function TdmFacturas.GenerarEfectosVenta(const ACodEmpban: string = '';
                                         const AIbanEmp: string = ''): Integer;
var
  ResultadoCalculo: TResultadoOperacionFactura;
begin
  Result := -1;
  if (unqryTablaG <> nil) and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
  begin
    if unqryTablaG.State in [dsEdit, dsInsert] then
    begin
      ResultadoCalculo := CalcularFactura;
      NotificarResultadoOperacion(ResultadoCalculo);
      unqryTablaG.Post;
    end;
    RequerirServiciosFactura;
    Result := FServicioEfectos.Generar(
      unqryTablaG.FieldByName('SERIE_FAC').AsString,
      unqryTablaG.FieldByName('NUMERO_FAC').AsString,
      IdentidadSesion.Usuario,
      ACodEmpban,
      AIbanEmp);
    if Assigned(unqryEfectosVenta) then
    begin
      unqryEfectosVenta.Close;
      unqryEfectosVenta.Open;
    end;
  end;
end;

function TdmFacturas.RegistrarCobroEfectoVenta(ANumEfecto: Integer;
  AFecha: TDateTime; AImporte: Double;
  const ATipo, AReferencia: string): Integer;
begin
  Result := -1;
  if (unqryTablaG <> nil) and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
  begin
    RequerirServiciosFactura;
    Result := FServicioEfectos.RegistrarCobro(
      unqryTablaG.FieldByName('SERIE_FAC').AsString,
      unqryTablaG.FieldByName('NUMERO_FAC').AsString,
      IdentidadSesion.Usuario,
      ANumEfecto,
      AFecha,
      AImporte,
      ATipo,
      AReferencia);
    if Assigned(unqryEfectosVenta) then
    begin
      unqryEfectosVenta.Close;
      unqryEfectosVenta.Open;
    end;
  end;
end;

function TdmFacturas.CambiarEstadoEfectoVenta(
  const AEstado: string): Boolean;
begin
  Result := False;
  if (unqryEfectosVenta <> nil) and unqryEfectosVenta.Active and
     (not unqryEfectosVenta.IsEmpty) then
  begin
    RequerirServiciosFactura;
    Result := FServicioEfectos.CambiarEstado(
      unqryEfectosVenta.FieldByName('SERIE_FAC_EFV').AsString,
      unqryEfectosVenta.FieldByName('NUMERO_FAC_EFV').AsString,
      IdentidadSesion.Usuario,
      unqryEfectosVenta.FieldByName('NUMERO_EFV').AsInteger,
      AEstado);
    unqryEfectosVenta.Close;
    unqryEfectosVenta.Open;
  end;
end;

procedure TdmFacturas.AsegurarConsolidacionAbierta;
var swQ: TStopwatch;
begin
  if not unqryConsolidacion.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      RellenarParamsDesdeMaestro(unqryConsolidacion);
      unqryConsolidacion.Open;
      RegistroLog.RegistrarRendimiento(
        'Facturas.Lazy', 'unqryConsolidacion OK', swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento('Facturas.Lazy',
          'unqryConsolidacion ERROR=' + E.Message, swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
end;

procedure TdmFacturas.AsegurarErroresAbierta;
var swQ: TStopwatch;
begin
  if not unqryErrores.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      RellenarParamsDesdeMaestro(unqryErrores);
      unqryErrores.Open;
      RegistroLog.RegistrarRendimiento('Facturas.Lazy', 'unqryErrores OK',
        swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento('Facturas.Lazy',
          'unqryErrores ERROR=' + E.Message, swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
end;

procedure TdmFacturas.AsegurarMovimientosFacAbierta;
var swQ: TStopwatch;
begin
  if not unqryMovimientosFac.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      RellenarParamsDesdeMaestro(unqryMovimientosFac);
      unqryMovimientosFac.Open;
      RegistroLog.RegistrarRendimiento(
        'Facturas.Lazy', 'unqryMovimientosFac OK', swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento('Facturas.Lazy',
          'unqryMovimientosFac ERROR=' + E.Message, swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
end;

procedure TdmFacturas.DataModuleDestroy(Sender: TObject);
begin
  FRepositorio := nil;
  FValidadorFiscal := nil;
  FCalculador := nil;
  FServicioBorrado := nil;
  FServicioEfectos := nil;
  FreeAndNil(FAdvertenciasPendientes);
  unqryLinFac.Close;
  unqryIvas.Close;
  unqryTarifas.Close;
  unqrySeries.Close;
  unqryFormaPago.Close;
  //unqryPerfiles.Close;
  unqryRecibos.Close;
  if Assigned(unqryEfectosVenta) then
    unqryEfectosVenta.Close;
  unqryPaisesEmp.Close;
  unqryPaisesCli.Close;
  unqryConsolidacion.Close;
  unqryErrores.Close;
  if Assigned(unqryMovimientosFac) and unqryMovimientosFac.Active then
    unqryMovimientosFac.Close;
  if Assigned(unqryAlmacenesFac) and unqryAlmacenesFac.Active then
    unqryAlmacenesFac.Close;
  FreeAndNil(dsEfectosVenta);
  FreeAndNil(unqryEfectosVenta);
  //unqrySeriesEditCombo.Close;
  //unqryCabIVA.Close;
  inherited;
end;

procedure TdmFacturas.dsLinFacStateChange(Sender: TObject);
begin
  inherited;
  // La conmutacion de columnas editables (s/IVA vs c/IVA) es UI pura:
  // la resuelve el form suscrito a OnLinFacEstado.
  if Assigned(FOnLinFacEstado) then
    FOnLinFacEstado(Sender);
end;

function TdmFacturas.FormaPagoDefault: String;
var
  sFormaPago: string;
   LocateSuccess: Boolean;
begin
  LocateSuccess := unqryFormaPago.Locate('ESDEFAULT_FORMA_PAGO_FP', 'S', []);
  sFormaPago := unqryFormaPago.FindField('CODIGO_FP_FP').AsString;
  if LocateSuccess then
    Result := sFormaPago
  else
    Result := '';
end;

function TdmFacturas.GetCodigoGrupoIVAAGricola: String;
var
  qryIVAAG : TUniQuery;
  sResul:String;
begin
  sResul := '';
  qryIVAAG := TUniQuery.Create(Self);
  try
    qryIVAAG.Connection := ConexionPrincipal;
    qryIVAAG.SQL.Text := 'SELECT IVA_IVAGRP ' +
                        '  FROM vi_ivas_empresa ' +
                        ' WHERE ESIVAAGRICOLA_IVA_IVAGRP = :pAGRICOLA ' +
                        '   AND CODIGO_EMP_EMP = :pEMPRESA ' +
                        '   AND FECHA_DESDE_IVA <= :pFECHA ' +
                        '   AND (FECHA_HASTA_IVA IS NULL ' +
                        '       OR FECHA_HASTA_IVA > :pFECHA)' +
                        ' LIMIT 1;';
    qryIVAAG.ParamByName('pAGRICOLA').AsString := 'S';
    qryIVAAG.ParamByName('pFECHA').AsDateTime :=
      unqryTablaG.FieldByName('FECHA_FAC').AsDateTime;
    qryIVAAG.ParamByName('pEMPRESA').AsString :=
      unqryTablaG.FieldByName('CODIGO_EMP_FAC').AsString;
    qryIVAAG.Open;
    if qryIVAAG.RecordCount > 0 then
      sResul := qryIVAAG.Fields[0].AsString
    else
    begin
      qryIVAAG.Close;
      qryIVAAG.SQL.Text := 'SELECT IVA_IVAGRP ' +
                          '  FROM vi_ivas_empresa ' +
                          ' WHERE ESIVAAGRICOLA_IVA_IVAGRP = :pAGRICOLA ' +
                          '   AND ESDEFAULT_IVA_IVAGRP = :pDEFAULT ' +
                          '   AND FECHA_DESDE_IVA <= :pFECHA ' +
                          '   AND ( FECHA_HASTA_IVA IS NULL ' +
                          '        OR FECHA_HASTA_IVA > :pFECHA)' +
                          ' LIMIT 1;';
      qryIVAAG.ParamByName('pAGRICOLA').AsString := 'S';
      qryIVAAG.ParamByName('pDEFAULT').AsString := 'S';
      qryIVAAG.ParamByName('pFECHA').AsDateTime :=
        unqryTablaG.FieldByName('FECHA_FAC').AsDateTime;
      qryIVAAG.Open;
      sResul := qryIVAAG.Fields[0].AsString;
    end;
    qryIVAAG.Close;
  finally
    FreeAndNil(qryIVAAG);
  end;
  Result := sResul;
end;

function TdmFacturas.GetTipoIVA(sTipoIVA: string): Currency;
var
  fPorcen:Currency;
  function FindField(const Nombre: string): TField;
  begin
    Result := unqryTablaG.FindField(Nombre);
  end;
begin
  case IndexStr(sTipoIVA, ['N', 'R', 'S', 'E']) of
    0: fPorcen := FindField('PORCENTAJE_IVAN_FAC').AsCurrency;
    1: fPorcen := FindField('PORCENTAJE_IVAR_FAC').AsCurrency;
    2: fPorcen := FindField('PORCENTAJE_IVAS_FAC').AsCurrency;
    3: fPorcen := FindField('PORCENTAJE_IVAE_FAC').AsCurrency;
    else
    begin
      RegistrarAdvertencia(SErrorTipoIvaFactura, False);
      fPorcen := unqryLinFac.FindField('PORCENTAJE_IVAN_FAC').AsCurrency;
      unqryLinFac.FindField('TIPO_IVA_ARTICULO_FACLIN').AsString := 'N';
    end;
  end;
  Result := fPorcen;
end;

procedure TdmFacturas.GetCodigoAutoFactura;
begin
  if (unqryTablaG.FindField('NUMERO_FAC').AsString = '0') then
  begin
    unstrdprcGetContadorFactura.Params.Clear;
    unstrdprcGetContadorFactura.Params.CreateParam(
      ftString, 'pserie', ptInput);
    unstrdprcGetContadorFactura.Params.CreateParam(
      ftString, 'ptipodoc', ptInput);
    unstrdprcGetContadorFactura.Params.CreateParam(
      ftString, 'pcont', ptOutput);
    unstrdprcGetContadorFactura.Params.CreateParam(
      ftString, 'pEMPRESA_CONTADOR', ptInput);
    unstrdprcGetContadorFactura.Params.CreateParam(
      ftString, 'pUSUARIOMODIF', ptInput);
    unstrdprcGetContadorFactura.ParamByName('pserie').AsString :=
      unqryTablaG.FindField('SERIE_FAC').AsString;
    unstrdprcGetContadorFactura.ParamByName('ptipodoc').AsString :=
      CrearConfiguracionDocumento(tdFactura, sdVenta).TipoContador;
    unstrdprcGetContadorFactura.ParamByName('pUSUARIOMODIF').AsString :=
      IdentidadSesion.Usuario;
    unstrdprcGetContadorFactura.ParamByName(
      'pEMPRESA_CONTADOR').AsString :=
        unqryTablaG.FindField('CODIGO_EMP_FAC').AsString;
    unstrdprcGetContadorFactura.ExecProc;
    unqryTablaG.FindField('NUMERO_FAC').AsString :=
      unstrdprcGetContadorFactura.ParamByName('pcont').AsString;
  end;
end;

function TdmFacturas.TotalPrendasFactura: Double;
begin
  Result := TotalPrendasLineasVenta(unqryLinFac,
    'TIPO_IVA_ARTICULO_FACLIN');
end;

procedure TdmFacturas.DesempaquetarAtributosLineas;
var
  bReadOnlyLineas: Boolean;
begin
  if unqryLinFac.Active and (not unqryLinFac.IsEmpty) and
     (unqryLinFac.FindField('ATTR1_VALOR_FACLIN') <> nil) and
     (unqryLinFac.FindField('NUM_ATRIBUTOS_FACLIN') <> nil) then
  begin
    FDesempaquetandoAtributos := True;
    bReadOnlyLineas := unqryLinFac.ReadOnly;
    if bReadOnlyLineas then
      unqryLinFac.ReadOnly := False;
    try
      DesempaquetarAtributosFactura(unqryLinFac);
    finally
      unqryLinFac.ReadOnly := bReadOnlyLineas;
      FDesempaquetandoAtributos := False;
    end;
  end;
end;

procedure TdmFacturas.GetCodigoAutoCliente;
begin
  if (unqryTablaG.FindField('CODIGO_CLI_FAC').AsString = '0') then
  begin
    //bEsNuevoCliente := True;
//    Llamada antigua a unstrdprcGetContador:
//    begin
//      Params.Clear;
//      Params.CreateParam(ftString, 'ptipodoc', ptInput);
//      Params.CreateParam(ftInteger, 'pcont', ptOutput);
//      Params.CreateParam(ftString, 'pUSUARIOMODIF', ptInput);
//      ParamByName('pUSUARIOMODIF').AsString := IdentidadSesion.Usuario;
//      ParamByName('ptipodoc').AsString :=  'CL';
//      ExecProc;
      unqryTablaG.FindField('CODIGO_CLI_FAC').AsString :=
                                                 ObtenerSiguienteContador(
                                                   ConexionPrincipal,
                                                   'CL',
                                                   IdentidadSesion.Usuario);
//    end;
  end;
end;

function TdmFacturas.TarifaDefault: string;
begin
  Result := ParametrosCaja.TarifaDefecto;
end;

procedure TdmFacturas.GuardarParametrosEDocFactura(ADataSet: TDataSet);
var
  Qry: TUniQuery;
  bCamposDisponibles: Boolean;
begin
  bCamposDisponibles :=
    (ADataSet.FindField('CODIGO_OFICINA_CONTABLE_FAC') <> nil) and
    (ADataSet.FindField('CODIGO_ORGANO_GESTOR_FAC') <> nil) and
    (ADataSet.FindField('CODIGO_UNIDAD_TRAMITADORA_FAC') <> nil) and
    (ADataSet.FindField('NOMBRE_PERSONA_CLIENTE_FAC') <> nil) and
    (ADataSet.FindField('APELLIDOS_PERSONA_CLIENTE_FAC') <> nil);
  if bCamposDisponibles and
     (Trim(ADataSet.FieldByName('NUMERO_FAC').AsString) <> '') and
     (Trim(ADataSet.FieldByName('SERIE_FAC').AsString) <> '') then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := unqryTablaG.Connection;
      Qry.SQL.Text :=
        ' UPDATE fza_facturas ' +
        ' SET CODIGO_OFICINA_CONTABLE_FAC = :OFICINA, ' +
        '     CODIGO_ORGANO_GESTOR_FAC = :ORGANO, ' +
        '     CODIGO_UNIDAD_TRAMITADORA_FAC = :UNIDAD, ' +
        '     NOMBRE_PERSONA_CLIENTE_FAC = :NOMBRE_PERSONA, ' +
        '     APELLIDOS_PERSONA_CLIENTE_FAC = :APELLIDOS_PERSONA ' +
        ' WHERE NUMERO_FAC = :NUMERO ' +
        '   AND SERIE_FAC = :SERIE ';
      Qry.ParamByName('OFICINA').AsString :=
        ADataSet.FieldByName('CODIGO_OFICINA_CONTABLE_FAC').AsString;
      Qry.ParamByName('ORGANO').AsString :=
        ADataSet.FieldByName('CODIGO_ORGANO_GESTOR_FAC').AsString;
      Qry.ParamByName('UNIDAD').AsString :=
        ADataSet.FieldByName('CODIGO_UNIDAD_TRAMITADORA_FAC').AsString;
      Qry.ParamByName('NOMBRE_PERSONA').AsString :=
        ADataSet.FieldByName('NOMBRE_PERSONA_CLIENTE_FAC').AsString;
      Qry.ParamByName('APELLIDOS_PERSONA').AsString :=
        ADataSet.FieldByName('APELLIDOS_PERSONA_CLIENTE_FAC').AsString;
      Qry.ParamByName('NUMERO').AsString :=
        ADataSet.FieldByName('NUMERO_FAC').AsString;
      Qry.ParamByName('SERIE').AsString :=
        ADataSet.FieldByName('SERIE_FAC').AsString;
      Qry.ExecSQL;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

procedure TdmFacturas.GuardarOpcionMovimientosFactura(ADataSet: TDataSet);
var
  Qry: TUniQuery;
begin
  if (ADataSet.FindField('ESMUEVE_STOCK_FAC') <> nil) and
     (Trim(ADataSet.FieldByName('NUMERO_FAC').AsString) <> '') and
     (Trim(ADataSet.FieldByName('SERIE_FAC').AsString) <> '') then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := unqryTablaG.Connection;
      Qry.SQL.Text :=
        'UPDATE fza_facturas ' +
        '   SET ESMUEVE_STOCK_FAC = :pMUEVE ' +
        ' WHERE NUMERO_FAC = :pNUMERO ' +
        '   AND SERIE_FAC = :pSERIE';
      Qry.ParamByName('pMUEVE').AsString :=
        ADataSet.FieldByName('ESMUEVE_STOCK_FAC').AsString;
      Qry.ParamByName('pNUMERO').AsString :=
        ADataSet.FieldByName('NUMERO_FAC').AsString;
      Qry.ParamByName('pSERIE').AsString :=
        ADataSet.FieldByName('SERIE_FAC').AsString;
      Qry.ExecSQL;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

procedure TdmFacturas.GetCodigoAutoEmpresa;
begin
  if unqryTablaG.FindField('CODIGO_EMP_FAC').AsString = '0' then
  begin
//    Llamada antigua a unstrdprcGetContador:
//    begin
//      Params.Clear;
//      Params.CreateParam(ftString, 'ptipodoc', ptInput);
//      Params.CreateParam(ftInteger, 'pcont', ptOutput);
//      Params.CreateParam(ftString, 'pUSUARIOMODIF', ptInput);
//      ParamByName('ptipodoc').AsString :=  'EM';
//      ParamByName('pUSUARIOMODIF').AsString := IdentidadSesion.Usuario;
//      ExecProc;
      unqryTablaG.FindField('CODIGO_EMP_FAC').AsString :=
                                                 ObtenerSiguienteContador(
                                                   ConexionPrincipal,
                                                   'EM',
                                                   IdentidadSesion.Usuario);
//    end;
  end;
end;

function TdmFacturas.FacturaGeneraMovimientos: Boolean;
var
  bMueveStock: Boolean;
  sTipo: string;
begin
  Result := False;
  if unqryTablaG.Active and
     (unqryTablaG.FindField('TIPO_FAC') <> nil) then
  begin
    sTipo := unqryTablaG.FieldByName('TIPO_FAC').AsString;
    bMueveStock := False;
    if unqryTablaG.FindField('ESMUEVE_STOCK_FAC') <> nil then
    begin
      bMueveStock := SameText(
        unqryTablaG.FieldByName('ESMUEVE_STOCK_FAC').AsString,
        'S');
    end;
    Result := FacturaDebeGenerarMovimientos(
      sTipo,
      bMueveStock);
  end;
end;

procedure TdmFacturas.unqryFacAfterPost(DataSet: TDataSet);
begin
  inherited;
  ProcesarFacturaPosteada(DataSet);
end;

procedure TdmFacturas.ProcesarFacturaPosteada(ADataSet: TDataSet);
var
  bTransaccionPropia: Boolean;
begin
  bTransaccionPropia := not ConexionPrincipal.InTransaction;
  if bTransaccionPropia then
    ConexionPrincipal.StartTransaction;
  try
    try
      // El DFM es anterior a estos campos; se persisten expresamente.
      GuardarOpcionMovimientosFactura(ADataSet);
      NotificarResultadoOperacion(CalcularFactura);
      GuardarParametrosEDocFactura(ADataSet);
      if bTransaccionPropia and ConexionPrincipal.InTransaction then
        ConexionPrincipal.Commit;
    except
      if bTransaccionPropia and ConexionPrincipal.InTransaction then
        ConexionPrincipal.Rollback;
      raise;
    end;
  finally
    NotificarAdvertenciasPendientes;
  end;
end;

procedure TdmFacturas.unqryLinFacAfterDelete(DataSet: TDataSet);
begin
  inherited;
  NotificarResultadoOperacion(CalcularFactura);
end;

procedure TdmFacturas.unqryLinFacAfterInsert(DataSet: TDataSet);
begin
  inherited;
  AplicarValoresPorDefecto(
    ConexionPrincipal,
    unqryLinFac,
    'fza_facturas_lineas');
  // Limpiar nro de línea para que BeforePost llame al SP de contador
  unqryLinFac.FindField(fnrolin).AsString := '0';
  unqryLinFac.FindField(fporiva).AsCurrency := GetTipoIVA(
    unqryLinFac.FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString);
  unqryLinFac.FieldByName(fimpcl).AsString :=
    unqryTablaG.FieldByName('ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString;
end;

procedure TdmFacturas.unqryLinFacBeforePost(DataSet: TDataSet);
var
  sNuevoNroLinea: string;
  iContadorBD: Integer;
  iNuevaLinea: Integer;
  sNumLin: string;
  sNumero: string;
  sSerie: string;
  function FieldByName(const Nombre: string): TField;
  begin
    Result := unqryLinFac.FieldByName(Nombre);
  end;
  function FindField(const Nombre: string): TField;
  begin
    Result := unqryLinFac.FindField(Nombre);
  end;
begin
  inherited;
  // Desempaquetado ATTR en curso: post descriptivo, sin logica de
  // numeracion ni fiscal.
  if not FDesempaquetandoAtributos then
  begin
  // Salvaguarda si la linea llega con un SKU/codigo de barras sin pasar
  // por el editor de articulo del formulario.
  NormalizarArticuloSkuEnDataSet(ConexionPrincipal, unqryLinFac,
    'CODIGO_ART_FACLIN', 'CODIGO_UNIDAD_FACLIN');
  if FieldByName(fdesart).AsString = '' then
  begin
    DataSet.Cancel;
    Abort;
  end;
  sNumLin := Trim(FindField(fnrolin).AsString);
  sNumero := Trim(unqryTablaG.FieldByName(fnrofac).AsString);
  sSerie  := Trim(unqryTablaG.FieldByName(fseriefac).AsString);
  if (sNumLin = '0') or
     (sNumLin = '') or
     ((DataSet.State = dsInsert) and
      LineaDocExiste(CrearContadorLineasDocumento(ConexionPrincipal),
        LIN_FACTURAS, sSerie, sNumero,
        sNumLin)) then
  begin
    iNuevaLinea := GetSiguienteLineaDocLibreSiguiente(
      CrearContadorLineasDocumento(ConexionPrincipal),
      CONT_FACTURAS, LIN_FACTURAS, sSerie, sNumero);
    if iNuevaLinea > 0 then
      sNuevoNroLinea := Format('%.3d', [iNuevaLinea])
    else
    begin
      unstdGetContadorLinea.ParamByName('pnumfac').AsString := sNumero;
      unstdGetContadorLinea.ParamByName('pserie').AsString := sSerie;
      unstdGetContadorLinea.ExecProc;
      sNuevoNroLinea :=
        unstdGetContadorLinea.ParamByName('presul').AsString;
    end;
    FindField(fnrolin).AsString := sNuevoNroLinea;
    // Sincronizar el contador en el dataset de cabecera para que un
    // Post posterior de la cabecera no sobreescriba el valor correcto
    if unqryTablaG.FindField('CONTADOR_LINEAS_FAC') <> nil then
    begin
      iContadorBD := StrToIntDef(sNuevoNroLinea, 0) + 10;
      if unqryTablaG.State = dsBrowse then
        unqryTablaG.Edit;
      unqryTablaG.FieldByName('CONTADOR_LINEAS_FAC').AsString :=
        Format('%.3d', [iContadorBD]);
    end;
  end;
  if DataSet.State in [dsEdit, dsInsert] then
    ActualizarAuditoria(DataSet);
  end;
end;

procedure TdmFacturas.unqryTablaGBeforeDelete(DataSet: TDataSet);
var
  Serie: string;
  Numero: string;
  Fase: string;
  Resultado: TResultadoBorradoFactura;
  Confirmado: Boolean;
begin
  Serie := DataSet.FieldByName(fseriefac).AsString;
  Numero := DataSet.FieldByName(fnrofac).AsString;
  Fase := '';
  if DataSet.FindField(ffasefac) <> nil then
    Fase := DataSet.FieldByName(ffasefac).AsString;
  RequerirServiciosFactura;
  Resultado := FServicioBorrado.Validar(Serie, Numero, Fase);
  if not Resultado.Permitido then
  begin
    NotificarResultadoBorrado(Resultado);
    Abort;
  end;
  Confirmado := False;
  if Assigned(FOnConfirmarBorrado) then
    Confirmado := FOnConfirmarBorrado(Serie, Numero);
  if not Confirmado then
  begin
    Abort;
  end;
  Resultado := FServicioBorrado.Preparar(Serie, Numero, Fase);
  if not Resultado.Permitido then
  begin
    NotificarResultadoBorrado(Resultado);
    Abort;
  end;
end;

procedure TdmFacturas.unqryTablaGAfterDeleteTx(DataSet: TDataSet);
begin
  if Assigned(FServicioBorrado) then
    FServicioBorrado.Confirmar;
end;

procedure TdmFacturas.unqryTablaGDeleteErrorTx(DataSet: TDataSet;
  E: EDatabaseError; var Action: TDataAction);
begin
  RevertirBorradoFactura(FServicioBorrado);
end;

procedure TdmFacturas.unqryTablaGAfterInsert(DataSet: TDataSet);
  function FieldByName(const Nombre: string): TField;
  begin
    Result := unqryTablaG.FieldByName(Nombre);
  end;
  function FindField(const Nombre: string): TField;
  begin
    Result := unqryTablaG.FindField(Nombre);
  end;
begin
  inherited;
    AplicarValoresPorDefecto(ConexionPrincipal, unqryTablaG, 'fza_facturas');
//    FieldByName('NUMERO_FAC').AsString := '0';
//    FieldByName('CODIGO_CLI_FAC').AsString := '0';
//    FieldByName('CODIGO_EMP_FAC').AsString := '0';
    FieldByName('TARIFA_ARTICULO_CLIENTE_FAC').AsString := TarifaDefault;
    FieldByName('ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString :=
                         unqryTarifas.FieldByName('ESIMP_INCL_TAR').AsString;
    FieldByName('FECHA_FAC').AsDateTime := Trunc(Now);
    FieldByName('FORMA_PAGO_FAC').AsString := FormaPagoDefault;
    FieldByName('ESCONSOLIDADA_FAC').AsString := 'N';
    // Toda factura nace en borrador: editable y sin imprimir hasta
    // lanzarla a Verifactu (Consolidar)
    FieldByName('FASE_FAC').AsString := 'BORRADOR';
    // Tipo de factura segun el formulario (NORMAL / SIMPLIFICADA)
    FieldByName('TIPO_FAC').AsString := FTipoFacturaDefecto;
    // Una factura normal insertada a mano es venta directa y mueve stock.
    // Los flujos que parten de otro documento deben negarlo expresamente.
    if FindField('ESMUEVE_STOCK_FAC') <> nil then
    begin
      if SameText(FieldByName('TIPO_FAC').AsString, 'NORMAL') then
        FieldByName('ESMUEVE_STOCK_FAC').AsString := 'S'
      else
        FieldByName('ESMUEVE_STOCK_FAC').AsString := 'N';
    end;
    // Encadenar alta: lo resuelve el form via OnNuevaFactura (el DM ya
    // no invoca botones de la UI directamente).
    if Assigned(FOnNuevaFactura) then
      FOnNuevaFactura(Self);
    RefrescarAlmacenes(FieldByName('CODIGO_EMP_FAC').AsString);
    // Empresa sin almacenes activos (instalacion de solo servicios): la
    // factura no puede mover stock y el check nace desmarcado, dejando
    // el almacen como opcional.
    if (FindField('ESMUEVE_STOCK_FAC') <> nil) and
       unqryAlmacenesFac.Active and unqryAlmacenesFac.IsEmpty then
      FieldByName('ESMUEVE_STOCK_FAC').AsString := 'N';
end;

procedure TdmFacturas.unqryLinFacBeforeEdit(DataSet: TDataSet);
begin
  inherited;
  //
  unqryLinFacBeforeInsert(DataSet);
end;

procedure TdmFacturas.unqryLinFacBeforeInsert(DataSet: TDataSet);
begin
  inherited;
  // Verificar que la factura esté guardada antes de insertar líneas
  if not Assigned(unqryTablaG) then
    Abort;
  // Si la cabecera está en edición o inserción, grabarla primero
  if unqryTablaG.State in [dsInsert, dsEdit] then
  begin
    try
      unqryTablaG.Post;
    except
      on E: EAbort do
      begin
        raise;
      end;
      on E: Exception do
      begin
        NotificarResultadoOperacion(
          TResultadoOperacionFactura.Error(
            Format(
              SErrorInsertarLineasCabeceraFactura,
              [E.Message])));
        Abort;
      end;
    end;
  end;
  // Verificar que exista un número de factura válido
  if (unqryTablaG.FieldByName('NUMERO_FAC').AsString = '') or
     (unqryTablaG.FieldByName('NUMERO_FAC').AsString = '0') or
     (unqryTablaG.FieldByName('SERIE_FAC').AsString = '') then
  begin
    NotificarResultadoOperacion(
      TResultadoOperacionFactura.Error(
        SErrorBorradorSinGrabarParaLineas));
    Abort;
  end;
end;

procedure TdmFacturas.unqryLinFacAfterPost(DataSet: TDataSet);
var
  Procedimiento: TUniStoredProc;
begin
  inherited;
  // Los posts del desempaquetado ATTR no crean articulos ni alteran
  // importes: salir sin efectos de negocio.
  if not FDesempaquetandoAtributos then
  begin
  if not FCalculandoFactura and
     SameText(unqryTablaG.FieldByName(fcreart).AsString, 'S') then
  begin
    Procedimiento := unstdCrearArticuloLin;
    Procedimiento.ParamByName('pCODIGO_ARTICULO').AsString :=
      unqryLinFac.FieldByName(fcodart).AsString;
    Procedimiento.ParamByName('pDESCRIPCION_ARTICULO').AsString :=
      unqryLinFac.FieldByName(fdesart).AsString;
    Procedimiento.ParamByName('pTIPOIVA_ARTICULO').AsString :=
      unqryLinFac.FieldByName(ftipiva).AsString;
    Procedimiento.ParamByName('pTIPO_CANTIDAD_ARTICULO').AsString :=
      unqryLinFac.FieldByName(ftipocant).AsString;
    Procedimiento.ParamByName('pESACTIVO_FIJO_ARTICULO').AsString :=
      unqryTablaG.FieldByName(factfij).AsString;
    Procedimiento.ParamByName('pCODIGO_FAMILIA').AsString :=
      unqryLinFac.FieldByName(fcodfam).AsString;
    Procedimiento.ParamByName('pNOMBRE_FAMILIA').AsString :=
      unqryLinFac.FieldByName(fnomfam).AsString;
    Procedimiento.ParamByName('pCODIGO_PROVEEDOR').AsString :=
      unqryLinFac.FieldByName(fcodprov).AsString;
    Procedimiento.ParamByName('pRAZONSOCIAL_PROVEEDOR').AsString :=
      unqryLinFac.FieldByName(frazprov).AsString;
    Procedimiento.ParamByName('pESPROVEEDORPRINCIPAL').AsString :=
      unqryLinFac.FieldByName(fpprov).AsString;
    Procedimiento.ParamByName('pPRECIO_ULT_COMPRA').AsCurrency :=
      unqryLinFac.FieldByName(fprecultc).AsCurrency;
//      ParamByName('pFECHA_FACTURA').AsString :=
//                                 unqryTablaG.FieldByName(ffechfac).AsString;
    Procedimiento.ParamByName('pCODIGO_TARIFA').AsString :=
      unqryLinFac.FieldByName(fcodtariflin).AsString;
    Procedimiento.ParamByName('pPRECIOSALIDA_TARIFA').AsCurrency :=
      unqryLinFac.FieldByName(fpreciosal).AsCurrency;
    if SameText(unqryLinFac.FieldByName(fimpcl).AsString, 'S') then
      Procedimiento.ParamByName('pPRECIOFINAL_TARIFA').AsCurrency :=
        unqryLinFac.FieldByName(fpreciva).AsCurrency
    else
      Procedimiento.ParamByName('pPRECIOFINAL_TARIFA').AsCurrency :=
        unqryLinFac.FieldByName(fpresiva).AsCurrency;
    Procedimiento.ParamByName('pPRECIO_DTO_TARIFA').AsCurrency :=
      unqryLinFac.FieldByName(fpordto).AsCurrency;
    Procedimiento.ParamByName('pPORCEN_DTO_TARIFA').AsCurrency :=
      unqryLinFac.FieldByName(fpordto).AsCurrency;
    Procedimiento.ParamByName('pUSUARIO').AsString :=
      IdentidadSesion.Usuario;
//      ParamByName('pUSUARIO').AsString         := IdentidadSesion.Usuario;
      //ParamByName('pINSTANTEMODIF').AsDateTime := Now;
      // ojo!!!! HAY UN TEMAZO DE UNIDAC CON EL PASO DE TIMESTAMPS POR PARÁMETRO
      //  ParamByName('pINSTANTEMODIF').AsString :=
      //                             FormatDateTime('YYYY-MM-DD hh:mm:ss', Now);
    Procedimiento.ExecProc;
  end;
  if not FCalculandoFactura and FRecalculoFacturaPendiente then
  begin
    FRecalculoFacturaPendiente := False;
    NotificarResultadoOperacion(CalcularFactura);
  end;
  end;
end;

procedure TdmFacturas.unqryFacBeforePost(DataSet: TDataSet);
begin
  inherited;
  // Impide que un Post anidado deje los buffers de UniDAC a medio postear.
  if FValidandoPost then
    Abort;
  FAdvertenciasPendientes.Clear;
  FValidandoPost := True;
  try
    try
      ValidarCabeceraBeforePost(DataSet);
    except
      on E: EValidacionFactura do
      begin
        FAdvertenciasPendientes.Clear;
        if Assigned(FOnValidacion) then
        begin
          FOnValidacion(E);
          Abort;
        end
        else
        begin
          raise;
        end;
      end;
      on E: Exception do
      begin
        FAdvertenciasPendientes.Clear;
        raise;
      end;
    end;
  finally
    FValidandoPost := False;
  end;
end;

procedure TdmFacturas.ValidarCabeceraBeforePost(DataSet: TDataSet);
var
  bValidar: Boolean;
  Datos: TDatosValidacionCabeceraFactura;
begin
  Datos := CrearDatosValidacionCabeceraFactura(unqryTablaG);
  Datos.SeriePerteneceOtraEmpresa := ExisteSerieEmpresa(
    Datos.Serie, unqryTablaG.FieldByName(fcodemp).AsString,
    CrearConfiguracionDocumento(tdFactura, sdVenta).TipoContador);
  ValidarIdentidadCabeceraFactura(Datos);
  bValidar := EsCabeceraFacturaValidable(Datos);
  if bValidar then
    ValidarOperacionVfactu;
  Datos.ControlarCronologia :=
    bValidar and not SinVerifactuActivo(ParametrosApp);
  if Datos.ControlarCronologia and Datos.TieneFecha then
  begin
    Datos.UltimaFechaSerie := UltimaFechaSerie(Datos.Serie,
      unqryTablaG.FieldByName(fcodemp).AsString, Datos.Numero);
  end;
  ValidarCoherenciaCabeceraFactura(Datos);
  if FechaCabeceraFacturaEsFutura(Datos, Date) then
    RegistrarAdvertencia(SAvisoFechaBorradorFutura, True);
  if unqryTablaG.State in [dsEdit, dsInsert] then
  begin
    if (unqryTablaG.State = dsInsert) and
       ParametrosApp.Licencia.Comprobada and Datos.TieneFecha then
    begin
      ValidarLimiteDemoFacturas(
        ConexionPrincipal, ParametrosApp.Licencia.Estado, Datos.Fecha);
    end;
    if Datos.Numero = '0' then
      GetCodigoAutoFactura;
    if unqryTablaG.FieldByName('CODIGO_CLI_FAC').AsString = '0' then
      GetCodigoAutoCliente;
    if unqryTablaG.FieldByName('CODIGO_EMP_FAC').AsString = '0' then
      GetCodigoAutoEmpresa;
    Datos.Numero := unqryTablaG.FieldByName('NUMERO_FAC').AsString;
    ValidarNumeroCabeceraFactura(Datos);
    if bValidar and (unqryTablaG.State = dsInsert) and
       HayHuecoNumeracion(
         Datos.Serie,
         unqryTablaG.FieldByName(fcodemp).AsString,
         Datos.Numero) then
    begin
      RegistrarAdvertencia(
        Format(SAvisoHuecoNumeracionFactura, [Datos.Serie]), True);
    end;
    ActualizarAuditoria(DataSet);
  end;
end;

initialization
  RegistrarDataModule(TdmFacturas);
  ForceReferenceToClass(TdmFacturas);
end.
