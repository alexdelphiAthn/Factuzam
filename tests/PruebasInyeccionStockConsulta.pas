{******************************************************************************}
{                                                                              }
{  Módulo:       PruebasInyeccionStockConsulta                                }
{    Tipo:       Pruebas                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Verifica el contexto explícito de la consulta de stock con dobles.        }
{******************************************************************************}
unit PruebasInyeccionStockConsulta;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasInyeccionStockConsulta = class
  public
    [Test]
    procedure Contexto_SeConstruyeConDoblesSinRaizVisual;
    [Test]
    procedure DependenciaAusente_FallaAlPrepararElContexto;
  end;

implementation

uses
  System.SysUtils, Data.DB,
  inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf,
  inLibDocumentosTrabajo,
  inLibStockConsultaInfo,
  inLibStockConsultaPersistenciaIntf,
  inMtoStockConsultaPresentacionComposicion;

type
  TDobleStockConsulta = class(
    TInterfacedObject,
    ILectorCatalogosStockConsulta,
    IRepositorioPivoteStock,
    ILectorInfoCabeceraStock)
  public
    function ResolverTextoArticulo(
      const AEntrada: string): IResultadoConsultaStock;
    function ResolverSku(
      const ACodigoArticulo, AColor, ATalla: string;
      out ACodigoSku: string): Integer;
    function ConsultarAlmacenes: IResultadoConsultaStock;
    function ConsultarColores(
      const ACodigoArticulo,
      ACodigoSku: string): IResultadoConsultaStock;
    function ConsultarPropiedadesPorColor(
      const ACodigoArticulo: string): IResultadoConsultaStock;
    function ObtenerDescripcionArticulo(
      const ACodigoArticulo: string;
      out ADescripcion: string): Boolean;
    function ConsultarFotosRelacionadas(
      const ASolicitud: TSolicitudFotosRelacionadasStock
    ): IResultadoConsultaStock;
    function BuscarArticulos(
      const ACodigoTarifa: string): IResultadoConsultaStock;
    function ListarTallas(
      const ACodigoArticulo: string;
      const AColores: TArray<string>): TArray<TInfoColumna>;
    function Consultar(
      const ASolicitud: TSolicitudPivoteStock;
      const ATallas: TArray<TInfoColumna>): IResultadoConsultaStock;
    function Cargar(
      const ACodigoArticulo: string): TInfoCabeceraStock;
  end;

  TDobleArticulosStock = class(
    TInterfacedObject,
    IArticulosValidador,
    IArticulosResolver)
  public
    function Resolver(
      const AEntrada: string): TArtResolucionEntrada;
    function ResolverCodigoBarras(
      const AEntrada: string): TArtResolucionEntrada;
    function ResolverConSku(
      const AEntrada,
      ACodigoSkuPreferido: string): TArtResolucionEntrada;
    function EsValido(const AEntrada: string): Boolean;
    function TieneSkuActivo(
      const ACodigoArticulo: string): Boolean;
    function ResolverDatos(
      const ACodigoArt, ACodigoSku: string;
      const ACodigoTarifa: string;
      const AFecha: TDateTime;
      const ACodigoAlmacen: string;
      const ACodigoProveedor: string): TArticuloDatos;
    function ResolverPrecio(
      const ACodigoArt, ACodigoSku, ACodigoTarifa: string;
      const AFecha: TDateTime): TArticuloPrecio;
    function ResolverUltimoCoste(
      const ACodigoArt: string;
      const ACodigoProveedor: string;
      const ACodigoSku: string): TArticuloCoste;
    function ResolverPMP(
      const ACodigoSku: string;
      const ACodigoAlmacen: string): TArticuloPMP;
    function ListarSkus(
      const ACodigoArt: string;
      AIncluirInactivos: Boolean): TArray<TArticuloSkuItem>;
    function DescuentoTarifaVigente(
      const ACodigoTarifa: string;
      const AFecha: TDateTime): Boolean;
  end;

  TDobleDocumentosTrabajoStock = class(
    TInterfacedObject,
    ILecturasDocumentosTrabajo,
    IEscrituraDocumentosTrabajo,
    IMaterializacionDocumentosTrabajo)
  public
    function ConsultaDocumentosAbiertos(
      const AUsuario: string): string;
    procedure CompletarDatosArticulo(
      var ALinea: TDocTrabajoLineaOrigen);
    function ConsultarDestinosCompartir: IConsultaDocumentoTrabajo;
    function ListarNombresAtributos:
      TNombresAtributosDocumentoTrabajo;
    function CrearDocumento(
      const ATitulo, AEmpresa, AAlmacen,
      AUsuario: string): Int64;
    procedure InsertarLinea(
      AIdDocumento: Int64;
      const ALinea: TDocTrabajoLineaOrigen;
      const AUsuario: string);
    function SiguienteContador(
      const ASerie, ATipoDocumento, AEmpresa,
      AUsuario: string): string;
    function CrearAlbaran(
      AIdDocumento: Int64;
      const AEmpresa, AAlmacen, ASerie, ANumero,
      AUsuario: string): Integer;
    function CrearFacturaVenta(
      AIdDocumento: Int64;
      const AEmpresa, AAlmacen, ASerie, ANumero,
      AUsuario: string): Integer;
    function CrearPedidoCompra(
      AIdDocumento: Int64;
      const AEmpresa, AAlmacen, ASerie, ANumero,
      AUsuario: string): Integer;
    function CrearInventario(
      AIdDocumento: Int64;
      const AEmpresa, AAlmacen, ASerie, ANumero,
      AUsuario: string): Integer;
    function CrearSesionTarifa(
      AIdDocumento: Int64;
      const AUsuario: string): Int64;
  end;

function TDobleStockConsulta.ResolverTextoArticulo(
  const AEntrada: string): IResultadoConsultaStock;
begin
  Result := nil;
end;

function TDobleStockConsulta.ResolverSku(
  const ACodigoArticulo, AColor, ATalla: string;
  out ACodigoSku: string): Integer;
begin
  ACodigoSku := '';
  Result := 0;
end;

function TDobleStockConsulta.ConsultarAlmacenes: IResultadoConsultaStock;
begin
  Result := nil;
end;

function TDobleStockConsulta.ConsultarColores(
  const ACodigoArticulo,
  ACodigoSku: string): IResultadoConsultaStock;
begin
  Result := nil;
end;

function TDobleStockConsulta.ConsultarPropiedadesPorColor(
  const ACodigoArticulo: string): IResultadoConsultaStock;
begin
  Result := nil;
end;

function TDobleStockConsulta.ObtenerDescripcionArticulo(
  const ACodigoArticulo: string;
  out ADescripcion: string): Boolean;
begin
  ADescripcion := '';
  Result := False;
end;

function TDobleStockConsulta.ConsultarFotosRelacionadas(
  const ASolicitud: TSolicitudFotosRelacionadasStock
): IResultadoConsultaStock;
begin
  Result := nil;
end;

function TDobleStockConsulta.BuscarArticulos(
  const ACodigoTarifa: string): IResultadoConsultaStock;
begin
  Result := nil;
end;

function TDobleStockConsulta.ListarTallas(
  const ACodigoArticulo: string;
  const AColores: TArray<string>): TArray<TInfoColumna>;
begin
  SetLength(Result, 0);
end;

function TDobleStockConsulta.Consultar(
  const ASolicitud: TSolicitudPivoteStock;
  const ATallas: TArray<TInfoColumna>): IResultadoConsultaStock;
begin
  Result := nil;
end;

function TDobleStockConsulta.Cargar(
  const ACodigoArticulo: string): TInfoCabeceraStock;
begin
  Result := Default(TInfoCabeceraStock);
end;

function TDobleArticulosStock.Resolver(
  const AEntrada: string): TArtResolucionEntrada;
begin
  Result := Default(TArtResolucionEntrada);
end;

function TDobleArticulosStock.ResolverCodigoBarras(
  const AEntrada: string): TArtResolucionEntrada;
begin
  Result := Default(TArtResolucionEntrada);
end;

function TDobleArticulosStock.ResolverConSku(
  const AEntrada,
  ACodigoSkuPreferido: string): TArtResolucionEntrada;
begin
  Result := Default(TArtResolucionEntrada);
end;

function TDobleArticulosStock.EsValido(
  const AEntrada: string): Boolean;
begin
  Result := False;
end;

function TDobleArticulosStock.TieneSkuActivo(
  const ACodigoArticulo: string): Boolean;
begin
  Result := False;
end;

function TDobleArticulosStock.ResolverDatos(
  const ACodigoArt, ACodigoSku: string;
  const ACodigoTarifa: string;
  const AFecha: TDateTime;
  const ACodigoAlmacen: string;
  const ACodigoProveedor: string): TArticuloDatos;
begin
  Result := Default(TArticuloDatos);
end;

function TDobleArticulosStock.ResolverPrecio(
  const ACodigoArt, ACodigoSku, ACodigoTarifa: string;
  const AFecha: TDateTime): TArticuloPrecio;
begin
  Result := Default(TArticuloPrecio);
end;

function TDobleArticulosStock.ResolverUltimoCoste(
  const ACodigoArt: string;
  const ACodigoProveedor: string;
  const ACodigoSku: string): TArticuloCoste;
begin
  Result := Default(TArticuloCoste);
end;

function TDobleArticulosStock.ResolverPMP(
  const ACodigoSku: string;
  const ACodigoAlmacen: string): TArticuloPMP;
begin
  Result := Default(TArticuloPMP);
end;

function TDobleArticulosStock.ListarSkus(
  const ACodigoArt: string;
  AIncluirInactivos: Boolean): TArray<TArticuloSkuItem>;
begin
  SetLength(Result, 0);
end;

function TDobleArticulosStock.DescuentoTarifaVigente(
  const ACodigoTarifa: string;
  const AFecha: TDateTime): Boolean;
begin
  Result := False;
end;

function TDobleDocumentosTrabajoStock.ConsultaDocumentosAbiertos(
  const AUsuario: string): string;
begin
  Result := '';
end;

procedure TDobleDocumentosTrabajoStock.CompletarDatosArticulo(
  var ALinea: TDocTrabajoLineaOrigen);
begin
end;

function TDobleDocumentosTrabajoStock.ConsultarDestinosCompartir:
  IConsultaDocumentoTrabajo;
begin
  Result := nil;
end;

function TDobleDocumentosTrabajoStock.ListarNombresAtributos:
  TNombresAtributosDocumentoTrabajo;
begin
  SetLength(Result, 0);
end;

function TDobleDocumentosTrabajoStock.CrearDocumento(
  const ATitulo, AEmpresa, AAlmacen,
  AUsuario: string): Int64;
begin
  Result := 0;
end;

procedure TDobleDocumentosTrabajoStock.InsertarLinea(
  AIdDocumento: Int64;
  const ALinea: TDocTrabajoLineaOrigen;
  const AUsuario: string);
begin
end;

function TDobleDocumentosTrabajoStock.SiguienteContador(
  const ASerie, ATipoDocumento, AEmpresa,
  AUsuario: string): string;
begin
  Result := '';
end;

function TDobleDocumentosTrabajoStock.CrearAlbaran(
  AIdDocumento: Int64;
  const AEmpresa, AAlmacen, ASerie, ANumero,
  AUsuario: string): Integer;
begin
  Result := 0;
end;

function TDobleDocumentosTrabajoStock.CrearFacturaVenta(
  AIdDocumento: Int64;
  const AEmpresa, AAlmacen, ASerie, ANumero,
  AUsuario: string): Integer;
begin
  Result := 0;
end;

function TDobleDocumentosTrabajoStock.CrearPedidoCompra(
  AIdDocumento: Int64;
  const AEmpresa, AAlmacen, ASerie, ANumero,
  AUsuario: string): Integer;
begin
  Result := 0;
end;

function TDobleDocumentosTrabajoStock.CrearInventario(
  AIdDocumento: Int64;
  const AEmpresa, AAlmacen, ASerie, ANumero,
  AUsuario: string): Integer;
begin
  Result := 0;
end;

function TDobleDocumentosTrabajoStock.CrearSesionTarifa(
  AIdDocumento: Int64;
  const AUsuario: string): Int64;
begin
  Result := 0;
end;

function CrearContextoConDobles: TContextoDependenciasStockConsulta;
var
  Articulos: TDobleArticulosStock;
  Documentos: TRepositoriosDocumentosTrabajo;
  DobleDocumentos: TDobleDocumentosTrabajoStock;
  DobleStock: TDobleStockConsulta;
  Servicios: TServiciosStockConsulta;
begin
  DobleStock := TDobleStockConsulta.Create;
  Articulos := TDobleArticulosStock.Create;
  DobleDocumentos := TDobleDocumentosTrabajoStock.Create;
  Servicios.Catalogos := DobleStock;
  Servicios.Pivote := DobleStock;
  Documentos.Lecturas := DobleDocumentos;
  Documentos.Escritura := DobleDocumentos;
  Documentos.Materializacion := DobleDocumentos;
  Result := TContextoDependenciasStockConsulta.Crear(
    Servicios,
    DobleStock,
    Articulos,
    Articulos,
    Documentos);
end;

procedure TPruebasInyeccionStockConsulta.
  Contexto_SeConstruyeConDoblesSinRaizVisual;
var
  Contexto: TContextoDependenciasStockConsulta;
begin
  Contexto := CrearContextoConDobles;
  try
    Assert.IsTrue(Assigned(Contexto.Catalogos));
    Assert.IsTrue(Assigned(Contexto.Pivote));
    Assert.IsTrue(Assigned(Contexto.InfoCabecera));
    Assert.IsTrue(Assigned(Contexto.Validador));
    Assert.IsTrue(Assigned(Contexto.ResolverArticulos));
    Assert.IsTrue(Assigned(Contexto.DocumentosTrabajo.Lecturas));
    Assert.IsTrue(Assigned(Contexto.DocumentosTrabajo.Escritura));
    Assert.IsTrue(
      Assigned(Contexto.DocumentosTrabajo.Materializacion));
  finally
    Contexto.Liberar;
  end;
end;

procedure TPruebasInyeccionStockConsulta.
  DependenciaAusente_FallaAlPrepararElContexto;
var
  Contexto: TContextoDependenciasStockConsulta;
begin
  Contexto := CrearContextoConDobles;
  try
    Contexto.Catalogos := nil;
    Assert.WillRaise(
      procedure
      begin
        Contexto.Validar;
      end,
      EArgumentNilException);
  finally
    Contexto.Liberar;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasInyeccionStockConsulta);

end.
