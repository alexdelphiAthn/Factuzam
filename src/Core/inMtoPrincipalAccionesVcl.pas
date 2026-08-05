{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoPrincipalAccionesVcl                                    }
{    Tipo:       Adaptador VCL                                                 }
{ Version:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Apertura y ciclo de vida de acciones modales del menu principal.         }
{******************************************************************************}
unit inMtoPrincipalAccionesVcl;

interface

uses
  System.Classes;

procedure MostrarListadoVentas(AOwner: TComponent);
procedure MostrarListadoDocumentosProveedor(AOwner: TComponent);
procedure MostrarListadoEfectosPago(AOwner: TComponent);
function FacturarAlbaranesCompra: Boolean;
procedure MostrarProcesosAuxiliares(AOwner: TComponent);
procedure MostrarDeclaracionVerifactu(AOwner: TComponent);
procedure MostrarBalanceAlmacenHorizontal;
procedure MostrarBalanceAlmacenSinTallas;
procedure MostrarMovimientosVentasArticulos;

implementation

uses
  System.SysUtils,
  Vcl.Controls,
  Vcl.Forms,
  inMtoModalListadoVentas,
  inMtoModalImpDocsProveedor,
  inMtoModalImpEfectosPago,
  inMtoModalFacturarAlbaranes,
  inMtoModalProcesosAuxiliaresBBDD,
  inMtoModalVerifactuDecl,
  inMtoModalImpBalanceTallas,
  inMtoModalImpBalanceSinTallas,
  inMtoModalImpMovVentasArt;

procedure MostrarListadoVentas(AOwner: TComponent);
var
  Formulario: TfrmModalListadoVentas;
begin
  Formulario := TfrmModalListadoVentas.Create(AOwner);
  try
    Formulario.ShowModal;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure MostrarListadoDocumentosProveedor(AOwner: TComponent);
var
  Formulario: TfrmPrintDocsProveedor;
begin
  Formulario := TfrmPrintDocsProveedor.Create(AOwner);
  try
    Formulario.ShowModal;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure MostrarListadoEfectosPago(AOwner: TComponent);
var
  Formulario: TfrmPrintEfectosPago;
begin
  Formulario := TfrmPrintEfectosPago.Create(AOwner);
  try
    Formulario.ShowModal;
  finally
    FreeAndNil(Formulario);
  end;
end;

function FacturarAlbaranesCompra: Boolean;
var
  Formulario: TfrmModalFacturarAlbaranes;
begin
  Formulario := TfrmModalFacturarAlbaranes.Create(nil);
  try
    Result := Formulario.ShowModal = mrOk;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure MostrarProcesosAuxiliares(AOwner: TComponent);
begin
  TfrmModalProcesosAuxiliaresBBDD.Ejecutar(AOwner);
end;

procedure MostrarDeclaracionVerifactu(AOwner: TComponent);
begin
  TfrmModalVerifactuDecl.Ejecutar(AOwner);
end;

procedure MostrarBalanceAlmacenHorizontal;
var
  Formulario: TfrmPrintBalanceTallas;
begin
  Formulario := TfrmPrintBalanceTallas.Create(Application);
  try
    Formulario.ShowModal;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure MostrarBalanceAlmacenSinTallas;
var
  Formulario: TfrmPrintBalanceSinTallas;
begin
  Formulario := TfrmPrintBalanceSinTallas.Create(Application);
  try
    Formulario.ShowModal;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure MostrarMovimientosVentasArticulos;
var
  Formulario: TfrmPrintMovVentasArt;
begin
  Formulario := TfrmPrintMovVentasArt.Create(Application);
  try
    Formulario.ShowModal;
  finally
    FreeAndNil(Formulario);
  end;
end;

end.
