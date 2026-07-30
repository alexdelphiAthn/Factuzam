{******************************************************************************}
{                                                                              }
{  Modulo:       inLibComprasSesionesCreacion                                  }
{    Tipo:       Dominio                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Decisiones del flujo de creacion de documentos desde una sesion de        }
{    compra: cuando se puede materializar, que valores propone el dialogo      }
{    y como se traducen los ajustes elegidos.                                  }
{                                                                              }
{    Sale de TfrmMtoComprasSesiones.btnCrearClick, donde vivia mezclado        }
{    con la VCL y no se podia probar. No conoce formularios, DevExpress        }
{    ni UniDAC. Las reglas trabajan sobre records; solo la traduccion          }
{    final conoce TDataSet, y se prueba con un TClientDataSet en memoria       }
{    (PLAN_SOLID.md Fase 3; LIBRO_DE_ESTILO_DELPHI.md 14.4).                   }
{******************************************************************************}
unit inLibComprasSesionesCreacion;

interface

uses
  Data.DB,
  inLibComprasSesionesIntf;

type
  // Estado de la cabecera de sesion que necesitan las reglas. Lo
  // rellena el llamante leyendo su dataset; aqui no se sabe de donde
  // viene.
  TEstadoSesionCreacion = record
    HayCabecera: Boolean;
    Estado: string;
    Serie: string;
    Numero: string;
    Empresa: string;
    Almacen: string;
    Tarifa: string;
    Temporada: Integer;
    TieneTemporada: Boolean;
    GeneraPedido: Boolean;
    GeneraAlbaran: Boolean;
    FormatoDistribuido: Boolean;
    RefProveedor: string;
  end;

  TMotivoBloqueoCreacion = (
    mbcNinguno,
    mbcSinCabecera,
    mbcYaMaterializada);

  // Lo que el dialogo de creacion debe mostrar de entrada.
  TDefectosDialogoCreacion = record
    SerieAlbaran: string;
    SeriePedido: string;
    Almacen: string;
    Tarifa: string;
    Temporada: Integer;
    GeneraPedido: Boolean;
    GeneraAlbaran: Boolean;
    RefProveedor: string;
    MostrarOpcionAgrupacion: Boolean;
  end;

  // Lo que el usuario confirmo en el dialogo.
  TAjustesCreacionElegidos = record
    SerieAlbaran: string;
    SeriePedido: string;
    Almacen: string;
    Tarifa: string;
    Temporada: Integer;
    GeneraPedido: Boolean;
    GeneraAlbaran: Boolean;
    RefProveedor: string;
    UnDocumentoPorAlmacen: Boolean;
  end;

  // Valores que hay que dejar en la cabecera antes de materializar. Las
  // series NO viajan aqui: pueden cambiar en cada materializacion y van
  // como parametros del caso de uso.
  TCabeceraSesionActualizada = record
    Almacen: string;
    Tarifa: string;
    Temporada: Integer;
    LimpiarTemporada: Boolean;
    GeneraPedido: Boolean;
    GeneraAlbaran: Boolean;
    RefProveedor: string;
  end;

// Por que no se puede materializar todavia, si es que no se puede.
function EvaluarBloqueoCreacionSesion(
  const AEstado: TEstadoSesionCreacion): TMotivoBloqueoCreacion;

// Serie que propone el dialogo: la de la empresa por tipo de documento
// y, si no hay, la propia serie de la sesion.
function SerieCreacionPropuesta(
  const ASerieEmpresa, ASerieSesion: string): string;

// Valores iniciales del dialogo. ASerieAlbEmpresa / ASeriePedEmpresa
// son las series por defecto que el llamante resolvio contra la BBDD.
function CalcularDefectosDialogoCreacion(
  const AEstado: TEstadoSesionCreacion;
  const ASerieAlbEmpresa, ASeriePedEmpresa: string):
  TDefectosDialogoCreacion;

// Traduce lo elegido a los valores de la cabecera.
function ComponerCabeceraActualizada(
  const AElegidos: TAjustesCreacionElegidos):
  TCabeceraSesionActualizada;

// Traduce lo elegido a los parametros del caso de uso.
function ComponerParametrosMaterializacion(
  const AUsuario: string;
  const AElegidos: TAjustesCreacionElegidos):
  TParametrosMaterializacionSesion;

// Traduccion entre la cabecera activa y los records de arriba. Conoce
// TDataSet, no UniDAC ni el formulario: se prueba con un
// TClientDataSet en memoria.
function LeerEstadoSesionCreacion(
  ADataSet: TDataSet): TEstadoSesionCreacion;
procedure EscribirCabeceraSesionCreacion(
  ADataSet: TDataSet;
  const ACabecera: TCabeceraSesionActualizada);

implementation

uses
  System.SysUtils, System.StrUtils;

const
  cEstadoSesionCerrada = 'CERRADA';

function EvaluarBloqueoCreacionSesion(
  const AEstado: TEstadoSesionCreacion): TMotivoBloqueoCreacion;
begin
  if not AEstado.HayCabecera then
    Result := mbcSinCabecera
  else if SameText(Trim(AEstado.Estado), cEstadoSesionCerrada) then
    Result := mbcYaMaterializada
  else
    Result := mbcNinguno;
end;

function SerieCreacionPropuesta(
  const ASerieEmpresa, ASerieSesion: string): string;
begin
  Result := Trim(ASerieEmpresa);
  if Result = '' then
    Result := Trim(ASerieSesion);
end;

function CalcularDefectosDialogoCreacion(
  const AEstado: TEstadoSesionCreacion;
  const ASerieAlbEmpresa, ASeriePedEmpresa: string):
  TDefectosDialogoCreacion;
begin
  Result := Default(TDefectosDialogoCreacion);
  Result.SerieAlbaran :=
    SerieCreacionPropuesta(ASerieAlbEmpresa, AEstado.Serie);
  Result.SeriePedido :=
    SerieCreacionPropuesta(ASeriePedEmpresa, AEstado.Serie);
  Result.Almacen := AEstado.Almacen;
  Result.Tarifa := AEstado.Tarifa;
  if AEstado.TieneTemporada then
    Result.Temporada := AEstado.Temporada
  else
    Result.Temporada := 0;
  Result.GeneraPedido := AEstado.GeneraPedido;
  // Escenario tipico de muestrarios: si la cabecera ya trae almacen se
  // propone generar albaran aunque el flag no este marcado.
  Result.GeneraAlbaran :=
    AEstado.GeneraAlbaran or (Trim(AEstado.Almacen) <> '');
  Result.RefProveedor := AEstado.RefProveedor;
  // Agrupar o un documento por almacen solo tiene sentido con formato
  // distribuido: en modo clasico hay un unico almacen efectivo.
  Result.MostrarOpcionAgrupacion := AEstado.FormatoDistribuido;
end;

function ComponerCabeceraActualizada(
  const AElegidos: TAjustesCreacionElegidos):
  TCabeceraSesionActualizada;
begin
  Result := Default(TCabeceraSesionActualizada);
  Result.Almacen := AElegidos.Almacen;
  Result.Tarifa := AElegidos.Tarifa;
  Result.LimpiarTemporada := AElegidos.Temporada <= 0;
  if not Result.LimpiarTemporada then
    Result.Temporada := AElegidos.Temporada;
  Result.GeneraPedido := AElegidos.GeneraPedido;
  Result.GeneraAlbaran := AElegidos.GeneraAlbaran;
  Result.RefProveedor := AElegidos.RefProveedor;
end;

function ComponerParametrosMaterializacion(
  const AUsuario: string;
  const AElegidos: TAjustesCreacionElegidos):
  TParametrosMaterializacionSesion;
begin
  Result := Default(TParametrosMaterializacionSesion);
  Result.Usuario := AUsuario;
  Result.SerieAlbaran := AElegidos.SerieAlbaran;
  Result.SeriePedido := AElegidos.SeriePedido;
  Result.UnDocumentoPorAlmacen := AElegidos.UnDocumentoPorAlmacen;
end;

function LeerEstadoSesionCreacion(
  ADataSet: TDataSet): TEstadoSesionCreacion;
begin
  Result := Default(TEstadoSesionCreacion);
  Result.HayCabecera :=
    Assigned(ADataSet) and ADataSet.Active and (not ADataSet.IsEmpty);
  if not Result.HayCabecera then
    Exit;
  Result.Estado := ADataSet.FieldByName('ESTADO_SES').AsString;
  Result.Serie := ADataSet.FieldByName('SERIE_SES').AsString;
  Result.Numero := ADataSet.FieldByName('NUMERO_SES').AsString;
  Result.Empresa := ADataSet.FieldByName('CODIGO_EMP_SES').AsString;
  Result.Almacen := ADataSet.FieldByName('CODIGO_ALM_SES').AsString;
  Result.Tarifa := ADataSet.FieldByName('CODIGO_TAR_SES').AsString;
  Result.TieneTemporada :=
    not ADataSet.FieldByName('ID_PV_TEMPORADA_SES').IsNull;
  if Result.TieneTemporada then
    Result.Temporada :=
      ADataSet.FieldByName('ID_PV_TEMPORADA_SES').AsInteger;
  Result.GeneraPedido :=
    ADataSet.FieldByName('ESGENERA_PEDIDO_SES').AsString = 'S';
  Result.GeneraAlbaran :=
    ADataSet.FieldByName('ESGENERA_ALBARAN_SES').AsString = 'S';
  Result.FormatoDistribuido :=
    ADataSet.FieldByName('ESFORMATO_DISTRIBUIDO_SES').AsString = 'S';
  Result.RefProveedor := ADataSet.FieldByName('REF_PRV_SES').AsString;
end;

procedure EscribirCabeceraSesionCreacion(
  ADataSet: TDataSet;
  const ACabecera: TCabeceraSesionActualizada);
begin
  ADataSet.Edit;
  ADataSet.FieldByName('CODIGO_ALM_SES').AsString := ACabecera.Almacen;
  ADataSet.FieldByName('CODIGO_TAR_SES').AsString := ACabecera.Tarifa;
  if ACabecera.LimpiarTemporada then
    ADataSet.FieldByName('ID_PV_TEMPORADA_SES').Clear
  else
    ADataSet.FieldByName('ID_PV_TEMPORADA_SES').AsInteger :=
      ACabecera.Temporada;
  ADataSet.FieldByName('ESGENERA_PEDIDO_SES').AsString :=
    IfThen(ACabecera.GeneraPedido, 'S', 'N');
  ADataSet.FieldByName('ESGENERA_ALBARAN_SES').AsString :=
    IfThen(ACabecera.GeneraAlbaran, 'S', 'N');
  // Ref. del documento del proveedor: viaja a REF_PROVEEDOR_ALBC via
  // InsertarAlbaranCompraCabecera, que ya lee S.REF_PRV_SES.
  ADataSet.FieldByName('REF_PRV_SES').AsString :=
    ACabecera.RefProveedor;
  ADataSet.Post;
end;

end.
