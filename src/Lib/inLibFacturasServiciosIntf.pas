{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasServiciosIntf                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos de validación y operaciones desacopladas de facturas de venta.  }
{******************************************************************************}
unit inLibFacturasServiciosIntf;

interface

uses
  System.SysUtils, Data.DB;

type
  TCampoValidacionFac = (
    cvfNinguno,
    cvfSerie,
    cvfRazonSocialCliente,
    cvfRazonSocialEmpresa,
    cvfPais,
    cvfFecha,
    cvfNifCliente,
    cvfNifEmpresa,
    cvfOperacionFiscal,
    cvfTipoIva);
  TResultadoOperacionFactura = record
    Exito: Boolean;
    Mensaje: string;
    class function Correcto: TResultadoOperacionFactura; static;
    class function Error(
      const AMensaje: string): TResultadoOperacionFactura; static;
  end;
  TResultadoBorradoFactura = record
    Permitido: Boolean;
    Mensaje: string;
    class function Permitir: TResultadoBorradoFactura; static;
    class function Denegar(
      const AMensaje: string): TResultadoBorradoFactura; static;
  end;
  EValidacionFactura = class(EDatabaseError)
  private
    FCampo: TCampoValidacionFac;
  public
    constructor Create(
      const AMensaje: string;
      ACampo: TCampoValidacionFac); reintroduce;
    property Campo: TCampoValidacionFac read FCampo;
  end;
  TResultadoOperacionFacturaEvent = procedure(
    const AResultado: TResultadoOperacionFactura) of object;
  TResultadoBorradoFacturaEvent = procedure(
    const AResultado: TResultadoBorradoFactura) of object;
  TAdvertenciaFacturaEvent = procedure(
    const AMensaje: string) of object;
  TValidacionFacturaEvent = procedure(
    const AError: EValidacionFactura) of object;
  TConfirmarBorradoFacturaEvent = function(
    const ASerie, ANumero: string): Boolean of object;
  IServicioBorradoFactura = interface
    ['{35C1550C-F905-4185-BCCB-6B63C81A51A1}']
    function Validar(
      const ASerie, ANumero, AFase: string
    ): TResultadoBorradoFactura;
    function Preparar(
      const ASerie, ANumero, AFase: string
    ): TResultadoBorradoFactura;
    procedure Confirmar;
    procedure Revertir;
  end;
  IServicioEfectosFactura = interface
    ['{F015E26D-5792-46B1-917A-C2B3EE4957F5}']
    procedure EstamparBancoRecibos(
      const ASerie, ANumero, ACodigoBanco, AIban: string);
    function BancoDefectoCliente(
      const ACodigoCliente: string): string;
    function Generar(
      const ASerie, ANumero, AUsuario,
      ACodigoBanco, AIban: string): Integer;
    function RegistrarCobro(
      const ASerie, ANumero, AUsuario: string;
      ANumeroEfecto: Integer;
      AFecha: TDateTime;
      AImporte: Double;
      const ATipo, AReferencia: string): Integer;
    function CambiarEstado(
      const ASerie, ANumero, AUsuario: string;
      ANumeroEfecto: Integer;
      const AEstado: string): Boolean;
  end;
  TSolicitudMovimientosFactura = record
    Serie: string;
    Numero: string;
    Empresa: string;
    Cliente: string;
    Caja: string;
    NumeroOperacion: string;
    Usuario: string;
  end;
  IServicioMovimientosFactura = interface
    ['{A73BE906-C8F3-412D-9CA6-27CF126A1282}']
    function GenerarSalidas(
      const ASolicitud: TSolicitudMovimientosFactura): Integer;
  end;

function EvaluarBorradoFactura(
  const AFase: string;
  ATieneEfectosCobrados: Boolean
): TResultadoBorradoFactura;

implementation

uses
  inLibMsg;

class function TResultadoOperacionFactura.Correcto:
  TResultadoOperacionFactura;
begin
  Result.Exito := True;
  Result.Mensaje := '';
end;

class function TResultadoOperacionFactura.Error(
  const AMensaje: string): TResultadoOperacionFactura;
begin
  Result.Exito := False;
  Result.Mensaje := AMensaje;
end;

class function TResultadoBorradoFactura.Permitir:
  TResultadoBorradoFactura;
begin
  Result.Permitido := True;
  Result.Mensaje := '';
end;

class function TResultadoBorradoFactura.Denegar(
  const AMensaje: string): TResultadoBorradoFactura;
begin
  Result.Permitido := False;
  Result.Mensaje := AMensaje;
end;

constructor EValidacionFactura.Create(
  const AMensaje: string;
  ACampo: TCampoValidacionFac);
begin
  inherited Create(AMensaje);
  FCampo := ACampo;
end;

function EvaluarBorradoFactura(
  const AFase: string;
  ATieneEfectosCobrados: Boolean
): TResultadoBorradoFactura;
begin
  if (Trim(AFase) <> '') and
     (not SameText(AFase, 'BORRADOR')) then
  begin
    Result := TResultadoBorradoFactura.Denegar(
      Format(SErrorBorrarBorradorFase, [AFase]));
  end
  else if ATieneEfectosCobrados then
  begin
    Result := TResultadoBorradoFactura.Denegar(
      SErrorBorrarBorradorEfectosCobrados);
  end
  else
  begin
    Result := TResultadoBorradoFactura.Permitir;
  end;
end;

end.
