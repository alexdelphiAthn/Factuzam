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
    Connection := oConn;
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
  unqryEmpresas.Connection := oConn;
  unqryGrupos.Connection := oConn;
  unqryEmpresas.MasterSource :=  (GetOwnerForm<TfrmMtoUsuarios>).dsTablaG;
  //unqry
end;

procedure TdmUsuarios.unqryTablaGAfterInsert(DataSet: TDataSet);
var
  fld: TField;
begin
  inherited;
  // Campos traidos por el JOIN de vi_usuarios (fza_usuarios_grupos y
  // vi_empresas): son de solo lectura y no forman parte del INSERT sobre
  // fza_usuarios. UniDAC los marca Required por ser NOT NULL en su tabla
  // origen, lo que bloquea el alta. Se desactiva la obligatoriedad.
  fld := unqryTablaG.FindField('GRUPO_USUGRP');
  if (fld <> nil) then
    fld.Required := False;
  fld := unqryTablaG.FindField('ESGRUPOADMINISTRADOR_USUGRP');
  if (fld <> nil) then
    fld.Required := False;
  fld := unqryTablaG.FindField('RAZON_SOCIAL_EMP');
  if (fld <> nil) then
    fld.Required := False;
  // Usuario nuevo activo por defecto: caja y traspasos solo listan
  // empleados con ESACTIVO_USU = 'S'.
  fld := unqryTablaG.FindField('ESACTIVO_USU');
  if (fld <> nil) then
    fld.AsString := 'S';
end;

procedure TdmUsuarios.unqryTablaGBeforePost(DataSet: TDataSet);
var
  sUsuario:string;
  bError:Boolean;
begin
  inherited;
  // Insert vacío (accidental): cancelar sin error
  if (DataSet.State = dsInsert) and
     (Trim(unqryTablaG.FindField('USUARIO_USU').AsString) = '') then
    Abort;
  bError := False;
  with unqryTablaG do
  begin
    sUsuario := Trim(FindField('USUARIO_USU').AsString);
    if (sUsuario = '') or
       SimbolosProhibidos(sUsuario, PerfilesUsuario) then
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
