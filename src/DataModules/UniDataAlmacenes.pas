{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit UniDataAlmacenes;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn, inLibGlobalVar;

type
  TdmAlmacenes = class(TdmBase)
    qryAlmacenesCajas: TUniQuery;
    dsAlmacenesCajas: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

uses
  inMtoAlmacenes;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmAlmacenes.DataModuleCreate(Sender: TObject);
begin
  inherited;
  qryAlmacenesCajas.Connection := oConn;
  qryAlmacenesCajas.Open;
  qryAlmacenesCajas.MasterSource := (GetOwnerForm<TfrmMtoAlmacenes>).dsTablaG;
end;


procedure TdmAlmacenes.DataModuleDestroy(Sender: TObject);
begin
  qryAlmacenesCajas.Close;
  inherited;
end;

initialization
  ForceReferenceToClass(TdmAlmacenes);
end.
