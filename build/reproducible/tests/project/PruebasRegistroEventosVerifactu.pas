{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasRegistroEventosVerifactu                              }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Caracteriza el registro fiscal mediante dobles sin conexión real.        }
{******************************************************************************}
unit PruebasRegistroEventosVerifactu;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasRegistroEventosVerifactu = class
  public
    [Test]
    procedure PrimerEvento_PersisteContenidoYHash;
    [Test]
    procedure EventoPosterior_EncadenaElEventoAnterior;
    [Test]
    procedure Reintento_RegistraOtroEventoEncadenado;
    [Test]
    procedure FirmaCorrecta_PersisteFirmaYCertificado;
    [Test]
    procedure FalloFirma_PersisteIncidenciaAntesDePropagar;
    [Test]
    procedure FalloReloj_PersisteIncidenciaAntesDePropagar;
    [Test]
    procedure ColumnasFirmaAusentes_PersisteYPropagaElError;
    [Test]
    procedure FalloPersistencia_NoSeConvierteEnExito;
    [Test]
    procedure FalloPersistenciaEnIncidencia_PrevaleceAlErrorParcial;
  end;

implementation

uses
  System.DateUtils, System.SysUtils,
  inLibVerifactuRegistroEventos;

type
  TRepositorioRegistroEventosFalso = class(
    TInterfacedObject,
    IRepositorioRegistroEventosVerifactu)
  public
    Anterior: TEventoAnteriorVerifactu;
    Empresa: TEmpresaRegistroEventoVerifactu;
    FallarGuardar: Boolean;
    IntentosGuardar: Integer;
    Registros: TArray<TRegistroEventoVerifactu>;
    TieneFirma: Boolean;
    ActualizarAnterior: Boolean;
    function TieneColumnasFirma: Boolean;
    function CargarEmpresa: TEmpresaRegistroEventoVerifactu;
    function CargarAnterior: TEventoAnteriorVerifactu;
    procedure Guardar(const ARegistro: TRegistroEventoVerifactu);
  end;

  TValidadorRelojFalso = class(
    TInterfacedObject,
    IValidadorRelojRegistroEventosVerifactu)
  public
    Fallar: Boolean;
    Llamadas: Integer;
    procedure ExigirRelojFiscal;
  end;

  TFirmadorRegistroEventosFalso = class(
    TInterfacedObject,
    IFirmadorRegistroEventosVerifactu)
  public
    Fallar: Boolean;
    Llamadas: Integer;
    function Firmar(
      const AXml, AHuella, ASerieCertificado,
      ATitularCertificado: string): TFirmaRegistroEventoVerifactu;
  end;

function CrearEmpresaPrueba: TEmpresaRegistroEventoVerifactu;
begin
  Result := Default(TEmpresaRegistroEventoVerifactu);
  Result.NifObligado := 'B12345678';
  Result.NombreObligado := 'Empresa & Pruebas';
  Result.SerialCertificado := 'SERIE-CERT';
  Result.TitularCertificado := 'Titular';
  Result.NifProductor := '12345678Z';
  Result.NombreProductor := 'Productor';
  Result.IdInstalacion := '1';
  Result.VersionInstalacion := '1.0';
  Result.CodigoSifInstalacion := 'FZ';
  Result.EsMultiOt := 'N';
end;

function CrearSolicitudPrueba: TSolicitudRegistroEventoVerifactu;
begin
  Result := Default(TSolicitudRegistroEventoVerifactu);
  Result.InstanteRegistro := EncodeDateTime(2026, 8, 5, 10, 15, 30, 125);
  Result.InstanteEvento := Result.InstanteRegistro;
  Result.Version := '9.9.9';
  Result.Usuario := 'PRUEBAS';
  Result.TipoEvento := 101;
  Result.Descripcion := 'Inicio de pruebas';
  Result.DatosAdicionales := 'ORIGEN=DUNITX';
  Result.SerieFactura := 'A';
  Result.NumeroFactura := '42';
end;

function CrearServicio(
  ARepositorio: TRepositorioRegistroEventosFalso;
  AValidador: TValidadorRelojFalso;
  AFirmador: TFirmadorRegistroEventosFalso): IRegistroEventosVerifactu;
var
  oFirmador: IFirmadorRegistroEventosVerifactu;
  oRepositorio: IRepositorioRegistroEventosVerifactu;
  oValidador: IValidadorRelojRegistroEventosVerifactu;
begin
  oRepositorio := ARepositorio;
  oValidador := AValidador;
  oFirmador := AFirmador;
  Result := CrearRegistroEventosVerifactu(
    oRepositorio, oValidador, oFirmador);
end;

function CapturarError(const AAccion: TProc): string;
begin
  Result := '';
  try
    AAccion;
  except
    on E: Exception do
      Result := E.Message;
  end;
end;

function TRepositorioRegistroEventosFalso.TieneColumnasFirma: Boolean;
begin
  Result := TieneFirma;
end;

function TRepositorioRegistroEventosFalso.CargarEmpresa:
  TEmpresaRegistroEventoVerifactu;
begin
  Result := Empresa;
end;

function TRepositorioRegistroEventosFalso.CargarAnterior:
  TEventoAnteriorVerifactu;
begin
  Result := Anterior;
end;

procedure TRepositorioRegistroEventosFalso.Guardar(
  const ARegistro: TRegistroEventoVerifactu);
var
  iIndice: Integer;
begin
  Inc(IntentosGuardar);
  if FallarGuardar then
    raise EInvalidOpException.Create('Fallo de persistencia simulado');
  iIndice := Length(Registros);
  SetLength(Registros, iIndice + 1);
  Registros[iIndice] := ARegistro;
  if ActualizarAnterior then
  begin
    Anterior.EsPrimero := False;
    Anterior.TipoEvento := ARegistro.TipoEvento;
    Anterior.Instante := EncodeDateTime(2026, 8, 5, 10, 15, 30, 125);
    Anterior.Huella := ARegistro.HashPropio;
  end;
end;

procedure TValidadorRelojFalso.ExigirRelojFiscal;
begin
  Inc(Llamadas);
  if Fallar then
    raise EInvalidOpException.Create('Reloj no fiable');
end;

function TFirmadorRegistroEventosFalso.Firmar(
  const AXml, AHuella, ASerieCertificado,
  ATitularCertificado: string): TFirmaRegistroEventoVerifactu;
begin
  Inc(Llamadas);
  if Fallar then
    raise EInvalidOpException.Create('Certificado rechazado');
  Result := Default(TFirmaRegistroEventoVerifactu);
  Result.XmlFirmado := AXml + '<Firma>OK</Firma>';
  Result.FirmaXades := 'FIRMA-XADES';
  Result.FirmaDigital := 'HASH-FIRMA';
  Result.SerieCertificado := ASerieCertificado;
  Result.TitularCertificado := ATitularCertificado;
  Result.HuellaCertificado := 'HUELLA-CERT';
end;

procedure TPruebasRegistroEventosVerifactu.
  PrimerEvento_PersisteContenidoYHash;
var
  oFirmador: TFirmadorRegistroEventosFalso;
  oRegistro: IRegistroEventosVerifactu;
  oRepositorio: TRepositorioRegistroEventosFalso;
  oSolicitud: TSolicitudRegistroEventoVerifactu;
  oValidador: TValidadorRelojFalso;
begin
  oRepositorio := TRepositorioRegistroEventosFalso.Create;
  oRepositorio.Empresa := CrearEmpresaPrueba;
  oRepositorio.Anterior.EsPrimero := True;
  oRepositorio.TieneFirma := True;
  oValidador := TValidadorRelojFalso.Create;
  oFirmador := TFirmadorRegistroEventosFalso.Create;
  oRegistro := CrearServicio(oRepositorio, oValidador, oFirmador);
  oSolicitud := CrearSolicitudPrueba;
  oRegistro.Registrar(oSolicitud);
  Assert.AreEqual(1, Integer(Length(oRepositorio.Registros)));
  Assert.AreEqual(StringOfChar('0', 64),
    oRepositorio.Registros[0].HashAnterior);
  Assert.AreEqual(64, Length(oRepositorio.Registros[0].HashPropio));
  Assert.AreEqual(oRepositorio.Registros[0].HashPropio,
    oRepositorio.Registros[0].FirmaDigital);
  Assert.Contains(oRepositorio.Registros[0].Xml,
    '<sf:PrimerEvento>S</sf:PrimerEvento>');
  Assert.Contains(oRepositorio.Registros[0].Xml,
    'Empresa &amp; Pruebas');
end;

procedure TPruebasRegistroEventosVerifactu.
  EventoPosterior_EncadenaElEventoAnterior;
var
  oFirmador: TFirmadorRegistroEventosFalso;
  oRegistro: IRegistroEventosVerifactu;
  oRepositorio: TRepositorioRegistroEventosFalso;
  oValidador: TValidadorRelojFalso;
begin
  oRepositorio := TRepositorioRegistroEventosFalso.Create;
  oRepositorio.Empresa := CrearEmpresaPrueba;
  oRepositorio.Anterior.EsPrimero := False;
  oRepositorio.Anterior.TipoEvento := 102;
  oRepositorio.Anterior.Instante :=
    EncodeDateTime(2026, 8, 5, 9, 0, 0, 0);
  oRepositorio.Anterior.Huella := StringOfChar('A', 64);
  oRepositorio.TieneFirma := True;
  oValidador := TValidadorRelojFalso.Create;
  oFirmador := TFirmadorRegistroEventosFalso.Create;
  oRegistro := CrearServicio(oRepositorio, oValidador, oFirmador);
  oRegistro.Registrar(CrearSolicitudPrueba);
  Assert.AreEqual(StringOfChar('A', 64),
    oRepositorio.Registros[0].HashAnterior);
  Assert.Contains(oRepositorio.Registros[0].Xml,
    '<sf:TipoEvento>02</sf:TipoEvento>');
  Assert.Contains(oRepositorio.Registros[0].Xml,
    '<sf:HuellaEvento>' + StringOfChar('A', 64));
end;

procedure TPruebasRegistroEventosVerifactu.
  Reintento_RegistraOtroEventoEncadenado;
var
  oFirmador: TFirmadorRegistroEventosFalso;
  oRegistro: IRegistroEventosVerifactu;
  oRepositorio: TRepositorioRegistroEventosFalso;
  oSolicitud: TSolicitudRegistroEventoVerifactu;
  oValidador: TValidadorRelojFalso;
begin
  oRepositorio := TRepositorioRegistroEventosFalso.Create;
  oRepositorio.Empresa := CrearEmpresaPrueba;
  oRepositorio.Anterior.EsPrimero := True;
  oRepositorio.TieneFirma := True;
  oRepositorio.ActualizarAnterior := True;
  oValidador := TValidadorRelojFalso.Create;
  oFirmador := TFirmadorRegistroEventosFalso.Create;
  oRegistro := CrearServicio(oRepositorio, oValidador, oFirmador);
  oSolicitud := CrearSolicitudPrueba;
  oRegistro.Registrar(oSolicitud);
  oRegistro.Registrar(oSolicitud);
  Assert.AreEqual(2, Integer(Length(oRepositorio.Registros)));
  Assert.AreEqual(oRepositorio.Registros[0].HashPropio,
    oRepositorio.Registros[1].HashAnterior);
  Assert.AreNotEqual(oRepositorio.Registros[0].HashPropio,
    oRepositorio.Registros[1].HashPropio);
end;

procedure TPruebasRegistroEventosVerifactu.
  FirmaCorrecta_PersisteFirmaYCertificado;
var
  oFirmador: TFirmadorRegistroEventosFalso;
  oRegistro: IRegistroEventosVerifactu;
  oRepositorio: TRepositorioRegistroEventosFalso;
  oSolicitud: TSolicitudRegistroEventoVerifactu;
  oValidador: TValidadorRelojFalso;
begin
  oRepositorio := TRepositorioRegistroEventosFalso.Create;
  oRepositorio.Empresa := CrearEmpresaPrueba;
  oRepositorio.Anterior.EsPrimero := True;
  oRepositorio.TieneFirma := True;
  oValidador := TValidadorRelojFalso.Create;
  oFirmador := TFirmadorRegistroEventosFalso.Create;
  oRegistro := CrearServicio(oRepositorio, oValidador, oFirmador);
  oSolicitud := CrearSolicitudPrueba;
  oSolicitud.FirmarCertificado := True;
  oRegistro.Registrar(oSolicitud);
  Assert.AreEqual(1, oFirmador.Llamadas);
  Assert.AreEqual('FIRMA-XADES',
    oRepositorio.Registros[0].FirmaXades);
  Assert.AreEqual('HASH-FIRMA',
    oRepositorio.Registros[0].FirmaDigital);
  Assert.AreEqual('SERIE-CERT',
    oRepositorio.Registros[0].SerieCertificado);
end;

procedure TPruebasRegistroEventosVerifactu.
  FalloFirma_PersisteIncidenciaAntesDePropagar;
var
  oFirmador: TFirmadorRegistroEventosFalso;
  oRegistro: IRegistroEventosVerifactu;
  oRepositorio: TRepositorioRegistroEventosFalso;
  oSolicitud: TSolicitudRegistroEventoVerifactu;
  oValidador: TValidadorRelojFalso;
  sError: string;
begin
  oRepositorio := TRepositorioRegistroEventosFalso.Create;
  oRepositorio.Empresa := CrearEmpresaPrueba;
  oRepositorio.Anterior.EsPrimero := True;
  oRepositorio.TieneFirma := True;
  oValidador := TValidadorRelojFalso.Create;
  oFirmador := TFirmadorRegistroEventosFalso.Create;
  oFirmador.Fallar := True;
  oRegistro := CrearServicio(oRepositorio, oValidador, oFirmador);
  oSolicitud := CrearSolicitudPrueba;
  oSolicitud.EsNoVerifactu := True;
  oSolicitud.FirmarCertificado := True;
  sError := CapturarError(
    procedure
    begin
      oRegistro.Registrar(oSolicitud);
    end);
  Assert.Contains(sError, 'Certificado rechazado');
  Assert.AreEqual(1, Integer(Length(oRepositorio.Registros)));
  Assert.Contains(oRepositorio.Registros[0].DatosAdicionales,
    'INCIDENCIA_CERTIFICADO=Certificado rechazado');
  Assert.AreEqual(oRepositorio.Registros[0].HashPropio,
    oRepositorio.Registros[0].FirmaDigital);
end;

procedure TPruebasRegistroEventosVerifactu.
  FalloReloj_PersisteIncidenciaAntesDePropagar;
var
  oFirmador: TFirmadorRegistroEventosFalso;
  oRegistro: IRegistroEventosVerifactu;
  oRepositorio: TRepositorioRegistroEventosFalso;
  oSolicitud: TSolicitudRegistroEventoVerifactu;
  oValidador: TValidadorRelojFalso;
  sError: string;
begin
  oRepositorio := TRepositorioRegistroEventosFalso.Create;
  oRepositorio.Empresa := CrearEmpresaPrueba;
  oRepositorio.Anterior.EsPrimero := True;
  oRepositorio.TieneFirma := True;
  oValidador := TValidadorRelojFalso.Create;
  oValidador.Fallar := True;
  oFirmador := TFirmadorRegistroEventosFalso.Create;
  oRegistro := CrearServicio(oRepositorio, oValidador, oFirmador);
  oSolicitud := CrearSolicitudPrueba;
  oSolicitud.EsNoVerifactu := True;
  oSolicitud.FirmarCertificado := True;
  sError := CapturarError(
    procedure
    begin
      oRegistro.Registrar(oSolicitud);
    end);
  Assert.Contains(sError, 'Reloj no fiable');
  Assert.AreEqual(1, Integer(Length(oRepositorio.Registros)));
  Assert.Contains(oRepositorio.Registros[0].DatosAdicionales,
    'INCIDENCIA_RELOJ=Reloj no fiable');
  Assert.AreEqual(1, oValidador.Llamadas);
end;

procedure TPruebasRegistroEventosVerifactu.
  ColumnasFirmaAusentes_PersisteYPropagaElError;
var
  oFirmador: TFirmadorRegistroEventosFalso;
  oRegistro: IRegistroEventosVerifactu;
  oRepositorio: TRepositorioRegistroEventosFalso;
  oSolicitud: TSolicitudRegistroEventoVerifactu;
  oValidador: TValidadorRelojFalso;
  sError: string;
begin
  oRepositorio := TRepositorioRegistroEventosFalso.Create;
  oRepositorio.Empresa := CrearEmpresaPrueba;
  oRepositorio.Anterior.EsPrimero := True;
  oRepositorio.TieneFirma := False;
  oValidador := TValidadorRelojFalso.Create;
  oFirmador := TFirmadorRegistroEventosFalso.Create;
  oRegistro := CrearServicio(oRepositorio, oValidador, oFirmador);
  oSolicitud := CrearSolicitudPrueba;
  oSolicitud.EsNoVerifactu := True;
  oSolicitud.FirmarCertificado := True;
  sError := CapturarError(
    procedure
    begin
      oRegistro.Registrar(oSolicitud);
    end);
  Assert.Contains(sError, 'Faltan columnas de firma');
  Assert.AreEqual(1, Integer(Length(oRepositorio.Registros)));
  Assert.IsFalse(oRepositorio.Registros[0].TieneColumnasFirma);
  Assert.AreEqual(0, oFirmador.Llamadas);
end;

procedure TPruebasRegistroEventosVerifactu.
  FalloPersistencia_NoSeConvierteEnExito;
var
  oFirmador: TFirmadorRegistroEventosFalso;
  oRegistro: IRegistroEventosVerifactu;
  oRepositorio: TRepositorioRegistroEventosFalso;
  oSolicitud: TSolicitudRegistroEventoVerifactu;
  oValidador: TValidadorRelojFalso;
  sError: string;
begin
  oRepositorio := TRepositorioRegistroEventosFalso.Create;
  oRepositorio.Empresa := CrearEmpresaPrueba;
  oRepositorio.Anterior.EsPrimero := True;
  oRepositorio.TieneFirma := True;
  oRepositorio.FallarGuardar := True;
  oValidador := TValidadorRelojFalso.Create;
  oFirmador := TFirmadorRegistroEventosFalso.Create;
  oRegistro := CrearServicio(oRepositorio, oValidador, oFirmador);
  oSolicitud := CrearSolicitudPrueba;
  sError := CapturarError(
    procedure
    begin
      oRegistro.Registrar(oSolicitud);
    end);
  Assert.AreEqual('Fallo de persistencia simulado', sError);
  Assert.AreEqual(1, oRepositorio.IntentosGuardar);
  Assert.AreEqual(0, Integer(Length(oRepositorio.Registros)));
end;

procedure TPruebasRegistroEventosVerifactu.
  FalloPersistenciaEnIncidencia_PrevaleceAlErrorParcial;
var
  oFirmador: TFirmadorRegistroEventosFalso;
  oRegistro: IRegistroEventosVerifactu;
  oRepositorio: TRepositorioRegistroEventosFalso;
  oSolicitud: TSolicitudRegistroEventoVerifactu;
  oValidador: TValidadorRelojFalso;
  sError: string;
begin
  oRepositorio := TRepositorioRegistroEventosFalso.Create;
  oRepositorio.Empresa := CrearEmpresaPrueba;
  oRepositorio.Anterior.EsPrimero := True;
  oRepositorio.TieneFirma := True;
  oRepositorio.FallarGuardar := True;
  oValidador := TValidadorRelojFalso.Create;
  oFirmador := TFirmadorRegistroEventosFalso.Create;
  oFirmador.Fallar := True;
  oRegistro := CrearServicio(oRepositorio, oValidador, oFirmador);
  oSolicitud := CrearSolicitudPrueba;
  oSolicitud.EsNoVerifactu := True;
  oSolicitud.FirmarCertificado := True;
  sError := CapturarError(
    procedure
    begin
      oRegistro.Registrar(oSolicitud);
    end);
  Assert.AreEqual('Fallo de persistencia simulado', sError);
  Assert.AreEqual(1, oRepositorio.IntentosGuardar);
  Assert.AreEqual(0, Integer(Length(oRepositorio.Registros)));
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasRegistroEventosVerifactu);

end.
