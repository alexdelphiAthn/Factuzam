{******************************************************************************}
{                                                                              }
{  Modulo:       inLibComprasSesionesAplicacionIntf                            }
{    Tipo:       Contrato                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Puertos minimos del flujo de materializacion de una sesion de compra.     }
{    No conocen formularios, datasets, UniDAC ni controles visuales.           }
{******************************************************************************}
unit inLibComprasSesionesAplicacionIntf;

interface

uses
  inLibComprasSesionesCreacion,
  inLibComprasSesionesIntf;

type
  TIncidenciasMaterializacionSesion = TArray<string>;

  IOperacionesMaterializacionCompraSesion = interface
    ['{C4647D25-CED5-40B7-B61C-6A354F6073F7}']
    function LeerEstado: TEstadoSesionCreacion;
    procedure GuardarEdicion;
    function NormalizarDuplicados(
      const AEstado: TEstadoSesionCreacion): Integer;
    function Validar(
      out AIncidencias: TIncidenciasMaterializacionSesion): Boolean;
    function CalcularDefectos(
      const AEstado: TEstadoSesionCreacion): TDefectosDialogoCreacion;
    procedure ActualizarCabecera(
      const AAjustes: TAjustesCreacionElegidos);
    function Materializar(
      const AAjustes: TAjustesCreacionElegidos;
      out AResultado: TResultadoMaterializacionSesion): Boolean;
    procedure Refrescar;
  end;

  IVistaMaterializacionCompraSesion = interface
    ['{5866836E-9552-4C01-A621-5152E3930AB4}']
    procedure Registrar(const ATexto: string);
    procedure MostrarBloqueo(AMotivo: TMotivoBloqueoCreacion);
    procedure InformarDuplicados(ACantidad: Integer);
    procedure MostrarIncidencias(
      const AIncidencias: TIncidenciasMaterializacionSesion);
    function SolicitarAjustes(
      const AEstado: TEstadoSesionCreacion;
      const ADefectos: TDefectosDialogoCreacion;
      out AAjustes: TAjustesCreacionElegidos): Boolean;
    procedure MostrarResultado(
      const AResultado: TResultadoMaterializacionSesion);
    procedure MostrarError(const AMensaje: string);
  end;

  IAplicacionMaterializacionCompraSesion = interface
    ['{28997231-E8B7-4DCA-A30C-EA3A570C1D21}']
    procedure Ejecutar;
  end;

implementation

end.
