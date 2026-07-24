{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAlmacenes                                              }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de almacenes.                                                 }
{    Maestro de fza_almacenes y consulta auxiliar de cajas por almacén.        }
{******************************************************************************}
unit UniDataAlmacenes;
interface
uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser;
type
  TdmAlmacenes = class(TdmBase)
    qryAlmacenesCajas: TUniQuery;
    dsAlmacenesCajas: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;
implementation

uses
  inMtoAlmacenes;
{%CLASSGROUP 'Vcl.Controls.TControl'}
{$R *.dfm}
procedure ForceReferenceToClass(C: TClass); begin end;
procedure TdmAlmacenes.DataModuleCreate(Sender: TObject);
begin
  inherited;
  qryAlmacenesCajas.Connection := ConexionPrincipal;
  qryAlmacenesCajas.Open;
  qryAlmacenesCajas.MasterSource := (GetOwnerForm<TfrmMtoAlmacenes>).dsTablaG;
end;


procedure TdmAlmacenes.DataModuleDestroy(Sender: TObject);
begin
  qryAlmacenesCajas.Close;
  inherited;
end;

initialization
  ForceReferenceToClass(TdmAlmacenes);
end.
