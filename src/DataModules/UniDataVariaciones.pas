{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit UniDataVariaciones;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmVariaciones = class(TdmBase)
    unqryArticulosVariacion: TUniQuery;
    dsArticulosVariacion: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

uses
  inMtoVariaciones;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmVariaciones.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryArticulosVariacion.Connection := oConn;
  unqryArticulosVariacion.MasterSource :=
                                  (GetOwnerForm<TfrmMtoVariaciones>).dsTablaG;
  unqryArticulosVariacion.Open;
end;

initialization
  ForceReferenceToClass(TdmVariaciones);
end.
