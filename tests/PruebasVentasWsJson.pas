{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasVentasWsJson                                           }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Caracteriza la fachada JSON de ventas mediante una fábrica falsa, sin     }
{    acceso a BBDD.                                                            }
{******************************************************************************}
unit PruebasVentasWsJson;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasVentasWsJson = class
  public
    [TearDown]
    procedure Liberar;
    [Test]
    procedure ConstruirEvento_DelegaTodosLosParametros;
    [Test]
    procedure FabricaAusente_FallaDeFormaRuidosa;
  end;

implementation

uses
  System.SysUtils, Uni, inLibParametrosIntf,
  inLibVentasWsJsonIntf, inLibVentasWsJson,
  UniDataVentasWsJson;

type
  TVentasWsJsonFalso = class(TInterfacedObject, IVentasWsJson)
  public
    Empresa: string;
    IdCola: Int64;
    IdEvento: string;
    Numero: string;
    Serie: string;
    TipoEvento: string;
    VersionApp: string;
    function ConstruirEvento(
      const AParametrosApp: IParametrosAplicacion;
      const AVersionApp: string;
      AIdCola: Int64;
      const AIdEvento, ATipoEvento, AEmpresa,
        ASerie, ANumero: string): string;
  end;

var
  oServicioFalso: IVentasWsJson;
  oFalso: TVentasWsJsonFalso;

function TVentasWsJsonFalso.ConstruirEvento(
  const AParametrosApp: IParametrosAplicacion;
  const AVersionApp: string;
  AIdCola: Int64;
  const AIdEvento, ATipoEvento, AEmpresa,
    ASerie, ANumero: string): string;
begin
  VersionApp := AVersionApp;
  IdCola := AIdCola;
  IdEvento := AIdEvento;
  TipoEvento := ATipoEvento;
  Empresa := AEmpresa;
  Serie := ASerie;
  Numero := ANumero;
  Result := '{"resultado":"falso"}';
end;

function FabricaFalsa(
  AConexion: TUniConnection): IVentasWsJson;
begin
  Result := oServicioFalso;
end;

procedure PrepararFabricaFalsa;
begin
  oFalso := TVentasWsJsonFalso.Create;
  oServicioFalso := oFalso;
  TFabricaVentasWsJson.Registrar(FabricaFalsa);
end;

procedure TPruebasVentasWsJson.Liberar;
begin
  TFabricaVentasWsJson.Registrar(CrearVentasWsJsonUniDAC);
  oServicioFalso := nil;
  oFalso := nil;
end;

procedure TPruebasVentasWsJson.
  ConstruirEvento_DelegaTodosLosParametros;
var
  Json: string;
begin
  PrepararFabricaFalsa;
  Json := TVentasWsJson.ConstruirEvento(
    nil, '37.0', nil, 42, 'EV-42', 'VENTA',
    'EMP', 'FS', '1001');
  Assert.AreEqual('{"resultado":"falso"}', Json);
  Assert.AreEqual('37.0', oFalso.VersionApp);
  Assert.AreEqual(Int64(42), oFalso.IdCola);
  Assert.AreEqual('EV-42', oFalso.IdEvento);
  Assert.AreEqual('VENTA', oFalso.TipoEvento);
  Assert.AreEqual('EMP', oFalso.Empresa);
  Assert.AreEqual('FS', oFalso.Serie);
  Assert.AreEqual('1001', oFalso.Numero);
end;

procedure TPruebasVentasWsJson.
  FabricaAusente_FallaDeFormaRuidosa;
begin
  TFabricaVentasWsJson.Registrar(nil);
  Assert.WillRaise(
    procedure
    begin
      TVentasWsJson.ConstruirEvento(
        nil, '37.0', nil, 43, 'EV-43', 'VENTA',
        'EMP', 'FS', '1002');
    end,
    Exception);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasVentasWsJson);

end.
