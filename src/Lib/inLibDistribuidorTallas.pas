{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDistribuidorTallas                                       }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Registro del ejecutor visual del distribuidor de tallas. La librería      }
{    declara el contrato y la unidad inMto* registra su implementación.        }
{******************************************************************************}
unit inLibDistribuidorTallas;

interface

uses
  System.SysUtils, Uni;

type
  TParametrosDistribuidorTallas = record
    Conexion: TUniConnection;
    Usuario: string;
    TablaCeldas: string;
    CampoSerie: string;
    CampoNumero: string;
    CampoLinea: string;
    CampoFila: string;
    CampoAlmacen: string;
    CampoAtributoValor: string;
    CampoCantidad: string;
    Serie: string;
    Numero: string;
    Linea: Integer;
    IdConjuntoPivot: Integer;
  end;
  TEjecutorDistribuidorTallas = class
  public
    class function Ejecutar(
      const AParametros: TParametrosDistribuidorTallas): Boolean;
      virtual; abstract;
  end;
  TClaseEjecutorDistribuidorTallas = class of TEjecutorDistribuidorTallas;
  TDistribuidorTallas = class
  private
    class var FClaseEjecutor: TClaseEjecutorDistribuidorTallas;
  public
    class procedure RegistrarEjecutor(
      AClase: TClaseEjecutorDistribuidorTallas);
    class function Ejecutar(
      const AParametros: TParametrosDistribuidorTallas): Boolean;
  end;

implementation

uses
  inLibMsgArticulos;

class procedure TDistribuidorTallas.RegistrarEjecutor(
  AClase: TClaseEjecutorDistribuidorTallas);
begin
  FClaseEjecutor := AClase;
end;

class function TDistribuidorTallas.Ejecutar(
  const AParametros: TParametrosDistribuidorTallas): Boolean;
begin
  if not Assigned(FClaseEjecutor) then
    raise Exception.Create(SErrorDistribuidorTallasNoRegistrado);
  Result := FClaseEjecutor.Ejecutar(AParametros);
end;

end.
