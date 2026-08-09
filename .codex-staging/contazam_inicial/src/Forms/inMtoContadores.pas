{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoContadores                                               }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Pantalla para mantener los numeradores de Contazam.                       }
{******************************************************************************}
unit inMtoContadores;

interface

uses
  System.Classes, inMtoGen, inLibConfiguracion, Uni,
  UniDataContadores;

type
  TfrmMtoContadores = class(TfrmMtoGen)
  private
    FDataModule: TdmContadores;
  public
    destructor Destroy; override;
    procedure Inicializar(
      AConexion: TUniConnection;
      const AConfiguracion: TConfiguracionContazam); override;
  end;

implementation

uses
  System.SysUtils;

destructor TfrmMtoContadores.Destroy;
begin
  FreeAndNil(FDataModule);
  inherited;
end;

procedure TfrmMtoContadores.Inicializar(
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionContazam);
begin
  inherited;
  Caption := 'Contadores';
  FDataModule := TdmContadores.Create(
    nil,
    AConexion,
    AConfiguracion.Empresa,
    AConfiguracion.Ejercicio);
  AsignarDataSet(FDataModule.DataSet);
  FDataModule.Abrir;
  AjustarVistaPrincipal;
  LblEstado.Caption :=
    'Numeración segura por empresa, ejercicio, documento y serie.';
end;

end.
