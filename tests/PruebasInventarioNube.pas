{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasInventarioNube                                         }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica la sincronización de recuentos con persistencia en memoria.      }
{******************************************************************************}
unit PruebasInventarioNube;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasInventarioNube = class
  public
    [Test]
    procedure RespuestaValidaGuardaEventoYAgregado;
    [Test]
    procedure ReintentoNoDuplicaEventos;
    [Test]
    procedure RespuestaInvalidaNoPersiste;
  end;

implementation

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  inLibInventarioNube,
  inLibInventarioNubePersistenciaIntf;

type
  TInventarioNubePersistenciaFalsa = class(
    TInterfacedObject,
    IInventarioNubePersistencia)
  private
    FEventos: TDictionary<string, Boolean>;
    FGuardados: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function ListarLineas(
      const AClave: TClaveInventarioNube): TLineasInventarioNube;
    function GuardarEventoSiNuevo(
      const AClave: TClaveInventarioNube;
      const AEvento: TEventoInventarioNube;
      const AUsuario: string): Boolean;
  end;

const
  RESPUESTA_RECUENTO =
    '{"eventos":[{' +
    '"uuid_evento":"EV-1",' +
    '"codigo_articulo":"ART-1",' +
    '"codigo_unidad":"SKU-1",' +
    '"codigo_barras":"840000000001",' +
    '"cantidad":2,' +
    '"lote":"L-1",' +
    '"fecha_caducidad":"2027-08-04",' +
    '"instante_recuento":"2026-08-04 10:00:00",' +
    '"operario":"OP-1",' +
    '"dispositivo":"MOVIL-1",' +
    '"zona":"A"}],' +
    '"agregado":[{' +
    '"codigo_unidad":"SKU-1",' +
    '"cantidad":2}]}';

constructor TInventarioNubePersistenciaFalsa.Create;
begin
  inherited Create;
  FEventos := TDictionary<string, Boolean>.Create;
end;

destructor TInventarioNubePersistenciaFalsa.Destroy;
begin
  FreeAndNil(FEventos);
  inherited;
end;

function TInventarioNubePersistenciaFalsa.ListarLineas(
  const AClave: TClaveInventarioNube): TLineasInventarioNube;
begin
  SetLength(Result, 0);
end;

function TInventarioNubePersistenciaFalsa.GuardarEventoSiNuevo(
  const AClave: TClaveInventarioNube;
  const AEvento: TEventoInventarioNube;
  const AUsuario: string): Boolean;
begin
  Result := not FEventos.ContainsKey(AEvento.Uuid);
  if Result then
  begin
    FEventos.Add(AEvento.Uuid, True);
    Inc(FGuardados);
  end;
end;

procedure PrepararClave(out AClave: TClaveInventarioNube);
begin
  AClave := Default(TClaveInventarioNube);
  AClave.Empresa := 'EMP-1';
  AClave.Almacen := 'ALM-1';
  AClave.Serie := 'I';
  AClave.Numero := '1';
end;

procedure TPruebasInventarioNube.RespuestaValidaGuardaEventoYAgregado;
var
  oPersistencia: TInventarioNubePersistenciaFalsa;
  oContrato: IInventarioNubePersistencia;
  oAgregado: TStringList;
  oClave: TClaveInventarioNube;
  iEventos: Integer;
begin
  PrepararClave(oClave);
  oPersistencia := TInventarioNubePersistenciaFalsa.Create;
  oContrato := oPersistencia;
  oAgregado := TStringList.Create;
  try
    Assert.IsTrue(
      AplicarRespuestaRecuento(
        RESPUESTA_RECUENTO,
        oContrato,
        oClave,
        'USUARIO',
        oAgregado,
        iEventos));
    Assert.AreEqual(1, iEventos);
    Assert.AreEqual(1, oPersistencia.FGuardados);
    Assert.AreEqual(1, oAgregado.Count);
    Assert.AreEqual('SKU-1=2', oAgregado[0]);
  finally
    FreeAndNil(oAgregado);
  end;
end;

procedure TPruebasInventarioNube.ReintentoNoDuplicaEventos;
var
  oPersistencia: TInventarioNubePersistenciaFalsa;
  oContrato: IInventarioNubePersistencia;
  oAgregado: TStringList;
  oClave: TClaveInventarioNube;
  iEventos: Integer;
begin
  PrepararClave(oClave);
  oPersistencia := TInventarioNubePersistenciaFalsa.Create;
  oContrato := oPersistencia;
  oAgregado := TStringList.Create;
  try
    Assert.IsTrue(
      AplicarRespuestaRecuento(
        RESPUESTA_RECUENTO,
        oContrato,
        oClave,
        'USUARIO',
        oAgregado,
        iEventos));
    Assert.AreEqual(1, iEventos);
    Assert.IsTrue(
      AplicarRespuestaRecuento(
        RESPUESTA_RECUENTO,
        oContrato,
        oClave,
        'USUARIO',
        oAgregado,
        iEventos));
    Assert.AreEqual(0, iEventos);
    Assert.AreEqual(1, oPersistencia.FGuardados);
    Assert.AreEqual(1, oAgregado.Count);
    Assert.AreEqual('SKU-1=2', oAgregado[0]);
  finally
    FreeAndNil(oAgregado);
  end;
end;

procedure TPruebasInventarioNube.RespuestaInvalidaNoPersiste;
var
  oPersistencia: TInventarioNubePersistenciaFalsa;
  oContrato: IInventarioNubePersistencia;
  oAgregado: TStringList;
  oClave: TClaveInventarioNube;
  iEventos: Integer;
begin
  PrepararClave(oClave);
  oPersistencia := TInventarioNubePersistenciaFalsa.Create;
  oContrato := oPersistencia;
  oAgregado := TStringList.Create;
  try
    Assert.IsFalse(
      AplicarRespuestaRecuento(
        '{',
        oContrato,
        oClave,
        'USUARIO',
        oAgregado,
        iEventos));
    Assert.AreEqual(0, iEventos);
    Assert.AreEqual(0, oPersistencia.FGuardados);
    Assert.AreEqual(0, oAgregado.Count);
  finally
    FreeAndNil(oAgregado);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasInventarioNube);

end.
