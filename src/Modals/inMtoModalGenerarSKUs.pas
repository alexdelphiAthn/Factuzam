unit inMtoModalGenerarSKUs;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoModalAceptCancel, cxGraphics,
  cxLookAndFeels, cxLookAndFeelPainters, Vcl.Menus, System.Actions,
  Vcl.ActnList, JvComponentBase, JvEnterTab, cxClasses, cxLocalization,
  Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, Data.DB, MemDS, DBAccess, Uni,
  cxControls, cxSplitter, cxStyles, cxDBData, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  UniDataConn, cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit,
  cxNavigator, dxDateRanges, dxScrollbarAnnotations;

type
  TfrmMtoModalGenerarSKUS = class(TfrmModalAceptCancel)
    unqryMaestro: TUniQuery;
    unqryDetalle: TUniQuery;
    dsMaestro: TDataSource;
    dsDetalle: TDataSource;
    pnlBodyCab: TPanel;
    pnlBodyDetalle: TPanel;
    cxSplitter1: TcxSplitter;
    tvMaestro: TcxGridDBTableView;
    cxGrid1Level1: TcxGridLevel;
    cxGrid1: TcxGrid;
    cxGrid2: TcxGrid;
    tvDetalle: TcxGridDBTableView;
    cxGridLevel1: TcxGridLevel;
    tvMaestroID_ATRIBUTO_VA: TcxGridDBColumn;
    tvMaestroID_VA: TcxGridDBColumn;
    tvMaestroNOMBRE_ATRIBUTO: TcxGridDBColumn;
    tvMaestroORDEN_VA: TcxGridDBColumn;
    tvDetalleID_ATRIBUTO_AC: TcxGridDBColumn;
    tvDetalleID_CONJUNTO_AC: TcxGridDBColumn;
    tvDetalleNOMBRE_AC: TcxGridDBColumn;
    tvDetalleYA_USADO: TcxGridDBColumn;
    tvDetalleMARCAR_NUEVO: TcxGridDBColumn;
    procedure FormShow(Sender: TObject);
    procedure tvMaestroFocusedRecordChanged(Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
  private
    FCodigoArticulo: string;
    FTipoVariacion: string;
    procedure CargarDimensionesMaestro;
    procedure CargarValoresDetalle(const IdAtributo: string);
  public
    // Método para llamar a esta pantalla desde el formulario principal
    class function Ejecutar(const ACodigoArticulo, ATipoVariacion: string): Boolean;
  end;

var
  frmMtoModalGenerarSKUS: TfrmMtoModalGenerarSKUS;

implementation

{$R *.dfm}

class function TfrmMtoModalGenerarSKUS.Ejecutar(const ACodigoArticulo, ATipoVariacion: string): Boolean;
var
  frm: TfrmMtoModalGenerarSKUS;
begin
  frm := TfrmMtoModalGenerarSKUS.Create(nil);
  try
    frm.FCodigoArticulo := ACodigoArticulo;
    frm.FTipoVariacion  := ATipoVariacion;
    Result := (frm.ShowModal = mrOk);
  finally
    frm.Free;
  end;
end;

procedure TfrmMtoModalGenerarSKUS.FormShow(Sender: TObject);
begin
  // IMPORTANTE: El query de detalle debe permitir edición en memoria (CachedUpdates)
  // para que los CheckBox funcionen sin hacer UPDATEs reales en la BD.
  unqryDetalle.CachedUpdates := True;

  CargarDimensionesMaestro;
end;

{ 1. CARGA DEL GRID MAESTRO (Izquierda) }
procedure TfrmMtoModalGenerarSKUS.CargarDimensionesMaestro;
begin
  unqryMaestro.Close;
  unqryMaestro.SQL.Text :=
    'SELECT va.ID_ATRIBUTO_VA, ' +
    '       COALESCE(va.NOMBRE_VA, va.ID_ATRIBUTO_VA) AS NOMBRE_ATRIBUTO, ' +
    '       va.ORDEN_VA ' +
    'FROM fza_variaciones_atributos va ' +
    'WHERE va.ID_VA = :var ' +
    'ORDER BY va.ORDEN_VA';

  unqryMaestro.ParamByName('var').AsString := FTipoVariacion;
  unqryMaestro.Open;
end;

{ 2. EVENTO AL CAMBIAR DE FILA EN EL MAESTRO }
procedure TfrmMtoModalGenerarSKUS.tvMaestroFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord; ANewItemRecordFocusingChanged: Boolean);
var
  IdAtributoSel: string;
begin
  if unqryMaestro.IsEmpty or (AFocusedRecord = nil) then
  begin
    unqryDetalle.Close;
    Exit;
  end;

  // Obtenemos el ID del atributo seleccionado (ej. 'TAL' o 'CO')
  //IdAtributoSel := AFocusedRecord.Values[tvMaestroID_ATRIBUTO_VA.Index];
  CargarValoresDetalle(IdAtributoSel);
end;

{ 3. CARGA DEL GRID DETALLE (Derecha) }
procedure TfrmMtoModalGenerarSKUS.CargarValoresDetalle(const IdAtributo: string);
begin
  unqryDetalle.Close;
  unqryDetalle.SQL.Text :=
    'SELECT ' +
    '  val.ID_CONJUNTO_AC, ' +
    '  val.NOMBRE_AC, ' +
    '  CASE WHEN asign.ID_CONJUNTO_ACA IS NOT NULL THEN ''S'' ELSE ''N'' END AS YA_USADO, ' +
    '  0 AS MARCAR_NUEVO ' + // <-- Nuestro campo falso para el CheckBox
    'FROM fza_atributos_conjuntos val ' +
    'LEFT JOIN fza_articulos_conjuntos_asign asign ' +
    '       ON asign.ID_CONJUNTO_ACA = val.ID_CONJUNTO_AC ' +
    '      AND asign.CODIGO_ARTICULO_ACA = :Articulo ' +
    'WHERE val.ID_ATRIBUTO_AC = :Atributo ' +
    '  AND val.ESACTIVO_AC = ''S'' ' +
    'ORDER BY val.NOMBRE_AC';

  unqryDetalle.ParamByName('Articulo').AsString := FCodigoArticulo;
  unqryDetalle.ParamByName('Atributo').AsString := IdAtributo;
  unqryDetalle.Open;
end;

end.
