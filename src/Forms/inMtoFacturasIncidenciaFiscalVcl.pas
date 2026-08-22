{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturasIncidenciaFiscalVcl                              }
{    Tipo:       Presentación VCL                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Integra la resolución de incidencias fiscales en Factura Venta Mayor.     }
{******************************************************************************}
unit inMtoFacturasIncidenciaFiscalVcl;
interface
uses
  System.Classes,
  Data.DB,
  cxButtons,
  inLibFacturasIncidenciaFiscalIntf;
procedure ActualizarBotonResolverIncidenciaVcl(
  ABoton: TcxButton;
  const ATipoFactura: string;
  AConsolidacion: TDataSet);
procedure ResolverIncidenciaVerifactuVcl(
  AOwner: TComponent;
  ABoton: TcxButton;
  AFacturas: TDataSet;
  const AServicio: IServicioIncidenciaFiscalFactura);
implementation
uses
  System.SysUtils,
  Vcl.Dialogs,
  inLibFacturasIncidenciaFiscal,
  inMtoModalResolverIncidenciaVerifactu;
procedure ActualizarBotonResolverIncidenciaVcl(
  ABoton: TcxButton;
  const ATipoFactura: string;
  AConsolidacion: TDataSet);
var
  sEstadoRegistro: string;
  sEstadoSubsanacion: string;
begin
  ABoton.Visible := False;
  if SameText(ATipoFactura, 'NORMAL') and
     Assigned(AConsolidacion) and
     AConsolidacion.Active and
     (not AConsolidacion.IsEmpty) then
  begin
    sEstadoRegistro := AConsolidacion.FieldByName(
      'ESTADO_FACCON').AsString;
    sEstadoSubsanacion := '';
    if Assigned(AConsolidacion.FindField(
       'ESTADO_SUBSANACION')) then
      sEstadoSubsanacion := AConsolidacion.FieldByName(
        'ESTADO_SUBSANACION').AsString;
    ABoton.Visible :=
      PuedeResolverIncidenciaFiscal(
        sEstadoRegistro,
        sEstadoSubsanacion,
        True);
  end;
end;
procedure ResolverIncidenciaVerifactuVcl(
  AOwner: TComponent;
  ABoton: TcxButton;
  AFacturas: TDataSet;
  const AServicio: IServicioIncidenciaFiscalFactura);
var
  Resultado: TResultadoResolucionIncidenciaFiscal;
  sNumero: string;
  sSerie: string;
begin
  if Assigned(AFacturas) and AFacturas.Active and
     (not AFacturas.IsEmpty) then
  begin
    sSerie := AFacturas.FieldByName('SERIE_FAC').AsString;
    sNumero := AFacturas.FieldByName('NUMERO_FAC').AsString;
    Resultado := TfrmModalResolverIncidenciaVerifactu.Ejecutar(
      AOwner,
      AServicio,
      sSerie,
      sNumero);
    if Resultado.EsCorrecto then
    begin
      ShowMessage(Resultado.Mensaje);
      AFacturas.Refresh;
      ABoton.Visible := False;
    end;
  end;
end;
end.
