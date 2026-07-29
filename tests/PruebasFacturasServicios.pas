{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFacturasServicios                                      }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pruebas de resultados y validaciones de servicios de facturas.            }
{******************************************************************************}
unit PruebasFacturasServicios;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFacturasServicios = class
  public
    [Test]
    procedure Borrado_BorradorSinCobrosPermitido;
    [Test]
    procedure Borrado_FacturaFiscalDenegada;
    [Test]
    procedure Borrado_EfectosCobradosDenegado;
    [Test]
    procedure Validacion_ConservaCampoYMensaje;
    [Test]
    procedure Consolidacion_ValidaEstadoLineasYNif;
    [Test]
    procedure Movimientos_SimplificadaSiempreGenera;
    [Test]
    procedure Movimientos_NormalRespetaConfiguracion;
    [Test]
    procedure Reapertura_RechazaConsolidadaOBorrador;
    [Test]
    procedure Reapertura_RechazaColaEnviadaOProcesando;
    [Test]
    procedure Reapertura_PermiteAltaPendienteOConError;
    [Test]
    procedure Fiscal_OperacionUERechazaPaisNoUE;
    [Test]
    procedure Fiscal_ExportacionSinIvaRechazaCuota;
    [Test]
    procedure Fiscal_ClienteExtranjeroExigeNif;
  end;

implementation

uses
  inLibFacturasServiciosIntf,
  inLibFacturasValidacionFiscal;

type
  TRepositorioFacturasPrueba = class(
    TInterfacedObject,
    IRepositorioFacturas)
  private
    FPaisEsUE: Boolean;
    FExisteOperacion: Boolean;
    FOperacion: TOperacionFiscalFactura;
  public
    function ExisteSerieOtraEmpresa(
      const ASerie, AEmpresa, ATipoDocumento: string): Boolean;
    function EsPaisUE(const ACodigoPais: string): Boolean;
    function ObtenerOperacionFiscal(
      const ACodigo: string;
      out AOperacion: TOperacionFiscalFactura): Boolean;
    function UltimaFechaSerie(
      const ASerie, AEmpresa, ANumero: string): TDateTime;
    function HayHuecoNumeracion(
      const ASerie, AEmpresa, ANumero: string): Boolean;
    procedure GuardarCliente(
      const ASolicitud: TSolicitudClienteFactura);
    procedure GuardarEmpresa(
      const ASolicitud: TSolicitudEmpresaFactura);
    property PaisEsUE: Boolean
      read FPaisEsUE write FPaisEsUE;
    property ExisteOperacion: Boolean
      read FExisteOperacion write FExisteOperacion;
    property Operacion: TOperacionFiscalFactura
      read FOperacion write FOperacion;
  end;

function TRepositorioFacturasPrueba.ExisteSerieOtraEmpresa(
  const ASerie, AEmpresa, ATipoDocumento: string): Boolean;
begin
  Result := False;
end;

function TRepositorioFacturasPrueba.EsPaisUE(
  const ACodigoPais: string): Boolean;
begin
  Result := FPaisEsUE;
end;

function TRepositorioFacturasPrueba.ObtenerOperacionFiscal(
  const ACodigo: string;
  out AOperacion: TOperacionFiscalFactura): Boolean;
begin
  AOperacion := FOperacion;
  Result := FExisteOperacion;
end;

function TRepositorioFacturasPrueba.UltimaFechaSerie(
  const ASerie, AEmpresa, ANumero: string): TDateTime;
begin
  Result := 0;
end;

function TRepositorioFacturasPrueba.HayHuecoNumeracion(
  const ASerie, AEmpresa, ANumero: string): Boolean;
begin
  Result := False;
end;

procedure TRepositorioFacturasPrueba.GuardarCliente(
  const ASolicitud: TSolicitudClienteFactura);
begin
end;

procedure TRepositorioFacturasPrueba.GuardarEmpresa(
  const ASolicitud: TSolicitudEmpresaFactura);
begin
end;

procedure TPruebasFacturasServicios.
  Borrado_BorradorSinCobrosPermitido;
var
  Resultado: TResultadoBorradoFactura;
begin
  Resultado := EvaluarBorradoFactura('BORRADOR', False);
  Assert.IsTrue(Resultado.Permitido);
  Assert.AreEqual('', Resultado.Mensaje);
end;

procedure TPruebasFacturasServicios.
  Borrado_FacturaFiscalDenegada;
var
  Resultado: TResultadoBorradoFactura;
begin
  Resultado := EvaluarBorradoFactura('REGISTRADA', False);
  Assert.IsFalse(Resultado.Permitido);
  Assert.IsNotEmpty(Resultado.Mensaje);
end;

procedure TPruebasFacturasServicios.
  Borrado_EfectosCobradosDenegado;
var
  Resultado: TResultadoBorradoFactura;
begin
  Resultado := EvaluarBorradoFactura('BORRADOR', True);
  Assert.IsFalse(Resultado.Permitido);
  Assert.IsNotEmpty(Resultado.Mensaje);
end;

procedure TPruebasFacturasServicios.
  Validacion_ConservaCampoYMensaje;
var
  Error: EValidacionFactura;
begin
  Error := EValidacionFactura.Create('NIF incorrecto', cvfNifCliente);
  try
    Assert.AreEqual(cvfNifCliente, Error.Campo);
    Assert.AreEqual('NIF incorrecto', Error.Message);
  finally
    Error.Free;
  end;
end;

procedure TPruebasFacturasServicios.
  Consolidacion_ValidaEstadoLineasYNif;
var
  Resultado: TResultadoOperacionFactura;
begin
  Resultado := EvaluarConsolidacionFactura(
    'F',
    '42',
    'BORRADOR',
    'NORMAL',
    '12345678Z',
    1);
  Assert.IsTrue(Resultado.Exito);
  Resultado := EvaluarConsolidacionFactura(
    'F',
    '42',
    'VERIFACTU_PENDIENTE',
    'NORMAL',
    '12345678Z',
    1);
  Assert.IsFalse(Resultado.Exito);
  Resultado := EvaluarConsolidacionFactura(
    'F',
    '42',
    'BORRADOR',
    'SIMPLIFICADA',
    '',
    0);
  Assert.IsFalse(Resultado.Exito);
  Resultado := EvaluarConsolidacionFactura(
    'F',
    '42',
    'BORRADOR',
    'NORMAL',
    '',
    1);
  Assert.IsFalse(Resultado.Exito);
end;

procedure TPruebasFacturasServicios.
  Movimientos_SimplificadaSiempreGenera;
begin
  Assert.IsTrue(
    FacturaDebeGenerarMovimientos('SIMPLIFICADA', False));
end;

procedure TPruebasFacturasServicios.
  Movimientos_NormalRespetaConfiguracion;
begin
  Assert.IsTrue(
    FacturaDebeGenerarMovimientos('NORMAL', True));
  Assert.IsFalse(
    FacturaDebeGenerarMovimientos('NORMAL', False));
end;

procedure TPruebasFacturasServicios.
  Reapertura_RechazaConsolidadaOBorrador;
var
  Resultado: TResultadoOperacionFactura;
begin
  Resultado := EvaluarReaperturaBorrador(
    'F',
    '42',
    'REGISTRADA',
    '',
    True);
  Assert.IsFalse(Resultado.Exito);
  Resultado := EvaluarReaperturaBorrador(
    'F',
    '42',
    'BORRADOR',
    '',
    False);
  Assert.IsFalse(Resultado.Exito);
end;

procedure TPruebasFacturasServicios.
  Reapertura_RechazaColaEnviadaOProcesando;
var
  Resultado: TResultadoOperacionFactura;
begin
  Resultado := EvaluarReaperturaBorrador(
    'F',
    '42',
    'VERIFACTU_PENDIENTE',
    'ENVIADA',
    False);
  Assert.IsFalse(Resultado.Exito);
  Resultado := EvaluarReaperturaBorrador(
    'F',
    '42',
    'VERIFACTU_PENDIENTE',
    'PROCESANDO',
    False);
  Assert.IsFalse(Resultado.Exito);
end;

procedure TPruebasFacturasServicios.
  Reapertura_PermiteAltaPendienteOConError;
var
  Resultado: TResultadoOperacionFactura;
begin
  Resultado := EvaluarReaperturaBorrador(
    'F',
    '42',
    'VERIFACTU_PENDIENTE',
    'PENDIENTE',
    False);
  Assert.IsTrue(Resultado.Exito);
  Resultado := EvaluarReaperturaBorrador(
    'F',
    '42',
    'VERIFACTU_PENDIENTE',
    'ERROR',
    False);
  Assert.IsTrue(Resultado.Exito);
end;

procedure TPruebasFacturasServicios.
  Fiscal_OperacionUERechazaPaisNoUE;
var
  RepositorioObjeto: TRepositorioFacturasPrueba;
  Repositorio: IRepositorioFacturas;
  Validador: IValidadorFiscalFactura;
  Solicitud: TSolicitudValidacionFiscalFactura;
  ErrorCapturado: Boolean;
begin
  RepositorioObjeto := TRepositorioFacturasPrueba.Create;
  Repositorio := RepositorioObjeto;
  RepositorioObjeto.PaisEsUE := False;
  RepositorioObjeto.ExisteOperacion := True;
  RepositorioObjeto.FOperacion.Ambito := 'UE';
  RepositorioObjeto.FOperacion.RepercuteIva := False;
  Validador := TValidadorFiscalFactura.Create(Repositorio);
  Solicitud.TipoOperacion := '02';
  Solicitud.CodigoPaisCliente := '840';
  Solicitud.NifCliente := 'US123';
  Solicitud.TotalImpuestos := 0;
  ErrorCapturado := False;
  try
    Validador.Validar(Solicitud);
  except
    on E: EValidacionFactura do
    begin
      ErrorCapturado := True;
      Assert.AreEqual(cvfPais, E.Campo);
    end;
  end;
  Assert.IsTrue(ErrorCapturado);
end;

procedure TPruebasFacturasServicios.
  Fiscal_ExportacionSinIvaRechazaCuota;
var
  RepositorioObjeto: TRepositorioFacturasPrueba;
  Repositorio: IRepositorioFacturas;
  Validador: IValidadorFiscalFactura;
  Solicitud: TSolicitudValidacionFiscalFactura;
  ErrorCapturado: Boolean;
begin
  RepositorioObjeto := TRepositorioFacturasPrueba.Create;
  Repositorio := RepositorioObjeto;
  RepositorioObjeto.PaisEsUE := False;
  RepositorioObjeto.ExisteOperacion := True;
  RepositorioObjeto.FOperacion.Ambito := 'EXTRA_UE';
  RepositorioObjeto.FOperacion.RepercuteIva := False;
  Validador := TValidadorFiscalFactura.Create(Repositorio);
  Solicitud.TipoOperacion := '03';
  Solicitud.CodigoPaisCliente := '840';
  Solicitud.NifCliente := 'US123';
  Solicitud.TotalImpuestos := 21;
  ErrorCapturado := False;
  try
    Validador.Validar(Solicitud);
  except
    on E: EValidacionFactura do
    begin
      ErrorCapturado := True;
      Assert.AreEqual(cvfOperacionFiscal, E.Campo);
    end;
  end;
  Assert.IsTrue(ErrorCapturado);
end;

procedure TPruebasFacturasServicios.
  Fiscal_ClienteExtranjeroExigeNif;
var
  RepositorioObjeto: TRepositorioFacturasPrueba;
  Repositorio: IRepositorioFacturas;
  Validador: IValidadorFiscalFactura;
  Solicitud: TSolicitudValidacionFiscalFactura;
  ErrorCapturado: Boolean;
begin
  RepositorioObjeto := TRepositorioFacturasPrueba.Create;
  Repositorio := RepositorioObjeto;
  RepositorioObjeto.PaisEsUE := False;
  RepositorioObjeto.ExisteOperacion := True;
  RepositorioObjeto.FOperacion.Ambito := 'EXTRA_UE';
  RepositorioObjeto.FOperacion.RepercuteIva := False;
  Validador := TValidadorFiscalFactura.Create(Repositorio);
  Solicitud.TipoOperacion := '03';
  Solicitud.CodigoPaisCliente := '840';
  Solicitud.NifCliente := '';
  Solicitud.TotalImpuestos := 0;
  ErrorCapturado := False;
  try
    Validador.Validar(Solicitud);
  except
    on E: EValidacionFactura do
    begin
      ErrorCapturado := True;
      Assert.AreEqual(cvfNifCliente, E.Campo);
    end;
  end;
  Assert.IsTrue(ErrorCapturado);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFacturasServicios);

end.
