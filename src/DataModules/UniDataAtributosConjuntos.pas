{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAtributosConjuntos                                     }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de conjuntos de atributos.                                    }
{    Mantiene fza_atributos_conjuntos y su detalle de valores asociados a      }
{    artículos.                                                                }
{******************************************************************************}
unit UniDataAtributosConjuntos;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmAtributosConjuntos = class(TdmBase)
    unqryConjuntoDetalle: TUniQuery;
    dsConjuntoDetalle: TDataSource;
    unqryValoresLookup: TUniQuery;
    dsValoresLookup: TDataSource;
    unqryArticulosConjunto: TUniQuery;
    dsArticulosConjunto: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryConjuntoDetalleAfterInsert(DataSet: TDataSet);
    procedure unqryConjuntoDetalleBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

uses
  inMtoAtributosConjuntos, inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmAtributosConjuntos.DataModuleCreate(Sender: TObject);
var
  LDsTablaG: TDataSource;
begin
  inherited;
  LDsTablaG := (GetOwnerForm<TfrmMtoAtributosConjuntos>).dsTablaG;

  unqryValoresLookup.Connection := oConn;
  unqryValoresLookup.Open;

  unqryConjuntoDetalle.Connection := oConn;
  unqryConjuntoDetalle.MasterSource := LDsTablaG;
  unqryConjuntoDetalle.Open;

  unqryArticulosConjunto.Connection := oConn;
  unqryArticulosConjunto.MasterSource := LDsTablaG;
  unqryArticulosConjunto.Open;
end;

procedure TdmAtributosConjuntos.unqryConjuntoDetalleAfterInsert(
                                                             DataSet: TDataSet);
begin
  inherited;
  DataSet.FieldByName('ID_AC_ACD').AsInteger :=
                                     unqryTablaG.FieldByName('ID_AC').AsInteger;
end;

procedure TdmAtributosConjuntos.unqryConjuntoDetalleBeforePost(
                                                             DataSet: TDataSet);
begin
  inherited;
  if DataSet.FieldByName('ID_AV_ACD').IsNull then
    raise Exception.Create('Selecciona un valor para añadirlo a la colección.');
  oDmConn.ActualizarUserTimeModif(DataSet);
end;

initialization
  ForceReferenceToClass(TdmAtributosConjuntos);
end.
