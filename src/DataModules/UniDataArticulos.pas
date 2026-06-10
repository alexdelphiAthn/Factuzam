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
  Uni, inLibUser, UniDataConn, inLibLog, cxListView, Vcl.Forms, vcl.dialogs,
  Vcl.ComCtrls, Winapi.Windows, system.strUtils, cxGridDBTableView,
  System.Variants, vcl.Controls, Datasnap.Provider, Datasnap.DBClient,
  System.Generics.Collections,
  frxClass, frxDBSet, frCoreClasses, System.UITypes;

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
    unqryAtributosBasicosLookup: TUniQuery;
    dsAtributosBasicosLookup: TDataSource;
    unqryUnidadesMedidaLookup: TUniQuery;
    dsUnidadesMedidaLookup: TDataSource;
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
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryProveedoresArticulosBeforePost(DataSet: TDataSet);
    procedure unqryTarifasArticulosBeforePost(DataSet: TDataSet);
    procedure unqryStockArticulosAfterScroll(DataSet: TDataSet);
    procedure unqryVariacionesArticulosBeforePost(DataSet: TDataSet);
    procedure unqryVariacionesArticulosBeforeDelete(DataSet: TDataSet);
    procedure unqrySkusBeforePost(DataSet: TDataSet);
    procedure unqrySkusBeforeDelete(DataSet: TDataSet);
    procedure unqryDetallesAtributosBeforePost(DataSet: TDataSet);
  private
    procedure AsegurarSkuBase(const ACodArt: string);
    procedure QuitarEscribiblesVista;
    procedure ActualizarSkuActivo(const aSku, aActivo: string);
    procedure UpsertCosteSku(const aSku: string;
                             aPrecioField, aFechaField: TField);
    procedure EliminarCosteSku(const aSku: string);

  public
    procedure PoblarCdsEtiquetasArtDesdeUniQuery;
    procedure ExpandirEtiquetasPorStock(const aFldStock: string);
    // Override: abre las queries detalle y lookups del Mto de Articulos
    // (tarifas, proveedores, lineas-factura, variaciones, skus, stock,
    // movimientos, atributos basicos, ivas, familias). Lo invoca
    // TfrmMtoGen.AbrirTablaPrincipalAsync DENTRO del thread del Open de
    // unqryTablaG. Antes de este refactor los Opens vivian en
    // DataModuleCreate y bloqueaban la UI 17-21 segundos al abrir el tab.
    procedure AbrirDetalles; override;
    // En main thread tras AbrirDetalles: reactiva los TDataSource que
    // se desactivaron durante el thread y dispara manualmente el
    // AfterScroll del stock (que tambien se silencio).
    procedure ReactivarControlesTrasAbrir; override;
    // Carga perezosa de tarifas. La vista vi_articulos_tarifas tarda
    // ~6 segundos en abrir por culpa de subqueries DEPENDENT y un
    // DERIVED full-scan. La quitamos de AbrirDetalles y la abrimos
    // solo cuando el usuario hace click en la sub-pestaña Tarifas
    // (ver TfrmMtoArticulos.PcDetailChange).
    procedure AsegurarTarifasAbiertas;
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
                                             aFechaTarifa: TDateTime;
                                             const aSkusCsv: string = '');
  end;

implementation

uses
  inMtoArticulos,
  inLibGlobalVar,
  inLibAppParam,
  System.Diagnostics,
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
                              unqryTablaG.FieldByName(
                                'CODIGO_ART_ART').AsString;
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

procedure TdmArticulos.unqryDetallesAtributosBeforePost(DataSet: TDataSet);
begin
  // La rejilla del detalle de atributos se nutre de una vista de sólo
  // lectura. Las ediciones reales (cambio de atributo básico, HEX nuevo)
  // se persisten desde el formulario con UPDATE directos sobre las tablas
  // implicadas: aquí abortamos el Post estándar del framework para evitar
  // el error "Cannot insert into JOIN".
  inherited;
  Abort;
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
const
  // Anchos fijos en pixels. Sustituyen al ApplyBestFit por columna que
  // se ejecutaba en este AfterScroll cada vez que el usuario cambiaba de
  // articulo. BestFit recorria todas las filas N veces (una por columna)
  // y era uno de los sospechosos del gap silencioso de 5s al abrir
  // Articulos. Si necesitas reajustar valores tipicos, edita estos const.
  ANCHO_ALMACEN = 180;  // texto largo (nombre de almacen)
  ANCHO_COLOR   =  90;  // texto + swatch de color, ya incluido el cuadrado
  ANCHO_TOTAL   =  80;  // numerico de cierre de fila
  ANCHO_TALLA   =  55;  // columnas dinamicas pivotadas (tallas, variantes)
var
  tvArticulosStock: TcxGridDBTableView;
  col: TcxGridDBColumn;
  nombre, sArt: string;
  i: Integer;
  swTotal, swTramo: TStopwatch;
  msSP, msRebuild, msAnchos: Int64;
begin
  inherited;
  if DataSet.ControlsDisabled then Exit;
  if not DataSet.Active or DataSet.IsEmpty then Exit;
  swTotal := TStopwatch.StartNew;
  msSP := 0; msRebuild := 0; msAnchos := 0;
  unqryStockArticulos.Close;
  sArt := unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
  unqryStockArticulos.ParamByName('CODIGO_ART_ART').AsString := sArt;
  tvArticulosStock := (GetOwnerForm<TfrmMtoArticulos>).tvStock;
  if sArt <> '' then
  begin
    swTramo := TStopwatch.StartNew;
    unqryStockArticulos.Open;
    msSP := swTramo.ElapsedMilliseconds;

//    swTramo := TStopwatch.StartNew;
    tvArticulosStock.BeginUpdate;
    try
      tvArticulosStock.ClearItems;
      tvArticulosStock.DataController.CreateAllItems;
    finally
      tvArticulosStock.EndUpdate;
    end;
//    msRebuild := swTramo.ElapsedMilliseconds;

    if unqryStockArticulos.Active and (tvArticulosStock.ColumnCount > 0) then
    begin
//      swTramo := TStopwatch.StartNew;
      // Asignamos anchos fijos segun el nombre del campo. Las columnas
      // especiales (Almacen, Color, Total) tienen su valor concreto;
      // el resto (tallas / variantes que llegan dinamicamente del SP
      // PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ) van con ANCHO_TALLA.
      for i := 0 to tvArticulosStock.ColumnCount - 1 do
      begin
        col := tvArticulosStock.Columns[i] as TcxGridDBColumn;
        nombre := col.DataBinding.FieldName;
        if SameText(nombre, 'Almacen') then
          col.Width := ANCHO_ALMACEN
        else if SameText(nombre, 'Color') then
          col.Width := ANCHO_COLOR
        else if SameText(nombre, 'Total') then
          col.Width := ANCHO_TOTAL
        else
          col.Width := ANCHO_TALLA;
      end;
//      msAnchos := swTramo.ElapsedMilliseconds;
      // Antes se llamaba a EnsancharColumnasStockParaSwatch para sumar
      // ANCHO_SWATCH_PX a las columnas con cuadradito de color (post-
      // proceso sobre los anchos calculados por ApplyBestFit). Como
      // ahora ANCHO_COLOR ya incluye espacio para el swatch, no hace
      // falta llamarlo. La funcion sigue viva por si la usas en otro
      // sitio (la mantenemos como utilidad).
    end;
  end;
  inLibLog.Log.LogPerf('Articulos.StockAfterScroll',
    Format('art=%s | SP=%d ms | RebuildItems=%d ms | Anchos=%d ms | cols=%d',
           [sArt, msSP, msRebuild, msAnchos, tvArticulosStock.ColumnCount]),
    swTotal.ElapsedMilliseconds);
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
  // Por defecto los articulos van en Unidades (sin decimales). Solo los que
  // se cambien a metros/kilos... mostraran decimales segun la unidad.
  if Trim(unqryTablaG.FindField('TIPO_CANTIDAD_ART').AsString) = '' then
    unqryTablaG.FindField('TIPO_CANTIDAD_ART').AsString := 'Uds';
end;

procedure TdmArticulos.unqryTablaGAfterPost(DataSet: TDataSet);
var
  sArt: string;
begin
  inherited;
  // Articulo simple (sin variaciones): garantizar una unidad/SKU base con
  // CODIGO_UNIDAD_SKU = CODIGO_ART_ART para que pueda llevar stock y aparezca
  // en la consulta (Ctrl+U), movimientos, etc. sin tener que crear SKUs a mano.
  if SameText(unqryTablaG.FindField('ESVARIACION_ART').AsString, 'N') then
  begin
    sArt := Trim(unqryTablaG.FindField('CODIGO_ART_ART').AsString);
    if sArt <> '' then
      AsegurarSkuBase(sArt);
  end;
end;

procedure TdmArticulos.AsegurarSkuBase(const ACodArt: string);
var
  qry: TUniQuery;
begin
  // Crea el SKU base solo si el articulo aun no tiene NINGUN SKU. El marcador
  // de "sin variacion" en CODIGO_VAR_SKU es '-' (convencion ya usada en la
  // BBDD, p.ej. el SKU 'BOLSO-PIEL'). Idempotente: NOT EXISTS + INSERT IGNORE.
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_skus ' +
      '  (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ESACTIVO_SKU, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'SELECT :cod, :art, ''-'', ''S'', CURRENT_TIMESTAMP, :usr, :usr ' +
      '  FROM DUAL ' +
      ' WHERE NOT EXISTS (SELECT 1 FROM fza_articulos_skus ' +
      '                    WHERE CODIGO_ART_SKU = :art2)';
    qry.ParamByName('cod').AsString  := ACodArt;
    qry.ParamByName('art').AsString  := ACodArt;
    qry.ParamByName('art2').AsString := ACodArt;
    qry.ParamByName('usr').AsString  := oUser;
    qry.ExecSQL;
  finally
    FreeAndNil(qry);
  end;
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
  // Solo asignamos Connection y MasterSource. Los Open se han movido a
  // AbrirDetalles (que invoca TfrmMtoGen.AbrirTablaPrincipalAsync en thread)
  // para no congelar la UI durante la creacion del data module.
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
  unqryDetallesAtributos.Connection := oConn;
  unqryAtributosBasicosLookup.Connection := oConn;
  unqryUnidadesMedidaLookup.Connection := oConn;
  // Las MasterSource solo aplican cuando el DM se instancia desde el
  // Mto de Articulos (Owner = TfrmMtoArticulos). Si lo crea otro
  // contexto puntual (p.ej. el boton 'Pegatinas' del Mto de Albaranes
  // de Compra crea un TdmArticulos temporal solo para reutilizar las
  // queries de etiquetas) el GetOwnerForm devuelve nil y aqui hariamos
  // un AV. Saltamos la asignacion si no hay form de articulos.
  if GetOwnerForm<TfrmMtoArticulos> <> nil then
  begin
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
  end;
  // El detalle de atributos sigue al SKU activo (master) para mostrar sólo
  // las filas del SKU posicionado en la rejilla superior.
  unqryDetallesAtributos.MasterSource := dsSkus;
end;

procedure TdmArticulos.AbrirDetalles;
const
  TAG = 'Articulos.AbrirDetalles';

  procedure AbrirConTiempo(qry: TUniQuery; const Nombre: string);
  var
    swQ: TStopwatch;
  begin
    if qry.Active then Exit;
    swQ := TStopwatch.StartNew;
    try
      qry.Open;
      inLibLog.Log.LogPerf(TAG, Nombre + ' OK', swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        inLibLog.Log.LogPerf(TAG,
          Nombre + ' ERROR=' + E.Message,
          swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;

var
  sw: TStopwatch;
  saveAfterScroll: TDataSetNotifyEvent;
begin
  inherited;
  sw := TStopwatch.StartNew;
  // unqryStockArticulos.AfterScroll dispara unqryStockArticulosAfterScroll
  // que ya se ha ejecutado durante CrearTablaPrincipal (linea 1798 de
  // inMtoArticulos.pas). Si lo dejamos activo aqui, al abrir
  // unqryStockArticulos el AfterScroll se dispara otra vez y re-ejecuta
  // el SP + rebuild del grid. Lo silenciamos para evitar el duplicado;
  // lo restauramos al final.
  saveAfterScroll := unqryStockArticulos.AfterScroll;
  unqryStockArticulos.AfterScroll := nil;
  try
    AbrirConTiempo(unqryTiposIVA,               'unqryTiposIVA');
    AbrirConTiempo(unqryFamiliaArticulos,       'unqryFamiliaArticulos');
    AbrirConTiempo(unqryVariaciones,            'unqryVariaciones');
    AbrirConTiempo(unqryAtributosBasicosLookup, 'unqryAtributosBasicosLookup');
    AbrirConTiempo(unqryUnidadesMedidaLookup,   'unqryUnidadesMedidaLookup');
    // unqryTarifasArticulos NO se abre aqui: la vista tarda ~6s
    // (subqueries DEPENDENT, ver EXPLAIN). Se abre solo cuando el
    // usuario va a la pestaña tsTarifas, via AsegurarTarifasAbiertas.
    AbrirConTiempo(unqryProveedoresArticulos,   'unqryProveedoresArticulos');
    AbrirConTiempo(unqryLinFacturasArticulos,   'unqryLinFacturasArticulos');
    AbrirConTiempo(unqryVariacionesArticulos,   'unqryVariacionesArticulos');
    AbrirConTiempo(unqrySkus,                   'unqrySkus');
    AbrirConTiempo(unqryStockArticulos,         'unqryStockArticulos');
    AbrirConTiempo(unqryMovimientosArticulos,   'unqryMovimientosArticulos');
    AbrirConTiempo(unqryDetallesAtributos,      'unqryDetallesAtributos');
  finally
    unqryStockArticulos.AfterScroll := saveAfterScroll;
  end;
  // QuitarEscribiblesVista necesita unqryTarifasArticulos abierto; ahora
  // que la abrimos perezosamente, esa rutina se llama desde
  // AsegurarTarifasAbiertas tras el primer Open.
  inLibLog.Log.LogPerf(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmArticulos.ReactivarControlesTrasAbrir;
begin
  inherited;
  // Ya no hay TDataSource desactivados ni AfterScroll silenciado:
  // AbrirDetalles corre en main thread y no necesita la proteccion
  // contra DevExpress non-thread-safe. Metodo vacio por compatibilidad.
end;

procedure TdmArticulos.AsegurarTarifasAbiertas;
var
  sw: TStopwatch;
begin
  if unqryTarifasArticulos.Active then Exit;
  sw := TStopwatch.StartNew;
  try
    unqryTarifasArticulos.Open;
    QuitarEscribiblesVista;
    inLibLog.Log.LogPerf('Articulos.Lazy', 'unqryTarifasArticulos OK',
      sw.ElapsedMilliseconds);
  except
    on E: Exception do
    begin
      inLibLog.Log.LogPerf('Articulos.Lazy',
        'unqryTarifasArticulos ERROR=' + E.Message,
        sw.ElapsedMilliseconds);
      raise;
    end;
  end;
end;

procedure TdmArticulos.QuitarEscribiblesVista;
const
  // Únicas columnas que pertenecen realmente a fza_articulos_tarifas
  CamposEscribibles: array[0..14] of string = (
    'CODIGO_ART_ARTTAR',  'CODIGO_UNICO_ARTTAR',  'CODIGO_UNIDAD_ARTTAR',
    'CODIGO_TAR_ARTTAR',  'ESACTIVO_ARTTAR',
    'PRECIO_SALIDA_ARTTAR','PRECIO_FINAL_ARTTAR','PRECIO_DTO_ARTTAR',
    'PORCENTAJE_DTO_ARTTAR',
    'FECHA_DESDE_ARTTAR', 'FECHA_HASTA_ARTTAR',
    'INSTANTE_MODIF', 'INSTANTE_ALTA', 'USUARIO_ALTA', 'USUARIO_MODIF'
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
      if SameText(FindField('CODIGO_TAR_ARTTAR').AsString,
                  oAppParams.GetString('appTarifaDefecto', 'PVP')) then
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
  // Insert vacío (accidental): cancelar sin error
  if (DataSet.State = dsInsert) and
     (Trim(unqryTablaG.FindField('DESCRIPCION_ART').AsString) = '') then
    Abort;
  with unqryTablaG do
  begin
    var sDescripcion := Trim(FindField('DESCRIPCION_ART').AsString);
    if (sDescripcion = '') or (SimbolosProhibidos(sDescripcion)) then
    begin
      raise ERangeError.CreateFmt('%s no es un valor válido ' +
                                       'para el campo Descripción de Artículos',
               [FindField('DESCRIPCION_ART').AsString]);
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
      // Las altas con precio>0 conservan el ESACTIVO que les haya puesto el
      // alta masiva.
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

      // 2. Añadimos: AND CODIGO_UNICO_ARTTAR <> :PK para que no se valide
      // contra sí mismo
      unqrySol.SQL.Text := 'SELECT * ' +
                           '  FROM fza_articulos_tarifas ' +
                           ' WHERE CODIGO_ART_ARTTAR = :CODIGO_ART_ART' +
                           '   AND CODIGO_TAR_ARTTAR = :CODIGO_TAR_ARTTAR' +
                           '   AND COALESCE(CODIGO_UNIDAD_ARTTAR, '''') = ' +
                           ':CODIGO_UNIDAD' +
                           '   AND CODIGO_UNICO_ARTTAR <> :PK';

      unqrySol.ParamByName('CODIGO_ART_ART').AsString :=
                              unqryTablaG.FindField('CODIGO_ART_ART').AsString;
      unqrySol.ParamByName('CODIGO_TAR_ARTTAR').AsString :=
                                            FindField(
                                              'CODIGO_TAR_ARTTAR').AsString;
      unqrySol.ParamByName('CODIGO_UNIDAD').AsString :=
                                            FindField(
                                              'CODIGO_UNIDAD_ARTTAR').AsString;
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
      FreeAndNil(unqrySol);
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
      '   AND (FECHA_DESDE_ARTTAR IS NULL OR FECHA_DESDE_ARTTAR <= ' +
      'CURRENT_DATE) ' +
      '   AND (FECHA_HASTA_ARTTAR IS NULL OR FECHA_HASTA_ARTTAR >= ' +
      'CURRENT_DATE) ' +
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
       SameText(unqryTarifasPrint.FieldByName('CODIGO_TAR_ARTTAR').AsString,
                oAppParams.GetString('appTarifaDefecto', 'PVP')) then
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
                                                      aFechaTarifa: TDateTime;
                                                      const aSkusCsv: string);
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
    '   %SKU_FILTER%'                                                         +
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
      FreeAndNil(lstCod);
    end;
    if sFiltroAlm <> '' then
      sFiltroAlm := 'WHERE CODIGO_ALM_STK IN (' + sFiltroAlm + ')';
  end;

  sSql := StringReplace(cSqlEtiq,
                        '%ALMACEN_FILTER%',
                        sFiltroAlm,
                        [rfReplaceAll]);
  // Filtro opcional por SKUs concretos (lo usa el modal de pegatinas de
  // albaranes / pedidos para reducir la query a los SKUs del documento).
  // El parser de SQL exige una lista literal — la construimos a partir
  // del CSV de entrada (codigos vienen de fza_albaranes_compra_lineas).
  if Trim(aSkusCsv) <> '' then
    sSql := StringReplace(sSql, '%SKU_FILTER%',
              'AND eti.CODIGO_UNIDAD_SKU IN (' + aSkusCsv + ')',
              [rfReplaceAll])
  else
    sSql := StringReplace(sSql, '%SKU_FILTER%', '', [rfReplaceAll]);

  unqryArtPrint.Close;
  unqryArtPrint.SQL.Text := sSql;
  unqryArtPrint.ParamByName('CODIGO_ART_ART').AsString    := aCodigoArt;
  unqryArtPrint.ParamByName('CODIGO_TAR_ARTTAR').AsString := aCodTarifa;
  unqryArtPrint.ParamByName('FECHA_APLICACION').AsDate    := aFechaTarifa;
  unqryArtPrint.Open;

  // Construimos el cdsEtiquetasArt copiando manualmente desde unqryArtPrint,
  // sin pasar por dtstprvEtiquetasArt. La ruta provider -> Data variant ->
  // cds lanzaba intermitentemente 'Missing data provider or data packet'
  // (TDataSetProvider con TUniQuery + JOINs complejos devolvia Variant
  // null), y a la vez nos da margen para anyadir el campo HEX_ATR_CO en
  // la misma pasada.
  PoblarCdsEtiquetasArtDesdeUniQuery;

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

procedure TdmArticulos.PoblarCdsEtiquetasArtDesdeUniQuery;
const
  // Cadena articulo -> color basico -> HEX. JOINs sencillos sobre tablas
  // base; no usa la vista vi_articulos_skus_etiquetas para evitar el coste
  // de repetir todo el pipeline de SKUs/proveedores/codigos de barras.
  cSqlHex =
    'SELECT sa.CODIGO_UNIDAD_SKU_SA AS CODIGO_UNIDAD_SKU,'                    +
    '       atb.HEX_ATB             AS HEX_ATR_CO '                           +
    '  FROM fza_atributos_sku sa'                                             +
    '  JOIN fza_articulos_skus sk'                                            +
    '    ON sk.CODIGO_UNIDAD_SKU = sa.CODIGO_UNIDAD_SKU_SA'                   +
    '  JOIN fza_atributos_valores av'                                         +
    '    ON av.ID_AV     = sa.ID_AV_SA'                                       +
    '   AND av.ID_VA_AV  = ''CO'''                                            +
    '  JOIN fza_articulos_atributos_basicos aab'                              +
    '    ON aab.CODIGO_ART_AAB = sk.CODIGO_ART_SKU'                           +
    '   AND aab.ID_AV_AAB     = av.ID_AV'                                     +
    '  JOIN fza_atributos_basicos atb'                                        +
    '    ON atb.ID_ATB = aab.ID_ATB_AAB';
var
  qryHex: TUniQuery;
  oHexMap: TDictionary<string, string>;
  fldDef, fdOrig: TFieldDef;
  sCodSku, sHex, sDiag: string;
  k, iCodSkuIdxOrig: Integer;
  // Mapea cualquier TFieldType al subconjunto que el motor MIDAS del
  // TClientDataSet admite en CreateDataSet. Las columnas calculadas desde
  // parametros y ciertos tipos de MariaDB (ftSingle, ftExtended, ftShortint,
  // ftByte, ftTimeStampOffset, ftUnknown...) hacen que CreateDataSet lance
  // 'Invalid field type'; aqui los reconducimos a un equivalente seguro.
  function TipoSeguroCds(aTipo: TFieldType): TFieldType;
  begin
    case aTipo of
      ftString, ftFixedChar:
        Result := ftString;
      ftWideString, ftFixedWideChar:
        Result := ftWideString;
      ftBoolean:
        Result := ftBoolean;
      ftShortint, ftByte, ftSmallint:
        Result := ftSmallint;
      ftWord, ftInteger, ftAutoInc:
        Result := ftInteger;
      ftLongWord, ftLargeint:
        Result := ftLargeint;
      ftSingle, ftFloat, ftExtended:
        Result := ftFloat;
      ftCurrency:
        Result := ftCurrency;
      ftBCD, ftFMTBcd:
        Result := ftFMTBcd;
      ftDate:
        Result := ftDate;
      ftTime:
        Result := ftTime;
      ftDateTime, ftTimeStamp, ftTimeStampOffset:
        Result := ftDateTime;
      ftMemo, ftWideMemo, ftFmtMemo:
        Result := ftWideString;
      ftBlob, ftGraphic, ftBytes, ftVarBytes:
        Result := ftBlob;
      ftGuid:
        Result := ftGuid;
    else
      // ftUnknown y tipos exoticos (ftADT, ftArray, ftCursor, ftVariant,
      // ftDataSet...): el disenyador solo necesita el nombre del campo, asi
      // que lo exponemos como texto.
      Result := ftWideString;
    end;
  end;
begin
  // 1) Mapa CODIGO_UNIDAD_SKU -> HEX_ATB en memoria. Una sola query.
  oHexMap := TDictionary<string, string>.Create;
  try
    qryHex := TUniQuery.Create(nil);
    try
      qryHex.Connection := unqryArtPrint.Connection;
      qryHex.SQL.Text   := cSqlHex;
      try
        qryHex.Open;
        try
          while not qryHex.Eof do
          begin
            sCodSku := qryHex.FieldByName('CODIGO_UNIDAD_SKU').AsString;
            sHex    := qryHex.FieldByName('HEX_ATR_CO').AsString;
            if sCodSku <> '' then
              oHexMap.AddOrSetValue(sCodSku, sHex);
            qryHex.Next;
          end;
        finally
          qryHex.Close;
        end;
      except
        // BBDD sin las tablas, permisos... ignoramos: la banda saldra
        // blanca, pero la impresion sigue adelante.
      end;
    finally
      qryHex.Free;
    end;

    // 2) Reconstruir el cds desde cero copiando el esquema de unqryArtPrint
    //    + HEX_ATR_CO. Evita el TDataSetProvider, que con esta combinacion
    //    UniDAC + JOINs devuelve un Variant Null y dispara
    //    'Missing data provider or data packet' al activar el cds.
    cdsEtiquetasArt.Close;
    cdsEtiquetasArt.FieldDefs.Clear;
    if unqryArtPrint.Active then
    begin
      unqryArtPrint.FieldDefs.Update;
      // Copiamos FieldDef a FieldDef (en vez de FieldDefs.Assign) para poder
      // reconducir cada tipo al subconjunto que admite CreateDataSet. Las
      // columnas calculadas desde parametros (p.ej. :CODIGO_TAR_ARTTAR) y
      // algunos tipos de MariaDB llegan como tipos que el motor MIDAS no
      // soporta, y CreateDataSet abortaba con 'Invalid field type'.
      for k := 0 to unqryArtPrint.FieldDefs.Count - 1 do
      begin
        fdOrig            := unqryArtPrint.FieldDefs[k];
        fldDef            := cdsEtiquetasArt.FieldDefs.AddFieldDef;
        fldDef.Name       := fdOrig.Name;
        fldDef.DataType   := TipoSeguroCds(fdOrig.DataType);
        fldDef.Required   := False;
        fldDef.Attributes := [];
        case fldDef.DataType of
          ftString, ftFixedChar, ftWideString, ftFixedWideChar:
          begin
            // Texto largo (GROUP_CONCAT/TEXT) -> tamanyo holgado. Para el
            // resto usamos el del origen, pero acotado: las columnas de
            // parametros vacios vuelven con tamanyo 0 o desmesurado, y un
            // ftWideString gigante tambien hace fallar CreateDataSet.
            if fdOrig.DataType in [ftMemo, ftWideMemo, ftFmtMemo] then
              fldDef.Size := 8192
            else if (fdOrig.Size > 0) and (fdOrig.Size <= 8192) then
              fldDef.Size := fdOrig.Size
            else
              fldDef.Size := 255;
          end;
          ftFMTBcd:
          begin
            if fdOrig.Precision > 0 then
              fldDef.Precision := fdOrig.Precision
            else
              fldDef.Precision := 18;
            if (fdOrig.Size > 0) and (fdOrig.Size <= fldDef.Precision) then
              fldDef.Size := fdOrig.Size
            else
              fldDef.Size := 4;
          end;
        end;
      end;
    end;
    iCodSkuIdxOrig := cdsEtiquetasArt.FieldDefs.IndexOf('CODIGO_UNIDAD_SKU');
    if cdsEtiquetasArt.FieldDefs.IndexOf('HEX_ATR_CO') < 0 then
    begin
      fldDef          := cdsEtiquetasArt.FieldDefs.AddFieldDef;
      fldDef.Name     := 'HEX_ATR_CO';
      fldDef.DataType := ftString;
      fldDef.Size     := 7;
    end;
    // Red de seguridad: si pese al saneo MIDAS aun rechaza algun tipo,
    // dejamos constancia del esquema exacto en el log y reconstruimos todo
    // como texto para que el disenyador / impresion abran igualmente.
    try
      cdsEtiquetasArt.CreateDataSet;
    except
      on E: Exception do
      begin
        cdsEtiquetasArt.Close;
        sDiag := '';
        for k := 0 to cdsEtiquetasArt.FieldDefs.Count - 1 do
          sDiag := sDiag + cdsEtiquetasArt.FieldDefs[k].Name + ':' +
                   IntToStr(Ord(cdsEtiquetasArt.FieldDefs[k].DataType)) +
                   '(' + IntToStr(cdsEtiquetasArt.FieldDefs[k].Size) + ') ';
        if Assigned(Log) then
          Log.LogError('PoblarCdsEtiquetasArt: CreateDataSet fallo (' +
                       E.Message + '). Esquema: ' + sDiag);
        for k := 0 to cdsEtiquetasArt.FieldDefs.Count - 1 do
        begin
          cdsEtiquetasArt.FieldDefs[k].DataType := ftWideString;
          cdsEtiquetasArt.FieldDefs[k].Size     := 255;
        end;
        cdsEtiquetasArt.CreateDataSet;
      end;
    end;
    cdsEtiquetasArt.LogChanges := False;
    for k := 0 to cdsEtiquetasArt.FieldCount - 1 do
    begin
      cdsEtiquetasArt.Fields[k].ReadOnly := False;
      cdsEtiquetasArt.Fields[k].Required := False;
    end;

    if (not unqryArtPrint.Active) or unqryArtPrint.IsEmpty then Exit;

    // 3) Volcar filas de unqryArtPrint -> cdsEtiquetasArt + HEX por SKU.
    cdsEtiquetasArt.DisableControls;
    try
      unqryArtPrint.First;
      while not unqryArtPrint.Eof do
      begin
        cdsEtiquetasArt.Append;
        for k := 0 to unqryArtPrint.FieldCount - 1 do
          cdsEtiquetasArt.Fields[k].Value := unqryArtPrint.Fields[k].Value;
        if iCodSkuIdxOrig >= 0 then
        begin
          sCodSku := unqryArtPrint.Fields[iCodSkuIdxOrig].AsString;
          if (sCodSku <> '') and oHexMap.TryGetValue(sCodSku, sHex) then
            cdsEtiquetasArt.FieldByName('HEX_ATR_CO').AsString := sHex;
        end;
        cdsEtiquetasArt.Post;
        unqryArtPrint.Next;
      end;
    finally
      cdsEtiquetasArt.EnableControls;
    end;
  finally
    oHexMap.Free;
  end;
end;

initialization
  ForceReferenceToClass(TdmArticulos);
end.
