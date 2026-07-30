{******************************************************************************}
{                                                                              }
{  Módulo:       DoblesComprasSesiones                                         }
{    Tipo:       Librería                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Dobles en memoria de los contratos de sesiones de compra.                 }
{******************************************************************************}
unit DoblesComprasSesiones;

interface

uses
  inLibComprasSesionesIntf,
  inLibComprasSesionesMaterializacionIntf;

type
  TRepositorioComprasSesionesMemoria = class(
    TInterfacedObject,
    IRepositorioLecturasComprasSesiones,
    IRepositorioComprasSesiones)
  private
    FCodigoArticuloPreferido: string;
    FCodigoBuscado: string;
    FCodigoProveedor: string;
    FDuplicado: TResolverDuplicadoSesion;
    FIncidencias: TIncidenciasSesionCompra;
    FSoloRefProveedor: Boolean;
    procedure AplicarDuplicadoEnLinea(
      const AResultado: TResolverDuplicadoSesion);
    procedure BorrarCeldasLinea(
      const ASerie, ANumero: string;
      ALinea: Integer);
    procedure CopiarCeldasDistribuidas(
      const ASerie, ANumero, AAlmacenCabecera, AUsuario: string;
      ALineaOrigen, ALineaDestino: Integer);
    function ObtenerSiguienteLinea(
      const ASerie, ANumero: string;
      ALineaActual: Integer): Integer;
    function ConsultarCantidadesLinea(
      const ASerie, ANumero: string;
      ALinea: Integer): TCantidadesPivotSesion;
    function ConsultarCodigosBasicosActivos(
      const AIdVariacion: string): TArray<string>;
    function ConsultarKitProveedor(
      const ACodigoProveedor, ACodigoKit: string;
      AIdAcLinea: Integer): TKitProveedorSesion;
    function ConsultarDetallesKitProveedor(
      const ACodigoProveedor, ACodigoKit: string):
      TDetallesKitProveedorSesion;
    function ObtenerNombreFamilia(
      const ACodigoFamilia: string): string;
    function ResolverCodigoFamilia(
      const ACodigoTecleado, AUsuario: string;
      out ACodigoGenerado: string): Boolean;
    function ResolverDuplicado(
      const ACodigoBuscado, ACodigoProveedor: string;
      ASoloRefProveedor: Boolean;
      const ACodigoArticuloPreferido: string):
      TResolverDuplicadoSesion;
    function ResolverDuplicadoIntraSesion(
      const ASerie, ANumero: string;
      ALineaActual: Integer;
      const AModelo, ACodigoArticulo: string):
      TResolverDuplicadoSesion;
    function NormalizarDuplicadosIntraSesion(
      const AUsuario, ASerie, ANumero: string): Integer;
    function ValidarSesionDetallado:
      TIncidenciasSesionCompra;
  public
    property CodigoArticuloPreferido: string
      read FCodigoArticuloPreferido;
    property CodigoBuscado: string
      read FCodigoBuscado;
    property CodigoProveedor: string
      read FCodigoProveedor;
    property Duplicado: TResolverDuplicadoSesion
      read FDuplicado write FDuplicado;
    property Incidencias: TIncidenciasSesionCompra
      read FIncidencias write FIncidencias;
    property SoloRefProveedor: Boolean
      read FSoloRefProveedor;
  end;
  TLecturasMaterializacionComprasSesionesMemoria = class(
    TInterfacedObject,
    ILecturasMaterializacionComprasSesiones)
  private
    FAlmacenes: TArray<string>;
    function ObtenerSiguienteSecuenciaEan(
      const APrefijo: string;
      ALongitudSecuencia: Integer): Int64;
    function ObtenerIdColorBasico(
      const ACodigoColor: string): Integer;
    function BuscarValorColor(
      const AValor: string): TValorColorMaterializacion;
    function ObtenerColorLinea(
      const ASerie, ANumero: string;
      ALinea: Integer): TColorLineaMaterializacion;
    function ConsultarSkusSesion(
      const ASerie, ANumero: string;
      ALinea: Integer): TSkusSesionMaterializacion;
    function ExisteEan13Sku(
      const ACodigoSku: string): Boolean;
    function ExisteProveedorPrincipalDistinto(
      const ACodigoArticulo,
      ACodigoProveedor: string): Boolean;
    function ObtenerCodigoUnicoTarifa(
      const ACodigoArticulo,
      ACodigoTarifa: string): Integer;
    function ResolverCodigoSku(
      const ACodigoArticulo: string;
      AIdAvPivot, AIdAvFila: Integer): string;
    function ConsultarLineasArticulos(
      const ASerie, ANumero: string):
      TLineasArticuloMaterializacion;
    function ConsultarLineasDocumento(
      const ASerie, ANumero, AAlmacenCabecera,
      AFiltroAlmacen: string):
      TLineasDocumentoCompraMaterializacion;
    function ConsultarAlmacenes(
      const ASerie, ANumero,
      AAlmacenCabecera: string): TArray<string>;
    function ConsultarPendientesRecibir(
      const ASerie, ANumero,
      AAlmacenCabecera: string):
      TPendientesRecibirMaterializacion;
    function ExisteTabla(
      const ATabla: string): Boolean;
    function ConsultarMovimientosHuerfanos(
      const AEmpresa, AAlmacen: string): TArray<string>;
  public
    property Almacenes: TArray<string>
      read FAlmacenes write FAlmacenes;
  end;
  TUnidadTrabajoMaterializacionMemoria = class(
    TInterfacedObject,
    IUnidadTrabajoMaterializacion)
  private
    FConfirmaciones: Integer;
    FEnCurso: Boolean;
    FInicios: Integer;
    FReversiones: Integer;
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  public
    property Confirmaciones: Integer
      read FConfirmaciones;
    property EnCurso: Boolean
      read FEnCurso;
    property Inicios: Integer
      read FInicios;
    property Reversiones: Integer
      read FReversiones;
  end;
  TControlTransaccionMaterializacionMemoria = class(
    TInterfacedObject,
    IControlTransaccionMaterializacion)
  private
    FConfirmaciones: Integer;
    FEnTransaccion: Boolean;
    FInicios: Integer;
    FReversiones: Integer;
    function EnTransaccion: Boolean;
    procedure IniciarTransaccion;
    procedure ConfirmarTransaccion;
    procedure RevertirTransaccion;
  public
    property Confirmaciones: Integer
      read FConfirmaciones;
    property EstadoTransaccion: Boolean
      read FEnTransaccion write FEnTransaccion;
    property Inicios: Integer
      read FInicios;
    property Reversiones: Integer
      read FReversiones;
  end;
  TPersistenciaMaterializacionMemoria = class(
    TInterfacedObject,
    IPersistenciaMaterializacionComprasSesiones,
    IPersistenciaReversionComprasSesiones)
  private
    FAlbaranes: Integer;
    FAlmacenes: TArray<string>;
    FArticulos: Integer;
    FCierres: Integer;
    FConfiguracion: TConfiguracionMaterializacionSesion;
    FErrores: Integer;
    FFalloEn: string;
    FMensajeError: string;
    FOperaciones: string;
    FPedidos: Integer;
    FReversiones: Integer;
    FValidaMaterializacion: Boolean;
    FValidaReversion: Boolean;
    procedure Anotar(const AOperacion: string);
    procedure ComprobarFallo(const AOperacion: string);
    function ValidarMaterializacion(
      out AMensajeError: string): Boolean;
    function CargarConfiguracion:
      TConfiguracionMaterializacionSesion;
    function ConsultarAlmacenes: TArray<string>;
    function ResolverSerieDocumento(
      const AEmpresa, ATipoDocumento, AAlmacen,
      ASerieAlternativa: string): string;
    procedure MaterializarArticulos(
      const AUsuario: string);
    function MaterializarPedido(
      const AUsuario, ASerie, AAlmacen: string):
      TDocumentoMaterializado;
    function MaterializarAlbaran(
      const AUsuario, ASerie, AAlmacen: string):
      TDocumentoMaterializado;
    procedure CerrarSesion(
      const APedido, AAlbaran: TDocumentoMaterializado;
      const AUsuario: string);
    procedure RegistrarError(
      const AUsuario, AMensaje: string);
    function ValidarReversion(
      out AMensajeError: string): Boolean;
    procedure EjecutarReversion(
      const AUsuario: string);
  public
    constructor Create;
    property Albaranes: Integer
      read FAlbaranes;
    property Almacenes: TArray<string>
      read FAlmacenes write FAlmacenes;
    property Articulos: Integer
      read FArticulos;
    property Cierres: Integer
      read FCierres;
    property Configuracion: TConfiguracionMaterializacionSesion
      read FConfiguracion write FConfiguracion;
    property Errores: Integer
      read FErrores;
    property FalloEn: string
      read FFalloEn write FFalloEn;
    property MensajeError: string
      read FMensajeError write FMensajeError;
    property Operaciones: string
      read FOperaciones;
    property Pedidos: Integer
      read FPedidos;
    property Reversiones: Integer
      read FReversiones;
    property ValidaMaterializacion: Boolean
      read FValidaMaterializacion write FValidaMaterializacion;
    property ValidaReversion: Boolean
      read FValidaReversion write FValidaReversion;
  end;

implementation

uses
  System.SysUtils;

procedure TRepositorioComprasSesionesMemoria.AplicarDuplicadoEnLinea(
  const AResultado: TResolverDuplicadoSesion);
begin
end;

procedure TRepositorioComprasSesionesMemoria.BorrarCeldasLinea(
  const ASerie, ANumero: string;
  ALinea: Integer);
begin
end;

procedure TRepositorioComprasSesionesMemoria.CopiarCeldasDistribuidas(
  const ASerie, ANumero, AAlmacenCabecera, AUsuario: string;
  ALineaOrigen, ALineaDestino: Integer);
begin
end;

function TRepositorioComprasSesionesMemoria.ObtenerSiguienteLinea(
  const ASerie, ANumero: string;
  ALineaActual: Integer): Integer;
begin
  Result := 0;
end;

function TRepositorioComprasSesionesMemoria.ConsultarCantidadesLinea(
  const ASerie, ANumero: string;
  ALinea: Integer): TCantidadesPivotSesion;
begin
  Result := nil;
end;

function TRepositorioComprasSesionesMemoria.
  ConsultarCodigosBasicosActivos(
    const AIdVariacion: string): TArray<string>;
begin
  Result := nil;
end;

function TRepositorioComprasSesionesMemoria.
  ConsultarKitProveedor(
  const ACodigoProveedor, ACodigoKit: string;
  AIdAcLinea: Integer): TKitProveedorSesion;
begin
  Result := Default(TKitProveedorSesion);
end;

function TRepositorioComprasSesionesMemoria.
  ConsultarDetallesKitProveedor(
  const ACodigoProveedor, ACodigoKit: string):
  TDetallesKitProveedorSesion;
begin
  Result := nil;
end;

function TRepositorioComprasSesionesMemoria.ObtenerNombreFamilia(
  const ACodigoFamilia: string): string;
begin
  Result := '';
end;

function TRepositorioComprasSesionesMemoria.ResolverCodigoFamilia(
  const ACodigoTecleado, AUsuario: string;
  out ACodigoGenerado: string): Boolean;
begin
  ACodigoGenerado := '';
  Result := False;
end;

function TRepositorioComprasSesionesMemoria.ResolverDuplicado(
  const ACodigoBuscado, ACodigoProveedor: string;
  ASoloRefProveedor: Boolean;
  const ACodigoArticuloPreferido: string):
  TResolverDuplicadoSesion;
begin
  FCodigoBuscado := ACodigoBuscado;
  FCodigoProveedor := ACodigoProveedor;
  FSoloRefProveedor := ASoloRefProveedor;
  FCodigoArticuloPreferido := ACodigoArticuloPreferido;
  Result := FDuplicado;
end;

function TRepositorioComprasSesionesMemoria.
  ResolverDuplicadoIntraSesion(
    const ASerie, ANumero: string;
    ALineaActual: Integer;
    const AModelo, ACodigoArticulo: string):
    TResolverDuplicadoSesion;
begin
  Result := Default(TResolverDuplicadoSesion);
end;

function TRepositorioComprasSesionesMemoria.
  NormalizarDuplicadosIntraSesion(
    const AUsuario, ASerie, ANumero: string): Integer;
begin
  Result := 0;
end;

function TRepositorioComprasSesionesMemoria.ValidarSesionDetallado:
  TIncidenciasSesionCompra;
begin
  Result := FIncidencias;
end;

function TLecturasMaterializacionComprasSesionesMemoria.
  ObtenerSiguienteSecuenciaEan(
    const APrefijo: string;
    ALongitudSecuencia: Integer): Int64;
begin
  Result := 1;
end;

function TLecturasMaterializacionComprasSesionesMemoria.
  ObtenerIdColorBasico(
    const ACodigoColor: string): Integer;
begin
  Result := 0;
end;

function TLecturasMaterializacionComprasSesionesMemoria.
  BuscarValorColor(
    const AValor: string): TValorColorMaterializacion;
begin
  Result := Default(TValorColorMaterializacion);
end;

function TLecturasMaterializacionComprasSesionesMemoria.
  ObtenerColorLinea(
    const ASerie, ANumero: string;
    ALinea: Integer): TColorLineaMaterializacion;
begin
  Result := Default(TColorLineaMaterializacion);
end;

function TLecturasMaterializacionComprasSesionesMemoria.
  ConsultarSkusSesion(
    const ASerie, ANumero: string;
    ALinea: Integer): TSkusSesionMaterializacion;
begin
  Result := nil;
end;

function TLecturasMaterializacionComprasSesionesMemoria.
  ExisteEan13Sku(
    const ACodigoSku: string): Boolean;
begin
  Result := False;
end;

function TLecturasMaterializacionComprasSesionesMemoria.
  ExisteProveedorPrincipalDistinto(
    const ACodigoArticulo,
    ACodigoProveedor: string): Boolean;
begin
  Result := False;
end;

function TLecturasMaterializacionComprasSesionesMemoria.
  ObtenerCodigoUnicoTarifa(
    const ACodigoArticulo,
    ACodigoTarifa: string): Integer;
begin
  Result := 0;
end;

function TLecturasMaterializacionComprasSesionesMemoria.
  ResolverCodigoSku(
    const ACodigoArticulo: string;
    AIdAvPivot, AIdAvFila: Integer): string;
begin
  Result := '';
end;

function TLecturasMaterializacionComprasSesionesMemoria.
  ConsultarLineasArticulos(
    const ASerie, ANumero: string):
    TLineasArticuloMaterializacion;
begin
  Result := nil;
end;

function TLecturasMaterializacionComprasSesionesMemoria.
  ConsultarLineasDocumento(
    const ASerie, ANumero, AAlmacenCabecera,
    AFiltroAlmacen: string):
    TLineasDocumentoCompraMaterializacion;
begin
  Result := nil;
end;

function TLecturasMaterializacionComprasSesionesMemoria.
  ConsultarAlmacenes(
    const ASerie, ANumero,
    AAlmacenCabecera: string): TArray<string>;
begin
  Result := FAlmacenes;
end;

function TLecturasMaterializacionComprasSesionesMemoria.
  ConsultarPendientesRecibir(
    const ASerie, ANumero,
    AAlmacenCabecera: string):
    TPendientesRecibirMaterializacion;
begin
  Result := nil;
end;

function TLecturasMaterializacionComprasSesionesMemoria.
  ExisteTabla(
    const ATabla: string): Boolean;
begin
  Result := False;
end;

function TLecturasMaterializacionComprasSesionesMemoria.
  ConsultarMovimientosHuerfanos(
    const AEmpresa, AAlmacen: string): TArray<string>;
begin
  Result := nil;
end;

procedure TUnidadTrabajoMaterializacionMemoria.Iniciar;
begin
  Inc(FInicios);
  FEnCurso := True;
end;

procedure TUnidadTrabajoMaterializacionMemoria.Confirmar;
begin
  Inc(FConfirmaciones);
  FEnCurso := False;
end;

procedure TUnidadTrabajoMaterializacionMemoria.Revertir;
begin
  Inc(FReversiones);
  FEnCurso := False;
end;

function TControlTransaccionMaterializacionMemoria.
  EnTransaccion: Boolean;
begin
  Result := FEnTransaccion;
end;

procedure TControlTransaccionMaterializacionMemoria.
  IniciarTransaccion;
begin
  Inc(FInicios);
  FEnTransaccion := True;
end;

procedure TControlTransaccionMaterializacionMemoria.
  ConfirmarTransaccion;
begin
  Inc(FConfirmaciones);
  FEnTransaccion := False;
end;

procedure TControlTransaccionMaterializacionMemoria.
  RevertirTransaccion;
begin
  Inc(FReversiones);
  FEnTransaccion := False;
end;

constructor TPersistenciaMaterializacionMemoria.Create;
begin
  inherited Create;
  FValidaMaterializacion := True;
  FValidaReversion := True;
end;

procedure TPersistenciaMaterializacionMemoria.Anotar(
  const AOperacion: string);
begin
  if FOperaciones <> '' then
    FOperaciones := FOperaciones + ',';
  FOperaciones := FOperaciones + AOperacion;
end;

procedure TPersistenciaMaterializacionMemoria.ComprobarFallo(
  const AOperacion: string);
begin
  if SameText(FFalloEn, AOperacion) then
    raise Exception.Create(
      'Fallo inyectado en ' + AOperacion);
end;

function TPersistenciaMaterializacionMemoria.
  ValidarMaterializacion(
    out AMensajeError: string): Boolean;
begin
  Anotar('VALIDAR');
  AMensajeError := FMensajeError;
  Result := FValidaMaterializacion;
end;

function TPersistenciaMaterializacionMemoria.CargarConfiguracion:
  TConfiguracionMaterializacionSesion;
begin
  Anotar('CONFIGURAR');
  Result := FConfiguracion;
end;

function TPersistenciaMaterializacionMemoria.ConsultarAlmacenes:
  TArray<string>;
begin
  Anotar('ALMACENES');
  Result := Copy(FAlmacenes);
end;

function TPersistenciaMaterializacionMemoria.ResolverSerieDocumento(
  const AEmpresa, ATipoDocumento, AAlmacen,
  ASerieAlternativa: string): string;
begin
  Anotar('SERIE-' + ATipoDocumento + '-' + AAlmacen);
  Result := ATipoDocumento + '-' + AAlmacen;
  if AAlmacen = '' then
    Result := ASerieAlternativa;
end;

procedure TPersistenciaMaterializacionMemoria.MaterializarArticulos(
  const AUsuario: string);
begin
  Inc(FArticulos);
  Anotar('ARTICULOS');
  ComprobarFallo('ARTICULOS');
end;

function TPersistenciaMaterializacionMemoria.MaterializarPedido(
  const AUsuario, ASerie, AAlmacen: string):
  TDocumentoMaterializado;
begin
  Inc(FPedidos);
  Anotar('PEDIDO-' + AAlmacen);
  ComprobarFallo('PEDIDO');
  Result := Default(TDocumentoMaterializado);
  Result.Tipo := 'Pedido';
  Result.Serie := ASerie;
  Result.Numero := IntToStr(FPedidos);
  Result.Almacen := AAlmacen;
end;

function TPersistenciaMaterializacionMemoria.MaterializarAlbaran(
  const AUsuario, ASerie, AAlmacen: string):
  TDocumentoMaterializado;
begin
  Inc(FAlbaranes);
  Anotar('ALBARAN-' + AAlmacen);
  ComprobarFallo('ALBARAN');
  Result := Default(TDocumentoMaterializado);
  Result.Tipo := 'Albaran';
  Result.Serie := ASerie;
  Result.Numero := IntToStr(FAlbaranes);
  Result.Almacen := AAlmacen;
end;

procedure TPersistenciaMaterializacionMemoria.CerrarSesion(
  const APedido, AAlbaran: TDocumentoMaterializado;
  const AUsuario: string);
begin
  Inc(FCierres);
  Anotar('CERRAR');
  ComprobarFallo('CERRAR');
end;

procedure TPersistenciaMaterializacionMemoria.RegistrarError(
  const AUsuario, AMensaje: string);
begin
  Inc(FErrores);
  FMensajeError := AMensaje;
  Anotar('ERROR');
end;

function TPersistenciaMaterializacionMemoria.ValidarReversion(
  out AMensajeError: string): Boolean;
begin
  Anotar('VALIDAR-REVERSION');
  AMensajeError := FMensajeError;
  Result := FValidaReversion;
end;

procedure TPersistenciaMaterializacionMemoria.EjecutarReversion(
  const AUsuario: string);
begin
  Inc(FReversiones);
  Anotar('REVERTIR');
  ComprobarFallo('REVERSION');
end;

end.
