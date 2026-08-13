{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPermisosIntf                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos y estructuras del sistema de permisos de la aplicación.         }
{******************************************************************************}
unit inLibPermisosIntf;

interface

type
  TPermisoAusente = (
    paPermitir,
    paDenegar
  );

  TOrigenPermiso = (
    opAdministrador,
    opUsuario,
    opGrupo,
    opTodos,
    opNoDefinido,
    opNoDisponible
  );

  TAccionPermisoMto = (
    apmConsultar,
    apmInsertar,
    apmModificar,
    apmBorrar,
    apmExcel,
    apmImprimir
  );

  TIdentidadPermisos = record
    Usuario        : string;
    Grupo          : string;
    EsAdministrador: Boolean;
    class function Crear(const AUsuario, AGrupo: string;
                         AEsAdministrador: Boolean): TIdentidadPermisos;
                         static;
  end;

  TReglaPermiso = record
    Sujeto   : string;
    Codigo   : string;
    Permitido: Boolean;
    class function Crear(const ASujeto, ACodigo: string;
                         APermitido: Boolean): TReglaPermiso; static;
  end;

  TResultadoPermiso = record
    Codigo   : string;
    Permitido: Boolean;
    Origen   : TOrigenPermiso;
  end;

  IPermisosAplicacion = interface
    ['{DDB43751-6161-495F-B70F-EACE1D1735E3}']
    function GetDisponible: Boolean;
    function Evaluar(const ACodigo: string;
                     APermisoAusente: TPermisoAusente): TResultadoPermiso;
    function TienePermiso(const ACodigo: string;
                          APermisoAusente: TPermisoAusente): Boolean;
    property Disponible: Boolean read GetDisponible;
  end;

  TContextoAutorizacionPantalla = record
  private
    FPermisos: IPermisosAplicacion;
  public
    class function Crear(
      const APermisos: IPermisosAplicacion
    ): TContextoAutorizacionPantalla; static;
    property Permisos: IPermisosAplicacion read FPermisos;
  end;

  IProveedorPermisosAplicacion = interface
    ['{5405FD8F-CE72-47B0-B512-E520B0B8B7AB}']
    function GetPermisos: IPermisosAplicacion;
    property Permisos: IPermisosAplicacion read GetPermisos;
  end;

const
  PERMISO_CAJA_CAMBIAR_FECHA = 'caja.cambiarFecha';
  PERMISO_CAJA_VER_COSTE = 'caja.verCoste';
  PERMISO_CAJA_ABRIR_CAJON = 'caja.abrirCajon';
  PERMISO_ARQUEO_VER_RESUMEN = 'arqueo.verResumen';
  PERMISO_ARQUEO_VER_IMPORTES = 'arqueo.verImportes';
  PERMISO_ARTICULOS_ACTIVAR_DESACTIVAR_WEB =
    'articulos.activarDesactivarWeb';

function CodigoPermisoMto(const ACall: string;
                           AAccion: TAccionPermisoMto): string;

implementation

uses
  System.SysUtils;

class function TContextoAutorizacionPantalla.Crear(
  const APermisos: IPermisosAplicacion): TContextoAutorizacionPantalla;
begin
  Result.FPermisos := APermisos;
end;

class function TIdentidadPermisos.Crear(
  const AUsuario, AGrupo: string;
  AEsAdministrador: Boolean): TIdentidadPermisos;
begin
  Result.Usuario := Trim(AUsuario);
  Result.Grupo := Trim(AGrupo);
  Result.EsAdministrador := AEsAdministrador;
end;

class function TReglaPermiso.Crear(
  const ASujeto, ACodigo: string;
  APermitido: Boolean): TReglaPermiso;
begin
  Result.Sujeto := Trim(ASujeto);
  Result.Codigo := Trim(ACodigo);
  Result.Permitido := APermitido;
end;

function CodigoPermisoMto(const ACall: string;
                           AAccion: TAccionPermisoMto): string;
const
  SUFIJOS: array[TAccionPermisoMto] of string = (
    'consultar',
    'insertar',
    'modificar',
    'borrar',
    'excel',
    'imprimir'
  );
begin
  Result := Trim(ACall) + '.' + SUFIJOS[AAccion];
end;

end.
