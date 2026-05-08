{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit UniDataArticulos;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, UniDataConn,  cxListView, Vcl.Forms, vcl.dialogs,
  Vcl.ComCtrls, Winapi.Windows, system.strUtils, cxGridDBTableView,
  System.Variants, vcl.Controls;

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
    unqryStockArticulos: TUniQuery;
    dsStockArticulos: TDataSource;
    unqryMovimientosArticulos: TUniQuery;
    dsMovimientosArticulos: TDataSource;
    unqryDetallesAtributos: TUniQuery;
    dsDetallesAtributos: TDataSource;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGAfterDelete(DataSet: TDataSet);
    procedure unqryProveedoresArticulosBeforePost(DataSet: TDataSet);
    procedure unqryTarifasArticulosBeforePost(DataSet: TDataSet);
    procedure unqryStockArticulosAfterScroll(DataSet: TDataSet);
    procedure unqryVariacionesArticulosBeforePost(DataSet: TDataSet);
    procedure unqryVariacionesArticulosBeforeDelete(DataSet: TDataSet);
  private
    procedure QuitarEscribiblesVista;
    procedure ActualizarSkuActivo(const aSku, aActivo: string);
  public
    procedure GetCodigoAutoArticulo;
    function ArticuloTieneProvPrin(sArt:String):Boolean;
    procedure CopiarProveedoraArticulo(dtProveedores:TDataset);
    procedure FillTarifas(lst:TcxListView);
    function ReconstruirStock: string;
    function ObtenerPrecioTarifaPadre(const aCodArt,
                                            aCodTarifa: string): Double;
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
  fldCB, fldAct, fldSku, fldId: TField;
  sNewCB, sSku, sTipo, sPrin: string;
  bChangedActivo: Boolean;
  qry: TUniQuery;
begin
  inherited;

  fldId  := DataSet.FindField('ID_CB');
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
    if (fldCB = nil) or (Trim(fldCB.AsString) = '') then
      raise ERangeError.Create(
        'Introduzca el código de barras antes de guardar la fila.');
    oDmConn.ActualizarUserTimeModif(DataSet);
    // Dejamos que el framework lance SQLInsert (sobre fza_codigos_barras).
    Exit;
  end;

  if DataSet.State <> dsEdit then Exit;

  oDmConn.ActualizarUserTimeModif(DataSet);

  bChangedActivo := (fldAct <> nil) and
                    (VarToStr(fldAct.OldValue) <> fldAct.AsString);

  // Caso especial: la fila representa un SKU sin ningún CB (ID_CB nulo
  // por LEFT JOIN). Si el usuario ha tecleado un código, lo insertamos
  // manualmente; el framework no puede usar SQLUpdate sobre ID_CB nulo.
  if (fldId <> nil) and fldId.IsNull and (fldCB <> nil) then
  begin
    sNewCB := Trim(fldCB.AsString);
    if sNewCB = '' then
    begin
      if bChangedActivo then
        ActualizarSkuActivo(sSku, fldAct.AsString);
      Exit;
    end;

    sTipo := Trim(VarToStr(DataSet.FieldByName('TIPO_CODIGO_CB').Value));
    if sTipo = '' then sTipo := 'EAN13';
    sPrin := Trim(VarToStr(DataSet.FieldByName('ESPRINCIPAL_CB').Value));
    if sPrin = '' then sPrin := 'N';

    qry := TUniQuery.Create(nil);
    try
      qry.Connection := oConn;
      qry.SQL.Text :=
        'INSERT INTO fza_codigos_barras '                              +
        '   (CODIGO_BARRAS_CB, CODIGO_UNIDAD_CB, TIPO_CODIGO_CB, '     +
        '    ESPRINCIPAL_CB, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (:CB, :SKU, :TIPO, :PRIN, '                            +
        '        CURRENT_TIMESTAMP, :USR, :USR)';
      qry.ParamByName('CB').AsString   := sNewCB;
      qry.ParamByName('SKU').AsString  := sSku;
      qry.ParamByName('TIPO').AsString := sTipo;
      qry.ParamByName('PRIN').AsString := sPrin;
      qry.ParamByName('USR').AsString  := oUser;
      qry.ExecSQL;
    finally
      FreeAndNil(qry);
    end;

    if bChangedActivo then
      ActualizarSkuActivo(sSku, fldAct.AsString);

    DataSet.Cancel;
    // Close+Open para que el dataset reflote ID_CB del nuevo registro:
    // un Refresh sobre detail master/detail puede no traer las filas
    // recién insertadas con sus IDs.
    DataSet.Close;
    DataSet.Open;
    Abort;
  end;

  // ESACTIVO_SKU vive en fza_articulos_skus, no en fza_codigos_barras.
  // El SQLUpdate del framework no lo tocaría: lo actualizamos a mano.
  if bChangedActivo then
    ActualizarSkuActivo(sSku, fldAct.AsString);
end;

procedure TdmArticulos.unqryVariacionesArticulosBeforeDelete(DataSet: TDataSet);
var
  fldId: TField;
begin
  inherited;
  // Filas "fantasma" del LEFT JOIN: el SKU no tiene ningún CB asociado
  // (ID_CB nulo). No hay nada que borrar en fza_codigos_barras.
  fldId := DataSet.FindField('ID_CB');
  if (fldId = nil) or fldId.IsNull then
    raise ERangeError.Create(
      'Esta fila representa un SKU sin códigos de barras: no hay nada ' +
      'que eliminar. Si quiere desactivar el SKU use la pestaña SKUs.');
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
  unqryStockArticulos.Connection := oConn;
  unqryMovimientosArticulos.Connection := oConn;
//  unqryStockArticulos.MasterSource := (GetOwnerForm<TfrmMtoArticulos>).dsTablaG;
  unqryVariacionesArticulos.MasterSource :=
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

initialization
  ForceReferenceToClass(TdmArticulos);
end.
