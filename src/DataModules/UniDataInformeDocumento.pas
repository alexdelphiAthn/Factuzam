{******************************************************************************}
{                                                                              }
{                       Módulo: UniDataInformeDocumento                        }
{                                Versión: 1.0.0                                }
{                              Fecha: 15/09/2026                               }
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
    FDatosCabecera: TfrxDBDataset;
    FDatosLineas: TfrxDBDataset;
    procedure ConfigurarCabecera(const AConfig: TConfiguracionDocumento);
    procedure ConfigurarLineas(const AConfig: TConfiguracionDocumento);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Abrir(AConexion: TUniConnection;
      const AConfig: TConfiguracionDocumento;
      const ASerie, ANumero: string);
    property Cabecera: TfrxDBDataset read FDatosCabecera;
    property Lineas: TfrxDBDataset read FDatosLineas;
  end;

implementation

uses
  System.SysUtils, Data.DB;

constructor TDatosInformeDocumento.Create(AOwner: TComponent);
begin
  inherited;
  FCabecera := TUniQuery.Create(Self);
  FCabecera.ReadOnly := True;
  FLineas := TUniQuery.Create(Self);
  FLineas.ReadOnly := True;
  FDatosCabecera := TfrxDBDataset.Create(Self);
  FDatosCabecera.UserName := 'Cabecera';
  FDatosCabecera.DataSet := FCabecera;
  FDatosLineas := TfrxDBDataset.Create(Self);
  FDatosLineas.UserName := 'Lineas';
  FDatosLineas.DataSet := FLineas;
end;

procedure TDatosInformeDocumento.ConfigurarCabecera(
  const AConfig: TConfiguracionDocumento);
var
  sSufijo, sTercero, sNif: string;
begin
  sSufijo := '_' + AConfig.PrefijoCabecera;
  sTercero := 'CLIENTE';
  if AConfig.Sentido = sdCompra then
    sTercero := 'PRV';
  sNif := sTercero;
  if (AConfig.TipoDocumento = tdPedido) and
     (AConfig.Sentido = sdVenta) then
    sTercero := 'CLIENTE_FISCAL';
  FCabecera.SQL.Text :=
    'SELECT SERIE' + sSufijo + ' AS SERIE, NUMERO' + sSufijo +
    ' AS NUMERO, FECHA' + sSufijo + ' AS FECHA, ' +
    'RAZON_SOCIAL_EMPRESA' + sSufijo + ' AS EMPRESA, ' +
    'NIF_EMPRESA' + sSufijo + ' AS NIF_EMPRESA, ' +
    'DIRECCION1_EMPRESA' + sSufijo + ' AS DIRECCION_EMPRESA, ' +
    'POBLACION_EMPRESA' + sSufijo + ' AS POBLACION_EMPRESA, ' +
    'RAZON_SOCIAL_' + sTercero + sSufijo + ' AS TERCERO, ' +
    'NIF_' + sNif + sSufijo + ' AS NIF_TERCERO, ' +
    'DIRECCION1_' + sTercero + sSufijo + ' AS DIRECCION_TERCERO, ' +
    'POBLACION_' + sTercero + sSufijo + ' AS POBLACION_TERCERO, ' +
    'TOTAL_BASES' + sSufijo + ' AS BASES, TOTAL_IMPUESTOS' + sSufijo +
    ' AS IMPUESTOS, TOTAL_RETENCION' + sSufijo + ' AS RETENCION, ' +
    'TOTAL_LIQUIDO' + sSufijo + ' AS TOTAL, COMENTARIOS' + sSufijo +
    ' AS COMENTARIOS, OBSERVACIONES' + sSufijo + ' AS OBSERVACIONES, ' +
    'FORMA_PAGO' + sSufijo + ' AS FORMA_PAGO FROM ' +
    AConfig.TablaCabecera + ' WHERE SERIE' + sSufijo + ' = :SERIE ' +
    'AND NUMERO' + sSufijo + ' = :NUMERO';
end;

procedure TDatosInformeDocumento.ConfigurarLineas(
  const AConfig: TConfiguracionDocumento);
var
  sSufijo, sPrecio, sVariante, sCelda, sLineaCelda, sTallas: string;
  iAtributo: Integer;
begin
  sSufijo := '_' + AConfig.PrefijoLineas;
  sPrecio := 'PRECIO_VENTA_SIVA_ARTICULO';
  if AConfig.Sentido = sdCompra then
    sPrecio := 'PRECIO_COMPRA_SIVA_ARTICULO';
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
  FLineas.SQL.Text :=
    'SELECT LINEA' + sSufijo + ' AS LINEA, CODIGO_ART' + sSufijo +
    ' AS ARTICULO, CODIGO_UNIDAD' + sSufijo + ' AS SKU, ' +
    'DESCRIPCION_ARTICULO' + sSufijo + ' AS DESCRIPCION, ' +
    sVariante + ' AS VARIACION, ' + sTallas + ' AS TALLAS, ' +
    'CANTIDAD' + sSufijo + ' AS CANTIDAD, ' + sPrecio + sSufijo +
    ' AS PRECIO, PORCENTAJE_IVA' + sSufijo + ' AS IVA, ' +
    'ROUND(CANTIDAD' + sSufijo + ' * ' + sPrecio + sSufijo +
    ', 2) AS TOTAL FROM ' + AConfig.TablaLineas + ' L' +
    ' WHERE ' + AConfig.CampoSerieLinea + ' = :SERIE AND ' +
    AConfig.CampoNumeroLinea + ' = :NUMERO ORDER BY LINEA' + sSufijo;
end;

procedure TDatosInformeDocumento.Abrir(AConexion: TUniConnection;
  const AConfig: TConfiguracionDocumento;
  const ASerie, ANumero: string);
begin
  FCabecera.Close;
  FLineas.Close;
  FCabecera.Connection := AConexion;
  FLineas.Connection := AConexion;
  ConfigurarCabecera(AConfig);
  ConfigurarLineas(AConfig);
  FCabecera.ParamByName('SERIE').AsString := ASerie;
  FCabecera.ParamByName('NUMERO').AsString := ANumero;
  FLineas.ParamByName('SERIE').AsString := ASerie;
  FLineas.ParamByName('NUMERO').AsString := ANumero;
  FCabecera.Open;
  if FCabecera.IsEmpty then
    raise Exception.Create(SErrorDocumentoImpresionNoExiste);
  FLineas.Open;
end;

end.
