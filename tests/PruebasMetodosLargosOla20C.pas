{******************************************************************************}
{                                                                              }
{  Modulo:       PruebasMetodosLargosOla20C                                   }
{    Tipo:       Pruebas de arquitectura (DUnitX)                              }
{ Version:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       FactuZam                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Caracteriza los cinco flujos residuales asignados a la tarea IA-20C.      }
{******************************************************************************}
unit PruebasMetodosLargosOla20C;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TPruebasMetodosLargosOla20C = class
  private
    function RaizRepositorio: string;
    function LeerUnidad(const ARuta: string): string;
    function LeerTramo(
      const ARuta, AInicio, AFin: string): string;
    function ContarLineas(const ATexto: string): Integer;
    procedure ComprobarContiene(
      const ATexto, AFragmento, AMensaje: string);
    procedure ComprobarOrden(
      const ATexto: string;
      const APasos: array of string);
  public
    [Test]
    procedure Traspaso_ConservaAtomicidadYPasos;
    [Test]
    procedure InformeCaja_ConservaComposicionSql;
    [Test]
    procedure EtiquetasPedido_ConservaFuentesYExpansion;
    [Test]
    procedure Inventario_ConservaValidacionYCreacionSku;
    [Test]
    procedure Captions_ConservanRutasPorTipo;
    [Test]
    procedure PedidoVenta_ConservaCreacionAtomicaDeAlbaran;
    [Test]
    procedure CargaMasiva_ConservaFiltrosDePreview;
    [Test]
    procedure Principal_ConservaEnrutadoDeAtajos;
    [Test]
    procedure Albaranes_ConservanFacturacionAgrupada;
    [Test]
    procedure Parametros_ConservanGuardadoYRecarga;
    [Test]
    procedure MetodosObjetivo_QuedanComoCoordinadores;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.StrUtils;

function TPruebasMetodosLargosOla20C.RaizRepositorio: string;
var
  iNivel: Integer;
  sPadre: string;
begin
  Result := GetCurrentDir;
  iNivel := 0;
  while (iNivel < 12) and
        (not TFile.Exists(TPath.Combine(Result, 'fzam.dpr'))) do
  begin
    sPadre := TDirectory.GetParent(Result);
    if SameText(sPadre, Result) then
      iNivel := 12
    else
    begin
      Result := sPadre;
      Inc(iNivel);
    end;
  end;
  Assert.IsTrue(TFile.Exists(TPath.Combine(Result, 'fzam.dpr')),
    'No se localizo la raiz del repositorio');
end;

function TPruebasMetodosLargosOla20C.LeerUnidad(
  const ARuta: string): string;
var
  sRutaCompleta: string;
begin
  sRutaCompleta := TPath.Combine(RaizRepositorio, ARuta);
  Assert.IsTrue(TFile.Exists(sRutaCompleta),
    'No existe la unidad ' + ARuta);
  Result := TFile.ReadAllText(sRutaCompleta);
end;

function TPruebasMetodosLargosOla20C.LeerTramo(
  const ARuta, AInicio, AFin: string): string;
var
  sFuente: string;
  iFin: Integer;
  iInicio: Integer;
begin
  sFuente := LeerUnidad(ARuta);
  iInicio := Pos(AInicio, sFuente);
  Assert.IsTrue(iInicio > 0, 'No se encontro ' + AInicio);
  iFin := PosEx(AFin, sFuente, iInicio + Length(AInicio));
  Assert.IsTrue(iFin > iInicio, 'No se encontro el final ' + AFin);
  Result := Copy(sFuente, iInicio, iFin - iInicio);
end;

function TPruebasMetodosLargosOla20C.ContarLineas(
  const ATexto: string): Integer;
var
  oLineas: TStringList;
begin
  oLineas := TStringList.Create;
  try
    oLineas.Text := ATexto;
    Result := oLineas.Count;
  finally
    FreeAndNil(oLineas);
  end;
end;

procedure TPruebasMetodosLargosOla20C.ComprobarContiene(
  const ATexto, AFragmento, AMensaje: string);
begin
  Assert.IsTrue(Pos(AFragmento, ATexto) > 0, AMensaje);
end;

procedure TPruebasMetodosLargosOla20C.ComprobarOrden(
  const ATexto: string;
  const APasos: array of string);
var
  iPaso: Integer;
  iPosicion: Integer;
begin
  iPosicion := 1;
  for iPaso := Low(APasos) to High(APasos) do
  begin
    iPosicion := PosEx(APasos[iPaso], ATexto, iPosicion);
    Assert.IsTrue(iPosicion > 0,
      'Falta o esta desordenado el paso ' + APasos[iPaso]);
    Inc(iPosicion, Length(APasos[iPaso]));
  end;
end;

procedure TPruebasMetodosLargosOla20C.
  Traspaso_ConservaAtomicidadYPasos;
const
  cRuta = 'src\Caja\DataModules\UniDataTraspaso.pas';
var
  sEjecucion: string;
  sLineas: string;
begin
  sEjecucion := LeerTramo(cRuta,
    'function TdmTraspaso.EjecutarGrabacionTraspaso(',
    'function TdmTraspaso.GrabarTraspaso');
  ComprobarOrden(sEjecucion,
    ['SiguienteOpCaja', 'SiguienteNumeroDocumento',
     'StartTransaction', 'GrabarLineasTraspaso',
     'RegistrarOperacionTraspaso', 'Commit', 'except', 'Rollback']);
  sLineas := LeerTramo(cRuta,
    'function TdmTraspaso.GrabarLineasTraspaso(',
    'procedure TdmTraspaso.RegistrarOperacionTraspaso');
  ComprobarContiene(sLineas, 'InsertarMovimientoAlmacen',
    'El traspaso debe conservar salida y entrada de almacen');
  ComprobarContiene(sLineas, 'RecalcularMovimientosDocumento',
    'El traspaso debe recalcular el documento antes del total');
  ComprobarContiene(sLineas, 'SUM(TOTAL_COSTE_MOV)',
    'El total debe proceder de los movimientos persistidos');
end;

procedure TPruebasMetodosLargosOla20C.
  InformeCaja_ConservaComposicionSql;
const
  cRuta =
    'src\Caja\DataModules\UniDataInformesCajaRepositorio.pas';
var
  sConstruccion: string;
  sFuente: string;
begin
  sConstruccion := LeerTramo(cRuta,
    'function TRepositorioInformesCajaUniDAC.ConstruirSqlOperacionesVenta(',
    'function TRepositorioInformesCajaUniDAC.ConsultarOperacionesVenta');
  ComprobarOrden(sConstruccion,
    ['AnadirCabeceraOperacionesVenta',
     'AnadirAtributosOperacionesVenta',
     'AnadirImportesOperacionesVenta',
     'AnadirOrigenOperacionesVenta',
     'AnadirColoresOperacionesVenta',
     'AnadirPagosOperacionesVenta',
     'AnadirFiltrosOperacionesVenta']);
  sFuente := LeerUnidad(cRuta);
  ComprobarContiene(sFuente, 'AS HEX_COLOR_BASICO',
    'El informe debe conservar el color basico');
  ComprobarContiene(sFuente, 'AS INGRESOS_OPERACION',
    'El informe debe conservar los ingresos por pagos');
  ComprobarContiene(sFuente, 'SQLExcluirVentaRetirada',
    'El informe debe seguir excluyendo ventas retiradas');
end;

procedure TPruebasMetodosLargosOla20C.
  EtiquetasPedido_ConservaFuentesYExpansion;
const
  cRuta = 'src\DataModules\UniDataPedidosCompra.pas';
var
  sFuente: string;
  sMetodo: string;
begin
  sMetodo := LeerTramo(cRuta,
    'procedure TdmPedidosCompra.ExpandirEtiquetasPorCantidadPed(',
    'procedure TdmPedidosCompra.CrearDataSetEtiquetasPed');
  ComprobarOrden(sMetodo,
    ['CargarCantidadesEtiquetas', 'ExpandirDataSetEtiquetas']);
  sFuente := LeerUnidad(cRuta);
  ComprobarContiene(sFuente, 'fza_pedidos_compra_celdas',
    'La cantidad debe incluir las celdas del pivote');
  ComprobarContiene(sFuente, 'UNION ALL',
    'La cantidad debe incluir las lineas sin celdas');
  ComprobarContiene(sFuente, 'NOT EXISTS',
    'Las lineas con celdas no deben contarse dos veces');
  ComprobarContiene(sFuente, 'DisableConstraints',
    'La expansion debe suspender restricciones temporalmente');
  ComprobarContiene(sFuente, 'AIndiceStock',
    'La expansion debe conservar el stock filtrado');
end;

procedure TPruebasMetodosLargosOla20C.
  Inventario_ConservaValidacionYCreacionSku;
const
  cRuta = 'src\DataModules\UniDataInventarios.pas';
var
  sFuente: string;
  sMetodo: string;
begin
  sMetodo := LeerTramo(cRuta,
    'procedure TdmInventarios.cdsLineasBeforePost(DataSet',
    'procedure TdmInventarios.cdsLineasAfterPost');
  ComprobarOrden(sMetodo,
    ['DesactivarRequeridosLinea', 'RegistrarSnapshotLinea',
     'AsegurarFechaRecuentoLinea', 'ValidarClavesLinea',
     'DescartarLineaSinArticulo', 'CompletarUnidadLinea',
     'RequiereValidarSkuLinea', 'ReconstruirSkuLinea',
     'ValidarOCrearSkuLinea']);
  sFuente := LeerUnidad(cRuta);
  ComprobarContiene(sFuente, 'TThread.ForceQueue',
    'La linea vacia debe seguir cancelandose fuera de BeforePost');
  ComprobarContiene(sFuente, 'Abort;',
    'La linea vacia debe abortar el Post automatico');
  ComprobarContiene(sFuente, 'SPreguntaCrearSkuInventario',
    'Un SKU ausente debe seguir pidiendo confirmacion');
  ComprobarContiene(sFuente, 'CrearSkuDesdeLinea',
    'La confirmacion debe seguir creando el SKU');
end;

procedure TPruebasMetodosLargosOla20C.Captions_ConservanRutasPorTipo;
const
  cRuta = 'src\Lib\inLibWin.pas';
var
  sFuente: string;
  sRutaTipos: string;
begin
  sRutaTipos := LeerTramo(cRuta, 'AplicarCaptionComponente(',
    'procedure SetLabelForm');
  ComprobarOrden(sRutaTipos,
    ['AplicarCaptionEtiqueta', 'AplicarCaptionPestana',
     'AplicarCaptionCheckBox', 'AplicarCaptionBoton',
     'AplicarCaptionGrupo', 'AplicarCaptionGrupoRadio',
     'AplicarCaptionBotonRapido', 'AplicarCaptionRadio']);
  sFuente := LeerUnidad(cRuta);
  ComprobarContiene(sFuente, 'lblTablaOrigen',
    'La etiqueta reservada de tabla debe seguir excluida');
  ComprobarContiene(sFuente, 'lblEditMode',
    'La etiqueta reservada de modo debe seguir excluida');
  ComprobarContiene(sFuente, 'GetPerfilSubKeyValueDef',
    'Los captions deben seguir procediendo del perfil');
end;

procedure TPruebasMetodosLargosOla20C.
  PedidoVenta_ConservaCreacionAtomicaDeAlbaran;
const
  cRuta = 'src\DataModules\UniDataPedidos.pas';
var
  sFuente: string;
  sMetodo: string;
begin
  sMetodo := LeerTramo(cRuta,
    'function TdmPedidos.CrearAlbaranDesdePedido',
    'function TdmPedidos.ExistePedidoPrestaShop');
  ComprobarOrden(sMetodo,
    ['InstalarProcedimientos', 'StartTransaction',
     'EjecutarLineasAlbaranPedido', 'EjecutarFinAlbaranPedido',
     'Commit', 'except', 'Rollback']);
  sFuente := LeerUnidad(cRuta);
  ComprobarContiene(sFuente, 'EjecutarInicioAlbaranPedido',
    'Un pedido debe poder crear una cabecera de albaran nueva');
  ComprobarContiene(sFuente, 'CopiarFormaPagoPedidoAAlbaran',
    'La forma de pago debe conservarse al crear o ampliar el albaran');
  ComprobarContiene(sFuente, 'p_CODIGO_ALM',
    'Las lineas deben conservar el almacen solicitado');
end;

procedure TPruebasMetodosLargosOla20C.
  CargaMasiva_ConservaFiltrosDePreview;
const
  cRuta =
    'src\DataModules\UniDataCargaMasivaArticulosRepositorio.pas';
var
  sMetodo: string;
begin
  sMetodo := LeerTramo(cRuta,
    'function TServicioCargaMasivaArticulosUniDAC.' +
    'ConstruirSqlPreviewArticulos',
    'function TServicioCargaMasivaArticulosUniDAC.ConstruirSqlPreview');
  ComprobarOrden(sMetodo,
    ['AnadirOrigenPreviewArticulos', 'SoloActivos',
     'ExcluirYaCargados', 'AnadirFiltroStockPreviewArticulos',
     'AnadirFiltroFamiliasPreviewArticulos',
     'AnadirFiltrosCatalogoPreviewArticulos',
     'AnadirFiltroVentasPreviewArticulos', 'ORDER BY']);
end;

procedure TPruebasMetodosLargosOla20C.
  Principal_ConservaEnrutadoDeAtajos;
const
  cRuta = 'src\Core\inMtoPrincipal.pas';
var
  sFuente: string;
  sMetodo: string;
begin
  sMetodo := LeerTramo(cRuta,
    'function TfrmMtoPrincipal.IsShortCut',
    'procedure TfrmMtoPrincipal.mnuEjecutarScriptClick');
  ComprobarContiene(sMetodo, 'VK_F9',
    'F9 debe conservar la apertura del cajon');
  ComprobarContiene(sMetodo, 'KF_ALTDOWN',
    'Alt+F4 debe conservar el cierre de la aplicacion');
  ComprobarContiene(sMetodo, 'VK_CONTROL',
    'Ctrl+F4 debe conservar el cierre de la ventana activa');
  ComprobarContiene(sMetodo, 'VK_ESCAPE',
    'Escape debe conservar el cierre contextual');
  sFuente := LeerUnidad(cRuta);
  ComprobarContiene(sFuente, 'EjecutarAtajoFormulario',
    'Los ActionList deben seguir recibiendo los atajos');
  ComprobarContiene(sFuente, 'FormularioPestanaActiva',
    'La pestana activa debe seguir participando en el enrutado');
end;

procedure TPruebasMetodosLargosOla20C.
  Albaranes_ConservanFacturacionAgrupada;
const
  cRuta = 'src\DataModules\UniDataAlbaranes.pas';
var
  sMetodo: string;
begin
  sMetodo := LeerTramo(cRuta,
    'function TdmAlbaranes.FacturarAlbaranesLista',
    'function TdmAlbaranes.GenerarMovimientosSalida');
  ComprobarOrden(sMetodo,
    ['PrepararConsultasFacturacionAlbaranes', 'StartTransaction',
     'DescomponerReferenciaAlbaran', 'ConsultarClienteAlbaran',
     'EjecutarCrearFacturaInicio',
     'NegarMovimientosFacturaDesdeAlbaran',
     'AbrirLineasPendientesAlbaran', 'EjecutarCrearFacturaLinea',
     'EjecutarCrearFacturaFin', 'Commit', 'except', 'Rollback']);
  ComprobarContiene(sMetodo, 'bAgruparPorCliente',
    'La lista debe conservar la agrupacion opcional por cliente');
end;

procedure TPruebasMetodosLargosOla20C.
  Parametros_ConservanGuardadoYRecarga;
const
  cRuta = 'src\Core\inMtoAppParam.pas';
var
  sFuente: string;
  sMetodo: string;
begin
  sMetodo := LeerTramo(cRuta,
    'procedure TfrmMtoAppParam.btnGuardarClick',
    'procedure TfrmMtoAppParam.GuardarLayout');
  ComprobarOrden(sMetodo,
    ['SaveValues', 'ClasificarCambioParametro', 'GuardarValores',
     'ActualizarOriginalesParametros', 'ShowMessage', 'Recargar',
     'RegistrarCambioConfiguracionVerifactuSeguro']);
  sFuente := LeerUnidad(cRuta);
  ComprobarContiene(sFuente, 'UsuarioPuedeEditarParametro',
    'Cada parametro debe conservar la validacion de permisos');
  ComprobarContiene(sFuente, 'SAvisoParametrosRestringidos',
    'Los cambios restringidos deben seguir avisandose');
end;

procedure TPruebasMetodosLargosOla20C.
  MetodosObjetivo_QuedanComoCoordinadores;
begin
  Assert.IsTrue(ContarLineas(LeerTramo(
    'src\Caja\DataModules\UniDataTraspaso.pas',
    'function TdmTraspaso.GrabarTraspaso',
    'procedure TdmTraspaso.MarcarSolicitudAtendida')) <= 30);
  Assert.IsTrue(ContarLineas(LeerTramo(
    'src\Caja\DataModules\UniDataInformesCajaRepositorio.pas',
    'function TRepositorioInformesCajaUniDAC.ConstruirSqlOperacionesVenta',
    'function TRepositorioInformesCajaUniDAC.ConsultarOperacionesVenta')) <=
    30);
  Assert.IsTrue(ContarLineas(LeerTramo(
    'src\DataModules\UniDataPedidosCompra.pas',
    'procedure TdmPedidosCompra.ExpandirEtiquetasPorCantidadPed',
    'procedure TdmPedidosCompra.CrearDataSetEtiquetasPed')) <= 30);
  Assert.IsTrue(ContarLineas(LeerTramo(
    'src\DataModules\UniDataInventarios.pas',
    'procedure TdmInventarios.cdsLineasBeforePost',
    'procedure TdmInventarios.cdsLineasAfterPost')) <= 30);
  Assert.IsTrue(ContarLineas(LeerTramo(
    'src\Lib\inLibWin.pas',
    'procedure SetLabelForm(oControl: TComponent; ' +
    'var oPerfilDic: TProfileDicc);',
    'procedure CargarCaptions')) <= 11);
  Assert.IsTrue(ContarLineas(LeerTramo(
    'src\DataModules\UniDataPedidos.pas',
    'function TdmPedidos.CrearAlbaranDesdePedido',
    'function TdmPedidos.ExistePedidoPrestaShop')) <= 70);
  Assert.IsTrue(ContarLineas(LeerTramo(
    'src\DataModules\UniDataCargaMasivaArticulosRepositorio.pas',
    'function TServicioCargaMasivaArticulosUniDAC.' +
    'ConstruirSqlPreviewArticulos',
    'function TServicioCargaMasivaArticulosUniDAC.' +
    'ConstruirSqlPreview')) <= 40);
  Assert.IsTrue(ContarLineas(LeerTramo(
    'src\Core\inMtoPrincipal.pas',
    'function TfrmMtoPrincipal.IsShortCut',
    'procedure TfrmMtoPrincipal.mnuEjecutarScriptClick')) <= 80);
  Assert.IsTrue(ContarLineas(LeerTramo(
    'src\DataModules\UniDataAlbaranes.pas',
    'function TdmAlbaranes.FacturarAlbaranesLista',
    'function TdmAlbaranes.GenerarMovimientosSalida')) <= 95);
  Assert.IsTrue(ContarLineas(LeerTramo(
    'src\Core\inMtoAppParam.pas',
    'procedure TfrmMtoAppParam.btnGuardarClick',
    'procedure TfrmMtoAppParam.GuardarLayout')) <= 100);
end;

initialization
  TDUnitX.RegisterTestFixture(TPruebasMetodosLargosOla20C);

end.
