{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaCierreVentaVcl                                       }
{    Tipo:       Adaptador VCL                                                 }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Coordina el diálogo VCL de cobro y entrega la solicitud al caso de uso.   }
{******************************************************************************}
unit inMtoCajaCierreVentaVcl;

interface

uses
  System.Classes, Data.DB, Uni,
  inLibFacturas, inLibFacturasLecturasIntf,
  inLibLogIntf,
  inLibCajaTipos, inLibCajaVentaIntf,
  inMtoCajaFaseCobro;

type
  TConfirmarMotivoDevolucionCaja = function: Boolean of object;
  TActualizarRelojCierreCaja = procedure of object;
  TLeerFechaCierreCaja = reference to function: TDateTime;
  TPresentarResultadoCierreCaja = procedure(
    const AResultado: TResultadoCierreVenta;
    AEnviarEmail: Boolean;
    const AEmailEnvio: string) of object;
  TContextoCierreVentaCajaVcl = record
    Propietario: TComponent;
    Conexion: TUniConnection;
    RepositorioFacturas: IRepositorioLecturasFactura;
    Cabecera: TDataSet;
    Lineas: TDataSet;
    RepartidorDescuento: IRepartidorDescuento;
    CasoUso: ICasoUsoCierreVentaCaja;
    RegistroLog: IRegistroLog;
    CodigoEmpresa: string;
    CodigoAlmacen: string;
    CodigoCaja: string;
    TipoRectificativa: TTipoRectificativaCaja;
    TratamientoMovimientos: TTratamientoMovimientosRectificativa;
    SerieRectificada: string;
    NumeroRectificado: string;
    MotivoDevolucion: string;
    SerieOrigenDevolucion: string;
    NumeroOrigenDevolucion: string;
    EmpresaOrigenDevolucion: string;
    AlmacenOrigenDevolucion: string;
    ConfirmarMotivoDevolucion: TConfirmarMotivoDevolucionCaja;
    ActualizarReloj: TActualizarRelojCierreCaja;
    LeerFecha: TLeerFechaCierreCaja;
    PresentarResultado: TPresentarResultadoCierreCaja;
  end;
  TCoordinadorCierreVentaCajaVcl = class
  private
    class procedure ConfigurarFaseCobro(
      const AContexto: TContextoCierreVentaCajaVcl;
      AFormulario: TfrmMtoCajaFaseCobro;
      ATotales: TFacturaTotales); static;
    class procedure AplicarDescuento(
      const AContexto: TContextoCierreVentaCajaVcl;
      AFormulario: TfrmMtoCajaFaseCobro;
      ATotales: TFacturaTotales); static;
    class function PrepararFaseCobro(
      const AContexto: TContextoCierreVentaCajaVcl;
      out AFormulario: TfrmMtoCajaFaseCobro;
      out ATotales: TFacturaTotales): Boolean; static;
    class function ConstruirSolicitud(
      const AContexto: TContextoCierreVentaCajaVcl;
      AFormulario: TfrmMtoCajaFaseCobro
    ): TSolicitudCierreVenta; static;
  public
    class procedure Ejecutar(
      const AContexto: TContextoCierreVentaCajaVcl); static;
  end;

implementation

uses
  System.SysUtils, System.UITypes,
  inLibCajaVentaOperacion, inLibCajaDescuentos;

class procedure TCoordinadorCierreVentaCajaVcl.ConfigurarFaseCobro(
  const AContexto: TContextoCierreVentaCajaVcl;
  AFormulario: TfrmMtoCajaFaseCobro;
  ATotales: TFacturaTotales);
var
  oEntrada: TEntradaFaseCobro;
begin
  oEntrada := Default(TEntradaFaseCobro);
  oEntrada.CodigoEmpresa := AContexto.CodigoEmpresa;
  oEntrada.CodigoAlmacen := AContexto.CodigoAlmacen;
  oEntrada.CodigoCaja := AContexto.CodigoCaja;
  oEntrada.Fecha := AContexto.LeerFecha();
  oEntrada.CodigoCliente :=
    AContexto.Cabecera.FieldByName('CODIGO_CLI_FAC').AsString;
  oEntrada.EmailCliente :=
    AContexto.Cabecera.FieldByName('EMAIL_CLIENTE_FAC').AsString;
  oEntrada.NifCliente :=
    AContexto.Cabecera.FieldByName('NIF_CLIENTE_FAC').AsString;
  oEntrada.CodigoPaisCliente :=
    AContexto.Cabecera.FieldByName(
      'CODIGO_PAI_CLIENTE_FAC').AsString;
  oEntrada.NombrePaisCliente :=
    AContexto.Cabecera.FieldByName(
      'NOMBRE_PAI_CLIENTE_FAC').AsString;
  oEntrada.HayLineasDeposito :=
    HayLineasDepositoVenta(AContexto.Lineas);
  if AContexto.NumeroRectificado <> '' then
    oEntrada.RectificaA :=
      AContexto.SerieRectificada + '\' +
      AContexto.NumeroRectificado;
  AFormulario.Configurar(oEntrada);
  AFormulario.CargarDatosDesdeFactura(ATotales);
end;

class procedure TCoordinadorCierreVentaCajaVcl.AplicarDescuento(
  const AContexto: TContextoCierreVentaCajaVcl;
  AFormulario: TfrmMtoCajaFaseCobro;
  ATotales: TFacturaTotales);
begin
  if AFormulario.DatosCobro.ImporteDescuentoGlobal > 0 then
  begin
    AplicarRepartoDescuentoDataSet(
      AContexto.RepartidorDescuento,
      AContexto.Lineas,
      AFormulario.DatosCobro.ImporteDescuentoGlobal);
    ATotales.ProcesarFacturaCompleta;
  end;
end;

class function TCoordinadorCierreVentaCajaVcl.PrepararFaseCobro(
  const AContexto: TContextoCierreVentaCajaVcl;
  out AFormulario: TfrmMtoCajaFaseCobro;
  out ATotales: TFacturaTotales): Boolean;
begin
  AFormulario := nil;
  ATotales := nil;
  CerrarLineaPendiente(AContexto.Lineas);
  AContexto.ActualizarReloj;
  EscribirFechaCabeceraVenta(
    AContexto.Cabecera,
    AContexto.LeerFecha());
  Result := AContexto.ConfirmarMotivoDevolucion;
  if Result then
  begin
    ATotales := TFacturaTotales.Create(
      AContexto.Conexion,
      AContexto.RepositorioFacturas,
      AContexto.Cabecera,
      AContexto.Lineas,
      nil,
      AContexto.RegistroLog);
    ATotales.ProcesarFacturaCompleta;
    AFormulario := TfrmMtoCajaFaseCobro.Create(
      AContexto.Propietario);
    ConfigurarFaseCobro(AContexto, AFormulario, ATotales);
    Result := AFormulario.ShowModal = mrOk;
  end;
end;

class function TCoordinadorCierreVentaCajaVcl.ConstruirSolicitud(
  const AContexto: TContextoCierreVentaCajaVcl;
  AFormulario: TfrmMtoCajaFaseCobro
): TSolicitudCierreVenta;
var
  dtFecha: TDateTime;
  oCobro: TResultadoFaseCobro;
  oDocumento: TDocumentoCierreVenta;
begin
  oCobro := AFormulario.ObtenerResultado;
  oDocumento := ResolverDocumentoCierreVenta(
    oCobro.TipoImpresion = tiFactura,
    oCobro.SerieDocumento,
    oCobro.SerieFactura,
    oCobro.FechaFactura,
    AContexto.NumeroRectificado <> '');
  AContexto.ActualizarReloj;
  dtFecha := AContexto.LeerFecha();
  EscribirFechaCabeceraVenta(AContexto.Cabecera, dtFecha);
  Result := Default(TSolicitudCierreVenta);
  Result.TipoImpresion := oCobro.TipoImpresion;
  Result.Grabacion.CodigoEmpresa := AContexto.CodigoEmpresa;
  Result.Grabacion.CodigoAlmacen := AContexto.CodigoAlmacen;
  Result.Grabacion.CodigoCaja := AContexto.CodigoCaja;
  Result.Grabacion.SerieDocumento := oDocumento.Serie;
  Result.Grabacion.TipoFactura := oDocumento.TipoFactura;
  Result.Grabacion.FechaFactura := oDocumento.FechaFactura;
  Result.Grabacion.FechaOperacion := dtFecha;
  Result.Grabacion.NumeroManual := oCobro.NumeroManual;
  Result.Grabacion.TipoRectificativa :=
    AContexto.TipoRectificativa;
  Result.Grabacion.SerieRectificada := AContexto.SerieRectificada;
  Result.Grabacion.NumeroRectificado := AContexto.NumeroRectificado;
  Result.Grabacion.TratamientoMovimientos :=
    AContexto.TratamientoMovimientos;
  Result.Grabacion.MotivoDevolucion := AContexto.MotivoDevolucion;
  Result.Grabacion.SerieOrigenDevolucion :=
    AContexto.SerieOrigenDevolucion;
  Result.Grabacion.NumeroOrigenDevolucion :=
    AContexto.NumeroOrigenDevolucion;
  Result.Grabacion.EmpresaOrigenDevolucion :=
    AContexto.EmpresaOrigenDevolucion;
  Result.Grabacion.AlmacenOrigenDevolucion :=
    AContexto.AlmacenOrigenDevolucion;
  Result.Grabacion.DatosCobro := oCobro.DatosCobro;
end;

class procedure TCoordinadorCierreVentaCajaVcl.Ejecutar(
  const AContexto: TContextoCierreVentaCajaVcl);
var
  frmFaseCobro: TfrmMtoCajaFaseCobro;
  oResultado: TResultadoCierreVenta;
  oSolicitud: TSolicitudCierreVenta;
  oTotales: TFacturaTotales;
begin
  frmFaseCobro := nil;
  oTotales := nil;
  try
    if PrepararFaseCobro(
      AContexto, frmFaseCobro, oTotales) then
    begin
      AplicarDescuento(AContexto, frmFaseCobro, oTotales);
      oSolicitud := ConstruirSolicitud(AContexto, frmFaseCobro);
      oResultado := AContexto.CasoUso.Ejecutar(oSolicitud);
      if oResultado.Grabada then
        AContexto.PresentarResultado(
          oResultado,
          frmFaseCobro.EnviarEmail,
          frmFaseCobro.EmailEnvio);
    end;
  finally
    FreeAndNil(frmFaseCobro);
    FreeAndNil(oTotales);
  end;
end;

end.
