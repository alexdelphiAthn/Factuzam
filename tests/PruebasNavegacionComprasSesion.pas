{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasNavegacionComprasSesion                               }
{    Tipo:       Pruebas DUnitX                                                }
{ Version:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Verifica la resolucion de destinos para documentos de una sesion.        }
{******************************************************************************}
unit PruebasNavegacionComprasSesion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasNavegacionComprasSesion = class
  public
    [Test]
    procedure Resolver_ExitoAbreAlbaranConClave;
    [Test]
    procedure Resolver_LimiteIgnoraMayusculasDelTipo;
    [Test]
    procedure Resolver_FalloDistingueSesionSinDocumentos;
    [Test]
    procedure Resolver_FalloRechazaTipoDesconocido;
  end;

implementation

uses
  inMtoComprasSesionesPresentacionNavegacion;

procedure TPruebasNavegacionComprasSesion.
  Resolver_ExitoAbreAlbaranConClave;
var
  Destino: TDestinoDocumentoSesion;
begin
  Destino := ResolverDestinoDocumentoSesion(
    True,
    'ALBC',
    'A',
    '25');
  Assert.AreEqual(Integer(eddsValido), Integer(Destino.Estado));
  Assert.AreEqual('AlbaranesCompra', Destino.Mantenimiento);
  Assert.AreEqual('A,25', Destino.Clave);
end;

procedure TPruebasNavegacionComprasSesion.
  Resolver_LimiteIgnoraMayusculasDelTipo;
var
  Destino: TDestinoDocumentoSesion;
begin
  Destino := ResolverDestinoDocumentoSesion(
    True,
    'pedc',
    'P',
    '7');
  Assert.AreEqual(Integer(eddsValido), Integer(Destino.Estado));
  Assert.AreEqual('PedidosCompra', Destino.Mantenimiento);
end;

procedure TPruebasNavegacionComprasSesion.
  Resolver_FalloDistingueSesionSinDocumentos;
var
  Destino: TDestinoDocumentoSesion;
begin
  Destino := ResolverDestinoDocumentoSesion(False, '', '', '');
  Assert.AreEqual(
    Integer(eddsSinDocumento),
    Integer(Destino.Estado));
end;

procedure TPruebasNavegacionComprasSesion.
  Resolver_FalloRechazaTipoDesconocido;
var
  Destino: TDestinoDocumentoSesion;
begin
  Destino := ResolverDestinoDocumentoSesion(
    True,
    'FACT',
    'F',
    '9');
  Assert.AreEqual(
    Integer(eddsTipoNoDisponible),
    Integer(Destino.Estado));
  Assert.AreEqual('FACT', Destino.Tipo);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasNavegacionComprasSesion);

end.
