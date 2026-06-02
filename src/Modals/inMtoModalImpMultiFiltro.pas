{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpMultiFiltro                                      }
{    Tipo:       Formulario base (Modal de impresión)                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formulario BASE para informes (FastReport) con filtros múltiples en       }
{    pestañas. Hereda de TfrmPrint (inMtoModalGenImp) y, al mostrarse, crea    }
{    por código un TcxPageControl con una pestaña por filtro:                  }
{      - Fechas      : rango desde / hasta.                                    }
{      - Almacenes   : checklist multi-selección.                             }
{      - Familias    : checklist multi-selección.                             }
{      - Proveedores : checklist multi-selección.                             }
{      - Temporadas  : checklist multi-selección.                             }
{                                                                              }
{    Cada informe concreto hereda de esta clase, indica con FiltrosUsados      }
{    qué pestañas quiere y, en preparar_consulta, lee los filtros con          }
{    CSVAlmacenes / CSVFamilias / CSVProveedores / CSVTemporadas y             }
{    FechaDesde / FechaHasta. Convención: checklist sin nada marcado = todos   }
{    (CSV vacío). Los códigos viajan como CSV (FIND_IN_SET en el servidor).    }
{                                                                              }
{    La UI se construye por código (no por DFM) para que los descendientes     }
{    no tengan que rehacer la herencia visual; solo añaden su informe y, si    }
{    procede, controles propios sobre la pestaña Fechas (TabFechas).           }
{******************************************************************************}
unit inMtoModalImpMultiFiltro;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls,
  inMtoModalGenImp, Data.DB, DBAccess, Uni,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, cxLabel, cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar,
  cxPC, cxCheckListBox, cxCheckBox, cxCustomListBox, cxClasses,
  dxSkinsCore, dxSkinsForm, inLibGlobalVar;

type
  TFiltroReport = (frFechas, frAlmacenes, frFamilias, frProveedores,
                   frTemporadas);
  TFiltrosReport = set of TFiltroReport;

  TfrmPrintMultiFiltro = class(TfrmPrint)
  private
    FFiltrosCreados : Boolean;
    FpcFiltros      : TcxPageControl;
    FtsFechas       : TcxTabSheet;
    FdteDesde       : TcxDateEdit;
    FdteHasta       : TcxDateEdit;
    FclbAlmacenes   : TcxCheckListBox;
    FclbFamilias    : TcxCheckListBox;
    FclbProveedores : TcxCheckListBox;
    FclbTemporadas  : TcxCheckListBox;
    procedure CrearUIFiltros;
    procedure CrearTabFechas;
    procedure CargarChecklist(AClb: TcxCheckListBox;
                              const ASQL, ACampoCod, ACampoNom: string);
    procedure CargarFiltros;
  protected
    // Los descendientes redefinen esto para elegir qué pestañas mostrar.
    function FiltrosUsados: TFiltrosReport; virtual;
    procedure DoShow; override;
    // Helpers reutilizables: el descendiente puede crear pestañas de
    // checklist propias (p. ej. "Bandas") y leer su selección como CSV.
    function  CrearTabChecklist(const ACaption: string): TcxCheckListBox;
    function  SeleccionadosCSV(AClb: TcxCheckListBox): string;
    // Expuestos para que el descendiente añada controles propios (p. ej.
    // modo/detalle) sobre la pestaña de fechas o gestione su habilitado.
    property TabFechas: TcxTabSheet read FtsFechas;
    property DteDesde : TcxDateEdit read FdteDesde;
    property DteHasta : TcxDateEdit read FdteHasta;
  public
    function CSVAlmacenes  : string;
    function CSVFamilias   : string;
    function CSVProveedores: string;
    function CSVTemporadas : string;
    function FechaDesde    : TDateTime;
    function FechaHasta    : TDateTime;
  end;

var
  frmPrintMultiFiltro: TfrmPrintMultiFiltro;

implementation

{$R *.dfm}

uses
  System.DateUtils, System.StrUtils;

{ TfrmPrintMultiFiltro }

function TfrmPrintMultiFiltro.FiltrosUsados: TFiltrosReport;
begin
  // Por defecto, todas las pestañas de filtro.
  Result := [frFechas, frAlmacenes, frFamilias, frProveedores, frTemporadas];
end;

procedure TfrmPrintMultiFiltro.DoShow;
begin
  inherited;
  // La UI de filtros se crea una sola vez (el padre hace Hide/Show en los
  // botones Imprimir/PDF/..., que reentran en DoShow).
  if not FFiltrosCreados then
  begin
    CrearUIFiltros;
    CargarFiltros;
    FFiltrosCreados := True;
  end;
end;

procedure TfrmPrintMultiFiltro.CrearUIFiltros;
var
  fs: TFiltrosReport;
begin
  fs := FiltrosUsados;
  FpcFiltros := TcxPageControl.Create(Self);
  FpcFiltros.Parent := Self;
  // El panel de botones del padre (pnl1) es alRight; el page control ocupa
  // el resto a la izquierda.
  FpcFiltros.Align := alClient;
  if frFechas in fs then
    CrearTabFechas;
  if frAlmacenes in fs then
    FclbAlmacenes := CrearTabChecklist('Almacenes');
  if frFamilias in fs then
    FclbFamilias := CrearTabChecklist('Familias');
  if frProveedores in fs then
    FclbProveedores := CrearTabChecklist('Proveedores');
  if frTemporadas in fs then
    FclbTemporadas := CrearTabChecklist('Temporadas');
  if FpcFiltros.PageCount > 0 then
    FpcFiltros.ActivePageIndex := 0;
end;

procedure TfrmPrintMultiFiltro.CrearTabFechas;
var
  lblD, lblH: TcxLabel;
begin
  FtsFechas := TcxTabSheet.Create(FpcFiltros);
  FtsFechas.PageControl := FpcFiltros;
  FtsFechas.Caption := 'Fechas';
  lblD := TcxLabel.Create(Self);
  lblD.Parent      := FtsFechas;
  lblD.Transparent := True;
  lblD.Caption     := 'Fecha inicio:';
  lblD.Left := 16;
  lblD.Top  := 16;
  FdteDesde := TcxDateEdit.Create(Self);
  FdteDesde.Parent := FtsFechas;
  FdteDesde.Left  := 16;
  FdteDesde.Top   := 38;
  FdteDesde.Width := 160;
  lblH := TcxLabel.Create(Self);
  lblH.Parent      := FtsFechas;
  lblH.Transparent := True;
  lblH.Caption     := 'Fecha fin:';
  lblH.Left := 16;
  lblH.Top  := 70;
  FdteHasta := TcxDateEdit.Create(Self);
  FdteHasta.Parent := FtsFechas;
  FdteHasta.Left  := 16;
  FdteHasta.Top   := 92;
  FdteHasta.Width := 160;
  FdteDesde.Date := EncodeDate(YearOf(Date), MonthOf(Date), 1);
  FdteHasta.Date := Date;
end;

function TfrmPrintMultiFiltro.CrearTabChecklist(
  const ACaption: string): TcxCheckListBox;
var
  ts : TcxTabSheet;
  lbl: TcxLabel;
begin
  ts := TcxTabSheet.Create(FpcFiltros);
  ts.PageControl := FpcFiltros;
  ts.Caption := ACaption;
  lbl := TcxLabel.Create(Self);
  lbl.Parent      := ts;
  lbl.Align       := alTop;
  lbl.Transparent := True;
  lbl.Caption :=
    'Marque los valores a incluir. Si no marca ninguno, salen todos.';
  Result := TcxCheckListBox.Create(Self);
  Result.Parent := ts;
  Result.Align  := alClient;
  // Por defecto (cvfInteger) el checklist usa una máscara de 64 bits y limita
  // a 64 ítems; con muchos proveedores/familias se supera. cvfString quita el
  // tope (no usamos el EditValue: leemos el State de cada ítem).
  Result.EditValueFormat := cvfString;
end;

procedure TfrmPrintMultiFiltro.CargarChecklist(AClb: TcxCheckListBox;
  const ASQL, ACampoCod, ACampoNom: string);
var
  q   : TUniQuery;
  item: TcxCheckListBoxItem;
  sCod, sNom: string;
begin
  if AClb <> nil then
  begin
    AClb.Items.Clear;
    q := TUniQuery.Create(nil);
    try
      q.Connection := inLibGlobalVar.oConn;
      q.SQL.Text := ASQL;
      q.Open;
      while not q.Eof do
      begin
        sCod := q.FieldByName(ACampoCod).AsString;
        if ACampoNom <> '' then
          sNom := q.FieldByName(ACampoNom).AsString
        else
          sNom := '';
        item := AClb.Items.Add;
        if (sNom <> '') and (sNom <> sCod) then
          item.Text := sCod + ' - ' + sNom
        else
          item.Text := sCod;
        item.State := cbsUnchecked;
        q.Next;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

procedure TfrmPrintMultiFiltro.CargarFiltros;
begin
  CargarChecklist(FclbAlmacenes,
    'SELECT CODIGO_ALM_ALM AS COD, NOMBRE_ALM_ALM AS NOM ' +
    '  FROM fza_almacenes ' +
    ' WHERE ESACTIVO_ALM = ''S'' ' +
    ' ORDER BY ORDEN_ALM, CODIGO_ALM_ALM', 'COD', 'NOM');
  CargarChecklist(FclbFamilias,
    'SELECT CODIGO_FAM_FAM AS COD, ' +
    '       COALESCE(NOMBRE_FAM_FAM, DESCRIPCION_FAM, CODIGO_FAM_FAM) AS NOM ' +
    '  FROM fza_articulos_familias ' +
    ' WHERE IFNULL(ESACTIVO_FAM, ''S'') = ''S'' ' +
    ' ORDER BY ORDEN_FAM, CODIGO_FAM_FAM', 'COD', 'NOM');
  CargarChecklist(FclbProveedores,
    'SELECT CODIGO_PRV_PRV AS COD, RAZON_SOCIAL_PRV AS NOM ' +
    '  FROM fza_proveedores ' +
    ' ORDER BY RAZON_SOCIAL_PRV, CODIGO_PRV_PRV', 'COD', 'NOM');
  // Temporada = valor de la propiedad de artículo 'TEMPORADA'. El código y
  // el nombre coinciden (el propio valor), por eso ACampoNom va vacío.
  CargarChecklist(FclbTemporadas,
    'SELECT PV AS COD ' +
    '  FROM fza_propiedades_valores ' +
    ' WHERE ID_PROP_PV = ''TEMPORADA'' ' +
    '   AND IFNULL(ESACTIVO_PV, ''S'') = ''S'' ' +
    ' ORDER BY PV', 'COD', '');
end;

// Devuelve el CSV de los códigos marcados. El código es el texto anterior
// a ' - ' (o el texto completo si no hay separador, p. ej. temporadas).
function TfrmPrintMultiFiltro.SeleccionadosCSV(AClb: TcxCheckListBox): string;
var
  i, p: Integer;
  s, sCod: string;
begin
  Result := '';
  if AClb <> nil then
    for i := 0 to AClb.Items.Count - 1 do
      if AClb.Items[i].State = cbsChecked then
      begin
        s := AClb.Items[i].Text;
        p := Pos(' - ', s);
        if p > 0 then
          sCod := Copy(s, 1, p - 1)
        else
          sCod := s;
        if Result <> '' then
          Result := Result + ',';
        Result := Result + sCod;
      end;
end;

function TfrmPrintMultiFiltro.CSVAlmacenes: string;
begin
  Result := SeleccionadosCSV(FclbAlmacenes);
end;

function TfrmPrintMultiFiltro.CSVFamilias: string;
begin
  Result := SeleccionadosCSV(FclbFamilias);
end;

function TfrmPrintMultiFiltro.CSVProveedores: string;
begin
  Result := SeleccionadosCSV(FclbProveedores);
end;

function TfrmPrintMultiFiltro.CSVTemporadas: string;
begin
  Result := SeleccionadosCSV(FclbTemporadas);
end;

function TfrmPrintMultiFiltro.FechaDesde: TDateTime;
begin
  if FdteDesde <> nil then
    Result := FdteDesde.Date
  else
    Result := Date;
end;

function TfrmPrintMultiFiltro.FechaHasta: TDateTime;
begin
  if FdteHasta <> nil then
    Result := FdteHasta.Date
  else
    Result := Date;
end;

end.
