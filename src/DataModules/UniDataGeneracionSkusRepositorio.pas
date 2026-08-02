{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataGeneracionSkusRepositorio                             }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       FactuZam                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC para configurar atributos y generar SKU.              }
{******************************************************************************}
unit UniDataGeneracionSkusRepositorio;

interface

uses
  Uni, inLibGeneracionSkusPersistenciaIntf;

function CrearRepositorioGeneracionSkusUniDAC(
  AConexion: TUniConnection): IRepositorioGeneracionSkus;

implementation

uses
  System.SysUtils, Data.DB;

const
  SQL_MAESTRO =
    'SELECT aca.CODIGO_ART_ACA, aca.ID_VA_ACA AS ID_ATB_VA, ' +
    'va.ID_VAR_VA, COALESCE(va.NOMBRE_VA, aca.ID_VA_ACA) ' +
    'AS NOMBRE_ATRIBUTO, va.ORDEN_VA, aca.ORDEN_ACA ' +
    'FROM fza_articulos_conjuntos_asign aca ' +
    'JOIN fza_variaciones_atributos va ' +
    'ON va.ID_ATB_VA = aca.ID_VA_ACA AND va.ID_VAR_VA = :var ' +
    'WHERE aca.CODIGO_ART_ACA = :art ' +
    'ORDER BY aca.ORDEN_ACA, va.ORDEN_VA';
  SQL_DETALLE =
    'SELECT ID_ATB_VA, MAX(ID_AC) AS ID_AC, NOMBRE_AC, ' +
    'MIN(ORDEN_AV) AS ORDEN_AV, 0 AS ASIGNADO FROM (' +
    'SELECT atr.ID_ATB_VA, val.ID_AV AS ID_AC, ' +
    'val.AV AS NOMBRE_AC, det.ORDEN_ACD AS ORDEN_AV ' +
    'FROM fza_variaciones_atributos atr ' +
    'JOIN fza_articulos_conjuntos_asign asign ' +
    'ON asign.ID_VA_ACA = atr.ID_ATB_VA ' +
    'AND asign.CODIGO_ART_ACA = :Articulo ' +
    'JOIN fza_atributos_conjuntos_det det ' +
    'ON det.ID_AC_ACD = asign.ID_AC_ACA ' +
    'JOIN fza_atributos_valores val ON val.ID_AV = det.ID_AV_ACD ' +
    'WHERE atr.ID_VAR_VA = :Variacion UNION ' +
    'SELECT atr.ID_ATB_VA, val.ID_AV AS ID_AC, ' +
    'val.AV AS NOMBRE_AC, val.ORDEN_AV AS ORDEN_AV ' +
    'FROM fza_variaciones_atributos atr ' +
    'JOIN fza_atributos_valores val ON val.ID_VA_AV = atr.ID_ATB_VA ' +
    'JOIN fza_atributos_sku asku ON asku.ID_AV_SA = val.ID_AV ' +
    'JOIN fza_articulos_skus skus ' +
    'ON skus.CODIGO_UNIDAD_SKU = asku.CODIGO_UNIDAD_SKU_SA ' +
    'AND skus.CODIGO_ART_SKU = :Articulo ' +
    'WHERE atr.ID_VAR_VA = :Variacion) AS combinados ' +
    'GROUP BY ID_ATB_VA, NOMBRE_AC ORDER BY ORDEN_AV';
  SQL_ASEGURAR_FILAS =
    'INSERT IGNORE INTO fza_articulos_conjuntos_asign ' +
    '(CODIGO_ART_ACA, ID_AC_ACA, ID_VA_ACA, ORDEN_ACA, ' +
    'ESGENERACION_AUTO_ACA, INSTANTE_ALTA, USUARIO_ALTA, ' +
    'USUARIO_MODIF) ' +
    'SELECT :art, 0, va.ID_ATB_VA, va.ORDEN_VA, ''S'', ' +
    'CURRENT_TIMESTAMP, ''SISTEMA'', ''SISTEMA'' ' +
    'FROM fza_variaciones_atributos va WHERE va.ID_VAR_VA = :var';
  SQL_NORMALIZAR_ORDEN_FILAS =
    'UPDATE fza_articulos_conjuntos_asign aca ' +
    'JOIN fza_variaciones_atributos va ' +
    'ON va.ID_ATB_VA = aca.ID_VA_ACA AND va.ID_VAR_VA = :var ' +
    'SET aca.ORDEN_ACA = va.ORDEN_VA ' +
    'WHERE aca.CODIGO_ART_ACA = :art AND aca.ORDEN_ACA = 0';
  SQL_OBTENER_CONJUNTO =
    'SELECT aca.ID_AC_ACA, ac.NOMBRE_AC ' +
    'FROM fza_articulos_conjuntos_asign aca ' +
    'LEFT JOIN fza_atributos_conjuntos ac ON ac.ID_AC = aca.ID_AC_ACA ' +
    'WHERE aca.CODIGO_ART_ACA = :Articulo ' +
    'AND aca.ID_VA_ACA = :Atributo';
  SQL_SIGUIENTE_ORDEN_CONJUNTO =
    'SELECT (FLOOR(COALESCE(MAX(ORDEN_ACD), 0) / 10) + 1) * 10 ' +
    'AS SIGUIENTE_ORDEN FROM fza_atributos_conjuntos_det ' +
    'WHERE ID_AC_ACD = :IdConjunto';
  SQL_SIGUIENTE_ORDEN_ATRIBUTO =
    'SELECT (FLOOR(COALESCE(MAX(ORDEN_AV), 0) / 10) + 1) * 10 ' +
    'AS SIGUIENTE_ORDEN FROM fza_atributos_valores ' +
    'WHERE ID_VA_AV = :IdAtributo';
  SQL_BUSCAR_VALOR =
    'SELECT ID_AV FROM fza_atributos_valores ' +
    'WHERE ID_VA_AV = :IdVa AND TRIM(UPPER(AV)) = UPPER(:Valor)';
  SQL_INSERTAR_VALOR =
    'INSERT INTO fza_atributos_valores (ID_VA_AV, AV, ORDEN_AV, ' +
    'INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:IdVa, :Valor, :Orden, CURRENT_TIMESTAMP, ''SISTEMA'', ' +
    '''SISTEMA'')';
  SQL_ULTIMO_ID = 'SELECT LAST_INSERT_ID() AS NUEVO_ID';
  SQL_GUARDAR_VALOR_CONJUNTO =
    'INSERT IGNORE INTO fza_atributos_conjuntos_det (ID_AC_ACD, ' +
    'ID_AV_ACD, ORDEN_ACD, INSTANTE_ALTA, USUARIO_ALTA, ' +
    'USUARIO_MODIF) VALUES (:Conj, :Val, :Orden, CURRENT_TIMESTAMP, ' +
    '''SISTEMA'', ''SISTEMA'')';
  SQL_GUARDAR_SKU =
    'INSERT IGNORE INTO fza_articulos_skus ' +
    '(CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
    'ESACTIVO_SKU, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:cod, :art, :var, ''S'', CURRENT_TIMESTAMP, ' +
    '''SISTEMA'', ''SISTEMA'')';
  SQL_GUARDAR_ATRIBUTO_SKU =
    'INSERT IGNORE INTO fza_atributos_sku ' +
    '(CODIGO_UNIDAD_SKU_SA, ID_AV_SA) VALUES (:cod, :val)';
  SQL_GUARDAR_ORDEN_ATRIBUTO =
    'INSERT INTO fza_articulos_conjuntos_asign ' +
    '(CODIGO_ART_ACA, ID_AC_ACA, ID_VA_ACA, ORDEN_ACA, ' +
    'ESGENERACION_AUTO_ACA, INSTANTE_ALTA, USUARIO_ALTA, ' +
    'USUARIO_MODIF) VALUES (:art, 0, :atr, :ord, ''S'', ' +
    'CURRENT_TIMESTAMP, ''SISTEMA'', ''SISTEMA'') ' +
    'ON DUPLICATE KEY UPDATE ORDEN_ACA = VALUES(ORDEN_ACA), ' +
    'USUARIO_MODIF = VALUES(USUARIO_MODIF)';
  SQL_GUARDAR_ORDEN_VALOR =
    'UPDATE fza_atributos_valores SET ORDEN_AV = :orden ' +
    'WHERE ID_AV = :id';
  SQL_GUARDAR_ORDEN_VALOR_CONJUNTO =
    'UPDATE fza_atributos_conjuntos_det SET ORDEN_ACD = :orden ' +
    'WHERE ID_AV_ACD = :id';

type
  TDatosGeneracionSkusUniDAC = class(
    TInterfacedObject,
    IDatosGeneracionSkus)
  private
    FConexion: TUniConnection;
    FCodigoArticulo: string;
    FTipoVariacion: string;
    FMaestro: TUniQuery;
    FDetalle: TUniQuery;
    FOrigenMaestro: TDataSource;
  public
    constructor Create(
      AConexion: TUniConnection;
      const ACodigoArticulo: string;
      const ATipoVariacion: string);
    destructor Destroy; override;
    function Maestro: TDataSet;
    function Detalle: TDataSet;
    procedure RecargarMaestro;
  end;

  TRepositorioGeneracionSkusUniDAC = class(
    TInterfacedObject,
    IRepositorioGeneracionSkus)
  private
    FConexion: TUniConnection;
    procedure AsegurarFilas(
      const ACodigoArticulo: string;
      const ATipoVariacion: string);
  public
    constructor Create(AConexion: TUniConnection);
    function PrepararDatos(
      const ACodigoArticulo: string;
      const ATipoVariacion: string
    ): IDatosGeneracionSkus;
    function ObtenerConjuntoAtributo(
      const ACodigoArticulo: string;
      const AIdAtributo: string
    ): TConjuntoAtributoSku;
    function CalcularSiguienteOrdenValor(
      const AIdAtributo: string;
      AIdConjunto: Integer
    ): Integer;
    function AsegurarValor(
      const AIdAtributo: string;
      const ANombre: string;
      AOrden: Integer
    ): Integer;
    procedure GuardarValorEnConjunto(
      AIdConjunto: Integer;
      AIdValor: Integer;
      AOrden: Integer);
    procedure GuardarSku(
      const ACodigoSku: string;
      const ACodigoArticulo: string;
      const ATipoVariacion: string;
      const AIdsValores: TArray<Integer>);
    procedure GuardarOrdenAtributo(
      const ACodigoArticulo: string;
      const AIdAtributo: string;
      AOrden: Integer);
    function ObtenerNombreConjunto(
      const ACodigoArticulo: string;
      const AIdAtributo: string
    ): string;
    procedure GuardarOrdenValor(
      AIdValor: Integer;
      AOrden: Integer);
  end;

constructor TDatosGeneracionSkusUniDAC.Create(
  AConexion: TUniConnection;
  const ACodigoArticulo: string;
  const ATipoVariacion: string);
begin
  inherited Create;
  FConexion := AConexion;
  FCodigoArticulo := ACodigoArticulo;
  FTipoVariacion := ATipoVariacion;
  FMaestro := TUniQuery.Create(nil);
  FMaestro.Connection := FConexion;
  FMaestro.SQL.Text := SQL_MAESTRO;
  FOrigenMaestro := TDataSource.Create(nil);
  FOrigenMaestro.DataSet := FMaestro;
  FDetalle := TUniQuery.Create(nil);
  FDetalle.Connection := FConexion;
  FDetalle.SQL.Text := SQL_DETALLE;
  FDetalle.Options.LocalMasterDetail := True;
  FDetalle.CachedUpdates := True;
  FDetalle.MasterSource := FOrigenMaestro;
  FDetalle.MasterFields := 'ID_ATB_VA';
  RecargarMaestro;
end;

destructor TDatosGeneracionSkusUniDAC.Destroy;
begin
  FreeAndNil(FDetalle);
  FreeAndNil(FOrigenMaestro);
  FreeAndNil(FMaestro);
  inherited;
end;

function TDatosGeneracionSkusUniDAC.Maestro: TDataSet;
begin
  Result := FMaestro;
end;

function TDatosGeneracionSkusUniDAC.Detalle: TDataSet;
begin
  Result := FDetalle;
end;

procedure TDatosGeneracionSkusUniDAC.RecargarMaestro;
begin
  FDetalle.Close;
  FMaestro.Close;
  FMaestro.ParamByName('var').AsString := FTipoVariacion;
  FMaestro.ParamByName('art').AsString := FCodigoArticulo;
  FMaestro.Open;
  FDetalle.ParamByName('Articulo').AsString := FCodigoArticulo;
  FDetalle.ParamByName('Variacion').AsString := FTipoVariacion;
  FDetalle.Open;
  FDetalle.FieldByName('ASIGNADO').ReadOnly := False;
  FDetalle.FieldByName('ID_ATB_VA').ReadOnly := False;
  FDetalle.FieldByName('ID_AC').ReadOnly := False;
  FDetalle.FieldByName('NOMBRE_AC').ReadOnly := False;
  if FDetalle.FindField('ORDEN_AV') <> nil then
  begin
    FDetalle.FieldByName('ORDEN_AV').ReadOnly := False;
  end;
end;

constructor TRepositorioGeneracionSkusUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

procedure TRepositorioGeneracionSkusUniDAC.AsegurarFilas(
  const ACodigoArticulo: string;
  const ATipoVariacion: string);
begin
  FConexion.ExecSQL(
    SQL_ASEGURAR_FILAS,
    [ACodigoArticulo, ATipoVariacion]);
  FConexion.ExecSQL(
    SQL_NORMALIZAR_ORDEN_FILAS,
    [ATipoVariacion, ACodigoArticulo]);
end;

function TRepositorioGeneracionSkusUniDAC.PrepararDatos(
  const ACodigoArticulo: string;
  const ATipoVariacion: string): IDatosGeneracionSkus;
begin
  AsegurarFilas(ACodigoArticulo, ATipoVariacion);
  Result := TDatosGeneracionSkusUniDAC.Create(
    FConexion,
    ACodigoArticulo,
    ATipoVariacion);
end;

function TRepositorioGeneracionSkusUniDAC.ObtenerConjuntoAtributo(
  const ACodigoArticulo: string;
  const AIdAtributo: string): TConjuntoAtributoSku;
var
  oConsulta: TUniQuery;
begin
  Result.Id := 0;
  Result.Nombre := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_OBTENER_CONJUNTO;
    oConsulta.ParamByName('Articulo').AsString := ACodigoArticulo;
    oConsulta.ParamByName('Atributo').AsString := AIdAtributo;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result.Id := oConsulta.FieldByName('ID_AC_ACA').AsInteger;
      Result.Nombre := oConsulta.FieldByName('NOMBRE_AC').AsString;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioGeneracionSkusUniDAC.CalcularSiguienteOrdenValor(
  const AIdAtributo: string;
  AIdConjunto: Integer): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 10;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    if AIdConjunto > 0 then
    begin
      oConsulta.SQL.Text := SQL_SIGUIENTE_ORDEN_CONJUNTO;
      oConsulta.ParamByName('IdConjunto').AsInteger := AIdConjunto;
    end
    else
    begin
      oConsulta.SQL.Text := SQL_SIGUIENTE_ORDEN_ATRIBUTO;
      oConsulta.ParamByName('IdAtributo').AsString := AIdAtributo;
    end;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result := oConsulta.FieldByName('SIGUIENTE_ORDEN').AsInteger;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioGeneracionSkusUniDAC.AsegurarValor(
  const AIdAtributo: string;
  const ANombre: string;
  AOrden: Integer): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_BUSCAR_VALOR;
    oConsulta.ParamByName('IdVa').AsString := AIdAtributo;
    oConsulta.ParamByName('Valor').AsString := ANombre;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result := oConsulta.FieldByName('ID_AV').AsInteger;
    end
    else
    begin
      FConexion.ExecSQL(
        SQL_INSERTAR_VALOR,
        [AIdAtributo, ANombre, AOrden]);
      oConsulta.Close;
      oConsulta.SQL.Text := SQL_ULTIMO_ID;
      oConsulta.Open;
      Result := oConsulta.FieldByName('NUEVO_ID').AsInteger;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioGeneracionSkusUniDAC.GuardarValorEnConjunto(
  AIdConjunto: Integer;
  AIdValor: Integer;
  AOrden: Integer);
begin
  FConexion.ExecSQL(
    SQL_GUARDAR_VALOR_CONJUNTO,
    [AIdConjunto, AIdValor, AOrden]);
end;

procedure TRepositorioGeneracionSkusUniDAC.GuardarSku(
  const ACodigoSku: string;
  const ACodigoArticulo: string;
  const ATipoVariacion: string;
  const AIdsValores: TArray<Integer>);
var
  iIdValor: Integer;
begin
  FConexion.ExecSQL(
    SQL_GUARDAR_SKU,
    [ACodigoSku, ACodigoArticulo, ATipoVariacion]);
  for iIdValor in AIdsValores do
  begin
    FConexion.ExecSQL(
      SQL_GUARDAR_ATRIBUTO_SKU,
      [ACodigoSku, iIdValor]);
  end;
end;

procedure TRepositorioGeneracionSkusUniDAC.GuardarOrdenAtributo(
  const ACodigoArticulo: string;
  const AIdAtributo: string;
  AOrden: Integer);
begin
  FConexion.ExecSQL(
    SQL_GUARDAR_ORDEN_ATRIBUTO,
    [ACodigoArticulo, AIdAtributo, AOrden]);
end;

function TRepositorioGeneracionSkusUniDAC.ObtenerNombreConjunto(
  const ACodigoArticulo: string;
  const AIdAtributo: string): string;
var
  oConjunto: TConjuntoAtributoSku;
begin
  oConjunto := ObtenerConjuntoAtributo(
    ACodigoArticulo,
    AIdAtributo);
  Result := oConjunto.Nombre;
end;

procedure TRepositorioGeneracionSkusUniDAC.GuardarOrdenValor(
  AIdValor: Integer;
  AOrden: Integer);
begin
  FConexion.ExecSQL(
    SQL_GUARDAR_ORDEN_VALOR,
    [AOrden, AIdValor]);
  FConexion.ExecSQL(
    SQL_GUARDAR_ORDEN_VALOR_CONJUNTO,
    [AOrden, AIdValor]);
end;

function CrearRepositorioGeneracionSkusUniDAC(
  AConexion: TUniConnection): IRepositorioGeneracionSkus;
begin
  Result := TRepositorioGeneracionSkusUniDAC.Create(AConexion);
end;

end.
