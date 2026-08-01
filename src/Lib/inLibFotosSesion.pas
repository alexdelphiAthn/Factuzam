{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFotosSesion                                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fotografías temporales y materialización de sesiones de compra.           }
{******************************************************************************}
unit inLibFotosSesion;

interface

uses
  inLibFotosPersistenciaIntf, inLibFotosTipos,
  inLibFotosAlmacenamiento;

type
  TSesionFotos = class
  private
    FRepositorioSesion : IRepositorioSesionFotos;
    FRepositorioEdicion: IRepositorioEdicionFotos;
    FAlmacenamiento    : TAlmacenamientoFotos;
    function BuscarFoto(const ASerieSesion,
      ANumeroSesion: string; ALinea: Integer;
      const ACodigoUnidad, ACodigoSolicitado: string;
      AOrigen: TFotoOrigen): TFotoInfo;
    function ClaveNombreSesion(const ASerieSesion,
      ANumeroSesion: string; ALinea: Integer;
      const ACodigoUnidad: string): string;
  public
    constructor Create(AAlmacenamiento: TAlmacenamientoFotos);
    procedure AsignarRepositorios(
      const ARepositorioSesion: IRepositorioSesionFotos;
      const ARepositorioEdicion: IRepositorioEdicionFotos);
    procedure LiberarServicios;
    function Guardar(const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer; const ACodigoArticuloTentativo,
      ACodigoUnidad, AFicheroOrigen, AUsuario: string): TFotoInfo;
    function Resolver(const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer; const ACodigoUnidad: string = ''): TFotoInfo;
    procedure Eliminar(const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer; const ACodigoUnidad: string);
    procedure Migrar(const ASerieSesion, ANumeroSesion: string;
      ALinea: Integer; const ACodigoArticulo, AUsuario: string);
  end;

implementation

uses
  System.SysUtils,
  Data.DB,
  inLibFotosConsulta, inLibMsgArticulos;

constructor TSesionFotos.Create(
  AAlmacenamiento: TAlmacenamientoFotos);
begin
  inherited Create;
  FAlmacenamiento := AAlmacenamiento;
end;

procedure TSesionFotos.AsignarRepositorios(
  const ARepositorioSesion: IRepositorioSesionFotos;
  const ARepositorioEdicion: IRepositorioEdicionFotos);
begin
  FRepositorioSesion := ARepositorioSesion;
  FRepositorioEdicion := ARepositorioEdicion;
end;

procedure TSesionFotos.LiberarServicios;
begin
  FRepositorioSesion := nil;
  FRepositorioEdicion := nil;
end;

function TSesionFotos.ClaveNombreSesion(const ASerieSesion,
  ANumeroSesion: string; ALinea: Integer;
  const ACodigoUnidad: string): string;
var
  sUnidad  : string;
  iCaracter: Integer;
begin
  Result := 'ses_' + ASerieSesion + '_' + ANumeroSesion + '_' +
    Format('%.4d', [ALinea]);
  sUnidad := ACodigoUnidad;
  if sUnidad <> '' then
  begin
    for iCaracter := 1 to Length(sUnidad) do
    begin
      if not CharInSet(sUnidad[iCaracter],
        ['A'..'Z', 'a'..'z', '0'..'9', '-', '_']) then
        sUnidad[iCaracter] := '_';
    end;
    Result := Result + '_' + sUnidad;
  end;
end;

function TSesionFotos.Guardar(const ASerieSesion,
  ANumeroSesion: string; ALinea: Integer;
  const ACodigoArticuloTentativo, ACodigoUnidad,
  AFicheroOrigen, AUsuario: string): TFotoInfo;
var
  oDatos         : TDataSet;
  sClave         : string;
  sExtension     : string;
  sNombreAnterior: string;
  sNombreNuevo   : string;
  iIndice        : Integer;
begin
  Result.Clear;
  if ASerieSesion = '' then
    raise Exception.Create(SErrorFotoSesionSinSerie);
  if ANumeroSesion = '' then
    raise Exception.Create(SErrorFotoSesionSinNumero);
  if ALinea <= 0 then
    raise Exception.Create(SErrorFotoSesionLineaInvalida);
  if not FileExists(AFicheroOrigen) then
    raise Exception.Create(Format(SErrorFicheroOrigenFotoNoExiste,
      [AFicheroOrigen]));
  sClave := ClaveNombreSesion(ASerieSesion, ANumeroSesion,
    ALinea, ACodigoUnidad);
  sExtension := FAlmacenamiento.ExtensionOrigen(AFicheroOrigen);
  sNombreAnterior := '';
  iIndice := 1;
  oDatos := nil;
  try
    oDatos := FRepositorioSesion.BuscarFotoSesion(
      ASerieSesion, ANumeroSesion, ALinea, ACodigoUnidad);
    if not oDatos.Eof then
    begin
      sNombreAnterior :=
        oDatos.FieldByName('NOMBRE_FOT_CSF').AsString;
      iIndice := FAlmacenamiento.ExtraerIndice(
        sNombreAnterior) + 1;
      if iIndice < 1 then
        iIndice := 1;
    end;
  finally
    FreeAndNil(oDatos);
  end;
  sNombreNuevo := FAlmacenamiento.ComponerNombre(
    sClave, iIndice);
  FAlmacenamiento.GuardarCopias(AFicheroOrigen, sNombreNuevo);
  FRepositorioSesion.GuardarFotoSesion(
    ASerieSesion,
    ANumeroSesion,
    ALinea,
    ACodigoUnidad,
    ACodigoArticuloTentativo,
    sNombreNuevo,
    sExtension,
    AUsuario);
  if (sNombreAnterior <> '') and
     (sNombreAnterior <> sNombreNuevo) then
    FAlmacenamiento.BorrarCopias(sNombreAnterior);
  Result.Encontrada := True;
  Result.Origen := foSku;
  Result.CodigoArt := ACodigoArticuloTentativo;
  Result.CodigoSku := ACodigoUnidad;
  Result.ClaveResuelta := ACodigoUnidad;
  Result.NombreBase := sNombreNuevo;
  Result.ExtensionOrigen := sExtension;
end;

function TSesionFotos.BuscarFoto(const ASerieSesion,
  ANumeroSesion: string; ALinea: Integer;
  const ACodigoUnidad, ACodigoSolicitado: string;
  AOrigen: TFotoOrigen): TFotoInfo;
var
  oDatos: TDataSet;
begin
  Result.Clear;
  oDatos := nil;
  try
    oDatos := FRepositorioSesion.BuscarFotoSesion(
      ASerieSesion, ANumeroSesion, ALinea, ACodigoUnidad);
    if not oDatos.Eof then
    begin
      Result.Encontrada := True;
      Result.Origen := AOrigen;
      Result.CodigoArt := oDatos.FieldByName(
        'CODIGO_ART_TENTATIVO_CSF').AsString;
      Result.CodigoSku := ACodigoSolicitado;
      Result.ClaveResuelta := ACodigoUnidad;
      Result.NombreBase :=
        oDatos.FieldByName('NOMBRE_FOT_CSF').AsString;
      Result.ExtensionOrigen := oDatos.FieldByName(
        'EXTENSION_ORIGEN_CSF').AsString;
    end;
  finally
    FreeAndNil(oDatos);
  end;
end;

function TSesionFotos.Resolver(const ASerieSesion,
  ANumeroSesion: string; ALinea: Integer;
  const ACodigoUnidad: string): TFotoInfo;
var
  aPrefijos: TArray<string>;
  iPrefijo : Integer;
  eOrigen  : TFotoOrigen;
begin
  Result.Clear;
  if (ASerieSesion <> '') and (ANumeroSesion <> '') and
     (ALinea > 0) then
  begin
    if ACodigoUnidad = '' then
      eOrigen := foArticulo
    else
      eOrigen := foSku;
    Result := BuscarFoto(ASerieSesion, ANumeroSesion, ALinea,
      ACodigoUnidad, ACodigoUnidad, eOrigen);
    if (not Result.Encontrada) and (ACodigoUnidad <> '') then
    begin
      aPrefijos := GenerarPrefijosSku(ACodigoUnidad);
      iPrefijo := 0;
      while (iPrefijo <= High(aPrefijos)) and
            (not Result.Encontrada) do
      begin
        if aPrefijos[iPrefijo] <> ACodigoUnidad then
          Result := BuscarFoto(ASerieSesion, ANumeroSesion,
            ALinea, aPrefijos[iPrefijo], ACodigoUnidad,
            foSkuPrefijo);
        Inc(iPrefijo);
      end;
    end;
    if (not Result.Encontrada) and (ACodigoUnidad <> '') then
      Result := BuscarFoto(ASerieSesion, ANumeroSesion, ALinea,
        '', ACodigoUnidad, foArticulo);
  end;
end;

procedure TSesionFotos.Eliminar(const ASerieSesion,
  ANumeroSesion: string; ALinea: Integer;
  const ACodigoUnidad: string);
var
  oDatos: TDataSet;
  sNombre: string;
begin
  if (ASerieSesion <> '') and (ANumeroSesion <> '') and
     (ALinea > 0) then
  begin
    sNombre := '';
    oDatos := nil;
    try
      oDatos := FRepositorioSesion.BuscarFotoSesion(
        ASerieSesion, ANumeroSesion, ALinea, ACodigoUnidad);
      if not oDatos.Eof then
        sNombre := oDatos.FieldByName('NOMBRE_FOT_CSF').AsString;
    finally
      FreeAndNil(oDatos);
    end;
    if sNombre <> '' then
    begin
      FRepositorioSesion.EliminarFotoSesion(
        ASerieSesion, ANumeroSesion, ALinea, ACodigoUnidad);
      FAlmacenamiento.BorrarCopias(sNombre);
    end;
  end;
end;

procedure TSesionFotos.Migrar(const ASerieSesion,
  ANumeroSesion: string; ALinea: Integer;
  const ACodigoArticulo, AUsuario: string);
var
  oOrigen      : TDataSet;
  oDestino     : TDataSet;
  sClave       : string;
  sCodigoUnidad: string;
  sExtension   : string;
  sNombreOrigen: string;
  sNombreNuevo : string;
  iIndice      : Integer;
begin
  if (ASerieSesion <> '') and (ANumeroSesion <> '') and
     (ALinea > 0) and (Trim(ACodigoArticulo) <> '') then
  begin
    oOrigen := nil;
    oDestino := nil;
    try
      oOrigen := FRepositorioSesion.BuscarFotosSesionLinea(
        ASerieSesion, ANumeroSesion, ALinea);
      while not oOrigen.Eof do
      begin
        sCodigoUnidad :=
          oOrigen.FieldByName('CODIGO_UNIDAD_CSF').AsString;
        sNombreOrigen :=
          oOrigen.FieldByName('NOMBRE_FOT_CSF').AsString;
        sExtension :=
          oOrigen.FieldByName('EXTENSION_ORIGEN_CSF').AsString;
        sClave := FAlmacenamiento.ClaveNombre(
          ACodigoArticulo, sCodigoUnidad);
        iIndice := 1;
        oDestino := FRepositorioEdicion.BuscarFotoEditable(
          ACodigoArticulo, sCodigoUnidad);
        if not oDestino.Eof then
          iIndice := FAlmacenamiento.ExtraerIndice(
            oDestino.FieldByName(fnomfot).AsString) + 1;
        FreeAndNil(oDestino);
        if iIndice < 1 then
          iIndice := 1;
        sNombreNuevo := FAlmacenamiento.ComponerNombre(
          sClave, iIndice);
        FAlmacenamiento.RenombrarCopias(
          sNombreOrigen, sNombreNuevo);
        FRepositorioSesion.GuardarFotoMigrada(
          ACodigoArticulo,
          sCodigoUnidad,
          sNombreNuevo,
          sExtension,
          AUsuario);
        oOrigen.Next;
      end;
      oOrigen.Close;
      FRepositorioSesion.EliminarFotosSesionLinea(
        ASerieSesion, ANumeroSesion, ALinea);
    finally
      FreeAndNil(oOrigen);
      FreeAndNil(oDestino);
    end;
  end;
end;

end.
