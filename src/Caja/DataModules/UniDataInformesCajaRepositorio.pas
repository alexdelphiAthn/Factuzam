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
  System.Classes, Uni, inLibInformesCajaPersistenciaIntf;

function CrearRepositorioInformesCajaUniDAC(
  AConexion: TUniConnection): IRepositorioInformesCaja;

implementation

uses
  System.SysUtils, Data.DB,
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
    function ConstruirFiltroUbicacionesSolicitudes(
      const AUbicaciones: TUbicacionesInformeCaja): string;
    function ConstruirFiltroEstadosSolicitudes(
      const AEstados: TEstadosSolicitudTraspasoCaja): string;
    function ConstruirSqlSolicitudesTraspaso(
      const AFiltroUbicaciones, AFiltroEstados: string): string;
    procedure AnadirCabeceraOperacionesVenta(ALineas: TStrings);
    procedure AnadirAtributosOperacionesVenta(ALineas: TStrings);
    procedure AnadirImportesOperacionesVenta(ALineas: TStrings);
    procedure AnadirOrigenOperacionesVenta(ALineas: TStrings);
    procedure AnadirColoresOperacionesVenta(ALineas: TStrings);
    procedure AnadirPagosOperacionesVenta(ALineas: TStrings);
    procedure AnadirFiltrosOperacionesVenta(
      ALineas: TStrings;
      const AFiltroUbicaciones: string);
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
    function ListarEstadosSolicitudesTraspaso:
      TEstadosSolicitudTraspasoCaja;
    function ConsultarSolicitudesTraspaso(
      const ASolicitud: TSolicitudTraspasosInformeCaja
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

procedure TRepositorioInformesCajaUniDAC.AnadirCabeceraOperacionesVenta(
  ALineas: TStrings);
begin
  ALineas.Add('SELECT DATE(o.FECHA_OPERACION_OPCAJA) AS FECHA_DIA,');
  ALineas.Add('       DATE(:pDESDE) AS FECHA_DESDE,');
  ALineas.Add('       DATE(:pHASTA) AS FECHA_HASTA,');
  ALineas.Add('       o.CODIGO_EMP_OPCAJA,');
  ALineas.Add('       o.CODIGO_ALM_OPCAJA,');
  ALineas.Add('       o.CODIGO_CAJA_OPCAJA,');
  ALineas.Add('       CONCAT(o.CODIGO_EMP_OPCAJA, ''/'',');
  ALineas.Add('              o.CODIGO_ALM_OPCAJA, ''/'',');
  ALineas.Add('              o.CODIGO_CAJA_OPCAJA) AS CLAVE_CAJA,');
  ALineas.Add('       o.NUMERO_OPERACION_OPCAJA,');
  ALineas.Add('       fl.LINEA_FACLIN,');
  ALineas.Add('       fl.CODIGO_ART_FACLIN AS ARTICULO,');
end;

procedure TRepositorioInformesCajaUniDAC.AnadirAtributosOperacionesVenta(
  ALineas: TStrings);
begin
  ALineas.Add('       COALESCE(');
  ALineas.Add('         NULLIF(CASE');
  ALineas.Add('           WHEN UPPER(fl.ATTR1_NOMBRE_FACLIN) LIKE ''%COLOR%''');
  ALineas.Add('             THEN fl.ATTR1_VALOR_FACLIN');
  ALineas.Add('           WHEN UPPER(fl.ATTR2_NOMBRE_FACLIN) LIKE ''%COLOR%''');
  ALineas.Add('             THEN fl.ATTR2_VALOR_FACLIN');
  ALineas.Add('           WHEN UPPER(fl.ATTR3_NOMBRE_FACLIN) LIKE ''%COLOR%''');
  ALineas.Add('             THEN fl.ATTR3_VALOR_FACLIN');
  ALineas.Add('           WHEN UPPER(fl.ATTR4_NOMBRE_FACLIN) LIKE ''%COLOR%''');
  ALineas.Add('             THEN fl.ATTR4_VALOR_FACLIN');
  ALineas.Add('           WHEN UPPER(fl.ATTR5_NOMBRE_FACLIN) LIKE ''%COLOR%''');
  ALineas.Add('             THEN fl.ATTR5_VALOR_FACLIN');
  ALineas.Add('           ELSE ''''');
  ALineas.Add('         END, ''''),');
  ALineas.Add('         CASE');
  ALineas.Add('           WHEN LENGTH(fl.CODIGO_UNIDAD_FACLIN) -');
  ALineas.Add('                LENGTH(REPLACE(fl.CODIGO_UNIDAD_FACLIN,');
  ALineas.Add('                               ''/'', '''')) >= 1');
  ALineas.Add('             THEN SUBSTRING_INDEX(SUBSTRING_INDEX(');
  ALineas.Add('                    fl.CODIGO_UNIDAD_FACLIN, ''/'', 2),');
  ALineas.Add('                    ''/'', -1)');
  ALineas.Add('           ELSE ''''');
  ALineas.Add('         END, '''') AS COLOR,');
  ALineas.Add('       COALESCE(cb.HEX_COLOR_BASICO, '''')');
  ALineas.Add('         AS HEX_COLOR_BASICO,');
  ALineas.Add('       COALESCE(');
  ALineas.Add('         NULLIF(CASE');
  ALineas.Add('           WHEN UPPER(fl.ATTR1_NOMBRE_FACLIN) LIKE ''%TALLA%''');
  ALineas.Add('             THEN fl.ATTR1_VALOR_FACLIN');
  ALineas.Add('           WHEN UPPER(fl.ATTR2_NOMBRE_FACLIN) LIKE ''%TALLA%''');
  ALineas.Add('             THEN fl.ATTR2_VALOR_FACLIN');
  ALineas.Add('           WHEN UPPER(fl.ATTR3_NOMBRE_FACLIN) LIKE ''%TALLA%''');
  ALineas.Add('             THEN fl.ATTR3_VALOR_FACLIN');
  ALineas.Add('           WHEN UPPER(fl.ATTR4_NOMBRE_FACLIN) LIKE ''%TALLA%''');
  ALineas.Add('             THEN fl.ATTR4_VALOR_FACLIN');
  ALineas.Add('           WHEN UPPER(fl.ATTR5_NOMBRE_FACLIN) LIKE ''%TALLA%''');
  ALineas.Add('             THEN fl.ATTR5_VALOR_FACLIN');
  ALineas.Add('           ELSE ''''');
  ALineas.Add('         END, ''''),');
  ALineas.Add('         CASE');
  ALineas.Add('           WHEN LENGTH(fl.CODIGO_UNIDAD_FACLIN) -');
  ALineas.Add('                LENGTH(REPLACE(fl.CODIGO_UNIDAD_FACLIN,');
  ALineas.Add('                               ''/'', '''')) >= 2');
  ALineas.Add('             THEN SUBSTRING_INDEX(SUBSTRING_INDEX(');
  ALineas.Add('                    fl.CODIGO_UNIDAD_FACLIN, ''/'', 3),');
  ALineas.Add('                    ''/'', -1)');
  ALineas.Add('           ELSE ''''');
  ALineas.Add('         END, '''') AS TALLA,');
  ALineas.Add('       COALESCE(NULLIF(TRIM(fl.CODIGO_PRV_FACLIN), ''''),');
  ALineas.Add('                ap.CODIGO_PRV_AP, '''') AS PROVEEDOR,');
  ALineas.Add('       COALESCE(ap.REF_PROVEEDOR_AP, '''') AS MODELO,');
  ALineas.Add('       fl.DESCRIPCION_ARTICULO_FACLIN AS DESCRIPCION,');
end;

procedure TRepositorioInformesCajaUniDAC.AnadirImportesOperacionesVenta(
  ALineas: TStrings);
begin
  ALineas.Add('       COALESCE(fl.CANTIDAD_FACLIN, 0) AS CANTIDAD,');
  ALineas.Add('       COALESCE(fl.CANTIDAD_FACLIN, 0) *');
  ALineas.Add('       COALESCE(fl.PRECIO_SALIDA_FACLIN,');
  ALineas.Add('                fl.PRECIO_VENTA_CIVA_ARTICULO_FACLIN, 0)');
  ALineas.Add('         AS BRUTO,');
  ALineas.Add('       COALESCE(fl.PORCENTAJE_DTO_FACLIN, 0)');
  ALineas.Add('         AS PORCENTAJE_DTO,');
  ALineas.Add('       COALESCE(fl.TOTAL_FACLIN, 0) AS NETO_ARTICULO,');
  ALineas.Add('       COALESCE(');
  ALineas.Add('         pg.INGRESOS_OPERACION * fl.TOTAL_FACLIN /');
  ALineas.Add('         NULLIF(o.IMPORTE_TOTAL_OPCAJA, 0), 0) AS INGRESOS,');
  ALineas.Add('       COALESCE(NULLIF(fl.CODIGO_VENDEDOR_FACLIN, ''''),');
  ALineas.Add('                o.CODIGO_EMPLEADO_OPCAJA, '''') AS VENDEDOR,');
  ALineas.Add('       COALESCE(pg.FORMAS_PAGO, '''') AS FORMA_PAGO,');
  ALineas.Add('       CONCAT_WS(''.'', o.CODIGO_EMP_OPCAJA,');
  ALineas.Add('                 o.TIPO_OPERACION_OPCAJA,');
  ALineas.Add('                 o.SERIE_FAC_OPCAJA,');
  ALineas.Add('                 o.NUMERO_FAC_OPCAJA) AS DOCUMENTO');
end;

procedure TRepositorioInformesCajaUniDAC.AnadirOrigenOperacionesVenta(
  ALineas: TStrings);
begin
  ALineas.Add('  FROM fza_caja_operaciones o');
  ALineas.Add('  JOIN fza_facturas_lineas fl');
  ALineas.Add('    ON fl.SERIE_FAC_FACLIN = o.SERIE_FAC_OPCAJA');
  ALineas.Add('   AND fl.NUMERO_FAC_FACLIN = o.NUMERO_FAC_OPCAJA');
  ALineas.Add('   AND fl.CODIGO_EMP_FACLIN = o.CODIGO_EMP_OPCAJA');
  ALineas.Add('  LEFT JOIN fza_articulos_proveedores ap');
  ALineas.Add('    ON ap.CODIGO_ART_AP = fl.CODIGO_ART_FACLIN');
  ALineas.Add('   AND ap.CODIGO_PRV_AP =');
  ALineas.Add('       COALESCE(NULLIF(TRIM(fl.CODIGO_PRV_FACLIN), ''''),');
  ALineas.Add('         (SELECT apx.CODIGO_PRV_AP');
  ALineas.Add('            FROM fza_articulos_proveedores apx');
  ALineas.Add('           WHERE apx.CODIGO_ART_AP = fl.CODIGO_ART_FACLIN');
  ALineas.Add('           ORDER BY CASE');
  ALineas.Add('             WHEN apx.ESPROVEEDORPRINCIPAL_AP = ''S''');
  ALineas.Add('             THEN 0 ELSE 1');
  ALineas.Add('           END, apx.FECHA_VALIDEZ_AP DESC,');
  ALineas.Add('           apx.CODIGO_PRV_AP');
  ALineas.Add('           LIMIT 1))');
end;

procedure TRepositorioInformesCajaUniDAC.AnadirColoresOperacionesVenta(
  ALineas: TStrings);
begin
  ALineas.Add('  LEFT JOIN (');
  ALineas.Add('    SELECT sa.CODIGO_UNIDAD_SKU_SA');
  ALineas.Add('             AS CODIGO_UNIDAD_SKU,');
  ALineas.Add('           MAX(atb.HEX_ATB) AS HEX_COLOR_BASICO');
  ALineas.Add('      FROM fza_atributos_sku sa');
  ALineas.Add('      JOIN fza_articulos_skus sk');
  ALineas.Add('        ON sk.CODIGO_UNIDAD_SKU =');
  ALineas.Add('           sa.CODIGO_UNIDAD_SKU_SA');
  ALineas.Add('      JOIN fza_atributos_valores av');
  ALineas.Add('        ON av.ID_AV = sa.ID_AV_SA');
  ALineas.Add('       AND av.ID_VA_AV = ''CO''');
  ALineas.Add('      JOIN fza_articulos_atributos_basicos aab');
  ALineas.Add('        ON aab.CODIGO_ART_AAB = sk.CODIGO_ART_SKU');
  ALineas.Add('       AND aab.ID_AV_AAB = av.ID_AV');
  ALineas.Add('      JOIN fza_atributos_basicos atb');
  ALineas.Add('        ON atb.ID_ATB = aab.ID_ATB_AAB');
  ALineas.Add('     GROUP BY sa.CODIGO_UNIDAD_SKU_SA');
  ALineas.Add('  ) cb');
  ALineas.Add('    ON cb.CODIGO_UNIDAD_SKU =');
  ALineas.Add('       fl.CODIGO_UNIDAD_FACLIN');
end;

procedure TRepositorioInformesCajaUniDAC.AnadirPagosOperacionesVenta(
  ALineas: TStrings);
begin
  ALineas.Add('  LEFT JOIN (');
  ALineas.Add('    SELECT p.CODIGO_EMP_PAGO, p.CODIGO_ALM_PAGO,');
  ALineas.Add('           p.CODIGO_CAJA_PAGO, p.NUMERO_OPERACION_PAGO,');
  ALineas.Add('           GROUP_CONCAT(DISTINCT p.CODIGO_FP_CFP');
  ALineas.Add('             ORDER BY p.CODIGO_FP_CFP SEPARATOR '', '')');
  ALineas.Add('             AS FORMAS_PAGO,');
  ALineas.Add('           SUM(p.IMPORTE_ENTREGADO_PAGO -');
  ALineas.Add('               p.IMPORTE_CAMBIO_PAGO) AS INGRESOS_OPERACION');
  ALineas.Add('      FROM fza_caja_pagos p');
  ALineas.Add('     GROUP BY p.CODIGO_EMP_PAGO, p.CODIGO_ALM_PAGO,');
  ALineas.Add('              p.CODIGO_CAJA_PAGO,');
  ALineas.Add('              p.NUMERO_OPERACION_PAGO');
  ALineas.Add('  ) pg');
  ALineas.Add('    ON pg.CODIGO_EMP_PAGO = o.CODIGO_EMP_OPCAJA');
  ALineas.Add('   AND pg.CODIGO_ALM_PAGO = o.CODIGO_ALM_OPCAJA');
  ALineas.Add('   AND pg.CODIGO_CAJA_PAGO = o.CODIGO_CAJA_OPCAJA');
  ALineas.Add('   AND pg.NUMERO_OPERACION_PAGO =');
  ALineas.Add('       o.NUMERO_OPERACION_OPCAJA');
end;

procedure TRepositorioInformesCajaUniDAC.AnadirFiltrosOperacionesVenta(
  ALineas: TStrings;
  const AFiltroUbicaciones: string);
begin
  ALineas.Add(' WHERE o.TIPO_OPERACION_OPCAJA = ''VE''');
  ALineas.Add(AFiltroUbicaciones);
  ALineas.Add('   AND o.FECHA_OPERACION_OPCAJA >= :pDESDE');
  ALineas.Add('   AND o.FECHA_OPERACION_OPCAJA <');
  ALineas.Add('       DATE_ADD(:pHASTA, INTERVAL 1 DAY)');
  ALineas.Add(SQLExcluirVentaRetirada(
    'o.CODIGO_EMP_OPCAJA',
    'o.SERIE_FAC_OPCAJA',
    'o.NUMERO_FAC_OPCAJA'));
  ALineas.Add(' ORDER BY FECHA_DIA, o.CODIGO_EMP_OPCAJA,');
  ALineas.Add('          o.CODIGO_ALM_OPCAJA,');
  ALineas.Add('          o.CODIGO_CAJA_OPCAJA,');
  ALineas.Add('          o.NUMERO_OPERACION_OPCAJA, fl.LINEA_FACLIN');
end;

function TRepositorioInformesCajaUniDAC.ConstruirSqlOperacionesVenta(
  const AFiltroUbicaciones: string): string;
var
  slSQL: TStringList;
begin
  slSQL := TStringList.Create;
  try
    AnadirCabeceraOperacionesVenta(slSQL);
    AnadirAtributosOperacionesVenta(slSQL);
    AnadirImportesOperacionesVenta(slSQL);
    AnadirOrigenOperacionesVenta(slSQL);
    AnadirColoresOperacionesVenta(slSQL);
    AnadirPagosOperacionesVenta(slSQL);
    AnadirFiltrosOperacionesVenta(slSQL, AFiltroUbicaciones);
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

function TRepositorioInformesCajaUniDAC.
  ConstruirFiltroUbicacionesSolicitudes(
  const AUbicaciones: TUbicacionesInformeCaja): string;
var
  iUbicacion: Integer;
  sSufijo: string;
begin
  if Length(AUbicaciones) = 0 then
    Result := '   AND 1 = 0'
  else
  begin
    Result := '   AND (';
    for iUbicacion := 0 to High(AUbicaciones) do
    begin
      if iUbicacion > 0 then
        Result := Result + sLineBreak + '        OR ';
      sSufijo := IntToStr(iUbicacion);
      Result := Result +
        '(s.CODIGO_EMP_TRSOL = :pEMPRESA' + sSufijo +
        ' AND s.CODIGO_ALM_DESTINO_TRSOL = :pALMACEN' + sSufijo +
        ' AND s.CODIGO_CAJA_TRSOL = :pCAJA' + sSufijo + ')';
    end;
    Result := Result + ')';
  end;
end;

function TRepositorioInformesCajaUniDAC.
  ConstruirFiltroEstadosSolicitudes(
  const AEstados: TEstadosSolicitudTraspasoCaja): string;
var
  iEstado: Integer;
begin
  Result := '';
  if Length(AEstados) > 0 then
  begin
    Result := '   AND s.ESTADO_TRSOL IN (';
    for iEstado := 0 to High(AEstados) do
    begin
      if iEstado > 0 then
        Result := Result + ', ';
      Result := Result + ':pESTADO' + IntToStr(iEstado);
    end;
    Result := Result + ')';
  end;
end;

function TRepositorioInformesCajaUniDAC.
  ConstruirSqlSolicitudesTraspaso(
  const AFiltroUbicaciones, AFiltroEstados: string): string;
var
  slSQL: TStringList;
begin
  slSQL := TStringList.Create;
  try
    slSQL.Add('SELECT DATE(:pDESDE) AS FECHA_DESDE,');
    slSQL.Add('       DATE(:pHASTA) AS FECHA_HASTA,');
    slSQL.Add('       CONCAT_WS(''|'', s.SERIE_TRSOL,');
    slSQL.Add('         s.NUMERO_TRSOL) AS CLAVE_SOLICITUD,');
    slSQL.Add('       s.NUMERO_TRSOL,');
    slSQL.Add('       s.SERIE_TRSOL,');
    slSQL.Add('       s.FECHA_TRSOL,');
    slSQL.Add('       s.INSTANTE_ALTA,');
    slSQL.Add('       s.TIPO_TRSOL,');
    slSQL.Add('       s.ESTADO_TRSOL,');
    slSQL.Add('       s.INSTANTE_VENTAS_DESDE_TRSOL,');
    slSQL.Add('       s.INSTANTE_VENTAS_HASTA_TRSOL,');
    slSQL.Add('       s.CODIGO_EMP_TRSOL,');
    slSQL.Add('       ep.RAZON_SOCIAL_EMP AS NOMBRE_EMPRESA_TRSOL,');
    slSQL.Add('       s.CODIGO_ALM_DESTINO_TRSOL,');
    slSQL.Add('       ad.NOMBRE_ALM_ALM AS NOMBRE_ALMACEN_DESTINO_TRSOL,');
    slSQL.Add('       s.CODIGO_CAJA_TRSOL,');
    slSQL.Add('       c.DESCRIPCION_ALMCAJ AS NOMBRE_CAJA_TRSOL,');
    slSQL.Add('       s.CODIGO_EMP_CONTRA_TRSOL,');
    slSQL.Add('       ec.RAZON_SOCIAL_EMP AS NOMBRE_EMPRESA_CONTRA_TRSOL,');
    slSQL.Add('       s.CODIGO_ALM_ORIGEN_TRSOL,');
    slSQL.Add('       ao.NOMBRE_ALM_ALM AS NOMBRE_ALMACEN_ORIGEN_TRSOL,');
    slSQL.Add('       s.CODIGO_EMPLEADO_TRSOL,');
    slSQL.Add('       COALESCE(NULLIF(TRIM(e.NOMBRE_EMPL), ''''),');
    slSQL.Add('         NULLIF(TRIM(e.DIMINUTIVO_TICKET_EMPL), ''''),');
    slSQL.Add('         s.CODIGO_EMPLEADO_TRSOL)');
    slSQL.Add('         AS NOMBRE_EMPLEADO_TRSOL,');
    slSQL.Add('       s.OBSERVACIONES_TRSOL,');
    slSQL.Add('       l.LINEA_TRSOLLIN,');
    slSQL.Add('       l.CODIGO_ART_TRSOLLIN AS CODIGO_ART,');
    slSQL.Add('       l.CODIGO_UNIDAD_TRSOLLIN AS SKU_UNIDAD,');
    slSQL.Add('       CASE WHEN l.LINEA_TRSOLLIN IS NULL');
    slSQL.Add('            THEN ''Sin líneas solicitadas''');
    slSQL.Add('            ELSE COALESCE(');
    slSQL.Add('              NULLIF(');
    slSQL.Add('                TRIM(l.DESCRIPCION_ARTICULO_TRSOLLIN), ''''),');
    slSQL.Add('              a.DESCRIPCION_ART, '''') END');
    slSQL.Add('         AS DESCRIPCION_ART,');
    slSQL.Add('       l.CANTIDAD_PEDIDA_TRSOLLIN,');
    slSQL.Add('       CASE WHEN s.TIPO_TRSOL = ''AUTO'' THEN 0');
    slSQL.Add('            ELSE l.CANTIDAD_SERVIDA_TRSOLLIN END');
    slSQL.Add('         AS CANTIDAD_SERVIDA_TRSOLLIN,');
    slSQL.Add('       CASE WHEN l.LINEA_TRSOLLIN IS NULL THEN NULL');
    slSQL.Add('            WHEN s.TIPO_TRSOL = ''AUTO'' THEN 0');
    slSQL.Add('            ELSE GREATEST(');
    slSQL.Add('              COALESCE(l.CANTIDAD_PEDIDA_TRSOLLIN, 0) -');
    slSQL.Add('              COALESCE(l.CANTIDAD_SERVIDA_TRSOLLIN, 0), 0)');
    slSQL.Add('            END AS CANTIDAD_PENDIENTE_TRSOLLIN,');
    slSQL.Add('       CASE WHEN l.LINEA_TRSOLLIN IS NULL THEN ''''');
    slSQL.Add('            WHEN s.TIPO_TRSOL = ''AUTO''');
    slSQL.Add('            THEN ''No aplica''');
    slSQL.Add('            WHEN l.ESATENDIDA_TRSOLLIN = ''S''');
    slSQL.Add('            THEN ''Sí'' ELSE ''No'' END');
    slSQL.Add('         AS ATENDIDA_TRSOLLIN,');
    slSQL.Add('       CASE WHEN s.TIPO_TRSOL = ''AUTO'' THEN NULL');
    slSQL.Add('            ELSE l.MOTIVO_RECHAZO_TRSOLLIN END');
    slSQL.Add('         AS MOTIVO_RECHAZO_TRSOLLIN,');
    slSQL.Add('       l.CODIGO_PRV_TRSOLLIN,');
    slSQL.Add('       l.RAZON_SOCIAL_PRV_TRSOLLIN');
    slSQL.Add('  FROM fza_traspasos_solicitudes s');
    slSQL.Add('  LEFT JOIN fza_traspasos_solicitudes_lineas l');
    slSQL.Add('    ON l.NUMERO_TRSOL_TRSOLLIN = s.NUMERO_TRSOL');
    slSQL.Add('   AND l.SERIE_TRSOL_TRSOLLIN = s.SERIE_TRSOL');
    slSQL.Add('  LEFT JOIN fza_articulos a');
    slSQL.Add('    ON a.CODIGO_ART_ART = l.CODIGO_ART_TRSOLLIN');
    slSQL.Add('  LEFT JOIN fza_empresas ep');
    slSQL.Add('    ON ep.CODIGO_EMP_EMP = s.CODIGO_EMP_TRSOL');
    slSQL.Add('  LEFT JOIN fza_empresas ec');
    slSQL.Add('    ON ec.CODIGO_EMP_EMP = s.CODIGO_EMP_CONTRA_TRSOL');
    slSQL.Add('  LEFT JOIN fza_almacenes ad');
    slSQL.Add('    ON ad.CODIGO_ALM_ALM = s.CODIGO_ALM_DESTINO_TRSOL');
    slSQL.Add('  LEFT JOIN fza_almacenes ao');
    slSQL.Add('    ON ao.CODIGO_ALM_ALM = s.CODIGO_ALM_ORIGEN_TRSOL');
    slSQL.Add('  LEFT JOIN fza_almacenes_cajas c');
    slSQL.Add('    ON c.CODIGO_ALM_ALMCAJ = s.CODIGO_ALM_DESTINO_TRSOL');
    slSQL.Add('   AND c.CODIGO_CAJA_ALMCAJ = s.CODIGO_CAJA_TRSOL');
    slSQL.Add('  LEFT JOIN fza_empleados e');
    slSQL.Add('    ON e.CODIGO_EMPL = s.CODIGO_EMPLEADO_TRSOL');
    slSQL.Add(' WHERE s.INSTANTE_ALTA >= :pDESDE');
    slSQL.Add('   AND s.INSTANTE_ALTA <');
    slSQL.Add('       DATE_ADD(:pHASTA, INTERVAL 1 DAY)');
    slSQL.Add(AFiltroUbicaciones);
    if AFiltroEstados <> '' then
      slSQL.Add(AFiltroEstados);
    slSQL.Add(' ORDER BY s.INSTANTE_ALTA, s.SERIE_TRSOL,');
    slSQL.Add('          CAST(s.NUMERO_TRSOL AS UNSIGNED),');
    slSQL.Add('          l.LINEA_TRSOLLIN');
    Result := slSQL.Text;
  finally
    FreeAndNil(slSQL);
  end;
end;

function TRepositorioInformesCajaUniDAC.
  ListarEstadosSolicitudesTraspaso:
  TEstadosSolicitudTraspasoCaja;
var
  iEstado: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT DISTINCT ESTADO_TRSOL ' +
      '  FROM fza_traspasos_solicitudes ' +
      ' WHERE NULLIF(TRIM(ESTADO_TRSOL), '''') IS NOT NULL ' +
      ' ORDER BY ESTADO_TRSOL';
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iEstado := 0;
    while not oConsulta.Eof do
    begin
      Result[iEstado] :=
        oConsulta.FieldByName('ESTADO_TRSOL').AsString;
      Inc(iEstado);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformesCajaUniDAC.
  ConsultarSolicitudesTraspaso(
  const ASolicitud: TSolicitudTraspasosInformeCaja
): IResultadoInformeCaja;
var
  iEstado: Integer;
  iUbicacion: Integer;
  oConsulta: TUniQuery;
  sSufijo: string;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ConstruirSqlSolicitudesTraspaso(
      ConstruirFiltroUbicacionesSolicitudes(
        ASolicitud.Ubicaciones),
      ConstruirFiltroEstadosSolicitudes(ASolicitud.Estados));
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
    for iEstado := 0 to High(ASolicitud.Estados) do
      oConsulta.ParamByName('pESTADO' + IntToStr(iEstado)).AsString :=
        ASolicitud.Estados[iEstado];
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
