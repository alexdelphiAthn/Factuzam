{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataEjercicios                                             }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Persistencia de ejercicios y creación de su contador inicial.             }
{******************************************************************************}
unit UniDataEjercicios;

interface

uses
  System.Classes, Data.DB, Uni, UniDataGen;

type
  TdmEjercicios = class(TdmBase)
  private
    FEmpresa: string;
    procedure DespuesDePublicar(DataSet: TDataSet);
    procedure AsegurarContadorAsientos(AEjercicio: Integer);
  protected
    procedure AplicarValoresIniciales(DataSet: TDataSet); override;
  public
    constructor Create(
      AOwner: TComponent;
      AConexion: TUniConnection;
      const AEmpresa: string); reintroduce;
    procedure Abrir; override;
  end;

implementation

uses
  System.SysUtils, System.DateUtils;

constructor TdmEjercicios.Create(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AEmpresa: string);
begin
  inherited Create(AOwner, AConexion, True);
  FEmpresa := AEmpresa;
  ConfigurarConsulta(
    'SELECT CODIGO_EMP_EJE, EJERCICIO_EJE, FECHA_INICIO_EJE, ' +
    '       FECHA_FIN_EJE, ESTADO_EJE, ESACTIVO_EJE, ' +
    '       INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF ' +
    '  FROM cza_ejercicios WHERE CODIGO_EMP_EJE = :EMPRESA ' +
    ' ORDER BY EJERCICIO_EJE DESC');
  ConfigurarEdicion(
    'INSERT INTO cza_ejercicios (' +
    'CODIGO_EMP_EJE, EJERCICIO_EJE, FECHA_INICIO_EJE, FECHA_FIN_EJE, ' +
    'ESTADO_EJE, ESACTIVO_EJE, INSTANTE_ALTA, USUARIO_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_MODIF) VALUES (' +
    ':CODIGO_EMP_EJE, :EJERCICIO_EJE, :FECHA_INICIO_EJE, ' +
    ':FECHA_FIN_EJE, :ESTADO_EJE, :ESACTIVO_EJE, :INSTANTE_ALTA, ' +
    ':USUARIO_ALTA, :INSTANTE_MODIF, :USUARIO_MODIF)',
    'UPDATE cza_ejercicios SET FECHA_INICIO_EJE = :FECHA_INICIO_EJE, ' +
    'FECHA_FIN_EJE = :FECHA_FIN_EJE, ESTADO_EJE = :ESTADO_EJE, ' +
    'ESACTIVO_EJE = :ESACTIVO_EJE, INSTANTE_MODIF = :INSTANTE_MODIF, ' +
    'USUARIO_MODIF = :USUARIO_MODIF ' +
    'WHERE CODIGO_EMP_EJE = :Old_CODIGO_EMP_EJE ' +
    'AND EJERCICIO_EJE = :Old_EJERCICIO_EJE',
    'DELETE FROM cza_ejercicios ' +
    'WHERE CODIGO_EMP_EJE = :Old_CODIGO_EMP_EJE ' +
    'AND EJERCICIO_EJE = :Old_EJERCICIO_EJE');
  DataSet.AfterPost := DespuesDePublicar;
end;

procedure TdmEjercicios.Abrir;
begin
  DataSet.ParamByName('EMPRESA').AsString := FEmpresa;
  inherited;
end;

procedure TdmEjercicios.AplicarValoresIniciales(DataSet: TDataSet);
var
  iEjercicio: Integer;
begin
  inherited;
  iEjercicio := YearOf(Date);
  DataSet.FieldByName('CODIGO_EMP_EJE').AsString := FEmpresa;
  DataSet.FieldByName('EJERCICIO_EJE').AsInteger := iEjercicio;
  DataSet.FieldByName('FECHA_INICIO_EJE').AsDateTime :=
    EncodeDate(iEjercicio, 1, 1);
  DataSet.FieldByName('FECHA_FIN_EJE').AsDateTime :=
    EncodeDate(iEjercicio, 12, 31);
  DataSet.FieldByName('ESTADO_EJE').AsString := 'ABIERTO';
  DataSet.FieldByName('ESACTIVO_EJE').AsString := 'S';
end;

procedure TdmEjercicios.AsegurarContadorAsientos(AEjercicio: Integer);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := Conexion;
    oConsulta.SQL.Text :=
      'INSERT IGNORE INTO cza_contadores (' +
      'TIPO_DOCUMENTO_CON, CODIGO_EMP_CON, EJERCICIO_CON, SERIE_CON, ' +
      'CONTADOR_CON, NUMERO_DIGITOS_CON, ESACTIVO_CON, ESDEFECTO_CON, ' +
      'INSTANTE_ALTA, USUARIO_ALTA) VALUES (' +
      '''ASIENTO'', :EMPRESA, :EJERCICIO, ''-'', 0, 8, ''S'', ''S'', ' +
      'NOW(), :USUARIO)';
    oConsulta.ParamByName('EMPRESA').AsString := FEmpresa;
    oConsulta.ParamByName('EJERCICIO').AsInteger := AEjercicio;
    oConsulta.ParamByName('USUARIO').AsString :=
      GetEnvironmentVariable('USERNAME');
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TdmEjercicios.DespuesDePublicar(DataSet: TDataSet);
begin
  AsegurarContadorAsientos(
    DataSet.FieldByName('EJERCICIO_EJE').AsInteger);
end;

end.

