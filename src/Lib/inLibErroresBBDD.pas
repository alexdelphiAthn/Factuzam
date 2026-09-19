{******************************************************************************}
{                                                                              }
{  Módulo:       inLibErroresBBDD                                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       19/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Excepciones de base de datos que distinguen el fallo pasajero del         }
{    fallo del dato, para que quien reintenta sepa a qué atenerse.             }
{******************************************************************************}
unit inLibErroresBBDD;

interface

uses
  System.SysUtils;

type
  { Bloqueo pasajero del motor: espera de bloqueo agotada o interbloqueo
    deshecho por el propio motor. No es un fallo del dato ni de la petición:
    el mismo trabajo sale adelante al repetirlo, así que quien reintenta no
    debe gastar intentos ni dar la operación por perdida. }
  EBloqueoBBDDTemporal = class(Exception)
  private
    FCodigo: Integer;
  public
    constructor Create(ACodigo: Integer;
                       const AMensaje: string); reintroduce;
    property Codigo: Integer read FCodigo;
  end;

{ Códigos de MariaDB/MySQL que solo indican contención entre sesiones.
  1205: se agotó la espera por un bloqueo. 1213: interbloqueo; el motor
  eligió víctima y deshizo su transacción. }
function EsBloqueoTemporalBBDD(ACodigo: Integer): Boolean;

implementation

const
  CEsperaBloqueoAgotada = 1205;
  CInterbloqueo         = 1213;

constructor EBloqueoBBDDTemporal.Create(ACodigo: Integer;
                                        const AMensaje: string);
begin
  inherited Create(AMensaje);
  FCodigo := ACodigo;
end;

function EsBloqueoTemporalBBDD(ACodigo: Integer): Boolean;
begin
  Result := (ACodigo = CEsperaBloqueoAgotada) or
            (ACodigo = CInterbloqueo);
end;

end.
