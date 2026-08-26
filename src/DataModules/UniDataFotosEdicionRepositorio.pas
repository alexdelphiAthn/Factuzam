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
  System.SysUtils, System.Hash;

const
  fcodartfot = 'CODIGO_ART_FOT';
  fcodunidadfot = 'CODIGO_UNIDAD_FOT';
  fordenfot = 'ORDEN_FOT';
  fnomfot = 'NOMBRE_FOT_FOT';
  fextfot = 'EXTENSION_ORIGEN_FOT';

type
  TRepositorioEdicionFotosUniDAC = class(
    TInterfacedObject,
    IRepositorioEdicionFotos)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
    function ClaveBloqueoColeccion(const ACodigoArticulo,
      ACodigoUnidad: string): string;
    procedure AdquirirBloqueoColeccion(AConsulta: TUniQuery;
      const AClave: string);
    procedure LiberarBloqueoColeccion(AConsulta: TUniQuery;
      const AClave: string);
    procedure ComprobarSinTransaccionExterna;
  public
    constructor Create(AConexion: TUniConnection);
    function BuscarFotoEditable(
      const ACodigoArticulo, ACodigoUnidad: string;
      out AMetadatos: TMetadatosFotoPersistida): Boolean; overload;
    function BuscarFotoEditable(
      const ACodigoArticulo, ACodigoUnidad: string;
      AOrden: Integer;
      out AMetadatos: TMetadatosFotoPersistida): Boolean; overload;
    function BuscarFotosEditables(
      const ACodigoArticulo, ACodigoUnidad: string):
      TArray<TMetadatosFotoPersistida>;
    procedure GuardarFoto(
      const AMetadatos: TMetadatosFotoPersistida;
      const ANombreAnterior, AUsuario: string);
    procedure AnadirFoto(
      var AMetadatos: TMetadatosFotoPersistida;
      const AUsuario: string);
    procedure ActualizarNombreFoto(
      const ACodigoArticulo, ACodigoUnidad, ANombre,
        AUsuario: string); overload;
    procedure ActualizarNombreFoto(
      const ACodigoArticulo, ACodigoUnidad: string;
      AOrden: Integer;
      const ANombreAnterior, ANombre,
        AUsuario: string); overload;
    function BuscarNombreFoto(
      const ACodigoArticulo, ACodigoUnidad: string): string; overload;
    function BuscarNombreFoto(
      const ACodigoArticulo, ACodigoUnidad: string;
      AOrden: Integer): string; overload;
    procedure EliminarFoto(
      const ACodigoArticulo, ACodigoUnidad: string); overload;
    procedure EliminarFoto(
      const ACodigoArticulo, ACodigoUnidad: string;
      AOrden: Integer;
      const ANombreEsperado: string); overload;
  end;

function LeerMetadatosFoto(
  AConsulta: TUniQuery): TMetadatosFotoPersistida;
begin
  Result := Default(TMetadatosFotoPersistida);
  Result.CodigoArticulo :=
    AConsulta.FieldByName(fcodartfot).AsString;
  Result.CodigoUnidad :=
    AConsulta.FieldByName(fcodunidadfot).AsString;
  Result.Orden := AConsulta.FieldByName(fordenfot).AsInteger;
  Result.Nombre := AConsulta.FieldByName(fnomfot).AsString;
  Result.Extension := AConsulta.FieldByName(fextfot).AsString;
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

function TRepositorioEdicionFotosUniDAC.ClaveBloqueoColeccion(
  const ACodigoArticulo, ACodigoUnidad: string): string;
begin
  Result := 'fza_fotos_' + THashMD5.GetHashString(
    UpperCase(Trim(ACodigoArticulo)) + #31 +
    UpperCase(Trim(ACodigoUnidad)));
end;

procedure TRepositorioEdicionFotosUniDAC.AdquirirBloqueoColeccion(
  AConsulta: TUniQuery; const AClave: string);
begin
  AConsulta.Close;
  AConsulta.SQL.Text :=
    'SELECT GET_LOCK(:CLAVE_BLOQUEO, 10) AS ADQUIRIDO';
  AConsulta.ParamByName('CLAVE_BLOQUEO').AsString := AClave;
  AConsulta.Open;
  if AConsulta.FieldByName('ADQUIRIDO').AsInteger <> 1 then
    raise Exception.Create(
      'No se pudo bloquear la galería para modificarla. Inténtalo de nuevo.');
  AConsulta.Close;
end;

procedure TRepositorioEdicionFotosUniDAC.LiberarBloqueoColeccion(
  AConsulta: TUniQuery; const AClave: string);
var
  iIntento: Integer;
begin
  // La mutación ya puede estar confirmada, por lo que un fallo al liberar no
  // se propaga al llamador. Se reintenta; si se perdió la conexión, el propio
  // servidor libera automáticamente sus bloqueos de sesión.
  for iIntento := 1 to 3 do
  begin
    try
      AConsulta.Close;
      AConsulta.SQL.Text :=
        'SELECT RELEASE_LOCK(:CLAVE_BLOQUEO) AS LIBERADO';
      AConsulta.ParamByName('CLAVE_BLOQUEO').AsString := AClave;
      AConsulta.Open;
      AConsulta.Close;
      Exit;
    except
      // Reintentar con la misma conexión.
    end;
  end;
end;

procedure TRepositorioEdicionFotosUniDAC.ComprobarSinTransaccionExterna;
begin
  if FConexion.InTransaction then
    raise Exception.Create(
      'No se pueden modificar fotos dentro de una transacción externa.');
end;

function TRepositorioEdicionFotosUniDAC.BuscarFotoEditable(
  const ACodigoArticulo, ACodigoUnidad: string;
  out AMetadatos: TMetadatosFotoPersistida): Boolean;
begin
  Result := BuscarFotoEditable(
    ACodigoArticulo, ACodigoUnidad, 1, AMetadatos);
end;

function TRepositorioEdicionFotosUniDAC.BuscarFotoEditable(
  const ACodigoArticulo, ACodigoUnidad: string;
  AOrden: Integer;
  out AMetadatos: TMetadatosFotoPersistida): Boolean;
var
  oConsulta: TUniQuery;
begin
  AMetadatos := Default(TMetadatosFotoPersistida);
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      ' SELECT CODIGO_ART_FOT, CODIGO_UNIDAD_FOT, ORDEN_FOT, ' +
      '        NOMBRE_FOT_FOT, EXTENSION_ORIGEN_FOT ' +
      '   FROM fza_articulos_fotos ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD ' +
      '    AND ORDEN_FOT         = :ORDEN ' +
      '  ORDER BY NOMBRE_FOT_FOT ' +
      '  LIMIT 1';
    oConsulta.ParamByName('CODIGO_ART').AsString :=
      ACodigoArticulo;
    oConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
      ACodigoUnidad;
    oConsulta.ParamByName('ORDEN').AsInteger := AOrden;
    oConsulta.Open;
    Result := not oConsulta.Eof;
    if Result then
      AMetadatos := LeerMetadatosFoto(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioEdicionFotosUniDAC.BuscarFotosEditables(
  const ACodigoArticulo, ACodigoUnidad: string):
  TArray<TMetadatosFotoPersistida>;
var
  oConsulta: TUniQuery;
  iFoto: Integer;
begin
  SetLength(Result, 0);
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      ' SELECT CODIGO_ART_FOT, CODIGO_UNIDAD_FOT, ORDEN_FOT, ' +
      '        NOMBRE_FOT_FOT, EXTENSION_ORIGEN_FOT ' +
      '   FROM fza_articulos_fotos ' +
      '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD ' +
      '  ORDER BY ORDEN_FOT, NOMBRE_FOT_FOT';
    oConsulta.ParamByName('CODIGO_ART').AsString :=
      ACodigoArticulo;
    oConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
      ACodigoUnidad;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iFoto := Length(Result);
      SetLength(Result, iFoto + 1);
      Result[iFoto] := LeerMetadatosFoto(oConsulta);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioEdicionFotosUniDAC.GuardarFoto(
  const AMetadatos: TMetadatosFotoPersistida;
  const ANombreAnterior, AUsuario: string);
var
  oConsulta     : TUniQuery;
  sClaveBloqueo: string;
  bBloqueada   : Boolean;
begin
  ComprobarSinTransaccionExterna;
  sClaveBloqueo := ClaveBloqueoColeccion(
    AMetadatos.CodigoArticulo, AMetadatos.CodigoUnidad);
  bBloqueada := False;
  oConsulta := NuevaConsulta;
  try
    AdquirirBloqueoColeccion(oConsulta, sClaveBloqueo);
    bBloqueada := True;
    FConexion.StartTransaction;
    try
      if ANombreAnterior = '' then
        oConsulta.SQL.Text :=
          'INSERT INTO fza_articulos_fotos ' +
          '  (CODIGO_ART_FOT, CODIGO_UNIDAD_FOT, ORDEN_FOT, ' +
          '   NOMBRE_FOT_FOT, EXTENSION_ORIGEN_FOT, INSTANTE_ALTA, ' +
          '   USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
          'VALUES (:a, :u, :orden, :nom, :ext, NOW(), :usr, ' +
          '        NOW(), :usr)'
      else
        oConsulta.SQL.Text :=
          ' UPDATE fza_articulos_fotos ' +
          '    SET NOMBRE_FOT_FOT       = :nom, ' +
          '        EXTENSION_ORIGEN_FOT = :ext, ' +
          '        INSTANTE_MODIF       = NOW(), ' +
          '        USUARIO_MODIF        = :usr ' +
          '  WHERE CODIGO_ART_FOT    = :a ' +
          '    AND CODIGO_UNIDAD_FOT = :u ' +
          '    AND ORDEN_FOT         = :orden ' +
          '    AND NOMBRE_FOT_FOT    = :nombre_anterior';
      oConsulta.ParamByName('a').AsString :=
        AMetadatos.CodigoArticulo;
      oConsulta.ParamByName('u').AsString :=
        AMetadatos.CodigoUnidad;
      oConsulta.ParamByName('orden').AsInteger := AMetadatos.Orden;
      oConsulta.ParamByName('nom').AsString := AMetadatos.Nombre;
      oConsulta.ParamByName('ext').AsString := AMetadatos.Extension;
      oConsulta.ParamByName('usr').AsString := AUsuario;
      if ANombreAnterior <> '' then
        oConsulta.ParamByName('nombre_anterior').AsString :=
          ANombreAnterior;
      oConsulta.ExecSQL;
      if (ANombreAnterior <> '') and
         (oConsulta.RowsAffected <> 1) then
        raise Exception.Create(
          'La foto principal ha cambiado; actualiza la galería e inténtalo de nuevo.');
      FConexion.Commit;
    except
      if FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    if bBloqueada then
      LiberarBloqueoColeccion(oConsulta, sClaveBloqueo);
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioEdicionFotosUniDAC.AnadirFoto(
  var AMetadatos: TMetadatosFotoPersistida;
  const AUsuario: string);
var
  oConsulta     : TUniQuery;
  sClaveBloqueo: string;
  bBloqueada   : Boolean;
begin
  ComprobarSinTransaccionExterna;
  sClaveBloqueo := ClaveBloqueoColeccion(
    AMetadatos.CodigoArticulo, AMetadatos.CodigoUnidad);
  bBloqueada := False;
  oConsulta := NuevaConsulta;
  try
    AdquirirBloqueoColeccion(oConsulta, sClaveBloqueo);
    bBloqueada := True;
    FConexion.StartTransaction;
    try
      oConsulta.SQL.Text :=
        ' SELECT COALESCE(MAX(ORDEN_FOT), 0) + 1 AS SIGUIENTE ' +
        '   FROM fza_articulos_fotos ' +
        '  WHERE CODIGO_ART_FOT    = :a ' +
        '    AND CODIGO_UNIDAD_FOT = :u';
      oConsulta.ParamByName('a').AsString :=
        AMetadatos.CodigoArticulo;
      oConsulta.ParamByName('u').AsString :=
        AMetadatos.CodigoUnidad;
      oConsulta.Open;
      AMetadatos.Orden :=
        oConsulta.FieldByName('SIGUIENTE').AsInteger;
      oConsulta.Close;

      oConsulta.SQL.Text :=
        'INSERT INTO fza_articulos_fotos ' +
        '  (CODIGO_ART_FOT, CODIGO_UNIDAD_FOT, ORDEN_FOT, ' +
        '   NOMBRE_FOT_FOT, EXTENSION_ORIGEN_FOT, INSTANTE_ALTA, ' +
        '   USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
        'VALUES (:a, :u, :orden, :nom, :ext, NOW(), :usr, ' +
        '        NOW(), :usr)';
      oConsulta.ParamByName('a').AsString :=
        AMetadatos.CodigoArticulo;
      oConsulta.ParamByName('u').AsString :=
        AMetadatos.CodigoUnidad;
      oConsulta.ParamByName('orden').AsInteger := AMetadatos.Orden;
      oConsulta.ParamByName('nom').AsString := AMetadatos.Nombre;
      oConsulta.ParamByName('ext').AsString := AMetadatos.Extension;
      oConsulta.ParamByName('usr').AsString := AUsuario;
      oConsulta.ExecSQL;
      FConexion.Commit;
    except
      if FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    if bBloqueada then
      LiberarBloqueoColeccion(oConsulta, sClaveBloqueo);
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioEdicionFotosUniDAC.ActualizarNombreFoto(
  const ACodigoArticulo, ACodigoUnidad, ANombre, AUsuario: string);
var
  sNombreAnterior: string;
begin
  sNombreAnterior := BuscarNombreFoto(
    ACodigoArticulo, ACodigoUnidad, 1);
  if sNombreAnterior = '' then
    raise Exception.Create(
      'La foto que se iba a actualizar ya no existe.');
  ActualizarNombreFoto(
    ACodigoArticulo, ACodigoUnidad, 1,
    sNombreAnterior, ANombre, AUsuario);
end;

procedure TRepositorioEdicionFotosUniDAC.ActualizarNombreFoto(
  const ACodigoArticulo, ACodigoUnidad: string;
  AOrden: Integer; const ANombreAnterior, ANombre,
  AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  ComprobarSinTransaccionExterna;
  oConsulta := NuevaConsulta;
  try
    FConexion.StartTransaction;
    try
      oConsulta.SQL.Text :=
        ' UPDATE fza_articulos_fotos ' +
        '    SET NOMBRE_FOT_FOT = :NOMBRE, ' +
        '        USUARIO_MODIF  = :USUARIO ' +
        '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
        '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD ' +
        '    AND ORDEN_FOT         = :ORDEN ' +
        '    AND NOMBRE_FOT_FOT    = :NOMBRE_ANTERIOR';
      oConsulta.ParamByName('NOMBRE').AsString := ANombre;
      oConsulta.ParamByName('USUARIO').AsString := AUsuario;
      oConsulta.ParamByName('CODIGO_ART').AsString :=
        ACodigoArticulo;
      oConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
        ACodigoUnidad;
      oConsulta.ParamByName('ORDEN').AsInteger := AOrden;
      oConsulta.ParamByName('NOMBRE_ANTERIOR').AsString :=
        ANombreAnterior;
      oConsulta.Execute;
      if oConsulta.RowsAffected <> 1 then
        raise Exception.Create(
          'La foto seleccionada ha cambiado; actualiza la galería e inténtalo de nuevo.');
      FConexion.Commit;
    except
      if FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioEdicionFotosUniDAC.BuscarNombreFoto(
  const ACodigoArticulo, ACodigoUnidad: string): string;
begin
  Result := BuscarNombreFoto(ACodigoArticulo, ACodigoUnidad, 1);
end;

function TRepositorioEdicionFotosUniDAC.BuscarNombreFoto(
  const ACodigoArticulo, ACodigoUnidad: string;
  AOrden: Integer): string;
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
      '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD ' +
      '    AND ORDEN_FOT         = :ORDEN ' +
      '  ORDER BY NOMBRE_FOT_FOT ' +
      '  LIMIT 1';
    oConsulta.ParamByName('CODIGO_ART').AsString :=
      ACodigoArticulo;
    oConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
      ACodigoUnidad;
    oConsulta.ParamByName('ORDEN').AsInteger := AOrden;
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
  sNombreEsperado: string;
begin
  sNombreEsperado := BuscarNombreFoto(
    ACodigoArticulo, ACodigoUnidad, 1);
  if sNombreEsperado <> '' then
    EliminarFoto(
      ACodigoArticulo, ACodigoUnidad, 1, sNombreEsperado);
end;

procedure TRepositorioEdicionFotosUniDAC.EliminarFoto(
  const ACodigoArticulo, ACodigoUnidad: string;
  AOrden: Integer; const ANombreEsperado: string);
var
  oConsulta     : TUniQuery;
  sClaveBloqueo: string;
  bBloqueada   : Boolean;
begin
  if AOrden < 1 then
    Exit;
  ComprobarSinTransaccionExterna;
  sClaveBloqueo := ClaveBloqueoColeccion(
    ACodigoArticulo, ACodigoUnidad);
  bBloqueada := False;
  oConsulta := NuevaConsulta;
  try
    AdquirirBloqueoColeccion(oConsulta, sClaveBloqueo);
    bBloqueada := True;
    FConexion.StartTransaction;
    try
      oConsulta.SQL.Text :=
        ' DELETE FROM fza_articulos_fotos ' +
        '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
        '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD ' +
        '    AND ORDEN_FOT         = :ORDEN ' +
        '    AND NOMBRE_FOT_FOT    = :NOMBRE_ESPERADO';
      oConsulta.ParamByName('CODIGO_ART').AsString :=
        ACodigoArticulo;
      oConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
        ACodigoUnidad;
      oConsulta.ParamByName('ORDEN').AsInteger := AOrden;
      oConsulta.ParamByName('NOMBRE_ESPERADO').AsString :=
        ANombreEsperado;
      oConsulta.Execute;
      if oConsulta.RowsAffected <> 1 then
        raise Exception.Create(
          'La foto seleccionada ha cambiado; actualiza la galería e inténtalo de nuevo.');

      oConsulta.SQL.Text :=
        ' UPDATE fza_articulos_fotos ' +
        '    SET ORDEN_FOT = ORDEN_FOT - 1 ' +
        '  WHERE CODIGO_ART_FOT    = :CODIGO_ART ' +
        '    AND CODIGO_UNIDAD_FOT = :CODIGO_UNIDAD ' +
        '    AND ORDEN_FOT         > :ORDEN ' +
        '  ORDER BY ORDEN_FOT';
      oConsulta.ParamByName('CODIGO_ART').AsString :=
        ACodigoArticulo;
      oConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
        ACodigoUnidad;
      oConsulta.ParamByName('ORDEN').AsInteger := AOrden;
      oConsulta.Execute;
      FConexion.Commit;
    except
      if FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    if bBloqueada then
      LiberarBloqueoColeccion(oConsulta, sClaveBloqueo);
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioEdicionFotosUniDAC(
  AConexion: TUniConnection): IRepositorioEdicionFotos;
begin
  Result := TRepositorioEdicionFotosUniDAC.Create(AConexion);
end;

end.
