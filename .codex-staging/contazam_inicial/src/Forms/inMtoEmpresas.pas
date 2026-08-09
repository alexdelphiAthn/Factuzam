{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoEmpresas                                                 }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Mantenimiento de empresas y su correspondencia con Factuzam.              }
{******************************************************************************}
unit inMtoEmpresas;

interface

uses
  System.Classes, inMtoGen, inLibConfiguracion, Uni, UniDataEmpresas;

type
  TfrmMtoEmpresas = class(TfrmMtoGen)
  private
    FDataModule: TdmEmpresas;
  public
    destructor Destroy; override;
    procedure Inicializar(
      AConexion: TUniConnection;
      const AConfiguracion: TConfiguracionContazam); override;
  end;

implementation

uses
  System.SysUtils;

destructor TfrmMtoEmpresas.Destroy;
begin
  FreeAndNil(FDataModule);
  inherited;
end;

procedure TfrmMtoEmpresas.Inicializar(
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionContazam);
begin
  inherited;
  Caption := 'Empresas';
  FDataModule := TdmEmpresas.Create(nil, AConexion);
  AsignarDataSet(FDataModule.DataSet);
  FDataModule.Abrir;
  AjustarVistaPrincipal;
  LblEstado.Caption :=
    'Reinicia Contazam para actualizar el selector tras añadir una empresa.';
end;

end.

