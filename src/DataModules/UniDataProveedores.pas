{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataProveedores                                            }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de proveedores.                                               }
{    Mantenimiento de fza_proveedores y consulta de artículos y líneas de      }
{    facturas asociadas.                                                       }
{******************************************************************************}
unit UniDataProveedores;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, UniDataConn;

type
  TdmProveedores = class(TdmBase)
    unstrdprcContador: TUniStoredProc;
    unqryArticulos: TUniQuery;
    dsArticulos: TDataSource;
    unqryLinFacturasArticulos: TUniQuery;
    dsLinFacturasArticulos: TDataSource;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    procedure GetCodigoAutoProveedor;
    // Override: ya no abre nada en el flujo inicial. Las dos queries
    // detail (Articulos, LinFacturasArticulos) son lazy por sub-pestaña.
    procedure AbrirDetalles; override;
    procedure AsegurarArticulosAbierta;
    procedure AsegurarVentasAbierta;
  end;

//var
//  dmmProveedores: TdmProveedores;

implementation

uses
  inMtoProveedores, inLibGlobalVar, inLibLog, System.Diagnostics;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmProveedores.DataModuleCreate(Sender: TObject);
begin
  inherited;
  // Solo Connection. Los .Open se han movido a AbrirDetalles.
  unstrdprcContador.Connection := oConn;
  unqryArticulos.Connection := oConn;
  unqryLinFacturasArticulos.Connection := oConn;
end;

procedure TdmProveedores.AbrirDetalles;
const
  TAG = 'Proveedores.AbrirDetalles';

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
        inLibLog.Log.LogPerf(TAG, Nombre + ' ERROR=' + E.Message,
          swQ.ElapsedMilliseconds);
    end;
  end;

var sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  // Ambas queries son lazy. AbrirDetalles solo registra el TOTAL para
  // mantener consistencia con los demas Mtos.
  inLibLog.Log.LogPerf(TAG, 'TOTAL (todo lazy)', sw.ElapsedMilliseconds);
end;

procedure TdmProveedores.AsegurarArticulosAbierta;
var swQ: TStopwatch;
begin
  if unqryArticulos.Active then Exit;
  swQ := TStopwatch.StartNew;
  try
    unqryArticulos.Open;
    inLibLog.Log.LogPerf('Proveedores.Lazy', 'unqryArticulos OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
      inLibLog.Log.LogPerf('Proveedores.Lazy',
        'unqryArticulos ERROR=' + E.Message, swQ.ElapsedMilliseconds);
  end;
end;

procedure TdmProveedores.AsegurarVentasAbierta;
var swQ: TStopwatch;
begin
  if unqryLinFacturasArticulos.Active then Exit;
  swQ := TStopwatch.StartNew;
  try
    unqryLinFacturasArticulos.Open;
    inLibLog.Log.LogPerf('Proveedores.Lazy', 'unqryLinFacturasArticulos OK',
      swQ.ElapsedMilliseconds);
  except
    on E: Exception do
      inLibLog.Log.LogPerf('Proveedores.Lazy',
        'unqryLinFacturasArticulos ERROR=' + E.Message,
        swQ.ElapsedMilliseconds);
  end;
end;

procedure TdmProveedores.GetCodigoAutoProveedor;
begin
  if unqryTablaG.FindField('CODIGO_PRV_PRV').AsString = '0' then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'PV';
      ExecProc;
      unqryTablaG.FindField('CODIGO_PRV_PRV').AsString :=
        ParamByName('pcont').AsString;
    end;
  end;
    if unqryTablaG.FindField('ORDEN_PRV').AsString = '0' then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'PO';
      ExecProc;
      unqryTablaG.FindField('ORDEN_PRV').AsString :=
        ParamByName('pcont').AsString;
    end;
  end;
end;

procedure TdmProveedores.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryTablaG.FindField('CODIGO_PRV_PRV').AsString := '0';
  unqryTablaG.FindField('ORDEN_PRV').AsString := '0';
end;

procedure TdmProveedores.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  GetCodigoAutoProveedor;
end;

initialization
  ForceReferenceToClass(TdmProveedores);
end.
