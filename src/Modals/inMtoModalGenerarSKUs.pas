{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGenerarSKUs                                         }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal para generar SKUs combinando dimensiones y valores de atributos.    }
{    Hereda de AceptCancel y devuelve el conjunto de SKUs generados.           }
{******************************************************************************}
unit inMtoModalGenerarSKUs;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoModalAceptCancel, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  Vcl.Menus, System.Actions, Vcl.ActnList, JvComponentBase, JvEnterTab,
  cxClasses, cxLocalization, Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, Data.DB,
  MemDS, DBAccess, Uni, cxControls, cxSplitter, cxStyles, cxDBData,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, UniDataConn, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, cxNavigator, dxDateRanges, dxScrollbarAnnotations,
  system.Generics.Collections, cxCheckBox, System.UITypes;

type
  TValorAtributo = record
    IdConjunto: Integer;
    NombreValor: string;
  end;

  TDimensionSKU = class
    IdAtributo: string;
    NombreAtributo: string;
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
    tvMaestroORDEN_ACA: TcxGridDBColumn;
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
    procedure tvMaestroDblClick(Sender: TObject);
    procedure tvDetalleCellDblClick(Sender: TcxCustomGridTableView;
      ACellViewInfo: TcxGridTableDataCellViewInfo; AButton: TMouseButton;
      AShift: TShiftState; var AHandled: Boolean);
  private
    FDimensiones: TObjectList<TDimensionSKU>;
    FCodigoArticulo: string;
    FTipoVariacion: string;
    FCargando: Boolean;
    procedure GenerarCombinaciones(Nivel: Integer;
                                   NombreSKU, IdsValores: string);
    procedure GuardarOrdenAtributo(const AIdAtributo: string;
                                   AOrden: Integer);
    procedure RecargarMaestro;
    procedure AsegurarFilasACA;
    function CalcularSiguienteOrdenValor(const AIdAtributo: string;
                                         AIdConjunto: Integer): Integer;
  public
    // Método para llamar a esta pantalla desde el formulario principal
    class function Ejecutar(const ACodigoArticulo,
                            ATipoVariacion: string): Boolean;
  end;

implementation

{$R *.dfm}

uses
  inLibMsgArticulos;


procedure TfrmMtoModalGenerarSKUS.GenerarCombinaciones(Nivel: Integer;
  NombreSKU, IdsValores: string);
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
    unqryMaestro.Connection.ExecSQL(
      'INSERT IGNORE INTO fza_articulos_skus ' +
      '(CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
      'ESACTIVO_SKU, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
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
          '(CODIGO_UNIDAD_SKU_SA, ID_AV_SA) ' +
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
    FreeAndNil(frm);
  end;
end;

procedure TfrmMtoModalGenerarSKUS.FormShow(Sender: TObject);
begin
  unqryMaestro.Connection := ConexionPrincipal;
  unqryDetalle.Connection := ConexionPrincipal;
  tvMaestro.OnDblClick := tvMaestroDblClick;
  RecargarMaestro;
  unqryDetalle.Close;
  unqryDetalle.SQL.Text :=
    'SELECT ID_ATB_VA, MAX(ID_AC) AS ID_AC, ' +
    'NOMBRE_AC, MIN(ORDEN_AV) AS ORDEN_AV, 0 AS ASIGNADO ' +
    'FROM ( ' +
    '  /* 1. Valores que vienen del conjunto global asignado */ ' +
    '  SELECT atr.ID_ATB_VA, val.ID_AV AS ID_AC, ' +
    '  val.AV AS NOMBRE_AC, det.ORDEN_ACD AS ORDEN_AV ' +
    '  FROM fza_variaciones_atributos atr ' +
    '  JOIN fza_articulos_conjuntos_asign asign ' +
    '    ON asign.ID_VA_ACA = atr.ID_ATB_VA ' +
    '   AND asign.CODIGO_ART_ACA = :Articulo ' +
    '  JOIN fza_atributos_conjuntos_det det ' +
    '    ON det.ID_AC_ACD = asign.ID_AC_ACA ' +
    '  JOIN fza_atributos_valores val ' +
    '    ON val.ID_AV = det.ID_AV_ACD ' +
    '  WHERE atr.ID_VAR_VA = :Variacion ' +
    '  UNION ' +
    '  /* 2. Valores que ya forman parte de algún SKU de este artículo */ ' +
    '  SELECT atr.ID_ATB_VA, val.ID_AV AS ID_AC, ' +
    '  val.AV AS NOMBRE_AC, val.ORDEN_AV AS ORDEN_AV ' +
    '  FROM fza_variaciones_atributos atr ' +
    '  JOIN fza_atributos_valores val ' +
    '    ON val.ID_VA_AV = atr.ID_ATB_VA ' +
    '  JOIN fza_atributos_sku asku ' +
    '    ON asku.ID_AV_SA = val.ID_AV ' +
    '  JOIN fza_articulos_skus skus ' +
    '    ON skus.CODIGO_UNIDAD_SKU = asku.CODIGO_UNIDAD_SKU_SA ' +
    '   AND skus.CODIGO_ART_SKU = :Articulo ' +
    '  WHERE atr.ID_VAR_VA = :Variacion ' +
    ') AS combinados ' +
    'GROUP BY ID_ATB_VA, NOMBRE_AC ' +
    'ORDER BY ORDEN_AV';
  unqryDetalle.Options.LocalMasterDetail := True;
  unqryDetalle.CachedUpdates := True;
  unqryDetalle.ParamByName('Articulo').AsString  := FCodigoArticulo;
  unqryDetalle.ParamByName('Variacion').AsString := FTipoVariacion;
  unqryDetalle.MasterSource := dsMaestro;
  unqryDetalle.MasterFields := 'ID_ATB_VA';
  unqryDetalle.Open;
  unqryDetalle.FieldByName('ASIGNADO').ReadOnly := False;
  unqryDetalle.FieldByName('ID_ATB_VA').ReadOnly := False;
  unqryDetalle.FieldByName('ID_AC').ReadOnly := False;
  unqryDetalle.FieldByName('NOMBRE_AC').ReadOnly := False;
  if unqryDetalle.FindField('ORDEN_AV') <> nil then
    unqryDetalle.FieldByName('ORDEN_AV').ReadOnly := False;
end;

procedure TfrmMtoModalGenerarSKUS.btnAceptarClick(Sender: TObject);
var
  DimDict: TObjectDictionary<string, TDimensionSKU>;
  DimActual: TDimensionSKU;
  ValorActual: TValorAtributo;
  i: Integer;
  BmMaestro: TBookmark;
  DimensionesSinValores: TStringList;
begin
  if tvMaestro.DataController.IsEditing then
    tvMaestro.DataController.Post;
  if unqryMaestro.State in [dsEdit, dsInsert] then
    unqryMaestro.Post;
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
        DimActual.IdAtributo :=
          unqryMaestro.FieldByName('ID_ATB_VA').AsString;
        DimActual.NombreAtributo :=
          unqryMaestro.FieldByName('NOMBRE_ATRIBUTO').AsString;
        DimDict.Add(DimActual.IdAtributo, DimActual);
        FDimensiones.Add(DimActual);
        unqryDetalle.First;
        while not unqryDetalle.Eof do
        begin
          if unqryDetalle.FieldByName('ASIGNADO').AsInteger = 1 then
          begin
            ValorActual.IdConjunto :=
              unqryDetalle.FieldByName('ID_AC').AsInteger;
            ValorActual.NombreValor :=
              unqryDetalle.FieldByName('NOMBRE_AC').AsString;
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
    DimensionesSinValores := TStringList.Create;
    try
      for i := 0 to FDimensiones.Count - 1 do
        if FDimensiones[i].Valores.Count = 0 then
          DimensionesSinValores.Add(FDimensiones[i].NombreAtributo);

      if FDimensiones.Count = 0 then
      begin
        ShowMessage(SErrorDimensionesSkuNoDefinidas);
        Exit;
      end;

      if DimensionesSinValores.Count = FDimensiones.Count then
      begin
        ShowMessage(SErrorValoresSkuNoSeleccionados);
        Exit;
      end;

      if DimensionesSinValores.Count > 0 then
      begin
        ShowMessage(Format(SErrorValoresDimensionesSkuIncompletos,
                           [DimensionesSinValores.CommaText]));
        Exit;
      end;
    finally
      FreeAndNil(DimensionesSinValores);
    end;
    GenerarCombinaciones(0, '', '');
    ShowMessage(SInfoCombinacionesSkuGeneradas);
  finally
    FreeAndNil(DimDict);
  end;
  inherited;
end;

procedure TfrmMtoModalGenerarSKUS.btnCancelarClick(Sender: TObject);
begin
  inherited;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

function TfrmMtoModalGenerarSKUS.CalcularSiguienteOrdenValor(
  const AIdAtributo: string; AIdConjunto: Integer): Integer;
var
  qTemp: TUniQuery;
begin
  Result := 10;
  qTemp := TUniQuery.Create(nil);
  try
    qTemp.Connection := unqryMaestro.Connection;
    if AIdConjunto > 0 then
      qTemp.SQL.Text :=
        'SELECT (FLOOR(COALESCE(MAX(ORDEN_ACD), 0) / 10) + 1) * 10 ' +
        'AS SIGUIENTE_ORDEN ' +
        'FROM fza_atributos_conjuntos_det ' +
        'WHERE ID_AC_ACD = :IdConjunto'
    else
      qTemp.SQL.Text :=
        'SELECT (FLOOR(COALESCE(MAX(ORDEN_AV), 0) / 10) + 1) * 10 ' +
        'AS SIGUIENTE_ORDEN ' +
        'FROM fza_atributos_valores ' +
        'WHERE ID_VA_AV = :IdAtributo';
    if AIdConjunto > 0 then
      qTemp.ParamByName('IdConjunto').AsInteger := AIdConjunto
    else
      qTemp.ParamByName('IdAtributo').AsString := AIdAtributo;
    qTemp.Open;
    if not qTemp.IsEmpty then
      Result := qTemp.FieldByName('SIGUIENTE_ORDEN').AsInteger;
  finally
    FreeAndNil(qTemp);
  end;
end;

procedure TfrmMtoModalGenerarSKUS.btnAddValueClick(Sender: TObject);
var
  NuevoNombre, IdAtrSel, OrdenStr, NombreConjunto: string;
  IdConjuntoAsignado, IdNuevoValor, OrdenVal, OrdenSugerido: Integer;
  Respuesta: Integer;
  qTemp: TUniQuery;
begin
  // 1. INPUTS DEL USUARIO
  NuevoNombre := Trim(InputBox(STituloAnadirValorSku,
    SSolicitudNombreValorSku, ''));
  if NuevoNombre = '' then
    Exit;
  // 2. DIMENSIÓN SELECCIONADA (Ej: 'CO' para Color)
  IdAtrSel := unqryMaestro.FieldByName('ID_ATB_VA').AsString;
  qTemp := TUniQuery.Create(nil);
  try
    qTemp.Connection := unqryMaestro.Connection;
    // =========================================================================
    // FASE 1: OBTENER EL CONJUNTO ACTUAL (Si lo tiene)
    // =========================================================================
    qTemp.SQL.Text :=
      'SELECT aca.ID_AC_ACA, ac.NOMBRE_AC ' +
      'FROM fza_articulos_conjuntos_asign aca ' +
      'LEFT JOIN fza_atributos_conjuntos ac ' +
      '  ON ac.ID_AC = aca.ID_AC_ACA ' +
      'WHERE aca.CODIGO_ART_ACA = :Articulo ' +
      '  AND aca.ID_VA_ACA = :Atributo';
    qTemp.ParamByName('Articulo').AsString := FCodigoArticulo;
    qTemp.ParamByName('Atributo').AsString := IdAtrSel;
    qTemp.Open;
    if qTemp.IsEmpty or (qTemp.FieldByName('ID_AC_ACA').AsInteger <= 0)
    then begin
      IdConjuntoAsignado := 0;
      NombreConjunto     := '';
    end
    else
    begin
      IdConjuntoAsignado := qTemp.FieldByName('ID_AC_ACA').AsInteger;
      NombreConjunto     := qTemp.FieldByName('NOMBRE_AC').AsString;
    end;
    OrdenSugerido := CalcularSiguienteOrdenValor(IdAtrSel,
                                                  IdConjuntoAsignado);
    OrdenStr := Trim(InputBox(STituloAnadirValorSku,
      SSolicitudOrdenNuevoValorSku,
      IntToStr(OrdenSugerido)));
    if OrdenStr = '' then
      Exit;
    OrdenVal := StrToIntDef(OrdenStr, OrdenSugerido);
    // =========================================================================
    // FASE 2: ASEGURARNOS DE QUE EL VALOR EXISTE EN EL DICCIONARIO MAESTRO
    // =========================================================================
    qTemp.Close;
    qTemp.SQL.Text :=
      'SELECT ID_AV FROM fza_atributos_valores ' +
      'WHERE ID_VA_AV = :IdVa AND TRIM(UPPER(AV)) = UPPER(:Valor)';
    qTemp.ParamByName('IdVa').AsString := IdAtrSel;
    qTemp.ParamByName('Valor').AsString := NuevoNombre;
    qTemp.Open;
    if not qTemp.IsEmpty then
      IdNuevoValor := qTemp.FieldByName('ID_AV').AsInteger
    else
    begin
      qTemp.Close;
      qTemp.SQL.Text :=
        'INSERT INTO fza_atributos_valores (ID_VA_AV, AV, ORDEN_AV, ' +
        'INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (:IdVa, :Valor, :Orden, CURRENT_TIMESTAMP, ''SISTEMA'', ' +
        '''SISTEMA'')';
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
    // FASE 3 y 4: LA PREGUNTA Y EL GUARDADO GLOBAL
    // =========================================================================
    if IdConjuntoAsignado > 0 then
    begin
      Respuesta := MessageDlg(
        Format(SPreguntaGuardarValorSkuGlobal,
               [NuevoNombre, NombreConjunto]),
        mtConfirmation, [mbYes, mbNo, mbCancel], 0);

      if Respuesta = mrCancel then Exit;
      if Respuesta = mrYes then
      begin
        qTemp.Close;
        qTemp.SQL.Text :=
          'INSERT IGNORE INTO fza_atributos_conjuntos_det (ID_AC_ACD, ' +
          'ID_AV_ACD, ORDEN_ACD, INSTANTE_ALTA, USUARIO_ALTA, ' +
          'USUARIO_MODIF) ' +
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
      Respuesta := MessageDlg(
        Format(SPreguntaUsarValorSkuTemporal, [NuevoNombre]),
        mtConfirmation, [mbYes, mbNo], 0);
      if Respuesta <> mrYes then Exit;
    end;
  finally
    FreeAndNil(qTemp);
  end;

  // =========================================================================
  // FASE 5: INYECCIÓN EN MEMORIA PARA GENERAR EL SKU
  // =========================================================================
  unqryDetalle.Append;
  unqryDetalle.FieldByName('ID_ATB_VA').AsString := IdAtrSel;
  unqryDetalle.FieldByName('ID_AC').AsInteger := IdNuevoValor;
  unqryDetalle.FieldByName('NOMBRE_AC').AsString := NuevoNombre;

  if unqryDetalle.FindField('ORDEN_AV') <> nil then
  begin
    unqryDetalle.FieldByName('ORDEN_AV').ReadOnly := False;
    unqryDetalle.FieldByName('ORDEN_AV').AsInteger := OrdenVal;
  end;

  unqryDetalle.FieldByName('ASIGNADO').AsInteger := 1; // Ya sale marcadito
  unqryDetalle.Post;
end;

procedure TfrmMtoModalGenerarSKUS.RecargarMaestro;
var
  IdAtrPrevio: string;
begin
  IdAtrPrevio := '';
  if unqryMaestro.Active and (not unqryMaestro.IsEmpty)
     and (unqryMaestro.FindField('ID_ATB_VA') <> nil) then
    IdAtrPrevio := unqryMaestro.FieldByName('ID_ATB_VA').AsString;
  AsegurarFilasACA;
  FCargando := True;
  try
    unqryMaestro.Close;
    unqryMaestro.SQL.Text :=
      'SELECT aca.CODIGO_ART_ACA, aca.ID_VA_ACA AS ID_ATB_VA, ' +
      '       va.ID_VAR_VA, ' +
      '       COALESCE(va.NOMBRE_VA, aca.ID_VA_ACA) ' +
      '           AS NOMBRE_ATRIBUTO, ' +
      '       va.ORDEN_VA, ' +
      '       aca.ORDEN_ACA ' +
      'FROM fza_articulos_conjuntos_asign aca ' +
      'JOIN fza_variaciones_atributos va ' +
      '  ON va.ID_ATB_VA = aca.ID_VA_ACA ' +
      ' AND va.ID_VAR_VA = :var ' +
      'WHERE aca.CODIGO_ART_ACA = :art ' +
      'ORDER BY aca.ORDEN_ACA, va.ORDEN_VA';
    unqryMaestro.ParamByName('var').AsString := FTipoVariacion;
    unqryMaestro.ParamByName('art').AsString := FCodigoArticulo;
    unqryMaestro.Open;
  finally
    FCargando := False;
  end;
  if (IdAtrPrevio <> '')
     and unqryMaestro.Locate('ID_ATB_VA', IdAtrPrevio, []) then
    ; // nos quedamos en el atributo que el usuario estaba editando
end;

procedure TfrmMtoModalGenerarSKUS.AsegurarFilasACA;
begin
  // Garantiza una fila en fza_articulos_conjuntos_asign por cada atributo
  // de la variacion. Asi el SELECT del maestro puede usar INNER JOIN y
  // UniDAC considera el campo ORDEN_ACA editable (al venir de la tabla
  // principal aca). Si la fila ya existe (con conjunto real), no la toca
  // gracias a INSERT IGNORE.
  // ORDEN_ACA se inicializa con va.ORDEN_VA para que el usuario vea
  // directamente el orden efectivo y no haga falta OnGetText.
  unqryMaestro.Connection.ExecSQL(
    'INSERT IGNORE INTO fza_articulos_conjuntos_asign ' +
    '  (CODIGO_ART_ACA, ID_AC_ACA, ID_VA_ACA, ORDEN_ACA, ' +
    '   ESGENERACION_AUTO_ACA, INSTANTE_ALTA, USUARIO_ALTA, ' +
    '   USUARIO_MODIF) ' +
    'SELECT :art, 0, va.ID_ATB_VA, va.ORDEN_VA, ''S'', ' +
    '       CURRENT_TIMESTAMP, ''SISTEMA'', ''SISTEMA'' ' +
    '  FROM fza_variaciones_atributos va ' +
    ' WHERE va.ID_VAR_VA = :var',
    [FCodigoArticulo, FTipoVariacion]);
  // Migra filas existentes que tengan ORDEN_ACA=0 (placeholder antiguo
  // o columna recien añadida) al ORDEN_VA global como valor inicial.
  unqryMaestro.Connection.ExecSQL(
    'UPDATE fza_articulos_conjuntos_asign aca ' +
    'JOIN fza_variaciones_atributos va ' +
    '  ON va.ID_ATB_VA = aca.ID_VA_ACA ' +
    ' AND va.ID_VAR_VA = :var ' +
    'SET aca.ORDEN_ACA = va.ORDEN_VA ' +
    'WHERE aca.CODIGO_ART_ACA = :art ' +
    '  AND aca.ORDEN_ACA = 0',
    [FTipoVariacion, FCodigoArticulo]);
end;

procedure TfrmMtoModalGenerarSKUS.GuardarOrdenAtributo(
  const AIdAtributo: string; AOrden: Integer);
begin
  unqryMaestro.Connection.ExecSQL(
    'INSERT INTO fza_articulos_conjuntos_asign ' +
    '  (CODIGO_ART_ACA, ID_AC_ACA, ID_VA_ACA, ORDEN_ACA, ' +
    '   ESGENERACION_AUTO_ACA, INSTANTE_ALTA, USUARIO_ALTA, ' +
    '   USUARIO_MODIF) ' +
    'VALUES (:art, 0, :atr, :ord, ''S'', CURRENT_TIMESTAMP, ' +
    '        ''SISTEMA'', ''SISTEMA'') ' +
    'ON DUPLICATE KEY UPDATE ' +
    '  ORDEN_ACA     = VALUES(ORDEN_ACA), ' +
    '  USUARIO_MODIF = VALUES(USUARIO_MODIF)',
    [FCodigoArticulo, AIdAtributo, AOrden]);
end;

procedure TfrmMtoModalGenerarSKUS.tvDetalleCellDblClick(
  Sender: TcxCustomGridTableView; ACellViewInfo: TcxGridTableDataCellViewInfo;
  AButton: TMouseButton; AShift: TShiftState; var AHandled: Boolean);
var
  IdVal, OrdenActual, Orden: Integer;
  NombreVal, OrdenStr, IdAtr, NombreConjunto: string;
  qTemp: TUniQuery;
begin
  if not unqryDetalle.Active or unqryDetalle.IsEmpty then Exit;

  // 1. Obtener los datos de la fila seleccionada
  IdVal := unqryDetalle.FieldByName('ID_AC').AsInteger;
  NombreVal := unqryDetalle.FieldByName('NOMBRE_AC').AsString;
  OrdenActual := unqryDetalle.FieldByName('ORDEN_AV').AsInteger;
  IdAtr := unqryDetalle.FieldByName('ID_ATB_VA').AsString; // Necesitamos saber de qué atributo es (Ej: 'CO')

  if IdVal <= 0 then Exit;

  // 2. Solicitar el nuevo orden al usuario
  OrdenStr := Trim(InputBox(STituloCambiarOrdenValorSku,
    Format(SSolicitudOrdenValorSku, [NombreVal]),
    IntToStr(OrdenActual)));

  if OrdenStr = '' then Exit;
  Orden := StrToIntDef(OrdenStr, -1);

  if Orden < 0 then
  begin
    ShowMessage(SErrorOrdenValorSkuNoValido);
    Exit;
  end;

  // 3. NUEVO: Comprobar si el valor pertenece a un sistema de atributos global
  qTemp := TUniQuery.Create(nil);
  try
    qTemp.Connection := unqryDetalle.Connection;
    qTemp.SQL.Text :=
      'SELECT ac.NOMBRE_AC ' +
      'FROM fza_articulos_conjuntos_asign aca ' +
      'JOIN fza_atributos_conjuntos ac ON ac.ID_AC = aca.ID_AC_ACA ' +
      'WHERE aca.CODIGO_ART_ACA = :Articulo ' +
      '  AND aca.ID_VA_ACA = :Atributo';
    qTemp.ParamByName('Articulo').AsString := FCodigoArticulo;
    qTemp.ParamByName('Atributo').AsString := IdAtr;
    qTemp.Open;

    if not qTemp.IsEmpty then
    begin
      NombreConjunto := qTemp.FieldByName('NOMBRE_AC').AsString;

      // Si tiene un nombre de conjunto, lanzamos la advertencia
      if Trim(NombreConjunto) <> '' then
      begin
        if MessageDlg(
          Format(SPreguntaCambiarOrdenValorSkuGlobal, [NombreConjunto]),
          mtWarning, [mbYes, mbNo], 0) <> mrYes then
        begin
          Exit; // Si el usuario pulsa "No", abortamos la operación silenciosamente
        end;
      end;
    end;
  finally
    qTemp.Free;
  end;

  // 4. Actualizar AMBAS tablas en la base de datos
  unqryDetalle.Connection.ExecSQL(
    'UPDATE fza_atributos_valores ' +
    'SET ORDEN_AV = :orden ' +
    'WHERE ID_AV = :id', [Orden, IdVal]);

  unqryDetalle.Connection.ExecSQL(
    'UPDATE fza_atributos_conjuntos_det ' +
    'SET ORDEN_ACD = :orden ' +
    'WHERE ID_AV_ACD = :id', [Orden, IdVal]);

  // 5. Actualizar el Dataset EN MEMORIA directamente.
  unqryDetalle.Edit;
  unqryDetalle.FieldByName('ORDEN_AV').AsInteger := Orden;
  unqryDetalle.Post;
end;

procedure TfrmMtoModalGenerarSKUS.tvMaestroDblClick(Sender: TObject);
var
  IdAtr, NombreAtr, OrdenStr: string;
  Orden, OrdenActual: Integer;
begin
  if not unqryMaestro.Active or unqryMaestro.IsEmpty then Exit;
  IdAtr := unqryMaestro.FieldByName('ID_ATB_VA').AsString;
  NombreAtr := unqryMaestro.FieldByName('NOMBRE_ATRIBUTO').AsString;
  OrdenActual := unqryMaestro.FieldByName('ORDEN_ACA').AsInteger;
  if IdAtr = '' then Exit;
  OrdenStr := Trim(InputBox(STituloCambiarOrdenAtributoSku,
    Format(SSolicitudOrdenAtributoSku, [NombreAtr]),
    IntToStr(OrdenActual)));
  if OrdenStr = '' then Exit;
  Orden := StrToIntDef(OrdenStr, -1);
  if Orden <= 0 then
  begin
    ShowMessage(SErrorOrdenAtributoSkuNoValido);
    Exit;
  end;
  GuardarOrdenAtributo(IdAtr, Orden);
  RecargarMaestro;
end;

constructor TDimensionSKU.Create;
begin
  Valores := TList<TValorAtributo>.Create;
end;

destructor TDimensionSKU.Destroy;
begin
  if Assigned(Valores) then
    FreeAndNil(Valores);
  inherited;
end;

end.
