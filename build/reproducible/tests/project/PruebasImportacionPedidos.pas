{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasImportacionPedidos                                    }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica la coordinación de fuente y repositorio al importar pedidos.    }
{******************************************************************************}
unit PruebasImportacionPedidos;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasImportacionPedidos = class
  public
    [Test]
    procedure Listar_EntregaCredencialesALaFuente;
    [Test]
    procedure Ejecutar_ImportaYOmiteDuplicados;
    [Test]
    procedure Ejecutar_ErrorDeUnPedidoContinuaConElSiguiente;
  end;

implementation

uses
  System.SysUtils,
  inLibImportacionPedidos,
  inLibImportacionPedidosIntf,
  inLibPresta;

type
  TPedidoImportacionPrueba = class(TOrder)
  public
    destructor Destroy; override;
  end;
  TFuentePedidosImportacionPrueba = class(
    TInterfacedObject,
    IFuentePedidosImportacion)
  private
    FIdConError: string;
    FIdsCargados: TIdsPedidosImportacion;
  public
    function ListarResumen(
      ALista: TResumenPedidosImportacion): Boolean;
    function CargarPedido(const AIdPedido: string): TOrder;
    property IdConError: string read FIdConError write FIdConError;
    property IdsCargados: TIdsPedidosImportacion read FIdsCargados;
  end;
  TFabricaFuentePedidosImportacionPrueba = class(
    TInterfacedObject,
    IFabricaFuentePedidosImportacion)
  private
    FApiKey: string;
    FBaseURL: string;
    FFuente: IFuentePedidosImportacion;
  public
    constructor Create(const AFuente: IFuentePedidosImportacion);
    function Crear(
      const ABaseURL, AApiKey: string): IFuentePedidosImportacion;
    property ApiKey: string read FApiKey;
    property BaseURL: string read FBaseURL;
  end;
  TRepositorioImportacionPedidosPrueba = class(
    TInterfacedObject,
    IRepositorioImportacionPedidos)
  private
    FIdExistente: string;
    FIdsImportados: TIdsPedidosImportacion;
  public
    function Existe(const AIdPedido: string): Boolean;
    function Importar(APedido: TOrder): Boolean;
    property IdExistente: string read FIdExistente write FIdExistente;
    property IdsImportados: TIdsPedidosImportacion read FIdsImportados;
  end;

destructor TPedidoImportacionPrueba.Destroy;
begin
  FreeAndNil(LineasPedido);
  FreeAndNil(MensajesPedido.LMensajes);
  inherited;
end;

function TFuentePedidosImportacionPrueba.ListarResumen(
  ALista: TResumenPedidosImportacion): Boolean;
var
  oResumen: TResumenPedidoImportacion;
begin
  oResumen := Default(TResumenPedidoImportacion);
  oResumen.IdPedido := '10';
  oResumen.Referencia := 'PS-10';
  ALista.Add(oResumen);
  Result := True;
end;

function TFuentePedidosImportacionPrueba.CargarPedido(
  const AIdPedido: string): TOrder;
var
  iCantidad: Integer;
begin
  if AIdPedido = FIdConError then
    raise Exception.Create('Pedido no disponible');
  iCantidad := Length(FIdsCargados);
  SetLength(FIdsCargados, iCantidad + 1);
  FIdsCargados[iCantidad] := AIdPedido;
  Result := TPedidoImportacionPrueba.Create;
  Result.idPedido := AIdPedido;
end;

constructor TFabricaFuentePedidosImportacionPrueba.Create(
  const AFuente: IFuentePedidosImportacion);
begin
  inherited Create;
  FFuente := AFuente;
end;

function TFabricaFuentePedidosImportacionPrueba.Crear(
  const ABaseURL, AApiKey: string): IFuentePedidosImportacion;
begin
  FBaseURL := ABaseURL;
  FApiKey := AApiKey;
  Result := FFuente;
end;

function TRepositorioImportacionPedidosPrueba.Existe(
  const AIdPedido: string): Boolean;
begin
  Result := AIdPedido = FIdExistente;
end;

function TRepositorioImportacionPedidosPrueba.Importar(
  APedido: TOrder): Boolean;
var
  iCantidad: Integer;
begin
  iCantidad := Length(FIdsImportados);
  SetLength(FIdsImportados, iCantidad + 1);
  FIdsImportados[iCantidad] := APedido.idPedido;
  Result := True;
end;

function CrearSolicitud(
  const AIds: array of string): TSolicitudImportacionPedidos;
var
  i: Integer;
begin
  Result := Default(TSolicitudImportacionPedidos);
  Result.BaseURL := 'https://tienda.test/api';
  Result.ApiKey := 'api-key';
  SetLength(Result.IdsPedidos, Length(AIds));
  for i := 0 to Length(AIds) - 1 do
    Result.IdsPedidos[i] := AIds[i];
end;

procedure TPruebasImportacionPedidos.
  Listar_EntregaCredencialesALaFuente;
var
  oCasoUso: ICasoUsoImportacionPedidos;
  oFabrica: TFabricaFuentePedidosImportacionPrueba;
  oFuente: IFuentePedidosImportacion;
  oLista: TResumenPedidosImportacion;
  oRepositorio: IRepositorioImportacionPedidos;
begin
  oFuente := TFuentePedidosImportacionPrueba.Create;
  oFabrica := TFabricaFuentePedidosImportacionPrueba.Create(oFuente);
  oRepositorio := TRepositorioImportacionPedidosPrueba.Create;
  oCasoUso := CrearCasoUsoImportacionPedidos(oFabrica, oRepositorio);
  oLista := TResumenPedidosImportacion.Create;
  try
    Assert.IsTrue(oCasoUso.Listar(
      'https://tienda.test/api',
      'api-key',
      oLista));
    Assert.AreEqual('https://tienda.test/api', oFabrica.BaseURL);
    Assert.AreEqual('api-key', oFabrica.ApiKey);
    Assert.AreEqual(1, Integer(oLista.Count));
    Assert.AreEqual('10', oLista[0].IdPedido);
  finally
    FreeAndNil(oLista);
  end;
end;

procedure TPruebasImportacionPedidos.
  Ejecutar_ImportaYOmiteDuplicados;
var
  oCasoUso: ICasoUsoImportacionPedidos;
  oFabrica: IFabricaFuentePedidosImportacion;
  oFuente: TFuentePedidosImportacionPrueba;
  oRepositorio: TRepositorioImportacionPedidosPrueba;
  oResultado: TResultadoImportacionPedidos;
begin
  oFuente := TFuentePedidosImportacionPrueba.Create;
  oFabrica := TFabricaFuentePedidosImportacionPrueba.Create(oFuente);
  oRepositorio := TRepositorioImportacionPedidosPrueba.Create;
  oRepositorio.IdExistente := '2';
  oCasoUso := CrearCasoUsoImportacionPedidos(oFabrica, oRepositorio);
  oResultado := oCasoUso.Ejecutar(
    CrearSolicitud(['1', '2']),
    nil);
  Assert.AreEqual(1, oResultado.Importados);
  Assert.AreEqual(0, oResultado.Errores);
  Assert.AreEqual(1, Integer(Length(oFuente.IdsCargados)));
  Assert.AreEqual('1', oFuente.IdsCargados[0]);
  Assert.AreEqual(1, Integer(Length(oRepositorio.IdsImportados)));
  Assert.AreEqual('1', oRepositorio.IdsImportados[0]);
end;

procedure TPruebasImportacionPedidos.
  Ejecutar_ErrorDeUnPedidoContinuaConElSiguiente;
var
  oCasoUso: ICasoUsoImportacionPedidos;
  oFabrica: IFabricaFuentePedidosImportacion;
  oFuente: TFuentePedidosImportacionPrueba;
  oRepositorio: TRepositorioImportacionPedidosPrueba;
  oResultado: TResultadoImportacionPedidos;
begin
  oFuente := TFuentePedidosImportacionPrueba.Create;
  oFuente.IdConError := 'ERROR';
  oFabrica := TFabricaFuentePedidosImportacionPrueba.Create(oFuente);
  oRepositorio := TRepositorioImportacionPedidosPrueba.Create;
  oCasoUso := CrearCasoUsoImportacionPedidos(oFabrica, oRepositorio);
  oResultado := oCasoUso.Ejecutar(
    CrearSolicitud(['ERROR', '2']),
    nil);
  Assert.AreEqual(1, oResultado.Importados);
  Assert.AreEqual(1, oResultado.Errores);
  Assert.AreEqual(1, Integer(Length(oRepositorio.IdsImportados)));
  Assert.AreEqual('2', oRepositorio.IdsImportados[0]);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasImportacionPedidos);

end.
