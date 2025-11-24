{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

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

var
  dmGrupos: TdmGrupos;

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
