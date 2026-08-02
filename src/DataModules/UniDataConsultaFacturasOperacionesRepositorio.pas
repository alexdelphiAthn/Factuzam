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
  System.SysUtils, Data.DB;

const
  SQL_CONSULTAR_FACTURA =
    'SELECT ESCONSOLIDADA_FAC, TIPO_FAC, FECHA_FAC ' +
    'FROM fza_facturas WHERE SERIE_FAC = :SERIE ' +
    'AND NUMERO_FAC = :NUMERO';

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
    Consulta.SQL.Text := SQL_CONSULTAR_FACTURA;
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.Open;
    Result.Existe := not Consulta.IsEmpty;
    if Result.Existe then
    begin
      Result.Consolidada :=
        Consulta.FieldByName('ESCONSOLIDADA_FAC').AsString = 'S';
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
