{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFormasdePago                                           }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de formas de pago.                                            }
{    Mantenimiento de fza_formas_pago y consulta de facturas/líneas que las    }
{    usan.                                                                     }
{******************************************************************************}
unit UniDataFormasdePago;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, UniDataConn;

type
  TdmFormasdePago = class(TdmBase)
    unstrdprcContador: TUniStoredProc;
    unqryFacturasLineas: TUniQuery;
    unqryFacturas: TUniQuery;
    dsFacturas: TDataSource;
    dsFacturasLineas: TDataSource;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
  public
    procedure GetCodigoAutoFormasdePago;
    //procedure GetCodigoAutoRetencion;
    procedure AbrirDetalles; override;
  end;

implementation

uses
  inMtoFormasdePago, inLibGlobalVar, inLibLog, System.Diagnostics;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmFormasdePago.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryTablaG.FindField('CODIGO_FP_FP').AsString := '0';
  unqryTablaG.FindField('ORDEN_FORMA_PAGO_FP').AsString := '0';
  unqryTablaG.FindField('PORCENTAJE_ANTICIPO_FORMA_PAGO_FP').AsString := '0';
end;

procedure TdmFormasdePago.DataModuleCreate(Sender: TObject);
begin
  inherited;
  // Solo Connection + MasterSource. Los .Open se han movido a AbrirDetalles.
  unstrdprcContador.Connection := oConn;
  unqryFacturas.Connection := oConn;
  unqryFacturasLineas.Connection := oConn;
  unqryFacturas.MasterSource := (GetOwnerForm<TfrmMtoFormasdePago>).dsTablaG;
  unqryFacturasLineas.MasterSource :=
                                   (GetOwnerForm<TfrmMtoFormasdePago>).dsTablaG;
end;

procedure TdmFormasdePago.AbrirDetalles;
const
  TAG = 'FormasdePago.AbrirDetalles';

  procedure AbrirConTiempo(qry: TUniQuery; const Nombre: string);
//  var swQ: TStopwatch;
  begin
    if qry.Active then Exit;
//    swQ := TStopwatch.StartNew;
//    try
      qry.Open;
//      inLibLog.Log.LogPerf(TAG, Nombre + ' OK', swQ.ElapsedMilliseconds);
//    except
//      on E: Exception do
//        inLibLog.Log.LogPerf(TAG, Nombre + ' ERROR=' + E.Message,
//          swQ.ElapsedMilliseconds);
//    end;
  end;

var sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  AbrirConTiempo(unqryFacturas,       'unqryFacturas');
  AbrirConTiempo(unqryFacturasLineas, 'unqryFacturasLineas');
//  inLibLog.Log.LogPerf(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmFormasdePago.GetCodigoAutoFormasdePago;
begin
  if unqryTablaG.FindField('CODIGO_FP_FP').AsString = '0' then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'PG';
      ExecProc;
      unqryTablaG.FindField('CODIGO_FP_FP').AsString :=
                                                  ParamByName('pcont').AsString;
    end;
  end;
  if unqryTablaG.FindField('ORDEN_FORMA_PAGO_FP').AsString = '0' then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'GO';
      ExecProc;
      unqryTablaG.FindField('ORDEN_FORMA_PAGO_FP').AsString :=
                                                  ParamByName('pcont').AsString;
    end;
  end;
end;

procedure TdmFormasdePago.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
    with unqryTablaG do
  begin
    if Trim(FindField('DESCRIPCION_FORMA_PAGO_FP').AsString) = '' then
      raise ERangeError.CreateFmt('%s no es un valor válido ' +
                                  'para el campo Descripción de Formas de Pago',
               [FindField('DESCRIPCION_FORMA_PAGO_FP').AsString]);
    GetCodigoAutoFormasdePago;
  end;
end;

initialization
  ForceReferenceToClass(TdmFormasdePago);
end.
