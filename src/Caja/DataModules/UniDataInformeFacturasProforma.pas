{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataInformeFacturasProforma                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Prepara los datos del informe de proformas internas de caja.              }
{******************************************************************************}
unit UniDataInformeFacturasProforma;

interface

uses
  System.Classes, Data.DB, MemDS, DBAccess, Uni, UniDataGen;

type
  TdmInformeFacturasProforma = class(TdmBase)
    unqryProforma: TUniQuery;
    unqryLineas: TUniQuery;
  public
    procedure Cargar(AIdProforma: Int64);
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmInformeFacturasProforma.Cargar(AIdProforma: Int64);
begin
  unqryProforma.Close;
  unqryLineas.Close;
  unqryProforma.Connection := ConexionPrincipal;
  unqryLineas.Connection := ConexionPrincipal;
  unqryProforma.ParamByName('id_proforma').AsLargeInt := AIdProforma;
  unqryLineas.ParamByName('id_proforma').AsLargeInt := AIdProforma;
  unqryProforma.Open;
  unqryLineas.Open;
end;

end.
