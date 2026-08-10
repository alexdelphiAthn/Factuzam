{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasImportacionPedidoOcr                                   }
{    Tipo:       Pruebas DUnitX                                                }
{ Version:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Verifica el contrato de salida de la importacion OCR para el caso         }
{    correcto, el limite de lineas sin codigo y los fallos no fatales.         }
{******************************************************************************}
unit PruebasImportacionPedidoOcr;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasImportacionPedidoOcr = class
  public
    [Test]
    procedure Formatear_ExitoIncluyeContadores;
    [Test]
    procedure Formatear_LimiteIncluyeLineasSinCodigo;
    [Test]
    procedure Formatear_FalloNoFatalIncluyeAdvertencia;
  end;

implementation

uses
  System.SysUtils,
  inMtoComprasSesionesPresentacionImportacionOcr;

procedure TPruebasImportacionPedidoOcr.
  Formatear_ExitoIncluyeContadores;
var
  Resultado: TResultadoImportacionPedidoOcr;
begin
  Resultado := Default(TResultadoImportacionPedidoOcr);
  Resultado.Lineas := 3;
  Resultado.Fotos := 2;
  Resultado.Paginas := 4;
  Assert.AreEqual(
    'Pedido importado: 3 líneas, 2 fotos y 4 páginas TIFF.',
    FormatearResultadoImportacionPedidoOcr(Resultado));
end;

procedure TPruebasImportacionPedidoOcr.
  Formatear_LimiteIncluyeLineasSinCodigo;
var
  Resultado: TResultadoImportacionPedidoOcr;
  sMensaje: string;
begin
  Resultado := Default(TResultadoImportacionPedidoOcr);
  Resultado.Lineas := 2;
  Resultado.LineasSinCodigo := 2;
  sMensaje := FormatearResultadoImportacionPedidoOcr(Resultado);
  Assert.IsTrue(Pos(
    '2 líneas quedan pendientes de familia y código interno.',
    sMensaje) > 0);
end;

procedure TPruebasImportacionPedidoOcr.
  Formatear_FalloNoFatalIncluyeAdvertencia;
var
  Resultado: TResultadoImportacionPedidoOcr;
  sMensaje: string;
begin
  Resultado := Default(TResultadoImportacionPedidoOcr);
  Resultado.Lineas := 1;
  Resultado.Advertencias :=
    'Fotos del pedido: almacenamiento no disponible';
  sMensaje := FormatearResultadoImportacionPedidoOcr(Resultado);
  Assert.IsTrue(Pos('Advertencias:', sMensaje) > 0);
  Assert.IsTrue(Pos(Resultado.Advertencias, sMensaje) > 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasImportacionPedidoOcr);

end.
