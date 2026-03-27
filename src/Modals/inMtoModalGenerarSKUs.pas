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

  // 1. Cargamos el grid Maestro
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

// 2. Cargamos el grid Detalle con los VALORES reales (Tallas y Colores)
  unqryDetalle.Close;
unqryDetalle.Close;
  unqryDetalle.SQL.Text :=
    'SELECT ' +
    '  atr.ID_ATRIBUTO_VA, ' +
    '  val.ID_VALOR_AV AS ID_CONJUNTO_AC, ' +
    '  val.VALOR_AV AS NOMBRE_AC, ' +
    '  0 AS ASIGNADO ' + // Siempre desmarcado por defecto
    'FROM fza_variaciones_atributos atr ' +
    'JOIN fza_articulos_conjuntos_asign asign ' +
    '  ON asign.ID_ATRIBUTO_ACA = atr.ID_ATRIBUTO_VA ' +
    ' AND asign.CODIGO_ARTICULO_ACA = :Articulo ' +
    'JOIN fza_atributos_conjuntos_det det ' +
    '  ON det.ID_CONJUNTO_ACD = asign.ID_CONJUNTO_ACA ' +
    'JOIN fza_atributos_valores val ' +
    '  ON val.ID_VALOR_AV = det.ID_VALOR_ACD ' +
    'WHERE atr.ID_VA = :Variacion ' +
    'ORDER BY atr.ORDEN_VA, val.VALOR_AV';

  // Configuración Maestro-Detalle automática
  unqryDetalle.MasterSource := dsMaestro;
  unqryDetalle.MasterFields := 'ID_ATRIBUTO_VA';
  unqryDetalle.DetailFields := 'ID_ATRIBUTO_VA';

  // Paso de parámetros
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
  BmMaestro: TBookmark; // Para recordar dónde estaba el usuario
begin
  // 1. Asegurar que lo que el usuario acaba de hacer clic se guarda en memoria
  if tvDetalle.DataController.IsEditing then
    tvDetalle.DataController.Post;
  if unqryDetalle.State in [dsEdit, dsInsert] then
    unqryDetalle.Post;

  if not Assigned(FDimensiones) then
    FDimensiones := TObjectList<TDimensionSKU>.Create(False);
  FDimensiones.Clear;

  DimDict := TObjectDictionary<string, TDimensionSKU>.Create([doOwnsValues]);
  try
    // Guardamos la posición actual para no volver loco al Grid visual
    BmMaestro := unqryMaestro.GetBookmark;

    // Apagamos los grids temporalmente para que el usuario no vea "parpadeos"
//    unqryMaestro.DisableControls;
//    unqryDetalle.DisableControls;
    tvMaestro.BeginUpdate;
    tvDetalle.BeginUpdate;
    try
      // =================================================================
      // 2. RECORREMOS EL MAESTRO (Sin romper el MasterSource)
      // =================================================================
      unqryMaestro.First;
      while not unqryMaestro.Eof do
      begin
        // Creamos la dimensión (Talla, Color...)
        DimActual := TDimensionSKU.Create;
        DimActual.IdAtributo := unqryMaestro.FieldByName('ID_ATRIBUTO_VA').AsString;
        DimActual.NombreAtributo := unqryMaestro.FieldByName('NOMBRE_ATRIBUTO').AsString;

        DimDict.Add(DimActual.IdAtributo, DimActual);
        FDimensiones.Add(DimActual);

        // Como nos hemos movido en el maestro, el unqryDetalle AHORA SOLO TIENE
        // los valores de esta dimensión. ¡Los leemos con total seguridad!
        unqryDetalle.First;
        while not unqryDetalle.Eof do
        begin
          // Si está marcado, lo metemos a la lista
          if unqryDetalle.FieldByName('ASIGNADO').AsInteger = 1 then
          begin
            ValorActual.IdConjunto := unqryDetalle.FieldByName('ID_CONJUNTO_AC').AsInteger;
            ValorActual.NombreValor := unqryDetalle.FieldByName('NOMBRE_AC').AsString;
            DimActual.Valores.Add(ValorActual);
          end;
          unqryDetalle.Next;
        end;

        unqryMaestro.Next; // Pasamos a la siguiente dimensión
      end;
    finally
      // Restauramos todo para que la pantalla quede como estaba
      if unqryMaestro.BookmarkValid(BmMaestro) then
        unqryMaestro.GotoBookmark(BmMaestro);
      unqryMaestro.FreeBookmark(BmMaestro);
//      unqryDetalle.EnableControls;
//      unqryMaestro.EnableControls;
        tvDetalle.EndUpdate;
        tvMaestro.EndUpdate;
    end;

    // 3. LIMPIEZA: Borrar las dimensiones donde no marcó ningún check
    for i := FDimensiones.Count - 1 downto 0 do
    begin
      if FDimensiones[i].Valores.Count = 0 then
        FDimensiones.Delete(i);
    end;

    // 4. GENERAR SKUS
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
  NuevoNombre := Trim(InputBox('Añadir nuevo valor', 'Introduce el nombre (Ej: XXL, Turquesa):', ''));

  // Si el usuario le da a Cancelar o lo deja en blanco, nos salimos sin hacer nada
  if NuevoNombre = '' then Exit;

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
      ShowMessage('Error: El artículo no tiene un grupo asignado para esta dimensión.');
      Exit;
    end;
    IdConjuntoAsignado := qTemp.FieldByName('ID_CONJUNTO_ACA').AsInteger;
    qTemp.Close;

    // B. Comprobamos si el valor (ej. "XXL") ya existe en la base de datos global
    qTemp.SQL.Text := 'SELECT ID_VALOR_AV FROM fza_atributos_valores WHERE VALOR_AV = :Valor';
    qTemp.ParamByName('Valor').AsString := NuevoNombre;
    qTemp.Open;

    if not qTemp.IsEmpty then
      IdNuevoValor := qTemp.FieldByName('ID_VALOR_AV').AsInteger
    else
    begin
      // Si es totalmente nuevo, lo insertamos
      qTemp.Close;
      qTemp.SQL.Text :=
        'INSERT INTO fza_atributos_valores ' +
        '(ID_VA_AV, VALOR_AV, INSTANTEALTA, USUARIOALTA, USUARIOMODIF) ' +
        'VALUES (:IdVa, :Valor, CURRENT_TIMESTAMP, ''SISTEMA'', ''SISTEMA'')';
      qTemp.ParamByName('IdVa').AsString := IdAtrSel;
      qTemp.ParamByName('Valor').AsString := NuevoNombre;
      qTemp.Execute;
      // Obtenemos el ID que MySQL le acaba de asignar mágicamente
      qTemp.Close;
      qTemp.SQL.Text := 'SELECT LAST_INSERT_ID() AS NUEVO_ID';
      qTemp.Open;
      IdNuevoValor := qTemp.FieldByName('NUEVO_ID').AsInteger;
    end;
    qTemp.Close;
    // C. Vinculamos el valor al grupo del artículo
    qTemp.SQL.Text :=
      'INSERT IGNORE INTO fza_atributos_conjuntos_det (ID_CONJUNTO_ACD, ID_VALOR_ACD) ' +
      'VALUES (:Conj, :Val)';
    qTemp.ParamByName('Conj').AsInteger := IdConjuntoAsignado;
    qTemp.ParamByName('Val').AsInteger  := IdNuevoValor;
    qTemp.Execute;

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

  // ¡Lo dejamos marcado con el check automáticamente por comodidad!
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
