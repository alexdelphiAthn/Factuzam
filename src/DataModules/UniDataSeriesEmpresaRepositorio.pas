{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataSeriesEmpresaRepositorio                              }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC de las series documentales de una empresa.           }
{******************************************************************************}
unit UniDataSeriesEmpresaRepositorio;

interface

uses
  Uni, inLibSeriesEmpresaPersistenciaIntf;

function CrearRepositorioSeriesEmpresaUniDAC(
  AConexion: TUniConnection): IRepositorioSeriesEmpresa;

implementation

uses
  System.SysUtils, Data.DB, inLibValoresAutomaticos, inLibMsgComun;

const
  SQL_TIPOS_DOCUMENTO =
    'SELECT DISTINCT TIPO_DOC FROM (' +
    'SELECT CODIGO_TIPO_DOCUMENTO_TD AS TIPO_DOC ' +
    'FROM fza_tipos_documentos ' +
    'WHERE TRIM(COALESCE(CODIGO_TIPO_DOCUMENTO_TD, '''')) <> '''' ' +
    'UNION SELECT TIPO_DOC_CON AS TIPO_DOC FROM fza_contadores ' +
    'WHERE TRIM(COALESCE(TIPO_DOC_CON, '''')) <> '''' ' +
    'UNION SELECT TIPO_DOC_EMPSER AS TIPO_DOC FROM fza_empresas_series ' +
    'WHERE TRIM(COALESCE(TIPO_DOC_EMPSER, '''')) <> '''') DOC ' +
    'ORDER BY TIPO_DOC';
  SQL_EXISTE_SERIE_SOLAPADA =
    'SELECT 1 FROM fza_empresas_series ' +
    'WHERE CODIGO_EMP_EMPSER = :EMP AND TIPO_DOC_EMPSER = :TIPO ' +
    'AND EMPSER = :SERIE AND IFNULL(CODIGO_ALM_EMPSER, '''') = '''' ' +
    'AND IFNULL(CODIGO_CAJA_EMPSER, '''') = '''' ' +
    'AND IFNULL(SUBTIPO_EMPSER, '''') = :SUBTIPO ' +
    'AND (FECHA_DESDE_EMPSER IS NULL OR FECHA_DESDE_EMPSER <= :HASTA) ' +
    'AND (FECHA_HASTA_EMPSER IS NULL OR FECHA_HASTA_EMPSER >= :DESDE) ' +
    'LIMIT 1';
  SQL_INSERTAR_SERIE =
    'INSERT INTO fza_empresas_series (CODIGO_SERIE_EMPSER, ' +
    'CODIGO_EMP_EMPSER, CODIGO_ALM_EMPSER, CODIGO_CAJA_EMPSER, EMPSER, ' +
    'TIPO_DOC_EMPSER, SUBTIPO_EMPSER, FECHA_DESDE_EMPSER, ' +
    'FECHA_HASTA_EMPSER, INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, ' +
    'USUARIO_MODIF) VALUES (:CODIGO, :EMP, NULL, NULL, :SERIE, :TIPO, ' +
    'NULLIF(:SUBTIPO, ''''), :DESDE, :HASTA, NOW(), NOW(), :USUARIO, ' +
    ':USUARIO)';

type
  TRepositorioSeriesEmpresaUniDAC = class(
    TInterfacedObject,
    IRepositorioSeriesEmpresa)
  private
    FConexion: TUniConnection;
    function ExisteSerieSolapada(
      const AEmpresa, ASerie, ATipo, ASubtipo: string;
      AFechaDesde, AFechaHasta: TDateTime): Boolean;
    procedure InsertarSerie(
      const AEmpresa, ASerie, ATipo, ASubtipo: string;
      AFechaDesde, AFechaHasta: TDateTime;
      const AUsuario: string);
  public
    constructor Create(AConexion: TUniConnection);
    function ListarTiposDocumento: TTiposDocumentoEmpresa;
    function CrearSerieSiFalta(
      const AEmpresa, ASerie, ATipo, ASubtipo: string;
      AFechaDesde, AFechaHasta: TDateTime;
      const AUsuario: string): Boolean;
  end;

constructor TRepositorioSeriesEmpresaUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TRepositorioSeriesEmpresaUniDAC.ListarTiposDocumento:
  TTiposDocumentoEmpresa;
var
  Consulta: TUniQuery;
  Posicion: Integer;
begin
  SetLength(Result, 0);
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := SQL_TIPOS_DOCUMENTO;
    Consulta.Open;
    while not Consulta.Eof do
    begin
      Posicion := Length(Result);
      SetLength(Result, Posicion + 1);
      Result[Posicion] := Consulta.FieldByName('TIPO_DOC').AsString;
      Consulta.Next;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioSeriesEmpresaUniDAC.ExisteSerieSolapada(
  const AEmpresa, ASerie, ATipo, ASubtipo: string;
  AFechaDesde, AFechaHasta: TDateTime): Boolean;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := SQL_EXISTE_SERIE_SOLAPADA;
    Consulta.ParamByName('EMP').AsString := AEmpresa;
    Consulta.ParamByName('TIPO').AsString := ATipo;
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('SUBTIPO').AsString := ASubtipo;
    Consulta.ParamByName('DESDE').AsDateTime := AFechaDesde;
    Consulta.ParamByName('HASTA').AsDateTime := AFechaHasta;
    Consulta.Open;
    Result := not Consulta.IsEmpty;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TRepositorioSeriesEmpresaUniDAC.InsertarSerie(
  const AEmpresa, ASerie, ATipo, ASubtipo: string;
  AFechaDesde, AFechaHasta: TDateTime;
  const AUsuario: string);
var
  Codigo: string;
  Consulta: TUniQuery;
begin
  Codigo := ObtenerSiguienteContador(FConexion, 'ES', AUsuario);
  if Trim(Codigo) = '' then
    raise Exception.Create(SErrorContadorSerieEmpresa);
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := SQL_INSERTAR_SERIE;
    Consulta.ParamByName('CODIGO').AsString := Codigo;
    Consulta.ParamByName('EMP').AsString := AEmpresa;
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('TIPO').AsString := ATipo;
    Consulta.ParamByName('SUBTIPO').AsString := ASubtipo;
    Consulta.ParamByName('DESDE').AsDateTime := AFechaDesde;
    Consulta.ParamByName('HASTA').AsDateTime := AFechaHasta;
    Consulta.ParamByName('USUARIO').AsString := AUsuario;
    Consulta.Execute;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioSeriesEmpresaUniDAC.CrearSerieSiFalta(
  const AEmpresa, ASerie, ATipo, ASubtipo: string;
  AFechaDesde, AFechaHasta: TDateTime;
  const AUsuario: string): Boolean;
begin
  Result := not ExisteSerieSolapada(
    AEmpresa,
    ASerie,
    ATipo,
    ASubtipo,
    AFechaDesde,
    AFechaHasta);
  if Result then
    InsertarSerie(
      AEmpresa,
      ASerie,
      ATipo,
      ASubtipo,
      AFechaDesde,
      AFechaHasta,
      AUsuario);
end;

function CrearRepositorioSeriesEmpresaUniDAC(
  AConexion: TUniConnection): IRepositorioSeriesEmpresa;
begin
  Result := TRepositorioSeriesEmpresaUniDAC.Create(AConexion);
end;

end.
