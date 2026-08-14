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
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, cxListView, Vcl.Forms,
  Vcl.ComCtrls, Winapi.Windows, system.strUtils, cxGridDBTableView,
  cxCustomData, cxFilter,
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
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryTablaGAfterDelete(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryProveedoresArticulosBeforePost(DataSet: TDataSet);
    procedure unqryTarifasArticulosBeforePost(DataSet: TDataSet);
    procedure unqryTarifasArticulosAfterPost(DataSet: TDataSet);
    procedure unqryTarifasArticulosBeforeDelete(DataSet: TDataSet);
    procedure unqryTarifasArticulosAfterDelete(DataSet: TDataSet);
    procedure unqryStockArticulosAfterScroll(DataSet: TDataSet);
    procedure unqryVariacionesArticulosBeforePost(DataSet: TDataSet);
    procedure unqryVariacionesArticulosBeforeDelete(DataSet: TDataSet);
    procedure unqrySkusBeforePost(DataSet: TDataSet);
    procedure unqrySkusBeforeDelete(DataSet: TDataSet);
    procedure unqrySkusAfterPost(DataSet: TDataSet);
    procedure unqrySkusAfterDelete(DataSet: TDataSet);
    procedure unqryDetallesAtributosBeforePost(DataSet: TDataSet);
  private
    // Vista de stock del Mto de Articulos, empujada por el form via
    // AsignarVistaStock (el DM ya no la busca con GetOwnerForm).
    FVistaStock: TcxGridDBTableView;
    FCodigoArticuloBorrado: string;
    FCodigoArticuloTarifaBorrada: string;
    FCodigoArticuloSkuBorrado: string;
    FPermitirCambiarMarcaWeb: Boolean;
    procedure AsegurarSkuBase(const ACodArt: string);
    procedure ValidarCambioMarcaWeb(ADataSet: TDataSet);
    procedure QuitarEscribiblesVista;
    procedure ActualizarSkuActivo(const aSku, aActivo: string);
    procedure UpsertCosteSku(const aSku: string;
                             aPrecioField, aFechaField: TField);
    procedure EliminarCosteSku(const aSku: string);
    procedure ReconstruirColumnasStock(AVista: TcxGridDBTableView);
    procedure AplicarAnchosColumnasStock(AVista: TcxGridDBTableView);
    procedure ConfigurarFiltroStock(AVista: TcxGridDBTableView);
    function PrepararClaveTarifa: Integer;
    procedure AplicarEstadoTarifaPorPrecio;
    procedure ValidarPeriodoTarifa(APk: Integer);
    procedure SanearDescuentoTarifa;

  public
    procedure PoblarCdsEtiquetasArtDesdeUniQuery;
    procedure ExpandirEtiquetasPorStock(const aFldStock: string);
    // Activa ('S') o desactiva ('N') en bloque todos los SKU del articulo que
    // comparten un mismo color (atributo 'CO'). La llama la ficha SKU desde el
    // menu/boton de color. Devuelve cuantos SKU forman el grupo de color.
    function ActualizarSkusColorActivo(const aCodArt, aColor,
                                       aActivo: string): Integer;
    // Override: abre las queries detalle y lookups del Mto de Articulos
    // (tarifas, proveedores, lineas-factura, variaciones, skus, stock,
    // movimientos, atributos basicos, ivas, familias). Lo invoca
    // TfrmMtoGen.AbrirTablaPrincipalAsync DENTRO del thread del Open de
    // unqryTablaG. Antes de este refactor los Opens vivian en
    // DataModuleCreate y bloqueaban la UI 17-21 segundos al abrir el tab.
    // El form empuja su dsTablaG; el DM ya no usa GetOwnerForm. El
    // TdmArticulos temporal del boton 'Pegatinas' nunca recibe estas
    // llamadas, igual que antes el GetOwnerForm le devolvia nil.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    procedure AsignarVistaStock(AVista: TcxGridDBTableView);
    procedure AsignarPermisoCambioMarcaWeb(APermitido: Boolean);
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

  System.Diagnostics,
  inLibCadenas, inLibDatasets,
  inLibLogIntf,
  inLibPrestaShopColaSenal,
  UniDataPrestaShopEncolado,
  UniDataValoresAutomaticosRepositorio,
  inLibMsgArticulos;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

const
  // Construimos manualmente la lista IN (...) con los codigos elegidos.
  // Los codigos vienen de fza_almacenes (validados al cargar el checklist),
  // asi que no llegan de entrada de usuario libre.
  cSqlEtiquetasArt =
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
  cSqlHexEtiquetas =
    'SELECT sa.CODIGO_UNIDAD_SKU_SA AS CODIGO_UNIDAD_SKU,' +
    '       atb.HEX_ATB             AS HEX_ATR_CO ' +
    '  FROM fza_atributos_sku sa' +
    '  JOIN fza_articulos_skus sk' +
    '    ON sk.CODIGO_UNIDAD_SKU = sa.CODIGO_UNIDAD_SKU_SA' +
    '  JOIN fza_atributos_valores av' +
    '    ON av.ID_AV     = sa.ID_AV_SA' +
    '   AND av.ID_VA_AV  = ''CO''' +
    '  JOIN fza_articulos_atributos_basicos aab' +
    '    ON aab.CODIGO_ART_AAB = sk.CODIGO_ART_SKU' +
    '   AND aab.ID_AV_AAB     = av.ID_AV' +
    '  JOIN fza_atributos_basicos atb' +
    '    ON atb.ID_ATB = aab.ID_ATB_AAB';

function TipoSeguroCdsEtiquetas(ATipo: TFieldType): TFieldType;
begin
  case ATipo of
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
    Result := ftWideString;
  end;
end;

function CargarMapaHexEtiquetas(
  AConexion: TUniConnection;
  const ARegistroLog: IRegistroLog): TDictionary<string, string>;
var
  oConsulta: TUniQuery;
  sCodigoSku: string;
begin
  Result := TDictionary<string, string>.Create;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := cSqlHexEtiquetas;
    try
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        sCodigoSku := oConsulta.FieldByName(
          'CODIGO_UNIDAD_SKU').AsString;
        if sCodigoSku <> '' then
          Result.AddOrSetValue(
            sCodigoSku,
            oConsulta.FieldByName('HEX_ATR_CO').AsString);
        oConsulta.Next;
      end;
      oConsulta.Close;
    except
      on E: Exception do
      begin
        if Assigned(ARegistroLog) then
          ARegistroLog.RegistrarAviso(
            'EtiquetasArt: mapa de colores HEX no disponible: ' +
            E.Message);
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure CopiarFilasEtiquetas(
  AOrigen: TDataSet;
  ADestino: TClientDataSet;
  AIndiceCodigoSku: Integer;
  AMapaHex: TDictionary<string, string>);
var
  i: Integer;
  sCodigoSku: string;
  sHex: string;
begin
  if AOrigen.Active and not AOrigen.IsEmpty then
  begin
    ADestino.DisableControls;
    try
      AOrigen.First;
      while not AOrigen.Eof do
      begin
        ADestino.Append;
        for i := 0 to AOrigen.FieldCount - 1 do
          ADestino.Fields[i].Value := AOrigen.Fields[i].Value;
        if AIndiceCodigoSku >= 0 then
        begin
          sCodigoSku := AOrigen.Fields[AIndiceCodigoSku].AsString;
          if (sCodigoSku <> '') and
             AMapaHex.TryGetValue(sCodigoSku, sHex) then
            ADestino.FieldByName('HEX_ATR_CO').AsString := sHex;
        end;
        ADestino.Post;
        AOrigen.Next;
      end;
    finally
      ADestino.EnableControls;
    end;
  end;
end;

function TdmArticulos.ArticuloTieneProvPrin(sArt:String):Boolean;
var
  unqrySol: TUniQuery;
begin
  unqrySol := TUniQuery.Create(nil);
  unqrySol.Connection := ConexionPrincipal;
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
    qry.Connection := ConexionPrincipal;
    qry.SQL.Text :=
      'UPDATE fza_articulos_skus '   +
      '   SET ESACTIVO_SKU = :ACT, ' +
      '       USUARIO_MODIF = :USR ' +
      ' WHERE CODIGO_UNIDAD_SKU = :SKU';
    qry.ParamByName('ACT').AsString := aActivo;
    qry.ParamByName('USR').AsString := IdentidadSesion.Usuario;
    qry.ParamByName('SKU').AsString := aSku;
    qry.ExecSQL;
    EncolarCambioPrestaShop(
      qry.Connection,
      '',
      aSku,
      True,
      True,
      IdentidadSesion.Usuario);
  finally
    FreeAndNil(qry);
  end;
end;

function TdmArticulos.ActualizarSkusColorActivo(const aCodArt, aColor,
  aActivo: string): Integer;
// Activa ('S') o desactiva ('N') en bloque todos los SKU del articulo cuyo
// color (atributo 'CO' resuelto por vi_atributos_sku_basico) coincide con
// aColor. Se hace en DOS pasos -- SELECT de los codigos de SKU + UPDATE por
// codigo -- y no en una sola sentencia con subconsulta, porque la vista lee de
// fza_articulos_skus y no se puede leer+actualizar la misma tabla a la vez
// (error 1093 de MariaDB; el truco de la tabla derivada no es fiable con
// derived_merge). Devuelve cuantos SKU forman el grupo de color.
var
  qrySel, qryUpd: TUniQuery;
begin
  Result := 0;
  qrySel := TUniQuery.Create(nil);
  qryUpd := TUniQuery.Create(nil);
  try
    qrySel.Connection := ConexionPrincipal;
    qrySel.SQL.Text :=
      'SELECT DISTINCT CODIGO_UNIDAD_SKU '                                  +
      '  FROM vi_atributos_sku_basico '                                     +
      ' WHERE CODIGO_ART_SKU = :ART '                                       +
      '   AND ID_VA_AV       = ''CO'' '                                     +
      '   AND VALOR_AV       = :COLOR';
    qrySel.ParamByName('ART').AsString   := aCodArt;
    qrySel.ParamByName('COLOR').AsString := aColor;
    qrySel.Open;
    qryUpd.Connection := ConexionPrincipal;
    qryUpd.SQL.Text :=
      'UPDATE fza_articulos_skus '   +
      '   SET ESACTIVO_SKU  = :ACT, '+
      '       USUARIO_MODIF = :USR ' +
      ' WHERE CODIGO_UNIDAD_SKU = :SKU';
    while not qrySel.Eof do
    begin
      qryUpd.ParamByName('ACT').AsString := aActivo;
      qryUpd.ParamByName('USR').AsString := IdentidadSesion.Usuario;
      qryUpd.ParamByName('SKU').AsString :=
        qrySel.FieldByName('CODIGO_UNIDAD_SKU').AsString;
      qryUpd.ExecSQL;
      Inc(Result);
      qrySel.Next;
    end;
    if Result > 0 then
      EncolarArticuloPrestaShop(
        qryUpd.Connection,
        aCodArt,
        IdentidadSesion.Usuario);
  finally
    FreeAndNil(qryUpd);
    FreeAndNil(qrySel);
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
  if fldSku <> nil then
  begin
    sSku := fldSku.AsString;
    if DataSet.State = dsInsert then
    begin
      if Trim(sSku) = '' then
        raise ERangeError.Create(SErrorCodigoSkuCodigoBarrasObligatorio);
      if fldCB = nil then
        raise ERangeError.Create(SErrorCampoCodigoBarrasAusente);
      ActualizarAuditoria(DataSet);
    end
    else if DataSet.State = dsEdit then
    begin
      ActualizarAuditoria(DataSet);
      bChangedActivo := (fldAct <> nil) and
        (VarToStr(fldAct.OldValue) <> fldAct.AsString);
      // ESACTIVO_SKU pertenece a fza_articulos_skus.
      if bChangedActivo then
        ActualizarSkuActivo(sSku, fldAct.AsString);
    end;
  end;
end;

procedure TdmArticulos.unqrySkusBeforePost(DataSet: TDataSet);
var
  fldPrecio, fldFecha: TField;
begin
  inherited;
  if DataSet.State = dsInsert then
  begin
    if Trim(DataSet.FieldByName('CODIGO_UNIDAD_SKU').AsString) = '' then
      raise ERangeError.Create(SErrorCodigoSkuObligatorio);
    // Article code se hereda del master/detail, pero por seguridad lo
    // forzamos al artículo activo si está vacío.
    if Trim(DataSet.FieldByName('CODIGO_ART_SKU').AsString) = '' then
      DataSet.FieldByName('CODIGO_ART_SKU').AsString :=
                              unqryTablaG.FieldByName(
                                'CODIGO_ART_ART').AsString;
  end;
  ActualizarAuditoria(DataSet);

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
  if SameText(
    unqryTablaG.FieldByName('ESWEB_ART').AsString,
    'S') then
    raise EDatabaseError.Create(
      'No se puede borrar un SKU de un artículo En web. ' +
      'Desmarque Activo para enviar stock cero a PrestaShop');
  FCodigoArticuloSkuBorrado := Trim(
    DataSet.FieldByName('CODIGO_ART_SKU').AsString);
  // Sin FK declarada, la fila de coste quedaría huérfana al borrar el SKU:
  // la limpiamos antes de que el framework dispare el DELETE sobre
  // fza_articulos_skus.
  EliminarCosteSku(DataSet.FieldByName('CODIGO_UNIDAD_SKU').AsString);
end;

procedure TdmArticulos.unqrySkusAfterPost(DataSet: TDataSet);
begin
  EncolarArticuloPrestaShop(
    unqrySkus.Connection,
    DataSet.FieldByName('CODIGO_ART_SKU').AsString,
    IdentidadSesion.Usuario);
end;

procedure TdmArticulos.unqrySkusAfterDelete(DataSet: TDataSet);
begin
  EncolarArticuloPrestaShop(
    unqrySkus.Connection,
    FCodigoArticuloSkuBorrado,
    IdentidadSesion.Usuario);
  FCodigoArticuloSkuBorrado := '';
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
  if Trim(aSku) <> '' then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := ConexionPrincipal;
      qry.SQL.Text :=
        'INSERT INTO fza_articulos_skus_costes ' +
        '       (CODIGO_UNIDAD_SKU_SKUC, PRECIO_ULT_COMPRA_SKUC, ' +
        '        FECHA_ULT_COMPRA_SKUC, ' +
        '        INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (:SKU, :PRECIO, :FECHA, ' +
        '        CURRENT_TIMESTAMP, :USR, :USR) ' +
        'ON DUPLICATE KEY UPDATE ' +
        '   PRECIO_ULT_COMPRA_SKUC = VALUES(PRECIO_ULT_COMPRA_SKUC), ' +
        '   FECHA_ULT_COMPRA_SKUC  = VALUES(FECHA_ULT_COMPRA_SKUC), ' +
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
      qry.ParamByName('USR').AsString := IdentidadSesion.Usuario;
      qry.ExecSQL;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

procedure TdmArticulos.EliminarCosteSku(const aSku: string);
var
  qry: TUniQuery;
begin
  if Trim(aSku) <> '' then
  begin
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := ConexionPrincipal;
      qry.SQL.Text :=
        'DELETE FROM fza_articulos_skus_costes ' +
        ' WHERE CODIGO_UNIDAD_SKU_SKUC = :SKU';
      qry.ParamByName('SKU').AsString := aSku;
      qry.ExecSQL;
    finally
      FreeAndNil(qry);
    end;
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
    raise ERangeError.Create(SErrorFilaCodigoBarrasInexistente);
end;

procedure TdmArticulos.unqryProveedoresArticulosBeforePost(DataSet: TDataSet);
begin
  inherited;
  if unqryProveedoresArticulos.State = dsInsert then
    if Trim(unqryProveedoresArticulos.FindField(
      'ESPROVEEDORPRINCIPAL').AsString) = 'S' then
    begin
      if ArticuloTieneProvPrin(
        unqryProveedoresArticulos.FindField(
          'CODIGO_ART_ART').AsString) then
      begin
        raise ERangeError.CreateFmt(SErrorProveedorPrincipalArticulo,
          [unqryProveedoresArticulos.FindField(
            'CODIGO_ART_ART').AsString]);
      end;
    end;
  ActualizarAuditoria(DataSet);
end;

procedure TdmArticulos.ReconstruirColumnasStock(
  AVista: TcxGridDBTableView);
begin
  AVista.BeginUpdate;
  try
    AVista.ClearItems;
    AVista.DataController.CreateAllItems;
  finally
    AVista.EndUpdate;
  end;
end;

procedure TdmArticulos.AplicarAnchosColumnasStock(
  AVista: TcxGridDBTableView);
const
  ANCHO_ALMACEN = 180;
  ANCHO_COLOR = 90;
  ANCHO_TOTAL = 80;
  ANCHO_TALLA = 55;
var
  Columna: TcxGridDBColumn;
  NombreCampo: string;
  Indice: Integer;
begin
  for Indice := 0 to AVista.ColumnCount - 1 do
  begin
    Columna := AVista.Columns[Indice] as TcxGridDBColumn;
    NombreCampo := Columna.DataBinding.FieldName;
    if SameText(NombreCampo, 'Almacen') then
      Columna.Width := ANCHO_ALMACEN
    else if SameText(NombreCampo, 'Color') then
      Columna.Width := ANCHO_COLOR
    else if SameText(NombreCampo, 'Total') then
      Columna.Width := ANCHO_TOTAL
    else
      Columna.Width := ANCHO_TALLA;
  end;
end;

procedure TdmArticulos.ConfigurarFiltroStock(
  AVista: TcxGridDBTableView);
var
  Columna: TcxGridDBColumn;
  ColumnaGrupo: TcxGridDBColumn;
  ColumnaTotal: TcxGridDBColumn;
  OcultarCeros: Boolean;
  NombreCampo: string;
  Indice: Integer;
begin
  ColumnaGrupo := nil;
  ColumnaTotal := nil;
  for Indice := 0 to AVista.ColumnCount - 1 do
  begin
    Columna := AVista.Columns[Indice] as TcxGridDBColumn;
    NombreCampo := Columna.DataBinding.FieldName;
    if SameText(NombreCampo, 'Total') or
       SameText(NombreCampo, 'Stock Total') then
      ColumnaTotal := Columna
    else if not SameText(NombreCampo, 'Almacen') and
            (Columna.DataBinding.Field <> nil) and
            (Columna.DataBinding.Field.DataType in
              [ftString, ftWideString, ftMemo, ftWideMemo]) then
      ColumnaGrupo := Columna;
  end;
  OcultarCeros := Assigned(ParametrosApp) and
    ParametrosApp.GetBool('appStockOcultarCeros', True);
  AVista.DataController.Filter.BeginUpdate;
  try
    AVista.DataController.Filter.Root.Clear;
    AVista.DataController.Filter.Root.BoolOperatorKind := fboAnd;
    if ColumnaGrupo <> nil then
      AVista.DataController.Filter.Root.AddItem(
        ColumnaGrupo as TObject, foNotEqual, '-', '-');
    if OcultarCeros and (ColumnaTotal <> nil) then
      AVista.DataController.Filter.Root.AddItem(
        ColumnaTotal as TObject, foNotEqual, 0, '0');
  finally
    AVista.DataController.Filter.EndUpdate;
  end;
  AVista.DataController.Filter.Active :=
    (ColumnaGrupo <> nil) or (OcultarCeros and (ColumnaTotal <> nil));
end;

procedure TdmArticulos.unqryStockArticulosAfterScroll(DataSet: TDataSet);
var
  tvArticulosStock: TcxGridDBTableView;
  sArt: string;
  swTotal, swTramo: TStopwatch;
  msSP, msRebuild, msAnchos: Int64;
begin
  inherited;
  if (not DataSet.ControlsDisabled) and DataSet.Active and
     (not DataSet.IsEmpty) then
  begin
    swTotal := TStopwatch.StartNew;
    msSP := 0;
    msRebuild := 0;
    msAnchos := 0;
    unqryStockArticulos.Close;
    sArt := unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
    unqryStockArticulos.ParamByName('CODIGO_ART_ART').AsString := sArt;
    tvArticulosStock := FVistaStock;
    if tvArticulosStock <> nil then
    begin
      if sArt <> '' then
      begin
        swTramo := TStopwatch.StartNew;
        unqryStockArticulos.Open;
        msSP := swTramo.ElapsedMilliseconds;

        ReconstruirColumnasStock(tvArticulosStock);
        if unqryStockArticulos.Active and
           (tvArticulosStock.ColumnCount > 0) then
        begin
          AplicarAnchosColumnasStock(tvArticulosStock);
          ConfigurarFiltroStock(tvArticulosStock);
        end;
      end;
      RegistroLog.RegistrarRendimiento('Articulos.StockAfterScroll',
        Format('art=%s | SP=%d ms | RebuildItems=%d ms | ' +
          'Anchos=%d ms | cols=%d',
          [sArt, msSP, msRebuild, msAnchos,
           tvArticulosStock.ColumnCount]),
        swTotal.ElapsedMilliseconds);
    end;
  end;
end;

procedure TdmArticulos.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
  inherited;
  FCodigoArticuloBorrado := Trim(
    DataSet.FieldByName('CODIGO_ART_ART').AsString);
end;

procedure TdmArticulos.unqryTablaGAfterDelete(DataSet: TDataSet);
var
  qryBorrarLineas : TUniQuery;
begin
  qryBorrarLineas := TUniQuery.Create(Self);
  qryBorrarLineas.Connection := ConexionPrincipal;
  qryBorrarLineas.SQL.Text := 'DELETE ' +
    '  FROM fza_articulos_proveedores ' +
    ' WHERE CODIGO_ART_AP = :Articulo ;';
  qryBorrarLineas.Params.ParamByName('Articulo').AsString :=
    FCodigoArticuloBorrado;
  qryBorrarLineas.ExecSQL;
  qryBorrarLineas.SQL.Text := 'DELETE ' +
    '  FROM fza_articulos_tarifas ' +
    ' WHERE CODIGO_ART_ARTTAR = :Articulo ;';
  qryBorrarLineas.Params.ParamByName('Articulo').AsString :=
    FCodigoArticuloBorrado;
  qryBorrarLineas.ExecSQL;
  qryBorrarLineas.Free;
  OmitirArticuloPrestaShop(
    unqryTablaG.Connection,
    FCodigoArticuloBorrado,
    IdentidadSesion.Usuario);
  FCodigoArticuloBorrado := '';
//  end;
end;

procedure TdmArticulos.unqryTablaGAfterInsert(DataSet: TDataSet);
var
  oCampoWeb: TField;
begin
  inherited;
  UniDataValoresAutomaticosRepositorio.AplicarValoresPorDefecto(
    ConexionPrincipal, unqryTablaG, 'fza_articulos');
  // La marca web es opt-in: un artículo nuevo nunca debe publicarse por
  // accidente ni enviar NULL aunque aún no exista un valor configurable.
  oCampoWeb := unqryTablaG.FindField('ESWEB_ART');
  if Assigned(oCampoWeb) and (Trim(oCampoWeb.AsString) = '') then
    oCampoWeb.AsString := 'N';
  unqryTablaG.FindField('CODIGO_FAM_ART').AsString :=
                                   ObtenerValorPorDefecto(
                                     ConexionPrincipal,
                                     'vi_articulos_familias_list',
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
  sArt := Trim(unqryTablaG.FindField('CODIGO_ART_ART').AsString);
  if SameText(unqryTablaG.FindField('ESWEB_ART').AsString, 'S') then
    EncolarArticuloPrestaShop(
      unqryTablaG.Connection,
      sArt,
      IdentidadSesion.Usuario)
  else
    OmitirArticuloPrestaShop(
      unqryTablaG.Connection,
      sArt,
      IdentidadSesion.Usuario);
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
    qry.Connection := ConexionPrincipal;
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
    qry.ParamByName('usr').AsString  := IdentidadSesion.Usuario;
    qry.ExecSQL;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TdmArticulos.CopiarProveedoraArticulo(dtProveedores: TDataset);
begin
  if unqryProveedoresArticulos.State = dsBrowse then
    unqryProveedoresArticulos.Insert;
  unqryProveedoresArticulos.FindField('CODIGO_PRV_PRV').AsString :=
    dtProveedores.FindField('CODIGO_PRV_PRV').AsString;
  unqryProveedoresArticulos.FindField('RAZON_SOCIAL_PRV').AsString :=
    dtProveedores.FindField('RAZON_SOCIAL_PRV').AsString;
  if unqryProveedoresArticulos.RecordCount = 0 then
    unqryProveedoresArticulos.FindField(
      'ESPROVEEDORPRINCIPAL').AsString := 'S'
  else
    unqryProveedoresArticulos.FindField(
      'ESPROVEEDORPRINCIPAL').AsString := 'N';
  unqryProveedoresArticulos.Post;
end;

procedure TdmArticulos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  // Solo asignamos Connection y MasterSource. Los Open se han movido a
  // AbrirDetalles (que invoca TfrmMtoGen.AbrirTablaPrincipalAsync en thread)
  // para no congelar la UI durante la creacion del data module.
  unqryFamiliaArticulos.Connection := ConexionPrincipal;
  unqryPerfiles.Connection := ConexionPrincipal;
  unqryTarifasArticulos.Connection := ConexionPrincipal;
  unqryProveedoresArticulos.Connection := ConexionPrincipal;
  unqryLinFacturasArticulos.Connection := ConexionPrincipal;
  unqryProveedores.Connection := ConexionPrincipal;
  unqryTiposIVA.Connection := ConexionPrincipal;
  unqryTarifas.Connection := ConexionPrincipal;
  unqryVariacionesArticulos.Connection := ConexionPrincipal;
  unqrySkus.Connection := ConexionPrincipal;
  unqryStockArticulos.Connection := ConexionPrincipal;
  unqryMovimientosArticulos.Connection := ConexionPrincipal;
  unqryDetallesAtributos.Connection := ConexionPrincipal;
  unqryAtributosBasicosLookup.Connection := ConexionPrincipal;
  unqryUnidadesMedidaLookup.Connection := ConexionPrincipal;
  // El detalle de atributos sigue al SKU activo (master) para mostrar sólo
  // las filas del SKU posicionado en la rejilla superior.
  unqryDetallesAtributos.MasterSource := dsSkus;
end;

procedure TdmArticulos.AsignarMaestroCabecera(ADataSource: TDataSource);
begin
  inherited;
  unqryVariacionesArticulos.MasterSource := ADataSource;
  unqrySkus.MasterSource := ADataSource;
  unqryLinFacturasArticulos.MasterSource := ADataSource;
  unqryTarifasArticulos.MasterSource := ADataSource;
  unqryProveedoresArticulos.MasterSource := ADataSource;
  unqryMovimientosArticulos.MasterSource := ADataSource;
end;

procedure TdmArticulos.AsignarVistaStock(AVista: TcxGridDBTableView);
begin
  FVistaStock := AVista;
end;

procedure TdmArticulos.AbrirDetalles;
const
  TAG = 'Articulos.AbrirDetalles';

  procedure AbrirConTiempo(qry: TUniQuery; const Nombre: string);
  var
    swQ: TStopwatch;
  begin
    if not qry.Active then
    begin
    swQ := TStopwatch.StartNew;
    try
      qry.Open;
      RegistroLog.RegistrarRendimiento(
        TAG, Nombre + ' OK', swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento(TAG,
          Nombre + ' ERROR=' + E.Message,
          swQ.ElapsedMilliseconds);
        raise;
      end;
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
  RegistroLog.RegistrarRendimiento(TAG, 'TOTAL', sw.ElapsedMilliseconds);
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
  if not unqryTarifasArticulos.Active then
  begin
    sw := TStopwatch.StartNew;
    try
      unqryTarifasArticulos.Open;
      QuitarEscribiblesVista;
      RegistroLog.RegistrarRendimiento(
        'Articulos.Lazy', 'unqryTarifasArticulos OK',
        sw.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento('Articulos.Lazy',
          'unqryTarifasArticulos ERROR=' + E.Message,
          sw.ElapsedMilliseconds);
        raise;
      end;
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
    begin
      if SameText(s, NombreCampo) then
        Result := True;
    end;
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
  if ContainsText(unqryTarifas.SQL.Text, ':CODIGO_ART_ART') then
    unqryTarifas.ParamByName('CODIGO_ART_ART').AsString :=
      unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
  unqryTarifas.Open;
  unqryTarifas.First;
  while not unqryTarifas.Eof do
  begin
    Itm := lst.Items.Add;
    Itm.Caption :=
      unqryTarifas.FindField('CODIGO_TAR_ARTTAR').AsString;
    Itm.SubItems.Add(
      unqryTarifas.FindField('NOMBRE_TAR_TAR').AsString);
    if SameText(
      unqryTarifas.FindField('CODIGO_TAR_ARTTAR').AsString,
      ParametrosCaja.TarifaDefecto) then
      Itm.Checked := True;
    unqryTarifas.Next;
  end;
  unqryTarifas.Close;
end;

procedure TdmArticulos.GetCodigoAutoArticulo;
begin
  if unqryTablaG.FindField('CODIGO_ART_ART').AsString = '0' then
  begin
    unqryTablaG.FindField('CODIGO_ART_ART').AsString :=
                          ObtenerSiguienteContador(
                                                   ConexionPrincipal,
                                                   'AR',
                                                   IdentidadSesion.Usuario);
  end;
  if unqryTablaG.FindField('ORDEN_ART').AsString = '0' then
  begin
      unqryTablaG.FindField('ORDEN_ART').AsString :=
                          ObtenerSiguienteContador(
                                                   ConexionPrincipal,
                                                   'AO',
                                                   IdentidadSesion.Usuario);
  end;
end;

procedure TdmArticulos.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  ValidarCambioMarcaWeb(DataSet);
  inherited;
  // Insert vacío (accidental): cancelar sin error
  if (DataSet.State = dsInsert) and
     (Trim(unqryTablaG.FindField('DESCRIPCION_ART').AsString) = '') then
    Abort;
  var sDescripcion :=
    Trim(unqryTablaG.FindField('DESCRIPCION_ART').AsString);
  if (sDescripcion = '') or
     SimbolosProhibidos(sDescripcion, PerfilesLectura) then
  begin
    raise ERangeError.CreateFmt(SErrorDescripcionArticulo,
      [unqryTablaG.FindField('DESCRIPCION_ART').AsString]);
  end
  else
    GetCodigoAutoArticulo;
end;

procedure TdmArticulos.AsignarPermisoCambioMarcaWeb(APermitido: Boolean);
begin
  FPermitirCambiarMarcaWeb := APermitido;
end;

procedure TdmArticulos.ValidarCambioMarcaWeb(ADataSet: TDataSet);
var
  Campo: TField;
  Cambio: Boolean;
  EstabaMarcado: Boolean;
  QuedaMarcado: Boolean;
begin
  Campo := ADataSet.FindField('ESWEB_ART');
  if Assigned(Campo) then
  begin
    QuedaMarcado := SameText(Trim(Campo.AsString), 'S');
    Cambio := False;
    if ADataSet.State = dsInsert then
      Cambio := QuedaMarcado
    else if ADataSet.State = dsEdit then
    begin
      EstabaMarcado := SameText(
        Trim(VarToStr(Campo.OldValue)),
        'S');
      Cambio := EstabaMarcado <> QuedaMarcado;
    end;
    if Cambio and
       (not FPermitirCambiarMarcaWeb) then
      raise EDatabaseError.Create(
        SErrorPermisoCambiarMarcaWebArticulo);
  end;
end;

function TdmArticulos.PrepararClaveTarifa: Integer;
begin
  if unqryTarifasArticulos.State = dsInsert then
  begin
    unqryTarifasArticulos.FieldByName(
      'CODIGO_UNICO_ARTTAR').Required := False;
    unqryTarifasArticulos.FieldByName(
      'CODIGO_UNICO_ARTTAR').AutoGenerateValue := arAutoInc;
    Result := -1;
  end
  else
    Result := unqryTarifasArticulos.FieldByName(
      'CODIGO_UNICO_ARTTAR').AsInteger;
end;

procedure TdmArticulos.AplicarEstadoTarifaPorPrecio;
var
  PrecioAnterior: Double;
  PrecioNuevo: Double;
  EstaActiva: string;
  ValorAnterior: Variant;
begin
  PrecioNuevo := unqryTarifasArticulos.FieldByName(
    'PRECIO_SALIDA_ARTTAR').AsFloat;
  EstaActiva := unqryTarifasArticulos.FieldByName(
    'ESACTIVO_ARTTAR').AsString;
  if unqryTarifasArticulos.State = dsInsert then
  begin
    if PrecioNuevo = 0 then
      unqryTarifasArticulos.FieldByName(
        'ESACTIVO_ARTTAR').AsString := 'N';
  end
  else if unqryTarifasArticulos.State = dsEdit then
  begin
    ValorAnterior := unqryTarifasArticulos.FieldByName(
      'PRECIO_SALIDA_ARTTAR').OldValue;
    if VarIsNull(ValorAnterior) or VarIsEmpty(ValorAnterior) then
      PrecioAnterior := 0
    else
      PrecioAnterior := ValorAnterior;
    if (PrecioAnterior > 0) and (PrecioNuevo = 0) and
       (EstaActiva = 'S') and
       SolicitarConfirmacion(SPreguntaDesactivarTarifaSinPrecio) then
      unqryTarifasArticulos.FieldByName(
        'ESACTIVO_ARTTAR').AsString := 'N';
    if (PrecioAnterior = 0) and (PrecioNuevo > 0) and
       (EstaActiva = 'N') and
       SolicitarConfirmacion(SPreguntaActivarTarifaConPrecio) then
      unqryTarifasArticulos.FieldByName(
        'ESACTIVO_ARTTAR').AsString := 'S';
  end;
end;

procedure TdmArticulos.ValidarPeriodoTarifa(APk: Integer);
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := ConexionPrincipal;
    Consulta.SQL.Text :=
      'SELECT * ' +
      '  FROM fza_articulos_tarifas ' +
      ' WHERE CODIGO_ART_ARTTAR = :CODIGO_ART_ART' +
      '   AND CODIGO_TAR_ARTTAR = :CODIGO_TAR_ARTTAR' +
      '   AND COALESCE(CODIGO_UNIDAD_ARTTAR, '''') = :CODIGO_UNIDAD' +
      '   AND CODIGO_UNICO_ARTTAR <> :PK';
    Consulta.ParamByName('CODIGO_ART_ART').AsString :=
      unqryTablaG.FieldByName('CODIGO_ART_ART').AsString;
    Consulta.ParamByName('CODIGO_TAR_ARTTAR').AsString :=
      unqryTarifasArticulos.FieldByName('CODIGO_TAR_ARTTAR').AsString;
    Consulta.ParamByName('CODIGO_UNIDAD').AsString :=
      unqryTarifasArticulos.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString;
    Consulta.ParamByName('PK').AsInteger := APk;
    Consulta.Open;
    if not ExistePeriodoUnico(
      Consulta,
      unqryTarifasArticulos.FieldByName('FECHA_DESDE_ARTTAR'),
      unqryTarifasArticulos.FieldByName('FECHA_HASTA_ARTTAR')) then
    begin
      NotificarError(Format(
        SErrorTarifaFechasConcurrentes,
        [unqryTarifasArticulos.FieldByName(
          'CODIGO_UNIDAD_ARTTAR').AsString]));
      Abort;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TdmArticulos.SanearDescuentoTarifa;
begin
  if (unqryTarifasArticulos.FieldByName(
        'PRECIO_FINAL_ARTTAR').AsFloat >
      unqryTarifasArticulos.FieldByName(
        'PRECIO_SALIDA_ARTTAR').AsFloat) or
     (unqryTarifasArticulos.FieldByName(
        'PRECIO_DTO_ARTTAR').AsFloat < 0) or
     (unqryTarifasArticulos.FieldByName(
        'PORCENTAJE_DTO_ARTTAR').AsFloat < 0) then
  begin
    unqryTarifasArticulos.FieldByName('PRECIO_FINAL_ARTTAR').AsFloat :=
      unqryTarifasArticulos.FieldByName('PRECIO_SALIDA_ARTTAR').AsFloat;
    unqryTarifasArticulos.FieldByName('PRECIO_DTO_ARTTAR').AsFloat := 0;
    unqryTarifasArticulos.FieldByName(
      'PORCENTAJE_DTO_ARTTAR').AsFloat := 0;
  end;
end;

procedure TdmArticulos.unqryTarifasArticulosBeforePost(DataSet: TDataSet);
var
  Clave: Integer;
begin
  inherited;
  Clave := PrepararClaveTarifa;
  AplicarEstadoTarifaPorPrecio;
  ValidarPeriodoTarifa(Clave);
  SanearDescuentoTarifa;
  if unqryTarifasArticulos.State in [dsInsert, dsEdit] then
    ActualizarAuditoria(DataSet);
end;

procedure TdmArticulos.unqryTarifasArticulosAfterPost(DataSet: TDataSet);
begin
  EncolarPrecioPrestaShop(
    unqryTarifasArticulos.Connection,
    DataSet.FieldByName('CODIGO_ART_ARTTAR').AsString,
    IdentidadSesion.Usuario);
end;

procedure TdmArticulos.unqryTarifasArticulosBeforeDelete(
  DataSet: TDataSet);
begin
  FCodigoArticuloTarifaBorrada := Trim(
    DataSet.FieldByName('CODIGO_ART_ARTTAR').AsString);
end;

procedure TdmArticulos.unqryTarifasArticulosAfterDelete(
  DataSet: TDataSet);
begin
  EncolarPrecioPrestaShop(
    unqryTarifasArticulos.Connection,
    FCodigoArticuloTarifaBorrada,
    IdentidadSesion.Usuario);
  FCodigoArticuloTarifaBorrada := '';
end;

function TdmArticulos.ReconstruirStock: string;
var
  unqrySol: TUniQuery;
begin
  Result := '';
  unqrySol := TUniQuery.Create(nil);
  try
    unqrySol.Connection := ConexionPrincipal;
    unqrySol.SQL.Text := 'CALL PRC_RECALCULAR_STOCK()';
    unqrySol.Open;
    if not unqrySol.IsEmpty then
      Result := unqrySol.FieldByName('MENSAJE').AsString;
    unqrySol.Close;
    if (not ConexionPrincipal.InTransaction) and
       (not StartsText('ERROR', Result)) then
      SolicitarProcesadoPrestaShop;
  finally
    FreeAndNil(unqrySol);
  end;
end;

function TdmArticulos.ObtenerPrecioTarifaPadre(
  const aCodArt, aCodTarifa: string): Double;
var
  qry: TUniQuery;
begin
  Result := 0;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := ConexionPrincipal;
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
                ParametrosCaja.TarifaDefecto) then
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
        if Trim(lstCod[i]) <> '' then
        begin
          if sFiltroAlm <> '' then
            sFiltroAlm := sFiltroAlm + ',';
          sFiltroAlm := sFiltroAlm + QuotedStr(Trim(lstCod[i]));
        end;
      end;
    finally
      FreeAndNil(lstCod);
    end;
    if sFiltroAlm <> '' then
      sFiltroAlm := 'WHERE CODIGO_ALM_STK IN (' + sFiltroAlm + ')';
  end;

  sSql := StringReplace(cSqlEtiquetasArt,
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
  if cdsEtiquetasArt.Active and (not cdsEtiquetasArt.IsEmpty) and
     (cdsEtiquetasArt.FindField(aFldStock) <> nil) then
  begin
    iStockIdx := cdsEtiquetasArt.FieldByName(aFldStock).Index;
    cdsEtiquetasArt.DisableControls;
    cdsEtiquetasArt.DisableConstraints;
    // Los campos del proveedor se hacen escribibles para reconstruirlos.
    for j := 0 to cdsEtiquetasArt.FieldCount - 1 do
    begin
      cdsEtiquetasArt.Fields[j].ReadOnly := False;
      cdsEtiquetasArt.Fields[j].Required := False;
    end;
    try
      // Se vuelcan los originales y se replica cada fila por su stock.
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
        if not VarIsNull(Filas[i][iStockIdx]) then
        begin
          iStock := Trunc(Double(Filas[i][iStockIdx]));
          if iStock > 0 then
          begin
            for k := 1 to iStock do
            begin
              cdsEtiquetasArt.Append;
              for j := 0 to cdsEtiquetasArt.FieldCount - 1 do
                cdsEtiquetasArt.Fields[j].Value := Filas[i][j];
              cdsEtiquetasArt.Post;
            end;
          end;
        end;
      end;
    finally
      cdsEtiquetasArt.EnableControls;
    end;
  end;
end;

procedure TdmArticulos.PoblarCdsEtiquetasArtDesdeUniQuery;
var
  oHexMap: TDictionary<string, string>;
  fldDef: TFieldDef;
  fdOrig: TFieldDef;
  sDiag: string;
  iCodSkuIdxOrig: Integer;
  k: Integer;
begin
  oHexMap := CargarMapaHexEtiquetas(
    unqryArtPrint.Connection,
    RegistroLog);
  try
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
        fldDef.DataType   := TipoSeguroCdsEtiquetas(fdOrig.DataType);
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
        if RegistroLog <> nil then
          RegistroLog.RegistrarError(
            'PoblarCdsEtiquetasArt: CreateDataSet fallo (' +
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

    CopiarFilasEtiquetas(
      unqryArtPrint,
      cdsEtiquetasArt,
      iCodSkuIdxOrig,
      oHexMap);
  finally
    FreeAndNil(oHexMap);
  end;
end;

initialization
  RegistrarDataModule(TdmArticulos);
  ForceReferenceToClass(TdmArticulos);
end.
