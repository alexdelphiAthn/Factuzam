{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalArqueo                                              }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       2.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pantalla F11 del menú de caja: arqueo (cierre Z) de un rango de fechas.   }
{    Pestaña Arqueo/Resúmenes/Más datos: importes calculados (lectura).        }
{    Pestaña Recuento: grid editable con una fila por forma de pago para       }
{    que el usuario introduzca lo que ha contado. Botón Grabar Arqueo          }
{    persiste en fza_caja_arqueos + fza_caja_arqueos_recuento.                 }
{******************************************************************************}
unit inMtoModalArqueo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ActnList, System.Actions, Vcl.Menus,
  System.DateUtils,
  Data.DB, Datasnap.DBClient,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxClasses, cxContainer, cxEdit, cxLabel, cxTextEdit, cxButtons,
  cxMaskEdit, cxDropDownEdit, cxCalendar, cxPC, cxNavigator, cxDBData,
  cxCustomData, cxData, cxDataStorage, cxFilter,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid,
  Uni,
  inMtoFrmBase, inLibArqueo, inLibArqueoTicket,
  inLibArqueoIntf, inLibArqueoTicketIntf, inLibArqueoPersistencia,
  inLibTiraCajaTicketIntf,
  inLibModalArqueoPersistenciaIntf,
  inLibInformesCajaPersistenciaIntf,
  UniDataModalArqueoOperacion,
  Vcl.ComCtrls, dxCore,
  cxDateUtils, cxCurrencyEdit, cxRadioGroup,
  JvComponentBase, JvEnterTab, cxLocalization, cxGroupBox,
  inLibCajaPantallaInyeccion;

type
  TfrmModalArqueo = class(TfrmBase)
    pnlTop: TPanel;
    pnlBody: TPanel;
    pnlBottom: TPanel;

    // Pestañas
    pcArqueo: TcxPageControl;
    tsArqueo: TcxTabSheet;
    tsResumenes: TcxTabSheet;
    tsMasDatos: TcxTabSheet;

    // Más datos: rejilla resumen por IVA
    pnlResIVA: TPanel;
    lblResIVATit: TcxLabel;
    cxgrdResIVA: TcxGrid;
    tvResIVA: TcxGridDBTableView;
    tvResIVABASE: TcxGridDBColumn;
    tvResIVAPORC_IVA: TcxGridDBColumn;
    tvResIVACUOTA_IVA: TcxGridDBColumn;
    tvResIVAPORC_RE: TcxGridDBColumn;
    tvResIVACUOTA_RE: TcxGridDBColumn;
    tvResIVABASE_IVAS: TcxGridDBColumn;
    lvResIVA: TcxGridLevel;
    dsResIVA: TDataSource;

    // Resúmenes: paneles y grids (uno por agrupación)
    pnlResEmpleado: TPanel;
    lblResEmpleadoTit: TcxLabel;
    cxgrdResEmpleado: TcxGrid;
    tvResEmpleado: TcxGridDBTableView;
    tvResEmpleadoEMP: TcxGridDBColumn;
    tvResEmpleadoUDS: TcxGridDBColumn;
    tvResEmpleadoNETO: TcxGridDBColumn;
    lvResEmpleado: TcxGridLevel;
    dsResEmpleado: TDataSource;

    pnlResFP: TPanel;
    lblResFPTit: TcxLabel;
    cxgrdResFP: TcxGrid;
    tvResFP: TcxGridDBTableView;
    tvResFPFP: TcxGridDBColumn;
    tvResFPUDS: TcxGridDBColumn;
    tvResFPNETO: TcxGridDBColumn;
    lvResFP: TcxGridLevel;
    dsResFP: TDataSource;

    pnlResFam: TPanel;
    lblResFamTit: TcxLabel;
    cxgrdResFam: TcxGrid;
    tvResFam: TcxGridDBTableView;
    tvResFamFAM: TcxGridDBColumn;
    tvResFamUDS: TcxGridDBColumn;
    tvResFamNETO: TcxGridDBColumn;
    lvResFam: TcxGridLevel;
    dsResFam: TDataSource;

    pnlResProp: TPanel;
    lblResPropTit: TcxLabel;
    cxgrdResProp: TcxGrid;
    tvResProp: TcxGridDBTableView;
    tvResPropPROP: TcxGridDBColumn;
    tvResPropVAL: TcxGridDBColumn;
    tvResPropUDS: TcxGridDBColumn;
    tvResPropNETO: TcxGridDBColumn;
    lvResProp: TcxGridLevel;
    dsResProp: TDataSource;

    // Cabecera (rango + ventas + accesos)
    lblTituloDesde: TcxLabel;
    dteFechaDesde: TcxDateEdit;
    lblTituloHasta: TcxLabel;
    dteFechaHasta: TcxDateEdit;
    lblTituloVentas: TcxLabel;
    lblVentas: TcxLabel;
    btnRecalcular: TcxButton;
    btnImprimir: TcxButton;
    btnHistorico: TcxButton;

    // Sección Líneas artículos
    pnlLineas: TPanel;
    lblLineasTitulo: TcxLabel;
    lblLinBrutoLbl: TcxLabel;
    lblLinBruto: TcxLabel;
    lblLinDescuentoLbl: TcxLabel;
    lblLinDescuento: TcxLabel;
    lblLinNetoLbl: TcxLabel;
    lblLinNeto: TcxLabel;

    // Sección Operaciones
    pnlOperaciones: TPanel;
    lblOpeTitulo: TcxLabel;
    lblOpeVentasNormLbl: TcxLabel;
    lblOpeVentasNorm: TcxLabel;
    lblOpeVentasPrestLbl: TcxLabel;
    lblOpeVentasPrest: TcxLabel;
    lblOpeDevolLbl: TcxLabel;
    lblOpeDevol: TcxLabel;
    lblOpeTotalVentasLbl: TcxLabel;
    lblOpeTotalVentas: TcxLabel;

    // Sección Cobros
    pnlCobros: TPanel;
    lblCobrosTitulo: TcxLabel;
    lblCobValesRecLbl: TcxLabel;
    lblCobValesRec: TcxLabel;
    lblCobValesEmiLbl: TcxLabel;
    lblCobValesEmi: TcxLabel;
    lblCobClientesLbl: TcxLabel;
    lblCobClientes: TcxLabel;
    lblCobPendienteLbl: TcxLabel;
    lblCobPendiente: TcxLabel;
    lblCobIngresosLbl: TcxLabel;
    lblCobIngresos: TcxLabel;

    lblEftIngresosLbl: TcxLabel;
    lblEftIngresos: TcxLabel;
    lblEftEntradasLbl: TcxLabel;
    lblEftEntradas: TcxLabel;
    lblEftSalidasLbl: TcxLabel;
    lblEftSalidas: TcxLabel;
    lblEftAnteriorLbl: TcxLabel;
    lblEftAnterior: TcxLabel;
    lblEftCajaLbl: TcxLabel;
    lblEftCaja: TcxLabel;
    lblTarjetasLbl: TcxLabel;
    lblTarjetas: TcxLabel;
    lblSaldoLbl: TcxLabel;
    lblSaldo: TcxLabel;

    // Pestaña Recuento
    tsRecuento: TcxTabSheet;
    // -- Sección 1: Resto día anterior
    pnlAnterior: TPanel;
    lblAnteriorTit: TcxLabel;
    lblAnteriorImporte: TcxLabel;
    // -- Sección 2: Recuento por forma de pago
    pnlOtrasFP: TPanel;
    lblOtrasFPTit: TcxLabel;
    cxgrdRecuento: TcxGrid;
    tvRecuento: TcxGridTableView;
    tvRecuentoFP: TcxGridColumn;
    tvRecuentoDesc: TcxGridColumn;
    tvRecuentoSistema: TcxGridColumn;
    tvRecuentoImporte: TcxGridColumn;
    tvRecuentoDiferencia: TcxGridColumn;
    lvRecuento: TcxGridLevel;
    // -- Sección 3: Totales + Retirada + Dejo mañana
    pnlRecuentoTotales: TPanel;
    lblDesgloseEfectivo: TcxLabel;
    lblRecTotalSistemaLbl: TcxLabel;
    lblRecTotalSistema: TcxLabel;
    lblRecTotalRecuentoLbl: TcxLabel;
    lblRecTotalRecuento: TcxLabel;
    lblRecDiferenciaLbl: TcxLabel;
    lblRecDiferencia: TcxLabel;
    lblRetiradaLbl: TcxLabel;
    rgRetiradaTipo: TcxRadioGroup;
    txtRetiradaImporte: TcxCurrencyEdit;
    lblDejoLbl: TcxLabel;
    lblDejoImporte: TcxLabel;
    txtObservaciones: TcxTextEdit;
    lblObservacionesLbl: TcxLabel;
    lblVendedorLbl: TcxLabel;
    txtVendedorCodigo: TcxTextEdit;
    lblVendedorNombre: TcxLabel;
    btnGrabarArqueo: TcxButton;

    // Pie
    btnAtras: TcxButton;
    lblESC: TcxLabel;

    // Acciones de teclado
    alArqueo: TActionList;
    actEscape: TAction;
    actRecalcular: TAction;
    actImprimir: TAction;
    actGrabar: TAction;
    actDesplegarDesde: TAction;
    actDesplegarHasta: TAction;
    actHistorico: TAction;
    actTiraCaja: TAction;
    btnTiraCaja: TcxButton;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAtrasClick(Sender: TObject);
    procedure btnRecalcularClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure btnHistoricoClick(Sender: TObject);
    procedure btnTiraCajaClick(Sender: TObject);
    procedure btnGrabarArqueoClick(Sender: TObject);
    procedure actEscapeExecute(Sender: TObject);
    procedure actRecalcularExecute(Sender: TObject);
    procedure actImprimirExecute(Sender: TObject);
    procedure actHistoricoExecute(Sender: TObject);
    procedure actTiraCajaExecute(Sender: TObject);
    procedure actGrabarExecute(Sender: TObject);
    procedure actDesplegarDesdeExecute(Sender: TObject);
    procedure actDesplegarHastaExecute(Sender: TObject);
    procedure dteFechaDesdePropertiesChange(Sender: TObject);
    procedure dteFechaHastaPropertiesChange(Sender: TObject);
    procedure tvRecuentoImportePropertiesEditValueChanged(
      Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem);
    procedure tvRecuentoKeyDown(Sender: TObject;
      var Key: Word; Shift: TShiftState);
    procedure txtRetiradaImportePropertiesChange(Sender: TObject);
    procedure txtVendedorCodigoExit(Sender: TObject);
  private
    FConn         : TUniConnection;
    FEmpresa      : string;
    FAlmacen      : string;
    FCaja         : string;
    FArqueoActual : TArqueoCaja;
    FArqueoTarjetasPermitido: Boolean;
    FPuedeVerResumen: Boolean;
    FResumenFamilias: TClientDataSet;
    FRepositorioPersistencia: IRepositorioModalArqueo;
    FPersistenciaArqueo: IArqueoPersistencia;
    FRepositorioArqueoCaja: IRepositorioArqueoCaja;
    FRepositorioArqueoTicket: IRepositorioArqueoTicket;
    FRepositorioTiraCaja: IRepositorioTiraCajaTicket;
    FRepositorioInformes: IRepositorioInformesCaja;
    FResumenEmpleados: IResultadoModalArqueo;
    FResumenFormasPago: IResultadoModalArqueo;
    FResumenPropiedades: IResultadoModalArqueo;
    FResumenIva: IResultadoModalArqueo;
    FOperacionArqueo: TOperacionModalArqueo;
    procedure ComponerDependencias;
    function  FechaEditada(AEdit: TcxDateEdit): TDateTime;
    function  FechaDesdeSeleccionada: TDateTime;
    function  FechaHastaSeleccionada: TDateTime;
    procedure RellenarPantalla(const AArqueo: TArqueoCaja);
    procedure Recalcular;
    procedure ConfigurarResumenes;
    procedure RefrescarResumenes;
    procedure CargarResumenFamilias;
    function ConstruirSolicitudResumen:
      TSolicitudResumenModalArqueo;
    function  FormatImporte(AValor: Currency): string;
    procedure CargarRecuento(const AArqueo: TArqueoCaja);
    procedure RecalcularTotalesRecuento;
    procedure RecalcularDejoManana;
    function ObtenerDatosRecuento:
      TArray<TDatoRecuentoModalArqueo>;
    function ObtenerImporteRecuento(
      AFila: Integer;
      AColumna: TcxGridColumn): Currency;
    function  ObtenerConceptoRetirada: string;
    function  BuscarNombreVendedor(const ACodigo: string): string;
    function ConstruirEntradaGrabacion:
      TEntradaGrabacionModalArqueo;
    function ConfirmarGrabacion(
      const AEntrada: TEntradaGrabacionModalArqueo): Boolean;
    procedure MostrarErrorPreparacion(
      const APreparacion: TResultadoPreparacionModalArqueo);
    procedure PersistirArqueo(
      const AEntrada: TEntradaGrabacionModalArqueo;
      const APreparacion: TResultadoPreparacionModalArqueo);
    procedure ImprimirCierre(
      const AEntrada: TEntradaGrabacionModalArqueo;
      const APreparacion: TResultadoPreparacionModalArqueo);
    procedure GrabarArqueo;
  public
    destructor Destroy; override;
    class procedure Ejecutar(AOwner       : TComponent;
                             AConn        : TUniConnection;
                             const AEmpresa : string;
                             const AAlmacen : string;
                             const ACaja    : string;
                             AFechaDesde    : TDate;
                             AFechaHasta    : TDate); overload;
    class procedure Ejecutar(
      AOwner: TComponent;
      AConn: TUniConnection;
      const ADependencias: TDependenciasArqueoCaja;
      const AEmpresa: string;
      const AAlmacen: string;
      const ACaja: string;
      AFechaDesde: TDate;
      AFechaHasta: TDate); overload;
  end;

implementation

{$R *.dfm}

uses inLibPermisosIntf,
     inMtoModalArqueosHistCaja,
     inLibTiraCajaTicket,
     inMtoModalTiraCaja, inLibVerifactu, inLibMsgCaja;

procedure ForceReferenceToClass(C: TClass); begin end;

// =============================================================================
//   API pública
// =============================================================================

class procedure TfrmModalArqueo.Ejecutar(AOwner       : TComponent;
                                         AConn        : TUniConnection;
                                         const AEmpresa : string;
                                         const AAlmacen : string;
                                         const ACaja    : string;
                                         AFechaDesde    : TDate;
                                         AFechaHasta    : TDate);
begin
  ValidarDependenciaCaja(nil, 'contexto del arqueo de Caja');
end;

class procedure TfrmModalArqueo.Ejecutar(
  AOwner: TComponent;
  AConn: TUniConnection;
  const ADependencias: TDependenciasArqueoCaja;
  const AEmpresa: string;
  const AAlmacen: string;
  const ACaja: string;
  AFechaDesde: TDate;
  AFechaHasta: TDate);
var
  frm: TfrmModalArqueo;
begin
  ADependencias.Validar;
  frm := TfrmModalArqueo.Create(AOwner);
  try
    frm.FConn    := AConn;
    frm.FRepositorioPersistencia := ADependencias.Modal;
    frm.FPersistenciaArqueo := ADependencias.Persistencia;
    frm.FRepositorioArqueoCaja := ADependencias.Arqueo;
    frm.FRepositorioArqueoTicket := ADependencias.Ticket;
    frm.FRepositorioTiraCaja := ADependencias.Tira;
    frm.FRepositorioInformes := ADependencias.Informes;
    frm.ComponerDependencias;
    frm.FEmpresa := AEmpresa;
    frm.FAlmacen := AAlmacen;
    frm.FCaja    := ACaja;
    frm.FArqueoTarjetasPermitido :=
      frm.ParametrosCaja.GetBool('vgerArqueoTarjetas', False);
    // Defaults: desde = 00:00:00, hasta = 23:59:59 del mismo día/rango.
    frm.dteFechaDesde.EditValue := DateOf(AFechaDesde);
    frm.dteFechaHasta.EditValue :=
      DateOf(AFechaHasta) + EncodeTime(23, 59, 59, 0);
    // Permisos
    if (not Assigned(frm.Permisos)) or
       (not frm.Permisos.TienePermiso(
         PERMISO_CAJA_CAMBIAR_FECHA,
         paPermitir)) then
    begin
      frm.dteFechaDesde.Properties.ReadOnly := True;
      frm.dteFechaHasta.Properties.ReadOnly := True;
    end;
    if (not Assigned(frm.Permisos)) or
       (not frm.Permisos.TienePermiso(
         PERMISO_ARQUEO_VER_IMPORTES,
         paPermitir)) then
    begin
      // El usuario introduce el recuento sin ver los importes del sistema.
      frm.tvRecuentoSistema.Visible := False;
      frm.tvRecuentoDiferencia.Visible := False;
    end;
    if frm.FArqueoTarjetasPermitido then
    begin
      // Arqueo ciego: no mostrar propuestas de efectivo ni de tarjetas.
      frm.tvRecuentoSistema.Visible := False;
      frm.tvRecuentoDiferencia.Visible := False;
      frm.lblDesgloseEfectivo.Visible := False;
      frm.lblRecTotalSistemaLbl.Visible := False;
      frm.lblRecTotalSistema.Visible := False;
      frm.lblRecDiferenciaLbl.Visible := False;
      frm.lblRecDiferencia.Visible := False;
    end;
    frm.FPuedeVerResumen :=
      Assigned(frm.Permisos) and
      frm.Permisos.TienePermiso(
        PERMISO_ARQUEO_VER_RESUMEN,
        paPermitir);
    if not frm.FPuedeVerResumen then
    begin
      frm.tsResumenes.TabVisible := False;
      frm.tsMasDatos.TabVisible := False;
      frm.btnImprimir.Visible := False;
      frm.actImprimir.Enabled := False;
    end;
    frm.Recalcular;
    frm.ShowModal;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalArqueo.ComponerDependencias;
var
  Dependencias: TDependenciasArqueoCaja;
begin
  Dependencias.Modal := FRepositorioPersistencia;
  Dependencias.Persistencia := FPersistenciaArqueo;
  Dependencias.Arqueo := FRepositorioArqueoCaja;
  Dependencias.Ticket := FRepositorioArqueoTicket;
  Dependencias.Tira := FRepositorioTiraCaja;
  Dependencias.Informes := FRepositorioInformes;
  Dependencias.Validar;
  FreeAndNil(FOperacionArqueo);
  FOperacionArqueo := TOperacionModalArqueo.Create(
    FRepositorioPersistencia,
    FPersistenciaArqueo);
end;

destructor TfrmModalArqueo.Destroy;
begin
  FreeAndNil(FOperacionArqueo);
  inherited;
end;

// =============================================================================
//   Eventos
// =============================================================================

procedure TfrmModalArqueo.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  ConfigurarResumenes;
end;

procedure TfrmModalArqueo.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  Action := caHide;
end;

function TfrmModalArqueo.FechaEditada(AEdit: TcxDateEdit): TDateTime;
var
  vFecha: Variant;
begin
  vFecha := AEdit.EditValue;
  if VarIsNull(vFecha) or VarIsEmpty(vFecha) then
    Result := AEdit.Date
  else
    Result := VarToDateTime(vFecha);
end;

function TfrmModalArqueo.FechaDesdeSeleccionada: TDateTime;
begin
  Result := FechaEditada(dteFechaDesde);
end;

function TfrmModalArqueo.FechaHastaSeleccionada: TDateTime;
begin
  Result := FechaEditada(dteFechaHasta);
end;

procedure TfrmModalArqueo.btnAtrasClick(Sender: TObject);
begin
  inherited;
  Close;
end;

procedure TfrmModalArqueo.btnRecalcularClick(Sender: TObject);
begin
  inherited;
  Recalcular;
end;

procedure TfrmModalArqueo.btnImprimirClick(Sender: TObject);
begin
  inherited;
  actImprimirExecute(Sender);
end;

procedure TfrmModalArqueo.actImprimirExecute(Sender: TObject);
begin
  inherited;
  if not FPuedeVerResumen then
  begin
    RegistroLog.RegistrarAviso(
      'Intento de imprimir el resumen de arqueo sin permiso');
    MessageDlg(
      SErrorPermisoResumenArqueoCaja,
      mtWarning,
      [mbOK],
      0);
  end
  else if (FConn <> nil) and FConn.Connected then
  begin
    Screen.Cursor := crHourGlass;
    try
      TArqueoTicket.Imprimir(
        PreviewTicket,
        FRepositorioArqueoCaja,
        FRepositorioArqueoTicket,
        ParametrosCaja,
        FEmpresa,
        FAlmacen,
        FCaja,
        FechaDesdeSeleccionada,
        FechaHastaSeleccionada,
        ParametrosCaja.ImpresoraCaja);
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmModalArqueo.btnHistoricoClick(Sender: TObject);
begin
  inherited;
  actHistoricoExecute(Sender);
end;

procedure TfrmModalArqueo.actHistoricoExecute(Sender: TObject);
var
  Dependencias: TDependenciasArqueosHistoricosCaja;
begin
  inherited;
  // Pantalla de histórico de arqueos de esta caja: reemite duplicados del
  // ticket o del cierre ya grabados, sin recalcular.
  if (FConn <> nil) and FConn.Connected then
  begin
    Dependencias.Informes := FRepositorioInformes;
    Dependencias.Arqueo := FRepositorioArqueoCaja;
    Dependencias.Ticket := FRepositorioArqueoTicket;
    TfrmModalArqueosHistCaja.Ejecutar(
      Self,
      FConn,
      Dependencias,
      FEmpresa,
      FAlmacen,
      FCaja);
  end;
end;

procedure TfrmModalArqueo.btnTiraCajaClick(Sender: TObject);
begin
  inherited;
  actTiraCajaExecute(Sender);
end;

procedure TfrmModalArqueo.actTiraCajaExecute(Sender: TObject);
var
  Series, SeleccionSeries: TArray<string>;
  bQR, bVerifactu, bCronologico, bExcel: Boolean;
  bIncluirTraspasos: Boolean;
  bIncluirIngresos: Boolean;
  bIncluirGastos: Boolean;
  bIncluirCredito: Boolean;
  bVerCoste: Boolean;
  bContinuar: Boolean;
begin
  inherited;
  bVerCoste := False;
  bContinuar := (FConn <> nil) and FConn.Connected;
  if bContinuar then
  begin
    Series := TTiraCajaTicket.ObtenerSeries(
      FRepositorioTiraCaja, FEmpresa, FAlmacen, FCaja,
      FechaDesdeSeleccionada, FechaHastaSeleccionada);
    if Length(Series) = 0 then
    begin
      Application.MessageBox(
        PChar(SInfoOperacionesFacturadasArqueoCajaNoEncontradas),
        PChar(STituloTiraCaja), MB_OK or MB_ICONINFORMATION);
      bContinuar := False;
    end;
  end;
  if bContinuar then
  begin
    bVerifactu := VerifactuActivo(ParametrosApp);
    bQR := False;
    bVerCoste := Assigned(Permisos) and
      Permisos.TienePermiso(PERMISO_CAJA_VER_COSTE, paDenegar);
    bContinuar := TfrmModalTiraCaja.Ejecutar(
      Self, FCaja, Series, bVerifactu,
      SeleccionSeries, bQR, bCronologico, bExcel,
      bIncluirTraspasos, bIncluirIngresos,
      bIncluirGastos, bIncluirCredito);
  end;
  if bContinuar then
  begin
    Screen.Cursor := crHourGlass;
    try
      if bExcel then
        TTiraCajaTicket.ExportarExcel(
          Self, ProveedorPreviewExcel, FRepositorioTiraCaja,
          FEmpresa, FAlmacen, FCaja,
          FechaDesdeSeleccionada, FechaHastaSeleccionada,
          SeleccionSeries, bCronologico, bIncluirTraspasos,
          bIncluirIngresos, bIncluirGastos, bIncluirCredito,
          bVerCoste)
      else
        TTiraCajaTicket.Imprimir(
          ParametrosApp, PreviewTicket, FRepositorioTiraCaja,
          FEmpresa, FAlmacen, FCaja,
          FechaDesdeSeleccionada, FechaHastaSeleccionada,
          SeleccionSeries, bQR, ParametrosCaja.ImpresoraCaja,
          bCronologico, bIncluirTraspasos, bIncluirIngresos,
          bIncluirGastos, bIncluirCredito, bVerCoste);
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmModalArqueo.actEscapeExecute(Sender: TObject);
begin
  inherited;
  Close;
end;

procedure TfrmModalArqueo.actRecalcularExecute(Sender: TObject);
begin
  inherited;
  Recalcular;
end;

procedure TfrmModalArqueo.dteFechaDesdePropertiesChange(Sender: TObject);
begin
  inherited;
  // Fuerza que "hasta" no quede antes que "desde"
  if FechaHastaSeleccionada < FechaDesdeSeleccionada then
    dteFechaHasta.EditValue := FechaDesdeSeleccionada;
end;

procedure TfrmModalArqueo.dteFechaHastaPropertiesChange(Sender: TObject);
begin
  inherited;
  if FechaHastaSeleccionada < FechaDesdeSeleccionada then
    dteFechaHasta.EditValue := FechaDesdeSeleccionada;
end;

// =============================================================================
//   Lógica interna
// =============================================================================

procedure TfrmModalArqueo.Recalcular;
begin
  Screen.Cursor := crHourGlass;
  try
    FArqueoActual := FRepositorioArqueoCaja.Calcular(
      FEmpresa,
      FAlmacen,
      FCaja,
      FechaDesdeSeleccionada,
      FechaHastaSeleccionada);
    RellenarPantalla(FArqueoActual);
    CargarRecuento(FArqueoActual);
    RefrescarResumenes;
  finally
    Screen.Cursor := crDefault;
  end;
end;

// =============================================================================
//   Resúmenes (pestaña 2)
// =============================================================================

procedure TfrmModalArqueo.ConfigurarResumenes;
begin
  // Familia: dataset en memoria alimentado por el repositorio compartido
  // con el ticket. La profundidad se envía mediante :pNIVELES.
  FResumenFamilias := TClientDataSet.Create(Self);
  FResumenFamilias.FieldDefs.Add(
    'FAMILIA',
    ftString,
    255);
  FResumenFamilias.FieldDefs.Add(
    'UDS',
    ftInteger);
  FResumenFamilias.FieldDefs.Add(
    'NETO',
    ftCurrency);
  FResumenFamilias.CreateDataSet;
  dsResFam.DataSet := FResumenFamilias;

end;

procedure TfrmModalArqueo.CargarResumenFamilias;
var
  aLineas: TArray<TResumenSeccionArqueo>;
  iLinea: Integer;
begin
  aLineas := FRepositorioArqueoTicket.ListarResumenSeccion(
      FArqueoActual,
      ParametrosCaja.NivelesFamiliaArqueo);
  FResumenFamilias.DisableControls;
  try
    FResumenFamilias.EmptyDataSet;
    iLinea := 0;
    while iLinea < Length(aLineas) do
    begin
      FResumenFamilias.AppendRecord(
        [aLineas[iLinea].Familia,
         aLineas[iLinea].Unidades,
         aLineas[iLinea].Neto]);
      Inc(iLinea);
    end;
    if not FResumenFamilias.IsEmpty then
      FResumenFamilias.First;
  finally
    FResumenFamilias.EnableControls;
  end;
end;

function TfrmModalArqueo.ConstruirSolicitudResumen:
  TSolicitudResumenModalArqueo;
begin
  Result.Empresa := FEmpresa;
  Result.Almacen := FAlmacen;
  Result.Caja := FCaja;
  Result.FechaDesde := FechaDesdeSeleccionada;
  Result.FechaHasta := FechaHastaSeleccionada;
end;

procedure TfrmModalArqueo.RefrescarResumenes;
var
  Solicitud: TSolicitudResumenModalArqueo;
begin
  if FPuedeVerResumen and
     (FConn <> nil) and
     FConn.Connected then
  begin
    Solicitud := ConstruirSolicitudResumen;
    dsResEmpleado.DataSet := nil;
    dsResFP.DataSet := nil;
    dsResProp.DataSet := nil;
    dsResIVA.DataSet := nil;
    FResumenEmpleados :=
      FRepositorioPersistencia.ConsultarResumenEmpleados(Solicitud);
    FResumenFormasPago :=
      FRepositorioPersistencia.ConsultarResumenFormasPago(Solicitud);
    FResumenPropiedades :=
      FRepositorioPersistencia.ConsultarResumenPropiedades(Solicitud);
    FResumenIva :=
      FRepositorioPersistencia.ConsultarResumenIva(Solicitud);
    dsResEmpleado.DataSet := FResumenEmpleados.DataSet;
    dsResFP.DataSet := FResumenFormasPago.DataSet;
    dsResProp.DataSet := FResumenPropiedades.DataSet;
    dsResIVA.DataSet := FResumenIva.DataSet;
    CargarResumenFamilias;
  end;
end;

procedure TfrmModalArqueo.RellenarPantalla(const AArqueo: TArqueoCaja);
begin
  lblVentas.Caption          := IntToStr(AArqueo.CantidadVentas);

  lblLinBruto.Caption        := FormatImporte(AArqueo.BrutoLineas);
  lblLinDescuento.Caption    := FormatImporte(AArqueo.DescuentosLineas);
  lblLinNeto.Caption         := FormatImporte(AArqueo.NetoLineas);

  lblOpeVentasNorm.Caption    := FormatImporte(AArqueo.VentasNormales);
  lblOpeVentasPrest.Caption   := FormatImporte(AArqueo.VentasPrestamos);
  lblOpeDevol.Caption         := FormatImporte(AArqueo.Devoluciones);
  lblOpeTotalVentas.Caption   := FormatImporte(AArqueo.TotalVentas);

  lblCobValesRec.Caption     := FormatImporte(AArqueo.ValesRecogidos);
  lblCobValesEmi.Caption     := FormatImporte(AArqueo.ValesEmitidos);
  lblCobClientes.Caption     := FormatImporte(AArqueo.CobrosClientes);
  lblCobPendiente.Caption    := FormatImporte(AArqueo.PendienteCobro);
  lblCobIngresos.Caption     := FormatImporte(AArqueo.IngresosCaja);

  lblEftIngresos.Caption     := FormatImporte(AArqueo.EfectivoIngresos);
  lblEftEntradas.Caption     := FormatImporte(AArqueo.EfectivoEntradas);
  lblEftSalidas.Caption      := FormatImporte(AArqueo.EfectivoSalidas);
  lblEftAnterior.Caption     := FormatImporte(AArqueo.EfectivoAnterior);
  lblEftCaja.Caption         := FormatImporte(AArqueo.EfectivoCaja);
  lblTarjetas.Caption        := FormatImporte(AArqueo.OtrosIngresos);
  lblSaldo.Caption           := FormatImporte(AArqueo.SaldoRecontar);
end;

function TfrmModalArqueo.FormatImporte(AValor: Currency): string;
begin
  if AValor = 0 then
    Result := ''
  else
    Result := FormatFloat(',0.00', AValor);
end;

// =============================================================================
//   Recuento: formas de pago, retirada, dejo mañana
// =============================================================================

procedure TfrmModalArqueo.CargarRecuento(const AArqueo: TArqueoCaja);
var
  i, iRow: Integer;
begin
  { Resto día anterior }
  lblAnteriorImporte.Caption :=
    Format(SCaptionImporteEur,
           [FormatFloat(',0.00', AArqueo.EfectivoAnterior)]);
  { Desglose del efectivo }
  lblDesgloseEfectivo.Caption :=
    Format(
      SCaptionDesgloseEfectivo,
      [FormatFloat(',0.00', AArqueo.EfectivoIngresos),
       FormatFloat(',0.00', AArqueo.EfectivoEntradas),
       FormatFloat(',0.00', AArqueo.EfectivoSalidas),
       FormatFloat(',0.00', AArqueo.EfectivoAnterior)]);
  { Grid de recuento: efectivo agrupado y formas de pago sin cajón }
  RegistroLog.RegistrarInformacion(Format(
    'CargarRecuento: PagosPorForma=%d filas',
    [Length(AArqueo.PagosPorForma)]));
  tvRecuento.BeginUpdate;
  try
    tvRecuento.DataController.RecordCount := 1;
    tvRecuento.DataController.Values[
      0, tvRecuentoFP.Index] := 'EFE';
    tvRecuento.DataController.Values[
      0, tvRecuentoDesc.Index] := 'Efectivo';
    tvRecuento.DataController.Values[
      0, tvRecuentoSistema.Index] := Double(AArqueo.EfectivoCaja);
    tvRecuento.DataController.Values[
      0, tvRecuentoImporte.Index] := Double(0);
    tvRecuento.DataController.Values[
      0, tvRecuentoDiferencia.Index] :=
      -Double(AArqueo.EfectivoCaja);
    iRow := 1;
    for i := 0 to High(AArqueo.PagosPorForma) do
    begin
      RegistroLog.RegistrarInformacion(Format(
        '  FP[%d]: %s (%s) EsEfectivo=%s Importe=%.2f',
        [i, AArqueo.PagosPorForma[i].Codigo,
         AArqueo.PagosPorForma[i].Descripcion,
         BoolToStr(AArqueo.PagosPorForma[i].EsEfectivo, True),
         Double(AArqueo.PagosPorForma[i].Importe)]));
      if not AArqueo.PagosPorForma[i].EsEfectivo then
      begin
        tvRecuento.DataController.RecordCount := iRow + 1;
        tvRecuento.DataController.Values[
          iRow, tvRecuentoFP.Index] :=
          AArqueo.PagosPorForma[i].Codigo;
        tvRecuento.DataController.Values[
          iRow, tvRecuentoDesc.Index] :=
          AArqueo.PagosPorForma[i].Descripcion;
        tvRecuento.DataController.Values[
          iRow, tvRecuentoSistema.Index] :=
          Double(AArqueo.PagosPorForma[i].Importe);
        if FArqueoTarjetasPermitido then
        begin
          tvRecuento.DataController.Values[
            iRow, tvRecuentoImporte.Index] := Double(0);
          tvRecuento.DataController.Values[
            iRow, tvRecuentoDiferencia.Index] :=
            -Double(AArqueo.PagosPorForma[i].Importe);
        end
        else
        begin
          tvRecuento.DataController.Values[
            iRow, tvRecuentoImporte.Index] :=
            Double(AArqueo.PagosPorForma[i].Importe);
          tvRecuento.DataController.Values[
            iRow, tvRecuentoDiferencia.Index] := Double(0);
        end;
        Inc(iRow);
      end;
    end;
  finally
    tvRecuento.EndUpdate;
  end;
  RecalcularTotalesRecuento;
end;

function TfrmModalArqueo.ObtenerImporteRecuento(
  AFila: Integer;
  AColumna: TcxGridColumn): Currency;
var
  vValor: Variant;
begin
  Result := 0;
  vValor := tvRecuento.DataController.Values[AFila, AColumna.Index];
  if not VarIsNull(vValor) then
    Result := Currency(Double(vValor));
end;

function TfrmModalArqueo.ObtenerDatosRecuento:
  TArray<TDatoRecuentoModalArqueo>;
var
  i: Integer;
begin
  SetLength(Result, tvRecuento.DataController.RecordCount);
  for i := 0 to High(Result) do
  begin
    Result[i].CodigoFormaPago := VarToStr(
      tvRecuento.DataController.Values[i, tvRecuentoFP.Index]);
    Result[i].Descripcion := VarToStr(
      tvRecuento.DataController.Values[i, tvRecuentoDesc.Index]);
    Result[i].ImporteSistema := ObtenerImporteRecuento(
      i,
      tvRecuentoSistema);
    Result[i].ImporteRecuento := ObtenerImporteRecuento(
      i,
      tvRecuentoImporte);
  end;
end;

procedure TfrmModalArqueo.RecalcularTotalesRecuento;
var
  Plan: TPlanGrabacionModalArqueo;
begin
  Plan := CalcularPlanGrabacionModalArqueo(
    ObtenerDatosRecuento,
    Currency(txtRetiradaImporte.Value));
  lblRecTotalSistema.Caption :=
    FormatFloat(',0.00', Plan.TotalSistema);
  lblRecTotalRecuento.Caption :=
    FormatFloat(',0.00', Plan.TotalRecuento);
  lblRecDiferencia.Caption :=
    FormatFloat(',0.00', Plan.DiferenciaTotal);
  if Plan.DiferenciaTotal < 0 then
    lblRecDiferencia.Style.TextColor := clRed
  else if Plan.DiferenciaTotal > 0 then
    lblRecDiferencia.Style.TextColor := clGreen
  else
    lblRecDiferencia.Style.TextColor := clWindowText;
  RecalcularDejoManana;
end;

procedure TfrmModalArqueo.RecalcularDejoManana;
var
  Plan: TPlanGrabacionModalArqueo;
begin
  Plan := CalcularPlanGrabacionModalArqueo(
    ObtenerDatosRecuento,
    Currency(txtRetiradaImporte.Value));
  lblDejoImporte.Caption :=
    Format(
      SCaptionImporteEur,
      [FormatFloat(',0.00', Plan.EfectivoDejado)]);
end;

procedure TfrmModalArqueo.tvRecuentoImportePropertiesEditValueChanged(
  Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem);
var
  iRow: Integer;
  dSistema, dRecuento, dDif: Double;
  v: Variant;
  oEdit: TcxCustomEdit;
begin
  if AItem = tvRecuentoImporte then
  begin
    iRow := tvRecuento.DataController.FocusedRecordIndex;
    if iRow >= 0 then
    begin
      dSistema := 0;
      v := tvRecuento.DataController.Values[
        iRow, tvRecuentoSistema.Index];
      if not VarIsNull(v) then
        dSistema := Double(v);
      dRecuento := 0;
      oEdit := tvRecuento.Controller.EditingController.Edit;
      if Assigned(oEdit) then
      begin
        v := oEdit.EditValue;
        if not VarIsNull(v) then
          dRecuento := Double(v);
      end;
      dDif := dRecuento - dSistema;
      tvRecuento.DataController.Values[
        iRow, tvRecuentoDiferencia.Index] := dDif;
      tvRecuento.DataController.Values[
        iRow, tvRecuentoImporte.Index] := dRecuento;
      RecalcularTotalesRecuento;
    end;
  end;
end;

procedure TfrmModalArqueo.tvRecuentoKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
var
  iRow, iDest: Integer;
begin
  if (Key = VK_RETURN) or
     ((Key = VK_END) and (ssCtrl in Shift)) or
     ((Key = VK_HOME) and (ssCtrl in Shift)) then
  begin
    if tvRecuento.Controller.EditingController.IsEditing then
      tvRecuento.Controller.EditingController.HideEdit(True);
    iRow := tvRecuento.DataController.FocusedRecordIndex;
    if Key = VK_RETURN then
      iDest := iRow + 1
    else if Key = VK_END then
      iDest := tvRecuento.DataController.RecordCount - 1
    else
      iDest := 0;
    if iDest < 0 then
      iDest := 0;
    if iDest > tvRecuento.DataController.RecordCount - 1 then
      iDest := tvRecuento.DataController.RecordCount - 1;
    if iDest <> iRow then
    begin
      tvRecuento.DataController.FocusedRecordIndex := iDest;
      tvRecuento.Controller.FocusedColumn := tvRecuentoImporte;
      tvRecuento.Controller.EditingController.ShowEdit(
        tvRecuentoImporte);
    end;
    Key := 0;
  end;
end;

procedure TfrmModalArqueo.txtRetiradaImportePropertiesChange(
  Sender: TObject);
begin
  RecalcularDejoManana;
end;

function TfrmModalArqueo.ObtenerConceptoRetirada: string;
begin
  case rgRetiradaTipo.ItemIndex of
    0: Result := 'Retirada banco';
    1: Result := 'Retirada encargado';
    2: Result := 'Caja fuerte';
    3: Result := 'Pago proveedor';
    4: Result := 'Gastos limpieza';
  else
    Result := 'Retirada cierre';
  end;
end;

// Nombre del empleado de caja activo en fza_empleados ('' si no existe).
// El vendedor que cierra el arqueo debe estar dado de alta como empleado.
function TfrmModalArqueo.BuscarNombreVendedor(const ACodigo: string): string;
begin
  Result := '';
  if (FConn <> nil) and
     FConn.Connected and
     Assigned(FRepositorioPersistencia) then
  begin
    Result := FRepositorioPersistencia.BuscarNombreVendedor(ACodigo);
  end;
end;

procedure TfrmModalArqueo.txtVendedorCodigoExit(Sender: TObject);
begin
  // Feedback inmediato: nombre del empleado (vacío si el código no vale)
  lblVendedorNombre.Caption :=
    BuscarNombreVendedor(txtVendedorCodigo.Text);
end;

procedure TfrmModalArqueo.btnGrabarArqueoClick(Sender: TObject);
begin
  inherited;
  actGrabarExecute(Sender);
end;

procedure TfrmModalArqueo.actGrabarExecute(Sender: TObject);
begin
  inherited;
  GrabarArqueo;
end;

procedure TfrmModalArqueo.actDesplegarDesdeExecute(Sender: TObject);
begin
  dteFechaDesde.DroppedDown := True;
end;

procedure TfrmModalArqueo.actDesplegarHastaExecute(Sender: TObject);
begin
  dteFechaHasta.DroppedDown := True;
end;

function TfrmModalArqueo.ConstruirEntradaGrabacion:
  TEntradaGrabacionModalArqueo;
begin
  Result := Default(TEntradaGrabacionModalArqueo);
  Result.Arqueo := FArqueoActual;
  Result.Solicitud := ConstruirSolicitudResumen;
  Result.Recuento := ObtenerDatosRecuento;
  Result.ImporteRetirada := Currency(txtRetiradaImporte.Value);
  Result.ConceptoRetirada := ObtenerConceptoRetirada;
  Result.DesgloseBilletes := '';
  Result.Observaciones := Trim(txtObservaciones.Text);
  Result.CodigoVendedor := txtVendedorCodigo.Text;
  Result.Usuario := IdentidadSesion.Usuario;
end;

function TfrmModalArqueo.ConfirmarGrabacion(
  const AEntrada: TEntradaGrabacionModalArqueo): Boolean;
begin
  Result := Application.MessageBox(
    PChar(Format(
      SPreguntaGrabarArqueoCaja,
      [FormatDateTime(
         'dd/mm/yyyy hh:nn:ss',
         AEntrada.Solicitud.FechaDesde),
       FormatDateTime(
         'dd/mm/yyyy hh:nn:ss',
         AEntrada.Solicitud.FechaHasta)])),
    PChar(STituloConfirmarArqueoCaja),
    MB_YESNO or MB_ICONQUESTION) = IDYES;
end;

procedure TfrmModalArqueo.MostrarErrorPreparacion(
  const APreparacion: TResultadoPreparacionModalArqueo);
begin
  case APreparacion.Estado of
    epmaVendedorNoIndicado:
      Application.MessageBox(
        PChar(SErrorVendedorArqueoCajaNoIndicado),
        PChar(STituloVendedorArqueoCajaObligatorio),
        MB_OK or MB_ICONWARNING);
    epmaVendedorNoValido:
      Application.MessageBox(
        PChar(SErrorVendedorArqueoCajaNoValido),
        PChar(STituloVendedorArqueoCajaNoValido),
        MB_OK or MB_ICONWARNING);
    epmaArqueoDuplicado:
      Application.MessageBox(
        PChar(SErrorArqueoCajaDuplicado),
        PChar(STituloArqueoCajaDuplicado),
        MB_OK or MB_ICONWARNING);
    epmaRecuentoNoDisponible:
      Application.MessageBox(
        PChar(SErrorRecuentoArqueoCajaNoDisponible),
        PChar(STituloAvisoCaja),
        MB_OK or MB_ICONWARNING);
  end;
  if APreparacion.Estado in [
       epmaVendedorNoIndicado,
       epmaVendedorNoValido] then
  begin
    pcArqueo.ActivePage := tsRecuento;
    txtVendedorCodigo.SetFocus;
  end;
end;

procedure TfrmModalArqueo.PersistirArqueo(
  const AEntrada: TEntradaGrabacionModalArqueo;
  const APreparacion: TResultadoPreparacionModalArqueo);
begin
  Screen.Cursor := crHourGlass;
  try
    FOperacionArqueo.Grabar(AEntrada, APreparacion);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmModalArqueo.ImprimirCierre(
  const AEntrada: TEntradaGrabacionModalArqueo;
  const APreparacion: TResultadoPreparacionModalArqueo);
begin
  TArqueoTicket.ImprimirCierre(
    PreviewTicket,
    FRepositorioArqueoTicket,
    ContextoSesion,
    AEntrada.Arqueo,
    APreparacion.Plan.Lineas,
    APreparacion.Plan.TotalSistema,
    APreparacion.Plan.TotalRecuento,
    APreparacion.Plan.DiferenciaTotal,
    AEntrada.ImporteRetirada,
    AEntrada.ConceptoRetirada,
    APreparacion.Plan.EfectivoDejado,
    AEntrada.DesgloseBilletes,
    AEntrada.Observaciones,
    APreparacion.CodigoVendedor + ' - ' +
      APreparacion.NombreVendedor,
    ParametrosCaja.ImpresoraCaja);
end;

procedure TfrmModalArqueo.GrabarArqueo;
var
  Entrada: TEntradaGrabacionModalArqueo;
  Preparacion: TResultadoPreparacionModalArqueo;
begin
  if (FConn <> nil) and FConn.Connected and
     Assigned(FOperacionArqueo) then
  begin
    Entrada := ConstruirEntradaGrabacion;
    Preparacion := FOperacionArqueo.Preparar(Entrada);
    if Preparacion.NombreVendedor <> '' then
      lblVendedorNombre.Caption := Preparacion.NombreVendedor;
    if not Preparacion.PuedeGrabar then
      MostrarErrorPreparacion(Preparacion)
    else if ConfirmarGrabacion(Entrada) then
    begin
      PersistirArqueo(Entrada, Preparacion);
      ImprimirCierre(Entrada, Preparacion);
    end;
  end;
end;

initialization
  ForceReferenceToClass(TfrmModalArqueo);
end.
