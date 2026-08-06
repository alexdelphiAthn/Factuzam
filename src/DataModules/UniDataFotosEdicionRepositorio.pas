{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFotosEdicionRepositorio                               }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Escritura UniDAC de metadatos de fotografías de artículos y SKU.          }
{******************************************************************************}
unit UniDataFotosEdicionRepositorio;

interface

uses
  Uni, inLibFotosPersistenciaIntf;

function CrearRepositorioEdicionFotosUniDAC(
  AConexion: TUniConnection): IRepositorioEdicionFotos;

implementation

uses
  System.SysUtils;

const
  fcodartfot = 'CODIGO_ART_FOT';
  fcodunidadfot = 'CODIGO_UNIDAD_FOT';
  fnomfot = 'NOMBRE_FOT_FOT';
  fextfot = 'EXTENSION_ORIGEN_FOT';

type
  TRepositorioEdicionFotosUniDAC = class(
    TInterfacedObject,
    IRepositorioEdicionFotos)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
  public
    constructor Create(AConexion: TUniConnection);
    function BuscarFotoEditable(
      const ACodigoArticulo, ACodigoUnidad: string;
      out AMetadatos: TMetadatosFotoPersistida): Boolean;
    procedure GuardarFoto(
      const AMetadatos: TMetadatosFotoPersistida;
      const AUsuario: string);
    procedure ActualizarNombreFoto(
      const ACodigoArticulo, ACodigoUnidad, ANombre, AUsuario: string);
    function BuscarNombreFoto(
      const ACodigoArticulo, ACodigoUnidad: string): string;
    procedure EliminarFoto(
      const ACodigoArticulo, ACodigoUnidad: string);
  end;

constructor TRepositorioEdicionFotosUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioEdicionFotosUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioEdicionFotosUniDAC.BuscarFotoEditable(
  const ACodigoArticulo, ACodigoUnidad: string;
  out AMetadatos: TMetadatosFotoPersistida): Boolean;
var
  oConsulta: TUniQuery;
begin
  AMetadatos := Default(TMetadatosFotoPersistida);
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      ' SELECT CODIGO_ART_FOT, CODIGO_UNIDAD_FOT, ' +
      '        NOMBRE_FOT_FOT, EXTENSION_ORIGEN_FOT ' +
      '   FROM fza_articulos_fotos ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD';
    oConsulta.ParamByName('CODIGO_ART').AsString :=
      ACodigoArticulo;
    oConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
      ACodigoUnidad;
    oConsulta.Open;
    Result := not oConsulta.Eof;
    if Result then
    begin
      AMetadatos.CodigoArticulo :=
        oConsulta.FieldByName(fcodartfot).AsString;
      AMetadatos.CodigoUnidad :=
        oConsulta.FieldByName(fcodunidadfot).AsString;
      AMetadatos.Nombre := oConsulta.FieldByName(fnomfot).AsString;
      AMetadatos.Extension :=
        oConsulta.FieldByName(fextfot).AsString;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioEdicionFotosUniDAC.GuardarFoto(
  const AMetadatos: TMetadatosFotoPersistida;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
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
    oConsulta.ParamByName('a').AsString :=
      AMetadatos.CodigoArticulo;
    oConsulta.ParamByName('u').AsString :=
      AMetadatos.CodigoUnidad;
    oConsulta.ParamByName('nom').AsString := AMetadatos.Nombre;
    oConsulta.ParamByName('ext').AsString := AMetadatos.Extension;
    oConsulta.ParamByName('usr').AsString := AUsuario;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioEdicionFotosUniDAC.ActualizarNombreFoto(
  const ACodigoArticulo, ACodigoUnidad, ANombre, AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      ' UPDATE fza_articulos_fotos ' +
      '    SET NOMBRE_FOT_FOT = :NOMBRE, ' +
      '        USUARIO_MODIF  = :USUARIO ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD';
    oConsulta.ParamByName('NOMBRE').AsString := ANombre;
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.ParamByName('CODIGO_ART').AsString :=
      ACodigoArticulo;
    oConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
      ACodigoUnidad;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioEdicionFotosUniDAC.BuscarNombreFoto(
  const ACodigoArticulo, ACodigoUnidad: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      ' SELECT NOMBRE_FOT_FOT ' +
      '   FROM fza_articulos_fotos ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD';
    oConsulta.ParamByName('CODIGO_ART').AsString :=
      ACodigoArticulo;
    oConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
      ACodigoUnidad;
    oConsulta.Open;
    if not oConsulta.Eof then
      Result := oConsulta.FieldByName(fnomfot).AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioEdicionFotosUniDAC.EliminarFoto(
  const ACodigoArticulo, ACodigoUnidad: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      ' DELETE FROM fza_articulos_fotos ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD';
    oConsulta.ParamByName('CODIGO_ART').AsString :=
      ACodigoArticulo;
    oConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
      ACodigoUnidad;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioEdicionFotosUniDAC(
  AConexion: TUniConnection): IRepositorioEdicionFotos;
begin
  Result := TRepositorioEdicionFotosUniDAC.Create(AConexion);
end;

end.
