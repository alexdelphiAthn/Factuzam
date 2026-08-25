{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPivoteVenta                                            }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC de los puertos del pivote de venta (fascículo V2         }
{    del anexo SRP): SKU y atributos, conjuntos de tallas, alta                }
{    idempotente de SKU y buscador de artículos. Concentra el SQL que          }
{    antes vivía en inLibGridPivoteVenta; no decide bandas, grupos ni          }
{    reglas del pivote.                                                        }
{******************************************************************************}
unit UniDataPivoteVenta;

interface

uses
  Uni,
  inLibPivoteVentaComposicionIntf, inLibPivoteVentaIntf, inLibGenBusq;
// Composición del adaptador para los formularios consumidores.
function CrearRepositorioPivoteVenta(AConexion: TUniConnection;
                                     const AUsuario: string;
                                     const ABusquedaVisual: IBusquedaVisual)
                                     : TRepositoriosPivoteVenta;

implementation

uses
  System.SysUtils, Data.DB,
  inLibGridArticulosPersistenciaIntf,
  UniDataGridArticulosRepositorio;

resourcestring
  STituloBusquedaArticulosPivoteVenta = 'Búsqueda de artículos';

type
  TContextoRepositorioPivoteVenta = record
    Usuario: string;
    BusquedaVisual: IBusquedaVisual;
  end;
  TRepositorioPivoteVentaUniDAC = class(TInterfacedObject,
                                        IRepositorioModeloPivoteVenta,
                                        IRepositorioEdicionPivoteVenta)
  private
    FConexion: TUniConnection;
    FContexto: TContextoRepositorioPivoteVenta;
    function CrearConsulta: TUniQuery;
    function ListaIds(const AIds: TArray<Integer>): string;
    function LeerValoresTalla(AConsulta: TUniQuery;
                              const ACampoId, ACampoValor: string)
                              : TValoresTallaPivoteVenta;
  public
    constructor Create(AConexion: TUniConnection;
                       const AUsuario: string;
                       const ABusquedaVisual: IBusquedaVisual);
    function ObtenerInfoSku(const ACodigoSku: string)
                            : TInfoSkuPivoteVenta;
    function ResolverSkuDesdeCodigoBarras(
      const ACodigoBarras: string): string;
    function ResolverSkuUnicoArticulo(
      const ACodigoArticulo: string): string;
    function BuscarConjuntoQueCubre(
      const AIdsTalla: TArray<Integer>): Integer;
    function PosicionesConjunto(AIdAc: Integer)
                                : TValoresTallaPivoteVenta;
    function TallasDeArticulo(const ACodigoArticulo: string)
                              : TValoresTallaPivoteVenta;
    function TallasPorIds(const AIdsTalla: TArray<Integer>)
                          : TValoresTallaPivoteVenta;
    function DescripcionTalla(AIdAvTalla: Integer): string;
    function BuscarSkuActivoPorAtributos(
      const ACodigoArticulo: string;
      ATallaAv, AColorAv: Integer): string;
    procedure CrearSkuConAtributos(const ACodigoSku, ACodigoArticulo,
                                   AVariacionSku: string;
                                   AColorAv, ATallaAv: Integer);
    function ElegirArticuloDesdeBusqueda(const AAlmacenStock: string;
                                         out ACodigoArticulo: string)
                                         : Boolean;
  end;

function CrearRepositorioPivoteVenta(AConexion: TUniConnection;
  const AUsuario: string;
  const ABusquedaVisual: IBusquedaVisual): TRepositoriosPivoteVenta;
var
  Repositorio: TRepositorioPivoteVentaUniDAC;
begin
  Result := Default(TRepositoriosPivoteVenta);
  Repositorio := TRepositorioPivoteVentaUniDAC.Create(
    AConexion, AUsuario, ABusquedaVisual);
  Result.Modelo := Repositorio;
  Result.Edicion := Repositorio;
end;

constructor TRepositorioPivoteVentaUniDAC.Create(
  AConexion: TUniConnection; const AUsuario: string;
  const ABusquedaVisual: IBusquedaVisual);
begin
  inherited Create;
  FConexion := AConexion;
  FContexto.Usuario := AUsuario;
  FContexto.BusquedaVisual := ABusquedaVisual;
end;
function TRepositorioPivoteVentaUniDAC.CrearConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;
// Lista estructural de ids enteros para cláusulas IN. Solo valores
// numéricos generados por código; ningún texto externo.
function TRepositorioPivoteVentaUniDAC.ListaIds(
  const AIds: TArray<Integer>): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to High(AIds) do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + IntToStr(AIds[i]);
  end;
end;
function TRepositorioPivoteVentaUniDAC.LeerValoresTalla(
  AConsulta: TUniQuery; const ACampoId, ACampoValor: string)
  : TValoresTallaPivoteVenta;
var
  i: Integer;
begin
  SetLength(Result, AConsulta.RecordCount);
  i := 0;
  while not AConsulta.Eof do
  begin
    Result[i].IdAv := AConsulta.FieldByName(ACampoId).AsInteger;
    Result[i].Valor := AConsulta.FieldByName(ACampoValor).AsString;
    Inc(i);
    AConsulta.Next;
  end;
end;

function TRepositorioPivoteVentaUniDAC.ObtenerInfoSku(
  const ACodigoSku: string): TInfoSkuPivoteVenta;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TInfoSkuPivoteVenta);
  if (Trim(ACodigoSku) <> '') and (FConexion <> nil) then
  begin
    oConsulta := CrearConsulta;
    try
      oConsulta.SQL.Text :=
        'SELECT COALESCE(AVC.ID_AV, 0) AS COLOR_AV, ' +
        '       COALESCE(NULLIF(AVC.AV, ''''), ATBC.NOMBRE_ATB, ' +
        '                '''') AS COLOR_TXT, ' +
        '       COALESCE(ATBC.CODIGO_ATB, '''') AS COLOR_COD, ' +
        '       COALESCE(T.ID_AV_SA, 0) AS TALLA_AV, ' +
        '       COALESCE(SKU0.CODIGO_VAR_SKU, ''TC'') AS VAR_SKU ' +
        '  FROM fza_articulos_skus SKU0 ' +
        '  LEFT JOIN fza_atributos_sku SAC ' +
        '    ON SAC.CODIGO_UNIDAD_SKU_SA = SKU0.CODIGO_UNIDAD_SKU ' +
        '   AND EXISTS (SELECT 1 FROM fza_atributos_valores AV ' +
        '                WHERE AV.ID_AV = SAC.ID_AV_SA ' +
        '                  AND AV.ID_VA_AV = ''CO'') ' +
        '  LEFT JOIN fza_atributos_valores AVC ' +
        '    ON AVC.ID_AV = SAC.ID_AV_SA ' +
        '   AND AVC.ID_VA_AV = ''CO'' ' +
        '  LEFT JOIN fza_atributos_basicos ATBC ' +
        '    ON ATBC.ID_ATB = AVC.ID_ATB_AV ' +
        '  LEFT JOIN fza_atributos_sku T ' +
        '    ON T.CODIGO_UNIDAD_SKU_SA = SKU0.CODIGO_UNIDAD_SKU ' +
        '   AND EXISTS (SELECT 1 FROM fza_atributos_valores AVT ' +
        '                WHERE AVT.ID_AV = T.ID_AV_SA ' +
        '                  AND AVT.ID_VA_AV = ''TAL'') ' +
        ' WHERE SKU0.CODIGO_UNIDAD_SKU = :sku ' +
        ' LIMIT 1';
      oConsulta.ParamByName('sku').AsString := Trim(ACodigoSku);
      oConsulta.Open;
      if not oConsulta.Eof then
      begin
        Result.Encontrado := True;
        Result.ColorAv :=
          oConsulta.FieldByName('COLOR_AV').AsInteger;
        Result.ColorTexto :=
          oConsulta.FieldByName('COLOR_TXT').AsString;
        Result.ColorCodigo :=
          oConsulta.FieldByName('COLOR_COD').AsString;
        Result.TallaAv :=
          oConsulta.FieldByName('TALLA_AV').AsInteger;
        Result.VarSku :=
          oConsulta.FieldByName('VAR_SKU').AsString;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioPivoteVentaUniDAC.ResolverSkuDesdeCodigoBarras(
  const ACodigoBarras: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  if (Trim(ACodigoBarras) <> '') and (FConexion <> nil) then
  begin
    oConsulta := CrearConsulta;
    try
      oConsulta.SQL.Text :=
        'SELECT CODIGO_UNIDAD_CB ' +
        '  FROM fza_codigos_barras ' +
        ' WHERE CODIGO_BARRAS_CB = :cod ' +
        '   AND COALESCE(CODIGO_UNIDAD_CB, '''') <> '''' ' +
        ' LIMIT 1';
      oConsulta.ParamByName('cod').AsString := Trim(ACodigoBarras);
      oConsulta.Open;
      if not oConsulta.Eof then
        Result := oConsulta.FieldByName('CODIGO_UNIDAD_CB').AsString;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioPivoteVentaUniDAC.ResolverSkuUnicoArticulo(
  const ACodigoArticulo: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  if (Trim(ACodigoArticulo) <> '') and (FConexion <> nil) then
  begin
    oConsulta := CrearConsulta;
    try
      oConsulta.SQL.Text :=
        'SELECT MIN(CODIGO_UNIDAD_SKU) AS SKU, COUNT(*) AS N ' +
        '  FROM fza_articulos_skus ' +
        ' WHERE CODIGO_ART_SKU = :art ' +
        '   AND COALESCE(ESACTIVO_SKU, ''S'') = ''S''';
      oConsulta.ParamByName('art').AsString := Trim(ACodigoArticulo);
      oConsulta.Open;
      if (not oConsulta.Eof) and
         (oConsulta.FieldByName('N').AsInteger = 1) then
        Result := oConsulta.FieldByName('SKU').AsString;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioPivoteVentaUniDAC.BuscarConjuntoQueCubre(
  const AIdsTalla: TArray<Integer>): Integer;
var
  oConsulta: TUniQuery;
  sIds: string;
begin
  Result := 0;
  sIds := ListaIds(AIdsTalla);
  if (sIds <> '') and (FConexion <> nil) then
  begin
    oConsulta := CrearConsulta;
    try
      oConsulta.SQL.Text :=
        'SELECT d.ID_AC_ACD AS ID_AC ' +
        '  FROM fza_atributos_conjuntos_det d ' +
        ' WHERE d.ID_AV_ACD IN (' + sIds + ') ' +
        ' GROUP BY d.ID_AC_ACD ' +
        ' HAVING COUNT(DISTINCT d.ID_AV_ACD) = ' +
          IntToStr(Length(AIdsTalla)) +
        ' ORDER BY (SELECT COUNT(*) ' +
        '             FROM fza_atributos_conjuntos_det t ' +
        '            WHERE t.ID_AC_ACD = d.ID_AC_ACD) ' +
        ' LIMIT 1';
      oConsulta.Open;
      if not oConsulta.Eof then
        Result := oConsulta.FieldByName('ID_AC').AsInteger;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioPivoteVentaUniDAC.PosicionesConjunto(
  AIdAc: Integer): TValoresTallaPivoteVenta;
var
  oConsulta: TUniQuery;
begin
  Result := nil;
  if (AIdAc > 0) and (FConexion <> nil) then
  begin
    oConsulta := CrearConsulta;
    try
      oConsulta.SQL.Text :=
        'SELECT ACD.ID_AV_ACD, AV.AV AS VALOR ' +
        '  FROM fza_atributos_conjuntos_det ACD ' +
        '  JOIN fza_atributos_valores AV ' +
        '    ON AV.ID_AV = ACD.ID_AV_ACD ' +
        ' WHERE ACD.ID_AC_ACD = :ac ' +
        ' ORDER BY ACD.ORDEN_ACD, AV.AV';
      oConsulta.ParamByName('ac').AsInteger := AIdAc;
      oConsulta.Open;
      Result := LeerValoresTalla(oConsulta, 'ID_AV_ACD', 'VALOR');
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioPivoteVentaUniDAC.TallasDeArticulo(
  const ACodigoArticulo: string): TValoresTallaPivoteVenta;
var
  oConsulta: TUniQuery;
begin
  Result := nil;
  if (Trim(ACodigoArticulo) <> '') and (FConexion <> nil) then
  begin
    oConsulta := CrearConsulta;
    try
      oConsulta.SQL.Text :=
        'SELECT DISTINCT AV.ID_AV, AV.AV, AV.ORDEN_AV ' +
        '  FROM fza_articulos_skus SK ' +
        '  JOIN fza_atributos_sku SA ' +
        '    ON SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
        '  JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
        ' WHERE SK.CODIGO_ART_SKU = :art ' +
        '   AND AV.ID_VA_AV = ''TAL'' ' +
        ' ORDER BY AV.ORDEN_AV, AV.AV';
      oConsulta.ParamByName('art').AsString := Trim(ACodigoArticulo);
      oConsulta.Open;
      Result := LeerValoresTalla(oConsulta, 'ID_AV', 'AV');
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioPivoteVentaUniDAC.TallasPorIds(
  const AIdsTalla: TArray<Integer>): TValoresTallaPivoteVenta;
var
  oConsulta: TUniQuery;
  sIds: string;
begin
  Result := nil;
  sIds := ListaIds(AIdsTalla);
  if (sIds <> '') and (FConexion <> nil) then
  begin
    oConsulta := CrearConsulta;
    try
      oConsulta.SQL.Text :=
        'SELECT ID_AV, AV, ORDEN_AV ' +
        '  FROM fza_atributos_valores ' +
        ' WHERE ID_AV IN (' + sIds + ') ' +
        ' ORDER BY ORDEN_AV, AV';
      oConsulta.Open;
      Result := LeerValoresTalla(oConsulta, 'ID_AV', 'AV');
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioPivoteVentaUniDAC.DescripcionTalla(
  AIdAvTalla: Integer): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  if (AIdAvTalla > 0) and (FConexion <> nil) then
  begin
    oConsulta := CrearConsulta;
    try
      oConsulta.SQL.Text :=
        'SELECT AV FROM fza_atributos_valores ' +
        ' WHERE ID_AV = :talla LIMIT 1';
      oConsulta.ParamByName('talla').AsInteger := AIdAvTalla;
      oConsulta.Open;
      if not oConsulta.Eof then
        Result := oConsulta.FieldByName('AV').AsString;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioPivoteVentaUniDAC.BuscarSkuActivoPorAtributos(
  const ACodigoArticulo: string; ATallaAv, AColorAv: Integer): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  if (Trim(ACodigoArticulo) <> '') and (ATallaAv > 0) and
     (FConexion <> nil) then
  begin
    oConsulta := CrearConsulta;
    try
      oConsulta.SQL.Text :=
        'SELECT sk.CODIGO_UNIDAD_SKU ' +
        '  FROM fza_articulos_skus sk ' +
        ' WHERE sk.CODIGO_ART_SKU = :art ' +
        '   AND sk.ESACTIVO_SKU = ''S'' ' +
        '   AND EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
        '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
        '                      sk.CODIGO_UNIDAD_SKU ' +
        '                  AND sa.ID_AV_SA = :talla) ';
      if AColorAv > 0 then
        oConsulta.SQL.Text := oConsulta.SQL.Text +
          '   AND EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
          '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
          '                      sk.CODIGO_UNIDAD_SKU ' +
          '                  AND sa.ID_AV_SA = :color) ';
      oConsulta.SQL.Text := oConsulta.SQL.Text + ' LIMIT 1';
      oConsulta.ParamByName('art').AsString := Trim(ACodigoArticulo);
      oConsulta.ParamByName('talla').AsInteger := ATallaAv;
      if AColorAv > 0 then
        oConsulta.ParamByName('color').AsInteger := AColorAv;
      oConsulta.Open;
      if not oConsulta.Eof then
        Result := oConsulta.FieldByName('CODIGO_UNIDAD_SKU').AsString;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TRepositorioPivoteVentaUniDAC.CrearSkuConAtributos(
  const ACodigoSku, ACodigoArticulo, AVariacionSku: string;
  AColorAv, ATallaAv: Integer);
var
  oConsulta: TUniQuery;
begin
  if (Trim(ACodigoSku) <> '') and (FConexion <> nil) then
  begin
    oConsulta := CrearConsulta;
    try
      oConsulta.SQL.Text :=
        'INSERT IGNORE INTO fza_articulos_skus ' +
        '  (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
        '   ESACTIVO_SKU, INSTANTE_ALTA, USUARIO_ALTA, ' +
        '   INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:sku, :art, :varsku, ''S'', NOW(), :u, NOW(), :u)';
      oConsulta.ParamByName('sku').AsString := ACodigoSku;
      oConsulta.ParamByName('art').AsString := ACodigoArticulo;
      oConsulta.ParamByName('varsku').AsString := AVariacionSku;
      oConsulta.ParamByName('u').AsString := FContexto.Usuario;
      oConsulta.ExecSQL;
      if AColorAv > 0 then
      begin
        oConsulta.SQL.Text :=
          'INSERT IGNORE INTO fza_atributos_sku ' +
          '  (CODIGO_UNIDAD_SKU_SA, ID_AV_SA, INSTANTE_ALTA, ' +
          '   USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
          'VALUES (:sku, :av, NOW(), :u, NOW(), :u)';
        oConsulta.ParamByName('sku').AsString := ACodigoSku;
        oConsulta.ParamByName('av').AsInteger := AColorAv;
        oConsulta.ParamByName('u').AsString := FContexto.Usuario;
        oConsulta.ExecSQL;
      end;
      if ATallaAv > 0 then
      begin
        oConsulta.SQL.Text :=
          'INSERT IGNORE INTO fza_atributos_sku ' +
          '  (CODIGO_UNIDAD_SKU_SA, ID_AV_SA, INSTANTE_ALTA, ' +
          '   USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
          'VALUES (:sku, :av, NOW(), :u, NOW(), :u)';
        oConsulta.ParamByName('sku').AsString := ACodigoSku;
        oConsulta.ParamByName('av').AsInteger := ATallaAv;
        oConsulta.ParamByName('u').AsString := FContexto.Usuario;
        oConsulta.ExecSQL;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioPivoteVentaUniDAC.ElegirArticuloDesdeBusqueda(
  const AAlmacenStock: string; out ACodigoArticulo: string): Boolean;
var
  oConsulta: IConsultaArticulosGrid;
  oDataSet: TDataSet;
begin
  Result := False;
  ACodigoArticulo := '';
  if FConexion <> nil then
  begin
    oConsulta := CrearConsultaArticulosGridUniDAC(FConexion);
    oConsulta.Aplicar(AAlmacenStock);
    oDataSet := oConsulta.DataSet;
    if FContexto.BusquedaVisual.EjecutarBusquedaDataSet(
         STituloBusquedaArticulosPivoteVenta, oDataSet,
         'frmMtoArtTraspasoSearch') then
    begin
      ACodigoArticulo := oDataSet.FieldByName('ARTICULO').AsString;
      Result := ACodigoArticulo <> '';
    end;
  end;
end;

end.
