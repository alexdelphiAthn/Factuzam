{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCambioArticuloColorRepositorio                         }
{    Tipo:       Repositorio UniDAC                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Recodifica artículos o colores y todas sus referencias lógicas.           }
{    Cualquier referencia en líneas de factura veta la operación.              }
{******************************************************************************}
unit UniDataCambioArticuloColorRepositorio;

interface

uses
  Uni,
  inLibCambioArticuloColorIntf;

function CrearRepositorioCambioArticuloColorUniDAC(
  AConexion: TUniConnection): IRepositorioCambioArticuloColor;

implementation

uses
  System.SysUtils,
  System.Classes,
  Data.DB;

const
  TABLA_TEMPORAL = 'tmp_fza_cambio_unidades';
  REFERENCIA_SKU_MAESTRO =
    'fza_articulos_skus|CODIGO_UNIDAD_SKU';

  REFERENCIAS_ARTICULO: array[0..29] of string = (
    'fza_articulos_atributos_basicos|CODIGO_ART_AAB',
    'fza_articulos_conjuntos_asign|CODIGO_ART_ACA',
    'fza_articulos_fotos|CODIGO_ART_FOT',
    'fza_articulos_pdte_recibir|CODIGO_ART_PDR',
    'fza_articulos_propiedades|CODIGO_ART_ART',
    'fza_articulos_proveedores|CODIGO_ART_AP',
    'fza_articulos_skus|CODIGO_ART_SKU',
    'fza_articulos_tarifas|CODIGO_ART_ARTTAR',
    'fza_articulos_vinculos|CODIGO_ART_PADRE_ARTVIN',
    'fza_articulos_vinculos|CODIGO_ART_HIJO_ARTVIN',
    'fza_atributos_valores|CODIGO_ART_EXTRA_AV',
    'fza_compras_sesiones_fotos|CODIGO_ART_TENTATIVO_CSF',
    'fza_compras_sesiones_lineas|CODIGO_ART_TENTATIVO_SESLIN',
    'fza_compras_sesiones_lineas|CODIGO_ART_REUSAR_SESLIN',
    'fza_depositos_cliente|CODIGO_ART_DEP',
    'fza_documentos_trabajo_lineas|CODIGO_ART_DTL',
    'fza_inventarios_lineas|CODIGO_ART_INVLIN',
    'fza_inventarios_recuentos|CODIGO_ART_INVREC',
    'fza_movimientos_almacen|CODIGO_ART_MOV',
    'fza_pedidos_compra_lineas|CODIGO_ART_PEDCLIN',
    'fza_albaranes_compra_lineas|CODIGO_ART_ALBCLIN',
    'fza_devoluciones_compra_lineas|CODIGO_ART_DEVCLIN',
    'fza_facturas_compra_lineas|CODIGO_ART_FACCLIN',
    'fza_pedidos_lineas|CODIGO_ART_PEDLIN',
    'fza_albaranes_lineas|CODIGO_ART_ALBLIN',
    'fza_proformas_caja_lineas|CODIGO_ART_PROCLIN',
    'fza_tarifas_cambios_lineas|CODIGO_ART_TARCLIN',
    'fza_traspasos_solicitudes_lineas|CODIGO_ART_TRSOLLIN',
    'inv_catalogo|codigo_articulo',
    'inv_eventos|codigo_articulo'
  );

  REFERENCIAS_UNIDAD: array[0..25] of string = (
    'fza_articulos_fotos|CODIGO_UNIDAD_FOT',
    'fza_articulos_pdte_recibir|CODIGO_UNIDAD_PDR',
    'fza_articulos_propiedades|CODIGO_UNIDAD_ARTPROP',
    'fza_articulos_skus|CODIGO_UNIDAD_SKU',
    'fza_articulos_skus_costes|CODIGO_UNIDAD_SKU_SKUC',
    'fza_articulos_stockactual|CODIGO_UNIDAD_STK',
    'fza_articulos_tarifas|CODIGO_UNIDAD_ARTTAR',
    'fza_atributos_sku|CODIGO_UNIDAD_SKU_SA',
    'fza_codigos_barras|CODIGO_UNIDAD_CB',
    'fza_compras_sesiones_fotos|CODIGO_UNIDAD_CSF',
    'fza_depositos_cliente|CODIGO_UNIDAD_DEP',
    'fza_documentos_trabajo_lineas|CODIGO_UNIDAD_DTL',
    'fza_inventarios_lineas|CODIGO_UNIDAD_INVLIN',
    'fza_inventarios_recuentos|CODIGO_UNIDAD_INVREC',
    'fza_movimientos_almacen|CODIGO_UNIDAD_MOV',
    'fza_pedidos_compra_lineas|CODIGO_UNIDAD_PEDCLIN',
    'fza_albaranes_compra_lineas|CODIGO_UNIDAD_ALBCLIN',
    'fza_devoluciones_compra_lineas|CODIGO_UNIDAD_DEVCLIN',
    'fza_facturas_compra_lineas|CODIGO_UNIDAD_FACCLIN',
    'fza_pedidos_lineas|CODIGO_UNIDAD_PEDLIN',
    'fza_albaranes_lineas|CODIGO_UNIDAD_ALBLIN',
    'fza_proformas_caja_lineas|CODIGO_UNIDAD_PROCLIN',
    'fza_tarifas_cambios_lineas|CODIGO_UNIDAD_SKU_TARCLIN',
    'fza_traspasos_solicitudes_lineas|CODIGO_UNIDAD_TRSOLLIN',
    'inv_catalogo|codigo_unidad',
    'inv_eventos|codigo_unidad'
  );

  REFERENCIAS_ATRIBUTOS: array[0..6] of string = (
    'fza_albaranes_compra_lineas|CODIGO_UNIDAD_ALBCLIN|ALBCLIN',
    'fza_albaranes_lineas|CODIGO_UNIDAD_ALBLIN|ALBLIN',
    'fza_devoluciones_compra_lineas|CODIGO_UNIDAD_DEVCLIN|DEVCLIN',
    'fza_documentos_trabajo_lineas|CODIGO_UNIDAD_DTL|DTL',
    'fza_facturas_compra_lineas|CODIGO_UNIDAD_FACCLIN|FACCLIN',
    'fza_pedidos_compra_lineas|CODIGO_UNIDAD_PEDCLIN|PEDCLIN',
    'fza_pedidos_lineas|CODIGO_UNIDAD_PEDLIN|PEDLIN'
  );

type
  TRepositorioCambioArticuloColorUniDAC = class(
    TInterfacedObject,
    IRepositorioCambioArticuloColor)
  private
    FConexion: TUniConnection;
    procedure Ejecutar(
      const ASql: string;
      const ANombres, AValores: array of string);
    function Existe(
      const ASql: string;
      const ANombres, AValores: array of string): Boolean;
    function EscalarEntero(
      const ASql: string;
      const ANombres, AValores: array of string): Integer;
    function CampoExiste(
      const ATabla, ACampo: string): Boolean;
    procedure SepararReferencia(
      const AReferencia: string;
      out ATabla, ACampo: string);
    procedure SepararReferenciaAtributos(
      const AReferencia: string;
      out ATabla, ACampoUnidad, ASufijo: string);
    function CondicionInstantaneaColor(
      const AAlias, ACampoValor, ACampoNombre, AParametro: string): string;
    function ExpresionConteoValoresAtributos(
      const ATabla, AAlias, ASufijo, AParametro: string): string;
    function CondicionInstantaneaColorSegura(
      const AAlias, ACampoValor, ACampoNombre, AParametro,
      AConteoValores: string): string;
    procedure PrepararTablaTemporal;
    procedure EliminarTablaTemporal;
    procedure IniciarTransaccion;
    procedure FinalizarTransaccion(
      const AResultado: TResultadoCambioArticuloColor);
    procedure BloquearArticulos(
      const AArticuloAntiguo, AArticuloNuevo: string);
    procedure BloquearColores(
      const AColorAntiguo, AColorNuevo: string);
    function ExisteArticulo(const AArticulo: string): Boolean;
    function ExisteColor(const AColor: string): Boolean;
    procedure ConstruirMapaArticulo(
      const AArticuloAntiguo, AArticuloNuevo: string);
    procedure AgregarMapaArticuloReferencias(
      const AArticuloAntiguo, AArticuloNuevo: string);
    procedure ConstruirMapaColor(
      const AColorAntiguo, AColorNuevo: string);
    procedure AgregarMapaColorReferencias(
      const AColorAntiguo, AColorNuevo: string);
    function NumeroSkuMapa: Integer;
    function MapaArticuloEsCompleto(
      const AArticuloAntiguo: string): Boolean;
    function MapaColorEsCompleto(
      const AColorAntiguo: string): Boolean;
    function MapaTieneCodigosLargos: Boolean;
    function MapaTieneDestinosDuplicados: Boolean;
    function HayVentasArticulo(
      const AArticuloAntiguo: string): Boolean;
    function HayVentasColor(const AColorAntiguo: string): Boolean;
    function HayDestinoEnVentasArticulo(
      const AArticuloNuevo: string): Boolean;
    function HayDestinoEnVentasColor(
      const AColorNuevo: string): Boolean;
    function HayPrestaShopArticulo(
      const AArticuloAntiguo: string): Boolean;
    function HayPrestaShopColor: Boolean;
    function HayDestinoEnReferencias(
      const AReferencias: array of string): Boolean;
    function HayOrigenEnReferencias(
      const AReferencias: array of string): Boolean;
    function HayUnidadesArticuloSinMapa(
      const AArticuloAntiguo: string): Boolean;
    function HayUnidadesColorSinMapa(
      const AColorAntiguo: string): Boolean;
    procedure ActualizarCampoPorValor(
      const ATabla, ACampo, AAnterior, ANuevo, AUsuario: string);
    procedure ActualizarCampoPorMapa(
      const ATabla, ACampo, AUsuario: string);
    procedure ActualizarReferenciasArticulo(
      const AAnterior, ANuevo, AUsuario: string);
    procedure ActualizarReferenciasUnidad(const AUsuario: string);
    procedure ActualizarSkuMaestro(const AUsuario: string);
    procedure ActualizarArticuloMaestro(
      const AAnterior, ANuevo, AUsuario: string);
    procedure ActualizarColorMaestro(
      const AAnterior, ANuevo, AUsuario: string);
    function SqlActualizacionAtributos(
      const ATabla, ACampoUnidad, ASufijo: string): string;
    function SqlActualizacionDescripcion(
      const ATabla, ACampoUnidad, ASufijo: string): string;
    procedure ActualizarInstantaneasColor(
      const AAnterior, ANuevo, AUsuario: string);
    function HayInstantaneasColorAntiguo(
      const AColorAntiguo: string): Boolean;
    function HayInstantaneasColorSinMapa(
      const AColorAntiguo: string): Boolean;
    function HayInstantaneasColorAmbiguas(
      const AColorAntiguo: string): Boolean;
    function HayDescripcionesColorAmbiguas(
      const AColorAntiguo: string): Boolean;
    function ValidarCambioArticulo(
      const AAnterior, ANuevo: string): TResultadoCambioArticuloColor;
    function ValidarCambioColor(
      const AAnterior, ANuevo: string): TResultadoCambioArticuloColor;
    function VerificarCambioArticulo(
      const AArticuloAntiguo: string): Boolean;
    function VerificarCambioColor(
      const AColorAntiguo: string): Boolean;
  public
    constructor Create(AConexion: TUniConnection);
    function CambiarArticulo(
      const AArticuloAntiguo, AArticuloNuevo, AUsuario: string):
      TResultadoCambioArticuloColor;
    function CambiarColor(
      const AColorAntiguo, AColorNuevo, AUsuario: string):
      TResultadoCambioArticuloColor;
  end;

constructor TRepositorioCambioArticuloColorUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

procedure TRepositorioCambioArticuloColorUniDAC.Ejecutar(
  const ASql: string;
  const ANombres, AValores: array of string);
var
  i: Integer;
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    for i := Low(ANombres) to High(ANombres) do
      if oConsulta.Params.FindParam(ANombres[i]) <> nil then
      begin
        oConsulta.ParamByName(ANombres[i]).AsString := AValores[i];
      end;
    oConsulta.ExecSQL;
  finally
    oConsulta.Free;
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.Existe(
  const ASql: string;
  const ANombres, AValores: array of string): Boolean;
var
  i: Integer;
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    for i := Low(ANombres) to High(ANombres) do
      if oConsulta.Params.FindParam(ANombres[i]) <> nil then
      begin
        oConsulta.ParamByName(ANombres[i]).AsString := AValores[i];
      end;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    oConsulta.Free;
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.EscalarEntero(
  const ASql: string;
  const ANombres, AValores: array of string): Integer;
var
  i: Integer;
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    for i := Low(ANombres) to High(ANombres) do
      if oConsulta.Params.FindParam(ANombres[i]) <> nil then
      begin
        oConsulta.ParamByName(ANombres[i]).AsString := AValores[i];
      end;
    oConsulta.Open;
    Result := oConsulta.Fields[0].AsInteger;
  finally
    oConsulta.Free;
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.CampoExiste(
  const ATabla, ACampo: string): Boolean;
const
  SQL_CAMPO_EXISTE =
    'SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS ' +
    'WHERE TABLE_SCHEMA = DATABASE() ' +
    'AND TABLE_NAME = :TABLA AND COLUMN_NAME = :CAMPO LIMIT 1';
begin
  Result := Existe(
    SQL_CAMPO_EXISTE,
    ['TABLA', 'CAMPO'],
    [ATabla, ACampo]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.SepararReferencia(
  const AReferencia: string;
  out ATabla, ACampo: string);
var
  iSeparador: Integer;
begin
  iSeparador := Pos('|', AReferencia);
  ATabla := Copy(AReferencia, 1, iSeparador - 1);
  ACampo := Copy(AReferencia, iSeparador + 1, MaxInt);
end;

procedure TRepositorioCambioArticuloColorUniDAC.
  SepararReferenciaAtributos(
    const AReferencia: string;
    out ATabla, ACampoUnidad, ASufijo: string);
var
  iPrimerSeparador: Integer;
  iSegundoSeparador: Integer;
begin
  iPrimerSeparador := Pos('|', AReferencia);
  iSegundoSeparador := Pos(
    '|',
    AReferencia,
    iPrimerSeparador + 1);
  ATabla := Copy(AReferencia, 1, iPrimerSeparador - 1);
  ACampoUnidad := Copy(
    AReferencia,
    iPrimerSeparador + 1,
    iSegundoSeparador - iPrimerSeparador - 1);
  ASufijo := Copy(AReferencia, iSegundoSeparador + 1, MaxInt);
end;

function TRepositorioCambioArticuloColorUniDAC.
  CondicionInstantaneaColor(
    const AAlias, ACampoValor, ACampoNombre, AParametro: string): string;
var
  sNombreVacioColor: string;
begin
  sNombreVacioColor := '';
  if SameText(Copy(ACampoValor, 1, 6), 'ATTR1_') then
  begin
    sNombreVacioColor := ' OR TRIM(COALESCE(' + AAlias + '.`' +
      ACampoNombre + '`, '''')) = ''''';
  end;
  Result := '(TRIM(' + AAlias + '.`' + ACampoValor + '`) = TRIM(:' +
    AParametro + ') AND (UPPER(TRIM(' + AAlias + '.`' +
    ACampoNombre + '`)) IN (''COLOR'', ''CO'') OR EXISTS (' +
    'SELECT 1 FROM `fza_variaciones_atributos` va ' +
    'WHERE va.`ID_ATB_VA` = ''CO'' AND UPPER(TRIM(va.`NOMBRE_VA`)) = ' +
    'UPPER(TRIM(' + AAlias + '.`' + ACampoNombre + '`)))' +
    sNombreVacioColor + '))';
end;

procedure TRepositorioCambioArticuloColorUniDAC.PrepararTablaTemporal;
begin
  EliminarTablaTemporal;
  Ejecutar(
    'CREATE TEMPORARY TABLE `' + TABLA_TEMPORAL + '` (' +
    '`ORIGEN` varchar(255) NOT NULL, ' +
    '`DESTINO` varchar(255) NOT NULL, ' +
    '`ES_SKU` char(1) NOT NULL DEFAULT ''S'', ' +
    'PRIMARY KEY (`ORIGEN`), KEY `IDX_DESTINO` (`DESTINO`)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ' +
    'COLLATE=utf8mb4_spanish_ci',
    [],
    []);
end;

procedure TRepositorioCambioArticuloColorUniDAC.EliminarTablaTemporal;
begin
  Ejecutar(
    'DROP TEMPORARY TABLE IF EXISTS `' + TABLA_TEMPORAL + '`',
    [],
    []);
end;

procedure TRepositorioCambioArticuloColorUniDAC.IniciarTransaccion;
begin
  Ejecutar(
    'SET TRANSACTION ISOLATION LEVEL SERIALIZABLE',
    [],
    []);
  FConexion.StartTransaction;
end;

procedure TRepositorioCambioArticuloColorUniDAC.FinalizarTransaccion(
  const AResultado: TResultadoCambioArticuloColor);
begin
  if AResultado.EsCorrecto then
    FConexion.Commit
  else
    FConexion.Rollback;
end;

procedure TRepositorioCambioArticuloColorUniDAC.BloquearArticulos(
  const AArticuloAntiguo, AArticuloNuevo: string);
begin
  Existe(
    'SELECT `CODIGO_ART_ART` FROM `fza_articulos` ' +
    'WHERE `CODIGO_ART_ART` IN (:ANTERIOR, :NUEVO) FOR UPDATE',
    ['ANTERIOR', 'NUEVO'],
    [AArticuloAntiguo, AArticuloNuevo]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.BloquearColores(
  const AColorAntiguo, AColorNuevo: string);
begin
  Existe(
    'SELECT `ID_AV` FROM `fza_atributos_valores` ' +
    'WHERE `ID_VA_AV` = ''CO'' ' +
    'AND TRIM(`AV`) IN (TRIM(:ANTERIOR), TRIM(:NUEVO)) FOR UPDATE',
    ['ANTERIOR', 'NUEVO'],
    [AColorAntiguo, AColorNuevo]);
end;

function TRepositorioCambioArticuloColorUniDAC.ExisteArticulo(
  const AArticulo: string): Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM `fza_articulos` ' +
    'WHERE `CODIGO_ART_ART` = :ARTICULO LIMIT 1',
    ['ARTICULO'],
    [AArticulo]);
end;

function TRepositorioCambioArticuloColorUniDAC.ExisteColor(
  const AColor: string): Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM `fza_atributos_valores` ' +
    'WHERE `ID_VA_AV` = ''CO'' AND TRIM(`AV`) = TRIM(:COLOR) LIMIT 1',
    ['COLOR'],
    [AColor]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.ConstruirMapaArticulo(
  const AArticuloAntiguo, AArticuloNuevo: string);
begin
  Ejecutar(
    'INSERT INTO `' + TABLA_TEMPORAL + '` ' +
    '(`ORIGEN`, `DESTINO`, `ES_SKU`) ' +
    'SELECT `CODIGO_UNIDAD_SKU`, ' +
    'CONCAT(:NUEVO, SUBSTRING(`CODIGO_UNIDAD_SKU`, ' +
    'CHAR_LENGTH(:ANTERIOR) + 1)), ''S'' ' +
    'FROM `fza_articulos_skus` ' +
    'WHERE `CODIGO_ART_SKU` = :ANTERIOR ' +
    'AND (`CODIGO_UNIDAD_SKU` = :ANTERIOR ' +
    'OR LEFT(`CODIGO_UNIDAD_SKU`, CHAR_LENGTH(:ANTERIOR) + 1) = ' +
    'CONCAT(:ANTERIOR, ''/''))',
    ['ANTERIOR', 'NUEVO'],
    [AArticuloAntiguo, AArticuloNuevo]);
  Ejecutar(
    'INSERT IGNORE INTO `' + TABLA_TEMPORAL + '` ' +
    '(`ORIGEN`, `DESTINO`, `ES_SKU`) ' +
    'VALUES (:ANTERIOR, :NUEVO, ''N'')',
    ['ANTERIOR', 'NUEVO'],
    [AArticuloAntiguo, AArticuloNuevo]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.
  AgregarMapaArticuloReferencias(
    const AArticuloAntiguo, AArticuloNuevo: string);
var
  i: Integer;
  sCampo: string;
  sSql: string;
  sTabla: string;
begin
  for i := Low(REFERENCIAS_UNIDAD) to High(REFERENCIAS_UNIDAD) do
  begin
    SepararReferencia(REFERENCIAS_UNIDAD[i], sTabla, sCampo);
    if CampoExiste(sTabla, sCampo) then
    begin
      sSql := 'INSERT IGNORE INTO `' + TABLA_TEMPORAL + '` ' +
        '(`ORIGEN`, `DESTINO`, `ES_SKU`) ' +
        'SELECT DISTINCT dato.`' + sCampo + '`, ' +
        'CONCAT(:NUEVO, SUBSTRING(dato.`' + sCampo + '`, ' +
        'CHAR_LENGTH(:ANTERIOR) + 1)), ''N'' FROM `' + sTabla +
        '` dato WHERE dato.`' + sCampo + '` = :ANTERIOR OR ' +
        'LEFT(dato.`' + sCampo + '`, CHAR_LENGTH(:ANTERIOR) + 1) = ' +
        'CONCAT(:ANTERIOR, ''/'')';
      Ejecutar(
        sSql,
        ['ANTERIOR', 'NUEVO'],
        [AArticuloAntiguo, AArticuloNuevo]);
    end;
  end;
end;

procedure TRepositorioCambioArticuloColorUniDAC.ConstruirMapaColor(
  const AColorAntiguo, AColorNuevo: string);
begin
  Ejecutar(
    'INSERT INTO `' + TABLA_TEMPORAL + '` ' +
    '(`ORIGEN`, `DESTINO`, `ES_SKU`) ' +
    'SELECT DISTINCT sku.`CODIGO_UNIDAD_SKU`, ' +
    'CONCAT(sku.`CODIGO_ART_SKU`, ''/'', ' +
    'TRIM(BOTH ''/'' FROM REPLACE(CONCAT(''/'', ' +
    'SUBSTRING(sku.`CODIGO_UNIDAD_SKU`, ' +
    'CHAR_LENGTH(sku.`CODIGO_ART_SKU`) + 2), ''/''), ' +
    'CONCAT(''/'', TRIM(av.`AV`), ''/''), ' +
    'CONCAT(''/'', :NUEVO, ''/'')))), ''S'' ' +
    'FROM `fza_articulos_skus` sku ' +
    'JOIN `fza_atributos_sku` sa ON ' +
    'sa.`CODIGO_UNIDAD_SKU_SA` = sku.`CODIGO_UNIDAD_SKU` ' +
    'JOIN `fza_atributos_valores` av ON av.`ID_AV` = sa.`ID_AV_SA` ' +
    'WHERE av.`ID_VA_AV` = ''CO'' ' +
    'AND TRIM(av.`AV`) = TRIM(:ANTERIOR) ' +
    'AND LEFT(sku.`CODIGO_UNIDAD_SKU`, ' +
    'CHAR_LENGTH(sku.`CODIGO_ART_SKU`) + 1) = ' +
    'CONCAT(sku.`CODIGO_ART_SKU`, ''/'') AND ' +
    '(CHAR_LENGTH(CONCAT(''/'', SUBSTRING(' +
    'sku.`CODIGO_UNIDAD_SKU`, ' +
    'CHAR_LENGTH(sku.`CODIGO_ART_SKU`) + 2), ''/'')) - ' +
    'CHAR_LENGTH(REPLACE(CONCAT(''/'', SUBSTRING(' +
    'sku.`CODIGO_UNIDAD_SKU`, ' +
    'CHAR_LENGTH(sku.`CODIGO_ART_SKU`) + 2), ''/''), ' +
    'CONCAT(''/'', TRIM(av.`AV`), ''/''), ''''))) / ' +
    'CHAR_LENGTH(CONCAT(''/'', TRIM(av.`AV`), ''/'')) = 1',
    ['ANTERIOR', 'NUEVO'],
    [AColorAntiguo, AColorNuevo]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.
  AgregarMapaColorReferencias(
    const AColorAntiguo, AColorNuevo: string);
var
  i: Integer;
  sCampo: string;
  sSql: string;
  sTabla: string;
begin
  for i := Low(REFERENCIAS_UNIDAD) to High(REFERENCIAS_UNIDAD) do
  begin
    SepararReferencia(REFERENCIAS_UNIDAD[i], sTabla, sCampo);
    if CampoExiste(sTabla, sCampo) then
    begin
      sSql := 'INSERT IGNORE INTO `' + TABLA_TEMPORAL + '` ' +
        '(`ORIGEN`, `DESTINO`, `ES_SKU`) ' +
        'SELECT DISTINCT dato.`' + sCampo + '`, ' +
        'CONCAT(aab.`CODIGO_ART_AAB`, ''/'', :NUEVO), ''N'' ' +
        'FROM `' + sTabla + '` dato ' +
        'JOIN `fza_articulos_atributos_basicos` aab ON ' +
        'dato.`' + sCampo + '` = CONCAT(aab.`CODIGO_ART_AAB`, ' +
        '''/'', TRIM(:ANTERIOR)) ' +
        'JOIN `fza_atributos_valores` av ON ' +
        'av.`ID_AV` = aab.`ID_AV_AAB` ' +
        'WHERE av.`ID_VA_AV` = ''CO'' ' +
        'AND TRIM(av.`AV`) = TRIM(:ANTERIOR)';
      Ejecutar(
        sSql,
        ['ANTERIOR', 'NUEVO'],
        [AColorAntiguo, AColorNuevo]);
    end;
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.NumeroSkuMapa: Integer;
begin
  Result := EscalarEntero(
    'SELECT COUNT(*) FROM `' + TABLA_TEMPORAL + '` ' +
    'WHERE `ES_SKU` = ''S''',
    [],
    []);
end;

function TRepositorioCambioArticuloColorUniDAC.MapaArticuloEsCompleto(
  const AArticuloAntiguo: string): Boolean;
var
  iNumeroSkuOrigen: Integer;
begin
  iNumeroSkuOrigen := EscalarEntero(
    'SELECT COUNT(*) FROM `fza_articulos_skus` ' +
    'WHERE `CODIGO_ART_SKU` = :ARTICULO',
    ['ARTICULO'],
    [AArticuloAntiguo]);
  Result := iNumeroSkuOrigen = NumeroSkuMapa;
end;

function TRepositorioCambioArticuloColorUniDAC.MapaColorEsCompleto(
  const AColorAntiguo: string): Boolean;
var
  iNumeroSkuOrigen: Integer;
begin
  iNumeroSkuOrigen := EscalarEntero(
    'SELECT COUNT(DISTINCT sku.`CODIGO_UNIDAD_SKU`) ' +
    'FROM `fza_articulos_skus` sku ' +
    'JOIN `fza_atributos_sku` sa ON ' +
    'sa.`CODIGO_UNIDAD_SKU_SA` = sku.`CODIGO_UNIDAD_SKU` ' +
    'JOIN `fza_atributos_valores` av ON av.`ID_AV` = sa.`ID_AV_SA` ' +
    'WHERE av.`ID_VA_AV` = ''CO'' ' +
    'AND TRIM(av.`AV`) = TRIM(:COLOR)',
    ['COLOR'],
    [AColorAntiguo]);
  Result := iNumeroSkuOrigen = NumeroSkuMapa;
end;

function TRepositorioCambioArticuloColorUniDAC.MapaTieneCodigosLargos:
  Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM `' + TABLA_TEMPORAL + '` ' +
    'WHERE CHAR_LENGTH(`DESTINO`) > 50 LIMIT 1',
    [],
    []);
end;

function TRepositorioCambioArticuloColorUniDAC.
  MapaTieneDestinosDuplicados: Boolean;
begin
  Result := Existe(
    'SELECT `DESTINO` FROM `' + TABLA_TEMPORAL + '` ' +
    'GROUP BY `DESTINO` HAVING COUNT(*) > 1 LIMIT 1',
    [],
    []);
end;

function TRepositorioCambioArticuloColorUniDAC.HayVentasArticulo(
  const AArticuloAntiguo: string): Boolean;
begin
  Result := Existe(
    'SELECT fl.`CODIGO_ART_FACLIN` ' +
    'FROM `fza_facturas_lineas` fl ' +
    'LEFT JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
    'mapa.`ORIGEN` = fl.`CODIGO_UNIDAD_FACLIN` ' +
    'WHERE fl.`CODIGO_ART_FACLIN` = :ARTICULO ' +
    'OR fl.`CODIGO_UNIDAD_FACLIN` = :ARTICULO ' +
    'OR LEFT(fl.`CODIGO_UNIDAD_FACLIN`, ' +
    'CHAR_LENGTH(:ARTICULO) + 1) = CONCAT(:ARTICULO, ''/'') ' +
    'OR mapa.`ORIGEN` IS NOT NULL LIMIT 1 FOR UPDATE',
    ['ARTICULO'],
    [AArticuloAntiguo]);
end;

function TRepositorioCambioArticuloColorUniDAC.HayVentasColor(
  const AColorAntiguo: string): Boolean;
var
  i: Integer;
  sCampoNombre: string;
  sCampoValor: string;
  sCondiciones: string;
  sSql: string;
begin
  sCondiciones := 'mapa.`ORIGEN` IS NOT NULL OR ' +
    '(sku_actual.`CODIGO_UNIDAD_SKU` IS NULL AND ' +
    'LOCATE(''/'', fl.`CODIGO_UNIDAD_FACLIN`) > 0 AND ' +
    'LOCATE(CONCAT(''/'', TRIM(:COLOR), ''/''), ' +
    'CONCAT(''/'', SUBSTRING(fl.`CODIGO_UNIDAD_FACLIN`, ' +
    'LOCATE(''/'', fl.`CODIGO_UNIDAD_FACLIN`) + 1), ''/'')) > 0)';
  for i := 1 to 5 do
  begin
    sCampoValor := 'ATTR' + IntToStr(i) + '_VALOR_FACLIN';
    sCampoNombre := 'ATTR' + IntToStr(i) + '_NOMBRE_FACLIN';
    sCondiciones := sCondiciones + ' OR ' + CondicionInstantaneaColor(
      'fl',
      sCampoValor,
      sCampoNombre,
      'COLOR');
  end;
  sSql := 'SELECT fl.`CODIGO_UNIDAD_FACLIN` ' +
    'FROM `fza_facturas_lineas` fl ' +
    'LEFT JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
    'mapa.`ORIGEN` = fl.`CODIGO_UNIDAD_FACLIN` ' +
    'LEFT JOIN `fza_articulos_skus` sku_actual ON ' +
    'sku_actual.`CODIGO_UNIDAD_SKU` = fl.`CODIGO_UNIDAD_FACLIN` WHERE ' +
    sCondiciones + ' LIMIT 1 FOR UPDATE';
  Result := Existe(
    sSql,
    ['COLOR'],
    [AColorAntiguo]);
end;

function TRepositorioCambioArticuloColorUniDAC.HayPrestaShopArticulo(
  const AArticuloAntiguo: string): Boolean;
begin
  Result := False;
  if CampoExiste('fza_articulos', 'ESWEB_ART') then
  begin
    Result := Existe(
      'SELECT 1 FROM `fza_articulos` ' +
      'WHERE `CODIGO_ART_ART` = :ARTICULO ' +
      'AND UPPER(TRIM(COALESCE(`ESWEB_ART`, ''N''))) = ''S'' ' +
      'LIMIT 1 FOR UPDATE',
      ['ARTICULO'],
      [AArticuloAntiguo]);
  end;
  if (not Result) and
     CampoExiste('fza_prestashop_cola', 'CODIGO_ART_PSCOLA') then
  begin
    Result := Existe(
      'SELECT 1 FROM `fza_prestashop_cola` ' +
      'WHERE `CODIGO_ART_PSCOLA` = :ARTICULO LIMIT 1 FOR UPDATE',
      ['ARTICULO'],
      [AArticuloAntiguo]);
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.HayPrestaShopColor:
  Boolean;
begin
  Result := False;
  if CampoExiste('fza_articulos', 'ESWEB_ART') then
  begin
    Result := Existe(
      'SELECT 1 FROM `fza_articulos` art JOIN (' +
      'SELECT DISTINCT SUBSTRING_INDEX(`ORIGEN`, ''/'', 1) `ARTICULO` ' +
      'FROM `' + TABLA_TEMPORAL + '`) afectados ON ' +
      'afectados.`ARTICULO` = art.`CODIGO_ART_ART` ' +
      'WHERE UPPER(TRIM(COALESCE(art.`ESWEB_ART`, ''N''))) = ''S'' ' +
      'LIMIT 1 FOR UPDATE',
      [],
      []);
  end;
  if (not Result) and
     CampoExiste('fza_prestashop_cola', 'CODIGO_ART_PSCOLA') then
  begin
    Result := Existe(
      'SELECT 1 FROM `fza_prestashop_cola` cola JOIN (' +
      'SELECT DISTINCT SUBSTRING_INDEX(`ORIGEN`, ''/'', 1) `ARTICULO` ' +
      'FROM `' + TABLA_TEMPORAL + '`) afectados ON ' +
      'afectados.`ARTICULO` = cola.`CODIGO_ART_PSCOLA` ' +
      'LIMIT 1 FOR UPDATE',
      [],
      []);
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.HayDestinoEnReferencias(
  const AReferencias: array of string): Boolean;
var
  i: Integer;
  sCampo: string;
  sSql: string;
  sTabla: string;
begin
  Result := False;
  i := Low(AReferencias);
  while (i <= High(AReferencias)) and not Result do
  begin
    SepararReferencia(AReferencias[i], sTabla, sCampo);
    if CampoExiste(sTabla, sCampo) then
    begin
      sSql := 'SELECT 1 FROM `' + sTabla + '` dato ' +
        'JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
        'mapa.`DESTINO` = dato.`' + sCampo + '` LIMIT 1';
      Result := Existe(sSql, [], []);
    end;
    Inc(i);
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.HayOrigenEnReferencias(
  const AReferencias: array of string): Boolean;
var
  i: Integer;
  sCampo: string;
  sSql: string;
  sTabla: string;
begin
  Result := False;
  i := Low(AReferencias);
  while (i <= High(AReferencias)) and not Result do
  begin
    SepararReferencia(AReferencias[i], sTabla, sCampo);
    if CampoExiste(sTabla, sCampo) then
    begin
      sSql := 'SELECT 1 FROM `' + sTabla + '` dato ' +
        'JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
        'mapa.`ORIGEN` = dato.`' + sCampo + '` LIMIT 1';
      Result := Existe(sSql, [], []);
    end;
    Inc(i);
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.
  HayUnidadesArticuloSinMapa(
    const AArticuloAntiguo: string): Boolean;
var
  i: Integer;
  sCampo: string;
  sSql: string;
  sTabla: string;
begin
  Result := False;
  i := Low(REFERENCIAS_UNIDAD);
  while (i <= High(REFERENCIAS_UNIDAD)) and not Result do
  begin
    SepararReferencia(REFERENCIAS_UNIDAD[i], sTabla, sCampo);
    if CampoExiste(sTabla, sCampo) then
    begin
      sSql := 'SELECT 1 FROM `' + sTabla + '` dato ' +
        'LEFT JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
        'mapa.`ORIGEN` = dato.`' + sCampo + '` ' +
        'WHERE mapa.`ORIGEN` IS NULL AND ' +
        '(dato.`' + sCampo + '` = :ANTERIOR OR ' +
        'LEFT(dato.`' + sCampo + '`, CHAR_LENGTH(:ANTERIOR) + 1) = ' +
        'CONCAT(:ANTERIOR, ''/'')) LIMIT 1';
      Result := Existe(sSql, ['ANTERIOR'], [AArticuloAntiguo]);
    end;
    Inc(i);
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.
  HayUnidadesColorSinMapa(const AColorAntiguo: string): Boolean;
var
  i: Integer;
  sCampo: string;
  sSql: string;
  sTabla: string;
begin
  Result := False;
  i := Low(REFERENCIAS_UNIDAD);
  while (i <= High(REFERENCIAS_UNIDAD)) and not Result do
  begin
    SepararReferencia(REFERENCIAS_UNIDAD[i], sTabla, sCampo);
    if CampoExiste(sTabla, sCampo) then
    begin
      sSql := 'SELECT 1 FROM `' + sTabla + '` dato LEFT JOIN `' +
        TABLA_TEMPORAL + '` mapa ON ' +
        'mapa.`ORIGEN` = dato.`' + sCampo + '` ' +
        'LEFT JOIN `fza_articulos_skus` sku_actual ON ' +
        'sku_actual.`CODIGO_UNIDAD_SKU` = dato.`' + sCampo + '` ' +
        'WHERE mapa.`ORIGEN` IS NULL ' +
        'AND sku_actual.`CODIGO_UNIDAD_SKU` IS NULL ' +
        'AND LOCATE(''/'', dato.`' + sCampo + '`) > 0 ' +
        'AND LOCATE(CONCAT(''/'', TRIM(:ANTERIOR), ''/''), ' +
        'CONCAT(''/'', SUBSTRING(dato.`' + sCampo + '`, ' +
        'LOCATE(''/'', dato.`' + sCampo + '`) + 1), ''/'')) > 0 ' +
        'LIMIT 1';
      Result := Existe(sSql, ['ANTERIOR'], [AColorAntiguo]);
    end;
    Inc(i);
  end;
end;

procedure TRepositorioCambioArticuloColorUniDAC.ActualizarCampoPorValor(
  const ATabla, ACampo, AAnterior, ANuevo, AUsuario: string);
var
  sAuditoria: string;
  sSql: string;
begin
  sAuditoria := '';
  if CampoExiste(ATabla, 'USUARIO_MODIF') then
    sAuditoria := ', `USUARIO_MODIF` = :USUARIO';
  sSql := 'UPDATE `' + ATabla + '` SET `' + ACampo + '` = :NUEVO' +
    sAuditoria + ' WHERE `' + ACampo + '` = :ANTERIOR';
  Ejecutar(
    sSql,
    ['ANTERIOR', 'NUEVO', 'USUARIO'],
    [AAnterior, ANuevo, AUsuario]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.ActualizarCampoPorMapa(
  const ATabla, ACampo, AUsuario: string);
var
  sAuditoria: string;
  sSql: string;
begin
  sAuditoria := '';
  if CampoExiste(ATabla, 'USUARIO_MODIF') then
    sAuditoria := ', dato.`USUARIO_MODIF` = :USUARIO';
  sSql := 'UPDATE `' + ATabla + '` dato ' +
    'JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
    'mapa.`ORIGEN` = dato.`' + ACampo + '` ' +
    'SET dato.`' + ACampo + '` = mapa.`DESTINO`' + sAuditoria;
  Ejecutar(sSql, ['USUARIO'], [AUsuario]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.
  ActualizarReferenciasArticulo(
    const AAnterior, ANuevo, AUsuario: string);
var
  i: Integer;
  sCampo: string;
  sTabla: string;
begin
  for i := Low(REFERENCIAS_ARTICULO) to High(REFERENCIAS_ARTICULO) do
  begin
    SepararReferencia(REFERENCIAS_ARTICULO[i], sTabla, sCampo);
    if CampoExiste(sTabla, sCampo) then
    begin
      ActualizarCampoPorValor(
        sTabla,
        sCampo,
        AAnterior,
        ANuevo,
        AUsuario);
    end;
  end;
end;

procedure TRepositorioCambioArticuloColorUniDAC.
  ActualizarReferenciasUnidad(const AUsuario: string);
var
  i: Integer;
  sCampo: string;
  sTabla: string;
begin
  for i := Low(REFERENCIAS_UNIDAD) to High(REFERENCIAS_UNIDAD) do
  begin
    if REFERENCIAS_UNIDAD[i] <> REFERENCIA_SKU_MAESTRO then
    begin
      SepararReferencia(REFERENCIAS_UNIDAD[i], sTabla, sCampo);
      if CampoExiste(sTabla, sCampo) then
        ActualizarCampoPorMapa(sTabla, sCampo, AUsuario);
    end;
  end;
end;

procedure TRepositorioCambioArticuloColorUniDAC.ActualizarSkuMaestro(
  const AUsuario: string);
begin
  ActualizarCampoPorMapa(
    'fza_articulos_skus',
    'CODIGO_UNIDAD_SKU',
    AUsuario);
end;

procedure TRepositorioCambioArticuloColorUniDAC.ActualizarArticuloMaestro(
  const AAnterior, ANuevo, AUsuario: string);
begin
  ActualizarCampoPorValor(
    'fza_articulos',
    'CODIGO_ART_ART',
    AAnterior,
    ANuevo,
    AUsuario);
end;

procedure TRepositorioCambioArticuloColorUniDAC.ActualizarColorMaestro(
  const AAnterior, ANuevo, AUsuario: string);
begin
  Ejecutar(
    'UPDATE `fza_atributos_valores` SET `AV` = :NUEVO, ' +
    '`USUARIO_MODIF` = :USUARIO WHERE `ID_VA_AV` = ''CO'' ' +
    'AND TRIM(`AV`) = TRIM(:ANTERIOR)',
    ['ANTERIOR', 'NUEVO', 'USUARIO'],
    [AAnterior, ANuevo, AUsuario]);
end;

function TRepositorioCambioArticuloColorUniDAC.SqlActualizacionAtributos(
  const ATabla, ACampoUnidad, ASufijo: string): string;
var
  i: Integer;
  sCampo: string;
  sCampoNombre: string;
  sCondicion: string;
  sCondiciones: string;
  sSeparadorCondiciones: string;
  sSeparadorValores: string;
  sValores: string;
begin
  sCondiciones := '';
  sValores := '';
  sSeparadorCondiciones := '';
  sSeparadorValores := '';
  for i := 1 to 5 do
  begin
    sCampo := 'ATTR' + IntToStr(i) + '_VALOR_' + ASufijo;
    sCampoNombre := 'ATTR' + IntToStr(i) + '_NOMBRE_' + ASufijo;
    if CampoExiste(ATabla, sCampo) and
       CampoExiste(ATabla, sCampoNombre) then
    begin
      sCondicion := CondicionInstantaneaColor(
        'dato',
        sCampo,
        sCampoNombre,
        'ANTERIOR');
      sValores := sValores + sSeparadorValores + 'dato.`' + sCampo +
        '` = CASE WHEN ' + sCondicion + ' THEN :NUEVO ELSE dato.`' +
        sCampo + '` END';
      sCondiciones := sCondiciones + sSeparadorCondiciones + sCondicion;
      sSeparadorValores := ', ';
      sSeparadorCondiciones := ' OR ';
    end;
  end;
  if (sValores <> '') and CampoExiste(ATabla, 'USUARIO_MODIF') then
    sValores := sValores + sSeparadorValores +
      'dato.`USUARIO_MODIF` = :USUARIO';
  Result := '';
  if sValores <> '' then
  begin
    Result := 'UPDATE `' + ATabla + '` dato ' +
      'JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
      'mapa.`ORIGEN` = dato.`' + ACampoUnidad + '` SET ' + sValores +
      ' WHERE ' + sCondiciones;
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.SqlActualizacionDescripcion(
  const ATabla, ACampoUnidad, ASufijo: string): string;
var
  i: Integer;
  sCampo: string;
  sCampoDescripcion: string;
  sPartes: string;
  sSeparador: string;
begin
  if SameText(ASufijo, 'DTL') then
    sCampoDescripcion := 'DESCRIPCION_UNIDAD_DTL'
  else
    sCampoDescripcion := 'DESCRIPCION_VARIACION_' + ASufijo;
  sPartes := '';
  sSeparador := '';
  if CampoExiste(ATabla, sCampoDescripcion) then
  begin
    for i := 1 to 5 do
    begin
      sCampo := 'ATTR' + IntToStr(i) + '_VALOR_' + ASufijo;
      if CampoExiste(ATabla, sCampo) then
      begin
        sPartes := sPartes + sSeparador + 'NULLIF(TRIM(dato.`' +
          sCampo + '`), '''')';
        sSeparador := ', ';
      end;
    end;
  end;
  Result := '';
  if sPartes <> '' then
  begin
    Result := 'UPDATE `' + ATabla + '` dato ' +
      'JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
      'mapa.`ORIGEN` = dato.`' + ACampoUnidad + '` SET dato.`' +
      sCampoDescripcion + '` = CONCAT_WS('' / '', ' + sPartes + ')';
  end;
end;

procedure TRepositorioCambioArticuloColorUniDAC.
  ActualizarInstantaneasColor(
    const AAnterior, ANuevo, AUsuario: string);
var
  i: Integer;
  sCampoUnidad: string;
  sSql: string;
  sSufijo: string;
  sTabla: string;
begin
  for i := Low(REFERENCIAS_ATRIBUTOS) to High(REFERENCIAS_ATRIBUTOS) do
  begin
    SepararReferenciaAtributos(
      REFERENCIAS_ATRIBUTOS[i],
      sTabla,
      sCampoUnidad,
      sSufijo);
    if CampoExiste(sTabla, sCampoUnidad) and
       CampoExiste(sTabla, 'ATTR1_VALOR_' + sSufijo) then
    begin
      sSql := SqlActualizacionAtributos(
        sTabla,
        sCampoUnidad,
        sSufijo);
      if sSql <> '' then
      begin
        Ejecutar(
          sSql,
          ['ANTERIOR', 'NUEVO', 'USUARIO'],
          [AAnterior, ANuevo, AUsuario]);
      end;
      sSql := SqlActualizacionDescripcion(
        sTabla,
        sCampoUnidad,
        sSufijo);
      if sSql <> '' then
        Ejecutar(sSql, [], []);
    end;
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.
  HayInstantaneasColorAntiguo(const AColorAntiguo: string): Boolean;
var
  i: Integer;
  j: Integer;
  sCampo: string;
  sCampoNombre: string;
  sCampoUnidad: string;
  sCondiciones: string;
  sSufijo: string;
  sTabla: string;
begin
  Result := False;
  i := Low(REFERENCIAS_ATRIBUTOS);
  while (i <= High(REFERENCIAS_ATRIBUTOS)) and not Result do
  begin
    SepararReferenciaAtributos(
      REFERENCIAS_ATRIBUTOS[i],
      sTabla,
      sCampoUnidad,
      sSufijo);
    if CampoExiste(sTabla, sCampoUnidad) then
    begin
      sCondiciones := '';
      for j := 1 to 5 do
      begin
        sCampo := 'ATTR' + IntToStr(j) + '_VALOR_' + sSufijo;
        sCampoNombre := 'ATTR' + IntToStr(j) + '_NOMBRE_' + sSufijo;
        if CampoExiste(sTabla, sCampo) and
           CampoExiste(sTabla, sCampoNombre) then
        begin
          if sCondiciones <> '' then
            sCondiciones := sCondiciones + ' OR ';
          sCondiciones := sCondiciones + CondicionInstantaneaColor(
            'dato',
            sCampo,
            sCampoNombre,
            'COLOR');
        end;
      end;
      if sCondiciones <> '' then
      begin
        Result := Existe(
          'SELECT 1 FROM `' + sTabla + '` dato WHERE ' +
          sCondiciones + ' LIMIT 1',
          ['COLOR'],
          [AColorAntiguo]);
      end;
    end;
    Inc(i);
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.
  HayInstantaneasColorSinMapa(
    const AColorAntiguo: string): Boolean;
var
  i: Integer;
  j: Integer;
  sCampoNombre: string;
  sCampoUnidad: string;
  sCampoValor: string;
  sCondiciones: string;
  sSufijo: string;
  sTabla: string;
begin
  Result := False;
  i := Low(REFERENCIAS_ATRIBUTOS);
  while (i <= High(REFERENCIAS_ATRIBUTOS)) and not Result do
  begin
    SepararReferenciaAtributos(
      REFERENCIAS_ATRIBUTOS[i],
      sTabla,
      sCampoUnidad,
      sSufijo);
    if CampoExiste(sTabla, sCampoUnidad) then
    begin
      sCondiciones := '';
      for j := 1 to 5 do
      begin
        sCampoValor := 'ATTR' + IntToStr(j) + '_VALOR_' + sSufijo;
        sCampoNombre := 'ATTR' + IntToStr(j) + '_NOMBRE_' + sSufijo;
        if CampoExiste(sTabla, sCampoValor) and
           CampoExiste(sTabla, sCampoNombre) then
        begin
          if sCondiciones <> '' then
            sCondiciones := sCondiciones + ' OR ';
          sCondiciones := sCondiciones + CondicionInstantaneaColor(
            'dato',
            sCampoValor,
            sCampoNombre,
            'COLOR');
        end;
      end;
      if sCondiciones <> '' then
      begin
        Result := Existe(
          'SELECT 1 FROM `' + sTabla + '` dato LEFT JOIN `' +
          TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = dato.`' +
          sCampoUnidad + '` WHERE mapa.`ORIGEN` IS NULL AND (' +
          sCondiciones + ') LIMIT 1',
          ['COLOR'],
          [AColorAntiguo]);
      end;
    end;
    Inc(i);
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.ValidarCambioArticulo(
  const AAnterior, ANuevo: string): TResultadoCambioArticuloColor;
begin
  Result := TResultadoCambioArticuloColor.Correcto(0);
  BloquearArticulos(AAnterior, ANuevo);
  if not ExisteArticulo(AAnterior) then
    Result := TResultadoCambioArticuloColor.Error(mcacOrigenNoExiste)
  else if ExisteArticulo(ANuevo) then
    Result := TResultadoCambioArticuloColor.Error(mcacDestinoYaExiste)
  else
  begin
    ConstruirMapaArticulo(AAnterior, ANuevo);
    AgregarMapaArticuloReferencias(AAnterior, ANuevo);
    if not MapaArticuloEsCompleto(AAnterior) then
    begin
      Result := TResultadoCambioArticuloColor.Error(
        mcacDatosInconsistentes,
        'Hay SKU que no comienzan por el código de artículo antiguo.');
    end
    else if HayUnidadesArticuloSinMapa(AAnterior) then
    begin
      Result := TResultadoCambioArticuloColor.Error(
        mcacDatosInconsistentes,
        'Hay unidades del artículo antiguo fuera del mapa de cambio.');
    end
    else if MapaTieneCodigosLargos or MapaTieneDestinosDuplicados then
      Result := TResultadoCambioArticuloColor.Error(mcacColisionUnidades)
    else if HayVentasArticulo(AAnterior) then
      Result := TResultadoCambioArticuloColor.Error(mcacExistenVentas)
    else if HayPrestaShopArticulo(AAnterior) then
      Result := TResultadoCambioArticuloColor.Error(mcacIntegracionExterna)
    else if HayDestinoEnReferencias(REFERENCIAS_ARTICULO) or
            HayDestinoEnReferencias(REFERENCIAS_UNIDAD) then
      Result := TResultadoCambioArticuloColor.Error(mcacColisionUnidades)
    else
      Result := TResultadoCambioArticuloColor.Correcto(NumeroSkuMapa);
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.ValidarCambioColor(
  const AAnterior, ANuevo: string): TResultadoCambioArticuloColor;
begin
  Result := TResultadoCambioArticuloColor.Correcto(0);
  BloquearColores(AAnterior, ANuevo);
  if not ExisteColor(AAnterior) then
    Result := TResultadoCambioArticuloColor.Error(mcacOrigenNoExiste)
  else if ExisteColor(ANuevo) then
    Result := TResultadoCambioArticuloColor.Error(mcacDestinoYaExiste)
  else
  begin
    ConstruirMapaColor(AAnterior, ANuevo);
    AgregarMapaColorReferencias(AAnterior, ANuevo);
    if not MapaColorEsCompleto(AAnterior) then
    begin
      Result := TResultadoCambioArticuloColor.Error(
        mcacDatosInconsistentes,
        'Hay SKU cuyo segmento de color no coincide con el catálogo.');
    end
    else if HayUnidadesColorSinMapa(AAnterior) or
            HayInstantaneasColorSinMapa(AAnterior) then
    begin
      Result := TResultadoCambioArticuloColor.Error(
        mcacDatosInconsistentes,
        'Hay unidades o documentos de color fuera del mapa de cambio.');
    end
    else if MapaTieneCodigosLargos or MapaTieneDestinosDuplicados then
      Result := TResultadoCambioArticuloColor.Error(mcacColisionUnidades)
    else if HayVentasColor(AAnterior) then
      Result := TResultadoCambioArticuloColor.Error(mcacExistenVentas)
    else if HayPrestaShopColor then
      Result := TResultadoCambioArticuloColor.Error(mcacIntegracionExterna)
    else if HayDestinoEnReferencias(REFERENCIAS_UNIDAD) then
      Result := TResultadoCambioArticuloColor.Error(mcacColisionUnidades)
    else
      Result := TResultadoCambioArticuloColor.Correcto(NumeroSkuMapa);
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.VerificarCambioArticulo(
  const AArticuloAntiguo: string): Boolean;
begin
  Result := (not ExisteArticulo(AArticuloAntiguo)) and
            (not HayOrigenEnReferencias(REFERENCIAS_ARTICULO)) and
            (not HayOrigenEnReferencias(REFERENCIAS_UNIDAD)) and
            (not HayUnidadesArticuloSinMapa(AArticuloAntiguo));
end;

function TRepositorioCambioArticuloColorUniDAC.VerificarCambioColor(
  const AColorAntiguo: string): Boolean;
begin
  Result := (not HayOrigenEnReferencias(REFERENCIAS_UNIDAD)) and
            (not HayUnidadesColorSinMapa(AColorAntiguo)) and
            (not HayInstantaneasColorAntiguo(AColorAntiguo));
end;

function TRepositorioCambioArticuloColorUniDAC.CambiarArticulo(
  const AArticuloAntiguo, AArticuloNuevo, AUsuario: string):
  TResultadoCambioArticuloColor;
begin
  if FConexion.InTransaction then
  begin
    Result := TResultadoCambioArticuloColor.Error(
      mcacDatosInconsistentes,
      'Ya existe una transacción activa en la conexión.');
  end
  else
  begin
    PrepararTablaTemporal;
    try
      IniciarTransaccion;
      try
        Result := ValidarCambioArticulo(
          AArticuloAntiguo,
          AArticuloNuevo);
        if Result.EsCorrecto then
        begin
          ActualizarReferenciasUnidad(AUsuario);
          ActualizarSkuMaestro(AUsuario);
          ActualizarReferenciasArticulo(
            AArticuloAntiguo,
            AArticuloNuevo,
            AUsuario);
          ActualizarArticuloMaestro(
            AArticuloAntiguo,
            AArticuloNuevo,
            AUsuario);
          if not VerificarCambioArticulo(AArticuloAntiguo) then
          begin
            Result := TResultadoCambioArticuloColor.Error(
              mcacDatosInconsistentes,
              'Persisten referencias al código de artículo antiguo.');
          end;
        end;
        FinalizarTransaccion(Result);
      except
        if FConexion.InTransaction then
          FConexion.Rollback;
        raise;
      end;
    finally
      EliminarTablaTemporal;
    end;
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.CambiarColor(
  const AColorAntiguo, AColorNuevo, AUsuario: string):
  TResultadoCambioArticuloColor;
begin
  if FConexion.InTransaction then
  begin
    Result := TResultadoCambioArticuloColor.Error(
      mcacDatosInconsistentes,
      'Ya existe una transacción activa en la conexión.');
  end
  else
  begin
    PrepararTablaTemporal;
    try
      IniciarTransaccion;
      try
        Result := ValidarCambioColor(AColorAntiguo, AColorNuevo);
        if Result.EsCorrecto then
        begin
          ActualizarInstantaneasColor(
            AColorAntiguo,
            AColorNuevo,
            AUsuario);
          ActualizarReferenciasUnidad(AUsuario);
          ActualizarSkuMaestro(AUsuario);
          if not VerificarCambioColor(AColorAntiguo) then
          begin
            Result := TResultadoCambioArticuloColor.Error(
              mcacDatosInconsistentes,
              'Persisten referencias al color antiguo.');
          end;
          if Result.EsCorrecto then
          begin
            ActualizarColorMaestro(
              AColorAntiguo,
              AColorNuevo,
              AUsuario);
            if ExisteColor(AColorAntiguo) then
            begin
              Result := TResultadoCambioArticuloColor.Error(
                mcacDatosInconsistentes,
                'Persiste el valor de color antiguo en el catálogo.');
            end;
          end;
        end;
        FinalizarTransaccion(Result);
      except
        if FConexion.InTransaction then
          FConexion.Rollback;
        raise;
      end;
    finally
      EliminarTablaTemporal;
    end;
  end;
end;

function CrearRepositorioCambioArticuloColorUniDAC(
  AConexion: TUniConnection): IRepositorioCambioArticuloColor;
begin
  Result := TRepositorioCambioArticuloColorUniDAC.Create(AConexion);
end;

end.
