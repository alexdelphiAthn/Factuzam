{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataDocumentosTrabajo                                      }
{    Tipo:       Data Module                                                   }
{ Versión:       1.1.0                                                         }
{   Fecha:       23/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de Documentos de Trabajo.                                     }
{******************************************************************************}
unit UniDataDocumentosTrabajo;

interface

uses
  System.SysUtils, System.Classes, Vcl.ComCtrls, cxListView,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen;

type
  TDocTrabajoAmbito = (dtaPropios, dtaCompartidos);

  TdmDocumentosTrabajo = class(TdmBase)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryLineasAfterInsert(DataSet: TDataSet);
    procedure unqryLineasBeforeDelete(DataSet: TDataSet);
    procedure unqryLineasBeforePost(DataSet: TDataSet);
    procedure unqryCompartidosAfterInsert(DataSet: TDataSet);
    procedure unqryCompartidosBeforeDelete(DataSet: TDataSet);
    procedure unqryCompartidosBeforePost(DataSet: TDataSet);
  private
    FAmbito: TDocTrabajoAmbito;
    procedure ConfigurarQueries;
    procedure ConfigurarSqlCabecera;
    procedure ConfigurarQueryCompartidos;
    function SqlSelectLineas: string;
    procedure ExpandirEtiquetasPorCantidadDoc(ADmArt: TObject;
                                              AIdDtr: Int64;
                                              const AAlmacenesCsv: string);
    function ObtenerAlmacenesSql(const AAlmacenesCsv: string): string;
    function ObtenerSkusDocumentoCsv(AIdDtr: Int64;
                                     const AAlmacenesCsv: string): string;
    function ExisteDestinoCompartir(const ADestino, ATipo: string): Boolean;
    function NormalizarTipoDestino(const ADestino, ATipo: string): string;
    function SiguienteLinea: string;
    function PuedeEditarDocumentoActual: Boolean;
  public
    unqryLineas: TUniQuery;
    unqryCompartidos: TUniQuery;
    dsLineas: TDataSource;
    dsCompartidos: TDataSource;
    property Ambito: TDocTrabajoAmbito read FAmbito;
    procedure AbrirDetalles; override;
    procedure CambiarAmbito(const AAmbito: TDocTrabajoAmbito);
    procedure CargarAlmacenesEtiquetasDoc(AIdDtr: Int64; ALV: TcxListView);
    function CompartirDocumentoActual(const ADestino, ATipo: string): Boolean;
    procedure CrearDataSetEtiquetasDoc(ADmArt: TObject; AIdDtr: Int64;
                                       const ACodTarifa,
                                             AAlmacenesCsv: string;
                                       AFecha: TDateTime);
    // Contrato ColumnSKUcxGrid: rellena ATTR1..5_VALOR_DTL y
    // NUM_ATRIBUTOS_DTL troceando el SKU de cada linea que aun los
    // tenga vacios (idempotente por linea; columnas reales, el Post
    // actualiza BD).
    procedure DesempaquetarAtributosLineas;
  end;

var
  dmDocumentosTrabajo: TdmDocumentosTrabajo;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
  System.Generics.Collections, System.Variants,
  UniDataArticulos, inMtoDocumentosTrabajo;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TdmDocumentosTrabajo.DataModuleCreate(Sender: TObject);
begin
  inherited;
  FAmbito := dtaPropios;
  unqryLineas := TUniQuery.Create(Self);
  unqryCompartidos := TUniQuery.Create(Self);
  dsLineas := TDataSource.Create(Self);
  dsCompartidos := TDataSource.Create(Self);
  dsLineas.DataSet := unqryLineas;
  dsCompartidos.DataSet := unqryCompartidos;
  ConfigurarQueries;
end;

procedure TdmDocumentosTrabajo.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(unqryLineas) then
  begin
    unqryLineas.Close;
  end;
  if Assigned(unqryCompartidos) then
  begin
    unqryCompartidos.Close;
  end;
  inherited;
end;

procedure TdmDocumentosTrabajo.ConfigurarSqlCabecera;
begin
  if FAmbito = dtaCompartidos then
  begin
    unqryTablaG.SQL.Text :=
      'SELECT DISTINCT d.* ' +
      '  FROM fza_documentos_trabajo d ' +
      '  JOIN fza_documentos_trabajo_compartidos c ' +
      '    ON c.ID_DTR_DTC = d.ID_DTR ' +
      ' WHERE ((COALESCE(c.TIPO_DESTINO_DTC, ''USUARIO'') = ''USUARIO'' ' +
      '         AND COALESCE(NULLIF(c.USUARIO_GRUPO_DTC, ''''), ' +
      '                      c.USUARIO_DTC) = :USUARIO) ' +
      '    OR (COALESCE(c.TIPO_DESTINO_DTC, ''USUARIO'') = ''GRUPO'' ' +
      '        AND COALESCE(NULLIF(c.USUARIO_GRUPO_DTC, ''''), ' +
      '                     c.USUARIO_DTC) = :GRUPO)) ' +
      ' ORDER BY d.INSTANTE_DOCUMENTO_DTR DESC, d.ID_DTR DESC';
  end
  else
  begin
    unqryTablaG.SQL.Text :=
      'SELECT * ' +
      '  FROM fza_documentos_trabajo ' +
      ' WHERE USUARIO_DTR = :USUARIO ' +
      ' ORDER BY INSTANTE_DOCUMENTO_DTR DESC, ID_DTR DESC';
  end;
  unqryTablaG.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
  if FAmbito = dtaCompartidos then
  begin
    unqryTablaG.ParamByName('GRUPO').AsString := IdentidadSesion.Grupo;
  end;
end;

function TdmDocumentosTrabajo.SqlSelectLineas: string;
begin
  Result :=
    'SELECT l.*, ' +
    '       COALESCE(a.CODIGO_FAM_ART, '''') AS CODIGO_FAM_ART, ' +
    '       COALESCE(f.DESCRIPCION_FAM, '''') AS DESCRIPCION_FAM, ' +
    '       COALESCE(ap.CODIGO_PRV_AP, '''') AS CODIGO_PRV_AP, ' +
    '       COALESCE(NULLIF(p.NOMBRE_PRV, ''''), ' +
    '                p.RAZON_SOCIAL_PRV, '''') AS NOMBRE_PRV, ' +
    '       COALESCE(ap.REF_PROVEEDOR_AP, '''') AS REF_PROVEEDOR, ' +
    '       COALESCE((SELECT COALESCE(pe.VALOR_PV, ' +
    '                                pe.VALOR_LIBRE_ARTPROP) ' +
    '                   FROM vi_articulos_propiedades_efectivas pe ' +
    '                  WHERE pe.CODIGO_ART = l.CODIGO_ART_DTL ' +
    '                    AND pe.CODIGO_UNIDAD_SKU = ' +
    '                        l.CODIGO_UNIDAD_DTL ' +
    '                    AND pe.CODIGO_PROP_ARTPROP = ''TEMPORADA'' ' +
    '                  LIMIT 1), '''') AS TEMPORADA_ART, ' +
    '       COALESCE(tar.CODIGO_TAR_ARTTAR, '''') ' +
    '         AS CODIGO_TAR_ARTTAR, ' +
    '       COALESCE(tar.NOMBRE_TAR_TAR, '''') AS NOMBRE_TAR_TAR, ' +
    '       COALESCE((SELECT at.PRECIO_FINAL_ARTTAR ' +
    '                   FROM fza_articulos_tarifas at ' +
    '                  WHERE at.CODIGO_ART_ARTTAR = ' +
    '                        l.CODIGO_ART_DTL ' +
    '                    AND at.CODIGO_TAR_ARTTAR = ' +
    '                        tar.CODIGO_TAR_ARTTAR ' +
    '                    AND at.ESACTIVO_ARTTAR = ''S'' ' +
    '                    AND (at.CODIGO_UNIDAD_ARTTAR = ' +
    '                         l.CODIGO_UNIDAD_DTL ' +
    '                         OR at.CODIGO_UNIDAD_ARTTAR IS NULL ' +
    '                         OR at.CODIGO_UNIDAD_ARTTAR = '''') ' +
    '                    AND (at.FECHA_DESDE_ARTTAR IS NULL ' +
    '                         OR at.FECHA_DESDE_ARTTAR <= CURRENT_DATE) ' +
    '                    AND (at.FECHA_HASTA_ARTTAR IS NULL ' +
    '                         OR at.FECHA_HASTA_ARTTAR >= CURRENT_DATE) ' +
    '                  ORDER BY CASE ' +
    '                    WHEN at.CODIGO_UNIDAD_ARTTAR = ' +
    '                         l.CODIGO_UNIDAD_DTL ' +
    '                     AND l.CODIGO_UNIDAD_DTL <> '''' ' +
    '                    THEN 0 ELSE 1 END, ' +
    '                    at.FECHA_DESDE_ARTTAR DESC, ' +
    '                    at.CODIGO_UNICO_ARTTAR DESC ' +
    '                  LIMIT 1), 0) AS PRECIO_FINAL_ARTTAR ' +
    '  FROM fza_documentos_trabajo_lineas l ' +
    '  LEFT JOIN fza_articulos a ' +
    '    ON a.CODIGO_ART_ART = l.CODIGO_ART_DTL ' +
    '  LEFT JOIN fza_articulos_familias f ' +
    '    ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART ' +
    '  LEFT JOIN fza_articulos_proveedores ap ' +
    '    ON ap.CODIGO_ART_AP = l.CODIGO_ART_DTL ' +
    '   AND ap.CODIGO_PRV_AP = ' +
    '       (SELECT apx.CODIGO_PRV_AP ' +
    '          FROM fza_articulos_proveedores apx ' +
    '         WHERE apx.CODIGO_ART_AP = l.CODIGO_ART_DTL ' +
    '         ORDER BY CASE ' +
    '                    WHEN apx.ESPROVEEDORPRINCIPAL_AP = ''S'' ' +
    '                    THEN 0 ELSE 1 ' +
    '                  END, ' +
    '                  apx.FECHA_VALIDEZ_AP DESC, ' +
    '                  apx.CODIGO_PRV_AP ' +
    '         LIMIT 1) ' +
    '  LEFT JOIN fza_proveedores p ' +
    '    ON p.CODIGO_PRV_PRV = ap.CODIGO_PRV_AP ' +
    '  LEFT JOIN fza_tarifas tar ' +
    '    ON tar.CODIGO_TAR_ARTTAR = ' +
    '       (SELECT t.CODIGO_TAR_ARTTAR ' +
    '          FROM fza_tarifas t ' +
    '         WHERE t.ESACTIVO_ARTTAR = ''S'' ' +
    '         ORDER BY (t.ORDEN_TAR IS NULL), t.ORDEN_TAR, ' +
    '                  t.CODIGO_TAR_ARTTAR ' +
    '         LIMIT 1) ';
end;

procedure TdmDocumentosTrabajo.ConfigurarQueries;
var
  frm: TfrmMtoDocumentosTrabajo;
begin
  ConfigurarSqlCabecera;
  unqryTablaG.KeyFields := 'ID_DTR';
  unqryTablaG.SQLInsert.Text :=
    'INSERT INTO fza_documentos_trabajo ' +
    '  (TITULO_DTR, TIPO_DTR, ESTADO_DTR, CODIGO_EMP_DTR, CODIGO_ALM_DTR, ' +
    '   USUARIO_DTR, INSTANTE_DOCUMENTO_DTR, OBSERVACIONES_DTR, ' +
    '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES ' +
    '  (:TITULO_DTR, :TIPO_DTR, :ESTADO_DTR, :CODIGO_EMP_DTR, ' +
    '   :CODIGO_ALM_DTR, :USUARIO_DTR, :INSTANTE_DOCUMENTO_DTR, ' +
    '   :OBSERVACIONES_DTR, :INSTANTE_ALTA, :USUARIO_ALTA, ' +
    '   :USUARIO_MODIF)';
  unqryTablaG.SQLUpdate.Text :=
    'UPDATE fza_documentos_trabajo SET ' +
    '  TITULO_DTR = :TITULO_DTR, ' +
    '  TIPO_DTR = :TIPO_DTR, ' +
    '  ESTADO_DTR = :ESTADO_DTR, ' +
    '  CODIGO_EMP_DTR = :CODIGO_EMP_DTR, ' +
    '  CODIGO_ALM_DTR = :CODIGO_ALM_DTR, ' +
    '  USUARIO_DTR = :USUARIO_DTR, ' +
    '  INSTANTE_DOCUMENTO_DTR = :INSTANTE_DOCUMENTO_DTR, ' +
    '  OBSERVACIONES_DTR = :OBSERVACIONES_DTR, ' +
    '  USUARIO_MODIF = :USUARIO_MODIF ' +
    'WHERE ID_DTR = :Old_ID_DTR';
  unqryTablaG.SQLDelete.Text :=
    'DELETE FROM fza_documentos_trabajo WHERE ID_DTR = :Old_ID_DTR';
  unqryTablaG.SQLRefresh.Text :=
    'SELECT * FROM fza_documentos_trabajo WHERE ID_DTR = :ID_DTR';
  unqryTablaG.SQLLock.Text :=
    'SELECT * FROM fza_documentos_trabajo ' +
    ' WHERE ID_DTR = :Old_ID_DTR FOR UPDATE';
  unqryTablaG.AfterInsert := unqryTablaGAfterInsert;
  unqryTablaG.BeforeDelete := unqryTablaGBeforeDelete;
  unqryTablaG.BeforePost := unqryTablaGBeforePost;
  unqryLineas.Connection := ConexionPrincipal;
  unqryLineas.SQL.Text := SqlSelectLineas +
    ' WHERE l.ID_DTR_DTL = :ID_DTR ' +
    ' ORDER BY l.LINEA_DTL';
  unqryLineas.KeyFields := 'ID_DTL';
  unqryLineas.MasterFields := 'ID_DTR';
  unqryLineas.DetailFields := 'ID_DTR_DTL';
  frm := GetOwnerForm<TfrmMtoDocumentosTrabajo>;
  if frm <> nil then
  begin
    unqryLineas.MasterSource := frm.dsTablaG;
  end;
  // ATTR1..5 / NUM_ATRIBUTOS / ID_AC_PIVOT: columnas del contrato
  // ColumnSKUcxGrid (documentos_trabajo_columnas_sku.sql).
  unqryLineas.SQLInsert.Text :=
    'INSERT INTO fza_documentos_trabajo_lineas ' +
    '  (ID_DTR_DTL, LINEA_DTL, CODIGO_ART_DTL, CODIGO_UNIDAD_DTL, ' +
    '   CODIGO_ALM_DTL, LOTE_DTL, FECHA_CADUCIDAD_DTL, ' +
    '   DESCRIPCION_ARTICULO_DTL, DESCRIPCION_UNIDAD_DTL, ' +
    '   CANTIDAD_STOCK_DTL, CANTIDAD_DTL, INSTANTE_STOCK_DTL, ' +
    '   ORIGEN_DTL, OBSERVACIONES_DTL, ' +
    '   ATTR1_VALOR_DTL, ATTR1_NOMBRE_DTL, ' +
    '   ATTR2_VALOR_DTL, ATTR2_NOMBRE_DTL, ' +
    '   ATTR3_VALOR_DTL, ATTR3_NOMBRE_DTL, ' +
    '   ATTR4_VALOR_DTL, ATTR4_NOMBRE_DTL, ' +
    '   ATTR5_VALOR_DTL, ATTR5_NOMBRE_DTL, ' +
    '   NUM_ATRIBUTOS_DTL, ID_AC_PIVOT_DTL, ' +
    '   INSTANTE_ALTA, USUARIO_ALTA, ' +
    '   USUARIO_MODIF) ' +
    'VALUES ' +
    '  (:ID_DTR_DTL, :LINEA_DTL, :CODIGO_ART_DTL, :CODIGO_UNIDAD_DTL, ' +
    '   :CODIGO_ALM_DTL, :LOTE_DTL, :FECHA_CADUCIDAD_DTL, ' +
    '   :DESCRIPCION_ARTICULO_DTL, :DESCRIPCION_UNIDAD_DTL, ' +
    '   :CANTIDAD_STOCK_DTL, :CANTIDAD_DTL, :INSTANTE_STOCK_DTL, ' +
    '   :ORIGEN_DTL, :OBSERVACIONES_DTL, ' +
    '   :ATTR1_VALOR_DTL, :ATTR1_NOMBRE_DTL, ' +
    '   :ATTR2_VALOR_DTL, :ATTR2_NOMBRE_DTL, ' +
    '   :ATTR3_VALOR_DTL, :ATTR3_NOMBRE_DTL, ' +
    '   :ATTR4_VALOR_DTL, :ATTR4_NOMBRE_DTL, ' +
    '   :ATTR5_VALOR_DTL, :ATTR5_NOMBRE_DTL, ' +
    '   :NUM_ATRIBUTOS_DTL, :ID_AC_PIVOT_DTL, ' +
    '   :INSTANTE_ALTA, ' +
    '   :USUARIO_ALTA, :USUARIO_MODIF)';
  unqryLineas.SQLUpdate.Text :=
    'UPDATE fza_documentos_trabajo_lineas SET ' +
    '  ID_DTR_DTL = :ID_DTR_DTL, ' +
    '  LINEA_DTL = :LINEA_DTL, ' +
    '  CODIGO_ART_DTL = :CODIGO_ART_DTL, ' +
    '  CODIGO_UNIDAD_DTL = :CODIGO_UNIDAD_DTL, ' +
    '  CODIGO_ALM_DTL = :CODIGO_ALM_DTL, ' +
    '  LOTE_DTL = :LOTE_DTL, ' +
    '  FECHA_CADUCIDAD_DTL = :FECHA_CADUCIDAD_DTL, ' +
    '  DESCRIPCION_ARTICULO_DTL = :DESCRIPCION_ARTICULO_DTL, ' +
    '  DESCRIPCION_UNIDAD_DTL = :DESCRIPCION_UNIDAD_DTL, ' +
    '  CANTIDAD_STOCK_DTL = :CANTIDAD_STOCK_DTL, ' +
    '  CANTIDAD_DTL = :CANTIDAD_DTL, ' +
    '  INSTANTE_STOCK_DTL = :INSTANTE_STOCK_DTL, ' +
    '  ORIGEN_DTL = :ORIGEN_DTL, ' +
    '  OBSERVACIONES_DTL = :OBSERVACIONES_DTL, ' +
    '  ATTR1_VALOR_DTL = :ATTR1_VALOR_DTL, ' +
    '  ATTR1_NOMBRE_DTL = :ATTR1_NOMBRE_DTL, ' +
    '  ATTR2_VALOR_DTL = :ATTR2_VALOR_DTL, ' +
    '  ATTR2_NOMBRE_DTL = :ATTR2_NOMBRE_DTL, ' +
    '  ATTR3_VALOR_DTL = :ATTR3_VALOR_DTL, ' +
    '  ATTR3_NOMBRE_DTL = :ATTR3_NOMBRE_DTL, ' +
    '  ATTR4_VALOR_DTL = :ATTR4_VALOR_DTL, ' +
    '  ATTR4_NOMBRE_DTL = :ATTR4_NOMBRE_DTL, ' +
    '  ATTR5_VALOR_DTL = :ATTR5_VALOR_DTL, ' +
    '  ATTR5_NOMBRE_DTL = :ATTR5_NOMBRE_DTL, ' +
    '  NUM_ATRIBUTOS_DTL = :NUM_ATRIBUTOS_DTL, ' +
    '  ID_AC_PIVOT_DTL = :ID_AC_PIVOT_DTL, ' +
    '  USUARIO_MODIF = :USUARIO_MODIF ' +
    'WHERE ID_DTL = :Old_ID_DTL';
  unqryLineas.SQLDelete.Text :=
    'DELETE FROM fza_documentos_trabajo_lineas WHERE ID_DTL = :Old_ID_DTL';
  unqryLineas.SQLRefresh.Text := SqlSelectLineas +
    ' WHERE l.ID_DTL = :ID_DTL';
  unqryLineas.SQLLock.Text :=
    'SELECT * FROM fza_documentos_trabajo_lineas ' +
    ' WHERE ID_DTL = :Old_ID_DTL FOR UPDATE';
  unqryLineas.AfterInsert := unqryLineasAfterInsert;
  unqryLineas.BeforeDelete := unqryLineasBeforeDelete;
  unqryLineas.BeforePost := unqryLineasBeforePost;
  ConfigurarQueryCompartidos;
end;

procedure TdmDocumentosTrabajo.ConfigurarQueryCompartidos;
var
  frm: TfrmMtoDocumentosTrabajo;
begin
  unqryCompartidos.Connection := ConexionPrincipal;
  unqryCompartidos.SQL.Text :=
    'SELECT * ' +
    '  FROM fza_documentos_trabajo_compartidos ' +
    ' WHERE ID_DTR_DTC = :ID_DTR ' +
    ' ORDER BY TIPO_DESTINO_DTC, USUARIO_GRUPO_DTC';
  unqryCompartidos.KeyFields := 'ID_DTC';
  unqryCompartidos.MasterFields := 'ID_DTR';
  unqryCompartidos.DetailFields := 'ID_DTR_DTC';
  frm := GetOwnerForm<TfrmMtoDocumentosTrabajo>;
  if frm <> nil then
  begin
    unqryCompartidos.MasterSource := frm.dsTablaG;
  end;
  unqryCompartidos.SQLInsert.Text :=
    'INSERT INTO fza_documentos_trabajo_compartidos ' +
    '  (ID_DTR_DTC, USUARIO_DTC, USUARIO_GRUPO_DTC, TIPO_DESTINO_DTC, ' +
    '   PERMISO_DTC, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES ' +
    '  (:ID_DTR_DTC, :USUARIO_DTC, :USUARIO_GRUPO_DTC, ' +
    '   :TIPO_DESTINO_DTC, :PERMISO_DTC, :INSTANTE_ALTA, ' +
    '   :USUARIO_ALTA, :USUARIO_MODIF)';
  unqryCompartidos.SQLUpdate.Text :=
    'UPDATE fza_documentos_trabajo_compartidos SET ' +
    '  ID_DTR_DTC = :ID_DTR_DTC, ' +
    '  USUARIO_DTC = :USUARIO_DTC, ' +
    '  USUARIO_GRUPO_DTC = :USUARIO_GRUPO_DTC, ' +
    '  TIPO_DESTINO_DTC = :TIPO_DESTINO_DTC, ' +
    '  PERMISO_DTC = :PERMISO_DTC, ' +
    '  USUARIO_MODIF = :USUARIO_MODIF ' +
    'WHERE ID_DTC = :Old_ID_DTC';
  unqryCompartidos.SQLDelete.Text :=
    'DELETE FROM fza_documentos_trabajo_compartidos ' +
    ' WHERE ID_DTC = :Old_ID_DTC';
  unqryCompartidos.SQLRefresh.Text :=
    'SELECT * FROM fza_documentos_trabajo_compartidos WHERE ID_DTC = :ID_DTC';
  unqryCompartidos.SQLLock.Text :=
    'SELECT * FROM fza_documentos_trabajo_compartidos ' +
    ' WHERE ID_DTC = :Old_ID_DTC FOR UPDATE';
  unqryCompartidos.AfterInsert := unqryCompartidosAfterInsert;
  unqryCompartidos.BeforeDelete := unqryCompartidosBeforeDelete;
  unqryCompartidos.BeforePost := unqryCompartidosBeforePost;
end;

function TdmDocumentosTrabajo.ObtenerAlmacenesSql(
  const AAlmacenesCsv: string): string;
var
  i: Integer;
  lst: TStringList;
  sCodigo: string;
begin
  Result := '';
  if Trim(AAlmacenesCsv) <> '' then
  begin
    lst := TStringList.Create;
    try
      lst.StrictDelimiter := True;
      lst.Delimiter := ',';
      lst.DelimitedText := AAlmacenesCsv;
      for i := 0 to lst.Count - 1 do
      begin
        sCodigo := Trim(lst[i]);
        if sCodigo <> '' then
        begin
          if Result <> '' then
          begin
            Result := Result + ',';
          end;
          Result := Result + QuotedStr(sCodigo);
        end;
      end;
    finally
      FreeAndNil(lst);
    end;
  end;
end;

function TdmDocumentosTrabajo.ObtenerSkusDocumentoCsv(AIdDtr: Int64;
  const AAlmacenesCsv: string): string;
var
  q: TUniQuery;
  sAlmacenes: string;
begin
  Result := '';
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionPrincipal;
    sAlmacenes := ObtenerAlmacenesSql(AAlmacenesCsv);
    q.SQL.Text :=
      'SELECT DISTINCT CODIGO_UNIDAD_DTL ' +
      '  FROM fza_documentos_trabajo_lineas ' +
      ' WHERE ID_DTR_DTL = :ID_DTR ' +
      '   AND COALESCE(CODIGO_UNIDAD_DTL, '''') <> ''''';
    if sAlmacenes <> '' then
    begin
      q.SQL.Add('   AND CODIGO_ALM_DTL IN (' + sAlmacenes + ')');
    end;
    q.SQL.Add(' ORDER BY CODIGO_UNIDAD_DTL');
    q.ParamByName('ID_DTR').AsLargeInt := AIdDtr;
    q.Open;
    while not q.Eof do
    begin
      if Result <> '' then
      begin
        Result := Result + ',';
      end;
      Result := Result + QuotedStr(
        q.FieldByName('CODIGO_UNIDAD_DTL').AsString);
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

procedure TdmDocumentosTrabajo.CargarAlmacenesEtiquetasDoc(AIdDtr: Int64;
  ALV: TcxListView);
var
  q: TUniQuery;
  oItem: TListItem;
begin
  if ALV <> nil then
  begin
    ALV.Items.BeginUpdate;
    try
      ALV.Clear;
      q := TUniQuery.Create(nil);
      try
        q.Connection := ConexionPrincipal;
        q.SQL.Text :=
          'SELECT DISTINCT L.CODIGO_ALM_DTL AS COD, ' +
          '       COALESCE(A.NOMBRE_ALM_ALM, L.CODIGO_ALM_DTL) AS NOM ' +
          '  FROM fza_documentos_trabajo_lineas L ' +
          '  LEFT JOIN fza_almacenes A ' +
          '    ON A.CODIGO_ALM_ALM = L.CODIGO_ALM_DTL ' +
          ' WHERE L.ID_DTR_DTL = :ID_DTR ' +
          '   AND COALESCE(L.CODIGO_ALM_DTL, '''') <> '''' ' +
          ' ORDER BY COD';
        q.ParamByName('ID_DTR').AsLargeInt := AIdDtr;
        q.Open;
        while not q.Eof do
        begin
          oItem := ALV.Items.Add;
          oItem.Caption := q.FieldByName('COD').AsString;
          oItem.SubItems.Add(q.FieldByName('NOM').AsString);
          oItem.Checked := True;
          q.Next;
        end;
      finally
        FreeAndNil(q);
      end;
    finally
      ALV.Items.EndUpdate;
    end;
  end;
end;

procedure TdmDocumentosTrabajo.ExpandirEtiquetasPorCantidadDoc(ADmArt: TObject;
  AIdDtr: Int64; const AAlmacenesCsv: string);
var
  q: TUniQuery;
  oDmArt: TdmArticulos;
  oCantidades: TDictionary<string, Integer>;
  Filas: array of array of Variant;
  i, j, k, iOriginales, iSkuIdx, iStockIdx, iCantidad: Integer;
  sAlmacenes, sSku: string;
begin
  if ADmArt is TdmArticulos then
  begin
    oDmArt := TdmArticulos(ADmArt);
    oCantidades := TDictionary<string, Integer>.Create;
    try
      q := TUniQuery.Create(nil);
      try
        q.Connection := ConexionPrincipal;
        sAlmacenes := ObtenerAlmacenesSql(AAlmacenesCsv);
        q.SQL.Text :=
          'SELECT CODIGO_UNIDAD_DTL, ' +
          '       SUM(COALESCE(CANTIDAD_DTL, 0)) AS CANTIDAD ' +
          '  FROM fza_documentos_trabajo_lineas ' +
          ' WHERE ID_DTR_DTL = :ID_DTR ' +
          '   AND COALESCE(CODIGO_UNIDAD_DTL, '''') <> ''''';
        if sAlmacenes <> '' then
        begin
          q.SQL.Add('   AND CODIGO_ALM_DTL IN (' + sAlmacenes + ')');
        end;
        q.SQL.Add(' GROUP BY CODIGO_UNIDAD_DTL');
        q.ParamByName('ID_DTR').AsLargeInt := AIdDtr;
        q.Open;
        while not q.Eof do
        begin
          iCantidad := Trunc(q.FieldByName('CANTIDAD').AsFloat);
          sSku := q.FieldByName('CODIGO_UNIDAD_DTL').AsString;
          if (sSku <> '') and (iCantidad > 0) then
          begin
            oCantidades.AddOrSetValue(sSku, iCantidad);
          end;
          q.Next;
        end;
      finally
        FreeAndNil(q);
      end;

      if oDmArt.cdsEtiquetasArt.Active then
      begin
        if (not oDmArt.cdsEtiquetasArt.IsEmpty) and
           (oDmArt.cdsEtiquetasArt.FindField('CODIGO_UNIDAD_SKU') <> nil) then
        begin
          iSkuIdx := oDmArt.cdsEtiquetasArt.FieldByName(
            'CODIGO_UNIDAD_SKU').Index;
          iStockIdx := -1;
          if oDmArt.cdsEtiquetasArt.FindField('STOCK_FILTRADO') <> nil then
          begin
            iStockIdx := oDmArt.cdsEtiquetasArt.FieldByName(
              'STOCK_FILTRADO').Index;
          end;
          oDmArt.cdsEtiquetasArt.DisableControls;
          oDmArt.cdsEtiquetasArt.DisableConstraints;
          try
            for j := 0 to oDmArt.cdsEtiquetasArt.FieldCount - 1 do
            begin
              oDmArt.cdsEtiquetasArt.Fields[j].ReadOnly := False;
              oDmArt.cdsEtiquetasArt.Fields[j].Required := False;
            end;
            iOriginales := oDmArt.cdsEtiquetasArt.RecordCount;
            SetLength(Filas, iOriginales);
            oDmArt.cdsEtiquetasArt.First;
            for i := 0 to iOriginales - 1 do
            begin
              SetLength(Filas[i], oDmArt.cdsEtiquetasArt.FieldCount);
              for j := 0 to oDmArt.cdsEtiquetasArt.FieldCount - 1 do
              begin
                Filas[i][j] := oDmArt.cdsEtiquetasArt.Fields[j].Value;
              end;
              oDmArt.cdsEtiquetasArt.Next;
            end;
            oDmArt.cdsEtiquetasArt.EmptyDataSet;
            for i := 0 to iOriginales - 1 do
            begin
              sSku := VarToStr(Filas[i][iSkuIdx]);
              if oCantidades.TryGetValue(sSku, iCantidad) then
              begin
                if iCantidad > 0 then
                begin
                  for k := 1 to iCantidad do
                  begin
                    oDmArt.cdsEtiquetasArt.Append;
                    for j := 0 to oDmArt.cdsEtiquetasArt.FieldCount - 1 do
                    begin
                      oDmArt.cdsEtiquetasArt.Fields[j].Value := Filas[i][j];
                    end;
                    if iStockIdx >= 0 then
                    begin
                      oDmArt.cdsEtiquetasArt.Fields[iStockIdx].AsInteger :=
                        iCantidad;
                    end;
                    oDmArt.cdsEtiquetasArt.Post;
                  end;
                end;
              end;
            end;
          finally
            oDmArt.cdsEtiquetasArt.EnableConstraints;
            oDmArt.cdsEtiquetasArt.EnableControls;
          end;
        end
        else
        begin
          oDmArt.cdsEtiquetasArt.EmptyDataSet;
        end;
      end;
    finally
      oCantidades.Free;
    end;
  end;
end;

procedure TdmDocumentosTrabajo.CrearDataSetEtiquetasDoc(ADmArt: TObject;
  AIdDtr: Int64; const ACodTarifa, AAlmacenesCsv: string; AFecha: TDateTime);
var
  oDmArt: TdmArticulos;
  sSkus: string;
begin
  if ADmArt is TdmArticulos then
  begin
    oDmArt := TdmArticulos(ADmArt);
    sSkus := ObtenerSkusDocumentoCsv(AIdDtr, AAlmacenesCsv);
    if sSkus <> '' then
    begin
      oDmArt.CrearDataSetEtiquetasArt('', ACodTarifa, '', AFecha, sSkus);
      ExpandirEtiquetasPorCantidadDoc(oDmArt, AIdDtr, AAlmacenesCsv);
    end
    else
    begin
      oDmArt.CrearDataSetEtiquetasArt('DUMMY_SIN_LINEAS',
                                      ACodTarifa, '', AFecha);
    end;
  end;
end;

function TdmDocumentosTrabajo.ExisteDestinoCompartir(const ADestino,
  ATipo: string): Boolean;
var
  q: TUniQuery;
begin
  Result := False;
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionPrincipal;
    if SameText(ATipo, 'USUARIO') then
    begin
      q.SQL.Text :=
        'SELECT USUARIO_USU ' +
        '  FROM fza_usuarios ' +
        ' WHERE USUARIO_USU = :DESTINO';
    end
    else if SameText(ATipo, 'GRUPO') then
    begin
      q.SQL.Text :=
        'SELECT GRUPO_USUGRP ' +
        '  FROM fza_usuarios_grupos ' +
        ' WHERE GRUPO_USUGRP = :DESTINO';
    end;
    if q.SQL.Text <> '' then
    begin
      q.ParamByName('DESTINO').AsString := ADestino;
      q.Open;
      Result := not q.IsEmpty;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function TdmDocumentosTrabajo.NormalizarTipoDestino(const ADestino,
  ATipo: string): string;
var
  sTipo: string;
begin
  Result := '';
  sTipo := UpperCase(Trim(ATipo));
  if (sTipo <> '') and (sTipo <> 'USUARIO') and (sTipo <> 'GRUPO') then
  begin
    raise ERangeError.Create('El tipo de destino debe ser USUARIO o GRUPO.');
  end;
  if sTipo <> '' then
  begin
    if not ExisteDestinoCompartir(ADestino, sTipo) then
    begin
      raise ERangeError.Create('El usuario o grupo indicado no existe.');
    end;
    Result := sTipo;
  end
  else if ExisteDestinoCompartir(ADestino, 'USUARIO') then
  begin
    Result := 'USUARIO';
  end
  else if ExisteDestinoCompartir(ADestino, 'GRUPO') then
  begin
    Result := 'GRUPO';
  end
  else
  begin
    raise ERangeError.Create('El usuario o grupo indicado no existe.');
  end;
end;

function TdmDocumentosTrabajo.CompartirDocumentoActual(const ADestino,
  ATipo: string): Boolean;
var
  sDestino: string;
  sTipo: string;
begin
  Result := False;
  sDestino := Trim(ADestino);
  if sDestino = '' then
  begin
    raise ERangeError.Create('Indique el usuario o grupo con el que comparte.');
  end;
  if not PuedeEditarDocumentoActual then
  begin
    raise ERangeError.Create(
      'Solo el propietario puede compartir el Documento de Trabajo.');
  end;
  if unqryTablaG.State in dsEditModes then
  begin
    unqryTablaG.Post;
  end;
  if unqryTablaG.FieldByName('ID_DTR').IsNull then
  begin
    raise ERangeError.Create(
      'Grabe primero la cabecera del Documento de Trabajo.');
  end;
  sTipo := NormalizarTipoDestino(sDestino, ATipo);
  if SameText(sTipo, 'USUARIO') and SameText(sDestino, IdentidadSesion.Usuario) then
  begin
    raise ERangeError.Create(
      'No es necesario compartir el documento consigo mismo.');
  end;
  if not unqryCompartidos.Active then
  begin
    unqryCompartidos.Open;
  end;
  if unqryCompartidos.State in dsEditModes then
  begin
    unqryCompartidos.Post;
  end;
  if not unqryCompartidos.Locate('TIPO_DESTINO_DTC;USUARIO_GRUPO_DTC',
                                 VarArrayOf([sTipo, sDestino]),
                                 [loCaseInsensitive]) then
  begin
    unqryCompartidos.Append;
    unqryCompartidos.FieldByName('TIPO_DESTINO_DTC').AsString := sTipo;
    unqryCompartidos.FieldByName('USUARIO_GRUPO_DTC').AsString := sDestino;
    unqryCompartidos.FieldByName('USUARIO_DTC').AsString := sDestino;
    unqryCompartidos.FieldByName('PERMISO_DTC').AsString := 'LECTURA';
    unqryCompartidos.Post;
    Result := True;
  end;
end;

procedure TdmDocumentosTrabajo.AbrirDetalles;
var
  frm: TfrmMtoDocumentosTrabajo;
begin
  inherited;
  frm := GetOwnerForm<TfrmMtoDocumentosTrabajo>;
  if (frm <> nil) and (unqryLineas.MasterSource = nil) then
  begin
    unqryLineas.MasterSource := frm.dsTablaG;
  end;
  if (frm <> nil) and (unqryCompartidos.MasterSource = nil) then
  begin
    unqryCompartidos.MasterSource := frm.dsTablaG;
  end;
  if not unqryLineas.Active then
  begin
    unqryLineas.Open;
  end;
  if not unqryCompartidos.Active then
  begin
    unqryCompartidos.Open;
  end;
end;

procedure TdmDocumentosTrabajo.CambiarAmbito(const AAmbito: TDocTrabajoAmbito);
var
  bAbrir: Boolean;
begin
  if FAmbito <> AAmbito then
  begin
    FAmbito := AAmbito;
    bAbrir := unqryTablaG.Active;
    if unqryCompartidos.Active then
    begin
      unqryCompartidos.Close;
    end;
    if unqryLineas.Active then
    begin
      unqryLineas.Close;
    end;
    if unqryTablaG.Active then
    begin
      unqryTablaG.Close;
    end;
    ConfigurarSqlCabecera;
    if bAbrir then
    begin
      unqryTablaG.Open;
      AbrirDetalles;
    end;
  end;
end;

function TdmDocumentosTrabajo.PuedeEditarDocumentoActual: Boolean;
begin
  Result := False;
  if FAmbito = dtaPropios then
  begin
    if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
    begin
      Result := SameText(unqryTablaG.FieldByName('USUARIO_DTR').AsString,
                         IdentidadSesion.Usuario);
    end;
  end;
end;

procedure TdmDocumentosTrabajo.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
  if not PuedeEditarDocumentoActual then
  begin
    raise ERangeError.Create(
      'Solo el propietario puede borrar un Documento de Trabajo.');
  end;
end;

procedure TdmDocumentosTrabajo.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  DataSet.FieldByName('TITULO_DTR').AsString :=
    'Documento de trabajo ' + FormatDateTime('dd/mm/yyyy hh:nn', Now);
  DataSet.FieldByName('TIPO_DTR').AsString := 'GENERAL';
  DataSet.FieldByName('ESTADO_DTR').AsString := 'ABIERTO';
  DataSet.FieldByName('CODIGO_EMP_DTR').AsString := UbicacionSesion.Empresa;
  DataSet.FieldByName('CODIGO_ALM_DTR').AsString := UbicacionSesion.Almacen;
  DataSet.FieldByName('USUARIO_DTR').AsString := IdentidadSesion.Usuario;
  DataSet.FieldByName('INSTANTE_DOCUMENTO_DTR').AsDateTime := Now;
end;

procedure TdmDocumentosTrabajo.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  if DataSet.State = dsInsert then
  begin
    DataSet.FieldByName('USUARIO_DTR').AsString := IdentidadSesion.Usuario;
  end;
  if Trim(DataSet.FieldByName('USUARIO_DTR').AsString) = '' then
  begin
    DataSet.FieldByName('USUARIO_DTR').AsString := IdentidadSesion.Usuario;
  end;
  if not SameText(DataSet.FieldByName('USUARIO_DTR').AsString, IdentidadSesion.Usuario) then
  begin
    raise ERangeError.Create(
      'El propietario del Documento de Trabajo no se puede cambiar.');
  end;
  if Trim(DataSet.FieldByName('TITULO_DTR').AsString) = '' then
  begin
    raise ERangeError.Create('Indique el titulo del Documento de Trabajo.');
  end;
  if Trim(DataSet.FieldByName('ESTADO_DTR').AsString) = '' then
  begin
    DataSet.FieldByName('ESTADO_DTR').AsString := 'ABIERTO';
  end;
  if Trim(DataSet.FieldByName('TIPO_DTR').AsString) = '' then
  begin
    DataSet.FieldByName('TIPO_DTR').AsString := 'GENERAL';
  end;
end;

function TdmDocumentosTrabajo.SiguienteLinea: string;
var
  q: TUniQuery;
  iLinea: Integer;
begin
  iLinea := 1;
  if not unqryTablaG.FieldByName('ID_DTR').IsNull then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := unqryLineas.Connection;
      q.SQL.Text :=
        'SELECT COALESCE(MAX(CAST(LINEA_DTL AS UNSIGNED)), 0) + 1 AS LINEA ' +
        '  FROM fza_documentos_trabajo_lineas ' +
        ' WHERE ID_DTR_DTL = :ID_DTR';
      q.ParamByName('ID_DTR').AsLargeInt :=
        unqryTablaG.FieldByName('ID_DTR').AsLargeInt;
      q.Open;
      if not q.IsEmpty then
      begin
        iLinea := q.FieldByName('LINEA').AsInteger;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
  Result := Format('%.8d', [iLinea]);
end;

procedure TdmDocumentosTrabajo.unqryLineasAfterInsert(DataSet: TDataSet);
begin
  if not unqryTablaG.FieldByName('ID_DTR').IsNull then
  begin
    DataSet.FieldByName('ID_DTR_DTL').AsLargeInt :=
      unqryTablaG.FieldByName('ID_DTR').AsLargeInt;
  end;
  DataSet.FieldByName('LINEA_DTL').AsString := SiguienteLinea;
  // El default SQL no se aplica antes de validar los campos requeridos.
  DataSet.FieldByName('LOTE_DTL').AsString := '';
  DataSet.FieldByName('CANTIDAD_STOCK_DTL').AsFloat := 0;
  DataSet.FieldByName('CANTIDAD_DTL').AsFloat := 0;
  DataSet.FieldByName('INSTANTE_STOCK_DTL').AsDateTime := Now;
  DataSet.FieldByName('ORIGEN_DTL').AsString := 'MANUAL';
end;

procedure TdmDocumentosTrabajo.unqryLineasBeforeDelete(DataSet: TDataSet);
begin
  if not PuedeEditarDocumentoActual then
  begin
    raise ERangeError.Create(
      'Solo el propietario puede borrar lineas del Documento de Trabajo.');
  end;
end;

procedure TdmDocumentosTrabajo.unqryLineasBeforePost(DataSet: TDataSet);
begin
  if not PuedeEditarDocumentoActual then
  begin
    raise ERangeError.Create(
      'Solo el propietario puede editar lineas del Documento de Trabajo.');
  end;
  if DataSet.FieldByName('ID_DTR_DTL').IsNull then
  begin
    raise ERangeError.Create(
      'Grabe primero la cabecera del Documento de Trabajo.');
  end;
  if Trim(DataSet.FieldByName('LINEA_DTL').AsString) = '' then
  begin
    DataSet.FieldByName('LINEA_DTL').AsString := SiguienteLinea;
  end;
  if Trim(DataSet.FieldByName('CODIGO_ART_DTL').AsString) = '' then
  begin
    raise ERangeError.Create('Indique el articulo de la linea.');
  end;
  if Trim(DataSet.FieldByName('CODIGO_UNIDAD_DTL').AsString) = '' then
  begin
    raise ERangeError.Create('Indique el SKU/unidad de la linea.');
  end;
  if DataSet.FieldByName('INSTANTE_STOCK_DTL').IsNull then
  begin
    DataSet.FieldByName('INSTANTE_STOCK_DTL').AsDateTime := Now;
  end;
  ActualizarAuditoria(DataSet);
end;

procedure TdmDocumentosTrabajo.DesempaquetarAtributosLineas;
var
  Partes: TArray<string>;
  Sku, sEsperado: string;
  i: Integer;
  Bm: TBookmark;
  bCambia: Boolean;
begin
  if unqryLineas.Active and (not unqryLineas.IsEmpty) and
     PuedeEditarDocumentoActual then
  begin
    Bm := unqryLineas.GetBookmark;
    unqryLineas.DisableControls;
    try
      unqryLineas.First;
      while not unqryLineas.Eof do
      begin
        Sku := unqryLineas.FieldByName('CODIGO_UNIDAD_DTL').AsString;
        Partes := Sku.Split(['/']);
        if Length(Partes) > 1 then
        begin
          // Idempotente POR COMPARACION (mismo arreglo que pedidos):
          // saltar solo si todos los ATTR coinciden con el troceo del
          // SKU; el criterio "ATTR1 relleno" dejaba lineas a medias.
          bCambia := unqryLineas.FieldByName(
            'NUM_ATRIBUTOS_DTL').AsInteger <> Length(Partes) - 1;
          for i := 1 to 5 do
          begin
            if i < Length(Partes) then
              sEsperado := Partes[i]
            else
              sEsperado := '';
            if Trim(unqryLineas.FieldByName('ATTR' + IntToStr(i) +
                 '_VALOR_DTL').AsString) <> sEsperado then
              bCambia := True;
          end;
          if bCambia then
          begin
            unqryLineas.Edit;
            unqryLineas.FieldByName('NUM_ATRIBUTOS_DTL').AsInteger :=
              Length(Partes) - 1;
            for i := 1 to 5 do
            begin
              if i < Length(Partes) then
                unqryLineas.FieldByName('ATTR' + IntToStr(i) +
                  '_VALOR_DTL').AsString := Partes[i]
              else
                unqryLineas.FieldByName('ATTR' + IntToStr(i) +
                  '_VALOR_DTL').AsString := '';
            end;
            unqryLineas.Post;
          end;
        end;
        unqryLineas.Next;
      end;
      if unqryLineas.BookmarkValid(Bm) then
        unqryLineas.GotoBookmark(Bm);
    finally
      unqryLineas.EnableControls;
      unqryLineas.FreeBookmark(Bm);
    end;
  end;
end;

procedure TdmDocumentosTrabajo.unqryCompartidosAfterInsert(DataSet: TDataSet);
begin
  if not unqryTablaG.FieldByName('ID_DTR').IsNull then
  begin
    DataSet.FieldByName('ID_DTR_DTC').AsLargeInt :=
      unqryTablaG.FieldByName('ID_DTR').AsLargeInt;
  end;
  DataSet.FieldByName('TIPO_DESTINO_DTC').AsString := 'USUARIO';
  DataSet.FieldByName('PERMISO_DTC').AsString := 'LECTURA';
end;

procedure TdmDocumentosTrabajo.unqryCompartidosBeforeDelete(DataSet: TDataSet);
begin
  if not PuedeEditarDocumentoActual then
  begin
    raise ERangeError.Create(
      'Solo el propietario puede dejar de compartir el Documento de Trabajo.');
  end;
end;

procedure TdmDocumentosTrabajo.unqryCompartidosBeforePost(DataSet: TDataSet);
var
  sDestino: string;
  sTipo: string;
begin
  if not PuedeEditarDocumentoActual then
  begin
    raise ERangeError.Create(
      'Solo el propietario puede compartir el Documento de Trabajo.');
  end;
  if DataSet.FieldByName('ID_DTR_DTC').IsNull then
  begin
    raise ERangeError.Create(
      'Grabe primero la cabecera del Documento de Trabajo.');
  end;
  sDestino := Trim(DataSet.FieldByName('USUARIO_GRUPO_DTC').AsString);
  if sDestino = '' then
  begin
    sDestino := Trim(DataSet.FieldByName('USUARIO_DTC').AsString);
  end;
  if sDestino = '' then
  begin
    raise ERangeError.Create(
      'Indique el usuario o grupo con el que se comparte.');
  end;
  sTipo := NormalizarTipoDestino(
    sDestino, DataSet.FieldByName('TIPO_DESTINO_DTC').AsString);
  if SameText(sTipo, 'USUARIO') and SameText(sDestino, IdentidadSesion.Usuario) then
  begin
    raise ERangeError.Create(
      'No es necesario compartir el documento consigo mismo.');
  end;
  DataSet.FieldByName('TIPO_DESTINO_DTC').AsString := sTipo;
  DataSet.FieldByName('USUARIO_GRUPO_DTC').AsString := sDestino;
  DataSet.FieldByName('USUARIO_DTC').AsString := sDestino;
  if Trim(DataSet.FieldByName('PERMISO_DTC').AsString) = '' then
  begin
    DataSet.FieldByName('PERMISO_DTC').AsString := 'LECTURA';
  end;
  ActualizarAuditoria(DataSet);
end;

initialization
  ForceReferenceToClass(TdmDocumentosTrabajo);
end.
