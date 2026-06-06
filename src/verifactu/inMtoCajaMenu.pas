unit inMtoCajaMenu;

interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, JvExControls, JvAnimatedImage,
  JvGIFCtrl, cxLabel, Vcl.ExtCtrls, math, cxStyles, cxSchedulerStorage,
  cxSchedulerCustomControls, cxSchedulerDateNavigator, cxDateNavigator,
  cxCalendar, UniProvider, MySQLUniProvider, Data.DB, DBAccess, Uni, Vcl.Menus,
  Vcl.StdCtrls, cxButtons;

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

  TfrmMtoMenuCaja = class(TForm)
    lblF5: TcxLabel;
    lblF10: TcxLabel;
    lblBuscarModificar: TcxLabel;
    lblVentas: TcxLabel;
    Shape1: TShape;
    cxClock1: TcxClock;
    cxDateNavigator1: TcxDateNavigator;
    Timer1: TTimer;
    lblF6: TcxLabel;
    lblEntradaCambio: TcxLabel;
    lblF7: TcxLabel;
    lblGastosCaja: TcxLabel;
    lblArqueo: TcxLabel;
    lblF11: TcxLabel;
    JvGIFAnimator1: TJvGIFAnimator;
    lblSalir: TcxLabel;
    lblESC: TcxLabel;
    lblFecha: TcxLabel;
    cxButton1: TcxButton;
    cxLabel1: TcxLabel;
    cxLabel2: TcxLabel;
    cxLabel3: TcxLabel;
    Shape2: TShape;
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
    //Eventos para ESC - Salir
    procedure lblSalirMouseEnter(Sender: TObject);
    procedure lblSalirMouseLeave(Sender: TObject);
    procedure lblESCMouseEnter(Sender: TObject);
    procedure lblESCMouseLeave(Sender: TObject);

    procedure cxDateNavigator1CustomDrawDayNumber(Sender: TObject;
      ACanvas: TcxCanvas; AViewInfo: TcxSchedulerDateNavigatorDayNumberViewInfo;
      var ADone: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure lblESCClick(Sender: TObject);
    procedure cxDateNavigator1PeriodChanged(Sender: TObject; const AStart,
      AFinish: TDateTime);
    procedure cxDateNavigator1ShowDateHint(Sender: TObject;
      const ADate: TDateTime; var AHintText: string; var AAllow: Boolean);
    procedure lblFechaMouseEnter(Sender: TObject);
    procedure lblFechaMouseLeave(Sender: TObject);
    procedure cxDateNavigator1DblClick(Sender: TObject);
    procedure cxButton1Click(Sender: TObject);
  //FECHAS SOMBREADAS
  private
    VentasList: TVentasList;
    procedure CargarVentasPeriodoVisible;
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
    // Métodos auxiliares para cambiar colores
    procedure ChangeMenuItemColors(FKeyLabel, DescLabel: TcxLabel;
                                   HoverColor: TColor);
    procedure RestoreMenuItemColors(FKeyLabel,
                                    DescLabel: TcxLabel;
                                    OriginalFKeyColor,
                                    OriginalDescColor: TColor);
  public
    { Public declarations }
  end;

var
  frmMtoMenuCaja: TfrmMtoMenuCaja;

implementation

uses
  UniDataCaja;
{$R *.dfm}

procedure TfrmMtoMenuCaja.FormCreate(Sender: TObject);
begin
  //REFERENTE A LOS SOMBREADOS DE FECHAS

  Application.ShowHint := True;
  Application.HintPause := 500;    // Pausa antes de mostrar
  Application.HintHidePause := 5000; // Tiempo visible

  cxDateNavigator1.ShowHint := True;
  cxDateNavigator1.ParentShowHint := False;
  lblFecha.Caption := FormatDateTime( 'dddd d mmmm yyyy', Now);
  CargarVentasPeriodoVisible;
  //referente a los  CAMBIOS DE COLOR
  // Guardar los colores originales
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
end;

procedure TfrmMtoMenuCaja.FormDestroy(Sender: TObject);
begin
  if Assigned(VentasList) then
    FreeAndNil(VentasList);
end;

procedure TfrmMtoMenuCaja.Timer1Timer(Sender: TObject);
begin
  with cxClock1 do
  begin
    Time := Now;              // Hora actual
  end;
end;

// Métodos auxiliares
procedure TfrmMtoMenuCaja.CargarVentasPeriodoVisible;
var
  Query: TUniQuery;
  FechaStr: string;
  PrimerDia, UltimoDia: TDateTime;
  VentaDia: TVentasDia;
begin
 if not Assigned(VentasList) then
    VentasList := TVentasList.Create;
  // Calcular primer y último día del mes
  PrimerDia := cxDateNavigator1.RealFirstDate;
  UltimoDia := cxDateNavigator1.RealLastDate;
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := dmDataCaja.UniConnection1; // Tu conexión
    // Consulta para obtener fecha y cantidad de ventas
    Query.SQL.Text :=
      ' SELECT FECHA, '+
      '        TOTAL_VENTAS, '+
      '        TOTAL_COBRADO ' +
      '    FROM vi_caja_totalventas ' +
      '   WHERE FECHA_FAC >= :fecha_inicio ' +
      '     AND FECHA_FAC <= :fecha_fin ';
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
    FreeAndNil(Query);
  end;
  // Actualizar el navegador
  cxDateNavigator1.Invalidate;
end;

procedure TfrmMtoMenuCaja.ChangeMenuItemColors(FKeyLabel, DescLabel: TcxLabel;
                                      HoverColor: TColor);
begin
  FKeyLabel.Style.TextColor := HoverColor;
  DescLabel.Style.TextColor := HoverColor;
end;

procedure TfrmMtoMenuCaja.cxButton1Click(Sender: TObject);
begin
  cxDateNavigator1.Date := Now;
end;

procedure TfrmMtoMenuCaja.cxDateNavigator1CustomDrawDayNumber(Sender: TObject;
  ACanvas: TcxCanvas; AViewInfo: TcxSchedulerDateNavigatorDayNumberViewInfo;
  var ADone: Boolean);
begin
    // Obtener la fecha exacta directamente del ViewInfo
  if Assigned(VentasList) and VentasList.HasSales(AViewInfo.Date) then
  begin
    ACanvas.Brush.Color := clDkGray;
    ACanvas.Font.Color := clWhite;
    ACanvas.Font.Style := [fsBold];
    ACanvas.FillRect(AViewInfo.Bounds);
    ACanvas.DrawText(AViewInfo.Text, AViewInfo.Bounds,
                     cxAlignCenter or cxAlignVCenter);
    ADone := True;
  end;
end;

procedure TfrmMtoMenuCaja.cxDateNavigator1DblClick(Sender: TObject);
begin
  lblFecha.Caption := FormatDateTime('dddd d mmmm yyyy',
                                     cxDateNavigator1.Date);
end;

procedure TfrmMtoMenuCaja.cxDateNavigator1PeriodChanged(Sender: TObject; const AStart,
  AFinish: TDateTime);
begin
  CargarVentasPeriodoVisible;
end;

procedure TfrmMtoMenuCaja.cxDateNavigator1ShowDateHint(Sender: TObject;
  const ADate: TDateTime; var AHintText: string; var AAllow: Boolean);
var
  VentaDia: TVentasDia;
begin
  AHintText := '';
  if Assigned(VentasList) then
  begin
    VentaDia := VentasList.FindByDate(ADate);
    if Assigned(VentaDia) then
    begin
      AHintText := VentaDia.GetHintText;
      AAllow := True;
    end;
  end;
end;

procedure TfrmMtoMenuCaja.RestoreMenuItemColors(FKeyLabel, DescLabel: TcxLabel; OriginalFKeyColor, OriginalDescColor: TColor);
begin
  FKeyLabel.Style.TextColor := OriginalFKeyColor;
  DescLabel.Style.TextColor := OriginalDescColor;
end;

// Eventos para F5 - Ventas
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
  RestoreMenuItemColors(lblESC, lblSalir, FOriginalESCColor, FOriginalSalirColor);
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
  RestoreMenuItemColors(lblESC, lblSalir, FOriginalESCColor, FOriginalSalirColor);
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
  FechaBuscada := AFecha; // Solo la parte de fecha, sin hora
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

end.
