{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoEjercicios                                               }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Mantenimiento de ejercicios para la empresa activa.                       }
{******************************************************************************}
unit inMtoEjercicios;

interface

uses
  System.Classes, inMtoGen, inLibConfiguracion, Uni,
  UniDataEjercicios;

type
  TfrmMtoEjercicios = class(TfrmMtoGen)
  private
    FDataModule: TdmEjercicios;
  public
    destructor Destroy; override;
    procedure Inicializar(
      AConexion: TUniConnection;
      const AConfiguracion: TConfiguracionContazam); override;
  end;

implementation

uses
  System.SysUtils;

destructor TfrmMtoEjercicios.Destroy;
begin
  FreeAndNil(FDataModule);
  inherited;
end;

procedure TfrmMtoEjercicios.Inicializar(
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionContazam);
begin
  inherited;
  Caption := 'Ejercicios - ' + AConfiguracion.Empresa;
  FDataModule := TdmEjercicios.Create(
    nil,
    AConexion,
    AConfiguracion.Empresa);
  AsignarDataSet(FDataModule.DataSet);
  FDataModule.Abrir;
  AjustarVistaPrincipal;
  LblEstado.Caption :=
    'Cada ejercicio crea su contador de asientos al guardarse.';
end;

end.
