{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpMultiFiltro                                      }
{    Tipo:       Formulario base (Modal de impresión)                          }
{ Versión:       1.2.0                                                         }
{   Fecha:       02/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formulario BASE para informes (FastReport) con filtros múltiples en       }
{    pestañas. Hereda de TfrmPrint y, al mostrarse, crea por código un         }
{    TcxPageControl con una pestaña por filtro: Fechas (rango) y, como         }
{    checklists multi-selección CON BUSCADOR, Almacenes / Familias /           }
{    Proveedores / Temporadas / Artículos.                                     }
{                                                                              }
{    Cada checklist de filtro guarda su lista completa (Fuente) y el conjunto  }
{    de códigos marcados (Marcados); el buscador re-filtra las filas visibles  }
{    sin perder lo marcado. Convención: sin nada marcado = todos. El CSV       }
{    devuelto sale de Marcados (no de las filas visibles), así un filtro de    }
{    búsqueda no descarta selecciones ocultas.                                 }
{                                                                              }
{    Los descendientes indican con FiltrosUsados qué pestañas quieren y leen   }
{    CSVAlmacenes / CSVFamilias / CSVProveedores / CSVTemporadas /             }
{    CSVArticulos y FechaDesde / FechaHasta. Para checklists propios sin       }
{    buscador (p. ej. bandas) disponen de CrearTabChecklist +                  }
{    SeleccionadosCSV.                                                         }
{******************************************************************************}
unit inMtoModalImpMultiFiltro;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Generics.Collections, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  inMtoModalGenImp, Data.DB, DBAccess, Uni,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, cxLabel, cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar,
  cxPC, cxCheckListBox, cxCheckBox, cxCustomListBox, cxClasses,
  cxButtons, cxSpinEdit, dxSkinsCore, dxSkinsForm, inLibGlobalVar;

type
  TFiltroReport = (frFechas, frAlmacenes, frFamilias, frProveedores,
                   frTemporadas, frArticulos);
  TFiltrosReport = set of TFiltroReport;

  // Checklist de filtro con buscador. Fuente = todos los ítems ("COD - NOM");
  // Marcados = códigos marcados (se conservan aunque el buscador oculte filas).
  TFiltroChecklist = class
  public
    Clb     : TcxCheckListBox;
    Edt     : TcxTextEdit;
    Fuente  : TStringList;
    Marcados: TStringList;
    constructor Create;
    destructor Destroy; override;
  end;

  // Dimensión de agrupación (proveedor / familia / temporada...). El orden en
  // la lista marca la prioridad (la primera = grupo más externo); Marcado
  // indica si entra en la jerarquía.
  TItemAgrup = class
  public
    Codigo  : string;
    Etiqueta: string;
    Marcado : Boolean;
  end;

  TfrmPrintMultiFiltro = class(TfrmPrint)
  private
    FFiltrosCreados : Boolean;
    FpcFiltros      : TcxPageControl;
    FtsFechas       : TcxTabSheet;
    FdteDesde       : TcxDateEdit;
    FdteHasta       : TcxDateEdit;
    FFiltros        : TObjectList<TFiltroChecklist>;
    FfcAlmacenes    : TFiltroChecklist;
    FfcFamilias     : TFiltroChecklist;
    FfcProveedores  : TFiltroChecklist;
    FfcTemporadas   : TFiltroChecklist;
    FfcArticulos    : TFiltroChecklist;
    // Pestaña de agrupaciones (reordenable). FAgrupItems es el orden actual de
    // las dimensiones; FclbAgrup el checklist; FseNivelFam el nivel de familia.
    FAgrupItems     : TObjectList<TItemAgrup>;
    FclbAgrup       : TcxCheckListBox;
    FseNivelFam     : TcxSpinEdit;
    procedure CrearUIFiltros;
    procedure CrearTabFechas;
    function  CrearTabFiltro(const ACaption: string): TFiltroChecklist;
    procedure CargarFiltro(AFc: TFiltroChecklist;
                           const ASQL, ACampoCod, ACampoNom: string);
    procedure RefiltrarChecklist(AFc: TFiltroChecklist);
    procedure CargarFiltros;
    function  CodigoDeItem(const AText: string): string;
    function  FiltroPorClb(AClb: TObject): TFiltroChecklist;
    function  FiltroPorEdt(AEdt: TObject): TFiltroChecklist;
    function  CSVDe(AFc: TFiltroChecklist): string;
    procedure ClbFiltroClickCheck(Sender: TObject; AIndex: Integer;
                                   APrevState, ANewState: TcxCheckBoxState);
    procedure SearchChange(Sender: TObject);
    // Soporte de la pestaña de agrupaciones reordenable.
    procedure AgrupRefrescar;
    procedure AgrupClickCheck(Sender: TObject; AIndex: Integer;
                              APrevState, ANewState: TcxCheckBoxState);
    procedure AgrupSubirClick(Sender: TObject);
    procedure AgrupBajarClick(Sender: TObject);
  protected
    // Los descendientes redefinen esto para elegir qué pestañas mostrar.
    function FiltrosUsados: TFiltrosReport; virtual;
    procedure DoShow; override;
    // Helpers para checklists "planos" SIN buscador (p. ej. la pestaña de
    // bandas del balance, pequeña): se crea uno y se lee su selección.
    function  CrearTabChecklist(const ACaption: string): TcxCheckListBox;
    function  SeleccionadosCSV(AClb: TcxCheckListBox): string;
    // Pestaña de agrupaciones: dimensiones (código + etiqueta) que se pueden
    // marcar y reordenar. AConNivelFamilia añade un spin de nivel de familia.
    // NivelesAgrupacion devuelve los códigos marcados en el orden elegido (el
    // primero = grupo más externo). NivelFamilia da el valor del spin (0 si no).
    function  CrearTabAgrupacion(const ACaption: string;
                                 const ACods, AEtiqs: array of string;
                                 AConNivelFamilia: Boolean = False): TcxCheckListBox;
    function  NivelesAgrupacion: TArray<string>;
    function  NivelFamilia: Integer;
    // Para que el descendiente añada controles propios (modo/detalle) sobre
    // la pestaña de fechas o gestione su habilitado.
    property TabFechas: TcxTabSheet read FtsFechas;
    property DteDesde : TcxDateEdit read FdteDesde;
    property DteHasta : TcxDateEdit read FdteHasta;
  public
    destructor Destroy; override;
    function CSVAlmacenes  : string;
    function CSVFamilias   : string;
    function CSVProveedores: string;
    function CSVTemporadas : string;
    function CSVArticulos  : string;
    function FechaDesde    : TDateTime;
    function FechaHasta    : TDateTime;
  end;

var
  frmPrintMultiFiltro: TfrmPrintMultiFiltro;

implementation

{$R *.dfm}

uses
  System.DateUtils;

{ TFiltroChecklist }

constructor TFiltroChecklist.Create;
begin
  inherited Create;
  Fuente := TStringList.Create;
  Marcados := TStringList.Create;
  Marcados.Sorted := True;
  Marcados.Duplicates := dupIgnore;
end;

destructor TFiltroChecklist.Destroy;
begin
  Fuente.Free;
  Marcados.Free;
  inherited Destroy;
end;

{ TfrmPrintMultiFiltro }

destructor TfrmPrintMultiFiltro.Destroy;
begin
  // Libera los TFiltroChecklist (y sus TStringList). Los controles (clb/edt)
  // son propiedad del form y los libera el inherited.
  FreeAndNil(FFiltros);
  FreeAndNil(FAgrupItems);
  inherited Destroy;
end;

function TfrmPrintMultiFiltro.FiltrosUsados: TFiltrosReport;
begin
  Result := [frFechas, frAlmacenes, frFamilias, frProveedores, frTemporadas];
end;

procedure TfrmPrintMultiFiltro.DoShow;
begin
  inherited;
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
  FFiltros := TObjectList<TFiltroChecklist>.Create(True);
  fs := FiltrosUsados;
  FpcFiltros := TcxPageControl.Create(Self);
  FpcFiltros.Parent := Self;
  FpcFiltros.Align := alClient;
  if frFechas in fs then
    CrearTabFechas;
  if frAlmacenes in fs then
    FfcAlmacenes := CrearTabFiltro('Almacenes');
  if frFamilias in fs then
    FfcFamilias := CrearTabFiltro('Familias');
  if frProveedores in fs then
    FfcProveedores := CrearTabFiltro('Proveedores');
  if frTemporadas in fs then
    FfcTemporadas := CrearTabFiltro('Temporadas');
  if frArticulos in fs then
    FfcArticulos := CrearTabFiltro('Art' + #237 + 'culos');
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

// Pestaña de filtro con buscador (TcxTextEdit alTop) + checklist (alClient).
function TfrmPrintMultiFiltro.CrearTabFiltro(
  const ACaption: string): TFiltroChecklist;
var
  ts : TcxTabSheet;
  edt: TcxTextEdit;
  clb: TcxCheckListBox;
begin
  ts := TcxTabSheet.Create(FpcFiltros);
  ts.PageControl := FpcFiltros;
  ts.Caption := ACaption;
  edt := TcxTextEdit.Create(Self);
  edt.Parent := ts;
  edt.Align  := alTop;
  edt.Hint     := 'Escriba y pulse Intro para filtrar (sin marcar nada = todos)';
  edt.ShowHint := True;
  // OnEditValueChanged (evento confirmado en cx): filtra al postear el texto
  // (Intro / salir del cuadro). Para filtrar en cada tecla habría que usar
  // Properties.OnChange si la versión lo expone.
  edt.Properties.OnEditValueChanged := SearchChange;
  clb := TcxCheckListBox.Create(Self);
  clb.Parent := ts;
  clb.Align  := alClient;
  // cvfStatesString: sin esto (cvfInteger) el checklist limita a 64 ítems.
  clb.EditValueFormat := cvfStatesString;
  clb.OnClickCheck := ClbFiltroClickCheck;
  Result := TFiltroChecklist.Create;
  Result.Clb := clb;
  Result.Edt := edt;
  FFiltros.Add(Result);
end;

// Checklist "plano" sin buscador (para descendientes). Mantiene la etiqueta
// de ayuda y el cvfStatesString, pero no lleva fuente/marcados ni OnClickCheck:
// SeleccionadosCSV lee directamente el State de cada ítem.
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
  Result.EditValueFormat := cvfStatesString;
end;

function TfrmPrintMultiFiltro.CodigoDeItem(const AText: string): string;
var
  p: Integer;
begin
  p := Pos(' - ', AText);
  if p > 0 then
    Result := Copy(AText, 1, p - 1)
  else
    Result := AText;
end;

procedure TfrmPrintMultiFiltro.CargarFiltro(AFc: TFiltroChecklist;
  const ASQL, ACampoCod, ACampoNom: string);
var
  q: TUniQuery;
  sCod, sNom, sLinea: string;
begin
  if AFc <> nil then
  begin
    AFc.Fuente.Clear;
    AFc.Marcados.Clear;
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
        if (sNom <> '') and (sNom <> sCod) then
          sLinea := sCod + ' - ' + sNom
        else
          sLinea := sCod;
        AFc.Fuente.Add(sLinea);
        q.Next;
      end;
    finally
      FreeAndNil(q);
    end;
    RefiltrarChecklist(AFc);
  end;
end;

// Repuebla las filas visibles del checklist según el texto del buscador,
// remarcando las que estén en Marcados (las selecciones se conservan).
procedure TfrmPrintMultiFiltro.RefiltrarChecklist(AFc: TFiltroChecklist);
var
  i: Integer;
  sFil, sLinea: string;
  item: TcxCheckListBoxItem;
begin
  if AFc <> nil then
  begin
    sFil := LowerCase(Trim(AFc.Edt.Text));
    AFc.Clb.Items.BeginUpdate;
    try
      AFc.Clb.Items.Clear;
      for i := 0 to AFc.Fuente.Count - 1 do
      begin
        sLinea := AFc.Fuente[i];
        if (sFil = '') or (Pos(sFil, LowerCase(sLinea)) > 0) then
        begin
          item := AFc.Clb.Items.Add;
          item.Text := sLinea;
          if AFc.Marcados.IndexOf(CodigoDeItem(sLinea)) >= 0 then
            item.State := cbsChecked
          else
            item.State := cbsUnchecked;
        end;
      end;
    finally
      AFc.Clb.Items.EndUpdate;
    end;
  end;
end;

procedure TfrmPrintMultiFiltro.CargarFiltros;
begin
  CargarFiltro(FfcAlmacenes,
    'SELECT CODIGO_ALM_ALM AS COD, NOMBRE_ALM_ALM AS NOM ' +
    '  FROM fza_almacenes ' +
    ' WHERE ESACTIVO_ALM = ''S'' ' +
    ' ORDER BY ORDEN_ALM, CODIGO_ALM_ALM', 'COD', 'NOM');
  CargarFiltro(FfcFamilias,
    'SELECT CODIGO_FAM_FAM AS COD, ' +
    '       COALESCE(NOMBRE_FAM_FAM, DESCRIPCION_FAM, CODIGO_FAM_FAM) AS NOM ' +
    '  FROM fza_articulos_familias ' +
    ' WHERE IFNULL(ESACTIVO_FAM, ''S'') = ''S'' ' +
    ' ORDER BY ORDEN_FAM, CODIGO_FAM_FAM', 'COD', 'NOM');
  // Solo proveedores con al menos un artículo: la lista es relevante y corta.
  CargarFiltro(FfcProveedores,
    'SELECT p.CODIGO_PRV_PRV AS COD, p.RAZON_SOCIAL_PRV AS NOM ' +
    '  FROM fza_proveedores p ' +
    ' WHERE EXISTS (SELECT 1 FROM fza_articulos_proveedores ap ' +
    '                WHERE ap.CODIGO_PRV_AP = p.CODIGO_PRV_PRV) ' +
    ' ORDER BY p.RAZON_SOCIAL_PRV, p.CODIGO_PRV_PRV', 'COD', 'NOM');
  // Temporada = valor de la propiedad de artículo 'TEMPORADA' (código=nombre).
  CargarFiltro(FfcTemporadas,
    'SELECT PV AS COD ' +
    '  FROM fza_propiedades_valores ' +
    ' WHERE ID_PROP_PV = ''TEMPORADA'' ' +
    '   AND IFNULL(ESACTIVO_PV, ''S'') = ''S'' ' +
    ' ORDER BY PV', 'COD', '');
  // Artículos activos (código + descripción). La lista puede ser larga: el
  // buscador de la pestaña acota las filas visibles. Sin marcar nada = todos.
  CargarFiltro(FfcArticulos,
    'SELECT CODIGO_ART_ART AS COD, DESCRIPCION_ART AS NOM ' +
    '  FROM fza_articulos ' +
    ' WHERE ESACTIVO_ART = ''S'' ' +
    ' ORDER BY CODIGO_ART_ART', 'COD', 'NOM');
end;

function TfrmPrintMultiFiltro.FiltroPorClb(AClb: TObject): TFiltroChecklist;
var
  i: Integer;
begin
  Result := nil;
  if FFiltros <> nil then
    for i := 0 to FFiltros.Count - 1 do
      if (Result = nil) and (FFiltros[i].Clb = AClb) then
        Result := FFiltros[i];
end;

function TfrmPrintMultiFiltro.FiltroPorEdt(AEdt: TObject): TFiltroChecklist;
var
  i: Integer;
begin
  Result := nil;
  if FFiltros <> nil then
    for i := 0 to FFiltros.Count - 1 do
      if (Result = nil) and (FFiltros[i].Edt = AEdt) then
        Result := FFiltros[i];
end;

// Al marcar/desmarcar un ítem, se actualiza el conjunto de códigos marcados
// (fuente de verdad para el CSV, independiente del filtro de búsqueda).
procedure TfrmPrintMultiFiltro.ClbFiltroClickCheck(Sender: TObject;
  AIndex: Integer; APrevState, ANewState: TcxCheckBoxState);
var
  fc : TFiltroChecklist;
  cod: string;
  idx: Integer;
begin
  fc := FiltroPorClb(Sender);
  if (fc <> nil) and (AIndex >= 0) and (AIndex < fc.Clb.Items.Count) then
  begin
    cod := CodigoDeItem(fc.Clb.Items[AIndex].Text);
    if ANewState = cbsChecked then
    begin
      if fc.Marcados.IndexOf(cod) < 0 then
        fc.Marcados.Add(cod);
    end
    else
    begin
      idx := fc.Marcados.IndexOf(cod);
      if idx >= 0 then
        fc.Marcados.Delete(idx);
    end;
  end;
end;

procedure TfrmPrintMultiFiltro.SearchChange(Sender: TObject);
var
  fc: TFiltroChecklist;
begin
  fc := FiltroPorEdt(Sender);
  if fc <> nil then
    RefiltrarChecklist(fc);
end;

function TfrmPrintMultiFiltro.CSVDe(AFc: TFiltroChecklist): string;
var
  i: Integer;
begin
  Result := '';
  if AFc <> nil then
    for i := 0 to AFc.Marcados.Count - 1 do
    begin
      if Result <> '' then
        Result := Result + ',';
      Result := Result + AFc.Marcados[i];
    end;
end;

// CSV de un checklist "plano" (sin Marcados): se lee el State de cada ítem.
function TfrmPrintMultiFiltro.SeleccionadosCSV(AClb: TcxCheckListBox): string;
var
  i: Integer;
begin
  Result := '';
  if AClb <> nil then
    for i := 0 to AClb.Items.Count - 1 do
      if AClb.Items[i].State = cbsChecked then
      begin
        if Result <> '' then
          Result := Result + ',';
        Result := Result + CodigoDeItem(AClb.Items[i].Text);
      end;
end;

// Crea la pestaña de agrupaciones: un checklist con las dimensiones (en el
// orden recibido) más botones Subir/Bajar para reordenarlas y, opcionalmente,
// un spin con el nivel de familia.
function TfrmPrintMultiFiltro.CrearTabAgrupacion(const ACaption: string;
  const ACods, AEtiqs: array of string;
  AConNivelFamilia: Boolean): TcxCheckListBox;
var
  ts      : TcxTabSheet;
  lbl     : TcxLabel;
  lblNivel: TcxLabel;
  pnl     : TPanel;
  btnSubir: TcxButton;
  btnBajar: TcxButton;
  i       : Integer;
  it      : TItemAgrup;
begin
  if FAgrupItems = nil then
    FAgrupItems := TObjectList<TItemAgrup>.Create(True);
  ts := TcxTabSheet.Create(FpcFiltros);
  ts.PageControl := FpcFiltros;
  ts.Caption := ACaption;
  lbl := TcxLabel.Create(Self);
  lbl.Parent      := ts;
  lbl.Align       := alTop;
  lbl.Transparent := True;
  lbl.Caption :=
    'Marque por qu' + #233 + ' agrupar y ordene los niveles con Subir/Bajar ' +
    '(el primero es el grupo m' + #225 + 's externo). Sin marcar = sin agrupar.';
  pnl := TPanel.Create(Self);
  pnl.Parent     := ts;
  pnl.Align      := alRight;
  pnl.Width      := 100;
  pnl.BevelOuter := bvNone;
  btnSubir := TcxButton.Create(Self);
  btnSubir.Parent  := pnl;
  btnSubir.Left    := 10;
  btnSubir.Top     := 10;
  btnSubir.Width   := 80;
  btnSubir.Caption := 'Subir';
  btnSubir.OnClick := AgrupSubirClick;
  btnBajar := TcxButton.Create(Self);
  btnBajar.Parent  := pnl;
  btnBajar.Left    := 10;
  btnBajar.Top     := 42;
  btnBajar.Width   := 80;
  btnBajar.Caption := 'Bajar';
  btnBajar.OnClick := AgrupBajarClick;
  if AConNivelFamilia then
  begin
    lblNivel := TcxLabel.Create(Self);
    lblNivel.Parent      := pnl;
    lblNivel.Transparent := True;
    lblNivel.Left        := 10;
    lblNivel.Top         := 86;
    lblNivel.Caption     := 'Nivel familia:';
    FseNivelFam := TcxSpinEdit.Create(Self);
    FseNivelFam.Parent             := pnl;
    FseNivelFam.Left               := 10;
    FseNivelFam.Top                := 106;
    FseNivelFam.Width              := 80;
    FseNivelFam.Properties.MinValue := 0;
    FseNivelFam.Properties.MaxValue := 20;
    FseNivelFam.Value              := 1;
    FseNivelFam.Hint :=
      'Al agrupar por familia: 0 = familia del art' + #237 +
      'culo; 1 = familia ra' + #237 + 'z; 2, 3... niveles intermedios.';
    FseNivelFam.ShowHint := True;
  end;
  FclbAgrup := TcxCheckListBox.Create(Self);
  FclbAgrup.Parent         := ts;
  FclbAgrup.Align          := alClient;
  FclbAgrup.EditValueFormat := cvfStatesString;
  FclbAgrup.OnClickCheck   := AgrupClickCheck;
  for i := Low(ACods) to High(ACods) do
  begin
    it := TItemAgrup.Create;
    it.Codigo := ACods[i];
    if i <= High(AEtiqs) then
      it.Etiqueta := AEtiqs[i]
    else
      it.Etiqueta := ACods[i];
    it.Marcado := False;
    FAgrupItems.Add(it);
  end;
  AgrupRefrescar;
  Result := FclbAgrup;
end;

// Repinta el checklist desde FAgrupItems (orden + marcas), conservando la fila
// seleccionada para que Subir/Bajar sean cómodos.
procedure TfrmPrintMultiFiltro.AgrupRefrescar;
var
  i, sel: Integer;
  item  : TcxCheckListBoxItem;
begin
  if (FclbAgrup <> nil) and (FAgrupItems <> nil) then
  begin
    sel := FclbAgrup.ItemIndex;
    FclbAgrup.Items.BeginUpdate;
    try
      FclbAgrup.Items.Clear;
      for i := 0 to FAgrupItems.Count - 1 do
      begin
        item := FclbAgrup.Items.Add;
        item.Text := FAgrupItems[i].Etiqueta;
        if FAgrupItems[i].Marcado then
          item.State := cbsChecked
        else
          item.State := cbsUnchecked;
      end;
    finally
      FclbAgrup.Items.EndUpdate;
    end;
    if (sel >= 0) and (sel < FclbAgrup.Items.Count) then
      FclbAgrup.ItemIndex := sel;
  end;
end;

procedure TfrmPrintMultiFiltro.AgrupClickCheck(Sender: TObject;
  AIndex: Integer; APrevState, ANewState: TcxCheckBoxState);
begin
  if (FAgrupItems <> nil) and (AIndex >= 0) and (AIndex < FAgrupItems.Count) then
    FAgrupItems[AIndex].Marcado := (ANewState = cbsChecked);
end;

procedure TfrmPrintMultiFiltro.AgrupSubirClick(Sender: TObject);
var
  i: Integer;
begin
  if (FclbAgrup <> nil) and (FAgrupItems <> nil) then
  begin
    i := FclbAgrup.ItemIndex;
    if i > 0 then
    begin
      FAgrupItems.Exchange(i, i - 1);
      AgrupRefrescar;
      FclbAgrup.ItemIndex := i - 1;
    end;
  end;
end;

procedure TfrmPrintMultiFiltro.AgrupBajarClick(Sender: TObject);
var
  i: Integer;
begin
  if (FclbAgrup <> nil) and (FAgrupItems <> nil) then
  begin
    i := FclbAgrup.ItemIndex;
    if (i >= 0) and (i < FAgrupItems.Count - 1) then
    begin
      FAgrupItems.Exchange(i, i + 1);
      AgrupRefrescar;
      FclbAgrup.ItemIndex := i + 1;
    end;
  end;
end;

// Códigos marcados en el orden elegido (el primero = grupo más externo).
function TfrmPrintMultiFiltro.NivelesAgrupacion: TArray<string>;
var
  i  : Integer;
  lst: TList<string>;
begin
  lst := TList<string>.Create;
  try
    if FAgrupItems <> nil then
      for i := 0 to FAgrupItems.Count - 1 do
        if FAgrupItems[i].Marcado then
          lst.Add(FAgrupItems[i].Codigo);
    Result := lst.ToArray;
  finally
    lst.Free;
  end;
end;

function TfrmPrintMultiFiltro.NivelFamilia: Integer;
begin
  if (FseNivelFam <> nil) and (not VarIsNull(FseNivelFam.Value)) then
    Result := FseNivelFam.Value
  else
    Result := 0;
end;

function TfrmPrintMultiFiltro.CSVAlmacenes: string;
begin
  Result := CSVDe(FfcAlmacenes);
end;

function TfrmPrintMultiFiltro.CSVFamilias: string;
begin
  Result := CSVDe(FfcFamilias);
end;

function TfrmPrintMultiFiltro.CSVProveedores: string;
begin
  Result := CSVDe(FfcProveedores);
end;

function TfrmPrintMultiFiltro.CSVTemporadas: string;
begin
  Result := CSVDe(FfcTemporadas);
end;

function TfrmPrintMultiFiltro.CSVArticulos: string;
begin
  Result := CSVDe(FfcArticulos);
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
