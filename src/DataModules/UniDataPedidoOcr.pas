{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidoOcr                                              }
{    Tipo:       Persistencia                                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       08/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Catálogo UniDAC para resolver el primer sistema activo que contiene       }
{    todas las tallas y recuperar colores básicos del histórico del proveedor. }
{******************************************************************************}
unit UniDataPedidoOcr;

interface

uses
  System.Generics.Collections,
  Uni,
  inLibPedidoOcr;

type
  TValorTallaPedidoOcr = record
    IdAv: Integer;
    Valor: string;
  end;
  TValoresTallaPedidoOcr = TArray<TValorTallaPedidoOcr>;
  TResolucionTallasPedidoOcr = record
    Encontrada: Boolean;
    IdAc: Integer;
    NombreSistema: string;
    IdsAv: TArray<Integer>;
  end;
  TSistemaTallasPedidoOcr = class
  public
    IdAc: Integer;
    Nombre: string;
    Valores: TValoresTallaPedidoOcr;
  end;
  TCatalogoTallasPedidoOcr = class
  private
    FSistemas: TObjectList<TSistemaTallasPedidoOcr>;
    FMaximoPosiciones: Integer;
    procedure Cargar(AConexion: TUniConnection);
    function BuscarValor(ASistema: TSistemaTallasPedidoOcr;
      const ATalla: string): Integer;
  public
    constructor Create(AConexion: TUniConnection;
      AMaximoPosiciones: Integer);
    destructor Destroy; override;
    function Resolver(
      const ATallas: TTallasPedidoOcr): TResolucionTallasPedidoOcr;
  end;
  // Reutiliza primero la última clasificación de una sesión y después la
  // clasificación más repetida entre los artículos del proveedor.
  THistoricoColoresPedidoOcr = class
  private
    class function ConsultarCodigo(
      AConexion: TUniConnection;
      const ASql, ACodigoProveedor,
      AColorProveedor: string): string; static;
  public
    class function Resolver(
      AConexion: TUniConnection;
      const ACodigoProveedor,
      AColorProveedor: string;
      out ACodigoColorBasico: string): Boolean; static;
  end;

implementation

uses
  Data.DB,
  System.SysUtils,
  inLibComprasSesionesReglas;

const
  SQL_COLOR_HISTORICO_SESIONES =
    'SELECT L.CODIGO_ATB_COLOR_SESLIN AS CODIGO_COLOR' +
    '  FROM fza_compras_sesiones_lineas L' +
    '  JOIN fza_compras_sesiones S' +
    '    ON S.SERIE_SES = L.SERIE_SES_SESLIN' +
    '   AND S.NUMERO_SES = L.NUMERO_SES_SESLIN' +
    '  JOIN fza_atributos_basicos B' +
    '    ON B.ID_VA_ATB = ''CO''' +
    '   AND B.CODIGO_ATB = L.CODIGO_ATB_COLOR_SESLIN' +
    '   AND B.ESACTIVO_ATB = ''S''' +
    ' WHERE S.CODIGO_PRV_SES = :proveedor' +
    '   AND UPPER(TRIM(L.COLOR_TEXTO_SESLIN)) = :color' +
    ' ORDER BY COALESCE(S.INSTANTE_MODIF, S.INSTANTE_ALTA) DESC,' +
    '          S.FECHA_SES DESC, L.LINEA_SESLIN DESC' +
    ' LIMIT 1';
  SQL_COLOR_HISTORICO_ARTICULOS =
    'SELECT B.CODIGO_ATB AS CODIGO_COLOR' +
    '  FROM fza_articulos_proveedores AP' +
    '  JOIN fza_articulos_skus SKU' +
    '    ON SKU.CODIGO_ART_SKU = AP.CODIGO_ART_AP' +
    '  JOIN fza_atributos_sku SA' +
    '    ON SA.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU' +
    '  JOIN fza_atributos_valores AV' +
    '    ON AV.ID_AV = SA.ID_AV_SA' +
    '   AND AV.ID_VA_AV = ''CO''' +
    '  JOIN fza_articulos_atributos_basicos AAB' +
    '    ON AAB.CODIGO_ART_AAB = SKU.CODIGO_ART_SKU' +
    '   AND AAB.ID_AV_AAB = AV.ID_AV' +
    '  JOIN fza_atributos_basicos B' +
    '    ON B.ID_ATB = AAB.ID_ATB_AAB' +
    '   AND B.ID_VA_ATB = ''CO''' +
    '   AND B.ESACTIVO_ATB = ''S''' +
    ' WHERE AP.CODIGO_PRV_AP = :proveedor' +
    '   AND UPPER(TRIM(AV.AV)) = :color' +
    ' GROUP BY B.CODIGO_ATB' +
    ' ORDER BY COUNT(DISTINCT AP.CODIGO_ART_AP) DESC,' +
    '          B.CODIGO_ATB' +
    ' LIMIT 1';

class function THistoricoColoresPedidoOcr.ConsultarCodigo(
  AConexion: TUniConnection;
  const ASql, ACodigoProveedor,
  AColorProveedor: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('proveedor').AsString := ACodigoProveedor;
    oConsulta.ParamByName('color').AsString := AColorProveedor;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      Result := Trim(
        oConsulta.FieldByName('CODIGO_COLOR').AsString);
  finally
    oConsulta.Free;
  end;
end;

class function THistoricoColoresPedidoOcr.Resolver(
  AConexion: TUniConnection;
  const ACodigoProveedor,
  AColorProveedor: string;
  out ACodigoColorBasico: string): Boolean;
var
  sColorNormalizado: string;
begin
  ACodigoColorBasico := '';
  sColorNormalizado := UpperCase(
    SanearColorSku(AColorProveedor));
  if Assigned(AConexion) and
     (Trim(ACodigoProveedor) <> '') and
     (sColorNormalizado <> '') then
  begin
    ACodigoColorBasico := ConsultarCodigo(
      AConexion,
      SQL_COLOR_HISTORICO_SESIONES,
      ACodigoProveedor,
      sColorNormalizado);
    if ACodigoColorBasico = '' then
      ACodigoColorBasico := ConsultarCodigo(
        AConexion,
        SQL_COLOR_HISTORICO_ARTICULOS,
        ACodigoProveedor,
        sColorNormalizado);
  end;
  Result := ACodigoColorBasico <> '';
end;

constructor TCatalogoTallasPedidoOcr.Create(
  AConexion: TUniConnection;
  AMaximoPosiciones: Integer);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FMaximoPosiciones := AMaximoPosiciones;
  FSistemas := TObjectList<TSistemaTallasPedidoOcr>.Create(True);
  Cargar(AConexion);
end;

destructor TCatalogoTallasPedidoOcr.Destroy;
begin
  FSistemas.Free;
  inherited Destroy;
end;

procedure TCatalogoTallasPedidoOcr.Cargar(AConexion: TUniConnection);
var
  iValor: Integer;
  oActual: TSistemaTallasPedidoOcr;
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT AC.ID_AC, AC.NOMBRE_AC, ACD.ID_AV_ACD, AV.AV' +
      '  FROM fza_atributos_conjuntos AC' +
      '  JOIN fza_atributos_conjuntos_det ACD' +
      '    ON ACD.ID_AC_ACD = AC.ID_AC' +
      '  JOIN fza_atributos_valores AV' +
      '    ON AV.ID_AV = ACD.ID_AV_ACD' +
      ' WHERE AC.ESACTIVO_AC = ''S''' +
      '   AND AC.ID_VA_AC = ''TAL''' +
      ' ORDER BY AC.NOMBRE_AC, AC.ID_AC,' +
      '          ACD.ORDEN_ACD, AV.AV';
    oConsulta.Open;
    oActual := nil;
    while not oConsulta.Eof do
    begin
      if (oActual = nil) or
         (oActual.IdAc <> oConsulta.FieldByName('ID_AC').AsInteger) then
      begin
        oActual := TSistemaTallasPedidoOcr.Create;
        oActual.IdAc := oConsulta.FieldByName('ID_AC').AsInteger;
        oActual.Nombre := oConsulta.FieldByName('NOMBRE_AC').AsString;
        FSistemas.Add(oActual);
      end;
      iValor := Length(oActual.Valores);
      SetLength(oActual.Valores, iValor + 1);
      oActual.Valores[iValor].IdAv :=
        oConsulta.FieldByName('ID_AV_ACD').AsInteger;
      oActual.Valores[iValor].Valor :=
        oConsulta.FieldByName('AV').AsString;
      oConsulta.Next;
    end;
  finally
    oConsulta.Free;
  end;
end;

function TCatalogoTallasPedidoOcr.BuscarValor(
  ASistema: TSistemaTallasPedidoOcr;
  const ATalla: string): Integer;
var
  bEncontrada: Boolean;
  iValor: Integer;
  sTalla: string;
begin
  Result := 0;
  bEncontrada := False;
  iValor := 0;
  sTalla := NormalizarTallaPedido(ATalla);
  while (iValor <= High(ASistema.Valores)) and (not bEncontrada) do
  begin
    if NormalizarTallaPedido(ASistema.Valores[iValor].Valor) = sTalla then
    begin
      Result := ASistema.Valores[iValor].IdAv;
      bEncontrada := True;
    end;
    Inc(iValor);
  end;
end;

function TCatalogoTallasPedidoOcr.Resolver(
  const ATallas: TTallasPedidoOcr): TResolucionTallasPedidoOcr;
var
  bCubre: Boolean;
  iSistema: Integer;
  iTalla: Integer;
begin
  Result := Default(TResolucionTallasPedidoOcr);
  iSistema := 0;
  while (iSistema < FSistemas.Count) and (not Result.Encontrada) do
  begin
    bCubre := (Length(FSistemas[iSistema].Valores) <=
               FMaximoPosiciones) and (Length(ATallas) > 0);
    SetLength(Result.IdsAv, Length(ATallas));
    iTalla := 0;
    while (iTalla <= High(ATallas)) and bCubre do
    begin
      Result.IdsAv[iTalla] := BuscarValor(
        FSistemas[iSistema],
        ATallas[iTalla].Talla);
      bCubre := Result.IdsAv[iTalla] > 0;
      Inc(iTalla);
    end;
    if bCubre then
    begin
      Result.Encontrada := True;
      Result.IdAc := FSistemas[iSistema].IdAc;
      Result.NombreSistema := FSistemas[iSistema].Nombre;
    end;
    Inc(iSistema);
  end;
  if not Result.Encontrada then
    Result.IdsAv := nil;
end;

end.
