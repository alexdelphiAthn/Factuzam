{******************************************************************************}
{                                                                              }
{  Módulo:       inLibConexionesIntf                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos para obtener y crear conexiones de la aplicación.               }
{******************************************************************************}
unit inLibConexionesIntf;

interface

uses
  System.Classes,
  Uni;

type
  TUsoConexionTrabajo = (
    uctMantenimiento,
    uctPrecarga,
    uctSegundoPlano
  );

  IServicioConexiones = interface
    ['{BB7D3E06-AD0C-4C73-B7A1-D8E19EE1D994}']
    function GetConexionPrincipal: TUniConnection;
    function GetDisponible: Boolean;
    function CrearConexion(
      AOwner: TComponent;
      AUso: TUsoConexionTrabajo
    ): TUniConnection;
    procedure Invalidar;
    property ConexionPrincipal: TUniConnection
      read GetConexionPrincipal;
    property Disponible: Boolean read GetDisponible;
  end;

  IProveedorConexiones = interface
    ['{A2B6D464-97AE-4ED4-9791-9ED38808770A}']
    function GetConexiones: IServicioConexiones;
    property Conexiones: IServicioConexiones read GetConexiones;
  end;

implementation

end.
