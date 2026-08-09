{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataContadores                                             }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Mantenimiento de numeradores contables por ejercicio y serie.             }
{******************************************************************************}
unit UniDataContadores;

interface

uses
  System.Classes, Data.DB, Uni, UniDataGen;

type
  TdmContadores = class(TdmBase)
  private
    FEmpresa: string;
    FEjercicio: Integer;
  protected
    procedure AplicarValoresIniciales(DataSet: TDataSet); override;
  public
    constructor Create(
      AOwner: TComponent;
      AConexion: TUniConnection;
      const AEmpresa: string;
      AEjercicio: Integer); reintroduce;
    procedure Abrir; override;
  end;

implementation

constructor TdmContadores.Create(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AEmpresa: string;
  AEjercicio: Integer);
begin
  inherited Create(AOwner, AConexion, True);
  FEmpresa := AEmpresa;
  FEjercicio := AEjercicio;
  ConfigurarConsulta(
    'SELECT TIPO_DOCUMENTO_CON, CODIGO_EMP_CON, EJERCICIO_CON, ' +
    '       SERIE_CON, CONTADOR_CON, NUMERO_CEROS_CON, ' +
    '       NUMERO_DIGITOS_CON, ' +
    '       ESACTIVO_CON, ESDEFECTO_CON, INSTANTE_ALTA, ' +
    '       USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF ' +
    '  FROM cza_contadores ' +
    ' WHERE CODIGO_EMP_CON = :EMPRESA ' +
    '   AND EJERCICIO_CON = :EJERCICIO ' +
    ' ORDER BY TIPO_DOCUMENTO_CON, SERIE_CON');
  ConfigurarEdicion(
    'INSERT INTO cza_contadores (' +
    'TIPO_DOCUMENTO_CON, CODIGO_EMP_CON, EJERCICIO_CON, SERIE_CON, ' +
    'CONTADOR_CON, NUMERO_DIGITOS_CON, ESACTIVO_CON, ESDEFECTO_CON, ' +
    'INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
    'VALUES (:TIPO_DOCUMENTO_CON, :CODIGO_EMP_CON, :EJERCICIO_CON, ' +
    ':SERIE_CON, :CONTADOR_CON, :NUMERO_DIGITOS_CON, :ESACTIVO_CON, ' +
    ':ESDEFECTO_CON, :INSTANTE_ALTA, :USUARIO_ALTA, ' +
    ':INSTANTE_MODIF, :USUARIO_MODIF)',
    'UPDATE cza_contadores SET CONTADOR_CON = :CONTADOR_CON, ' +
    'NUMERO_DIGITOS_CON = :NUMERO_DIGITOS_CON, ' +
    'ESACTIVO_CON = :ESACTIVO_CON, ESDEFECTO_CON = :ESDEFECTO_CON, ' +
    'INSTANTE_MODIF = :INSTANTE_MODIF, USUARIO_MODIF = :USUARIO_MODIF ' +
    'WHERE TIPO_DOCUMENTO_CON = :Old_TIPO_DOCUMENTO_CON ' +
    'AND CODIGO_EMP_CON = :Old_CODIGO_EMP_CON ' +
    'AND EJERCICIO_CON = :Old_EJERCICIO_CON ' +
    'AND SERIE_CON = :Old_SERIE_CON',
    'DELETE FROM cza_contadores ' +
    'WHERE TIPO_DOCUMENTO_CON = :Old_TIPO_DOCUMENTO_CON ' +
    'AND CODIGO_EMP_CON = :Old_CODIGO_EMP_CON ' +
    'AND EJERCICIO_CON = :Old_EJERCICIO_CON ' +
    'AND SERIE_CON = :Old_SERIE_CON');
end;

procedure TdmContadores.Abrir;
begin
  DataSet.ParamByName('EMPRESA').AsString := FEmpresa;
  DataSet.ParamByName('EJERCICIO').AsInteger := FEjercicio;
  inherited;
end;

procedure TdmContadores.AplicarValoresIniciales(DataSet: TDataSet);
begin
  inherited;
  DataSet.FieldByName('CODIGO_EMP_CON').AsString := FEmpresa;
  DataSet.FieldByName('EJERCICIO_CON').AsInteger := FEjercicio;
  DataSet.FieldByName('SERIE_CON').AsString := '-';
  DataSet.FieldByName('CONTADOR_CON').AsString := '00000000';
  DataSet.FieldByName('NUMERO_DIGITOS_CON').AsInteger := 8;
  DataSet.FieldByName('ESACTIVO_CON').AsString := 'S';
  DataSet.FieldByName('ESDEFECTO_CON').AsString := 'N';
end;

end.
