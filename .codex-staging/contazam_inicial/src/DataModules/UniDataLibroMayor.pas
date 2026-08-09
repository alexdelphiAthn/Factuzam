{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataLibroMayor                                             }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Consulta parametrizada de movimientos y saldos del libro mayor.           }
{******************************************************************************}
unit UniDataLibroMayor;

interface

uses
  System.Classes, System.SysUtils, Uni, UniDataGen;

type
  TdmLibroMayor = class(TdmBase)
  private
    FEmpresa: string;
    FEjercicio: Integer;
  public
    constructor Create(
      AOwner: TComponent;
      AConexion: TUniConnection;
      const AEmpresa: string;
      AEjercicio: Integer); reintroduce;
    procedure Consultar(
      AFechaDesde: TDate;
      AFechaHasta: TDate;
      const ACuenta: string);
  end;

implementation

constructor TdmLibroMayor.Create(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AEmpresa: string;
  AEjercicio: Integer);
begin
  inherited Create(AOwner, AConexion, False);
  FEmpresa := AEmpresa;
  FEjercicio := AEjercicio;
  ConfigurarConsulta(
    'SELECT CODIGO_EMP_MAY, EJERCICIO_MAY, CODIGO_CTA_MAY, ' +
    '       NOMBRE_CTA_MAY, FECHA_MAY, NUMERO_ASI_MAY, ' +
    '       LINEA_ASILIN_MAY, CONCEPTO_MAY, DOCUMENTO_MAY, ' +
    '       IMPORTE_DEBE_MAY, IMPORTE_HABER_MAY, ' +
    '       SALDO_ACUMULADO_MAY ' +
    '  FROM VI_CZA_LIBRO_MAYOR ' +
    ' WHERE CODIGO_EMP_MAY = :EMPRESA ' +
    '   AND EJERCICIO_MAY = :EJERCICIO ' +
    '   AND FECHA_MAY BETWEEN :DESDE AND :HASTA ' +
    '   AND (:CUENTA = '''' OR CODIGO_CTA_MAY LIKE CONCAT(:CUENTA, ''%'')) ' +
    ' ORDER BY CODIGO_CTA_MAY, FECHA_MAY, NUMERO_ASI_MAY, ' +
    '          LINEA_ASILIN_MAY');
end;

procedure TdmLibroMayor.Consultar(
  AFechaDesde: TDate;
  AFechaHasta: TDate;
  const ACuenta: string);
begin
  DataSet.Close;
  DataSet.ParamByName('EMPRESA').AsString := FEmpresa;
  DataSet.ParamByName('EJERCICIO').AsInteger := FEjercicio;
  DataSet.ParamByName('DESDE').AsDate := AFechaDesde;
  DataSet.ParamByName('HASTA').AsDate := AFechaHasta;
  DataSet.ParamByName('CUENTA').AsString := Trim(ACuenta);
  DataSet.Open;
end;

end.

