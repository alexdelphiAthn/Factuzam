{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaVentanasIntf                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos y fábricas de las ventanas de operación y consulta de caja.     }
{******************************************************************************}
unit inLibCajaVentanasIntf;

interface

uses
  System.Classes, Vcl.Forms, inLibCajaTipos, inLibPermisosIntf;

type
  IOperacionCaja = interface
    ['{8DC46E81-713D-4CCB-ADCB-1D5204D6EF50}']
    function FormularioCaja: TCustomForm;
    function IntentarCerrar: Boolean;
    function OperacionVacia: Boolean;
    function CargarSkuExterno(
      const ASku: string;
      ACant: Double): Boolean;
    procedure PrepararValores(
      AEmpresa, AAlmacen, ACaja: string;
      AFecha: TDateTime);
    procedure CargarRectificacion(
      const ASerie, ANumero: string;
      ATipoRectificativa: TTipoRectificativaCaja;
      ATratamientoMovimientos:
        TTratamientoMovimientosRectificativa);
  end;

  IConsultaOperacionesCaja = interface
    ['{50D890C9-5772-47A0-9B53-530748886CBB}']
    function FormularioConsultaCaja: TCustomForm;
    procedure PrepararValores(
      const AEmpresa, AAlmacen, ACaja: string;
      AFecha: TDateTime);
    procedure RefrescarOperaciones;
  end;

  IReceptorFechaCaja = interface
    ['{31EB4CB2-7A61-4322-93D6-14A956327846}']
    procedure ActualizarFechaCaja(AFechaCaja: TDateTime);
  end;

  IAnfitrionCajaVentanas = interface
    ['{2D68C9D7-F132-476E-B762-543CA87E6DCC}']
    function CrearOperacionCaja(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion): IOperacionCaja;
    function CrearConsultaOperacionesCaja(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion): IConsultaOperacionesCaja;
  end;

function ExigirAnfitrionCaja(
  AObjeto: TObject): IAnfitrionCajaVentanas;
function BuscarOperacionCajaVacia: IOperacionCaja;
function BuscarOperacionCajaVisible: IOperacionCaja;
function PuedenCerrarOperacionesCaja: Boolean;
procedure RefrescarConsultasOperacionesCaja;
procedure NotificarFechaCaja(AFecha: TDateTime);

implementation

uses
  System.SysUtils;

resourcestring
  SErrorAnfitrionCajaNoDisponible =
    'La aplicación no proporciona el servicio de ventanas de caja.';

function ExigirAnfitrionCaja(
  AObjeto: TObject): IAnfitrionCajaVentanas;
begin
  if not Supports(AObjeto, IAnfitrionCajaVentanas, Result) then
    raise EInvalidOpException.Create(
      SErrorAnfitrionCajaNoDisponible);
end;

function BuscarOperacionCajaVacia: IOperacionCaja;
var
  i: Integer;
  oOperacion: IOperacionCaja;
begin
  Result := nil;
  for i := 0 to Screen.FormCount - 1 do
  begin
    if (Result = nil) and
       Supports(Screen.Forms[i], IOperacionCaja, oOperacion) and
       oOperacion.OperacionVacia then
      Result := oOperacion;
  end;
end;

function BuscarOperacionCajaVisible: IOperacionCaja;
var
  i: Integer;
  oOperacion: IOperacionCaja;
begin
  Result := nil;
  for i := 0 to Screen.FormCount - 1 do
  begin
    if (Result = nil) and
       Supports(Screen.Forms[i], IOperacionCaja, oOperacion) and
       oOperacion.FormularioCaja.Visible then
      Result := oOperacion;
  end;
end;

function PuedenCerrarOperacionesCaja: Boolean;
var
  i: Integer;
  oOperacion: IOperacionCaja;
begin
  Result := True;
  i := Screen.FormCount - 1;
  while (i >= 0) and Result do
  begin
    if Supports(Screen.Forms[i], IOperacionCaja, oOperacion) and
       not oOperacion.IntentarCerrar then
      Result := False;
    Dec(i);
  end;
end;

procedure RefrescarConsultasOperacionesCaja;
var
  i: Integer;
  oConsulta: IConsultaOperacionesCaja;
begin
  for i := 0 to Screen.FormCount - 1 do
  begin
    if Supports(
         Screen.Forms[i],
         IConsultaOperacionesCaja,
         oConsulta) then
      oConsulta.RefrescarOperaciones;
  end;
end;

procedure NotificarFechaCaja(AFecha: TDateTime);
var
  i: Integer;
  oReceptor: IReceptorFechaCaja;
begin
  for i := 0 to Screen.FormCount - 1 do
  begin
    if Supports(Screen.Forms[i], IReceptorFechaCaja, oReceptor) then
      oReceptor.ActualizarFechaCaja(AFecha);
  end;
end;

end.
