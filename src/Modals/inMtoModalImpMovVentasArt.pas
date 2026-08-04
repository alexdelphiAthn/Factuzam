{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpMovVentasArt                                     }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresión del "Movimientos de ventas por artículos y fechas"     }
{    (ranking de ventas, FastReport). Una fila por artículo (o por             }
{    artículo+almacén si se agrupa por almacén) con las magnitudes de compra   }
{    (entradas) y venta del periodo y dos márgenes: Margen 1 (sobre lo         }
{    vendido) y Margen 2 (contando todo lo comprado como gasto). Mantiene la   }
{    foto del artículo. Se apoya en el SP PRC_GET_MOV_VENTAS_ART (ver          }
{    DESARROLLOS EN CURSO/movimientos_ventas_articulos.sql).                   }
{                                                                              }
{    Hereda de TfrmPrintMultiFiltro: reutiliza las pestañas de filtros         }
{    múltiples (almacenes / familias / proveedores / temporadas / artículos /  }
{    fechas) y la de agrupaciones. Solo añade la fecha extra "Inicio compras"  }
{    (filtra los artículos por su primera compra), la plantilla del informe y  }
{    la consulta.                                                              }
{******************************************************************************}
unit inMtoModalImpMovVentasArt;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.DateUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs,
  inMtoModalImpMultiFiltro, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, frxDesgn, Data.DB, MemDS, DBAccess, Uni,
  frxExportXLSX, frxClass, frxDBSet, frxExportBaseDialog, frxExportPDF,
  Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, cxControls, cxContainer, cxEdit,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxLabel, cxRadioGroup,
  cxCheckListBox, cxCheckBox, cxCustomListBox,
  cxClasses, dxSkinsForm, System.Actions, Vcl.ActnList, frxSmartMemo,
  frLocalization, frLanguageSpanish, frCoreClasses,
  frxExportBaseImageSettingsDialog, JvComponentBase, JvEnterTab, cxLocalization,
  inLibInformeMovimientosVentasArticuloPersistenciaIntf;

type
  TfrmPrintMovVentasArt = class(TfrmPrintMultiFiltro)
    fxdsMovVentas: TfrxDBDataset;
  private
    FInicializado: Boolean;
    FRepositorioMovimientos:
      IRepositorioInformeMovimientosVentasArticulo;
    FResultadoMovimientos: IResultadoInformeMovimientosVentasArticulo;
    FchkIniCompras: TcxCheckBox;   // activa el filtro de inicio de compras
    // fecha de primera compra a partir de la cual
    FdteIniCompras: TcxDateEdit;
    FchkSoloVentas: TcxCheckBox;   // 'solo artículos con ventas' en el periodo
    // Crea el control de "Inicio compras" sobre la pestaña de fechas.
    procedure CrearControlesPropios;
    procedure chkIniComprasChange(Sender: TObject);
    // Exportación a Excel propia (sustituye al export FastReport del base).
    procedure ExportarExcelMovVentas(Sender: TObject);
    // Handler de OnBeforePrint: fotos + ocultar bandas de grupo inactivas.
    procedure ReportBeforePrint(Component: TfrxReportComponent);
    // Precarga en bloque las fotos de los artículos del resultado (1 consulta).
    procedure PrecargarFotosArticulos;
  protected
    function FiltrosUsados: TFiltrosReport; override;
    procedure DoShow; override;
  public
    destructor Destroy; override;
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
  end;

implementation

{$R *.dfm}

uses
  System.StrUtils, inMtoPreviewExcel, inLibMovVentasArtExcel,
  inLibMsgVentas,
  inLibHojaCalculoIntf, inLibHojaCalculoDevEx, dxSpreadSheet,
  inLibFotos, UniDataInformeMovimientosVentasArticuloRepositorio;

{ TfrmPrintMovVentasArt }

function TfrmPrintMovVentasArt.FiltrosUsados: TFiltrosReport;
begin
  Result := [frFechas, frAlmacenes, frFamilias, frProveedores, frTemporadas,
             frArticulos];
end;

procedure TfrmPrintMovVentasArt.DoShow;
begin
  inherited;
  if not FInicializado then
  begin
    CrearControlesPropios;
    // El botón Excel del base exporta el FastReport a XLSX (farragoso); lo
    // redirigimos a una exportación limpia con el mismo layout que el informe.
    btnExcel.OnClick := ExportarExcelMovVentas;
    FInicializado := True;
  end;
end;

procedure TfrmPrintMovVentasArt.CrearControlesPropios;
begin
  if TabFechas <> nil then
  begin
    // Por defecto el ranking mira las ventas del AÑO en curso (no del mes):
    // las entradas son de siempre, así que un periodo corto deja casi todo a
    // cero. El base pone el 1 del mes; aquí lo ampliamos al 1 de enero.
    if DteDesde <> nil then
      DteDesde.Date := EncodeDate(YearOf(Date), 1, 1);
    // "Inicio compras": filtra los artículos por su primera entrada (AC/AE).
    // El check permite desactivarlo (sin filtro = todos los que tengan
    // actividad). Arranca DESMARCADO para no ocultar artículos sin querer.
    FchkIniCompras := TcxCheckBox.Create(Self);
    FchkIniCompras.Parent    := TabFechas;
    FchkIniCompras.Left      := 220;
    FchkIniCompras.Top       := 16;
    FchkIniCompras.Width     := 210;
    FchkIniCompras.Caption   := SCaptionFiltrarInicioCompras;
    FchkIniCompras.Properties.OnEditValueChanged := chkIniComprasChange;
    FdteIniCompras := TcxDateEdit.Create(Self);
    FdteIniCompras.Parent  := TabFechas;
    FdteIniCompras.Left    := 220;
    FdteIniCompras.Top     := 40;
    FdteIniCompras.Width   := 160;
    FdteIniCompras.Date    := EncodeDate(YearOf(Date), 1, 1);
    FdteIniCompras.Enabled := False;
    // "Solo artículos con ventas": oculta los que solo tienen entradas (lo
    // típico de un ranking de ventas). Arranca DESMARCADO = salen todos.
    FchkSoloVentas := TcxCheckBox.Create(Self);
    FchkSoloVentas.Parent  := TabFechas;
    FchkSoloVentas.Left    := 220;
    FchkSoloVentas.Top     := 72;
    FchkSoloVentas.Width   := 210;
    FchkSoloVentas.Caption := SCaptionSoloArticulosConVentas;
  end;
  // Pestaña "Agrupaciones": almacén/proveedor/familia/temporada reordenables
  // + spin de nivel de familia (igual que el balance de almacén).
  CrearTabAgrupacion('Agrupaciones',
    ['ALM', 'PRV', 'FAM', 'TMP'],
    ['Almacén', 'Proveedor', 'Familia', 'Temporada'], True);
end;

procedure TfrmPrintMovVentasArt.chkIniComprasChange(Sender: TObject);
begin
  if FdteIniCompras <> nil then
    FdteIniCompras.Enabled := (FchkIniCompras <> nil)
      and (FchkIniCompras.Checked);
end;

procedure TfrmPrintMovVentasArt.preparar_consulta;
var
  criterios: TCriteriosInformeMovimientosVentasArticulo;
  niveles: TArray<string>;
  function NivelN(idx: Integer): string;
  begin
    if (idx >= 0) and (idx < Length(niveles)) then
      Result := niveles[idx]
    else
      Result := '';
  end;
begin
  inherited;
  niveles := NivelesAgrupacion;
  criterios.FechaDesde := FechaDesde;
  criterios.FechaHasta := FechaHasta;
  criterios.UsarInicioCompras := (FchkIniCompras <> nil) and
    FchkIniCompras.Checked and (FdteIniCompras <> nil);
  if criterios.UsarInicioCompras then
    criterios.InicioCompras := FdteIniCompras.Date;
  criterios.Almacenes := CSVAlmacenes;
  criterios.Familias := CSVFamilias;
  criterios.Proveedores := CSVProveedores;
  criterios.Temporadas := CSVTemporadas;
  criterios.Articulos := CSVArticulos;
  criterios.Nivel1 := NivelN(0);
  criterios.Nivel2 := NivelN(1);
  criterios.Nivel3 := NivelN(2);
  criterios.NivelFamilia := NivelFamilia;
  criterios.SoloVentas := (FchkSoloVentas <> nil) and
    FchkSoloVentas.Checked;
  if FRepositorioMovimientos = nil then
    FRepositorioMovimientos :=
      CrearRepositorioInformeMovimientosVentasArticuloUniDAC(
        ConexionPrincipal);
  FResultadoMovimientos := FRepositorioMovimientos.Preparar(criterios);
  fxdsMovVentas.UpdateBounds;
end;

procedure TfrmPrintMovVentasArt.AfterReportLoaded;
begin
  inherited;
  // La foto necesita el DataSet directo del TfrxDBDataset (no solo el
  // DataSource): ver inLibFotos.ObtenerDataSetDeBandaPadre.
  fxdsMovVentas.DataSet := FResultadoMovimientos.DataSet;
  frxrprt1.DataSets.Clear;
  frxrprt1.DataSets.Add(fxdsMovVentas);
  // Sustituimos el OnBeforePrint del base (fotos) por el nuestro, que encadena
  // las fotos y oculta las bandas de grupo de los niveles inactivos.
  frxrprt1.OnBeforePrint := ReportBeforePrint;
  // Precarga de fotos a nivel artículo en UNA consulta (evita el N+1).
  PrecargarFotosArticulos;
end;

destructor TfrmPrintMovVentasArt.Destroy;
begin
  FotosArticulos.LimpiarPrecargaFotos;
  inherited Destroy;
end;

procedure TfrmPrintMovVentasArt.PrecargarFotosArticulos;
var
  slCod: TStringList;
begin
  if (FResultadoMovimientos <> nil) and
     FResultadoMovimientos.DataSet.Active and
     (not FResultadoMovimientos.DataSet.IsEmpty) then
  begin
    slCod := TStringList.Create;
    try
      slCod.Sorted := True;
      slCod.Duplicates := dupIgnore;
      FResultadoMovimientos.DataSet.DisableControls;
      try
        FResultadoMovimientos.DataSet.First;
        while not FResultadoMovimientos.DataSet.Eof do
        begin
          slCod.Add(FResultadoMovimientos.DataSet.FieldByName(
            'CODIGO_ART_ART').AsString);
          FResultadoMovimientos.DataSet.Next;
        end;
      finally
        FResultadoMovimientos.DataSet.EnableControls;
      end;
      FotosArticulos.PrecargarFotosLote(slCod.ToStringArray);
    finally
      FreeAndNil(slCod);
    end;
  end;
end;

procedure TfrmPrintMovVentasArt.ReportBeforePrint(
  Component: TfrxReportComponent);
var
  sNom : string;
  nivel: Integer;
begin
  FotosArticulos.HandlerReportBeforePrint(Component);
  if Component is TfrxBand then
  begin
    sNom := Component.Name;
    nivel := 0;
    if (Pos('GroupHeaderG', sNom) = 1) or (Pos('GroupFooterG', sNom) = 1) then
      nivel := StrToIntDef(Copy(sNom, Length(sNom), 1), 0);
    if (nivel >= 1) and (nivel <= 3) and
       (FResultadoMovimientos <> nil) and
       FResultadoMovimientos.DataSet.Active then
      TfrxBand(Component).Visible :=
        FResultadoMovimientos.DataSet.FieldByName(
          Format('GRUPO%d_ETIQ', [nivel])).AsString <> ''
    else if (sNom = 'GroupHeaderFam') or (sNom = 'GroupFooterFam') then
      // La familia NO agrupa por sí sola: solo se agrupa por familia si se
      // elige FAM en la pestaña Agrupaciones (sale como "Familia: ...").
      TfrxBand(Component).Visible := False;
  end;
end;

procedure TfrmPrintMovVentasArt.ExportarExcelMovVentas(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
  oServiciosHoja: TServiciosHojaCalculo;
begin
  preparar_consulta;
  Self.Hide;
  try
    fPreview := TfrmMtoPreviewExcel.Create(Self);
    try
      fPreview.DialogoGuardar.InitialDir :=
        ParametrosApp.GetPath('appDirExcel');
      fPreview.DialogoGuardar.FileName := 'Movimientos_ventas_articulos';
      oServiciosHoja := CrearServiciosHojaCalculoDevEx(
        fPreview.dxSpreadSheet1);
      ExportarMovVentasArtExcel(
        oServiciosHoja.Escritor,
        oServiciosHoja.Formateador,
        FResultadoMovimientos.DataSet);
      fPreview.ShowModal;
    finally
      FreeAndNil(fPreview);
    end;
  finally
    Self.Show;
  end;
end;

end.
