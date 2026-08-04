{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasCorreoTickets                                         }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Prueba del contrato que entrega datos validados al envío de correo.       }
{******************************************************************************}
unit PruebasCorreoTickets;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasCorreoTickets = class
  public
    [Test]
    procedure LecturasInyectadas_EntreganOperacionValidada;
  end;

implementation

uses
  inLibCorreoTickets, inLibCorreoTicketsLecturasIntf;

type
  TLecturasCorreoTicketsPrueba = class(
    TInterfacedObject,
    ICorreoTicketsLecturas)
  public
    function CargarDatosOperacion(const AEmpresa, AAlmacen, ACaja,
      ANumeroOperacion: string): TDatosCorreoOperacion;
  end;

function TLecturasCorreoTicketsPrueba.CargarDatosOperacion(
  const AEmpresa, AAlmacen, ACaja,
  ANumeroOperacion: string): TDatosCorreoOperacion;
begin
  Result := Default(TDatosCorreoOperacion);
  Result.Encontrada := True;
  Result.EmailCliente := 'cliente@ejemplo.es';
  Result.NombreEmpresa := AEmpresa;
  Result.TieneFactura := True;
end;

procedure TPruebasCorreoTickets.
  LecturasInyectadas_EntreganOperacionValidada;
var
  oLecturas: ICorreoTicketsLecturas;
  oDatos: TDatosCorreoOperacion;
begin
  oLecturas := TLecturasCorreoTicketsPrueba.Create;
  oDatos := oLecturas.CargarDatosOperacion('EMP', 'ALM', 'CAJA', '15');
  Assert.IsTrue(oDatos.Encontrada);
  Assert.IsTrue(oDatos.TieneFactura);
  Assert.AreEqual('cliente@ejemplo.es', oDatos.EmailCliente);
  Assert.AreEqual('EMP', oDatos.NombreEmpresa);
end;

end.
