{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFotosRepositorio                                       }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Implementación UniDAC de la persistencia del subsistema de fotos.         }
{******************************************************************************}
unit UniDataFotosRepositorio;

interface

uses
  Uni, inLibFotosPersistenciaIntf;

function CrearRepositorioFotosUniDAC(
  AConexion: TUniConnection): TRepositoriosFotos;

implementation
uses
  System.SysUtils, Data.DB;
type
  TRepositorioFotosUniDAC = class(
    TInterfacedObject,
    IRepositorioConsultaFotos,
    IRepositorioEdicionFotos,
    IRepositorioSesionFotos)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
  public
    constructor Create(AConexion: TUniConnection);
    function BuscarFotoPorUnidades(
      const ACodigoArticulo: string;
      const AUnidades: TArray<string>): TDataSet;
    function BuscarFotoArticulo(
      const ACodigoArticulo: string): TDataSet;
    function BuscarPrimeraFotoUnidad(
      const ACodigoArticulo: string): TDataSet;
    function BuscarFotosArticulos(
      const ACodigosArticulo: TArray<string>): TDataSet;
    function BuscarFotoEditable(
      const ACodigoArticulo, ACodigoUnidad: string): TDataSet;
    procedure ActualizarNombreFoto(
      const ACodigoArticulo, ACodigoUnidad, ANombre, AUsuario: string);
    function BuscarNombreFoto(
      const ACodigoArticulo, ACodigoUnidad: string): string;
    procedure EliminarFoto(
      const ACodigoArticulo, ACodigoUnidad: string);
    function BuscarFotoSesion(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer;
      const ACodigoUnidad: string): TDataSet;
    procedure GuardarFotoSesion(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer;
      const ACodigoUnidad, ACodigoArticuloTentativo, ANombre,
        AExtension, AUsuario: string);
    procedure EliminarFotoSesion(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer;
      const ACodigoUnidad: string);
    function BuscarFotosSesionLinea(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer): TDataSet;
    procedure GuardarFotoMigrada(
      const ACodigoArticulo, ACodigoUnidad, ANombre, AExtension,
        AUsuario: string);
    procedure EliminarFotosSesionLinea(
      const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer);
  end;
constructor TRepositorioFotosUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;
function TRepositorioFotosUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;
function TRepositorioFotosUniDAC.BuscarFotoPorUnidades(
  const ACodigoArticulo: string;
  const AUnidades: TArray<string>): TDataSet;
var
  Consulta: TUniQuery;
  i: Integer;
  sParametros: string;
begin
  Consulta := NuevaConsulta;
  try
    sParametros := '';
    for i := 0 to High(AUnidades) do
    begin
      if sParametros <> '' then
        sParametros := sParametros + ', ';
      sParametros := sParametros + ':P' + IntToStr(i);
    end;
    Consulta.SQL.Text :=
      ' SELECT * FROM fza_articulos_fotos ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT IN (' + sParametros + ') ' +
      '  ORDER BY LENGTH(CODIGO_UNIDAD_FOT) DESC ' +
      '  LIMIT 1';
    Consulta.ParamByName('CODIGO_ART').AsString := ACodigoArticulo;
    for i := 0 to High(AUnidades) do
      Consulta.ParamByName('P' + IntToStr(i)).AsString := AUnidades[i];
    Consulta.Open;
    Result := Consulta;
    Consulta := nil;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioFotosUniDAC.BuscarFotoArticulo(
  const ACodigoArticulo: string): TDataSet;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      ' SELECT * FROM fza_articulos_fotos ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = '''' ' +
      '  LIMIT 1';
    Consulta.ParamByName('CODIGO_ART').AsString := ACodigoArticulo;
    Consulta.Open;
    Result := Consulta;
    Consulta := nil;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioFotosUniDAC.BuscarPrimeraFotoUnidad(
  const ACodigoArticulo: string): TDataSet;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      ' SELECT * FROM fza_articulos_fotos ' +
      '  WHERE CODIGO_ART_FOT = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT <> '''' ' +
      '  ORDER BY CODIGO_UNIDAD_FOT, NOMBRE_FOT_FOT ' +
      '  LIMIT 1';
    Consulta.ParamByName('CODIGO_ART').AsString := ACodigoArticulo;
    Consulta.Open;
    Result := Consulta;
    Consulta := nil;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioFotosUniDAC.BuscarFotosArticulos(
  const ACodigosArticulo: TArray<string>): TDataSet;
var
  Consulta: TUniQuery;
  i: Integer;
  sParametros: string;
begin
  Consulta := NuevaConsulta;
  try
    sParametros := '';
    for i := 0 to High(ACodigosArticulo) do
    begin
      if sParametros <> '' then
        sParametros := sParametros + ', ';
      sParametros := sParametros + ':A' + IntToStr(i);
    end;
    Consulta.SQL.Text :=
      ' SELECT CODIGO_ART_FOT, CODIGO_UNIDAD_FOT, ' +
      '        NOMBRE_FOT_FOT, EXTENSION_ORIGEN_FOT ' +
      '   FROM fza_articulos_fotos ' +
      '  WHERE CODIGO_ART_FOT IN (' + sParametros + ') ' +
      '  ORDER BY CODIGO_ART_FOT, CODIGO_UNIDAD_FOT, ' +
      '           NOMBRE_FOT_FOT';
    for i := 0 to High(ACodigosArticulo) do
      Consulta.ParamByName('A' + IntToStr(i)).AsString :=
        ACodigosArticulo[i];
    Consulta.Open;
    Result := Consulta;
    Consulta := nil;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioFotosUniDAC.BuscarFotoEditable(
  const ACodigoArticulo, ACodigoUnidad: string): TDataSet;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      ' SELECT * FROM fza_articulos_fotos ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_SKU';
    Consulta.ParamByName('CODIGO_ART').AsString := ACodigoArticulo;
    Consulta.ParamByName('CODIGO_SKU').AsString := ACodigoUnidad;
    Consulta.Open;
    Result := Consulta;
    Consulta := nil;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TRepositorioFotosUniDAC.ActualizarNombreFoto(
  const ACodigoArticulo, ACodigoUnidad, ANombre, AUsuario: string);
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      ' UPDATE fza_articulos_fotos ' +
      '    SET NOMBRE_FOT_FOT   = :NOMBRE, ' +
      '        USUARIO_MODIF    = :USUARIO ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD';
    Consulta.ParamByName('NOMBRE').AsString := ANombre;
    Consulta.ParamByName('USUARIO').AsString := AUsuario;
    Consulta.ParamByName('CODIGO_ART').AsString := ACodigoArticulo;
    Consulta.ParamByName('CODIGO_UNIDAD').AsString := ACodigoUnidad;
    Consulta.Execute;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioFotosUniDAC.BuscarNombreFoto(
  const ACodigoArticulo, ACodigoUnidad: string): string;
var
  Consulta: TUniQuery;
begin
  Result := '';
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      ' SELECT NOMBRE_FOT_FOT ' +
      '   FROM fza_articulos_fotos ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD';
    Consulta.ParamByName('CODIGO_ART').AsString := ACodigoArticulo;
    Consulta.ParamByName('CODIGO_UNIDAD').AsString := ACodigoUnidad;
    Consulta.Open;
    if not Consulta.Eof then
      Result := Consulta.FieldByName('NOMBRE_FOT_FOT').AsString;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TRepositorioFotosUniDAC.EliminarFoto(
  const ACodigoArticulo, ACodigoUnidad: string);
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      ' DELETE FROM fza_articulos_fotos ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD';
    Consulta.ParamByName('CODIGO_ART').AsString := ACodigoArticulo;
    Consulta.ParamByName('CODIGO_UNIDAD').AsString := ACodigoUnidad;
    Consulta.Execute;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioFotosUniDAC.BuscarFotoSesion(
  const ASerieSesion, ANumeroSesion: string;
  ALinea: Integer;
  const ACodigoUnidad: string): TDataSet;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT * FROM fza_compras_sesiones_fotos ' +
      ' WHERE SERIE_SES_CSF     = :s ' +
      '   AND NUMERO_SES_CSF    = :n ' +
      '   AND LINEA_CSF         = :l ' +
      '   AND CODIGO_UNIDAD_CSF = :u';
    Consulta.ParamByName('s').AsString := ASerieSesion;
    Consulta.ParamByName('n').AsString := ANumeroSesion;
    Consulta.ParamByName('l').AsInteger := ALinea;
    Consulta.ParamByName('u').AsString := ACodigoUnidad;
    Consulta.Open;
    Result := Consulta;
    Consulta := nil;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TRepositorioFotosUniDAC.GuardarFotoSesion(
  const ASerieSesion, ANumeroSesion: string;
  ALinea: Integer;
  const ACodigoUnidad, ACodigoArticuloTentativo, ANombre,
    AExtension, AUsuario: string);
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'INSERT INTO fza_compras_sesiones_fotos ' +
      '  (SERIE_SES_CSF, NUMERO_SES_CSF, LINEA_CSF, ' +
      '   CODIGO_UNIDAD_CSF, CODIGO_ART_TENTATIVO_CSF, ' +
      '   NOMBRE_FOT_CSF, EXTENSION_ORIGEN_CSF, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:s, :n, :l, :u, :a, :nom, :ext, NOW(), :usr, ' +
      '        NOW(), :usr) ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  CODIGO_ART_TENTATIVO_CSF = :a, ' +
      '  NOMBRE_FOT_CSF           = :nom, ' +
      '  EXTENSION_ORIGEN_CSF     = :ext, ' +
      '  INSTANTE_MODIF           = NOW(), ' +
      '  USUARIO_MODIF            = :usr';
    Consulta.ParamByName('s').AsString := ASerieSesion;
    Consulta.ParamByName('n').AsString := ANumeroSesion;
    Consulta.ParamByName('l').AsInteger := ALinea;
    Consulta.ParamByName('u').AsString := ACodigoUnidad;
    Consulta.ParamByName('a').AsString := ACodigoArticuloTentativo;
    Consulta.ParamByName('nom').AsString := ANombre;
    Consulta.ParamByName('ext').AsString := AExtension;
    Consulta.ParamByName('usr').AsString := AUsuario;
    Consulta.ExecSQL;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TRepositorioFotosUniDAC.EliminarFotoSesion(
  const ASerieSesion, ANumeroSesion: string;
  ALinea: Integer;
  const ACodigoUnidad: string);
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'DELETE FROM fza_compras_sesiones_fotos ' +
      ' WHERE SERIE_SES_CSF     = :s ' +
      '   AND NUMERO_SES_CSF    = :n ' +
      '   AND LINEA_CSF         = :l ' +
      '   AND CODIGO_UNIDAD_CSF = :u';
    Consulta.ParamByName('s').AsString := ASerieSesion;
    Consulta.ParamByName('n').AsString := ANumeroSesion;
    Consulta.ParamByName('l').AsInteger := ALinea;
    Consulta.ParamByName('u').AsString := ACodigoUnidad;
    Consulta.ExecSQL;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioFotosUniDAC.BuscarFotosSesionLinea(
  const ASerieSesion, ANumeroSesion: string;
  ALinea: Integer): TDataSet;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT * FROM fza_compras_sesiones_fotos ' +
      ' WHERE SERIE_SES_CSF  = :s ' +
      '   AND NUMERO_SES_CSF = :n ' +
      '   AND LINEA_CSF      = :l';
    Consulta.ParamByName('s').AsString := ASerieSesion;
    Consulta.ParamByName('n').AsString := ANumeroSesion;
    Consulta.ParamByName('l').AsInteger := ALinea;
    Consulta.Open;
    Result := Consulta;
    Consulta := nil;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TRepositorioFotosUniDAC.GuardarFotoMigrada(
  const ACodigoArticulo, ACodigoUnidad, ANombre, AExtension,
    AUsuario: string);
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'INSERT INTO fza_articulos_fotos ' +
      '  (CODIGO_ART_FOT, CODIGO_UNIDAD_FOT, NOMBRE_FOT_FOT, ' +
      '   EXTENSION_ORIGEN_FOT, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES (:a, :u, :nom, :ext, NOW(), :usr, NOW(), :usr) ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  NOMBRE_FOT_FOT       = :nom, ' +
      '  EXTENSION_ORIGEN_FOT = :ext, ' +
      '  INSTANTE_MODIF       = NOW(), ' +
      '  USUARIO_MODIF        = :usr';
    Consulta.ParamByName('a').AsString := ACodigoArticulo;
    Consulta.ParamByName('u').AsString := ACodigoUnidad;
    Consulta.ParamByName('nom').AsString := ANombre;
    Consulta.ParamByName('ext').AsString := AExtension;
    Consulta.ParamByName('usr').AsString := AUsuario;
    Consulta.ExecSQL;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TRepositorioFotosUniDAC.EliminarFotosSesionLinea(
  const ASerieSesion, ANumeroSesion: string;
  ALinea: Integer);
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'DELETE FROM fza_compras_sesiones_fotos ' +
      ' WHERE SERIE_SES_CSF  = :s ' +
      '   AND NUMERO_SES_CSF = :n ' +
      '   AND LINEA_CSF      = :l';
    Consulta.ParamByName('s').AsString := ASerieSesion;
    Consulta.ParamByName('n').AsString := ANumeroSesion;
    Consulta.ParamByName('l').AsInteger := ALinea;
    Consulta.ExecSQL;
  finally
    FreeAndNil(Consulta);
  end;
end;

function CrearRepositorioFotosUniDAC(
  AConexion: TUniConnection): TRepositoriosFotos;
var
  Repositorio: TRepositorioFotosUniDAC;
begin
  Result := Default(TRepositoriosFotos);
  Repositorio := TRepositorioFotosUniDAC.Create(AConexion);
  Result.Consulta := Repositorio;
  Result.Edicion := Repositorio;
  Result.Sesion := Repositorio;
end;

end.
