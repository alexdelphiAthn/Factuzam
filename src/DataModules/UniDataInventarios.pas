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
  UniDataGen;

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
    unspEliminarRegul: TUniStoredProc;         // PRC_FZA_INVENTARIOS_ELIMINAR_REGUL (nuevo)

    // === EVENTOS DE DATASET ===
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGAfterScroll(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure cdsLineasAfterPost(DataSet: TDataSet);
    procedure cdsLineasBeforeDelete(DataSet: TDataSet);
    procedure cdsLineasCalcFields(DataSet: TDataSet);
    procedure cdsLineasNewRecord(DataSet: TDataSet);
  private
    FCodigoEmpresa: string;
    FCodigoAlmacen: string;
    FSerie: string;
    FNumero: string;
    FUsuario: string;
  public
    // === CONFIGURACIÓN ===
    procedure SetClavesActivas(const AEmpresa, AAlmacen, ASerie, ANumero: string);

    // === CARGA DE LÍNEAS ===
    procedure CargarLineasInventario;
    procedure CargarMovimientosRegularizacion;

    // === GESTIÓN DE LÍNEAS ===
    function GenerarSiguienteLinea: string;
    function ExisteLineaConSku(const ASku: string): Boolean;
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
  end;

var
  dmInventarios: TdmInventarios;

implementation

uses
  inLibUser,            // Usuario logueado
  inLibGlobalVar,
  UniDataConn;      // oConn

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

{ TdmInventarios }

procedure TdmInventarios.DataModuleCreate(Sender: TObject);
begin
  // Asignación de la conexión global a todos los queries del módulo
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

  // CRÍTICO: por defecto UniDAC genera UPDATEs con todos los campos en el
  // WHERE para control optimista de concurrencia. La tabla tiene
  // INSTANTE_MODIF con ON UPDATE CURRENT_TIMESTAMP, por lo que el segundo
  // UPDATE sobre una misma fila falla con "Record not found or changed by
  // another user" porque el INSTANTE_MODIF antiguo ya no existe en BD.
  //
  // Solución: especificar UPDATE/DELETE personalizados que sólo usan la PK.
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
  if DataSet.IsEmpty then Exit;

  SetClavesActivas(
    DataSet.FieldByName('CODIGO_EMP_INV').AsString,
    DataSet.FieldByName('CODIGO_ALM_INV').AsString,
    DataSet.FieldByName('SERIE_INV').AsString,
    DataSet.FieldByName('NUMERO_INV').AsString
  );

  CargarLineasInventario;
  CargarMovimientosRegularizacion;
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
  end;
  DataSet.FieldByName('USUARIO_MODIF').AsString := FUsuario;
end;

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

  if cdsLineas.Active then cdsLineas.Close;
  cdsLineas.Open;
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
begin
  Maximo := 0;
  if cdsLineas.Active and (cdsLineas.RecordCount > 0) then
  begin
    cdsLineas.DisableControls;
    try
      cdsLineas.First;
      while not cdsLineas.Eof do
      begin
        if StrToIntDef(cdsLineas.FieldByName('LINEA_INVLIN').AsString, 0) > Maximo then
          Maximo := StrToIntDef(cdsLineas.FieldByName('LINEA_INVLIN').AsString, 0);
        cdsLineas.Next;
      end;
    finally
      cdsLineas.EnableControls;
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
  // Defaults al insertar una línea nueva
  DataSet.FieldByName('CODIGO_EMP_INVLIN').AsString := FCodigoEmpresa;
  DataSet.FieldByName('CODIGO_ALM_INVLIN').AsString := FCodigoAlmacen;
  DataSet.FieldByName('SERIE_INV_INVLIN').AsString          := FSerie;
  DataSet.FieldByName('NUMERO_INV_INVLIN').AsString            := FNumero;
  DataSet.FieldByName('LINEA_INVLIN').AsString          := GenerarSiguienteLinea;
  DataSet.FieldByName('CANTIDAD_TEORICA_INVLIN').AsCurrency := 0;
  DataSet.FieldByName('CANTIDAD_FISICA_INVLIN').AsCurrency := 0;
  DataSet.FieldByName('PRECIO_MEDIO_INVLIN').AsCurrency    := 0;
  DataSet.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency := 0;
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

procedure TdmInventarios.cdsLineasAfterPost(DataSet: TDataSet);
begin
  // Persistencia inmediata a BD
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

  // Aseguramos que cualquier cambio pendiente se persiste antes de llamar al SP
  if cdsLineas.Active and (cdsLineas.ChangeCount > 0) then
    cdsLineas.ApplyUpdates(0);

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

  if cdsLineas.Active and (cdsLineas.ChangeCount > 0) then
    cdsLineas.ApplyUpdates(0);

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

end.
