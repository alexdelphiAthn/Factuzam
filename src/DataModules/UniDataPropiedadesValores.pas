{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit UniDataPropiedadesValores;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmPropiedadesValores = class(TdmBase)
    unqryPropiedades: TUniQuery;
    dsPropiedades: TDataSource;
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

procedure TdmPropiedadesValores.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryPropiedades.Connection := oConn;
  if not unqryPropiedades.Active then
    unqryPropiedades.Open;
end;

initialization
  ForceReferenceToClass(TdmPropiedadesValores);
end.
