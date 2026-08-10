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
    [Test]
    procedure Cobro_RedondeoInferiorACentimoNoGeneraCambio;
    [Test]
    procedure CobroParcial_PriorizaDepositoExistente;
    [Test]
    procedure Borrado_ErrorDePersistenciaEjecutaRollback;
  end;

implementation

uses
  inLibFacturasServiciosIntf,
  inLibFacturasValidacionFiscal,
  inLibFaseCobroCalculo,
  UniDataFacturas;

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
  TServicioBorradoFacturaPrueba = class(
    TInterfacedObject,
    IServicioBorradoFactura)
  private
    FReversiones: Integer;
  public
    function Validar(
      const ASerie, ANumero, AFase: string): TResultadoBorradoFactura;
    function Preparar(
      const ASerie, ANumero, AFase: string): TResultadoBorradoFactura;
    procedure Confirmar;
    procedure Revertir;
    property Reversiones: Integer read FReversiones;
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

function TServicioBorradoFacturaPrueba.Validar(
  const ASerie, ANumero, AFase: string): TResultadoBorradoFactura;
begin
  Result := Default(TResultadoBorradoFactura);
end;

function TServicioBorradoFacturaPrueba.Preparar(
  const ASerie, ANumero, AFase: string): TResultadoBorradoFactura;
begin
  Result := Default(TResultadoBorradoFactura);
end;

procedure TServicioBorradoFacturaPrueba.Confirmar;
begin
end;

procedure TServicioBorradoFacturaPrueba.Revertir;
begin
  Inc(FReversiones);
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

procedure TPruebasFacturasServicios.
  Cobro_RedondeoInferiorACentimoNoGeneraCambio;
var
  oEntrada: TEntradaTotalesCobro;
  oResultado: TResultadoTotalesCobro;
begin
  oEntrada := Default(TEntradaTotalesCobro);
  oEntrada.ImporteBruto := 10;
  oEntrada.TotalEntregado := 10.005;
  oEntrada.TotalEntregadoConCambio := 10.005;
  oResultado := TCalculadorFaseCobro.CalcularTotales(oEntrada);
  Assert.AreEqual(Currency(0), oResultado.ImportePendiente);
  Assert.AreEqual(Currency(0), oResultado.ImporteCambio);
end;

procedure TPruebasFacturasServicios.
  CobroParcial_PriorizaDepositoExistente;
var
  oLineas: TArray<TLineaCobroParcial>;
begin
  SetLength(oLineas, 2);
  oLineas[0].IdDeposito := 'DEP-1';
  oLineas[0].VieneDeDeposito := 'S';
  oLineas[0].AccionDeposito := 'COBRAR';
  oLineas[0].Descripcion := 'Prenda depositada';
  oLineas[0].Total := 20;
  oLineas[0].AnticipoPrevio := 5;
  oLineas[0].PorcentajeIva := 21;
  oLineas[1].Descripcion := 'Prenda nueva';
  oLineas[1].Total := 10;
  oLineas[1].PorcentajeIva := 21;
  TCalculadorCobroParcial.Transformar(oLineas, 10);
  Assert.AreEqual('AUMENTAR_DEP', oLineas[0].AccionDeposito);
  Assert.AreEqual(Currency(10), oLineas[0].Total);
  Assert.AreEqual('NUEVO_DEP', oLineas[1].AccionDeposito);
  Assert.AreEqual(Currency(0), oLineas[1].Total);
end;

procedure TPruebasFacturasServicios.
  Borrado_ErrorDePersistenciaEjecutaRollback;
var
  oServicioObjeto: TServicioBorradoFacturaPrueba;
  oServicio: IServicioBorradoFactura;
begin
  oServicioObjeto := TServicioBorradoFacturaPrueba.Create;
  oServicio := oServicioObjeto;
  RevertirBorradoFactura(oServicio);
  Assert.AreEqual(1, oServicioObjeto.Reversiones);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFacturasServicios);

end.
