{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFacturaePersistencia                                   }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica la fábrica del repositorio Facturae sin acceso a BBDD.           }
{******************************************************************************}
unit PruebasFacturaePersistencia;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFacturaePersistencia = class
  public
    [Test]
    procedure CreadorExplicito_DevuelveRepositorio;
  end;

implementation

uses
  inLibFacturaePersistenciaIntf,
  UniDataFacturaeRepositorio;

procedure TPruebasFacturaePersistencia.
  CreadorExplicito_DevuelveRepositorio;
var
  Repositorio: IRepositorioFacturae;
begin
  Repositorio := CrearRepositorioFacturaeUniDAC(nil);
  Assert.IsTrue(Assigned(Repositorio));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFacturaePersistencia);

end.
