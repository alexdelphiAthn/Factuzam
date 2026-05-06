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
  Vcl.ComCtrls, Winapi.Windows, system.strUtils, cxGridDBTableView;

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
  private
    procedure QuitarEscribiblesVista;
  public
    procedure GetCodigoAutoArticulo;
    function ArticuloTieneProvPrin(sArt:String):Boolean;
    procedure CopiarProveedoraArticulo(dtProveedores:TDataset);
    procedure FillTarifas(lst:TcxListView);
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

initialization
  ForceReferenceToClass(TdmArticulos);
end.
