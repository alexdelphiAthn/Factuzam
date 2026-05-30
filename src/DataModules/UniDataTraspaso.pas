{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataTraspaso                                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de la operativa de traspasos entre almacenes (TPV).           }
{    El traspaso ejecutado se graba SOLO en fza_caja_operaciones (TR/AT) +     }
{    fza_movimientos_almacen (par salida+entrada). Ver                         }
{    DESARROLLOS EN CURSO/traspasos_caja.md.                                   }
{******************************************************************************}
unit UniDataTraspaso;

interface

uses
  System.SysUtils, System.Classes, Data.DB, Datasnap.DBClient, Uni, MemDS,
  DBAccess, System.Math, System.StrUtils, inLibGlobalVar, inLibtb;

type
  // Modo de la operativa: traspaso directo, solicitar a otro almacén o
  // atender una solicitud que me han hecho.
  TModoTraspaso = (mtTraspaso, mtSolicitar, mtAtender);

  TdmTraspaso = class(TDataModule)
    cdsCabecera: TClientDataSet;
    cdsLineas: TClientDataSet;
    dsCabecera: TDataSource;
    dsLineas: TDataSource;
    qryAux: TUniQuery;
    procedure DataModuleCreate(Sender: TObject);
  private
    FModo: TModoTraspaso;
    procedure ConfigurarEstructuraCabecera;
    procedure ConfigurarEstructuraLineas;
    function ObtenerEmpresaAlmacen(const AAlmacen: string): string;
    // Serie del documento de traspaso (fza_empresas_series + fallback) y su
    // siguiente número (PRC_GET_NEXT_CONT_FACT_SERIE, como la factura).
    function ObtenerSerieDocumento(const AEmpresa, AAlmacen, ACaja,
                             ATipoDoc: string): string;
    function SiguienteNumeroDocumento(const ASerie, ATipoDoc, AEmpresa,
                             AUsuario: string): string;
    // Replica autocontenida de los helpers de UniDataCaja (privados allí).
    function SiguienteOpCaja(const AEmpresa, AAlmacen, ACaja,
                             AEmpleado: string): string;
    procedure InsertarMovimientoAlmacen(QryTrx: TUniQuery;
                             const ATipoDoc, ASerie, ANro, ALinea, AEmpresa,
                             AAlmacen, ACaja, AAlmacenContra, ATipoMov,
                             ASku: string; ACantidad: Double; ACoste: Currency;
                             const AUsuario: string;
                             const AAlmacenDoc: string = '';
                             const ANumOperacion: string = '';
                             const ACodCliente: string = '';
                             const ACodArticulo: string = '');
    procedure InsertarOperacionCaja(QryTrx: TUniQuery;
                             const AEmpresa, AAlmacen, ACaja, ANumOperacion,
                             ATipoOp: string; AImporte: Currency;
                             const AEmpleado, AConcepto, ASerieOrigen,
                             ANroOrigen, AEmpresaContra, AAlmContra,
                             AEsTraspaso, ANroDoc, ASerieDoc: string);
    // Suma lo servido a las líneas de la solicitud y recalcula su estado.
    procedure MarcarSolicitudAtendida(QryTrx: TUniQuery;
                             const ANumero, ASerie: string);
  public
    property Modo: TModoTraspaso read FModo write FModo;
    procedure PrepararNuevo(AModo: TModoTraspaso; const AEmpresa, AAlmacen,
                            ACaja: string; AFecha: TDateTime);
    function ObtenerCosteMedio(const ASku, AAlmacen: string): Currency;
    function ObtenerStock(const ASku, AAlmacen: string): Double;
    // Resuelve el SKU contra el almacén origen; devuelve descripción, padre,
    // coste medio y stock disponible. False si el artículo no existe.
    function ResolverSku(const ASku, AAlmacen: string;
                         out ADescripcion, ACodArticulo: string;
                         out ACoste: Currency; out AStock: Double): Boolean;
    // Añade (o consolida) una línea al ticket de traspaso. False si el SKU
    // no es válido.
    function AnadirLinea(const ASku: string; ACantidad: Double): Boolean;
    // Graba el traspaso directo: par salida+entrada por línea + operación
    // de caja TR/AT, todo en una transacción. Devuelve el nº de operación.
    function GrabarTraspaso(const AAlmacenDestino: string;
                            out ANumOperacion: string;
                            const ANumSolicitud: string = '';
                            const ASerieSolicitud: string = ''): Boolean;
    // --- Ciclo de solicitudes (fza_traspasos_solicitudes) ---
    // Solicitar: graba la petición (origen = a quién pido) en estado
    // PENDIENTE, sin mover stock.
    function GrabarSolicitud(const AAlmacenOrigen: string;
                             out ANumero, ASerie: string): Boolean;
    // Atender: lista las solicitudes pendientes que me tocan (yo, origen).
    procedure CargarSolicitudesPendientes(AItems, ACodigos: TStrings);
    // Carga una solicitud pendiente en cabecera/líneas para servirla.
    function CargarSolicitud(const ANumero, ASerie: string): Boolean;
    // Valida el empleado responsable por su código o diminutivo de ticket.
    function ValidarEmpleado(const ABusqueda: string;
                             out ACodigo, ANombre: string): Boolean;
  end;

var
  dmTraspaso: TdmTraspaso;

implementation

{$R *.dfm}

procedure TdmTraspaso.DataModuleCreate(Sender: TObject);
begin
  qryAux.Connection := oConn;
  ConfigurarEstructuraCabecera;
  ConfigurarEstructuraLineas;
end;

procedure TdmTraspaso.ConfigurarEstructuraCabecera;
begin
  if cdsCabecera.Active then
    cdsCabecera.Close;
  cdsCabecera.FieldDefs.Clear;
  cdsCabecera.IndexDefs.Clear;
  with cdsCabecera.FieldDefs do
  begin
    Add('CODIGO_EMP', ftString, 20);
    Add('CODIGO_ALM_ORIGEN', ftString, 10);
    Add('CODIGO_ALM_DESTINO', ftString, 10);
    Add('CODIGO_CAJA', ftString, 10);
    Add('CODIGO_EMPLEADO', ftString, 20);
    Add('NUMERO_SOL', ftString, 20);
    Add('SERIE_SOL', ftString, 20);
    Add('FECHA', ftDate, 0);
    Add('CONTADOR_LINEAS', ftInteger, 0);
    Add('TOTAL', ftCurrency, 0);
  end;
  cdsCabecera.CreateDataSet;
end;

procedure TdmTraspaso.ConfigurarEstructuraLineas;
begin
  if cdsLineas.Active then
    cdsLineas.Close;
  cdsLineas.FieldDefs.Clear;
  cdsLineas.IndexDefs.Clear;
  with cdsLineas.FieldDefs do
  begin
    Add('LINEA', ftString, 4);
    Add('CODIGO_ART', ftString, 20);
    Add('CODIGO_UNIDAD', ftString, 50);
    Add('DESCRIPCION', ftString, 100);
    Add('CANTIDAD', ftFloat, 0);
    Add('PRECIO_COSTE', ftCurrency, 0);
    Add('TOTAL', ftCurrency, 0);
    Add('STOCK_ORIGEN', ftFloat, 0);
  end;
  cdsLineas.CreateDataSet;
end;

procedure TdmTraspaso.PrepararNuevo(AModo: TModoTraspaso; const AEmpresa,
                                    AAlmacen, ACaja: string; AFecha: TDateTime);
begin
  FModo := AModo;
  ConfigurarEstructuraCabecera;
  ConfigurarEstructuraLineas;
  cdsCabecera.Append;
  cdsCabecera.FieldByName('CODIGO_EMP').AsString := AEmpresa;
  // En mtTraspaso el origen es el propio; en mtSolicitar se invierte (origen
  // será otro almacén y el propio pasa a destino) — se ajusta desde el form.
  cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString := AAlmacen;
  cdsCabecera.FieldByName('CODIGO_CAJA').AsString := ACaja;
  cdsCabecera.FieldByName('FECHA').AsDateTime := AFecha;
  cdsCabecera.FieldByName('CONTADOR_LINEAS').AsInteger := 0;
  cdsCabecera.FieldByName('TOTAL').AsCurrency := 0;
  cdsCabecera.Post;
end;

function TdmTraspaso.ObtenerEmpresaAlmacen(const AAlmacen: string): string;
begin
  qryAux.SQL.Text :=
    'SELECT CODIGO_EMP_ALM FROM fza_almacenes WHERE CODIGO_ALM_ALM = :ALM';
  qryAux.ParamByName('ALM').AsString := AAlmacen;
  qryAux.Open;
  try
    if qryAux.IsEmpty then
      Result := ''
    else
      Result := qryAux.FieldByName('CODIGO_EMP_ALM').AsString;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.ValidarEmpleado(const ABusqueda: string;
                                     out ACodigo, ANombre: string): Boolean;
begin
  Result := False;
  ACodigo := '';
  ANombre := '';
  qryAux.SQL.Text :=
    'SELECT CODIGO_EMPLEADO_USU, DIMINUTIVO_TICKET_USU FROM fza_usuarios' +
    ' WHERE (CODIGO_EMPLEADO_USU = :BUS OR DIMINUTIVO_TICKET_USU = :BUS)' +
    '   AND ESACTIVO_USU = ''S'' LIMIT 1';
  qryAux.ParamByName('BUS').AsString := ABusqueda;
  qryAux.Open;
  try
    if not qryAux.IsEmpty then
    begin
      ACodigo := qryAux.FieldByName('CODIGO_EMPLEADO_USU').AsString;
      ANombre := qryAux.FieldByName('DIMINUTIVO_TICKET_USU').AsString;
      Result := True;
    end;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.ObtenerSerieDocumento(const AEmpresa, AAlmacen, ACaja,
                                           ATipoDoc: string): string;
begin
  // Serie configurada para este tipo de documento (prefiere la de la caja /
  // almacén; si no, la de empresa). Fallback: el propio tipo de documento.
  qryAux.SQL.Text :=
    'SELECT EMPSER FROM fza_empresas_series' +
    ' WHERE CODIGO_EMP_EMPSER = :EMP AND TIPO_DOC_EMPSER = :TIPO' +
    '   AND (CODIGO_ALM_EMPSER = :ALM OR CODIGO_ALM_EMPSER IS NULL' +
    '        OR CODIGO_ALM_EMPSER = '''')' +
    '   AND (CODIGO_CAJA_EMPSER = :CAJA OR CODIGO_CAJA_EMPSER IS NULL' +
    '        OR CODIGO_CAJA_EMPSER = '''')' +
    ' ORDER BY (CODIGO_CAJA_EMPSER = :CAJA) DESC,' +
    '          (CODIGO_ALM_EMPSER = :ALM) DESC LIMIT 1';
  qryAux.ParamByName('EMP').AsString := AEmpresa;
  qryAux.ParamByName('TIPO').AsString := ATipoDoc;
  qryAux.ParamByName('ALM').AsString := AAlmacen;
  qryAux.ParamByName('CAJA').AsString := ACaja;
  qryAux.Open;
  try
    if qryAux.IsEmpty then
      Result := ATipoDoc
    else
      Result := qryAux.FieldByName('EMPSER').AsString;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.SiguienteNumeroDocumento(const ASerie, ATipoDoc, AEmpresa,
                                              AUsuario: string): string;
var
  SpTrx: TUniStoredProc;
begin
  SpTrx := TUniStoredProc.Create(nil);
  try
    SpTrx.Connection := oConn;
    SpTrx.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
    SpTrx.Prepare;
    SpTrx.ParamByName('pserie').AsString := ASerie;
    SpTrx.ParamByName('pTipoDoc').AsString := ATipoDoc;
    SpTrx.ParamByName('pEMPRESA_CONTADOR').AsString := AEmpresa;
    SpTrx.ParamByName('pUSUARIOMODIF').AsString := AUsuario;
    SpTrx.Execute;
    Result := SpTrx.ParamByName('pcont').AsString;
  finally
    FreeAndNil(SpTrx);
  end;
end;

function TdmTraspaso.ObtenerCosteMedio(const ASku, AAlmacen: string): Currency;
begin
  qryAux.SQL.Text :=
    'SELECT PRECIO_MEDIO_STK FROM fza_articulos_stockactual ' +
    ' WHERE CODIGO_ALM_STK = :ALM AND CODIGO_UNIDAD_STK = :SKU';
  qryAux.ParamByName('ALM').AsString := AAlmacen;
  qryAux.ParamByName('SKU').AsString := ASku;
  qryAux.Open;
  try
    if qryAux.IsEmpty then
      Result := 0
    else
      Result := qryAux.FieldByName('PRECIO_MEDIO_STK').AsCurrency;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.ObtenerStock(const ASku, AAlmacen: string): Double;
begin
  qryAux.SQL.Text :=
    'SELECT CANTIDAD_STK FROM fza_articulos_stockactual ' +
    ' WHERE CODIGO_ALM_STK = :ALM AND CODIGO_UNIDAD_STK = :SKU';
  qryAux.ParamByName('ALM').AsString := AAlmacen;
  qryAux.ParamByName('SKU').AsString := ASku;
  qryAux.Open;
  try
    if qryAux.IsEmpty then
      Result := 0
    else
      Result := qryAux.FieldByName('CANTIDAD_STK').AsFloat;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.ResolverSku(const ASku, AAlmacen: string;
                                 out ADescripcion, ACodArticulo: string;
                                 out ACoste: Currency;
                                 out AStock: Double): Boolean;
var
  sPadre: string;
begin
  Result := False;
  ADescripcion := '';
  ACodArticulo := '';
  ACoste := 0;
  AStock := 0;
  // El padre es el primer tramo del SKU (PADRE/COLOR/TALLA).
  sPadre := ASku;
  if Pos('/', ASku) > 0 then
    sPadre := Copy(ASku, 1, Pos('/', ASku) - 1);
  qryAux.SQL.Text :=
    'SELECT CODIGO_ART_ART, DESCRIPCION_ART, TIPO_ART FROM fza_articulos ' +
    ' WHERE CODIGO_ART_ART = :ART AND ESACTIVO_ART = ''S''';
  qryAux.ParamByName('ART').AsString := sPadre;
  qryAux.Open;
  try
    if not qryAux.IsEmpty then
    begin
      // Sólo se traspasan artículos físicos con control de stock.
      if SameText(qryAux.FieldByName('TIPO_ART').AsString, 'ESTANDAR') then
      begin
        ACodArticulo := qryAux.FieldByName('CODIGO_ART_ART').AsString;
        ADescripcion := qryAux.FieldByName('DESCRIPCION_ART').AsString;
        Result := True;
      end;
    end;
  finally
    qryAux.Close;
  end;
  if Result then
  begin
    ACoste := ObtenerCosteMedio(ASku, AAlmacen);
    AStock := ObtenerStock(ASku, AAlmacen);
  end;
end;

function TdmTraspaso.AnadirLinea(const ASku: string; ACantidad: Double): Boolean;
var
  sDescripcion, sArticulo: string;
  cCoste: Currency;
  dStock: Double;
  sAlmacenOrigen: string;
begin
  sAlmacenOrigen := cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
  Result := ResolverSku(ASku, sAlmacenOrigen, sDescripcion, sArticulo,
                        cCoste, dStock);
  if not Result then
    Exit;
  // Consolida si el SKU ya está en el ticket.
  if cdsLineas.Locate('CODIGO_UNIDAD', ASku, []) then
  begin
    cdsLineas.Edit;
    cdsLineas.FieldByName('CANTIDAD').AsFloat :=
      cdsLineas.FieldByName('CANTIDAD').AsFloat + ACantidad;
  end
  else
  begin
    cdsLineas.Append;
    cdsLineas.FieldByName('CODIGO_ART').AsString := sArticulo;
    cdsLineas.FieldByName('CODIGO_UNIDAD').AsString := ASku;
    cdsLineas.FieldByName('DESCRIPCION').AsString := sDescripcion;
    cdsLineas.FieldByName('CANTIDAD').AsFloat := ACantidad;
    cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency := cCoste;
    cdsLineas.FieldByName('STOCK_ORIGEN').AsFloat := dStock;
  end;
  cdsLineas.FieldByName('TOTAL').AsCurrency :=
    cdsLineas.FieldByName('CANTIDAD').AsFloat *
    cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency;
  cdsLineas.Post;
end;

function TdmTraspaso.SiguienteOpCaja(const AEmpresa, AAlmacen, ACaja,
                                     AEmpleado: string): string;
var
  SpTrx: TUniStoredProc;
begin
  SpTrx := TUniStoredProc.Create(nil);
  try
    SpTrx.Connection := oConn;
    SpTrx.StoredProcName := 'PRC_GET_NEXT_OP_CAJA';
    SpTrx.Params.CreateParam(ftString, 'pEmpresa', ptInput).AsString :=
      AEmpresa;
    SpTrx.Params.CreateParam(ftString, 'pAlmacen', ptInput).AsString :=
      AAlmacen;
    SpTrx.Params.CreateParam(ftString, 'pCaja', ptInput).AsString := ACaja;
    SpTrx.Params.CreateParam(ftString, 'pUsuario', ptInput).AsString :=
      AEmpleado;
    SpTrx.Params.CreateParam(ftString, 'pSerie', ptOutput).Size := 12;
    SpTrx.Params.CreateParam(ftString, 'pcont', ptOutput).Size := 20;
    SpTrx.Prepare;
    SpTrx.Execute;
    Result := SpTrx.ParamByName('pcont').AsString;
  finally
    FreeAndNil(SpTrx);
  end;
end;

procedure TdmTraspaso.InsertarMovimientoAlmacen(QryTrx: TUniQuery;
                          const ATipoDoc, ASerie, ANro, ALinea, AEmpresa,
                          AAlmacen, ACaja, AAlmacenContra, ATipoMov,
                          ASku: string; ACantidad: Double; ACoste: Currency;
                          const AUsuario: string; const AAlmacenDoc: string;
                          const ANumOperacion: string;
                          const ACodCliente: string;
                          const ACodArticulo: string);
var
  uspMov: TUniStoredProc;
begin
  uspMov := TUniStoredProc.Create(nil);
  try
    uspMov.Connection := QryTrx.Connection;
    uspMov.StoredProcName := 'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT';
    uspMov.Prepare;
    uspMov.ParamByName('p_NUMERO_MOV').AsString :=
      inLibtb.ObtenerSiguienteContador('MV');
    uspMov.ParamByName('p_TIPO_DOC_MOV').AsString := ATipoDoc;
    uspMov.ParamByName('p_SERIE_DOC_MOV').AsString := ASerie;
    uspMov.ParamByName('p_NRO_DOC_MOV').AsString := ANro;
    uspMov.ParamByName('p_LINEA_MOV').AsString := ALinea;
    uspMov.ParamByName('p_CODIGO_EMPRESA_MOV').AsString := AEmpresa;
    uspMov.ParamByName('p_CODIGO_ALMACEN_MOV').AsString := AAlmacen;
    uspMov.ParamByName('p_CODIGO_CAJA_DOC_MOV').AsString := ACaja;
    if Trim(AAlmacenContra) = '' then
      uspMov.ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').Clear
    else
      uspMov.ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').AsString :=
        AAlmacenContra;
    uspMov.ParamByName('p_CODIGO_UNIDAD_MOV').AsString := ASku;
    uspMov.ParamByName('p_TIPO_MOVIMIENTO_MOV').AsString := ATipoMov;
    uspMov.ParamByName('p_CANTIDAD_MOV').AsFloat := Abs(ACantidad);
    uspMov.ParamByName('p_PRECIO_MEDIO_MOV').AsCurrency := ACoste;
    uspMov.ParamByName('p_TOTAL_COSTE_MOV').AsCurrency := ACoste * Abs(ACantidad);
    uspMov.ParamByName('p_USUARIO').AsString := AUsuario;
    uspMov.ParamByName('p_ALMACEN_DOC').AsString := AAlmacenDoc;
    uspMov.ParamByName('p_NUMOP_DOC').AsString := ANumOperacion;
    uspMov.ParamByName('p_CODCLIENTE').AsString := ACodCliente;
    uspMov.ParamByName('p_CODARTICULO').AsString := ACodArticulo;
    uspMov.Execute;
  finally
    FreeAndNil(uspMov);
  end;
end;

procedure TdmTraspaso.InsertarOperacionCaja(QryTrx: TUniQuery;
                          const AEmpresa, AAlmacen, ACaja, ANumOperacion,
                          ATipoOp: string; AImporte: Currency;
                          const AEmpleado, AConcepto, ASerieOrigen,
                          ANroOrigen, AEmpresaContra, AAlmContra,
                          AEsTraspaso, ANroDoc, ASerieDoc: string);
begin
  QryTrx.SQL.Text :=
    'INSERT INTO fza_caja_operaciones (' +
    '  CODIGO_EMP_OPCAJA, CODIGO_ALM_OPCAJA, CODIGO_CAJA_OPCAJA,' +
    '  NUMERO_FAC_OPCAJA, SERIE_FAC_OPCAJA,' +
    '  NUMERO_OPERACION_OPCAJA, TIPO_OPERACION_OPCAJA, IMPORTE_TOTAL_OPCAJA,' +
    '  FECHA_OPERACION_OPCAJA, FECHA_OP_DIA_OPCAJA, CODIGO_EMPLEADO_OPCAJA,' +
    '  CONCEPTO_GASTO_INGRESO_OPCAJA, SERIE_REF_ORIGEN_OPCAJA,' +
    '  NUMERO_REF_ORIGEN_OPCAJA, CODIGO_EMP_CONTRA_OPCAJA,' +
    '  CODIGO_ALM_CONTRA_OPCAJA, ESTRASPASO_OPCAJA, ESTADO_DEVOLUCION_OPCAJA,' +
    '  USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA) ' +
    'VALUES (' +
    '  :EMP, :ALM, :CAJA,' +
    '  NULLIF(:NRODOC, ''''), NULLIF(:SERIEDOC, ''''),' +
    '  :NUMOP, :TIPOOP, :IMPORTE, NOW(), CURRENT_DATE,' +
    '  :EMPLEADO, NULLIF(:CONCEPTO, ''''), NULLIF(:SERIEORIG, ''''),' +
    '  NULLIF(:NROORIG, ''''), NULLIF(:EMPCONTRA, ''''),' +
    '  NULLIF(:ALMCONTRA, ''''), :ESTRASPASO, ''N'',' +
    '  :USUARIO, :USUARIO, NOW())';
  QryTrx.ParamByName('EMP').AsString := AEmpresa;
  QryTrx.ParamByName('ALM').AsString := AAlmacen;
  QryTrx.ParamByName('CAJA').AsString := ACaja;
  QryTrx.ParamByName('NUMOP').AsString := ANumOperacion;
  QryTrx.ParamByName('TIPOOP').AsString := ATipoOp;
  QryTrx.ParamByName('IMPORTE').AsCurrency := AImporte;
  QryTrx.ParamByName('EMPLEADO').AsString := AEmpleado;
  QryTrx.ParamByName('CONCEPTO').AsString := AConcepto;
  QryTrx.ParamByName('SERIEORIG').AsString := ASerieOrigen;
  QryTrx.ParamByName('NROORIG').AsString := ANroOrigen;
  QryTrx.ParamByName('EMPCONTRA').AsString := AEmpresaContra;
  QryTrx.ParamByName('ALMCONTRA').AsString := AAlmContra;
  QryTrx.ParamByName('ESTRASPASO').AsString := AEsTraspaso;
  QryTrx.ParamByName('NRODOC').AsString := ANroDoc;
  QryTrx.ParamByName('SERIEDOC').AsString := ASerieDoc;
  // Auditoría con el usuario logueado; el empleado responsable va en EMPLEADO.
  QryTrx.ParamByName('USUARIO').AsString := inLibGlobalVar.oUser;
  QryTrx.Execute;
end;

function TdmTraspaso.GrabarTraspaso(const AAlmacenDestino: string;
                                    out ANumOperacion: string;
                                    const ANumSolicitud: string;
                                    const ASerieSolicitud: string): Boolean;
var
  QryTrx: TUniQuery;
  sEmpresa, sAlmacenOrigen, sCaja, sUsuario, sEmpContra, sTipoDoc: string;
  sSku, sArticulo, sLinea, sSerieDoc, sNumeroDoc, sEmpleado: string;
  dCantidad: Double;
  cCoste, cTotal: Currency;
  iLinea: Integer;
begin
  Result := False;
  if cdsLineas.State in [dsEdit, dsInsert] then
    cdsLineas.Post;
  if cdsLineas.IsEmpty then
    raise Exception.Create('No hay líneas que traspasar.');
  if Trim(AAlmacenDestino) = '' then
    raise Exception.Create('Selecciona el almacén destino.');
  sEmpresa := cdsCabecera.FieldByName('CODIGO_EMP').AsString;
  sAlmacenOrigen := cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
  sCaja := cdsCabecera.FieldByName('CODIGO_CAJA').AsString;
  sUsuario := inLibGlobalVar.oUser;
  sEmpleado := cdsCabecera.FieldByName('CODIGO_EMPLEADO').AsString;
  if SameText(sAlmacenOrigen, AAlmacenDestino) then
    raise Exception.Create('Origen y destino no pueden ser el mismo almacén.');
  // TR = misma empresa (origen y destino); TA = entre empresas distintas.
  sEmpContra := ObtenerEmpresaAlmacen(AAlmacenDestino);
  if (sEmpContra = '') or SameText(sEmpContra, sEmpresa) then
    sTipoDoc := 'TR'
  else
    sTipoDoc := 'TA';
  // Serie del documento de traspaso (de fza_empresas_series, con fallback).
  sSerieDoc := ObtenerSerieDocumento(sEmpresa, sAlmacenOrigen, sCaja, sTipoDoc);
  QryTrx := TUniQuery.Create(nil);
  try
    QryTrx.Connection := oConn;
    ANumOperacion := SiguienteOpCaja(sEmpresa, sAlmacenOrigen, sCaja, sUsuario);
    // Número del documento dentro de la serie (mismo SP que la factura).
    sNumeroDoc := SiguienteNumeroDocumento(sSerieDoc, sTipoDoc, sEmpresa,
                                           sUsuario);
    oConn.StartTransaction;
    try
      cTotal := 0;
      iLinea := 0;
      cdsLineas.First;
      while not cdsLineas.Eof do
      begin
        iLinea := iLinea + 10;
        sLinea := Format('%.4d', [iLinea]);
        sSku := cdsLineas.FieldByName('CODIGO_UNIDAD').AsString;
        sArticulo := cdsLineas.FieldByName('CODIGO_ART').AsString;
        dCantidad := cdsLineas.FieldByName('CANTIDAD').AsFloat;
        cCoste := cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency;
        // Salida del origen hacia el destino.
        InsertarMovimientoAlmacen(QryTrx, sTipoDoc, sSerieDoc, sNumeroDoc,
          sLinea, sEmpresa, sAlmacenOrigen, sCaja, AAlmacenDestino, 'S', sSku,
          dCantidad, cCoste, sUsuario, sAlmacenOrigen, ANumOperacion, '',
          sArticulo);
        // Entrada en el destino desde el origen.
        InsertarMovimientoAlmacen(QryTrx, sTipoDoc, sSerieDoc, sNumeroDoc,
          sLinea, sEmpresa, AAlmacenDestino, sCaja, sAlmacenOrigen, 'E', sSku,
          dCantidad, cCoste, sUsuario, sAlmacenOrigen, ANumOperacion, '',
          sArticulo);
        cTotal := cTotal + cCoste * dCantidad;
        cdsLineas.Next;
      end;
      // Operación de caja del traspaso (cabecera del documento). Si atiende
      // una solicitud, se enlaza por SERIE/NUMERO_REF_ORIGEN.
      InsertarOperacionCaja(QryTrx, sEmpresa, sAlmacenOrigen, sCaja,
        ANumOperacion, sTipoDoc, cTotal, sEmpleado,
        'Traspaso a ' + AAlmacenDestino, ASerieSolicitud, ANumSolicitud,
        sEmpContra, AAlmacenDestino, 'S', sNumeroDoc, sSerieDoc);
      if Trim(ANumSolicitud) <> '' then
        MarcarSolicitudAtendida(QryTrx, ANumSolicitud, ASerieSolicitud);
      oConn.Commit;
      Result := True;
    except
      oConn.Rollback;
      raise;
    end;
  finally
    FreeAndNil(QryTrx);
  end;
end;

procedure TdmTraspaso.MarcarSolicitudAtendida(QryTrx: TUniQuery;
                          const ANumero, ASerie: string);
var
  sUsuario: string;
begin
  sUsuario := inLibGlobalVar.oUser;
  // Suma lo servido (cantidad de cada línea del ticket) por SKU.
  cdsLineas.First;
  while not cdsLineas.Eof do
  begin
    QryTrx.SQL.Text :=
      'UPDATE fza_traspasos_solicitudes_lineas' +
      '   SET CANTIDAD_SERVIDA_TRSOLLIN =' +
      '         CANTIDAD_SERVIDA_TRSOLLIN + :SERV,' +
      '       ESATENDIDA_TRSOLLIN =' +
      '         IF(CANTIDAD_SERVIDA_TRSOLLIN + :SERV >=' +
      '            CANTIDAD_PEDIDA_TRSOLLIN, ''S'', ''N''),' +
      '       USUARIO_MODIF = :USU' +
      ' WHERE NUMERO_TRSOL_TRSOLLIN = :NUM' +
      '   AND SERIE_TRSOL_TRSOLLIN = :SER' +
      '   AND CODIGO_UNIDAD_TRSOLLIN = :SKU';
    QryTrx.ParamByName('SERV').AsFloat :=
      cdsLineas.FieldByName('CANTIDAD').AsFloat;
    QryTrx.ParamByName('USU').AsString := sUsuario;
    QryTrx.ParamByName('NUM').AsString := ANumero;
    QryTrx.ParamByName('SER').AsString := ASerie;
    QryTrx.ParamByName('SKU').AsString :=
      cdsLineas.FieldByName('CODIGO_UNIDAD').AsString;
    QryTrx.Execute;
    cdsLineas.Next;
  end;
  // ATENDIDA si no queda ninguna línea pendiente; si no, PARCIAL.
  QryTrx.SQL.Text :=
    'UPDATE fza_traspasos_solicitudes' +
    '   SET ESTADO_TRSOL = IF((SELECT COUNT(*)' +
    '         FROM fza_traspasos_solicitudes_lineas L' +
    '        WHERE L.NUMERO_TRSOL_TRSOLLIN = :NUM' +
    '          AND L.SERIE_TRSOL_TRSOLLIN = :SER' +
    '          AND L.ESATENDIDA_TRSOLLIN = ''N'') = 0,' +
    '        ''ATENDIDA'', ''PARCIAL''),' +
    '       USUARIO_MODIF = :USU' +
    ' WHERE NUMERO_TRSOL = :NUM AND SERIE_TRSOL = :SER';
  QryTrx.ParamByName('NUM').AsString := ANumero;
  QryTrx.ParamByName('SER').AsString := ASerie;
  QryTrx.ParamByName('USU').AsString := sUsuario;
  QryTrx.Execute;
end;

function TdmTraspaso.GrabarSolicitud(const AAlmacenOrigen: string;
                                     out ANumero, ASerie: string): Boolean;
var
  QryTrx: TUniQuery;
  sEmpresa, sAlmacenPropio, sCaja, sUsuario, sEmpContra, sLinea,
  sEmpleado: string;
  iLinea: Integer;
begin
  Result := False;
  if cdsLineas.State in [dsEdit, dsInsert] then
    cdsLineas.Post;
  if cdsLineas.IsEmpty then
    raise Exception.Create('No hay líneas que solicitar.');
  if Trim(AAlmacenOrigen) = '' then
    raise Exception.Create('Selecciona el almacén al que solicitas.');
  sEmpresa := cdsCabecera.FieldByName('CODIGO_EMP').AsString;
  // En mtSolicitar el propio (CODIGO_ALM_ORIGEN) es el DESTINO de la petición.
  sAlmacenPropio := cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
  sCaja := cdsCabecera.FieldByName('CODIGO_CAJA').AsString;
  sUsuario := inLibGlobalVar.oUser;
  sEmpleado := cdsCabecera.FieldByName('CODIGO_EMPLEADO').AsString;
  if SameText(sAlmacenPropio, AAlmacenOrigen) then
    raise Exception.Create('No puedes solicitarte a ti mismo.');
  sEmpContra := ObtenerEmpresaAlmacen(AAlmacenOrigen);
  ANumero := inLibtb.ObtenerSiguienteContador('TS');
  ASerie := 'TS';
  QryTrx := TUniQuery.Create(nil);
  try
    QryTrx.Connection := oConn;
    oConn.StartTransaction;
    try
      QryTrx.SQL.Text :=
        'INSERT INTO fza_traspasos_solicitudes (' +
        '  NUMERO_TRSOL, SERIE_TRSOL, FECHA_TRSOL, ESTADO_TRSOL,' +
        '  CODIGO_EMP_TRSOL, CODIGO_ALM_ORIGEN_TRSOL,' +
        '  CODIGO_ALM_DESTINO_TRSOL, CODIGO_EMP_CONTRA_TRSOL,' +
        '  CODIGO_CAJA_TRSOL, CODIGO_EMPLEADO_TRSOL,' +
        '  USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA) ' +
        'VALUES (:NUM, :SER, CURRENT_DATE, ''PENDIENTE'', :EMP, :ORI, :DES,' +
        '  NULLIF(:EMPC, ''''), :CAJA, :EMPLE, :USU, :USU, NOW())';
      QryTrx.ParamByName('NUM').AsString := ANumero;
      QryTrx.ParamByName('SER').AsString := ASerie;
      QryTrx.ParamByName('EMP').AsString := sEmpresa;
      QryTrx.ParamByName('ORI').AsString := AAlmacenOrigen;
      QryTrx.ParamByName('DES').AsString := sAlmacenPropio;
      QryTrx.ParamByName('EMPC').AsString := sEmpContra;
      QryTrx.ParamByName('CAJA').AsString := sCaja;
      QryTrx.ParamByName('EMPLE').AsString := sEmpleado;
      QryTrx.ParamByName('USU').AsString := sUsuario;
      QryTrx.Execute;
      iLinea := 0;
      cdsLineas.First;
      while not cdsLineas.Eof do
      begin
        iLinea := iLinea + 10;
        sLinea := Format('%.4d', [iLinea]);
        QryTrx.SQL.Text :=
          'INSERT INTO fza_traspasos_solicitudes_lineas (' +
          '  NUMERO_TRSOL_TRSOLLIN, SERIE_TRSOL_TRSOLLIN, LINEA_TRSOLLIN,' +
          '  CODIGO_ART_TRSOLLIN, CODIGO_UNIDAD_TRSOLLIN,' +
          '  DESCRIPCION_ARTICULO_TRSOLLIN, CANTIDAD_PEDIDA_TRSOLLIN,' +
          '  CANTIDAD_SERVIDA_TRSOLLIN, ESATENDIDA_TRSOLLIN,' +
          '  USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA) ' +
          'VALUES (:NUM, :SER, :LIN, :ART, :SKU, :DESC, :CANT, 0, ''N'',' +
          '  :USU, :USU, NOW())';
        QryTrx.ParamByName('NUM').AsString := ANumero;
        QryTrx.ParamByName('SER').AsString := ASerie;
        QryTrx.ParamByName('LIN').AsString := sLinea;
        QryTrx.ParamByName('ART').AsString :=
          cdsLineas.FieldByName('CODIGO_ART').AsString;
        QryTrx.ParamByName('SKU').AsString :=
          cdsLineas.FieldByName('CODIGO_UNIDAD').AsString;
        QryTrx.ParamByName('DESC').AsString :=
          cdsLineas.FieldByName('DESCRIPCION').AsString;
        QryTrx.ParamByName('CANT').AsFloat :=
          cdsLineas.FieldByName('CANTIDAD').AsFloat;
        QryTrx.ParamByName('USU').AsString := sUsuario;
        QryTrx.Execute;
        cdsLineas.Next;
      end;
      oConn.Commit;
      Result := True;
    except
      oConn.Rollback;
      raise;
    end;
  finally
    FreeAndNil(QryTrx);
  end;
end;

procedure TdmTraspaso.CargarSolicitudesPendientes(AItems, ACodigos: TStrings);
var
  sPropio: string;
begin
  AItems.Clear;
  ACodigos.Clear;
  sPropio := cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
  qryAux.SQL.Text :=
    'SELECT S.NUMERO_TRSOL, S.SERIE_TRSOL, S.ESTADO_TRSOL,' +
    '       S.CODIGO_ALM_DESTINO_TRSOL,' +
    '       (SELECT COUNT(*) FROM fza_traspasos_solicitudes_lineas L' +
    '         WHERE L.NUMERO_TRSOL_TRSOLLIN = S.NUMERO_TRSOL' +
    '           AND L.SERIE_TRSOL_TRSOLLIN = S.SERIE_TRSOL' +
    '           AND L.ESATENDIDA_TRSOLLIN = ''N'') AS NLIN' +
    '  FROM fza_traspasos_solicitudes S' +
    ' WHERE S.CODIGO_ALM_ORIGEN_TRSOL = :PROPIO' +
    '   AND S.ESTADO_TRSOL IN (''PENDIENTE'', ''PARCIAL'')' +
    ' ORDER BY S.FECHA_TRSOL, S.NUMERO_TRSOL';
  qryAux.ParamByName('PROPIO').AsString := sPropio;
  qryAux.Open;
  try
    while not qryAux.Eof do
    begin
      AItems.Add(Format('%s/%s  ->  %s  ·  %d líneas  ·  %s',
        [qryAux.FieldByName('SERIE_TRSOL').AsString,
         qryAux.FieldByName('NUMERO_TRSOL').AsString,
         qryAux.FieldByName('CODIGO_ALM_DESTINO_TRSOL').AsString,
         qryAux.FieldByName('NLIN').AsInteger,
         qryAux.FieldByName('ESTADO_TRSOL').AsString]));
      ACodigos.Add(qryAux.FieldByName('NUMERO_TRSOL').AsString + '|' +
                   qryAux.FieldByName('SERIE_TRSOL').AsString);
      qryAux.Next;
    end;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.CargarSolicitud(const ANumero, ASerie: string): Boolean;
var
  bExiste: Boolean;
  sPropio, sSolicitante: string;
begin
  bExiste := False;
  sPropio := '';
  sSolicitante := '';
  qryAux.SQL.Text :=
    'SELECT CODIGO_ALM_ORIGEN_TRSOL, CODIGO_ALM_DESTINO_TRSOL' +
    '  FROM fza_traspasos_solicitudes' +
    ' WHERE NUMERO_TRSOL = :NUM AND SERIE_TRSOL = :SER';
  qryAux.ParamByName('NUM').AsString := ANumero;
  qryAux.ParamByName('SER').AsString := ASerie;
  qryAux.Open;
  try
    bExiste := not qryAux.IsEmpty;
    if bExiste then
    begin
      sPropio := qryAux.FieldByName('CODIGO_ALM_ORIGEN_TRSOL').AsString;
      sSolicitante := qryAux.FieldByName('CODIGO_ALM_DESTINO_TRSOL').AsString;
    end;
  finally
    qryAux.Close;
  end;
  Result := bExiste;
  if bExiste then
  begin
    ConfigurarEstructuraLineas;
    if cdsCabecera.State = dsBrowse then
      cdsCabecera.Edit;
    cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString := sPropio;
    cdsCabecera.FieldByName('CODIGO_ALM_DESTINO').AsString := sSolicitante;
    cdsCabecera.FieldByName('NUMERO_SOL').AsString := ANumero;
    cdsCabecera.FieldByName('SERIE_SOL').AsString := ASerie;
    cdsCabecera.Post;
    // Pase 1: volcar SKU/uds pendientes (qryAux ocupado, sin coste todavía).
    qryAux.SQL.Text :=
      'SELECT CODIGO_ART_TRSOLLIN, CODIGO_UNIDAD_TRSOLLIN,' +
      '       DESCRIPCION_ARTICULO_TRSOLLIN,' +
      '       (CANTIDAD_PEDIDA_TRSOLLIN -' +
      '        CANTIDAD_SERVIDA_TRSOLLIN) AS PENDIENTE' +
      '  FROM fza_traspasos_solicitudes_lineas' +
      ' WHERE NUMERO_TRSOL_TRSOLLIN = :NUM' +
      '   AND SERIE_TRSOL_TRSOLLIN = :SER' +
      '   AND (CANTIDAD_PEDIDA_TRSOLLIN -' +
      '        CANTIDAD_SERVIDA_TRSOLLIN) > 0' +
      ' ORDER BY LINEA_TRSOLLIN';
    qryAux.ParamByName('NUM').AsString := ANumero;
    qryAux.ParamByName('SER').AsString := ASerie;
    qryAux.Open;
    try
      while not qryAux.Eof do
      begin
        cdsLineas.Append;
        cdsLineas.FieldByName('CODIGO_ART').AsString :=
          qryAux.FieldByName('CODIGO_ART_TRSOLLIN').AsString;
        cdsLineas.FieldByName('CODIGO_UNIDAD').AsString :=
          qryAux.FieldByName('CODIGO_UNIDAD_TRSOLLIN').AsString;
        cdsLineas.FieldByName('DESCRIPCION').AsString :=
          qryAux.FieldByName('DESCRIPCION_ARTICULO_TRSOLLIN').AsString;
        cdsLineas.FieldByName('CANTIDAD').AsFloat :=
          qryAux.FieldByName('PENDIENTE').AsFloat;
        cdsLineas.Post;
        qryAux.Next;
      end;
    finally
      qryAux.Close;
    end;
    // Pase 2: rellenar coste y stock del almacén que sirve (el propio).
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      cdsLineas.Edit;
      cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency :=
        ObtenerCosteMedio(cdsLineas.FieldByName('CODIGO_UNIDAD').AsString,
                          sPropio);
      cdsLineas.FieldByName('STOCK_ORIGEN').AsFloat :=
        ObtenerStock(cdsLineas.FieldByName('CODIGO_UNIDAD').AsString, sPropio);
      cdsLineas.FieldByName('TOTAL').AsCurrency :=
        cdsLineas.FieldByName('CANTIDAD').AsFloat *
        cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency;
      cdsLineas.Post;
      cdsLineas.Next;
    end;
  end;
end;

end.
