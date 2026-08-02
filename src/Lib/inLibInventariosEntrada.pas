{******************************************************************************}
{                                                                              }
{  Módulo:       inLibInventariosEntrada                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Decisiones y escritura de la entrada de artículos y SKU en inventarios.  }
{******************************************************************************}
unit inLibInventariosEntrada;

interface

type
  TDecisionEntradaInventario = record
    CodigoUnidad: string;
    CargarStock: Boolean;
    RellenarAtributos: Boolean;
  end;

function ResolverEntradaInventario(
  const ACodigoArticulo, ACodigoSku: string;
  ANumeroAtributos: Integer): TDecisionEntradaInventario;
implementation

function ResolverEntradaInventario(
  const ACodigoArticulo, ACodigoSku: string;
  ANumeroAtributos: Integer): TDecisionEntradaInventario;
begin
  Result.CodigoUnidad := ACodigoArticulo;
  Result.CargarStock := ANumeroAtributos = 0;
  Result.RellenarAtributos := False;
  if ACodigoSku <> '' then
  begin
    Result.CodigoUnidad := ACodigoSku;
    Result.CargarStock := True;
    Result.RellenarAtributos := True;
  end;
end;

end.
