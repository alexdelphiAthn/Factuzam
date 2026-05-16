{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataUsuarios                                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de usuarios.                                                  }
{    Mantenimiento de fza_usuarios y sus grupos y empresas asignadas.          }
{******************************************************************************}
unit UniDataUsuarios;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn, Vcl.Dialogs;

type
  TdmUsuarios = class(TdmBase)
    unqryGrupos: TUniQuery;
    dsGrupos: TDataSource;
    unqryEmpresas: TUniQuery;
    dsEmpresas: TDataSource;
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
  private
    function UsuarioEsGrupo(sUsuario:string):boolean;
  public
    { Public declarations }
  end;

implementation

uses
  inLibtb, inLibGlobalVar, inMtoUsuarios;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

function TdmUsuarios.UsuarioEsGrupo(sUsuario: string): boolean;
var
  unqrySol:TUniQuery;
begin
  unqrySol := TUniQuery.Create(Self);
  with unqrySol do
  begin
    Connection := inLibGlobalVar.oConn;
    SQL.Text :=  'SELECT * '+
                 '  FROM fza_usuarios_grupos ' +
                 ' WHERE GRUPO_USUGRP = :grupo ';
    ParamByName('grupo').AsString := sUsuario;
    Open;
    Result := unqrySol.RecordCount > 0;
  end;
  FreeAndNil(unqrySol);
end;

procedure TdmUsuarios.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryEmpresas.Connection := inLibGlobalVar.oConn;
  unqryGrupos.Connection := inLibGlobalVar.oConn;
  unqryEmpresas.MasterSource :=  (GetOwnerForm<TfrmMtoUsuarios>).dsTablaG;
  //unqry
end;

procedure TdmUsuarios.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
//  with unqryTablaG do
//  begin
//    FieldByName()
//  end;
end;

procedure TdmUsuarios.unqryTablaGBeforePost(DataSet: TDataSet);
var
  sUsuario:string;
  bError:Boolean;
begin
  inherited;
  bError := False;
  with unqryTablaG do
  begin
    sUsuario := Trim(FindField('USUARIO_USU').AsString);
    if ((sUsuario = '') or (SimbolosProhibidos(sUsuario))) then
    begin
      ShowMessageFmt('%s no es un valor de registro válido ' +
                     'para el campo usuario', [sUsuario]);
      bError := True;
    end;
    if (UsuarioEsGrupo(sUsuario)) then
    begin
      ShowMessageFmt('El usuario %s coincide con un grupo del sistema',
                     [sUsuario]);
      bError := True;
    end;
    if bError then
      Abort;
  end;
end;

initialization
  ForceReferenceToClass(TdmUsuarios);
end.
