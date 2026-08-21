{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCambioArticuloColorIntf                                  }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos para recodificar artículos o colores de forma atómica.          }
{******************************************************************************}
unit inLibCambioArticuloColorIntf;

interface

type
  TMotivoCambioArticuloColor = (
    mcacNinguno,
    mcacDatosInvalidos,
    mcacOrigenNoExiste,
    mcacDestinoYaExiste,
    mcacExistenVentas,
    mcacColisionUnidades,
    mcacDatosInconsistentes,
    mcacIntegracionExterna
  );

  TResultadoCambioArticuloColor = record
    Motivo: TMotivoCambioArticuloColor;
    UnidadesAfectadas: Integer;
    Detalle: string;
    class function Correcto(AUnidadesAfectadas: Integer):
      TResultadoCambioArticuloColor; static;
    class function Error(
      AMotivo: TMotivoCambioArticuloColor;
      const ADetalle: string = ''): TResultadoCambioArticuloColor; static;
    function EsCorrecto: Boolean;
  end;

  IRepositorioCambioArticuloColor = interface
    ['{DFC346E3-FDE9-4882-8B90-E561B74AA4DA}']
    function CambiarArticulo(
      const AArticuloAntiguo, AArticuloNuevo, AUsuario: string):
      TResultadoCambioArticuloColor;
    function FusionarArticulo(
      const AArticuloAntiguo, AArticuloDestino, AUsuario: string):
      TResultadoCambioArticuloColor;
    function CambiarColor(
      const AColorAntiguo, AColorNuevo, AUsuario: string):
      TResultadoCambioArticuloColor;
    function FusionarColor(
      const AColorAntiguo, AColorDestino, AUsuario: string):
      TResultadoCambioArticuloColor;
  end;

  IServicioCambioArticuloColor = interface
    ['{A38540C9-98D0-4882-82B9-761869791D92}']
    function CambiarArticulo(
      const AArticuloAntiguo, AArticuloNuevo, AUsuario: string):
      TResultadoCambioArticuloColor;
    function FusionarArticulo(
      const AArticuloAntiguo, AArticuloDestino, AUsuario: string):
      TResultadoCambioArticuloColor;
    function CambiarColor(
      const AColorAntiguo, AColorNuevo, AUsuario: string):
      TResultadoCambioArticuloColor;
    function FusionarColor(
      const AColorAntiguo, AColorDestino, AUsuario: string):
      TResultadoCambioArticuloColor;
  end;

implementation

class function TResultadoCambioArticuloColor.Correcto(
  AUnidadesAfectadas: Integer): TResultadoCambioArticuloColor;
begin
  Result.Motivo := mcacNinguno;
  Result.UnidadesAfectadas := AUnidadesAfectadas;
  Result.Detalle := '';
end;

class function TResultadoCambioArticuloColor.Error(
  AMotivo: TMotivoCambioArticuloColor;
  const ADetalle: string): TResultadoCambioArticuloColor;
begin
  Result.Motivo := AMotivo;
  Result.UnidadesAfectadas := 0;
  Result.Detalle := ADetalle;
end;

function TResultadoCambioArticuloColor.EsCorrecto: Boolean;
begin
  Result := Motivo = mcacNinguno;
end;

end.
