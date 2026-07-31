{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCajaPagosHist                                          }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module del histórico de pagos de caja.                               }
{    Contenedor de consultas sobre fza_caja_pagos para el histórico de cobros. }
{******************************************************************************}
unit UniDataCajaPagosHist;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmCajaPagosHist = class(TdmBase)
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
  RegistrarDataModule(TdmCajaPagosHist);
  ForceReferenceToClass(TdmCajaPagosHist);
end.
