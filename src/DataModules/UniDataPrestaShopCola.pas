{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPrestaShopCola                                        }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       2.0.0                                                         }
{   Fecha:       13/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Persiste eventos por artículo y obtiene su estado actual al reclamarlo.   }
{******************************************************************************}
unit UniDataPrestaShopCola;

interface

uses
  Uni, inLibPrestaShopColaIntf;

function CrearRepositorioPrestaShopColaUniDAC(
  AConexion: TUniConnection): IRepositorioPrestaShopCola;

implementation

uses
  System.Math, System.SysUtils, Data.DB;

type
  TRepositorioPrestaShopColaUniDAC = class(
    TInterfacedObject,
    IRepositorioPrestaShopCola)
  private
    FConexion: TUniConnection;
    function CrearToken: string;
    function NuevaConsulta: TUniQuery;
    function PrecioSinIva(
      APrecio, APorcentajeIva: Double;
      AEsImpuestoIncluido: Boolean): Double;
    procedure CargarLineas(
      const AConfiguracion: TConfiguracionPrestaShopCola;
      var ATrabajo: TTrabajoArticuloPrestaShop);
    procedure CargarPrecioProducto(
      const AConfiguracion: TConfiguracionPrestaShopCola;
      var ATrabajo: TTrabajoArticuloPrestaShop);
  public
    constructor Create(AConexion: TUniConnection);
    procedure EncolarCambio(
      const ACodigoArticulo, ACodigoUnidad: string;
      AEsPrecio, AEsStock: Boolean;
      const AUsuario: string);
    function LeerConfiguracionGlobal:
      TConfiguracionGlobalPrestaShop;
    procedure ReconciliarSiProcede(
      AHoras: Integer;
      AStockActivo: Boolean;
      const AUsuario: string);
    procedure ReencolarProcesandoCaducadas(
      const AClaveInstalacion: string;
      AIdTienda: Integer;
      AMinutos: Integer);
    function BuscarPendientes(
      const AClaveInstalacion: string;
      AIdTienda: Integer;
      AMaximo: Integer): TArray<Int64>;
    function MarcarProcesando(
      AIdCola: Int64;
      const AClaveInstalacion: string;
      AIdTienda: Integer;
      const AUsuario: string;
      out AToken: string): Boolean;
    function LeerTrabajo(
      AIdCola: Int64;
      const AToken: string;
      const AConfiguracion: TConfiguracionPrestaShopCola):
      TTrabajoArticuloPrestaShop;
    function RenovarReclamacion(
      AIdCola: Int64;
      const AToken: string): Boolean;
    procedure MarcarEnviada(
      AIdCola: Int64;
      const AToken, AUsuario: string;
      ATieneProximoPrecio: Boolean;
      AProximoPrecio: TDateTime);
    procedure GuardarErrorIntento(
      AIdCola: Int64;
      const AToken, AEstado: string;
      AEsperaSegundos: Integer;
      const AMensaje, AUsuario: string);
  end;

const
  SQL_PRECIO_PRODUCTO =
    'SELECT CASE WHEN ((COALESCE(tp.PORCENTAJE_DTO_ARTTAR, 0) <> 0 ' +
    'OR COALESCE(tp.PRECIO_DTO_ARTTAR, 0) <> 0) AND ' +
    '((tar.FECHA_DESDE_DTO_TAR IS NOT NULL AND ' +
    'tar.FECHA_DESDE_DTO_TAR > CURDATE()) OR ' +
    '(tar.FECHA_HASTA_DTO_TAR IS NOT NULL AND ' +
    'tar.FECHA_HASTA_DTO_TAR < CURDATE()))) ' +
    'THEN tp.PRECIO_SALIDA_ARTTAR ' +
    'ELSE tp.PRECIO_FINAL_ARTTAR END AS PRECIO_BRUTO, ' +
    'tar.ESIMP_INCL_TAR, CASE a.TIPO_IVA_ART ' +
    'WHEN ''N'' THEN iva.PORCENTAJE_NORMAL_IVA ' +
    'WHEN ''R'' THEN iva.PORCENTAJE_REDUCIDO_IVA ' +
    'WHEN ''S'' THEN iva.PORCENTAJE_SUPERREDUCIDO_IVA ' +
    'WHEN ''E'' THEN iva.PORCENTAJE_EXENTO_IVA ' +
    'ELSE NULL END AS PORCENTAJE_IVA ' +
    'FROM fza_articulos a ' +
    'JOIN fza_empresas emp ' +
    'ON emp.CODIGO_EMP_EMP = :EMPRESA ' +
    'AND emp.ESACTIVO_EMP = ''S'' ' +
    'JOIN fza_tarifas tar ' +
    'ON tar.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND tar.ESACTIVO_ARTTAR = ''S'' ' +
    'LEFT JOIN fza_ivas iva ON iva.CODIGO_IVA = (' +
    'SELECT iv2.CODIGO_IVA FROM fza_ivas iv2 ' +
    'WHERE iv2.IVA_IVAGRP = emp.GRUPO_ZONA_IVA_EMP ' +
    'AND iv2.FECHA_DESDE_IVA <= CURDATE() ' +
    'AND (iv2.FECHA_HASTA_IVA IS NULL ' +
    'OR iv2.FECHA_HASTA_IVA >= CURDATE()) ' +
    'ORDER BY iv2.FECHA_DESDE_IVA DESC, ' +
    'iv2.CODIGO_IVA DESC LIMIT 1) ' +
    'LEFT JOIN fza_articulos_tarifas tp ' +
    'ON tp.CODIGO_UNICO_ARTTAR = (' +
    'SELECT t.CODIGO_UNICO_ARTTAR FROM fza_articulos_tarifas t ' +
    'WHERE t.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
    'AND t.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND t.ESACTIVO_ARTTAR = ''S'' ' +
    'AND COALESCE(t.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    'AND (t.FECHA_DESDE_ARTTAR IS NULL ' +
    'OR t.FECHA_DESDE_ARTTAR <= CURDATE()) ' +
    'AND (t.FECHA_HASTA_ARTTAR IS NULL ' +
    'OR t.FECHA_HASTA_ARTTAR >= CURDATE()) ' +
    'ORDER BY t.INSTANTE_MODIF DESC, ' +
    't.CODIGO_UNICO_ARTTAR DESC LIMIT 1) ' +
    'WHERE a.CODIGO_ART_ART = :ARTICULO ' +
    'AND a.ESWEB_ART = ''S''';
  SQL_LINEAS =
    'SELECT COALESCE(s.CODIGO_UNIDAD_SKU, ' +
    'a.CODIGO_ART_ART) AS CODIGO_SKU, ' +
    'a.ESACTIVO_ART, COALESCE(s.ESACTIVO_SKU, ' +
    'a.ESACTIVO_ART) AS ESACTIVO_SKU, a.ESVARIACION_ART, ' +
    'a.TIPO_ART, CASE WHEN s.CODIGO_UNIDAD_SKU IS NULL ' +
    'THEN ''N'' ELSE ''S'' END AS ESSKU_REAL, ' +
    'CASE WHEN ((COALESCE(te.PORCENTAJE_DTO_ARTTAR, 0) <> 0 ' +
    'OR COALESCE(te.PRECIO_DTO_ARTTAR, 0) <> 0) AND ' +
    '((tar.FECHA_DESDE_DTO_TAR IS NOT NULL AND ' +
    'tar.FECHA_DESDE_DTO_TAR > CURDATE()) OR ' +
    '(tar.FECHA_HASTA_DTO_TAR IS NOT NULL AND ' +
    'tar.FECHA_HASTA_DTO_TAR < CURDATE()))) ' +
    'THEN te.PRECIO_SALIDA_ARTTAR ' +
    'ELSE te.PRECIO_FINAL_ARTTAR END AS PRECIO_SKU_BRUTO, ' +
    'tar.ESIMP_INCL_TAR, CASE a.TIPO_IVA_ART ' +
    'WHEN ''N'' THEN iva.PORCENTAJE_NORMAL_IVA ' +
    'WHEN ''R'' THEN iva.PORCENTAJE_REDUCIDO_IVA ' +
    'WHEN ''S'' THEN iva.PORCENTAJE_SUPERREDUCIDO_IVA ' +
    'WHEN ''E'' THEN iva.PORCENTAJE_EXENTO_IVA ' +
    'ELSE NULL END AS PORCENTAJE_IVA, ' +
    'CASE WHEN a.ESACTIVO_ART <> ''S'' ' +
    'OR COALESCE(s.ESACTIVO_SKU, a.ESACTIVO_ART) <> ''S'' THEN 0 ' +
    'ELSE COALESCE((SELECT FLOOR(GREATEST(' +
    'SUM(COALESCE(st.CANTIDAD_STK, 0)), 0)) ' +
    'FROM fza_articulos_stockactual st ' +
    'JOIN fza_almacenes alm ' +
    'ON alm.CODIGO_ALM_ALM = st.CODIGO_ALM_STK ' +
    'AND alm.CODIGO_EMP_ALM = :EMPRESA ' +
    'AND alm.ESWEB_ALM = ''S'' ' +
    'AND alm.ESACTIVO_ALM = ''S'' ' +
    'AND alm.ESFISICO_ALM = ''S'' ' +
    'AND UPPER(TRIM(alm.TIPO_USO_ALM)) = ''ESTANDAR'' ' +
    'WHERE st.CODIGO_UNIDAD_STK = ' +
    'COALESCE(s.CODIGO_UNIDAD_SKU, a.CODIGO_ART_ART)), 0) ' +
    'END AS CANTIDAD_STOCK ' +
    'FROM fza_articulos a ' +
    'LEFT JOIN fza_articulos_skus s ' +
    'ON s.CODIGO_ART_SKU = a.CODIGO_ART_ART ' +
    'AND a.ESVARIACION_ART = ''S'' ' +
    'LEFT JOIN fza_empresas emp ' +
    'ON emp.CODIGO_EMP_EMP = :EMPRESA ' +
    'AND emp.ESACTIVO_EMP = ''S'' ' +
    'LEFT JOIN fza_tarifas tar ' +
    'ON tar.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND tar.ESACTIVO_ARTTAR = ''S'' ' +
    'LEFT JOIN fza_ivas iva ON iva.CODIGO_IVA = (' +
    'SELECT iv2.CODIGO_IVA FROM fza_ivas iv2 ' +
    'WHERE iv2.IVA_IVAGRP = emp.GRUPO_ZONA_IVA_EMP ' +
    'AND iv2.FECHA_DESDE_IVA <= CURDATE() ' +
    'AND (iv2.FECHA_HASTA_IVA IS NULL ' +
    'OR iv2.FECHA_HASTA_IVA >= CURDATE()) ' +
    'ORDER BY iv2.FECHA_DESDE_IVA DESC, ' +
    'iv2.CODIGO_IVA DESC LIMIT 1) ' +
    'LEFT JOIN fza_articulos_tarifas te ' +
    'ON te.CODIGO_UNICO_ARTTAR = (' +
    'SELECT t.CODIGO_UNICO_ARTTAR FROM fza_articulos_tarifas t ' +
    'WHERE t.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
    'AND t.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND t.ESACTIVO_ARTTAR = ''S'' AND (' +
    't.CODIGO_UNIDAD_ARTTAR = ' +
    'COALESCE(s.CODIGO_UNIDAD_SKU, a.CODIGO_ART_ART) OR (' +
    'COALESCE(t.CODIGO_UNIDAD_ARTTAR, '''') <> '''' AND ' +
    'LEFT(COALESCE(s.CODIGO_UNIDAD_SKU, a.CODIGO_ART_ART), ' +
    'CHAR_LENGTH(t.CODIGO_UNIDAD_ARTTAR) + 1) = ' +
    'CONCAT(t.CODIGO_UNIDAD_ARTTAR, ''/'')) OR ' +
    'COALESCE(t.CODIGO_UNIDAD_ARTTAR, '''') = '''') ' +
    'AND (t.FECHA_DESDE_ARTTAR IS NULL ' +
    'OR t.FECHA_DESDE_ARTTAR <= CURDATE()) ' +
    'AND (t.FECHA_HASTA_ARTTAR IS NULL ' +
    'OR t.FECHA_HASTA_ARTTAR >= CURDATE()) ' +
    'ORDER BY CASE WHEN t.CODIGO_UNIDAD_ARTTAR = ' +
    'COALESCE(s.CODIGO_UNIDAD_SKU, a.CODIGO_ART_ART) THEN 0 ' +
    'WHEN COALESCE(t.CODIGO_UNIDAD_ARTTAR, '''') <> '''' ' +
    'THEN 1 ELSE 2 END, ' +
    'CHAR_LENGTH(t.CODIGO_UNIDAD_ARTTAR) DESC, ' +
    't.INSTANTE_MODIF DESC, t.CODIGO_UNICO_ARTTAR DESC LIMIT 1) ' +
    'WHERE a.CODIGO_ART_ART = :ARTICULO ' +
    'AND a.ESWEB_ART = ''S'' ' +
    'ORDER BY CODIGO_SKU';
  SQL_PROXIMO_PRECIO =
    'SELECT MIN(x.FRONTERA) AS FRONTERA FROM (' +
    'SELECT t.FECHA_DESDE_ARTTAR AS FRONTERA ' +
    'FROM fza_articulos_tarifas t ' +
    'WHERE t.CODIGO_ART_ARTTAR = :ARTICULO ' +
    'AND t.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND t.ESACTIVO_ARTTAR = ''S'' ' +
    'AND t.FECHA_DESDE_ARTTAR > CURDATE() ' +
    'UNION ALL SELECT DATE_ADD(t.FECHA_HASTA_ARTTAR, ' +
    'INTERVAL 1 DAY) FROM fza_articulos_tarifas t ' +
    'WHERE t.CODIGO_ART_ARTTAR = :ARTICULO ' +
    'AND t.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND t.ESACTIVO_ARTTAR = ''S'' ' +
    'AND t.FECHA_HASTA_ARTTAR >= CURDATE() ' +
    'UNION ALL SELECT tar.FECHA_DESDE_DTO_TAR ' +
    'FROM fza_tarifas tar ' +
    'WHERE tar.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND tar.ESACTIVO_ARTTAR = ''S'' ' +
    'AND tar.FECHA_DESDE_DTO_TAR > CURDATE() ' +
    'UNION ALL SELECT DATE_ADD(tar.FECHA_HASTA_DTO_TAR, ' +
    'INTERVAL 1 DAY) FROM fza_tarifas tar ' +
    'WHERE tar.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND tar.ESACTIVO_ARTTAR = ''S'' ' +
    'AND tar.FECHA_HASTA_DTO_TAR >= CURDATE() ' +
    'UNION ALL SELECT iva.FECHA_DESDE_IVA ' +
    'FROM fza_ivas iva JOIN fza_empresas emp ' +
    'ON emp.CODIGO_EMP_EMP = :EMPRESA ' +
    'AND emp.ESACTIVO_EMP = ''S'' ' +
    'AND iva.IVA_IVAGRP = emp.GRUPO_ZONA_IVA_EMP ' +
    'WHERE iva.FECHA_DESDE_IVA > CURDATE() ' +
    'UNION ALL SELECT DATE_ADD(iva.FECHA_HASTA_IVA, ' +
    'INTERVAL 1 DAY) FROM fza_ivas iva ' +
    'JOIN fza_empresas emp ' +
    'ON emp.CODIGO_EMP_EMP = :EMPRESA ' +
    'AND emp.ESACTIVO_EMP = ''S'' ' +
    'AND iva.IVA_IVAGRP = emp.GRUPO_ZONA_IVA_EMP ' +
    'WHERE iva.FECHA_HASTA_IVA >= CURDATE()) x ' +
    'WHERE EXISTS (SELECT 1 FROM fza_tarifas tar_ok ' +
    'WHERE tar_ok.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND tar_ok.ESACTIVO_ARTTAR = ''S'') ' +
    'AND EXISTS (SELECT 1 FROM fza_empresas emp_ok ' +
    'WHERE emp_ok.CODIGO_EMP_EMP = :EMPRESA ' +
    'AND emp_ok.ESACTIVO_EMP = ''S'')';

constructor TRepositorioPrestaShopColaUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioPrestaShopColaUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioPrestaShopColaUniDAC.CrearToken: string;
var
  oGuid: TGUID;
  sGuid: string;
begin
  CreateGUID(oGuid);
  sGuid := GUIDToString(oGuid);
  Result := Copy(sGuid, 2, 36);
end;

function TRepositorioPrestaShopColaUniDAC.PrecioSinIva(
  APrecio, APorcentajeIva: Double;
  AEsImpuestoIncluido: Boolean): Double;
begin
  Result := APrecio;
  if AEsImpuestoIncluido then
    Result := APrecio / (1 + (APorcentajeIva / 100));
  Result := SimpleRoundTo(Result, -6);
end;

procedure TRepositorioPrestaShopColaUniDAC.EncolarCambio(
  const ACodigoArticulo, ACodigoUnidad: string;
  AEsPrecio, AEsStock: Boolean;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  if (Trim(ACodigoArticulo) = '') and
     (Trim(ACodigoUnidad) = '') then
    raise EArgumentException.Create(
      'El cambio PrestaShop no identifica artículo ni unidad');
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'CALL PRC_PRESTASHOP_ENCOLAR_CAMBIO(' +
      ':ARTICULO, :UNIDAD, :PRECIO, :STOCK, :USUARIO)';
    oConsulta.ParamByName('ARTICULO').AsString :=
      Trim(ACodigoArticulo);
    oConsulta.ParamByName('UNIDAD').AsString :=
      Trim(ACodigoUnidad);
    if AEsPrecio then
      oConsulta.ParamByName('PRECIO').AsString := 'S'
    else
      oConsulta.ParamByName('PRECIO').AsString := 'N';
    if AEsStock then
      oConsulta.ParamByName('STOCK').AsString := 'S'
    else
      oConsulta.ParamByName('STOCK').AsString := 'N';
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioPrestaShopColaUniDAC.LeerConfiguracionGlobal:
  TConfiguracionGlobalPrestaShop;
var
  oConsulta: TUniQuery;

  function Valor(const ACampo, ADefecto: string): string;
  begin
    Result := ADefecto;
    if not oConsulta.FieldByName(ACampo).IsNull then
      Result := oConsulta.FieldByName(ACampo).AsString;
  end;

begin
  Result := Default(TConfiguracionGlobalPrestaShop);
  Result.SegundosCiclo := 60;
  Result.HorasBarrido := 24;
  Result.MaxIntentos := 10;
  Result.Cola.CodigoEmpresa := '1';
  Result.Cola.CodigoTarifa := 'PVP';
  Result.Cola.IdTienda := 1;
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT ' +
      'MAX(CASE WHEN SUBKEY_USUPER = ''appPrestaShopActivo'' ' +
      'THEN VALUE_USUPER END) AS ACTIVO, ' +
      'MAX(CASE WHEN SUBKEY_USUPER = ''appPrestaShopStockActivo'' ' +
      'THEN VALUE_USUPER END) AS STOCK_ACTIVO, ' +
      'MAX(CASE WHEN SUBKEY_USUPER = ''appPrestaShopUrl'' ' +
      'THEN VALUE_USUPER END) AS URL_API, ' +
      'MAX(CASE WHEN SUBKEY_USUPER = ''appPrestaShopApiKey'' ' +
      'THEN VALUE_USUPER END) AS CLAVE_API, ' +
      'MAX(CASE WHEN SUBKEY_USUPER = ''appPrestaShopEmpresa'' ' +
      'THEN VALUE_USUPER END) AS EMPRESA, ' +
      'MAX(CASE WHEN SUBKEY_USUPER = ''appPrestaShopTarifa'' ' +
      'THEN VALUE_USUPER END) AS TARIFA, ' +
      'MAX(CASE WHEN SUBKEY_USUPER = ''appPrestaShopIdTienda'' ' +
      'THEN VALUE_USUPER END) AS TIENDA, ' +
      'MAX(CASE WHEN SUBKEY_USUPER = ''appPrestaShopSegundosCiclo'' ' +
      'THEN VALUE_USUPER END) AS SEGUNDOS, ' +
      'MAX(CASE WHEN SUBKEY_USUPER = ''appPrestaShopHorasBarrido'' ' +
      'THEN VALUE_USUPER END) AS HORAS_BARRIDO, ' +
      'MAX(CASE WHEN SUBKEY_USUPER = ''appPrestaShopMaxIntentos'' ' +
      'THEN VALUE_USUPER END) AS INTENTOS ' +
      'FROM fza_usuarios_perfiles ' +
      'WHERE USUARIO_GRUPO_USUPER = ''Todos'' ' +
      'AND KEY_USUPER = ''frmMtoAppParam'' ' +
      'AND SUBKEY_USUPER LIKE ''appPrestaShop%''';
    oConsulta.Open;
    Result.Activo := SameText(Valor('ACTIVO', 'False'), 'True') or
      (Valor('ACTIVO', '0') = '1');
    Result.Cola.StockActivo :=
      SameText(Valor('STOCK_ACTIVO', 'False'), 'True') or
      (Valor('STOCK_ACTIVO', '0') = '1');
    Result.UrlApi := Trim(Valor(
      'URL_API',
      'https://www.martamere.com/api'));
    Result.ClaveApi := Trim(Valor('CLAVE_API', ''));
    Result.Cola.CodigoEmpresa := Trim(Valor('EMPRESA', '1'));
    Result.Cola.CodigoTarifa := Trim(Valor('TARIFA', 'PVP'));
    Result.Cola.IdTienda := StrToIntDef(Valor('TIENDA', '1'), 1);
    Result.SegundosCiclo :=
      StrToIntDef(Valor('SEGUNDOS', '60'), 60);
    Result.HorasBarrido :=
      StrToIntDef(Valor('HORAS_BARRIDO', '24'), 24);
    Result.MaxIntentos :=
      StrToIntDef(Valor('INTENTOS', '10'), 10);
    if Result.SegundosCiclo < 5 then
      Result.SegundosCiclo := 5;
    if Result.HorasBarrido < 1 then
      Result.HorasBarrido := 1;
    if Result.HorasBarrido > 720 then
      Result.HorasBarrido := 720;
    if Result.MaxIntentos < 1 then
      Result.MaxIntentos := 1;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioPrestaShopColaUniDAC.ReconciliarSiProcede(
  AHoras: Integer;
  AStockActivo: Boolean;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'CALL PRC_PRESTASHOP_RECONCILIAR(' +
      ':HORAS, :STOCK, :USUARIO)';
    oConsulta.ParamByName('HORAS').AsInteger := AHoras;
    if AStockActivo then
      oConsulta.ParamByName('STOCK').AsString := 'S'
    else
      oConsulta.ParamByName('STOCK').AsString := 'N';
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioPrestaShopColaUniDAC.
  ReencolarProcesandoCaducadas(
  const AClaveInstalacion: string;
  AIdTienda: Integer;
  AMinutos: Integer);
var
  oConsulta: TUniQuery;
begin
  if AMinutos <= 0 then
    raise EArgumentOutOfRangeException.Create('AMinutos');
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'UPDATE fza_prestashop_cola SET ' +
      'ESTADO_PSCOLA = ''PENDIENTE'', ' +
      'VERSION_RECLAMADA_PSCOLA = NULL, ' +
      'ESCAMBIO_PRECIO_RECLAMADO_PSCOLA = ''N'', ' +
      'ESCAMBIO_STOCK_RECLAMADO_PSCOLA = ''N'', ' +
      'ID_RECLAMACION_PSCOLA = NULL, ' +
      'INSTANTE_RECLAMACION_PSCOLA = NULL, ' +
      'INSTANTE_PROXIMO_INTENTO_PSCOLA = NULL, ' +
      'INSTANTE_MODIF = NOW() ' +
      'WHERE CLAVE_INSTALACION_PSCOLA = :INSTALACION ' +
      'AND ID_TIENDA_PSCOLA = :TIENDA ' +
      'AND ESTADO_PSCOLA = ''PROCESANDO'' ' +
      'AND (INSTANTE_RECLAMACION_PSCOLA IS NULL OR ' +
      'INSTANTE_RECLAMACION_PSCOLA < ' +
      'DATE_SUB(NOW(), INTERVAL :MINUTOS MINUTE))';
    oConsulta.ParamByName('INSTALACION').AsString :=
      AClaveInstalacion;
    oConsulta.ParamByName('TIENDA').AsInteger := AIdTienda;
    oConsulta.ParamByName('MINUTOS').AsInteger := AMinutos;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioPrestaShopColaUniDAC.BuscarPendientes(
  const AClaveInstalacion: string;
  AIdTienda: Integer;
  AMaximo: Integer): TArray<Int64>;
var
  iFila: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  if AMaximo > 0 then
  begin
    oConsulta := NuevaConsulta;
    try
      oConsulta.SQL.Text :=
        'SELECT ID_PSCOLA FROM fza_prestashop_cola ' +
        'WHERE CLAVE_INSTALACION_PSCOLA = :INSTALACION ' +
        'AND ID_TIENDA_PSCOLA = :TIENDA ' +
        'AND ESTADO_PSCOLA = ''PENDIENTE'' ' +
        'AND (INSTANTE_PROXIMO_INTENTO_PSCOLA IS NULL OR ' +
        'INSTANTE_PROXIMO_INTENTO_PSCOLA <= NOW()) ' +
        'ORDER BY ID_PSCOLA LIMIT :MAXIMO';
      oConsulta.ParamByName('INSTALACION').AsString :=
        AClaveInstalacion;
      oConsulta.ParamByName('TIENDA').AsInteger := AIdTienda;
      oConsulta.ParamByName('MAXIMO').AsInteger := AMaximo;
      oConsulta.Open;
      SetLength(Result, oConsulta.RecordCount);
      iFila := 0;
      while not oConsulta.Eof do
      begin
        Result[iFila] :=
          oConsulta.FieldByName('ID_PSCOLA').AsLargeInt;
        Inc(iFila);
        oConsulta.Next;
      end;
      SetLength(Result, iFila);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioPrestaShopColaUniDAC.MarcarProcesando(
  AIdCola: Int64;
  const AClaveInstalacion: string;
  AIdTienda: Integer;
  const AUsuario: string;
  out AToken: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  AToken := CrearToken;
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'UPDATE fza_prestashop_cola SET ' +
      'ESTADO_PSCOLA = ''PROCESANDO'', ' +
      'VERSION_RECLAMADA_PSCOLA = VERSION_DESEADA_PSCOLA, ' +
      'ESCAMBIO_PRECIO_RECLAMADO_PSCOLA = ' +
      'ESCAMBIO_PRECIO_PSCOLA, ' +
      'ESCAMBIO_STOCK_RECLAMADO_PSCOLA = ' +
      'ESCAMBIO_STOCK_PSCOLA, ' +
      'ID_RECLAMACION_PSCOLA = :TOKEN, ' +
      'INSTANTE_RECLAMACION_PSCOLA = NOW(), ' +
      'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      'WHERE ID_PSCOLA = :ID ' +
      'AND CLAVE_INSTALACION_PSCOLA = :INSTALACION ' +
      'AND ID_TIENDA_PSCOLA = :TIENDA ' +
      'AND ESTADO_PSCOLA = ''PENDIENTE'' ' +
      'AND (INSTANTE_PROXIMO_INTENTO_PSCOLA IS NULL OR ' +
      'INSTANTE_PROXIMO_INTENTO_PSCOLA <= NOW())';
    oConsulta.ParamByName('TOKEN').AsString := AToken;
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.ParamByName('ID').AsLargeInt := AIdCola;
    oConsulta.ParamByName('INSTALACION').AsString :=
      AClaveInstalacion;
    oConsulta.ParamByName('TIENDA').AsInteger := AIdTienda;
    oConsulta.Execute;
    Result := oConsulta.RowsAffected = 1;
    if not Result then
      AToken := '';
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioPrestaShopColaUniDAC.CargarPrecioProducto(
  const AConfiguracion: TConfiguracionPrestaShopCola;
  var ATrabajo: TTrabajoArticuloPrestaShop);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text := SQL_PROXIMO_PRECIO;
    oConsulta.ParamByName('EMPRESA').AsString :=
      AConfiguracion.CodigoEmpresa;
    oConsulta.ParamByName('TARIFA').AsString :=
      AConfiguracion.CodigoTarifa;
    oConsulta.ParamByName('ARTICULO').AsString :=
      ATrabajo.CodigoArticulo;
    oConsulta.Open;
    ATrabajo.TieneProximoCambioPrecio :=
      not oConsulta.FieldByName('FRONTERA').IsNull;
    if ATrabajo.TieneProximoCambioPrecio then
      ATrabajo.ProximoCambioPrecio :=
        oConsulta.FieldByName('FRONTERA').AsDateTime;
    oConsulta.Close;
    oConsulta.SQL.Text := SQL_PRECIO_PRODUCTO;
    oConsulta.ParamByName('EMPRESA').AsString :=
      AConfiguracion.CodigoEmpresa;
    oConsulta.ParamByName('TARIFA').AsString :=
      AConfiguracion.CodigoTarifa;
    oConsulta.ParamByName('ARTICULO').AsString :=
      ATrabajo.CodigoArticulo;
    oConsulta.Open;
    if oConsulta.IsEmpty or
       oConsulta.FieldByName('PRECIO_BRUTO').IsNull then
    begin
      if not ATrabajo.TieneProximoCambioPrecio then
        raise EDatabaseError.CreateFmt(
          'El artículo %s no tiene un precio web válido',
          [ATrabajo.CodigoArticulo]);
    end
    else
    begin
      if (oConsulta.FieldByName('ESIMP_INCL_TAR').AsString = 'S') and
         oConsulta.FieldByName('PORCENTAJE_IVA').IsNull then
        raise EDatabaseError.CreateFmt(
          'El artículo %s no tiene un tipo de IVA válido',
          [ATrabajo.CodigoArticulo]);
      ATrabajo.TienePrecioProducto := True;
      ATrabajo.PrecioProducto := PrecioSinIva(
        oConsulta.FieldByName('PRECIO_BRUTO').AsFloat,
        oConsulta.FieldByName('PORCENTAJE_IVA').AsFloat,
        oConsulta.FieldByName('ESIMP_INCL_TAR').AsString = 'S');
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioPrestaShopColaUniDAC.CargarLineas(
  const AConfiguracion: TConfiguracionPrestaShopCola;
  var ATrabajo: TTrabajoArticuloPrestaShop);
var
  bActiva: Boolean;
  bEsCombinacion: Boolean;
  iLinea: Integer;
  oConsulta: TUniQuery;
  oLinea: TLineaArticuloPrestaShop;
begin
  SetLength(ATrabajo.Lineas, 0);
  oConsulta := NuevaConsulta;
  try
    if ATrabajo.TieneStock then
    begin
      oConsulta.SQL.Text :=
        'SELECT COUNT(*) AS NUMERO_ALMACENES ' +
        'FROM fza_almacenes ' +
        'WHERE CODIGO_EMP_ALM = :EMPRESA ' +
        'AND ESWEB_ALM = ''S'' ' +
        'AND ESACTIVO_ALM = ''S'' ' +
        'AND ESFISICO_ALM = ''S'' ' +
        'AND UPPER(TRIM(TIPO_USO_ALM)) = ''ESTANDAR''';
      oConsulta.ParamByName('EMPRESA').AsString :=
        AConfiguracion.CodigoEmpresa;
      oConsulta.Open;
      if oConsulta.FieldByName('NUMERO_ALMACENES').AsInteger = 0 then
        raise EDatabaseError.CreateFmt(
          'La empresa %s no tiene almacenes web activos, físicos y estándar',
          [AConfiguracion.CodigoEmpresa]);
      oConsulta.Close;
    end;
    oConsulta.SQL.Text := SQL_LINEAS;
    oConsulta.ParamByName('EMPRESA').AsString :=
      AConfiguracion.CodigoEmpresa;
    oConsulta.ParamByName('TARIFA').AsString :=
      AConfiguracion.CodigoTarifa;
    oConsulta.ParamByName('ARTICULO').AsString :=
      ATrabajo.CodigoArticulo;
    oConsulta.Open;
    iLinea := 0;
    while not oConsulta.Eof do
    begin
      oLinea := Default(TLineaArticuloPrestaShop);
      oLinea.CodigoSku :=
        oConsulta.FieldByName('CODIGO_SKU').AsString;
      if (oConsulta.FieldByName('ESVARIACION_ART').AsString = 'S') and
         ((oConsulta.FieldByName('ESSKU_REAL').AsString <> 'S') or
          SameText(oLinea.CodigoSku, ATrabajo.CodigoArticulo)) then
        raise EDatabaseError.CreateFmt(
          'El artículo variable %s no tiene SKU diferenciados válidos',
          [ATrabajo.CodigoArticulo]);
      bEsCombinacion :=
        (oConsulta.FieldByName('ESVARIACION_ART').AsString = 'S') and
        (oConsulta.FieldByName('ESSKU_REAL').AsString = 'S') and
        (not SameText(oLinea.CodigoSku, ATrabajo.CodigoArticulo));
      bActiva :=
        (oConsulta.FieldByName('ESACTIVO_ART').AsString = 'S') and
        (oConsulta.FieldByName('ESACTIVO_SKU').AsString = 'S');
      oLinea.EsCombinacion := bEsCombinacion;
      oLinea.TieneStock := ATrabajo.TieneStock and
        (oConsulta.FieldByName('TIPO_ART').AsString <> 'SERVICIO');
      if oLinea.TieneStock then
        oLinea.Cantidad :=
          oConsulta.FieldByName('CANTIDAD_STOCK').AsInteger;
      oLinea.TienePrecio := ATrabajo.TienePrecio and
        bEsCombinacion and bActiva and
        (not oConsulta.FieldByName('PRECIO_SKU_BRUTO').IsNull);
      if oLinea.TienePrecio then
      begin
        if (oConsulta.FieldByName('ESIMP_INCL_TAR').AsString = 'S') and
           oConsulta.FieldByName('PORCENTAJE_IVA').IsNull then
          raise EDatabaseError.CreateFmt(
            'El artículo %s no tiene un tipo de IVA válido',
            [ATrabajo.CodigoArticulo]);
        oLinea.Precio := PrecioSinIva(
          oConsulta.FieldByName('PRECIO_SKU_BRUTO').AsFloat,
          oConsulta.FieldByName('PORCENTAJE_IVA').AsFloat,
          oConsulta.FieldByName('ESIMP_INCL_TAR').AsString = 'S');
      end;
      if oLinea.TienePrecio or oLinea.TieneStock then
      begin
        SetLength(ATrabajo.Lineas, iLinea + 1);
        ATrabajo.Lineas[iLinea] := oLinea;
        Inc(iLinea);
      end;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioPrestaShopColaUniDAC.LeerTrabajo(
  AIdCola: Int64;
  const AToken: string;
  const AConfiguracion: TConfiguracionPrestaShopCola):
  TTrabajoArticuloPrestaShop;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TTrabajoArticuloPrestaShop);
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT c.ID_PSCOLA, c.ID_TIENDA_PSCOLA, ' +
      'c.CODIGO_ART_PSCOLA, c.CONTADOR_INTENTOS_PSCOLA, ' +
      'c.VERSION_RECLAMADA_PSCOLA, ' +
      'c.ESCAMBIO_PRECIO_RECLAMADO_PSCOLA, ' +
      'c.ESCAMBIO_STOCK_RECLAMADO_PSCOLA, ' +
      'c.ID_RECLAMACION_PSCOLA, a.ESWEB_ART, a.TIPO_ART ' +
      'FROM fza_prestashop_cola c ' +
      'LEFT JOIN fza_articulos a ' +
      'ON a.CODIGO_ART_ART = c.CODIGO_ART_PSCOLA ' +
      'WHERE c.ID_PSCOLA = :ID ' +
      'AND c.CLAVE_INSTALACION_PSCOLA = :INSTALACION ' +
      'AND c.ID_TIENDA_PSCOLA = :TIENDA ' +
      'AND c.ID_RECLAMACION_PSCOLA = :TOKEN ' +
      'AND c.ESTADO_PSCOLA = ''PROCESANDO''';
    oConsulta.ParamByName('ID').AsLargeInt := AIdCola;
    oConsulta.ParamByName('INSTALACION').AsString :=
      AConfiguracion.ClaveInstalacion;
    oConsulta.ParamByName('TIENDA').AsInteger :=
      AConfiguracion.IdTienda;
    oConsulta.ParamByName('TOKEN').AsString := AToken;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result.IdCola :=
        oConsulta.FieldByName('ID_PSCOLA').AsLargeInt;
      Result.IdTienda :=
        oConsulta.FieldByName('ID_TIENDA_PSCOLA').AsInteger;
      Result.Intentos := oConsulta.FieldByName(
        'CONTADOR_INTENTOS_PSCOLA').AsInteger;
      Result.VersionReclamada := oConsulta.FieldByName(
        'VERSION_RECLAMADA_PSCOLA').AsLargeInt;
      Result.CodigoArticulo := oConsulta.FieldByName(
        'CODIGO_ART_PSCOLA').AsString;
      Result.Token := oConsulta.FieldByName(
        'ID_RECLAMACION_PSCOLA').AsString;
      Result.EstaEnWeb :=
        oConsulta.FieldByName('ESWEB_ART').AsString = 'S';
      Result.EsServicio := SameText(
        oConsulta.FieldByName('TIPO_ART').AsString,
        'SERVICIO');
      Result.TienePrecio := oConsulta.FieldByName(
        'ESCAMBIO_PRECIO_RECLAMADO_PSCOLA').AsString = 'S';
      Result.TieneStock := oConsulta.FieldByName(
        'ESCAMBIO_STOCK_RECLAMADO_PSCOLA').AsString = 'S';
      Result.TieneStock := Result.TieneStock and
        AConfiguracion.StockActivo and
        (not Result.EsServicio);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
  if (Result.IdCola > 0) and Result.EstaEnWeb then
  begin
    if Result.TienePrecio then
      CargarPrecioProducto(AConfiguracion, Result);
    if (Result.TienePrecio and Result.TienePrecioProducto) or
       Result.TieneStock then
      CargarLineas(AConfiguracion, Result);
    if Result.TieneStock and (Length(Result.Lineas) = 0) then
      raise EDatabaseError.CreateFmt(
        'El artículo %s no tiene unidades válidas para sincronizar stock',
        [Result.CodigoArticulo]);
  end;
end;

function TRepositorioPrestaShopColaUniDAC.RenovarReclamacion(
  AIdCola: Int64;
  const AToken: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'UPDATE fza_prestashop_cola ' +
      'SET INSTANTE_RECLAMACION_PSCOLA = NOW() ' +
      'WHERE ID_PSCOLA = :ID ' +
      'AND ID_RECLAMACION_PSCOLA = :TOKEN ' +
      'AND ESTADO_PSCOLA = ''PROCESANDO'' ' +
      'AND VERSION_DESEADA_PSCOLA = VERSION_RECLAMADA_PSCOLA';
    oConsulta.ParamByName('ID').AsLargeInt := AIdCola;
    oConsulta.ParamByName('TOKEN').AsString := AToken;
    oConsulta.Execute;
    Result := oConsulta.RowsAffected = 1;
    if not Result then
    begin
      oConsulta.SQL.Text :=
        'SELECT COUNT(*) AS NUMERO_FILAS ' +
        'FROM fza_prestashop_cola ' +
        'WHERE ID_PSCOLA = :ID ' +
        'AND ID_RECLAMACION_PSCOLA = :TOKEN ' +
        'AND ESTADO_PSCOLA = ''PROCESANDO'' ' +
        'AND VERSION_DESEADA_PSCOLA = VERSION_RECLAMADA_PSCOLA';
      oConsulta.ParamByName('ID').AsLargeInt := AIdCola;
      oConsulta.ParamByName('TOKEN').AsString := AToken;
      oConsulta.Open;
      Result := oConsulta.FieldByName('NUMERO_FILAS').AsInteger = 1;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioPrestaShopColaUniDAC.MarcarEnviada(
  AIdCola: Int64;
  const AToken, AUsuario: string;
  ATieneProximoPrecio: Boolean;
  AProximoPrecio: TDateTime);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'UPDATE fza_prestashop_cola SET ' +
      'ESTADO_PSCOLA = CASE WHEN VERSION_DESEADA_PSCOLA <> ' +
      'VERSION_RECLAMADA_PSCOLA THEN ''PENDIENTE'' ' +
      'WHEN :PROGRAMAR = ''S'' THEN ''PENDIENTE'' ' +
      'ELSE ''ENVIADA'' END, ' +
      'ESCAMBIO_PRECIO_PSCOLA = CASE WHEN VERSION_DESEADA_PSCOLA = ' +
      'VERSION_RECLAMADA_PSCOLA AND :PROGRAMAR = ''S'' THEN ''S'' ' +
      'WHEN VERSION_DESEADA_PSCOLA = VERSION_RECLAMADA_PSCOLA ' +
      'THEN ''N'' ' +
      'ELSE ESCAMBIO_PRECIO_PSCOLA END, ' +
      'ESCAMBIO_STOCK_PSCOLA = CASE WHEN VERSION_DESEADA_PSCOLA = ' +
      'VERSION_RECLAMADA_PSCOLA THEN ''N'' ' +
      'ELSE ESCAMBIO_STOCK_PSCOLA END, ' +
      'CONTADOR_INTENTOS_PSCOLA = 0, ' +
      'INSTANTE_PROXIMO_INTENTO_PSCOLA = CASE ' +
      'WHEN VERSION_DESEADA_PSCOLA <> VERSION_RECLAMADA_PSCOLA ' +
      'THEN NULL WHEN :PROGRAMAR = ''S'' THEN :PROXIMO ' +
      'ELSE NULL END, ' +
      'MENSAJE_ERROR_PSCOLA = NULL, ' +
      'INSTANTE_ULTIMO_ENVIO_PSCOLA = NOW(), ' +
      'VERSION_DESEADA_PSCOLA = CASE ' +
      'WHEN VERSION_DESEADA_PSCOLA = VERSION_RECLAMADA_PSCOLA ' +
      'AND :PROGRAMAR = ''S'' THEN VERSION_DESEADA_PSCOLA + 1 ' +
      'ELSE VERSION_DESEADA_PSCOLA END, ' +
      'VERSION_RECLAMADA_PSCOLA = NULL, ' +
      'ESCAMBIO_PRECIO_RECLAMADO_PSCOLA = ''N'', ' +
      'ESCAMBIO_STOCK_RECLAMADO_PSCOLA = ''N'', ' +
      'ID_RECLAMACION_PSCOLA = NULL, ' +
      'INSTANTE_RECLAMACION_PSCOLA = NULL, ' +
      'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      'WHERE ID_PSCOLA = :ID ' +
      'AND ID_RECLAMACION_PSCOLA = :TOKEN ' +
      'AND ESTADO_PSCOLA = ''PROCESANDO''';
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    if ATieneProximoPrecio then
      oConsulta.ParamByName('PROGRAMAR').AsString := 'S'
    else
      oConsulta.ParamByName('PROGRAMAR').AsString := 'N';
    oConsulta.ParamByName('PROXIMO').DataType := ftDateTime;
    if ATieneProximoPrecio then
      oConsulta.ParamByName('PROXIMO').AsDateTime := AProximoPrecio
    else
      oConsulta.ParamByName('PROXIMO').Clear;
    oConsulta.ParamByName('ID').AsLargeInt := AIdCola;
    oConsulta.ParamByName('TOKEN').AsString := AToken;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioPrestaShopColaUniDAC.GuardarErrorIntento(
  AIdCola: Int64;
  const AToken, AEstado: string;
  AEsperaSegundos: Integer;
  const AMensaje, AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  if (AEstado <> 'PENDIENTE') and (AEstado <> 'ERROR') then
    raise EArgumentException.Create(
      'Estado de reintento PrestaShop no válido');
  if AEsperaSegundos < 0 then
    raise EArgumentOutOfRangeException.Create('AEsperaSegundos');
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'UPDATE fza_prestashop_cola SET ' +
      'ESTADO_PSCOLA = CASE WHEN VERSION_DESEADA_PSCOLA = ' +
      'VERSION_RECLAMADA_PSCOLA THEN :ESTADO ' +
      'ELSE ''PENDIENTE'' END, ' +
      'CONTADOR_INTENTOS_PSCOLA = CASE ' +
      'WHEN VERSION_DESEADA_PSCOLA = VERSION_RECLAMADA_PSCOLA ' +
      'THEN CONTADOR_INTENTOS_PSCOLA + 1 ELSE 0 END, ' +
      'INSTANTE_PROXIMO_INTENTO_PSCOLA = CASE ' +
      'WHEN VERSION_DESEADA_PSCOLA = VERSION_RECLAMADA_PSCOLA ' +
      'AND :ESTADO = ''PENDIENTE'' THEN ' +
      'DATE_ADD(NOW(), INTERVAL :ESPERA SECOND) ELSE NULL END, ' +
      'MENSAJE_ERROR_PSCOLA = CASE ' +
      'WHEN VERSION_DESEADA_PSCOLA = VERSION_RECLAMADA_PSCOLA ' +
      'THEN :MENSAJE ELSE NULL END, ' +
      'VERSION_RECLAMADA_PSCOLA = NULL, ' +
      'ESCAMBIO_PRECIO_RECLAMADO_PSCOLA = ''N'', ' +
      'ESCAMBIO_STOCK_RECLAMADO_PSCOLA = ''N'', ' +
      'ID_RECLAMACION_PSCOLA = NULL, ' +
      'INSTANTE_RECLAMACION_PSCOLA = NULL, ' +
      'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      'WHERE ID_PSCOLA = :ID ' +
      'AND ID_RECLAMACION_PSCOLA = :TOKEN ' +
      'AND ESTADO_PSCOLA = ''PROCESANDO''';
    oConsulta.ParamByName('ESTADO').AsString := AEstado;
    oConsulta.ParamByName('ESPERA').AsInteger := AEsperaSegundos;
    oConsulta.ParamByName('MENSAJE').AsMemo := AMensaje;
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.ParamByName('ID').AsLargeInt := AIdCola;
    oConsulta.ParamByName('TOKEN').AsString := AToken;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioPrestaShopColaUniDAC(
  AConexion: TUniConnection): IRepositorioPrestaShopCola;
begin
  Result := TRepositorioPrestaShopColaUniDAC.Create(AConexion);
end;

end.
