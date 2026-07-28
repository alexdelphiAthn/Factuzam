{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFiltroUsuario                                          }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de la restricción de documentos por empresa, almacén y caja.      }
{******************************************************************************}
unit PruebasFiltroUsuario;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFiltroUsuario = class
  public
    [Test]
    procedure Documento_DerivaEmpresaYAlmacen;
    [Test]
    procedure Factura_IncluyeCajaYToleraNulos;
    [Test]
    procedure Documento_InactivoNoFiltra;
    [Test]
    procedure Documento_AdminNoFiltra;
    [Test]
    procedure Documento_OmiteUbicacionesVacias;
  end;

implementation

uses
  System.SysUtils, inLibContextoSesionIntf, inLibContextoSesion,
  inLibParametrosIntf, inLibLicenciaAplicacion, inLibFiltroUsuario;

type
  TParametrosFiltroPrueba = class(
    TInterfacedObject,
    IParametros,
    IParametrosAplicacion
  )
  private
    FActivo: Boolean;
    function GetString(
      const AKey: string;
      const ADefault: string = ''
    ): string;
    function GetBool(
      const AKey: string;
      const ADefault: Boolean = False
    ): Boolean;
    function GetInt(
      const AKey: string;
      const ADefault: Integer = 0
    ): Integer;
    function GetPath(const ANombre: string): string;
    function Licencia: TResultadoLicenciaAplicacion;
  public
    constructor Create(AActivo: Boolean);
  end;

constructor TParametrosFiltroPrueba.Create(AActivo: Boolean);
begin
  inherited Create;
  FActivo := AActivo;
end;

function TParametrosFiltroPrueba.GetString(
  const AKey, ADefault: string): string;
begin
  Result := ADefault;
end;

function TParametrosFiltroPrueba.GetBool(
  const AKey: string; const ADefault: Boolean): Boolean;
begin
  if SameText(AKey, 'appRestringirEmpAlmCaja') then
    Result := FActivo
  else
    Result := ADefault;
end;

function TParametrosFiltroPrueba.GetInt(
  const AKey: string; const ADefault: Integer): Integer;
begin
  Result := ADefault;
end;

function TParametrosFiltroPrueba.GetPath(
  const ANombre: string): string;
begin
  Result := '';
end;

function TParametrosFiltroPrueba.Licencia:
  TResultadoLicenciaAplicacion;
begin
  Result := TResultadoLicenciaAplicacion.CrearNoComprobada;
end;

procedure TPruebasFiltroUsuario.Documento_DerivaEmpresaYAlmacen;
var
  oContexto: IContextoSesionAplicacion;
  oParametros: IParametrosAplicacion;
begin
  oContexto := TContextoSesionAplicacion.Create(
    TIdentidadSesion.Crear('USUARIO', 'VENTAS', 'N'),
    TUbicacionSesion.Crear('012', 'GEN', '1'));
  oParametros := TParametrosFiltroPrueba.Create(True);
  Assert.AreEqual(
    ' AND (CODIGO_EMP_PEDC = ''012'' OR ' +
    'CODIGO_EMP_PEDC IS NULL)' +
    ' AND (CODIGO_ALM_PEDC = ''GEN'' OR ' +
    'CODIGO_ALM_PEDC IS NULL)',
    SqlFiltroDocumento(oContexto, oParametros, 'PEDC'));
end;

procedure TPruebasFiltroUsuario.Factura_IncluyeCajaYToleraNulos;
var
  oContexto: IContextoSesionAplicacion;
  oParametros: IParametrosAplicacion;
begin
  oContexto := TContextoSesionAplicacion.Create(
    TIdentidadSesion.Crear('USUARIO', 'VENTAS', 'N'),
    TUbicacionSesion.Crear('012', 'GEN', '1'));
  oParametros := TParametrosFiltroPrueba.Create(True);
  Assert.AreEqual(
    ' AND (CODIGO_EMP_FAC = ''012'' OR ' +
    'CODIGO_EMP_FAC IS NULL)' +
    ' AND (CODIGO_ALM_FAC = ''GEN'' OR ' +
    'CODIGO_ALM_FAC IS NULL)' +
    ' AND (CODIGO_CAJA_FAC = ''1'' OR ' +
    'CODIGO_CAJA_FAC IS NULL)',
    SqlFiltroDocumento(
      oContexto, oParametros, 'FAC', True));
end;

procedure TPruebasFiltroUsuario.Documento_InactivoNoFiltra;
var
  oContexto: IContextoSesionAplicacion;
  oParametros: IParametrosAplicacion;
begin
  oContexto := TContextoSesionAplicacion.Create(
    TIdentidadSesion.Crear('USUARIO', 'VENTAS', 'N'),
    TUbicacionSesion.Crear('012', 'GEN', '1'));
  oParametros := TParametrosFiltroPrueba.Create(False);
  Assert.AreEqual(
    '', SqlFiltroDocumento(oContexto, oParametros, 'INV'));
end;

procedure TPruebasFiltroUsuario.Documento_AdminNoFiltra;
var
  oContexto: IContextoSesionAplicacion;
  oParametros: IParametrosAplicacion;
begin
  oContexto := TContextoSesionAplicacion.Create(
    TIdentidadSesion.Crear('ADMIN', 'ADMINISTRADORES', 'S'),
    TUbicacionSesion.Crear('012', 'GEN', '1'));
  oParametros := TParametrosFiltroPrueba.Create(True);
  Assert.AreEqual(
    '', SqlFiltroDocumento(oContexto, oParametros, 'ALB'));
end;

procedure TPruebasFiltroUsuario.Documento_OmiteUbicacionesVacias;
var
  oContexto: IContextoSesionAplicacion;
  oParametros: IParametrosAplicacion;
begin
  oContexto := TContextoSesionAplicacion.Create(
    TIdentidadSesion.Crear('USUARIO', 'VENTAS', 'N'),
    TUbicacionSesion.Crear('012', '', ''));
  oParametros := TParametrosFiltroPrueba.Create(True);
  Assert.AreEqual(
    ' AND (CODIGO_EMP_DEVC = ''012'' OR ' +
    'CODIGO_EMP_DEVC IS NULL)',
    SqlFiltroDocumento(oContexto, oParametros, 'DEVC'));
end;

end.
