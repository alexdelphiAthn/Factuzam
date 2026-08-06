{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasModalArqueoPersistencia                               }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Caracteriza cálculo y coordinación del arqueo sin VCL ni base de datos.   }
{******************************************************************************}
unit PruebasModalArqueoPersistencia;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasModalArqueoPersistencia = class
  public
    [Test]
    procedure Calculo_SumaImportesYClasificaElCajon;
    [Test]
    procedure Calculo_RetiradaMayorNoDejaEfectivoNegativo;
    [Test]
    procedure Preparacion_VendedorVacioDetieneLaOperacion;
    [Test]
    procedure Preparacion_VendedorInvalidoDetieneLaOperacion;
    [Test]
    procedure Preparacion_ArqueoDuplicadoDetieneLaOperacion;
    [Test]
    procedure Preparacion_RecuentoVacioDetieneLaOperacion;
    [Test]
    procedure Preparacion_ValidaNormalizaElVendedor;
    [Test]
    procedure Grabacion_ValidaDelegaTodosLosDatos;
    [Test]
    procedure Grabacion_PreparacionInvalidaFallaTemprano;
    [Test]
    procedure Grabacion_ErrorDePersistenciaSePropaga;
    [Test]
    procedure Construccion_DependenciaAusenteFallaTemprano;
  end;

implementation

uses
  System.SysUtils,
  inLibArqueo,
  inLibArqueoPersistencia,
  inLibModalArqueoPersistenciaIntf,
  UniDataModalArqueoOperacion;

type
  TRepositorioModalArqueoFalso = class(
    TInterfacedObject,
    IRepositorioModalArqueo)
  public
    ConsultasDuplicado: Integer;
    ConsultasVendedor: Integer;
    EsDuplicado: Boolean;
    NombreVendedor: string;
    function ConsultarResumenEmpleados(
      const ASolicitud: TSolicitudResumenModalArqueo
    ): IResultadoModalArqueo;
    function ConsultarResumenFormasPago(
      const ASolicitud: TSolicitudResumenModalArqueo
    ): IResultadoModalArqueo;
    function ConsultarResumenPropiedades(
      const ASolicitud: TSolicitudResumenModalArqueo
    ): IResultadoModalArqueo;
    function ConsultarResumenIva(
      const ASolicitud: TSolicitudResumenModalArqueo
    ): IResultadoModalArqueo;
    function BuscarNombreVendedor(
      const ACodigo: string): string;
    function ExisteArqueoCerrado(
      const ASolicitud: TSolicitudResumenModalArqueo): Boolean;
  end;
  TPersistenciaArqueoFalsa = class(
    TInterfacedObject,
    IArqueoPersistencia)
  public
    DiferenciaTotal: Currency;
    EfectivoDejado: Currency;
    Fallar: Boolean;
    Grabaciones: Integer;
    ImporteRetirada: Currency;
    Lineas: TArray<TArqueoRecuentoLinea>;
    TotalRecuento: Currency;
    Vendedor: string;
    procedure GrabarArqueo(
      const AArqueo: TArqueoCaja;
      const ALineasRecuento: TArray<TArqueoRecuentoLinea>;
      ATotalRecuento: Currency;
      ADiferenciaTotal: Currency;
      AEfectivoDejado: Currency;
      AImporteRetirada: Currency;
      const AConceptoRetirada: string;
      const ADesgloseBilletes: string;
      const AObservaciones: string;
      const ACodigoEmpleado: string;
      const AUsuario: string);
  end;

function CrearEntrada: TEntradaGrabacionModalArqueo;
begin
  Result := Default(TEntradaGrabacionModalArqueo);
  Result.Solicitud.Empresa := 'EMP';
  Result.Solicitud.Almacen := 'ALM';
  Result.Solicitud.Caja := 'CAJ';
  Result.CodigoVendedor := '  VEN  ';
  Result.Usuario := 'PRUEBAS';
  Result.ImporteRetirada := 30;
  Result.ConceptoRetirada := 'Retirada banco';
  SetLength(Result.Recuento, 2);
  Result.Recuento[0].CodigoFormaPago := 'EFE';
  Result.Recuento[0].Descripcion := 'Efectivo';
  Result.Recuento[0].ImporteSistema := 100;
  Result.Recuento[0].ImporteRecuento := 90;
  Result.Recuento[1].CodigoFormaPago := 'TAR';
  Result.Recuento[1].Descripcion := 'Tarjeta';
  Result.Recuento[1].ImporteSistema := 40;
  Result.Recuento[1].ImporteRecuento := 42;
end;

function CrearOperacion(
  out ARepositorio: TRepositorioModalArqueoFalso;
  out APersistencia: TPersistenciaArqueoFalsa): TOperacionModalArqueo;
var
  oPersistencia: IArqueoPersistencia;
  oRepositorio: IRepositorioModalArqueo;
begin
  ARepositorio := TRepositorioModalArqueoFalso.Create;
  ARepositorio.NombreVendedor := 'Vendedor de prueba';
  APersistencia := TPersistenciaArqueoFalsa.Create;
  oRepositorio := ARepositorio;
  oPersistencia := APersistencia;
  Result := TOperacionModalArqueo.Create(
    oRepositorio,
    oPersistencia);
end;

function TRepositorioModalArqueoFalso.ConsultarResumenEmpleados(
  const ASolicitud: TSolicitudResumenModalArqueo
): IResultadoModalArqueo;
begin
  Result := nil;
end;

function TRepositorioModalArqueoFalso.ConsultarResumenFormasPago(
  const ASolicitud: TSolicitudResumenModalArqueo
): IResultadoModalArqueo;
begin
  Result := nil;
end;

function TRepositorioModalArqueoFalso.ConsultarResumenPropiedades(
  const ASolicitud: TSolicitudResumenModalArqueo
): IResultadoModalArqueo;
begin
  Result := nil;
end;

function TRepositorioModalArqueoFalso.ConsultarResumenIva(
  const ASolicitud: TSolicitudResumenModalArqueo
): IResultadoModalArqueo;
begin
  Result := nil;
end;

function TRepositorioModalArqueoFalso.BuscarNombreVendedor(
  const ACodigo: string): string;
begin
  Inc(ConsultasVendedor);
  Result := NombreVendedor;
end;

function TRepositorioModalArqueoFalso.ExisteArqueoCerrado(
  const ASolicitud: TSolicitudResumenModalArqueo): Boolean;
begin
  Inc(ConsultasDuplicado);
  Result := EsDuplicado;
end;

procedure TPersistenciaArqueoFalsa.GrabarArqueo(
  const AArqueo: TArqueoCaja;
  const ALineasRecuento: TArray<TArqueoRecuentoLinea>;
  ATotalRecuento: Currency;
  ADiferenciaTotal: Currency;
  AEfectivoDejado: Currency;
  AImporteRetirada: Currency;
  const AConceptoRetirada: string;
  const ADesgloseBilletes: string;
  const AObservaciones: string;
  const ACodigoEmpleado: string;
  const AUsuario: string);
begin
  Inc(Grabaciones);
  Lineas := Copy(ALineasRecuento);
  TotalRecuento := ATotalRecuento;
  DiferenciaTotal := ADiferenciaTotal;
  EfectivoDejado := AEfectivoDejado;
  ImporteRetirada := AImporteRetirada;
  Vendedor := ACodigoEmpleado;
  if Fallar then
    raise EInvalidOpException.Create('Fallo simulado de persistencia');
end;

procedure TPruebasModalArqueoPersistencia.
  Calculo_SumaImportesYClasificaElCajon;
var
  Entrada: TEntradaGrabacionModalArqueo;
  Plan: TPlanGrabacionModalArqueo;
begin
  Entrada := CrearEntrada;
  Plan := CalcularPlanGrabacionModalArqueo(
    Entrada.Recuento,
    Entrada.ImporteRetirada);
  Assert.AreEqual(Currency(140), Plan.TotalSistema);
  Assert.AreEqual(Currency(132), Plan.TotalRecuento);
  Assert.AreEqual(Currency(-8), Plan.DiferenciaTotal);
  Assert.AreEqual(Currency(90), Plan.EfectivoRecontado);
  Assert.AreEqual(Currency(60), Plan.EfectivoDejado);
  Assert.AreEqual('S', Plan.Lineas[0].EsCajon);
  Assert.AreEqual('N', Plan.Lineas[1].EsCajon);
  Assert.AreEqual(Currency(2), Plan.Lineas[1].Diferencia);
end;

procedure TPruebasModalArqueoPersistencia.
  Calculo_RetiradaMayorNoDejaEfectivoNegativo;
var
  Entrada: TEntradaGrabacionModalArqueo;
  Plan: TPlanGrabacionModalArqueo;
begin
  Entrada := CrearEntrada;
  Plan := CalcularPlanGrabacionModalArqueo(
    Entrada.Recuento,
    200);
  Assert.AreEqual(Currency(0), Plan.EfectivoDejado);
end;

procedure TPruebasModalArqueoPersistencia.
  Preparacion_VendedorVacioDetieneLaOperacion;
var
  Entrada: TEntradaGrabacionModalArqueo;
  Operacion: TOperacionModalArqueo;
  Persistencia: TPersistenciaArqueoFalsa;
  Repositorio: TRepositorioModalArqueoFalso;
  Resultado: TResultadoPreparacionModalArqueo;
begin
  Operacion := CrearOperacion(Repositorio, Persistencia);
  try
    Entrada := CrearEntrada;
    Entrada.CodigoVendedor := '   ';
    Resultado := Operacion.Preparar(Entrada);
    Assert.AreEqual(
      Integer(epmaVendedorNoIndicado),
      Integer(Resultado.Estado));
    Assert.AreEqual(0, Repositorio.ConsultasVendedor);
    Assert.AreEqual(0, Repositorio.ConsultasDuplicado);
  finally
    FreeAndNil(Operacion);
  end;
end;

procedure TPruebasModalArqueoPersistencia.
  Preparacion_VendedorInvalidoDetieneLaOperacion;
var
  Entrada: TEntradaGrabacionModalArqueo;
  Operacion: TOperacionModalArqueo;
  Persistencia: TPersistenciaArqueoFalsa;
  Repositorio: TRepositorioModalArqueoFalso;
  Resultado: TResultadoPreparacionModalArqueo;
begin
  Operacion := CrearOperacion(Repositorio, Persistencia);
  try
    Repositorio.NombreVendedor := '';
    Entrada := CrearEntrada;
    Resultado := Operacion.Preparar(Entrada);
    Assert.AreEqual(
      Integer(epmaVendedorNoValido),
      Integer(Resultado.Estado));
    Assert.AreEqual(1, Repositorio.ConsultasVendedor);
    Assert.AreEqual(0, Repositorio.ConsultasDuplicado);
  finally
    FreeAndNil(Operacion);
  end;
end;

procedure TPruebasModalArqueoPersistencia.
  Preparacion_ArqueoDuplicadoDetieneLaOperacion;
var
  Entrada: TEntradaGrabacionModalArqueo;
  Operacion: TOperacionModalArqueo;
  Persistencia: TPersistenciaArqueoFalsa;
  Repositorio: TRepositorioModalArqueoFalso;
  Resultado: TResultadoPreparacionModalArqueo;
begin
  Operacion := CrearOperacion(Repositorio, Persistencia);
  try
    Repositorio.EsDuplicado := True;
    Entrada := CrearEntrada;
    Resultado := Operacion.Preparar(Entrada);
    Assert.AreEqual(
      Integer(epmaArqueoDuplicado),
      Integer(Resultado.Estado));
    Assert.AreEqual(1, Repositorio.ConsultasDuplicado);
    Assert.AreEqual(0, Persistencia.Grabaciones);
  finally
    FreeAndNil(Operacion);
  end;
end;

procedure TPruebasModalArqueoPersistencia.
  Preparacion_RecuentoVacioDetieneLaOperacion;
var
  Entrada: TEntradaGrabacionModalArqueo;
  Operacion: TOperacionModalArqueo;
  Persistencia: TPersistenciaArqueoFalsa;
  Repositorio: TRepositorioModalArqueoFalso;
  Resultado: TResultadoPreparacionModalArqueo;
begin
  Operacion := CrearOperacion(Repositorio, Persistencia);
  try
    Entrada := CrearEntrada;
    SetLength(Entrada.Recuento, 0);
    Resultado := Operacion.Preparar(Entrada);
    Assert.AreEqual(
      Integer(epmaRecuentoNoDisponible),
      Integer(Resultado.Estado));
    Assert.AreEqual(0, Persistencia.Grabaciones);
  finally
    FreeAndNil(Operacion);
  end;
end;

procedure TPruebasModalArqueoPersistencia.
  Preparacion_ValidaNormalizaElVendedor;
var
  Entrada: TEntradaGrabacionModalArqueo;
  Operacion: TOperacionModalArqueo;
  Persistencia: TPersistenciaArqueoFalsa;
  Repositorio: TRepositorioModalArqueoFalso;
  Resultado: TResultadoPreparacionModalArqueo;
begin
  Operacion := CrearOperacion(Repositorio, Persistencia);
  try
    Entrada := CrearEntrada;
    Resultado := Operacion.Preparar(Entrada);
    Assert.IsTrue(Resultado.PuedeGrabar);
    Assert.AreEqual('VEN', Resultado.CodigoVendedor);
    Assert.AreEqual('Vendedor de prueba', Resultado.NombreVendedor);
    Assert.AreEqual(Currency(132), Resultado.Plan.TotalRecuento);
  finally
    FreeAndNil(Operacion);
  end;
end;

procedure TPruebasModalArqueoPersistencia.
  Grabacion_ValidaDelegaTodosLosDatos;
var
  Entrada: TEntradaGrabacionModalArqueo;
  Operacion: TOperacionModalArqueo;
  Persistencia: TPersistenciaArqueoFalsa;
  Repositorio: TRepositorioModalArqueoFalso;
  Resultado: TResultadoPreparacionModalArqueo;
begin
  Operacion := CrearOperacion(Repositorio, Persistencia);
  try
    Entrada := CrearEntrada;
    Resultado := Operacion.Preparar(Entrada);
    Operacion.Grabar(Entrada, Resultado);
    Assert.AreEqual(1, Persistencia.Grabaciones);
    Assert.AreEqual(2, Integer(Length(Persistencia.Lineas)));
    Assert.AreEqual(Currency(132), Persistencia.TotalRecuento);
    Assert.AreEqual(Currency(-8), Persistencia.DiferenciaTotal);
    Assert.AreEqual(Currency(60), Persistencia.EfectivoDejado);
    Assert.AreEqual(Currency(30), Persistencia.ImporteRetirada);
    Assert.AreEqual('VEN', Persistencia.Vendedor);
  finally
    FreeAndNil(Operacion);
  end;
end;

procedure TPruebasModalArqueoPersistencia.
  Grabacion_PreparacionInvalidaFallaTemprano;
var
  Entrada: TEntradaGrabacionModalArqueo;
  Operacion: TOperacionModalArqueo;
  Persistencia: TPersistenciaArqueoFalsa;
  Repositorio: TRepositorioModalArqueoFalso;
  Resultado: TResultadoPreparacionModalArqueo;
  bFallo: Boolean;
begin
  Operacion := CrearOperacion(Repositorio, Persistencia);
  try
    Entrada := CrearEntrada;
    Resultado := Default(TResultadoPreparacionModalArqueo);
    Resultado.Estado := epmaVendedorNoValido;
    bFallo := False;
    try
      Operacion.Grabar(Entrada, Resultado);
    except
      on E: EInvalidOpException do
        bFallo := True;
    end;
    Assert.IsTrue(bFallo);
    Assert.AreEqual(0, Persistencia.Grabaciones);
  finally
    FreeAndNil(Operacion);
  end;
end;

procedure TPruebasModalArqueoPersistencia.
  Grabacion_ErrorDePersistenciaSePropaga;
var
  Entrada: TEntradaGrabacionModalArqueo;
  Operacion: TOperacionModalArqueo;
  Persistencia: TPersistenciaArqueoFalsa;
  Repositorio: TRepositorioModalArqueoFalso;
  Resultado: TResultadoPreparacionModalArqueo;
  bFallo: Boolean;
begin
  Operacion := CrearOperacion(Repositorio, Persistencia);
  try
    Persistencia.Fallar := True;
    Entrada := CrearEntrada;
    Resultado := Operacion.Preparar(Entrada);
    bFallo := False;
    try
      Operacion.Grabar(Entrada, Resultado);
    except
      on E: EInvalidOpException do
        bFallo := True;
    end;
    Assert.IsTrue(bFallo);
    Assert.AreEqual(1, Persistencia.Grabaciones);
  finally
    FreeAndNil(Operacion);
  end;
end;

procedure TPruebasModalArqueoPersistencia.
  Construccion_DependenciaAusenteFallaTemprano;
var
  oPersistencia: IArqueoPersistencia;
  oRepositorio: IRepositorioModalArqueo;
  Operacion: TOperacionModalArqueo;
  Persistencia: TPersistenciaArqueoFalsa;
  Repositorio: TRepositorioModalArqueoFalso;
  bFallo: Boolean;
begin
  Persistencia := TPersistenciaArqueoFalsa.Create;
  oPersistencia := Persistencia;
  Operacion := nil;
  bFallo := False;
  try
    Operacion := TOperacionModalArqueo.Create(nil, oPersistencia);
  except
    on E: EArgumentNilException do
      bFallo := True;
  end;
  FreeAndNil(Operacion);
  Assert.IsTrue(bFallo);
  Repositorio := TRepositorioModalArqueoFalso.Create;
  oRepositorio := Repositorio;
  bFallo := False;
  try
    Operacion := TOperacionModalArqueo.Create(oRepositorio, nil);
  except
    on E: EArgumentNilException do
      bFallo := True;
  end;
  FreeAndNil(Operacion);
  Assert.IsTrue(bFallo);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasModalArqueoPersistencia);
end.
