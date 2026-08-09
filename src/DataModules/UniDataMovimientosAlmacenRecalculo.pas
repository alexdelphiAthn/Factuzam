{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataMovimientosAlmacenRecalculo                            }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerta única al recálculo cronológico de stock y PMP.                     }
{******************************************************************************}
unit UniDataMovimientosAlmacenRecalculo;

interface

uses
  Uni;

procedure RecalcularMovimientosDocumento(
  AConexion: TUniConnection;
  const ATipo, ASerie, ANumero: string);
procedure FecharYRecalcularMovimientosDocumento(
  AConexion: TUniConnection;
  const ATipo, ASerie, ANumero: string;
  AFecha: TDateTime);
procedure RecalcularMovimientosOperacion(
  AConexion: TUniConnection;
  const AOperacion: string);
procedure RecalcularMovimiento(
  AConexion: TUniConnection;
  const ANumeroMovimiento: string);

implementation

uses
  System.SysUtils,
  Data.DB;

function ProcedimientoDisponible(
  AConexion: TUniConnection;
  const ANombre: string): Boolean;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'SELECT COUNT(*) AS TOTAL ' +
      '  FROM information_schema.ROUTINES ' +
      ' WHERE ROUTINE_SCHEMA = DATABASE() ' +
      '   AND ROUTINE_TYPE = ''PROCEDURE'' ' +
      '   AND ROUTINE_NAME = :NOMBRE';
    Consulta.ParamByName('NOMBRE').AsString := ANombre;
    Consulta.Open;
    Result := Consulta.FieldByName('TOTAL').AsInteger > 0;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure FecharYRecalcularMovimientosDocumento(
  AConexion: TUniConnection;
  const ATipo, ASerie, ANumero: string;
  AFecha: TDateTime);
var
  Consulta: TUniQuery;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'UPDATE fza_movimientos_almacen ' +
      '   SET FECHA_MOV = :FECHA ' +
      ' WHERE TIPO_DOC_MOV = :TIPO ' +
      '   AND SERIE_DOC_MOV = :SERIE ' +
      '   AND NUMERO_DOC_MOV = :NUMERO';
    Consulta.ParamByName('FECHA').AsDateTime := AFecha;
    Consulta.ParamByName('TIPO').AsString := ATipo;
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('NUMERO').AsString := ANumero;
    Consulta.ExecSQL;
  finally
    FreeAndNil(Consulta);
  end;
  RecalcularMovimientosDocumento(AConexion, ATipo, ASerie, ANumero);
end;

procedure RecalcularMovimientosDocumento(
  AConexion: TUniConnection;
  const ATipo, ASerie, ANumero: string);
var
  Procedimiento: TUniStoredProc;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if ProcedimientoDisponible(
    AConexion, 'PRC_FZA_MOVIMIENTOS_RECALCULAR_DOCUMENTO') then
  begin
    Procedimiento := TUniStoredProc.Create(nil);
    try
      Procedimiento.Connection := AConexion;
      Procedimiento.StoredProcName :=
        'PRC_FZA_MOVIMIENTOS_RECALCULAR_DOCUMENTO';
      Procedimiento.Params.Clear;
      Procedimiento.Params.CreateParam(ftString, 'p_TIPO', ptInput);
      Procedimiento.Params.CreateParam(ftString, 'p_SERIE', ptInput);
      Procedimiento.Params.CreateParam(ftString, 'p_NUMERO', ptInput);
      Procedimiento.ParamByName('p_TIPO').AsString := ATipo;
      Procedimiento.ParamByName('p_SERIE').AsString := ASerie;
      Procedimiento.ParamByName('p_NUMERO').AsString := ANumero;
      Procedimiento.ExecProc;
    finally
      FreeAndNil(Procedimiento);
    end;
  end;
end;

procedure RecalcularMovimientosOperacion(
  AConexion: TUniConnection;
  const AOperacion: string);
var
  Procedimiento: TUniStoredProc;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if Trim(AOperacion) = '' then
    raise EArgumentException.Create('AOperacion');
  if ProcedimientoDisponible(
    AConexion, 'PRC_FZA_MOVIMIENTOS_RECALCULAR_OPERACION') then
  begin
    Procedimiento := TUniStoredProc.Create(nil);
    try
      Procedimiento.Connection := AConexion;
      Procedimiento.StoredProcName :=
        'PRC_FZA_MOVIMIENTOS_RECALCULAR_OPERACION';
      Procedimiento.Params.Clear;
      Procedimiento.Params.CreateParam(ftString, 'p_OPERACION', ptInput);
      Procedimiento.ParamByName('p_OPERACION').AsString := AOperacion;
      Procedimiento.ExecProc;
    finally
      FreeAndNil(Procedimiento);
    end;
  end;
end;

procedure RecalcularMovimiento(
  AConexion: TUniConnection;
  const ANumeroMovimiento: string);
var
  Procedimiento: TUniStoredProc;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if Trim(ANumeroMovimiento) = '' then
    raise EArgumentException.Create('ANumeroMovimiento');
  if ProcedimientoDisponible(
    AConexion, 'PRC_FZA_MOVIMIENTOS_RECALCULAR_MOVIMIENTO') then
  begin
    Procedimiento := TUniStoredProc.Create(nil);
    try
      Procedimiento.Connection := AConexion;
      Procedimiento.StoredProcName :=
        'PRC_FZA_MOVIMIENTOS_RECALCULAR_MOVIMIENTO';
      Procedimiento.Params.Clear;
      Procedimiento.Params.CreateParam(ftString, 'p_NUMERO', ptInput);
      Procedimiento.ParamByName('p_NUMERO').AsString := ANumeroMovimiento;
      Procedimiento.ExecProc;
    finally
      FreeAndNil(Procedimiento);
    end;
  end;
end;

end.
