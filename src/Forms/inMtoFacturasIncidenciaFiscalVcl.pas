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
type
  TcxResolverIncidenciaVerifactuButton = class(TcxButton)
  private
    FFuenteFacturas: TDataSource;
    FServicio: IServicioIncidenciaFiscalFactura;
  public
    destructor Destroy; override;
    procedure Configurar(
      const AServicio: IServicioIncidenciaFiscalFactura;
      AFuenteFacturas: TDataSource);
    procedure Click; override;
  end;
procedure ActualizarBotonResolverIncidenciaVcl(
  ABoton: TcxButton;
  const ATipoFactura: string;
  AConsolidacion: TDataSet);
implementation
uses
  System.SysUtils,
  Vcl.Dialogs,
  inLibFacturasIncidenciaFiscal,
  inMtoModalResolverIncidenciaVerifactu;
procedure ResolverIncidenciaVerifactuVcl(
  AOwner: TComponent;
  ABoton: TcxButton;
  AFacturas: TDataSet;
  const AServicio: IServicioIncidenciaFiscalFactura); forward;
destructor TcxResolverIncidenciaVerifactuButton.Destroy;
begin
  FServicio := nil;
  FFuenteFacturas := nil;
  inherited;
end;
procedure TcxResolverIncidenciaVerifactuButton.Configurar(
  const AServicio: IServicioIncidenciaFiscalFactura;
  AFuenteFacturas: TDataSource);
begin
  if not Assigned(AServicio) then
    raise EArgumentNilException.Create('AServicio');
  if not Assigned(AFuenteFacturas) then
    raise EArgumentNilException.Create('AFuenteFacturas');
  FServicio := AServicio;
  FFuenteFacturas := AFuenteFacturas;
end;
procedure TcxResolverIncidenciaVerifactuButton.Click;
begin
  if not Assigned(FServicio) then
    raise EInvalidOpException.Create(
      'No se configuró el servicio de incidencia fiscal.');
  if not Assigned(FFuenteFacturas) then
    raise EInvalidOpException.Create(
      'No se configuró el origen de facturas.');
  ResolverIncidenciaVerifactuVcl(
    Owner,
    Self,
    FFuenteFacturas.DataSet,
    FServicio);
end;
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
