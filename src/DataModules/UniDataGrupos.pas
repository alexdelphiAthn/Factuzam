{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataGrupos                                                 }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de grupos de usuarios.                                        }
{    Mantenimiento de fza_usuarios_grupos y consulta de usuarios asociados al  }
{    grupo.                                                                    }
{******************************************************************************}
unit UniDataGrupos;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmGrupos = class(TdmBase)
    unqryUsuariosGrupo: TUniQuery;
    dsUsuariosGrupo: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses inMtoGrupos, inLibGlobalVar;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmGrupos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryUsuariosGrupo.Connection := oConn;
  unqryTablaG.Connection := oConn;
  unqryUsuariosGrupo.Open;
end;

initialization
  ForceReferenceToClass(TdmGrupos);
end.
