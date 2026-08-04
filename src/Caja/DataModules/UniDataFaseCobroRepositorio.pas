{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataFaseCobroRepositorio                                   }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       FactuZam                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Consultas UniDAC utilizadas durante la fase de cobro.                     }
{******************************************************************************}
unit UniDataFaseCobroRepositorio;

interface

uses
  Uni, inLibFaseCobroPersistenciaIntf;

function CrearRepositorioFaseCobroUniDAC(
  AConexion: TUniConnection
): IRepositorioFaseCobro;

implementation

uses
  System.SysUtils, Data.DB;

type
  TResultadoConsultaFaseCobroUniDAC = class(
    TInterfacedObject,
    IResultadoConsultaFaseCobro)
  private
    FDataSet: TDataSet;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioFaseCobroUniDAC = class(
    TInterfacedObject,
    IRepositorioFaseCobro)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarSeries(
      const ASolicitud: TSolicitudSeriesFaseCobro
    ): TSeriesFaseCobro;
    function ObtenerResumenNumeracion(
      const ACodigoEmpresa, ASerie: string;
      ANumero: Int64
    ): TResumenNumeracionFaseCobro;
    function ConsultarFormasPago: IResultadoConsultaFaseCobro;
    function ObtenerCliente(
      const ACodigoCliente: string;
      out ACliente: TClienteFaseCobro
    ): Boolean;
    function ExisteValePendiente(
      const ACodigoVale: string
    ): Boolean;
  end;

constructor TResultadoConsultaFaseCobroUniDAC.Create(ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TResultadoConsultaFaseCobroUniDAC.Destroy;
begin
  FreeAndNil(FDataSet);
  inherited;
end;

function TResultadoConsultaFaseCobroUniDAC.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

constructor TRepositorioFaseCobroUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioFaseCobroUniDAC.ListarSeries(
  const ASolicitud: TSolicitudSeriesFaseCobro
): TSeriesFaseCobro;
var
  oConsulta: TUniQuery;
  iSerie: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT EMPSER AS SERIE_CON ' +
      '  FROM vi_empresas_series ' +
      ' WHERE CODIGO_EMP_EMPSER = :EMPRESA ' +
      '   AND (CODIGO_ALM_EMPSER = :ALMACEN ' +
      '        OR IFNULL(CODIGO_ALM_EMPSER, '''') = '''') ' +
      '   AND (CODIGO_CAJA_EMPSER = :CAJA ' +
      '        OR IFNULL(CODIGO_CAJA_EMPSER, '''') = '''') ' +
      '   AND TIPO_DOC_EMPSER = ''FC'' ' +
      '   AND SUBTIPO_EMPSER = :SUBTIPO ' +
      '   AND (FECHA_DESDE_EMPSER <= :FECHA ' +
      '        OR FECHA_DESDE_EMPSER IS NULL) ' +
      '   AND (FECHA_HASTA_EMPSER >= :FECHA ' +
      '        OR FECHA_HASTA_EMPSER IS NULL)';
    oConsulta.ParamByName('EMPRESA').AsString :=
      ASolicitud.CodigoEmpresa;
    oConsulta.ParamByName('ALMACEN').AsString :=
      ASolicitud.CodigoAlmacen;
    oConsulta.ParamByName('CAJA').AsString := ASolicitud.CodigoCaja;
    oConsulta.ParamByName('SUBTIPO').AsString := ASolicitud.Subtipo;
    oConsulta.ParamByName('FECHA').AsDateTime := ASolicitud.Fecha;
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iSerie := 0;
    while not oConsulta.Eof do
    begin
      Result[iSerie] := oConsulta.FieldByName('SERIE_CON').AsString;
      Inc(iSerie);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFaseCobroUniDAC.ObtenerResumenNumeracion(
  const ACodigoEmpresa, ASerie: string;
  ANumero: Int64
): TResumenNumeracionFaseCobro;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TResumenNumeracionFaseCobro);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT COUNT(*) AS NFILAS, ' +
      '       MIN(CAST(NUMERO_FAC AS UNSIGNED)) AS NMIN, ' +
      '       MAX(CAST(NUMERO_FAC AS UNSIGNED)) AS NMAX, ' +
      '       MAX(LENGTH(NUMERO_FAC)) AS NLEN, ' +
      '       SUM(CASE WHEN CAST(NUMERO_FAC AS UNSIGNED) = :NUMERO ' +
      '                THEN 1 ELSE 0 END) AS NEXISTE ' +
      '  FROM fza_facturas ' +
      ' WHERE CODIGO_EMP_FAC = :EMPRESA ' +
      '   AND SERIE_FAC = :SERIE';
    oConsulta.ParamByName('NUMERO').AsLargeInt := ANumero;
    oConsulta.ParamByName('EMPRESA').AsString := ACodigoEmpresa;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.Open;
    Result.Filas := oConsulta.FieldByName('NFILAS').AsLargeInt;
    Result.Minimo := oConsulta.FieldByName('NMIN').AsLargeInt;
    Result.Maximo := oConsulta.FieldByName('NMAX').AsLargeInt;
    Result.Longitud := oConsulta.FieldByName('NLEN').AsInteger;
    Result.ExistentesNumero :=
      oConsulta.FieldByName('NEXISTE').AsLargeInt;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFaseCobroUniDAC.ConsultarFormasPago:
  IResultadoConsultaFaseCobro;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  oConsulta.Connection := FConexion;
  oConsulta.SQL.Text :=
    'SELECT * ' +
    '  FROM fza_caja_formas_pago ' +
    ' WHERE ESACTIVO_FORMA_PAGO_CFP = ''S'' ' +
    ' ORDER BY ORDEN_VISUAL_FORMA_PAGO_CFP';
  oConsulta.Open;
  Result := TResultadoConsultaFaseCobroUniDAC.Create(oConsulta);
end;

function TRepositorioFaseCobroUniDAC.ObtenerCliente(
  const ACodigoCliente: string;
  out ACliente: TClienteFaseCobro
): Boolean;
var
  oConsulta: TUniQuery;
begin
  ACliente := Default(TClienteFaseCobro);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT RAZON_SOCIAL_CLI, EMAIL_CLI, ' +
      '       ESPERMITE_DEUDA_CLI, TOTAL_LIMITE_CREDITO_CLI, ' +
      '       TOTAL_DEUDA_CLI ' +
      '  FROM fza_clientes ' +
      ' WHERE CODIGO_CLI_CLI = :CODIGO ' +
      ' LIMIT 1';
    oConsulta.ParamByName('CODIGO').AsString := ACodigoCliente;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
    if Result then
    begin
      ACliente.Nombre :=
        oConsulta.FieldByName('RAZON_SOCIAL_CLI').AsString;
      ACliente.Email := oConsulta.FieldByName('EMAIL_CLI').AsString;
      ACliente.PermiteDeuda :=
        oConsulta.FieldByName('ESPERMITE_DEUDA_CLI').AsString = 'S';
      ACliente.LimiteCredito :=
        oConsulta.FieldByName('TOTAL_LIMITE_CREDITO_CLI').AsCurrency;
      ACliente.DeudaActual :=
        oConsulta.FieldByName('TOTAL_DEUDA_CLI').AsCurrency;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFaseCobroUniDAC.ExisteValePendiente(
  const ACodigoVale: string
): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT 1 ' +
      '  FROM fza_caja_vales ' +
      ' WHERE CODIGO_VL = :CODIGO ' +
      '   AND ESTADO_VL = ''PENDIENTE'' ' +
      ' LIMIT 1';
    oConsulta.ParamByName('CODIGO').AsString := ACodigoVale;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioFaseCobroUniDAC(
  AConexion: TUniConnection
): IRepositorioFaseCobro;
begin
  Result := TRepositorioFaseCobroUniDAC.Create(AConexion);
end;

end.
