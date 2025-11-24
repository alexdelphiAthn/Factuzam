{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit UniDataUsuariosPerfiles;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmUsuariosPerfiles = class(TdmBase)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

//var
//  dmUsuariosPerfiles: TdmUsuariosPerfiles;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses inMtoUsuariosPerfiles;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

initialization
  ForceReferenceToClass(TdmUsuariosPerfiles);
end.
