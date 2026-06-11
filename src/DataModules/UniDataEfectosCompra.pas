{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataEfectosCompra                                           }
{    Tipo:       Data Module                                                    }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de efectos de pago (vi_efectos_compra).                      }
{******************************************************************************}
unit UniDataEfectosCompra;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmEfectosCompra = class(TdmBase)
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
  ForceReferenceToClass(TdmEfectosCompra);
end.
