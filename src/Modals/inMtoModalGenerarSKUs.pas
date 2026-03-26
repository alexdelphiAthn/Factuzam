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
    procedure FormShow(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
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
    unqryMaestro.Connection.ExecSQL(
      'INSERT IGNORE INTO fza_articulos_skus ' +
      '(CODIGO_UNIDAD_SKU, CODIGO_ARTICULO_SKU, ACTIVO_SKU) ' +
      'VALUES (:cod, :art, :desc, ''S'')',
      [CodigoNuevoSKU, FCodigoArticulo, NombreSKU]
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
  unqryDetalle.Open;
  unqryDetalle.FieldByName('ASIGNADO').ReadOnly := False;
end;

procedure TfrmMtoModalGenerarSKUS.btnAceptarClick(Sender: TObject);
var
  DimDict: TObjectDictionary<string, TDimensionSKU>;
  DimActual: TDimensionSKU;
  ValorActual: TValorAtributo;
  IdAtr: string;
  i: Integer;
begin
  // 1. Forzamos que se guarde cualquier check que esté a medias de editar
  if tvDetalle.DataController.IsEditing then
    tvDetalle.DataController.Post;

  // 2. FUNDAMENTAL: Asegurar que el buffer del Dataset está aceptado
  if unqryDetalle.State in [dsEdit, dsInsert] then
    unqryDetalle.Post;

  // Preparamos la lista global que usará la recursividad (sin destruir objetos automáticamente)
  if not Assigned(FDimensiones) then
    FDimensiones := TObjectList<TDimensionSKU>.Create(False);
  FDimensiones.Clear;

  // El diccionario será el dueño real de la memoria
  DimDict := TObjectDictionary<string, TDimensionSKU>.Create([doOwnsValues]);
  try
    // =======================================================================
    // 2. EL ARREGLO DEL ORDEN: Leemos primero el Maestro ordenado (1, 2...)
    // =======================================================================
    unqryMaestro.First;
    while not unqryMaestro.Eof do
    begin
      DimActual := TDimensionSKU.Create;
      DimActual.IdAtributo := unqryMaestro.FieldByName('ID_ATRIBUTO_VA').AsString;
      DimActual.NombreAtributo := unqryMaestro.FieldByName('NOMBRE_ATRIBUTO').AsString;

      // Lo añadimos al diccionario para buscar rápido, Y A LA LISTA PARA MANTENER EL ORDEN
      DimDict.Add(DimActual.IdAtributo, DimActual);
      FDimensiones.Add(DimActual); // ¡Aquí se guardan ordenados 1, 2, 3!

      unqryMaestro.Next;
    end;

    // 3. Recorremos el detalle para meter los checks marcados dentro de su dimensión
    unqryDetalle.MasterSource := nil;
    unqryDetalle.First;

    while not unqryDetalle.Eof do
    begin
      if unqryDetalle.FieldByName('ASIGNADO').AsInteger = 1 then
      begin
        IdAtr := unqryDetalle.FieldByName('ID_ATRIBUTO_VA').AsString;

        // Buscamos la dimensión (que ya creamos en el paso 2) y le añadimos el valor
        if DimDict.TryGetValue(IdAtr, DimActual) then
        begin
          ValorActual.IdConjunto := unqryDetalle.FieldByName('ID_CONJUNTO_AC').AsInteger;
          ValorActual.NombreValor := unqryDetalle.FieldByName('NOMBRE_AC').AsString;
          DimActual.Valores.Add(ValorActual);
        end;
      end;
      unqryDetalle.Next;
    end;
    unqryDetalle.MasterSource := dsMaestro;

    // 4. LIMPIEZA DE SEGURIDAD:
    // Si el usuario marcó colores pero no marcó ninguna talla, tenemos que quitar la dimensión
    // Talla de la lista para que la recursividad no se bloquee ni genere códigos con saltos nulos.
    for i := FDimensiones.Count - 1 downto 0 do
    begin
      if FDimensiones[i].Valores.Count = 0 then
        FDimensiones.Delete(i);
    end;

    // 5. PREPARAMOS LA LLAMADA
    if FDimensiones.Count = 0 then
    begin
      ShowMessage('No has marcado ningún valor nuevo para generar SKUs.');
      Exit;
    end;

    // =================================================================
    // 6. ¡LA GRAN LLAMADA A LA RECURSIVIDAD!
    // =================================================================
    GenerarCombinaciones(0, '', '');

    ShowMessage('¡Combinaciones generadas con éxito!');

  finally
    DimDict.Free; // Esto destruirá todos los TDimensionSKU limpiamente de la memoria
  end;

  inherited;
end;

procedure TfrmMtoModalGenerarSKUS.btnCancelarClick(Sender: TObject);
begin
  inherited;
  PostMessage(Handle, WM_CLOSE, 0, 0);
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
