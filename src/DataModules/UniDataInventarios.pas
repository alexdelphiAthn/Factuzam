{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2026 fzam.6dvdy@slmail.me         }
{                                                       }
{*******************************************************}

unit UniDataInventarios;

interface

uses
  System.SysUtils, System.Classes, Data.DB, MemDS, DBAccess, Uni,
  Datasnap.DBClient, Datasnap.Provider, UniProvider, MySQLUniProvider,
  UniDataGen, vcl.Controls;

type
  TdmInventarios = class(TdmBase)                    // Cabecera (heredado de TdmBase)

    // === LÍNEAS DEL INVENTARIO (Detalle pestaña 2) ===
    unqryLineas: TUniQuery;                    // Líneas físicas en BD
    udspLineas: TDataSetProvider;
    cdsLineas: TClientDataSet;                 // Buffer cliente para edición
    dsLineas: TDataSource;

    // === CAMPOS CALCULADOS DE cdsLineas ===
    cdsLineasCODIGO_EMPRESA_INVENTARIO_LINEA: TWideStringField;
    cdsLineasCODIGO_ALMACEN_INVENTARIO_LINEA: TWideStringField;
    cdsLineasSERIE_INVENTARIO_LINEA: TWideStringField;
    cdsLineasNRO_INVENTARIO_LINEA: TWideStringField;
    cdsLineasLINEA_INVENTARIO_LINEA: TWideStringField;
    cdsLineasCODIGO_ARTICULO_INVENTARIO_LINEA: TWideStringField;
    cdsLineasCODIGO_UNIDAD_INVENTARIO_LINEA: TWideStringField;
    cdsLineasLOTE_INVENTARIO_LINEA: TWideStringField;
    cdsLineasFECHA_CADUCIDAD_INVENTARIO_LINEA: TDateField;
    cdsLineasDESCRIPCION_ARTICULO_INVENTARIO_LINEA: TWideStringField;
    cdsLineasCANTIDAD_TEORICA_INVENTARIO_LINEA: TFloatField;
    cdsLineasCANTIDAD_FISICA_INVENTARIO_LINEA: TFloatField;
    cdsLineasCANTIDAD_DIFERENCIA_INVENTARIO_LINEA: TFloatField;
    cdsLineasPRECIO_MEDIO_INVENTARIO_LINEA: TFloatField;
    cdsLineasPRECIO_MEDIO_NUEVO_INVENTARIO_LINEA: TFloatField;
    cdsLineasTOTAL_COSTE_DIFERENCIA_LINEA: TFloatField;
    cdsLineasFECHA_RECUENTO_INVENTARIO_LINEA: TDateTimeField;

    // === Campos in-memory para SKUs dinámicos (1 a 5 atributos) ===
    cdsLineasNUM_ATRIBUTOS_REQ_INV_LINEA: TIntegerField;
    cdsLineasATTR1_NOMBRE: TStringField;
    cdsLineasATTR1_VALOR: TStringField;
    cdsLineasATTR2_NOMBRE: TStringField;
    cdsLineasATTR2_VALOR: TStringField;
    cdsLineasATTR3_NOMBRE: TStringField;
    cdsLineasATTR3_VALOR: TStringField;
    cdsLineasATTR4_NOMBRE: TStringField;
    cdsLineasATTR4_VALOR: TStringField;
    cdsLineasATTR5_NOMBRE: TStringField;
    cdsLineasATTR5_VALOR: TStringField;
    // Unidades regularizadas (calculado: 0 si ABIERTO, =DIFERENCIA si APLICADO)
    cdsLineasUDS_REGULARIZADAS: TFloatField;

    // === MOVIMIENTOS DE ALMACÉN GENERADOS POR ESTE INVENTARIO (Pestaña 3) ===
    unqryMovsRegul: TUniQuery;
    dsMovsRegul: TDataSource;

    // === CONSULTAS AUXILIARES ===
    unqryArticulo: TUniQuery;                  // Buscar artículo por código
    unqryDefinicionArticulo: TUniQuery;        // Definición atributos del SKU
    unqryStockActual: TUniQuery;               // Lectura PMP/Stock actual
    unqryFamilias: TUniQuery;                  // Lookup familias
    dsFamilias: TDataSource;
    unqryProveedores: TUniQuery;               // Lookup proveedores
    dsProveedores: TDataSource;
    unqryAlmacenes: TUniQuery;
    dsAlmacenes: TDataSource;
    unqryEmpresas: TUniQuery;
    dsEmpresas: TDataSource;
    unqrySeries: TUniQuery;
    dsSeries: TDataSource;

    // === STORED PROCEDURES ===
    unspActualizarTeorico: TUniStoredProc;     // PRC_FZA_INVENTARIOS_ACTUALIZAR_TEORICO
    unspAplicar: TUniStoredProc;               // PRC_FZA_INVENTARIOS_APLICAR
    unspEliminarRegul: TUniStoredProc;
    cdsLineasINSTANTE_ALTA: TDateTimeField;
    cdsLineasUSUARIO_ALTA: TWideStringField;
    cdsLineasUSUARIO_MODIF: TWideStringField;
    cdsLineasINSTANTE_MODIF: TDateTimeField;         // PRC_FZA_INVENTARIOS_ELIMINAR_REGUL (nuevo)

    // === EVENTOS DE DATASET ===
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGAfterScroll(DataSet: TDataSet);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure cdsLineasAfterPost(DataSet: TDataSet);
    procedure cdsLineasBeforePost(DataSet: TDataSet);
    procedure cdsLineasBeforeDelete(DataSet: TDataSet);
    procedure cdsLineasCalcFields(DataSet: TDataSet);
    procedure cdsLineasNewRecord(DataSet: TDataSet);
  private
    FCodigoEmpresa: string;
    FCodigoAlmacen: string;
    FSerie: string;
    FNumero: string;
    FUsuario: string;
    FDesempaquetando: Boolean;
    function ObtenerSeriePorDefecto(const AEmpresa,
                                          ATipoDoc: string): string;
    procedure GetCodigoAutoInventario;
  public
    // === CONFIGURACIÓN ===
    procedure SetClavesActivas(const AEmpresa, AAlmacen, ASerie, ANumero: string);

    // === CARGA DE LÍNEAS ===
    procedure CargarLineasInventario;
    procedure CargarMovimientosRegularizacion;

    // === GESTIÓN DE LÍNEAS ===
    function GenerarSiguienteLinea: string;
    function ExisteLineaConSku(const ASku: string): Boolean;
    function GenerarSkuFinal(const AArticuloBase: string): string;
    procedure RellenarDatosArticulo(const ACodigoArticulo: string;
                                    out ADescripcion: string;
                                    out ANumAtributos: Integer;
                                    out ATipoArticulo: string);
    procedure RellenarDatosSku(const ASku: string;
                               out ACantidadTeorica: Currency;
                               out APMPActual: Currency);

    // === CARGAS MASIVAS ===
    procedure CargarPorFamilia(const ACodigoFamilia: string);
    procedure CargarPorProveedor(const ACodigoProveedor: string);
    procedure CargarTodosArticulosConStock;
    procedure CompletarUnidadesNoLeidas;
    procedure CargarDesdeListaSkus(ALista: TStringList);
    function  CargarSkusConMovimientosArticulo(const ACodigoArticulo: string): Integer;
    function  SkuExiste(const ASku: string): Boolean;
    function  CrearSkuDesdeLinea(const ACodigoArticulo, ASku: string;
                                 const AAtributos: array of string): Boolean;

    // === ACCIONES SOBRE INVENTARIO ===
    function GetEstadoInventario: string;
    procedure RecalcularTeorico;
    procedure AplicarInventario;
    procedure EliminarRegularizacion;

    // === PROPIEDADES ===
    property CodigoEmpresa: string read FCodigoEmpresa;
    property CodigoAlmacen: string read FCodigoAlmacen;
    property Serie: string read FSerie;
    property Numero: string read FNumero;

    procedure CargarAlmacenesPorEmpresa(const ACodigoEmpresa: string);
    procedure CargarSeriesPorEmpresa(const ACodigoEmpresa: string);
  private
    procedure DesempaquetarAtributosDesdeSku;
  end;

var
  dmInventarios: TdmInventarios;

implementation

uses
  Vcl.Dialogs,          // MessageDlg para validación de SKU en BeforePost
  inLibUser,            // Usuario logueado
  inLibGlobalVar,
  UniDataConn;      // oConn

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

{ TdmInventarios }

procedure TdmInventarios.CargarLineasInventario;
begin
  if (FCodigoEmpresa = '') or (FNumero = '') then
  begin
    if cdsLineas.Active then cdsLineas.EmptyDataSet;
    Exit;
  end;

  unqryLineas.Close;
  unqryLineas.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
  unqryLineas.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
  unqryLineas.ParamByName('SERIE').AsString   := FSerie;
  unqryLineas.ParamByName('NUMERO').AsString  := FNumero;
  unqryLineas.Open;
  var iCount := unqryLineas.RecordCount;
  if cdsLineas.Active then cdsLineas.Close;
  cdsLineas.Open;

  // Volcado instantaneo de los valores de atributos a partir del SKU
  DesempaquetarAtributosDesdeSku;
end;

procedure TdmInventarios.DesempaquetarAtributosDesdeSku;
var
  Sku, ValorAtr: string;
  Partes: TArray<string>;
  i: Integer;
begin
  if (not cdsLineas.Active) or cdsLineas.IsEmpty then
    Exit;
  FDesempaquetando := True;
  cdsLineas.DisableControls;
  try
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      Sku := cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString;
      if Sku <> '' then
      begin
        Partes := Sku.Split(['/']);
        if Length(Partes) > 1 then
        begin
          if not (cdsLineas.State in [dsEdit, dsInsert]) then
            cdsLineas.Edit;
          // Tantos atributos como segmentos haya tras el código de artículo.
          // Sin esto, GenerarSkuFinal itera 0 veces sobre las líneas cargadas
          // de BBDD y el SKU se queda obsoleto al cambiar Color/Talla.
          cdsLineas.FieldByName('NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger :=
                                                          Length(Partes) - 1;
          for i := 1 to 5 do
          begin
            if i < Length(Partes) then
              ValorAtr := Partes[i]
            else
              ValorAtr := '';
            cdsLineas.FieldByName('ATTR' + IntToStr(i) + '_VALOR').AsString := ValorAtr;
          end;
          cdsLineas.Post;  // AfterPost ya no enviara a BD (FDesempaquetando=True)
        end;
      end;
      cdsLineas.Next;
    end;
    cdsLineas.MergeChangeLog;
  finally
    cdsLineas.EnableControls;
    FDesempaquetando := False;
  end;
end;

procedure TdmInventarios.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection           := oConn;
  unqryLineas.Connection           := oConn;
  unqryMovsRegul.Connection        := oConn;
  unqryArticulo.Connection         := oConn;
  unqryDefinicionArticulo.Connection := oConn;
  unqryStockActual.Connection      := oConn;
  unqryFamilias.Connection         := oConn;
  unqryProveedores.Connection      := oConn;
  unqryAlmacenes.Connection        := oConn;
  unqryEmpresas.Connection         := oConn;
  unqrySeries.Connection           := oConn;
  unspActualizarTeorico.Connection := oConn;
  unspAplicar.Connection           := oConn;
  unspEliminarRegul.Connection     := oConn;

  unqryLineas.SQLUpdate.Text :=
    'UPDATE fza_inventarios_lineas SET '                              + sLineBreak +
    '  CODIGO_ART_INVLIN              = :CODIGO_ART_INVLIN,'          + sLineBreak +
    '  CODIGO_UNIDAD_INVLIN           = :CODIGO_UNIDAD_INVLIN,'       + sLineBreak +
    '  LOTE_INVLIN                    = :LOTE_INVLIN,'                + sLineBreak +
    '  FECHA_CADUCIDAD_INVLIN         = :FECHA_CADUCIDAD_INVLIN,'     + sLineBreak +
    '  DESCRIPCION_ARTICULO_INVLIN    = :DESCRIPCION_ARTICULO_INVLIN,'+ sLineBreak +
    '  CANTIDAD_TEORICA_INVLIN        = :CANTIDAD_TEORICA_INVLIN,'    + sLineBreak +
    '  CANTIDAD_FISICA_INVLIN         = :CANTIDAD_FISICA_INVLIN,'     + sLineBreak +
    '  CANTIDAD_DIFERENCIA_INVLIN     = :CANTIDAD_DIFERENCIA_INVLIN,' + sLineBreak +
    '  PRECIO_MEDIO_INVLIN            = :PRECIO_MEDIO_INVLIN,'        + sLineBreak +
    '  PRECIO_MEDIO_NUEVO_INVLIN      = :PRECIO_MEDIO_NUEVO_INVLIN,'  + sLineBreak +
    '  TOTAL_COSTE_DIFERENCIA_INVLIN  = :TOTAL_COSTE_DIFERENCIA_INVLIN,' + sLineBreak +
    '  FECHA_RECUENTO_INVLIN          = :FECHA_RECUENTO_INVLIN,'      + sLineBreak +
    '  USUARIO_MODIF                  = :USUARIO_MODIF '              + sLineBreak +
    'WHERE CODIGO_EMP_INVLIN          = :OLD_CODIGO_EMP_INVLIN '      + sLineBreak +
    '  AND CODIGO_ALM_INVLIN          = :OLD_CODIGO_ALM_INVLIN '      + sLineBreak +
    '  AND SERIE_INV_INVLIN           = :OLD_SERIE_INV_INVLIN '       + sLineBreak +
    '  AND NUMERO_INV_INVLIN          = :OLD_NUMERO_INV_INVLIN '      + sLineBreak +
    '  AND LINEA_INVLIN               = :OLD_LINEA_INVLIN ';

  unqryLineas.SQLDelete.Text :=
    'DELETE FROM fza_inventarios_lineas '                             + sLineBreak +
    'WHERE CODIGO_EMP_INVLIN          = :OLD_CODIGO_EMP_INVLIN '      + sLineBreak +
    '  AND CODIGO_ALM_INVLIN          = :OLD_CODIGO_ALM_INVLIN '      + sLineBreak +
    '  AND SERIE_INV_INVLIN           = :OLD_SERIE_INV_INVLIN '       + sLineBreak +
    '  AND NUMERO_INV_INVLIN          = :OLD_NUMERO_INV_INVLIN '      + sLineBreak +
    '  AND LINEA_INVLIN               = :OLD_LINEA_INVLIN ';

  // Apertura de los lookups
  if not unqryEmpresas.Active   then unqryEmpresas.Open;
  if not unqryAlmacenes.Active  then unqryAlmacenes.Open;
  if not unqrySeries.Active     then unqrySeries.Open;
  if not unqryFamilias.Active   then unqryFamilias.Open;
  if not unqryProveedores.Active then unqryProveedores.Open;

  FUsuario := oUser;
end;

procedure TdmInventarios.SetClavesActivas(const AEmpresa, AAlmacen, ASerie,
  ANumero: string);
begin
  FCodigoEmpresa := AEmpresa;
  FCodigoAlmacen := AAlmacen;
  FSerie         := ASerie;
  FNumero        := ANumero;
end;

procedure TdmInventarios.unqryTablaGAfterScroll(DataSet: TDataSet);
begin
  // Cuando navegamos por las cabeceras, refrescamos las dependientes
  if DataSet.IsEmpty then
    Exit;
  if DataSet.ControlsDisabled then
    Exit;
  SetClavesActivas( DataSet.FieldByName('CODIGO_EMP_INV').AsString,
                    DataSet.FieldByName('CODIGO_ALM_INV').AsString,
                    DataSet.FieldByName('SERIE_INV').AsString,
                    DataSet.FieldByName('NUMERO_INV').AsString );
  CargarLineasInventario;
  CargarMovimientosRegularizacion;
end;

procedure TdmInventarios.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  // Pre-rellenamos los datos por defecto del usuario logueado al crear un
  // inventario nuevo, igual que hace facturas:
  //   - empresa/almacen del usuario (oEmpresa/oAlmacen, cargados en login)
  //   - serie por defecto de la empresa para tipo IN
  //   - NUMERO_INV='0' como marcador para que BeforePost asigne el contador
  //     real desde fza_contadores via PRC_GET_NEXT_CONT_FACT_SERIE.
  if Trim(oEmpresa) <> '' then
    DataSet.FieldByName('CODIGO_EMP_INV').AsString := oEmpresa;
  if Trim(oAlmacen) <> '' then
    DataSet.FieldByName('CODIGO_ALM_INV').AsString := oAlmacen;
  DataSet.FieldByName('TIPO_DOC_INV').AsString := 'IN';
  DataSet.FieldByName('FECHA_INV').AsDateTime  := Now;
  DataSet.FieldByName('ESTADO_INV').AsString   := 'ABIERTO';
  DataSet.FieldByName('NUMERO_INV').AsString   := '0';
  if Trim(oEmpresa) <> '' then
    DataSet.FieldByName('SERIE_INV').AsString  :=
                                       ObtenerSeriePorDefecto(oEmpresa, 'IN');
end;

procedure TdmInventarios.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  // Forzamos campos de auditoría
  if DataSet.State = dsInsert then
  begin
    DataSet.FieldByName('USUARIO_ALTA').AsString := FUsuario;
    if DataSet.FieldByName('FECHA_INV').IsNull then
      DataSet.FieldByName('FECHA_INV').AsDateTime := Now;
    if DataSet.FieldByName('ESTADO_INV').AsString = '' then
      DataSet.FieldByName('ESTADO_INV').AsString := 'ABIERTO';
    if DataSet.FieldByName('TIPO_DOC_INV').AsString = '' then
      DataSet.FieldByName('TIPO_DOC_INV').AsString := 'IN';
    // Si el numero viene a '0' (recien insertado), tomamos el contador real
    // de fza_contadores. El SP esta nombrado como FACT_SERIE pero es generico
    // y acepta cualquier tipo de documento + serie + empresa.
    if DataSet.FieldByName('NUMERO_INV').AsString = '0' then
      GetCodigoAutoInventario;
  end;
  DataSet.FieldByName('USUARIO_MODIF').AsString := FUsuario;
end;

function TdmInventarios.ObtenerSeriePorDefecto(const AEmpresa,
                                                     ATipoDoc: string): string;
var
  qry: TUniQuery;
begin
  Result := '';
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'SELECT EMPSER ' +
      '  FROM fza_empresas_series ' +
      ' WHERE CODIGO_EMP_EMPSER = :EMPRESA ' +
      '   AND TIPO_DOC_EMPSER  = :TIPO ' +
      '   AND (FECHA_DESDE_EMPSER IS NULL OR FECHA_DESDE_EMPSER <= NOW()) ' +
      '   AND (FECHA_HASTA_EMPSER IS NULL OR FECHA_HASTA_EMPSER >= NOW()) ' +
      ' ORDER BY FECHA_DESDE_EMPSER DESC ' +
      ' LIMIT 1';
    qry.ParamByName('EMPRESA').AsString := AEmpresa;
    qry.ParamByName('TIPO').AsString    := ATipoDoc;
    qry.Open;
    if not qry.IsEmpty then
      Result := qry.FieldByName('EMPSER').AsString;
  finally
    qry.Free;
  end;
end;

procedure TdmInventarios.GetCodigoAutoInventario;
var
  sp: TUniStoredProc;
begin
  if unqryTablaG.FindField('NUMERO_INV').AsString <> '0' then Exit;
  sp := TUniStoredProc.Create(nil);
  try
    sp.Connection := oConn;
    sp.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
    sp.Params.Clear;
    sp.Params.CreateParam(ftString, 'pserie',           ptInput);
    sp.Params.CreateParam(ftString, 'ptipodoc',         ptInput);
    sp.Params.CreateParam(ftString, 'pEMPRESA_CONTADOR',ptInput);
    sp.Params.CreateParam(ftString, 'pUSUARIOMODIF',    ptInput);
    sp.Params.CreateParam(ftString, 'pcont',            ptOutput);
    sp.ParamByName('pserie').AsString :=
                            unqryTablaG.FindField('SERIE_INV').AsString;
    sp.ParamByName('ptipodoc').AsString := 'IN';
    sp.ParamByName('pEMPRESA_CONTADOR').AsString :=
                            unqryTablaG.FindField('CODIGO_EMP_INV').AsString;
    sp.ParamByName('pUSUARIOMODIF').AsString := oUser;
    sp.ExecProc;
    unqryTablaG.FindField('NUMERO_INV').AsString :=
                                              sp.ParamByName('pcont').AsString;
  finally
    sp.Free;
  end;
end;

procedure TdmInventarios.CargarMovimientosRegularizacion;
begin
  unqryMovsRegul.Close;
  if (FCodigoEmpresa = '') or (FCodigoAlmacen = '') or
     (FSerie = '') or (FNumero = '') then Exit;

  // Los movimientos de regularización solo existen si el inventario ya
  // ha sido APLICADO. Si el estado es ABIERTO o CANCELADO, no consultamos.
  if GetEstadoInventario <> 'APLICADO' then Exit;

  unqryMovsRegul.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
  unqryMovsRegul.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
  unqryMovsRegul.ParamByName('SERIE').AsString   := FSerie;
  unqryMovsRegul.ParamByName('NUMERO').AsString  := FNumero;
  unqryMovsRegul.Open;
end;

function TdmInventarios.GenerarSiguienteLinea: string;
var
  Maximo: Integer;
  Clone: TClientDataSet;
begin
  Maximo := 0;
  if cdsLineas.Active and (cdsLineas.RecordCount > 0) then
  begin
    // Iteramos a través de un clon del cursor para no mover el cursor real
    // de cdsLineas. Esto es crítico cuando GenerarSiguienteLinea se llama
    // desde cdsLineasNewRecord (durante Append): mover el cursor con .First
    // mientras el dataset está en dsInsert dispararía el Post automático
    // del registro recién insertado, todavía con CODIGO_ART_INVLIN vacío,
    // y haría saltar cdsLineasBeforePost con "(linea )" sin número.
    Clone := TClientDataSet.Create(nil);
    try
      Clone.CloneCursor(cdsLineas, True);
      Clone.First;
      while not Clone.Eof do
      begin
        if StrToIntDef(Clone.FieldByName('LINEA_INVLIN').AsString, 0) > Maximo then
          Maximo := StrToIntDef(Clone.FieldByName('LINEA_INVLIN').AsString, 0);
        Clone.Next;
      end;
    finally
      Clone.Free;
    end;
  end;
  Result := Format('%.4d', [Maximo + 1]);
end;

function TdmInventarios.ExisteLineaConSku(const ASku: string): Boolean;
var
  Bookmark: TBookmark;
begin
  Result := False;
  if not cdsLineas.Active then Exit;

  Bookmark := cdsLineas.GetBookmark;
  cdsLineas.DisableControls;
  try
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      if SameText(cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString, ASku) then
      begin
        Result := True;
        Break;
      end;
      cdsLineas.Next;
    end;
  finally
    if cdsLineas.BookmarkValid(Bookmark) then
      cdsLineas.GotoBookmark(Bookmark);
    cdsLineas.FreeBookmark(Bookmark);
    cdsLineas.EnableControls;
  end;
end;

function TdmInventarios.GenerarSkuFinal(const AArticuloBase: string): string;
var
  i, NumAttr: Integer;
  ValorAttr: string;
begin
  // Construye el SKU concatenando ARTICULO/ATTR1/ATTR2/... con los valores
  // que haya rellenados en cdsLineas. Si algun valor falta, se omite (el SKU
  // queda incompleto, lo que el llamante interpreta para decidir si ya hay
  // que recalcular teoricas/PMP).
  Result := AArticuloBase;
  if not cdsLineas.Active then Exit;
  if cdsLineas.FindField('NUM_ATRIBUTOS_REQ_INV_LINEA') = nil then Exit;
  NumAttr := cdsLineas.FieldByName('NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger;
  for i := 1 to NumAttr do
  begin
    ValorAttr := cdsLineas.FieldByName('ATTR' + IntToStr(i) + '_VALOR').AsString;
    if Trim(ValorAttr) <> '' then
      Result := Result + '/' + ValorAttr;
  end;
end;

procedure TdmInventarios.RellenarDatosArticulo(const ACodigoArticulo: string;
  out ADescripcion: string; out ANumAtributos: Integer; out ATipoArticulo: string);
begin
  ADescripcion  := '';
  ANumAtributos := 0;
  ATipoArticulo := 'ESTANDAR';

  unqryArticulo.Close;
  unqryArticulo.ParamByName('CODIGO').AsString := ACodigoArticulo;
  unqryArticulo.Open;

  if not unqryArticulo.IsEmpty then
  begin
    ADescripcion  := unqryArticulo.FieldByName('DESCRIPCION_ART').AsString;
    ATipoArticulo := unqryArticulo.FieldByName('TIPO_ART').AsString;
    // Conteo de atributos del artículo padre
    unqryDefinicionArticulo.Close;
    unqryDefinicionArticulo.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    unqryDefinicionArticulo.Open;
    ANumAtributos := unqryDefinicionArticulo.RecordCount;
  end;
end;

procedure TdmInventarios.RellenarDatosSku(const ASku: string;
  out ACantidadTeorica: Currency; out APMPActual: Currency);
begin
  ACantidadTeorica := 0;
  APMPActual       := 0;

  unqryStockActual.Close;
  unqryStockActual.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
  unqryStockActual.ParamByName('SKU').AsString     := ASku;
  unqryStockActual.Open;

  if not unqryStockActual.IsEmpty then
  begin
    ACantidadTeorica := unqryStockActual.FieldByName('CANTIDAD_STK').AsCurrency;
    APMPActual       := unqryStockActual.FieldByName('PRECIO_MEDIO_STK').AsCurrency;
  end;
end;

procedure TdmInventarios.cdsLineasNewRecord(DataSet: TDataSet);
begin
  // Defaults al insertar una línea nueva.
  // Inicializamos a '' los campos NOT NULL del BD (CODIGO_ART_INVLIN,
  // CODIGO_UNIDAD_INVLIN) en vez de dejarlos NULL: asi al pulsar Grabar el
  // TClientDataSet.Post no falla con "Field value required" antes de que
  // cdsLineasBeforePost pueda dar un mensaje claro.
  DataSet.FieldByName('CODIGO_EMP_INVLIN').AsString := FCodigoEmpresa;
  DataSet.FieldByName('CODIGO_ALM_INVLIN').AsString := FCodigoAlmacen;
  DataSet.FieldByName('SERIE_INV_INVLIN').AsString  := FSerie;
  DataSet.FieldByName('NUMERO_INV_INVLIN').AsString := FNumero;
  DataSet.FieldByName('LINEA_INVLIN').AsString      := GenerarSiguienteLinea;
  DataSet.FieldByName('CODIGO_ART_INVLIN').AsString    := '';
  DataSet.FieldByName('CODIGO_UNIDAD_INVLIN').AsString := '';
  DataSet.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency    := 0;
  DataSet.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency     := 0;
  DataSet.FieldByName('CANTIDAD_DIFERENCIA_INVLIN').AsCurrency := 0;
  DataSet.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency        := 0;
  DataSet.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency  := 0;
  DataSet.FieldByName('NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger        := 0;
  DataSet.FieldByName('USUARIO_ALTA').AsString                         := FUsuario;
  DataSet.FieldByName('USUARIO_MODIF').AsString                        := FUsuario;
end;

procedure TdmInventarios.cdsLineasCalcFields(DataSet: TDataSet);
var
  Estado: string;
  Diferencia: Currency;
begin
  // El cálculo de uds regularizadas: si el inventario está APLICADO,
  // entonces es la propia diferencia. Si está ABIERTO/CANCELADO es 0.
  Estado := GetEstadoInventario;
  Diferencia := DataSet.FieldByName('CANTIDAD_DIFERENCIA_INVLIN').AsCurrency;

  if Estado = 'APLICADO' then
    DataSet.FieldByName('UDS_REGULARIZADAS').AsCurrency := Diferencia
  else
    DataSet.FieldByName('UDS_REGULARIZADAS').AsCurrency := 0;
end;

procedure TdmInventarios.cdsLineasBeforePost(DataSet: TDataSet);
var
  CodArticulo, CodSku: string;
  Atribs: array[0..4] of string;
  i: Integer;
begin
  // Validamos antes de Post para dar un mensaje claro en lugar del cryptico
  // "Field value required" del TClientDataSet.
  if FDesempaquetando then Exit;
  if Trim(DataSet.FieldByName('CODIGO_ART_INVLIN').AsString) = '' then
    raise Exception.Create(
      'No se puede grabar una linea sin articulo. Selecciona un articulo o '+
      'elimina la linea (linea ' +
      DataSet.FieldByName('LINEA_INVLIN').AsString + ').');
  // Si por alguna razon CODIGO_UNIDAD_INVLIN ha quedado vacio, lo rellenamos
  // con el codigo del articulo. CODIGO_UNIDAD_INVLIN es NOT NULL en BD.
  if Trim(DataSet.FieldByName('CODIGO_UNIDAD_INVLIN').AsString) = '' then
    DataSet.FieldByName('CODIGO_UNIDAD_INVLIN').AsString :=
      DataSet.FieldByName('CODIGO_ART_INVLIN').AsString;

  // Validación de SKU: si la línea apunta a un SKU con atributos
  // (CODIGO_UNIDAD_INVLIN ≠ CODIGO_ART_INVLIN) que no existe en
  // fza_articulos_skus, preguntar al usuario si quiere crearlo. Sin esto,
  // PRC_FZA_INVENTARIOS_APLICAR genera movimientos huérfanos sobre un SKU
  // que no existe ni en fza_articulos_skus ni en fza_atributos_sku, y el
  // stock no aparece bien en las pestañas de stock pivotado.
  CodArticulo := DataSet.FieldByName('CODIGO_ART_INVLIN').AsString;
  CodSku      := DataSet.FieldByName('CODIGO_UNIDAD_INVLIN').AsString;
  if (CodSku <> CodArticulo) and (not SkuExiste(CodSku)) then
  begin
    if MessageDlg(
         Format(
           'El SKU "%s" no existe en la base de datos.'#13#10#13#10 +
           '¿Quieres crearlo automáticamente con los atributos seleccionados ' +
           'y guardar la línea?'#13#10#13#10 +
           'Sí: se crea el SKU (fza_articulos_skus + fza_atributos_sku) y ' +
           'se graba la línea.'#13#10 +
           'No: no se graba. Cambia los atributos a una combinación válida ' +
           'o pulsa "- Eliminar línea".',
           [CodSku]),
         mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      raise Exception.CreateFmt(
        'SKU "%s" no existe. La línea no se ha grabado. Cambia los ' +
        'atributos o elimina la línea.', [CodSku]);

    for i := 0 to 4 do
      Atribs[i] := DataSet.FieldByName('ATTR' + IntToStr(i + 1) +
                                                          '_VALOR').AsString;
    CrearSkuDesdeLinea(CodArticulo, CodSku, Atribs);
  end;
end;

procedure TdmInventarios.cdsLineasAfterPost(DataSet: TDataSet);
begin
  // Durante el desempaquetado de atributos in-memory NO debemos enviar
  // cambios a BD: esos campos no existen en fza_inventarios_lineas.
  if FDesempaquetando then
    Exit;

  if cdsLineas.ChangeCount > 0 then
    cdsLineas.ApplyUpdates(0);
end;

procedure TdmInventarios.cdsLineasBeforeDelete(DataSet: TDataSet);
begin
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create('No se pueden eliminar líneas: el inventario no está ABIERTO');
end;

function TdmInventarios.GetEstadoInventario: string;
begin
  Result := '';
  if unqryTablaG.Active and not unqryTablaG.IsEmpty then
    Result := unqryTablaG.FieldByName('ESTADO_INV').AsString;
end;

procedure TdmInventarios.RecalcularTeorico;
begin
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create('Solo se puede recalcular un inventario en estado ABIERTO');

  // Aseguramos que cualquier cambio pendiente se persiste antes de llamar al
  // SP. Si la linea recien insertada esta incompleta (sin articulo picado)
  // hacer Post da "Field value required". Cancelamos en ese caso.
  if cdsLineas.Active then
  begin
    if cdsLineas.State in [dsInsert, dsEdit] then
    begin
      if (Trim(cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString) = '') or
         (Trim(cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString) = '') then
        cdsLineas.Cancel
      else
        cdsLineas.Post;
    end;
    if cdsLineas.ChangeCount > 0 then
      cdsLineas.ApplyUpdates(0);
  end;

  unspActualizarTeorico.Close;
  unspActualizarTeorico.ParamByName('p_EMPRESA').AsString := FCodigoEmpresa;
  unspActualizarTeorico.ParamByName('p_ALMACEN').AsString := FCodigoAlmacen;
  unspActualizarTeorico.ParamByName('p_SERIE').AsString   := FSerie;
  unspActualizarTeorico.ParamByName('p_NRO').AsString     := FNumero;
  unspActualizarTeorico.ParamByName('p_USUARIO').AsString := FUsuario;
  unspActualizarTeorico.ExecProc;

  // Refrescamos las líneas
  CargarLineasInventario;
  unqryTablaG.Refresh;
end;

procedure TdmInventarios.AplicarInventario;
begin
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create('Solo se puede aplicar un inventario en estado ABIERTO');

  // Mismo Post defensivo que en RecalcularTeorico.
  if cdsLineas.Active then
  begin
    if cdsLineas.State in [dsInsert, dsEdit] then
    begin
      if (Trim(cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString) = '') or
         (Trim(cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString) = '') then
        cdsLineas.Cancel
      else
        cdsLineas.Post;
    end;
    if cdsLineas.ChangeCount > 0 then
      cdsLineas.ApplyUpdates(0);
  end;

  unspAplicar.Close;
  unspAplicar.ParamByName('p_EMPRESA').AsString := FCodigoEmpresa;
  unspAplicar.ParamByName('p_ALMACEN').AsString := FCodigoAlmacen;
  unspAplicar.ParamByName('p_SERIE').AsString   := FSerie;
  unspAplicar.ParamByName('p_NRO').AsString     := FNumero;
  unspAplicar.ParamByName('p_USUARIO').AsString := FUsuario;
  unspAplicar.ExecProc;

  // Refrescamos
  CargarLineasInventario;
  CargarMovimientosRegularizacion;
  unqryTablaG.Refresh;
end;

procedure TdmInventarios.EliminarRegularizacion;
begin
  if GetEstadoInventario <> 'APLICADO' then
    raise Exception.Create('Solo se puede eliminar la regularización de un inventario APLICADO');

  unspEliminarRegul.Close;
  unspEliminarRegul.ParamByName('p_EMPRESA').AsString := FCodigoEmpresa;
  unspEliminarRegul.ParamByName('p_ALMACEN').AsString := FCodigoAlmacen;
  unspEliminarRegul.ParamByName('p_SERIE').AsString   := FSerie;
  unspEliminarRegul.ParamByName('p_NRO').AsString     := FNumero;
  unspEliminarRegul.ParamByName('p_USUARIO').AsString := FUsuario;
  unspEliminarRegul.ExecProc;

  CargarLineasInventario;
  CargarMovimientosRegularizacion;
  unqryTablaG.Refresh;
end;

procedure TdmInventarios.CargarPorFamilia(const ACodigoFamilia: string);
var
  qry: TUniQuery;
  NumLinea: Integer;
begin
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create('Solo se pueden cargar artículos en un inventario ABIERTO');

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, ' +
      '       a.DESCRIPCION_ART, ' +
      '       IFNULL(stk.CANTIDAD_STK, 0)        AS CANTIDAD_ARTVIN, ' +
      '       IFNULL(stk.PRECIO_MEDIO_STK, 0)    AS PMP ' +
      '  FROM fza_articulos_skus s ' +
      '  JOIN fza_articulos a ' +
      '    ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU ' +
      '  LEFT JOIN fza_articulos_stockactual stk ' +
      '    ON stk.CODIGO_UNIDAD_STK   = s.CODIGO_UNIDAD_SKU ' +
      '   AND stk.CODIGO_ALM_STK = :ALMACEN ' +
      ' WHERE a.CODIGO_FAM_ART = :FAMILIA ' +
      '   AND a.TIPO_ART = ''ESTANDAR'' ' +
      ' ORDER BY a.CODIGO_ART_ART, s.CODIGO_UNIDAD_SKU';
    qry.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
    qry.ParamByName('FAMILIA').AsString := ACodigoFamilia;
    qry.Open;

    NumLinea := StrToIntDef(GenerarSiguienteLinea, 1);
    cdsLineas.DisableControls;
    try
      while not qry.Eof do
      begin
        // Saltar duplicados
        if not ExisteLineaConSku(qry.FieldByName('CODIGO_UNIDAD_SKU').AsString) then
        begin
          cdsLineas.Append;
          cdsLineas.FieldByName('LINEA_INVLIN').AsString          := Format('%.4d', [NumLinea]);
          cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString := qry.FieldByName('CODIGO_ART_SKU').AsString;
          cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString   := qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
          cdsLineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString := qry.FieldByName('DESCRIPCION_ART').AsString;
          cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency   := qry.FieldByName('CANTIDAD_ARTVIN').AsCurrency;
          cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency    := qry.FieldByName('CANTIDAD_ARTVIN').AsCurrency; // por defecto = teórica
          cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency       := qry.FieldByName('PMP').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency := qry.FieldByName('PMP').AsCurrency; // por defecto = anterior
          cdsLineas.Post;
          Inc(NumLinea);
        end;
        qry.Next;
      end;
      cdsLineas.ApplyUpdates(0);
    finally
      cdsLineas.EnableControls;
    end;
  finally
    qry.Free;
  end;
end;

procedure TdmInventarios.CargarPorProveedor(const ACodigoProveedor: string);
var
  qry: TUniQuery;
  NumLinea: Integer;
begin
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create('Solo se pueden cargar artículos en un inventario ABIERTO');

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, ' +
      '       a.DESCRIPCION_ART, ' +
      '       IFNULL(stk.CANTIDAD_STK, 0)     AS CANTIDAD_ARTVIN, ' +
      '       IFNULL(stk.PRECIO_MEDIO_STK, 0) AS PMP ' +
      '  FROM fza_articulos_proveedores ap ' +
      '  JOIN fza_articulos a ' +
      '    ON a.CODIGO_ART_ART = ap.CODIGO_ARTICULO_AP ' +
      '  JOIN fza_articulos_skus s ' +
      '    ON s.CODIGO_ART_SKU = a.CODIGO_ART_ART ' +
      '  LEFT JOIN fza_articulos_stockactual stk ' +
      '    ON stk.CODIGO_UNIDAD_STK   = s.CODIGO_UNIDAD_SKU ' +
      '   AND stk.CODIGO_ALM_STK = :ALMACEN ' +
      ' WHERE ap.CODIGO_PROVEEDOR_AP = :PROVEEDOR ' +
      '   AND a.TIPO_ART = ''ESTANDAR'' ' +
      ' ORDER BY a.CODIGO_ART_ART, s.CODIGO_UNIDAD_SKU';
    qry.ParamByName('ALMACEN').AsString   := FCodigoAlmacen;
    qry.ParamByName('PROVEEDOR').AsString := ACodigoProveedor;
    qry.Open;

    NumLinea := StrToIntDef(GenerarSiguienteLinea, 1);
    cdsLineas.DisableControls;
    try
      while not qry.Eof do
      begin
        if not ExisteLineaConSku(qry.FieldByName('CODIGO_UNIDAD_SKU').AsString) then
        begin
          cdsLineas.Append;
          cdsLineas.FieldByName('LINEA_INVLIN').AsString          := Format('%.4d', [NumLinea]);
          cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString := qry.FieldByName('CODIGO_ART_SKU').AsString;
          cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString   := qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
          cdsLineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString := qry.FieldByName('DESCRIPCION_ART').AsString;
          cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency   := qry.FieldByName('CANTIDAD_ARTVIN').AsCurrency;
          cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency    := qry.FieldByName('CANTIDAD_ARTVIN').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency       := qry.FieldByName('PMP').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency := qry.FieldByName('PMP').AsCurrency;
          cdsLineas.Post;
          Inc(NumLinea);
        end;
        qry.Next;
      end;
      cdsLineas.ApplyUpdates(0);
    finally
      cdsLineas.EnableControls;
    end;
  finally
    qry.Free;
  end;
end;

procedure TdmInventarios.CargarTodosArticulosConStock;
var
  qry: TUniQuery;
  NumLinea: Integer;
begin
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create('Solo se pueden cargar artículos en un inventario ABIERTO');

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, ' +
      '       a.DESCRIPCION_ART, ' +
      '       stk.CANTIDAD_STK     AS CANTIDAD_ARTVIN, ' +
      '       stk.PRECIO_MEDIO_STK AS PMP ' +
      '  FROM fza_articulos_skus s ' +
      '  JOIN fza_articulos a ' +
      '    ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU ' +
      '  JOIN fza_articulos_stockactual stk ' +
      '    ON stk.CODIGO_UNIDAD_STK   = s.CODIGO_UNIDAD_SKU ' +
      '   AND stk.CODIGO_ALM_STK = :ALMACEN ' +
      ' WHERE a.TIPO_ART = ''ESTANDAR'' ' +
      '   AND stk.CANTIDAD_STK <> 0 ' +
      ' ORDER BY a.CODIGO_ART_ART, s.CODIGO_UNIDAD_SKU';
    qry.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
    qry.Open;

    NumLinea := StrToIntDef(GenerarSiguienteLinea, 1);
    cdsLineas.DisableControls;
    try
      while not qry.Eof do
      begin
        if not ExisteLineaConSku(qry.FieldByName('CODIGO_UNIDAD_SKU').AsString) then
        begin
          cdsLineas.Append;
          cdsLineas.FieldByName('LINEA_INVLIN').AsString          := Format('%.4d', [NumLinea]);
          cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString := qry.FieldByName('CODIGO_ART_SKU').AsString;
          cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString   := qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
          cdsLineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString := qry.FieldByName('DESCRIPCION_ART').AsString;
          cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency   := qry.FieldByName('CANTIDAD_ARTVIN').AsCurrency;
          cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency    := qry.FieldByName('CANTIDAD_ARTVIN').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency       := qry.FieldByName('PMP').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency := qry.FieldByName('PMP').AsCurrency;
          cdsLineas.Post;
          Inc(NumLinea);
        end;
        qry.Next;
      end;
      cdsLineas.ApplyUpdates(0);
    finally
      cdsLineas.EnableControls;
    end;
  finally
    qry.Free;
  end;
end;

procedure TdmInventarios.CompletarUnidadesNoLeidas;
var
  qry: TUniQuery;
  NumLinea: Integer;
begin
  // "Completar" significa: traer al inventario todos los SKUs con stock que NO
  // estén ya en el inventario actual, asignándoles cantidad_artvin física = 0
  // (porque NO se han contado / son los que faltan).
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create('Solo se puede completar un inventario ABIERTO');

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_ART_SKU, ' +
      '       a.DESCRIPCION_ART, ' +
      '       stk.CANTIDAD_STK     AS CANTIDAD_ARTVIN, ' +
      '       stk.PRECIO_MEDIO_STK AS PMP ' +
      '  FROM fza_articulos_skus s ' +
      '  JOIN fza_articulos a ' +
      '    ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU ' +
      '  JOIN fza_articulos_stockactual stk ' +
      '    ON stk.CODIGO_UNIDAD_STK   = s.CODIGO_UNIDAD_SKU ' +
      '   AND stk.CODIGO_ALM_STK = :ALMACEN ' +
      ' WHERE a.TIPO_ART = ''ESTANDAR'' ' +
      '   AND stk.CANTIDAD_STK <> 0 ' +
      '   AND NOT EXISTS ( ' +
      '         SELECT 1 FROM fza_inventarios_lineas l ' +
      '          WHERE l.CODIGO_EMP_INVLIN = :EMPRESA ' +
      '            AND l.CODIGO_ALM_INVLIN = :ALMACEN ' +
      '            AND l.SERIE_INV_INVLIN          = :SERIE ' +
      '            AND l.NUMERO_INV_INVLIN            = :NUMERO ' +
      '            AND l.CODIGO_UNIDAD_INVLIN  = s.CODIGO_UNIDAD_SKU) ' +
      ' ORDER BY a.CODIGO_ART_ART, s.CODIGO_UNIDAD_SKU';
    qry.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
    qry.ParamByName('EMPRESA').AsString := FCodigoEmpresa;
    qry.ParamByName('SERIE').AsString   := FSerie;
    qry.ParamByName('NUMERO').AsString  := FNumero;
    qry.Open;

    NumLinea := StrToIntDef(GenerarSiguienteLinea, 1);
    cdsLineas.DisableControls;
    try
      while not qry.Eof do
      begin
        cdsLineas.Append;
        cdsLineas.FieldByName('LINEA_INVLIN').AsString          := Format('%.4d', [NumLinea]);
        cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString := qry.FieldByName('CODIGO_ART_SKU').AsString;
        cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString   := qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
        cdsLineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString := qry.FieldByName('DESCRIPCION_ART').AsString;
        cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency   := qry.FieldByName('CANTIDAD_ARTVIN').AsCurrency;
        // OJO: en COMPLETAR, la cantidad_artvin física es 0 — porque por definición no se ha contado
        cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency    := 0;
        cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency       := qry.FieldByName('PMP').AsCurrency;
        cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency := qry.FieldByName('PMP').AsCurrency;
        cdsLineas.Post;
        Inc(NumLinea);
        qry.Next;
      end;
      cdsLineas.ApplyUpdates(0);
    finally
      cdsLineas.EnableControls;
    end;
  finally
    qry.Free;
  end;
end;

function TdmInventarios.CargarSkusConMovimientosArticulo(
  const ACodigoArticulo: string): Integer;
var
  qry: TUniQuery;
  NumLinea: Integer;
  Sku: string;
begin
  // Inserta una línea de inventario por cada SKU distinto del artículo
  // ACodigoArticulo que tenga al menos un movimiento en el almacén actual.
  // Salta SKUs que ya estén presentes en este inventario.
  // Devuelve el número de líneas insertadas.
  Result := 0;
  if Trim(ACodigoArticulo) = '' then
    raise Exception.Create('Debe indicar un artículo (la línea actual está vacía).');
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create('Solo se pueden añadir SKUs en un inventario ABIERTO');

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'SELECT DISTINCT m.CODIGO_UNIDAD_MOV AS CODIGO_UNIDAD_SKU, ' +
      '       m.CODIGO_ART_MOV    AS CODIGO_ART_SKU, ' +
      '       a.DESCRIPCION_ART, ' +
      '       COALESCE(stk.CANTIDAD_STK, 0)     AS CANTIDAD_TEORICA, ' +
      '       COALESCE(stk.PRECIO_MEDIO_STK, 0) AS PMP ' +
      '  FROM fza_movimientos_almacen m ' +
      '  JOIN fza_articulos a ' +
      '    ON a.CODIGO_ART_ART = m.CODIGO_ART_MOV ' +
      '  LEFT JOIN fza_articulos_stockactual stk ' +
      '    ON stk.CODIGO_UNIDAD_STK = m.CODIGO_UNIDAD_MOV ' +
      '   AND stk.CODIGO_ALM_STK    = :ALMACEN ' +
      ' WHERE m.CODIGO_ART_MOV = :ARTICULO ' +
      '   AND m.CODIGO_ALM_MOV = :ALMACEN ' +
      ' ORDER BY m.CODIGO_UNIDAD_MOV';
    qry.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    qry.ParamByName('ALMACEN').AsString  := FCodigoAlmacen;
    qry.Open;

    if qry.IsEmpty then Exit;

    NumLinea := StrToIntDef(GenerarSiguienteLinea, 1);
    cdsLineas.DisableControls;
    try
      while not qry.Eof do
      begin
        Sku := qry.FieldByName('CODIGO_UNIDAD_SKU').AsString;
        if (Sku <> '') and (not ExisteLineaConSku(Sku)) then
        begin
          cdsLineas.Append;
          cdsLineas.FieldByName('LINEA_INVLIN').AsString          := Format('%.4d', [NumLinea]);
          cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString     := qry.FieldByName('CODIGO_ART_SKU').AsString;
          cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString  := Sku;
          cdsLineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString := qry.FieldByName('DESCRIPCION_ART').AsString;
          cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency   := qry.FieldByName('CANTIDAD_TEORICA').AsCurrency;
          // FISICA = 0: el usuario aún tiene que contar
          cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency    := 0;
          cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency       := qry.FieldByName('PMP').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency := qry.FieldByName('PMP').AsCurrency;
          cdsLineas.Post;
          Inc(NumLinea);
          Inc(Result);
        end;
        qry.Next;
      end;
      if Result > 0 then
      begin
        cdsLineas.ApplyUpdates(0);
        DesempaquetarAtributosDesdeSku;
      end;
    finally
      cdsLineas.EnableControls;
    end;
  finally
    qry.Free;
  end;
end;

function TdmInventarios.SkuExiste(const ASku: string): Boolean;
var
  qry: TUniQuery;
begin
  Result := False;
  if Trim(ASku) = '' then Exit;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text := 'SELECT 1 FROM fza_articulos_skus ' +
                    ' WHERE CODIGO_UNIDAD_SKU = :SKU LIMIT 1';
    qry.ParamByName('SKU').AsString := ASku;
    qry.Open;
    Result := not qry.IsEmpty;
    qry.Close;
  finally
    qry.Free;
  end;
end;

function TdmInventarios.CrearSkuDesdeLinea(const ACodigoArticulo, ASku: string;
  const AAtributos: array of string): Boolean;
var
  qry: TUniQuery;
  i, IdAv: Integer;
  ValorAtrib: string;
begin
  // Crea fza_articulos_skus + fza_atributos_sku para un SKU que no existía,
  // a partir del artículo padre y los valores de atributo de la línea.
  // CODIGO_VAR_SKU se hereda del primer SKU existente del artículo o, si no
  // hay ninguno, de fza_articulos.TIPO_VARIACION_ART.
  Result := False;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;

    // 1) Insertar la cabecera del SKU.
    qry.SQL.Text :=
      'INSERT IGNORE INTO fza_articulos_skus ' +
      '  (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU, CODIGO_VAR_SKU, ' +
      '   ESACTIVO_SKU, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'SELECT :SKU, :ART, ' +
      '       COALESCE( ' +
      '         (SELECT s.CODIGO_VAR_SKU FROM fza_articulos_skus s ' +
      '           WHERE s.CODIGO_ART_SKU = :ART LIMIT 1), ' +
      '         (SELECT a.TIPO_VARIACION_ART FROM fza_articulos a ' +
      '           WHERE a.CODIGO_ART_ART = :ART) ' +
      '       ), ''S'', NOW(), :USR, :USR';
    qry.ParamByName('SKU').AsString := ASku;
    qry.ParamByName('ART').AsString := ACodigoArticulo;
    qry.ParamByName('USR').AsString := FUsuario;
    qry.ExecSQL;

    // 2) Insertar la relación con cada valor de atributo. La posición i+1
    //    corresponde al ORDEN_VISUAL_ATRIBUTO de vi_atributos_nombres.
    for i := 0 to High(AAtributos) do
    begin
      ValorAtrib := Trim(AAtributos[i]);
      if ValorAtrib = '' then Continue;

      qry.SQL.Text :=
        'SELECT v.ID_AV ' +
        '  FROM fza_atributos_valores v ' +
        '  JOIN vi_atributos_nombres n ON v.ID_VA_AV = n.ID_ATRIBUTO ' +
        ' WHERE n.CODIGO_ART_PADRE_ARTVIN = :ART ' +
        '   AND n.ORDEN_VISUAL_ATRIBUTO = :ORDEN ' +
        '   AND v.AV = :VALOR ' +
        '   AND COALESCE(v.ESACTIVO_AV, ''S'') = ''S'' ' +
        ' LIMIT 1';
      qry.ParamByName('ART').AsString    := ACodigoArticulo;
      qry.ParamByName('ORDEN').AsInteger := i + 1;
      qry.ParamByName('VALOR').AsString  := ValorAtrib;
      qry.Open;
      if qry.IsEmpty then
      begin
        qry.Close;
        raise Exception.CreateFmt(
          'No se encontró el valor "%s" en el atributo nº %d del artículo %s. ' +
          'No se ha podido crear el SKU %s.',
          [ValorAtrib, i + 1, ACodigoArticulo, ASku]);
      end;
      IdAv := qry.FieldByName('ID_AV').AsInteger;
      qry.Close;

      qry.SQL.Text :=
        'INSERT IGNORE INTO fza_atributos_sku ' +
        '  (CODIGO_UNIDAD_SKU_SA, ID_AV_SA, ' +
        '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (:SKU, :IDAV, NOW(), :USR, :USR)';
      qry.ParamByName('SKU').AsString   := ASku;
      qry.ParamByName('IDAV').AsInteger := IdAv;
      qry.ParamByName('USR').AsString   := FUsuario;
      qry.ExecSQL;
    end;

    Result := True;
  finally
    qry.Free;
  end;
end;

procedure TdmInventarios.CargarAlmacenesPorEmpresa(const ACodigoEmpresa: string);
begin
  unqryAlmacenes.Close;
  if ACodigoEmpresa = '' then Exit;
  unqryAlmacenes.ParamByName('EMPRESA').AsString := ACodigoEmpresa;
  unqryAlmacenes.Open;
end;

procedure TdmInventarios.CargarSeriesPorEmpresa(const ACodigoEmpresa: string);
begin
  // Solo aplicable si la SQL de unqrySeries declara el parámetro :EMPRESA
  // (ver dfm: tabla fza_empresas_series filtrada por CODIGO_EMP_EMPSER).
  unqrySeries.Close;
  if ACodigoEmpresa = '' then
  begin
    unqrySeries.Open;
    Exit;
  end;
  if unqrySeries.Params.FindParam('EMPRESA') <> nil then
    unqrySeries.ParamByName('EMPRESA').AsString := ACodigoEmpresa;
  unqrySeries.Open;
end;

procedure TdmInventarios.CargarDesdeListaSkus(ALista: TStringList);
var
  i, NumLinea: Integer;
  Sku, ArticuloPadre: string;
  CANTIDAD_ARTVIN, PMP: Currency;
  qry: TUniQuery;
begin
  // Cada línea de la lista debe tener: SKU;CANTIDAD_FISICA  (separador ; o tab)
  // O bien solo el SKU (cantidad_artvin física = 1)
  if GetEstadoInventario <> 'ABIERTO' then
    raise Exception.Create('Solo se pueden cargar artículos en un inventario ABIERTO');

  qry := TUniQuery.Create(nil);
  try
    qry.Connection := oConn;
    qry.SQL.Text :=
      'SELECT s.CODIGO_ART_SKU, a.DESCRIPCION_ART ' +
      '  FROM fza_articulos_skus s ' +
      '  JOIN fza_articulos a ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU ' +
      ' WHERE s.CODIGO_UNIDAD_SKU = :SKU';

    NumLinea := StrToIntDef(GenerarSiguienteLinea, 1);
    cdsLineas.DisableControls;
    try
      for i := 0 to ALista.Count - 1 do
      begin
        Sku := Trim(ALista.Names[i]);
        if Sku = '' then
          Sku := Trim(ALista[i]);
        if Sku = '' then Continue;

        CANTIDAD_ARTVIN := StrToCurrDef(ALista.ValueFromIndex[i], 1);

        qry.Close;
        qry.ParamByName('SKU').AsString := Sku;
        qry.Open;
        if qry.IsEmpty then Continue; // ignorar SKUs que no existen
        ArticuloPadre := qry.FieldByName('CODIGO_ART_SKU').AsString;

        RellenarDatosSku(Sku, PMP, PMP); // PMP en variable temporal
        // Recargamos PMP correctamente:
        unqryStockActual.Close;
        unqryStockActual.ParamByName('ALMACEN').AsString := FCodigoAlmacen;
        unqryStockActual.ParamByName('SKU').AsString     := Sku;
        unqryStockActual.Open;

        // Si el SKU ya existe en el inventario, sumamos cantidad_artvin
        if ExisteLineaConSku(Sku) then
        begin
          if cdsLineas.Locate('CODIGO_UNIDAD_INVLIN', Sku, [loCaseInsensitive]) then
          begin
            cdsLineas.Edit;
            cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency :=
              cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency + CANTIDAD_ARTVIN;
            cdsLineas.Post;
          end;
        end
        else
        begin
          cdsLineas.Append;
          cdsLineas.FieldByName('LINEA_INVLIN').AsString          := Format('%.4d', [NumLinea]);
          cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString := ArticuloPadre;
          cdsLineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString   := Sku;
          cdsLineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString := qry.FieldByName('DESCRIPCION_ART').AsString;
          cdsLineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency   := unqryStockActual.FieldByName('CANTIDAD_STK').AsCurrency;
          cdsLineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency    := CANTIDAD_ARTVIN;
          cdsLineas.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency       := unqryStockActual.FieldByName('PRECIO_MEDIO_STK').AsCurrency;
          cdsLineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency := unqryStockActual.FieldByName('PRECIO_MEDIO_STK').AsCurrency;
          cdsLineas.FieldByName('FECHA_RECUENTO_INVLIN').AsDateTime     := Now;
          cdsLineas.Post;
          Inc(NumLinea);
        end;
      end;
      cdsLineas.ApplyUpdates(0);
    finally
      cdsLineas.EnableControls;
    end;
  finally
    qry.Free;
  end;
end;


initialization
  ForceReferenceToClass(TdmInventarios);
end.
