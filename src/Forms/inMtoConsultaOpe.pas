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
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls, Data.DB,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit, cxNavigator,
  cxDBData, cxGridLevel, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, cxCalendar, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, cxButtonEdit, cxContainer, cxLabel,
  cxSplitter, Vcl.Imaging.PngImage,
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
    btnCerrar:        TButton;
    tmrBusqueda:      TTimer;
    btnDevolverAbonar: TButton;
    btnAnularVerifactu: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnRefrescarClick(Sender: TObject);
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
    procedure OnFacturaLinDataChange(Sender: TObject; Field: TField);
    procedure RefrescarFotoConsulta;
    // Lee el ARTICULO / SKU de la linea activa en cxViewFacLin para
    // alimentar la pantalla flotante de fotos (Ctrl + F).
    procedure ResolverArtSkuDeFacLin(out ACodArt, ACodSku: string);
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

uses inLibtb, inLibGenerarTicketBD, inLibGenerarTicketCaja,
     inLibGlobalVar, inLibLog, inLibFotos, inMtoFotoArticulo;

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

procedure TfrmConsultaOpe.FormShow(Sender: TObject);
begin
  inherited;
  Log.LogInfo(Format('frmConsultaOpe.FormShow: INICIO emp="%s" alm="%s" ' +
                     'caja="%s" fecha=%s',
                     [FEmpresa, FAlmacen, FCaja, DateToStr(dtpFecha.Date)]));
  Caption := Format('Buscar operaciones — Empresa %s / Almacen %s / Caja %s',
                    [FEmpresa, FAlmacen, FCaja]);
  RecargarMaestro;
  RestaurarLayout;
  if edtBuscar.CanFocus then
    edtBuscar.SetFocus;
  Log.LogInfo('frmConsultaOpe.FormShow: FIN');
end;

procedure TfrmConsultaOpe.FormKeyDown(Sender: TObject; var Key: Word;
                                                       Shift: TShiftState);
var
  sArt, sSku: string;
begin
  // Ctrl + F -> Foto del articulo / SKU de la linea de factura
  // activa en cxViewFacLin.
  if (Key = Ord('F')) and (ssCtrl in Shift) and (ssAlt in Shift) then
  begin
    ResolverArtSkuDeFacLin(sArt, sSku);
    if sArt <> '' then
    begin
      MostrarFotoFlotante(Self, sArt, sSku);
      if Assigned(frmFotoArticulo) then
        frmFotoArticulo.VincularMtoPadre(FdmConsulta.dsFacturaLin,
                                         ResolverArtSkuDeFacLin);
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
        ResetearLayout(Self.Name);
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
  Layout := TLayoutSaver.Create(Self.Name);
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
      ShowMessage('Layout guardado.');
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
  tsPagos.TabVisible       := FdmConsulta.TienePagos;
  tsVales.TabVisible       := FdmConsulta.TieneVales;
  tsMovimientos.TabVisible := FdmConsulta.TieneMovimientos;
  tsCliente.TabVisible     := FdmConsulta.TieneCliente;
  tsDepositos.TabVisible   := FdmConsulta.TieneDepositos;
  tsFactura.TabVisible     := FdmConsulta.TieneFactura;

  if (PagActiva <> nil) and (not PagActiva.TabVisible) then
    pcHijos.ActivePage := tsOperacion;

  btnReimprimir.Enabled :=
    FdmConsulta.TieneFactura
    or FdmConsulta.TieneDepositos
    or FdmConsulta.EsOperacionCaja;
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
var
  sEmp, sAlm, sCaja, sNumOp, sCliente: string;
begin
  if FdmConsulta.qryMaestro.IsEmpty then Exit;

  sEmp     := FdmConsulta.qryMaestro.FieldByName('CODIGO_EMP_OPCAJA').AsString;
  sAlm     := FdmConsulta.qryMaestro.FieldByName('CODIGO_ALM_OPCAJA').AsString;
  sCaja    := FdmConsulta.qryMaestro.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
  sNumOp   :=
    FdmConsulta.qryMaestro.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
  sCliente := FdmConsulta.qryMaestro.FieldByName('CLIENTE').AsString;
  if FdmConsulta.TieneFactura then
    ImprimirTicketDesdeBD(sEmp, sAlm, sCaja, sNumOp, oNomImpresoraCaja);
  if FdmConsulta.TieneDepositos then
    ImprimirResguardoDeposito(sEmp, sAlm, sCaja, sNumOp, oNomImpresoraCaja);
  if FdmConsulta.EsOperacionCaja then
    ImprimirTicketOperacionCaja(sEmp, sAlm, sCaja, sNumOp,
                                oNomImpresoraCaja);
  if (not FdmConsulta.TieneFactura)
     and (not FdmConsulta.TieneDepositos)
     and (not FdmConsulta.EsOperacionCaja) then
  begin
    ShowMessage('Esta operación no tiene ticket asociado.');
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
