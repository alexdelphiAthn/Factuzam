{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPlanContable                                           }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Persistencia del árbol de cuentas contables por empresa y ejercicio.      }
{******************************************************************************}
unit UniDataPlanContable;

interface

uses
  System.Classes, Data.DB, Uni, UniDataGen;

type
  TdmPlanContable = class(TdmBase)
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
    procedure CargarModeloPymes;
  end;

implementation

uses
  System.SysUtils;

constructor TdmPlanContable.Create(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AEmpresa: string;
  AEjercicio: Integer);
begin
  inherited Create(AOwner, AConexion, True);
  FEmpresa := AEmpresa;
  FEjercicio := AEjercicio;
  ConfigurarConsulta(
    'SELECT CODIGO_EMP_CTA, EJERCICIO_CTA, CODIGO_CTA, ' +
    '       CODIGO_CTA_PADRE_CTA, NOMBRE_CTA, NIVEL_CTA, ' +
    '       TIPO_CTA, NATURALEZA_CTA, ESIMPUTABLE_CTA, ' +
    '       ESACTIVO_CTA, ORDEN_CTA, INSTANTE_ALTA, ' +
    '       USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF ' +
    '  FROM cza_cuentas ' +
    ' WHERE CODIGO_EMP_CTA = :EMPRESA ' +
    '   AND EJERCICIO_CTA = :EJERCICIO ' +
    ' ORDER BY LENGTH(CODIGO_CTA), ORDEN_CTA, CODIGO_CTA');
  ConfigurarEdicion(
    'INSERT INTO cza_cuentas (' +
    'CODIGO_EMP_CTA, EJERCICIO_CTA, CODIGO_CTA, ' +
    'CODIGO_CTA_PADRE_CTA, NOMBRE_CTA, NIVEL_CTA, TIPO_CTA, ' +
    'NATURALEZA_CTA, ESIMPUTABLE_CTA, ESACTIVO_CTA, ORDEN_CTA, ' +
    'INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
    'VALUES (:CODIGO_EMP_CTA, :EJERCICIO_CTA, :CODIGO_CTA, ' +
    ':CODIGO_CTA_PADRE_CTA, :NOMBRE_CTA, :NIVEL_CTA, :TIPO_CTA, ' +
    ':NATURALEZA_CTA, :ESIMPUTABLE_CTA, :ESACTIVO_CTA, :ORDEN_CTA, ' +
    ':INSTANTE_ALTA, :USUARIO_ALTA, :INSTANTE_MODIF, :USUARIO_MODIF)',
    'UPDATE cza_cuentas SET ' +
    'CODIGO_CTA_PADRE_CTA = :CODIGO_CTA_PADRE_CTA, ' +
    'NOMBRE_CTA = :NOMBRE_CTA, NIVEL_CTA = :NIVEL_CTA, ' +
    'TIPO_CTA = :TIPO_CTA, NATURALEZA_CTA = :NATURALEZA_CTA, ' +
    'ESIMPUTABLE_CTA = :ESIMPUTABLE_CTA, ESACTIVO_CTA = :ESACTIVO_CTA, ' +
    'ORDEN_CTA = :ORDEN_CTA, INSTANTE_MODIF = :INSTANTE_MODIF, ' +
    'USUARIO_MODIF = :USUARIO_MODIF ' +
    'WHERE CODIGO_EMP_CTA = :Old_CODIGO_EMP_CTA ' +
    'AND EJERCICIO_CTA = :Old_EJERCICIO_CTA ' +
    'AND CODIGO_CTA = :Old_CODIGO_CTA',
    'DELETE FROM cza_cuentas ' +
    'WHERE CODIGO_EMP_CTA = :Old_CODIGO_EMP_CTA ' +
    'AND EJERCICIO_CTA = :Old_EJERCICIO_CTA ' +
    'AND CODIGO_CTA = :Old_CODIGO_CTA');
end;

procedure TdmPlanContable.Abrir;
begin
  DataSet.ParamByName('EMPRESA').AsString := FEmpresa;
  DataSet.ParamByName('EJERCICIO').AsInteger := FEjercicio;
  inherited;
end;

procedure TdmPlanContable.CargarModeloPymes;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := Conexion;
    Conexion.StartTransaction;
    try
      oConsulta.SQL.Text :=
        'INSERT IGNORE INTO cza_cuentas (' +
        'CODIGO_EMP_CTA, EJERCICIO_CTA, CODIGO_CTA, ' +
        'CODIGO_CTA_PADRE_CTA, NOMBRE_CTA, NIVEL_CTA, TIPO_CTA, ' +
        'NATURALEZA_CTA, ESIMPUTABLE_CTA, ESACTIVO_CTA, ORDEN_CTA, ' +
        'INSTANTE_ALTA, USUARIO_ALTA) ' +
        'SELECT :EMPRESA, :EJERCICIO, CODIGO_MOD, ' +
        'CODIGO_PADRE_MOD, NOMBRE_MOD, NIVEL_MOD, TIPO_MOD, ' +
        'NATURALEZA_MOD, ESIMPUTABLE_MOD, ''S'', ORDEN_MOD, ' +
        'NOW(), :USUARIO FROM cza_cuentas_modelo ' +
        'WHERE ESACTIVO_MOD = ''S''';
      oConsulta.ParamByName('EMPRESA').AsString := FEmpresa;
      oConsulta.ParamByName('EJERCICIO').AsInteger := FEjercicio;
      oConsulta.ParamByName('USUARIO').AsString :=
        GetEnvironmentVariable('USERNAME');
      oConsulta.ExecSQL;
      oConsulta.SQL.Text :=
        'INSERT IGNORE INTO cza_mapeos_contables (' +
        'CODIGO_EMP_MAP, EJERCICIO_MAP, ROL_MAP, CODIGO_CTA_MAP, ' +
        'ESACTIVO_MAP, INSTANTE_ALTA, USUARIO_ALTA) VALUES ' +
        '(:EMPRESA, :EJERCICIO, ''CLIENTES'', ''430000000000'', ' +
        '''S'', NOW(), :USUARIO), ' +
        '(:EMPRESA, :EJERCICIO, ''RETENCIONES'', ''473000000000'', ' +
        '''S'', NOW(), :USUARIO), ' +
        '(:EMPRESA, :EJERCICIO, ''VENTAS'', ''700000000000'', ' +
        '''S'', NOW(), :USUARIO), ' +
        '(:EMPRESA, :EJERCICIO, ''IVA_REPERCUTIDO'', ' +
        '''477000000000'', ''S'', NOW(), :USUARIO)';
      oConsulta.ParamByName('EMPRESA').AsString := FEmpresa;
      oConsulta.ParamByName('EJERCICIO').AsInteger := FEjercicio;
      oConsulta.ParamByName('USUARIO').AsString :=
        GetEnvironmentVariable('USERNAME');
      oConsulta.ExecSQL;
      oConsulta.SQL.Text :=
        'INSERT IGNORE INTO cza_reglas_contrapartida (' +
        'CODIGO_EMP_REG, EJERCICIO_REG, PREFIJO_ORIGEN_REG, ' +
        'PREFIJO_DESTINO_REG, PRIORIDAD_REG, ESACTIVO_REG, ' +
        'INSTANTE_ALTA, USUARIO_ALTA) ' +
        'SELECT :EMPRESA, :EJERCICIO, PREFIJO_ORIGEN_REG, ' +
        'PREFIJO_DESTINO_REG, PRIORIDAD_REG, ''S'', NOW(), :USUARIO ' +
        'FROM cza_reglas_contrapartida ' +
        'WHERE CODIGO_EMP_REG = ''001'' ' +
        'AND EJERCICIO_REG = YEAR(CURDATE())';
      oConsulta.ParamByName('EMPRESA').AsString := FEmpresa;
      oConsulta.ParamByName('EJERCICIO').AsInteger := FEjercicio;
      oConsulta.ParamByName('USUARIO').AsString :=
        GetEnvironmentVariable('USERNAME');
      oConsulta.ExecSQL;
      Conexion.Commit;
    except
      if Conexion.InTransaction then
      begin
        Conexion.Rollback;
      end;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
  DataSet.Close;
  Abrir;
end;

procedure TdmPlanContable.AplicarValoresIniciales(DataSet: TDataSet);
begin
  inherited;
  DataSet.FieldByName('CODIGO_EMP_CTA').AsString := FEmpresa;
  DataSet.FieldByName('EJERCICIO_CTA').AsInteger := FEjercicio;
  DataSet.FieldByName('NIVEL_CTA').AsInteger := 4;
  DataSet.FieldByName('TIPO_CTA').AsString := 'SUBCUENTA';
  DataSet.FieldByName('NATURALEZA_CTA').AsString := 'D';
  DataSet.FieldByName('ESIMPUTABLE_CTA').AsString := 'S';
  DataSet.FieldByName('ESACTIVO_CTA').AsString := 'S';
end;

end.
