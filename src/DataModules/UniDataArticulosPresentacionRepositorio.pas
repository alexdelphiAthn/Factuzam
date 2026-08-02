{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataArticulosPresentacionRepositorio                       }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Unica unidad con SQL y transacciones de la pantalla de articulos.         }
{    Implementa los puertos de inLibArticulosPresentacionIntf.                 }
{******************************************************************************}
unit UniDataArticulosPresentacionRepositorio;

interface

uses
  Uni,
  inLibPerfilesUsuarioIntf,
  inLibArticulosPresentacionIntf;

function CrearCatalogoAltaTarifasArticuloUniDAC(
  AConexion: TUniConnection): ICatalogoAltaTarifasArticulo;
function CrearLecturaCodigosBarrasArticuloUniDAC(
  AConexion: TUniConnection): ILecturaCodigosBarrasArticulo;
function CrearListaArticulosPantallaUniDAC(
  AConsulta: TUniQuery): IListaArticulosPantalla;
function CrearEscrituraPrecargaArticulosUniDAC(
  AConexion: TUniConnection;
  const AEscritura: IEscritorPerfilesUsuario): IEscrituraPrecargaArticulos;

implementation

uses
  System.SysUtils;

const
  SQL_LISTAR_SKUS_ARTICULO =
    'SELECT CODIGO_UNIDAD_SKU ' +
    '  FROM fza_articulos_skus ' +
    ' WHERE CODIGO_ART_SKU = :ART ' +
    ' ORDER BY CODIGO_UNIDAD_SKU';
  SQL_LISTAR_TARIFAS_ACTIVAS =
    '  SELECT CODIGO_TAR_ARTTAR ' +
    '    FROM fza_tarifas ' +
    '   WHERE ESACTIVO_ARTTAR = ''S'' ' +
    'ORDER BY ORDEN_TAR';
  SQL_LISTAR_CODIGOS_BARRAS =
    'SELECT cb.CODIGO_BARRAS_CB, cb.CODIGO_UNIDAD_CB, cb.TIPO_CODIGO_CB ' +
    '  FROM fza_codigos_barras cb '                                       +
    '  JOIN fza_articulos_skus sku '                                      +
    '    ON sku.CODIGO_UNIDAD_SKU = cb.CODIGO_UNIDAD_CB '                 +
    ' WHERE sku.CODIGO_ART_SKU = :CODIGO_ART_ART';

type
  TCatalogoAltaTarifasArticuloUniDAC = class(
    TInterfacedObject,
    ICatalogoAltaTarifasArticulo)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarSkus(const ACodigoArticulo: string): TArray<string>;
    function ListarTarifasActivas: TArray<string>;
  end;

  TLecturaCodigosBarrasArticuloUniDAC = class(
    TInterfacedObject,
    ILecturaCodigosBarrasArticulo)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarCodigosBarras(
      const ACodigoArticulo: string): TCodigosBarrasArticulo;
  end;

  TListaArticulosPantallaUniDAC = class(
    TInterfacedObject,
    IListaArticulosPantalla)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConsulta: TUniQuery);
    procedure AplicarSql(const ASql: string);
  end;

  TEscrituraPrecargaArticulosUniDAC = class(
    TInterfacedObject,
    IEscrituraPrecargaArticulos)
  private
    FConexion: TUniConnection;
    FEscritura: IEscritorPerfilesUsuario;
  public
    constructor Create(
      AConexion: TUniConnection;
      const AEscritura: IEscritorPerfilesUsuario);
    procedure GrabarPerfiles(const APerfiles: TPerfilList);
  end;

constructor TCatalogoAltaTarifasArticuloUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TCatalogoAltaTarifasArticuloUniDAC.ListarSkus(
  const ACodigoArticulo: string): TArray<string>;
var
  iFila: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_LISTAR_SKUS_ARTICULO;
    oConsulta.ParamByName('ART').AsString := ACodigoArticulo;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iFila := Length(Result);
      SetLength(Result, iFila + 1);
      Result[iFila] := oConsulta.FieldByName('CODIGO_UNIDAD_SKU').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TCatalogoAltaTarifasArticuloUniDAC.ListarTarifasActivas:
  TArray<string>;
var
  iFila: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_LISTAR_TARIFAS_ACTIVAS;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iFila := Length(Result);
      SetLength(Result, iFila + 1);
      Result[iFila] := oConsulta.FieldByName('CODIGO_TAR_ARTTAR').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

constructor TLecturaCodigosBarrasArticuloUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TLecturaCodigosBarrasArticuloUniDAC.ListarCodigosBarras(
  const ACodigoArticulo: string): TCodigosBarrasArticulo;
var
  iFila: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_LISTAR_CODIGOS_BARRAS;
    oConsulta.ParamByName('CODIGO_ART_ART').AsString := ACodigoArticulo;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iFila := Length(Result);
      SetLength(Result, iFila + 1);
      Result[iFila].Codigo :=
        oConsulta.FieldByName('CODIGO_BARRAS_CB').AsString;
      Result[iFila].Sku :=
        oConsulta.FieldByName('CODIGO_UNIDAD_CB').AsString;
      Result[iFila].Tipo :=
        oConsulta.FieldByName('TIPO_CODIGO_CB').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

constructor TListaArticulosPantallaUniDAC.Create(AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

procedure TListaArticulosPantallaUniDAC.AplicarSql(const ASql: string);
begin
  // La pantalla decide el filtro; el SQL del dataset solo se toca aqui.
  if FConsulta <> nil then
  begin
    FConsulta.Close;
    FConsulta.SQL.Text := ASql;
  end;
end;

constructor TEscrituraPrecargaArticulosUniDAC.Create(
  AConexion: TUniConnection;
  const AEscritura: IEscritorPerfilesUsuario);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  // AEscritura puede llegar sin resolver si el propietario no publica los
  // servicios de perfiles; el fallo se manifiesta al grabar, como antes.
  FConexion := AConexion;
  FEscritura := AEscritura;
end;

procedure TEscrituraPrecargaArticulosUniDAC.GrabarPerfiles(
  const APerfiles: TPerfilList);
begin
  // Unidad de trabajo de la precarga: el upsert de todos los filtros
  // entra o no entra completo.
  FConexion.StartTransaction;
  try
    FEscritura.GrabarPerfiles(APerfiles);
    FConexion.Commit;
  except
    FConexion.Rollback;
    raise;
  end;
end;

function CrearCatalogoAltaTarifasArticuloUniDAC(
  AConexion: TUniConnection): ICatalogoAltaTarifasArticulo;
begin
  Result := TCatalogoAltaTarifasArticuloUniDAC.Create(AConexion);
end;

function CrearLecturaCodigosBarrasArticuloUniDAC(
  AConexion: TUniConnection): ILecturaCodigosBarrasArticulo;
begin
  Result := TLecturaCodigosBarrasArticuloUniDAC.Create(AConexion);
end;

function CrearListaArticulosPantallaUniDAC(
  AConsulta: TUniQuery): IListaArticulosPantalla;
begin
  Result := TListaArticulosPantallaUniDAC.Create(AConsulta);
end;

function CrearEscrituraPrecargaArticulosUniDAC(
  AConexion: TUniConnection;
  const AEscritura: IEscritorPerfilesUsuario): IEscrituraPrecargaArticulos;
begin
  Result := TEscrituraPrecargaArticulosUniDAC.Create(AConexion, AEscritura);
end;

end.
