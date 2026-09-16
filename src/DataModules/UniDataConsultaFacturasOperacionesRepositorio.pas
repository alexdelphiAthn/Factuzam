{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataConsultaFacturasOperacionesRepositorio                }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC para consultar una factura desde operaciones.        }
{******************************************************************************}
unit UniDataConsultaFacturasOperacionesRepositorio;

interface

uses
  Uni, inLibConsultaFacturasOperacionesPersistenciaIntf;

function CrearRepositorioConsultaFacturasOperacionesUniDAC(
  AConexion: TUniConnection): IRepositorioConsultaFacturasOperaciones;

implementation

uses
  System.SysUtils, Data.DB, UniDataRectificativasSql;

const
  SQL_CONSULTAR_FACTURA =
    'SELECT f.ESCONSOLIDADA_FAC, f.TIPO_FAC, f.FECHA_FAC, ' +
    'CASE WHEN f.ESCONSOLIDADA_FAC = ''S'' ' +
    'AND f.TIPO_FAC = ''SIMPLIFICADA'' ' +
    'AND f.FASE_FAC IN (''VERIFACTU_OK'', ''VERIFACTU_ACEPT_ERR'') ' +
    'AND (SELECT c.ESTADO_FACCON FROM fza_facturas_consolidaciones c ' +
    'WHERE c.SERIE_FAC_FACCON = f.SERIE_FAC ' +
    'AND c.NUMERO_FAC_FACCON = f.NUMERO_FAC ' +
    'ORDER BY c.ID_FACCON DESC LIMIT 1) IN ' +
    '(''VERIFACTU_OK'', ''VERIFACTU_PROCESADO'', ''VERIFACTU_DUPLICADO'', ' +
    '''VERIFACTU_SUBSANADO'', ''VERIFACTU_ACEPT_ERR'') ' +
    'AND NOT EXISTS (SELECT 1 FROM fza_verifactu_cola q ' +
    'WHERE q.SERIE_FAC_VFCOLA = f.SERIE_FAC ' +
    'AND q.NUMERO_FAC_VFCOLA = f.NUMERO_FAC ' +
    'AND q.TIPO_OPERACION_VFCOLA IN ' +
    '(''ALTA'', ''ANULACION'', ''SUBSANACION'') ' +
    'AND (q.ESTADO_VFCOLA <> ''ENVIADA'' ' +
    'OR q.TIPO_OPERACION_VFCOLA = ''ANULACION'')) ';

type
  TRepositorioConsultaFacturasOperacionesUniDAC = class(
    TInterfacedObject,
    IRepositorioConsultaFacturasOperaciones)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarFactura(
      const ASerie, ANumero: string): TFacturaConsultaOperacion;
  end;

constructor TRepositorioConsultaFacturasOperacionesUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TRepositorioConsultaFacturasOperacionesUniDAC.ConsultarFactura(
  const ASerie, ANumero: string): TFacturaConsultaOperacion;
var
  Consulta: TUniQuery;
begin
  Result := Default(TFacturaConsultaOperacion);
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := SQL_CONSULTAR_FACTURA +
      SQLExcluirVentaRetirada(
        'f.CODIGO_EMP_FAC', 'f.SERIE_FAC', 'f.NUMERO_FAC') +
      'THEN ''S'' ELSE ''N'' END AS PUEDE_SUBSANAR ' +
      'FROM fza_facturas f WHERE f.SERIE_FAC = :SERIE ' +
      'AND f.NUMERO_FAC = :NUMERO';
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.Open;
    Result.Existe := not Consulta.IsEmpty;
    if Result.Existe then
    begin
      Result.Consolidada :=
        Consulta.FieldByName('ESCONSOLIDADA_FAC').AsString = 'S';
      Result.PuedeSubsanar :=
        Consulta.FieldByName('PUEDE_SUBSANAR').AsString = 'S';
      Result.Tipo := Consulta.FieldByName('TIPO_FAC').AsString;
      Result.Fecha := Consulta.FieldByName('FECHA_FAC').AsDateTime;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function CrearRepositorioConsultaFacturasOperacionesUniDAC(
  AConexion: TUniConnection): IRepositorioConsultaFacturasOperaciones;
begin
  Result := TRepositorioConsultaFacturasOperacionesUniDAC.Create(AConexion);
end;

end.
