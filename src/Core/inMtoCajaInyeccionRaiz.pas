{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaInyeccionRaiz                                       }
{    Tipo:       Composición raíz                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{                                                                              }
{  Descripción:                                                                }
{    Compone los contextos mínimos de Caja y registra sus fábricas.            }
{******************************************************************************}
unit inMtoCajaInyeccionRaiz;

interface

uses
  System.Classes,
  Data.DB,
  Uni,
  inLibCajaVentanasIntf,
  inLibPermisosIntf,
  inLibCajaPantallaInyeccion,
  inLibCajasDefectoPersistenciaIntf,
  inLibCajaOperacionesHistPersistenciaIntf,
  inLibCajaPagosHistPersistenciaIntf,
  inLibCajaPantallaHistoricosIntf,
  inLibPerfilesUsuarioIntf,
  UniDataComposicionAplicacion,
  UniDataCajaPantallaComposicion;

type
  TInyeccionCajaRaiz = class
  private
    FOwnerRaiz: TComponent;
    FComposicion: TComposicionAplicacion;
    function Componer(const ANombrePantalla: string):
      TComposicionCajaPantalla;
    function CrearDependenciasInforme(
      const ACaja: TComposicionCajaPantalla
    ): TDependenciasInformeCaja;
    function CrearDependenciasTraspaso(
      const ACaja: TComposicionCajaPantalla
    ): TDependenciasTraspasoCaja;
  public
    constructor Create(
      AOwnerRaiz: TComponent;
      AComposicion: TComposicionAplicacion);
    procedure RegistrarFabricas;
    procedure RetirarFabricas;
    function CrearOperacion(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion): IOperacionCaja;
    function CrearConsulta(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion): IConsultaOperacionesCaja;
    function CrearTraspaso(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion): ITraspasoCaja;
    procedure MostrarMenu(const APermisos: IPermisosAplicacion);
    procedure MostrarParametros;
    procedure MostrarInformeOperacionesVenta;
    function CrearRepositorioCajasDefecto(
      const ANombrePantalla: string): IRepositorioCajasDefecto;
  end;

implementation

uses
  System.SysUtils,
  Vcl.Forms,
  inLibRegistroPantallas,
  inMtoFrmBase,
  inMtoCajaOpe,
  inMtoConsultaOpe,
  inMtoTraspasoOpe,
  inMtoCajaMenu,
  inMtoCajaParam,
  inMtoCajaOperacionesHist,
  inMtoCajaPagosHist,
  inMtoCajaArqueosHist,
  inMtoDepositosCliente,
  inMtoUsuarios,
  inMtoModalImpOperacionesVenta;

procedure NormalizarOwnerPantallaCaja(
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

procedure ReparentarCajaSiProcede(
  AFormulario: TForm;
  AReparentarAplicacion: Boolean);
begin
  if AReparentarAplicacion then
  begin
    AFormulario.Owner.RemoveComponent(AFormulario);
    Application.InsertComponent(AFormulario);
  end;
end;

constructor TInyeccionCajaRaiz.Create(
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

function TInyeccionCajaRaiz.Componer(
  const ANombrePantalla: string): TComposicionCajaPantalla;
begin
  Result := ComponerCajaPantalla(
    FComposicion.CrearRepositoriosArticulosPantalla(ANombrePantalla),
    FComposicion.CrearRepositoriosCajaPantalla(ANombrePantalla),
    FComposicion.CrearRepositoriosConfiguracionPantalla(ANombrePantalla),
    FComposicion.CrearRepositoriosOperacionesPantalla(ANombrePantalla),
    FComposicion.CrearRepositoriosTicketsCajaPantalla(ANombrePantalla));
end;

function TInyeccionCajaRaiz.CrearDependenciasInforme(
  const ACaja: TComposicionCajaPantalla): TDependenciasInformeCaja;
begin
  Result := Default(TDependenciasInformeCaja);
  Result.Repositorio := ACaja.Informes.CrearRepositorioInformesCaja;
  Result.CajasDefecto := ACaja.Operaciones.CrearRepositorioCajasDefecto;
  Result.Validar;
end;

function TInyeccionCajaRaiz.CrearDependenciasTraspaso(
  const ACaja: TComposicionCajaPantalla): TDependenciasTraspasoCaja;
begin
  Result := Default(TDependenciasTraspasoCaja);
  Result.Consultas := ACaja.Consultas.CrearRepositorioConsultasCaja;
  Result.Persistencia := ACaja.Operaciones.CrearRepositorioTraspasoOpe;
  Result.ValidadorArticulos :=
    ACaja.Operaciones.CrearValidadorArticulos;
  Result.AtributosArticulos :=
    ACaja.Operaciones.CrearLookupAtributosArticulos;
  Result.Ticket := ACaja.Tickets.CrearRepositorioTraspasoTicket;
  Result.Validar;
end;

function TInyeccionCajaRaiz.CrearOperacion(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion): IOperacionCaja;
var
  Caja: TComposicionCajaPantalla;
  Dependencias: TDependenciasOperacionCaja;
  Formulario: TfrmMtoOpeCaja;
begin
  Caja := Componer('frmMtoOpeCaja');
  Dependencias := Default(TDependenciasOperacionCaja);
  Dependencias.ResolverArticulos :=
    Caja.Operaciones.CrearResolverArticulos;
  Dependencias.ValidadorArticulos :=
    Caja.Operaciones.CrearValidadorArticulos;
  Dependencias.AtributosArticulos :=
    Caja.Operaciones.CrearLookupAtributosArticulos;
  Dependencias.Articulos :=
    Caja.Operaciones.CrearRepositorioArticulosCaja;
  Dependencias.TraspasoTicket :=
    Caja.Tickets.CrearRepositorioTraspasoTicket;
  Dependencias.Tickets := Caja.Tickets.CrearRepositorioTicketsCaja;
  Dependencias.FaseCobro.Persistencia :=
    Caja.Operaciones.CrearRepositorioFaseCobro;
  Dependencias.FaseCobro.Vales :=
    Caja.Informes.CrearRepositorioInformesCaja;
  Dependencias.Validar;
  Formulario := TfrmMtoOpeCaja.Create(
    AOwner,
    TContextoAutorizacionPantalla.Crear(APermisos),
    Dependencias);
  Result := Formulario;
end;

function TInyeccionCajaRaiz.CrearConsulta(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion): IConsultaOperacionesCaja;
var
  Caja: TComposicionCajaPantalla;
  Dependencias: TDependenciasConsultaOperacionesCaja;
  Formulario: TfrmConsultaOpe;
begin
  Caja := Componer('frmConsultaOpe');
  Dependencias := Default(TDependenciasConsultaOperacionesCaja);
  Dependencias.Facturas :=
    Caja.Consultas.CrearRepositorioConsultaFacturas;
  Dependencias.VentasCalendario :=
    Caja.Consultas.CrearRepositorioVentasCalendario;
  Dependencias.EmisionFiscal :=
    Caja.Consultas.CrearServicioEmisionFiscal;
  Dependencias.TraspasoTicket :=
    Caja.Tickets.CrearRepositorioTraspasoTicket;
  Dependencias.Tickets := Caja.Tickets.CrearRepositorioTicketsCaja;
  Dependencias.LecturasTicket :=
    Caja.Tickets.CrearLecturasImpresionTicketCaja;
  Dependencias.Validar;
  Formulario := TfrmConsultaOpe.Create(
    AOwner,
    APermisos,
    Dependencias);
  Result := Formulario;
end;

function TInyeccionCajaRaiz.CrearTraspaso(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion): ITraspasoCaja;
var
  Caja: TComposicionCajaPantalla;
  Dependencias: TDependenciasTraspasoCaja;
begin
  Caja := Componer('frmMtoOpeTraspaso');
  Dependencias := CrearDependenciasTraspaso(Caja);
  Result := TfrmMtoOpeTraspaso.Create(
    AOwner,
    APermisos,
    Dependencias);
end;

procedure TInyeccionCajaRaiz.MostrarMenu(
  const APermisos: IPermisosAplicacion);
var
  Caja: TComposicionCajaPantalla;
  Dependencias: TDependenciasMenuCaja;
begin
  Caja := Componer('frmMtoMenuCaja');
  Dependencias := Default(TDependenciasMenuCaja);
  Dependencias.VentasCalendario :=
    Caja.Consultas.CrearRepositorioVentasCalendario;
  Dependencias.CajasDefecto :=
    Caja.Operaciones.CrearRepositorioCajasDefecto;
  Dependencias.EntradaCambio.Consultas :=
    Caja.Consultas.CrearRepositorioConsultasCaja;
  Dependencias.EntradaCambio.Persistencia :=
    Caja.Tickets.CrearRepositorioEntradaCambio;
  Dependencias.EntradaCambio.LecturasTicket :=
    Caja.Tickets.CrearLecturasImpresionTicketCaja;
  Dependencias.Gasto.Consultas :=
    Caja.Consultas.CrearRepositorioConsultasCaja;
  Dependencias.Gasto.Persistencia :=
    Caja.Tickets.CrearRepositorioGastoCaja;
  Dependencias.Gasto.LecturasTicket :=
    Caja.Tickets.CrearLecturasImpresionTicketCaja;
  Dependencias.Arqueo.Modal :=
    Caja.Arqueos.CrearRepositorioModalArqueo;
  Dependencias.Arqueo.Persistencia :=
    Caja.Arqueos.CrearPersistenciaArqueoCaja;
  Dependencias.Arqueo.Arqueo :=
    Caja.Arqueos.CrearRepositorioArqueoCaja;
  Dependencias.Arqueo.Ticket :=
    Caja.Arqueos.CrearRepositorioArqueoTicket;
  Dependencias.Arqueo.Tira :=
    Caja.Arqueos.CrearRepositorioTiraCajaTicket;
  Dependencias.Arqueo.Informes :=
    Caja.Informes.CrearRepositorioInformesCaja;
  Dependencias.Traspaso := CrearDependenciasTraspaso(Caja);
  Dependencias.Validar;
  MostrarMenuCaja(APermisos, Dependencias);
end;

procedure TInyeccionCajaRaiz.MostrarParametros;
var
  Caja: TComposicionCajaPantalla;
  Dependencias: TDependenciasParametrosCaja;
  Formulario: TfrmMtoCajaParam;
begin
  Caja := Componer('frmMtoCajaParam');
  Dependencias := Default(TDependenciasParametrosCaja);
  Dependencias.Edicion := FComposicion.ParametrosCajaEdicion;
  Dependencias.Persistencia :=
    Caja.Configuracion.CrearRepositorioAppParam;
  Dependencias.Validar;
  Formulario := TfrmMtoCajaParam.Create(
    FOwnerRaiz,
    TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
    Dependencias);
  try
    Formulario.ShowModal;
  finally
    Formulario.Free;
  end;
end;

procedure TInyeccionCajaRaiz.MostrarInformeOperacionesVenta;
var
  Caja: TComposicionCajaPantalla;
  Formulario: TfrmPrintOperacionesVenta;
begin
  Caja := Componer('frmPrintOperacionesVenta');
  Formulario := TfrmPrintOperacionesVenta.Create(
    FOwnerRaiz,
    Caja.Informes.CrearRepositorioInformesCaja);
  try
    Formulario.ShowModal;
  finally
    Formulario.Free;
  end;
end;

function TInyeccionCajaRaiz.CrearRepositorioCajasDefecto(
  const ANombrePantalla: string): IRepositorioCajasDefecto;
var
  Caja: TComposicionCajaPantalla;
begin
  Caja := Componer(ANombrePantalla);
  Result := Caja.Operaciones.CrearRepositorioCajasDefecto;
end;

procedure TInyeccionCajaRaiz.RegistrarFabricas;
begin
  RegistrarFabricaPantalla(
    TfrmMtoCajaArqueosHist,
    function(AOwner: TComponent): TForm
    var
      Caja: TComposicionCajaPantalla;
      Formulario: TfrmMtoCajaArqueosHist;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantallaCaja(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Caja := Componer('frmMtoCajaArqueosHist');
      Formulario := TfrmMtoCajaArqueosHist.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        CrearDependenciasInforme(Caja));
      ReparentarCajaSiProcede(Formulario, ReparentarAplicacion);
      Result := Formulario;
    end);

  RegistrarFabricaPantalla(
    TfrmMtoDepositosCliente,
    function(AOwner: TComponent): TForm
    var
      Caja: TComposicionCajaPantalla;
      Formulario: TfrmMtoDepositosCliente;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantallaCaja(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Caja := Componer('frmMtoDepositosCliente');
      Formulario := TfrmMtoDepositosCliente.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        CrearDependenciasInforme(Caja));
      ReparentarCajaSiProcede(Formulario, ReparentarAplicacion);
      Result := Formulario;
    end);

  RegistrarFabricaPantalla(
    TfrmMtoUsuarios,
    function(AOwner: TComponent): TForm
    var
      Caja: TComposicionCajaPantalla;
      Formulario: TfrmMtoUsuarios;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantallaCaja(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Caja := Componer('frmMtoUsuarios');
      Formulario := TfrmMtoUsuarios.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        Caja.Operaciones.CrearRepositorioCajasDefecto);
      ReparentarCajaSiProcede(Formulario, ReparentarAplicacion);
      Result := Formulario;
    end);

  RegistrarFabricaPantalla(
    TfrmMtoCajaOperacionesHist,
    function(AOwner: TComponent): TForm
    var
      Caja: TComposicionCajaPantalla;
      Dependencias: TDependenciasOperacionesHistoricasCaja;
      Formulario: TfrmMtoCajaOperacionesHist;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantallaCaja(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Caja := Componer('frmMtoCajaOperacionesHist');
      Dependencias := Default(TDependenciasOperacionesHistoricasCaja);
      Dependencias.CrearPersistencia :=
        function(ADataSet: TDataSet): IRepositorioCajaOperacionesHist
        begin
          Result := Caja.Historicos.CrearRepositorioCajaOperacionesHist(
            ADataSet);
        end;
      Dependencias.CrearPerfiles :=
        function(
          AConexion: TUniConnection;
          const AEscritor: IEscritorPerfilesUsuario
        ): IGrabadorPerfilesHistoricoCaja
        begin
          Result := Caja.Historicos.CrearGrabadorPerfiles(
            AConexion,
            AEscritor);
        end;
      Dependencias.Informe := CrearDependenciasInforme(Caja);
      Dependencias.Validar;
      Formulario := TfrmMtoCajaOperacionesHist.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        Dependencias);
      ReparentarCajaSiProcede(Formulario, ReparentarAplicacion);
      Result := Formulario;
    end);

  RegistrarFabricaPantalla(
    TfrmMtoCajaPagosHist,
    function(AOwner: TComponent): TForm
    var
      Caja: TComposicionCajaPantalla;
      Dependencias: TDependenciasPagosHistoricosCaja;
      Formulario: TfrmMtoCajaPagosHist;
      OwnerCreacion: TComponent;
      ReparentarAplicacion: Boolean;
    begin
      NormalizarOwnerPantallaCaja(
        AOwner,
        FOwnerRaiz,
        OwnerCreacion,
        ReparentarAplicacion);
      Caja := Componer('frmMtoCajaPagosHist');
      Dependencias := Default(TDependenciasPagosHistoricosCaja);
      Dependencias.CrearPersistencia :=
        function(ADataSet: TDataSet): IRepositorioCajaPagosHist
        begin
          Result := Caja.Historicos.CrearRepositorioCajaPagosHist(
            ADataSet);
        end;
      Dependencias.CrearPerfiles :=
        function(
          AConexion: TUniConnection;
          const AEscritor: IEscritorPerfilesUsuario
        ): IGrabadorPerfilesHistoricoCaja
        begin
          Result := Caja.Historicos.CrearGrabadorPerfiles(
            AConexion,
            AEscritor);
        end;
      Dependencias.Informe := CrearDependenciasInforme(Caja);
      Dependencias.Validar;
      Formulario := TfrmMtoCajaPagosHist.Create(
        OwnerCreacion,
        TContextoAutorizacionPantalla.Crear(FComposicion.Permisos),
        Dependencias);
      ReparentarCajaSiProcede(Formulario, ReparentarAplicacion);
      Result := Formulario;
    end);
end;

procedure TInyeccionCajaRaiz.RetirarFabricas;
begin
  RetirarFabricaPantalla(TfrmMtoCajaPagosHist);
  RetirarFabricaPantalla(TfrmMtoCajaOperacionesHist);
  RetirarFabricaPantalla(TfrmMtoUsuarios);
  RetirarFabricaPantalla(TfrmMtoDepositosCliente);
  RetirarFabricaPantalla(TfrmMtoCajaArqueosHist);
end;

end.
