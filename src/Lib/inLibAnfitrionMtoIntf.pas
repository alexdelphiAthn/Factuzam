{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAnfitrionMtoIntf                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos mínimos entre los mantenimientos y la aplicación anfitriona.    }
{******************************************************************************}
unit inLibAnfitrionMtoIntf;

interface

uses
  System.SysUtils, Winapi.Messages, Vcl.Menus, inLibUnitForm;

const
  WM_FREECONTROL = WM_USER + 1;

type
  // Un servicio del anfitrion que debia estar no esta disponible. El
  // descubrimiento falla ruidosamente (PLAN_SOLID, Fase 4, patron 5.3).
  EServicioNoDisponible = class(Exception);

  IAnfitrionMantenimiento = interface
    ['{545F7B3D-D158-49C2-BC88-537B85F68A13}']
    function ResolverCallPantalla(const AUnidadClase: string): string;
    function ResolverDataModulePantalla(
      const AUnidadClase: string): string;
    procedure CancelarEdicionesPantallas;
    procedure VincularFotoMantenimiento(AMantenimiento: TObject);
  end;

  IProveedorMenuPantallas = interface
    ['{8B43F995-A4C7-483E-8DEB-34D23A85A90C}']
    function MenuAplicacion: TMainMenu;
    function RegistroPantallas: TfzaWinF;
  end;

implementation

end.
