{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoComparativaMovimientos                                   }
{    Tipo:       Formulario (Cuadro de mando / BI)                             }
{ Versión:       1.1.0                                                         }
{   Fecha:       14/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Comparativa de dos periodos interanuales sobre un mismo rango de fechas.  }
{    El usuario elige un rango (p.ej. 01/01 a 31/01) y la pantalla dibuja dos  }
{    series solapadas: el periodo elegido de este año y el mismo rango del año }
{    anterior. La magnitud puede ser Ventas facturadas (€) — sobre            }
{    fza_facturas_lineas — o métricas de fza_movimientos_almacen (coste,       }
{    unidades o número de movimientos). El eje X se agrupa por día, semana o   }
{    mes y se puede filtrar por almacén, familia y temporada.                  }
{    Sólo lectura: usa la conexión global oConn con consultas bajo demanda.    }
{******************************************************************************}
unit inMtoComparativaMovimientos;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.DateUtils, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls,
  Data.DB, MemDS, DBAccess, Uni,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxClasses, cxContainer, cxEdit, cxLabel, cxTextEdit, cxButtons, cxMaskEdit,
  cxDropDownEdit, cxCalendar, cxDateUtils, dxCore,
  JvComponentBase, JvEnterTab, cxLocalization,
  VCLTee.TeEngine, VCLTee.Series, VCLTee.TeeProcs, VCLTee.Chart,
  inMtoFrmBase, inLibGlobalVar;

type
  TfrmMtoComparativaMovimientos = class(TfrmBase)
    pnlTop: TPanel;
    lblDesde: TcxLabel;
    dteFechaDesde: TcxDateEdit;
    lblHasta: TcxLabel;
    dteFechaHasta: TcxDateEdit;
    lblMagnitud: TcxLabel;
    cboMagnitud: TcxComboBox;
    lblAgrupacion: TcxLabel;
    cboAgrupacion: TcxComboBox;
    btnComparar: TcxButton;
    lblAlmacen: TcxLabel;
    cboAlmacen: TcxComboBox;
    lblFamilia: TcxLabel;
    cboFamilia: TcxComboBox;
    lblTemporada: TcxLabel;
    cboTemporada: TcxComboBox;
    pnlResumen: TPanel;
    lblTotActualTit: TcxLabel;
    lblTotActual: TcxLabel;
    lblTotAnteriorTit: TcxLabel;
    lblTotAnterior: TcxLabel;
    lblVariacionTit: TcxLabel;
    lblVariacion: TcxLabel;
    pnlChart: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCompararClick(Sender: TObject);
    procedure dteFechaDesdePropertiesChange(Sender: TObject);
  private
    FChart: TChart;
    FSerieActual: TLineSeries;
    FSerieAnterior: TLineSeries;
    FCodAlmacenes: TStringList;
    FCodFamilias: TStringList;
    FCodTemporadas: TStringList;
    procedure CrearGrafico;
    procedure CargarCombos;
    procedure CargarCombo(ACombo: TcxComboBox; ALista: TStringList;
                          const ASQL: string);
    function CodigoFiltro(ACombo: TcxComboBox; ALista: TStringList): string;
    procedure Comparar;
    function NumeroBuckets(AD1, AD2: TDate): Integer;
    function SQLConsulta: string;
    function CargarDatos(AD1, AD2: TDate; ACount: Integer;
                         out ATotal: Double): TArray<Double>;
    function EtiquetaBucket(AD1: TDate; AIndice: Integer): string;
    function FormataValor(AValor: Double): string;
  end;

implementation

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

// =============================================================================
//   Ciclo de vida
// =============================================================================

procedure TfrmMtoComparativaMovimientos.FormCreate(Sender: TObject);
begin
  inherited;
  FCodAlmacenes := TStringList.Create;
  FCodFamilias := TStringList.Create;
  FCodTemporadas := TStringList.Create;
  // Magnitudes: orden por utilidad de negocio (ventas primero)
  cboMagnitud.Properties.DropDownListStyle := lsFixedList;
  cboMagnitud.Properties.Items.Clear;
  cboMagnitud.Properties.Items.Add('Ventas facturadas (€)');
  cboMagnitud.Properties.Items.Add('Coste movido (€)');
  cboMagnitud.Properties.Items.Add('Unidades movidas');
  cboMagnitud.Properties.Items.Add('Nº de movimientos');
  cboMagnitud.ItemIndex := 0;
  // Agrupación del eje X
  cboAgrupacion.Properties.DropDownListStyle := lsFixedList;
  cboAgrupacion.Properties.Items.Clear;
  cboAgrupacion.Properties.Items.Add('Día');
  cboAgrupacion.Properties.Items.Add('Semana');
  cboAgrupacion.Properties.Items.Add('Mes');
  cboAgrupacion.ItemIndex := 0;
  // Filtros: se rellenan desde la BBDD (primer elemento siempre "(Todos)")
  cboAlmacen.Properties.DropDownListStyle := lsFixedList;
  cboFamilia.Properties.DropDownListStyle := lsFixedList;
  cboTemporada.Properties.DropDownListStyle := lsFixedList;
  CargarCombos;
  // Por defecto: mes en curso del año actual
  dteFechaDesde.Date := StartOfTheMonth(Date);
  dteFechaHasta.Date := Date;
  CrearGrafico;
end;

procedure TfrmMtoComparativaMovimientos.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FCodAlmacenes);
  FreeAndNil(FCodFamilias);
  FreeAndNil(FCodTemporadas);
  inherited;
end;

procedure TfrmMtoComparativaMovimientos.CrearGrafico;
begin
  // El TChart se crea en código para evitar serializar series en el .dfm
  FChart := TChart.Create(Self);
  FChart.Parent := pnlChart;
  FChart.Align := alClient;
  FChart.BevelOuter := bvNone;
  FChart.View3D := False;
  FChart.Title.Text.Text := 'Comparativa de periodos';
  FChart.Legend.Visible := True;
  FSerieActual := TLineSeries.Create(FChart);
  FSerieActual.SeriesColor := clBlue;
  FSerieActual.LinePen.Width := 2;
  FSerieActual.Pointer.Visible := True;
  FChart.AddSeries(FSerieActual);
  FSerieAnterior := TLineSeries.Create(FChart);
  FSerieAnterior.SeriesColor := clRed;
  FSerieAnterior.LinePen.Width := 2;
  FSerieAnterior.Pointer.Visible := True;
  FChart.AddSeries(FSerieAnterior);
end;

// =============================================================================
//   Combos de filtro
// =============================================================================

procedure TfrmMtoComparativaMovimientos.CargarCombos;
begin
  CargarCombo(cboAlmacen, FCodAlmacenes,
    'SELECT CODIGO_ALM_ALM AS COD,' +
    '       COALESCE(NULLIF(NOMBRE_ALM_ALM, ''''), CODIGO_ALM_ALM) AS NOMBRE' +
    '  FROM fza_almacenes ORDER BY NOMBRE');
  CargarCombo(cboFamilia, FCodFamilias,
    'SELECT CODIGO_FAM_FAM AS COD,' +
    '       COALESCE(NULLIF(NOMBRE_FAM_FAM, ''''), CODIGO_FAM_FAM) AS NOMBRE' +
    '  FROM fza_articulos_familias WHERE ESACTIVO_FAM = ''S''' +
    ' ORDER BY NOMBRE');
  CargarCombo(cboTemporada, FCodTemporadas,
    'SELECT DISTINCT TEMPORADA_ART AS COD, TEMPORADA_ART AS NOMBRE' +
    '  FROM fza_articulos' +
    ' WHERE TEMPORADA_ART IS NOT NULL AND TEMPORADA_ART <> ''''' +
    ' ORDER BY TEMPORADA_ART');
end;

// Rellena un combo con un primer elemento "(Todos)" (código vacío) y, a
// continuación, las filas de ASQL (columnas COD y NOMBRE). La lista paralela
// guarda los códigos alineados por índice con los items del combo.
procedure TfrmMtoComparativaMovimientos.CargarCombo(ACombo: TcxComboBox;
  ALista: TStringList; const ASQL: string);
var
  qry: TUniQuery;
begin
  ACombo.Properties.Items.Clear;
  ALista.Clear;
  ACombo.Properties.Items.Add('(Todos)');
  ALista.Add('');
  if (oConn <> nil) and oConn.Connected then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := oConn;
      qry.SQL.Text := ASQL;
      qry.Open;
      while not qry.Eof do
      begin
        ACombo.Properties.Items.Add(qry.FieldByName('NOMBRE').AsString);
        ALista.Add(qry.FieldByName('COD').AsString);
        qry.Next;
      end;
      qry.Close;
    finally
      FreeAndNil(qry);
    end;
  end;
  ACombo.ItemIndex := 0;
end;

// Código seleccionado en un combo de filtro ('' = "(Todos)", sin filtro)
function TfrmMtoComparativaMovimientos.CodigoFiltro(ACombo: TcxComboBox;
  ALista: TStringList): string;
begin
  if (ACombo.ItemIndex > 0) and (ACombo.ItemIndex < ALista.Count) then
    Result := ALista[ACombo.ItemIndex]
  else
    Result := '';
end;

// =============================================================================
//   Lógica de comparación
// =============================================================================

procedure TfrmMtoComparativaMovimientos.btnCompararClick(Sender: TObject);
begin
  inherited;
  Comparar;
end;

procedure TfrmMtoComparativaMovimientos.dteFechaDesdePropertiesChange(
  Sender: TObject);
begin
  inherited;
  // "Hasta" nunca puede quedar antes que "Desde"
  if dteFechaHasta.Date < dteFechaDesde.Date then
    dteFechaHasta.Date := dteFechaDesde.Date;
end;

procedure TfrmMtoComparativaMovimientos.Comparar;
var
  dD1Act, dD2Act, dD1Ant, dD2Ant: TDate;
  iN, i: Integer;
  arrAct, arrAnt: TArray<Double>;
  dTotAct, dTotAnt, dVar: Double;
begin
  if (oConn = nil) or (not oConn.Connected) then
    Application.MessageBox('No hay conexión con la base de datos.',
                           'Comparativa', MB_OK or MB_ICONWARNING)
  else
  begin
    Screen.Cursor := crHourGlass;
    try
      dD1Act := DateOf(dteFechaDesde.Date);
      dD2Act := DateOf(dteFechaHasta.Date);
      if dD2Act < dD1Act then
        dD2Act := dD1Act;
      // Mismo rango exacto del año anterior
      dD1Ant := IncYear(dD1Act, -1);
      dD2Ant := IncYear(dD2Act, -1);
      iN := NumeroBuckets(dD1Act, dD2Act);
      arrAct := CargarDatos(dD1Act, dD2Act, iN, dTotAct);
      arrAnt := CargarDatos(dD1Ant, dD2Ant, iN, dTotAnt);
      FSerieActual.Clear;
      FSerieAnterior.Clear;
      FSerieActual.Title := 'Periodo ' + IntToStr(YearOf(dD1Act));
      FSerieAnterior.Title := 'Periodo ' + IntToStr(YearOf(dD1Ant));
      // Las etiquetas del eje se toman del periodo actual; la serie anterior
      // se solapa por índice de bucket (mismo desplazamiento desde su inicio)
      for i := 0 to iN - 1 do
      begin
        FSerieActual.Add(arrAct[i], EtiquetaBucket(dD1Act, i));
        FSerieAnterior.Add(arrAnt[i], '');
      end;
      FChart.Title.Text.Text := cboMagnitud.Text;
      lblTotActual.Caption := FormataValor(dTotAct);
      lblTotAnterior.Caption := FormataValor(dTotAnt);
      // Variación interanual del total del rango
      if dTotAnt <> 0 then
      begin
        dVar := (dTotAct - dTotAnt) / dTotAnt * 100;
        lblVariacion.Caption := FormatFloat('+0.0;-0.0', dVar) + ' %';
        if dVar >= 0 then
          lblVariacion.Style.TextColor := clGreen
        else
          lblVariacion.Style.TextColor := clRed;
      end
      else
      begin
        lblVariacion.Caption := 'n/d';
        lblVariacion.Style.TextColor := clWindowText;
      end;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

// Número de buckets del eje X según la agrupación, derivado del rango actual.
// El mismo valor se reutiliza para el periodo anterior, garantizando series
// alineadas punto a punto.
function TfrmMtoComparativaMovimientos.NumeroBuckets(AD1, AD2: TDate): Integer;
var
  iDias, iMeses: Integer;
begin
  iDias := Trunc(AD2) - Trunc(AD1);
  if iDias < 0 then
    iDias := 0;
  case cboAgrupacion.ItemIndex of
    1: Result := (iDias div 7) + 1;
    2:
      begin
        iMeses := (YearOf(AD2) * 12 + MonthOf(AD2)) -
                  (YearOf(AD1) * 12 + MonthOf(AD1));
        Result := iMeses + 1;
      end;
  else
    Result := iDias + 1;
  end;
end;

// Construye el SELECT agrupado según magnitud, agrupación y filtros. Devuelve
// dos columnas: BUCKET (desplazamiento entero desde :pD1) y VALOR (agregado).
// Las ventas se calculan a nivel de línea (fza_facturas_lineas) para poder
// segmentar por familia/temporada; el resto sale de fza_movimientos_almacen.
function TfrmMtoComparativaMovimientos.SQLConsulta: string;
var
  bVentas, bArtJoin: Boolean;
  sFecha, sAgg, sFrom, sBucket, sWhere: string;
begin
  bVentas := (cboMagnitud.ItemIndex = 0);
  bArtJoin := (CodigoFiltro(cboFamilia, FCodFamilias) <> '') or
              (CodigoFiltro(cboTemporada, FCodTemporadas) <> '');
  if bVentas then
  begin
    sFecha := 'f.FECHA_FAC';
    sAgg := 'COALESCE(SUM(l.TOTAL_FACLIN), 0)';
    sFrom := ' FROM fza_facturas_lineas l' +
             ' JOIN fza_facturas f' +
             '   ON f.NUMERO_FAC = l.NUMERO_FAC_FACLIN' +
             '  AND f.SERIE_FAC = l.SERIE_FAC_FACLIN';
    if bArtJoin then
      sFrom := sFrom +
             ' LEFT JOIN fza_articulos a' +
             '   ON a.CODIGO_ART_ART = l.CODIGO_ART_FACLIN';
    sWhere := ' WHERE ' + sFecha + ' >= :pD1' +
              '   AND ' + sFecha + ' < DATE_ADD(:pD2, INTERVAL 1 DAY)';
    if CodigoFiltro(cboAlmacen, FCodAlmacenes) <> '' then
      sWhere := sWhere + '   AND l.CODIGO_ALM_FACLIN = :pALM';
  end
  else
  begin
    sFecha := 'm.FECHA_MOV';
    case cboMagnitud.ItemIndex of
      1: sAgg := 'COALESCE(SUM(m.TOTAL_COSTE_MOV), 0)';
      2: sAgg := 'COALESCE(SUM(m.CANTIDAD_MOV), 0)';
    else
      sAgg := 'COUNT(*)';
    end;
    sFrom := ' FROM fza_movimientos_almacen m';
    if bArtJoin then
      sFrom := sFrom +
             ' LEFT JOIN fza_articulos_skus s' +
             '   ON s.CODIGO_UNIDAD_SKU = m.CODIGO_UNIDAD_MOV' +
             ' LEFT JOIN fza_articulos a' +
             '   ON a.CODIGO_ART_ART =' +
             '      COALESCE(m.CODIGO_ARTICULO_MOV, s.CODIGO_ART_SKU)';
    sWhere := ' WHERE m.ESACTIVO_MOV = ''S''' +
              '   AND ' + sFecha + ' >= :pD1' +
              '   AND ' + sFecha + ' < DATE_ADD(:pD2, INTERVAL 1 DAY)';
    if CodigoFiltro(cboAlmacen, FCodAlmacenes) <> '' then
      sWhere := sWhere + '   AND m.CODIGO_ALMACEN_MOV = :pALM';
  end;
  if CodigoFiltro(cboFamilia, FCodFamilias) <> '' then
    sWhere := sWhere + '   AND a.CODIGO_FAM_ART = :pFAM';
  if CodigoFiltro(cboTemporada, FCodTemporadas) <> '' then
    sWhere := sWhere + '   AND a.TEMPORADA_ART = :pTEMP';
  case cboAgrupacion.ItemIndex of
    1: sBucket := 'FLOOR(DATEDIFF(' + sFecha + ', :pD1) / 7)';
    2: sBucket := 'PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM ' + sFecha +
                  '), EXTRACT(YEAR_MONTH FROM :pD1))';
  else
    sBucket := 'DATEDIFF(' + sFecha + ', :pD1)';
  end;
  Result := 'SELECT ' + sBucket + ' AS BUCKET, ' + sAgg + ' AS VALOR' +
            sFrom + sWhere + ' GROUP BY BUCKET ORDER BY BUCKET';
end;

// Ejecuta la consulta para un periodo y vuelca el agregado en un array
// indexado por bucket (0..ACount-1). Rellena ATotal con la suma del rango.
// Los parámetros de filtro sólo se enlazan si aparecen en la consulta.
function TfrmMtoComparativaMovimientos.CargarDatos(AD1, AD2: TDate;
  ACount: Integer; out ATotal: Double): TArray<Double>;
var
  qry: TUniQuery;
  prm: TDAParam;
  iIdx: Integer;
  dVal: Double;
begin
  SetLength(Result, ACount);
  for iIdx := 0 to ACount - 1 do
    Result[iIdx] := 0;
  ATotal := 0;
  if (oConn <> nil) and oConn.Connected then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := oConn;
      qry.SQL.Text := SQLConsulta;
      qry.ParamByName('pD1').AsDate := AD1;
      qry.ParamByName('pD2').AsDate := AD2;
      prm := qry.FindParam('pALM');
      if Assigned(prm) then
        prm.AsString := CodigoFiltro(cboAlmacen, FCodAlmacenes);
      prm := qry.FindParam('pFAM');
      if Assigned(prm) then
        prm.AsString := CodigoFiltro(cboFamilia, FCodFamilias);
      prm := qry.FindParam('pTEMP');
      if Assigned(prm) then
        prm.AsString := CodigoFiltro(cboTemporada, FCodTemporadas);
      qry.Open;
      while not qry.Eof do
      begin
        iIdx := qry.FieldByName('BUCKET').AsInteger;
        dVal := qry.FieldByName('VALOR').AsFloat;
        if (iIdx >= 0) and (iIdx < ACount) then
          Result[iIdx] := dVal;
        ATotal := ATotal + dVal;
        qry.Next;
      end;
      qry.Close;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

function TfrmMtoComparativaMovimientos.EtiquetaBucket(AD1: TDate;
  AIndice: Integer): string;
begin
  case cboAgrupacion.ItemIndex of
    1: Result := 'Sem ' + IntToStr(AIndice + 1);
    2: Result := FormatDateTime('mmm/yy', IncMonth(AD1, AIndice));
  else
    Result := FormatDateTime('dd/mm', AD1 + AIndice);
  end;
end;

// Formato del total según magnitud: euros, unidades o conteo
function TfrmMtoComparativaMovimientos.FormataValor(AValor: Double): string;
begin
  case cboMagnitud.ItemIndex of
    0, 1: Result := FormatFloat('#,##0.00 €', AValor);
    2: Result := FormatFloat('#,##0.###', AValor);
  else
    Result := FormatFloat('#,##0', AValor);
  end;
end;

initialization
  ForceReferenceToClass(TfrmMtoComparativaMovimientos);
end.
