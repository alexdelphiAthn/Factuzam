{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataGridPivoteCompraRepositorio                            }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Implementación UniDAC de la persistencia del pivote de compra.            }
{******************************************************************************}
unit UniDataGridPivoteCompraRepositorio;

interface

uses
  Uni, inLibGridPivoteCompraPersistenciaIntf;

function CrearRepositorioGridPivoteCompraUniDAC(
  AConexion: TUniConnection): IRepositorioGridPivoteCompra;

implementation

uses
  System.SysUtils, System.StrUtils, Data.DB;

type
  TRepositorioGridPivoteCompraUniDAC = class(
    TInterfacedObject,
    IRepositorioGridPivoteCompra)
  private
    FConexion: TUniConnection;
    FTablaLineas: string;
    FCampoSerie: string;
    FCampoNumero: string;
    FCampoLinea: string;
    FCampoArticulo: string;
    FCampoSku: string;
    FCampoCantidad: string;
    FCampoCantidadRecibida: string;
    FCampoIdConjunto: string;
    FCampoAlmacen: string;
    FCampoColorTexto: string;
    FMaximoColumnas: Integer;
    function NuevaConsulta: TUniQuery;
  public
    constructor Create(AConexion: TUniConnection);
    procedure Configurar(
      const ATablaLineas, ACampoSerie, ACampoNumero, ACampoLinea,
        ACampoArticulo, ACampoSku, ACampoCantidad,
        ACampoCantidadRecibida, ACampoIdConjunto, ACampoAlmacen,
        ACampoColorTexto: string;
      AMaximoColumnas: Integer);
    function BuscarColorBasico(
      const ACodigo: string;
      out AIdBasico: Integer;
      out ANombre: string): Boolean;
    function BuscarValorColor(
      const AValor: string;
      out AIdValor: Integer;
      out ATieneBasico: Boolean): Boolean;
    procedure VincularValorColor(
      AIdValor, AIdBasico: Integer;
      const AUsuario: string);
    function InsertarValorColor(
      const AValor, ADescripcion, AUsuario: string;
      AIdBasico: Integer): Integer;
    function BuscarArticulosSinSistema(
      const ASerie, ANumero: string): TDataSet;
    function BuscarSistemasConExceso(
      const ASerie, ANumero: string): TDataSet;
    function BuscarSkusFueraSistema(
      const ASerie, ANumero: string): TDataSet;
    function BuscarLineasPivote(
      const ASerie, ANumero: string): TDataSet;
    function BuscarSku(
      const ACodigoArticulo: string;
      AIdTalla, AIdColor: Integer): string;
    function BuscarValorAtributo(AIdValor: Integer): string;
    procedure AsegurarSkuConAtributos(
      const ACodigoSku, ACodigoArticulo, ACodigoVariacion,
        AUsuario: string;
      AIdColor, AIdTalla: Integer);
    function BuscarTipoVariacion(
      const ACodigoArticulo: string): string;
    procedure AsegurarSkuColor(
      const ACodigoSku, ACodigoArticulo, ACodigoVariacion,
        AUsuario: string;
      AIdColor: Integer);
  end;

constructor TRepositorioGridPivoteCompraUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

procedure TRepositorioGridPivoteCompraUniDAC.Configurar(
  const ATablaLineas, ACampoSerie, ACampoNumero, ACampoLinea,
    ACampoArticulo, ACampoSku, ACampoCantidad,
    ACampoCantidadRecibida, ACampoIdConjunto, ACampoAlmacen,
    ACampoColorTexto: string;
  AMaximoColumnas: Integer);
begin
  FTablaLineas := ATablaLineas;
  FCampoSerie := ACampoSerie;
  FCampoNumero := ACampoNumero;
  FCampoLinea := ACampoLinea;
  FCampoArticulo := ACampoArticulo;
  FCampoSku := ACampoSku;
  FCampoCantidad := ACampoCantidad;
  FCampoCantidadRecibida := ACampoCantidadRecibida;
  FCampoIdConjunto := ACampoIdConjunto;
  FCampoAlmacen := ACampoAlmacen;
  FCampoColorTexto := ACampoColorTexto;
  FMaximoColumnas := AMaximoColumnas;
end;

function TRepositorioGridPivoteCompraUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioGridPivoteCompraUniDAC.BuscarColorBasico(
  const ACodigo: string;
  out AIdBasico: Integer;
  out ANombre: string): Boolean;
var
  Consulta: TUniQuery;
begin
  AIdBasico := 0;
  ANombre := '';
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT ID_ATB, NOMBRE_ATB ' +
      '  FROM fza_atributos_basicos ' +
      ' WHERE ID_VA_ATB = ''CO'' ' +
      '   AND CODIGO_ATB = :cod ' +
      '   AND COALESCE(ESACTIVO_ATB, ''S'') = ''S'' ' +
      ' LIMIT 1';
    Consulta.ParamByName('cod').AsString := ACodigo;
    Consulta.Open;
    Result := not Consulta.IsEmpty;
    if Result then
    begin
      AIdBasico := Consulta.FieldByName('ID_ATB').AsInteger;
      ANombre := Consulta.FieldByName('NOMBRE_ATB').AsString;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioGridPivoteCompraUniDAC.BuscarValorColor(
  const AValor: string;
  out AIdValor: Integer;
  out ATieneBasico: Boolean): Boolean;
var
  Consulta: TUniQuery;
begin
  AIdValor := 0;
  ATieneBasico := False;
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT ID_AV, ID_ATB_AV ' +
      '  FROM fza_atributos_valores ' +
      ' WHERE ID_VA_AV = ''CO'' ' +
      '   AND AV = :av ' +
      ' LIMIT 1';
    Consulta.ParamByName('av').AsString := AValor;
    Consulta.Open;
    Result := not Consulta.IsEmpty;
    if Result then
    begin
      AIdValor := Consulta.FieldByName('ID_AV').AsInteger;
      ATieneBasico := not Consulta.FieldByName('ID_ATB_AV').IsNull;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TRepositorioGridPivoteCompraUniDAC.VincularValorColor(
  AIdValor, AIdBasico: Integer;
  const AUsuario: string);
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'UPDATE fza_atributos_valores ' +
      '   SET ID_ATB_AV = :id_atb, INSTANTE_MODIF = NOW(), ' +
      '       USUARIO_MODIF = :usuario ' +
      ' WHERE ID_AV = :id_av';
    Consulta.ParamByName('id_atb').AsInteger := AIdBasico;
    Consulta.ParamByName('usuario').AsString := AUsuario;
    Consulta.ParamByName('id_av').AsInteger := AIdValor;
    Consulta.Execute;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioGridPivoteCompraUniDAC.InsertarValorColor(
  const AValor, ADescripcion, AUsuario: string;
  AIdBasico: Integer): Integer;
var
  Consulta: TUniQuery;
begin
  Result := 0;
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'INSERT INTO fza_atributos_valores ' +
      '  (ID_VA_AV, AV, DESCRIPCION_AV, ID_ATB_AV, ESACTIVO_AV, ' +
      '   ORDEN_AV, INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, ' +
      '   USUARIO_MODIF) ' +
      'VALUES (''CO'', :av, :descripcion, :id_atb, ''S'', 0, ' +
      '        NOW(), :usuario, NOW(), :usuario)';
    Consulta.ParamByName('av').AsString := AValor;
    Consulta.ParamByName('descripcion').AsString := ADescripcion;
    Consulta.ParamByName('id_atb').AsInteger := AIdBasico;
    Consulta.ParamByName('usuario').AsString := AUsuario;
    Consulta.Execute;
    Consulta.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID_AV';
    Consulta.Open;
    if not Consulta.IsEmpty then
      Result := Consulta.FieldByName('ID_AV').AsInteger;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioGridPivoteCompraUniDAC.BuscarArticulosSinSistema(
  const ASerie, ANumero: string): TDataSet;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT DISTINCT L.' + FCampoArticulo + ' AS ART ' +
      '  FROM ' + FTablaLineas + ' L ' +
      ' WHERE L.' + FCampoSerie + ' = :SERIE ' +
      '   AND L.' + FCampoNumero + ' = :NUMERO ' +
      '   AND (L.' + FCampoIdConjunto + ' IS NULL ' +
      '        OR L.' + FCampoIdConjunto + ' = 0) ' +
      '   AND EXISTS ( ' +
      '         SELECT 1 FROM fza_atributos_sku SAT ' +
      '          JOIN fza_atributos_valores AVT ' +
      '            ON AVT.ID_AV = SAT.ID_AV_SA ' +
      '           AND AVT.ID_VA_AV = ''TAL'' ' +
      '         WHERE SAT.CODIGO_UNIDAD_SKU_SA = L.' + FCampoSku + ') ' +
      ' ORDER BY ART';
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.Open;
    Result := Consulta;
    Consulta := nil;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioGridPivoteCompraUniDAC.BuscarSistemasConExceso(
  const ASerie, ANumero: string): TDataSet;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT DISTINCT L.' + FCampoArticulo + ' AS ART, ' +
      '       AC.NOMBRE_AC AS SISTEMA, ' +
      '       (SELECT COUNT(*) FROM fza_atributos_conjuntos_det ACD ' +
      '         WHERE ACD.ID_AC_ACD = L.' + FCampoIdConjunto + ') AS N ' +
      '  FROM ' + FTablaLineas + ' L ' +
      '  JOIN fza_atributos_conjuntos AC ' +
      '    ON AC.ID_AC = L.' + FCampoIdConjunto + ' ' +
      ' WHERE L.' + FCampoSerie + ' = :SERIE ' +
      '   AND L.' + FCampoNumero + ' = :NUMERO ' +
      '   AND L.' + FCampoIdConjunto + ' > 0 ' +
      '   AND (SELECT COUNT(*) FROM fza_atributos_conjuntos_det ACD ' +
      '         WHERE ACD.ID_AC_ACD = L.' + FCampoIdConjunto +
      ') > :NMAX ' +
      ' ORDER BY ART';
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.ParamByName('NMAX').AsInteger := FMaximoColumnas;
    Consulta.Open;
    Result := Consulta;
    Consulta := nil;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioGridPivoteCompraUniDAC.BuscarSkusFueraSistema(
  const ASerie, ANumero: string): TDataSet;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT DISTINCT L.' + FCampoSku + ' AS SKU, ' +
      '       L.' + FCampoArticulo + ' AS ART, AV.AV AS TALLA ' +
      '  FROM ' + FTablaLineas + ' L ' +
      '  JOIN fza_atributos_sku SAT ' +
      '    ON SAT.CODIGO_UNIDAD_SKU_SA = L.' + FCampoSku + ' ' +
      '  JOIN fza_atributos_valores AV ' +
      '    ON AV.ID_AV = SAT.ID_AV_SA ' +
      '   AND AV.ID_VA_AV = ''TAL'' ' +
      ' WHERE L.' + FCampoSerie + ' = :SERIE ' +
      '   AND L.' + FCampoNumero + ' = :NUMERO ' +
      '   AND L.' + FCampoIdConjunto + ' > 0 ' +
      '   AND NOT EXISTS ( ' +
      '         SELECT 1 FROM fza_atributos_conjuntos_det ACD ' +
      '          WHERE ACD.ID_AC_ACD = L.' + FCampoIdConjunto + ' ' +
      '            AND ACD.ID_AV_ACD = SAT.ID_AV_SA) ' +
      ' ORDER BY ART, SKU';
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.Open;
    Result := Consulta;
    Consulta := nil;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioGridPivoteCompraUniDAC.BuscarLineasPivote(
  const ASerie, ANumero: string): TDataSet;
var
  Consulta: TUniQuery;
  sCampoColor: string;
  sCampoRecibida: string;
begin
  if FCampoCantidadRecibida <> '' then
    sCampoRecibida :=
      ', IFNULL(L.' + FCampoCantidadRecibida + ', 0) AS RECIBIDA '
  else
    sCampoRecibida := ', 0 AS RECIBIDA ';
  sCampoColor := IfThen(
    FCampoColorTexto <> '',
    '       COALESCE(NULLIF(L.' + FCampoColorTexto +
      ', ''''), '''') AS COLOR_PROV_TXT, ',
    '       '''' AS COLOR_PROV_TXT, ');
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT L.' + FCampoLinea + ' AS LINEA, ' +
      '       L.' + FCampoArticulo + ' AS ART, ' +
      '       COALESCE(L.' + FCampoIdConjunto + ', 0) AS ID_AC, ' +
      '       COALESCE(AVC.ID_AV, 0) AS COLOR_AV, ' +
      '       COALESCE(NULLIF(AVC.AV, ''''), ATBC.NOMBRE_ATB, ' +
      '                SUBSTRING_INDEX(SUBSTRING_INDEX(L.' + FCampoSku +
      ', ''/'', 2), ''/'', -1), ' +
      '                '''') AS COLOR_TXT, ' +
      sCampoColor +
      '       COALESCE(ATBC.CODIGO_ATB, ' +
      '                SUBSTRING_INDEX(SUBSTRING_INDEX(L.' + FCampoSku +
      ', ''/'', 2), ''/'', -1), ' +
      '                '''') AS COLOR_COD, ' +
      '       COALESCE(T.ID_AV_SA, 0) AS TALLA_AV, ' +
      '       L.' + FCampoCantidad + ' AS CANTIDAD, ' +
      '       L.' + FCampoSku + ' AS SKU, ' +
      '       COALESCE(SKU0.CODIGO_VAR_SKU, ''TC'') AS VAR_SKU, ' +
      '       L.' + FCampoAlmacen + ' AS ALM_LIN ' +
      sCampoRecibida +
      '  FROM ' + FTablaLineas + ' L ' +
      '  LEFT JOIN fza_articulos_skus SKU0 ' +
      '    ON SKU0.CODIGO_UNIDAD_SKU = L.' + FCampoSku + ' ' +
      '  LEFT JOIN fza_atributos_sku SAC ' +
      '    ON SAC.CODIGO_UNIDAD_SKU_SA = L.' + FCampoSku + ' ' +
      '   AND EXISTS (SELECT 1 FROM fza_atributos_valores AV ' +
      '                WHERE AV.ID_AV = SAC.ID_AV_SA ' +
      '                  AND AV.ID_VA_AV = ''CO'') ' +
      '  LEFT JOIN fza_atributos_valores AVC ' +
      '    ON AVC.ID_AV = SAC.ID_AV_SA ' +
      '   AND AVC.ID_VA_AV = ''CO'' ' +
      '  LEFT JOIN fza_atributos_basicos ATBC ' +
      '    ON ATBC.ID_ATB = AVC.ID_ATB_AV ' +
      '  LEFT JOIN fza_atributos_sku T ' +
      '    ON T.CODIGO_UNIDAD_SKU_SA = L.' + FCampoSku + ' ' +
      '   AND EXISTS (SELECT 1 FROM fza_atributos_valores AVT ' +
      '                WHERE AVT.ID_AV = T.ID_AV_SA ' +
      '                  AND AVT.ID_VA_AV = ''TAL'') ' +
      ' WHERE L.' + FCampoSerie + ' = :SERIE ' +
      '   AND L.' + FCampoNumero + ' = :NUMERO ' +
      ' ORDER BY ART, COLOR_AV, L.' + FCampoLinea;
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.Open;
    Result := Consulta;
    Consulta := nil;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioGridPivoteCompraUniDAC.BuscarSku(
  const ACodigoArticulo: string;
  AIdTalla, AIdColor: Integer): string;
var
  Consulta: TUniQuery;
begin
  Result := '';
  Consulta := NuevaConsulta;
  try
    if AIdColor > 0 then
      Consulta.SQL.Text :=
        'SELECT sk.CODIGO_UNIDAD_SKU ' +
        '  FROM fza_articulos_skus sk ' +
        ' WHERE sk.CODIGO_ART_SKU = :art ' +
        '   AND sk.ESACTIVO_SKU = ''S'' ' +
        '   AND EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
        '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
        '                      sk.CODIGO_UNIDAD_SKU ' +
        '                  AND sa.ID_AV_SA = :talla) ' +
        '   AND EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
        '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
        '                      sk.CODIGO_UNIDAD_SKU ' +
        '                  AND sa.ID_AV_SA = :color) ' +
        ' LIMIT 1'
    else
      Consulta.SQL.Text :=
        'SELECT sk.CODIGO_UNIDAD_SKU ' +
        '  FROM fza_articulos_skus sk ' +
        ' WHERE sk.CODIGO_ART_SKU = :art ' +
        '   AND sk.ESACTIVO_SKU = ''S'' ' +
        '   AND EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
        '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
        '                      sk.CODIGO_UNIDAD_SKU ' +
        '                  AND sa.ID_AV_SA = :talla) ' +
        ' LIMIT 1';
    Consulta.ParamByName('art').AsString := ACodigoArticulo;
    Consulta.ParamByName('talla').AsInteger := AIdTalla;
    if AIdColor > 0 then
      Consulta.ParamByName('color').AsInteger := AIdColor;
    Consulta.Open;
    if not Consulta.Eof then
      Result := Consulta.FieldByName('CODIGO_UNIDAD_SKU').AsString;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioGridPivoteCompraUniDAC.BuscarValorAtributo(
  AIdValor: Integer): string;
var
  Consulta: TUniQuery;
begin
  Result := '';
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT AV ' +
      '  FROM fza_atributos_valores ' +
      ' WHERE ID_AV = :talla ' +
      ' LIMIT 1';
    Consulta.ParamByName('talla').AsInteger := AIdValor;
    Consulta.Open;
    if not Consulta.Eof then
      Result := Consulta.FieldByName('AV').AsString;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TRepositorioGridPivoteCompraUniDAC.AsegurarSkuConAtributos(
  const ACodigoSku, ACodigoArticulo, ACodigoVariacion,
    AUsuario: string;
  AIdColor, AIdTalla: Integer);
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_skus ' +
      '  (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
      '   ESACTIVO_SKU, INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, ' +
      '   USUARIO_MODIF) ' +
      'VALUES (:sku, :art, :varsku, ''S'', NOW(), :u, NOW(), :u)';
    Consulta.ParamByName('sku').AsString := ACodigoSku;
    Consulta.ParamByName('art').AsString := ACodigoArticulo;
    Consulta.ParamByName('varsku').AsString := ACodigoVariacion;
    Consulta.ParamByName('u').AsString := AUsuario;
    Consulta.ExecSQL;
    if AIdColor > 0 then
    begin
      Consulta.SQL.Text :=
        'INSERT IGNORE INTO fza_atributos_sku ' +
        '  (CODIGO_UNIDAD_SKU_SA, ID_AV_SA, INSTANTE_ALTA, ' +
        '   USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:sku, :av, NOW(), :u, NOW(), :u)';
      Consulta.ParamByName('sku').AsString := ACodigoSku;
      Consulta.ParamByName('av').AsInteger := AIdColor;
      Consulta.ParamByName('u').AsString := AUsuario;
      Consulta.ExecSQL;
    end;
    Consulta.SQL.Text :=
      'INSERT IGNORE INTO fza_atributos_sku ' +
      '  (CODIGO_UNIDAD_SKU_SA, ID_AV_SA, INSTANTE_ALTA, ' +
      '   USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:sku, :av, NOW(), :u, NOW(), :u)';
    Consulta.ParamByName('sku').AsString := ACodigoSku;
    Consulta.ParamByName('av').AsInteger := AIdTalla;
    Consulta.ParamByName('u').AsString := AUsuario;
    Consulta.ExecSQL;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioGridPivoteCompraUniDAC.BuscarTipoVariacion(
  const ACodigoArticulo: string): string;
var
  Consulta: TUniQuery;
begin
  Result := '';
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT COALESCE(NULLIF(TIPO_VARIACION_ART, ''''), ''TC'') ' +
      '       AS VARSKU ' +
      '  FROM fza_articulos ' +
      ' WHERE CODIGO_ART_ART = :art ' +
      ' LIMIT 1';
    Consulta.ParamByName('art').AsString := ACodigoArticulo;
    Consulta.Open;
    if not Consulta.IsEmpty then
      Result := Consulta.FieldByName('VARSKU').AsString;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TRepositorioGridPivoteCompraUniDAC.AsegurarSkuColor(
  const ACodigoSku, ACodigoArticulo, ACodigoVariacion,
    AUsuario: string;
  AIdColor: Integer);
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'INSERT INTO fza_articulos_skus ' +
      '  (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
      '   ESACTIVO_SKU, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:sku, :art, :varsku, ''S'', NOW(), :usuario, ' +
      '        NOW(), :usuario) ' +
      'ON DUPLICATE KEY UPDATE ESACTIVO_SKU = ''S'', ' +
      '  INSTANTE_MODIF = NOW(), USUARIO_MODIF = :usuario';
    Consulta.ParamByName('sku').AsString := ACodigoSku;
    Consulta.ParamByName('art').AsString := ACodigoArticulo;
    Consulta.ParamByName('varsku').AsString := ACodigoVariacion;
    Consulta.ParamByName('usuario').AsString := AUsuario;
    Consulta.Execute;
    Consulta.SQL.Text :=
      'INSERT IGNORE INTO fza_atributos_sku ' +
      '  (CODIGO_UNIDAD_SKU_SA, ID_AV_SA, INSTANTE_ALTA, ' +
      '   USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:sku, :av, NOW(), :usuario, NOW(), :usuario)';
    Consulta.ParamByName('sku').AsString := ACodigoSku;
    Consulta.ParamByName('av').AsInteger := AIdColor;
    Consulta.ParamByName('usuario').AsString := AUsuario;
    Consulta.Execute;
  finally
    FreeAndNil(Consulta);
  end;
end;

function CrearRepositorioGridPivoteCompraUniDAC(
  AConexion: TUniConnection): IRepositorioGridPivoteCompra;
begin
  Result := TRepositorioGridPivoteCompraUniDAC.Create(AConexion);
end;

initialization
  TFabricaRepositorioGridPivoteCompra.Registrar(
    CrearRepositorioGridPivoteCompraUniDAC);

end.
