{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataDepositosCliente                                       }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de depósitos de cliente.                                      }
{    Mantenimiento de fza_depositos_cliente y su uso en operaciones de caja.   }
{******************************************************************************}
unit UniDataDepositosCliente;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmDepositosCliente = class(TdmBase)
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
  RegistrarDataModule(TdmDepositosCliente);
  ForceReferenceToClass(TdmDepositosCliente);
end.
