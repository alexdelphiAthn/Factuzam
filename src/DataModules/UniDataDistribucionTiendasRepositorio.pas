{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataDistribucionTiendasRepositorio                         }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adaptador UniDAC de la distribución entre tiendas: unidades del           }
{    documento de trabajo, stock por almacén y propuestas de traspaso          }
{    (fza_traspasos_propuestas y fza_traspasos_propuestas_lineas).             }
{******************************************************************************}
unit UniDataDistribucionTiendasRepositorio;

interface

uses
  System.SysUtils, Uni,
  inLibDistribucionTiendasIntf;

type
  // Las propuestas del documento cambiaron (alguien confirmó una) desde que
  // se cargó la distribución: hay que recargar antes de guardar.
  EDistribucionTiendasDesactualizada = class(Exception);

function CrearRepositorioDistribucionTiendasUniDAC(
  AConexion: TUniConnection): IRepositorioDistribucionTiendas;

// SQL expuesto para las pruebas de contrato e integración.
function SqlUnidadesDocumentoDistribucion: string;
function SqlAlmacenesDistribucion: string;
function SqlStocksDistribucion: string;
function SqlAsignacionesDistribucion: string;
function SqlCabecerasPropuestasTraspaso(const AFiltro: string): string;
function SqlLineasPropuestasTraspaso(const AFiltro: string): string;
function SqlInsertarPropuestaTraspaso: string;
function SqlInsertarLineaPropuestaTraspaso: string;
function SqlBorrarLineasPropuestasPendientes: string;
function SqlBorrarPropuestasPendientesVacias: string;
function SqlBloquearPropuestasPendientes: string;

const
  FILTRO_PROPUESTAS_DOCUMENTO = 'P.ID_DTR_TRPRO = :ID_DTR';
  FILTRO_PROPUESTAS_PENDIENTES_ORIGEN =
    'P.CODIGO_ALM_ORIGEN_TRPRO = :ORIGEN ' +
    'AND P.ESTADO_TRPRO = ''PENDIENTE''';
  FILTRO_PROPUESTA_POR_ID = 'P.ID_TRPRO = :ID_TRPRO';

implementation

uses
  System.Math, System.Generics.Collections, Data.DB,
  inLibMsgDistribucionTiendas;

const
  TOLERANCIA_CANTIDAD = 0.000001;
  SEPARADOR_CLAVE = #9;

type
  TRepositorioDistribucionTiendasUniDAC = class(
    TInterfacedObject,
    IRepositorioDistribucionTiendas)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
    function LeerTitulo(
      AConsulta: TUniQuery; AIdDocumento: Int64): string;
    function LeerUnidades(
      AConsulta: TUniQuery;
      AIdDocumento: Int64): TUnidadesDocumentoDistribucion;
    function LeerAlmacenes(
      AConsulta: TUniQuery;
      AIdDocumento: Int64): TAlmacenesDistribucion;
    function LeerStocks(
      AConsulta: TUniQuery; AIdDocumento: Int64): TStocksDistribucion;
    function LeerAsignaciones(
      AConsulta: TUniQuery;
      AIdDocumento: Int64): TAsignacionesDistribucion;
    function LeerPropuestas(
      const AFiltro, AParametro: string;
      const AValor: Variant): TPropuestasTraspaso;
    procedure LeerLineasPropuestas(
      AConsulta: TUniQuery;
      const AFiltro, AParametro: string;
      const AValor: Variant;
      var APropuestas: TPropuestasTraspaso);
    procedure ComprobarConfirmadoSinCambios(
      AConsulta: TUniQuery;
      AIdDocumento: Int64;
      const AAsignaciones: TAsignacionesDistribucion);
    procedure CargarPropuestasPendientes(
      AConsulta: TUniQuery;
      AIdDocumento: Int64;
      APendientes: TDictionary<string, Int64>);
    function AsegurarPropuestaPendiente(
      AConsulta: TUniQuery;
      AIdDocumento: Int64;
      const AAsignacion: TAsignacionDistribucion;
      const AUsuario: string;
      APendientes: TDictionary<string, Int64>): Int64;
    procedure InsertarLinea(
      AConsulta: TUniQuery;
      AIdDocumento, AIdPropuesta: Int64;
      const AAsignacion: TAsignacionDistribucion;
      const AUsuario: string);
    procedure SincronizarPropuestas(
      AConsulta: TUniQuery;
      AIdDocumento: Int64;
      const AAsignaciones: TAsignacionesDistribucion;
      const AUsuario: string);
  public
    constructor Create(AConexion: TUniConnection);
    function CargarDocumento(
      AIdDocumento: Int64): TDocumentoDistribucion;
    procedure GuardarPropuestas(
      AIdDocumento: Int64;
      const AAsignaciones: TAsignacionesDistribucion;
      const AUsuario: string);
    function ListarPropuestasDocumento(
      AIdDocumento: Int64): TPropuestasTraspaso;
    function ListarPropuestasPendientesOrigen(
      const AAlmacenOrigen: string): TPropuestasTraspaso;
    function LeerPropuesta(AIdPropuesta: Int64): TPropuestaTraspaso;
    function EliminarPropuestaPendiente(AIdPropuesta: Int64): Boolean;
  end;

function ClavePareja(const AOrigen, ADestino: string): string;
begin
  Result := AnsiUpperCase(Trim(AOrigen)) + SEPARADOR_CLAVE +
    AnsiUpperCase(Trim(ADestino));
end;

function ClaveAsignacion(const AOrigen, ADestino, ASku: string): string;
begin
  Result := ClavePareja(AOrigen, ADestino) + SEPARADOR_CLAVE +
    AnsiUpperCase(Trim(ASku));
end;

// ===========================================================================
//   SQL
// ===========================================================================

// Color, talla y orden de talla de un SKU. El color es el atributo 'CO';
// la talla, el resto de atributos. El orden sigue el criterio de la
// consulta de stock: artículo, conjunto del artículo y valor global.
function SqlAtributosSku(const ACampoSku, ACampoArticulo: string): string;
begin
  Result :=
    '       COALESCE((SELECT MIN(AVC.AV) ' +
    '                   FROM fza_atributos_sku SAC ' +
    '                   JOIN fza_atributos_valores AVC ' +
    '                     ON AVC.ID_AV = SAC.ID_AV_SA ' +
    '                  WHERE SAC.CODIGO_UNIDAD_SKU_SA = ' + ACampoSku +
    '                    AND AVC.ID_VA_AV = ''CO''), '''') AS COLOR, ' +
    '       COALESCE((SELECT GROUP_CONCAT(AVT.AV ' +
    '                          ORDER BY AVT.ID_VA_AV SEPARATOR ''/'') ' +
    '                   FROM fza_atributos_sku SAT ' +
    '                   JOIN fza_atributos_valores AVT ' +
    '                     ON AVT.ID_AV = SAT.ID_AV_SA ' +
    '                  WHERE SAT.CODIGO_UNIDAD_SKU_SA = ' + ACampoSku +
    '                    AND AVT.ID_VA_AV <> ''CO''), '''') AS TALLA, ' +
    '       COALESCE((SELECT MIN(COALESCE(AAB.ORDEN_AAB, ' +
    '                                     ACD.ORDEN_ACD, ' +
    '                                     AVO.ORDEN_AV)) ' +
    '                   FROM fza_atributos_sku SAO ' +
    '                   JOIN fza_atributos_valores AVO ' +
    '                     ON AVO.ID_AV = SAO.ID_AV_SA ' +
    '                   LEFT JOIN fza_articulos_atributos_basicos AAB ' +
    '                     ON AAB.CODIGO_ART_AAB = ' + ACampoArticulo +
    '                    AND AAB.ID_AV_AAB = AVO.ID_AV ' +
    '                   LEFT JOIN fza_articulos_conjuntos_asign ACA ' +
    '                     ON ACA.CODIGO_ART_ACA = ' + ACampoArticulo +
    '                    AND ACA.ID_VA_ACA = AVO.ID_VA_AV ' +
    '                   LEFT JOIN fza_atributos_conjuntos_det ACD ' +
    '                     ON ACD.ID_AC_ACD = ACA.ID_AC_ACA ' +
    '                    AND ACD.ID_AV_ACD = AVO.ID_AV ' +
    '                  WHERE SAO.CODIGO_UNIDAD_SKU_SA = ' + ACampoSku +
    '                    AND AVO.ID_VA_AV <> ''CO''), 0) AS ORDEN_TALLA ';
end;

// Una fila por almacén y SKU. El almacén de la línea manda; si no lo
// lleva, el de la cabecera del documento. Las líneas sin SKU cerrado o sin
// unidades no se pueden repartir.
function SqlUnidadesDocumentoDistribucion: string;
begin
  Result :=
    'SELECT L.CODIGO_ALM, L.CODIGO_ART, L.CODIGO_UNIDAD, ' +
    '       L.DESCRIPCION, L.CANTIDAD, ' +
    SqlAtributosSku('L.CODIGO_UNIDAD', 'L.CODIGO_ART') +
    '  FROM (SELECT COALESCE(NULLIF(DTL.CODIGO_ALM_DTL, ''''), ' +
    '                        DTR.CODIGO_ALM_DTR, '''') AS CODIGO_ALM, ' +
    '               DTL.CODIGO_ART_DTL AS CODIGO_ART, ' +
    '               DTL.CODIGO_UNIDAD_DTL AS CODIGO_UNIDAD, ' +
    '               MAX(COALESCE(DTL.DESCRIPCION_ARTICULO_DTL, '''')) ' +
    '                 AS DESCRIPCION, ' +
    '               SUM(DTL.CANTIDAD_DTL) AS CANTIDAD ' +
    '          FROM fza_documentos_trabajo_lineas DTL ' +
    '          JOIN fza_documentos_trabajo DTR ' +
    '            ON DTR.ID_DTR = DTL.ID_DTR_DTL ' +
    '         WHERE DTL.ID_DTR_DTL = :ID_DTR ' +
    '           AND COALESCE(DTL.CODIGO_UNIDAD_DTL, '''') <> '''' ' +
    '         GROUP BY COALESCE(NULLIF(DTL.CODIGO_ALM_DTL, ''''), ' +
    '                           DTR.CODIGO_ALM_DTR, ''''), ' +
    '                  DTL.CODIGO_ART_DTL, DTL.CODIGO_UNIDAD_DTL ' +
    '        HAVING SUM(DTL.CANTIDAD_DTL) > 0) L ' +
    ' WHERE L.CODIGO_ALM <> '''' ' +
    ' ORDER BY L.CODIGO_ART, COLOR, ORDEN_TALLA, TALLA, L.CODIGO_ALM';
end;

// Tiendas activas de uso estándar y, además, cualquier almacén que el
// documento use como origen aunque no lo sea.
function SqlAlmacenesDistribucion: string;
begin
  Result :=
    'SELECT ALM.CODIGO_ALM_ALM, ' +
    '       COALESCE(ALM.NOMBRE_ALM_ALM, '''') AS NOMBRE_ALM_ALM, ' +
    '       COALESCE(ALM.ORDEN_ALM, 0) AS ORDEN_ALM ' +
    '  FROM fza_almacenes ALM ' +
    ' WHERE (ALM.ESACTIVO_ALM = ''S'' ' +
    '        AND ALM.TIPO_USO_ALM IN (''ESTANDAR'', ''ESTANDARD'')) ' +
    '    OR EXISTS (SELECT 1 ' +
    '                 FROM fza_documentos_trabajo_lineas DTL ' +
    '                 JOIN fza_documentos_trabajo DTR ' +
    '                   ON DTR.ID_DTR = DTL.ID_DTR_DTL ' +
    '                WHERE DTL.ID_DTR_DTL = :ID_DTR ' +
    '                  AND COALESCE(NULLIF(DTL.CODIGO_ALM_DTL, ''''), ' +
    '                               DTR.CODIGO_ALM_DTR) = ' +
    '                      ALM.CODIGO_ALM_ALM) ' +
    ' ORDER BY COALESCE(ALM.ORDEN_ALM, 0), ALM.CODIGO_ALM_ALM';
end;

function SqlStocksDistribucion: string;
begin
  Result :=
    'SELECT STK.CODIGO_ALM_STK, STK.CODIGO_UNIDAD_STK, ' +
    '       SUM(STK.CANTIDAD_STK) AS CANTIDAD ' +
    '  FROM fza_articulos_stockactual STK ' +
    '  JOIN (SELECT DISTINCT DTL.CODIGO_UNIDAD_DTL AS CODIGO_UNIDAD ' +
    '          FROM fza_documentos_trabajo_lineas DTL ' +
    '         WHERE DTL.ID_DTR_DTL = :ID_DTR ' +
    '           AND DTL.CODIGO_UNIDAD_DTL <> '''') D ' +
    '    ON D.CODIGO_UNIDAD = STK.CODIGO_UNIDAD_STK ' +
    ' GROUP BY STK.CODIGO_ALM_STK, STK.CODIGO_UNIDAD_STK';
end;

// Lo confirmado cuenta por lo realmente traspasado; lo pendiente, por lo
// propuesto.
function SqlAsignacionesDistribucion: string;
begin
  Result :=
    'SELECT P.CODIGO_ALM_ORIGEN_TRPRO AS ORIGEN, ' +
    '       P.CODIGO_ALM_DESTINO_TRPRO AS DESTINO, ' +
    '       L.CODIGO_UNIDAD_TRPROLIN AS CODIGO_UNIDAD, ' +
    '       SUM(CASE WHEN P.ESTADO_TRPRO = ''CONFIRMADA'' ' +
    '                THEN L.CANTIDAD_TRASPASADA_TRPROLIN ' +
    '                ELSE 0 END) AS CONFIRMADA, ' +
    '       SUM(CASE WHEN P.ESTADO_TRPRO = ''PENDIENTE'' ' +
    '                THEN L.CANTIDAD_TRPROLIN ' +
    '                ELSE 0 END) AS PENDIENTE ' +
    '  FROM fza_traspasos_propuestas P ' +
    '  JOIN fza_traspasos_propuestas_lineas L ' +
    '    ON L.ID_TRPRO_TRPROLIN = P.ID_TRPRO ' +
    ' WHERE P.ID_DTR_TRPRO = :ID_DTR ' +
    ' GROUP BY P.CODIGO_ALM_ORIGEN_TRPRO, P.CODIGO_ALM_DESTINO_TRPRO, ' +
    '          L.CODIGO_UNIDAD_TRPROLIN';
end;

function SqlCabecerasPropuestasTraspaso(const AFiltro: string): string;
begin
  Result :=
    'SELECT P.ID_TRPRO, P.ID_DTR_TRPRO, ' +
    '       COALESCE(DTR.TITULO_DTR, '''') AS TITULO_DTR, ' +
    '       P.INSTANTE_PROPUESTA_TRPRO, P.ESTADO_TRPRO, ' +
    '       P.CODIGO_ALM_ORIGEN_TRPRO, ' +
    '       COALESCE(AO.NOMBRE_ALM_ALM, '''') AS NOMBRE_ORIGEN, ' +
    '       P.CODIGO_ALM_DESTINO_TRPRO, ' +
    '       COALESCE(AD.NOMBRE_ALM_ALM, '''') AS NOMBRE_DESTINO, ' +
    '       COALESCE(P.TIPO_DOC_TRPRO, '''') AS TIPO_DOC_TRPRO, ' +
    '       COALESCE(P.SERIE_DOC_TRPRO, '''') AS SERIE_DOC_TRPRO, ' +
    '       COALESCE(P.NUMERO_DOC_TRPRO, '''') AS NUMERO_DOC_TRPRO, ' +
    '       COALESCE(P.NUMERO_OPERACION_TRPRO, '''') ' +
    '         AS NUMERO_OPERACION_TRPRO ' +
    '  FROM fza_traspasos_propuestas P ' +
    '  LEFT JOIN fza_documentos_trabajo DTR ' +
    '    ON DTR.ID_DTR = P.ID_DTR_TRPRO ' +
    '  LEFT JOIN fza_almacenes AO ' +
    '    ON AO.CODIGO_ALM_ALM = P.CODIGO_ALM_ORIGEN_TRPRO ' +
    '  LEFT JOIN fza_almacenes AD ' +
    '    ON AD.CODIGO_ALM_ALM = P.CODIGO_ALM_DESTINO_TRPRO ' +
    ' WHERE ' + AFiltro + ' ' +
    ' ORDER BY P.CODIGO_ALM_ORIGEN_TRPRO, P.CODIGO_ALM_DESTINO_TRPRO, ' +
    '          P.ID_TRPRO';
end;

function SqlLineasPropuestasTraspaso(const AFiltro: string): string;
begin
  Result :=
    'SELECT L.ID_TRPRO_TRPROLIN, L.CODIGO_ART_TRPROLIN, ' +
    '       COALESCE(L.DESCRIPCION_ARTICULO_TRPROLIN, '''') ' +
    '         AS DESCRIPCION_ARTICULO_TRPROLIN, ' +
    '       L.CODIGO_UNIDAD_TRPROLIN, L.CANTIDAD_TRPROLIN, ' +
    '       L.CANTIDAD_TRASPASADA_TRPROLIN, ' +
    SqlAtributosSku('L.CODIGO_UNIDAD_TRPROLIN', 'L.CODIGO_ART_TRPROLIN') +
    '  FROM fza_traspasos_propuestas_lineas L ' +
    '  JOIN fza_traspasos_propuestas P ' +
    '    ON P.ID_TRPRO = L.ID_TRPRO_TRPROLIN ' +
    ' WHERE ' + AFiltro + ' ' +
    ' ORDER BY L.ID_TRPRO_TRPROLIN, L.CODIGO_ART_TRPROLIN, COLOR, ' +
    '          ORDEN_TALLA, TALLA';
end;

function SqlBloquearPropuestasPendientes: string;
begin
  Result :=
    'SELECT P.ID_TRPRO, P.CODIGO_ALM_ORIGEN_TRPRO, ' +
    '       P.CODIGO_ALM_DESTINO_TRPRO ' +
    '  FROM fza_traspasos_propuestas P ' +
    ' WHERE P.ID_DTR_TRPRO = :ID_DTR ' +
    '   AND P.ESTADO_TRPRO = ''PENDIENTE'' ' +
    ' ORDER BY P.ID_TRPRO ' +
    '   FOR UPDATE';
end;

function SqlInsertarPropuestaTraspaso: string;
begin
  Result :=
    'INSERT INTO fza_traspasos_propuestas (' +
    '  ID_DTR_TRPRO, INSTANTE_PROPUESTA_TRPRO, ESTADO_TRPRO, ' +
    '  CODIGO_ALM_ORIGEN_TRPRO, CODIGO_ALM_DESTINO_TRPRO, ' +
    '  INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (' +
    '  :ID_DTR, NOW(), ''PENDIENTE'', :ORIGEN, :DESTINO, ' +
    '  NOW(), :USUARIO, :USUARIO)';
end;

// El artículo y su descripción salen de las líneas del documento: si el
// SKU ya no está en él, no se inserta nada y el llamante lo detecta.
function SqlInsertarLineaPropuestaTraspaso: string;
begin
  Result :=
    'INSERT INTO fza_traspasos_propuestas_lineas (' +
    '  ID_TRPRO_TRPROLIN, CODIGO_UNIDAD_TRPROLIN, CODIGO_ART_TRPROLIN, ' +
    '  DESCRIPCION_ARTICULO_TRPROLIN, CANTIDAD_TRPROLIN, ' +
    '  CANTIDAD_TRASPASADA_TRPROLIN, INSTANTE_ALTA, USUARIO_ALTA, ' +
    '  USUARIO_MODIF) ' +
    'SELECT :ID_TRPRO, MAX(DTL.CODIGO_UNIDAD_DTL), ' +
    '       MAX(DTL.CODIGO_ART_DTL), ' +
    '       MAX(DTL.DESCRIPCION_ARTICULO_DTL), :CANTIDAD, 0, NOW(), ' +
    '       :USUARIO, :USUARIO ' +
    '  FROM fza_documentos_trabajo_lineas DTL ' +
    ' WHERE DTL.ID_DTR_DTL = :ID_DTR ' +
    '   AND DTL.CODIGO_UNIDAD_DTL = :CODIGO_UNIDAD ' +
    'HAVING COUNT(*) > 0';
end;

function SqlBorrarLineasPropuestasPendientes: string;
begin
  Result :=
    'DELETE L ' +
    '  FROM fza_traspasos_propuestas_lineas L ' +
    '  JOIN fza_traspasos_propuestas P ' +
    '    ON P.ID_TRPRO = L.ID_TRPRO_TRPROLIN ' +
    ' WHERE P.ID_DTR_TRPRO = :ID_DTR ' +
    '   AND P.ESTADO_TRPRO = ''PENDIENTE''';
end;

function SqlBorrarPropuestasPendientesVacias: string;
begin
  Result :=
    'DELETE P ' +
    '  FROM fza_traspasos_propuestas P ' +
    ' WHERE P.ID_DTR_TRPRO = :ID_DTR ' +
    '   AND P.ESTADO_TRPRO = ''PENDIENTE'' ' +
    '   AND NOT EXISTS (SELECT 1 ' +
    '                     FROM fza_traspasos_propuestas_lineas L ' +
    '                    WHERE L.ID_TRPRO_TRPROLIN = P.ID_TRPRO)';
end;

// ===========================================================================
//   Repositorio
// ===========================================================================

function CrearRepositorioDistribucionTiendasUniDAC(
  AConexion: TUniConnection): IRepositorioDistribucionTiendas;
begin
  Result := TRepositorioDistribucionTiendasUniDAC.Create(AConexion);
end;

constructor TRepositorioDistribucionTiendasUniDAC.Create(
  AConexion: TUniConnection);
begin
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioDistribucionTiendasUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioDistribucionTiendasUniDAC.LeerTitulo(
  AConsulta: TUniQuery; AIdDocumento: Int64): string;
begin
  AConsulta.Close;
  AConsulta.SQL.Text :=
    'SELECT DTR.TITULO_DTR ' +
    '  FROM fza_documentos_trabajo DTR ' +
    ' WHERE DTR.ID_DTR = :ID_DTR';
  AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
  AConsulta.Open;
  if AConsulta.IsEmpty then
    raise EArgumentException.CreateFmt(
      SErrorDocumentoDistribucionNoExiste, [AIdDocumento]);
  Result := AConsulta.FieldByName('TITULO_DTR').AsString;
  AConsulta.Close;
end;

function TRepositorioDistribucionTiendasUniDAC.LeerUnidades(
  AConsulta: TUniQuery;
  AIdDocumento: Int64): TUnidadesDocumentoDistribucion;
var
  Lista: TList<TUnidadDocumentoDistribucion>;
  Unidad: TUnidadDocumentoDistribucion;
begin
  Lista := TList<TUnidadDocumentoDistribucion>.Create;
  try
    AConsulta.Close;
    AConsulta.SQL.Text := SqlUnidadesDocumentoDistribucion;
    AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    AConsulta.Open;
    while not AConsulta.Eof do
    begin
      Unidad.CodigoAlmacen := AConsulta.FieldByName('CODIGO_ALM').AsString;
      Unidad.CodigoArticulo :=
        AConsulta.FieldByName('CODIGO_ART').AsString;
      Unidad.DescripcionArticulo :=
        AConsulta.FieldByName('DESCRIPCION').AsString;
      Unidad.CodigoSku := AConsulta.FieldByName('CODIGO_UNIDAD').AsString;
      Unidad.Color := AConsulta.FieldByName('COLOR').AsString;
      Unidad.Talla := AConsulta.FieldByName('TALLA').AsString;
      Unidad.OrdenTalla := AConsulta.FieldByName('ORDEN_TALLA').AsInteger;
      Unidad.Cantidad := AConsulta.FieldByName('CANTIDAD').AsFloat;
      Lista.Add(Unidad);
      AConsulta.Next;
    end;
    AConsulta.Close;
    Result := Lista.ToArray;
  finally
    FreeAndNil(Lista);
  end;
end;

function TRepositorioDistribucionTiendasUniDAC.LeerAlmacenes(
  AConsulta: TUniQuery;
  AIdDocumento: Int64): TAlmacenesDistribucion;
var
  Lista: TList<TAlmacenDistribucion>;
  Almacen: TAlmacenDistribucion;
begin
  Lista := TList<TAlmacenDistribucion>.Create;
  try
    AConsulta.Close;
    AConsulta.SQL.Text := SqlAlmacenesDistribucion;
    AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    AConsulta.Open;
    while not AConsulta.Eof do
    begin
      Almacen.Codigo := AConsulta.FieldByName('CODIGO_ALM_ALM').AsString;
      Almacen.Nombre := AConsulta.FieldByName('NOMBRE_ALM_ALM').AsString;
      Almacen.Orden := AConsulta.FieldByName('ORDEN_ALM').AsInteger;
      Lista.Add(Almacen);
      AConsulta.Next;
    end;
    AConsulta.Close;
    Result := Lista.ToArray;
  finally
    FreeAndNil(Lista);
  end;
end;

function TRepositorioDistribucionTiendasUniDAC.LeerStocks(
  AConsulta: TUniQuery; AIdDocumento: Int64): TStocksDistribucion;
var
  Lista: TList<TStockDistribucion>;
  Stock: TStockDistribucion;
begin
  Lista := TList<TStockDistribucion>.Create;
  try
    AConsulta.Close;
    AConsulta.SQL.Text := SqlStocksDistribucion;
    AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    AConsulta.Open;
    while not AConsulta.Eof do
    begin
      Stock.CodigoAlmacen :=
        AConsulta.FieldByName('CODIGO_ALM_STK').AsString;
      Stock.CodigoSku := AConsulta.FieldByName('CODIGO_UNIDAD_STK').AsString;
      Stock.Cantidad := AConsulta.FieldByName('CANTIDAD').AsFloat;
      Lista.Add(Stock);
      AConsulta.Next;
    end;
    AConsulta.Close;
    Result := Lista.ToArray;
  finally
    FreeAndNil(Lista);
  end;
end;

function TRepositorioDistribucionTiendasUniDAC.LeerAsignaciones(
  AConsulta: TUniQuery;
  AIdDocumento: Int64): TAsignacionesDistribucion;
var
  Lista: TList<TAsignacionDistribucion>;
  Asignacion: TAsignacionDistribucion;
begin
  Lista := TList<TAsignacionDistribucion>.Create;
  try
    AConsulta.Close;
    AConsulta.SQL.Text := SqlAsignacionesDistribucion;
    AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    AConsulta.Open;
    while not AConsulta.Eof do
    begin
      Asignacion.AlmacenOrigen := AConsulta.FieldByName('ORIGEN').AsString;
      Asignacion.AlmacenDestino :=
        AConsulta.FieldByName('DESTINO').AsString;
      Asignacion.CodigoSku :=
        AConsulta.FieldByName('CODIGO_UNIDAD').AsString;
      Asignacion.CantidadConfirmada :=
        AConsulta.FieldByName('CONFIRMADA').AsFloat;
      Asignacion.CantidadPendiente :=
        AConsulta.FieldByName('PENDIENTE').AsFloat;
      Lista.Add(Asignacion);
      AConsulta.Next;
    end;
    AConsulta.Close;
    Result := Lista.ToArray;
  finally
    FreeAndNil(Lista);
  end;
end;

function TRepositorioDistribucionTiendasUniDAC.CargarDocumento(
  AIdDocumento: Int64): TDocumentoDistribucion;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TDocumentoDistribucion);
  oConsulta := NuevaConsulta;
  try
    Result.IdDocumento := AIdDocumento;
    Result.Titulo := LeerTitulo(oConsulta, AIdDocumento);
    Result.Unidades := LeerUnidades(oConsulta, AIdDocumento);
    Result.Almacenes := LeerAlmacenes(oConsulta, AIdDocumento);
    Result.Stocks := LeerStocks(oConsulta, AIdDocumento);
    Result.Asignaciones := LeerAsignaciones(oConsulta, AIdDocumento);
  finally
    FreeAndNil(oConsulta);
  end;
end;

// ===========================================================================
//   Propuestas: lectura
// ===========================================================================

procedure TRepositorioDistribucionTiendasUniDAC.LeerLineasPropuestas(
  AConsulta: TUniQuery;
  const AFiltro, AParametro: string;
  const AValor: Variant;
  var APropuestas: TPropuestasTraspaso);
var
  Indices: TDictionary<Int64, Integer>;
  Linea: TLineaPropuestaTraspaso;
  i, iPropuesta, iNueva: Integer;
begin
  Indices := TDictionary<Int64, Integer>.Create;
  try
    for i := 0 to High(APropuestas) do
      Indices.AddOrSetValue(APropuestas[i].IdPropuesta, i);
    AConsulta.Close;
    AConsulta.SQL.Text := SqlLineasPropuestasTraspaso(AFiltro);
    AConsulta.ParamByName(AParametro).Value := AValor;
    AConsulta.Open;
    while not AConsulta.Eof do
    begin
      if Indices.TryGetValue(
           AConsulta.FieldByName('ID_TRPRO_TRPROLIN').AsLargeInt,
           iPropuesta) then
      begin
        Linea.CodigoArticulo :=
          AConsulta.FieldByName('CODIGO_ART_TRPROLIN').AsString;
        Linea.DescripcionArticulo := AConsulta.FieldByName(
          'DESCRIPCION_ARTICULO_TRPROLIN').AsString;
        Linea.CodigoSku :=
          AConsulta.FieldByName('CODIGO_UNIDAD_TRPROLIN').AsString;
        Linea.Color := AConsulta.FieldByName('COLOR').AsString;
        Linea.Talla := AConsulta.FieldByName('TALLA').AsString;
        Linea.OrdenTalla :=
          AConsulta.FieldByName('ORDEN_TALLA').AsInteger;
        Linea.Cantidad :=
          AConsulta.FieldByName('CANTIDAD_TRPROLIN').AsFloat;
        Linea.CantidadTraspasada := AConsulta.FieldByName(
          'CANTIDAD_TRASPASADA_TRPROLIN').AsFloat;
        iNueva := Length(APropuestas[iPropuesta].Lineas);
        SetLength(APropuestas[iPropuesta].Lineas, iNueva + 1);
        APropuestas[iPropuesta].Lineas[iNueva] := Linea;
      end;
      AConsulta.Next;
    end;
    AConsulta.Close;
  finally
    FreeAndNil(Indices);
  end;
end;

function TRepositorioDistribucionTiendasUniDAC.LeerPropuestas(
  const AFiltro, AParametro: string;
  const AValor: Variant): TPropuestasTraspaso;
var
  oConsulta: TUniQuery;
  Lista: TList<TPropuestaTraspaso>;
  Propuesta: TPropuestaTraspaso;
begin
  oConsulta := NuevaConsulta;
  Lista := TList<TPropuestaTraspaso>.Create;
  try
    oConsulta.SQL.Text := SqlCabecerasPropuestasTraspaso(AFiltro);
    oConsulta.ParamByName(AParametro).Value := AValor;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      Propuesta := Default(TPropuestaTraspaso);
      Propuesta.IdPropuesta :=
        oConsulta.FieldByName('ID_TRPRO').AsLargeInt;
      Propuesta.IdDocumento :=
        oConsulta.FieldByName('ID_DTR_TRPRO').AsLargeInt;
      Propuesta.TituloDocumento :=
        oConsulta.FieldByName('TITULO_DTR').AsString;
      Propuesta.Instante :=
        oConsulta.FieldByName('INSTANTE_PROPUESTA_TRPRO').AsDateTime;
      Propuesta.Estado := oConsulta.FieldByName('ESTADO_TRPRO').AsString;
      Propuesta.AlmacenOrigen :=
        oConsulta.FieldByName('CODIGO_ALM_ORIGEN_TRPRO').AsString;
      Propuesta.NombreAlmacenOrigen :=
        oConsulta.FieldByName('NOMBRE_ORIGEN').AsString;
      Propuesta.AlmacenDestino :=
        oConsulta.FieldByName('CODIGO_ALM_DESTINO_TRPRO').AsString;
      Propuesta.NombreAlmacenDestino :=
        oConsulta.FieldByName('NOMBRE_DESTINO').AsString;
      Propuesta.TipoDocumento :=
        oConsulta.FieldByName('TIPO_DOC_TRPRO').AsString;
      Propuesta.SerieDocumento :=
        oConsulta.FieldByName('SERIE_DOC_TRPRO').AsString;
      Propuesta.NumeroDocumento :=
        oConsulta.FieldByName('NUMERO_DOC_TRPRO').AsString;
      Propuesta.NumeroOperacion :=
        oConsulta.FieldByName('NUMERO_OPERACION_TRPRO').AsString;
      Lista.Add(Propuesta);
      oConsulta.Next;
    end;
    Result := Lista.ToArray;
    LeerLineasPropuestas(oConsulta, AFiltro, AParametro, AValor, Result);
  finally
    FreeAndNil(Lista);
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioDistribucionTiendasUniDAC.ListarPropuestasDocumento(
  AIdDocumento: Int64): TPropuestasTraspaso;
begin
  Result := LeerPropuestas(
    FILTRO_PROPUESTAS_DOCUMENTO, 'ID_DTR', AIdDocumento);
end;

function TRepositorioDistribucionTiendasUniDAC.
  ListarPropuestasPendientesOrigen(
  const AAlmacenOrigen: string): TPropuestasTraspaso;
begin
  Result := LeerPropuestas(
    FILTRO_PROPUESTAS_PENDIENTES_ORIGEN, 'ORIGEN', AAlmacenOrigen);
end;

function TRepositorioDistribucionTiendasUniDAC.LeerPropuesta(
  AIdPropuesta: Int64): TPropuestaTraspaso;
var
  Propuestas: TPropuestasTraspaso;
begin
  Propuestas := LeerPropuestas(
    FILTRO_PROPUESTA_POR_ID, 'ID_TRPRO', AIdPropuesta);
  if Length(Propuestas) = 0 then
    raise EArgumentException.CreateFmt(
      SErrorPropuestaTraspasoNoExiste, [AIdPropuesta]);
  Result := Propuestas[0];
end;

// ===========================================================================
//   Propuestas: escritura
// ===========================================================================

procedure TRepositorioDistribucionTiendasUniDAC.
  ComprobarConfirmadoSinCambios(
  AConsulta: TUniQuery;
  AIdDocumento: Int64;
  const AAsignaciones: TAsignacionesDistribucion);
var
  Esperado: TDictionary<string, Double>;
  Actuales: TAsignacionesDistribucion;
  i: Integer;
  sClave: string;
  dEsperado, dTotalEsperado, dTotalActual: Double;
  bCoincide: Boolean;
begin
  Esperado := TDictionary<string, Double>.Create;
  try
    dTotalEsperado := 0;
    for i := 0 to High(AAsignaciones) do
    begin
      if AAsignaciones[i].CantidadConfirmada > TOLERANCIA_CANTIDAD then
      begin
        Esperado.AddOrSetValue(
          ClaveAsignacion(
            AAsignaciones[i].AlmacenOrigen,
            AAsignaciones[i].AlmacenDestino,
            AAsignaciones[i].CodigoSku),
          AAsignaciones[i].CantidadConfirmada);
        dTotalEsperado := dTotalEsperado +
          AAsignaciones[i].CantidadConfirmada;
      end;
    end;
    Actuales := LeerAsignaciones(AConsulta, AIdDocumento);
    bCoincide := True;
    dTotalActual := 0;
    for i := 0 to High(Actuales) do
    begin
      if Actuales[i].CantidadConfirmada > TOLERANCIA_CANTIDAD then
      begin
        sClave := ClaveAsignacion(
          Actuales[i].AlmacenOrigen,
          Actuales[i].AlmacenDestino,
          Actuales[i].CodigoSku);
        dTotalActual := dTotalActual + Actuales[i].CantidadConfirmada;
        if not Esperado.TryGetValue(sClave, dEsperado) or
           not SameValue(dEsperado, Actuales[i].CantidadConfirmada,
             TOLERANCIA_CANTIDAD) then
          bCoincide := False;
      end;
    end;
    if not bCoincide or
       not SameValue(dTotalEsperado, dTotalActual, TOLERANCIA_CANTIDAD) then
      raise EDistribucionTiendasDesactualizada.Create(
        SErrorDistribucionTiendasDesactualizada);
  finally
    FreeAndNil(Esperado);
  end;
end;

procedure TRepositorioDistribucionTiendasUniDAC.CargarPropuestasPendientes(
  AConsulta: TUniQuery;
  AIdDocumento: Int64;
  APendientes: TDictionary<string, Int64>);
begin
  AConsulta.Close;
  AConsulta.SQL.Text := SqlBloquearPropuestasPendientes;
  AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
  AConsulta.Open;
  while not AConsulta.Eof do
  begin
    // Si hubiera más de una pendiente para la pareja, vale la primera.
    if not APendientes.ContainsKey(ClavePareja(
         AConsulta.FieldByName('CODIGO_ALM_ORIGEN_TRPRO').AsString,
         AConsulta.FieldByName('CODIGO_ALM_DESTINO_TRPRO').AsString)) then
      APendientes.Add(
        ClavePareja(
          AConsulta.FieldByName('CODIGO_ALM_ORIGEN_TRPRO').AsString,
          AConsulta.FieldByName('CODIGO_ALM_DESTINO_TRPRO').AsString),
        AConsulta.FieldByName('ID_TRPRO').AsLargeInt);
    AConsulta.Next;
  end;
  AConsulta.Close;
end;

function TRepositorioDistribucionTiendasUniDAC.AsegurarPropuestaPendiente(
  AConsulta: TUniQuery;
  AIdDocumento: Int64;
  const AAsignacion: TAsignacionDistribucion;
  const AUsuario: string;
  APendientes: TDictionary<string, Int64>): Int64;
var
  sClave: string;
begin
  sClave := ClavePareja(
    AAsignacion.AlmacenOrigen, AAsignacion.AlmacenDestino);
  if not APendientes.TryGetValue(sClave, Result) then
  begin
    AConsulta.Close;
    AConsulta.SQL.Text := SqlInsertarPropuestaTraspaso;
    AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    AConsulta.ParamByName('ORIGEN').AsString :=
      Trim(AAsignacion.AlmacenOrigen);
    AConsulta.ParamByName('DESTINO').AsString :=
      Trim(AAsignacion.AlmacenDestino);
    AConsulta.ParamByName('USUARIO').AsString := AUsuario;
    AConsulta.Execute;
    AConsulta.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID_TRPRO';
    AConsulta.Open;
    Result := AConsulta.FieldByName('ID_TRPRO').AsLargeInt;
    AConsulta.Close;
    APendientes.Add(sClave, Result);
  end;
end;

procedure TRepositorioDistribucionTiendasUniDAC.InsertarLinea(
  AConsulta: TUniQuery;
  AIdDocumento, AIdPropuesta: Int64;
  const AAsignacion: TAsignacionDistribucion;
  const AUsuario: string);
begin
  AConsulta.Close;
  AConsulta.SQL.Text := SqlInsertarLineaPropuestaTraspaso;
  AConsulta.ParamByName('ID_TRPRO').AsLargeInt := AIdPropuesta;
  AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
  AConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
    Trim(AAsignacion.CodigoSku);
  AConsulta.ParamByName('CANTIDAD').AsFloat :=
    AAsignacion.CantidadPendiente;
  AConsulta.ParamByName('USUARIO').AsString := AUsuario;
  AConsulta.Execute;
  if AConsulta.RowsAffected <> 1 then
    raise EInvalidOpException.CreateFmt(
      SErrorSkuDistribucionFueraDocumento, [AAsignacion.CodigoSku]);
end;

// Las líneas de las propuestas pendientes se rehacen enteras: son pocas y
// así lo guardado es exactamente lo que se ve en el cuadrante.
procedure TRepositorioDistribucionTiendasUniDAC.SincronizarPropuestas(
  AConsulta: TUniQuery;
  AIdDocumento: Int64;
  const AAsignaciones: TAsignacionesDistribucion;
  const AUsuario: string);
var
  Pendientes: TDictionary<string, Int64>;
  i: Integer;
begin
  Pendientes := TDictionary<string, Int64>.Create;
  try
    CargarPropuestasPendientes(AConsulta, AIdDocumento, Pendientes);
    ComprobarConfirmadoSinCambios(AConsulta, AIdDocumento, AAsignaciones);
    AConsulta.Close;
    AConsulta.SQL.Text := SqlBorrarLineasPropuestasPendientes;
    AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    AConsulta.Execute;
    for i := 0 to High(AAsignaciones) do
    begin
      if AAsignaciones[i].CantidadPendiente > TOLERANCIA_CANTIDAD then
        InsertarLinea(
          AConsulta,
          AIdDocumento,
          AsegurarPropuestaPendiente(
            AConsulta, AIdDocumento, AAsignaciones[i], AUsuario,
            Pendientes),
          AAsignaciones[i],
          AUsuario);
    end;
    AConsulta.Close;
    AConsulta.SQL.Text := SqlBorrarPropuestasPendientesVacias;
    AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    AConsulta.Execute;
  finally
    FreeAndNil(Pendientes);
  end;
end;

procedure TRepositorioDistribucionTiendasUniDAC.GuardarPropuestas(
  AIdDocumento: Int64;
  const AAsignaciones: TAsignacionesDistribucion;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
  bTransaccionPropia: Boolean;
begin
  oConsulta := NuevaConsulta;
  try
    bTransaccionPropia := not FConexion.InTransaction;
    if bTransaccionPropia then
      FConexion.StartTransaction;
    try
      SincronizarPropuestas(
        oConsulta, AIdDocumento, AAsignaciones, AUsuario);
      if bTransaccionPropia then
        FConexion.Commit;
    except
      if bTransaccionPropia then
        FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioDistribucionTiendasUniDAC.EliminarPropuestaPendiente(
  AIdPropuesta: Int64): Boolean;
var
  oConsulta: TUniQuery;
  bTransaccionPropia: Boolean;
begin
  oConsulta := NuevaConsulta;
  try
    bTransaccionPropia := not FConexion.InTransaction;
    if bTransaccionPropia then
      FConexion.StartTransaction;
    try
      // La cabecera se borra primero y con el estado en el predicado: si
      // entre tanto se confirmó, no se toca nada.
      oConsulta.SQL.Text :=
        'DELETE FROM fza_traspasos_propuestas ' +
        ' WHERE ID_TRPRO = :ID_TRPRO ' +
        '   AND ESTADO_TRPRO = ''PENDIENTE''';
      oConsulta.ParamByName('ID_TRPRO').AsLargeInt := AIdPropuesta;
      oConsulta.Execute;
      Result := oConsulta.RowsAffected = 1;
      if Result then
      begin
        oConsulta.SQL.Text :=
          'DELETE FROM fza_traspasos_propuestas_lineas ' +
          ' WHERE ID_TRPRO_TRPROLIN = :ID_TRPRO';
        oConsulta.ParamByName('ID_TRPRO').AsLargeInt := AIdPropuesta;
        oConsulta.Execute;
      end;
      if bTransaccionPropia then
        FConexion.Commit;
    except
      if bTransaccionPropia then
        FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
