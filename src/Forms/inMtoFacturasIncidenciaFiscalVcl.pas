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
  cxButtons;
type
  TcxResolverIncidenciaVerifactuButton = class(TcxButton)
  protected
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
  inMtoFrmBase,
  inLibEmisionFiscal,
  inLibEmisionFiscalIntf,
  inLibFacturasIncidenciaFiscal,
  inLibFacturasIncidenciaFiscalIntf,
  inLibVerifactuColaIntf,
  inLibVerifactuSubsanacionIntf,
  inMtoModalResolverIncidenciaVerifactu,
  UniDataFacturasIncidenciaFiscal,
  UniDataVerifactuColaRepositorio,
  UniDataVerifactuSubsanacionRepositorio;
procedure ResolverIncidenciaVerifactuVcl(
  AOwner: TfrmBase;
  ABoton: TcxButton;
  AFacturas: TDataSet); forward;
procedure TcxResolverIncidenciaVerifactuButton.Click;
var
  Formulario: TfrmBase;
  FuenteFacturas: TDataSource;
begin
  Formulario := Owner as TfrmBase;
  FuenteFacturas := Owner.FindComponent('dsTablaG') as TDataSource;
  ResolverIncidenciaVerifactuVcl(
    Formulario,
    Self,
    FuenteFacturas.DataSet);
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
  AOwner: TfrmBase;
  ABoton: TcxButton;
  AFacturas: TDataSet);
var
  Emision: IServicioEmisionFiscal;
  Cola: IServicioVerifactuCola;
  Repositorio: IRepositorioIncidenciaFiscalFactura;
  Servicio: IServicioIncidenciaFiscalFactura;
  Subsanacion: IServicioVerifactuSubsanacion;
  Resultado: TResultadoResolucionIncidenciaFiscal;
  sNumero: string;
  sSerie: string;
begin
  if Assigned(AFacturas) and AFacturas.Active and
     (not AFacturas.IsEmpty) then
  begin
    sSerie := AFacturas.FieldByName('SERIE_FAC').AsString;
    sNumero := AFacturas.FieldByName('NUMERO_FAC').AsString;
    Cola := CrearServicioVerifactuColaUniDAC(
      AOwner.ConexionPrincipal);
    Subsanacion := CrearServicioVerifactuSubsanacionUniDAC(
      AOwner.ConexionPrincipal);
    Emision := CrearServicioEmisionFiscal(
      AOwner.ParametrosApp,
      AOwner.ParametrosCaja,
      AOwner.ConexionPrincipal,
      Cola);
    Repositorio := CrearRepositorioIncidenciaFiscalFacturaUniDAC(
      AOwner.ConexionPrincipal);
    Servicio := CrearServicioIncidenciaFiscalFactura(
      Repositorio,
      Cola,
      Subsanacion,
      Emision,
      AOwner.ParametrosApp,
      AOwner.ParametrosCaja,
      AOwner.IdentidadSesion.Usuario);
    Resultado := TfrmModalResolverIncidenciaVerifactu.Ejecutar(
      AOwner,
      Servicio,
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
