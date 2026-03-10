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
  JvExComCtrls, JvMonthCalendar, cxCalendar, CommCtrl;
type
  TVentasDia = class
  private
    FFecha: TDateTime;
    FTotalVentas: Integer;
    FTotalCobrado: Currency;
  public
    constructor Create(AFecha: TDateTime; ATotalVentas: Integer; ATotalCobrado: Currency);
    property Fecha: TDateTime read FFecha write FFecha;
    property TotalVentas: Integer read FTotalVentas write FTotalVentas;
    property TotalCobrado: Currency read FTotalCobrado write FTotalCobrado;
    function GetHintText: string;
  end;
  TVentasList = class(TList<TVentasDia>)
  public
    function FindByDate(AFecha: TDateTime): TVentasDia;
    function HasSales(AFecha: TDateTime): Boolean;
  end;
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
    JvMonthCalendar1:TJvMonthCalendar;
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    // Eventos para F5 - Ventas
    procedure lblVentasMouseEnter(Sender: TObject);
    procedure lblVentasMouseLeave(Sender: TObject);
    procedure lblF5MouseEnter(Sender: TObject);
    procedure lblF5MouseLeave(Sender: TObject);
    // Eventos para F10 - Buscar/Modificar
    procedure lblBuscarModificarMouseEnter(Sender: TObject);
    procedure lblBuscarModificarMouseLeave(Sender: TObject);
    procedure lblF10MouseEnter(Sender: TObject);
    procedure lblF10MouseLeave(Sender: TObject);
    // Eventos para F6 - Entrada de Cambio
    procedure lblEntradaCambioMouseEnter(Sender: TObject);
    procedure lblEntradaCambioMouseLeave(Sender: TObject);
    procedure lblF6MouseEnter(Sender: TObject);
    procedure lblF6MouseLeave(Sender: TObject);
    // Eventos para F7 - Gastos por Caja
    procedure lblGastosCajaMouseEnter(Sender: TObject);
    procedure lblGastosCajaMouseLeave(Sender: TObject);
    procedure lblF7MouseEnter(Sender: TObject);
    procedure lblF7MouseLeave(Sender: TObject);
    // Eventos para F11 - Arqueo
    procedure lblArqueoMouseEnter(Sender: TObject);
    procedure lblArqueoMouseLeave(Sender: TObject);
    procedure lblF11MouseEnter(Sender: TObject);
    procedure lblF11MouseLeave(Sender: TObject);
    // Eventos para F3 - Traspasos
    procedure lblTraspasosMouseEnter(Sender: TObject);
    procedure lblTraspasosMouseLeave(Sender: TObject);
    procedure lblF3MouseEnter(Sender: TObject);
    procedure lblF3MouseLeave(Sender: TObject);
    //Eventos para ESC - Salir
    procedure lblSalirMouseEnter(Sender: TObject);
    procedure lblSalirMouseLeave(Sender: TObject);
    procedure lblESCMouseEnter(Sender: TObject);
    procedure lblESCMouseLeave(Sender: TObject);
//    procedure JvMonthCalendar1Change(Sender: TObject);
    procedure JvMonthCalendar1GetMonthBoldInfo(Sender: TObject; Month,
      Year: Cardinal; var MonthBoldInfo: Cardinal);
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
//    procedure JvMonthCalendar1GetMonthInfo(Sender: TObject; Month: Cardinal;
//      var MonthBoldInfo: Cardinal);
    procedure JvMonthCalendar1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    VentasList: TVentasList;
    procedure CargarVentasPeriodoVisible(Month, Year: Cardinal);
  private
    // Colores originales para restaurar
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
    FOriginalESCColor:TColor;
    FOriginalSalirColor:TColor;
    FOriginalF3Color: TColor;
    FOriginalTraspasosColor: TColor;
    // Métodos auxiliares para cambiar colores
    procedure ChangeMenuItemColors(FKeyLabel, DescLabel: TcxLabel;
                                   HoverColor: TColor);
    procedure RestoreMenuItemColors(FKeyLabel,
                                    DescLabel: TcxLabel;
                                    OriginalFKeyColor,
                                    OriginalDescColor: TColor);
    procedure AbrirSelectorCaja;
  public
    { Public declarations }
    FFechaCaja:TDateTime;
    //FConfigBD: TConfigBD; // Variable privada que guardará los datos en RAM
    FEmpresa, FAlmacen, FCaja:string;
    //procedure CargarConfiguracionDesdeINI; // Lee el disco SOLO una vez
  public
//    property ConfigBD: TConfigBD read FConfigBD;
    property FechaCaja:TDateTime read FFechaCaja;
  end;
var
  frmMtoMenuCaja: TfrmMtoMenuCaja;
implementation
uses
  inLibGlobalVar, inLibCajaParam, DateUtils;
{$R *.dfm}
procedure ForceReferenceToClass(C: TClass); begin end;
// Asigna este procedimiento al evento OnCloseQuery del formulario del Menú
procedure TfrmMtoMenuCaja.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  i: Integer;
  F: TForm;
begin
  CanClose := True;
  // Recorremos los formularios de la pantalla.
  // IMPORTANTE: Iteramos hacia atrás (downto 0) porque vamos a ir destruyendo
  // formularios y eso altera el índice de Screen.Forms.
  for i := Screen.FormCount - 1 downto 0 do
  begin
    F := Screen.Forms[i];
    // Verificamos si el formulario es del tipo Operación de Caja
    if F is TfrmMtoOpeCaja then
    begin
      // Llamamos a la función que creamos antes
      if not TfrmMtoOpeCaja(F).IntentarCerrar then
      begin
        // Si el usuario dijo "NO" en alguna operación,
        // cancelamos el cierre del menú principal.
        CanClose := False;
        // Opcional: Salimos del bucle si queremos parar a la primera negativa
        Break;
      end;
    end;
  end;
end;
procedure TfrmMtoMenuCaja.FormCreate(Sender: TObject);
var
  FormatSettings: TFormatSettings;
begin
  //CargarConfiguracionDesdeINI;
  //UniConnection1.Connect;
  Self.Position  := poScreenCenter;
  Application.ShowHint := True;
  Application.HintPause := 500;    // Pausa antes de mostrar
  Application.HintHidePause := 5000; // Tiempo visible
  JvMonthCalendar1.ShowHint := True;
  JvMonthCalendar1.ParentShowHint := False;
  lblFecha.Caption := FormatDateTime( 'dddd d mmmm yyyy', Now);
  if oCajaParams.GetBool('vgerShowCajaSelection', True) then
    AbrirSelectorCaja
  else
  begin
    // Tomar directamente los valores del login
    FEmpresa := oEmpresa;
    FAlmacen := oAlmacen;
    FCaja    := oCaja;
    // Si aún así están vacíos, forzar selector como fallback
    if (FEmpresa = '') or (FAlmacen = '') or (FCaja = '') then
    begin
      ShowMessage('Error al asignar Empresa Almacén Caja');
      Exit;
    end
    else
    begin
      lblEmpresa.Caption := Format('Empresa %s - Almacén %s - Caja %s',
                                   [FEmpresa, FAlmacen, FCaja]);
    end;
  end;
//  lblEmpresa.Caption := 'Empresa ' + FEmpresa + ' - '
//                         + 'Almacén ' + FAlmacen + ' - ' + 'Caja ' +
//                         FCaja;
  CargarVentasPeriodoVisible( MonthOf(Now),
                              YearOf(Now));
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
end;
// Eventos para F3 - Traspasos
procedure TfrmMtoMenuCaja.lblTraspasosMouseEnter(Sender: TObject);
begin
  // Usamos clWebOrange para mantener la coherencia con F6, F7, F10, F11
  ChangeMenuItemColors(lblF3, lblTraspasos, clWebOrange);
end;
procedure TfrmMtoMenuCaja.lblTraspasosMouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF3, lblTraspasos, FOriginalF3Color, FOriginalTraspasosColor);
end;
procedure TfrmMtoMenuCaja.lblF3MouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF3, lblTraspasos, clWebOrange);
end;
procedure TfrmMtoMenuCaja.lblF3MouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF3, lblTraspasos, FOriginalF3Color, FOriginalTraspasosColor);
end;
procedure TfrmMtoMenuCaja.FormDestroy(Sender: TObject);
begin
  if Assigned(VentasList) then
    VentasList.Free;
end;
procedure TfrmMtoMenuCaja.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_F5: lblVentasClick(Sender);
    VK_ESCAPE : lblESCClick(Sender);
  end;
end;
procedure TfrmMtoMenuCaja.Timer1Timer(Sender: TObject);
begin
  with cxClock1 do
  begin
    Time := Now;              // Hora actual
  end;
end;
procedure TfrmMtoMenuCaja.AbrirSelectorCaja;
var
  frm: TfrmMtoModalCajDef;
begin
  frm := TfrmMtoModalCajDef.Create(Self);
  try
    // Configuramos la conexión antes de abrir
    frm.qrySeleccion.Connection := inLibGlobalVar.oConn;
    frm.qrySeleccion.Open;
    frm.sEmpresa := oEmpresa;
    frm.sAlmacen := oAlmacen;
    frm.sCaja := oCaja;
    frm.ShowModal;
    if (frm.sFicha = 'S') then
    begin
      // ASIGNACIÓN DE VARIABLES desde el dataset del formulario modal
      FEmpresa := frm.qrySeleccion.FieldByName('Empresa').AsString;
      FAlmacen := frm.qrySeleccion.FieldByName('Almacen').AsString;
      FCaja    := frm.qrySeleccion.FieldByName('Caja').AsString;
      lblEmpresa.Caption := Format('Empresa %s - Almacén %s - Caja %s',
                                  [FEmpresa, FAlmacen, FCaja]);
//      if Assigned(VentasList) then
//        VentasList.Clear;
//      CargarVentasPeriodoVisible;
//      cxDateNavigator1.Invalidate;
    end
    else
      PostMessage(Self.Handle, WM_CLOSE, 0, 0);
  finally
    frm.Free;
  end;
end;

procedure TfrmMtoMenuCaja.CargarVentasPeriodoVisible(Month, Year: Cardinal);
var
  Query: TUniQuery;
  FechaStr: string;
  PrimerDia, UltimoDia: TDateTime;
  VentaDia: TVentasDia;
begin
 if not Assigned(VentasList) then
    VentasList := TVentasList.Create;
 VentasList.Clear; // limpiar antes de recargar

  PrimerDia := EncodeDate(Year, Month, 1);
  UltimoDia := EncodeDate(Year, Month, DaysInAMonth(Year, Month));
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := inLibGlobalVar.oConn; // Tu conexión
    // Consulta para obtener fecha y cantidad de ventas
    Query.SQL.Text :=
      ' SELECT FECHA_FACTURA AS FECHA, ' +
      '        COUNT(*) AS TOTAL_VENTAS, '+
      '               0 AS TOTAL_COBRADO ' +
//      '        SUM(TOTAL_LIQUIDO_FACTURA) AS TOTAL_COBRADO ' +
      '    FROM fza_facturas ' +
      '   WHERE FECHA_FACTURA >= :fecha_inicio ' +
      '     AND FECHA_FACTURA <= :fecha_fin ' +
//      '     AND CODIGO_EMPRESA_FACTURA = :Empresa ' +
//      '     AND TIPO_FACTURA = ''SIMPLIFICADA'' ' +
      'GROUP BY FECHA_FACTURA ' +
      'ORDER BY FECHA_FACTURA ';
//    Query.ParamByName('Empresa').AsString := FEmpresa;
    Query.ParamByName('fecha_inicio').AsDate := PrimerDia;
    Query.ParamByName('fecha_fin').AsDate := UltimoDia;
    Query.Open;
    while not Query.Eof do
    begin
      VentaDia := TVentasDia.Create(
                                   Query.FieldByName('FECHA').AsDateTime,
                                   Query.FieldByName('TOTAL_VENTAS').AsInteger,
                                   Query.FieldByName('TOTAL_COBRADO').AsCurrency
                                   );
      VentasList.Add(VentaDia);
      Query.Next;
    end;
    Query.Close;
  finally
    Query.Free;
  end;
  // Actualizar el calendario para refrescar el bold de los días
  JvMonthCalendar1.Invalidate;
end;

procedure TfrmMtoMenuCaja.ChangeMenuItemColors(FKeyLabel, DescLabel: TcxLabel;
                                      HoverColor: TColor);
begin
  FKeyLabel.Style.TextColor := HoverColor;
  DescLabel.Style.TextColor := HoverColor;
end;

procedure TfrmMtoMenuCaja.cxButton1Click(Sender: TObject);
begin
  JvMonthCalendar1.Date := Now;
end;

procedure TfrmMtoMenuCaja.JvMonthCalendar1GetMonthBoldInfo(Sender: TObject;
  Month, Year: Cardinal; var MonthBoldInfo: Cardinal);
var
  Dia: Integer;
  Fecha: TDateTime;
begin
  CargarVentasPeriodoVisible(Month, Year);
  MonthBoldInfo := 0;
  if not Assigned(VentasList) then
    Exit;
  for Dia := 1 to DaysInAMonth(Year, Month) do
  begin
    Fecha := EncodeDate(Year, Month, Dia);
    if VentasList.HasSales(Fecha) then
      MonthBoldInfo := MonthBoldInfo or (1 shl (Dia - 1));
  end;
end;

procedure TfrmMtoMenuCaja.JvMonthCalendar1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  HitTest: TMCHitTestInfo;
  VentaDia: TVentasDia;
  Fecha: TDateTime;
begin
  ZeroMemory(@HitTest, SizeOf(HitTest));
  HitTest.cbSize := SizeOf(HitTest);
  HitTest.pt.X := X;
  HitTest.pt.Y := Y;

  SendMessage(JvMonthCalendar1.Handle, MCM_HITTEST, 0, LPARAM(@HitTest));

  // MCHT_CALENDARDATE = el cursor está sobre un día concreto
  if (HitTest.uHit and MCHT_CALENDARDATE) <> 0 then
  begin
    Fecha := EncodeDate(HitTest.st.wYear, HitTest.st.wMonth, HitTest.st.wDay);
    if Assigned(VentasList) then
    begin
      VentaDia := VentasList.FindByDate(Fecha);
      if Assigned(VentaDia) then
        JvMonthCalendar1.Hint := VentaDia.GetHintText
      else
        JvMonthCalendar1.Hint := '';
    end;
  end
  else
    JvMonthCalendar1.Hint := '';
end;

// -----------------------------------------------------------------------------
// JvMonthCalendar1DblClick — equivalente a OnDblClick del cxDateNavigator
// -----------------------------------------------------------------------------
procedure TfrmMtoMenuCaja.JvMonthCalendar1DblClick(Sender: TObject);
begin
  lblFecha.Caption := FormatDateTime('dddd d mmmm yyyy', JvMonthCalendar1.Date);
  FFechaCaja := JvMonthCalendar1.Date;
end;
procedure TfrmMtoMenuCaja.RestoreMenuItemColors(FKeyLabel, DescLabel: TcxLabel; OriginalFKeyColor, OriginalDescColor: TColor);
begin
  FKeyLabel.Style.TextColor := OriginalFKeyColor;
  DescLabel.Style.TextColor := OriginalDescColor;
end;
procedure TfrmMtoMenuCaja.lblVentasClick(Sender: TObject);
var
  frmMtoOpeCaja: TfrmMtoOpeCaja;
begin
  frmMtoOpeCaja := TfrmMtoOpeCaja.Create(Application); // Ojo: Owner Application para que no muera al cerrar el menú si fuera necesario
  try
    // INICIALIZACIÓN IMPORTANTE
    frmMtoOpeCaja.Tag := 1; // Esta es la operación 1
    frmMtoOpeCaja.Caption := Format('Operación 1 - (Caja Real %s)', [Self.FCaja]);
    frmMtoOpeCaja.PrepararValores(Self.FEmpresa,
                                  Self.FAlmacen,
                                  Self.FCaja,
                                  Self.FFechaCaja);
    frmMtoOpeCaja.Show;
    // No usamos ShowModal para permitir que existan varias ventanas si fuera necesario interactuar
  except
    frmMtoOpeCaja.Free;
  end;
end;
procedure TfrmMtoMenuCaja.lblVentasMouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF5, lblVentas, clBlue); // Cambiar a azul al pasar el mouse
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
// Eventos para F10 - Buscar/Modificar
procedure TfrmMtoMenuCaja.lblBuscarModificarMouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF10, lblBuscarModificar, clWebOrange);
end;
procedure TfrmMtoMenuCaja.lblBuscarModificarMouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF10, lblBuscarModificar, FOriginalF10Color, FOriginalBuscarModificarColor);
end;
procedure TfrmMtoMenuCaja.lblF10MouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF10, lblBuscarModificar, clWebOrange);
end;
procedure TfrmMtoMenuCaja.lblF10MouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF10, lblBuscarModificar, FOriginalF10Color, FOriginalBuscarModificarColor);
end;
// Eventos para F6 - Entrada de Cambio
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
  RestoreMenuItemColors(lblF6, lblEntradaCambio, FOriginalF6Color, FOriginalEntradaCambioColor);
end;
procedure TfrmMtoMenuCaja.lblF6MouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF6, lblEntradaCambio, clWebOrange);
end;
procedure TfrmMtoMenuCaja.lblF6MouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF6, lblEntradaCambio, FOriginalF6Color, FOriginalEntradaCambioColor);
end;
// Eventos para F7 - Gastos por Caja
procedure TfrmMtoMenuCaja.lblGastosCajaMouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF7, lblGastosCaja, clWebOrange);
end;
procedure TfrmMtoMenuCaja.lblGastosCajaMouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF7, lblGastosCaja, FOriginalF7Color, FOriginalGastosCajaColor);
end;
procedure TfrmMtoMenuCaja.lblF7MouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF7, lblGastosCaja, clWebOrange);
end;
procedure TfrmMtoMenuCaja.lblF7MouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF7, lblGastosCaja, FOriginalF7Color, FOriginalGastosCajaColor);
end;
procedure TfrmMtoMenuCaja.lblFechaMouseEnter(Sender: TObject);
begin
  lblFecha.Style.TextColor := clBlue;
end;
procedure TfrmMtoMenuCaja.lblFechaMouseLeave(Sender: TObject);
begin
  lblFecha.Style.TextColor := clBlack;
end;
// Eventos para F11 - Arqueo
procedure TfrmMtoMenuCaja.lblArqueoMouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF11, lblArqueo, clWebOrange);
end;
procedure TfrmMtoMenuCaja.lblArqueoMouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF11, lblArqueo, FOriginalF11Color, FOriginalArqueoColor);
end;
procedure TfrmMtoMenuCaja.lblF11MouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblF11, lblArqueo, clWebOrange);
end;
procedure TfrmMtoMenuCaja.lblF11MouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblF11, lblArqueo, FOriginalF11Color, FOriginalArqueoColor);
end;
procedure TfrmMtoMenuCaja.lblSalirMouseEnter(Sender: TObject);
begin
  ChangeMenuItemColors(lblESC, lblSalir, clBlue); // Cambiar a azul al pasar el mouse
end;
procedure TfrmMtoMenuCaja.lblSalirMouseLeave(Sender: TObject);
begin
  RestoreMenuItemColors(lblESC,
                        lblSalir,
                        FOriginalESCColor,
                        FOriginalSalirColor);
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
  RestoreMenuItemColors(lblESC,
                              lblSalir, FOriginalESCColor, FOriginalSalirColor);
end;
{ TVentasDia }
constructor TVentasDia.Create(AFecha: TDateTime;
                              ATotalVentas: Integer;
                              ATotalCobrado: Currency);
begin
  inherited Create;
  FFecha := AFecha;
  FTotalVentas := ATotalVentas;
  FTotalCobrado := ATotalCobrado;
end;
function TVentasDia.GetHintText: string;
begin
  Result := Format('Total Ventas: %d' + #13 + 'Total Cobrado: %s €',
                   [FTotalVentas, FormatFloat('#,##0.00', FTotalCobrado)]);
end;
{ TVentasList }
function TVentasList.FindByDate(AFecha: TDateTime): TVentasDia;
var
  I: Integer;
  FechaBuscada: TDateTime;
begin
  Result := nil;
  FechaBuscada := AFecha;
  for I := 0 to Count - 1 do
  begin
    if (Items[I].Fecha = FechaBuscada) then
    begin
      Result := Items[I];
      Exit;
    end;
  end;
end;
function TVentasList.HasSales(AFecha: TDateTime): Boolean;
begin
  Result := FindByDate(AFecha) <> nil;
end;
initialization
  ForceReferenceToClass(TfrmMtoMenuCaja);
end.
