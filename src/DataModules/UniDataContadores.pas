{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataContadores                                             }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de contadores.                                                }
{    Mantenimiento de la tabla fza_contadores para numeración automática de    }
{    documentos.                                                               }
{******************************************************************************}
unit UniDataContadores;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser,  UniDataConn;

type
  TdmContadores = class(TdmBase)
  private
    { Private declarations }
  public
    procedure AjustarContadores;
    procedure RefrescarContadores;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmContadores.AjustarContadores;
var
  oProcedimiento: TUniStoredProc;
begin
  oProcedimiento := TUniStoredProc.Create(nil);
  try
    oProcedimiento.Connection := unqryTablaG.Connection;
    oProcedimiento.StoredProcName := 'PRC_AJUSTAR_CONTADORES';
    oProcedimiento.Params.Clear;
    oProcedimiento.Params.CreateParam(ftString, 'p_USUARIO', ptInput);
    oProcedimiento.ParamByName('p_USUARIO').AsString :=
      IdentidadSesion.Usuario;
    oProcedimiento.ExecProc;
  finally
    FreeAndNil(oProcedimiento);
  end;
end;

procedure TdmContadores.RefrescarContadores;
begin
  if unqryTablaG.Active then
    unqryTablaG.Refresh;
end;

initialization
  RegistrarDataModule(TdmContadores);
  ForceReferenceToClass(TdmContadores);
end.
