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
  inLibUser;

type
  TdmAtributosConjuntos = class(TdmBase)
    unqryConjuntoDetalle: TUniQuery;
    dsConjuntoDetalle: TDataSource;
    unqryValoresLookup: TUniQuery;
    dsValoresLookup: TDataSource;
    unqryArticulosConjunto: TUniQuery;
    dsArticulosConjunto: TDataSource;
    unqryVariacionesLookup: TUniQuery;
    dsVariacionesLookup: TDataSource;
    unqryAtributosLookup: TUniQuery;
    dsAtributosLookup: TDataSource;
    unqryAtributosBasicosLookup: TUniQuery;
    dsAtributosBasicosLookup: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryConjuntoDetalleAfterInsert(DataSet: TDataSet);
    procedure unqryConjuntoDetalleBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure AbrirDetalles; override;
  end;

implementation

uses
  inMtoAtributosConjuntos, inLibGlobalVar, inLibLog, System.Diagnostics;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmAtributosConjuntos.DataModuleCreate(Sender: TObject);
var
  LDsTablaG: TDataSource;
begin
  inherited;
  // Solo Connection + MasterSource. Los .Open se han movido a AbrirDetalles.
  LDsTablaG := (GetOwnerForm<TfrmMtoAtributosConjuntos>).dsTablaG;
  unqryValoresLookup.Connection := oConn;
  unqryVariacionesLookup.Connection := oConn;
  unqryAtributosLookup.Connection := oConn;
  unqryAtributosBasicosLookup.Connection := oConn;
  unqryConjuntoDetalle.Connection := oConn;
  unqryConjuntoDetalle.MasterSource := LDsTablaG;
  unqryArticulosConjunto.Connection := oConn;
  unqryArticulosConjunto.MasterSource := LDsTablaG;
end;

procedure TdmAtributosConjuntos.AbrirDetalles;
const
  TAG = 'AtributosConjuntos.AbrirDetalles';

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
  AbrirConTiempo(unqryValoresLookup,          'unqryValoresLookup');
  AbrirConTiempo(unqryVariacionesLookup,      'unqryVariacionesLookup');
  AbrirConTiempo(unqryAtributosLookup,        'unqryAtributosLookup');
  AbrirConTiempo(unqryAtributosBasicosLookup, 'unqryAtributosBasicosLookup');
  AbrirConTiempo(unqryConjuntoDetalle,        'unqryConjuntoDetalle');
  AbrirConTiempo(unqryArticulosConjunto,      'unqryArticulosConjunto');
  inLibLog.Log.LogPerf(TAG, 'TOTAL', sw.ElapsedMilliseconds);
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
  ActualizarAuditoria(DataSet);
end;

initialization
  ForceReferenceToClass(TdmAtributosConjuntos);
end.
