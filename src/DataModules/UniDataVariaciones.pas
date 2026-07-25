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
    procedure AbrirDetalles; override;
  end;

implementation

uses
  inMtoVariaciones, inLibLog, System.Diagnostics;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmVariaciones.DataModuleCreate(Sender: TObject);
var
  LDsTablaG: TDataSource;
begin
  inherited;
  // Solo Connection + MasterSource. Los .Open se han movido a AbrirDetalles.
  LDsTablaG := (GetOwnerForm<TfrmMtoVariaciones>).dsTablaG;
  unqryArticulosVariacion.Connection := ConexionPrincipal;
  unqryArticulosVariacion.MasterSource := LDsTablaG;
  unqryAtributosVariacion.Connection := ConexionPrincipal;
  unqryAtributosVariacion.MasterSource := LDsTablaG;
  unqrySkusArticulo.Connection := ConexionPrincipal;
end;

procedure TdmVariaciones.AbrirDetalles;
const
  TAG = 'Variaciones.AbrirDetalles';

  procedure AbrirConTiempo(qry: TUniQuery; const Nombre: string);
  var swQ: TStopwatch;
  begin
    if qry.Active then Exit;
    swQ := TStopwatch.StartNew;
    try
      qry.Open;
      inLibLog.Log.LogPerf(TAG, Nombre + ' OK', swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        inLibLog.Log.LogPerf(TAG, Nombre + ' ERROR=' + E.Message,
          swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;

var sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  AbrirConTiempo(unqryArticulosVariacion, 'unqryArticulosVariacion');
  AbrirConTiempo(unqryAtributosVariacion, 'unqryAtributosVariacion');
  AbrirConTiempo(unqrySkusArticulo,       'unqrySkusArticulo');
  inLibLog.Log.LogPerf(TAG, 'TOTAL', sw.ElapsedMilliseconds);
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
