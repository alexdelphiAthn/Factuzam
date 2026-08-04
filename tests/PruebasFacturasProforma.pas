{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasFacturasProforma                                       }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica el enrutado y validación de la facturación de caja.              }
{******************************************************************************}
unit PruebasFacturasProforma;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasFacturasProforma = class
  public
    [Test]
    procedure Venta_UsaRepositorioDeProformas;
    [Test]
    procedure Traspaso_UsaRepositorioDeFacturas;
    [Test]
    procedure PeriodoInverso_EsRechazado;
    [Test]
    procedure EmpresaDestinoVacia_EsRechazada;
    [Test]
    procedure UsuarioVacio_EsRechazado;
  end;

implementation

uses
  System.SysUtils, inLibFacturasProformaIntf,
  inLibFacturasProforma;

type
  TRepositorioFacturasProformaFalso = class(
    TInterfacedObject,
    IRepositorioFacturasProforma
  )
  private
    FGeneracionesVenta   : Integer;
    FGeneracionesTraspaso: Integer;
    FUltimaSolicitud     : TSolicitudFacturacionCaja;
  public
    function GenerarVenta(
      const ASolicitud: TSolicitudFacturacionCaja
    ): TResultadoFacturacionCaja;
    function GenerarTraspasos(
      const ASolicitud: TSolicitudFacturacionCaja
    ): TResultadoFacturacionCaja;
    property GeneracionesVenta: Integer read FGeneracionesVenta;
    property GeneracionesTraspaso: Integer read FGeneracionesTraspaso;
    property UltimaSolicitud: TSolicitudFacturacionCaja
      read FUltimaSolicitud;
  end;

function CrearSolicitudValida: TSolicitudFacturacionCaja;
begin
  Result := Default(TSolicitudFacturacionCaja);
  Result.FechaDesde := EncodeDate(2026, 1, 1);
  Result.FechaHasta := EncodeDate(2026, 3, 31);
  Result.CodigoEmpresaDestino := 'EMP2';
  Result.Usuario := 'PRUEBAS';
end;

function TRepositorioFacturasProformaFalso.GenerarVenta(
  const ASolicitud: TSolicitudFacturacionCaja
): TResultadoFacturacionCaja;
begin
  Inc(FGeneracionesVenta);
  FUltimaSolicitud := ASolicitud;
  Result := Default(TResultadoFacturacionCaja);
  Result.CantidadDocumentos := 1;
  Result.CantidadOperaciones := 3;
  Result.CantidadAjustes := 1;
  Result.Descripcion := 'Proforma interna';
end;

function TRepositorioFacturasProformaFalso.GenerarTraspasos(
  const ASolicitud: TSolicitudFacturacionCaja
): TResultadoFacturacionCaja;
begin
  Inc(FGeneracionesTraspaso);
  FUltimaSolicitud := ASolicitud;
  Result := Default(TResultadoFacturacionCaja);
  Result.CantidadDocumentos := 2;
  Result.CantidadOperaciones := 4;
  Result.Descripcion := 'Facturas fiscales';
end;

procedure TPruebasFacturasProforma.Venta_UsaRepositorioDeProformas;
var
  Repositorio: TRepositorioFacturasProformaFalso;
  Servicio   : TFacturadorOperacionesCaja;
  Solicitud  : TSolicitudFacturacionCaja;
  Resultado  : TResultadoFacturacionCaja;
begin
  Repositorio := TRepositorioFacturasProformaFalso.Create;
  Servicio := TFacturadorOperacionesCaja.Create(Repositorio);
  try
    Solicitud := CrearSolicitudValida;
    Resultado := Servicio.Ejecutar(mfcVenta, Solicitud);
    Assert.AreEqual(1, Repositorio.GeneracionesVenta);
    Assert.AreEqual(0, Repositorio.GeneracionesTraspaso);
    Assert.AreEqual(3, Resultado.CantidadOperaciones);
    Assert.AreEqual(1, Resultado.CantidadAjustes);
    Assert.AreEqual('EMP2',
      Repositorio.UltimaSolicitud.CodigoEmpresaDestino);
  finally
    Servicio.Free;
  end;
end;

procedure TPruebasFacturasProforma.Traspaso_UsaRepositorioDeFacturas;
var
  Repositorio: TRepositorioFacturasProformaFalso;
  Servicio   : TFacturadorOperacionesCaja;
  Resultado  : TResultadoFacturacionCaja;
begin
  Repositorio := TRepositorioFacturasProformaFalso.Create;
  Servicio := TFacturadorOperacionesCaja.Create(Repositorio);
  try
    Resultado := Servicio.Ejecutar(
      mfcTraspaso,
      CrearSolicitudValida);
    Assert.AreEqual(0, Repositorio.GeneracionesVenta);
    Assert.AreEqual(1, Repositorio.GeneracionesTraspaso);
    Assert.AreEqual(2, Resultado.CantidadDocumentos);
    Assert.AreEqual(4, Resultado.CantidadOperaciones);
  finally
    Servicio.Free;
  end;
end;

procedure TPruebasFacturasProforma.PeriodoInverso_EsRechazado;
var
  Repositorio: IRepositorioFacturasProforma;
  Servicio   : TFacturadorOperacionesCaja;
  Solicitud  : TSolicitudFacturacionCaja;
begin
  Repositorio := TRepositorioFacturasProformaFalso.Create;
  Servicio := TFacturadorOperacionesCaja.Create(Repositorio);
  try
    Solicitud := CrearSolicitudValida;
    Solicitud.FechaDesde := Solicitud.FechaHasta + 1;
    Assert.WillRaise(
      procedure
      begin
        Servicio.Ejecutar(mfcVenta, Solicitud);
      end,
      EArgumentException);
  finally
    Servicio.Free;
  end;
end;

procedure TPruebasFacturasProforma.EmpresaDestinoVacia_EsRechazada;
var
  Repositorio: IRepositorioFacturasProforma;
  Servicio   : TFacturadorOperacionesCaja;
  Solicitud  : TSolicitudFacturacionCaja;
begin
  Repositorio := TRepositorioFacturasProformaFalso.Create;
  Servicio := TFacturadorOperacionesCaja.Create(Repositorio);
  try
    Solicitud := CrearSolicitudValida;
    Solicitud.CodigoEmpresaDestino := ' ';
    Assert.WillRaise(
      procedure
      begin
        Servicio.Ejecutar(mfcVenta, Solicitud);
      end,
      EArgumentException);
  finally
    Servicio.Free;
  end;
end;

procedure TPruebasFacturasProforma.UsuarioVacio_EsRechazado;
var
  Repositorio: IRepositorioFacturasProforma;
  Servicio   : TFacturadorOperacionesCaja;
  Solicitud  : TSolicitudFacturacionCaja;
begin
  Repositorio := TRepositorioFacturasProformaFalso.Create;
  Servicio := TFacturadorOperacionesCaja.Create(Repositorio);
  try
    Solicitud := CrearSolicitudValida;
    Solicitud.Usuario := '';
    Assert.WillRaise(
      procedure
      begin
        Servicio.Ejecutar(mfcTraspaso, Solicitud);
      end,
      EArgumentException);
  finally
    Servicio.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasFacturasProforma);

end.
