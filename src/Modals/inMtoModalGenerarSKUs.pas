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
  CodigoNuevoSKU: string;
  ArrayIds: TArray<string>;
  IdStr: string;
begin
  if Nivel = FDimensiones.Count then
  begin
    CodigoNuevoSKU := FCodigoArticulo + '/' + NombreSKU;
//    CodigoNuevoSKU := StringReplace(CodigoNuevoSKU, ' ', '', [rfReplaceAll]);
    unqryMaestro.Connection.ExecSQL(
      'INSERT IGNORE INTO fza_articulos_skus ' +
      '(CODIGO_UNIDAD_SKU, CODIGO_ARTICULO_SKU, CODIGO_VAR_SKU, ESACTIVO_SKU, ' +
      ' INSTANTEALTA, USUARIOALTA, USUARIOMODIF) ' +
      'VALUES (:cod, :art, :var, ''S'', ' +
      ' CURRENT_TIMESTAMP, ''SISTEMA'', ''SISTEMA'')',
      [CodigoNuevoSKU, FCodigoArticulo, FTipoVariacion]
    );
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
    Exit;
  end;
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
    'SELECT ID_ATRIBUTO_VA, MAX(ID_CONJUNTO_AC) AS ID_CONJUNTO_AC, NOMBRE_AC, MIN(ORDEN_AV) AS ORDEN_AV, 0 AS ASIGNADO ' +
    'FROM ( ' +
    '    /* 1. Valores que vienen del conjunto global asignado */ ' +
    '    SELECT atr.ID_ATRIBUTO_VA, val.ID_VALOR_AV AS ID_CONJUNTO_AC, val.VALOR_AV AS NOMBRE_AC, det.ORDEN_ACD AS ORDEN_AV ' +
    '    FROM fza_variaciones_atributos atr ' +
    '    JOIN fza_articulos_conjuntos_asign asign ON asign.ID_ATRIBUTO_ACA = atr.ID_ATRIBUTO_VA ' +
    '     AND asign.CODIGO_ARTICULO_ACA = :Articulo ' +
    '    JOIN fza_atributos_conjuntos_det det ON det.ID_CONJUNTO_ACD = asign.ID_CONJUNTO_ACA ' +
    '    JOIN fza_atributos_valores val ON val.ID_VALOR_AV = det.ID_VALOR_ACD ' +
    '    WHERE atr.ID_VA = :Variacion ' +
    '    ' +
    '    UNION ' +
    '    ' +
    '    /* 2. Valores personalizados que ya forman parte de algún SKU de este artículo */ ' +
    '    SELECT atr.ID_ATRIBUTO_VA, val.ID_VALOR_AV AS ID_CONJUNTO_AC, val.VALOR_AV AS NOMBRE_AC, val.ORDEN_AV AS ORDEN_AV ' +
    '    FROM fza_variaciones_atributos atr ' +
    '    JOIN fza_atributos_valores val ON val.ID_VA_AV = atr.ID_ATRIBUTO_VA ' +
    '    JOIN fza_atributos_sku asku ON asku.ID_VALOR_SA = val.ID_VALOR_AV ' +
    '    JOIN fza_articulos_skus skus ON skus.CODIGO_UNIDAD_SKU = asku.CODIGO_UNIDAD_SA ' +
    '     AND skus.CODIGO_ARTICULO_SKU = :Articulo ' +
    '    WHERE atr.ID_VA = :Variacion ' +
    ') AS combinados ' +
    'GROUP BY ID_ATRIBUTO_VA, NOMBRE_AC ' +
    'ORDER BY ORDEN_AV';
  unqryDetalle.Options.LocalMasterDetail := True;
  unqryDetalle.CachedUpdates := True;
  unqryDetalle.ParamByName('Articulo').AsString  := FCodigoArticulo;
  unqryDetalle.ParamByName('Variacion').AsString := FTipoVariacion;
  unqryDetalle.MasterSource := dsMaestro;
  unqryDetalle.MasterFields := 'ID_ATRIBUTO_VA';
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
  NuevoNombre, IdAtrSel, OrdenStr, NombreConjunto: string;
  IdConjuntoAsignado, IdNuevoValor, OrdenVal, Respuesta: Integer;
  qTemp: TUniQuery;
begin
  // 1. INPUTS DEL USUARIO
  NuevoNombre := Trim(InputBox('Añadir nuevo valor',
             'Introduce el nombre del nuevo atributo (Ej: XXL, Turquesa):', ''));
  if NuevoNombre = '' then Exit;
  OrdenStr := Trim(InputBox('Añadir nuevo valor', 'Introduce el ORDEN (Ej: 10, 20, 30...):', '100'));
  if OrdenStr = '' then Exit;
  OrdenVal := StrToIntDef(OrdenStr, 100);
  // 2. DIMENSIÓN SELECCIONADA (Ej: 'CO' para Color)
  IdAtrSel := unqryMaestro.FieldByName('ID_ATRIBUTO_VA').AsString;
  qTemp := TUniQuery.Create(nil);
  try
    qTemp.Connection := unqryMaestro.Connection;
    // =========================================================================
    // FASE 1: OBTENER EL CONJUNTO ACTUAL (Si lo tiene)
    // =========================================================================
    qTemp.SQL.Text :=
      'SELECT aca.ID_CONJUNTO_ACA, ac.NOMBRE_AC ' +
      'FROM fza_articulos_conjuntos_asign aca ' +
      'LEFT JOIN fza_atributos_conjuntos ac ON ac.ID_CONJUNTO_AC = aca.ID_CONJUNTO_ACA ' +
      'WHERE aca.CODIGO_ARTICULO_ACA = :Articulo AND aca.ID_ATRIBUTO_ACA = :Atributo';
    qTemp.ParamByName('Articulo').AsString := FCodigoArticulo;
    qTemp.ParamByName('Atributo').AsString := IdAtrSel;
    qTemp.Open;
    if qTemp.IsEmpty or (qTemp.FieldByName('ID_CONJUNTO_ACA').AsInteger <= 0) then
    begin
      IdConjuntoAsignado := 0;
      NombreConjunto     := '';
    end
    else
    begin
      IdConjuntoAsignado := qTemp.FieldByName('ID_CONJUNTO_ACA').AsInteger;
      NombreConjunto     := qTemp.FieldByName('NOMBRE_AC').AsString;
    end;
    // =========================================================================
    // FASE 2: ASEGURARNOS DE QUE EL VALOR EXISTE EN EL DICCIONARIO MAESTRO
    // =========================================================================
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
      qTemp.Close;
      qTemp.SQL.Text :=
        'INSERT INTO fza_atributos_valores (ID_VA_AV, VALOR_AV, ORDEN_AV, INSTANTEALTA, USUARIOALTA, USUARIOMODIF) ' +
        'VALUES (:IdVa, :Valor, :Orden, CURRENT_TIMESTAMP, ''SISTEMA'', ''SISTEMA'')';
      qTemp.ParamByName('IdVa').AsString   := IdAtrSel;
      qTemp.ParamByName('Valor').AsString  := NuevoNombre;
      qTemp.ParamByName('Orden').AsInteger := OrdenVal;
      qTemp.Execute;
      qTemp.Close;
      qTemp.SQL.Text := 'SELECT LAST_INSERT_ID() AS NUEVO_ID';
      qTemp.Open;
      IdNuevoValor := qTemp.FieldByName('NUEVO_ID').AsInteger;
    end;
    // =========================================================================
    // FASE 3 y 4: LA PREGUNTA Y EL GUARDADO GLOBAL (Depende de si hay conjunto)
    // =========================================================================
    if IdConjuntoAsignado > 0 then
    begin
      // TIENE CONJUNTO: Preguntamos si lo quiere global o de usar y tirar
      Respuesta := MessageDlg(
        'Va a utilizar el valor "' + NuevoNombre + '".' + #13#10#13#10 +
        '¿Desea guardarlo de forma permanente en el conjunto global "' +
        NombreConjunto + '" ' +
        'para que aparezca disponible siempre para otros artículos?' +
        #13#10#13#10 +
        '[SÍ] -> Añadir al conjunto global' + #13#10 +
        '[NO] -> Usar SOLO ESTA VEZ para generar el SKU (no se guarda en el' +
        ' conjunto)',
        mtConfirmation, [mbYes, mbNo, mbCancel], 0);
      if Respuesta = mrCancel then Exit;
      if Respuesta = mrYes then
      begin
        qTemp.Close;
        qTemp.SQL.Text :=
          'INSERT IGNORE INTO fza_atributos_conjuntos_det (ID_CONJUNTO_ACD, ' +
          'ID_VALOR_ACD, ORDEN_ACD, INSTANTEALTA, USUARIOALTA, USUARIOMODIF) ' +
          'VALUES (:Conj, :Val, :Orden, CURRENT_TIMESTAMP, ''SISTEMA'',' +
          ' ''SISTEMA'')';
        qTemp.ParamByName('Conj').AsInteger  := IdConjuntoAsignado;
        qTemp.ParamByName('Val').AsInteger   := IdNuevoValor;
        qTemp.ParamByName('Orden').AsInteger := OrdenVal;
        qTemp.Execute;
      end;
    end
    else
    begin
      // NO TIENE CONJUNTO: Avisamos de que será de usar y tirar
      Respuesta := MessageDlg(
        'El artículo no tiene un conjunto global asignado.' + #13#10#13#10 +
        'El valor "' + NuevoNombre +
        '" se utilizará SOLO ESTA VEZ para generar el SKU de este artículo, ' +
        'pero no se guardará en ninguna lista de conjuntos.' + #13#10#13#10 +
        '¿Desea continuar?',
        mtConfirmation, [mbYes, mbNo], 0);
      if Respuesta <> mrYes then Exit;
    end;
  finally
    qTemp.Free;
  end;
  // =========================================================================
  // FASE 5: INYECCIÓN EN MEMORIA PARA GENERAR EL SKU (Ocurre siempre)
  // =========================================================================
  unqryDetalle.Append;
  unqryDetalle.FieldByName('ID_ATRIBUTO_VA').AsString := IdAtrSel;
  unqryDetalle.FieldByName('ID_CONJUNTO_AC').AsInteger := IdNuevoValor;
  unqryDetalle.FieldByName('NOMBRE_AC').AsString := NuevoNombre;
  if unqryDetalle.FindField('ORDEN_AV') <> nil then
  begin
    unqryDetalle.FieldByName('ORDEN_AV').ReadOnly := False;
    unqryDetalle.FieldByName('ORDEN_AV').AsInteger := OrdenVal;
  end;
  unqryDetalle.FieldByName('ASIGNADO').AsInteger := 1; // Ya sale marcadito
  unqryDetalle.Post;
end;

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
