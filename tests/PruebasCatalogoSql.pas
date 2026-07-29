{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasCatalogoSql                                            }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas del catálogo, validación y publicación de SQL en perfiles.        }
{******************************************************************************}
unit PruebasCatalogoSql;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasCatalogoSql = class
  public
    [Test]
    procedure SinPerfil_DevuelveSqlBase;
    [Test]
    procedure PerfilActivoValido_DevuelvePersonalizacion;
    [Test]
    procedure PerfilConParametrosInvalidos_DevuelveSqlBase;
    [Test]
    procedure SentenciaPeligrosa_NoEsValida;
    [Test]
    procedure Administrador_PublicaSoloLasConsultasQueFaltan;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections,
  inLibCatalogoSqlIntf,
  inLibCatalogoSqlValidacion,
  inLibCatalogoSqlPerfiles,
  inLibCatalogoSqlAdmin,
  inLibPerfilesUsuarioIntf;

type
  TPerfilesUsuarioFalso = class(
    TInterfacedObject,
    IPerfilesUsuario)
  private
    FGrabaciones: Integer;
    FPerfil: TProfileDicc;
    function ClonarPerfil: TProfileDicc;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Definir(
      const ASubclave, AValor, ATexto: string);
    function Texto(const ASubclave: string): string;
    procedure GrabarPerfil(
      const AUsuarioGrupo, AClave, ASubclave, AValor: string;
      const AValorTexto: WideString = '');
    procedure GrabarPerfiles(const APerfiles: TPerfilList);
    procedure EliminarPerfil(
      const AUsuarioGrupo, AClave: string;
      const ASubclave: string = '');
    function ObtenerValorPerfil(
      const AClave, ASubclave, AValorPredeterminado: string
    ): string;
    function ObtenerSubclavePerfil(
      const AClave: string;
      const AValorPredeterminado: string = ''
    ): string;
    procedure PrecargarPerfilesUsuario;
    function CargarPerfilFormulario(
      const AFormulario: string;
      out APerfil: TProfileDicc
    ): Boolean; overload;
    function CargarPerfilFormulario(
      const AFormulario, AUsuario, AGrupo: string;
      out APerfil: TProfileDicc
    ): Boolean; overload;
    procedure ResincronizarPerfilFormulario(
      const AFormulario: string);
    procedure InvalidarCachePerfiles;
    property Grabaciones: Integer read FGrabaciones;
  end;

function DefinicionConsulta(
  const AOperacion: string): TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioPrueba',
    AOperacion,
    'SELECT VALOR FROM TABLA WHERE A = :a AND B = :b',
    'a,b',
    tssSelect);
end;

constructor TPerfilesUsuarioFalso.Create;
begin
  inherited Create;
  FPerfil := TProfileDicc.Create;
end;

destructor TPerfilesUsuarioFalso.Destroy;
begin
  FreeAndNil(FPerfil);
  inherited;
end;

function TPerfilesUsuarioFalso.ClonarPerfil: TProfileDicc;
var
  oPar: TPair<string, TDictValue>;
begin
  Result := TProfileDicc.Create;
  for oPar in FPerfil do
    Result.AddOrSetValue(oPar.Key, oPar.Value);
end;

procedure TPerfilesUsuarioFalso.Definir(
  const ASubclave, AValor, ATexto: string);
var
  oValor: TDictValue;
begin
  oValor.sValue := AValor;
  oValor.sValueText := ATexto;
  FPerfil.AddOrSetValue(ASubclave, oValor);
end;

function TPerfilesUsuarioFalso.Texto(
  const ASubclave: string): string;
var
  oValor: TDictValue;
begin
  Result := '';
  if FPerfil.TryGetValue(ASubclave, oValor) then
    Result := string(oValor.sValueText);
end;

procedure TPerfilesUsuarioFalso.GrabarPerfil(
  const AUsuarioGrupo, AClave, ASubclave, AValor: string;
  const AValorTexto: WideString);
begin
  Inc(FGrabaciones);
  Definir(ASubclave, AValor, string(AValorTexto));
end;

procedure TPerfilesUsuarioFalso.GrabarPerfiles(
  const APerfiles: TPerfilList);
var
  iIndice: Integer;
begin
  if Assigned(APerfiles) then
  begin
    for iIndice := 0 to APerfiles.Count - 1 do
      GrabarPerfil(
        APerfiles[iIndice].UserGroup,
        APerfiles[iIndice].KeyPerfil,
        APerfiles[iIndice].SubKey,
        APerfiles[iIndice].Value);
  end;
end;

procedure TPerfilesUsuarioFalso.EliminarPerfil(
  const AUsuarioGrupo, AClave, ASubclave: string);
begin
  if ASubclave <> '' then
    FPerfil.Remove(ASubclave)
  else
    FPerfil.Clear;
end;

function TPerfilesUsuarioFalso.ObtenerValorPerfil(
  const AClave, ASubclave, AValorPredeterminado: string): string;
var
  oValor: TDictValue;
begin
  Result := AValorPredeterminado;
  if FPerfil.TryGetValue(ASubclave, oValor) then
    Result := oValor.sValue;
end;

function TPerfilesUsuarioFalso.ObtenerSubclavePerfil(
  const AClave, AValorPredeterminado: string): string;
begin
  Result := AValorPredeterminado;
end;

procedure TPerfilesUsuarioFalso.PrecargarPerfilesUsuario;
begin
end;

function TPerfilesUsuarioFalso.CargarPerfilFormulario(
  const AFormulario: string;
  out APerfil: TProfileDicc): Boolean;
begin
  APerfil := ClonarPerfil;
  Result := True;
end;

function TPerfilesUsuarioFalso.CargarPerfilFormulario(
  const AFormulario, AUsuario, AGrupo: string;
  out APerfil: TProfileDicc): Boolean;
begin
  APerfil := ClonarPerfil;
  Result := True;
end;

procedure TPerfilesUsuarioFalso.ResincronizarPerfilFormulario(
  const AFormulario: string);
begin
end;

procedure TPerfilesUsuarioFalso.InvalidarCachePerfiles;
begin
end;

procedure TPruebasCatalogoSql.SinPerfil_DevuelveSqlBase;
var
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oResultado: TSqlResuelto;
begin
  oDefinicion := DefinicionConsulta('Consultar');
  oCatalogo := TCatalogoSqlPerfiles.Create(nil);
  oResultado := oCatalogo.Resolver(oDefinicion);
  Assert.AreEqual(Ord(osBase), Ord(oResultado.Origen));
  Assert.AreEqual(oDefinicion.SqlBase, oResultado.Texto);
end;

procedure TPruebasCatalogoSql.
  PerfilActivoValido_DevuelvePersonalizacion;
var
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oPerfil: TProfileDicc;
  oResultado: TSqlResuelto;
  oValor: TDictValue;
  sSqlPersonalizado: string;
begin
  oDefinicion := DefinicionConsulta('Consultar');
  sSqlPersonalizado :=
    'SELECT VALOR FROM VISTA WHERE A = :a AND B = :b';
  oValor.sValue := 'S;V=2';
  oValor.sValueText := sSqlPersonalizado;
  oPerfil := TProfileDicc.Create;
  try
    oPerfil.Add(
      ClavePerfilSql(oDefinicion), oValor);
    oCatalogo := TCatalogoSqlPerfiles.Create(oPerfil);
  finally
    FreeAndNil(oPerfil);
  end;
  oResultado := oCatalogo.Resolver(oDefinicion);
  Assert.AreEqual(Ord(osPerfil), Ord(oResultado.Origen));
  Assert.AreEqual(sSqlPersonalizado, oResultado.Texto);
end;

procedure TPruebasCatalogoSql.
  PerfilConParametrosInvalidos_DevuelveSqlBase;
var
  oCatalogo: ICatalogoSql;
  oDefinicion: TDefinicionSql;
  oPerfil: TProfileDicc;
  oResultado: TSqlResuelto;
  oValor: TDictValue;
begin
  oDefinicion := DefinicionConsulta('Consultar');
  oValor.sValue := 'S;V=2';
  oValor.sValueText :=
    'SELECT VALOR FROM VISTA WHERE A = :a';
  oPerfil := TProfileDicc.Create;
  try
    oPerfil.Add(
      ClavePerfilSql(oDefinicion), oValor);
    oCatalogo := TCatalogoSqlPerfiles.Create(oPerfil);
  finally
    FreeAndNil(oPerfil);
  end;
  oResultado := oCatalogo.Resolver(oDefinicion);
  Assert.AreEqual(Ord(osBase), Ord(oResultado.Origen));
  Assert.IsNotEmpty(oResultado.MotivoSqlBase);
end;

procedure TPruebasCatalogoSql.SentenciaPeligrosa_NoEsValida;
var
  oDefinicion: TDefinicionSql;
  oResultado: TResultadoValidacionSql;
begin
  oDefinicion := DefinicionConsulta('Consultar');
  oResultado := ValidarSql(
    oDefinicion,
    'SELECT VALOR FROM TABLA WHERE A = :a AND B = :b; ' +
    'DROP TABLE TABLA');
  Assert.IsFalse(oResultado.EsValido);
end;

procedure TPruebasCatalogoSql.
  Administrador_PublicaSoloLasConsultasQueFaltan;
var
  oAdministrador: TAdministradorSqlPerfiles;
  oDefinicionExistente: TDefinicionSql;
  oDefinicionNueva: TDefinicionSql;
  oDefiniciones: TDefinicionesSql;
  oPerfiles: IPerfilesUsuario;
  oPerfilesObjeto: TPerfilesUsuarioFalso;
  sSqlPersonalizado: string;
begin
  oDefinicionExistente := DefinicionConsulta('Existente');
  oDefinicionNueva := DefinicionConsulta('Nueva');
  SetLength(oDefiniciones, 2);
  oDefiniciones[0] := oDefinicionExistente;
  oDefiniciones[1] := oDefinicionNueva;
  sSqlPersonalizado :=
    'SELECT VALOR FROM VISTA WHERE A = :a AND B = :b';
  oPerfilesObjeto := TPerfilesUsuarioFalso.Create;
  oPerfiles := oPerfilesObjeto;
  oPerfilesObjeto.Definir(
    ClavePerfilSql(oDefinicionExistente),
    'S;V=2',
    sSqlPersonalizado);
  oAdministrador := TAdministradorSqlPerfiles.Create(
    oPerfiles);
  try
    oAdministrador.PublicarFaltantes(
      CLAVE_PERFIL_CATALOGO_SQL,
      oDefiniciones);
    Assert.AreEqual(1, oPerfilesObjeto.Grabaciones);
    Assert.AreEqual(
      sSqlPersonalizado,
      oPerfilesObjeto.Texto(
        ClavePerfilSql(oDefinicionExistente)));
    Assert.AreEqual(
      oDefinicionNueva.SqlBase,
      oPerfilesObjeto.Texto(
        ClavePerfilSql(oDefinicionNueva)));
  finally
    FreeAndNil(oAdministrador);
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TPruebasCatalogoSql);

end.
