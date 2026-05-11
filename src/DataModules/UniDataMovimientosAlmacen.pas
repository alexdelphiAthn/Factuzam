{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataMovimientosAlmacen                                     }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de movimientos de almacén.                                    }
{    Contenedor de consultas sobre fza_movimientos_almacen (kardex).           }
{******************************************************************************}
unit UniDataMovimientosAlmacen;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmMovimientosAlmacen = class(TdmBase)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

initialization
  ForceReferenceToClass(TdmMovimientosAlmacen);
end.
