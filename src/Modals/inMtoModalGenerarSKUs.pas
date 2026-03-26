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
  cxNavigator, dxDateRanges, dxScrollbarAnnotations, system.Generics.Collections;

type
    TValorAtributo = record
    IdConjunto: Integer; // ej: 1004
    NombreValor: string; // ej: 'XL'
  end;

  TDimensionSKU = class
    IdAtributo: string;      // ej: 'TAL'
    NombreAtributo: string;  // ej: 'Talla'
    Valores: TList<TValorAtributo>;
    constructor Create;
    destructor Destroy; override;
  end;

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
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
  private
    private
    FDimensiones: TObjectList<TDimensionSKU>;
    FCodigoArticulo: string;
    FTipoVariacion: string;
    procedure CargarDimensionesMaestro;
    procedure CargarValoresDetalle(const IdAtributo: string);
    procedure GenerarCombinaciones(Nivel: Integer;
                                   NombreSKU, IdsValores: string);
  public
    // Método para llamar a esta pantalla desde el formulario principal
    class function Ejecutar(const ACodigoArticulo,
                                  ATipoVariacion: string): Boolean;
  end;

var
  frmMtoModalGenerarSKUS: TfrmMtoModalGenerarSKUS;

implementation

{$R *.dfm}

uses inLibGlobalVar;

procedure TfrmMtoModalGenerarSKUS.GenerarCombinaciones(Nivel: Integer;
                                                 NombreSKU, IdsValores: string);
var
  DimActual: TDimensionSKU;
  ValActual: TValorAtributo;
  NuevoNombre, NuevosIds: string;
begin
  // CONDICIÓN DE PARADA: Hemos llegado al final de las dimensiones
  if Nivel = FDimensiones.Count then
  begin
    // ¡AQUÍ NACE UN SKU!
    // En este punto tienes la combinación completa.
    // Aquí es donde lo insertas en una tabla temporal (MemTable),
    // en un TcxGrid o directamente en la BD.

    // Ej: MemTableSKU.AppendRecord([NuevoCodigo, NombreSKU, PrecioPorDefecto...]);
    Writeln('Generado SKU: ', NombreSKU, ' (IDs: ', IdsValores, ')');
    Exit;
  end;

  // Tomamos la dimensión actual (ej: Talla)
  DimActual := FDimensiones[Nivel];

  // Iteramos por todos sus valores (S, M, L...)
  for ValActual in DimActual.Valores do
  begin
    // Construimos los textos para el siguiente salto
    if NombreSKU = '' then
      NuevoNombre := ValActual.NombreValor
    else
      NuevoNombre := NombreSKU + ' - ' + ValActual.NombreValor;

    if IdsValores = '' then
      NuevosIds := IntToStr(ValActual.IdConjunto)
    else
      NuevosIds := IdsValores + ';' + IntToStr(ValActual.IdConjunto);

    // LLAMADA RECURSIVA: Saltamos a la siguiente dimensión (ej: Color)
    GenerarCombinaciones(Nivel + 1, NuevoNombre, NuevosIds);
  end;
end;

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
  unqryMaestro.Connection := oConn;
  unqryDetalle.Connection := oConn;
  // 1. Cargamos el grid Maestro (Talla, Color...)
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

  // 2. Cargamos el grid Detalle (S, M, Azul, Verde...) de GOLPE y configuramos el enlace
  unqryDetalle.Close;
  unqryDetalle.SQL.Text :=
    'SELECT ' +
    '  val.ID_ATRIBUTO_AC, ' +
    '  val.ID_CONJUNTO_AC, ' +
    '  val.NOMBRE_AC, ' +
    '  CASE WHEN asign.ID_CONJUNTO_ACA IS NOT NULL THEN 1 ELSE 0 END AS ASIGNADO ' +
    'FROM fza_atributos_conjuntos val ' +
    'LEFT JOIN fza_articulos_conjuntos_asign asign ' +
    '       ON asign.ID_CONJUNTO_ACA = val.ID_CONJUNTO_AC ' +
    '      AND asign.CODIGO_ARTICULO_ACA = :Articulo ' +
    'WHERE val.ID_ATRIBUTO_AC IN ( ' +
    '        SELECT ID_ATRIBUTO_VA FROM fza_variaciones_atributos WHERE ID_VA = :Variacion ' +
    '      ) ' +
    '  AND val.ESACTIVO_AC = ''S'' ' +
    'ORDER BY val.NOMBRE_AC';

  // La magia automática:
  unqryDetalle.MasterSource := dsMaestro;
  unqryDetalle.MasterFields := 'ID_ATRIBUTO_VA';
  unqryDetalle.DetailFields := 'ID_ATRIBUTO_AC';

  unqryDetalle.ParamByName('Articulo').AsString  := FCodigoArticulo;
  unqryDetalle.ParamByName('Variacion').AsString := FTipoVariacion;

  // Activamos el modo memoria y abrimos
  unqryDetalle.CachedUpdates := True;
  unqryDetalle.Open;

  // Hacemos que el check sea clickeable
  unqryDetalle.FieldByName('ASIGNADO').ReadOnly := False;
end;

procedure TfrmMtoModalGenerarSKUS.btnAceptarClick(Sender: TObject);
var
  DimDict: TObjectDictionary<string, TDimensionSKU>;
  DimActual: TDimensionSKU;
  ValorActual: TValorAtributo;
  IdAtr: string;
begin
  // 1. Forzamos que se guarde cualquier check que esté a medias de editar en el grid
  if tvDetalle.DataController.IsEditing then
    tvDetalle.DataController.Post;

  // Creamos un diccionario para agrupar las dimensiones y sus valores seleccionados
  DimDict := TObjectDictionary<string, TDimensionSKU>.Create([doOwnsValues]);
  try
    // 2. TRUCO: Desconectamos el Maestro-Detalle temporalmente para ver TODOS los registros
    unqryDetalle.MasterSource := nil;
    unqryDetalle.First;

    // 3. Recorremos el dataset en memoria buscando lo que tiene el check (MARCAR_NUEVO = 1)
    while not unqryDetalle.Eof do
    begin
      if unqryDetalle.FieldByName('MARCAR_NUEVO').AsInteger = 1 then
      begin
        IdAtr := unqryDetalle.FieldByName('ID_ATRIBUTO_AC').AsString;

        // Si esta dimensión aún no está en nuestro diccionario, la creamos
        if not DimDict.TryGetValue(IdAtr, DimActual) then
        begin
          DimActual := TDimensionSKU.Create;
          DimActual.IdAtributo := IdAtr;
          // Buscamos el nombre de la dimensión en el grid maestro para que quede bonito
          if unqryMaestro.Locate('ID_ATRIBUTO_VA', IdAtr, []) then
            DimActual.NombreAtributo := unqryMaestro.FieldByName('NOMBRE_ATRIBUTO').AsString;

          DimDict.Add(IdAtr, DimActual);
        end;

        // Añadimos el valor marcado (Ej: "XL") a esta dimensión
        ValorActual.IdConjunto := unqryDetalle.FieldByName('ID_CONJUNTO_AC').AsInteger;
        ValorActual.NombreValor := unqryDetalle.FieldByName('NOMBRE_AC').AsString;
        DimActual.Valores.Add(ValorActual);
      end;
      unqryDetalle.Next;
    end;

    // Volvemos a conectar el Maestro-Detalle para dejar la pantalla como estaba
    unqryDetalle.MasterSource := dsMaestro;

    // 4. PREPARAMOS LA LLAMADA
    if DimDict.Count = 0 then
    begin
      ShowMessage('No has marcado ningún valor nuevo para generar SKUs.');
      Exit;
    end;

    // Pasamos los valores del diccionario a tu lista global de la clase (FDimensiones)
    // para que la función recursiva pueda leerla fácilmente por índice (0, 1, 2...)
    if not Assigned(FDimensiones) then
      FDimensiones := TObjectList<TDimensionSKU>.Create(False); // False = no destruye los objetos, lo hace el dict
    FDimensiones.Clear;

    for DimActual in DimDict.Values do
      FDimensiones.Add(DimActual);

    // =================================================================
    // 5. ¡LA GRAN LLAMADA A LA RECURSIVIDAD!
    // =================================================================
    GenerarCombinaciones(0, '', '');

    // Si la recursividad lo mete en una MemTable visual, el usuario
    // verá aquí aparecer las combinaciones mágicamente.
    ShowMessage('¡Combinaciones generadas con éxito!');

  finally
    DimDict.Free;
  end;
  inherited;
end;

procedure TfrmMtoModalGenerarSKUS.btnCancelarClick(Sender: TObject);
begin
  inherited;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

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
//var
//  IdAtributoSel: string;
begin
//  if unqryMaestro.IsEmpty or (AFocusedRecord = nil) then
//  begin
//    unqryDetalle.Close;
//    Exit;
//  end;
//
//  // Obtenemos el ID del atributo seleccionado (ej. 'TAL' o 'CO')
//  //IdAtributoSel := AFocusedRecord.Values[tvMaestroID_ATRIBUTO_VA.Index];
//  CargarValoresDetalle(IdAtributoSel);
end;

{ 3. CARGA DEL GRID DETALLE (Derecha) }
procedure TfrmMtoModalGenerarSKUS.CargarValoresDetalle(const IdAtributo: string);
begin
  unqryDetalle.Close;
  unqryDetalle.SQL.Text :=
    'SELECT ' +
    '  val.ID_ATRIBUTO_AC, ' + // <-- ¡VITAL! Hay que traerlo para que DetailFields funcione
    '  val.ID_CONJUNTO_AC, ' +
    '  val.NOMBRE_AC, ' +
    '  CASE WHEN asign.ID_CONJUNTO_ACA IS NOT NULL THEN ''S'' ELSE ''N'' END AS YA_USADO, ' +
    '  0 AS MARCAR_NUEVO ' +
    'FROM fza_atributos_conjuntos val ' +
    'LEFT JOIN fza_articulos_conjuntos_asign asign ' +
    '       ON asign.ID_CONJUNTO_ACA = val.ID_CONJUNTO_AC ' +
    '      AND asign.CODIGO_ARTICULO_ACA = :Articulo ' +

    // <-- CAMBIO MÁGICO: En lugar de pedir un atributo concreto, pedimos TODOS los
    // de este esquema de variación (ej. los del 'TC_BASICO') de un solo golpe.
    'WHERE val.ID_ATRIBUTO_AC IN ( ' +
    '        SELECT ID_ATRIBUTO_VA FROM fza_variaciones_atributos WHERE ID_VA = :Variacion ' +
    '      ) ' +
    '  AND val.ESACTIVO_AC = ''S'' ' +
    'ORDER BY val.NOMBRE_AC';

  // Vinculamos Maestro-Detalle por código
  unqryDetalle.MasterSource := dsMaestro;        // El DataSource del grid izquierdo
  unqryDetalle.MasterFields := 'ID_ATRIBUTO_VA'; // El campo del maestro
  unqryDetalle.DetailFields := 'ID_ATRIBUTO_AC'; // El campo del detalle (ahora sí existe en el SELECT)

  // Pasamos los parámetros
  unqryDetalle.ParamByName('Articulo').AsString  := FCodigoArticulo;
  unqryDetalle.ParamByName('Variacion').AsString := FTipoVariacion; // Ej: 'TC_BASICO'

  // Abrimos y configuramos caché
  unqryDetalle.CachedUpdates := True;
  unqryDetalle.Open;
end;

{ TDimensionSKU }

constructor TDimensionSKU.Create;
begin
  Valores := TList<TValorAtributo>.Create;
end;

destructor TDimensionSKU.Destroy;
begin
  if Assigned(Valores) then
    Valores.Free;
  inherited;
end;

end.
