{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit UniDataArticulosPropiedades;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmArticulosPropiedades = class(TdmBase)
    unqryPropiedades: TUniQuery;
    dsPropiedades: TDataSource;
    unqryValores: TUniQuery;
    dsValores: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses inLibGlobalVar;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmArticulosPropiedades.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryPropiedades.Connection := oConn;
  unqryValores.Connection := oConn;
  if not unqryPropiedades.Active then
    unqryPropiedades.Open;
  if not unqryValores.Active then
    unqryValores.Open;
end;

initialization
  ForceReferenceToClass(TdmArticulosPropiedades);
end.
