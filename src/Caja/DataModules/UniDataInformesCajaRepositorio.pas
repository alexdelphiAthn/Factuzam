{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataInformesCajaRepositorio                               }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       FactuZam                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC de los informes historicos de caja.                   }
{******************************************************************************}
unit UniDataInformesCajaRepositorio;

interface

uses
  Uni, inLibInformesCajaPersistenciaIntf;

function CrearRepositorioInformesCajaUniDAC(
  AConexion: TUniConnection): IRepositorioInformesCaja;

implementation

uses
  System.SysUtils, System.Classes, Data.DB,
  UniDataRectificativasSql;

type
  TResultadoInformeCajaUniDAC = class(
    TInterfacedObject,
    IResultadoInformeCaja)
  private
    FDataSet: TDataSet;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioInformesCajaUniDAC = class(
    TInterfacedObject,
    IRepositorioInformesCaja)
  private
    FConexion: TUniConnection;
    function EjecutarInforme(
      const ASql: string;
      const ASolicitud: TSolicitudInformeCaja
    ): IResultadoInformeCaja;
    function ConstruirFiltroUbicaciones(
      const AUbicaciones: TUbicacionesInformeCaja): string;
    function ConstruirSqlOperacionesVenta(
      const AFiltroUbicaciones: string): string;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarArqueos(
      const ASolicitud: TSolicitudInformeCaja
    ): IResultadoInformeCaja;
    function ConsultarDepositos(
      const ASolicitud: TSolicitudInformeCaja
    ): IResultadoInformeCaja;
    function ConsultarOperaciones(
      const ASolicitud: TSolicitudInformeCaja
    ): IResultadoInformeCaja;
    function ListarFormasPago(
      const ASolicitud: TSolicitudInformeCaja
    ): TFormasPagoInformeCaja;
    function ConsultarPagos(
      const ASolicitud: TSolicitudInformeCaja;
      const ACodigosFormaPago: TCodigosFormaPagoInformeCaja
    ): IResultadoInformeCaja;
    function ListarUbicaciones: TUbicacionesInformeCaja;
    function ConsultarOperacionesVenta(
      const ASolicitud: TSolicitudOperacionesVentaCaja
    ): IResultadoInformeCaja;
    function ConsultarArqueosHistorico(
      const AEmpresa, AAlmacen, ACaja: string
    ): IResultadoInformeCaja;
    function ConsultarValesPendientes(
      const AFiltro, APin: string;
      AUsarCaducidad: Boolean
    ): IResultadoInformeCaja;
  end;

constructor TResultadoInformeCajaUniDAC.Create(ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TResultadoInformeCajaUniDAC.Destroy;
begin
  FreeAndNil(FDataSet);
  inherited;
end;

function TResultadoInformeCajaUniDAC.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

constructor TRepositorioInformesCajaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioInformesCajaUniDAC.EjecutarInforme(
  const ASql: string;
  const ASolicitud: TSolicitudInformeCaja
): IResultadoInformeCaja;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('EMPRESA').AsString := ASolicitud.Empresa;
    oConsulta.ParamByName('ALMACEN').AsString := ASolicitud.Almacen;
    oConsulta.ParamByName('CAJA').AsString := ASolicitud.Caja;
    oConsulta.ParamByName('DESDE').AsDateTime := ASolicitud.FechaDesde;
    oConsulta.ParamByName('HASTA').AsDateTime := ASolicitud.FechaHasta;
    oConsulta.Open;
    Result := TResultadoInformeCajaUniDAC.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformesCajaUniDAC.ConsultarArqueos(
  const ASolicitud: TSolicitudInformeCaja
): IResultadoInformeCaja;
begin
  Result := EjecutarInforme(
    'SELECT * ' +
    '  FROM fza_caja_arqueos ' +
    ' WHERE CODIGO_EMP_ARQ = :EMPRESA ' +
    '   AND CODIGO_ALM_ARQ = :ALMACEN ' +
    '   AND CODIGO_CAJA_ARQ = :CAJA ' +
    '   AND FECHA_DESDE_ARQ >= :DESDE ' +
    '   AND FECHA_DESDE_ARQ < DATE_ADD(:HASTA, INTERVAL 1 DAY) ' +
    ' ORDER BY FECHA_DESDE_ARQ DESC, CODIGO_ARQ DESC',
    ASolicitud);
end;

function TRepositorioInformesCajaUniDAC.ConsultarDepositos(
  const ASolicitud: TSolicitudInformeCaja
): IResultadoInformeCaja;
begin
  Result := EjecutarInforme(
    'SELECT * ' +
    '  FROM fza_depositos_cliente ' +
    ' WHERE CODIGO_EMP_DEP = :EMPRESA ' +
    '   AND CODIGO_ALM_DEP = :ALMACEN ' +
    '   AND CODIGO_CAJA_DEP = :CAJA ' +
    '   AND DATE(FECHA_CREACION_DEP) BETWEEN :DESDE AND :HASTA ' +
    ' ORDER BY FECHA_CREACION_DEP, ID_DEPOSITO_DEP',
    ASolicitud);
end;

function TRepositorioInformesCajaUniDAC.ConsultarOperaciones(
  const ASolicitud: TSolicitudInformeCaja
): IResultadoInformeCaja;
begin
  Result := EjecutarInforme(
    'SELECT * ' +
    '  FROM fza_caja_operaciones ' +
    ' WHERE CODIGO_EMP_OPCAJA = :EMPRESA ' +
    '   AND CODIGO_ALM_OPCAJA = :ALMACEN ' +
    '   AND CODIGO_CAJA_OPCAJA = :CAJA ' +
    '   AND DATE(FECHA_OPERACION_OPCAJA) BETWEEN :DESDE AND :HASTA ' +
    ' ORDER BY FECHA_OPERACION_OPCAJA, NUMERO_OPERACION_OPCAJA',
    ASolicitud);
end;

function TRepositorioInformesCajaUniDAC.ListarFormasPago(
  const ASolicitud: TSolicitudInformeCaja
): TFormasPagoInformeCaja;
var
  oConsulta: TUniQuery;
  iFormaPago: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT DISTINCT p.CODIGO_FP_CFP AS COD, ' +
      '       COALESCE(fp.DESCRIPCION_FORMA_PAGO_FP, ' +
      '                p.CODIGO_FP_CFP) AS DESCR ' +
      '  FROM vi_caja_pagos p ' +
      '  LEFT JOIN fza_formas_pago fp ' +
      '    ON fp.CODIGO_FP_FP = p.CODIGO_FP_CFP ' +
      ' WHERE p.CODIGO_EMP_PAGO = :EMPRESA ' +
      '   AND p.CODIGO_ALM_PAGO = :ALMACEN ' +
      '   AND p.CODIGO_CAJA_PAGO = :CAJA ' +
      '   AND DATE(p.FECHA_PAGO) BETWEEN :DESDE AND :HASTA ' +
      ' ORDER BY COD';
    oConsulta.ParamByName('EMPRESA').AsString := ASolicitud.Empresa;
    oConsulta.ParamByName('ALMACEN').AsString := ASolicitud.Almacen;
    oConsulta.ParamByName('CAJA').AsString := ASolicitud.Caja;
    oConsulta.ParamByName('DESDE').AsDateTime := ASolicitud.FechaDesde;
    oConsulta.ParamByName('HASTA').AsDateTime := ASolicitud.FechaHasta;
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iFormaPago := 0;
    while not oConsulta.Eof do
    begin
      Result[iFormaPago].Codigo :=
        oConsulta.FieldByName('COD').AsString;
      Result[iFormaPago].Descripcion :=
        oConsulta.FieldByName('DESCR').AsString;
      Inc(iFormaPago);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformesCajaUniDAC.ConsultarPagos(
  const ASolicitud: TSolicitudInformeCaja;
  const ACodigosFormaPago: TCodigosFormaPagoInformeCaja
): IResultadoInformeCaja;
var
  Codigo: string;
  oConsulta: TUniQuery;
  iCodigo: Integer;
  sFiltro: string;
begin
  sFiltro := '';
  iCodigo := 0;
  for Codigo in ACodigosFormaPago do
  begin
    if sFiltro <> '' then
    begin
      sFiltro := sFiltro + ', ';
    end;
    sFiltro := sFiltro + ':FP' + IntToStr(iCodigo);
    Inc(iCodigo);
  end;
  if sFiltro <> '' then
  begin
    sFiltro := ' AND CODIGO_FP_CFP IN (' + sFiltro + ')';
  end;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT * ' +
      '  FROM vi_caja_pagos ' +
      ' WHERE CODIGO_EMP_PAGO = :EMPRESA ' +
      '   AND CODIGO_ALM_PAGO = :ALMACEN ' +
      '   AND CODIGO_CAJA_PAGO = :CAJA ' +
      '   AND DATE(FECHA_PAGO) BETWEEN :DESDE AND :HASTA ' +
      sFiltro +
      ' ORDER BY FECHA_PAGO, NUMERO_OPERACION_PAGO, ' +
      '          NUMERO_LINEA_PAGO';
    oConsulta.ParamByName('EMPRESA').AsString := ASolicitud.Empresa;
    oConsulta.ParamByName('ALMACEN').AsString := ASolicitud.Almacen;
    oConsulta.ParamByName('CAJA').AsString := ASolicitud.Caja;
    oConsulta.ParamByName('DESDE').AsDateTime := ASolicitud.FechaDesde;
    oConsulta.ParamByName('HASTA').AsDateTime := ASolicitud.FechaHasta;
    for iCodigo := 0 to High(ACodigosFormaPago) do
    begin
      oConsulta.ParamByName('FP' + IntToStr(iCodigo)).AsString :=
        ACodigosFormaPago[iCodigo];
    end;
    oConsulta.Open;
    Result := TResultadoInformeCajaUniDAC.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformesCajaUniDAC.ListarUbicaciones:
  TUbicacionesInformeCaja;
var
  oConsulta: TUniQuery;
  iUbicacion: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT Empresa, NombreEmpresa, Almacen, ' +
      '       `NombreAlmacén`, Caja, NombreCaja ' +
      '  FROM vi_cajasdef ' +
      ' ORDER BY Empresa, Almacen, Caja';
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iUbicacion := 0;
    while not oConsulta.Eof do
    begin
      Result[iUbicacion].Empresa :=
        oConsulta.FieldByName('Empresa').AsString;
      Result[iUbicacion].NombreEmpresa :=
        oConsulta.FieldByName('NombreEmpresa').AsString;
      Result[iUbicacion].Almacen :=
        oConsulta.FieldByName('Almacen').AsString;
      Result[iUbicacion].NombreAlmacen :=
        oConsulta.FieldByName('NombreAlmacén').AsString;
      Result[iUbicacion].Caja :=
        oConsulta.FieldByName('Caja').AsString;
      Result[iUbicacion].NombreCaja :=
        oConsulta.FieldByName('NombreCaja').AsString;
      Inc(iUbicacion);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformesCajaUniDAC.ConstruirFiltroUbicaciones(
  const AUbicaciones: TUbicacionesInformeCaja): string;
var
  iUbicacion: Integer;
  sSufijo: string;
begin
  Result := '   AND (';
  for iUbicacion := 0 to High(AUbicaciones) do
  begin
    if iUbicacion > 0 then
    begin
      Result := Result + sLineBreak + '        OR ';
    end;
    sSufijo := IntToStr(iUbicacion);
    Result := Result +
      '(o.CODIGO_EMP_OPCAJA = :pEMPRESA' + sSufijo +
      ' AND o.CODIGO_ALM_OPCAJA = :pALMACEN' + sSufijo +
      ' AND o.CODIGO_CAJA_OPCAJA = :pCAJA' + sSufijo + ')';
  end;
  Result := Result + ')';
end;

function TRepositorioInformesCajaUniDAC.ConstruirSqlOperacionesVenta(
  const AFiltroUbicaciones: string): string;
var
  slSQL: TStringList;

  procedure Anadir(const ALinea: string);
  begin
    slSQL.Add(ALinea);
  end;

begin
  slSQL := TStringList.Create;
  try
    Anadir('SELECT DATE(o.FECHA_OPERACION_OPCAJA) AS FECHA_DIA,');
    Anadir('       DATE(:pDESDE) AS FECHA_DESDE,');
    Anadir('       DATE(:pHASTA) AS FECHA_HASTA,');
    Anadir('       o.CODIGO_EMP_OPCAJA,');
    Anadir('       o.CODIGO_ALM_OPCAJA,');
    Anadir('       o.CODIGO_CAJA_OPCAJA,');
    Anadir('       CONCAT(o.CODIGO_EMP_OPCAJA, ''/'',');
    Anadir('              o.CODIGO_ALM_OPCAJA, ''/'',');
    Anadir('              o.CODIGO_CAJA_OPCAJA) AS CLAVE_CAJA,');
    Anadir('       o.NUMERO_OPERACION_OPCAJA,');
    Anadir('       fl.LINEA_FACLIN,');
    Anadir('       fl.CODIGO_ART_FACLIN AS ARTICULO,');
    Anadir('       COALESCE(');
    Anadir('         NULLIF(CASE');
    Anadir('           WHEN UPPER(fl.ATTR1_NOMBRE_FACLIN) LIKE ''%COLOR%''');
    Anadir('             THEN fl.ATTR1_VALOR_FACLIN');
    Anadir('           WHEN UPPER(fl.ATTR2_NOMBRE_FACLIN) LIKE ''%COLOR%''');
    Anadir('             THEN fl.ATTR2_VALOR_FACLIN');
    Anadir('           WHEN UPPER(fl.ATTR3_NOMBRE_FACLIN) LIKE ''%COLOR%''');
    Anadir('             THEN fl.ATTR3_VALOR_FACLIN');
    Anadir('           WHEN UPPER(fl.ATTR4_NOMBRE_FACLIN) LIKE ''%COLOR%''');
    Anadir('             THEN fl.ATTR4_VALOR_FACLIN');
    Anadir('           WHEN UPPER(fl.ATTR5_NOMBRE_FACLIN) LIKE ''%COLOR%''');
    Anadir('             THEN fl.ATTR5_VALOR_FACLIN');
    Anadir('           ELSE ''''');
    Anadir('         END, ''''),');
    Anadir('         CASE');
    Anadir('           WHEN LENGTH(fl.CODIGO_UNIDAD_FACLIN) -');
    Anadir('                LENGTH(REPLACE(fl.CODIGO_UNIDAD_FACLIN,');
    Anadir('                               ''/'', '''')) >= 1');
    Anadir('             THEN SUBSTRING_INDEX(SUBSTRING_INDEX(');
    Anadir('                    fl.CODIGO_UNIDAD_FACLIN, ''/'', 2),');
    Anadir('                    ''/'', -1)');
    Anadir('           ELSE ''''');
    Anadir('         END, '''') AS COLOR,');
    Anadir('       COALESCE(cb.HEX_COLOR_BASICO, '''')');
    Anadir('         AS HEX_COLOR_BASICO,');
    Anadir('       COALESCE(');
    Anadir('         NULLIF(CASE');
    Anadir('           WHEN UPPER(fl.ATTR1_NOMBRE_FACLIN) LIKE ''%TALLA%''');
    Anadir('             THEN fl.ATTR1_VALOR_FACLIN');
    Anadir('           WHEN UPPER(fl.ATTR2_NOMBRE_FACLIN) LIKE ''%TALLA%''');
    Anadir('             THEN fl.ATTR2_VALOR_FACLIN');
    Anadir('           WHEN UPPER(fl.ATTR3_NOMBRE_FACLIN) LIKE ''%TALLA%''');
    Anadir('             THEN fl.ATTR3_VALOR_FACLIN');
    Anadir('           WHEN UPPER(fl.ATTR4_NOMBRE_FACLIN) LIKE ''%TALLA%''');
    Anadir('             THEN fl.ATTR4_VALOR_FACLIN');
    Anadir('           WHEN UPPER(fl.ATTR5_NOMBRE_FACLIN) LIKE ''%TALLA%''');
    Anadir('             THEN fl.ATTR5_VALOR_FACLIN');
    Anadir('           ELSE ''''');
    Anadir('         END, ''''),');
    Anadir('         CASE');
    Anadir('           WHEN LENGTH(fl.CODIGO_UNIDAD_FACLIN) -');
    Anadir('                LENGTH(REPLACE(fl.CODIGO_UNIDAD_FACLIN,');
    Anadir('                               ''/'', '''')) >= 2');
    Anadir('             THEN SUBSTRING_INDEX(SUBSTRING_INDEX(');
    Anadir('                    fl.CODIGO_UNIDAD_FACLIN, ''/'', 3),');
    Anadir('                    ''/'', -1)');
    Anadir('           ELSE ''''');
    Anadir('         END, '''') AS TALLA,');
    Anadir('       COALESCE(NULLIF(TRIM(fl.CODIGO_PRV_FACLIN), ''''),');
    Anadir('                ap.CODIGO_PRV_AP, '''') AS PROVEEDOR,');
    Anadir('       COALESCE(ap.REF_PROVEEDOR_AP, '''') AS MODELO,');
    Anadir('       fl.DESCRIPCION_ARTICULO_FACLIN AS DESCRIPCION,');
    Anadir('       COALESCE(fl.CANTIDAD_FACLIN, 0) AS CANTIDAD,');
    Anadir('       COALESCE(fl.CANTIDAD_FACLIN, 0) *');
    Anadir('       COALESCE(fl.PRECIO_SALIDA_FACLIN,');
    Anadir('                fl.PRECIO_VENTA_CIVA_ARTICULO_FACLIN, 0)');
    Anadir('         AS BRUTO,');
    Anadir('       COALESCE(fl.PORCENTAJE_DTO_FACLIN, 0)');
    Anadir('         AS PORCENTAJE_DTO,');
    Anadir('       COALESCE(fl.TOTAL_FACLIN, 0) AS NETO_ARTICULO,');
    Anadir('       COALESCE(');
    Anadir('         pg.INGRESOS_OPERACION * fl.TOTAL_FACLIN /');
    Anadir('         NULLIF(o.IMPORTE_TOTAL_OPCAJA, 0), 0) AS INGRESOS,');
    Anadir('       COALESCE(NULLIF(fl.CODIGO_VENDEDOR_FACLIN, ''''),');
    Anadir('                o.CODIGO_EMPLEADO_OPCAJA, '''') AS VENDEDOR,');
    Anadir('       COALESCE(pg.FORMAS_PAGO, '''') AS FORMA_PAGO,');
    Anadir('       CONCAT_WS(''.'', o.CODIGO_EMP_OPCAJA,');
    Anadir('                 o.TIPO_OPERACION_OPCAJA,');
    Anadir('                 o.SERIE_FAC_OPCAJA,');
    Anadir('                 o.NUMERO_FAC_OPCAJA) AS DOCUMENTO');
    Anadir('  FROM fza_caja_operaciones o');
    Anadir('  JOIN fza_facturas_lineas fl');
    Anadir('    ON fl.SERIE_FAC_FACLIN = o.SERIE_FAC_OPCAJA');
    Anadir('   AND fl.NUMERO_FAC_FACLIN = o.NUMERO_FAC_OPCAJA');
    Anadir('   AND fl.CODIGO_EMP_FACLIN = o.CODIGO_EMP_OPCAJA');
    Anadir('  LEFT JOIN fza_articulos_proveedores ap');
    Anadir('    ON ap.CODIGO_ART_AP = fl.CODIGO_ART_FACLIN');
    Anadir('   AND ap.CODIGO_PRV_AP =');
    Anadir('       COALESCE(NULLIF(TRIM(fl.CODIGO_PRV_FACLIN), ''''),');
    Anadir('         (SELECT apx.CODIGO_PRV_AP');
    Anadir('            FROM fza_articulos_proveedores apx');
    Anadir('           WHERE apx.CODIGO_ART_AP = fl.CODIGO_ART_FACLIN');
    Anadir('           ORDER BY CASE');
    Anadir('             WHEN apx.ESPROVEEDORPRINCIPAL_AP = ''S''');
    Anadir('             THEN 0 ELSE 1');
    Anadir('           END, apx.FECHA_VALIDEZ_AP DESC,');
    Anadir('           apx.CODIGO_PRV_AP');
    Anadir('           LIMIT 1))');
    Anadir('  LEFT JOIN (');
    Anadir('    SELECT sa.CODIGO_UNIDAD_SKU_SA');
    Anadir('             AS CODIGO_UNIDAD_SKU,');
    Anadir('           MAX(atb.HEX_ATB) AS HEX_COLOR_BASICO');
    Anadir('      FROM fza_atributos_sku sa');
    Anadir('      JOIN fza_articulos_skus sk');
    Anadir('        ON sk.CODIGO_UNIDAD_SKU =');
    Anadir('           sa.CODIGO_UNIDAD_SKU_SA');
    Anadir('      JOIN fza_atributos_valores av');
    Anadir('        ON av.ID_AV = sa.ID_AV_SA');
    Anadir('       AND av.ID_VA_AV = ''CO''');
    Anadir('      JOIN fza_articulos_atributos_basicos aab');
    Anadir('        ON aab.CODIGO_ART_AAB = sk.CODIGO_ART_SKU');
    Anadir('       AND aab.ID_AV_AAB = av.ID_AV');
    Anadir('      JOIN fza_atributos_basicos atb');
    Anadir('        ON atb.ID_ATB = aab.ID_ATB_AAB');
    Anadir('     GROUP BY sa.CODIGO_UNIDAD_SKU_SA');
    Anadir('  ) cb');
    Anadir('    ON cb.CODIGO_UNIDAD_SKU =');
    Anadir('       fl.CODIGO_UNIDAD_FACLIN');
    Anadir('  LEFT JOIN (');
    Anadir('    SELECT p.CODIGO_EMP_PAGO, p.CODIGO_ALM_PAGO,');
    Anadir('           p.CODIGO_CAJA_PAGO, p.NUMERO_OPERACION_PAGO,');
    Anadir('           GROUP_CONCAT(DISTINCT p.CODIGO_FP_CFP');
    Anadir('             ORDER BY p.CODIGO_FP_CFP SEPARATOR '', '')');
    Anadir('             AS FORMAS_PAGO,');
    Anadir('           SUM(p.IMPORTE_ENTREGADO_PAGO -');
    Anadir('               p.IMPORTE_CAMBIO_PAGO) AS INGRESOS_OPERACION');
    Anadir('      FROM fza_caja_pagos p');
    Anadir('     GROUP BY p.CODIGO_EMP_PAGO, p.CODIGO_ALM_PAGO,');
    Anadir('              p.CODIGO_CAJA_PAGO,');
    Anadir('              p.NUMERO_OPERACION_PAGO');
    Anadir('  ) pg');
    Anadir('    ON pg.CODIGO_EMP_PAGO = o.CODIGO_EMP_OPCAJA');
    Anadir('   AND pg.CODIGO_ALM_PAGO = o.CODIGO_ALM_OPCAJA');
    Anadir('   AND pg.CODIGO_CAJA_PAGO = o.CODIGO_CAJA_OPCAJA');
    Anadir('   AND pg.NUMERO_OPERACION_PAGO =');
    Anadir('       o.NUMERO_OPERACION_OPCAJA');
    Anadir(' WHERE o.TIPO_OPERACION_OPCAJA = ''VE''');
    Anadir(AFiltroUbicaciones);
    Anadir('   AND o.FECHA_OPERACION_OPCAJA >= :pDESDE');
    Anadir('   AND o.FECHA_OPERACION_OPCAJA <');
    Anadir('       DATE_ADD(:pHASTA, INTERVAL 1 DAY)');
    Anadir(SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA'));
    Anadir(' ORDER BY FECHA_DIA, o.CODIGO_EMP_OPCAJA,');
    Anadir('          o.CODIGO_ALM_OPCAJA,');
    Anadir('          o.CODIGO_CAJA_OPCAJA,');
    Anadir('          o.NUMERO_OPERACION_OPCAJA, fl.LINEA_FACLIN');
    Result := slSQL.Text;
  finally
    FreeAndNil(slSQL);
  end;
end;

function TRepositorioInformesCajaUniDAC.ConsultarOperacionesVenta(
  const ASolicitud: TSolicitudOperacionesVentaCaja
): IResultadoInformeCaja;
var
  oConsulta: TUniQuery;
  iUbicacion: Integer;
  sSufijo: string;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ConstruirSqlOperacionesVenta(
      ConstruirFiltroUbicaciones(ASolicitud.Ubicaciones));
    oConsulta.ParamByName('pDESDE').AsDateTime :=
      Trunc(ASolicitud.FechaDesde);
    oConsulta.ParamByName('pHASTA').AsDateTime :=
      Trunc(ASolicitud.FechaHasta);
    for iUbicacion := 0 to High(ASolicitud.Ubicaciones) do
    begin
      sSufijo := IntToStr(iUbicacion);
      oConsulta.ParamByName('pEMPRESA' + sSufijo).AsString :=
        ASolicitud.Ubicaciones[iUbicacion].Empresa;
      oConsulta.ParamByName('pALMACEN' + sSufijo).AsString :=
        ASolicitud.Ubicaciones[iUbicacion].Almacen;
      oConsulta.ParamByName('pCAJA' + sSufijo).AsString :=
        ASolicitud.Ubicaciones[iUbicacion].Caja;
    end;
    oConsulta.Open;
    Result := TResultadoInformeCajaUniDAC.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformesCajaUniDAC.ConsultarArqueosHistorico(
  const AEmpresa, AAlmacen, ACaja: string
): IResultadoInformeCaja;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT * ' +
      '  FROM fza_caja_arqueos ' +
      ' WHERE CODIGO_EMP_ARQ = :EMPRESA ' +
      '   AND CODIGO_ALM_ARQ = :ALMACEN ' +
      '   AND CODIGO_CAJA_ARQ = :CAJA ' +
      ' ORDER BY FECHA_DESDE_ARQ DESC, CODIGO_ARQ DESC';
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.ParamByName('ALMACEN').AsString := AAlmacen;
    oConsulta.ParamByName('CAJA').AsString := ACaja;
    oConsulta.Open;
    Result := TResultadoInformeCajaUniDAC.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformesCajaUniDAC.ConsultarValesPendientes(
  const AFiltro, APin: string;
  AUsarCaducidad: Boolean
): IResultadoInformeCaja;
var
  oConsulta: TUniQuery;
  sSql: string;
begin
  sSql :=
    'SELECT CODIGO_VL, PIN_SEGURIDAD_VL, ESTADO_VL, ' +
    '       IMPORTE_NOMINAL_VL, FECHA_EMISION_VL, ' +
    '       FECHA_CADUCIDAD_VL, OBSERVACIONES_VL ' +
    '  FROM fza_caja_vales ' +
    ' WHERE ESTADO_VL = ''PENDIENTE''';
  if AUsarCaducidad then
  begin
    sSql := sSql +
      ' AND (FECHA_CADUCIDAD_VL IS NULL ' +
      '      OR FECHA_CADUCIDAD_VL >= CURDATE())';
  end;
  if AFiltro <> '' then
  begin
    sSql := sSql + ' AND CODIGO_VL LIKE :FILTRO';
  end;
  if APin <> '' then
  begin
    sSql := sSql + ' AND PIN_SEGURIDAD_VL = :PIN';
  end;
  sSql := sSql + ' ORDER BY FECHA_EMISION_VL DESC';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := sSql;
    if AFiltro <> '' then
    begin
      oConsulta.ParamByName('FILTRO').AsString := '%' + AFiltro + '%';
    end;
    if APin <> '' then
    begin
      oConsulta.ParamByName('PIN').AsString := APin;
    end;
    oConsulta.Open;
    Result := TResultadoInformeCajaUniDAC.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioInformesCajaUniDAC(
  AConexion: TUniConnection): IRepositorioInformesCaja;
begin
  Result := TRepositorioInformesCajaUniDAC.Create(AConexion);
end;

end.
