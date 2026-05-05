unit inMtoConsultaOpe;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls, Data.DB,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit, cxNavigator,
  cxDBData, cxGridLevel, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, cxCalendar, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, cxButtonEdit, cxContainer, cxLabel,
  inMtoFrmBase, inLibVentasCalendario, inLibLayoutForm,
  UniDataConsultaOpe, dxCore, cxDateUtils, dxCoreGraphics, cxCurrencyEdit,
  cxClasses, cxGridCustomView, JvComponentBase, JvEnterTab, cxLocalization;

type
  TfrmConsultaOpe = class(TfrmBase)
    pnlFiltros:       TPanel;
    lblFecha:         TcxLabel;
    lblBuscar:        TcxLabel;
    edtBuscar:        TcxButtonEdit;
    pnlMaestro:       TPanel;
    cxGridMaestro:    TcxGrid;
    cxViewMaestro:    TcxGridDBTableView;
    cxLevelMaestro:   TcxGridLevel;
    splitter:         TSplitter;
    pcHijos:          TcxPageControl;
    tsOperacion:      TcxTabSheet;
    tsPagos:          TcxTabSheet;
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
    pnlPie:           TPanel;
    btnReimprimir:    TButton;
    btnCerrar:        TButton;
    tmrBusqueda:      TTimer;
    Button1: TButton;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnRefrescarClick(Sender: TObject);
    procedure dtpFechaPropertiesChange(Sender: TObject);
    procedure edtBuscarPropertiesChange(Sender: TObject);
    procedure tmrBusquedaTimer(Sender: TObject);
    procedure btnReimprimirClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure dtpFechaPropertiesGetDayState(Sender: TObject; ADate: TDateTime;
      AState: TCustomDrawState; AFont: TFont; var ABackgroundColor: TColor);
    procedure dtpFechaPropertiesEditValueChanged(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FdmConsulta: TdmConsultaOpe;
    FEmpresa:    string;
    FAlmacen:    string;
    FCaja:       string;
    procedure RecargarMaestro;
    procedure GuardarLayout;
    procedure RestaurarLayout;
    procedure AjustarVisibilidadPestanas;
    procedure AplicarAnchosPestanasHijas;
    procedure OnMaestroDataChange(Sender: TObject; Field: TField);
  public
    procedure PrepararValores(const AEmpresa,
                                    AAlmacen,
                                    ACaja: string;
                                    AFecha: TDateTime);
  private
    FLayout: TLayoutLoader;
    FVentasCal: TVentasCalendarioCache;
    procedure dtpFechaGetDayState(Sender: TObject; ADate: TDateTime;
      AState: TCustomDrawState; AFont: TFont; var ABackgroundColor: TColor);
  end;

var
  frmConsultaOpe: TfrmConsultaOpe;

implementation

{$R *.dfm}

uses inLibtb, inLibGenerarTicketBD, inLibGlobalVar;

// -----------------------------------------------------------------------------
procedure TfrmConsultaOpe.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  Action := CaFree;
end;

procedure TfrmConsultaOpe.FormCreate(Sender: TObject);
begin
  inherited;
  FdmConsulta := TdmConsultaOpe.Create(Self);
  FLayout     := TLayoutLoader.Create(Self.Name);
  FVentasCal := TVentasCalendarioCache.Create(inLibGlobalVar.oConn);
  dtpFecha.Properties.OnGetDayState := dtpFechaGetDayState;
  cxViewMaestro.DataController.DataSource := FdmConsulta.dsMaestro;
  cxViewOpe.DataController.DataSource     := FdmConsulta.dsOperacion;
  cxViewPagos.DataController.DataSource   := FdmConsulta.dsPagos;
  cxViewMov.DataController.DataSource     := FdmConsulta.dsMovimientos;
  cxViewCli.DataController.DataSource     := FdmConsulta.dsCliente;
  cxViewDep.DataController.DataSource     := FdmConsulta.dsDepositos;
  cxViewFacCab.DataController.DataSource  := FdmConsulta.dsFactura;
  cxViewFacLin.DataController.DataSource  := FdmConsulta.dsFacturaLin;
  FdmConsulta.dsMaestro.OnDataChange := OnMaestroDataChange;
  tmrBusqueda.Enabled  := False;
  tmrBusqueda.Interval := 400;
  KeyPreview := True;   // para que FormKeyDown capture F5/ESC aunque el foco
                        // esté en el grid o en el edit de búsqueda
end;

procedure TfrmConsultaOpe.FormDestroy(Sender: TObject);
begin
  inherited;
  FLayout.Free;
  FVentasCal.Free;
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

procedure TfrmConsultaOpe.FormShow(Sender: TObject);
begin
  inherited;
  Caption := Format('Buscar operaciones — Empresa %s / Almacén %s / Caja %s',
                    [FEmpresa, FAlmacen, FCaja]);
  RecargarMaestro;
  RestaurarLayout;
  if edtBuscar.CanFocus then
    edtBuscar.SetFocus;
end;

procedure TfrmConsultaOpe.FormKeyDown(Sender: TObject; var Key: Word;
                                                       Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE: Close;
    VK_F5:     RecargarMaestro;
    VK_F12:    if ssAlt in Shift then GuardarLayout;
  end;
end;

procedure TfrmConsultaOpe.RestaurarLayout;
begin
  if not FLayout.Disponible then Exit;
  FLayout.RestaurarGeometria(Self);
  FLayout.RestaurarAlturaPanel('PnlMaestroHeight', pnlMaestro, 80);
  FLayout.RestaurarGrid('Maestro', cxViewMaestro);
  AplicarAnchosPestanasHijas;
end;

procedure TfrmConsultaOpe.AplicarAnchosPestanasHijas;
begin
  if not FLayout.Disponible then Exit;
  FLayout.RestaurarGrid('Operacion',   cxViewOpe);
  FLayout.RestaurarGrid('Pagos',       cxViewPagos);
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
  Layout := TLayoutSaver.Create(Self.Name);
  try
    Layout.GuardarGeometria(Self);
    Layout.GuardarAlturaPanel('PnlMaestroHeight', pnlMaestro);
    Layout.GuardarGrid('Maestro',     cxViewMaestro);
    Layout.GuardarGrid('Operacion',   cxViewOpe);
    Layout.GuardarGrid('Pagos',       cxViewPagos);
    Layout.GuardarGrid('Movimientos', cxViewMov);
    Layout.GuardarGrid('Cliente',     cxViewCli);
    Layout.GuardarGrid('Depositos',   cxViewDep);
    Layout.GuardarGrid('FacturaCab',  cxViewFacCab);
    Layout.GuardarGrid('FacturaLin',  cxViewFacLin);
    if Layout.PreguntarYGrabar('Personalización Consulta Operaciones') then
      ShowMessage('Layout guardado.');
  finally
    Layout.Free;
  end;
end;

procedure TfrmConsultaOpe.RecargarMaestro;
begin
  if (FEmpresa = '') or (FAlmacen = '') or (FCaja = '') then Exit;
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
  if Field = nil then
  begin
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
  tsPagos.TabVisible       := FdmConsulta.TienePagos;
  tsMovimientos.TabVisible := FdmConsulta.TieneMovimientos;
  tsCliente.TabVisible     := FdmConsulta.TieneCliente;
  tsDepositos.TabVisible   := FdmConsulta.TieneDepositos;
  tsFactura.TabVisible     := FdmConsulta.TieneFactura;

  if (PagActiva <> nil) and (not PagActiva.TabVisible) then
    pcHijos.ActivePage := tsOperacion;

  btnReimprimir.Enabled :=
    FdmConsulta.TieneFactura or FdmConsulta.TieneDepositos;
end;

// -----------------------------------------------------------------------------
procedure TfrmConsultaOpe.btnRefrescarClick(Sender: TObject);
begin
  RecargarMaestro;
end;

procedure TfrmConsultaOpe.dtpFechaPropertiesChange(Sender: TObject);
begin
  RecargarMaestro;
end;

procedure TfrmConsultaOpe.dtpFechaPropertiesEditValueChanged(Sender: TObject);
begin
  inherited;
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
var
  sEmp, sAlm, sCaja, sNumOp, sCliente: string;
begin
  if FdmConsulta.qryMaestro.IsEmpty then Exit;

  sEmp     := FdmConsulta.qryMaestro.FieldByName('CODIGO_EMP_OPCAJA').AsString;
  sAlm     := FdmConsulta.qryMaestro.FieldByName('CODIGO_ALM_OPCAJA').AsString;
  sCaja    := FdmConsulta.qryMaestro.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
  sNumOp   := FdmConsulta.qryMaestro.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
  sCliente := FdmConsulta.qryMaestro.FieldByName('CLIENTE').AsString;
  if FdmConsulta.TieneFactura then
    ImprimirTicketDesdeBD(sEmp, sAlm, sCaja, sNumOp, oNomImpresoraCaja);
  if FdmConsulta.TieneDepositos then
    ImprimirResguardoDeposito(sEmp, sAlm, sCaja, sNumOp, oNomImpresoraCaja);
  if (not FdmConsulta.TieneFactura) and (not FdmConsulta.TieneDepositos) then
  begin
    ShowMessage('Esta operación no tiene ticket ni depósito asociado.');
    Exit;
  end;
  if Trim(sCliente) <> '' then
    ImprimirRecordatorio(sCliente, oNomImpresoraCaja);
end;

procedure TfrmConsultaOpe.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

end.
