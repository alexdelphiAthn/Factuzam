{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

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
  private
    function UsuarioEsGrupo(sUsuario:string):boolean;
  public
    { Public declarations }
  end;

//var
//  dmUsuarios: TdmUsuarios;

implementation

uses
  inLibtb, inLibGlobalVar;

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
                 ' WHERE GRUPO_GRUPO = :grupo ';
    ParamByName('grupo').AsString := sUsuario;
    Open;
    Result := unqrySol.RecordCount > 0;
  end;
  FreeAndNil(unqrySol);
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
    sUsuario := Trim(FindField('USUARIO_USUARIO').AsString);
    if ((sUsuario = '') or (SimbolosProhibidos(sUsuario))) then
    begin
      ShowMessageFmt('%s no es un valor de registro válido ' +
                     'para el campo usuario',[sUsuario]);
      bError := True;
    end;
    if (UsuarioEsGrupo(sUsuario)) then
    begin
      ShowMessageFmt('El usuario %s es coincidente con el grupo %s',[sUsuario]);
      bError := True;
    end;
    if bError then
      Abort;
  end;
end;

initialization
  ForceReferenceToClass(TdmUsuarios);
end.
