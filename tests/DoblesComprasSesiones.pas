{******************************************************************************}
{                                                                              }
{  Módulo:       DoblesComprasSesiones                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Repositorio de sesiones de compra en memoria para pruebas DUnitX.         }
{******************************************************************************}
unit DoblesComprasSesiones;

interface

uses
  inLibComprasSesionesIntf;

type
  TRepositorioComprasSesionesMemoria = class(
    TInterfacedObject,
    IRepositorioComprasSesiones)
  private
    FCodigoArticuloPreferido: string;
    FCodigoBuscado: string;
    FCodigoProveedor: string;
    FDuplicado: TResolverDuplicadoSesion;
    FIncidencias: TIncidenciasSesionCompra;
    FMaterializaciones: Integer;
    FMensajeReversion: string;
    FResultadoMaterializacion: TResultadoMaterializacionSesion;
    FResultadoMaterializacionOk: Boolean;
    FResultadoReversionOk: Boolean;
    FReversiones: Integer;
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
    function EjecutarMaterializacion(
      const AParametros: TParametrosMaterializacionSesion;
      out AResultado: TResultadoMaterializacionSesion): Boolean;
    function RevertirMaterializacion(
      const AUsuario: string;
      out AMensajeError: string): Boolean;
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
    property Materializaciones: Integer
      read FMaterializaciones;
    property MensajeReversion: string
      read FMensajeReversion write FMensajeReversion;
    property ResultadoMaterializacion: TResultadoMaterializacionSesion
      read FResultadoMaterializacion write FResultadoMaterializacion;
    property ResultadoMaterializacionOk: Boolean
      read FResultadoMaterializacionOk write FResultadoMaterializacionOk;
    property ResultadoReversionOk: Boolean
      read FResultadoReversionOk write FResultadoReversionOk;
    property Reversiones: Integer
      read FReversiones;
    property SoloRefProveedor: Boolean
      read FSoloRefProveedor;
  end;

implementation

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

function TRepositorioComprasSesionesMemoria.ConsultarCodigosBasicosActivos(
  const AIdVariacion: string): TArray<string>;
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

function TRepositorioComprasSesionesMemoria.ResolverDuplicadoIntraSesion(
  const ASerie, ANumero: string;
  ALineaActual: Integer;
  const AModelo, ACodigoArticulo: string):
  TResolverDuplicadoSesion;
begin
  Result := Default(TResolverDuplicadoSesion);
end;

function TRepositorioComprasSesionesMemoria.NormalizarDuplicadosIntraSesion(
  const AUsuario, ASerie, ANumero: string): Integer;
begin
  Result := 0;
end;

function TRepositorioComprasSesionesMemoria.ValidarSesionDetallado:
  TIncidenciasSesionCompra;
begin
  Result := FIncidencias;
end;

function TRepositorioComprasSesionesMemoria.EjecutarMaterializacion(
  const AParametros: TParametrosMaterializacionSesion;
  out AResultado: TResultadoMaterializacionSesion): Boolean;
begin
  Inc(FMaterializaciones);
  AResultado := FResultadoMaterializacion;
  Result := FResultadoMaterializacionOk;
end;

function TRepositorioComprasSesionesMemoria.RevertirMaterializacion(
  const AUsuario: string;
  out AMensajeError: string): Boolean;
begin
  Inc(FReversiones);
  AMensajeError := FMensajeReversion;
  Result := FResultadoReversionOk;
end;

end.
