unit UniDataValoresAutomaticosRepositorio;

interface

uses
  System.Classes, Data.DB, Uni,
  inLibValoresAutomaticosPersistenciaIntf;

type
  TRepositorioValoresAutomaticosUniDAC = class(
    TInterfacedObject, IRepositorioValoresAutomaticos)
  private
    FConexion: TUniConnection;
    procedure ComprobarConexion;
  public
    constructor Create(AConexion: TUniConnection);
    function ObtenerSeriePropiaAlmacen(const AEmpresa,
      ATipoDocumento, AAlmacen: string): string;
    function ObtenerSerieDefecto(const AEmpresa, ATipoDocumento,
      AAlmacen: string): string;
    procedure CargarSeriesEmpresa(const AEmpresa,
      ATipoDocumento: string; AElementos: TStrings);
    function ObtenerSiguienteContador(const ATipoDocumento,
      AUsuario: string): TResultadoContadorAutomatico;
    function ObtenerValorPorDefecto(const ATabla, ACampo,
      ACampoCondicion: string): string;
    function CargarValoresPorDefecto(const ANombreTabla: string):
      TArray<TValorPorDefectoPersistido>;
  end;

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
procedure AplicarValoresPorDefecto(AConexion: TUniConnection;
  ADataSetDestino: TDataSet;
  const ANombreTabla: string);

implementation

uses
  System.SysUtils, System.Generics.Collections,
  inLibValoresAutomaticos;

const
  SQL_VIGENCIA_SERIE =
    '   AND (FECHA_DESDE_EMPSER IS NULL OR ' +
    'FECHA_DESDE_EMPSER <= CURDATE()) ' +
    '   AND (FECHA_HASTA_EMPSER IS NULL OR ' +
    'FECHA_HASTA_EMPSER >= CURDATE()) ';

constructor TRepositorioValoresAutomaticosUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

procedure TRepositorioValoresAutomaticosUniDAC.ComprobarConexion;
begin
  if not Assigned(FConexion) or
     not FConexion.Connected then
  begin
    raise EValoresAutomaticosPersistencia.Create(
      evaConexionNoDisponible,
      'La conexión de valores automáticos no está activa.');
  end;
end;

function TRepositorioValoresAutomaticosUniDAC.ObtenerSeriePropiaAlmacen(
  const AEmpresa, ATipoDocumento, AAlmacen: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  ComprobarConexion;
  oConsulta := TUniQuery.Create(nil);
  try
    try
      oConsulta.Connection := FConexion;
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
    except
      on E: Exception do
      begin
        raise EValoresAutomaticosPersistencia.Create(
          evaLecturaFallida, E.Message);
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioValoresAutomaticosUniDAC.ObtenerSerieDefecto(
  const AEmpresa, ATipoDocumento, AAlmacen: string): string;
var
  oConsulta: TUniQuery;
  sFiltroAlmacen: string;
begin
  Result := '';
  ComprobarConexion;
  if Trim(AAlmacen) <> '' then
  begin
    Result := ObtenerSeriePropiaAlmacen(
      AEmpresa, ATipoDocumento, AAlmacen);
  end;
  if Result = '' then
  begin
    sFiltroAlmacen := '';
    if Trim(AAlmacen) <> '' then
    begin
      sFiltroAlmacen :=
        '   AND IFNULL(CODIGO_ALM_EMPSER, '''') = '''' ';
    end;
    oConsulta := TUniQuery.Create(nil);
    try
      try
        oConsulta.Connection := FConexion;
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
      except
        on E: Exception do
        begin
          raise EValoresAutomaticosPersistencia.Create(
            evaLecturaFallida, E.Message);
        end;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TRepositorioValoresAutomaticosUniDAC.CargarSeriesEmpresa(
  const AEmpresa, ATipoDocumento: string; AElementos: TStrings);
var
  oConsulta: TUniQuery;
begin
  ComprobarConexion;
  AElementos.Clear;
  oConsulta := TUniQuery.Create(nil);
  try
    try
      oConsulta.Connection := FConexion;
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
    except
      on E: Exception do
      begin
        raise EValoresAutomaticosPersistencia.Create(
          evaLecturaFallida, E.Message);
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioValoresAutomaticosUniDAC.ObtenerSiguienteContador(
  const ATipoDocumento, AUsuario: string):
  TResultadoContadorAutomatico;
var
  oProcedimiento: TUniStoredProc;
begin
  if not Assigned(FConexion) or
     not FConexion.Connected then
  begin
    Result := TResultadoContadorAutomatico.Fallido(
      evaConexionNoDisponible,
      'La conexión de valores automáticos no está activa.');
  end
  else
  begin
    oProcedimiento := TUniStoredProc.Create(nil);
    try
      oProcedimiento.Connection := FConexion;
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
        Result := TResultadoContadorAutomatico.Correcto(
          oProcedimiento.Params.ParamByName(
            'pcont').AsString);
      except
        on E: Exception do
        begin
          Result := TResultadoContadorAutomatico.Fallido(
            evaGeneracionContadorFallida, E.Message);
        end;
      end;
    finally
      FreeAndNil(oProcedimiento);
    end;
  end;
end;

function TRepositorioValoresAutomaticosUniDAC.ObtenerValorPorDefecto(
  const ATabla, ACampo, ACampoCondicion: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  ComprobarConexion;
  oConsulta := TUniQuery.Create(nil);
  try
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text := Format(
        'SELECT %s FROM %s WHERE %s = %s LIMIT 1',
        [ACampo, ATabla, ACampoCondicion, QuotedStr('S')]);
      oConsulta.Open;
      if not oConsulta.Eof then
        Result := oConsulta.Fields[0].AsString;
    except
      on E: Exception do
      begin
        raise EValoresAutomaticosPersistencia.Create(
          evaLecturaFallida, E.Message);
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioValoresAutomaticosUniDAC.CargarValoresPorDefecto(
  const ANombreTabla: string): TArray<TValorPorDefectoPersistido>;
var
  oConsulta: TUniQuery;
  oElemento: TValorPorDefectoPersistido;
  oElementos: TList<TValorPorDefectoPersistido>;
begin
  ComprobarConexion;
  oElementos := TList<TValorPorDefectoPersistido>.Create;
  try
    oConsulta := TUniQuery.Create(nil);
    try
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text :=
          'SELECT CAMPO_OBJETIVO_DEF_VD, ' +
          '       VALOR_DEF_VD, ' +
          '       TIPO_DATO_DEF_VD ' +
          '  FROM fza_valores_defecto ' +
          ' WHERE TABLA_OBJETIVO_DEF_VD = :TABLA';
        oConsulta.ParamByName('TABLA').AsString := ANombreTabla;
        oConsulta.Open;
        while not oConsulta.Eof do
        begin
          oElemento.Campo := oConsulta.FieldByName(
            'CAMPO_OBJETIVO_DEF_VD').AsString;
          oElemento.Valor := oConsulta.FieldByName(
            'VALOR_DEF_VD').AsString;
          oElemento.TipoDato := oConsulta.FieldByName(
            'TIPO_DATO_DEF_VD').AsString;
          oElementos.Add(oElemento);
          oConsulta.Next;
        end;
      except
        on E: Exception do
        begin
          raise EValoresAutomaticosPersistencia.Create(
            evaLecturaFallida, E.Message);
        end;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
    Result := oElementos.ToArray;
  finally
    FreeAndNil(oElementos);
  end;
end;

function CrearRepositorio(AConexion: TUniConnection):
  IRepositorioValoresAutomaticos;
begin
  Result := TRepositorioValoresAutomaticosUniDAC.Create(AConexion);
end;

function ObtenerSeriePropiaAlmacen(AConexion: TUniConnection;
  const AEmpresa, ATipoDocumento, AAlmacen: string): string;
begin
  Result := inLibValoresAutomaticos.ObtenerSeriePropiaAlmacen(
    CrearRepositorio(AConexion), AEmpresa, ATipoDocumento, AAlmacen);
end;

function ObtenerSerieDefecto(AConexion: TUniConnection;
  const AEmpresa, ATipoDocumento, AAlmacen: string): string;
begin
  Result := inLibValoresAutomaticos.ObtenerSerieDefecto(
    CrearRepositorio(AConexion), AEmpresa, ATipoDocumento, AAlmacen);
end;

procedure CargarSeriesEmpresa(AConexion: TUniConnection;
  const AEmpresa, ATipoDocumento: string; AElementos: TStrings);
begin
  inLibValoresAutomaticos.CargarSeriesEmpresa(
    CrearRepositorio(AConexion), AEmpresa, ATipoDocumento, AElementos);
end;

function ObtenerSiguienteContador(AConexion: TUniConnection;
  const ATipoDocumento, AUsuario: string): string;
begin
  Result := inLibValoresAutomaticos.ObtenerSiguienteContador(
    CrearRepositorio(AConexion), ATipoDocumento, AUsuario);
end;

function ObtenerValorPorDefecto(AConexion: TUniConnection;
  const ATabla, ACampo, ACampoCondicion: string): string;
begin
  Result := inLibValoresAutomaticos.ObtenerValorPorDefecto(
    CrearRepositorio(AConexion), ATabla, ACampo, ACampoCondicion);
end;

procedure AplicarValoresPorDefecto(AConexion: TUniConnection;
  ADataSetDestino: TDataSet; const ANombreTabla: string);
begin
  inLibValoresAutomaticos.AplicarValoresPorDefecto(
    CrearRepositorio(AConexion), ADataSetDestino, ANombreTabla);
end;

end.
