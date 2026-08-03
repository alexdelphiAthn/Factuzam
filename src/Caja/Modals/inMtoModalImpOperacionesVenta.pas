{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpOperacionesVenta                                 }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.2.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Listado de operaciones de venta del TPV, agrupado por fecha y caja.       }
{    Detalla artículos, variantes, importes, vendedor y formas de pago.        }
{******************************************************************************}
unit inMtoModalImpOperacionesVenta;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.DateUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Data.DB,
  inMtoModalGenImp, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  cxControls, cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  cxCalendar, cxLabel, cxButtons, cxClasses, cxLocalization, cxPC,
  cxCheckListBox, cxCheckBox, dxSkinsForm, dxCore, frxClass, frxDBSet,
  frxDesgn, frxExportXLSX,
  frxExportBaseDialog, frxExportPDF, frxSmartMemo, frLocalization,
  frLanguageSpanish, frxExportBaseImageSettingsDialog, frCoreClasses,
  JvComponentBase, JvEnterTab, Vcl.Menus, System.Actions, Vcl.ActnList,
  inLibInformesCajaPersistenciaIntf, UniDataCajaPantallaComposicion;

type
  TfrmPrintOperacionesVenta = class(TfrmPrint)
    pcOpciones: TcxPageControl;
    tsUbicaciones: TcxTabSheet;
    lblFechas: TcxLabel;
    lblDesde: TcxLabel;
    dteDesde: TcxDateEdit;
    lblHasta: TcxLabel;
    dteHasta: TcxDateEdit;
    lblContexto: TcxLabel;
    lblEmpresa: TcxLabel;
    edtEmpresa: TcxTextEdit;
    lblAlmacen: TcxLabel;
    edtAlmacen: TcxTextEdit;
    lblCaja: TcxLabel;
    edtCaja: TcxTextEdit;
    lblUbicaciones: TcxLabel;
    clbUbicaciones: TcxCheckListBox;
    btnMarcarTodas: TcxButton;
    btnDesmarcarTodas: TcxButton;
    dsVentasPrint: TDataSource;
    fxdsVentas: TfrxDBDataset;
    procedure btnMarcarTodasClick(Sender: TObject);
    procedure btnDesmarcarTodasClick(Sender: TObject);
  private
    FAlmacenesUbicacion: TStringList;
    FCajasUbicacion: TStringList;
    FEmpresasUbicacion: TStringList;
    FInicializado: Boolean;
    FRestringido: Boolean;
    FRepositorioPersistencia: IRepositorioInformesCaja;
    FResultado: IResultadoInformeCaja;
    FDatos: TDataSet;
    procedure ComponerDependencias;
    procedure AsegurarUbicacionSeleccionada;
    procedure CargarUbicaciones;
    function ConstruirSolicitud:
      TSolicitudOperacionesVentaCaja;
    function HexAColor(const AHex: string; out AColor: TColor): Boolean;
    function NumeroUbicacionesMarcadas: Integer;
  protected
    procedure DoShow; override;
    procedure ReportBeforePrintConColor(
      Component: TfrxReportComponent);
  public
    procedure AfterReportLoaded; override;
    procedure preparar_consulta; override;
    destructor Destroy; override;
  end;

implementation

uses
  inLibFiltroUsuario, inLibMsgCaja;

{$R *.dfm}

{ TfrmPrintOperacionesVenta }

procedure TfrmPrintOperacionesVenta.AsegurarUbicacionSeleccionada;
var
  i: Integer;
begin
  if not FRestringido then
  begin
    if NumeroUbicacionesMarcadas = 0 then
    begin
      for i := 0 to clbUbicaciones.Items.Count - 1 do
      begin
        if SameText(
             FEmpresasUbicacion[i],
             UbicacionSesion.Empresa) and
           SameText(
             FAlmacenesUbicacion[i],
             UbicacionSesion.Almacen) and
           SameText(
             FCajasUbicacion[i],
             UbicacionSesion.Caja) then
          clbUbicaciones.Items[i].State := cbsChecked;
      end;
    end;
    if (NumeroUbicacionesMarcadas = 0) and
       (clbUbicaciones.Items.Count > 0) then
      clbUbicaciones.Items[0].State := cbsChecked;
  end;
end;

procedure TfrmPrintOperacionesVenta.AfterReportLoaded;
begin
  inherited;
  frxrprt1.OnBeforePrint := ReportBeforePrintConColor;
end;

procedure TfrmPrintOperacionesVenta.btnDesmarcarTodasClick(
  Sender: TObject);
var
  i: Integer;
begin
  inherited;
  for i := 0 to clbUbicaciones.Items.Count - 1 do
    clbUbicaciones.Items[i].State := cbsUnchecked;
end;

procedure TfrmPrintOperacionesVenta.btnMarcarTodasClick(Sender: TObject);
var
  i: Integer;
begin
  inherited;
  for i := 0 to clbUbicaciones.Items.Count - 1 do
    clbUbicaciones.Items[i].State := cbsChecked;
end;

procedure TfrmPrintOperacionesVenta.CargarUbicaciones;
var
  Ubicaciones: TUbicacionesInformeCaja;
  Ubicacion: TUbicacionInformeCaja;
  item: TcxCheckListBoxItem;
  sAlmacen: string;
  sCaja: string;
  sEmpresa: string;
begin
  if FEmpresasUbicacion = nil then
    FEmpresasUbicacion := TStringList.Create;
  if FAlmacenesUbicacion = nil then
    FAlmacenesUbicacion := TStringList.Create;
  if FCajasUbicacion = nil then
    FCajasUbicacion := TStringList.Create;
  clbUbicaciones.Items.BeginUpdate;
  try
    clbUbicaciones.Items.Clear;
    FEmpresasUbicacion.Clear;
    FAlmacenesUbicacion.Clear;
    FCajasUbicacion.Clear;
    Ubicaciones := FRepositorioPersistencia.ListarUbicaciones;
    for Ubicacion in Ubicaciones do
    begin
      sEmpresa := Ubicacion.Empresa;
      sAlmacen := Ubicacion.Almacen;
      sCaja := Ubicacion.Caja;
      item := clbUbicaciones.Items.Add;
      item.Text := Format(
        '%s - %s  |  %s - %s  |  %s - %s',
        [sEmpresa, Ubicacion.NombreEmpresa,
         sAlmacen, Ubicacion.NombreAlmacen,
         sCaja, Ubicacion.NombreCaja]);
      item.State := cbsUnchecked;
      if SameText(sEmpresa, UbicacionSesion.Empresa) and
         SameText(sAlmacen, UbicacionSesion.Almacen) and
         SameText(sCaja, UbicacionSesion.Caja) then
      begin
        item.State := cbsChecked;
      end;
      FEmpresasUbicacion.Add(sEmpresa);
      FAlmacenesUbicacion.Add(sAlmacen);
      FCajasUbicacion.Add(sCaja);
    end;
  finally
    clbUbicaciones.Items.EndUpdate;
  end;
  AsegurarUbicacionSeleccionada;
end;

destructor TfrmPrintOperacionesVenta.Destroy;
begin
  FreeAndNil(FEmpresasUbicacion);
  FreeAndNil(FAlmacenesUbicacion);
  FreeAndNil(FCajasUbicacion);
  inherited;
end;

procedure TfrmPrintOperacionesVenta.DoShow;
begin
  inherited;
  ComponerDependencias;
  if not FInicializado then
  begin
    dteDesde.Date := EncodeDate(YearOf(Date), 1, 1);
    dteHasta.Date := Date;
    edtEmpresa.Text := UbicacionSesion.Empresa;
    edtAlmacen.Text := UbicacionSesion.Almacen;
    edtCaja.Text := UbicacionSesion.Caja;
    FRestringido := RestriccionEmpAlmCajaActiva(
      ContextoSesion,
      ParametrosApp);
    pcOpciones.Visible := not FRestringido;
    tsUbicaciones.TabVisible := not FRestringido;
    if FRestringido then
    begin
      ClientWidth := 341;
      lblContexto.Caption := SCaptionTpvRestringido;
    end
    else
    begin
      ClientWidth := 900;
      pcOpciones.ActivePage := tsUbicaciones;
      CargarUbicaciones;
    end;
    FInicializado := True;
  end;
end;

procedure TfrmPrintOperacionesVenta.ComponerDependencias;
var
  oComposicion: TComposicionCajaPantalla;
begin
  if not Assigned(FRepositorioPersistencia) then
  begin
    oComposicion := ComponerCajaPantalla(Self);
    FRepositorioPersistencia := oComposicion.Informes.
      CrearRepositorioInformesCaja;
  end;
end;

function TfrmPrintOperacionesVenta.HexAColor(
  const AHex: string;
  out AColor: TColor): Boolean;
var
  nAzul: Integer;
  nRojo: Integer;
  nVerde: Integer;
  sHex: string;
begin
  Result := False;
  sHex := Trim(AHex);
  if Copy(sHex, 1, 1) = '#' then
    Delete(sHex, 1, 1);
  if Length(sHex) = 6 then
  begin
    Result :=
      TryStrToInt('$' + Copy(sHex, 1, 2), nRojo) and
      TryStrToInt('$' + Copy(sHex, 3, 2), nVerde) and
      TryStrToInt('$' + Copy(sHex, 5, 2), nAzul);
    if Result then
      AColor := RGB(nRojo, nVerde, nAzul);
  end;
end;

function TfrmPrintOperacionesVenta.NumeroUbicacionesMarcadas: Integer;
var
  i: Integer;
begin
  Result := 0;
  if clbUbicaciones <> nil then
    for i := 0 to clbUbicaciones.Items.Count - 1 do
      if clbUbicaciones.Items[i].State = cbsChecked then
        Inc(Result);
end;

procedure TfrmPrintOperacionesVenta.preparar_consulta;
begin
  inherited;
  if dteDesde.Date <= 0 then
    dteDesde.Date := EncodeDate(YearOf(Date), 1, 1);
  if dteHasta.Date <= 0 then
    dteHasta.Date := Date;
  if dteHasta.Date < dteDesde.Date then
    dteHasta.Date := dteDesde.Date;
  AsegurarUbicacionSeleccionada;
  dsVentasPrint.DataSet := nil;
  FDatos := nil;
  FResultado := FRepositorioPersistencia.ConsultarOperacionesVenta(
    ConstruirSolicitud);
  FDatos := FResultado.DataSet;
  dsVentasPrint.DataSet := FDatos;
  fxdsVentas.UpdateBounds;
end;

function TfrmPrintOperacionesVenta.ConstruirSolicitud:
  TSolicitudOperacionesVentaCaja;
var
  i: Integer;
begin
  Result.FechaDesde := Trunc(dteDesde.Date);
  Result.FechaHasta := Trunc(dteHasta.Date);
  SetLength(Result.Ubicaciones, 0);
  if FRestringido or (NumeroUbicacionesMarcadas = 0) then
  begin
    SetLength(Result.Ubicaciones, 1);
    Result.Ubicaciones[0].Empresa := UbicacionSesion.Empresa;
    Result.Ubicaciones[0].Almacen := UbicacionSesion.Almacen;
    Result.Ubicaciones[0].Caja := UbicacionSesion.Caja;
  end
  else
  begin
    for i := 0 to clbUbicaciones.Items.Count - 1 do
    begin
      if clbUbicaciones.Items[i].State = cbsChecked then
      begin
        SetLength(
          Result.Ubicaciones,
          Length(Result.Ubicaciones) + 1);
        Result.Ubicaciones[High(Result.Ubicaciones)].Empresa :=
          FEmpresasUbicacion[i];
        Result.Ubicaciones[High(Result.Ubicaciones)].Almacen :=
          FAlmacenesUbicacion[i];
        Result.Ubicaciones[High(Result.Ubicaciones)].Caja :=
          FCajasUbicacion[i];
      end;
    end;
  end;
end;

procedure TfrmPrintOperacionesVenta.ReportBeforePrintConColor(
  Component: TfrxReportComponent);
var
  ColorBasico: TColor;
  MemoColorBasico: TfrxMemoView;
begin
  ReportBeforePrintConQR(Component);
  if (Component <> nil) and
     SameText(Component.Name, 'MemoColorBasico') and
     (Component is TfrxMemoView) then
  begin
    MemoColorBasico := TfrxMemoView(Component);
    if Assigned(FDatos) and
       HexAColor(
         FDatos.FieldByName('HEX_COLOR_BASICO').AsString,
         ColorBasico) then
      MemoColorBasico.Color := ColorBasico
    else
      MemoColorBasico.Color := clWhite;
  end;
end;

end.
