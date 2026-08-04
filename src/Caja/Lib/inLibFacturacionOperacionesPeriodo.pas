{******************************************************************************}
{  Módulo: inLibFacturacionOperacionesPeriodo                                 }
{  Tipo: Librería de dominio                                                  }
{  Descripción: Reglas puras de facturación periódica de operaciones TPV.     }
{******************************************************************************}
unit inLibFacturacionOperacionesPeriodo;

interface

uses
  inLibFacturacionOperacionesPeriodoIntf;

type
  TClasificacionOperacionPeriodo = (
    copNoFacturable,
    copVentaContado,
    copTraspasoEntreEmpresas);
  TValidacionFacturacionOperacionesPeriodo = record
    EsValida: Boolean;
    Mensaje: string;
  end;

function ClasificarOperacionPeriodo(
  const ATipoOperacion: string;
  AEsVentaContado: Boolean): TClasificacionOperacionPeriodo;
function EsVentaContadoSinClienteFiscal(
  const ACodigoCliente, ARazonSocial, ANif: string): Boolean;
function ValidarSolicitudFacturacionOperacionesPeriodo(
  const ASolicitud: TSolicitudFacturacionOperacionesPeriodo
): TValidacionFacturacionOperacionesPeriodo;
function CrearClaveIdempotenciaOperacionPeriodo(
  const ATipoOperacion: string;
  AIdOperacion, AIdVersionAnterior: Int64;
  const AHuellaOrigen: string): string;
function DescripcionEstadoFiscalPeriodo(
  const ATipoOperacion, AFaseFactura: string): string;

implementation

uses
  System.SysUtils, System.Hash,
  inLibMsgFacturacionOperacionesPeriodo;

function ClasificarOperacionPeriodo(
  const ATipoOperacion: string;
  AEsVentaContado: Boolean): TClasificacionOperacionPeriodo;
var
  sTipo: string;
begin
  sTipo := UpperCase(Trim(ATipoOperacion));
  Result := copNoFacturable;
  if (sTipo = 'VE') and AEsVentaContado then
  begin
    Result := copVentaContado;
  end
  else if (sTipo = 'TA') or (sTipo = 'AT') then
  begin
    Result := copTraspasoEntreEmpresas;
  end;
end;

function EsVentaContadoSinClienteFiscal(
  const ACodigoCliente, ARazonSocial, ANif: string): Boolean;
begin
  Result := (Trim(ACodigoCliente) = '') and
    (Trim(ARazonSocial) = '') and
    (Trim(ANif) = '');
end;

function ValidarSolicitudFacturacionOperacionesPeriodo(
  const ASolicitud: TSolicitudFacturacionOperacionesPeriodo
): TValidacionFacturacionOperacionesPeriodo;
begin
  Result.EsValida := False;
  Result.Mensaje := '';
  if Trim(ASolicitud.Empresa) = '' then
  begin
    Result.Mensaje := SErrorEmpresaFacturacionPeriodoObligatoria;
  end
  else if Trim(ASolicitud.Almacen) = '' then
  begin
    Result.Mensaje := SErrorAlmacenFacturacionPeriodoObligatorio;
  end
  else if Trim(ASolicitud.Caja) = '' then
  begin
    Result.Mensaje := SErrorCajaFacturacionPeriodoObligatoria;
  end
  else if ASolicitud.FechaDesde <= 0 then
  begin
    Result.Mensaje := SErrorFechaDesdeFacturacionPeriodoObligatoria;
  end
  else if ASolicitud.FechaHasta < ASolicitud.FechaDesde then
  begin
    Result.Mensaje := SErrorRangoFacturacionPeriodoNoValido;
  end
  else if ASolicitud.FechaDocumento <= 0 then
  begin
    Result.Mensaje := SErrorFechaDocumentoFacturacionPeriodoObligatoria;
  end
  else if not ASolicitud.IncluirVentasContado and
          not ASolicitud.IncluirTraspasosEmpresas then
  begin
    Result.Mensaje := SErrorTipoFacturacionPeriodoObligatorio;
  end
  else if ASolicitud.IncluirTraspasosEmpresas and
          (Trim(ASolicitud.SerieFiscal) = '') then
  begin
    Result.Mensaje := SErrorSerieFiscalFacturacionPeriodoObligatoria;
  end
  else
  begin
    Result.EsValida := True;
  end;
end;

function CrearClaveIdempotenciaOperacionPeriodo(
  const ATipoOperacion: string;
  AIdOperacion, AIdVersionAnterior: Int64;
  const AHuellaOrigen: string): string;
var
  sBase: string;
begin
  sBase := UpperCase(Trim(ATipoOperacion)) + '|' +
    IntToStr(AIdOperacion) + '|' + IntToStr(AIdVersionAnterior) + '|' +
    UpperCase(Trim(AHuellaOrigen));
  Result := UpperCase(THashSHA2.GetHashString(sBase));
end;

function DescripcionEstadoFiscalPeriodo(
  const ATipoOperacion, AFaseFactura: string): string;
begin
  if SameText(Trim(ATipoOperacion), 'VE') then
  begin
    Result := SEstadoFiscalNoAplicaFacturacionPeriodo;
  end
  else if Trim(AFaseFactura) = '' then
  begin
    Result := SEstadoFiscalPendienteFacturacionPeriodo;
  end
  else
  begin
    Result := AFaseFactura;
  end;
end;

end.
