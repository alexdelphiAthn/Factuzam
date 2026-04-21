unit inMtoConsultaOpe;

// =============================================================================
//  F10 - BUSCAR/MODIFICAR OPERACIONES DE CAJA
//
//  Se invoca desde inMtoCajaMenu pasando (empresa, almacen, caja, fecha).
//  Hereda de TfrmBase (como el resto del sistema) para estética consistente.
//
//  Layout:
//    ┌────────────────────────────────────────────────────────────────┐
//    │ [Fecha ▾]  [Buscar: ___________________]  [Refrescar]          │
//    ├────────────────────────────────────────────────────────────────┤
//    │  cxGrid MAESTRO (operaciones del día agrupadas)                │
//    │                                                                │
//    ├────────────────────────────────────────────────────────────────┤
//    │ [Operación] [Movimientos] [Cliente] [Depósitos] [Factura]      │
//    │  grids en cada pestaña — sólo lectura                          │
//    │                                                                │
//    │        [ Reimprimir ]            [ Cerrar (ESC) ]              │
//    └────────────────────────────────────────────────────────────────┘
// =============================================================================

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
  inMtoFrmBase,
  UniDataConsultaOpe, dxCore, cxDateUtils, dxCoreGraphics, cxCurrencyEdit,
  cxClasses, cxGridCustomView, JvComponentBase, JvEnterTab, cxLocalization;

type
  TfrmConsultaOpe = class(TfrmBase)
    pnlFiltros:       TPanel;
    lblFecha:         TcxLabel;


    lblBuscar:        TcxLabel;
    edtBuscar:        TcxButtonEdit;
    btnRefrescar:     TButton;

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
  private
    FdmConsulta: TdmConsultaOpe;
    FEmpresa:    string;
    FAlmacen:    string;
    FCaja:       string;
    procedure RecargarMaestro;
    procedure AjustarVisibilidadPestanas;
    procedure OnMaestroDataChange(Sender: TObject; Field: TField);
  public
    // Invocado por inMtoCajaMenu antes de Show (patrón idéntico al de TfrmMtoOpeCaja)
    procedure PrepararValores(const AEmpresa,
                                    AAlmacen,
                                    ACaja: string;
                                    AFecha: TDateTime);
  end;

var
  frmConsultaOpe: TfrmConsultaOpe;

implementation

{$R *.dfm}

uses inLibtb, inLibGenerarTicketBD, inLibGlobalVar;

// -----------------------------------------------------------------------------
procedure TfrmConsultaOpe.FormCreate(Sender: TObject);
begin
  inherited;
  FdmConsulta := TdmConsultaOpe.Create(Self);

  cxViewMaestro.DataController.DataSource := FdmConsulta.dsMaestro;
  cxViewOpe.DataController.DataSource     := FdmConsulta.dsOperacion;
  cxViewPagos.DataController.DataSource   := FdmConsulta.dsPagos;
  cxViewMov.DataController.DataSource     := FdmConsulta.dsMovimientos;
  cxViewCli.DataController.DataSource     := FdmConsulta.dsCliente;
  cxViewDep.DataController.DataSource     := FdmConsulta.dsDepositos;
  cxViewFacCab.DataController.DataSource  := FdmConsulta.dsFactura;
  cxViewFacLin.DataController.DataSource  := FdmConsulta.dsFacturaLin;

  // Reaccionamos al cambio de fila del maestro
  FdmConsulta.dsMaestro.OnDataChange := OnMaestroDataChange;

  // Timer de debounce para la búsqueda en caliente (400ms)
  tmrBusqueda.Enabled  := False;
  tmrBusqueda.Interval := 400;

  KeyPreview := True;   // para que FormKeyDown capture F5/ESC aunque el foco
                        // esté en el grid o en el edit de búsqueda
end;

// -----------------------------------------------------------------------------
procedure TfrmConsultaOpe.PrepararValores(const AEmpresa,
                                                AAlmacen,
                                                ACaja: string;
                                                AFecha: TDateTime);
begin
  FEmpresa := AEmpresa;
  FAlmacen := AAlmacen;
  FCaja    := ACaja;
  dtpFecha.Date := AFecha;   // fecha heredada del calendario del menú
end;

// -----------------------------------------------------------------------------
procedure TfrmConsultaOpe.FormShow(Sender: TObject);
begin
  inherited;
  Caption := Format('Buscar operaciones — Empresa %s / Almacén %s / Caja %s',
                    [FEmpresa, FAlmacen, FCaja]);
  RecargarMaestro;
  if edtBuscar.CanFocus then
    edtBuscar.SetFocus;
end;

// -----------------------------------------------------------------------------
procedure TfrmConsultaOpe.FormKeyDown(Sender: TObject; var Key: Word;
                                                       Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE: Close;
    VK_F5:     RecargarMaestro;
  end;
end;

// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
procedure TfrmConsultaOpe.OnMaestroDataChange(Sender: TObject; Field: TField);
begin
  // Field=nil => cambio de fila (no de celda). Refrescamos hijas y visibilidad.
  if Field = nil then
  begin
    FdmConsulta.RefrescarPestanasHijas;
    AjustarVisibilidadPestanas;
  end;
end;

// -----------------------------------------------------------------------------
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

// Debounce: cada vez que el usuario pulsa una tecla, reiniciamos el timer.
// Cuando pare de teclear 400ms, disparamos la búsqueda. Así no saturamos MySQL.
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

// -----------------------------------------------------------------------------
procedure TfrmConsultaOpe.btnReimprimirClick(Sender: TObject);
var
  sEmp, sAlm, sCaja, sNumOp, sCliente: string;
begin
  if FdmConsulta.qryMaestro.IsEmpty then Exit;

  sEmp     := FdmConsulta.qryMaestro.FieldByName('CODIGO_EMPRESA_OPCAJA').AsString;
  sAlm     := FdmConsulta.qryMaestro.FieldByName('CODIGO_ALMACEN_OPCAJA').AsString;
  sCaja    := FdmConsulta.qryMaestro.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
  sNumOp   := FdmConsulta.qryMaestro.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
  sCliente := FdmConsulta.qryMaestro.FieldByName('CLIENTE').AsString;

  // Replicamos el orden de GrabarFacturaSimplificada:
  //   1º  ticket fiscal        (si existe factura)
  //   2º  resguardo depósitos  (si hubo alta/cancelación de depósito)
  //   3º  recordatorio cliente (estado de cuenta ACTUAL, si hay cliente)
  //
  // Una misma operación puede imprimir las tres cosas: p.ej. cuando el
  // cliente cobra un depósito existente y a la vez aparta prenda nueva.

  if FdmConsulta.TieneFactura then
    ImprimirTicketDesdeBD(sEmp, sAlm, sCaja, sNumOp, 'DEBUG');

  if FdmConsulta.TieneDepositos then
    ImprimirResguardoDeposito(sEmp, sAlm, sCaja, sNumOp, 'DEBUG');

  if (not FdmConsulta.TieneFactura) and (not FdmConsulta.TieneDepositos) then
  begin
    ShowMessage('Esta operación no tiene ticket ni resguardo asociados.');
    Exit;
  end;

  // Recordatorio de estado de cuenta: se imprime SIEMPRE que haya cliente,
  // independientemente de si la operación era factura o depósito.
  // Muestra la situación al día de HOY, no la del día de la operación original.
  if Trim(sCliente) <> '' then
    ImprimirRecordatorio(sCliente, 'DEBUG');
end;

// -----------------------------------------------------------------------------
procedure TfrmConsultaOpe.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

end.
