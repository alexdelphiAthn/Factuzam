{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataDocumentosTrabajo                                      }
{    Tipo:       Data Module                                                   }
{ Version:       1.0.0                                                         }
{   Fecha:       21/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Data module de Documentos de Trabajo.                                     }
{******************************************************************************}
unit UniDataDocumentosTrabajo;

interface

uses
  System.SysUtils, System.Classes, Data.DB, MemDS, DBAccess, Uni,
  UniDataGen;

type
  TdmDocumentosTrabajo = class(TdmBase)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryLineasAfterInsert(DataSet: TDataSet);
    procedure unqryLineasBeforePost(DataSet: TDataSet);
  private
    procedure ConfigurarQueries;
    function SiguienteLinea: string;
  public
    unqryLineas: TUniQuery;
    dsLineas: TDataSource;
    procedure AbrirDetalles; override;
  end;

var
  dmDocumentosTrabajo: TdmDocumentosTrabajo;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
  inLibGlobalVar, inMtoDocumentosTrabajo;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TdmDocumentosTrabajo.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryLineas := TUniQuery.Create(Self);
  dsLineas := TDataSource.Create(Self);
  dsLineas.DataSet := unqryLineas;
  ConfigurarQueries;
end;

procedure TdmDocumentosTrabajo.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(unqryLineas) then
  begin
    unqryLineas.Close;
  end;
  inherited;
end;

procedure TdmDocumentosTrabajo.ConfigurarQueries;
var
  frm: TfrmMtoDocumentosTrabajo;
begin
  unqryTablaG.SQL.Text :=
    'SELECT * ' +
    '  FROM fza_documentos_trabajo ' +
    ' ORDER BY INSTANTE_DOCUMENTO_DTR DESC, ID_DTR DESC';
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
    'SELECT * FROM fza_documentos_trabajo WHERE ID_DTR = :Old_ID_DTR FOR UPDATE';
  unqryTablaG.AfterInsert := unqryTablaGAfterInsert;
  unqryTablaG.BeforePost := unqryTablaGBeforePost;
  unqryLineas.Connection := oConn;
  unqryLineas.SQL.Text :=
    'SELECT * ' +
    '  FROM fza_documentos_trabajo_lineas ' +
    ' WHERE ID_DTR_DTL = :ID_DTR ' +
    ' ORDER BY LINEA_DTL';
  unqryLineas.KeyFields := 'ID_DTL';
  unqryLineas.MasterFields := 'ID_DTR';
  unqryLineas.DetailFields := 'ID_DTR_DTL';
  frm := GetOwnerForm<TfrmMtoDocumentosTrabajo>;
  if frm <> nil then
  begin
    unqryLineas.MasterSource := frm.dsTablaG;
  end;
  unqryLineas.SQLInsert.Text :=
    'INSERT INTO fza_documentos_trabajo_lineas ' +
    '  (ID_DTR_DTL, LINEA_DTL, CODIGO_ART_DTL, CODIGO_UNIDAD_DTL, ' +
    '   CODIGO_ALM_DTL, LOTE_DTL, FECHA_CADUCIDAD_DTL, ' +
    '   DESCRIPCION_ARTICULO_DTL, DESCRIPCION_UNIDAD_DTL, ' +
    '   CANTIDAD_STOCK_DTL, CANTIDAD_DTL, INSTANTE_STOCK_DTL, ' +
    '   ORIGEN_DTL, OBSERVACIONES_DTL, INSTANTE_ALTA, USUARIO_ALTA, ' +
    '   USUARIO_MODIF) ' +
    'VALUES ' +
    '  (:ID_DTR_DTL, :LINEA_DTL, :CODIGO_ART_DTL, :CODIGO_UNIDAD_DTL, ' +
    '   :CODIGO_ALM_DTL, :LOTE_DTL, :FECHA_CADUCIDAD_DTL, ' +
    '   :DESCRIPCION_ARTICULO_DTL, :DESCRIPCION_UNIDAD_DTL, ' +
    '   :CANTIDAD_STOCK_DTL, :CANTIDAD_DTL, :INSTANTE_STOCK_DTL, ' +
    '   :ORIGEN_DTL, :OBSERVACIONES_DTL, :INSTANTE_ALTA, ' +
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
    '  USUARIO_MODIF = :USUARIO_MODIF ' +
    'WHERE ID_DTL = :Old_ID_DTL';
  unqryLineas.SQLDelete.Text :=
    'DELETE FROM fza_documentos_trabajo_lineas WHERE ID_DTL = :Old_ID_DTL';
  unqryLineas.SQLRefresh.Text :=
    'SELECT * FROM fza_documentos_trabajo_lineas WHERE ID_DTL = :ID_DTL';
  unqryLineas.SQLLock.Text :=
    'SELECT * FROM fza_documentos_trabajo_lineas ' +
    ' WHERE ID_DTL = :Old_ID_DTL FOR UPDATE';
  unqryLineas.AfterInsert := unqryLineasAfterInsert;
  unqryLineas.BeforePost := unqryLineasBeforePost;
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
  if not unqryLineas.Active then
  begin
    unqryLineas.Open;
  end;
end;

procedure TdmDocumentosTrabajo.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  DataSet.FieldByName('TITULO_DTR').AsString :=
    'Documento de trabajo ' + FormatDateTime('dd/mm/yyyy hh:nn', Now);
  DataSet.FieldByName('TIPO_DTR').AsString := 'GENERAL';
  DataSet.FieldByName('ESTADO_DTR').AsString := 'ABIERTO';
  DataSet.FieldByName('CODIGO_EMP_DTR').AsString := oEmpresa;
  DataSet.FieldByName('CODIGO_ALM_DTR').AsString := oAlmacen;
  DataSet.FieldByName('USUARIO_DTR').AsString := oUser;
  DataSet.FieldByName('INSTANTE_DOCUMENTO_DTR').AsDateTime := Now;
end;

procedure TdmDocumentosTrabajo.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
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
  DataSet.FieldByName('CANTIDAD_STOCK_DTL').AsFloat := 0;
  DataSet.FieldByName('CANTIDAD_DTL').AsFloat := 0;
  DataSet.FieldByName('INSTANTE_STOCK_DTL').AsDateTime := Now;
  DataSet.FieldByName('ORIGEN_DTL').AsString := 'MANUAL';
end;

procedure TdmDocumentosTrabajo.unqryLineasBeforePost(DataSet: TDataSet);
begin
  if DataSet.FieldByName('ID_DTR_DTL').IsNull then
  begin
    raise ERangeError.Create('Grabe primero la cabecera del Documento de Trabajo.');
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
  odmConn.ActualizarUserTimeModif(DataSet);
end;

initialization
  ForceReferenceToClass(TdmDocumentosTrabajo);
end.
