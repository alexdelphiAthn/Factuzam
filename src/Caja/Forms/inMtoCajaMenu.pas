{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaMenu                                                 }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Menu principal del modulo de caja (TPV).                                  }
{    Acceso a ventas, arqueo, gastos, entrada de cambio y calendario.          }
{******************************************************************************}
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
  Vcl.StdCtrls, cxButtons, inMtoCajaOpe, inMtoTraspasoOpe, UniDataTraspaso,
  system.IOUtils, system.IniFiles,
  inMtoModalCajDef, JvTFManager, JvTFGlance, JvTFMonths, Vcl.ComCtrls,
  JvExComCtrls, JvMonthCalendar, cxCalendar, CommCtrl,
  inLibVentasCalendario, System.Actions, Vcl.ActnList, dxGDIPlusClasses, cxImage;

type
  TfrmMtoMenuCaja = class(TfrmBase)
    lblF5: TcxLabel;
    lblF10: TcxLabel;
    lblBuscarModificar: TcxLabel;
    lblVentas: TcxLabel;
    shpFondo: TShape;
    clkHora: TcxClock;
    tmrReloj: TTimer;
    lblF6: TcxLabel;
    lblEntradaCambio: TcxLabel;
    lblF7: TcxLabel;
    lblGastosCaja: TcxLabel;
    lblArqueo: TcxLabel;
    lblF11: TcxLabel;
    lblSalir: TcxLabel;
    lblESC: TcxLabel;
    lblFecha: TcxLabel;
    shpSeparador: TShape;
    lblF3: TcxLabel;
    lblTraspasos: TcxLabel;
    gifAnimador: TJvGIFAnimator;
    lblEmpresa: TcxLabel;
    calMes: TJvMonthCalendar;
    alCajaMenu: TActionList;
    actSalirMenu: TAction;
    cxImage1: TcxImage;
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
    procedure lblEntradaCambioClick(Sender: TObject);
    procedure lblEntradaCambioMouseEnter(Sender: TObject);
    procedure lblEntradaCambioMouseLeave(Sender: TObject);
    procedure lblF6MouseEnter(Sender: TObject);
    procedure lblF6MouseLeave(Sender: TObject);
    // Eventos F7
    procedure lblGastosCajaClick(Sender: TObject);
    procedure lblGastosCajaMouseEnter(Sender: TObject);
    procedure lblGastosCajaMouseLeave(Sender: TObject);
    procedure lblF7MouseEnter(Sender: TObject);
    procedure lblF7MouseLeave(Sender: TObject);
    // Eventos F11
    procedure lblArqueoClick(Sender: TObject);
    procedure lblArqueoMouseEnter(Sender: TObject);
    procedure lblArqueoMouseLeave(Sender: TObject);
    procedure lblF11MouseEnter(Sender: TObject);
    procedure lblF11MouseLeave(Sender: TObject);
    // Eventos F3
    procedure lblTraspasosClick(Sender: TObject);
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
    procedure JvMonthCalendar1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormDestroy(Sender: TObject);
    procedure lblESCClick(Sender: TObject);
    procedure lblFechaMouseEnter(Sender: TObject);
    procedure lblFechaMouseLeave(Sender: TObject);
    procedure cxButton1Click(Sender: TObject);
    procedure lblVentasClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure lblEmpresaDblClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShortCut(var Msg: TWMKey; var Handled: Boolean);
    procedure JvMonthCalendar1Click(Sender: TObject);
    procedure lblBuscarModificarClick(Sender: TObject);
    procedure lblF10Click(Sender: TObject);
    procedure Action1Execute(Sender: TObject);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  private
    type
      TMenuItem = record
        KeyLabel: TcxLabel;
        DescLabel: TcxLabel;
        HoverColor: TColor;
        OriginalKeyColor: TColor;
        OriginalDescColor: TColor;
      end;
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
    FUltimoTickReloj: TDateTime;
    // Navegación por teclado
    FMenuItems: array of TMenuItem;
    FSelectedIndex: Integer;
    procedure ChangeMenuItemColors(FKeyLabel, DescLabel: TcxLabel;
                                   HoverColor: TColor);
    procedure RestoreMenuItemColors(FKeyLabel, DescLabel: TcxLabel;
                                    OriginalFKeyColor,
                                    OriginalDescColor: TColor);
    procedure InitMenuItems;
    procedure SetSelectedIndex(NewIndex: Integer);
    procedure ExecuteSelectedItem;
    procedure AbrirSelectorCaja;
    procedure RecargarCalendario;
    procedure clkHoraDblClick(Sender: TObject);
  public
    FFechaCaja: TDateTime;
    FEmpresa, FAlmacen, FCaja: string;
    procedure ActualizarFechaCaja(AFechaCaja: TDateTime);
    property FechaCaja: TDateTime read FFechaCaja;
  end;

var
  frmMtoMenuCaja: TfrmMtoMenuCaja;

implementation

uses
  inLibGlobalVar, inLibCajaParam, inLibPermisosIntf,
  DateUtils, inMtoConsultaOpe, inMtoPrincipal,
  inMtoModalArqueo, inMtoModalEntradaCambio, inMtoModalGastoCaja;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoMenuCaja.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.ExStyle   := Params.ExStyle or WS_EX_APPWINDOW;
  Params.WndParent := 0;
end;

procedure TfrmMtoMenuCaja.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  frmMtoMenuCaja := nil;
  if Assigned(frmMtoPrincipal) and
     (frmMtoPrincipal.WindowState = wsMinimized) then
    frmMtoPrincipal.WindowState := wsMaximized;
end;

procedure TfrmMtoMenuCaja.FormCloseQuery(Sender: TObject;
                                         var CanClose: Boolean);
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
  // forzar mes actual (evita fecha cacheada en DFM)
  calMes.Date := Date;

  Application.ShowHint     := True;
  Application.HintPause    := 500;
  Application.HintHidePause := 5000;
  calMes.ShowHint       := True;
  calMes.ParentShowHint := False;
  lblFecha.Caption := FormatDateTime('dddd d mmmm yyyy', Now);
  // Permiso: si no puede cambiar fecha, deshabilitar calendario
  if (not Assigned(Permisos)) or
     (not Permisos.TienePermiso(
       PERMISO_CAJA_CAMBIAR_FECHA,
       paPermitir)) then
    calMes.Enabled := False;
  // Crear el caché ANTES de cualquier cosa que pueda disparar eventos del
  // calendario
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

  // Forzar repintado para que el calendario marque el mes actual con los días
  // con ventas
  calMes.Invalidate;

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
  ActualizarFechaCaja(Now);
  clkHora.OnDblClick := clkHoraDblClick;
  FOriginalESCColor := lblESC.Style.TextColor;
  FOriginalSalirColor := lblSalir.Style.TextColor;

  InitMenuItems;
  FSelectedIndex := -1;
  SetSelectedIndex(0);
end;

procedure TfrmMtoMenuCaja.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FVentasCal);
end;

procedure TfrmMtoMenuCaja.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_F3:     lblTraspasosClick(Sender);
    VK_F5:     lblVentasClick(Sender);
    VK_F6:     lblEntradaCambioClick(Sender);
    VK_F7:     lblGastosCajaClick(Sender);
    VK_ESCAPE: lblESCClick(Sender);
    VK_F10:    AbrirBuscarModificar;
    VK_F11:    lblArqueoClick(Sender);
  end;
end;

procedure TfrmMtoMenuCaja.FormShortCut(var Msg: TWMKey; var Handled: Boolean);
begin
  // OnShortCut se dispara antes que el OnKeyDown del control con foco, así
  // que el calendario u otros controles no se quedan con las flechas/Enter.
  case Msg.CharCode of
    VK_UP:
      begin
        SetSelectedIndex(FSelectedIndex - 1);
        Handled := True;
      end;
    VK_DOWN:
      begin
        SetSelectedIndex(FSelectedIndex + 1);
        Handled := True;
      end;
    VK_RETURN:
      begin
        ExecuteSelectedItem;
        Handled := True;
      end;
  end;
end;

procedure TfrmMtoMenuCaja.ActualizarFechaCaja(AFechaCaja: TDateTime);
begin
  if AFechaCaja = 0 then
    AFechaCaja := Now;
  FFechaCaja := AFechaCaja;
  FUltimoTickReloj := Now;
  calMes.Date := DateOf(FFechaCaja);
  lblFecha.Caption := FormatDateTime('dddd d mmmm yyyy', FFechaCaja);
  clkHora.Time := FFechaCaja;
end;

procedure TfrmMtoMenuCaja.Timer1Timer(Sender: TObject);
var
  dtAhora: TDateTime;
begin
  dtAhora := Now;
  if FUltimoTickReloj = 0 then
    FUltimoTickReloj := dtAhora;
  if FFechaCaja = 0 then
    FFechaCaja := dtAhora;
  FFechaCaja := FFechaCaja + (dtAhora - FUltimoTickReloj);
  FUltimoTickReloj := dtAhora;
  clkHora.Time := FFechaCaja;
  lblFecha.Caption := FormatDateTime('dddd d mmmm yyyy', FFechaCaja);
end;

procedure TfrmMtoMenuCaja.clkHoraDblClick(Sender: TObject);
var
  sHora: string;
  dtHora: TDateTime;
  dtFechaBase: TDateTime;
begin
  dtFechaBase := FFechaCaja;
  if dtFechaBase = 0 then
    dtFechaBase := Now;
  sHora := FormatDateTime('hh:nn', dtFechaBase);
  if InputQuery('Hora de caja', 'Hora (HH:MM)', sHora) then
  begin
    if TryStrToTime(sHora, dtHora) then
      ActualizarFechaCaja(DateOf(dtFechaBase) + Frac(dtHora))
    else
      ShowMessage('Hora no válida. Use HH:MM.');
  end
  else
    ActualizarFechaCaja(Now);
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
  frm := TfrmConsultaOpe.Create(Application, Permisos);
  try
    frm.PopupParent := Self;
    frm.PrepararValores(FEmpresa, FAlmacen, FCaja, FFechaCaja);
    frm.Show;
  except
    FreeAndNil(frm);
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
    // Cierra el cronometro del monitor SQL antes del ShowModal (vease
    // TdmConn.CerrarSQLPendiente). La instancia viva es odmConn: la
    // variable global dmConn de UniDataConn no se asigna nunca.
    if Assigned(odmConn) then
      odmConn.CerrarSQLPendiente;
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
    FreeAndNil(frm);
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
  calMes.Invalidate;
end;

procedure TfrmMtoMenuCaja.JvMonthCalendar1GetMonthBoldInfo(Sender: TObject;
  Month, Year: Cardinal; var MonthBoldInfo: Cardinal);
begin
  MonthBoldInfo := FVentasCal.MaskBoldDelMes(Year, Month);
end;

procedure TfrmMtoMenuCaja.JvMonthCalendar1Click(Sender: TObject);
begin
  ActualizarFechaCaja(DateOf(calMes.Date) + Frac(FFechaCaja));
  // Si quieres mostrar el resumen del día clickado, descomenta:
  // VentaDia := FVentasCal.GetVentasDia(FFechaCaja);
  // if Assigned(VentaDia) then
  //   ShowMessage(VentaDia.GetHintText);
end;

procedure TfrmMtoMenuCaja.JvMonthCalendar1DblClick(Sender: TObject);
begin
  ActualizarFechaCaja(DateOf(calMes.Date) + Frac(FFechaCaja));
end;

procedure TfrmMtoMenuCaja.JvMonthCalendar1KeyDown(Sender: TObject;
                                                  var Key: Word;
  Shift: TShiftState);
begin
  // El calendario reclama las flechas y Enter al nivel de Win32, así que las
  // capturamos aquí para que la navegación del menú funcione aun con el foco
  // sobre él. Key := 0 evita además que el calendario las procese.
  case Key of
    VK_UP:
      begin
        SetSelectedIndex(FSelectedIndex - 1);
        Key := 0;
      end;
    VK_DOWN:
      begin
        SetSelectedIndex(FSelectedIndex + 1);
        Key := 0;
      end;
    VK_RETURN:
      begin
        ExecuteSelectedItem;
        Key := 0;
      end;
  end;
end;

procedure TfrmMtoMenuCaja.cxButton1Click(Sender: TObject);
begin
  calMes.Date := Now;
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

// =============================================================================
// Navegación por teclado: Up / Down resaltan, Enter ejecuta el OnClick
// =============================================================================

procedure TfrmMtoMenuCaja.InitMenuItems;

  procedure AddItem(Idx: Integer; KeyLbl, DescLbl: TcxLabel;
                    OrigKey, OrigDesc, Hover: TColor);
  begin
    FMenuItems[Idx].KeyLabel         := KeyLbl;
    FMenuItems[Idx].DescLabel        := DescLbl;
    FMenuItems[Idx].HoverColor       := Hover;
    FMenuItems[Idx].OriginalKeyColor := OrigKey;
    FMenuItems[Idx].OriginalDescColor:= OrigDesc;
  end;

begin
  SetLength(FMenuItems, 7);
  AddItem(0, lblF5, lblVentas, FOriginalF5Color, FOriginalVentasColor, clBlue);
  AddItem(1,
          lblF10,
          lblBuscarModificar,
          FOriginalF10Color,
          FOriginalBuscarModificarColor,
          clBlue);
  AddItem(2,
          lblF6,
          lblEntradaCambio,
          FOriginalF6Color,
          FOriginalEntradaCambioColor,
          clWebOrange);
  AddItem(3,
          lblF7,
          lblGastosCaja,
          FOriginalF7Color,
          FOriginalGastosCajaColor,
          clWebOrange);
  AddItem(4,
          lblF11,
          lblArqueo,
          FOriginalF11Color,
          FOriginalArqueoColor,
          clWebOrange);
  AddItem(5,
          lblF3,
          lblTraspasos,
          FOriginalF3Color,
          FOriginalTraspasosColor,
          clWebOrange);
  AddItem(6, lblESC, lblSalir, FOriginalESCColor, FOriginalSalirColor, clBlue);
end;

procedure TfrmMtoMenuCaja.SetSelectedIndex(NewIndex: Integer);
var
  Cnt: Integer;
begin
  Cnt := Length(FMenuItems);
  if Cnt = 0 then Exit;

  // Wrap circular: -1 va al último, Cnt vuelve al primero
  NewIndex := ((NewIndex mod Cnt) + Cnt) mod Cnt;
  if NewIndex = FSelectedIndex then Exit;

  if (FSelectedIndex >= 0) and (FSelectedIndex < Cnt) then
    RestoreMenuItemColors(FMenuItems[FSelectedIndex].KeyLabel,
                          FMenuItems[FSelectedIndex].DescLabel,
                          FMenuItems[FSelectedIndex].OriginalKeyColor,
                          FMenuItems[FSelectedIndex].OriginalDescColor);

  FSelectedIndex := NewIndex;

  ChangeMenuItemColors(FMenuItems[FSelectedIndex].KeyLabel,
                       FMenuItems[FSelectedIndex].DescLabel,
                       FMenuItems[FSelectedIndex].HoverColor);
end;

procedure TfrmMtoMenuCaja.ExecuteSelectedItem;
var
  Item: TMenuItem;
begin
  if (FSelectedIndex < 0) or (FSelectedIndex >= Length(FMenuItems)) then Exit;
  Item := FMenuItems[FSelectedIndex];
  if Assigned(Item.DescLabel.OnClick) then
    Item.DescLabel.OnClick(Item.DescLabel)
  else if Assigned(Item.KeyLabel.OnClick) then
    Item.KeyLabel.OnClick(Item.KeyLabel);
end;

// F5 - Ventas
procedure TfrmMtoMenuCaja.lblVentasClick(Sender: TObject);
var
  frmMtoOpeCaja: TfrmMtoOpeCaja;
begin
  frmMtoOpeCaja := TfrmMtoOpeCaja.Create(Application, Permisos);
  try
    frmMtoOpeCaja.PopupParent := Self;
    frmMtoOpeCaja.Tag := 1;
    frmMtoOpeCaja.Caption := Format('Operación 1 - (Caja Real %s)',
                                    [Self.FCaja]);
    frmMtoOpeCaja.PrepararValores(Self.FEmpresa, Self.FAlmacen, Self.FCaja,
                                  Self.FFechaCaja);
    frmMtoOpeCaja.Show;
  except
    FreeAndNil(frmMtoOpeCaja);
  end;
end;

procedure TfrmMtoMenuCaja.lblVentasMouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF5, lblVentas, clBlue);
end;

procedure TfrmMtoMenuCaja.lblVentasMouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF5,
                        lblVentas,
                        FOriginalF5Color,
                        FOriginalVentasColor);
end;

procedure TfrmMtoMenuCaja.lblF5MouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF5, lblVentas, clBlue);
end;

procedure TfrmMtoMenuCaja.lblF5MouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF5,
                        lblVentas,
                        FOriginalF5Color,
                        FOriginalVentasColor);
end;

// F10 - Buscar/Modificar
procedure TfrmMtoMenuCaja.lblBuscarModificarClick(Sender: TObject);
begin
  inherited;
  AbrirBuscarModificar;
end;

procedure TfrmMtoMenuCaja.lblBuscarModificarMouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF10, lblBuscarModificar, clBlue);
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
  ChangeMenuItemColors(lblF10, lblBuscarModificar, clBlue);
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

procedure TfrmMtoMenuCaja.lblEntradaCambioClick(Sender: TObject);
begin
  TfrmModalEntradaCambio.Ejecutar(Self, oConn,
    FEmpresa, FAlmacen, FCaja, FFechaCaja);
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
procedure TfrmMtoMenuCaja.lblGastosCajaClick(Sender: TObject);
begin
  TfrmModalGastoCaja.Ejecutar(Self, oConn,
    FEmpresa, FAlmacen, FCaja, FFechaCaja);
end;

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
procedure TfrmMtoMenuCaja.lblArqueoClick(Sender: TObject);
begin
  if (FEmpresa = '') or (FAlmacen = '') or (FCaja = '') then
  begin
    ShowMessage('No hay empresa/almacén/caja asignados. ' +
                'Selecciona una caja antes de hacer arqueo.');
    Exit;
  end;
  TfrmModalArqueo.Ejecutar(Self,
                           inLibGlobalVar.oConn,
                           FEmpresa,
                           FAlmacen,
                           FCaja,
                           DateOf(FFechaCaja),
                           DateOf(FFechaCaja));
end;

procedure TfrmMtoMenuCaja.lblArqueoMouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF11, lblArqueo, clBlue);
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
procedure TfrmMtoMenuCaja.lblTraspasosClick(Sender: TObject);
var
  frmTraspaso: TfrmMtoOpeTraspaso;
begin
  if (FEmpresa = '') or (FAlmacen = '') or (FCaja = '') then
    ShowMessage('No hay empresa/almacén/caja asignados. ' +
                'Selecciona una caja antes de hacer traspasos.')
  else
  begin
    frmTraspaso := TfrmMtoOpeTraspaso.Create(Application, Permisos);
    try
      frmTraspaso.PopupParent := Self;
      frmTraspaso.Caption := Format('Traspasos - (Almacén %s · Caja %s)',
                                    [Self.FAlmacen, Self.FCaja]);
      frmTraspaso.PrepararValores(mtTraspaso, Self.FEmpresa, Self.FAlmacen,
                                  Self.FCaja, Self.FFechaCaja);
      frmTraspaso.Show;
    except
      FreeAndNil(frmTraspaso);
    end;
  end;
end;

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
