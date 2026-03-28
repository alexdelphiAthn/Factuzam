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
  cxNavigator, dxDateRanges, dxScrollbarAnnotations, system.Generics.Collections,
  cxCheckBox;

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
    tvDetalleASIGNADO: TcxGridDBColumn;
    btnAddValue: TcxButton;
    tvDetalleID_ATRIBUTO_VA: TcxGridDBColumn;
    tvDetalleORDEN_AV: TcxGridDBColumn;
    procedure FormShow(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnAddValueClick(Sender: TObject);
  private
    FDimensiones: TObjectList<TDimensionSKU>;
    FCodigoArticulo: string;
    FTipoVariacion: string;
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

procedure TfrmMtoModalGenerarSKUS.GenerarCombinaciones(Nivel: Integer; NombreSKU, IdsValores: string);
var
  DimActual: TDimensionSKU;
  ValActual: TValorAtributo;
  NuevoNombre, NuevosIds: string;

  // Variables nuevas para la inserción
  CodigoNuevoSKU: string;
  ArrayIds: TArray<string>;
  IdStr: string;
begin
  // CONDICIÓN DE PARADA: Hemos llegado al final de las dimensiones
  if Nivel = FDimensiones.Count then
  begin
    // 1. Fabricamos el código único del SKU (Ej: 'DEMO-CAMISA-M-BLANCO')
    // Usamos el código del artículo y le pegamos el nombre de la combinación reemplazando ' - ' por '-'
    CodigoNuevoSKU := FCodigoArticulo + '/' + NombreSKU;

    // (Opcional) Si quieres quitar espacios en blanco del código de barras/SKU:
    CodigoNuevoSKU := StringReplace(CodigoNuevoSKU, ' ', '', [rfReplaceAll]);

    // 2. INSERTAMOS EN LA TABLA MAESTRA DE SKUs
    // Usamos INSERT IGNORE para que si el usuario le da a "Generar" dos veces y
    // el SKU ya existía, la BD lo ignore pacíficamente sin dar error.
// 2. INSERTAMOS EN LA TABLA MAESTRA DE SKUs (Adaptado a tu tabla real)
    unqryMaestro.Connection.ExecSQL(
      'INSERT IGNORE INTO fza_articulos_skus ' +
      '(CODIGO_UNIDAD_SKU, CODIGO_ARTICULO_SKU, CODIGO_VAR_SKU, ESACTIVO_SKU, ' +
      ' INSTANTEALTA, USUARIOALTA, USUARIOMODIF) ' +
      'VALUES (:cod, :art, :var, ''S'', ' +
      ' CURRENT_TIMESTAMP, ''SISTEMA'', ''SISTEMA'')',
      [CodigoNuevoSKU, FCodigoArticulo, FTipoVariacion]
    );
    // 3. INSERTAMOS EN LA TABLA DETALLE DE ATRIBUTOS (El desglose)
    // IdsValores trae los IDs separados por punto y coma (ej: '9102;9201')
    ArrayIds := IdsValores.Split([';']);
    for IdStr in ArrayIds do
    begin
      if Trim(IdStr) <> '' then
      begin
        unqryMaestro.Connection.ExecSQL(
          'INSERT IGNORE INTO fza_atributos_sku ' +
          '(CODIGO_UNIDAD_SA, ID_VALOR_SA) ' +
          'VALUES (:cod, :val)',
          [CodigoNuevoSKU, StrToInt(IdStr)]
        );
      end;
    end;

    // Salimos porque ya hemos terminado esta rama de la recursividad
    Exit;
  end;

  // =========================================================
  // EL RESTO DE TU FUNCIÓN SE QUEDA EXACTAMENTE IGUAL
  // =========================================================
  DimActual := FDimensiones[Nivel];

  for ValActual in DimActual.Valores do
  begin
    if NombreSKU = '' then
      NuevoNombre := ValActual.NombreValor
    else
      NuevoNombre := NombreSKU + '/' + ValActual.NombreValor;

    if IdsValores = '' then
      NuevosIds := IntToStr(ValActual.IdConjunto)
    else
      NuevosIds := IdsValores + ';' + IntToStr(ValActual.IdConjunto);

    GenerarCombinaciones(Nivel + 1, NuevoNombre, NuevosIds);
  end;
end;

class function TfrmMtoModalGenerarSKUS.Ejecutar(const ACodigoArticulo,
                                               ATipoVariacion: string): Boolean;
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
  unqryDetalle.Close;
  unqryDetalle.SQL.Text :=
    'SELECT ' +
    '         atr.ID_ATRIBUTO_VA, ' +
    '         val.ID_VALOR_AV AS ID_CONJUNTO_AC, ' +
    '         val.VALOR_AV AS NOMBRE_AC, ' +
    '         val.ORDEN_AV, ' +
    '         0 AS ASIGNADO ' +
    '    FROM fza_variaciones_atributos atr ' +
    '    JOIN fza_articulos_conjuntos_asign asign ' +
    '      ON asign.ID_ATRIBUTO_ACA = atr.ID_ATRIBUTO_VA ' +
    '     AND asign.CODIGO_ARTICULO_ACA = :Articulo ' +
    '    JOIN fza_atributos_conjuntos_det det ' +
    '      ON det.ID_CONJUNTO_ACD = asign.ID_CONJUNTO_ACA ' +
    '    JOIN fza_atributos_valores val ' +
    '      ON val.ID_VALOR_AV = det.ID_VALOR_ACD ' +
    '   WHERE atr.ID_VA = :Variacion ' +
    'ORDER BY atr.ORDEN_VA, val.ORDEN_AV';
  unqryDetalle.MasterSource := dsMaestro;
  unqryDetalle.MasterFields := 'ID_ATRIBUTO_VA';
  unqryDetalle.DetailFields := 'ID_ATRIBUTO_VA';
  unqryDetalle.ParamByName('Articulo').AsString  := FCodigoArticulo;
  unqryDetalle.ParamByName('Variacion').AsString := FTipoVariacion;
  unqryDetalle.CachedUpdates := True;
  unqryDetalle.Options.LocalMasterDetail := True;
  unqryDetalle.Open;
  unqryDetalle.FieldByName('ASIGNADO').ReadOnly := False;
  unqryDetalle.FieldByName('ID_ATRIBUTO_VA').ReadOnly := False;
  unqryDetalle.FieldByName('ID_CONJUNTO_AC').ReadOnly := False;
  unqryDetalle.FieldByName('NOMBRE_AC').ReadOnly := False;
end;

procedure TfrmMtoModalGenerarSKUS.btnAceptarClick(Sender: TObject);
var
  DimDict: TObjectDictionary<string, TDimensionSKU>;
  DimActual: TDimensionSKU;
  ValorActual: TValorAtributo;
  IdAtr: string;
  i: Integer;
  BmMaestro: TBookmark;
begin
  if tvDetalle.DataController.IsEditing then
    tvDetalle.DataController.Post;
  if unqryDetalle.State in [dsEdit, dsInsert] then
    unqryDetalle.Post;
  if not Assigned(FDimensiones) then
    FDimensiones := TObjectList<TDimensionSKU>.Create(False);
  FDimensiones.Clear;
  DimDict := TObjectDictionary<string, TDimensionSKU>.Create([doOwnsValues]);
  try
    BmMaestro := unqryMaestro.GetBookmark;
    tvMaestro.BeginUpdate;
    tvDetalle.BeginUpdate;
    try
      unqryMaestro.First;
      while not unqryMaestro.Eof do
      begin
        DimActual := TDimensionSKU.Create;
        DimActual.IdAtributo := unqryMaestro.FieldByName('ID_ATRIBUTO_VA').AsString;
        DimActual.NombreAtributo := unqryMaestro.FieldByName('NOMBRE_ATRIBUTO').AsString;
        DimDict.Add(DimActual.IdAtributo, DimActual);
        FDimensiones.Add(DimActual);
        unqryDetalle.First;
        while not unqryDetalle.Eof do
        begin
          if unqryDetalle.FieldByName('ASIGNADO').AsInteger = 1 then
          begin
            ValorActual.IdConjunto := unqryDetalle.FieldByName('ID_CONJUNTO_AC').AsInteger;
            ValorActual.NombreValor := unqryDetalle.FieldByName('NOMBRE_AC').AsString;
            DimActual.Valores.Add(ValorActual);
          end;
          unqryDetalle.Next;
        end;
        unqryMaestro.Next;
      end;
    finally
      if unqryMaestro.BookmarkValid(BmMaestro) then
        unqryMaestro.GotoBookmark(BmMaestro);
      unqryMaestro.FreeBookmark(BmMaestro);
      tvDetalle.EndUpdate;
      tvMaestro.EndUpdate;
    end;
    for i := FDimensiones.Count - 1 downto 0 do
    begin
      if FDimensiones[i].Valores.Count = 0 then
        FDimensiones.Delete(i);
    end;
    if FDimensiones.Count = 0 then
    begin
      ShowMessage('No has marcado ningún valor para generar SKUs.');
      Exit;
    end;
    GenerarCombinaciones(0, '', '');
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

procedure TfrmMtoModalGenerarSKUS.btnAddValueClick(Sender: TObject);
var
  NuevoNombre, IdAtrSel: string;
  IdConjuntoAsignado, IdNuevoValor: Integer;
  qTemp: TUniQuery;
begin
  // 1. EL INPUTBOX: Muestra un pequeño popup pidiendo el nombre de la nueva talla/color
  NuevoNombre := Trim(InputBox('Añadir nuevo valor',
            'Introduce el nombre del nuevo atributo (Ej: XXL, Turquesa):', ''));
  if NuevoNombre = '' then Exit;
  var OrdenStr := Trim(InputBox('Añadir nuevo valor', 'Introduce el ORDEN (Ej: 10, 20, 30...):', '100'));
  if OrdenStr = '' then Exit;
  var OrdenVal := StrToIntDef(OrdenStr, 100); // Valor por defecto 100 si mete letras sin querer

  // 2. Obtenemos qué dimensión está seleccionada en el grid Maestro (ej. 'TAL' para Talla)
  IdAtrSel := unqryMaestro.FieldByName('ID_ATRIBUTO_VA').AsString;

  qTemp := TUniQuery.Create(nil);
  try
    qTemp.Connection := unqryMaestro.Connection;

    // =========================================================================
    // FASE 1: GUARDADO FÍSICO EN LA BASE DE DATOS
    // =========================================================================

    // A. Averiguamos qué "Grupo" (Conjunto) usa el artículo para esta dimensión
    qTemp.SQL.Text :=
      'SELECT ID_CONJUNTO_ACA FROM fza_articulos_conjuntos_asign ' +
      'WHERE CODIGO_ARTICULO_ACA = :Articulo AND ID_ATRIBUTO_ACA = :Atributo';
    qTemp.ParamByName('Articulo').AsString := FCodigoArticulo;
    qTemp.ParamByName('Atributo').AsString := IdAtrSel;
    qTemp.Open;

    if qTemp.IsEmpty then
    begin
      ShowMessage('Error: El artículo no tiene un grupo asignado para esta' +
                  ' dimensión. Debe asignarlo en Artículos -> pestaña General');
      Exit;
    end;
    IdConjuntoAsignado := qTemp.FieldByName('ID_CONJUNTO_ACA').AsInteger;
    qTemp.Close;
    qTemp.SQL.Text :=
      'SELECT ID_VALOR_AV FROM fza_atributos_valores ' +
      'WHERE ID_VA_AV = :IdVa AND TRIM(UPPER(VALOR_AV)) = UPPER(:Valor)';
    qTemp.ParamByName('IdVa').AsString := IdAtrSel;
    qTemp.ParamByName('Valor').AsString := NuevoNombre;
    qTemp.Open;
    if not qTemp.IsEmpty then
      IdNuevoValor := qTemp.FieldByName('ID_VALOR_AV').AsInteger
    else
    begin
      var Respuesta: Integer;
      var IdNuevoConjunto: Integer;
      Respuesta := MessageDlg(
        '¿Desea añadir "' + NuevoNombre + '" a TODO el conjunto actual (afectará a otros artículos) ' +
        #13#10 + 'o crear una excepción SOLO para este artículo?',
        mtConfirmation, [mbYes, mbNo, mbCancel], 0);

      if Respuesta = mrCancel then
        Exit; // Abortamos la operación
      if Respuesta = mrYes then
      begin
        // OPCIÓN A: Añadir al conjunto global (AÑADIMOS ORDEN_ACD)
        qTemp.Close;
        qTemp.SQL.Text :=
          'INSERT IGNORE INTO fza_atributos_conjuntos_det ' +
          '(ID_CONJUNTO_ACD, ID_VALOR_ACD, ORDEN_ACD, INSTANTEALTA, USUARIOALTA, USUARIOMODIF) ' +
          'VALUES (:Conj, :Val, :Orden, CURRENT_TIMESTAMP, ''SISTEMA'', ''SISTEMA'')';
        qTemp.ParamByName('Conj').AsInteger  := IdConjuntoAsignado;
        qTemp.ParamByName('Val').AsInteger   := IdNuevoValor;
        qTemp.ParamByName('Orden').AsInteger := OrdenVal; // <-- ¡Pasamos el orden aquí!
        qTemp.Execute;
      end
      else if Respuesta = mrNo then
      begin
        // OPCIÓN B: Crear un conjunto específico solo para este artículo

        // 1. Clonar la cabecera del conjunto (Igual que antes)
        qTemp.Close;
        qTemp.SQL.Text :=
          'INSERT INTO fza_atributos_conjuntos (NOMBRE_AC, ID_VARIACION_AC, ID_ATRIBUTO_AC, INSTANTEALTA, USUARIOALTA, USUARIOMODIF) ' +
          'SELECT CONCAT(NOMBRE_AC, '' ('', :Articulo, '')''), ID_VARIACION_AC, ID_ATRIBUTO_AC, CURRENT_TIMESTAMP, ''SISTEMA'', ''SISTEMA'' ' +
          'FROM fza_atributos_conjuntos WHERE ID_CONJUNTO_AC = :OldConj';
        qTemp.ParamByName('Articulo').AsString := FCodigoArticulo;
        qTemp.ParamByName('OldConj').AsInteger := IdConjuntoAsignado;
        qTemp.Execute;

        // Obtener el ID del conjunto recién creado
        qTemp.Close;
        qTemp.SQL.Text := 'SELECT LAST_INSERT_ID() AS NUEVO_ID';
        qTemp.Open;
        IdNuevoConjunto := qTemp.FieldByName('NUEVO_ID').AsInteger;

        // 2. Copiar todos los valores al nuevo conjunto (IMPORTANTE: Copiamos también su ORDEN_ACD original)
        qTemp.Close;
        qTemp.SQL.Text :=
          'INSERT INTO fza_atributos_conjuntos_det ' +
          '(ID_CONJUNTO_ACD, ID_VALOR_ACD, ORDEN_ACD, INSTANTEALTA, USUARIOALTA, USUARIOMODIF) ' +
          'SELECT :NewConj, ID_VALOR_ACD, ORDEN_ACD, CURRENT_TIMESTAMP, ''SISTEMA'', ''SISTEMA'' ' +
          'FROM fza_atributos_conjuntos_det WHERE ID_CONJUNTO_ACD = :OldConj';
        qTemp.ParamByName('NewConj').AsInteger := IdNuevoConjunto;
        qTemp.ParamByName('OldConj').AsInteger := IdConjuntoAsignado;
        qTemp.Execute;

        // 3. Añadir el NUEVO valor que acabamos de crear a este nuevo conjunto (AÑADIMOS ORDEN_ACD)
        qTemp.Close;
        qTemp.SQL.Text :=
          'INSERT INTO fza_atributos_conjuntos_det ' +
          '(ID_CONJUNTO_ACD, ID_VALOR_ACD, ORDEN_ACD, INSTANTEALTA, USUARIOALTA, USUARIOMODIF) ' +
          'VALUES (:NewConj, :Val, :Orden, CURRENT_TIMESTAMP, ''SISTEMA'', ''SISTEMA'')';
        qTemp.ParamByName('NewConj').AsInteger := IdNuevoConjunto;
        qTemp.ParamByName('Val').AsInteger     := IdNuevoValor;
        qTemp.ParamByName('Orden').AsInteger   := OrdenVal; // <-- ¡Pasamos el orden aquí!
        qTemp.Execute;

        // 4. Desvincular el artículo del conjunto antiguo y vincularlo al nuevo (Igual que antes)
        qTemp.Close;
        qTemp.SQL.Text :=
          'UPDATE fza_articulos_conjuntos_asign ' +
          'SET ID_CONJUNTO_ACA = :NewConj ' +
          'WHERE CODIGO_ARTICULO_ACA = :Articulo AND ID_ATRIBUTO_ACA = :Atributo';
        qTemp.ParamByName('NewConj').AsInteger := IdNuevoConjunto;
        qTemp.ParamByName('Articulo').AsString := FCodigoArticulo;
        qTemp.ParamByName('Atributo').AsString := IdAtrSel;
        qTemp.Execute;
      end;
    end;
  finally
    qTemp.Free;
  end;

  // =========================================================================
  // FASE 2: MAGIA EN MEMORIA (Para no perder los checks)
  // =========================================================================

  // "Inyectamos" la nueva fila en la RAM sin recargar la consulta
  unqryDetalle.Append;
  unqryDetalle.FieldByName('ID_ATRIBUTO_VA').AsString := IdAtrSel;
  unqryDetalle.FieldByName('ID_CONJUNTO_AC').AsInteger := IdNuevoValor;
  unqryDetalle.FieldByName('NOMBRE_AC').AsString := NuevoNombre;

  // NUEVO: Inyectamos el orden en memoria
  if unqryDetalle.FindField('ORDEN_AV') <> nil then
    unqryDetalle.FieldByName('ORDEN_AV').AsInteger := OrdenVal;

  unqryDetalle.FieldByName('ASIGNADO').AsInteger := 1;
  unqryDetalle.Post;
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
