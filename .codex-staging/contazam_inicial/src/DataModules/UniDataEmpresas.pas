{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataEmpresas                                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Persistencia de las empresas gestionadas por Contazam.                    }
{******************************************************************************}
unit UniDataEmpresas;

interface

uses
  System.Classes, Data.DB, Uni, UniDataGen;

type
  TdmEmpresas = class(TdmBase)
  protected
    procedure AplicarValoresIniciales(DataSet: TDataSet); override;
  public
    constructor Create(
      AOwner: TComponent;
      AConexion: TUniConnection); reintroduce;
  end;

implementation

constructor TdmEmpresas.Create(
  AOwner: TComponent;
  AConexion: TUniConnection);
begin
  inherited Create(AOwner, AConexion, True);
  ConfigurarConsulta(
    'SELECT CODIGO_EMP, RAZON_SOCIAL_EMP, NIF_EMP, ORDEN_EMP, ' +
    '       ESACTIVO_EMP, CODIGO_EMP_FACTUZAM_EMP, ' +
    '       BASE_DATOS_FACTUZAM_EMP, INSTANTE_ALTA, USUARIO_ALTA, ' +
    '       INSTANTE_MODIF, USUARIO_MODIF ' +
    '  FROM cza_empresas ORDER BY ORDEN_EMP, CODIGO_EMP');
  ConfigurarEdicion(
    'INSERT INTO cza_empresas (' +
    'CODIGO_EMP, RAZON_SOCIAL_EMP, NIF_EMP, ORDEN_EMP, ESACTIVO_EMP, ' +
    'CODIGO_EMP_FACTUZAM_EMP, BASE_DATOS_FACTUZAM_EMP, ' +
    'INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
    'VALUES (:CODIGO_EMP, :RAZON_SOCIAL_EMP, :NIF_EMP, :ORDEN_EMP, ' +
    ':ESACTIVO_EMP, :CODIGO_EMP_FACTUZAM_EMP, ' +
    ':BASE_DATOS_FACTUZAM_EMP, :INSTANTE_ALTA, :USUARIO_ALTA, ' +
    ':INSTANTE_MODIF, :USUARIO_MODIF)',
    'UPDATE cza_empresas SET RAZON_SOCIAL_EMP = :RAZON_SOCIAL_EMP, ' +
    'NIF_EMP = :NIF_EMP, ORDEN_EMP = :ORDEN_EMP, ' +
    'ESACTIVO_EMP = :ESACTIVO_EMP, ' +
    'CODIGO_EMP_FACTUZAM_EMP = :CODIGO_EMP_FACTUZAM_EMP, ' +
    'BASE_DATOS_FACTUZAM_EMP = :BASE_DATOS_FACTUZAM_EMP, ' +
    'INSTANTE_MODIF = :INSTANTE_MODIF, USUARIO_MODIF = :USUARIO_MODIF ' +
    'WHERE CODIGO_EMP = :Old_CODIGO_EMP',
    'DELETE FROM cza_empresas WHERE CODIGO_EMP = :Old_CODIGO_EMP');
end;

procedure TdmEmpresas.AplicarValoresIniciales(DataSet: TDataSet);
begin
  inherited;
  DataSet.FieldByName('ESACTIVO_EMP').AsString := 'S';
  DataSet.FieldByName('BASE_DATOS_FACTUZAM_EMP').AsString := 'factuzam';
end;

end.

