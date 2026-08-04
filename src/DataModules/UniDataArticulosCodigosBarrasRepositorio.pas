{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataArticulosCodigosBarrasRepositorio                     }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persistencia UniDAC de generación progresiva de códigos de barras.        }
{******************************************************************************}
unit UniDataArticulosCodigosBarrasRepositorio;

interface

uses
  Uni,
  inLibArticulosCodigosBarrasPersistenciaIntf;

function CrearArticulosCodigosBarrasPersistenciaUniDAC(
  AConexion: TUniConnection): IArticulosCodigosBarrasPersistencia;

implementation

uses
  System.SysUtils,
  UniDataValoresAutomaticosRepositorio;

type
  TArticulosCodigosBarrasPersistenciaUniDAC = class(
    TInterfacedObject,
    IArticulosCodigosBarrasPersistencia)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
  public
    constructor Create(AConexion: TUniConnection);
    function EnTransaccion: Boolean;
    procedure IniciarTransaccion;
    procedure ConfirmarTransaccion;
    procedure RevertirTransaccion;
    function EliminarMarcadoresAntiguos(
      const ACodigoArticulo: string): Integer;
    function ConsultarSkusActivos(
      const ACodigoArticulo: string): TArray<TEstadoCodigoBarrasSku>;
    function ObtenerSiguienteContador(
      const ATipo, AUsuario: string): string;
    procedure InsertarCodigoPrincipal(const ACodigoSku,
      ACodigoBarras, ATipo, AUsuario: string);
    procedure InsertarFilaFabricante(
      const ACodigoSku, ATipo, AUsuario: string);
  end;

constructor TArticulosCodigosBarrasPersistenciaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TArticulosCodigosBarrasPersistenciaUniDAC.NuevaConsulta:
  TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TArticulosCodigosBarrasPersistenciaUniDAC.EnTransaccion:
  Boolean;
begin
  Result := FConexion.InTransaction;
end;

procedure TArticulosCodigosBarrasPersistenciaUniDAC.IniciarTransaccion;
begin
  FConexion.StartTransaction;
end;

procedure TArticulosCodigosBarrasPersistenciaUniDAC.ConfirmarTransaccion;
begin
  FConexion.Commit;
end;

procedure TArticulosCodigosBarrasPersistenciaUniDAC.RevertirTransaccion;
begin
  FConexion.Rollback;
end;

function TArticulosCodigosBarrasPersistenciaUniDAC.
  EliminarMarcadoresAntiguos(const ACodigoArticulo: string): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'DELETE CB FROM fza_codigos_barras CB ' +
      '  JOIN fza_articulos_skus SKU ' +
      '    ON SKU.CODIGO_UNIDAD_SKU = CB.CODIGO_UNIDAD_CB ' +
      ' WHERE SKU.CODIGO_ART_SKU = :art ' +
      '   AND LEFT(CB.CODIGO_BARRAS_CB, 5) = ''_FAB_''';
    oConsulta.ParamByName('art').AsString := ACodigoArticulo;
    oConsulta.ExecSQL;
    Result := oConsulta.RowsAffected;
  finally
    oConsulta.Free;
  end;
end;

function TArticulosCodigosBarrasPersistenciaUniDAC.ConsultarSkusActivos(
  const ACodigoArticulo: string): TArray<TEstadoCodigoBarrasSku>;
var
  iIndice: Integer;
  oConsulta: TUniQuery;
begin
  Result := nil;
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT SKU.CODIGO_UNIDAD_SKU, ' +
      '       (SELECT COUNT(*) FROM fza_codigos_barras P ' +
      '         WHERE P.CODIGO_UNIDAD_CB = SKU.CODIGO_UNIDAD_SKU ' +
      '           AND P.ESPRINCIPAL_CB = ''S'') AS NUM_PRIN, ' +
      '       (SELECT COUNT(*) FROM fza_codigos_barras V ' +
      '         WHERE V.CODIGO_UNIDAD_CB = SKU.CODIGO_UNIDAD_SKU ' +
      '           AND COALESCE(V.CODIGO_BARRAS_CB, '''') = '''') ' +
      '         AS NUM_EMPTY ' +
      '  FROM fza_articulos_skus SKU ' +
      ' WHERE SKU.CODIGO_ART_SKU = :art ' +
      '   AND SKU.ESACTIVO_SKU = ''S''';
    oConsulta.ParamByName('art').AsString := ACodigoArticulo;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iIndice := Length(Result);
      SetLength(Result, iIndice + 1);
      Result[iIndice].CodigoSku :=
        oConsulta.FieldByName('CODIGO_UNIDAD_SKU').AsString;
      Result[iIndice].TienePrincipal :=
        oConsulta.FieldByName('NUM_PRIN').AsInteger > 0;
      Result[iIndice].TieneFilaFabricante :=
        oConsulta.FieldByName('NUM_EMPTY').AsInteger > 0;
      oConsulta.Next;
    end;
  finally
    oConsulta.Free;
  end;
end;

function TArticulosCodigosBarrasPersistenciaUniDAC.
  ObtenerSiguienteContador(const ATipo, AUsuario: string): string;
begin
  Result := UniDataValoresAutomaticosRepositorio.ObtenerSiguienteContador(
    FConexion, ATipo, AUsuario);
end;

procedure TArticulosCodigosBarrasPersistenciaUniDAC.InsertarCodigoPrincipal(
  const ACodigoSku, ACodigoBarras, ATipo, AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'INSERT INTO fza_codigos_barras ' +
      '  (CODIGO_BARRAS_CB, CODIGO_UNIDAD_CB, TIPO_CODIGO_CB, ' +
      '   ESPRINCIPAL_CB, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   USUARIO_MODIF) ' +
      'VALUES (:codigo, :sku, :tipo, ''S'', ' +
      '        CURRENT_TIMESTAMP, :usuario, :usuario)';
    oConsulta.ParamByName('codigo').AsString := ACodigoBarras;
    oConsulta.ParamByName('sku').AsString := ACodigoSku;
    oConsulta.ParamByName('tipo').AsString := ATipo;
    oConsulta.ParamByName('usuario').AsString := AUsuario;
    oConsulta.ExecSQL;
  finally
    oConsulta.Free;
  end;
end;

procedure TArticulosCodigosBarrasPersistenciaUniDAC.InsertarFilaFabricante(
  const ACodigoSku, ATipo, AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'INSERT INTO fza_codigos_barras ' +
      '  (CODIGO_BARRAS_CB, CODIGO_UNIDAD_CB, TIPO_CODIGO_CB, ' +
      '   ESPRINCIPAL_CB, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   USUARIO_MODIF) ' +
      'VALUES ('''', :sku, :tipo, ''N'', ' +
      '        CURRENT_TIMESTAMP, :usuario, :usuario)';
    oConsulta.ParamByName('sku').AsString := ACodigoSku;
    oConsulta.ParamByName('tipo').AsString := ATipo;
    oConsulta.ParamByName('usuario').AsString := AUsuario;
    oConsulta.ExecSQL;
  finally
    oConsulta.Free;
  end;
end;

function CrearArticulosCodigosBarrasPersistenciaUniDAC(
  AConexion: TUniConnection): IArticulosCodigosBarrasPersistencia;
begin
  Result := TArticulosCodigosBarrasPersistenciaUniDAC.Create(AConexion);
end;

end.
