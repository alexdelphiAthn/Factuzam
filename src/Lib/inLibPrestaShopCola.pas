{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPrestaShopCola                                          }
{    Tipo:       Librería                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       13/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Consume eventos de catálogo por artículo, sin recorrer el catálogo.       }
{******************************************************************************}
unit inLibPrestaShopCola;

interface

uses
  System.Classes, inLibContextoSesionIntf, inLibParametrosIntf,
  inLibPrestaShopColaIntf, inLibLogIntf;

type
  TPrestaShopCola = class
  private
    FHilo: TThread;
    FRegistroLog: IRegistroLog;
  public
    constructor Create(const ARegistroLog: IRegistroLog);
    destructor Destroy; override;
    procedure IniciarHilo(
      const AContextoSesion: IContextoSesionAplicacion;
      const AParametrosApp: IParametrosAplicacion;
      const AFabricaSesion: IFabricaSesionPrestaShopCola;
      const AUsuario: string);
    procedure DetenerHilo;
  end;

implementation

uses
  Winapi.ActiveX, Winapi.Windows, System.Math, System.SysUtils,
  inLibPrestaCatalogoIntf, inLibPrestaCatalogo;

const
  CToleranciaPrecio = 0.000001;
  CFilasPorCiclo = 10;
  CMinutosReclamacionCaducada = 10;

type
  THiloPrestaShopCola = class(TThread)
  private
    FSesion: ISesionPrestaShopCola;
    FRepositorio: IRepositorioPrestaShopCola;
    FContextoSesion: IContextoSesionAplicacion;
    FFabricaSesion: IFabricaSesionPrestaShopCola;
    FRegistroLog: IRegistroLog;
    FUsuario: string;
    FClaveOculta: string;
    FSegundosCiclo: Integer;
    FAvisoConfiguracion: Boolean;
    function ConfiguracionCompleta(
      const AConfiguracion: TConfiguracionGlobalPrestaShop): Boolean;
    function PrepararConfiguracion:
      TConfiguracionGlobalPrestaShop;
    function SigueVigente(
      const AConfiguracion: TConfiguracionGlobalPrestaShop): Boolean;
    procedure AsegurarLease(const ATrabajo: TTrabajoArticuloPrestaShop);
    procedure EsperarSegundos(ASegundos: Integer);
    procedure GuardarError(
      const ATrabajo: TTrabajoArticuloPrestaShop;
      const AConfiguracion: TConfiguracionGlobalPrestaShop;
      const AMensaje: string);
    procedure ProcesarArticulo(
      const ATrabajo: TTrabajoArticuloPrestaShop;
      const ACliente: IClienteCatalogoPresta);
    procedure ProcesarCiclo;
    procedure ProcesarFila(
      AIdCola: Int64;
      const ACliente: IClienteCatalogoPresta;
      const AConfiguracion: TConfiguracionGlobalPrestaShop);
    procedure ProcesarLinea(
      const ATrabajo: TTrabajoArticuloPrestaShop;
      const ALinea: TLineaArticuloPrestaShop;
      AIdProducto: Integer;
      const ACliente: IClienteCatalogoPresta);
    procedure ProcesarPendientes(
      const ACliente: IClienteCatalogoPresta;
      const AConfiguracion: TConfiguracionGlobalPrestaShop);
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AContextoSesion: IContextoSesionAplicacion;
      const AParametrosApp: IParametrosAplicacion;
      const AFabricaSesion: IFabricaSesionPrestaShopCola;
      const AUsuario: string;
      const ARegistroLog: IRegistroLog); reintroduce;
    destructor Destroy; override;
  end;

resourcestring
  SConfiguracionPrestaShopIncompleta =
    'Cola PrestaShop pendiente: faltan URL, API key, empresa, tarifa o ' +
    'identificador de tienda en la configuración global Todos.';
  SSesionPrestaShopNoCreada =
    'La fábrica no creó la sesión de cola PrestaShop.';
  SRepositorioPrestaShopNoCreado =
    'La sesión de cola PrestaShop no tiene repositorio.';
  STrabajoPrestaShopNoReclamado =
    'No se pudo leer el artículo reclamado de la cola PrestaShop.';
  SLeasePrestaShopPerdido =
    'La reclamación del artículo PrestaShop dejó de estar vigente.';
  SPrecioProductoPrestaShopAusente =
    'El artículo %s no tiene precio base vigente.';
  SPrecioProductoNoVerificado =
    'PrestaShop no confirmó el precio del producto %d.';
  SPrecioCombinacionNoVerificado =
    'PrestaShop no confirmó el impacto de precio de la combinación %d.';
  SStockPrestaShopNoVerificado =
    'PrestaShop no confirmó el stock %d.';
  SBarridoPrestaShopOmitido =
    'Barrido de respaldo PrestaShop omitido: %s';

function PrecioDiferente(AActual, ADeseado: Double): Boolean;
begin
  Result := IsNan(AActual) or IsInfinite(AActual) or
            IsNan(ADeseado) or IsInfinite(ADeseado) or
            (Abs(AActual - ADeseado) > CToleranciaPrecio);
end;

function OcultarClave(const AMensaje, AClave: string): string;
begin
  Result := AMensaje;
  if AClave <> '' then
    Result := StringReplace(
      Result,
      AClave,
      '[oculta]',
      [rfReplaceAll, rfIgnoreCase]);
end;

function CalcularEspera(AIntentos: Integer): Integer;
begin
  if AIntentos < 0 then
    AIntentos := 0;
  if AIntentos > 6 then
    AIntentos := 6;
  Result := 60 * (1 shl AIntentos);
end;

{ TPrestaShopCola }

constructor TPrestaShopCola.Create(const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  FRegistroLog := ARegistroLog;
end;

destructor TPrestaShopCola.Destroy;
begin
  DetenerHilo;
  FRegistroLog := nil;
  inherited;
end;

procedure TPrestaShopCola.IniciarHilo(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const AFabricaSesion: IFabricaSesionPrestaShopCola;
  const AUsuario: string);
var
  oHilo: TThread;
begin
  if FHilo = nil then
  begin
    oHilo := THiloPrestaShopCola.Create(
      AContextoSesion,
      AParametrosApp,
      AFabricaSesion,
      AUsuario,
      FRegistroLog);
    try
      oHilo.FreeOnTerminate := False;
      oHilo.Start;
      FHilo := oHilo;
      oHilo := nil;
      if Assigned(FRegistroLog) then
        FRegistroLog.RegistrarInformacion(
          'Cola PrestaShop por artículo: hilo iniciado');
    finally
      FreeAndNil(oHilo);
    end;
  end;
end;

procedure TPrestaShopCola.DetenerHilo;
begin
  if FHilo <> nil then
  begin
    FHilo.Terminate;
    FHilo.WaitFor;
    FreeAndNil(FHilo);
    if Assigned(FRegistroLog) then
      FRegistroLog.RegistrarInformacion(
        'Cola PrestaShop por artículo: hilo detenido');
  end;
end;

{ THiloPrestaShopCola }

constructor THiloPrestaShopCola.Create(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const AFabricaSesion: IFabricaSesionPrestaShopCola;
  const AUsuario: string;
  const ARegistroLog: IRegistroLog);
begin
  if not Assigned(AContextoSesion) then
    raise EArgumentNilException.Create('AContextoSesion');
  if not Assigned(AParametrosApp) then
    raise EArgumentNilException.Create('AParametrosApp');
  if not Assigned(AFabricaSesion) then
    raise EArgumentNilException.Create('AFabricaSesion');
  inherited Create(True);
  FContextoSesion := AContextoSesion;
  FFabricaSesion := AFabricaSesion;
  FUsuario := Trim(AUsuario);
  if FUsuario = '' then
    FUsuario := 'SISTEMA';
  FRegistroLog := ARegistroLog;
  FSegundosCiclo := 60;
end;

destructor THiloPrestaShopCola.Destroy;
begin
  FRepositorio := nil;
  FSesion := nil;
  FFabricaSesion := nil;
  FContextoSesion := nil;
  FRegistroLog := nil;
  inherited;
end;

function THiloPrestaShopCola.ConfiguracionCompleta(
  const AConfiguracion: TConfiguracionGlobalPrestaShop): Boolean;
begin
  Result := (AConfiguracion.UrlApi <> '') and
            (AConfiguracion.ClaveApi <> '') and
            (AConfiguracion.Cola.ClaveInstalacion <> '') and
            (AConfiguracion.Cola.CodigoEmpresa <> '') and
            (AConfiguracion.Cola.CodigoTarifa <> '') and
            (AConfiguracion.Cola.IdTienda > 0);
end;

function THiloPrestaShopCola.PrepararConfiguracion:
  TConfiguracionGlobalPrestaShop;
begin
  Result := FRepositorio.LeerConfiguracionGlobal;
  FSegundosCiclo := Result.SegundosCiclo;
  FClaveOculta := Result.ClaveApi;
  if Result.Activo and (Result.UrlApi <> '') then
    Result.Cola.ClaveInstalacion :=
      CalcularClaveInstalacionPresta(Result.UrlApi);
end;

function THiloPrestaShopCola.SigueVigente(
  const AConfiguracion: TConfiguracionGlobalPrestaShop): Boolean;
var
  oActual: TConfiguracionGlobalPrestaShop;
begin
  oActual := PrepararConfiguracion;
  Result := oActual.Activo and
    SameText(oActual.UrlApi, AConfiguracion.UrlApi) and
    (oActual.ClaveApi = AConfiguracion.ClaveApi) and
    SameText(
      oActual.Cola.ClaveInstalacion,
      AConfiguracion.Cola.ClaveInstalacion) and
    (oActual.Cola.IdTienda = AConfiguracion.Cola.IdTienda) and
    (oActual.Cola.StockActivo = AConfiguracion.Cola.StockActivo) and
    (oActual.HorasBarrido = AConfiguracion.HorasBarrido) and
    SameText(
      oActual.Cola.CodigoEmpresa,
      AConfiguracion.Cola.CodigoEmpresa) and
    SameText(
      oActual.Cola.CodigoTarifa,
      AConfiguracion.Cola.CodigoTarifa);
end;

procedure THiloPrestaShopCola.AsegurarLease(
  const ATrabajo: TTrabajoArticuloPrestaShop);
begin
  if not FRepositorio.RenovarReclamacion(
    ATrabajo.IdCola,
    ATrabajo.Token) then
    raise EInvalidOpException.Create(SLeasePrestaShopPerdido);
end;

procedure THiloPrestaShopCola.Execute;
var
  iInicializacionCom: HRESULT;
  sMensaje: string;
begin
  iInicializacionCom := CoInitializeEx(nil, COINIT_APARTMENTTHREADED);
  try
    NameThreadForDebugging('PrestaShopCola');
    FAvisoConfiguracion := False;
    while (not Terminated) and
          (not FContextoSesion.CerrandoAplicacion) do
    begin
      try
        ProcesarCiclo;
      except
        on E: Exception do
        begin
          sMensaje := OcultarClave(E.Message, FClaveOculta);
          if Assigned(FRegistroLog) then
            FRegistroLog.RegistrarError(
              'Cola PrestaShop: ' + sMensaje);
          FRepositorio := nil;
          FSesion := nil;
        end;
      end;
      if (not Terminated) and
         (not FContextoSesion.CerrandoAplicacion) then
        EsperarSegundos(FSegundosCiclo);
    end;
  finally
    if Succeeded(iInicializacionCom) then
      CoUninitialize;
  end;
end;

procedure THiloPrestaShopCola.EsperarSegundos(ASegundos: Integer);
var
  iPaso: Integer;
  iPasos: Integer;
begin
  if ASegundos < 1 then
    ASegundos := 1;
  if ASegundos > 300 then
    ASegundos := 300;
  iPasos := ASegundos * 10;
  iPaso := 0;
  while (iPaso < iPasos) and (not Terminated) and
        (not FContextoSesion.CerrandoAplicacion) do
  begin
    Sleep(100);
    Inc(iPaso);
  end;
end;

procedure THiloPrestaShopCola.ProcesarCiclo;
var
  oCliente: IClienteCatalogoPresta;
  oConfiguracion: TConfiguracionGlobalPrestaShop;
  sMensaje: string;
begin
  if FSesion = nil then
  begin
    FSesion := FFabricaSesion.CrearSesion;
    if not Assigned(FSesion) then
      raise EInvalidOpException.Create(SSesionPrestaShopNoCreada);
    FRepositorio := FSesion.Repositorio;
    if not Assigned(FRepositorio) then
      raise EInvalidOpException.Create(SRepositorioPrestaShopNoCreado);
  end;
  oConfiguracion := PrepararConfiguracion;
  if oConfiguracion.Activo and ConfiguracionCompleta(oConfiguracion) then
  begin
    FAvisoConfiguracion := False;
    oCliente := TClienteCatalogoPresta.Create(
      oConfiguracion.UrlApi,
      oConfiguracion.ClaveApi);
    FRepositorio.ReencolarProcesandoCaducadas(
      oConfiguracion.Cola.ClaveInstalacion,
      oConfiguracion.Cola.IdTienda,
      CMinutosReclamacionCaducada);
    try
      FRepositorio.ReconciliarSiProcede(
        oConfiguracion.HorasBarrido,
        oConfiguracion.Cola.StockActivo,
        FUsuario);
    except
      on E: Exception do
      begin
        sMensaje := OcultarClave(E.Message, FClaveOculta);
        if Assigned(FRegistroLog) then
          FRegistroLog.RegistrarAviso(
            Format(SBarridoPrestaShopOmitido, [sMensaje]));
      end;
    end;
    ProcesarPendientes(oCliente, oConfiguracion);
  end
  else
  begin
    if oConfiguracion.Activo and (not FAvisoConfiguracion) then
    begin
      if Assigned(FRegistroLog) then
        FRegistroLog.RegistrarAviso(SConfiguracionPrestaShopIncompleta);
      FAvisoConfiguracion := True;
    end;
    if not oConfiguracion.Activo then
      FAvisoConfiguracion := False;
  end;
end;

procedure THiloPrestaShopCola.ProcesarPendientes(
  const ACliente: IClienteCatalogoPresta;
  const AConfiguracion: TConfiguracionGlobalPrestaShop);
var
  aPendientes: TArray<Int64>;
  bContinuar: Boolean;
  iIndice: Integer;
begin
  bContinuar := True;
  while bContinuar and (not Terminated) and
        (not FContextoSesion.CerrandoAplicacion) do
  begin
    aPendientes := FRepositorio.BuscarPendientes(
      AConfiguracion.Cola.ClaveInstalacion,
      AConfiguracion.Cola.IdTienda,
      CFilasPorCiclo);
    bContinuar := Length(aPendientes) > 0;
    iIndice := 0;
    while (iIndice <= High(aPendientes)) and bContinuar and
          (not Terminated) and
          (not FContextoSesion.CerrandoAplicacion) do
    begin
      bContinuar := SigueVigente(AConfiguracion);
      if bContinuar then
        ProcesarFila(
          aPendientes[iIndice],
          ACliente,
          AConfiguracion);
      Inc(iIndice);
    end;
  end;
end;

procedure THiloPrestaShopCola.ProcesarFila(
  AIdCola: Int64;
  const ACliente: IClienteCatalogoPresta;
  const AConfiguracion: TConfiguracionGlobalPrestaShop);
var
  oTrabajo: TTrabajoArticuloPrestaShop;
  sToken: string;
begin
  if FRepositorio.MarcarProcesando(
    AIdCola,
    AConfiguracion.Cola.ClaveInstalacion,
    AConfiguracion.Cola.IdTienda,
    FUsuario,
    sToken) then
  begin
    oTrabajo := Default(TTrabajoArticuloPrestaShop);
    oTrabajo.IdCola := AIdCola;
    oTrabajo.Token := sToken;
    try
      oTrabajo := FRepositorio.LeerTrabajo(
        AIdCola,
        sToken,
        AConfiguracion.Cola);
      if oTrabajo.IdCola = 0 then
        oTrabajo.IdCola := AIdCola;
      oTrabajo.Token := sToken;
      if oTrabajo.CodigoArticulo = '' then
        raise EInvalidOpException.Create(STrabajoPrestaShopNoReclamado);
      if oTrabajo.EstaEnWeb and
         ((oTrabajo.TienePrecio and
           oTrabajo.TienePrecioProducto) or
          oTrabajo.TieneStock) then
      begin
        AsegurarLease(oTrabajo);
        if not SigueVigente(AConfiguracion) then
          raise EInvalidOpException.Create(
            'La configuración global PrestaShop cambió durante el envío');
        ProcesarArticulo(oTrabajo, ACliente);
      end;
      FRepositorio.MarcarEnviada(
        oTrabajo.IdCola,
        oTrabajo.Token,
        FUsuario,
        oTrabajo.TieneProximoCambioPrecio,
        oTrabajo.ProximoCambioPrecio);
    except
      on E: Exception do
        GuardarError(oTrabajo, AConfiguracion, E.Message);
    end;
  end;
end;

procedure THiloPrestaShopCola.ProcesarArticulo(
  const ATrabajo: TTrabajoArticuloPrestaShop;
  const ACliente: IClienteCatalogoPresta);
var
  dActual: Double;
  iLinea: Integer;
  iProducto: Integer;
begin
  AsegurarLease(ATrabajo);
  iProducto := ACliente.BuscarProductoUnico(
    ATrabajo.CodigoArticulo,
    ATrabajo.IdTienda);
  AsegurarLease(ATrabajo);
  if ATrabajo.TienePrecio then
  begin
    if not ATrabajo.TienePrecioProducto then
      raise EInvalidOpException.CreateFmt(
        SPrecioProductoPrestaShopAusente,
        [ATrabajo.CodigoArticulo]);
    AsegurarLease(ATrabajo);
    dActual := ACliente.LeerPrecioProducto(
      iProducto,
      ATrabajo.IdTienda);
    if PrecioDiferente(dActual, ATrabajo.PrecioProducto) then
    begin
      AsegurarLease(ATrabajo);
      ACliente.ActualizarPrecioProducto(
        iProducto,
        ATrabajo.IdTienda,
        ATrabajo.PrecioProducto);
    end;
    AsegurarLease(ATrabajo);
    dActual := ACliente.LeerPrecioProducto(
      iProducto,
      ATrabajo.IdTienda);
    if PrecioDiferente(dActual, ATrabajo.PrecioProducto) then
      raise EInvalidOpException.CreateFmt(
        SPrecioProductoNoVerificado,
        [iProducto]);
  end;
  iLinea := 0;
  while iLinea <= High(ATrabajo.Lineas) do
  begin
    AsegurarLease(ATrabajo);
    ProcesarLinea(
      ATrabajo,
      ATrabajo.Lineas[iLinea],
      iProducto,
      ACliente);
    Inc(iLinea);
  end;
end;

procedure THiloPrestaShopCola.ProcesarLinea(
  const ATrabajo: TTrabajoArticuloPrestaShop;
  const ALinea: TLineaArticuloPrestaShop;
  AIdProducto: Integer;
  const ACliente: IClienteCatalogoPresta);
var
  dActual: Double;
  dImpacto: Double;
  iActual: Integer;
  iAtributo: Integer;
  iStock: Integer;
  oStock: TStockDisponiblePresta;
begin
  iAtributo := 0;
  if ALinea.EsCombinacion then
  begin
    AsegurarLease(ATrabajo);
    iAtributo := ACliente.BuscarCombinacionUnica(
      ALinea.CodigoSku,
      AIdProducto,
      ATrabajo.IdTienda);
  end;
  if ALinea.TienePrecio then
  begin
    dImpacto := ALinea.Precio - ATrabajo.PrecioProducto;
    AsegurarLease(ATrabajo);
    dActual := ACliente.LeerImpactoPrecioCombinacion(
      iAtributo,
      ATrabajo.IdTienda);
    if PrecioDiferente(dActual, dImpacto) then
    begin
      AsegurarLease(ATrabajo);
      ACliente.ActualizarImpactoPrecioCombinacion(
        iAtributo,
        ATrabajo.IdTienda,
        dImpacto);
    end;
    AsegurarLease(ATrabajo);
    dActual := ACliente.LeerImpactoPrecioCombinacion(
      iAtributo,
      ATrabajo.IdTienda);
    if PrecioDiferente(dActual, dImpacto) then
      raise EInvalidOpException.CreateFmt(
        SPrecioCombinacionNoVerificado,
        [iAtributo]);
  end;
  if ALinea.TieneStock then
  begin
    AsegurarLease(ATrabajo);
    oStock := ACliente.ResolverStockDisponible(
      AIdProducto,
      iAtributo,
      ATrabajo.IdTienda);
    iStock := oStock.Id;
    AsegurarLease(ATrabajo);
    iActual := ACliente.LeerCantidadStock(
      iStock,
      ATrabajo.IdTienda);
    if iActual <> ALinea.Cantidad then
    begin
      AsegurarLease(ATrabajo);
      ACliente.ActualizarCantidadStock(
        iStock,
        ATrabajo.IdTienda,
        ALinea.Cantidad);
    end;
    AsegurarLease(ATrabajo);
    iActual := ACliente.LeerCantidadStock(
      iStock,
      ATrabajo.IdTienda);
    if iActual <> ALinea.Cantidad then
      raise EInvalidOpException.CreateFmt(
        SStockPrestaShopNoVerificado,
        [iStock]);
  end;
end;

procedure THiloPrestaShopCola.GuardarError(
  const ATrabajo: TTrabajoArticuloPrestaShop;
  const AConfiguracion: TConfiguracionGlobalPrestaShop;
  const AMensaje: string);
var
  iEspera: Integer;
  sEstado: string;
  sMensaje: string;
begin
  iEspera := CalcularEspera(ATrabajo.Intentos);
  if (ATrabajo.Intentos + 1) >= AConfiguracion.MaxIntentos then
    sEstado := 'ERROR'
  else
    sEstado := 'PENDIENTE';
  sMensaje := OcultarClave(AMensaje, AConfiguracion.ClaveApi);
  FRepositorio.GuardarErrorIntento(
    ATrabajo.IdCola,
    ATrabajo.Token,
    sEstado,
    iEspera,
    sMensaje,
    FUsuario);
  if Assigned(FRegistroLog) then
    FRegistroLog.RegistrarAviso(
      Format(
        'Cola PrestaShop, artículo %s: %s',
        [ATrabajo.CodigoArticulo, sMensaje]));
end;

end.
