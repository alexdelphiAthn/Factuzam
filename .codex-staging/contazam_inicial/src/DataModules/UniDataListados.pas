{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataListados                                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Consultas parametrizadas para los listados contables básicos.            }
{******************************************************************************}
unit UniDataListados;

interface

uses
  System.Classes, Data.DB, Uni, UniDataGen, inLibListadosTipos;

type
  TdmListados = class(TdmBase)
  private
    FEmpresa: string;
    FEjercicio: Integer;
    procedure ConfigurarBalance;
    procedure ConfigurarBorradores;
    procedure ConfigurarDiario;
    procedure ConfigurarDocumentos;
    procedure ConfigurarMayor;
    procedure ConfigurarEtiquetas;
    procedure PrepararParametros(
      AFechaDesde: TDate;
      AFechaHasta: TDate;
      const ACuenta: string);
  public
    constructor Create(
      AOwner: TComponent;
      AConexion: TUniConnection;
      const AEmpresa: string;
      AEjercicio: Integer); reintroduce;
    procedure Consultar(
      ATipo: TTipoListadoContable;
      AFechaDesde: TDate;
      AFechaHasta: TDate;
      const ACuenta: string);
  end;

implementation

uses
  System.SysUtils;

constructor TdmListados.Create(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AEmpresa: string;
  AEjercicio: Integer);
begin
  inherited Create(AOwner, AConexion, False);
  FEmpresa := AEmpresa;
  FEjercicio := AEjercicio;
end;

procedure TdmListados.ConfigurarBalance;
begin
  ConfigurarConsulta(
    'SELECT L.CODIGO_CTA_ASILIN AS CUENTA, C.NOMBRE_CTA AS NOMBRE, ' +
    'SUM(L.IMPORTE_DEBE_ASILIN) AS SUMA_DEBE, ' +
    'SUM(L.IMPORTE_HABER_ASILIN) AS SUMA_HABER, ' +
    'GREATEST(SUM(L.IMPORTE_DEBE_ASILIN - ' +
    'L.IMPORTE_HABER_ASILIN), 0) AS SALDO_DEUDOR, ' +
    'GREATEST(SUM(L.IMPORTE_HABER_ASILIN - ' +
    'L.IMPORTE_DEBE_ASILIN), 0) AS SALDO_ACREEDOR ' +
    'FROM cza_asientos A JOIN cza_asientos_lineas L ' +
    'ON L.ID_ASI_ASILIN = A.ID_ASI JOIN cza_cuentas C ' +
    'ON C.CODIGO_EMP_CTA = A.CODIGO_EMP_ASI ' +
    'AND C.EJERCICIO_CTA = A.EJERCICIO_ASI ' +
    'AND C.CODIGO_CTA = L.CODIGO_CTA_ASILIN ' +
    'WHERE A.CODIGO_EMP_ASI = :EMPRESA ' +
    'AND A.EJERCICIO_ASI = :EJERCICIO ' +
    'AND A.ESTADO_ASI = ''CERRADO'' ' +
    'AND A.FECHA_ASI BETWEEN :DESDE AND :HASTA ' +
    'AND (:CUENTA = '''' OR L.CODIGO_CTA_ASILIN ' +
    'LIKE CONCAT(:CUENTA, ''%'')) ' +
    'GROUP BY L.CODIGO_CTA_ASILIN, C.NOMBRE_CTA ' +
    'ORDER BY L.CODIGO_CTA_ASILIN');
end;

procedure TdmListados.ConfigurarBorradores;
begin
  ConfigurarConsulta(
    'SELECT A.NUMERO_ASI AS NUMERO, A.FECHA_ASI AS FECHA, ' +
    'A.CONCEPTO_ASI AS CONCEPTO, A.SISTEMA_ORIGEN_ASI AS ORIGEN, ' +
    'COUNT(L.ID_ASILIN) AS APUNTES, ' +
    'COALESCE(SUM(L.IMPORTE_DEBE_ASILIN), 0) AS TOTAL_DEBE, ' +
    'COALESCE(SUM(L.IMPORTE_HABER_ASILIN), 0) AS TOTAL_HABER, ' +
    'COALESCE(SUM(L.IMPORTE_DEBE_ASILIN - ' +
    'L.IMPORTE_HABER_ASILIN), 0) AS DIFERENCIA ' +
    'FROM cza_asientos A LEFT JOIN cza_asientos_lineas L ' +
    'ON L.ID_ASI_ASILIN = A.ID_ASI ' +
    'WHERE A.CODIGO_EMP_ASI = :EMPRESA ' +
    'AND A.EJERCICIO_ASI = :EJERCICIO ' +
    'AND A.ESTADO_ASI = ''BORRADOR'' ' +
    'AND A.FECHA_ASI BETWEEN :DESDE AND :HASTA ' +
    'AND (:CUENTA = '''' OR EXISTS (SELECT 1 ' +
    'FROM cza_asientos_lineas LF WHERE LF.ID_ASI_ASILIN = A.ID_ASI ' +
    'AND LF.CODIGO_CTA_ASILIN LIKE CONCAT(:CUENTA, ''%''))) ' +
    'GROUP BY A.ID_ASI, A.NUMERO_ASI, A.FECHA_ASI, ' +
    'A.CONCEPTO_ASI, A.SISTEMA_ORIGEN_ASI ' +
    'ORDER BY A.FECHA_ASI, A.NUMERO_ASI');
end;

procedure TdmListados.ConfigurarDiario;
begin
  ConfigurarConsulta(
    'SELECT NUMERO_ASI_DIA AS NUMERO, FECHA_DIA AS FECHA, ' +
    'LINEA_ASILIN_DIA AS LINEA, CODIGO_CTA_DIA AS CUENTA, ' +
    'NOMBRE_CTA_DIA AS NOMBRE, CONCEPTO_DIA AS CONCEPTO, ' +
    'DOCUMENTO_DIA AS DOCUMENTO, IMPORTE_DEBE_DIA AS DEBE, ' +
    'IMPORTE_HABER_DIA AS HABER FROM VI_CZA_LIBRO_DIARIO ' +
    'WHERE CODIGO_EMP_DIA = :EMPRESA ' +
    'AND EJERCICIO_DIA = :EJERCICIO ' +
    'AND FECHA_DIA BETWEEN :DESDE AND :HASTA ' +
    'AND (:CUENTA = '''' OR CODIGO_CTA_DIA ' +
    'LIKE CONCAT(:CUENTA, ''%'')) ' +
    'ORDER BY FECHA_DIA, NUMERO_ASI_DIA, LINEA_ASILIN_DIA');
end;

procedure TdmListados.ConfigurarDocumentos;
begin
  ConfigurarConsulta(
    'SELECT ''ARCHIVADO'' AS ESTADO, D.REFERENCIA_DOC AS REFERENCIA, ' +
    'D.TIPO_DOC AS TIPO, D.FECHA_DOC AS FECHA, ' +
    'D.DESCRIPCION_DOC AS DESCRIPCION, ' +
    'D.NOMBRE_ARCHIVO_DOC AS ARCHIVO, D.TAMANO_DOC AS BYTES, ' +
    'D.SHA256_DOC AS SHA256 FROM cza_documentos D ' +
    'WHERE D.CODIGO_EMP_DOC = :EMPRESA ' +
    'AND D.EJERCICIO_DOC = :EJERCICIO ' +
    'AND COALESCE(D.FECHA_DOC, :DESDE) BETWEEN :DESDE AND :HASTA ' +
    'UNION ALL SELECT DISTINCT ''REFERENCIA SIN PDF'', ' +
    'L.DOCUMENTO_ASILIN, ' +
    '''APUNTE'', A.FECHA_ASI, ' +
    'COALESCE(L.CONCEPTO_ASILIN, A.CONCEPTO_ASI), NULL, 0, NULL ' +
    'FROM cza_asientos A JOIN cza_asientos_lineas L ' +
    'ON L.ID_ASI_ASILIN = A.ID_ASI LEFT JOIN cza_documentos D ' +
    'ON D.CODIGO_EMP_DOC = A.CODIGO_EMP_ASI ' +
    'AND D.EJERCICIO_DOC = A.EJERCICIO_ASI ' +
    'AND D.REFERENCIA_DOC = L.DOCUMENTO_ASILIN ' +
    'WHERE A.CODIGO_EMP_ASI = :EMPRESA ' +
    'AND A.EJERCICIO_ASI = :EJERCICIO ' +
    'AND A.FECHA_ASI BETWEEN :DESDE AND :HASTA ' +
    'AND COALESCE(L.DOCUMENTO_ASILIN, '''') <> '''' ' +
    'AND D.ID_DOC IS NULL ' +
    'AND (:CUENTA = '''' OR L.CODIGO_CTA_ASILIN ' +
    'LIKE CONCAT(:CUENTA, ''%'')) ' +
    'ORDER BY FECHA, REFERENCIA');
end;

procedure TdmListados.ConfigurarEtiquetas;
var
  oCampo: TField;
begin
  for oCampo in DataSet.Fields do
  begin
    oCampo.DisplayLabel := StringReplace(
      oCampo.FieldName,
      '_',
      ' ',
      [rfReplaceAll]);
    if oCampo.DataType in [ftFloat, ftCurrency, ftBCD, ftFMTBcd] then
    begin
      TNumericField(oCampo).DisplayFormat := '#,##0.00;[Red]-#,##0.00';
    end;
  end;
end;

procedure TdmListados.ConfigurarMayor;
begin
  ConfigurarConsulta(
    'SELECT CODIGO_CTA_MAY AS CUENTA, NOMBRE_CTA_MAY AS NOMBRE, ' +
    'FECHA_MAY AS FECHA, NUMERO_ASI_MAY AS NUMERO, ' +
    'LINEA_ASILIN_MAY AS LINEA, CONCEPTO_MAY AS CONCEPTO, ' +
    'DOCUMENTO_MAY AS DOCUMENTO, IMPORTE_DEBE_MAY AS DEBE, ' +
    'IMPORTE_HABER_MAY AS HABER, ' +
    'SALDO_ACUMULADO_MAY AS SALDO_ACUMULADO ' +
    'FROM VI_CZA_LIBRO_MAYOR WHERE CODIGO_EMP_MAY = :EMPRESA ' +
    'AND EJERCICIO_MAY = :EJERCICIO ' +
    'AND FECHA_MAY BETWEEN :DESDE AND :HASTA ' +
    'AND (:CUENTA = '''' OR CODIGO_CTA_MAY ' +
    'LIKE CONCAT(:CUENTA, ''%'')) ' +
    'ORDER BY CODIGO_CTA_MAY, FECHA_MAY, ' +
    'NUMERO_ASI_MAY, LINEA_ASILIN_MAY');
end;

procedure TdmListados.Consultar(
  ATipo: TTipoListadoContable;
  AFechaDesde: TDate;
  AFechaHasta: TDate;
  const ACuenta: string);
begin
  DataSet.Close;
  case ATipo of
    tlBalanceSumasSaldos:
      ConfigurarBalance;
    tlLibroDiario:
      ConfigurarDiario;
    tlLibroMayor:
      ConfigurarMayor;
    tlAsientosBorrador:
      ConfigurarBorradores;
    tlArchivoDocumental:
      ConfigurarDocumentos;
  end;
  PrepararParametros(AFechaDesde, AFechaHasta, ACuenta);
  DataSet.Open;
  ConfigurarEtiquetas;
end;

procedure TdmListados.PrepararParametros(
  AFechaDesde: TDate;
  AFechaHasta: TDate;
  const ACuenta: string);
begin
  DataSet.ParamByName('EMPRESA').AsString := FEmpresa;
  DataSet.ParamByName('EJERCICIO').AsInteger := FEjercicio;
  DataSet.ParamByName('DESDE').AsDate := AFechaDesde;
  DataSet.ParamByName('HASTA').AsDate := AFechaHasta;
  if DataSet.Params.FindParam('CUENTA') <> nil then
  begin
    DataSet.ParamByName('CUENTA').AsString := Trim(ACuenta);
  end;
end;

end.
