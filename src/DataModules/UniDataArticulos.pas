{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataArticulos                                              }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de artículos.                                                 }
{    Queries de fza_articulos, tarifas, proveedores, variaciones, SKUs y stock.}
{******************************************************************************}
unit UniDataArticulos;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, UniDataConn,  cxListView, Vcl.Forms, vcl.dialogs,
  Vcl.ComCtrls, Winapi.Windows, system.strUtils, cxGridDBTableView,
  System.Variants, vcl.Controls, Datasnap.Provider, Datasnap.DBClient,
  frxClass, frxDBSet;

type
  TdmArticulos = class(TdmBase)
    unqryFamiliaArticulos: TUniQuery;
    dsFamiliaArticulos: TDataSource;
    unqryTarifasArticulos: TUniQuery;
    dsTarifasArticulos: TDataSource;
    unqryProveedoresArticulos: TUniQuery;
    dsProveedoresArticulos: TDataSource;
    unqryLinFacturasArticulos: TUniQuery;
    dsLinFacturasArticulos: TDataSource;
    unqryProveedores: TUniQuery;
    dsProveedores: TDataSource;
    unqryTiposIVA: TUniQuery;
    dsTiposIVA: TDataSource;
    unqryTarifas: TUniQuery;
    dsTarifas: TDataSource;
    unqryVariaciones: TUniQuery;
    dsVariaciones: TDataSource;
    unqryVariacionesArticulos: TUniQuery;
    dsVariacionesArticulos: TDataSource;
    unqrySkus: TUniQuery;
    dsSkus: TDataSource;
    unqryStockArticulos: TUniQuery;
    dsStockArticulos: TDataSource;
    unqryMovimientosArticulos: TUniQuery;
    dsMovimientosArticulos: TDataSource;
    unqryDetallesAtributos: TUniQuery;
    dsDetallesAtributos: TDataSource;
    unqryArtPrint: TUniQuery;
    dtstprvEtiquetasArt: TDataSetProvider;
    cdsEtiquetasArt: TClientDataSet;
    dsEtiquetasArt: TDataSource;
    fxdsEtiquetasArt: TfrxDBDataset;
    unqryAlmacenesPrint: TUniQuery;
    unqryTarifasPrint: TUniQuery;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGAfterDelete(DataSet: TDataSet);
    procedure unqryProveedoresArticulosBeforePost(DataSet: TDataSet);
    procedure unqryTarifasArticulosBeforePost(DataSet: TDataSet);
    procedure unqryStockArticulosAfterScroll(DataSet: TDataSet);
    procedure unqryVariacionesArticulosBeforePost(DataSet: TDataSet);
    procedure unqryVariacionesArticulosBeforeDelete(DataSet: TDataSet);
    procedure unqrySkusBeforePost(DataSet: TDataSet);
    procedure unqrySkusBeforeDelete(DataSet: TDataSet);
  private
    procedure QuitarEscribiblesVista;
    procedure ActualizarSkuActivo(const aSku, aActivo: string);
    procedure UpsertCosteSku(const aSku: string;
                             aPrecioField, aFechaField: TField);
    procedure EliminarCosteSku(const aSku: string);
    procedure ExpandirEtiquetasPorStock(const aFldStock: string);
  public
    procedure GetCodigoAutoArticulo;
    function ArticuloTieneProvPrin(sArt:String):Boolean;
    procedure CopiarProveedoraArticulo(dtProveedores:TDataset);
    procedure FillTarifas(lst:TcxListView);
    function ReconstruirStock: string;
    function ObtenerPrecioTarifaPadre(const aCodArt,
                                            aCodTarifa: string): Double;
    // El modal de etiquetas se nutre de estas tres rutinas: dos para
    // poblar tarifa y almacenes, y la tercera para construir el dataset
    // que consume el FastReport.
    procedure CargarTarifasEtiquetas(items: TStrings; codigos: TStrings;
                                     var aIdxDefault: Integer);
    procedure CargarAlmacenesEtiquetas(lst: TcxListView);
    procedure CrearDataSetEtiquetasArt(const aCodigoArt,
                                             aCodTarifa,
                                             aAlmacenesCsv: string;
                                             aFechaTarifa: TDateTime);
  end;

//var
//  dmArticulos: TdmArticulos;

implementation

uses
  inMtoArticulos,
  inLibGlobalVar,
  inLibtb;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

function TdmArticulos.ArticuloTieneProvPrin(sArt:String):Boolean;
var
  unqrySol: TUniQuery;
begin
  unqrySol := TUniQuery.Create(nil);
  unqrySol.Connection := oConn;
  unqrySol.SQL.Text := 'SELECT * ' +
                       '  FROM vi_articulos_proveedores ' +
                       ' WHERE CODIGO_ART_ART = :CODIGO_ART_ART' +
                       '   AND ESPROVEEDORPRINCIPAL = ' + QuotedStr('S');
  unqrySol.ParamByName('CODIGO_ART_ART').AsString := sArt;
  unqrySol.Open;
  if (unqrySol.RecordCount > 0) then
  begin
    Result := True
  end
  else
    Result := False;
  unqrySol.Close;
  FreeAndNil(unqrySol);
end;

procedure TdmArticulos.ActualizarSkuActivo(const aSku, aActivo: string);
var
  qry: TUniQuery;
begin
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'UPDATE fza_articulos_skus '   +
      '   SET ESACTIVO_SKU = :ACT, ' +
      '       USUARIO_MODIF = :USR ' +
      ' WHERE CODIGO_UNIDAD_SKU = :SKU';
    qry.ParamByName('ACT').AsString := aActivo;
    qry.ParamByName('USR').AsString := oUser;
    qry.ParamByName('SKU').AsString := aSku;
    qry.ExecSQL;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmArticulos.unqryVariacionesArticulosBeforePost(DataSet: TDataSet);
var
  fldCB, fldAct, fldSku: TField;
  sSku: string;
  bChangedActivo: Boolean;
begin
  inherited;

  fldCB  := DataSet.FindField('CODIGO_BARRAS_CB');
  fldAct := DataSet.FindField('ESACTIVO_SKU');
  fldSku := DataSet.FindField('CODIGO_UNIDAD_SKU');
  if fldSku = nil then Exit;

  sSku := fldSku.AsString;

  if DataSet.State = dsInsert then
  begin
    if Trim(sSku) = '' then
      raise ERangeError.Create(
        'Indique el código de SKU al añadir un nuevo código de barras. ' +
        'Para crear un SKU nuevo use la pestaña SKUs.');
    if (fldCB = nil) then
      raise ERangeError.Create('Falta el campo CODIGO_BARRAS_CB.');
    oDmConn.ActualizarUserTimeModif(DataSet);
    Exit; // El framework lanza SQLInsert
  end;

  if DataSet.State <> dsEdit then Exit;

  oDmConn.ActualizarUserTimeModif(DataSet);

  bChangedActivo := (fldAct <> nil) and
                    (VarToStr(fldAct.OldValue) <> fldAct.AsString);

  // ESACTIVO_SKU vive en fza_articulos_skus, no en fza_codigos_barras.
  // El SQLUpdate del framework no lo tocaría: lo actualizamos a mano.
  if bChangedActivo then
    ActualizarSkuActivo(sSku, fldAct.AsString);
end;

procedure TdmArticulos.unqrySkusBeforePost(DataSet: TDataSet);
var
  fldPrecio, fldFecha: TField;
begin
  inherited;
  if DataSet.State = dsInsert then
  begin
    if Trim(DataSet.FieldByName('CODIGO_UNIDAD_SKU').AsString) = '' then
      raise ERangeError.Create('Indique el código del SKU.');
    // Article code se hereda del master/detail, pero por seguridad lo
    // forzamos al artículo activo si está vacío.
    if Trim(DataSet.FieldByName('CODIGO_ART_SKU').AsString) = '' then
      DataSet.FieldByName('CODIGO_ART_SKU').AsString :=
                              unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
  end;
  oDmConn.ActualizarUserTimeModif(DataSet);

  // El SQLInsert / SQLUpdate del framework sólo escribe en fza_articulos_skus.
  // El coste y la fecha de última compra viven en fza_articulos_skus_costes:
  // los volcamos aquí mediante UPSERT.
  fldPrecio := DataSet.FindField('PRECIO_ULT_COMPRA_SKUC');
  fldFecha  := DataSet.FindField('FECHA_ULT_COMPRA_SKUC');
  if (fldPrecio <> nil) or (fldFecha <> nil) then
    UpsertCosteSku(DataSet.FieldByName('CODIGO_UNIDAD_SKU').AsString,
                   fldPrecio, fldFecha);
end;

procedure TdmArticulos.unqrySkusBeforeDelete(DataSet: TDataSet);
begin
  inherited;
  // Sin FK declarada, la fila de coste quedaría huérfana al borrar el SKU:
  // la limpiamos antes de que el framework dispare el DELETE sobre
  // fza_articulos_skus.
  EliminarCosteSku(DataSet.FieldByName('CODIGO_UNIDAD_SKU').AsString);
end;

procedure TdmArticulos.UpsertCosteSku(const aSku: string;
                                     aPrecioField, aFechaField: TField);
var
  qry: TUniQuery;
begin
  if Trim(aSku) = '' then Exit;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'INSERT INTO fza_articulos_skus_costes '                              +
      '       (CODIGO_UNIDAD_SKU_SKUC, PRECIO_ULT_COMPRA_SKUC, '            +
      '        FECHA_ULT_COMPRA_SKUC, '                                     +
      '        INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) '                +
      'VALUES (:SKU, :PRECIO, :FECHA, '                                     +
      '        CURRENT_TIMESTAMP, :USR, :USR) '                             +
      'ON DUPLICATE KEY UPDATE '                                            +
      '   PRECIO_ULT_COMPRA_SKUC = VALUES(PRECIO_ULT_COMPRA_SKUC), '        +
      '   FECHA_ULT_COMPRA_SKUC  = VALUES(FECHA_ULT_COMPRA_SKUC), '         +
      '   USUARIO_MODIF          = VALUES(USUARIO_MODIF)';
    qry.ParamByName('SKU').AsString := aSku;
    if (aPrecioField <> nil) and not aPrecioField.IsNull then
      qry.ParamByName('PRECIO').AsFloat := aPrecioField.AsFloat
    else
      qry.ParamByName('PRECIO').Clear;
    if (aFechaField <> nil) and not aFechaField.IsNull then
      qry.ParamByName('FECHA').AsDateTime := aFechaField.AsDateTime
    else
      qry.ParamByName('FECHA').Clear;
    qry.ParamByName('USR').AsString := oUser;
    qry.ExecSQL;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmArticulos.EliminarCosteSku(const aSku: string);
var
  qry: TUniQuery;
begin
  if Trim(aSku) = '' then Exit;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'DELETE FROM fza_articulos_skus_costes ' +
      ' WHERE CODIGO_UNIDAD_SKU_SKUC = :SKU';
    qry.ParamByName('SKU').AsString := aSku;
    qry.ExecSQL;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmArticulos.unqryVariacionesArticulosBeforeDelete(DataSet: TDataSet);
var
  fldId: TField;
begin
  inherited;
  // Defensivo por si la vista volviera a permitir filas sin ID_CB:
  // sin ID_CB no hay nada que borrar en fza_codigos_barras.
  fldId := DataSet.FindField('ID_CB');
  if (fldId = nil) or fldId.IsNull then
    raise ERangeError.Create(
      'Esta fila no representa un código de barras existente. No hay ' +
      'nada que eliminar.');
end;

procedure TdmArticulos.unqryProveedoresArticulosBeforePost(DataSet: TDataSet);
begin
  inherited;
  with unqryProveedoresArticulos do
  if (State = dsInsert) then
    if Trim(FindField('ESPROVEEDORPRINCIPAL').AsString) = 'S' then
    begin
      if (ArticuloTieneProvPrin(FindField('CODIGO_ART_ART').AsString)) then
      begin
        raise ERangeError.CreateFmt('%s ya tiene un proveedor principal ' +
                                    'asociado a este artículo.',
                                       [FindField('CODIGO_ART_ART').AsString]);
      end;
    end;
  oDmConn.ActualizarUserTimeModif(DataSet);
end;

procedure TdmArticulos.unqryStockArticulosAfterScroll(DataSet: TDataSet);
var
  tvArticulosStock:TcxGridDBTableView;
  i:Integer;
begin
  inherited;
  if DataSet.ControlsDisabled then Exit;
  if not DataSet.Active or DataSet.IsEmpty then Exit;
//  DataSet.AfterScroll := nil;
  unqryStockArticulos.Close;
  unqryStockArticulos.ParamByName('CODIGO_ART_ART').AsString :=
                            unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
  if unqryStockArticulos.ParamByName('CODIGO_ART_ART').AsString <> '' then
  begin
    unqryStockArticulos.Open;
    tvArticulosStock :=  (GetOwnerForm<TfrmMtoArticulos>).tvStock;
    tvArticulosStock.BeginUpdate;
     try
     tvArticulosStock.ClearItems;
     tvArticulosStock.DataController.CreateAllItems;

    // 3. Aplicamos el BestFit a todas las columnas para que se ajusten al texto perfecto
//     (GetOwnerForm<TfrmMtoArticulos>).tvStock.ApplyBestFit;
     finally
      tvArticulosStock.EndUpdate;
     end;
     if unqryStockArticulos.Active and (tvArticulosStock.ColumnCount > 0) then
     begin
       for i := 0 to tvArticulosStock.ColumnCount - 1 do
       begin
         tvArticulosStock.Columns[i].ApplyBestFit;
       end;
     end;
    //DataSet.AfterScroll := unqryStockArticulosAfterScroll;
    // Opcional: Si además quieres que las columnas se estiren para ocupar todo el ancho
    // visual del grid y no quede espacio en blanco a la derecha:
    // cxGrid1DBTableView1.OptionsView.ColumnAutoWidth := True;
  end;
end;

procedure TdmArticulos.unqryTablaGAfterDelete(DataSet: TDataSet);
var
  qryBorrarLineas : TUniQuery;
begin
  with qryBorrarLineas do
  begin
//  if not( Application.MessageBox(  '¿Desea borrar también tarifas y ' +
//                                   'proveedores de la ficha del artículo?',
//                                   'Mensaje Advertencia',
//                                   MB_YESNO ) = ID_YES ) then
//    begin
    qryBorrarLineas := TUniQuery.Create(Self);
    Connection := inLibGlobalVar.oConn;
    SQL.Text := 'DELETE ' +
                '  FROM fza_articulos_proveedores ' +
                ' WHERE CODIGO_ART_AP = :Articulo ;';
    Params.ParamByName('Articulo').AsString :=
                            unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
    ExecSQL;
    SQL.Text := 'DELETE ' +
                '  FROM fza_articulos_tarifas ' +
                ' WHERE CODIGO_ART_ARTTAR = :Articulo ;';
    Params.ParamByName('Articulo').AsString :=
                            unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
    ExecSQL;
    Free;
  end;
//  end;
end;

procedure TdmArticulos.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  AplicarValoresPorDefecto(unqryTablaG, 'fza_articulos');
  unqryTablaG.FindField('CODIGO_FAM_ART').AsString :=
                                   GetDefaultValue('vi_articulos_familias_list',
                                                   'CODIGO_FAM_FAM',
                                                   'ESDEFAULT_FAM');
end;

procedure TdmArticulos.CopiarProveedoraArticulo(dtProveedores: TDataset);
begin
  with unqryProveedoresArticulos do
  begin
    if (State = dsBrowse) then
      Insert;
    FindField('CODIGO_PRV_PRV').AsString :=
                           dtProveedores.FindField('CODIGO_PRV_PRV').AsString;
    FindField('RAZON_SOCIAL_PRV').AsString :=
                      dtProveedores.FindField('RAZON_SOCIAL_PRV').AsString;
    if RecordCount = 0 then
      FindField('ESPROVEEDORPRINCIPAL').AsString := 'S'
    else
      FindField('ESPROVEEDORPRINCIPAL').AsString := 'N';
    Post;
  end;
end;

procedure TdmArticulos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryFamiliaArticulos.Connection := oConn;
  unqryPerfiles.Connection := oConn;
  unqryTarifasArticulos.Connection := oConn;
  unqryProveedoresArticulos.Connection := oConn;
  unqryLinFacturasArticulos.Connection := oConn;
  unqryProveedores.Connection := oConn;
  unqryTiposIVA.Connection := oConn;
  unqryTarifas.Connection := oConn;
  unqryVariacionesArticulos.Connection := oConn;
  unqrySkus.Connection := oConn;
  unqryStockArticulos.Connection := oConn;
  unqryMovimientosArticulos.Connection := oConn;
//  unqryStockArticulos.MasterSource := (GetOwnerForm<TfrmMtoArticulos>).dsTablaG;
  unqryVariacionesArticulos.MasterSource :=
                                      (GetOwnerForm<TfrmMtoArticulos>).dsTablaG;
  unqrySkus.MasterSource :=
                                      (GetOwnerForm<TfrmMtoArticulos>).dsTablaG;
  unqryLinFacturasArticulos.MasterSource :=
                                      (GetOwnerForm<TfrmMtoArticulos>).dsTablaG;
  unqryTarifasArticulos.MasterSource :=
                                      (GetOwnerForm<TfrmMtoArticulos>).dsTablaG;
  unqryProveedoresArticulos.MasterSource :=
                                      (GetOwnerForm<TfrmMtoArticulos>).dsTablaG;
  unqryMovimientosArticulos.MasterSource :=
                                      (GetOwnerForm<TfrmMtoArticulos>).dsTablaG;
  unqryTiposIVA.Open;
  unqryFamiliaArticulos.Open;
  unqryTarifasArticulos.Open;
  unqryProveedoresArticulos.Open;
  unqryLinFacturasArticulos.Open;
  unqryVariaciones.Open;
  unqryVariacionesArticulos.Open;
  unqrySkus.Open;
  unqryStockArticulos.Open;
  unqryMovimientosArticulos.Open;
  QuitarEscribiblesVista;
end;

procedure TdmArticulos.QuitarEscribiblesVista;
const
  // Únicas columnas que pertenecen realmente a fza_articulos_tarifas
  CamposEscribibles: array[0..14] of string = (
    'CODIGO_ART_ARTTAR',  'CODIGO_UNICO_ARTTAR',  'CODIGO_UNIDAD_ARTTAR',
    'CODIGO_TAR_ARTTAR',  'ESACTIVO_ARTTAR',
    'PRECIO_SALIDA_ARTTAR','PRECIO_FINAL_ARTTAR','PRECIO_DTO_ARTTAR','PORCENTAJE_DTO_ARTTAR',
    'FECHA_DESDE_ARTTAR', 'FECHA_HASTA_ARTTAR',
    'INSTANTE_MODIF',     'INSTANTE_ALTA',         'USUARIO_ALTA',  'USUARIO_MODIF'
  );

  function EsEscribible(const NombreCampo: string): Boolean;
  var s: string;
  begin
    Result := False;
    for s in CamposEscribibles do
      if SameText(s, NombreCampo) then Exit(True);
  end;

var
  i: Integer;
begin
  inherited;
  if not unqryTarifasArticulos.Active then
    unqryTarifasArticulos.Open;
  for i := 0 to unqryTarifasArticulos.Fields.Count - 1 do
    if not EsEscribible(unqryTarifasArticulos.Fields[i].FieldName) then
      unqryTarifasArticulos.Fields[i].Required := False;
end;

procedure TdmArticulos.FillTarifas(lst: TcxListView);
var
  Itm: TListItem;
begin
  lst.Clear;
  with unqryTarifas do
  begin
    if ContainsText(SQL.Text, ':CODIGO_ART_ART') then
      ParamByName('CODIGO_ART_ART').AsString :=
                            unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
    Open;
    First;
    while not (Eof) do
    begin
      Itm := lst.Items.Add;
      Itm.Caption := FindField('CODIGO_TAR_ARTTAR').AsString;
      Itm.SubItems.Add(FindField('NOMBRE_TAR_TAR').AsString);
      if FieldByName('ESDEFAULT_TAR').AsString = 'S' then
        Itm.Checked := True;
      Next;
    end;
    Close;
  end;
end;

procedure TdmArticulos.GetCodigoAutoArticulo;
begin
  if unqryTablaG.FindField('CODIGO_ART_ART').AsString = '0' then
  begin
    unqryTablaG.FindField('CODIGO_ART_ART').AsString :=
                                                 ObtenerSiguienteContador('AR');
  end;
  if unqryTablaG.FindField('ORDEN_ART').AsString = '0' then
  begin
      unqryTablaG.FindField('ORDEN_ART').AsString :=
                                                 ObtenerSiguienteContador('AO');
  end;
end;

procedure TdmArticulos.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  with unqryTablaG do
  begin
    var sDescripcion := Trim(FindField('DESCRIPCION_ART').AsString);
    if (sDescripcion = '') or (SimbolosProhibidos(sDescripcion)) then
    begin
      raise ERangeError.CreateFmt('%s no es un valor válido ' +
                                       'para el campo Descripción de Artículos',
               [FindField('DESCRIPCION_ART').AsString]);
        Abort;
    end
    else
      GetCodigoAutoArticulo;
  end;
end;

procedure TdmArticulos.unqryTarifasArticulosBeforePost(DataSet: TDataSet);
var
  unqrySol: TUniQuery;
  PKValue: Integer;
  oldPrecio, newPrecio: Double;
  esActivo: string;
  vOld: Variant;
begin
  inherited;
  with unqryTarifasArticulos do
  begin
    // 1. Averiguamos el ID del registro actual.
    // Si estamos insertando uno nuevo, le damos un valor que no existe (-1)
    if State = dsInsert then
    begin
      FieldByName('CODIGO_UNICO_ARTTAR').Required := False;
      FieldByName('CODIGO_UNICO_ARTTAR').AutoGenerateValue := arAutoInc;
      PKValue := -1;
    end
    else
    begin
      // Si estamos editando, cogemos su ID real
      PKValue := FieldByName('CODIGO_UNICO_ARTTAR').AsInteger;
    end;

    // ----------------------------------------------------------------
    // Activación / desactivación según transición del precio de salida
    // ----------------------------------------------------------------
    newPrecio := FindField('PRECIO_SALIDA_ARTTAR').AsFloat;
    esActivo  := FindField('ESACTIVO_ARTTAR').AsString;

    if State = dsInsert then
    begin
      // En alta, si nace a 0 lo dejamos inactivo por defecto (sin preguntar).
      // Las altas con precio>0 conservan el ESACTIVO que les haya puesto el alta masiva.
      if newPrecio = 0 then
        FindField('ESACTIVO_ARTTAR').AsString := 'N';
    end
    else if State = dsEdit then
    begin
      vOld := FindField('PRECIO_SALIDA_ARTTAR').OldValue;
      if VarIsNull(vOld) or VarIsEmpty(vOld) then
        oldPrecio := 0
      else
        oldPrecio := vOld;

      // De >0 a 0 estando activa -> preguntar si desactivar
      if (oldPrecio > 0) and (newPrecio = 0) and (esActivo = 'S') then
      begin
        if MessageDlg('El precio de salida pasa a 0. ' +
                      '¿Desea desactivar la tarifa?',
                      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
          FindField('ESACTIVO_ARTTAR').AsString := 'N';
      end;

      // De 0 a >0 estando inactiva -> preguntar si activar
      if (oldPrecio = 0) and (newPrecio > 0) and (esActivo = 'N') then
      begin
        if MessageDlg('El precio de salida es mayor que 0. ' +
                      '¿Desea activar la tarifa?',
                      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
          FindField('ESACTIVO_ARTTAR').AsString := 'S';
      end;
    end;

    unqrySol := TUniQuery.Create(nil);
    try
      unqrySol.Connection := oConn;

      // 2. Añadimos: AND CODIGO_UNICO_ARTTAR <> :PK para que no se valide contra sí mismo
      unqrySol.SQL.Text := 'SELECT * ' +
                           '  FROM fza_articulos_tarifas ' +
                           ' WHERE CODIGO_ART_ARTTAR = :CODIGO_ART_ART' +
                           '   AND CODIGO_TAR_ARTTAR = :CODIGO_TAR_ARTTAR' +
                           '   AND COALESCE(CODIGO_UNIDAD_ARTTAR, '''') = :CODIGO_UNIDAD' +
                           '   AND CODIGO_UNICO_ARTTAR <> :PK';

      unqrySol.ParamByName('CODIGO_ART_ART').AsString :=
                              unqryTablaG.FindField('CODIGO_ART_ART').AsString;
      unqrySol.ParamByName('CODIGO_TAR_ARTTAR').AsString :=
                                            FindField('CODIGO_TAR_ARTTAR').AsString;
      unqrySol.ParamByName('CODIGO_UNIDAD').AsString :=
                                            FindField('CODIGO_UNIDAD_ARTTAR').AsString;
      unqrySol.ParamByName('PK').AsInteger := PKValue;

      unqrySol.Open;

      if not(ExistePeriodoUnico(unqrySol,
                                FindField('FECHA_DESDE_ARTTAR'),
                                FindField('FECHA_HASTA_ARTTAR')))
      then
      begin
        ShowMessageFmt('No se pueden grabar dos precios para una tarifa ' +
                       'activa en fechas concurrentes para el artículo/SKU %s',
                       [FindField('CODIGO_UNIDAD_ARTTAR').AsString]);
        Abort;
      end;
    finally
      // Liberamos memoria de forma segura
      unqrySol.Free;
    end;

    // ----------------------------------------------------------------
    // Sanea precio final / descuento: precio_salida >= precio_final
    // siempre. Si no, iguala (precio_final = precio_salida) y limpia
    // los descuentos para que no haya valores negativos en ninguna
    // factura/etiqueta posterior (anticomercial y rompe los Z).
    // ----------------------------------------------------------------
    if (FindField('PRECIO_FINAL_ARTTAR').AsFloat >
        FindField('PRECIO_SALIDA_ARTTAR').AsFloat) or
       (FindField('PRECIO_DTO_ARTTAR').AsFloat < 0) or
       (FindField('PORCENTAJE_DTO_ARTTAR').AsFloat < 0) then
    begin
      FindField('PRECIO_FINAL_ARTTAR').AsFloat   :=
                                  FindField('PRECIO_SALIDA_ARTTAR').AsFloat;
      FindField('PRECIO_DTO_ARTTAR').AsFloat     := 0;
      FindField('PORCENTAJE_DTO_ARTTAR').AsFloat := 0;
    end;

    if ((State = dsInsert) or (State = dsEdit)) then
      oDmConn.ActualizarUserTimeModif(DataSet);
  end;
end;

function TdmArticulos.ReconstruirStock: string;
var
  unqrySol: TUniQuery;
begin
  Result := '';
  unqrySol := TUniQuery.Create(nil);
  try
    unqrySol.Connection := oConn;
    unqrySol.SQL.Text := 'CALL PRC_RECALCULAR_STOCK()';
    unqrySol.Open;
    if not unqrySol.IsEmpty then
      Result := unqrySol.FieldByName('MENSAJE').AsString;
    unqrySol.Close;
  finally
    FreeAndNil(unqrySol);
  end;
end;

function TdmArticulos.ObtenerPrecioTarifaPadre(const aCodArt,
                                                     aCodTarifa: string): Double;
var
  qry: TUniQuery;
begin
  Result := 0;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    // Fila padre = misma tarifa, mismo artículo, sin SKU específico,
    // activa y vigente en la fecha actual.
    qry.SQL.Text :=
      'SELECT PRECIO_SALIDA_ARTTAR '                                       +
      '  FROM fza_articulos_tarifas '                                      +
      ' WHERE CODIGO_ART_ARTTAR = :ART '                                   +
      '   AND CODIGO_TAR_ARTTAR = :TAR '                                   +
      '   AND COALESCE(CODIGO_UNIDAD_ARTTAR, '''') = '''' '                +
      '   AND ESACTIVO_ARTTAR = ''S'' '                                    +
      '   AND (FECHA_DESDE_ARTTAR IS NULL OR FECHA_DESDE_ARTTAR <= CURRENT_DATE) ' +
      '   AND (FECHA_HASTA_ARTTAR IS NULL OR FECHA_HASTA_ARTTAR >= CURRENT_DATE) ' +
      ' ORDER BY FECHA_DESDE_ARTTAR DESC '                                 +
      ' LIMIT 1';
    qry.ParamByName('ART').AsString := aCodArt;
    qry.ParamByName('TAR').AsString := aCodTarifa;
    qry.Open;
    if not qry.IsEmpty then
      Result := qry.FieldByName('PRECIO_SALIDA_ARTTAR').AsFloat;
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmArticulos.CargarTarifasEtiquetas(items: TStrings;
                                              codigos: TStrings;
                                              var aIdxDefault: Integer);
var
  i: Integer;
begin
  items.Clear;
  codigos.Clear;
  aIdxDefault := -1;
  unqryTarifasPrint.Close;
  unqryTarifasPrint.Open;
  unqryTarifasPrint.First;
  i := 0;
  while not unqryTarifasPrint.Eof do
  begin
    items.Add(unqryTarifasPrint.FieldByName('NOMBRE_TAR_TAR').AsString);
    codigos.Add(unqryTarifasPrint.FieldByName('CODIGO_TAR_ARTTAR').AsString);
    if (aIdxDefault = -1) and
       (unqryTarifasPrint.FieldByName('ESDEFAULT_TAR').AsString = 'S') then
      aIdxDefault := i;
    Inc(i);
    unqryTarifasPrint.Next;
  end;
  unqryTarifasPrint.Close;
  if (aIdxDefault = -1) and (items.Count > 0) then
    aIdxDefault := 0;
end;

procedure TdmArticulos.CargarAlmacenesEtiquetas(lst: TcxListView);
var
  Itm: TListItem;
begin
  lst.Clear;
  unqryAlmacenesPrint.Close;
  unqryAlmacenesPrint.Open;
  unqryAlmacenesPrint.First;
  while not unqryAlmacenesPrint.Eof do
  begin
    Itm := lst.Items.Add;
    Itm.Caption :=
                unqryAlmacenesPrint.FieldByName('CODIGO_ALM_ALM').AsString;
    Itm.SubItems.Add(
                unqryAlmacenesPrint.FieldByName('NOMBRE_ALM_ALM').AsString);
    unqryAlmacenesPrint.Next;
  end;
  unqryAlmacenesPrint.Close;
end;

procedure TdmArticulos.CrearDataSetEtiquetasArt(const aCodigoArt,
                                                      aCodTarifa,
                                                      aAlmacenesCsv: string;
                                                      aFechaTarifa: TDateTime);
const
  // Construimos manualmente la lista IN (...) con los codigos elegidos.
  // Los codigos vienen de fza_almacenes (validados al cargar el checklist),
  // asi que no llegan de entrada de usuario libre.
  cSqlEtiq =
    'SELECT eti.*, '                                                          +
    '       COALESCE(prc.PRECIO_SALIDA_ARTTAR, prc_pad.PRECIO_SALIDA_ARTTAR)' +
    '         AS PRECIO_SALIDA_ARTTAR,'                                       +
    '       COALESCE(prc.PRECIO_FINAL_ARTTAR,  prc_pad.PRECIO_FINAL_ARTTAR) ' +
    '         AS PRECIO_FINAL_ARTTAR,'                                        +
    '       COALESCE(prc.PRECIO_DTO_ARTTAR,    prc_pad.PRECIO_DTO_ARTTAR)   ' +
    '         AS PRECIO_DTO_ARTTAR,'                                          +
    '       COALESCE(prc.PORCENTAJE_DTO_ARTTAR,'                              +
    '                prc_pad.PORCENTAJE_DTO_ARTTAR)'                          +
    '         AS PORCENTAJE_DTO_ARTTAR,'                                      +
    '       CASE WHEN prc.CODIGO_UNICO_ARTTAR IS NOT NULL'                    +
    '            THEN ''ESPECIFICO_SKU'' ELSE ''PADRE'' END'                  +
    '         AS ORIGEN_PRECIO,'                                              +
    '       :CODIGO_TAR_ARTTAR AS CODIGO_TAR_ARTTAR,'                         +
    '       tar.NOMBRE_TAR_TAR     AS NOMBRE_TAR_TAR,'                        +
    '       tar.ESIMP_INCL_TAR     AS ESIMP_INCL_TAR,'                        +
    '       :FECHA_APLICACION      AS FECHA_APLICACION,'                      +
    '       COALESCE(stk.STOCK_FILTRADO, 0) AS STOCK_FILTRADO'                +
    '  FROM vi_articulos_skus_etiquetas eti'                                  +
    '  LEFT JOIN fza_tarifas tar'                                             +
    '    ON tar.CODIGO_TAR_ARTTAR = :CODIGO_TAR_ARTTAR'                       +
    '  LEFT JOIN fza_articulos_tarifas prc'                                   +
    '    ON  prc.CODIGO_ART_ARTTAR   = eti.CODIGO_ART_ART'                    +
    '    AND prc.CODIGO_UNIDAD_ARTTAR= eti.CODIGO_UNIDAD_SKU'                 +
    '    AND prc.CODIGO_TAR_ARTTAR   = :CODIGO_TAR_ARTTAR'                    +
    '    AND prc.ESACTIVO_ARTTAR     = ''S'''                                 +
    '    AND COALESCE(prc.FECHA_DESDE_ARTTAR, ''0000-01-01'')'                +
    '                                  <= :FECHA_APLICACION'                  +
    '    AND COALESCE(prc.FECHA_HASTA_ARTTAR, ''9999-12-31'')'                +
    '                                  >= :FECHA_APLICACION'                  +
    '  LEFT JOIN fza_articulos_tarifas prc_pad'                               +
    '    ON  prc_pad.CODIGO_ART_ARTTAR   = eti.CODIGO_ART_ART'                +
    '    AND COALESCE(prc_pad.CODIGO_UNIDAD_ARTTAR, '''') = '''''             +
    '    AND prc_pad.CODIGO_TAR_ARTTAR   = :CODIGO_TAR_ARTTAR'                +
    '    AND prc_pad.ESACTIVO_ARTTAR     = ''S'''                             +
    '    AND COALESCE(prc_pad.FECHA_DESDE_ARTTAR, ''0000-01-01'')'            +
    '                                  <= :FECHA_APLICACION'                  +
    '    AND COALESCE(prc_pad.FECHA_HASTA_ARTTAR, ''9999-12-31'')'            +
    '                                  >= :FECHA_APLICACION'                  +
    '  LEFT JOIN ('                                                           +
    '       SELECT CODIGO_UNIDAD_STK,'                                        +
    '              SUM(CANTIDAD_STK) AS STOCK_FILTRADO'                       +
    '         FROM fza_articulos_stockactual'                                 +
    '        %ALMACEN_FILTER%'                                                +
    '        GROUP BY CODIGO_UNIDAD_STK'                                      +
    '       ) stk'                                                            +
    '    ON stk.CODIGO_UNIDAD_STK = eti.CODIGO_UNIDAD_SKU'                    +
    ' WHERE (:CODIGO_ART_ART = ''''  OR eti.CODIGO_ART_ART = :CODIGO_ART_ART)'+
    '   AND eti.ESACTIVO_SKU = ''S'''                                         +
    '   AND eti.ESACTIVO_ART = ''S'''                                         +
    ' ORDER BY eti.CODIGO_ART_ART, eti.CODIGO_UNIDAD_SKU';
var
  sSql, sFiltroAlm: string;
  i: Integer;
  lstCod: TStringList;
begin
  // Limpia los codigos: solo aceptamos lo que el usuario haya marcado en el
  // checklist (que viene de fza_almacenes). Si la lista esta vacia, no
  // aplicamos filtro de almacen para no excluir cualquier stock.
  sFiltroAlm := '';
  if Trim(aAlmacenesCsv) <> '' then
  begin
    lstCod := TStringList.Create;
    try
      lstCod.StrictDelimiter := True;
      lstCod.Delimiter       := ',';
      lstCod.DelimitedText   := aAlmacenesCsv;
      // Construimos la lista IN. Como los codigos pueden contener apostrofos,
      // los duplicamos para evitar SQL injection aunque el origen sea
      // controlado.
      sFiltroAlm := '';
      for i := 0 to lstCod.Count - 1 do
      begin
        if Trim(lstCod[i]) = '' then Continue;
        if sFiltroAlm <> '' then sFiltroAlm := sFiltroAlm + ',';
        sFiltroAlm := sFiltroAlm + QuotedStr(Trim(lstCod[i]));
      end;
    finally
      lstCod.Free;
    end;
    if sFiltroAlm <> '' then
      sFiltroAlm := 'WHERE CODIGO_ALM_STK IN (' + sFiltroAlm + ')';
  end;

  sSql := StringReplace(cSqlEtiq, '%ALMACEN_FILTER%', sFiltroAlm, [rfReplaceAll]);

  unqryArtPrint.Close;
  unqryArtPrint.SQL.Text := sSql;
  unqryArtPrint.ParamByName('CODIGO_ART_ART').AsString    := aCodigoArt;
  unqryArtPrint.ParamByName('CODIGO_TAR_ARTTAR').AsString := aCodTarifa;
  unqryArtPrint.ParamByName('FECHA_APLICACION').AsDate    := aFechaTarifa;
  unqryArtPrint.Open;

  // El TClientDataSet alimenta al TfrxDBDataset; replica el patron de
  // CrearDataSetEtiquetas de UniDataClientes.
  cdsEtiquetasArt.Close;
  cdsEtiquetasArt.Data := dtstprvEtiquetasArt.Data;
  cdsEtiquetasArt.ReadOnly := False;
  cdsEtiquetasArt.Active := True;

  // Cuando el usuario marca almacenes, una etiqueta por unidad de stock:
  // se elimina cualquier SKU sin existencia en los almacenes elegidos y se
  // replica cada fila restante tantas veces como unidades tenga. Sin
  // almacenes marcados conservamos una sola etiqueta por SKU (el campo
  // STOCK_FILTRADO entonces refleja la suma global, que no es lo que el
  // usuario quiere para etiquetar).
  if Trim(aAlmacenesCsv) <> '' then
    ExpandirEtiquetasPorStock('STOCK_FILTRADO');

  cdsEtiquetasArt.First;
end;

procedure TdmArticulos.ExpandirEtiquetasPorStock(const aFldStock: string);
var
  i, j, k, iStock, iStockIdx, iOriginales: Integer;
  Filas: array of array of Variant;
begin
  if (not cdsEtiquetasArt.Active) or cdsEtiquetasArt.IsEmpty then Exit;
  if cdsEtiquetasArt.FindField(aFldStock) = nil then Exit;
  iStockIdx := cdsEtiquetasArt.FieldByName(aFldStock).Index;

  cdsEtiquetasArt.DisableControls;
  cdsEtiquetasArt.DisableConstraints;
  // Los TField vienen marcados como ReadOnly desde el DataSetProvider; sin
  // esto, el Fields[j].Value := ... peta con
  // 'Field xxx cannot be modified'.
  for j := 0 to cdsEtiquetasArt.FieldCount - 1 do
  begin
    cdsEtiquetasArt.Fields[j].ReadOnly := False;
    cdsEtiquetasArt.Fields[j].Required := False;
  end;
  try
    // Volcamos los originales a memoria, vaciamos el cds y lo
    // reconstruimos replicando cada fila por su stock.
    iOriginales := cdsEtiquetasArt.RecordCount;
    SetLength(Filas, iOriginales);
    cdsEtiquetasArt.First;
    for i := 0 to iOriginales - 1 do
    begin
      SetLength(Filas[i], cdsEtiquetasArt.FieldCount);
      for j := 0 to cdsEtiquetasArt.FieldCount - 1 do
        Filas[i][j] := cdsEtiquetasArt.Fields[j].Value;
      cdsEtiquetasArt.Next;
    end;

    cdsEtiquetasArt.EmptyDataSet;

    for i := 0 to iOriginales - 1 do
    begin
      if VarIsNull(Filas[i][iStockIdx]) then Continue;
      iStock := Trunc(Double(Filas[i][iStockIdx]));
      if iStock <= 0 then Continue;
      for k := 1 to iStock do
      begin
        cdsEtiquetasArt.Append;
        for j := 0 to cdsEtiquetasArt.FieldCount - 1 do
          cdsEtiquetasArt.Fields[j].Value := Filas[i][j];
        cdsEtiquetasArt.Post;
      end;
    end;
  finally
    cdsEtiquetasArt.EnableControls;
  end;
end;

initialization
  ForceReferenceToClass(TdmArticulos);
end.
