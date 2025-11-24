{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit UniDataContadores;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser,  UniDataConn;

type
  TdmContadores = class(TdmBase)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

//var
//  dmContadores: TdmContadores;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

initialization
  ForceReferenceToClass(TdmContadores);
end.
