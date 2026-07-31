{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoConsultaOpe                                              }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consulta de operaciones de venta.                                         }
{    Vista maestro-detalle de operaciones con filtros de fecha.                }
{******************************************************************************}
unit inMtoConsultaOpe;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls, Data.DB,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit, cxNavigator,
  cxDBData, cxGridLevel, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, cxCalendar, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, cxButtonEdit, cxContainer, cxLabel,
  cxSplitter, cxButtons, Vcl.Imaging.PngImage,
  inMtoFrmBase, inLibVentasCalendario, inLibLayoutForm,
  UniDataConsultaOpe, UniDataCaja, dxCore, cxDateUtils, dxCoreGraphics,
  cxCurrencyEdit, cxClasses, cxGridCustomView, JvComponentBase, JvEnterTab,
  cxLocalization, Vcl.Menus, inLibCajaTipos, inLibCajaVentanasIntf;

type
  TfrmConsultaOpe = class(TfrmBase, IConsultaOperacionesCaja)
    pnlFiltros:       TPanel;
    lblFecha:         TcxLabel;
    lblBuscar:        TcxLabel;
    edtBuscar:        TcxButtonEdit;
    pnlMaestro:       TPanel;
    cxGridMaestro:    TcxGrid;
    cxViewMaestro:    TcxGridDBTableView;
    cxLevelMaestro:   TcxGridLevel;
    splPrincipal:         TSplitter;
    pcHijos:          TcxPageControl;
    tsOperacion:      TcxTabSheet;
    tsPagos:          TcxTabSheet;
    tsVales:          TcxTabSheet;
    tsMovimientos:    TcxTabSheet;
    tsCliente:        TcxTabSheet;
    tsDepositos:      TcxTabSheet;
    tsFactura:        TcxTabSheet;
    dtpFecha: TcxDateEdit;
    cxGridOpe:        TcxGrid;
    cxViewOpe:        TcxGridDBTableView;
    cxLevelOpe:       TcxGridLevel;
    cxGridPagos:      TcxGrid;
    cxViewPagos:      TcxGridDBTableView;
    cxLevelPagos:     TcxGridLevel;
    cxGridVales:      TcxGrid;
    cxViewVales:      TcxGridDBTableView;
    cxLevelVales:     TcxGridLevel;
    cxGridMov:        TcxGrid;
    cxViewMov:        TcxGridDBTableView;
    cxLevelMov:       TcxGridLevel;
    cxGridCli:        TcxGrid;
    cxViewCli:        TcxGridDBTableView;
    cxLevelCli:       TcxGridLevel;
    cxGridDep:        TcxGrid;
    cxViewDep:        TcxGridDBTableView;
    cxLevelDep:       TcxGridLevel;
    pnlFacCabecera:   TPanel;
    cxGridFacCab:     TcxGrid;
    cxViewFacCab:     TcxGridDBTableView;
    cxLevelFacCab:    TcxGridLevel;
    cxGridFacLin:     TcxGrid;
    cxViewFacLin:     TcxGridDBTableView;
    cxLevelFacLin:    TcxGridLevel;
    splFotoConsulta:  TcxSplitter;
    pnlFotoConsulta:  TPanel;
    imgFotoConsulta:  TImage;
    pnlPie:           TPanel;
    btnReimprimir:    TButton;
    btnReimprimirOtros: TcxButton;
    btnCerrar:        TButton;
    tmrBusqueda:      TTimer;
    btnDevolverAbonar: TButton;
    btnAnularVerifactu: TButton;
    btnFacturarTicket: TButton;
    btnRectificar: TButton;
    btnEnviarEmail: TcxButton;
    colMovColor: TcxGridDBColumn;
    colMovTalla: TcxGridDBColumn;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnRefrescarClick(Sender: TObject);
    procedure edtBuscarPropertiesChange(Sender: TObject);
    procedure tmrBusquedaTimer(Sender: TObject);
    procedure btnReimprimirClick(Sender: TObject);
    procedure btnReimprimirOtrosClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure dtpFechaPropertiesGetDayState(Sender: TObject; ADate: TDateTime;
      AState: TCustomDrawState; AFont: TFont; var ABackgroundColor: TColor);
    procedure dtpFechaPropertiesEditValueChanged(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAnularVerifactuClick(Sender: TObject);
    procedure btnFacturarTicketClick(Sender: TObject);
    procedure btnRectificarClick(Sender: TObject);
    procedure btnEnviarEmailClick(Sender: TObject);
    procedure cxViewMovCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
  private
    FdmConsulta: TdmConsultaOpe;
    FEmpresa:    string;
    FAlmacen:    string;
    FCaja:       string;
    // Factura de la operación seleccionada (pestaña Factura)
    function FacturaSeleccionada(out ASerie, ANumero: string): Boolean;
    function SeleccionarTipoRectificativa(
      const ASerie, ANumero: string;
      out ATipoRectificativa: TTipoRectificativaCaja): Boolean;
    function SeleccionarMovimientosRectificativa(
      const ASerie, ANumero: string;
      out ATratamiento:
        TTratamientoMovimientosRectificativa): Boolean;
    procedure RecargarMaestro;
    procedure GuardarLayout;
    procedure RestaurarLayout;
    procedure AjustarVisibilidadPestanas;
    procedure AplicarAnchosPestanasHijas;
    procedure AjustarAPantalla;
    procedure ReimprimirOperacion(const ANombreImpresora: string);
    procedure OnMaestroDataChange(Sender: TObject; Field: TField);
    procedure OnFacturaLinDataChange(Sender: TObject; Field: TField);
    procedure RefrescarFotoConsulta;
    // Lee el ARTICULO / SKU de la linea activa en cxViewFacLin para
    // alimentar la pantalla flotante de fotos (Ctrl + F).
    procedure ResolverArtSkuDeFacLin(out ACodArt, ACodSku: string);
    // Ctrl+A / Ctrl+M (pestana Movimientos) y Ctrl+Shift+F (pestana
    // Factura): saltan a la ficha del articulo, del movimiento de almacen o
    // de la factura del registro activo, abriendola como pestana en el
    // formulario principal via ShowMto.
    procedure AbrirArticuloDeMovimiento;
    procedure AbrirMovimientoActivo;
    procedure AbrirFacturaActiva;
  public
    function FormularioConsultaCaja: TCustomForm;
    procedure PrepararValores(const AEmpresa,
                                    AAlmacen,
                                    ACaja: string;
                                    AFecha: TDateTime);
    procedure RefrescarOperaciones;
  private
    FLayout: TLayoutLoader;
    FVentasCal: TVentasCalendarioCache;
    procedure dtpFechaGetDayState(Sender: TObject; ADate: TDateTime;
      AState: TCustomDrawState; AFont: TFont; var ABackgroundColor: TColor);
  end;

implementation

{$R *.dfm}

uses inLibGenerarTicketBD, inLibGenerarTicketCaja,
     inLibLog, inLibFotos, inMtoFotoArticulo,
     inLibTraspasoTicket, inLibShowMto, Uni,
     inLibVerifactu, inMtoModalFacturarTicket,
     inLibEmisionFiscalIntf, inLibEmisionFiscal,
     UniDataVerifactuColaRepositorio,
  inLibCorreoTickets, inLibAtributosPaleta, inLibMsgComun,
  inLibMsgCaja, inLibMsgConfiguracion, inLibMsgFacturas;

// -----------------------------------------------------------------------------
procedure TfrmConsultaOpe.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  Action := CaFree;
end;

procedure TfrmConsultaOpe.FormCreate(Sender: TObject);
begin
  inherited;
  FdmConsulta := TdmConsultaOpe.Create(Self, ConexionPrincipal);
  FLayout := TLayoutLoader.Create(
    Self.Name, ContextoSesion, PerfilesLectura);
  FVentasCal := TVentasCalendarioCache.Create(ConexionPrincipal);
  dtpFecha.Properties.OnGetDayState := dtpFechaGetDayState;
  cxViewMaestro.DataController.DataSource := FdmConsulta.dsMaestro;
  cxViewOpe.DataController.DataSource     := FdmConsulta.dsOperacion;
  cxViewPagos.DataController.DataSource   := FdmConsulta.dsPagos;
  cxViewVales.DataController.DataSource   := FdmConsulta.dsVales;
  cxViewMov.DataController.DataSource     := FdmConsulta.dsMovimientos;
  cxViewCli.DataController.DataSource     := FdmConsulta.dsCliente;
  cxViewDep.DataController.DataSource     := FdmConsulta.dsDepositos;
  cxViewFacCab.DataController.DataSource  := FdmConsulta.dsFactura;
  cxViewFacLin.DataController.DataSource  := FdmConsulta.dsFacturaLin;
  FdmConsulta.dsMaestro.OnDataChange    := OnMaestroDataChange;
  FdmConsulta.dsFacturaLin.OnDataChange := OnFacturaLinDataChange;
  tmrBusqueda.Enabled  := False;
  tmrBusqueda.Interval := 400;
  KeyPreview := True;   // para que FormKeyDown capture F5/ESC aunque el foco
                        // este en el grid o en el edit de busqueda
end;

function TfrmConsultaOpe.FormularioConsultaCaja: TCustomForm;
begin
  Result := Self;
end;

procedure TfrmConsultaOpe.FormDestroy(Sender: TObject);
begin
  inherited;
  FreeAndNil(FLayout);
  FreeAndNil(FVentasCal);
end;

procedure TfrmConsultaOpe.dtpFechaGetDayState(Sender: TObject;
  ADate: TDateTime; AState: TCustomDrawState; AFont: TFont;
  var ABackgroundColor: TColor);
begin
  FVentasCal.AplicarEstiloDia(ADate, AFont, ABackgroundColor);
end;

procedure TfrmConsultaOpe.PrepararValores(const AEmpresa,
                                                AAlmacen,
                                                ACaja: string;
                                                AFecha: TDateTime);
begin
  FEmpresa := AEmpresa;
  FAlmacen := AAlmacen;
  FCaja    := ACaja;
  dtpFecha.Date := AFecha;
  FVentasCal.Reconfigurar(AEmpresa, AAlmacen, ACaja);
end;

procedure TfrmConsultaOpe.RefrescarOperaciones;
begin
  if Assigned(FdmConsulta) then
  begin
    FdmConsulta.InvalidarCacheMaestro;
    RecargarMaestro;
  end;
end;

procedure TfrmConsultaOpe.FormShow(Sender: TObject);
begin
  inherited;
  Log.LogInfo(Format('frmConsultaOpe.FormShow: INICIO emp="%s" alm="%s" ' +
                     'caja="%s" fecha=%s',
                     [FEmpresa, FAlmacen, FCaja, DateToStr(dtpFecha.Date)]));
  Caption := Format('Buscar operaciones — Empresa %s / Almacen %s / Caja %s',
                    [FEmpresa, FAlmacen, FCaja]);
  RecargarMaestro;
  pcHijos.ActivePage := tsMovimientos;
  RestaurarLayout;
  AjustarAPantalla;
  if edtBuscar.CanFocus then
    edtBuscar.SetFocus;
  Log.LogInfo('frmConsultaOpe.FormShow: FIN');
end;

procedure TfrmConsultaOpe.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  FormularioFoto: TfrmFotoArticulo;
  sArt, sSku: string;
begin
  // Ctrl + Shift + F -> ficha de la factura (normal o simplificada) que se
  // muestra en la pestana Factura.
  if (Key = Ord('F')) and (ssCtrl in Shift) and (ssShift in Shift) and
     not (ssAlt in Shift) then
  begin
    AbrirFacturaActiva;
    Key := 0;
    Exit;
  end;
  // Ctrl + A -> ficha del articulo del movimiento activo (pestana Movimientos).
  if (Key = Ord('A')) and (ssCtrl in Shift) and not (ssShift in Shift) and
     not (ssAlt in Shift) then
  begin
    AbrirArticuloDeMovimiento;
    Key := 0;
    Exit;
  end;
  // Ctrl + M -> ficha del movimiento de almacen activo (pestana Movimientos).
  if (Key = Ord('M')) and (ssCtrl in Shift) and not (ssShift in Shift) and
     not (ssAlt in Shift) then
  begin
    AbrirMovimientoActivo;
    Key := 0;
    Exit;
  end;
  // Ctrl + F (sin Shift) -> Foto del articulo / SKU de la linea de factura
  // activa. Toggle: si la foto ya esta visible, ocultarla.
  if (Key = Ord('F')) and (ssCtrl in Shift) and not (ssShift in Shift) and
     not (ssAlt in Shift) then
  begin
    FormularioFoto := FotoFlotanteActual;
    if (FormularioFoto <> nil) and FormularioFoto.Visible then
      FormularioFoto.Hide
    else
    begin
      ResolverArtSkuDeFacLin(sArt, sSku);
      if sArt <> '' then
      begin
        MostrarFotoFlotante(Self, sArt, sSku);
        FormularioFoto := FotoFlotanteActual;
        if FormularioFoto <> nil then
          FormularioFoto.VincularMtoPadre(FdmConsulta.dsFacturaLin,
                                          ResolverArtSkuDeFacLin);
      end;
    end;
    Key := 0;
    Exit;
  end;
  case Key of
    VK_ESCAPE: Close;
    VK_F5:     RecargarMaestro;
    VK_F12:
      if (ssAlt in Shift) and not (ssCtrl in Shift) then
        GuardarLayout
      else if (ssCtrl in Shift) and not (ssAlt in Shift) then
        ResetearLayout(Self.Name, PerfilesEscritura);
  end;
end;

procedure TfrmConsultaOpe.ResolverArtSkuDeFacLin(out ACodArt,
                                                 ACodSku: string);
begin
  ACodArt := '';
  ACodSku := '';
  if not Assigned(FdmConsulta) then Exit;
  LeerArtSkuDeDataSet(FdmConsulta.dsFacturaLin.DataSet, ACodArt, ACodSku);
end;

// Ctrl + A: abre la ficha del articulo (Mto Articulos) del movimiento
// activo en la pestana Movimientos, como pestana del formulario principal.
procedure TfrmConsultaOpe.AbrirArticuloDeMovimiento;
var
  ds  : TDataSet;
  sArt: string;
begin
  if not Assigned(FdmConsulta) then Exit;
  ds := FdmConsulta.dsMovimientos.DataSet;
  if (ds = nil) or (not ds.Active) or ds.IsEmpty then Exit;
  sArt := ds.FieldByName('CODIGO_ART_MOV').AsString;
  if sArt <> '' then
    ShowMto(Application.MainForm, 'Articulos', sArt);
end;

// Ctrl + M: abre el Mto de Movimientos de Almacen posicionado en el
// movimiento (NUMERO_MOV) activo en la pestana Movimientos.
procedure TfrmConsultaOpe.AbrirMovimientoActivo;
var
  ds     : TDataSet;
  sNumMov: string;
begin
  if not Assigned(FdmConsulta) then Exit;
  ds := FdmConsulta.dsMovimientos.DataSet;
  if (ds = nil) or (not ds.Active) or ds.IsEmpty then Exit;
  sNumMov := ds.FieldByName('NUMERO_MOV').AsString;
  if sNumMov <> '' then
    ShowMto(Application.MainForm, 'MovimientosAlmacen', sNumMov);
end;

// Ctrl + Shift + F: abre la factura SIMPLIFICADA que se muestra en la
// pestana Factura. En la consulta de operaciones de caja las facturas son
// siempre simplificadas, asi que vamos directos a 'FacturasSimplif'.
procedure TfrmConsultaOpe.AbrirFacturaActiva;
var
  ds  : TDataSet;
  sNum: string;
  sSer: string;
begin
  if not Assigned(FdmConsulta) then Exit;
  ds := FdmConsulta.dsFactura.DataSet;
  if (ds = nil) or (not ds.Active) or ds.IsEmpty then Exit;
  sNum := ds.FieldByName('NUMERO_FAC').AsString;
  sSer := ds.FieldByName('SERIE_FAC').AsString;
  if (sNum <> '') and (sSer <> '') then
    ShowMto(Application.MainForm, 'FacturasSimplif', sNum + ',' + sSer);
end;

function TfrmConsultaOpe.FacturaSeleccionada(out ASerie,
                                             ANumero: string): Boolean;
var
  ds: TDataSet;
begin
  ASerie  := '';
  ANumero := '';
  if Assigned(FdmConsulta) then
  begin
    ds := FdmConsulta.dsFactura.DataSet;
    if (ds <> nil) and ds.Active and (not ds.IsEmpty) then
    begin
      ASerie  := ds.FieldByName('SERIE_FAC').AsString;
      ANumero := ds.FieldByName('NUMERO_FAC').AsString;
    end;
  end;
  Result := (Trim(ASerie) <> '') and (Trim(ANumero) <> '');
end;

procedure TfrmConsultaOpe.btnAnularVerifactuClick(Sender: TObject);
var
  Qry:                  TUniQuery;
  sSerie:               string;
  sNumero:              string;
  bBorrarMovimientos:   Boolean;
  EsFacturaSimplificada: Boolean;
  Resultado: TResultadoEmisionFiscal;
  Servicio: IServicioEmisionFiscal;
  Solicitud: TSolicitudEmisionFiscal;
begin
  //Anulación Verifactu (RegistroAnulacion) de la factura del ticket
  bBorrarMovimientos := True;
  if not FacturaSeleccionada(sSerie, sNumero) then
    ShowMessage(SErrorOperacionSinBorrador)
  else
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := ConexionPrincipal;
      Qry.SQL.Text :=
        ' SELECT ESCONSOLIDADA_FAC, TIPO_FAC FROM fza_facturas ' +
        ' WHERE SERIE_FAC  = :SERIE ' +
        '   AND NUMERO_FAC = :NUMERO';
      Qry.ParamByName('SERIE').AsString  := sSerie;
      Qry.ParamByName('NUMERO').AsString := sNumero;
      Qry.Open;
      if Qry.IsEmpty or (Qry.Fields[0].AsString <> 'S') then
        ShowMessage(Format(SErrorBorradorNoCerradoFiscalmente,
                           [sSerie, sNumero]))
      else if MessageDlg(Format(SPreguntaAnularFiscalmenteBorrador,
                               [sSerie, sNumero]), mtConfirmation,
                         [mbYes, mbNo], 0) = mrYes then
      begin
        EsFacturaSimplificada := SameText(
          Qry.FieldByName('TIPO_FAC').AsString, 'SIMPLIFICADA');
        if EsFacturaSimplificada then
        begin
          bBorrarMovimientos := MessageDlg(
            Format(SPreguntaBorrarMovimientosTicketAnulado,
                   [sSerie, sNumero]), mtConfirmation,
            [mbYes, mbNo], 0) = mrYes;
        end;
        Qry.Close;
        Servicio := CrearServicioEmisionFiscal(
          ParametrosApp,
          ParametrosCaja,
          ConexionPrincipal,
          CrearServicioVerifactuColaUniDAC(ConexionPrincipal));
        Solicitud := TSolicitudEmisionFiscal.ParaOperacion(
          sSerie,
          sNumero,
          IdentidadSesion.Usuario,
          'ANULACION',
          'Anulación',
          bBorrarMovimientos,
          'Anulación encolada desde Buscar operaciones');
        Resultado := Servicio.Emitir(Solicitud);
        ShowMessage(Resultado.Mensaje);
      end;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

procedure TfrmConsultaOpe.btnFacturarTicketClick(Sender: TObject);
var
  Qry:     TUniQuery;
  oRes:    TFacturarTicketResult;
  sSerie:  string;
  sNumero: string;
  dtFecha: TDateTime;
  bSigue:  Boolean;
begin
  //Factura completa (F3) en sustitución del ticket de la operación
  dtFecha := 0;
  bSigue  := False;
  if not FacturaSeleccionada(sSerie, sNumero) then
    ShowMessage(SErrorOperacionSinBorrador)
  else
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := ConexionPrincipal;
      Qry.SQL.Text :=
        ' SELECT TIPO_FAC, FECHA_FAC FROM fza_facturas ' +
        ' WHERE SERIE_FAC  = :SERIE ' +
        '   AND NUMERO_FAC = :NUMERO';
      Qry.ParamByName('SERIE').AsString  := sSerie;
      Qry.ParamByName('NUMERO').AsString := sNumero;
      Qry.Open;
      if Qry.IsEmpty or
         (not SameText(Qry.FieldByName('TIPO_FAC').AsString,
                       'SIMPLIFICADA')) then
        ShowMessage(SErrorFacturarTicketRequiereSimplificado)
      else
      begin
        dtFecha := Qry.FieldByName('FECHA_FAC').AsDateTime;
        bSigue  := True;
      end;
    finally
      FreeAndNil(Qry);
    end;
    if bSigue then
    begin
      oRes := TfrmModalFacturarTicket.Ejecutar(Self, sSerie, sNumero,
                                               FEmpresa, FAlmacen,
                                               dtFecha);
      if oRes.Aceptado then
        ShowMessage(Format(SInfoBorradorSustitucionTicketCreado,
                          [oRes.SerieNueva, oRes.NumeroNueva,
                           sSerie, sNumero,
                           ModoVerifactuTexto(ParametrosApp)]));
    end;
  end;
end;

procedure TfrmConsultaOpe.btnRectificarClick(Sender: TObject);
var
  Qry:     TUniQuery;
  oAnfitrion: IAnfitrionCajaVentanas;
  oOperacionCaja: IOperacionCaja;
  oFormularioCaja: TCustomForm;
  sSerie:  string;
  sNumero: string;
  bSigue:  Boolean;
  TipoRectificativa: TTipoRectificativaCaja;
  TratamientoMovimientos: TTratamientoMovimientosRectificativa;
begin
  // Rectificar carga la venta con el signo del tipo elegido; al cobrar
  // saldrá con serie rectificativa y quedará enlazada.
  bSigue := False;
  if not FacturaSeleccionada(sSerie, sNumero) then
    ShowMessage(SErrorOperacionSinBorrador)
  else
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := ConexionPrincipal;
      Qry.SQL.Text :=
        ' SELECT TIPO_FAC FROM fza_facturas ' +
        ' WHERE SERIE_FAC  = :SERIE ' +
        '   AND NUMERO_FAC = :NUMERO';
      Qry.ParamByName('SERIE').AsString  := sSerie;
      Qry.ParamByName('NUMERO').AsString := sNumero;
      Qry.Open;
      if Qry.IsEmpty or
         SameText(Qry.FieldByName('TIPO_FAC').AsString,
                  'RECTIFICATIVA') then
        ShowMessage(SErrorRectificarRectificativa)
      else
        bSigue := True;
    finally
      FreeAndNil(Qry);
    end;
  end;
  if bSigue and SeleccionarTipoRectificativa(
    sSerie, sNumero, TipoRectificativa) then
  begin
    TratamientoMovimientos := tmrMantenerOriginales;
    if TipoRectificativa = trcSustitutiva then
    begin
      bSigue := SeleccionarMovimientosRectificativa(
        sSerie, sNumero, TratamientoMovimientos);
    end;
    if bSigue then
    begin
      // Ventana de ventas libre, o una nueva si todas están ocupadas
      oOperacionCaja := BuscarOperacionCajaVacia;
      if oOperacionCaja = nil then
      begin
        oAnfitrion := ExigirAnfitrionCaja(Application.MainForm);
        oOperacionCaja :=
          oAnfitrion.CrearOperacionCaja(Application, Permisos);
        oFormularioCaja := oOperacionCaja.FormularioCaja;
        oFormularioCaja.Caption :=
          Format(STituloOperacionCajaReal, [FCaja]);
        oOperacionCaja.PrepararValores(FEmpresa, FAlmacen, FCaja, Now);
      end;
      oFormularioCaja := oOperacionCaja.FormularioCaja;
      oOperacionCaja.CargarRectificacion(
        sSerie, sNumero, TipoRectificativa, TratamientoMovimientos);
      oFormularioCaja.Show;
      oFormularioCaja.BringToFront;
      if oFormularioCaja.WindowState = wsMinimized then
        oFormularioCaja.WindowState := wsNormal;
    end;
  end;
end;

function TfrmConsultaOpe.SeleccionarTipoRectificativa(
  const ASerie, ANumero: string;
  out ATipoRectificativa: TTipoRectificativaCaja): Boolean;
const
  AnchoBoton = 125;
  SeparacionBotones = 8;
var
  oDialogo: TForm;
  oBoton: TButton;
  i: Integer;
  iBotones: Integer;
  iIzquierda: Integer;
begin
  Result := False;
  ATipoRectificativa := trcNinguna;
  oDialogo := CreateMessageDialog(
    Format(SPreguntaRectificarBorrador, [ASerie, ANumero]),
    mtConfirmation, [mbYes, mbNo, mbCancel]);
  try
    oDialogo.Caption := STituloTipoRectificativa;
    if oDialogo.ClientWidth < 440 then
      oDialogo.ClientWidth := 440;
    iBotones := 0;
    for i := 0 to oDialogo.ComponentCount - 1 do
    begin
      if oDialogo.Components[i] is TButton then
        Inc(iBotones);
    end;
    iIzquierda := (oDialogo.ClientWidth -
      (iBotones * AnchoBoton) -
      ((iBotones - 1) * SeparacionBotones)) div 2;
    for i := 0 to oDialogo.ComponentCount - 1 do
    begin
      if oDialogo.Components[i] is TButton then
      begin
        oBoton := TButton(oDialogo.Components[i]);
        case oBoton.ModalResult of
          mrYes:
            oBoton.Caption := SCaptionPorDiferencias;
          mrNo:
            oBoton.Caption := SCaptionSustitutiva;
          mrCancel:
            oBoton.Caption := SCaptionCancelar;
        end;
        oBoton.SetBounds(iIzquierda, oBoton.Top, AnchoBoton, oBoton.Height);
        Inc(iIzquierda, AnchoBoton + SeparacionBotones);
      end;
    end;
    case oDialogo.ShowModal of
      mrYes:
        begin
          ATipoRectificativa := trcDiferencias;
          Result := True;
        end;
      mrNo:
        begin
          ATipoRectificativa := trcSustitutiva;
          Result := True;
        end;
    end;
  finally
    FreeAndNil(oDialogo);
  end;
end;

function TfrmConsultaOpe.SeleccionarMovimientosRectificativa(
  const ASerie, ANumero: string;
  out ATratamiento: TTratamientoMovimientosRectificativa): Boolean;
const
  AnchoBoton = 155;
  SeparacionBotones = 8;
var
  oDialogo: TForm;
  oBoton: TButton;
  i: Integer;
  iBotones: Integer;
  iIzquierda: Integer;
begin
  Result := False;
  ATratamiento := tmrMantenerOriginales;
  oDialogo := CreateMessageDialog(
    Format(SPreguntaMovimientosRectificativaSustitutiva,
      [ASerie, ANumero]),
    mtConfirmation, [mbYes, mbNo, mbCancel]);
  try
    oDialogo.Caption := STituloMovimientosAlmacen;
    if oDialogo.ClientWidth < 520 then
      oDialogo.ClientWidth := 520;
    iBotones := 0;
    for i := 0 to oDialogo.ComponentCount - 1 do
    begin
      if oDialogo.Components[i] is TButton then
        Inc(iBotones);
    end;
    iIzquierda := (oDialogo.ClientWidth -
      (iBotones * AnchoBoton) -
      ((iBotones - 1) * SeparacionBotones)) div 2;
    for i := 0 to oDialogo.ComponentCount - 1 do
    begin
      if oDialogo.Components[i] is TButton then
      begin
        oBoton := TButton(oDialogo.Components[i]);
        case oBoton.ModalResult of
          mrYes:
            oBoton.Caption := SCaptionEliminarOriginales;
          mrNo:
            oBoton.Caption := SCaptionMantenerOriginales;
          mrCancel:
            oBoton.Caption := SCaptionCancelar;
        end;
        oBoton.SetBounds(iIzquierda, oBoton.Top, AnchoBoton, oBoton.Height);
        Inc(iIzquierda, AnchoBoton + SeparacionBotones);
      end;
    end;
    case oDialogo.ShowModal of
      mrYes:
        begin
          ATratamiento := tmrReemplazarOriginales;
          Result := True;
        end;
      mrNo:
        begin
          ATratamiento := tmrMantenerOriginales;
          Result := True;
        end;
    end;
  finally
    FreeAndNil(oDialogo);
  end;
end;

// Recarga imgFotoConsulta con la foto a 300 px del articulo / SKU de
// la linea de factura activa. Lo invoca OnFacturaLinDataChange.
procedure TfrmConsultaOpe.RefrescarFotoConsulta;
var
  sArt, sSku: string;
  info: TFotoInfo;
  sRuta: string;
  png: TPngImage;
begin
  if not Assigned(imgFotoConsulta) then Exit;
  imgFotoConsulta.Picture.Assign(nil);
  ResolverArtSkuDeFacLin(sArt, sSku);
  if sArt = '' then Exit;
  info := oFotos.Resolver(sArt, sSku);
  sRuta := oFotos.RutaFoto(info, frPx300);
  if sRuta = '' then Exit;
  png := TPngImage.Create;
  try
    png.LoadFromFile(sRuta);
    imgFotoConsulta.Picture.Assign(png);
  finally
    FreeAndNil(png);
  end;
end;

procedure TfrmConsultaOpe.OnFacturaLinDataChange(Sender: TObject;
                                                 Field: TField);
begin
  if Field = nil then RefrescarFotoConsulta;
end;

procedure TfrmConsultaOpe.cxViewMovCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  colArticulo: TcxGridDBColumn;
  sArticulo: string;
  sColor: string;
begin
  ADone := False;
  if (AViewInfo <> nil) and
     (AViewInfo.GridRecord <> nil) and
     (AViewInfo.Item = colMovColor) then
  begin
    colArticulo := cxViewMov.GetColumnByFieldName('CODIGO_ART_MOV');
    if colArticulo <> nil then
    begin
      sArticulo := VarToStr(
        AViewInfo.GridRecord.Values[colArticulo.Index]);
      sColor := VarToStr(
        AViewInfo.GridRecord.Values[colMovColor.Index]);
      if PintarCeldaSwatchArticuloSiAplica(
        ConexionPrincipal,
        ACanvas,
        AViewInfo,
        sArticulo,
        sColor,
        nil) then
        ADone := True;
    end;
  end;
end;

procedure TfrmConsultaOpe.RestaurarLayout;
begin
  if not FLayout.Disponible then
  begin
    Log.LogInfo('RestaurarLayout: SKIP (FLayout no disponible)');
    Exit;
  end;
  Log.LogInfo('RestaurarLayout: aplicando geometria + 9 grids');
  FLayout.RestaurarGeometria(Self);
  FLayout.RestaurarAlturaPanel('PnlMaestroHeight', pnlMaestro, 80);
  FLayout.RestaurarAnchoPanel('FotoConsultaWidth', pnlFotoConsulta, 50);
  FLayout.RestaurarGrid('Maestro', cxViewMaestro);
  AplicarAnchosPestanasHijas;
  Log.LogInfo('RestaurarLayout: FIN');
end;

// Encaja el formulario en el area de trabajo del monitor actual. En
// resoluciones pequenas (1366x768, 1280x720...) el tamano de diseno deja la
// botonera inferior fuera de pantalla; aqui se recorta la ventana y se
// recoloca para que se vea entera. Se invoca tras RestaurarLayout porque el
// perfil guardado puede traer una geometria mayor que la pantalla del puesto.
procedure TfrmConsultaOpe.AjustarAPantalla;
var
  rArea: TRect;
begin
  if WindowState = wsNormal then
  begin
    rArea := Monitor.WorkareaRect;
    if Width > rArea.Width then
      Width := rArea.Width;
    if Height > rArea.Height then
      Height := rArea.Height;
    if Left + Width > rArea.Right then
      Left := rArea.Right - Width;
    if Top + Height > rArea.Bottom then
      Top := rArea.Bottom - Height;
    if Left < rArea.Left then
      Left := rArea.Left;
    if Top < rArea.Top then
      Top := rArea.Top;
  end;
end;

procedure TfrmConsultaOpe.AplicarAnchosPestanasHijas;
begin
  if not FLayout.Disponible then Exit;
  FLayout.RestaurarGrid('Operacion',   cxViewOpe);
  FLayout.RestaurarGrid('Pagos',       cxViewPagos);
  FLayout.RestaurarGrid('Vales',       cxViewVales);
  FLayout.RestaurarGrid('Movimientos', cxViewMov);
  FLayout.RestaurarGrid('Cliente',     cxViewCli);
  FLayout.RestaurarGrid('Depositos',   cxViewDep);
  FLayout.RestaurarGrid('FacturaCab',  cxViewFacCab);
  FLayout.RestaurarGrid('FacturaLin',  cxViewFacLin);
end;

procedure TfrmConsultaOpe.GuardarLayout;
var
  Layout: TLayoutSaver;
begin
  Layout := TLayoutSaver.Create(Self.Name, PerfilesEscritura);
  try
    Layout.GuardarGeometria(Self);
    Layout.GuardarAlturaPanel('PnlMaestroHeight', pnlMaestro);
    Layout.GuardarAnchoPanel('FotoConsultaWidth', pnlFotoConsulta);
    Layout.GuardarGrid('Maestro',     cxViewMaestro);
    Layout.GuardarGrid('Operacion',   cxViewOpe);
    Layout.GuardarGrid('Pagos',       cxViewPagos);
    Layout.GuardarGrid('Vales',       cxViewVales);
    Layout.GuardarGrid('Movimientos', cxViewMov);
    Layout.GuardarGrid('Cliente',     cxViewCli);
    Layout.GuardarGrid('Depositos',   cxViewDep);
    Layout.GuardarGrid('FacturaCab',  cxViewFacCab);
    Layout.GuardarGrid('FacturaLin',  cxViewFacLin);
    if Layout.PreguntarYGrabar('Personalizacion Consulta Operaciones') then
      ShowMessage(SInfoLayoutGuardado);
  finally
    FreeAndNil(Layout);
  end;
end;

procedure TfrmConsultaOpe.RecargarMaestro;
begin
  if (FEmpresa = '') or (FAlmacen = '') or (FCaja = '') then
  begin
    Log.LogInfo('RecargarMaestro: SKIP (contexto vacio)');
    Exit;
  end;
  Log.LogInfo(Format('RecargarMaestro: emp="%s" alm="%s" caja="%s" ' +
                     'fecha=%s txt="%s"',
                     [FEmpresa, FAlmacen, FCaja, DateToStr(dtpFecha.Date),
                      Trim(edtBuscar.Text)]));
  Screen.Cursor := crHourGlass;
  try
    FdmConsulta.CargarMaestro(dtpFecha.Date,
                              FEmpresa, FAlmacen, FCaja,
                              Trim(edtBuscar.Text));
    AjustarVisibilidadPestanas;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmConsultaOpe.OnMaestroDataChange(Sender: TObject; Field: TField);
begin
  // Field=nil => cambio de fila (no de celda). Refrescamos hijas y visibilidad.
  // El escudo FUltimaClaveHijas en el dm evita relanzar las 8 queries si la
  // operacion activa no ha cambiado realmente.
  if Field = nil then
  begin
    Log.LogInfo('OnMaestroDataChange: Field=nil -> RefrescarPestanasHijas');
    FdmConsulta.RefrescarPestanasHijas;
    AjustarVisibilidadPestanas;
  end;
end;

procedure TfrmConsultaOpe.AjustarVisibilidadPestanas;
var
  PagActiva: TcxTabSheet;
begin
  PagActiva := pcHijos.ActivePage;
  tsOperacion.TabVisible   := True;   // siempre visible
  tsPagos.TabVisible       := True;  // siempre visible
  tsVales.TabVisible       := FdmConsulta.TieneVales;
  tsMovimientos.TabVisible := True;  // siempre visible y pestaña inicial
  tsCliente.TabVisible     := FdmConsulta.TieneCliente;
  tsDepositos.TabVisible   := FdmConsulta.TieneDepositos;
  tsFactura.TabVisible     := FdmConsulta.TieneFactura;

  if (PagActiva <> nil) and (not PagActiva.TabVisible) then
    pcHijos.ActivePage := tsOperacion;

  btnReimprimir.Enabled :=
    FdmConsulta.TieneFactura
    or FdmConsulta.TieneDepositos
    or FdmConsulta.EsOperacionCaja
    or FdmConsulta.EsTraspaso;
  btnReimprimirOtros.Enabled := btnReimprimir.Enabled;
  btnEnviarEmail.Enabled := btnReimprimir.Enabled;
end;

// -----------------------------------------------------------------------------
procedure TfrmConsultaOpe.btnRefrescarClick(Sender: TObject);
begin
  RecargarMaestro;
end;

procedure TfrmConsultaOpe.dtpFechaPropertiesEditValueChanged(Sender: TObject);
begin
  inherited;
  // Antes habia tambien un handler dtpFechaPropertiesChange (Properties.
  // OnChange en el dfm) llamando a RecargarMaestro. Disparaba la carga del
  // maestro dos veces seguidas con los mismos parametros porque tanto
  // OnChange como OnEditValueChanged se activan al setear dtpFecha.Date.
  // Eliminado el handler OnChange; este (OnEditValueChanged) es suficiente.
  RecargarMaestro;
end;

procedure TfrmConsultaOpe.dtpFechaPropertiesGetDayState(Sender: TObject;
  ADate: TDateTime; AState: TCustomDrawState; AFont: TFont;
  var ABackgroundColor: TColor);
begin
  inherited;
  FVentasCal.AplicarEstiloDia(ADate, AFont, ABackgroundColor);
end;

procedure TfrmConsultaOpe.edtBuscarPropertiesChange(Sender: TObject);
begin
  tmrBusqueda.Enabled := False;
  tmrBusqueda.Enabled := True;
end;

procedure TfrmConsultaOpe.tmrBusquedaTimer(Sender: TObject);
begin
  tmrBusqueda.Enabled := False;
  RecargarMaestro;
end;

procedure TfrmConsultaOpe.btnReimprimirClick(Sender: TObject);
begin
  ReimprimirOperacion(ParametrosCaja.ImpresoraCaja);
end;

procedure TfrmConsultaOpe.btnReimprimirOtrosClick(Sender: TObject);
begin
  ReimprimirOperacion('DEBUG');
end;

procedure TfrmConsultaOpe.btnEnviarEmailClick(Sender: TObject);
var
  Datos: TDatosCorreoOperacion;
  sEmp, sAlm, sCaja, sNumOp, sEmail, sMensaje: string;
  bContinuar: Boolean;
begin
  if not FdmConsulta.qryMaestro.IsEmpty then
  begin
    bContinuar := CorreoTicketsConfigurado(ParametrosApp, sMensaje);
    if not bContinuar then
      ShowMessage(sMensaje)
    else
    begin
      sEmp := FdmConsulta.qryMaestro.
        FieldByName('CODIGO_EMP_OPCAJA').AsString;
      sAlm := FdmConsulta.qryMaestro.
        FieldByName('CODIGO_ALM_OPCAJA').AsString;
      sCaja := FdmConsulta.qryMaestro.
        FieldByName('CODIGO_CAJA_OPCAJA').AsString;
      sNumOp := FdmConsulta.qryMaestro.
        FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
      Datos := ObtenerDatosCorreoOperacion(ConexionPrincipal, sEmp, sAlm,
        sCaja, sNumOp);
      sEmail := Datos.EmailCliente;
      bContinuar := Datos.Encontrada;
      if not bContinuar then
        ShowMessage(SErrorOperacionCorreoNoEncontrada)
      else if sEmail = '' then
        bContinuar := InputQuery(STituloEnviarDocumentacion,
          SSolicitudCorreoElectronico, sEmail);
      if bContinuar and (Trim(sEmail) = '') then
      begin
        ShowMessage(SErrorCorreoElectronicoObligatorio);
        bContinuar := False;
      end;
      if bContinuar then
      begin
        Screen.Cursor := crHourGlass;
        try
          if EnviarDocumentacionOperacion(
            ParametrosApp,
            CrearRepositorioTraspasoTicket,
            CrearRepositorioTicketsCaja,
            ConexionPrincipal,
            sEmp,
            sAlm,
            sCaja, sNumOp,
            sEmail, sMensaje) then
            ShowMessage(sMensaje)
          else
            ShowMessage(Format(SErrorEnviarCorreoOperacion, [sMensaje]));
        finally
          Screen.Cursor := crDefault;
        end;
      end;
    end;
  end;
end;

procedure TfrmConsultaOpe.ReimprimirOperacion(
  const ANombreImpresora: string);
var
  sEmp, sAlm, sCaja, sNumOp, sCliente: string;
begin
  if not FdmConsulta.qryMaestro.IsEmpty then
  begin
    sEmp :=
      FdmConsulta.qryMaestro.FieldByName('CODIGO_EMP_OPCAJA').AsString;
    sAlm :=
      FdmConsulta.qryMaestro.FieldByName('CODIGO_ALM_OPCAJA').AsString;
    sCaja :=
      FdmConsulta.qryMaestro.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
    sNumOp := FdmConsulta.qryMaestro.
      FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
    sCliente := FdmConsulta.qryMaestro.FieldByName('CLIENTE').AsString;
    // Los traspasos usan su ticket específico con stock origen/destino.
    if FdmConsulta.EsTraspaso then
      TTraspasoTicket.ImprimirTraspasoDesdeBD(
                                              CrearRepositorioTraspasoTicket,
                                              sEmp,
                                              sAlm, sCaja, sNumOp,
                                              ANombreImpresora)
    else
    begin
      if FdmConsulta.TieneFactura then
        ImprimirTicketDesdeBD(
          ParametrosApp,
          CrearRepositorioTicketsCaja,
          sEmp,
          sAlm,
          sCaja,
          sNumOp,
          ANombreImpresora);
      if FdmConsulta.TieneDepositos then
        ImprimirResguardoDeposito(
          CrearRepositorioTicketsCaja,
          sEmp,
          sAlm,
          sCaja,
          sNumOp,
          ANombreImpresora);
      if FdmConsulta.EsOperacionCaja then
        ImprimirTicketOperacionCaja(ConexionPrincipal, sEmp, sAlm, sCaja,
                                    sNumOp,
                                    ANombreImpresora);
      if (not FdmConsulta.TieneFactura)
         and (not FdmConsulta.TieneDepositos)
         and (not FdmConsulta.EsOperacionCaja) then
        ShowMessage(SErrorOperacionSinTicket)
      else if Trim(sCliente) <> '' then
        ImprimirRecordatorio(
          CrearRepositorioTicketsCaja,
          UbicacionSesion.Empresa,
          sCliente,
          ANombreImpresora);
    end;
  end;
end;

procedure TfrmConsultaOpe.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

end.
