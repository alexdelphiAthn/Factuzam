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
  System.Classes, Vcl.Forms, cxPC, Uni,
  inLibLogIntf, inLibCargaEfectosRemesaPersistenciaIntf;

type
  TAccionPrincipalVcl = reference to procedure;

procedure MostrarListadoVentas(AOwner: TComponent);
procedure MostrarListadoDocumentosProveedor(AOwner: TComponent);
procedure MostrarListadoEfectosPago(AOwner: TComponent);
function FacturarAlbaranesCompra: Boolean;
procedure MostrarProcesosAuxiliares(AOwner: TComponent);
procedure MostrarCambioArticuloColor(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AUsuario: string);
procedure MostrarDeclaracionVerifactu(AOwner: TComponent);
procedure MostrarBalanceAlmacenHorizontal;
procedure MostrarBalanceAlmacenSinTallas;
procedure MostrarMovimientosVentasArticulos;
procedure MostrarAcercaDe(
  AOwner: TComponent;
  const ARegistroLog: IRegistroLog);
procedure MostrarConsultaStockPrincipal(
  AFormularioPrincipal: TForm;
  APaginas: TcxPageControl);
procedure DesvincularConsultaStockPrincipal;
procedure CargarEfectosRemesaPrincipal(
  AOwner: TComponent;
  const ARepositorio: IRepositorioCargaEfectosRemesa;
  AEsVenta: Boolean;
  const AAlCompletar: TAccionPrincipalVcl);

implementation

uses
  System.SysUtils,
  Vcl.Controls,
  inMtoModalListadoVentas,
  inMtoModalImpDocsProveedor,
  inMtoModalImpEfectosPago,
  inMtoModalFacturarAlbaranes,
  inMtoModalProcesosAuxiliaresBBDD,
  inMtoModalCambioArticuloColor,
  inLibCambioArticuloColor,
  UniDataCambioArticuloColorRepositorio,
  inMtoModalVerifactuDecl,
  inMtoModalImpBalanceTallas,
  inMtoModalImpBalanceSinTallas,
  inMtoModalImpMovVentasArt,
  inMtoSplash,
  inMtoFrmBase, inMtoStockConsulta,
  inMtoModalCargarEfectosRemesa;

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

procedure MostrarCambioArticuloColor(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AUsuario: string);
begin
  TfrmModalCambioArticuloColor.Ejecutar(
    AOwner,
    CrearServicioCambioArticuloColor(
      CrearRepositorioCambioArticuloColorUniDAC(AConexion)),
    AUsuario);
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

procedure MostrarAcercaDe(
  AOwner: TComponent;
  const ARegistroLog: IRegistroLog);
var
  Formulario: TfrmSplash;
begin
  Formulario := TfrmSplash.Create(AOwner, ARegistroLog);
  try
    Formulario.ShowModal;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure MostrarConsultaStockPrincipal(
  AFormularioPrincipal: TForm;
  APaginas: TcxPageControl);
var
  FormularioActivo: TForm;
  Pestana: TcxTabSheet;
  Articulo: string;
  Sku: string;
begin
  FormularioActivo := Screen.ActiveForm;
  if (FormularioActivo = AFormularioPrincipal) and
     Assigned(APaginas) and
     (APaginas.PageCount > 0) and
     (APaginas.ActivePageIndex >= 0) then
  begin
    Pestana := APaginas.Pages[APaginas.ActivePageIndex] as TcxTabSheet;
    if (Pestana.ControlCount > 0) and
       (Pestana.Controls[0] is TForm) then
      FormularioActivo := TForm(Pestana.Controls[0]);
  end;
  Articulo := '';
  Sku := '';
  if FormularioActivo is TfrmBase then
    TfrmBase(FormularioActivo).ResolverArtSkuStock(Articulo, Sku);
  MostrarStockConsulta(Articulo, Sku);
end;

procedure DesvincularConsultaStockPrincipal;
begin
  DesvincularPerfilesStockConsulta;
end;

procedure CargarEfectosRemesaPrincipal(
  AOwner: TComponent;
  const ARepositorio: IRepositorioCargaEfectosRemesa;
  AEsVenta: Boolean;
  const AAlCompletar: TAccionPrincipalVcl);
var
  Formulario: TfrmModalCargarEfectosRemesa;
begin
  if AEsVenta then
    Formulario := TfrmModalCargarEfectosRemesa.CrearParaVenta(
      AOwner,
      ARepositorio)
  else
    Formulario := TfrmModalCargarEfectosRemesa.CrearParaCompra(
      AOwner,
      ARepositorio);
  try
    if (Formulario.ShowModal = mrOk) and Assigned(AAlCompletar) then
      AAlCompletar();
  finally
    Formulario.Free;
  end;
end;

end.
