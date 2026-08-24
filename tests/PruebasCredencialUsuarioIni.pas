{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasCredencialUsuarioIni                                  }
{    Tipo:       Pruebas                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Prueba la protección DPAPI y la migración de PasswordEn del usuario.      }
{******************************************************************************}
unit PruebasCredencialUsuarioIni;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasCredencialUsuarioIni = class
  public
    [Test]
    procedure DPAPIProtegeParaUsuarioActual;
    [Test]
    procedure GuardaPasswordDpapiSinTextoPlano;
    [Test]
    procedure MigraPasswordEnDespuesDeVerificarDpapi;
    [Test]
    procedure RecuperaDpapiInvalidoDesdePasswordEn;
    [Test]
    procedure ConservaPasswordEnInvalido;
    [Test]
    procedure BorradoExplicitoRetiraAmbasClaves;
  end;

implementation

uses
  System.IniFiles,
  System.IOUtils,
  System.SysUtils,
  inLibCifrado,
  inLibCredencialUsuarioIni,
  inLibProteccionCredenciales;

const
  CONTRASENA_PRUEBA = 'Clave funcional #2026';

function CrearRutaIniTemporal: string;
var
  oId: TGUID;
  sDirectorio: string;
begin
  CreateGUID(oId);
  sDirectorio := TPath.Combine(
    TPath.GetTempPath,
    'factuzam_usuario_' + GUIDToString(oId));
  TDirectory.CreateDirectory(sDirectorio);
  Result := TPath.Combine(sDirectorio, 'factuzam.ini');
end;

procedure EliminarIniTemporal(const ARutaIni: string);
var
  sDirectorio: string;
begin
  sDirectorio := ExtractFileDir(ARutaIni);
  if TDirectory.Exists(sDirectorio) and
    sDirectorio.StartsWith(TPath.GetTempPath, True) then
  begin
    TDirectory.Delete(sDirectorio, True);
  end;
end;

procedure TPruebasCredencialUsuarioIni.DPAPIProtegeParaUsuarioActual;
var
  sProtegido: string;
begin
  sProtegido := ProtegerSecretoUsuario(CONTRASENA_PRUEBA);

  Assert.IsNotEmpty(sProtegido);
  Assert.AreNotEqual(CONTRASENA_PRUEBA, sProtegido);
  Assert.IsFalse(sProtegido.Contains(#13));
  Assert.IsFalse(sProtegido.Contains(#10));
  Assert.AreEqual(
    CONTRASENA_PRUEBA,
    DesprotegerSecretoUsuario(sProtegido));
end;

procedure TPruebasCredencialUsuarioIni.GuardaPasswordDpapiSinTextoPlano;
var
  oIni: TIniFile;
  sContenido: string;
  sProtegido: string;
  sRutaIni: string;
begin
  sRutaIni := CrearRutaIniTemporal;
  try
    GuardarContrasenaUsuarioRecordada(sRutaIni, CONTRASENA_PRUEBA);
    oIni := TIniFile.Create(sRutaIni);
    try
      sProtegido := oIni.ReadString(
        'UserInfo',
        'PasswordDpapi',
        '');
      Assert.IsFalse(oIni.ValueExists('UserInfo', 'PasswordEn'));
    finally
      FreeAndNil(oIni);
    end;
    Assert.AreEqual(
      CONTRASENA_PRUEBA,
      DesprotegerSecretoUsuario(sProtegido));
    Assert.AreEqual(
      CONTRASENA_PRUEBA,
      CargarContrasenaUsuarioRecordada(sRutaIni));
    sContenido := TFile.ReadAllText(sRutaIni, TEncoding.UTF8);
    Assert.IsFalse(sContenido.Contains(CONTRASENA_PRUEBA));
  finally
    EliminarIniTemporal(sRutaIni);
  end;
end;

procedure TPruebasCredencialUsuarioIni.
  MigraPasswordEnDespuesDeVerificarDpapi;
var
  oIni: TIniFile;
  sProtegido: string;
  sRutaIni: string;
begin
  sRutaIni := CrearRutaIniTemporal;
  try
    oIni := TIniFile.Create(sRutaIni);
    try
      oIni.WriteString(
        'UserInfo',
        'PasswordEn',
        CifrarAES(CONTRASENA_PRUEBA));
      oIni.UpdateFile;
    finally
      FreeAndNil(oIni);
    end;

    Assert.AreEqual(
      CONTRASENA_PRUEBA,
      CargarContrasenaUsuarioRecordada(sRutaIni));
    oIni := TIniFile.Create(sRutaIni);
    try
      Assert.IsFalse(oIni.ValueExists('UserInfo', 'PasswordEn'));
      sProtegido := oIni.ReadString(
        'UserInfo',
        'PasswordDpapi',
        '');
    finally
      FreeAndNil(oIni);
    end;
    Assert.AreEqual(
      CONTRASENA_PRUEBA,
      DesprotegerSecretoUsuario(sProtegido));
  finally
    EliminarIniTemporal(sRutaIni);
  end;
end;

procedure TPruebasCredencialUsuarioIni.
  RecuperaDpapiInvalidoDesdePasswordEn;
var
  oIni: TIniFile;
  sProtegido: string;
  sRutaIni: string;
begin
  sRutaIni := CrearRutaIniTemporal;
  try
    oIni := TIniFile.Create(sRutaIni);
    try
      oIni.WriteString(
        'UserInfo',
        'PasswordDpapi',
        'DpapiInvalido');
      oIni.WriteString(
        'UserInfo',
        'PasswordEn',
        CifrarAES(CONTRASENA_PRUEBA));
      oIni.UpdateFile;
    finally
      FreeAndNil(oIni);
    end;

    Assert.AreEqual(
      CONTRASENA_PRUEBA,
      CargarContrasenaUsuarioRecordada(sRutaIni));
    oIni := TIniFile.Create(sRutaIni);
    try
      Assert.IsFalse(oIni.ValueExists('UserInfo', 'PasswordEn'));
      sProtegido := oIni.ReadString(
        'UserInfo',
        'PasswordDpapi',
        '');
    finally
      FreeAndNil(oIni);
    end;
    Assert.AreEqual(
      CONTRASENA_PRUEBA,
      DesprotegerSecretoUsuario(sProtegido));
  finally
    EliminarIniTemporal(sRutaIni);
  end;
end;

procedure TPruebasCredencialUsuarioIni.ConservaPasswordEnInvalido;
const
  CIFRADO_INVALIDO = 'PasswordEnInvalido';
var
  oIni: TIniFile;
  sRutaIni: string;
begin
  sRutaIni := CrearRutaIniTemporal;
  try
    oIni := TIniFile.Create(sRutaIni);
    try
      oIni.WriteString(
        'UserInfo',
        'PasswordEn',
        CIFRADO_INVALIDO);
      oIni.UpdateFile;
    finally
      FreeAndNil(oIni);
    end;

    Assert.WillRaise(
      procedure
      begin
        CargarContrasenaUsuarioRecordada(sRutaIni);
      end,
      EConvertError);
    oIni := TIniFile.Create(sRutaIni);
    try
      Assert.AreEqual(
        CIFRADO_INVALIDO,
        oIni.ReadString('UserInfo', 'PasswordEn', ''));
      Assert.IsFalse(oIni.ValueExists('UserInfo', 'PasswordDpapi'));
    finally
      FreeAndNil(oIni);
    end;
  finally
    EliminarIniTemporal(sRutaIni);
  end;
end;

procedure TPruebasCredencialUsuarioIni.
  BorradoExplicitoRetiraAmbasClaves;
var
  oIni: TIniFile;
  sRutaIni: string;
begin
  sRutaIni := CrearRutaIniTemporal;
  try
    GuardarContrasenaUsuarioRecordada(sRutaIni, CONTRASENA_PRUEBA);
    oIni := TIniFile.Create(sRutaIni);
    try
      oIni.WriteString(
        'UserInfo',
        'PasswordEn',
        CifrarAES(CONTRASENA_PRUEBA));
      oIni.UpdateFile;
    finally
      FreeAndNil(oIni);
    end;

    EliminarContrasenaUsuarioRecordada(sRutaIni);
    oIni := TIniFile.Create(sRutaIni);
    try
      Assert.IsFalse(oIni.ValueExists('UserInfo', 'PasswordDpapi'));
      Assert.IsFalse(oIni.ValueExists('UserInfo', 'PasswordEn'));
    finally
      FreeAndNil(oIni);
    end;
  finally
    EliminarIniTemporal(sRutaIni);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasCredencialUsuarioIni);

end.
