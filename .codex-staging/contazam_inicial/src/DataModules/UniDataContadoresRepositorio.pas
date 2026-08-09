{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataContadoresRepositorio                                  }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adaptador UniDAC para obtener numeradores mediante bloqueo pesimista.     }
{******************************************************************************}
unit UniDataContadoresRepositorio;

interface

uses
  Data.DB, Uni, inLibContadoresIntf;

function CrearRepositorioContadores(
  AConexion: TUniConnection): IContadorDocumentos;

implementation

uses
  System.SysUtils;

type
  TRepositorioContadores = class(
    TInterfacedObject,
    IContadorDocumentos)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function SiguienteNumero(
      const AEmpresa: string;
      AEjercicio: Integer;
      const ATipoDocumento: string;
      const ASerie: string): Int64;
  end;

constructor TRepositorioContadores.Create(AConexion: TUniConnection);
begin
  if AConexion = nil then
  begin
    raise EArgumentNilException.Create('AConexion');
  end;
  inherited Create;
  FConexion := AConexion;
end;

function CrearRepositorioContadores(
  AConexion: TUniConnection): IContadorDocumentos;
begin
  Result := TRepositorioContadores.Create(AConexion);
end;

function TRepositorioContadores.SiguienteNumero(
  const AEmpresa: string;
  AEjercicio: Integer;
  const ATipoDocumento: string;
  const ASerie: string): Int64;
var
  oConsulta: TUniQuery;
  bTransaccionPropia: Boolean;
  iContadorActual: Int64;
  iNumeroDigitos: Integer;
  sNumero: string;
begin
  bTransaccionPropia := not FConexion.InTransaction;
  if bTransaccionPropia then
  begin
    FConexion.StartTransaction;
  end;
  oConsulta := TUniQuery.Create(nil);
  try
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT CONTADOR_CON, NUMERO_DIGITOS_CON FROM cza_contadores ' +
        'WHERE TIPO_DOCUMENTO_CON = :TIPO ' +
        'AND CODIGO_EMP_CON = :EMPRESA ' +
        'AND EJERCICIO_CON = :EJERCICIO ' +
        'AND SERIE_CON = :SERIE ' +
        'AND ESACTIVO_CON = ''S'' FOR UPDATE';
      oConsulta.ParamByName('TIPO').AsString := ATipoDocumento;
      oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
      oConsulta.ParamByName('EJERCICIO').AsInteger := AEjercicio;
      oConsulta.ParamByName('SERIE').AsString := ASerie;
      oConsulta.Open;
      if oConsulta.IsEmpty then
      begin
        raise EInvalidOpException.CreateFmt(
          'No existe el contador %s/%s para el ejercicio %d.',
          [ATipoDocumento, ASerie, AEjercicio]);
      end;
      if not TryStrToInt64(
        Trim(oConsulta.FieldByName('CONTADOR_CON').AsString),
        iContadorActual) then
      begin
        raise EConvertError.CreateFmt(
          'El contador %s/%s no contiene un número válido.',
          [ATipoDocumento, ASerie]);
      end;
      Result := iContadorActual + 1;
      iNumeroDigitos := oConsulta.FieldByName(
        'NUMERO_DIGITOS_CON').AsInteger;
      if iNumeroDigitos < Length(
        Trim(oConsulta.FieldByName('CONTADOR_CON').AsString)) then
      begin
        iNumeroDigitos := Length(
          Trim(oConsulta.FieldByName('CONTADOR_CON').AsString));
      end;
      sNumero := IntToStr(Result);
      if Length(sNumero) < iNumeroDigitos then
      begin
        sNumero := StringOfChar(
          '0',
          iNumeroDigitos - Length(sNumero)) + sNumero;
      end;
      oConsulta.Close;
      oConsulta.SQL.Text :=
        'UPDATE cza_contadores SET CONTADOR_CON = :NUMERO, ' +
        'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
        'WHERE TIPO_DOCUMENTO_CON = :TIPO ' +
        'AND CODIGO_EMP_CON = :EMPRESA ' +
        'AND EJERCICIO_CON = :EJERCICIO ' +
        'AND SERIE_CON = :SERIE';
      oConsulta.ParamByName('NUMERO').AsString := sNumero;
      oConsulta.ParamByName('USUARIO').AsString :=
        GetEnvironmentVariable('USERNAME');
      oConsulta.ParamByName('TIPO').AsString := ATipoDocumento;
      oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
      oConsulta.ParamByName('EJERCICIO').AsInteger := AEjercicio;
      oConsulta.ParamByName('SERIE').AsString := ASerie;
      oConsulta.ExecSQL;
      if bTransaccionPropia then
      begin
        FConexion.Commit;
      end;
    except
      if bTransaccionPropia and FConexion.InTransaction then
      begin
        FConexion.Rollback;
      end;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
