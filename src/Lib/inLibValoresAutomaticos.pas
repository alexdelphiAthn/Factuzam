{******************************************************************************}
{                                                                              }
{  Módulo:       inLibValoresAutomaticos                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Resuelve series, contadores y valores configurados por defecto.           }
{******************************************************************************}
unit inLibValoresAutomaticos;

interface

uses
  System.Classes, Data.DB, Uni;

function ObtenerSeriePropiaAlmacen(AConexion: TUniConnection;
  const AEmpresa, ATipoDocumento, AAlmacen: string): string;
function ObtenerSerieDefecto(AConexion: TUniConnection;
  const AEmpresa, ATipoDocumento: string;
  const AAlmacen: string = ''): string;
procedure CargarSeriesEmpresa(AConexion: TUniConnection;
  const AEmpresa, ATipoDocumento: string;
  AElementos: TStrings);
function ObtenerSiguienteContador(AConexion: TUniConnection;
  const ATipoDocumento, AUsuario: string): string;
function ObtenerValorPorDefecto(AConexion: TUniConnection;
  const ATabla, ACampo, ACampoCondicion: string): string;
procedure AsignarValorPorDefecto(ADataSet: TDataSet;
  const ACampo, AValor, ATipoDato: string);
procedure AplicarValoresPorDefecto(AConexion: TUniConnection;
  ADataSetDestino: TDataSet;
  const ANombreTabla: string);

implementation

uses
  System.SysUtils, inLibMsgComun;

const
  SQL_VIGENCIA_SERIE =
    '   AND (FECHA_DESDE_EMPSER IS NULL OR ' +
    'FECHA_DESDE_EMPSER <= CURDATE()) ' +
    '   AND (FECHA_HASTA_EMPSER IS NULL OR ' +
    'FECHA_HASTA_EMPSER >= CURDATE()) ';

function HayDatosSerie(const AEmpresa, ATipoDocumento: string): Boolean;
begin
  Result :=
    (Trim(AEmpresa) <> '') and
    (Trim(ATipoDocumento) <> '');
end;

function ObtenerSeriePropiaAlmacen(AConexion: TUniConnection;
  const AEmpresa, ATipoDocumento, AAlmacen: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  if HayDatosSerie(AEmpresa, ATipoDocumento) and
     (Trim(AAlmacen) <> '') then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text :=
        'SELECT EMPSER FROM fza_empresas_series ' +
        ' WHERE CODIGO_EMP_EMPSER = :emp ' +
        '   AND TIPO_DOC_EMPSER = :tip ' +
        '   AND CODIGO_ALM_EMPSER = :alm ' +
        SQL_VIGENCIA_SERIE +
        ' LIMIT 1';
      oConsulta.ParamByName('emp').AsString := AEmpresa;
      oConsulta.ParamByName('tip').AsString := ATipoDocumento;
      oConsulta.ParamByName('alm').AsString := AAlmacen;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
        Result := oConsulta.FieldByName('EMPSER').AsString;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function ObtenerSerieDefecto(AConexion: TUniConnection;
  const AEmpresa, ATipoDocumento: string;
  const AAlmacen: string): string;
var
  oConsulta: TUniQuery;
  sFiltroAlmacen: string;
begin
  Result := '';
  if HayDatosSerie(AEmpresa, ATipoDocumento) then
  begin
    if Trim(AAlmacen) <> '' then
      Result := ObtenerSeriePropiaAlmacen(
        AConexion, AEmpresa, ATipoDocumento, AAlmacen);
    if Result = '' then
    begin
      sFiltroAlmacen := '';
      if Trim(AAlmacen) <> '' then
        sFiltroAlmacen :=
          '   AND IFNULL(CODIGO_ALM_EMPSER, '''') = '''' ';
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := AConexion;
        oConsulta.SQL.Text :=
          'SELECT EMPSER FROM fza_empresas_series ' +
          ' WHERE CODIGO_EMP_EMPSER = :emp ' +
          '   AND TIPO_DOC_EMPSER = :tip ' +
          SQL_VIGENCIA_SERIE +
          sFiltroAlmacen +
          ' LIMIT 1';
        oConsulta.ParamByName('emp').AsString := AEmpresa;
        oConsulta.ParamByName('tip').AsString := ATipoDocumento;
        oConsulta.Open;
        if not oConsulta.IsEmpty then
          Result := oConsulta.FieldByName('EMPSER').AsString;
      finally
        FreeAndNil(oConsulta);
      end;
    end;
  end;
end;

procedure CargarSeriesEmpresa(AConexion: TUniConnection;
  const AEmpresa, ATipoDocumento: string;
  AElementos: TStrings);
var
  oConsulta: TUniQuery;
begin
  AElementos.Clear;
  if HayDatosSerie(AEmpresa, ATipoDocumento) then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text :=
        'SELECT DISTINCT EMPSER FROM fza_empresas_series ' +
        ' WHERE CODIGO_EMP_EMPSER = :emp ' +
        '   AND TIPO_DOC_EMPSER = :tip ' +
        SQL_VIGENCIA_SERIE +
        ' ORDER BY EMPSER';
      oConsulta.ParamByName('emp').AsString := AEmpresa;
      oConsulta.ParamByName('tip').AsString := ATipoDocumento;
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        AElementos.Add(
          oConsulta.FieldByName('EMPSER').AsString);
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function ObtenerSiguienteContador(AConexion: TUniConnection;
  const ATipoDocumento, AUsuario: string): string;
var
  oProcedimiento: TUniStoredProc;
begin
  Result := '';
  oProcedimiento := TUniStoredProc.Create(nil);
  try
    oProcedimiento.Connection := AConexion;
    oProcedimiento.StoredProcName := 'PRC_GET_NEXT_CONT';
    oProcedimiento.Params.Clear;
    oProcedimiento.Params.CreateParam(
      ftString, 'pTipoDoc', ptInput).AsString :=
        ATipoDocumento;
    oProcedimiento.Params.CreateParam(
      ftString, 'pUSUARIO_MODIF', ptInput).AsString :=
        AUsuario;
    oProcedimiento.Params.CreateParam(
      ftString, 'pcont', ptOutput);
    try
      oProcedimiento.Execute;
      Result :=
        oProcedimiento.Params.ParamByName('pcont').AsString;
    except
      on E: Exception do
        raise Exception.Create(Format(
          SErrorGenerarContadorAutomatico, [E.Message]));
    end;
  finally
    FreeAndNil(oProcedimiento);
  end;
end;

function ObtenerValorPorDefecto(AConexion: TUniConnection;
  const ATabla, ACampo, ACampoCondicion: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := Format(
      'SELECT %s FROM %s WHERE %s = %s LIMIT 1',
      [ACampo, ATabla, ACampoCondicion, QuotedStr('S')]);
    oConsulta.Open;
    if not oConsulta.Eof then
      Result := oConsulta.Fields[0].AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure AsignarValorPorDefecto(ADataSet: TDataSet;
  const ACampo, AValor, ATipoDato: string);
var
  oCampo: TField;
begin
  oCampo := ADataSet.FindField(ACampo);
  if Assigned(oCampo) then
  begin
    if ATipoDato = 'INTEGER' then
      oCampo.AsInteger := StrToIntDef(AValor, 0)
    else if ATipoDato = 'FLOAT' then
      oCampo.AsFloat := StrToFloatDef(AValor, 0)
    else
      oCampo.AsString := AValor;
  end;
end;

procedure AplicarValoresPorDefecto(AConexion: TUniConnection;
  ADataSetDestino: TDataSet;
  const ANombreTabla: string);
var
  oConsulta: TUniQuery;
begin
  if not (
    ADataSetDestino.State in [dsInsert, dsEdit]) then
    ADataSetDestino.Edit;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT CAMPO_OBJETIVO_DEF_VD, ' +
      '       VALOR_DEF_VD, ' +
      '       TIPO_DATO_DEF_VD ' +
      '  FROM fza_valores_defecto ' +
      ' WHERE TABLA_OBJETIVO_DEF_VD = ' +
      QuotedStr(ANombreTabla);
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      AsignarValorPorDefecto(
        ADataSetDestino,
        oConsulta.FieldByName(
          'CAMPO_OBJETIVO_DEF_VD').AsString,
        oConsulta.FieldByName(
          'VALOR_DEF_VD').AsString,
        oConsulta.FieldByName(
          'TIPO_DATO_DEF_VD').AsString);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
