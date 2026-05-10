{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit UniDataAtributosConjuntos;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmAtributosConjuntos = class(TdmBase)
    unqryConjuntoDetalle: TUniQuery;
    dsConjuntoDetalle: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryConjuntoDetalleAfterInsert(DataSet: TDataSet);
    procedure unqryConjuntoDetalleBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

uses
  inMtoAtributosConjuntos, inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmAtributosConjuntos.DataModuleCreate(Sender: TObject);
var
  LDsTablaG: TDataSource;
begin
  inherited;
  LDsTablaG := (GetOwnerForm<TfrmMtoAtributosConjuntos>).dsTablaG;

  unqryConjuntoDetalle.Connection := oConn;
  unqryConjuntoDetalle.MasterSource := LDsTablaG;
  unqryConjuntoDetalle.Open;
end;

procedure TdmAtributosConjuntos.unqryConjuntoDetalleAfterInsert(DataSet: TDataSet);
begin
  inherited;
  DataSet.FieldByName('ID_AC_ACD').AsInteger :=
                                    unqryTablaG.FieldByName('ID_AC').AsInteger;
end;

procedure TdmAtributosConjuntos.unqryConjuntoDetalleBeforePost(DataSet: TDataSet);
begin
  inherited;
  if DataSet.FieldByName('ID_AV_ACD').IsNull then
    raise Exception.Create('El identificador del valor (ID_AV_ACD) es obligatorio.');
end;

initialization
  ForceReferenceToClass(TdmAtributosConjuntos);
end.
