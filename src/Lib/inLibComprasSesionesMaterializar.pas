{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasSesionesMaterializar                              }
{    Tipo:       Librería                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Orquesta materialización y reversión sin conocer UniDAC ni la BBDD.       }
{******************************************************************************}
unit inLibComprasSesionesMaterializar;

interface

uses
  inLibComprasSesionesIntf,
  inLibComprasSesionesMaterializacionIntf;

type
  TMaterializadorComprasSesiones = class
  private
    FPersistencia: IPersistenciaMaterializacionComprasSesiones;
    FUnidadTrabajo: IUnidadTrabajoMaterializacion;
    procedure MaterializarDocumentos(
      const AParametros: TParametrosMaterializacionSesion;
      const AConfiguracion: TConfiguracionMaterializacionSesion;
      const AAlmacen, ASeriePedido, ASerieAlbaran: string;
      var AResultado: TResultadoMaterializacionSesion;
      out APedido, AAlbaran: TDocumentoMaterializado);
    procedure MaterializarDocumentoUnico(
      const AParametros: TParametrosMaterializacionSesion;
      const AConfiguracion: TConfiguracionMaterializacionSesion;
      var AResultado: TResultadoMaterializacionSesion);
    procedure MaterializarDocumentosPorAlmacen(
      const AParametros: TParametrosMaterializacionSesion;
      const AConfiguracion: TConfiguracionMaterializacionSesion;
      var AResultado: TResultadoMaterializacionSesion);
  public
    constructor Create(
      const APersistencia: IPersistenciaMaterializacionComprasSesiones;
      const AUnidadTrabajo: IUnidadTrabajoMaterializacion);
    function Ejecutar(
      const AParametros: TParametrosMaterializacionSesion;
      out AResultado: TResultadoMaterializacionSesion): Boolean;
  end;
  TRevertidorComprasSesiones = class
  private
    FPersistencia: IPersistenciaReversionComprasSesiones;
    FUnidadTrabajo: IUnidadTrabajoMaterializacion;
  public
    constructor Create(
      const APersistencia: IPersistenciaReversionComprasSesiones;
      const AUnidadTrabajo: IUnidadTrabajoMaterializacion);
    function Ejecutar(
      const AUsuario: string;
      out AMensajeError: string): Boolean;
  end;

procedure InicializarResultadoMaterializacion(
  out AResultado: TResultadoMaterializacionSesion);
procedure AgregarDocumentoMaterializado(
  var AResultado: TResultadoMaterializacionSesion;
  const ADocumento: TDocumentoMaterializado);

implementation

uses
  System.SysUtils;

procedure InicializarResultadoMaterializacion(
  out AResultado: TResultadoMaterializacionSesion);
begin
  AResultado := Default(TResultadoMaterializacionSesion);
  SetLength(AResultado.Documentos, 0);
end;

procedure GuardarPrimerDocumento(
  var AResultado: TResultadoMaterializacionSesion;
  const ADocumento: TDocumentoMaterializado);
begin
  if SameText(ADocumento.Tipo, 'Pedido') and
     (AResultado.NumeroPedido = '') then
  begin
    AResultado.SeriePedido := ADocumento.Serie;
    AResultado.NumeroPedido := ADocumento.Numero;
  end;
  if SameText(ADocumento.Tipo, 'Albaran') and
     (AResultado.NumeroAlbaran = '') then
  begin
    AResultado.SerieAlbaran := ADocumento.Serie;
    AResultado.NumeroAlbaran := ADocumento.Numero;
  end;
end;

procedure AgregarDocumentoMaterializado(
  var AResultado: TResultadoMaterializacionSesion;
  const ADocumento: TDocumentoMaterializado);
var
  iIndice: Integer;
begin
  if ADocumento.Numero <> '' then
  begin
    iIndice := Length(AResultado.Documentos);
    SetLength(AResultado.Documentos, iIndice + 1);
    AResultado.Documentos[iIndice] := ADocumento;
    GuardarPrimerDocumento(AResultado, ADocumento);
  end;
end;

constructor TMaterializadorComprasSesiones.Create(
  const APersistencia: IPersistenciaMaterializacionComprasSesiones;
  const AUnidadTrabajo: IUnidadTrabajoMaterializacion);
begin
  inherited Create;
  if not Assigned(APersistencia) then
    raise EArgumentNilException.Create('APersistencia');
  if not Assigned(AUnidadTrabajo) then
    raise EArgumentNilException.Create('AUnidadTrabajo');
  FPersistencia := APersistencia;
  FUnidadTrabajo := AUnidadTrabajo;
end;

procedure TMaterializadorComprasSesiones.MaterializarDocumentos(
  const AParametros: TParametrosMaterializacionSesion;
  const AConfiguracion: TConfiguracionMaterializacionSesion;
  const AAlmacen, ASeriePedido, ASerieAlbaran: string;
  var AResultado: TResultadoMaterializacionSesion;
  out APedido, AAlbaran: TDocumentoMaterializado);
begin
  APedido := Default(TDocumentoMaterializado);
  AAlbaran := Default(TDocumentoMaterializado);
  if AConfiguracion.GeneraPedido then
    APedido := FPersistencia.MaterializarPedido(
      AParametros.Usuario, ASeriePedido, AAlmacen);
  try
    if AConfiguracion.GeneraAlbaran then
      AAlbaran := FPersistencia.MaterializarAlbaran(
        AParametros.Usuario, ASerieAlbaran, AAlmacen);
  except
    if AConfiguracion.GeneraPedido then
      AgregarDocumentoMaterializado(AResultado, APedido);
    raise;
  end;
  if AConfiguracion.GeneraAlbaran then
    AgregarDocumentoMaterializado(AResultado, AAlbaran);
  if AConfiguracion.GeneraPedido then
    AgregarDocumentoMaterializado(AResultado, APedido);
end;

procedure TMaterializadorComprasSesiones.MaterializarDocumentoUnico(
  const AParametros: TParametrosMaterializacionSesion;
  const AConfiguracion: TConfiguracionMaterializacionSesion;
  var AResultado: TResultadoMaterializacionSesion);
var
  oAlbaran: TDocumentoMaterializado;
  oPedido: TDocumentoMaterializado;
begin
  FPersistencia.MaterializarArticulos(AParametros.Usuario);
  MaterializarDocumentos(
    AParametros,
    AConfiguracion,
    AConfiguracion.AlmacenCabecera,
    AParametros.SeriePedido,
    AParametros.SerieAlbaran,
    AResultado,
    oPedido,
    oAlbaran);
  FPersistencia.CerrarSesion(
    oPedido,
    oAlbaran,
    AParametros.Usuario);
end;

procedure TMaterializadorComprasSesiones.MaterializarDocumentosPorAlmacen(
  const AParametros: TParametrosMaterializacionSesion;
  const AConfiguracion: TConfiguracionMaterializacionSesion;
  var AResultado: TResultadoMaterializacionSesion);
var
  aAlmacenes: TArray<string>;
  iAlmacen: Integer;
  oAlbaran: TDocumentoMaterializado;
  oPedido: TDocumentoMaterializado;
  sAlmacen: string;
  sSerieAlbaran: string;
  sSeriePedido: string;
begin
  oPedido := Default(TDocumentoMaterializado);
  oAlbaran := Default(TDocumentoMaterializado);
  aAlmacenes := FPersistencia.ConsultarAlmacenes;
  if Length(aAlmacenes) > 0 then
    FPersistencia.MaterializarArticulos(AParametros.Usuario);
  for iAlmacen := 0 to High(aAlmacenes) do
  begin
    sAlmacen := aAlmacenes[iAlmacen];
    sSeriePedido := FPersistencia.ResolverSerieDocumento(
      AConfiguracion.Empresa,
      'PC',
      sAlmacen,
      AParametros.SeriePedido);
    sSerieAlbaran := FPersistencia.ResolverSerieDocumento(
      AConfiguracion.Empresa,
      'AB',
      sAlmacen,
      AParametros.SerieAlbaran);
    MaterializarDocumentos(
      AParametros,
      AConfiguracion,
      sAlmacen,
      sSeriePedido,
      sSerieAlbaran,
      AResultado,
      oPedido,
      oAlbaran);
  end;
  if Length(aAlmacenes) > 0 then
    FPersistencia.CerrarSesion(
      oPedido,
      oAlbaran,
      AParametros.Usuario);
end;

function TMaterializadorComprasSesiones.Ejecutar(
  const AParametros: TParametrosMaterializacionSesion;
  out AResultado: TResultadoMaterializacionSesion): Boolean;
var
  oConfiguracion: TConfiguracionMaterializacionSesion;
  sMensajeError: string;
begin
  Result := False;
  InicializarResultadoMaterializacion(AResultado);
  FUnidadTrabajo.Iniciar;
  try
    if not FPersistencia.ValidarMaterializacion(sMensajeError) then
      raise Exception.Create(sMensajeError);
    oConfiguracion := FPersistencia.CargarConfiguracion;
    if AParametros.UnDocumentoPorAlmacen then
      MaterializarDocumentosPorAlmacen(
        AParametros,
        oConfiguracion,
        AResultado)
    else
      MaterializarDocumentoUnico(
        AParametros,
        oConfiguracion,
        AResultado);
    FUnidadTrabajo.Confirmar;
    Result := True;
  except
    on E: Exception do
    begin
      FUnidadTrabajo.Revertir;
      if AResultado.MensajeError = '' then
        AResultado.MensajeError := E.Message;
      FPersistencia.RegistrarError(
        AParametros.Usuario,
        AResultado.MensajeError);
    end;
  end;
end;

constructor TRevertidorComprasSesiones.Create(
  const APersistencia: IPersistenciaReversionComprasSesiones;
  const AUnidadTrabajo: IUnidadTrabajoMaterializacion);
begin
  inherited Create;
  if not Assigned(APersistencia) then
    raise EArgumentNilException.Create('APersistencia');
  if not Assigned(AUnidadTrabajo) then
    raise EArgumentNilException.Create('AUnidadTrabajo');
  FPersistencia := APersistencia;
  FUnidadTrabajo := AUnidadTrabajo;
end;

function TRevertidorComprasSesiones.Ejecutar(
  const AUsuario: string;
  out AMensajeError: string): Boolean;
begin
  Result := False;
  AMensajeError := '';
  FUnidadTrabajo.Iniciar;
  try
    if not FPersistencia.ValidarReversion(AMensajeError) then
      raise Exception.Create(AMensajeError);
    FPersistencia.EjecutarReversion(AUsuario);
    FUnidadTrabajo.Confirmar;
    Result := True;
  except
    on E: Exception do
    begin
      FUnidadTrabajo.Revertir;
      if AMensajeError = '' then
        AMensajeError := E.Message;
    end;
  end;
end;

end.
