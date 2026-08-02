{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaEntrada                                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Orquesta una lectura de artículo de caja contra puertos independientes.  }
{******************************************************************************}
unit inLibCajaEntrada;

interface

uses
  inLibArticulosValidadorIntf,
  inLibCajaEntradaIntf;

function CrearAplicacionEntradaCaja(
  const AValidador: IArticulosValidador;
  const AOperaciones: IOperacionesEntradaCaja;
  const AVista: IVistaEntradaCaja
): IAplicacionEntradaCaja;

implementation

uses
  System.SysUtils,
  inLibMsgCaja;

type
  TAplicacionEntradaCaja = class(
    TInterfacedObject,
    IAplicacionEntradaCaja)
  private
    FOperaciones: IOperacionesEntradaCaja;
    FValidador: IArticulosValidador;
    FVista: IVistaEntradaCaja;
  public
    constructor Create(
      const AValidador: IArticulosValidador;
      const AOperaciones: IOperacionesEntradaCaja;
      const AVista: IVistaEntradaCaja);
    procedure Procesar(const ACodigo: string);
  end;

constructor TAplicacionEntradaCaja.Create(
  const AValidador: IArticulosValidador;
  const AOperaciones: IOperacionesEntradaCaja;
  const AVista: IVistaEntradaCaja);
begin
  if not Assigned(AValidador) then
    raise EArgumentNilException.Create('AValidador');
  if not Assigned(AOperaciones) then
    raise EArgumentNilException.Create('AOperaciones');
  if not Assigned(AVista) then
    raise EArgumentNilException.Create('AVista');
  inherited Create;
  FValidador := AValidador;
  FOperaciones := AOperaciones;
  FVista := AVista;
end;

procedure TAplicacionEntradaCaja.Procesar(const ACodigo: string);
var
  Resolucion: TArtResolucionEntrada;
  sSku: string;
begin
  if FOperaciones.Disponible then
  begin
    FOperaciones.Iniciar;
    try
      if not FOperaciones.VendedorAsignado then
      begin
        FVista.MostrarError(SErrorVendedorCajaNoAsignado);
        FVista.EnfocarVendedor;
      end
      else
      begin
        FVista.PrepararLectura;
        Resolucion := FValidador.ResolverCodigoBarras(ACodigo);
        sSku := Resolucion.CodigoSku;
        if not Resolucion.Encontrado then
        begin
          FVista.MostrarError(Format(
            SErrorCodigoBarrasVentaCajaNoEncontrado,
            [ACodigo]));
        end
        else if (Trim(sSku) = '') or
                FOperaciones.PermitirSku(sSku) then
        begin
          FOperaciones.PrepararLinea;
          if (Trim(sSku) <> '') and
             FOperaciones.ConsolidarSku(sSku) then
          begin
            FVista.RefrescarConsolidacion;
          end
          else
          begin
            FOperaciones.AplicarCodigo(
              ACodigo,
              sSku,
              Resolucion.CodigoArticulo);
          end;
        end;
        FVista.PrepararSiguiente;
      end;
    finally
      FOperaciones.Finalizar;
    end;
  end;
end;

function CrearAplicacionEntradaCaja(
  const AValidador: IArticulosValidador;
  const AOperaciones: IOperacionesEntradaCaja;
  const AVista: IVistaEntradaCaja
): IAplicacionEntradaCaja;
begin
  Result := TAplicacionEntradaCaja.Create(
    AValidador,
    AOperaciones,
    AVista);
end;

end.
