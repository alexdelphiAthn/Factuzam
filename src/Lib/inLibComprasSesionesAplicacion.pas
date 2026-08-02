{******************************************************************************}
{                                                                              }
{  Modulo:       inLibComprasSesionesAplicacion                                }
{    Tipo:       Aplicacion                                                    }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Orquesta la materializacion de sesiones de compra mediante puertos        }
{    independientes de VCL y de la persistencia.                               }
{******************************************************************************}
unit inLibComprasSesionesAplicacion;

interface

uses
  inLibComprasSesionesAplicacionIntf;

function CrearAplicacionMaterializacionCompraSesion(
  const AOperaciones: IOperacionesMaterializacionCompraSesion;
  const AVista: IVistaMaterializacionCompraSesion):
  IAplicacionMaterializacionCompraSesion;

implementation

uses
  System.SysUtils,
  inLibComprasSesionesCreacion,
  inLibComprasSesionesIntf;

type
  TAplicacionMaterializacionCompraSesion = class(
    TInterfacedObject,
    IAplicacionMaterializacionCompraSesion)
  private
    FOperaciones: IOperacionesMaterializacionCompraSesion;
    FVista: IVistaMaterializacionCompraSesion;
  public
    constructor Create(
      const AOperaciones: IOperacionesMaterializacionCompraSesion;
      const AVista: IVistaMaterializacionCompraSesion);
    procedure Ejecutar;
  end;

constructor TAplicacionMaterializacionCompraSesion.Create(
  const AOperaciones: IOperacionesMaterializacionCompraSesion;
  const AVista: IVistaMaterializacionCompraSesion);
begin
  inherited Create;
  if not Assigned(AOperaciones) then
    raise EArgumentNilException.Create('AOperaciones');
  if not Assigned(AVista) then
    raise EArgumentNilException.Create('AVista');
  FOperaciones := AOperaciones;
  FVista := AVista;
end;

procedure TAplicacionMaterializacionCompraSesion.Ejecutar;
var
  bContinuar: Boolean;
  bMaterializada: Boolean;
  iDuplicados: Integer;
  Estado: TEstadoSesionCreacion;
  Motivo: TMotivoBloqueoCreacion;
  Defectos: TDefectosDialogoCreacion;
  Ajustes: TAjustesCreacionElegidos;
  Incidencias: TIncidenciasMaterializacionSesion;
  ResultadoMaterializacion: TResultadoMaterializacionSesion;
begin
  FVista.Registrar('MaterializacionCompraSesion INICIO');
  Estado := FOperaciones.LeerEstado;
  Motivo := EvaluarBloqueoCreacionSesion(Estado);
  bContinuar := Motivo = mbcNinguno;
  if not bContinuar then
    FVista.MostrarBloqueo(Motivo);
  if bContinuar then
  begin
    FOperaciones.GuardarEdicion;
    iDuplicados := FOperaciones.NormalizarDuplicados(Estado);
    if iDuplicados > 0 then
      FVista.InformarDuplicados(iDuplicados);
    bContinuar := FOperaciones.Validar(Incidencias);
    if not bContinuar then
      FVista.MostrarIncidencias(Incidencias);
  end;
  if bContinuar then
  begin
    Defectos := FOperaciones.CalcularDefectos(Estado);
    bContinuar := FVista.SolicitarAjustes(
      Estado,
      Defectos,
      Ajustes);
  end;
  if bContinuar then
  begin
    FOperaciones.ActualizarCabecera(Ajustes);
    bMaterializada := FOperaciones.Materializar(
      Ajustes,
      ResultadoMaterializacion);
    if bMaterializada then
    begin
      FOperaciones.Refrescar;
      FVista.MostrarResultado(ResultadoMaterializacion);
    end
    else
      FVista.MostrarError(ResultadoMaterializacion.MensajeError);
  end;
  FVista.Registrar('MaterializacionCompraSesion FIN');
end;

function CrearAplicacionMaterializacionCompraSesion(
  const AOperaciones: IOperacionesMaterializacionCompraSesion;
  const AVista: IVistaMaterializacionCompraSesion):
  IAplicacionMaterializacionCompraSesion;
begin
  Result := TAplicacionMaterializacionCompraSesion.Create(
    AOperaciones,
    AVista);
end;

end.
