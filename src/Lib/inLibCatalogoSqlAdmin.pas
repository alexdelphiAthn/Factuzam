{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCatalogoSqlAdmin                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Publicación, revisión y exportación del catálogo SQL en perfiles.         }
{******************************************************************************}
unit inLibCatalogoSqlAdmin;

interface

uses
  inLibCatalogoSqlIntf, inLibPerfilesUsuarioIntf;

type
  TEstadoPerfilSql = (
    epsFalta,
    epsDesactivado,
    epsBase,
    epsPersonalizado,
    epsInvalido);
  TRevisionPerfilSql = record
    ClavePerfil: string;
    Estado: TEstadoPerfilSql;
    Mensaje: string;
    HuellaBase: string;
    HuellaPerfil: string;
  end;
  TRevisionesPerfilSql = array of TRevisionPerfilSql;
  TAdministradorSqlPerfiles = class
  private
    FPerfiles: IPerfilesUsuario;
    function CargarPerfil(
      const AClavePerfil: string): TProfileDicc;
    function PerfilActivo(const AValor: string): Boolean;
    function NombreSeguro(const ATexto: string): string;
  public
    constructor Create(
      const APerfiles: IPerfilesUsuario);
    procedure PublicarFaltantes(
      const AClavePerfil: string;
      const ADefiniciones: TDefinicionesSql);
    function Revisar(
      const AClavePerfil: string;
      const ADefiniciones: TDefinicionesSql
    ): TRevisionesPerfilSql;
    procedure Exportar(
      const ARuta: string;
      const ADefiniciones: TDefinicionesSql);
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils,
  inLibCatalogoSqlValidacion;

resourcestring
  SErrorPerfilesSqlNoConfigurados =
    'El servicio de perfiles no está configurado.';

constructor TAdministradorSqlPerfiles.Create(
  const APerfiles: IPerfilesUsuario);
begin
  inherited Create;
  FPerfiles := APerfiles;
end;

function TAdministradorSqlPerfiles.CargarPerfil(
  const AClavePerfil: string): TProfileDicc;
begin
  Result := nil;
  if not Assigned(FPerfiles) then
    raise Exception.Create(
      SErrorPerfilesSqlNoConfigurados);
  FPerfiles.CargarPerfilFormulario(
    AClavePerfil,
    PERFIL_TODOS,
    PERFIL_TODOS,
    Result);
  if not Assigned(Result) then
    Result := TProfileDicc.Create;
end;

function TAdministradorSqlPerfiles.PerfilActivo(
  const AValor: string): Boolean;
begin
  Result := SameText(
    Copy(Trim(AValor), 1, 1), 'S');
end;

function TAdministradorSqlPerfiles.NombreSeguro(
  const ATexto: string): string;
var
  cCaracter: Char;
  iIndice: Integer;
begin
  Result := '';
  for iIndice := 1 to Length(ATexto) do
  begin
    cCaracter := ATexto[iIndice];
    if CharInSet(
         cCaracter,
         ['A'..'Z', 'a'..'z', '0'..'9', '-', '_']) then
      Result := Result + cCaracter
    else
      Result := Result + '_';
  end;
end;

procedure TAdministradorSqlPerfiles.PublicarFaltantes(
  const AClavePerfil: string;
  const ADefiniciones: TDefinicionesSql);
var
  iIndice: Integer;
  oPerfil: TProfileDicc;
  sClaveSql: string;
  sVersion: string;
begin
  oPerfil := CargarPerfil(AClavePerfil);
  try
    for iIndice := 0 to High(ADefiniciones) do
    begin
      sClaveSql := ClavePerfilSql(
        ADefiniciones[iIndice]);
      if not oPerfil.ContainsKey(sClaveSql) then
      begin
        sVersion := Format(
          'S;V=%d;BASE=%s',
          [ADefiniciones[iIndice].Version,
           CalcularHuellaSql(
             ADefiniciones[iIndice].SqlBase)]);
        FPerfiles.GrabarPerfil(
          PERFIL_TODOS,
          AClavePerfil,
          sClaveSql,
          sVersion,
          ADefiniciones[iIndice].SqlBase);
      end;
    end;
  finally
    FreeAndNil(oPerfil);
  end;
end;

function TAdministradorSqlPerfiles.Revisar(
  const AClavePerfil: string;
  const ADefiniciones: TDefinicionesSql
): TRevisionesPerfilSql;
var
  iIndice: Integer;
  oPerfil: TProfileDicc;
  oValidacion: TResultadoValidacionSql;
  oValor: TDictValue;
  sClaveSql: string;
  sSqlPerfil: string;
begin
  SetLength(Result, Length(ADefiniciones));
  oPerfil := CargarPerfil(AClavePerfil);
  try
    for iIndice := 0 to High(ADefiniciones) do
    begin
      sClaveSql := ClavePerfilSql(
        ADefiniciones[iIndice]);
      Result[iIndice].ClavePerfil := sClaveSql;
      Result[iIndice].HuellaBase := CalcularHuellaSql(
        ADefiniciones[iIndice].SqlBase);
      Result[iIndice].HuellaPerfil := '';
      Result[iIndice].Mensaje := '';
      Result[iIndice].Estado := epsFalta;
      if oPerfil.TryGetValue(sClaveSql, oValor) then
      begin
        sSqlPerfil := string(oValor.sValueText);
        Result[iIndice].HuellaPerfil :=
          CalcularHuellaSql(sSqlPerfil);
        if not PerfilActivo(oValor.sValue) then
          Result[iIndice].Estado := epsDesactivado
        else
        begin
          oValidacion := ValidarSql(
            ADefiniciones[iIndice], sSqlPerfil);
          if not oValidacion.EsValido then
          begin
            Result[iIndice].Estado := epsInvalido;
            Result[iIndice].Mensaje :=
              oValidacion.Mensaje;
          end
          else if Result[iIndice].HuellaBase =
                  Result[iIndice].HuellaPerfil then
            Result[iIndice].Estado := epsBase
          else
            Result[iIndice].Estado :=
              epsPersonalizado;
        end;
      end;
    end;
  finally
    FreeAndNil(oPerfil);
  end;
end;

procedure TAdministradorSqlPerfiles.Exportar(
  const ARuta: string;
  const ADefiniciones: TDefinicionesSql);
var
  iIndice: Integer;
  oIndice: TStringList;
  sDirectorioRepositorio: string;
  sFichero: string;
begin
  ForceDirectories(ARuta);
  oIndice := TStringList.Create;
  try
    for iIndice := 0 to High(ADefiniciones) do
    begin
      sDirectorioRepositorio := TPath.Combine(
        ARuta,
        NombreSeguro(
          ADefiniciones[iIndice].Repositorio));
      ForceDirectories(sDirectorioRepositorio);
      sFichero := TPath.Combine(
        sDirectorioRepositorio,
        NombreSeguro(
          ADefiniciones[iIndice].Operacion) + '.sql');
      TFile.WriteAllText(
        sFichero,
        ADefiniciones[iIndice].SqlBase,
        TEncoding.UTF8);
      oIndice.Add(Format(
        '%s | V%d | %s',
        [ClavePerfilSql(ADefiniciones[iIndice]),
         ADefiniciones[iIndice].Version,
         CalcularHuellaSql(
           ADefiniciones[iIndice].SqlBase)]));
    end;
    oIndice.SaveToFile(
      TPath.Combine(ARuta, 'catalogo_sql.txt'),
      TEncoding.UTF8);
  finally
    FreeAndNil(oIndice);
  end;
end;

end.
