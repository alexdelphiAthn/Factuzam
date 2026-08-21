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

  REFERENCIAS_UNIDAD: array[0..26] of string = (
    'fza_articulos_fotos|CODIGO_UNIDAD_FOT',
    'fza_articulos_pdte_recibir|CODIGO_UNIDAD_PDR',
    'fza_articulos_propiedades|CODIGO_UNIDAD_ARTPROP',
    'fza_articulos_skus|CODIGO_UNIDAD_SKU',
    'fza_articulos_skus_costes|CODIGO_UNIDAD_SKU_SKUC',
    'fza_stock_bloqueos|CODIGO_UNIDAD_STKBLQ',
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
      const AAlias, ACampoValor, ACampoNombre, AParametro: string;
      APosicion: Integer): string;
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
    function ArticulosCoincidenEnBaseDatos(
      const AAnterior, ANuevo: string): Boolean;
    function ColoresCoincidenEnBaseDatos(
      const AAnterior, ANuevo: string): Boolean;
    function SqlSkusConPosicionColor: string;
    procedure ConstruirMapaArticulo(
      const AArticuloAntiguo, AArticuloNuevo: string);
    procedure AgregarMapaArticuloReferencias(
      const AArticuloAntiguo, AArticuloNuevo: string);
    procedure ConstruirMapaColor(
      const AColorAntiguo, AColorNuevo: string);
    function SqlCandidatosColorReferencia(
      const ATabla, ACampo: string): string;
    procedure AgregarMapaColorReferencias(
      const AColorAntiguo, AColorNuevo: string);
    function HayMapaColorReferenciasAmbiguo(
      const AColorAntiguo, AColorNuevo: string): Boolean;
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
    function HayDestinoMapaEnVentas: Boolean;
    function HayPrestaShopArticulo(
      const AArticuloAntiguo: string): Boolean;
    function HayPrestaShopColor(
      const AColorAntiguo: string): Boolean;
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
    procedure EliminarArticuloMaestro(
      const AArticuloAntiguo: string);
    procedure ActualizarColorMaestro(
      const AAnterior, ANuevo, AUsuario: string;
      AFusionar: Boolean);
    procedure LimpiarBasicosColorFusion(
      const AColorAntiguo, AUsuario: string);
    function FusionColorEsSegura(
      const AAnterior, ANuevo: string): Boolean;
    function FusionArticuloEsSegura(
      const AAnterior, ANuevo: string): Boolean;
    procedure PrepararFusionArticulo(
      const AAnterior, ANuevo: string);
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
      const AColorAntiguo, AColorNuevo: string): Boolean;
    function ValidarCambioArticulo(
      const AAnterior, ANuevo: string;
      AFusionar: Boolean): TResultadoCambioArticuloColor;
    function ValidarCambioColor(
      const AAnterior, ANuevo: string;
      AFusionar: Boolean): TResultadoCambioArticuloColor;
    function VerificarCambioArticulo(
      const AArticuloAntiguo: string): Boolean;
    function VerificarCambioColor(
      const AColorAntiguo: string): Boolean;
    function EjecutarCambioArticulo(
      const AArticuloAntiguo, AArticuloNuevo, AUsuario: string;
      AFusionar: Boolean): TResultadoCambioArticuloColor;
    function EjecutarCambioColor(
      const AColorAntiguo, AColorNuevo, AUsuario: string;
      AFusionar: Boolean): TResultadoCambioArticuloColor;
  public
    constructor Create(AConexion: TUniConnection);
    function CambiarArticulo(
      const AArticuloAntiguo, AArticuloNuevo, AUsuario: string):
      TResultadoCambioArticuloColor;
    function FusionarArticulo(
      const AArticuloAntiguo, AArticuloDestino, AUsuario: string):
      TResultadoCambioArticuloColor;
    function CambiarColor(
      const AColorAntiguo, AColorNuevo, AUsuario: string):
      TResultadoCambioArticuloColor;
    function FusionarColor(
      const AColorAntiguo, AColorDestino, AUsuario: string):
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
begin
  Result := '(TRIM(' + AAlias + '.`' + ACampoValor + '`) = TRIM(:' +
    AParametro + ') AND (UPPER(TRIM(' + AAlias + '.`' +
    ACampoNombre + '`)) IN (''COLOR'', ''CO'') OR EXISTS (' +
    'SELECT 1 FROM `fza_variaciones_atributos` va ' +
    'WHERE va.`ID_ATB_VA` = ''CO'' AND UPPER(TRIM(va.`NOMBRE_VA`)) = ' +
    'UPPER(TRIM(' + AAlias + '.`' + ACampoNombre + '`)))))';
end;

function TRepositorioCambioArticuloColorUniDAC.
  ExpresionConteoValoresAtributos(
    const ATabla, AAlias, ASufijo, AParametro: string): string;
var
  i: Integer;
  sCampo: string;
  sExpresion: string;
  sSeparador: string;
begin
  sExpresion := '';
  sSeparador := '';
  for i := 1 to 5 do
  begin
    sCampo := 'ATTR' + IntToStr(i) + '_VALOR_' + ASufijo;
    if CampoExiste(ATabla, sCampo) then
    begin
      sExpresion := sExpresion + sSeparador +
        'CASE WHEN TRIM(' + AAlias + '.`' + sCampo + '`) = TRIM(:' +
        AParametro + ') THEN 1 ELSE 0 END';
      sSeparador := ' + ';
    end;
  end;
  if sExpresion = '' then
    sExpresion := '0';
  Result := '(' + sExpresion + ')';
end;

function TRepositorioCambioArticuloColorUniDAC.
  CondicionInstantaneaColorSegura(
    const AAlias, ACampoValor, ACampoNombre, AParametro: string;
    APosicion: Integer): string;
begin
  Result := '(TRIM(' + AAlias + '.`' + ACampoValor + '`) = TRIM(:' +
    AParametro + ') AND mapa.`POSICION_COLOR` = ' +
    IntToStr(APosicion) + ' AND (TRIM(COALESCE(' + AAlias + '.`' +
    ACampoNombre + '`, '''')) = '''' OR UPPER(TRIM(' + AAlias + '.`' +
    ACampoNombre + '`)) IN (''COLOR'', ''CO'') OR EXISTS (' +
    'SELECT 1 FROM `fza_variaciones_atributos` va ' +
    'WHERE va.`ID_ATB_VA` = ''CO'' AND UPPER(TRIM(va.`NOMBRE_VA`)) = ' +
    'UPPER(TRIM(' + AAlias + '.`' + ACampoNombre + '`)))))';
end;

procedure TRepositorioCambioArticuloColorUniDAC.PrepararTablaTemporal;
begin
  EliminarTablaTemporal;
  Ejecutar(
    'CREATE TEMPORARY TABLE `' + TABLA_TEMPORAL + '` (' +
    '`ORIGEN` varchar(255) NOT NULL, ' +
    '`DESTINO` varchar(255) NOT NULL, ' +
    '`ES_SKU` char(1) NOT NULL DEFAULT ''S'', ' +
    '`POSICION_COLOR` smallint NULL, ' +
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

function TRepositorioCambioArticuloColorUniDAC.
  ArticulosCoincidenEnBaseDatos(
    const AAnterior, ANuevo: string): Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM `fza_articulos` WHERE ' +
    '`CODIGO_ART_ART` = :ANTERIOR AND ' +
    '`CODIGO_ART_ART` = :NUEVO LIMIT 1',
    ['ANTERIOR', 'NUEVO'],
    [AAnterior, ANuevo]);
end;

function TRepositorioCambioArticuloColorUniDAC.
  ColoresCoincidenEnBaseDatos(
    const AAnterior, ANuevo: string): Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM `fza_atributos_valores` WHERE ' +
    '`ID_VA_AV` = ''CO'' AND TRIM(`AV`) = TRIM(:ANTERIOR) AND ' +
    'TRIM(`AV`) = TRIM(:NUEVO) LIMIT 1',
    ['ANTERIOR', 'NUEVO'],
    [AAnterior, ANuevo]);
end;

function TRepositorioCambioArticuloColorUniDAC.SqlSkusConPosicionColor:
  string;
var
  sOrdenColor: string;
  sOrdenEmpate: string;
  sOrdenPrevio: string;
begin
  sOrdenColor := '(CASE WHEN color.`ORDEN_ACA` = 0 THEN ' +
    'COALESCE(va_color.`ORDEN_VA`, -2147483648) ELSE ' +
    'color.`ORDEN_ACA` END)';
  sOrdenEmpate := '(CASE WHEN empate.`ORDEN_ACA` = 0 THEN ' +
    'COALESCE(va_empate.`ORDEN_VA`, -2147483648) ELSE ' +
    'empate.`ORDEN_ACA` END)';
  sOrdenPrevio := '(CASE WHEN orden.`ORDEN_ACA` = 0 THEN ' +
    'COALESCE(va_orden.`ORDEN_VA`, -2147483648) ELSE ' +
    'orden.`ORDEN_ACA` END)';
  Result := 'SELECT sku.`CODIGO_UNIDAD_SKU` `CODIGO_UNIDAD`, ' +
    'sku.`CODIGO_ART_SKU` `CODIGO_ARTICULO`, ' +
    '(1 + (SELECT COUNT(*) FROM ' +
    '`fza_articulos_conjuntos_asign` orden ' +
    'JOIN `fza_variaciones_atributos` va_orden ON ' +
    'va_orden.`ID_ATB_VA` = orden.`ID_VA_ACA` AND ' +
    'va_orden.`ID_VAR_VA` = sku.`CODIGO_VAR_SKU` ' +
    'WHERE orden.`CODIGO_ART_ACA` = sku.`CODIGO_ART_SKU` AND ' +
    '(' + sOrdenPrevio + ' < ' + sOrdenColor + ' OR (' +
    sOrdenPrevio + ' = ' + sOrdenColor + ' AND ' +
    'COALESCE(va_orden.`ORDEN_VA`, -2147483648) < ' +
    'COALESCE(va_color.`ORDEN_VA`, -2147483648))))) ' +
    '`POSICION_COLOR`, (SELECT COUNT(*) FROM ' +
    '`fza_articulos_conjuntos_asign` dimensiones ' +
    'JOIN `fza_variaciones_atributos` va_dimension ON ' +
    'va_dimension.`ID_ATB_VA` = dimensiones.`ID_VA_ACA` AND ' +
    'va_dimension.`ID_VAR_VA` = sku.`CODIGO_VAR_SKU` ' +
    'WHERE dimensiones.`CODIGO_ART_ACA` = sku.`CODIGO_ART_SKU`) ' +
    '`NUM_ATRIBUTOS`, (SELECT COUNT(*) FROM ' +
    '`fza_articulos_conjuntos_asign` empate ' +
    'JOIN `fza_variaciones_atributos` va_empate ON ' +
    'va_empate.`ID_ATB_VA` = empate.`ID_VA_ACA` AND ' +
    'va_empate.`ID_VAR_VA` = sku.`CODIGO_VAR_SKU` ' +
    'WHERE empate.`CODIGO_ART_ACA` = sku.`CODIGO_ART_SKU` AND ' +
    'empate.`ID_VA_ACA` <> ''CO'' AND ' +
    sOrdenEmpate + ' = ' + sOrdenColor + ' AND ' +
    'COALESCE(va_empate.`ORDEN_VA`, -2147483648) = ' +
    'COALESCE(va_color.`ORDEN_VA`, -2147483648)) `ORDEN_AMBIGUO` ' +
    'FROM `fza_articulos_skus` sku ' +
    'JOIN `fza_articulos_conjuntos_asign` color ON ' +
    'color.`CODIGO_ART_ACA` = sku.`CODIGO_ART_SKU` AND ' +
    'color.`ID_VA_ACA` = ''CO'' ' +
    'JOIN `fza_variaciones_atributos` va_color ON ' +
    'va_color.`ID_VAR_VA` = sku.`CODIGO_VAR_SKU` AND ' +
    'va_color.`ID_ATB_VA` = ''CO''';
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
    '(`ORIGEN`, `DESTINO`, `ES_SKU`, `POSICION_COLOR`) ' +
    'SELECT origen.`CODIGO_UNIDAD`, CONCAT(' +
    'SUBSTRING_INDEX(origen.`CODIGO_UNIDAD`, ''/'', ' +
    'origen.`POSICION_COLOR`), ''/'', :NUEVO, ' +
    'SUBSTRING(origen.`CODIGO_UNIDAD`, CHAR_LENGTH(' +
    'SUBSTRING_INDEX(origen.`CODIGO_UNIDAD`, ''/'', ' +
    'origen.`POSICION_COLOR` + 1)) + 1)), ''S'', ' +
    'origen.`POSICION_COLOR` FROM (' +
    SqlSkusConPosicionColor + ') origen WHERE ' +
    'origen.`ORDEN_AMBIGUO` = 0 AND ' +
    '(CHAR_LENGTH(origen.`CODIGO_UNIDAD`) - CHAR_LENGTH(' +
    'REPLACE(origen.`CODIGO_UNIDAD`, ''/'', ''''))) = ' +
    'origen.`NUM_ATRIBUTOS` AND ' +
    'TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(origen.`CODIGO_UNIDAD`, ' +
    '''/'', origen.`POSICION_COLOR` + 1), ''/'', -1)) = ' +
    'TRIM(:ANTERIOR) AND EXISTS (SELECT 1 FROM ' +
    '`fza_atributos_sku` sa JOIN `fza_atributos_valores` av ON ' +
    'av.`ID_AV` = sa.`ID_AV_SA` WHERE ' +
    'sa.`CODIGO_UNIDAD_SKU_SA` = origen.`CODIGO_UNIDAD` AND ' +
    'av.`ID_VA_AV` = ''CO'' AND TRIM(av.`AV`) = TRIM(:ANTERIOR))',
    ['ANTERIOR', 'NUEVO'],
    [AColorAntiguo, AColorNuevo]);
end;

function TRepositorioCambioArticuloColorUniDAC.
  SqlCandidatosColorReferencia(
    const ATabla, ACampo: string): string;
begin
  Result := 'SELECT DISTINCT dato.`' + ACampo + '` `ORIGEN`, ' +
    'CONCAT(SUBSTRING_INDEX(dato.`' + ACampo + '`, ''/'', ' +
    'posicion.`POSICION_COLOR`), ''/'', :NUEVO, SUBSTRING(dato.`' +
    ACampo + '`, CHAR_LENGTH(SUBSTRING_INDEX(dato.`' + ACampo +
    '`, ''/'', posicion.`POSICION_COLOR` + 1)) + 1)) `DESTINO`, ' +
    'posicion.`POSICION_COLOR` `POSICION_COLOR` ' +
    'FROM `' + ATabla + '` dato JOIN (' + SqlSkusConPosicionColor +
    ') posicion ON posicion.`CODIGO_UNIDAD` = dato.`' + ACampo +
    '` OR LEFT(posicion.`CODIGO_UNIDAD`, CHAR_LENGTH(dato.`' +
    ACampo + '`) + 1) = CONCAT(dato.`' + ACampo + '`, ''/'') WHERE ' +
    'posicion.`ORDEN_AMBIGUO` = 0 AND ' +
    '(CHAR_LENGTH(posicion.`CODIGO_UNIDAD`) - CHAR_LENGTH(REPLACE(' +
    'posicion.`CODIGO_UNIDAD`, ''/'', ''''))) = ' +
    'posicion.`NUM_ATRIBUTOS` AND ' +
    'TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(' +
    'posicion.`CODIGO_UNIDAD`, ''/'', ' +
    'posicion.`POSICION_COLOR` + 1), ''/'', -1)) = TRIM(:ANTERIOR) ' +
    'AND EXISTS (SELECT 1 FROM `fza_atributos_sku` sa ' +
    'JOIN `fza_atributos_valores` av ON av.`ID_AV` = sa.`ID_AV_SA` ' +
    'WHERE sa.`CODIGO_UNIDAD_SKU_SA` = ' +
    'posicion.`CODIGO_UNIDAD` AND av.`ID_VA_AV` = ''CO'' AND ' +
    'TRIM(av.`AV`) = TRIM(:ANTERIOR)) AND ' +
    '(CHAR_LENGTH(dato.`' + ACampo + '`) - CHAR_LENGTH(REPLACE(' +
    'dato.`' + ACampo + '`, ''/'', ''''))) >= ' +
    'posicion.`POSICION_COLOR` AND ' +
    'TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(dato.`' + ACampo +
    '`, ''/'', posicion.`POSICION_COLOR` + 1), ''/'', -1)) = ' +
    'TRIM(:ANTERIOR)';
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
    if REFERENCIAS_UNIDAD[i] <> REFERENCIA_SKU_MAESTRO then
    begin
      SepararReferencia(REFERENCIAS_UNIDAD[i], sTabla, sCampo);
      if CampoExiste(sTabla, sCampo) then
      begin
        sSql := 'INSERT IGNORE INTO `' + TABLA_TEMPORAL + '` ' +
          '(`ORIGEN`, `DESTINO`, `ES_SKU`, `POSICION_COLOR`) SELECT ' +
          'candidatos.`ORIGEN`, MIN(candidatos.`DESTINO`), ''N'', ' +
          'MIN(candidatos.`POSICION_COLOR`) FROM (' +
          SqlCandidatosColorReferencia(sTabla, sCampo) +
          ') candidatos GROUP BY candidatos.`ORIGEN` ' +
          'HAVING COUNT(DISTINCT candidatos.`DESTINO`, ' +
          'candidatos.`POSICION_COLOR`) = 1';
        Ejecutar(
          sSql,
          ['ANTERIOR', 'NUEVO'],
          [AColorAntiguo, AColorNuevo]);
      end;
    end;
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.
  HayMapaColorReferenciasAmbiguo(
    const AColorAntiguo, AColorNuevo: string): Boolean;
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
    if REFERENCIAS_UNIDAD[i] <> REFERENCIA_SKU_MAESTRO then
    begin
      SepararReferencia(REFERENCIAS_UNIDAD[i], sTabla, sCampo);
      if CampoExiste(sTabla, sCampo) then
      begin
        sSql := 'SELECT candidatos.`ORIGEN` FROM (' +
          SqlCandidatosColorReferencia(sTabla, sCampo) +
          ') candidatos GROUP BY candidatos.`ORIGEN` ' +
          'HAVING COUNT(DISTINCT candidatos.`DESTINO`, ' +
          'candidatos.`POSICION_COLOR`) > 1 LIMIT 1';
        Result := Existe(
          sSql,
          ['ANTERIOR', 'NUEVO'],
          [AColorAntiguo, AColorNuevo]);
      end;
    end;
    Inc(i);
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
  bHaySegmentoSinAtributo: Boolean;
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
  bHaySegmentoSinAtributo := Existe(
    'SELECT 1 FROM (' + SqlSkusConPosicionColor + ') origen WHERE ' +
    'origen.`ORDEN_AMBIGUO` = 0 AND ' +
    '(CHAR_LENGTH(origen.`CODIGO_UNIDAD`) - CHAR_LENGTH(' +
    'REPLACE(origen.`CODIGO_UNIDAD`, ''/'', ''''))) = ' +
    'origen.`NUM_ATRIBUTOS` AND ' +
    'TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(origen.`CODIGO_UNIDAD`, ' +
    '''/'', origen.`POSICION_COLOR` + 1), ''/'', -1)) = ' +
    'TRIM(:COLOR) AND NOT EXISTS (SELECT 1 FROM ' +
    '`fza_atributos_sku` sa ' +
    'JOIN `fza_atributos_valores` av ON av.`ID_AV` = sa.`ID_AV_SA` ' +
    'WHERE sa.`CODIGO_UNIDAD_SKU_SA` = origen.`CODIGO_UNIDAD` ' +
    'AND av.`ID_VA_AV` = ''CO'' AND ' +
    'TRIM(av.`AV`) = TRIM(:COLOR)) LIMIT 1',
    ['COLOR'],
    [AColorAntiguo]);
  Result := (iNumeroSkuOrigen = NumeroSkuMapa) and
            (not bHaySegmentoSinAtributo);
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
    sCondiciones := sCondiciones + ' OR ' +
      '(posicion_actual.`CODIGO_UNIDAD` IS NULL AND TRIM(fl.`' +
      sCampoValor + '`) = TRIM(:COLOR))';
    sCondiciones := sCondiciones + ' OR ' +
      '(posicion_actual.`POSICION_COLOR` = ' + IntToStr(i) + ' AND ' +
      'TRIM(COALESCE(fl.`' + sCampoNombre + '`, '''')) = '''' AND ' +
      'TRIM(fl.`' + sCampoValor + '`) = TRIM(:COLOR))';
  end;
  sSql := 'SELECT fl.`CODIGO_UNIDAD_FACLIN` ' +
    'FROM `fza_facturas_lineas` fl ' +
    'LEFT JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
    'mapa.`ORIGEN` = fl.`CODIGO_UNIDAD_FACLIN` ' +
    'LEFT JOIN `fza_articulos_skus` sku_actual ON ' +
    'sku_actual.`CODIGO_UNIDAD_SKU` = fl.`CODIGO_UNIDAD_FACLIN` ' +
    'LEFT JOIN (' + SqlSkusConPosicionColor + ') posicion_actual ON ' +
    'posicion_actual.`CODIGO_UNIDAD` = fl.`CODIGO_UNIDAD_FACLIN` AND ' +
    'posicion_actual.`ORDEN_AMBIGUO` = 0 AND ' +
    '(CHAR_LENGTH(posicion_actual.`CODIGO_UNIDAD`) - CHAR_LENGTH(' +
    'REPLACE(posicion_actual.`CODIGO_UNIDAD`, ''/'', ''''))) = ' +
    'posicion_actual.`NUM_ATRIBUTOS` WHERE ' +
    sCondiciones + ' LIMIT 1 FOR UPDATE';
  Result := Existe(
    sSql,
    ['COLOR'],
    [AColorAntiguo]);
end;

function TRepositorioCambioArticuloColorUniDAC.
  HayDestinoEnVentasArticulo(const AArticuloNuevo: string): Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM `fza_facturas_lineas` fl ' +
    'LEFT JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
    'mapa.`DESTINO` = fl.`CODIGO_UNIDAD_FACLIN` ' +
    'WHERE fl.`CODIGO_ART_FACLIN` = :ARTICULO ' +
    'OR fl.`CODIGO_UNIDAD_FACLIN` = :ARTICULO ' +
    'OR LEFT(fl.`CODIGO_UNIDAD_FACLIN`, ' +
    'CHAR_LENGTH(:ARTICULO) + 1) = CONCAT(:ARTICULO, ''/'') ' +
    'OR mapa.`DESTINO` IS NOT NULL LIMIT 1 FOR UPDATE',
    ['ARTICULO'],
    [AArticuloNuevo]);
end;

function TRepositorioCambioArticuloColorUniDAC.
  HayDestinoEnVentasColor(const AColorNuevo: string): Boolean;
var
  i: Integer;
  sCampoNombre: string;
  sCampoValor: string;
  sCondiciones: string;
  sSql: string;
begin
  sCondiciones := 'mapa.`DESTINO` IS NOT NULL OR ' +
    'EXISTS (SELECT 1 FROM `fza_atributos_sku` sa_destino ' +
    'JOIN `fza_atributos_valores` av_destino ON ' +
    'av_destino.`ID_AV` = sa_destino.`ID_AV_SA` ' +
    'WHERE sa_destino.`CODIGO_UNIDAD_SKU_SA` = ' +
    'fl.`CODIGO_UNIDAD_FACLIN` AND ' +
    'av_destino.`ID_VA_AV` = ''CO'' AND ' +
    'TRIM(av_destino.`AV`) = TRIM(:COLOR)) OR ' +
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
    sCondiciones := sCondiciones + ' OR ' +
      '(posicion_actual.`CODIGO_UNIDAD` IS NULL AND TRIM(fl.`' +
      sCampoValor + '`) = TRIM(:COLOR))';
    sCondiciones := sCondiciones + ' OR ' +
      '(posicion_actual.`POSICION_COLOR` = ' + IntToStr(i) + ' AND ' +
      'TRIM(COALESCE(fl.`' + sCampoNombre + '`, '''')) = '''' AND ' +
      'TRIM(fl.`' + sCampoValor + '`) = TRIM(:COLOR))';
  end;
  sSql := 'SELECT 1 FROM `fza_facturas_lineas` fl ' +
    'LEFT JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
    'mapa.`DESTINO` = fl.`CODIGO_UNIDAD_FACLIN` ' +
    'LEFT JOIN `fza_articulos_skus` sku_actual ON ' +
    'sku_actual.`CODIGO_UNIDAD_SKU` = fl.`CODIGO_UNIDAD_FACLIN` ' +
    'LEFT JOIN (' + SqlSkusConPosicionColor + ') posicion_actual ON ' +
    'posicion_actual.`CODIGO_UNIDAD` = fl.`CODIGO_UNIDAD_FACLIN` AND ' +
    'posicion_actual.`ORDEN_AMBIGUO` = 0 AND ' +
    '(CHAR_LENGTH(posicion_actual.`CODIGO_UNIDAD`) - CHAR_LENGTH(' +
    'REPLACE(posicion_actual.`CODIGO_UNIDAD`, ''/'', ''''))) = ' +
    'posicion_actual.`NUM_ATRIBUTOS` WHERE ' +
    sCondiciones + ' LIMIT 1 FOR UPDATE';
  Result := Existe(sSql, ['COLOR'], [AColorNuevo]);
end;

function TRepositorioCambioArticuloColorUniDAC.HayDestinoMapaEnVentas:
  Boolean;
begin
  Result := Existe(
    'SELECT 1 FROM `fza_facturas_lineas` fl ' +
    'JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
    'mapa.`DESTINO` = fl.`CODIGO_UNIDAD_FACLIN` ' +
    'LIMIT 1 FOR UPDATE',
    [],
    []);
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

function TRepositorioCambioArticuloColorUniDAC.HayPrestaShopColor(
  const AColorAntiguo: string): Boolean;
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
     CampoExiste('fza_articulos', 'ESWEB_ART') then
  begin
    Result := Existe(
      'SELECT 1 FROM `fza_articulos` art ' +
      'JOIN `fza_articulos_atributos_basicos` aab ON ' +
      'aab.`CODIGO_ART_AAB` = art.`CODIGO_ART_ART` ' +
      'JOIN `fza_atributos_valores` av ON ' +
      'av.`ID_AV` = aab.`ID_AV_AAB` ' +
      'WHERE av.`ID_VA_AV` = ''CO'' AND ' +
      'TRIM(av.`AV`) = TRIM(:COLOR) AND ' +
      'UPPER(TRIM(COALESCE(art.`ESWEB_ART`, ''N''))) = ''S'' ' +
      'LIMIT 1 FOR UPDATE',
      ['COLOR'],
      [AColorAntiguo]);
  end;
  if (not Result) and
     CampoExiste('fza_articulos', 'ESWEB_ART') then
  begin
    Result := Existe(
      'SELECT 1 FROM `fza_articulos` art ' +
      'JOIN `fza_articulos_conjuntos_asign` aca ON ' +
      'aca.`CODIGO_ART_ACA` = art.`CODIGO_ART_ART` ' +
      'JOIN `fza_atributos_conjuntos_det` acd ON ' +
      'acd.`ID_AC_ACD` = aca.`ID_AC_ACA` ' +
      'JOIN `fza_atributos_valores` av ON ' +
      'av.`ID_AV` = acd.`ID_AV_ACD` ' +
      'WHERE av.`ID_VA_AV` = ''CO'' AND ' +
      'TRIM(av.`AV`) = TRIM(:COLOR) AND ' +
      'UPPER(TRIM(COALESCE(art.`ESWEB_ART`, ''N''))) = ''S'' ' +
      'LIMIT 1 FOR UPDATE',
      ['COLOR'],
      [AColorAntiguo]);
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
  if (not Result) and
     CampoExiste('fza_prestashop_cola', 'CODIGO_ART_PSCOLA') then
  begin
    Result := Existe(
      'SELECT 1 FROM `fza_prestashop_cola` cola ' +
      'JOIN `fza_articulos_atributos_basicos` aab ON ' +
      'aab.`CODIGO_ART_AAB` = cola.`CODIGO_ART_PSCOLA` ' +
      'JOIN `fza_atributos_valores` av ON ' +
      'av.`ID_AV` = aab.`ID_AV_AAB` ' +
      'WHERE av.`ID_VA_AV` = ''CO'' AND ' +
      'TRIM(av.`AV`) = TRIM(:COLOR) LIMIT 1 FOR UPDATE',
      ['COLOR'],
      [AColorAntiguo]);
  end;
  if (not Result) and
     CampoExiste('fza_prestashop_cola', 'CODIGO_ART_PSCOLA') then
  begin
    Result := Existe(
      'SELECT 1 FROM `fza_prestashop_cola` cola ' +
      'JOIN `fza_articulos_conjuntos_asign` aca ON ' +
      'aca.`CODIGO_ART_ACA` = cola.`CODIGO_ART_PSCOLA` ' +
      'JOIN `fza_atributos_conjuntos_det` acd ON ' +
      'acd.`ID_AC_ACD` = aca.`ID_AC_ACA` ' +
      'JOIN `fza_atributos_valores` av ON ' +
      'av.`ID_AV` = acd.`ID_AV_ACD` ' +
      'WHERE av.`ID_VA_AV` = ''CO'' AND ' +
      'TRIM(av.`AV`) = TRIM(:COLOR) LIMIT 1 FOR UPDATE',
      ['COLOR'],
      [AColorAntiguo]);
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
  if CampoExiste(ATabla, 'INSTANTE_MODIF') then
    sAuditoria := ', `INSTANTE_MODIF` = CURRENT_TIMESTAMP';
  if CampoExiste(ATabla, 'USUARIO_MODIF') then
    sAuditoria := sAuditoria + ', `USUARIO_MODIF` = :USUARIO';
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
  if CampoExiste(ATabla, 'INSTANTE_MODIF') then
    sAuditoria := ', dato.`INSTANTE_MODIF` = CURRENT_TIMESTAMP';
  if CampoExiste(ATabla, 'USUARIO_MODIF') then
    sAuditoria := sAuditoria + ', dato.`USUARIO_MODIF` = :USUARIO';
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

procedure TRepositorioCambioArticuloColorUniDAC.EliminarArticuloMaestro(
  const AArticuloAntiguo: string);
begin
  Ejecutar(
    'DELETE FROM `fza_articulos` WHERE `CODIGO_ART_ART` = :ARTICULO',
    ['ARTICULO'],
    [AArticuloAntiguo]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.LimpiarBasicosColorFusion(
  const AColorAntiguo, AUsuario: string);
begin
  Ejecutar(
    'UPDATE `fza_articulos_atributos_basicos` aab ' +
    'JOIN `fza_atributos_valores` av ON av.`ID_AV` = aab.`ID_AV_AAB` ' +
    'SET aab.`ID_ATB_AAB` = NULL, ' +
    'aab.`DESCRIPCION_AAB` = NULL, ' +
    'aab.`USUARIO_MODIF` = :USUARIO ' +
    'WHERE av.`ID_VA_AV` = ''CO'' ' +
    'AND TRIM(av.`AV`) = TRIM(:ANTERIOR)',
    ['ANTERIOR', 'USUARIO'],
    [AColorAntiguo, AUsuario]);
  Ejecutar(
    'UPDATE `fza_atributos_conjuntos_det` acd ' +
    'JOIN `fza_atributos_valores` av ON av.`ID_AV` = acd.`ID_AV_ACD` ' +
    'SET acd.`ID_ATB_ACD` = NULL, ' +
    'acd.`USUARIO_MODIF` = :USUARIO ' +
    'WHERE av.`ID_VA_AV` = ''CO'' ' +
    'AND TRIM(av.`AV`) = TRIM(:ANTERIOR)',
    ['ANTERIOR', 'USUARIO'],
    [AColorAntiguo, AUsuario]);
  Ejecutar(
    'UPDATE `fza_atributos_valores` SET `ID_ATB_AV` = NULL, ' +
    '`DESCRIPCION_AV` = NULL, ' +
    '`USUARIO_MODIF` = :USUARIO WHERE `ID_VA_AV` = ''CO'' ' +
    'AND TRIM(`AV`) = TRIM(:ANTERIOR)',
    ['ANTERIOR', 'USUARIO'],
    [AColorAntiguo, AUsuario]);
end;

procedure TRepositorioCambioArticuloColorUniDAC.ActualizarColorMaestro(
  const AAnterior, ANuevo, AUsuario: string;
  AFusionar: Boolean);
var
  sAuditoria: string;
begin
  if AFusionar then
    LimpiarBasicosColorFusion(AAnterior, AUsuario)
  else
  begin
    Ejecutar(
      'UPDATE `fza_articulos_atributos_basicos` aab ' +
      'JOIN `fza_atributos_valores` av ON ' +
      'av.`ID_AV` = aab.`ID_AV_AAB` ' +
      'SET aab.`DESCRIPCION_AAB` = NULL, ' +
      'aab.`USUARIO_MODIF` = :USUARIO ' +
      'WHERE av.`ID_VA_AV` = ''CO'' AND ' +
      'TRIM(av.`AV`) = TRIM(:ANTERIOR)',
      ['ANTERIOR', 'USUARIO'],
      [AAnterior, AUsuario]);
  end;
  sAuditoria := '';
  if CampoExiste('fza_atributos_valores', 'INSTANTE_MODIF') then
    sAuditoria := ', `INSTANTE_MODIF` = CURRENT_TIMESTAMP';
  if CampoExiste('fza_atributos_valores', 'USUARIO_MODIF') then
    sAuditoria := sAuditoria + ', `USUARIO_MODIF` = :USUARIO';
  Ejecutar(
    'UPDATE `fza_atributos_valores` SET `AV` = :NUEVO, ' +
    '`DESCRIPCION_AV` = NULL' +
    sAuditoria + ' WHERE `ID_VA_AV` = ''CO'' ' +
    'AND TRIM(`AV`) = TRIM(:ANTERIOR)',
    ['ANTERIOR', 'NUEVO', 'USUARIO'],
    [AAnterior, ANuevo, AUsuario]);
end;

function TRepositorioCambioArticuloColorUniDAC.FusionColorEsSegura(
  const AAnterior, ANuevo: string): Boolean;
begin
  Result := not Existe(
    'SELECT 1 FROM `fza_atributos_sku` sa ' +
    'JOIN `fza_atributos_valores` origen ON ' +
    'origen.`ID_AV` = sa.`ID_AV_SA` AND ' +
    'origen.`ID_VA_AV` = ''CO'' AND ' +
    'TRIM(origen.`AV`) = TRIM(:ANTERIOR) ' +
    'JOIN `fza_atributos_sku` sa_destino ON ' +
    'sa_destino.`CODIGO_UNIDAD_SKU_SA` = ' +
    'sa.`CODIGO_UNIDAD_SKU_SA` ' +
    'JOIN `fza_atributos_valores` destino ON ' +
    'destino.`ID_AV` = sa_destino.`ID_AV_SA` AND ' +
    'destino.`ID_VA_AV` = ''CO'' AND ' +
    'TRIM(destino.`AV`) = TRIM(:NUEVO) LIMIT 1',
    ['ANTERIOR', 'NUEVO'],
    [AAnterior, ANuevo]);
  if Result then
  begin
    Result := not Existe(
      'SELECT afectados.`CODIGO_UNIDAD` FROM (SELECT DISTINCT ' +
      'sa.`CODIGO_UNIDAD_SKU_SA` `CODIGO_UNIDAD` FROM ' +
      '`fza_atributos_sku` sa JOIN `fza_atributos_valores` av ON ' +
      'av.`ID_AV` = sa.`ID_AV_SA` WHERE av.`ID_VA_AV` = ''CO'' AND ' +
      'TRIM(av.`AV`) = TRIM(:ANTERIOR)) afectados ' +
      'JOIN `fza_atributos_sku` todos ON ' +
      'todos.`CODIGO_UNIDAD_SKU_SA` = afectados.`CODIGO_UNIDAD` ' +
      'JOIN `fza_atributos_valores` av_todos ON ' +
      'av_todos.`ID_AV` = todos.`ID_AV_SA` ' +
      'WHERE av_todos.`ID_VA_AV` = ''CO'' ' +
      'GROUP BY afectados.`CODIGO_UNIDAD` ' +
      'HAVING COUNT(*) <> 1 LIMIT 1',
      ['ANTERIOR'],
      [AAnterior]);
  end;
  if Result then
  begin
    Result := not Existe(
      'SELECT 1 FROM `fza_articulos_atributos_basicos` origen ' +
      'JOIN `fza_atributos_valores` av_origen ON ' +
      'av_origen.`ID_AV` = origen.`ID_AV_AAB` AND ' +
      'av_origen.`ID_VA_AV` = ''CO'' AND ' +
      'TRIM(av_origen.`AV`) = TRIM(:ANTERIOR) ' +
      'JOIN `fza_articulos_atributos_basicos` destino ON ' +
      'destino.`CODIGO_ART_AAB` = origen.`CODIGO_ART_AAB` ' +
      'JOIN `fza_atributos_valores` av_destino ON ' +
      'av_destino.`ID_AV` = destino.`ID_AV_AAB` AND ' +
      'av_destino.`ID_VA_AV` = ''CO'' AND ' +
      'TRIM(av_destino.`AV`) = TRIM(:NUEVO) LIMIT 1',
      ['ANTERIOR', 'NUEVO'],
      [AAnterior, ANuevo]);
  end;
  if Result then
  begin
    Result := not Existe(
      'SELECT 1 FROM `fza_atributos_conjuntos_det` origen ' +
      'JOIN `fza_atributos_valores` av_origen ON ' +
      'av_origen.`ID_AV` = origen.`ID_AV_ACD` AND ' +
      'av_origen.`ID_VA_AV` = ''CO'' AND ' +
      'TRIM(av_origen.`AV`) = TRIM(:ANTERIOR) ' +
      'JOIN `fza_atributos_conjuntos_det` destino ON ' +
      'destino.`ID_AC_ACD` = origen.`ID_AC_ACD` ' +
      'JOIN `fza_atributos_valores` av_destino ON ' +
      'av_destino.`ID_AV` = destino.`ID_AV_ACD` AND ' +
      'av_destino.`ID_VA_AV` = ''CO'' AND ' +
      'TRIM(av_destino.`AV`) = TRIM(:NUEVO) LIMIT 1',
      ['ANTERIOR', 'NUEVO'],
      [AAnterior, ANuevo]);
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.FusionArticuloEsSegura(
  const AAnterior, ANuevo: string): Boolean;
begin
  Result := not Existe(
    'SELECT 1 FROM `fza_articulos` origen ' +
    'JOIN `fza_articulos` destino ON ' +
    'destino.`CODIGO_ART_ART` = :NUEVO ' +
    'WHERE origen.`CODIGO_ART_ART` = :ANTERIOR AND NOT (' +
    'origen.`TIPO_ART` <=> destino.`TIPO_ART` AND ' +
    'origen.`TIPO_CANTIDAD_ART` <=> destino.`TIPO_CANTIDAD_ART` AND ' +
    'origen.`ESTRAZABLE_ART` <=> destino.`ESTRAZABLE_ART` AND ' +
    'origen.`ESVARIACION_ART` <=> destino.`ESVARIACION_ART` AND ' +
    'origen.`TIPO_VARIACION_ART` <=> ' +
    'destino.`TIPO_VARIACION_ART`) LIMIT 1',
    ['ANTERIOR', 'NUEVO'],
    [AAnterior, ANuevo]);
  if Result then
  begin
    Result := not Existe(
      'SELECT 1 FROM `fza_articulos_skus` sku ' +
      'JOIN `fza_articulos` destino ON ' +
      'destino.`CODIGO_ART_ART` = :NUEVO ' +
      'WHERE sku.`CODIGO_ART_SKU` = :ANTERIOR AND NOT (' +
      '(destino.`ESVARIACION_ART` = ''N'' AND COALESCE(NULLIF(' +
      'TRIM(sku.`CODIGO_VAR_SKU`), ''''), ''-'') = ''-'') OR ' +
      '(destino.`ESVARIACION_ART` = ''S'' AND ' +
      'sku.`CODIGO_VAR_SKU` <=> destino.`TIPO_VARIACION_ART`)) LIMIT 1',
      ['ANTERIOR', 'NUEVO'],
      [AAnterior, ANuevo]);
  end;
  if Result then
  begin
    Result := not Existe(
      'SELECT 1 FROM `fza_articulos_atributos_basicos` origen ' +
      'JOIN `fza_atributos_valores` av_origen ON ' +
      'av_origen.`ID_AV` = origen.`ID_AV_AAB` ' +
      'JOIN `fza_articulos_atributos_basicos` destino ON ' +
      'destino.`CODIGO_ART_AAB` = :NUEVO ' +
      'JOIN `fza_atributos_valores` av_destino ON ' +
      'av_destino.`ID_AV` = destino.`ID_AV_AAB` AND ' +
      'av_destino.`ID_VA_AV` = av_origen.`ID_VA_AV` AND ' +
      'TRIM(av_destino.`AV`) = TRIM(av_origen.`AV`) ' +
      'WHERE origen.`CODIGO_ART_AAB` = :ANTERIOR AND NOT (' +
      'origen.`ID_AV_AAB` = destino.`ID_AV_AAB` AND ' +
      'origen.`ID_ATB_AAB` <=> destino.`ID_ATB_AAB` AND ' +
      'origen.`DESCRIPCION_AAB` <=> destino.`DESCRIPCION_AAB` AND ' +
      'origen.`ORDEN_AAB` <=> destino.`ORDEN_AAB`) LIMIT 1',
      ['ANTERIOR', 'NUEVO'],
      [AAnterior, ANuevo]);
  end;
  if Result then
  begin
    Result := not Existe(
      'SELECT 1 FROM `fza_articulos_conjuntos_asign` origen ' +
      'JOIN `fza_articulos_conjuntos_asign` destino ON ' +
      'destino.`CODIGO_ART_ACA` = :NUEVO AND ' +
      'destino.`ID_VA_ACA` = origen.`ID_VA_ACA` ' +
      'WHERE origen.`CODIGO_ART_ACA` = :ANTERIOR AND NOT (' +
      'origen.`ID_AC_ACA` <=> destino.`ID_AC_ACA` AND ' +
      'origen.`ORDEN_ACA` <=> destino.`ORDEN_ACA` AND ' +
      'origen.`ESGENERACION_AUTO_ACA` <=> ' +
      'destino.`ESGENERACION_AUTO_ACA`) LIMIT 1',
      ['ANTERIOR', 'NUEVO'],
      [AAnterior, ANuevo]);
  end;
  if Result then
  begin
    Result := not Existe(
      'SELECT 1 FROM `fza_articulos_proveedores` origen ' +
      'JOIN `fza_articulos_proveedores` destino ON ' +
      'destino.`CODIGO_ART_AP` = :NUEVO AND ' +
      'destino.`CODIGO_PRV_AP` = origen.`CODIGO_PRV_AP` ' +
      'WHERE origen.`CODIGO_ART_AP` = :ANTERIOR LIMIT 1',
      ['ANTERIOR', 'NUEVO'],
      [AAnterior, ANuevo]);
  end;
  if Result then
  begin
    Result := not Existe(
      'SELECT 1 FROM `fza_articulos_fotos` origen LEFT JOIN `' +
      TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = ' +
      'origen.`CODIGO_UNIDAD_FOT` JOIN `fza_articulos_fotos` destino ' +
      'ON destino.`CODIGO_ART_FOT` = :NUEVO AND ' +
      'destino.`CODIGO_UNIDAD_FOT` = COALESCE(' +
      'mapa.`DESTINO`, origen.`CODIGO_UNIDAD_FOT`) ' +
      'WHERE origen.`CODIGO_ART_FOT` = :ANTERIOR LIMIT 1',
      ['ANTERIOR', 'NUEVO'],
      [AAnterior, ANuevo]);
  end;
  if Result then
  begin
    Result := not Existe(
      'SELECT 1 FROM `fza_articulos_propiedades` origen LEFT JOIN `' +
      TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = ' +
      'origen.`CODIGO_UNIDAD_ARTPROP` ' +
      'JOIN `fza_articulos_propiedades` destino ON ' +
      'destino.`CODIGO_ART_ART` = :NUEVO AND ' +
      'destino.`CODIGO_PROP_ARTPROP` = ' +
      'origen.`CODIGO_PROP_ARTPROP` AND ' +
      'destino.`CODIGO_UNIDAD_ARTPROP` = COALESCE(' +
      'mapa.`DESTINO`, origen.`CODIGO_UNIDAD_ARTPROP`) ' +
      'WHERE origen.`CODIGO_ART_ART` = :ANTERIOR LIMIT 1',
      ['ANTERIOR', 'NUEVO'],
      [AAnterior, ANuevo]);
  end;
  if Result then
  begin
    Result := not Existe(
      'SELECT 1 FROM `fza_tarifas_cambios_lineas` origen LEFT JOIN `' +
      TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = ' +
      'origen.`CODIGO_UNIDAD_SKU_TARCLIN` ' +
      'JOIN `fza_tarifas_cambios_lineas` destino ON ' +
      'destino.`CODIGO_ART_TARCLIN` = :NUEVO AND ' +
      'destino.`CODIGO_TARC_TARCLIN` = ' +
      'origen.`CODIGO_TARC_TARCLIN` AND ' +
      'destino.`CODIGO_UNIDAD_SKU_TARCLIN` = COALESCE(' +
      'mapa.`DESTINO`, origen.`CODIGO_UNIDAD_SKU_TARCLIN`) ' +
      'WHERE origen.`CODIGO_ART_TARCLIN` = :ANTERIOR LIMIT 1',
      ['ANTERIOR', 'NUEVO'],
      [AAnterior, ANuevo]);
  end;
  if Result then
  begin
    Result := not Existe(
      'SELECT 1 FROM `fza_articulos_tarifas` origen LEFT JOIN `' +
      TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = ' +
      'origen.`CODIGO_UNIDAD_ARTTAR` ' +
      'JOIN `fza_articulos_tarifas` destino ON ' +
      'destino.`CODIGO_ART_ARTTAR` = :NUEVO AND ' +
      'destino.`CODIGO_TAR_ARTTAR` = origen.`CODIGO_TAR_ARTTAR` AND ' +
      'COALESCE(destino.`CODIGO_UNIDAD_ARTTAR`, '''') = COALESCE(' +
      'mapa.`DESTINO`, origen.`CODIGO_UNIDAD_ARTTAR`, '''') ' +
      'WHERE origen.`CODIGO_ART_ARTTAR` = :ANTERIOR LIMIT 1',
      ['ANTERIOR', 'NUEVO'],
      [AAnterior, ANuevo]);
  end;
  if Result then
  begin
    Result := not Existe(
      'SELECT 1 FROM `fza_articulos_vinculos` origen WHERE ' +
      '(origen.`CODIGO_ART_PADRE_ARTVIN` = :ANTERIOR OR ' +
      'origen.`CODIGO_ART_HIJO_ARTVIN` = :ANTERIOR) AND (' +
      'CASE WHEN origen.`CODIGO_ART_PADRE_ARTVIN` = :ANTERIOR ' +
      'THEN :NUEVO ELSE origen.`CODIGO_ART_PADRE_ARTVIN` END = ' +
      'CASE WHEN origen.`CODIGO_ART_HIJO_ARTVIN` = :ANTERIOR ' +
      'THEN :NUEVO ELSE origen.`CODIGO_ART_HIJO_ARTVIN` END OR ' +
      'EXISTS (SELECT 1 FROM `fza_articulos_vinculos` destino ' +
      'WHERE destino.`ID_ARTVIN` <> origen.`ID_ARTVIN` AND ' +
      'destino.`CODIGO_ART_PADRE_ARTVIN` = CASE WHEN ' +
      'origen.`CODIGO_ART_PADRE_ARTVIN` = :ANTERIOR THEN :NUEVO ' +
      'ELSE origen.`CODIGO_ART_PADRE_ARTVIN` END AND ' +
      'destino.`CODIGO_ART_HIJO_ARTVIN` = CASE WHEN ' +
      'origen.`CODIGO_ART_HIJO_ARTVIN` = :ANTERIOR THEN :NUEVO ' +
      'ELSE origen.`CODIGO_ART_HIJO_ARTVIN` END)) LIMIT 1',
      ['ANTERIOR', 'NUEVO'],
      [AAnterior, ANuevo]);
  end;
end;

procedure TRepositorioCambioArticuloColorUniDAC.PrepararFusionArticulo(
  const AAnterior, ANuevo: string);
begin
  Ejecutar(
    'DELETE origen FROM `fza_articulos_atributos_basicos` origen ' +
    'JOIN `fza_articulos_atributos_basicos` destino ON ' +
    'destino.`CODIGO_ART_AAB` = :NUEVO AND ' +
    'destino.`ID_AV_AAB` = origen.`ID_AV_AAB` ' +
    'WHERE origen.`CODIGO_ART_AAB` = :ANTERIOR',
    ['ANTERIOR', 'NUEVO'],
    [AAnterior, ANuevo]);
  Ejecutar(
    'DELETE origen FROM `fza_articulos_conjuntos_asign` origen ' +
    'JOIN `fza_articulos_conjuntos_asign` destino ON ' +
    'destino.`CODIGO_ART_ACA` = :NUEVO AND ' +
    'destino.`ID_VA_ACA` = origen.`ID_VA_ACA` ' +
    'WHERE origen.`CODIGO_ART_ACA` = :ANTERIOR',
    ['ANTERIOR', 'NUEVO'],
    [AAnterior, ANuevo]);
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
      sCondicion := CondicionInstantaneaColorSegura(
        'dato',
        sCampo,
        sCampoNombre,
        'ANTERIOR',
        i);
      sValores := sValores + sSeparadorValores + 'dato.`' + sCampo +
        '` = CASE WHEN ' + sCondicion + ' THEN :NUEVO ELSE dato.`' +
        sCampo + '` END';
      sCondiciones := sCondiciones + sSeparadorCondiciones + sCondicion;
      sSeparadorValores := ', ';
      sSeparadorCondiciones := ' OR ';
    end;
  end;
  if (sValores <> '') and CampoExiste(ATabla, 'INSTANTE_MODIF') then
  begin
    sValores := sValores + sSeparadorValores +
      'dato.`INSTANTE_MODIF` = CURRENT_TIMESTAMP';
    sSeparadorValores := ', ';
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
  sCampoNombre: string;
  sCampoDescripcion: string;
  sCasos: string;
  sCondicion: string;
  sCondiciones: string;
  sDescripcionEnvuelta: string;
  sRepeticiones: string;
  sReemplazada: string;
  sToken: string;
begin
  if SameText(ASufijo, 'DTL') then
    sCampoDescripcion := 'DESCRIPCION_UNIDAD_DTL'
  else
    sCampoDescripcion := 'DESCRIPCION_VARIACION_' + ASufijo;
  sCasos := '';
  sCondiciones := '';
  if CampoExiste(ATabla, sCampoDescripcion) then
  begin
    for i := 1 to 5 do
    begin
      sCampo := 'ATTR' + IntToStr(i) + '_VALOR_' + ASufijo;
      sCampoNombre := 'ATTR' + IntToStr(i) + '_NOMBRE_' + ASufijo;
      if CampoExiste(ATabla, sCampo) and
         CampoExiste(ATabla, sCampoNombre) then
      begin
        sCondicion := CondicionInstantaneaColorSegura(
          'dato',
          sCampo,
          sCampoNombre,
          'ANTERIOR',
          i);
        sDescripcionEnvuelta := 'CONCAT('' / '', dato.`' +
          sCampoDescripcion + '`, '' / '')';
        sToken := 'CONCAT('' / '', TRIM(dato.`' + sCampo +
          '`), '' / '')';
        sRepeticiones := '((CHAR_LENGTH(' + sDescripcionEnvuelta +
          ') - CHAR_LENGTH(REPLACE(' + sDescripcionEnvuelta + ', ' +
          sToken + ', ''''))) / NULLIF(CHAR_LENGTH(' + sToken + '), 0))';
        sReemplazada := 'REPLACE(' + sDescripcionEnvuelta + ', ' +
          sToken + ', CONCAT('' / '', :NUEVO, '' / ''))';
        sCasos := sCasos + ' WHEN ' + sCondicion + ' AND ' +
          sRepeticiones + ' = 1 THEN SUBSTRING(' + sReemplazada +
          ', 4, CHAR_LENGTH(' + sReemplazada + ') - 6)';
        if sCondiciones <> '' then
          sCondiciones := sCondiciones + ' OR ';
        sCondiciones := sCondiciones + '(' + sCondicion + ' AND ' +
          sRepeticiones + ' = 1)';
      end;
    end;
  end;
  Result := '';
  if sCasos <> '' then
  begin
    Result := 'UPDATE `' + ATabla + '` dato ' +
      'JOIN `' + TABLA_TEMPORAL + '` mapa ON ' +
      'mapa.`ORIGEN` = dato.`' + ACampoUnidad + '` SET dato.`' +
      sCampoDescripcion + '` = CASE' + sCasos + ' ELSE dato.`' +
      sCampoDescripcion + '` END WHERE dato.`' + sCampoDescripcion +
      '` IS NOT NULL AND TRIM(dato.`' + sCampoDescripcion +
      '`) <> '''' AND (' + sCondiciones + ')';
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
      sSql := SqlActualizacionDescripcion(
        sTabla,
        sCampoUnidad,
        sSufijo);
      if sSql <> '' then
      begin
        Ejecutar(
          sSql,
          ['ANTERIOR', 'NUEVO'],
          [AAnterior, ANuevo]);
      end;
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
          sCondiciones := sCondiciones + CondicionInstantaneaColorSegura(
            'dato',
            sCampo,
            sCampoNombre,
            'COLOR',
            j);
        end;
      end;
      if sCondiciones <> '' then
      begin
        Result := Existe(
          'SELECT 1 FROM `' + sTabla + '` dato JOIN `' +
          TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = dato.`' +
          sCampoUnidad + '` WHERE ' + sCondiciones + ' LIMIT 1',
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
  sPosicionales: string;
  sReconocidas: string;
  sSufijo: string;
  sTabla: string;
  sValores: string;
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
      sPosicionales := '';
      sReconocidas := '';
      sValores := '';
      for j := 1 to 5 do
      begin
        sCampoValor := 'ATTR' + IntToStr(j) + '_VALOR_' + sSufijo;
        sCampoNombre := 'ATTR' + IntToStr(j) + '_NOMBRE_' + sSufijo;
        if CampoExiste(sTabla, sCampoValor) and
           CampoExiste(sTabla, sCampoNombre) then
        begin
          if sReconocidas <> '' then
            sReconocidas := sReconocidas + ' OR ';
          sReconocidas := sReconocidas + CondicionInstantaneaColor(
            'dato',
            sCampoValor,
            sCampoNombre,
            'COLOR');
          if sValores <> '' then
            sValores := sValores + ' OR ';
          sValores := sValores + 'TRIM(dato.`' + sCampoValor +
            '`) = TRIM(:COLOR)';
          if sPosicionales <> '' then
            sPosicionales := sPosicionales + ' OR ';
          sPosicionales := sPosicionales +
            '(posicion_actual.`POSICION_COLOR` = ' + IntToStr(j) +
            ' AND TRIM(COALESCE(dato.`' + sCampoNombre +
            '`, '''')) = '''' AND TRIM(dato.`' + sCampoValor +
            '`) = TRIM(:COLOR))';
        end;
      end;
      if sReconocidas <> '' then
      begin
        Result := Existe(
          'SELECT 1 FROM `' + sTabla + '` dato LEFT JOIN `' +
          TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = dato.`' +
          sCampoUnidad + '` LEFT JOIN (' + SqlSkusConPosicionColor +
          ') posicion_actual ON posicion_actual.`CODIGO_UNIDAD` = ' +
          'dato.`' + sCampoUnidad + '` AND ' +
          'posicion_actual.`ORDEN_AMBIGUO` = 0 AND ' +
          '(CHAR_LENGTH(posicion_actual.`CODIGO_UNIDAD`) - ' +
          'CHAR_LENGTH(REPLACE(posicion_actual.`CODIGO_UNIDAD`, ' +
          '''/'', ''''))) = posicion_actual.`NUM_ATRIBUTOS` ' +
          'WHERE mapa.`ORIGEN` IS NULL AND ((' + sReconocidas +
          ') OR (' + sPosicionales + ') OR ' +
          '(posicion_actual.`CODIGO_UNIDAD` IS NULL AND (' + sValores +
          '))) LIMIT 1',
          ['COLOR'],
          [AColorAntiguo]);
      end;
    end;
    Inc(i);
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.
  HayInstantaneasColorAmbiguas(
    const AColorAntiguo: string): Boolean;
var
  i: Integer;
  j: Integer;
  sCampoNombre: string;
  sCampoUnidad: string;
  sCampoValor: string;
  sCondicionesSeguras: string;
  sConteoValores: string;
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
      sConteoValores := ExpresionConteoValoresAtributos(
        sTabla,
        'dato',
        sSufijo,
        'COLOR');
      sCondicionesSeguras := '';
      for j := 1 to 5 do
      begin
        sCampoValor := 'ATTR' + IntToStr(j) + '_VALOR_' + sSufijo;
        sCampoNombre := 'ATTR' + IntToStr(j) + '_NOMBRE_' + sSufijo;
        if CampoExiste(sTabla, sCampoValor) and
           CampoExiste(sTabla, sCampoNombre) then
        begin
          if sCondicionesSeguras <> '' then
            sCondicionesSeguras := sCondicionesSeguras + ' OR ';
          sCondicionesSeguras := sCondicionesSeguras +
            CondicionInstantaneaColorSegura(
              'dato',
              sCampoValor,
              sCampoNombre,
              'COLOR',
              j);
        end;
      end;
      if sCondicionesSeguras <> '' then
      begin
        Result := Existe(
          'SELECT 1 FROM `' + sTabla + '` dato JOIN `' +
          TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = dato.`' +
          sCampoUnidad + '` WHERE ' + sConteoValores + ' > 0 AND NOT (' +
          sCondicionesSeguras + ') LIMIT 1',
          ['COLOR'],
          [AColorAntiguo]);
      end;
    end;
    Inc(i);
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.
  HayDescripcionesColorAmbiguas(
    const AColorAntiguo, AColorNuevo: string): Boolean;
var
  i: Integer;
  j: Integer;
  sCampoDescripcion: string;
  sCampoNombre: string;
  sCampoUnidad: string;
  sCampoValor: string;
  sCondicion: string;
  sCondiciones: string;
  sCondicionesSeguras: string;
  sConteoValores: string;
  sDescripcionEnvuelta: string;
  sRepeticiones: string;
  sRepeticionesSinMayusculas: string;
  sSufijo: string;
  sTabla: string;
  sTextoAntiguoEnDescripcion: string;
  sToken: string;
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
    if SameText(sSufijo, 'DTL') then
      sCampoDescripcion := 'DESCRIPCION_UNIDAD_DTL'
    else
      sCampoDescripcion := 'DESCRIPCION_VARIACION_' + sSufijo;
    if CampoExiste(sTabla, sCampoUnidad) and
       CampoExiste(sTabla, sCampoDescripcion) then
    begin
      sCondiciones := '';
      sCondicionesSeguras := '';
      sConteoValores := ExpresionConteoValoresAtributos(
        sTabla,
        'dato',
        sSufijo,
        'COLOR');
      sTextoAntiguoEnDescripcion :=
        'LOCATE(LOWER(TRIM(:COLOR)), LOWER(dato.`' +
        sCampoDescripcion + '`)) > 0';
      for j := 1 to 5 do
      begin
        sCampoValor := 'ATTR' + IntToStr(j) + '_VALOR_' + sSufijo;
        sCampoNombre := 'ATTR' + IntToStr(j) + '_NOMBRE_' + sSufijo;
        if CampoExiste(sTabla, sCampoValor) and
           CampoExiste(sTabla, sCampoNombre) then
        begin
          sCondicion := CondicionInstantaneaColorSegura(
            'dato',
            sCampoValor,
            sCampoNombre,
            'COLOR',
            j);
          if sCondicionesSeguras <> '' then
            sCondicionesSeguras := sCondicionesSeguras + ' OR ';
          sCondicionesSeguras := sCondicionesSeguras + sCondicion;
          sDescripcionEnvuelta := 'CONCAT('' / '', dato.`' +
            sCampoDescripcion + '`, '' / '')';
          sToken := 'CONCAT('' / '', TRIM(dato.`' + sCampoValor +
            '`), '' / '')';
          sRepeticiones := '((CHAR_LENGTH(' + sDescripcionEnvuelta +
            ') - CHAR_LENGTH(REPLACE(' + sDescripcionEnvuelta + ', ' +
            sToken + ', ''''))) / NULLIF(CHAR_LENGTH(' + sToken +
            '), 0))';
          sRepeticionesSinMayusculas := '((CHAR_LENGTH(LOWER(' +
            sDescripcionEnvuelta + ')) - CHAR_LENGTH(REPLACE(LOWER(' +
            sDescripcionEnvuelta + '), LOWER(' + sToken +
            '), ''''))) / NULLIF(CHAR_LENGTH(' + sToken + '), 0))';
          if sCondiciones <> '' then
            sCondiciones := sCondiciones + ' OR ';
          sCondiciones := sCondiciones + '(' + sCondicion + ' AND (' +
            sRepeticionesSinMayusculas + ' > 1 OR (' +
            sRepeticionesSinMayusculas + ' = 1 AND ' + sRepeticiones +
            ' <> 1) OR (' + sRepeticionesSinMayusculas + ' = 0 AND ' +
            'LOCATE(LOWER(TRIM(dato.`' + sCampoValor + '`)), LOWER(' +
            'dato.`' + sCampoDescripcion + '`)) > 0) OR (' +
            sRepeticiones + ' = 1 AND CHAR_LENGTH(dato.`' +
            sCampoDescripcion + '`) - CHAR_LENGTH(TRIM(dato.`' +
            sCampoValor + '`)) + CHAR_LENGTH(:NUEVO) > COALESCE((' +
            'SELECT col.`CHARACTER_MAXIMUM_LENGTH` FROM ' +
            '`INFORMATION_SCHEMA`.`COLUMNS` col WHERE ' +
            'col.`TABLE_SCHEMA` = DATABASE() AND col.`TABLE_NAME` = ''' +
            sTabla + ''' AND col.`COLUMN_NAME` = ''' + sCampoDescripcion +
            ''' LIMIT 1), 65535))))';
        end;
      end;
      if sCondicionesSeguras = '' then
        sCondicionesSeguras := '0 = 1';
      if sCondiciones <> '' then
        sCondiciones := sCondiciones + ' OR ';
      sCondiciones := sCondiciones + '(' +
        sTextoAntiguoEnDescripcion + ' AND COALESCE((' +
        sCondicionesSeguras + '), 0) = 0)';
      sCondiciones := sCondiciones + ' OR (' + sConteoValores +
        ' > 1 AND ' + sTextoAntiguoEnDescripcion + ')';
      if sCondiciones <> '' then
      begin
        Result := Existe(
          'SELECT 1 FROM `' + sTabla + '` dato JOIN `' +
          TABLA_TEMPORAL + '` mapa ON mapa.`ORIGEN` = dato.`' +
          sCampoUnidad + '` WHERE dato.`' + sCampoDescripcion +
          '` IS NOT NULL AND TRIM(dato.`' + sCampoDescripcion +
          '`) <> '''' AND (' + sCondiciones + ') LIMIT 1',
          ['COLOR', 'NUEVO'],
          [AColorAntiguo, AColorNuevo]);
      end;
    end;
    Inc(i);
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.ValidarCambioArticulo(
  const AAnterior, ANuevo: string;
  AFusionar: Boolean): TResultadoCambioArticuloColor;
begin
  Result := TResultadoCambioArticuloColor.Correcto(0);
  BloquearArticulos(AAnterior, ANuevo);
  if ArticulosCoincidenEnBaseDatos(AAnterior, ANuevo) then
  begin
    Result := TResultadoCambioArticuloColor.Error(
      mcacDatosInvalidos,
      'Origen y destino son la misma identidad para la base de datos.');
  end
  else if not ExisteArticulo(AAnterior) then
    Result := TResultadoCambioArticuloColor.Error(mcacOrigenNoExiste)
  else if AFusionar and (not ExisteArticulo(ANuevo)) then
  begin
    Result := TResultadoCambioArticuloColor.Error(
      mcacDatosInconsistentes,
      'El artículo destino de la fusión no existe.');
  end
  else if (not AFusionar) and ExisteArticulo(ANuevo) then
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
    else if HayPrestaShopArticulo(AAnterior) or
            HayPrestaShopArticulo(ANuevo) then
      Result := TResultadoCambioArticuloColor.Error(mcacIntegracionExterna)
    else if HayDestinoEnVentasArticulo(ANuevo) or
            HayDestinoMapaEnVentas then
      Result := TResultadoCambioArticuloColor.Error(mcacExistenVentas)
    else if AFusionar and
            (not FusionArticuloEsSegura(AAnterior, ANuevo)) then
    begin
      Result := TResultadoCambioArticuloColor.Error(
        mcacDatosInconsistentes,
        'Los artículos tienen datos maestros incompatibles.');
    end
    else if ((not AFusionar) and
             HayDestinoEnReferencias(REFERENCIAS_ARTICULO)) or
            HayDestinoEnReferencias(REFERENCIAS_UNIDAD) then
      Result := TResultadoCambioArticuloColor.Error(mcacColisionUnidades)
    else
      Result := TResultadoCambioArticuloColor.Correcto(NumeroSkuMapa);
  end;
end;

function TRepositorioCambioArticuloColorUniDAC.ValidarCambioColor(
  const AAnterior, ANuevo: string;
  AFusionar: Boolean): TResultadoCambioArticuloColor;
begin
  Result := TResultadoCambioArticuloColor.Correcto(0);
  BloquearColores(AAnterior, ANuevo);
  if ColoresCoincidenEnBaseDatos(AAnterior, ANuevo) then
  begin
    Result := TResultadoCambioArticuloColor.Error(
      mcacDatosInvalidos,
      'Origen y destino son el mismo color para la base de datos.');
  end
  else if not ExisteColor(AAnterior) then
    Result := TResultadoCambioArticuloColor.Error(mcacOrigenNoExiste)
  else if AFusionar and (not ExisteColor(ANuevo)) then
  begin
    Result := TResultadoCambioArticuloColor.Error(
      mcacDatosInconsistentes,
      'El color destino de la fusión no existe.');
  end
  else if (not AFusionar) and ExisteColor(ANuevo) then
    Result := TResultadoCambioArticuloColor.Error(mcacDestinoYaExiste)
  else
  begin
    ConstruirMapaColor(AAnterior, ANuevo);
    AgregarMapaColorReferencias(AAnterior, ANuevo);
    if HayMapaColorReferenciasAmbiguo(AAnterior, ANuevo) then
    begin
      Result := TResultadoCambioArticuloColor.Error(
        mcacDatosInconsistentes,
        'Una referencia parcial admite más de un destino de color.');
    end
    else if not MapaColorEsCompleto(AAnterior) then
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
    else if HayInstantaneasColorAmbiguas(AAnterior) or
            HayDescripcionesColorAmbiguas(AAnterior, ANuevo) then
    begin
      Result := TResultadoCambioArticuloColor.Error(
        mcacDatosInconsistentes,
        'Hay instantáneas cuyo atributo de color es ambiguo.');
    end
    else if AFusionar and (not FusionColorEsSegura(AAnterior, ANuevo)) then
    begin
      Result := TResultadoCambioArticuloColor.Error(
        mcacDatosInconsistentes,
        'El color origen y el destino coinciden en SKU o conjuntos.');
    end
    else if MapaTieneCodigosLargos or MapaTieneDestinosDuplicados then
      Result := TResultadoCambioArticuloColor.Error(mcacColisionUnidades)
    else if HayVentasColor(AAnterior) then
      Result := TResultadoCambioArticuloColor.Error(mcacExistenVentas)
    else if HayPrestaShopColor(AAnterior) or
            (AFusionar and HayPrestaShopColor(ANuevo)) then
      Result := TResultadoCambioArticuloColor.Error(mcacIntegracionExterna)
    else if HayDestinoEnVentasColor(ANuevo) or
            HayDestinoMapaEnVentas then
      Result := TResultadoCambioArticuloColor.Error(mcacExistenVentas)
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
  Result := (not ExisteColor(AColorAntiguo)) and
            (not HayOrigenEnReferencias(REFERENCIAS_UNIDAD)) and
            (not HayUnidadesColorSinMapa(AColorAntiguo)) and
            (not HayInstantaneasColorSinMapa(AColorAntiguo)) and
            (not HayInstantaneasColorAntiguo(AColorAntiguo));
end;

function TRepositorioCambioArticuloColorUniDAC.CambiarArticulo(
  const AArticuloAntiguo, AArticuloNuevo, AUsuario: string):
  TResultadoCambioArticuloColor;
begin
  Result := EjecutarCambioArticulo(
    AArticuloAntiguo,
    AArticuloNuevo,
    AUsuario,
    False);
end;

function TRepositorioCambioArticuloColorUniDAC.FusionarArticulo(
  const AArticuloAntiguo, AArticuloDestino, AUsuario: string):
  TResultadoCambioArticuloColor;
begin
  Result := EjecutarCambioArticulo(
    AArticuloAntiguo,
    AArticuloDestino,
    AUsuario,
    True);
end;

function TRepositorioCambioArticuloColorUniDAC.EjecutarCambioArticulo(
  const AArticuloAntiguo, AArticuloNuevo, AUsuario: string;
  AFusionar: Boolean): TResultadoCambioArticuloColor;
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
          AArticuloNuevo,
          AFusionar);
        if Result.EsCorrecto then
        begin
          if AFusionar then
            PrepararFusionArticulo(
              AArticuloAntiguo,
              AArticuloNuevo);
          ActualizarReferenciasUnidad(AUsuario);
          ActualizarSkuMaestro(AUsuario);
          ActualizarReferenciasArticulo(
            AArticuloAntiguo,
            AArticuloNuevo,
            AUsuario);
          if AFusionar then
            EliminarArticuloMaestro(AArticuloAntiguo)
          else
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
  Result := EjecutarCambioColor(
    AColorAntiguo,
    AColorNuevo,
    AUsuario,
    False);
end;

function TRepositorioCambioArticuloColorUniDAC.FusionarColor(
  const AColorAntiguo, AColorDestino, AUsuario: string):
  TResultadoCambioArticuloColor;
begin
  Result := EjecutarCambioColor(
    AColorAntiguo,
    AColorDestino,
    AUsuario,
    True);
end;

function TRepositorioCambioArticuloColorUniDAC.EjecutarCambioColor(
  const AColorAntiguo, AColorNuevo, AUsuario: string;
  AFusionar: Boolean): TResultadoCambioArticuloColor;
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
        Result := ValidarCambioColor(
          AColorAntiguo,
          AColorNuevo,
          AFusionar);
        if Result.EsCorrecto then
        begin
          ActualizarInstantaneasColor(
            AColorAntiguo,
            AColorNuevo,
            AUsuario);
          ActualizarReferenciasUnidad(AUsuario);
          ActualizarSkuMaestro(AUsuario);
          ActualizarColorMaestro(
            AColorAntiguo,
            AColorNuevo,
            AUsuario,
            AFusionar);
          if not VerificarCambioColor(AColorAntiguo) then
          begin
            Result := TResultadoCambioArticuloColor.Error(
              mcacDatosInconsistentes,
              'Persisten referencias al color antiguo.');
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
