{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasNuevoEquipo                                            }
{    Tipo:       Pruebas                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Pruebas puras del conmutador secreto y de su contrasena inicial.          }
{******************************************************************************}
unit PruebasNuevoEquipo;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasNuevoEquipo = class
  public
    [Test]
    procedure ReconoceConmutadorNormalizado;
    [Test]
    procedure RechazaParametrosDistintos;
    [Test]
    procedure ExaminaTodosLosParametros;
    [Test]
    procedure ExigePerfilIniEnPrimeraPosicion;
    [Test]
    procedure ConservaPendienteHastaCompletarlo;
    [Test]
    procedure LimitaMarcaPendienteAlPerfilDemoLocal;
    [Test]
    procedure DefineUsuarioInicial;
    [Test]
    procedure ValidaLongitudContrasenaNueva;
    [Test]
    procedure ElevaExcepcionParaContrasenaNoValida;
  end;

implementation

uses
  System.IniFiles,
  System.IOUtils,
  System.SysUtils,
  inLibNuevoEquipo;

const
  MARCA_INSTALADOR_PRUEBA =
    '22A7FC7BE67DDBA5B97E0F66E2BA8AE67545348464C618ABAE2020AB54EC3103';

function CrearRutaIniTemporal: string;
var
  oId: TGUID;
  sDirectorio: string;
begin
  CreateGUID(oId);
  sDirectorio := TPath.Combine(
    TPath.GetTempPath,
    'factuzam_nuevo_equipo_' + GUIDToString(oId));
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

procedure TPruebasNuevoEquipo.ReconoceConmutadorNormalizado;
begin
  Assert.IsTrue(EsConmutadorNuevoEquipo('/NEWCOMPUTER'));
  Assert.IsTrue(EsConmutadorNuevoEquipo('-newcomputer'));
  Assert.IsTrue(EsConmutadorNuevoEquipo('  /NewComputer  '));
  Assert.IsTrue(EsConmutadorNuevoEquipo('--/NEWCOMPUTER'));
end;

procedure TPruebasNuevoEquipo.RechazaParametrosDistintos;
begin
  Assert.IsFalse(EsConmutadorNuevoEquipo(''));
  Assert.IsFalse(EsConmutadorNuevoEquipo('NEWCOMPUTER'));
  Assert.IsFalse(EsConmutadorNuevoEquipo('/NEWCOMPUTERS'));
  Assert.IsFalse(EsConmutadorNuevoEquipo('/NEWCOMPUTER=SI'));
  Assert.IsFalse(EsConmutadorNuevoEquipo('/SETMAJORLICENSE'));
end;

procedure TPruebasNuevoEquipo.ExigePerfilIniEnPrimeraPosicion;
begin
  Assert.IsTrue(EsOrdenParametrosNuevoEquipoValido(
    ['/NEWCOMPUTER']));
  Assert.IsTrue(EsOrdenParametrosNuevoEquipoValido(
    ['cliente.ini', '/NEWCOMPUTER']));
  Assert.IsTrue(EsOrdenParametrosNuevoEquipoValido(
    ['/OTRO', '/NEWCOMPUTER']));
  Assert.IsFalse(EsOrdenParametrosNuevoEquipoValido(
    ['/NEWCOMPUTER', 'cliente.ini']));
  Assert.IsFalse(EsOrdenParametrosNuevoEquipoValido(
    ['cliente.ini', '/NEWCOMPUTER', 'otro.ini']));
end;

procedure TPruebasNuevoEquipo.ConservaPendienteHastaCompletarlo;
var
  oIni: TIniFile;
  sRutaIni: string;
begin
  sRutaIni := CrearRutaIniTemporal;
  try
    Assert.IsFalse(HayNuevoEquipoPendienteEnIni(sRutaIni));
    oIni := TIniFile.Create(sRutaIni);
    try
      oIni.WriteString(
        'Installation',
        'NewComputerPending',
        'Yes');
      oIni.UpdateFile;
    finally
      oIni.Free;
    end;
    Assert.IsFalse(HayNuevoEquipoPendienteEnIni(sRutaIni));
    oIni := TIniFile.Create(sRutaIni);
    try
      oIni.WriteString(
        'Installation',
        'NewComputerPending',
        MARCA_INSTALADOR_PRUEBA);
      oIni.UpdateFile;
    finally
      oIni.Free;
    end;
    Assert.IsTrue(HayNuevoEquipoPendienteEnIni(sRutaIni));

    CompletarNuevoEquipoPendienteEnIni(sRutaIni);

    Assert.IsFalse(HayNuevoEquipoPendienteEnIni(sRutaIni));
  finally
    EliminarIniTemporal(sRutaIni);
  end;
end;

procedure TPruebasNuevoEquipo.LimitaMarcaPendienteAlPerfilDemoLocal;
begin
  Assert.IsTrue(EsPerfilInstalacionDemoLocal(
    '127.0.0.1', 'factuzam', 'root', 3310));
  Assert.IsFalse(EsPerfilInstalacionDemoLocal(
    'servidor-cliente', 'factuzam', 'root', 3310));
  Assert.IsFalse(EsPerfilInstalacionDemoLocal(
    '127.0.0.1', 'cliente', 'root', 3310));
  Assert.IsFalse(EsPerfilInstalacionDemoLocal(
    '127.0.0.1', 'factuzam', 'root', 3306));
end;

procedure TPruebasNuevoEquipo.ExaminaTodosLosParametros;
begin
  Assert.IsTrue(HayConmutadorNuevoEquipo(
    ['primero', '/OTRO', '/NEWCOMPUTER', 'ultimo']));
  Assert.IsTrue(HayConmutadorNuevoEquipo(
    ['/NEWCOMPUTER', 'segundo']));
  Assert.IsFalse(HayConmutadorNuevoEquipo(
    ['primero', '/OTRO', 'ultimo']));
  Assert.IsFalse(HayConmutadorNuevoEquipo([]));
end;

procedure TPruebasNuevoEquipo.DefineUsuarioInicial;
begin
  Assert.AreEqual('Administrador', USUARIO_INICIAL_NUEVO_EQUIPO);
end;

procedure TPruebasNuevoEquipo.ValidaLongitudContrasenaNueva;
begin
  Assert.IsFalse(EsContrasenaNuevoEquipoValida(''));
  Assert.IsTrue(EsContrasenaNuevoEquipoValida('nueva'));
  Assert.IsTrue(EsContrasenaNuevoEquipoValida(
    StringOfChar('x', LONGITUD_MAXIMA_CONTRASENA_NUEVO_EQUIPO)));
  Assert.IsFalse(EsContrasenaNuevoEquipoValida(
    StringOfChar('x', LONGITUD_MAXIMA_CONTRASENA_NUEVO_EQUIPO + 1)));
end;

procedure TPruebasNuevoEquipo.ElevaExcepcionParaContrasenaNoValida;
begin
  Assert.WillRaise(
    procedure
    begin
      ValidarContrasenaNuevoEquipo('');
    end,
    EContrasenaNuevoEquipoNoValida);
  Assert.WillRaise(
    procedure
    begin
      ValidarContrasenaNuevoEquipo(
        StringOfChar(
          'x',
          LONGITUD_MAXIMA_CONTRASENA_NUEVO_EQUIPO + 1));
    end,
    EContrasenaNuevoEquipoNoValida);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasNuevoEquipo);

end.
