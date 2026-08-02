{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataCargaMasivaArticulosRepositorio                       }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       FactuZam                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Consultas y transacciones de la carga masiva de articulos.                }
{******************************************************************************}
unit UniDataCargaMasivaArticulosRepositorio;

interface

uses
  Uni, inLibCargaMasivaArticulosPersistenciaIntf;

function CrearServicioCargaMasivaArticulosUniDAC(
  AConexion: TUniConnection): TServiciosCargaMasivaArticulos;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Math,
  Data.DB;

const
  SQL_FAMILIAS =
    'SELECT CODIGO_FAM_FAM, ' +
    'COALESCE(CODIGO_SUBFAMILIA_FAM, '''') AS CODIGO_PADRE, ' +
    'NOMBRE_FAM_FAM, DESCRIPCION_FAM FROM fza_articulos_familias ' +
    'WHERE ESACTIVO_FAM = ''S'' ORDER BY ' +
    'COALESCE(CODIGO_SUBFAMILIA_FAM, ''''), ORDEN_FAM, NOMBRE_FAM_FAM';
  SQL_PROVEEDORES =
    'SELECT CODIGO_PRV_PRV, RAZON_SOCIAL_PRV, NIF_PRV ' +
    'FROM fza_proveedores WHERE ESACTIVO_PRV = ''S'' ' +
    'ORDER BY RAZON_SOCIAL_PRV';
  SQL_PROPIEDADES =
    'SELECT CODIGO_PROP_ARTPROP, NOMBRE_PROP_PROP FROM fza_propiedades ' +
    'WHERE ESACTIVO_PROP = ''S'' AND TIPO_VALOR_PROP = ''LISTA'' ' +
    'ORDER BY NOMBRE_PROP_PROP';
  SQL_VALORES_PROPIEDAD_TODOS =
    'SELECT v.ID_PV_ARTPROP, v.ID_PROP_PV, p.NOMBRE_PROP_PROP, v.PV ' +
    'FROM fza_propiedades_valores v JOIN fza_propiedades p ' +
    'ON p.CODIGO_PROP_ARTPROP = v.ID_PROP_PV ' +
    'WHERE v.ESACTIVO_PV = ''S'' AND p.TIPO_VALOR_PROP = ''LISTA'' ' +
    'ORDER BY p.NOMBRE_PROP_PROP, v.PV';
  SQL_VALORES_PROPIEDAD =
    'SELECT v.ID_PV_ARTPROP, v.ID_PROP_PV, p.NOMBRE_PROP_PROP, v.PV ' +
    'FROM fza_propiedades_valores v JOIN fza_propiedades p ' +
    'ON p.CODIGO_PROP_ARTPROP = v.ID_PROP_PV ' +
    'WHERE v.ESACTIVO_PV = ''S'' AND v.ID_PROP_PV = :PROP ORDER BY v.PV';
  SQL_ALMACENES =
    'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM FROM fza_almacenes ' +
    'WHERE ESACTIVO_ALM = ''S'' AND (TIPO_USO_ALM IN ' +
    '(''ESTANDAR'', ''ESTANDARD'', ''DEPOSITO'') OR TIPO_USO_ALM IS NULL) ' +
    'ORDER BY ORDEN_ALM, NOMBRE_ALM_ALM';
  SQL_TARIFAS =
    'SELECT CODIGO_TAR_ARTTAR, NOMBRE_TAR_TAR FROM fza_tarifas ' +
    'WHERE ESACTIVO_ARTTAR = ''S'' ORDER BY ORDEN_TAR, CODIGO_TAR_ARTTAR';
  SQL_INSERTAR_TARIFA =
    'INSERT INTO fza_articulos_tarifas (' +
    'CODIGO_ART_ARTTAR, CODIGO_UNIDAD_ARTTAR, CODIGO_TAR_ARTTAR, ' +
    'ESACTIVO_ARTTAR, PRECIO_SALIDA_ARTTAR, PRECIO_FINAL_ARTTAR, ' +
    'PRECIO_DTO_ARTTAR, PORCENTAJE_DTO_ARTTAR, FECHA_DESDE_ARTTAR, ' +
    'FECHA_HASTA_ARTTAR, USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA) ' +
    'VALUES (:ART, '''', :TARIFA, ''S'', :SALIDA, :FINAL, :DTO, :PDTO, ' +
    ':DESDE, :HASTA, :USR, :USR2, NOW())';
  SQL_PROXIMA_LINEA_INVENTARIO =
    'SELECT COALESCE(MAX(CAST(LINEA_INVLIN AS UNSIGNED)), 0) + 1 AS PROX ' +
    'FROM fza_inventarios_lineas WHERE CODIGO_EMP_INVLIN = :EMP ' +
    'AND CODIGO_ALM_INVLIN = :ALM AND SERIE_INV_INVLIN = :SER ' +
    'AND NUMERO_INV_INVLIN = :NRO';
  SQL_SKUS_ARTICULO =
    'SELECT sk.CODIGO_UNIDAD_SKU AS SKU, a.DESCRIPCION_ART AS DESC_ART ' +
    'FROM fza_articulos_skus sk JOIN fza_articulos a ' +
    'ON a.CODIGO_ART_ART = sk.CODIGO_ART_SKU ' +
    'WHERE sk.CODIGO_ART_SKU = :ART UNION ' +
    'SELECT a.CODIGO_ART_ART AS SKU, a.DESCRIPCION_ART AS DESC_ART ' +
    'FROM fza_articulos a WHERE a.CODIGO_ART_ART = :ART2 ' +
    'AND NOT EXISTS (SELECT 1 FROM fza_articulos_skus sk2 ' +
    'WHERE sk2.CODIGO_ART_SKU = a.CODIGO_ART_ART) ORDER BY SKU';
  SQL_INSERTAR_LINEA_INVENTARIO =
    'INSERT INTO fza_inventarios_lineas (' +
    'CODIGO_EMP_INVLIN, CODIGO_ALM_INVLIN, SERIE_INV_INVLIN, ' +
    'NUMERO_INV_INVLIN, LINEA_INVLIN, CODIGO_ART_INVLIN, ' +
    'CODIGO_UNIDAD_INVLIN, DESCRIPCION_ARTICULO_INVLIN, ' +
    'CANTIDAD_TEORICA_INVLIN, CANTIDAD_FISICA_INVLIN, ' +
    'CANTIDAD_DIFERENCIA_INVLIN, PRECIO_MEDIO_INVLIN, ' +
    'PRECIO_MEDIO_NUEVO_INVLIN, USUARIO_ALTA, USUARIO_MODIF, ' +
    'INSTANTE_ALTA) VALUES (:EMP, :ALM, :SER, :NRO, :LINEA, :ART, ' +
    ':SKU, :DESCRIPCION, 0, 0, 0, 0, 0, :USR, :USR2, NOW())';
  SQL_PROXIMA_LINEA_DOCUMENTO =
    'SELECT COALESCE(MAX(CAST(LINEA_DTL AS UNSIGNED)), 0) + 1 AS PROX ' +
    'FROM fza_documentos_trabajo_lineas WHERE ID_DTR_DTL = :ID_DTR';
  SQL_SKUS_DOCUMENTO =
    'SELECT s.CODIGO_ALM_STK AS ALM, s.CODIGO_UNIDAD_STK AS SKU, ' +
    's.LOTE_STK, s.FECHA_CADUCIDAD_STK, s.CANTIDAD_STK, ' +
    'a.DESCRIPCION_ART AS DESC_ART, COALESCE((SELECT GROUP_CONCAT(' +
    'av.AV ORDER BY av.ORDEN_AV SEPARATOR '' / '') ' +
    'FROM fza_atributos_sku sa JOIN fza_atributos_valores av ' +
    'ON av.ID_AV = sa.ID_AV_SA WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
    's.CODIGO_UNIDAD_STK), '''') AS DESC_SKU ' +
    'FROM fza_articulos_stockactual s LEFT JOIN fza_articulos_skus sk ' +
    'ON sk.CODIGO_UNIDAD_SKU = s.CODIGO_UNIDAD_STK JOIN fza_articulos a ' +
    'ON a.CODIGO_ART_ART = COALESCE(sk.CODIGO_ART_SKU, ' +
    's.CODIGO_UNIDAD_STK) WHERE COALESCE(sk.CODIGO_ART_SKU, ' +
    's.CODIGO_UNIDAD_STK) = :ART AND s.CANTIDAD_STK > 0';
  SQL_INSERTAR_LINEA_DOCUMENTO =
    'INSERT INTO fza_documentos_trabajo_lineas (' +
    'ID_DTR_DTL, LINEA_DTL, CODIGO_ART_DTL, CODIGO_UNIDAD_DTL, ' +
    'CODIGO_ALM_DTL, LOTE_DTL, FECHA_CADUCIDAD_DTL, ' +
    'DESCRIPCION_ARTICULO_DTL, DESCRIPCION_UNIDAD_DTL, ' +
    'CANTIDAD_STOCK_DTL, CANTIDAD_DTL, INSTANTE_STOCK_DTL, ' +
    'ORIGEN_DTL, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:ID_DTR, :LINEA, :ART, :SKU, :ALM, :LOTE, :CADUCIDAD, ' +
    ':DESC_ART, :DESC_SKU, :CANTIDAD_STOCK, :CANTIDAD, NOW(), ' +
    ':ORIGEN, NOW(), :USR, :USR2)';
  SQL_INSERTAR_SESION_TARIFA =
    'INSERT INTO fza_tarifas_cambios_lineas (' +
    'CODIGO_TARC_TARCLIN, CODIGO_ART_TARCLIN, ' +
    'CODIGO_UNIDAD_SKU_TARCLIN, CODIGO_TAR_ORIGEN_TARCLIN, ' +
    'CODIGO_TAR_DESTINO_TARCLIN, PRECIO_ORIGEN_TARCLIN, ' +
    'PRECIO_COSTE_TARCLIN, PRECIO_SALIDA_ACTUAL_TARCLIN, ' +
    'PRECIO_FINAL_ACTUAL_TARCLIN, PRECIO_DTO_ACTUAL_TARCLIN, ' +
    'PORCENTAJE_DTO_ACTUAL_TARCLIN, PRECIO_NUEVO_TARCLIN, ' +
    'PRECIO_FINAL_NUEVO_TARCLIN, PRECIO_DTO_NUEVO_TARCLIN, ' +
    'PORCENTAJE_DTO_NUEVO_TARCLIN, ESAPLICAR_TARCLIN, ESTADO_TARCLIN, ' +
    'USUARIO_ALTA, USUARIO_MODIF) VALUES (:TARC, :ART, '''', :TAR_ORIG, ' +
    ':TAR_DEST, :P_ORIG, :P_COSTE, :P_SAL_ACT, :P_FIN_ACT, :P_DTO_ACT, ' +
    ':P_PDTO_ACT, :P_NUEVO, :P_FIN_NUEVO, 0, 0, ''S'', ''PENDIENTE'', ' +
    ':USUARIO, :USUARIO) ON DUPLICATE KEY UPDATE ' +
    'PRECIO_ORIGEN_TARCLIN = VALUES(PRECIO_ORIGEN_TARCLIN), ' +
    'PRECIO_COSTE_TARCLIN = VALUES(PRECIO_COSTE_TARCLIN), ' +
    'PRECIO_SALIDA_ACTUAL_TARCLIN = VALUES(PRECIO_SALIDA_ACTUAL_TARCLIN), ' +
    'PRECIO_FINAL_ACTUAL_TARCLIN = VALUES(PRECIO_FINAL_ACTUAL_TARCLIN), ' +
    'PRECIO_DTO_ACTUAL_TARCLIN = VALUES(PRECIO_DTO_ACTUAL_TARCLIN), ' +
    'PORCENTAJE_DTO_ACTUAL_TARCLIN = ' +
    'VALUES(PORCENTAJE_DTO_ACTUAL_TARCLIN), ' +
    'USUARIO_MODIF = VALUES(USUARIO_MODIF), INSTANTE_MODIF = NOW()';

type
  TConsultaCargaMasivaArticulosUniDAC = class(
    TInterfacedObject,
    IConsultaCargaMasivaArticulos)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConsulta: TUniQuery);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TServicioCargaMasivaArticulosUniDAC = class(
    TInterfacedObject,
    IConsultasCargaMasivaArticulos,
    IInsercionesCargaMasivaArticulos)
  private
    FConexion: TUniConnection;
    function CrearConsulta(const ASql: string): TUniQuery;
    function EnvolverConsulta(AConsulta: TUniQuery):
      IConsultaCargaMasivaArticulos;
    function StrArrToCsvSql(const AValores: TArray<string>): string;
    function IntArrToCsvSql(const AValores: TArray<Integer>): string;
    function ColumnasExtra(
      const AContexto: TContextoCargaMasivaArticulos): string;
    function ExpresionYaCargado(
      const AContexto: TContextoCargaMasivaArticulos): string;
    function CondicionExcluirCargados(
      const AContexto: TContextoCargaMasivaArticulos): string;
    function ConstruirSqlPreview(
      const AFiltros: TFiltrosCargaMasivaArticulos;
      const AContexto: TContextoCargaMasivaArticulos): string;
    procedure VincularParametrosPreview(
      AConsulta: TUniQuery;
      const AFiltros: TFiltrosCargaMasivaArticulos;
      const AContexto: TContextoCargaMasivaArticulos);
    function AjustarPrecio(
      APrecio: Double;
      const AParametros: TParametrosInsercionTarifa): Double;
    procedure CalcularPreciosTarifa(
      APrecioSalidaOrigen: Double;
      APrecioFinalOrigen: Double;
      const AParametros: TParametrosInsercionTarifa;
      out APrecioSalida: Double;
      out APrecioFinal: Double;
      out APorcentajeDescuento: Double);
    function ProximaLineaInventario(
      const AParametros: TParametrosInsercionInventario): Integer;
    procedure InsertarSkusInventario(
      AInsercion: TUniQuery;
      const ACodigoArticulo: string;
      const AParametros: TParametrosInsercionInventario;
      var ALineaActual: Integer;
      var ANumeroLineas: Integer);
    function ProximaLineaDocumento(AIdDocumento: Int64): Integer;
    procedure InsertarSkusDocumento(
      AInsercion: TUniQuery;
      const ACodigoArticulo: string;
      const AParametros: TParametrosInsercionDocumentoTrabajo;
      var ALineaActual: Integer;
      var ANumeroLineas: Integer);
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarFamilias: IConsultaCargaMasivaArticulos;
    function ConsultarProveedores: IConsultaCargaMasivaArticulos;
    function ConsultarValoresPropiedad(
      const ACodigoPropiedad: string): IConsultaCargaMasivaArticulos;
    function ListarPropiedades: TPropiedadesCargaMasiva;
    function ListarAlmacenes: TAlmacenesCargaMasiva;
    function ListarTarifas: TTarifasCargaMasiva;
    function Previsualizar(
      const AFiltros: TFiltrosCargaMasivaArticulos;
      const AContexto: TContextoCargaMasivaArticulos
    ): IConsultaCargaMasivaArticulos;
    function InsertarTarifa(
      const AConsulta: IConsultaCargaMasivaArticulos;
      const AParametros: TParametrosInsercionTarifa
    ): TResultadoInsercionCargaMasiva;
    function InsertarInventario(
      const AConsulta: IConsultaCargaMasivaArticulos;
      const AParametros: TParametrosInsercionInventario
    ): TResultadoInsercionCargaMasiva;
    function InsertarDocumentoTrabajo(
      const AConsulta: IConsultaCargaMasivaArticulos;
      const AParametros: TParametrosInsercionDocumentoTrabajo
    ): TResultadoInsercionCargaMasiva;
    function InsertarSesionTarifa(
      const AConsulta: IConsultaCargaMasivaArticulos;
      const AParametros: TParametrosInsercionSesionTarifa
    ): TResultadoInsercionCargaMasiva;
  end;

constructor TConsultaCargaMasivaArticulosUniDAC.Create(AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

destructor TConsultaCargaMasivaArticulosUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TConsultaCargaMasivaArticulosUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

constructor TServicioCargaMasivaArticulosUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TServicioCargaMasivaArticulosUniDAC.CrearConsulta(
  const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
end;

function TServicioCargaMasivaArticulosUniDAC.EnvolverConsulta(
  AConsulta: TUniQuery): IConsultaCargaMasivaArticulos;
begin
  Result := TConsultaCargaMasivaArticulosUniDAC.Create(AConsulta);
end;

function TServicioCargaMasivaArticulosUniDAC.ConsultarFamilias:
  IConsultaCargaMasivaArticulos;
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta(SQL_FAMILIAS);
  try
    oConsulta.Open;
    Result := EnvolverConsulta(oConsulta);
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ConsultarProveedores:
  IConsultaCargaMasivaArticulos;
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta(SQL_PROVEEDORES);
  try
    oConsulta.Open;
    Result := EnvolverConsulta(oConsulta);
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ConsultarValoresPropiedad(
  const ACodigoPropiedad: string): IConsultaCargaMasivaArticulos;
var
  oConsulta: TUniQuery;
begin
  if ACodigoPropiedad = '' then
  begin
    oConsulta := CrearConsulta(SQL_VALORES_PROPIEDAD_TODOS);
  end
  else
  begin
    oConsulta := CrearConsulta(SQL_VALORES_PROPIEDAD);
    oConsulta.ParamByName('PROP').AsString := ACodigoPropiedad;
  end;
  try
    oConsulta.Open;
    Result := EnvolverConsulta(oConsulta);
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ListarPropiedades:
  TPropiedadesCargaMasiva;
var
  iPosicion: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := CrearConsulta(SQL_PROPIEDADES);
  try
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iPosicion := Length(Result);
      SetLength(Result, iPosicion + 1);
      Result[iPosicion].Codigo :=
        oConsulta.FieldByName('CODIGO_PROP_ARTPROP').AsString;
      Result[iPosicion].Nombre :=
        oConsulta.FieldByName('NOMBRE_PROP_PROP').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ListarAlmacenes:
  TAlmacenesCargaMasiva;
var
  iPosicion: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := CrearConsulta(SQL_ALMACENES);
  try
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iPosicion := Length(Result);
      SetLength(Result, iPosicion + 1);
      Result[iPosicion].Codigo :=
        oConsulta.FieldByName('CODIGO_ALM_ALM').AsString;
      Result[iPosicion].Nombre :=
        oConsulta.FieldByName('NOMBRE_ALM_ALM').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ListarTarifas:
  TTarifasCargaMasiva;
var
  iPosicion: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := CrearConsulta(SQL_TARIFAS);
  try
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iPosicion := Length(Result);
      SetLength(Result, iPosicion + 1);
      Result[iPosicion].Codigo :=
        oConsulta.FieldByName('CODIGO_TAR_ARTTAR').AsString;
      Result[iPosicion].Nombre :=
        oConsulta.FieldByName('NOMBRE_TAR_TAR').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.StrArrToCsvSql(
  const AValores: TArray<string>): string;
var
  iPosicion: Integer;
begin
  Result := '';
  for iPosicion := 0 to High(AValores) do
  begin
    if Result <> '' then
    begin
      Result := Result + ',';
    end;
    Result := Result + QuotedStr(AValores[iPosicion]);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.IntArrToCsvSql(
  const AValores: TArray<Integer>): string;
var
  iPosicion: Integer;
begin
  Result := '';
  for iPosicion := 0 to High(AValores) do
  begin
    if Result <> '' then
    begin
      Result := Result + ',';
    end;
    Result := Result + IntToStr(AValores[iPosicion]);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ColumnasExtra(
  const AContexto: TContextoCargaMasivaArticulos): string;
begin
  case AContexto.Modo of
    mcTarifa:
      begin
        if AContexto.CodigoTarifaOrigen <> '' then
        begin
          Result :=
            '(SELECT t.PRECIO_SALIDA_ARTTAR FROM fza_articulos_tarifas t ' +
            'WHERE t.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
            'AND t.CODIGO_TAR_ARTTAR = :P_TARIFA_ORIG_S ' +
            'AND t.ESACTIVO_ARTTAR = ''S'' ' +
            'ORDER BY t.FECHA_DESDE_ARTTAR DESC LIMIT 1) ' +
            'AS PRECIO_SALIDA_ORIG, ' +
            '(SELECT t.PRECIO_FINAL_ARTTAR FROM fza_articulos_tarifas t ' +
            'WHERE t.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
            'AND t.CODIGO_TAR_ARTTAR = :P_TARIFA_ORIG_F ' +
            'AND t.ESACTIVO_ARTTAR = ''S'' ' +
            'ORDER BY t.FECHA_DESDE_ARTTAR DESC LIMIT 1) ' +
            'AS PRECIO_FINAL_ORIG,';
        end
        else
        begin
          Result := '0 AS PRECIO_SALIDA_ORIG, 0 AS PRECIO_FINAL_ORIG,';
        end;
      end;
    mcInventario:
      begin
        Result :=
          '(SELECT COUNT(DISTINCT s.CODIGO_UNIDAD_STK) ' +
          'FROM fza_articulos_stockactual s LEFT JOIN fza_articulos_skus sk ' +
          'ON sk.CODIGO_UNIDAD_SKU = s.CODIGO_UNIDAD_STK ' +
          'WHERE COALESCE(sk.CODIGO_ART_SKU, s.CODIGO_UNIDAD_STK) = ' +
          'a.CODIGO_ART_ART AND s.CODIGO_ALM_STK = :P_INV_ALMACEN ' +
          'AND s.CANTIDAD_STK > 0) AS NUM_SKUS_CON_STOCK, ' +
          '(SELECT AVG(s.PRECIO_MEDIO_STK) ' +
          'FROM fza_articulos_stockactual s LEFT JOIN fza_articulos_skus sk ' +
          'ON sk.CODIGO_UNIDAD_SKU = s.CODIGO_UNIDAD_STK ' +
          'WHERE COALESCE(sk.CODIGO_ART_SKU, s.CODIGO_UNIDAD_STK) = ' +
          'a.CODIGO_ART_ART AND s.CODIGO_ALM_STK = :P_INV_ALMACEN_PMP ' +
          'AND s.PRECIO_MEDIO_STK > 0) AS PMP_ACTUAL,';
      end;
    mcSesionTarifa:
      begin
        Result :=
          '(SELECT TOG.PRECIO_SALIDA_ARTTAR FROM fza_articulos_tarifas TOG ' +
          'WHERE TOG.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
          'AND COALESCE(TOG.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
          'AND TOG.CODIGO_TAR_ARTTAR = :P_TAR_ORIG ' +
          'AND TOG.ESACTIVO_ARTTAR = ''S'' ' +
          'ORDER BY TOG.FECHA_DESDE_ARTTAR DESC, ' +
          'TOG.CODIGO_UNICO_ARTTAR DESC LIMIT 1) AS PRECIO_ORIGEN, ' +
          '(SELECT TDE.PRECIO_SALIDA_ARTTAR FROM fza_articulos_tarifas TDE ' +
          'WHERE TDE.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
          'AND COALESCE(TDE.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
          'AND TDE.CODIGO_TAR_ARTTAR = :P_TAR_DEST_SAL ' +
          'AND TDE.ESACTIVO_ARTTAR = ''S'' ' +
          'ORDER BY TDE.FECHA_DESDE_ARTTAR DESC, ' +
          'TDE.CODIGO_UNICO_ARTTAR DESC LIMIT 1) AS PRECIO_SALIDA_ACT, ' +
          '(SELECT TDF.PRECIO_FINAL_ARTTAR FROM fza_articulos_tarifas TDF ' +
          'WHERE TDF.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
          'AND COALESCE(TDF.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
          'AND TDF.CODIGO_TAR_ARTTAR = :P_TAR_DEST_FIN ' +
          'AND TDF.ESACTIVO_ARTTAR = ''S'' ' +
          'ORDER BY TDF.FECHA_DESDE_ARTTAR DESC, ' +
          'TDF.CODIGO_UNICO_ARTTAR DESC LIMIT 1) AS PRECIO_FINAL_ACT, ' +
          '(SELECT TDD.PRECIO_DTO_ARTTAR FROM fza_articulos_tarifas TDD ' +
          'WHERE TDD.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
          'AND COALESCE(TDD.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
          'AND TDD.CODIGO_TAR_ARTTAR = :P_TAR_DEST_DTO ' +
          'AND TDD.ESACTIVO_ARTTAR = ''S'' ' +
          'ORDER BY TDD.FECHA_DESDE_ARTTAR DESC, ' +
          'TDD.CODIGO_UNICO_ARTTAR DESC LIMIT 1) AS PRECIO_DTO_ACT, ' +
          '(SELECT TDP.PORCENTAJE_DTO_ARTTAR ' +
          'FROM fza_articulos_tarifas TDP ' +
          'WHERE TDP.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
          'AND COALESCE(TDP.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
          'AND TDP.CODIGO_TAR_ARTTAR = :P_TAR_DEST_PDTO ' +
          'AND TDP.ESACTIVO_ARTTAR = ''S'' ' +
          'ORDER BY TDP.FECHA_DESDE_ARTTAR DESC, ' +
          'TDP.CODIGO_UNICO_ARTTAR DESC LIMIT 1) AS PORC_DTO_ACT, ' +
          '(SELECT AP.PRECIO_ULT_COMPRA_AP ' +
          'FROM fza_articulos_proveedores AP ' +
          'WHERE AP.CODIGO_ART_AP = a.CODIGO_ART_ART ' +
          'AND AP.ESPROVEEDORPRINCIPAL_AP = ''S'' LIMIT 1) AS PRECIO_COSTE,';
      end;
  else
    Result := '';
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ExpresionYaCargado(
  const AContexto: TContextoCargaMasivaArticulos): string;
begin
  case AContexto.Modo of
    mcTarifa:
      Result :=
        'CASE WHEN EXISTS (SELECT 1 FROM fza_articulos_tarifas ta ' +
        'WHERE ta.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
        'AND ta.CODIGO_TAR_ARTTAR = :P_TARIFA_CHK) ' +
        'THEN ''S'' ELSE ''N'' END';
    mcInventario:
      Result :=
        'CASE WHEN EXISTS (SELECT 1 FROM fza_inventarios_lineas il ' +
        'WHERE il.CODIGO_EMP_INVLIN = :P_INV_EMP_C ' +
        'AND il.CODIGO_ALM_INVLIN = :P_INV_ALM_C ' +
        'AND il.SERIE_INV_INVLIN = :P_INV_SER_C ' +
        'AND il.NUMERO_INV_INVLIN = :P_INV_NRO_C ' +
        'AND il.CODIGO_ART_INVLIN = a.CODIGO_ART_ART) ' +
        'THEN ''S'' ELSE ''N'' END';
    mcDocumentoTrabajo:
      Result :=
        'CASE WHEN EXISTS (SELECT 1 FROM fza_documentos_trabajo_lineas dl ' +
        'WHERE dl.ID_DTR_DTL = :P_DTR_CHK ' +
        'AND dl.CODIGO_ART_DTL = a.CODIGO_ART_ART) ' +
        'THEN ''S'' ELSE ''N'' END';
  else
    Result :=
      'CASE WHEN EXISTS (SELECT 1 FROM fza_tarifas_cambios_lineas SL ' +
      'WHERE SL.CODIGO_TARC_TARCLIN = :P_TARC_CHK ' +
      'AND SL.CODIGO_ART_TARCLIN = a.CODIGO_ART_ART ' +
      'AND SL.CODIGO_UNIDAD_SKU_TARCLIN = '''') ' +
      'THEN ''S'' ELSE ''N'' END';
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.CondicionExcluirCargados(
  const AContexto: TContextoCargaMasivaArticulos): string;
begin
  case AContexto.Modo of
    mcTarifa:
      Result :=
        'NOT EXISTS (SELECT 1 FROM fza_articulos_tarifas tx ' +
        'WHERE tx.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
        'AND tx.CODIGO_TAR_ARTTAR = :P_TARIFA_EXCL)';
    mcInventario:
      Result :=
        'NOT EXISTS (SELECT 1 FROM fza_inventarios_lineas ilx ' +
        'WHERE ilx.CODIGO_EMP_INVLIN = :P_INV_EMP_X ' +
        'AND ilx.CODIGO_ALM_INVLIN = :P_INV_ALM_X ' +
        'AND ilx.SERIE_INV_INVLIN = :P_INV_SER_X ' +
        'AND ilx.NUMERO_INV_INVLIN = :P_INV_NRO_X ' +
        'AND ilx.CODIGO_ART_INVLIN = a.CODIGO_ART_ART)';
    mcDocumentoTrabajo:
      Result :=
        'NOT EXISTS (SELECT 1 FROM fza_documentos_trabajo_lineas dlx ' +
        'WHERE dlx.ID_DTR_DTL = :P_DTR_EXCL ' +
        'AND dlx.CODIGO_ART_DTL = a.CODIGO_ART_ART)';
  else
    Result :=
      'NOT EXISTS (SELECT 1 FROM fza_tarifas_cambios_lineas SLX ' +
      'WHERE SLX.CODIGO_TARC_TARCLIN = :P_TARC_EXCL ' +
      'AND SLX.CODIGO_ART_TARCLIN = a.CODIGO_ART_ART ' +
      'AND SLX.CODIGO_UNIDAD_SKU_TARCLIN = '''')';
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ConstruirSqlPreview(
  const AFiltros: TFiltrosCargaMasivaArticulos;
  const AContexto: TContextoCargaMasivaArticulos): string;
var
  oSql: TStringList;
  sAlmacenes: string;
  sFamilias: string;
  sProveedores: string;
  sPropiedades: string;
begin
  sAlmacenes := StrArrToCsvSql(AFiltros.CodigosAlmacen);
  sFamilias := StrArrToCsvSql(AFiltros.CodigosFamilia);
  sProveedores := StrArrToCsvSql(AFiltros.CodigosProveedor);
  sPropiedades := IntArrToCsvSql(AFiltros.IdsValorPropiedad);
  oSql := TStringList.Create;
  try
    oSql.Add('SELECT a.CODIGO_ART_ART, a.DESCRIPCION_ART,');
    oSql.Add('a.CODIGO_FAM_ART, f.NOMBRE_FAM_FAM,');
    oSql.Add('(SELECT GROUP_CONCAT(ap.CODIGO_PRV_AP)');
    oSql.Add('FROM fza_articulos_proveedores ap');
    oSql.Add('WHERE ap.CODIGO_ART_AP = a.CODIGO_ART_ART) AS PROVEEDORES,');
    oSql.Add('COALESCE((SELECT SUM(s.CANTIDAD_STK)');
    oSql.Add('FROM fza_articulos_stockactual s');
    oSql.Add('LEFT JOIN fza_articulos_skus sk');
    oSql.Add('ON sk.CODIGO_UNIDAD_SKU = s.CODIGO_UNIDAD_STK');
    oSql.Add('WHERE COALESCE(sk.CODIGO_ART_SKU, s.CODIGO_UNIDAD_STK)');
    oSql.Add('= a.CODIGO_ART_ART');
    if sAlmacenes <> '' then
    begin
      oSql.Add('AND s.CODIGO_ALM_STK IN (' + sAlmacenes + ')');
    end;
    oSql.Add('), 0) AS STOCK_TOTAL,');
    if ColumnasExtra(AContexto) <> '' then
    begin
      oSql.Add(ColumnasExtra(AContexto));
    end;
    oSql.Add(ExpresionYaCargado(AContexto) + ' AS YA_CARGADO');
    oSql.Add('FROM fza_articulos a LEFT JOIN fza_articulos_familias f');
    oSql.Add('ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART WHERE 1 = 1');
    if AFiltros.SoloActivos then
    begin
      oSql.Add('AND a.ESACTIVO_ART = ''S''');
    end;
    if AFiltros.ExcluirYaCargados then
    begin
      oSql.Add('AND ' + CondicionExcluirCargados(AContexto));
    end;
    if AFiltros.SoloConStock and (sAlmacenes <> '') then
    begin
      case AFiltros.StockCombinacion of
        scCualquiera:
          begin
            oSql.Add('AND EXISTS (SELECT 1 FROM fza_articulos_stockactual s2');
            oSql.Add('LEFT JOIN fza_articulos_skus sk2');
            oSql.Add('ON sk2.CODIGO_UNIDAD_SKU = s2.CODIGO_UNIDAD_STK');
            oSql.Add('WHERE COALESCE(sk2.CODIGO_ART_SKU,');
            oSql.Add('s2.CODIGO_UNIDAD_STK) = a.CODIGO_ART_ART');
            oSql.Add('AND s2.CANTIDAD_STK > 0');
            oSql.Add('AND s2.CODIGO_ALM_STK IN (' + sAlmacenes + '))');
          end;
        scTodos:
          begin
            oSql.Add('AND (SELECT COUNT(DISTINCT s2.CODIGO_ALM_STK)');
            oSql.Add('FROM fza_articulos_stockactual s2');
            oSql.Add('LEFT JOIN fza_articulos_skus sk2');
            oSql.Add('ON sk2.CODIGO_UNIDAD_SKU = s2.CODIGO_UNIDAD_STK');
            oSql.Add('WHERE COALESCE(sk2.CODIGO_ART_SKU,');
            oSql.Add('s2.CODIGO_UNIDAD_STK) = a.CODIGO_ART_ART');
            oSql.Add('AND s2.CANTIDAD_STK > 0');
            oSql.Add('AND s2.CODIGO_ALM_STK IN (' + sAlmacenes + ')) = ' +
              IntToStr(Length(AFiltros.CodigosAlmacen)));
          end;
        scSumaPositiva:
          begin
            oSql.Add('AND COALESCE((SELECT SUM(s2.CANTIDAD_STK)');
            oSql.Add('FROM fza_articulos_stockactual s2');
            oSql.Add('LEFT JOIN fza_articulos_skus sk2');
            oSql.Add('ON sk2.CODIGO_UNIDAD_SKU = s2.CODIGO_UNIDAD_STK');
            oSql.Add('WHERE COALESCE(sk2.CODIGO_ART_SKU,');
            oSql.Add('s2.CODIGO_UNIDAD_STK) = a.CODIGO_ART_ART');
            oSql.Add('AND s2.CODIGO_ALM_STK IN (' + sAlmacenes + ')), 0) > 0');
          end;
      end;
    end;
    if sFamilias <> '' then
    begin
      if AFiltros.PropagarFamilias then
      begin
        oSql.Add('AND a.CODIGO_FAM_ART IN (WITH RECURSIVE arbol AS (');
        oSql.Add('SELECT CODIGO_FAM_FAM, CODIGO_SUBFAMILIA_FAM');
        oSql.Add('FROM fza_articulos_familias');
        oSql.Add('WHERE CODIGO_FAM_FAM IN (' + sFamilias + ') UNION ALL');
        oSql.Add('SELECT h.CODIGO_FAM_FAM, h.CODIGO_SUBFAMILIA_FAM');
        oSql.Add('FROM fza_articulos_familias h JOIN arbol a2');
        oSql.Add('ON h.CODIGO_SUBFAMILIA_FAM = a2.CODIGO_FAM_FAM)');
        oSql.Add('SELECT CODIGO_FAM_FAM FROM arbol)');
      end
      else
      begin
        oSql.Add('AND a.CODIGO_FAM_ART IN (' + sFamilias + ')');
      end;
    end;
    if sProveedores <> '' then
    begin
      oSql.Add('AND EXISTS (SELECT 1 FROM fza_articulos_proveedores apx');
      oSql.Add('WHERE apx.CODIGO_ART_AP = a.CODIGO_ART_ART');
      oSql.Add('AND apx.CODIGO_PRV_AP IN (' + sProveedores + ')');
      if AFiltros.SoloProveedorPrincipal then
      begin
        oSql.Add('AND apx.ESPROVEEDORPRINCIPAL_AP = ''S''');
      end;
      oSql.Add(')');
    end;
    if sPropiedades <> '' then
    begin
      oSql.Add('AND EXISTS (SELECT 1 FROM fza_articulos_propiedades pp');
      oSql.Add('WHERE pp.CODIGO_ART_ART = a.CODIGO_ART_ART');
      oSql.Add('AND pp.ID_PV_ARTPROP IN (' + sPropiedades + '))');
    end;
    if AFiltros.AplicarFechaAlta then
    begin
      oSql.Add('AND a.INSTANTE_ALTA >= :P_ALTA_DESDE');
      oSql.Add('AND a.INSTANTE_ALTA < :P_ALTA_HASTA');
    end;
    if AFiltros.FiltrarVentas then
    begin
      if AFiltros.ConVentas then
      begin
        oSql.Add('AND (SELECT COUNT(*) FROM fza_facturas_lineas fl');
        oSql.Add(
          'JOIN fza_facturas fc ON fc.NUMERO_FAC = fl.NUMERO_FAC_FACLIN');
        oSql.Add('AND fc.SERIE_FAC = fl.SERIE_FAC_FACLIN');
        oSql.Add('WHERE fl.CODIGO_ART_FACLIN = a.CODIGO_ART_ART');
        oSql.Add('AND fc.FECHA_FAC BETWEEN :P_VTA_DESDE AND :P_VTA_HASTA)');
        oSql.Add('>= :P_NUM_MIN_VTAS');
      end
      else
      begin
        oSql.Add('AND NOT EXISTS (SELECT 1 FROM fza_facturas_lineas fl');
        oSql.Add(
          'JOIN fza_facturas fc ON fc.NUMERO_FAC = fl.NUMERO_FAC_FACLIN');
        oSql.Add('AND fc.SERIE_FAC = fl.SERIE_FAC_FACLIN');
        oSql.Add('WHERE fl.CODIGO_ART_FACLIN = a.CODIGO_ART_ART');
        oSql.Add('AND fc.FECHA_FAC BETWEEN :P_VTA_DESDE AND :P_VTA_HASTA)');
      end;
    end;
    oSql.Add('ORDER BY a.CODIGO_FAM_ART, a.CODIGO_ART_ART');
    Result := oSql.Text;
  finally
    FreeAndNil(oSql);
  end;
end;

procedure TServicioCargaMasivaArticulosUniDAC.VincularParametrosPreview(
  AConsulta: TUniQuery;
  const AFiltros: TFiltrosCargaMasivaArticulos;
  const AContexto: TContextoCargaMasivaArticulos);

  procedure Cadena(const ANombre, AValor: string);
  begin
    if Assigned(AConsulta.Params.FindParam(ANombre)) then
    begin
      AConsulta.ParamByName(ANombre).AsString := AValor;
    end;
  end;

  procedure Entero(const ANombre: string; AValor: Integer);
  begin
    if Assigned(AConsulta.Params.FindParam(ANombre)) then
    begin
      AConsulta.ParamByName(ANombre).AsInteger := AValor;
    end;
  end;

  procedure EnteroGrande(const ANombre: string; AValor: Int64);
  begin
    if Assigned(AConsulta.Params.FindParam(ANombre)) then
    begin
      AConsulta.ParamByName(ANombre).AsLargeInt := AValor;
    end;
  end;

begin
  if Assigned(AConsulta.Params.FindParam('P_ALTA_DESDE')) then
  begin
    AConsulta.ParamByName('P_ALTA_DESDE').AsDateTime :=
      AFiltros.FechaAltaDesde;
    AConsulta.ParamByName('P_ALTA_HASTA').AsDateTime :=
      AFiltros.FechaAltaHasta + 1;
  end;
  if Assigned(AConsulta.Params.FindParam('P_VTA_DESDE')) then
  begin
    AConsulta.ParamByName('P_VTA_DESDE').AsDateTime := AFiltros.VentaDesde;
    AConsulta.ParamByName('P_VTA_HASTA').AsDateTime := AFiltros.VentaHasta;
  end;
  Entero('P_NUM_MIN_VTAS', AFiltros.NumeroMinimoVentas);
  Cadena('P_TARIFA_CHK', AContexto.CodigoTarifa);
  Cadena('P_TARIFA_EXCL', AContexto.CodigoTarifa);
  Cadena('P_TARIFA_ORIG_S', AContexto.CodigoTarifaOrigen);
  Cadena('P_TARIFA_ORIG_F', AContexto.CodigoTarifaOrigen);
  Cadena('P_INV_ALMACEN', AContexto.AlmacenInventario);
  Cadena('P_INV_ALMACEN_PMP', AContexto.AlmacenInventario);
  Cadena('P_INV_EMP_C', AContexto.EmpresaInventario);
  Cadena('P_INV_ALM_C', AContexto.AlmacenInventario);
  Cadena('P_INV_SER_C', AContexto.SerieInventario);
  Cadena('P_INV_NRO_C', AContexto.NumeroInventario);
  Cadena('P_INV_EMP_X', AContexto.EmpresaInventario);
  Cadena('P_INV_ALM_X', AContexto.AlmacenInventario);
  Cadena('P_INV_SER_X', AContexto.SerieInventario);
  Cadena('P_INV_NRO_X', AContexto.NumeroInventario);
  EnteroGrande('P_DTR_CHK', AContexto.IdDocumentoTrabajo);
  EnteroGrande('P_DTR_EXCL', AContexto.IdDocumentoTrabajo);
  Entero('P_TARC_CHK', AContexto.CodigoSesionTarifa);
  Entero('P_TARC_EXCL', AContexto.CodigoSesionTarifa);
  Cadena('P_TAR_ORIG', AContexto.TarifaOrigenSesion);
  Cadena('P_TAR_DEST_SAL', AContexto.TarifaDestinoSesion);
  Cadena('P_TAR_DEST_FIN', AContexto.TarifaDestinoSesion);
  Cadena('P_TAR_DEST_DTO', AContexto.TarifaDestinoSesion);
  Cadena('P_TAR_DEST_PDTO', AContexto.TarifaDestinoSesion);
end;

function TServicioCargaMasivaArticulosUniDAC.Previsualizar(
  const AFiltros: TFiltrosCargaMasivaArticulos;
  const AContexto: TContextoCargaMasivaArticulos):
  IConsultaCargaMasivaArticulos;
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta(ConstruirSqlPreview(AFiltros, AContexto));
  try
    VincularParametrosPreview(oConsulta, AFiltros, AContexto);
    oConsulta.Open;
    Result := EnvolverConsulta(oConsulta);
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.AjustarPrecio(
  APrecio: Double;
  const AParametros: TParametrosInsercionTarifa): Double;
var
  dValor: Double;
begin
  Result := APrecio;
  if AParametros.AjustarPrecio and (APrecio > 0) and
     (AParametros.MultiploAjuste > 0) then
  begin
    dValor := Ceil(APrecio / AParametros.MultiploAjuste) *
      AParametros.MultiploAjuste - AParametros.RestarAjuste;
    if dValor < 0 then
    begin
      dValor := 0;
    end;
    Result := Round(dValor * 100) / 100;
  end;
end;

procedure TServicioCargaMasivaArticulosUniDAC.CalcularPreciosTarifa(
  APrecioSalidaOrigen: Double;
  APrecioFinalOrigen: Double;
  const AParametros: TParametrosInsercionTarifa;
  out APrecioSalida: Double;
  out APrecioFinal: Double;
  out APorcentajeDescuento: Double);
var
  dBaseSalida: Double;
begin
  APorcentajeDescuento := AParametros.PorcentajeDescuento;
  if APrecioSalidaOrigen > 0 then
  begin
    dBaseSalida := APrecioSalidaOrigen;
  end
  else
  begin
    dBaseSalida := APrecioFinalOrigen;
  end;
  APrecioSalida := dBaseSalida;
  if APorcentajeDescuento > 0 then
  begin
    APrecioFinal := dBaseSalida * (1 - APorcentajeDescuento / 100);
  end
  else
  begin
    APrecioFinal := dBaseSalida;
  end;
  if AParametros.AjustarPrecio then
  begin
    if AParametros.AlcanceAjuste in [aaSoloSalida, aaAmbos] then
    begin
      APrecioSalida := AjustarPrecio(APrecioSalida, AParametros);
    end;
    if AParametros.AlcanceAjuste in [aaSoloFinal, aaAmbos] then
    begin
      APrecioFinal := AjustarPrecio(APrecioFinal, AParametros);
    end;
    if (APrecioSalida > 0) and (APrecioSalida <> APrecioFinal) then
    begin
      APorcentajeDescuento := (1 - APrecioFinal / APrecioSalida) * 100;
    end
    else if APrecioSalida = APrecioFinal then
    begin
      APorcentajeDescuento := 0;
    end;
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.InsertarTarifa(
  const AConsulta: IConsultaCargaMasivaArticulos;
  const AParametros: TParametrosInsercionTarifa):
  TResultadoInsercionCargaMasiva;
var
  dDescuento: Double;
  dDescuentoEuros: Double;
  dFinal: Double;
  dOrigenFinal: Double;
  dOrigenSalida: Double;
  dSalida: Double;
  oCodigos: TList<string>;
  oDatos: TDataSet;
  oInsercion: TUniQuery;
  sArticulo: string;
begin
  Result.NumeroLineas := 0;
  Result.NumeroArticulos := 0;
  SetLength(Result.CodigosArticulo, 0);
  oDatos := AConsulta.DataSet;
  oCodigos := TList<string>.Create;
  oInsercion := CrearConsulta(SQL_INSERTAR_TARIFA);
  try
    oDatos.DisableControls;
    FConexion.StartTransaction;
    try
      oDatos.First;
      while not oDatos.Eof do
      begin
        if oDatos.FieldByName('YA_CARGADO').AsString <> 'S' then
        begin
          dOrigenSalida := oDatos.FieldByName('PRECIO_SALIDA_ORIG').AsFloat;
          dOrigenFinal := oDatos.FieldByName('PRECIO_FINAL_ORIG').AsFloat;
          CalcularPreciosTarifa(
            dOrigenSalida,
            dOrigenFinal,
            AParametros,
            dSalida,
            dFinal,
            dDescuento);
          if (dOrigenSalida = 0) and (dOrigenFinal = 0) then
          begin
            dSalida := 0;
            dFinal := 0;
            dDescuento := AParametros.PorcentajeDescuento;
          end;
          dDescuentoEuros := dSalida - dFinal;
          if dDescuentoEuros < 0 then
          begin
            dDescuentoEuros := 0;
          end;
          sArticulo := oDatos.FieldByName('CODIGO_ART_ART').AsString;
          oInsercion.ParamByName('ART').AsString := sArticulo;
          oInsercion.ParamByName('TARIFA').AsString := AParametros.CodigoTarifa;
          oInsercion.ParamByName('SALIDA').AsFloat := dSalida;
          oInsercion.ParamByName('FINAL').AsFloat := dFinal;
          oInsercion.ParamByName('DTO').AsFloat := dDescuentoEuros;
          oInsercion.ParamByName('PDTO').AsFloat := dDescuento;
          oInsercion.ParamByName('DESDE').AsDateTime := AParametros.FechaDesde;
          if AParametros.UsaFechaHasta then
          begin
            oInsercion.ParamByName('HASTA').AsDateTime :=
              AParametros.FechaHasta;
          end
          else
          begin
            oInsercion.ParamByName('HASTA').Clear;
          end;
          oInsercion.ParamByName('USR').AsString := AParametros.Usuario;
          oInsercion.ParamByName('USR2').AsString := AParametros.Usuario;
          oInsercion.Execute;
          oCodigos.Add(sArticulo);
        end;
        oDatos.Next;
      end;
      FConexion.Commit;
      Result.NumeroLineas := oCodigos.Count;
      Result.NumeroArticulos := oCodigos.Count;
      Result.CodigosArticulo := oCodigos.ToArray;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    oDatos.EnableControls;
    FreeAndNil(oInsercion);
    FreeAndNil(oCodigos);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ProximaLineaInventario(
  const AParametros: TParametrosInsercionInventario): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta(SQL_PROXIMA_LINEA_INVENTARIO);
  try
    oConsulta.ParamByName('EMP').AsString := AParametros.Empresa;
    oConsulta.ParamByName('ALM').AsString := AParametros.Almacen;
    oConsulta.ParamByName('SER').AsString := AParametros.Serie;
    oConsulta.ParamByName('NRO').AsString := AParametros.Numero;
    oConsulta.Open;
    Result := oConsulta.FieldByName('PROX').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioCargaMasivaArticulosUniDAC.InsertarSkusInventario(
  AInsercion: TUniQuery;
  const ACodigoArticulo: string;
  const AParametros: TParametrosInsercionInventario;
  var ALineaActual: Integer;
  var ANumeroLineas: Integer);
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta(SQL_SKUS_ARTICULO);
  try
    oConsulta.ParamByName('ART').AsString := ACodigoArticulo;
    oConsulta.ParamByName('ART2').AsString := ACodigoArticulo;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      AInsercion.ParamByName('LINEA').AsString :=
        Format('%.4d', [ALineaActual]);
      AInsercion.ParamByName('ART').AsString := ACodigoArticulo;
      AInsercion.ParamByName('SKU').AsString :=
        oConsulta.FieldByName('SKU').AsString;
      AInsercion.ParamByName('DESCRIPCION').AsString :=
        oConsulta.FieldByName('DESC_ART').AsString;
      AInsercion.ParamByName('USR').AsString := AParametros.Usuario;
      AInsercion.ParamByName('USR2').AsString := AParametros.Usuario;
      AInsercion.Execute;
      Inc(ALineaActual);
      Inc(ANumeroLineas);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.InsertarInventario(
  const AConsulta: IConsultaCargaMasivaArticulos;
  const AParametros: TParametrosInsercionInventario):
  TResultadoInsercionCargaMasiva;
var
  iLineaActual: Integer;
  oCodigos: TList<string>;
  oDatos: TDataSet;
  oInsercion: TUniQuery;
  sArticulo: string;
begin
  Result.NumeroLineas := 0;
  Result.NumeroArticulos := 0;
  SetLength(Result.CodigosArticulo, 0);
  oDatos := AConsulta.DataSet;
  iLineaActual := ProximaLineaInventario(AParametros);
  oCodigos := TList<string>.Create;
  oInsercion := CrearConsulta(SQL_INSERTAR_LINEA_INVENTARIO);
  try
    oInsercion.ParamByName('EMP').AsString := AParametros.Empresa;
    oInsercion.ParamByName('ALM').AsString := AParametros.Almacen;
    oInsercion.ParamByName('SER').AsString := AParametros.Serie;
    oInsercion.ParamByName('NRO').AsString := AParametros.Numero;
    oDatos.DisableControls;
    FConexion.StartTransaction;
    try
      oDatos.First;
      while not oDatos.Eof do
      begin
        if oDatos.FieldByName('YA_CARGADO').AsString <> 'S' then
        begin
          sArticulo := oDatos.FieldByName('CODIGO_ART_ART').AsString;
          InsertarSkusInventario(
            oInsercion,
            sArticulo,
            AParametros,
            iLineaActual,
            Result.NumeroLineas);
          oCodigos.Add(sArticulo);
        end;
        oDatos.Next;
      end;
      FConexion.Commit;
      Result.NumeroArticulos := oCodigos.Count;
      Result.CodigosArticulo := oCodigos.ToArray;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    oDatos.EnableControls;
    FreeAndNil(oInsercion);
    FreeAndNil(oCodigos);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.ProximaLineaDocumento(
  AIdDocumento: Int64): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 1;
  oConsulta := CrearConsulta(SQL_PROXIMA_LINEA_DOCUMENTO);
  try
    oConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result := oConsulta.FieldByName('PROX').AsInteger;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TServicioCargaMasivaArticulosUniDAC.InsertarSkusDocumento(
  AInsercion: TUniQuery;
  const ACodigoArticulo: string;
  const AParametros: TParametrosInsercionDocumentoTrabajo;
  var ALineaActual: Integer;
  var ANumeroLineas: Integer);
var
  oConsulta: TUniQuery;
  sSql: string;
begin
  sSql := SQL_SKUS_DOCUMENTO;
  if Length(AParametros.CodigosAlmacen) > 0 then
  begin
    sSql := sSql + ' AND s.CODIGO_ALM_STK IN (' +
      StrArrToCsvSql(AParametros.CodigosAlmacen) + ')';
  end;
  sSql := sSql +
    ' ORDER BY s.CODIGO_ALM_STK, s.CODIGO_UNIDAD_STK, s.LOTE_STK';
  oConsulta := CrearConsulta(sSql);
  try
    oConsulta.ParamByName('ART').AsString := ACodigoArticulo;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      AInsercion.ParamByName('ID_DTR').AsLargeInt := AParametros.IdDocumento;
      AInsercion.ParamByName('LINEA').AsString :=
        Format('%.8d', [ALineaActual]);
      AInsercion.ParamByName('ART').AsString := ACodigoArticulo;
      AInsercion.ParamByName('SKU').AsString :=
        oConsulta.FieldByName('SKU').AsString;
      AInsercion.ParamByName('ALM').AsString :=
        oConsulta.FieldByName('ALM').AsString;
      AInsercion.ParamByName('LOTE').AsString :=
        oConsulta.FieldByName('LOTE_STK').AsString;
      if oConsulta.FieldByName('FECHA_CADUCIDAD_STK').IsNull then
      begin
        AInsercion.ParamByName('CADUCIDAD').Clear;
      end
      else
      begin
        AInsercion.ParamByName('CADUCIDAD').AsDate :=
          oConsulta.FieldByName('FECHA_CADUCIDAD_STK').AsDateTime;
      end;
      AInsercion.ParamByName('DESC_ART').AsString :=
        oConsulta.FieldByName('DESC_ART').AsString;
      AInsercion.ParamByName('DESC_SKU').AsString :=
        oConsulta.FieldByName('DESC_SKU').AsString;
      AInsercion.ParamByName('CANTIDAD_STOCK').AsFloat :=
        oConsulta.FieldByName('CANTIDAD_STK').AsFloat;
      AInsercion.ParamByName('CANTIDAD').AsFloat := 1;
      AInsercion.ParamByName('ORIGEN').AsString := 'FILTROS';
      AInsercion.ParamByName('USR').AsString := AParametros.Usuario;
      AInsercion.ParamByName('USR2').AsString := AParametros.Usuario;
      AInsercion.Execute;
      Inc(ALineaActual);
      Inc(ANumeroLineas);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.InsertarDocumentoTrabajo(
  const AConsulta: IConsultaCargaMasivaArticulos;
  const AParametros: TParametrosInsercionDocumentoTrabajo):
  TResultadoInsercionCargaMasiva;
var
  iAntes: Integer;
  iLineaActual: Integer;
  oCodigos: TList<string>;
  oDatos: TDataSet;
  oInsercion: TUniQuery;
  sArticulo: string;
begin
  Result.NumeroLineas := 0;
  Result.NumeroArticulos := 0;
  SetLength(Result.CodigosArticulo, 0);
  oDatos := AConsulta.DataSet;
  iLineaActual := ProximaLineaDocumento(AParametros.IdDocumento);
  oCodigos := TList<string>.Create;
  oInsercion := CrearConsulta(SQL_INSERTAR_LINEA_DOCUMENTO);
  try
    oDatos.DisableControls;
    FConexion.StartTransaction;
    try
      oDatos.First;
      while not oDatos.Eof do
      begin
        if oDatos.FieldByName('YA_CARGADO').AsString <> 'S' then
        begin
          sArticulo := oDatos.FieldByName('CODIGO_ART_ART').AsString;
          iAntes := Result.NumeroLineas;
          InsertarSkusDocumento(
            oInsercion,
            sArticulo,
            AParametros,
            iLineaActual,
            Result.NumeroLineas);
          if Result.NumeroLineas > iAntes then
          begin
            oCodigos.Add(sArticulo);
          end;
        end;
        oDatos.Next;
      end;
      FConexion.Commit;
      Result.NumeroArticulos := oCodigos.Count;
      Result.CodigosArticulo := oCodigos.ToArray;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    oDatos.EnableControls;
    FreeAndNil(oInsercion);
    FreeAndNil(oCodigos);
  end;
end;

function TServicioCargaMasivaArticulosUniDAC.InsertarSesionTarifa(
  const AConsulta: IConsultaCargaMasivaArticulos;
  const AParametros: TParametrosInsercionSesionTarifa):
  TResultadoInsercionCargaMasiva;
var
  dOrigen: Double;
  oCodigos: TList<string>;
  oDatos: TDataSet;
  oInsercion: TUniQuery;
  sArticulo: string;
begin
  Result.NumeroLineas := 0;
  Result.NumeroArticulos := 0;
  SetLength(Result.CodigosArticulo, 0);
  oDatos := AConsulta.DataSet;
  oCodigos := TList<string>.Create;
  oInsercion := CrearConsulta(SQL_INSERTAR_SESION_TARIFA);
  try
    oDatos.DisableControls;
    FConexion.StartTransaction;
    try
      oDatos.First;
      while not oDatos.Eof do
      begin
        if oDatos.FieldByName('YA_CARGADO').AsString <> 'S' then
        begin
          sArticulo := oDatos.FieldByName('CODIGO_ART_ART').AsString;
          dOrigen := oDatos.FieldByName('PRECIO_ORIGEN').AsFloat;
          oInsercion.ParamByName('TARC').AsInteger := AParametros.CodigoSesion;
          oInsercion.ParamByName('ART').AsString := sArticulo;
          oInsercion.ParamByName('TAR_ORIG').AsString :=
            AParametros.TarifaOrigen;
          oInsercion.ParamByName('TAR_DEST').AsString :=
            AParametros.TarifaDestino;
          oInsercion.ParamByName('P_ORIG').AsFloat := dOrigen;
          oInsercion.ParamByName('P_COSTE').AsFloat :=
            oDatos.FieldByName('PRECIO_COSTE').AsFloat;
          oInsercion.ParamByName('P_SAL_ACT').AsFloat :=
            oDatos.FieldByName('PRECIO_SALIDA_ACT').AsFloat;
          oInsercion.ParamByName('P_FIN_ACT').AsFloat :=
            oDatos.FieldByName('PRECIO_FINAL_ACT').AsFloat;
          oInsercion.ParamByName('P_DTO_ACT').AsFloat :=
            oDatos.FieldByName('PRECIO_DTO_ACT').AsFloat;
          oInsercion.ParamByName('P_PDTO_ACT').AsFloat :=
            oDatos.FieldByName('PORC_DTO_ACT').AsFloat;
          oInsercion.ParamByName('P_NUEVO').AsFloat := dOrigen;
          oInsercion.ParamByName('P_FIN_NUEVO').AsFloat := dOrigen;
          oInsercion.ParamByName('USUARIO').AsString := AParametros.Usuario;
          oInsercion.Execute;
          oCodigos.Add(sArticulo);
        end;
        oDatos.Next;
      end;
      FConexion.Commit;
      Result.NumeroLineas := oCodigos.Count;
      Result.NumeroArticulos := oCodigos.Count;
      Result.CodigosArticulo := oCodigos.ToArray;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    oDatos.EnableControls;
    FreeAndNil(oInsercion);
    FreeAndNil(oCodigos);
  end;
end;

function CrearServicioCargaMasivaArticulosUniDAC(
  AConexion: TUniConnection): TServiciosCargaMasivaArticulos;
var
  oServicio: TServicioCargaMasivaArticulosUniDAC;
begin
  oServicio := TServicioCargaMasivaArticulosUniDAC.Create(AConexion);
  Result.Consultas := oServicio;
  Result.Inserciones := oServicio;
end;

end.
