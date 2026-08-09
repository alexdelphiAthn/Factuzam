{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataGen                                                    }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Base UniDAC para consultas y auditoría de mantenimientos.                 }
{******************************************************************************}
unit UniDataGen;

interface

uses
  System.Classes, Data.DB, Uni;

type
  TdmBase = class(TDataModule)
  private
    FConexion: TUniConnection;
    FConsulta: TUniQuery;
    FEsEditable: Boolean;
    procedure AntesDePublicar(DataSet: TDataSet);
  protected
    property Conexion: TUniConnection read FConexion;
    property Consulta: TUniQuery read FConsulta;
    procedure ConfigurarConsulta(const ASql: string);
    procedure ConfigurarEdicion(
      const ASqlInsertar, ASqlModificar, ASqlEliminar: string);
    procedure AplicarValoresIniciales(DataSet: TDataSet); virtual;
  public
    constructor Create(
      AOwner: TComponent;
      AConexion: TUniConnection;
      AEsEditable: Boolean = True); reintroduce; virtual;
    procedure Abrir; virtual;
    procedure Cerrar;
    property DataSet: TUniQuery read FConsulta;
  end;

implementation

uses
  System.SysUtils;

constructor TdmBase.Create(
  AOwner: TComponent;
  AConexion: TUniConnection;
  AEsEditable: Boolean);
begin
  if AConexion = nil then
  begin
    raise EArgumentNilException.Create('AConexion');
  end;
  inherited CreateNew(AOwner);
  FConexion := AConexion;
  FEsEditable := AEsEditable;
  FConsulta := TUniQuery.Create(Self);
  FConsulta.Connection := FConexion;
  FConsulta.ReadOnly := not FEsEditable;
  if FEsEditable then
  begin
    FConsulta.BeforePost := AntesDePublicar;
  end;
end;

procedure TdmBase.Abrir;
begin
  FConsulta.Open;
end;

procedure TdmBase.AntesDePublicar(DataSet: TDataSet);
begin
  if DataSet.State = dsInsert then
  begin
    AplicarValoresIniciales(DataSet);
    DataSet.FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    DataSet.FieldByName('USUARIO_ALTA').AsString :=
      GetEnvironmentVariable('USERNAME');
  end;
  DataSet.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
  DataSet.FieldByName('USUARIO_MODIF').AsString :=
    GetEnvironmentVariable('USERNAME');
end;

procedure TdmBase.AplicarValoresIniciales(DataSet: TDataSet);
begin
end;

procedure TdmBase.Cerrar;
begin
  FConsulta.Close;
end;

procedure TdmBase.ConfigurarConsulta(const ASql: string);
begin
  FConsulta.SQL.Text := ASql;
end;

procedure TdmBase.ConfigurarEdicion(
  const ASqlInsertar, ASqlModificar, ASqlEliminar: string);
begin
  FConsulta.SQLInsert.Text := ASqlInsertar;
  FConsulta.SQLUpdate.Text := ASqlModificar;
  FConsulta.SQLDelete.Text := ASqlEliminar;
end;

end.
