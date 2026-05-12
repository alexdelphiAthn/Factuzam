{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVariaciones                                            }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de variaciones de artículos.                                  }
{    Mantenimiento de fza_variaciones, sus atributos, artículos vinculados y   }
{    SKUs generados.                                                           }
{******************************************************************************}
unit UniDataVariaciones;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmVariaciones = class(TdmBase)
    unqryArticulosVariacion: TUniQuery;
    dsArticulosVariacion: TDataSource;
    unqryAtributosVariacion: TUniQuery;
    dsAtributosVariacion: TDataSource;
    unqrySkusArticulo: TUniQuery;
    dsSkusArticulo: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryAtributosVariacionAfterInsert(DataSet: TDataSet);
    procedure unqryAtributosVariacionBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

uses
  inMtoVariaciones, inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmVariaciones.DataModuleCreate(Sender: TObject);
var
  LDsTablaG: TDataSource;
begin
  inherited;
  LDsTablaG := (GetOwnerForm<TfrmMtoVariaciones>).dsTablaG;

  unqryArticulosVariacion.Connection := oConn;
  unqryArticulosVariacion.MasterSource := LDsTablaG;
  unqryArticulosVariacion.Open;

  unqryAtributosVariacion.Connection := oConn;
  unqryAtributosVariacion.MasterSource := LDsTablaG;
  unqryAtributosVariacion.Open;

  unqrySkusArticulo.Connection := oConn;
  unqrySkusArticulo.Open;
end;

procedure TdmVariaciones.unqryAtributosVariacionAfterInsert(DataSet: TDataSet);
begin
  inherited;
  DataSet.FieldByName('ID_VAR_VA').AsString :=
                                  unqryTablaG.FieldByName(
                                    'CODIGO_VAR').AsString;
end;

procedure TdmVariaciones.unqryAtributosVariacionBeforePost(DataSet: TDataSet);
begin
  inherited;
  if Trim(DataSet.FieldByName('ID_ATB_VA').AsString) = '' then
    raise Exception.Create('El código del atributo es obligatorio.');
end;

initialization
  ForceReferenceToClass(TdmVariaciones);
end.
