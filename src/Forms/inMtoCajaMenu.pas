unit inMtoCajaMenu;

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  inMtoFrmBase,
  System.Classes, Vcl.Graphics, Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, JvExControls, JvAnimatedImage,
  JvGIFCtrl, cxLabel, Vcl.ExtCtrls, math, cxStyles,
  UniProvider, MySQLUniProvider, Data.DB, DBAccess, Uni, Vcl.Menus,
  Vcl.StdCtrls, cxButtons, inMtoCajaOpe, system.IOUtils, system.IniFiles,
  inMtoModalCajDef, JvTFManager, JvTFGlance, JvTFMonths, Vcl.ComCtrls,
  JvExComCtrls, JvMonthCalendar, cxCalendar, CommCtrl,
  inLibVentasCalendario, System.Actions, Vcl.ActnList;

type
  TfrmMtoMenuCaja = class(TfrmBase)
    lblF5: TcxLabel;
    lblF10: TcxLabel;
    lblBuscarModificar: TcxLabel;
    lblVentas: TcxLabel;
    Shape1: TShape;
    cxClock1: TcxClock;
    Timer1: TTimer;
    lblF6: TcxLabel;
    lblEntradaCambio: TcxLabel;
    lblF7: TcxLabel;
    lblGastosCaja: TcxLabel;
    lblArqueo: TcxLabel;
    lblF11: TcxLabel;
    lblSalir: TcxLabel;
    lblESC: TcxLabel;
    lblFecha: TcxLabel;
    cxLabel2: TcxLabel;
    cxLabel3: TcxLabel;
    Shape2: TShape;
    lblF3: TcxLabel;
    lblTraspasos: TcxLabel;
    jvgfnmtr1: TJvGIFAnimator;
    lblEmpresa: TcxLabel;
    JvMonthCalendar1: TJvMonthCalendar;
    ActionList1: TActionList;
    Action1: TAction;
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    // Eventos F5
    procedure lblVentasMouseEnter(Sender: TObject);
    procedure lblVentasMouseLeave(Sender: TObject);
    procedure lblF5MouseEnter(Sender: TObject);
    procedure lblF5MouseLeave(Sender: TObject);
    // Eventos F10
    procedure lblBuscarModificarMouseEnter(Sender: TObject);
    procedure lblBuscarModificarMouseLeave(Sender: TObject);
    procedure lblF10MouseEnter(Sender: TObject);
    procedure lblF10MouseLeave(Sender: TObject);
    // Eventos F6
    procedure lblEntradaCambioMouseEnter(Sender: TObject);
    procedure lblEntradaCambioMouseLeave(Sender: TObject);
    procedure lblF6MouseEnter(Sender: TObject);
    procedure lblF6MouseLeave(Sender: TObject);
    // Eventos F7
    procedure lblGastosCajaMouseEnter(Sender: TObject);
    procedure lblGastosCajaMouseLeave(Sender: TObject);
    procedure lblF7MouseEnter(Sender: TObject);
    procedure lblF7MouseLeave(Sender: TObject);
    // Eventos F11
    procedure lblArqueoMouseEnter(Sender: TObject);
    procedure lblArqueoMouseLeave(Sender: TObject);
    procedure lblF11MouseEnter(Sender: TObject);
    procedure lblF11MouseLeave(Sender: TObject);
    // Eventos F3
    procedure lblTraspasosMouseEnter(Sender: TObject);
    procedure lblTraspasosMouseLeave(Sender: TObject);
    procedure lblF3MouseEnter(Sender: TObject);
    procedure lblF3MouseLeave(Sender: TObject);
    // Eventos ESC
    procedure lblSalirMouseEnter(Sender: TObject);
    procedure lblSalirMouseLeave(Sender: TObject);
    procedure lblESCMouseEnter(Sender: TObject);
    procedure lblESCMouseLeave(Sender: TObject);
    procedure JvMonthCalendar1GetMonthBoldInfo(Sender: TObject;
      Month, Year: Cardinal; var MonthBoldInfo: Cardinal);
    procedure JvMonthCalendar1DblClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lblESCClick(Sender: TObject);
    procedure lblFechaMouseEnter(Sender: TObject);
    procedure lblFechaMouseLeave(Sender: TObject);
    procedure cxButton1Click(Sender: TObject);
    procedure lblVentasClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure lblEmpresaDblClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure JvMonthCalendar1Click(Sender: TObject);
    procedure lblBuscarModificarClick(Sender: TObject);
    procedure lblF10Click(Sender: TObject);
    procedure Action1Execute(Sender: TObject);
  private
    FVentasCal: TVentasCalendarioCache;
    procedure AbrirBuscarModificar;
  private
    // Colores originales
    FOriginalF5Color: TColor;
    FOriginalVentasColor: TColor;
    FOriginalF10Color: TColor;
    FOriginalBuscarModificarColor: TColor;
    FOriginalF6Color: TColor;
    FOriginalEntradaCambioColor: TColor;
    FOriginalF7Color: TColor;
    FOriginalGastosCajaColor: TColor;
    FOriginalF11Color: TColor;
    FOriginalArqueoColor: TColor;
    FOriginalESCColor: TColor;
    FOriginalSalirColor: TColor;
    FOriginalF3Color: TColor;
    FOriginalTraspasosColor: TColor;
    procedure ChangeMenuItemColors(FKeyLabel, DescLabel: TcxLabel;
                                   HoverColor: TColor);
    procedure RestoreMenuItemColors(FKeyLabel, DescLabel: TcxLabel;
                                    OriginalFKeyColor,
                                    OriginalDescColor: TColor);
    procedure AbrirSelectorCaja;
    procedure RecargarCalendario;
  public
    FFechaCaja: TDateTime;
    FEmpresa, FAlmacen, FCaja: string;
    property FechaCaja: TDateTime read FFechaCaja;
  end;

var
  frmMtoMenuCaja: TfrmMtoMenuCaja;

implementation

uses
  inLibGlobalVar, inLibCajaParam, DateUtils, inMtoConsultaOpe;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoMenuCaja.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  i: Integer;
  F: TForm;
begin
  CanClose := True;
  for i := Screen.FormCount - 1 downto 0 do
  begin
    F := Screen.Forms[i];
    if F is TfrmMtoOpeCaja then
    begin
      if not TfrmMtoOpeCaja(F).IntentarCerrar then
      begin
        CanClose := False;
        Break;
      end;
    end;
  end;
end;

procedure TfrmMtoMenuCaja.FormCreate(Sender: TObject);
begin
  Self.Position := poScreenCenter;
  JvMonthCalendar1.Date := Date;     // forzar mes actual (evita fecha cacheada en DFM)

  Application.ShowHint     := True;
  Application.HintPause    := 500;
  Application.HintHidePause := 5000;
  JvMonthCalendar1.ShowHint       := True;
  JvMonthCalendar1.ParentShowHint := False;
  lblFecha.Caption := FormatDateTime('dddd d mmmm yyyy', Now);

  // Crear el caché ANTES de cualquier cosa que pueda disparar eventos del calendario
  FVentasCal := TVentasCalendarioCache.Create(inLibGlobalVar.oConn);

  if oCajaParams.GetBool('vgerShowCajaSelection', True) then
    AbrirSelectorCaja
  else
  begin
    FEmpresa := oEmpresa;
    FAlmacen := oAlmacen;
    FCaja    := oCaja;
    if (FEmpresa = '') or (FAlmacen = '') or (FCaja = '') then
    begin
      ShowMessage('Error al asignar Empresa Almacén Caja');
      Exit;
    end
    else
    begin
      lblEmpresa.Caption := Format('Empresa %s - Almacén %s - Caja %s',
                                   [FEmpresa, FAlmacen, FCaja]);
      FVentasCal.Reconfigurar(FEmpresa, FAlmacen, FCaja);
    end;
  end;

  // Forzar repintado para que el calendario marque el mes actual con los días con ventas
  JvMonthCalendar1.Invalidate;

  FOriginalF5Color := lblF5.Style.TextColor;
  FOriginalVentasColor := lblVentas.Style.TextColor;
  FOriginalF10Color := lblF10.Style.TextColor;
  FOriginalBuscarModificarColor := lblBuscarModificar.Style.TextColor;
  FOriginalF6Color := lblF6.Style.TextColor;
  FOriginalEntradaCambioColor := lblEntradaCambio.Style.TextColor;
  FOriginalF7Color := lblF7.Style.TextColor;
  FOriginalGastosCajaColor := lblGastosCaja.Style.TextColor;
  FOriginalF11Color := lblF11.Style.TextColor;
  FOriginalArqueoColor := lblArqueo.Style.TextColor;
  FOriginalF3Color := lblF3.Style.TextColor;
  FOriginalTraspasosColor := lblTraspasos.Style.TextColor;
  FFechaCaja := Now;
  FOriginalESCColor := lblESC.Style.TextColor;
  FOriginalSalirColor := lblSalir.Style.TextColor;
end;

procedure TfrmMtoMenuCaja.FormDestroy(Sender: TObject);
begin
  FVentasCal.Free;
end;

procedure TfrmMtoMenuCaja.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_F5:     lblVentasClick(Sender);
    VK_ESCAPE: lblESCClick(Sender);
    VK_F10:    AbrirBuscarModificar;
  end;
end;

procedure TfrmMtoMenuCaja.Timer1Timer(Sender: TObject);
begin
  cxClock1.Time := Now;
end;

procedure TfrmMtoMenuCaja.AbrirBuscarModificar;
var
  frm: TfrmConsultaOpe;
begin
  if (FEmpresa = '') or (FAlmacen = '') or (FCaja = '') then
  begin
    ShowMessage('No hay empresa/almacén/caja asignados. ' +
                'Selecciona una caja antes de buscar operaciones.');
    Exit;
  end;
  frm := TfrmConsultaOpe.Create(Application);
  try
    frm.PrepararValores(FEmpresa, FAlmacen, FCaja, FFechaCaja);
    frm.Show;
  except
    frm.Free;
    raise;
  end;
end;

procedure TfrmMtoMenuCaja.AbrirSelectorCaja;
var
  frm: TfrmMtoModalCajDef;
begin
  frm := TfrmMtoModalCajDef.Create(Self);
  try
    frm.qrySeleccion.Connection := inLibGlobalVar.oConn;
    frm.qrySeleccion.Open;
    frm.sEmpresa := oEmpresa;
    frm.sAlmacen := oAlmacen;
    frm.sCaja    := oCaja;
    frm.ShowModal;
    if (frm.sFicha = 'S') then
    begin
      FEmpresa := frm.qrySeleccion.FieldByName('Empresa').AsString;
      FAlmacen := frm.qrySeleccion.FieldByName('Almacen').AsString;
      FCaja    := frm.qrySeleccion.FieldByName('Caja').AsString;
      lblEmpresa.Caption := Format('Empresa %s - Almacén %s - Caja %s',
                                   [FEmpresa, FAlmacen, FCaja]);
      RecargarCalendario;
    end
    else
      PostMessage(Self.Handle, WM_CLOSE, 0, 0);
  finally
    frm.Free;
  end;
end;

procedure TfrmMtoMenuCaja.Action1Execute(Sender: TObject);
begin
  inherited;
  lblESCClick(Sender);
end;

procedure TfrmMtoMenuCaja.RecargarCalendario;
begin
  // Si el contexto cambió, esto vacía el caché internamente
  FVentasCal.Reconfigurar(FEmpresa, FAlmacen, FCaja);
  JvMonthCalendar1.Invalidate;
end;

procedure TfrmMtoMenuCaja.JvMonthCalendar1GetMonthBoldInfo(Sender: TObject;
  Month, Year: Cardinal; var MonthBoldInfo: Cardinal);
begin
  MonthBoldInfo := FVentasCal.MaskBoldDelMes(Year, Month);
end;

procedure TfrmMtoMenuCaja.JvMonthCalendar1Click(Sender: TObject);
var
  VentaDia: TVentasDia;
begin
  FFechaCaja := JvMonthCalendar1.Date;
  lblFecha.Caption := FormatDateTime('dddd d mmmm yyyy', FFechaCaja);
  // Si quieres mostrar el resumen del día clickado, descomenta:
  // VentaDia := FVentasCal.GetVentasDia(FFechaCaja);
  // if Assigned(VentaDia) then
  //   ShowMessage(VentaDia.GetHintText);
end;

procedure TfrmMtoMenuCaja.JvMonthCalendar1DblClick(Sender: TObject);
begin
  lblFecha.Caption := FormatDateTime('dddd d mmmm yyyy', JvMonthCalendar1.Date);
  FFechaCaja := JvMonthCalendar1.Date;
end;

procedure TfrmMtoMenuCaja.cxButton1Click(Sender: TObject);
begin
  JvMonthCalendar1.Date := Now;
end;

// =============================================================================
// Hover de etiquetas — sin cambios funcionales respecto a tu versión
// =============================================================================

procedure TfrmMtoMenuCaja.ChangeMenuItemColors(FKeyLabel, DescLabel: TcxLabel;
  HoverColor: TColor);
begin
  FKeyLabel.Style.TextColor := HoverColor;
  DescLabel.Style.TextColor := HoverColor;
end;

procedure TfrmMtoMenuCaja.RestoreMenuItemColors(FKeyLabel, DescLabel: TcxLabel;
  OriginalFKeyColor, OriginalDescColor: TColor);
begin
  FKeyLabel.Style.TextColor := OriginalFKeyColor;
  DescLabel.Style.TextColor := OriginalDescColor;
end;

// F5 - Ventas
procedure TfrmMtoMenuCaja.lblVentasClick(Sender: TObject);
var
  frmMtoOpeCaja: TfrmMtoOpeCaja;
begin
  frmMtoOpeCaja := TfrmMtoOpeCaja.Create(Application);
  try
    frmMtoOpeCaja.Tag := 1;
    frmMtoOpeCaja.Caption := Format('Operación 1 - (Caja Real %s)', [Self.FCaja]);
    frmMtoOpeCaja.PrepararValores(Self.FEmpresa, Self.FAlmacen, Self.FCaja,
                                  Self.FFechaCaja);
    frmMtoOpeCaja.Show;
  except
    frmMtoOpeCaja.Free;
  end;
end;

procedure TfrmMtoMenuCaja.lblVentasMouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF5, lblVentas, clBlue);
end;

procedure TfrmMtoMenuCaja.lblVentasMouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF5, lblVentas, FOriginalF5Color, FOriginalVentasColor);
end;

procedure TfrmMtoMenuCaja.lblF5MouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF5, lblVentas, clBlue);
end;

procedure TfrmMtoMenuCaja.lblF5MouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF5, lblVentas, FOriginalF5Color, FOriginalVentasColor);
end;

// F10 - Buscar/Modificar
procedure TfrmMtoMenuCaja.lblBuscarModificarClick(Sender: TObject);
begin
  inherited;
  AbrirBuscarModificar;
end;

procedure TfrmMtoMenuCaja.lblBuscarModificarMouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF10, lblBuscarModificar, clWebOrange);
end;

procedure TfrmMtoMenuCaja.lblBuscarModificarMouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF10, lblBuscarModificar,
                        FOriginalF10Color, FOriginalBuscarModificarColor);
end;

procedure TfrmMtoMenuCaja.lblF10Click(Sender: TObject);
begin
  inherited;
  AbrirBuscarModificar;
end;

procedure TfrmMtoMenuCaja.lblF10MouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF10, lblBuscarModificar, clWebOrange);
end;

procedure TfrmMtoMenuCaja.lblF10MouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF10, lblBuscarModificar,
                        FOriginalF10Color, FOriginalBuscarModificarColor);
end;

// F6 - Entrada de Cambio
procedure TfrmMtoMenuCaja.lblEmpresaDblClick(Sender: TObject);
begin
  if oCajaParams.GetBool('vgerShowCajaSelection', True) then
    AbrirSelectorCaja;
end;

procedure TfrmMtoMenuCaja.lblEntradaCambioMouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF6, lblEntradaCambio, clWebOrange);
end;

procedure TfrmMtoMenuCaja.lblEntradaCambioMouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF6, lblEntradaCambio,
                        FOriginalF6Color, FOriginalEntradaCambioColor);
end;

procedure TfrmMtoMenuCaja.lblF6MouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF6, lblEntradaCambio, clWebOrange);
end;

procedure TfrmMtoMenuCaja.lblF6MouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF6, lblEntradaCambio,
                        FOriginalF6Color, FOriginalEntradaCambioColor);
end;

// F7 - Gastos por Caja
procedure TfrmMtoMenuCaja.lblGastosCajaMouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF7, lblGastosCaja, clWebOrange);
end;

procedure TfrmMtoMenuCaja.lblGastosCajaMouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF7, lblGastosCaja,
                        FOriginalF7Color, FOriginalGastosCajaColor);
end;

procedure TfrmMtoMenuCaja.lblF7MouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF7, lblGastosCaja, clWebOrange);
end;

procedure TfrmMtoMenuCaja.lblF7MouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF7, lblGastosCaja,
                        FOriginalF7Color, FOriginalGastosCajaColor);
end;

// Etiqueta fecha
procedure TfrmMtoMenuCaja.lblFechaMouseEnter(Sender: TObject);
begin
  lblFecha.Style.TextColor := clBlue;
end;

procedure TfrmMtoMenuCaja.lblFechaMouseLeave(Sender: TObject);
begin
  lblFecha.Style.TextColor := clBlack;
end;

// F11 - Arqueo
procedure TfrmMtoMenuCaja.lblArqueoMouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF11, lblArqueo, clWebOrange);
end;

procedure TfrmMtoMenuCaja.lblArqueoMouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF11, lblArqueo,
                        FOriginalF11Color, FOriginalArqueoColor);
end;

procedure TfrmMtoMenuCaja.lblF11MouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF11, lblArqueo, clWebOrange);
end;

procedure TfrmMtoMenuCaja.lblF11MouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF11, lblArqueo,
                        FOriginalF11Color, FOriginalArqueoColor);
end;

// F3 - Traspasos
procedure TfrmMtoMenuCaja.lblTraspasosMouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF3, lblTraspasos, clWebOrange);
end;

procedure TfrmMtoMenuCaja.lblTraspasosMouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF3, lblTraspasos,
                        FOriginalF3Color, FOriginalTraspasosColor);
end;

procedure TfrmMtoMenuCaja.lblF3MouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF3, lblTraspasos, clWebOrange);
end;

procedure TfrmMtoMenuCaja.lblF3MouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF3, lblTraspasos,
                        FOriginalF3Color, FOriginalTraspasosColor);
end;

// ESC - Salir
procedure TfrmMtoMenuCaja.lblSalirMouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblESC, lblSalir, clBlue);
end;

procedure TfrmMtoMenuCaja.lblSalirMouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblESC, lblSalir,
                        FOriginalESCColor, FOriginalSalirColor);
end;

procedure TfrmMtoMenuCaja.lblESCClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMtoMenuCaja.lblESCMouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblESC, lblSalir, clBlue);
end;

procedure TfrmMtoMenuCaja.lblESCMouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblESC, lblSalir,
                        FOriginalESCColor, FOriginalSalirColor);
end;

initialization
  ForceReferenceToClass(TfrmMtoMenuCaja);
end.
