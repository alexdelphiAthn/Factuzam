{******************************************************************************}
{                                                                              }
{                       Módulo: UniDataInformeDocumento                        }
{                                Versión: 1.1.0                                }
{                              Fecha: 22/09/2026                               }
{                       Autor: Alejandro Laorden Hidalgo                       }
{                                                                              }
{             Presupuestos e impresión de documentos comerciales.              }
{******************************************************************************}
unit UniDataInformeDocumento;

interface

uses
  inLibMsgPresupuestos,
  System.Classes, Uni, frxDBSet, inLibDocumentoIntf;

type
  TDatosInformeDocumento = class(TComponent)
  private
    FCabecera: TUniQuery;
    FLineas: TUniQuery;
    FImpuestos: TUniQuery;
    FDatosCabecera: TfrxDBDataset;
    FDatosLineas: TfrxDBDataset;
    FDatosImpuestos: TfrxDBDataset;
    procedure ConfigurarCabecera(const AConfig: TConfiguracionDocumento);
    procedure ConfigurarLineas(const AConfig: TConfiguracionDocumento);
    procedure ConfigurarImpuestos(const AConfig: TConfiguracionDocumento);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Abrir(AConexion: TUniConnection;
      const AConfig: TConfiguracionDocumento;
      const ASerie, ANumero: string);
    property Cabecera: TfrxDBDataset read FDatosCabecera;
    property Lineas: TfrxDBDataset read FDatosLineas;
    // Desglose por tipo de IVA: solo los tipos con base o cuota.
    property Impuestos: TfrxDBDataset read FDatosImpuestos;
  end;

implementation

uses
  System.SysUtils, Data.DB;

const
  SALTO_SQL = 'CHAR(13,10)';

constructor TDatosInformeDocumento.Create(AOwner: TComponent);
begin
  inherited;
  FCabecera := TUniQuery.Create(Self);
  FCabecera.ReadOnly := True;
  FLineas := TUniQuery.Create(Self);
  FLineas.ReadOnly := True;
  FImpuestos := TUniQuery.Create(Self);
  FImpuestos.ReadOnly := True;
  FDatosCabecera := TfrxDBDataset.Create(Self);
  FDatosCabecera.UserName := 'Cabecera';
  FDatosCabecera.DataSet := FCabecera;
  FDatosLineas := TfrxDBDataset.Create(Self);
  FDatosLineas.UserName := 'Lineas';
  FDatosLineas.DataSet := FLineas;
  FDatosImpuestos := TfrxDBDataset.Create(Self);
  FDatosImpuestos.UserName := 'Impuestos';
  FDatosImpuestos.DataSet := FImpuestos;
end;

// Texto vacio como NULL, para que CONCAT_WS se salte el dato.
function SinVacio(const AExpresion: string): string;
begin
  Result := 'NULLIF(TRIM(' + AExpresion + '), '''')';
end;

// Bloque de direccion en varias lineas (sin huecos por datos vacios):
// direccion, CP y poblacion, provincia y pais, contacto y NIF.
function BloqueDireccion(const ASujeto, ANif, ASufijo: string): string;
  function Campo(const ANombre: string): string;
  begin
    Result := ANombre + '_' + ASujeto + ASufijo;
  end;
begin
  Result := 'COALESCE(CONCAT_WS(' + SALTO_SQL + ', ' +
    SinVacio('CONCAT_WS('' '', ' + Campo('DIRECCION1') + ', ' +
      Campo('DIRECCION2') + ')') + ', ' +
    SinVacio('CONCAT_WS('' '', ' + Campo('CODIGO_POSTAL') + ', ' +
      Campo('POBLACION') + ')') + ', ' +
    SinVacio('CONCAT_WS('' - '', ' + SinVacio(Campo('PROVINCIA')) +
      ', ' + SinVacio(Campo('NOMBRE_PAI')) + ')') + ', ' +
    SinVacio('CONCAT_WS('' · '', ' + SinVacio(Campo('MOVIL')) + ', ' +
      SinVacio(Campo('EMAIL')) + ')') + ', ' +
    'CONCAT(' + QuotedStr(SInformeNifDocumento) + ', ' +
      SinVacio('NIF_' + ANif + ASufijo) + ')), '''')';
end;

procedure TDatosInformeDocumento.ConfigurarCabecera(
  const AConfig: TConfiguracionDocumento);
var
  sSufijo, sTercero, sNif, sValidez, sFormaPago, sNotas: string;
begin
  sSufijo := '_' + AConfig.PrefijoCabecera;
  sTercero := 'CLIENTE';
  if AConfig.Sentido = sdCompra then
    sTercero := 'PRV';
  sNif := sTercero;
  if (AConfig.TipoDocumento = tdPedido) and
     (AConfig.Sentido = sdVenta) then
    sTercero := 'CLIENTE_FISCAL';
  // Solo el presupuesto tiene fecha de validez.
  sValidez := '''''';
  if AConfig.TipoDocumento = tdPresupuesto then
    sValidez := 'COALESCE(CONCAT(' + QuotedStr(SInformeValidezDocumento) +
      ', DATE_FORMAT(FECHA_VALIDEZ' + sSufijo + ', ''%d/%m/%Y'')), '''')';
  sFormaPago := 'COALESCE((SELECT FP.DESCRIPCION_FORMA_PAGO_FP ' +
    'FROM fza_formas_pago FP WHERE FP.CODIGO_FP_FP = FORMA_PAGO' +
    sSufijo + '), FORMA_PAGO' + sSufijo + ', '''')';
  sNotas := 'COALESCE(CONCAT_WS(' + SALTO_SQL + ', ' +
    SinVacio('COMENTARIOS' + sSufijo) + ', ' +
    SinVacio('OBSERVACIONES' + sSufijo) + '), '''')';
  // Los alias anteriores se conservan: los formatos personalizados que
  // el usuario haya guardado siguen encontrando sus campos.
  FCabecera.SQL.Text :=
    'SELECT SERIE' + sSufijo + ' AS SERIE, NUMERO' + sSufijo +
    ' AS NUMERO, FECHA' + sSufijo + ' AS FECHA, ' +
    'RAZON_SOCIAL_EMPRESA' + sSufijo + ' AS EMPRESA, ' +
    'NIF_EMPRESA' + sSufijo + ' AS NIF_EMPRESA, ' +
    'DIRECCION1_EMPRESA' + sSufijo + ' AS DIRECCION_EMPRESA, ' +
    'POBLACION_EMPRESA' + sSufijo + ' AS POBLACION_EMPRESA, ' +
    BloqueDireccion('EMPRESA', 'EMPRESA', sSufijo) +
    ' AS BLOQUE_EMPRESA, ' +
    'RAZON_SOCIAL_' + sTercero + sSufijo + ' AS TERCERO, ' +
    'NIF_' + sNif + sSufijo + ' AS NIF_TERCERO, ' +
    'DIRECCION1_' + sTercero + sSufijo + ' AS DIRECCION_TERCERO, ' +
    'POBLACION_' + sTercero + sSufijo + ' AS POBLACION_TERCERO, ' +
    BloqueDireccion(sTercero, sNif, sSufijo) + ' AS BLOQUE_TERCERO, ' +
    'TOTAL_BASES' + sSufijo + ' AS BASES, TOTAL_IMPUESTOS' + sSufijo +
    ' AS IMPUESTOS, TOTAL_RETENCION' + sSufijo + ' AS RETENCION, ' +
    'COALESCE(PORCENTAJE_RETENCION' + sSufijo +
    ', 0) AS PORCENTAJE_RETENCION, ' +
    'TOTAL_LIQUIDO' + sSufijo + ' AS TOTAL, COMENTARIOS' + sSufijo +
    ' AS COMENTARIOS, OBSERVACIONES' + sSufijo + ' AS OBSERVACIONES, ' +
    sNotas + ' AS NOTAS, ' +
    'FORMA_PAGO' + sSufijo + ' AS FORMA_PAGO, ' +
    sFormaPago + ' AS FORMA_PAGO_DESCRIPCION, ' +
    sValidez + ' AS VALIDEZ FROM ' +
    AConfig.TablaCabecera + ' WHERE SERIE' + sSufijo + ' = :SERIE ' +
    'AND NUMERO' + sSufijo + ' = :NUMERO';
end;

function PrecioLinea(const AConfig: TConfiguracionDocumento): string;
begin
  Result := 'PRECIO_VENTA_SIVA_ARTICULO';
  if AConfig.Sentido = sdCompra then
    Result := 'PRECIO_COMPRA_SIVA_ARTICULO';
  Result := Result + '_' + AConfig.PrefijoLineas;
end;

procedure TDatosInformeDocumento.ConfigurarLineas(
  const AConfig: TConfiguracionDocumento);
var
  sSufijo, sPrecio, sVariante, sCelda, sLineaCelda, sTallas: string;
  sDetalle: string;
  iAtributo: Integer;
begin
  sSufijo := '_' + AConfig.PrefijoLineas;
  sPrecio := PrecioLinea(AConfig);
  sVariante := 'CONCAT_WS('' / ''';
  for iAtributo := 1 to 5 do
    sVariante := sVariante + ', NULLIF(ATTR' + IntToStr(iAtributo) +
      '_VALOR' + sSufijo + ', '''')';
  sVariante := sVariante + ')';
  if AConfig.PrefijoLineas <> 'PEDLIN' then
    sVariante := 'COALESCE(NULLIF(DESCRIPCION_VARIACION' + sSufijo +
      ', ''''), ' + sVariante + ')';
  sCelda := AConfig.PrefijoCabecera + 'CEL';
  sLineaCelda := 'LINEA_' + sCelda;
  if AConfig.Sentido = sdCompra then
    sLineaCelda := 'LINEA_PEDC_PEDCCEL';
  sTallas := '(SELECT GROUP_CONCAT(CONCAT(V.AV, '': '', ' +
    'C.CANTIDAD_' + sCelda + ') ORDER BY V.ORDEN_AV, V.AV ' +
    'SEPARATOR '' / '') FROM ' + AConfig.TablaCabecera + '_celdas C ' +
    'JOIN fza_atributos_valores V ON V.ID_AV = C.ID_AV_PIVOT_' +
    sCelda + ' WHERE C.SERIE_' + AConfig.PrefijoCabecera + '_' +
    sCelda + ' = L.' + AConfig.CampoSerieLinea +
    ' AND C.NUMERO_' + AConfig.PrefijoCabecera + '_' + sCelda +
    ' = L.' + AConfig.CampoNumeroLinea + ' AND C.' + sLineaCelda +
    ' = L.LINEA' + sSufijo + ' AND C.CANTIDAD_' + sCelda + ' <> 0)';
  // Descripcion y, debajo, variante y tallas solo si las hay.
  sDetalle := 'CONCAT_WS(' + SALTO_SQL + ', COALESCE(' +
    SinVacio('DESCRIPCION_ARTICULO' + sSufijo) + ', CODIGO_ART' +
    sSufijo + ', ''''), ' + SinVacio('CONCAT_WS('' · '', ' +
    SinVacio(sVariante) + ', ' + SinVacio(sTallas) + ')') + ')';
  FLineas.SQL.Text :=
    'SELECT LINEA' + sSufijo + ' AS LINEA, CODIGO_ART' + sSufijo +
    ' AS ARTICULO, CODIGO_UNIDAD' + sSufijo + ' AS SKU, ' +
    'DESCRIPCION_ARTICULO' + sSufijo + ' AS DESCRIPCION, ' +
    sVariante + ' AS VARIACION, ' + sTallas + ' AS TALLAS, ' +
    sDetalle + ' AS DETALLE, ' +
    'COALESCE(TIPO_CANTIDAD_ARTICULO' + sSufijo + ', '''') AS UNIDAD, ' +
    'CANTIDAD' + sSufijo + ' AS CANTIDAD, ' + sPrecio +
    ' AS PRECIO, PORCENTAJE_IVA' + sSufijo + ' AS IVA, ' +
    'ROUND(CANTIDAD' + sSufijo + ' * ' + sPrecio +
    ', 2) AS TOTAL FROM ' + AConfig.TablaLineas + ' L' +
    ' WHERE ' + AConfig.CampoSerieLinea + ' = :SERIE AND ' +
    AConfig.CampoNumeroLinea + ' = :NUMERO ORDER BY LINEA' + sSufijo;
end;

procedure TDatosInformeDocumento.ConfigurarImpuestos(
  const AConfig: TConfiguracionDocumento);
const
  TIPOS: array[0..3] of Char = ('N', 'R', 'S', 'E');
var
  sSufijo, sSufijoLin, sBase, sNombre, sSql: string;
  iTipo: Integer;
begin
  sSufijo := '_' + AConfig.PrefijoCabecera;
  sSufijoLin := '_' + AConfig.PrefijoLineas;
  sSql := '';
  for iTipo := 0 to High(TIPOS) do
  begin
    case TIPOS[iTipo] of
      'N': sNombre := SInformeIvaNormalDocumento;
      'R': sNombre := SInformeIvaReducidoDocumento;
      'S': sNombre := SInformeIvaSuperreducidoDocumento;
    else
      sNombre := SInformeIvaExentoDocumento;
    end;
    // La base sale de las lineas (la cabecera de presupuestos y
    // albaranes no la guarda por tipo); la cuota, de la cabecera.
    sBase := '(SELECT COALESCE(SUM(ROUND(L.CANTIDAD' + sSufijoLin +
      ' * L.' + PrecioLinea(AConfig) + ', 2)), 0) FROM ' +
      AConfig.TablaLineas + ' L WHERE L.' + AConfig.CampoSerieLinea +
      ' = :SERIE AND L.' + AConfig.CampoNumeroLinea + ' = :NUMERO ' +
      'AND COALESCE(NULLIF(L.TIPO_IVA_ARTICULO' + sSufijoLin +
      ', ''''), ''N'') = ''' + TIPOS[iTipo] + ''')';
    if sSql <> '' then
      sSql := sSql + ' UNION ALL ';
    sSql := sSql + 'SELECT ' + IntToStr(iTipo) + ' AS ORDEN, ' +
      QuotedStr(sNombre) + ' AS NOMBRE, COALESCE(PORCENTAJE_IVA' +
      TIPOS[iTipo] + sSufijo + ', 0) AS PORCENTAJE, ' + sBase +
      ' AS BASE, COALESCE(TOTAL_IVA' + TIPOS[iTipo] + sSufijo +
      ', 0) AS CUOTA FROM ' + AConfig.TablaCabecera +
      ' WHERE SERIE' + sSufijo + ' = :SERIE AND NUMERO' + sSufijo +
      ' = :NUMERO';
  end;
  FImpuestos.SQL.Text := 'SELECT NOMBRE, PORCENTAJE, BASE, CUOTA ' +
    'FROM (' + sSql + ') T WHERE BASE <> 0 OR CUOTA <> 0 ORDER BY ORDEN';
end;

procedure TDatosInformeDocumento.Abrir(AConexion: TUniConnection;
  const AConfig: TConfiguracionDocumento;
  const ASerie, ANumero: string);
var
  Consultas: TArray<TUniQuery>;
  oConsulta: TUniQuery;
begin
  FCabecera.Close;
  FLineas.Close;
  FImpuestos.Close;
  ConfigurarCabecera(AConfig);
  ConfigurarLineas(AConfig);
  ConfigurarImpuestos(AConfig);
  Consultas := TArray<TUniQuery>.Create(FCabecera, FLineas, FImpuestos);
  for oConsulta in Consultas do
  begin
    oConsulta.Connection := AConexion;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
  end;
  FCabecera.Open;
  if FCabecera.IsEmpty then
    raise Exception.Create(SErrorDocumentoImpresionNoExiste);
  FLineas.Open;
  FImpuestos.Open;
end;

end.
