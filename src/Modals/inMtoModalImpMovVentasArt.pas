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
  frLocalization, frLanguageSpanish, frCoreClasses, inLibGlobalVar;

type
  TfrmPrintMovVentasArt = class(TfrmPrintMultiFiltro)
    unqryMovVentasPrint: TUniQuery;
    fxdsMovVentas: TfrxDBDataset;
  private
    FInicializado: Boolean;
    FchkIniCompras: TcxCheckBox;   // activa el filtro de inicio de compras
    FdteIniCompras: TcxDateEdit;   // fecha de primera compra a partir de la cual
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

var
  frmPrintMovVentasArt: TfrmPrintMovVentasArt;

implementation

{$R *.dfm}

uses
  System.StrUtils, inLibAppParam, inMtoPreviewExcel, inLibMovVentasArtExcel,
  dxSpreadSheet, inLibFotos;

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
    // "Inicio compras": filtra los artículos por su primera compra. El check
    // permite desactivarlo (sin filtro = todos los artículos con actividad).
    FchkIniCompras := TcxCheckBox.Create(Self);
    FchkIniCompras.Parent    := TabFechas;
    FchkIniCompras.Left      := 220;
    FchkIniCompras.Top       := 16;
    FchkIniCompras.Width     := 210;
    FchkIniCompras.Caption   := 'Filtrar por inicio de compras';
    FchkIniCompras.Properties.OnEditValueChanged := chkIniComprasChange;
    FdteIniCompras := TcxDateEdit.Create(Self);
    FdteIniCompras.Parent  := TabFechas;
    FdteIniCompras.Left    := 220;
    FdteIniCompras.Top     := 40;
    FdteIniCompras.Width   := 160;
    FdteIniCompras.Date    := EncodeDate(YearOf(Date), 1, 1);
    FdteIniCompras.Enabled := False;
  end;
  // Pestaña "Agrupaciones": almacén/proveedor/familia/temporada reordenables
  // + spin de nivel de familia (igual que el balance de almacén).
  CrearTabAgrupacion('Agrupaciones',
    ['ALM', 'PRV', 'FAM', 'TMP'],
    ['Almac' + #233 + 'n', 'Proveedor', 'Familia', 'Temporada'], True);
end;

procedure TfrmPrintMovVentasArt.chkIniComprasChange(Sender: TObject);
begin
  if FdteIniCompras <> nil then
    FdteIniCompras.Enabled := (FchkIniCompras <> nil)
      and (FchkIniCompras.Checked);
end;

procedure TfrmPrintMovVentasArt.preparar_consulta;
var
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
  with unqryMovVentasPrint do
  begin
    Close;
    Connection := oConn;
    SQL.Text :=
      'CALL PRC_GET_MOV_VENTAS_ART(' +
      ':pDESDE, :pHASTA, :pINICMP, :pALM, :pFAM, :pPRV, :pTMP, :pART, ' +
      ':pN1, :pN2, :pN3, :pNFAM)';
    ParamByName('pDESDE').AsDateTime := FechaDesde;
    ParamByName('pHASTA').AsDateTime := FechaHasta;
    // Inicio compras: solo si el check está marcado; si no, NULL = sin filtro.
    if (FchkIniCompras <> nil) and FchkIniCompras.Checked
       and (FdteIniCompras <> nil) then
      ParamByName('pINICMP').AsDateTime := FdteIniCompras.Date
    else
      ParamByName('pINICMP').Clear;
    ParamByName('pALM').AsString := CSVAlmacenes;
    ParamByName('pFAM').AsString := CSVFamilias;
    ParamByName('pPRV').AsString := CSVProveedores;
    ParamByName('pTMP').AsString := CSVTemporadas;
    ParamByName('pART').AsString := CSVArticulos;
    ParamByName('pN1').AsString := NivelN(0);
    ParamByName('pN2').AsString := NivelN(1);
    ParamByName('pN3').AsString := NivelN(2);
    ParamByName('pNFAM').AsInteger := NivelFamilia;
    Open;
  end;
  fxdsMovVentas.UpdateBounds;
end;

procedure TfrmPrintMovVentasArt.AfterReportLoaded;
begin
  inherited;
  // La foto necesita el DataSet directo del TfrxDBDataset (no solo el
  // DataSource): ver inLibFotos.ObtenerDataSetDeBandaPadre.
  fxdsMovVentas.DataSet := unqryMovVentasPrint;
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
  oFotos.LimpiarPrecargaFotos;
  inherited Destroy;
end;

procedure TfrmPrintMovVentasArt.PrecargarFotosArticulos;
var
  slCod: TStringList;
begin
  if unqryMovVentasPrint.Active and (not unqryMovVentasPrint.IsEmpty) then
  begin
    slCod := TStringList.Create;
    try
      slCod.Sorted := True;
      slCod.Duplicates := dupIgnore;
      unqryMovVentasPrint.DisableControls;
      try
        unqryMovVentasPrint.First;
        while not unqryMovVentasPrint.Eof do
        begin
          slCod.Add(unqryMovVentasPrint.FieldByName('CODIGO_ART_ART').AsString);
          unqryMovVentasPrint.Next;
        end;
      finally
        unqryMovVentasPrint.EnableControls;
      end;
      oFotos.PrecargarFotosLote(slCod.ToStringArray);
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
  oFotos.HandlerReportBeforePrint(Component);
  if Component is TfrxBand then
  begin
    sNom := Component.Name;
    nivel := 0;
    if (Pos('GroupHeaderG', sNom) = 1) or (Pos('GroupFooterG', sNom) = 1) then
      nivel := StrToIntDef(Copy(sNom, Length(sNom), 1), 0);
    if (nivel >= 1) and (nivel <= 3) and unqryMovVentasPrint.Active then
      TfrxBand(Component).Visible :=
        unqryMovVentasPrint.FieldByName(
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
begin
  preparar_consulta;
  Self.Hide;
  try
    fPreview := TfrmMtoPreviewExcel.Create(Self);
    try
      fPreview.DialogoGuardar.InitialDir := oAppParams.GetPath('appDirExcel');
      fPreview.DialogoGuardar.FileName := 'Movimientos_ventas_articulos';
      ExportarMovVentasArtExcel(fPreview.dxSpreadSheet1, unqryMovVentasPrint);
      fPreview.ShowModal;
    finally
      FreeAndNil(fPreview);
    end;
  finally
    Self.Show;
  end;
end;

end.
