{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataMantenimientosInyeccionRaiz                            }
{    Tipo:       Composición raíz                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{                                                                              }
{  Descripción:                                                                }
{    Registra las fábricas de mantenimientos que requieren dependencias        }
{    explícitas y las compone exclusivamente en la raíz de la aplicación.      }
{******************************************************************************}
unit UniDataMantenimientosInyeccionRaiz;

interface

uses
  System.Classes,
  UniDataComposicionAplicacion;

type
  TInyeccionMantenimientosRaiz = class
  private
    FOwnerRaiz: TComponent;
    FComposicion: TComposicionAplicacion;
  public
    constructor Create(
      AOwnerRaiz: TComponent;
      AComposicion: TComposicionAplicacion);
    procedure RegistrarFabricas;
    procedure RetirarFabricas;
  end;

implementation

uses
  System.SysUtils,
  Vcl.Forms,
  inLibRegistroPantallas,
  inMtoFrmBase,
  inMtoStockConsulta,
  inMtoStockConsultaPresentacionComposicion,
  inMtoAlbaranesCompra,
  inMtoFacturasCompra,
  inMtoPedidosCompra,
  inMtoDevolucionesCompra,
  inMtoDocumentosTrabajo,
  inMtoArticulos,
  inMtoInventarios,
  inMtoComprasSesiones,
  inMtoFacturasNormal,
  inMtoFacturasSimplif,
  inLibPermisosIntf,
  inLibRepositoriosPantallaIntf,
  inLibArticulosInyeccion,
  inLibInventariosInyeccion,
  inLibFacturasInyeccion,
  inLibComprasSesionesInyeccion,
  UniDataArticulosPropiedadesRepositorio,
  UniDataArticulosVariaciones,
  UniDataInventariosInyeccion,
  UniDataFacturasInyeccion;

type
  TfrmStockConsultaInyectadaRaiz = class(TfrmStockConsulta)
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ADependencias: TContextoDependenciasStockConsulta);
  end;

constructor TfrmStockConsultaInyectadaRaiz.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ADependencias: TContextoDependenciasStockConsulta);
begin
  ADependencias.Validar;
  FDependencias := ADependencias;
  inherited Create(AOwner, AContexto);
end;

procedure NormalizarOwnerPantalla(
  AOwnerSolicitado: TComponent;
  AOwnerRaiz: TComponent;
  out AOwnerCreacion: TComponent;
  out AReparentarAplicacion: Boolean);
begin
  AReparentarAplicacion := AOwnerSolicitado = Application;
  AOwnerCreacion := AOwnerSolicitado;
  if not Assigned(AOwnerCreacion) or AReparentarAplicacion then
    AOwnerCreacion := AOwnerRaiz;
end;

procedure ReparentarAplicacionSiProcede(
  AFormulario: TForm;
  AReparentarAplicacion: Boolean);
begin
  if AReparentarAplicacion then
  begin
    AFormulario.Owner.RemoveComponent(AFormulario);
    Application.InsertComponent(AFormulario);
  end;
end;

constructor TInyeccionMantenimientosRaiz.Create(
  AOwnerRaiz: TComponent;
  AComposicion: TComposicionAplicacion);
begin
  inherited Create;
  if not Assigned(AOwnerRaiz) then
    raise EArgumentNilException.Create('AOwnerRaiz');
  if not Assigned(AComposicion) then
    raise EArgumentNilException.Create('AComposicion');
  FOwnerRaiz := AOwnerRaiz;
  FComposicion := AComposicion;
end;

procedure TInyeccionMantenimientosRaiz.RegistrarFabricas;
begin
  RegistrarFabricaPantalla(
    TfrmStockConsulta,
    function(AOwner: TComponent): TForm
    var
      Articulos: IRepositoriosArticulosPantalla;
      Dependencias: TContextoDependenciasStockConsulta;
      Documentos: IRepositoriosDocumentosPantalla;
      Formulario: TfrmStockConsultaInyectadaRaiz;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Articulos := FComposicion.CrearRepositoriosArticulosPantalla(
        NOMBRE_PANTALLA_STOCK_CONSULTA);
      Documentos := FComposicion.CrearRepositoriosDocumentosPantalla(
        NOMBRE_PANTALLA_STOCK_CONSULTA);
      Dependencias := CrearContextoStockConsulta(
        Articulos,
        Documentos,
        FComposicion.DmConn.conUni);
      Formulario := TfrmStockConsultaInyectadaRaiz.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        Dependencias);
      ReparentarAplicacionSiProcede(Formulario, ReparentarAplicacion);
      Result := Formulario;
    end);

  RegistrarFabricaPantalla(
    TfrmMtoAlbaranesCompra,
    function(AOwner: TComponent): TForm
    var
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Result := CrearAlbaranesCompraInyectada(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        FComposicion.CrearRepositoriosArticulosPantalla(
          NOMBRE_PANTALLA_ALBARANES_COMPRA));
      ReparentarAplicacionSiProcede(Result, ReparentarAplicacion);
    end);

  RegistrarFabricaPantalla(
    TfrmMtoFacturasCompra,
    function(AOwner: TComponent): TForm
    var
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Result := CrearFacturasCompraInyectada(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        FComposicion.CrearRepositoriosArticulosPantalla(
          NOMBRE_PANTALLA_FACTURAS_COMPRA));
      ReparentarAplicacionSiProcede(Result, ReparentarAplicacion);
    end);

  RegistrarFabricaPantalla(
    TfrmMtoPedidosCompra,
    function(AOwner: TComponent): TForm
    var
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Result := CrearPedidosCompraInyectada(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        FComposicion.CrearRepositoriosArticulosPantalla(
          NOMBRE_PANTALLA_PEDIDOS_COMPRA));
      ReparentarAplicacionSiProcede(Result, ReparentarAplicacion);
    end);

  RegistrarFabricaPantalla(
    TfrmMtoDevolucionesCompra,
    function(AOwner: TComponent): TForm
    var
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Result := CrearDevolucionesCompraInyectada(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        FComposicion.CrearRepositoriosArticulosPantalla(
          NOMBRE_PANTALLA_DEVOLUCIONES_COMPRA));
      ReparentarAplicacionSiProcede(Result, ReparentarAplicacion);
    end);

  RegistrarFabricaPantalla(
    TfrmMtoDocumentosTrabajo,
    function(AOwner: TComponent): TForm
    var
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Result := CrearDocumentosTrabajoCompraInyectada(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        FComposicion.CrearRepositoriosArticulosPantalla(
          NOMBRE_PANTALLA_DOCUMENTOS_TRABAJO),
        FComposicion.CrearRepositoriosCajaPantalla(
          NOMBRE_PANTALLA_DOCUMENTOS_TRABAJO).
          CrearRepositorioCajasDefecto);
      ReparentarAplicacionSiProcede(Result, ReparentarAplicacion);
    end);

  RegistrarFabricaPantalla(
    TfrmMtoArticulos,
    function(AOwner: TComponent): TForm
    var
      Articulos: IRepositoriosArticulosPantalla;
      Dependencias: TContextoDependenciasArticulos;
      Formulario: TfrmMtoArticulos;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Articulos := FComposicion.CrearRepositoriosArticulosPantalla(
        'frmMtoArticulos');
      Dependencias := TContextoDependenciasArticulos.Crear(
        CrearCreadorGuardadoArticulo,
        CrearServiciosPropiedadesArticuloUniDAC(
          FComposicion.DmConn.conUni),
        CrearArticulosVariacionesUniDAC(FComposicion.DmConn.conUni),
        Articulos.CrearRepositorioMargen);
      Formulario := TfrmMtoArticulos.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        Dependencias);
      ReparentarAplicacionSiProcede(Formulario, ReparentarAplicacion);
      Result := Formulario;
    end);

  RegistrarFabricaPantalla(
    TfrmMtoInventarios,
    function(AOwner: TComponent): TForm
    var
      Articulos: IRepositoriosArticulosPantalla;
      Dependencias: TDependenciasInventarios;
      Formulario: TfrmMtoInventarios;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Articulos := FComposicion.CrearRepositoriosArticulosPantalla(
        'frmMtoInventarios');
      Dependencias := CrearDependenciasInventariosUniDAC(
        Articulos,
        FComposicion.DmConn.conUni);
      Formulario := TfrmMtoInventarios.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        Dependencias);
      ReparentarAplicacionSiProcede(Formulario, ReparentarAplicacion);
      Result := Formulario;
    end);

  RegistrarFabricaPantalla(
    TfrmMtoComprasSesiones,
    function(AOwner: TComponent): TForm
    var
      Dependencias: TContextoDependenciasComprasSesiones;
      Formulario: TfrmMtoComprasSesiones;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
      Sql: TServiciosSqlPantalla;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Sql := FComposicion.CrearServiciosSqlPantalla(
        NOMBRE_PANTALLA_COMPRAS_SESIONES);
      Dependencias := TContextoDependenciasComprasSesiones.Crear(
        Sql.Catalogo,
        Sql.Incidencias,
        FComposicion.CrearRepositoriosArticulosPantalla(
          NOMBRE_PANTALLA_COMPRAS_SESIONES).
          CrearRepositorioDistribuidor);
      Formulario := TfrmMtoComprasSesiones.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        Dependencias);
      ReparentarAplicacionSiProcede(Formulario, ReparentarAplicacion);
      Result := Formulario;
    end);

  RegistrarFabricaPantalla(
    TfrmMtoFacturasNormal,
    function(AOwner: TComponent): TForm
    var
      ContextoUniDAC: TContextoFacturasUniDAC;
      Dependencias: TDependenciasFacturas;
      Formulario: TfrmMtoFacturasNormal;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
      Sql: TServiciosSqlPantalla;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Sql := FComposicion.CrearServiciosSqlPantalla(
        'frmMtoFacturasNormal');
      ContextoUniDAC := Default(TContextoFacturasUniDAC);
      ContextoUniDAC.Conexion := FComposicion.DmConn.conUni;
      ContextoUniDAC.ParametrosApp := FComposicion.ParametrosApp;
      ContextoUniDAC.ParametrosCaja := FComposicion.ParametrosCaja;
      ContextoUniDAC.CatalogoSql := Sql.Catalogo;
      ContextoUniDAC.IncidenciasSql := Sql.Incidencias;
      ContextoUniDAC.RegistroLog := FComposicion.RegistroLog;
      ContextoUniDAC.Usuario := FComposicion.ContextoSesion.Identidad.Usuario;
      Dependencias := CrearDependenciasFacturasUniDAC(ContextoUniDAC);
      Formulario := TfrmMtoFacturasNormal.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        Dependencias);
      ReparentarAplicacionSiProcede(Formulario, ReparentarAplicacion);
      Result := Formulario;
    end);

  RegistrarFabricaPantalla(
    TfrmMtoFacturasSimplif,
    function(AOwner: TComponent): TForm
    var
      ContextoUniDAC: TContextoFacturasUniDAC;
      Dependencias: TDependenciasFacturas;
      Formulario: TfrmMtoFacturasSimplif;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
      Sql: TServiciosSqlPantalla;
    begin
      NormalizarOwnerPantalla(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Sql := FComposicion.CrearServiciosSqlPantalla(
        'frmMtoFacturasSimplif');
      ContextoUniDAC := Default(TContextoFacturasUniDAC);
      ContextoUniDAC.Conexion := FComposicion.DmConn.conUni;
      ContextoUniDAC.ParametrosApp := FComposicion.ParametrosApp;
      ContextoUniDAC.ParametrosCaja := FComposicion.ParametrosCaja;
      ContextoUniDAC.CatalogoSql := Sql.Catalogo;
      ContextoUniDAC.IncidenciasSql := Sql.Incidencias;
      ContextoUniDAC.RegistroLog := FComposicion.RegistroLog;
      ContextoUniDAC.Usuario := FComposicion.ContextoSesion.Identidad.Usuario;
      Dependencias := CrearDependenciasFacturasUniDAC(ContextoUniDAC);
      Formulario := TfrmMtoFacturasSimplif.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        Dependencias);
      ReparentarAplicacionSiProcede(Formulario, ReparentarAplicacion);
      Result := Formulario;
    end);
end;

procedure TInyeccionMantenimientosRaiz.RetirarFabricas;
begin
  RetirarFabricaPantalla(TfrmMtoFacturasSimplif);
  RetirarFabricaPantalla(TfrmMtoFacturasNormal);
  RetirarFabricaPantalla(TfrmMtoComprasSesiones);
  RetirarFabricaPantalla(TfrmMtoInventarios);
  RetirarFabricaPantalla(TfrmMtoArticulos);
  RetirarFabricaPantalla(TfrmMtoDocumentosTrabajo);
  RetirarFabricaPantalla(TfrmMtoDevolucionesCompra);
  RetirarFabricaPantalla(TfrmMtoPedidosCompra);
  RetirarFabricaPantalla(TfrmMtoFacturasCompra);
  RetirarFabricaPantalla(TfrmMtoAlbaranesCompra);
  RetirarFabricaPantalla(TfrmStockConsulta);
end;

end.
