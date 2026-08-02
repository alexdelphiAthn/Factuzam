{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFacturasConsolidacionVcl                                 }
{    Tipo:       Adaptador VCL                                                 }
{ Versión:       2.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Recoge la factura seleccionada y delega en la aplicación de consolidar.  }
{******************************************************************************}
unit inMtoFacturasConsolidacionVcl;

interface

uses
  Data.DB,
  inLibFacturasAplicacionIntf;

type
  TContextoConsolidacionFacturaVcl = record
    Facturas: TDataSet;
    Aplicacion: IAplicacionConsolidacionFactura;
    Vista: IVistaFactura;
    Usuario: string;
  end;
  TCoordinadorConsolidacionFacturaVcl = class
  public
    class procedure Ejecutar(
      const AContexto: TContextoConsolidacionFacturaVcl); static;
  end;

implementation

uses
  inLibMsgFacturas;

class procedure TCoordinadorConsolidacionFacturaVcl.Ejecutar(
  const AContexto: TContextoConsolidacionFacturaVcl);
var
  sNumero: string;
  sSerie: string;
begin
  if Assigned(AContexto.Facturas) and
     AContexto.Facturas.Active and
     (not AContexto.Facturas.IsEmpty) then
  begin
    sSerie := AContexto.Facturas.FieldByName('SERIE_FAC').AsString;
    sNumero := AContexto.Facturas.FieldByName('NUMERO_FAC').AsString;
    AContexto.Aplicacion.Ejecutar(
      sSerie,
      sNumero,
      AContexto.Usuario);
  end
  else
    AContexto.Vista.MostrarError(SErrorBorradorListaNoSeleccionado);
end;

end.
