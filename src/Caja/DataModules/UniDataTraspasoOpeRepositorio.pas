{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataTraspasoOpeRepositorio                                }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       FactuZam                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Lecturas UniDAC auxiliares de la operativa de traspasos.                  }
{******************************************************************************}
unit UniDataTraspasoOpeRepositorio;

interface

uses
  Uni, inLibTraspasoOpePersistenciaIntf;

function CrearRepositorioTraspasoOpeUniDAC(
  AConexion: TUniConnection): IRepositorioTraspasoOpe;

implementation

uses
  System.SysUtils;

type
  TRepositorioTraspasoOpeUniDAC = class(
    TInterfacedObject,
    IRepositorioTraspasoOpe)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarAlmacenesDestino(
      const AAlmacenPropio: string): TAlmacenesDestinoTraspaso;
  end;

constructor TRepositorioTraspasoOpeUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioTraspasoOpeUniDAC.ListarAlmacenesDestino(
  const AAlmacenPropio: string): TAlmacenesDestinoTraspaso;
var
  oConsulta: TUniQuery;
  iAlmacen: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM ' +
      '  FROM fza_almacenes ' +
      ' WHERE ESACTIVO_ALM = ''S'' ' +
      '   AND TIPO_USO_ALM = ''ESTANDAR'' ' +
      '   AND CODIGO_ALM_ALM <> :PROPIO ' +
      ' ORDER BY ORDEN_ALM, CODIGO_ALM_ALM';
    oConsulta.ParamByName('PROPIO').AsString := AAlmacenPropio;
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iAlmacen := 0;
    while not oConsulta.Eof do
    begin
      Result[iAlmacen].Codigo :=
        oConsulta.FieldByName('CODIGO_ALM_ALM').AsString;
      Result[iAlmacen].Nombre :=
        oConsulta.FieldByName('NOMBRE_ALM_ALM').AsString;
      Inc(iAlmacen);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioTraspasoOpeUniDAC(
  AConexion: TUniConnection): IRepositorioTraspasoOpe;
begin
  Result := TRepositorioTraspasoOpeUniDAC.Create(AConexion);
end;

end.
