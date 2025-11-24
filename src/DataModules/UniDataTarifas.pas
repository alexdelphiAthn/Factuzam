{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit UniDataTarifas;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, UniDataConn;

type
  TdmTarifas = class(TdmBase)
    unstrdprcContador: TUniStoredProc;
    unqryArticulosTarifas: TUniQuery;
    dsArticulosTarifas: TDataSource;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
  public
    procedure GetCodigoAutoFamilia;
    //procedure GetCodigoAutoRetencion;
  end;

//var
//  dmTarifas: TdmTarifas;

implementation

uses
  inMtoTarifas, inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmTarifas.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryTablaG.FindField('CODIGO_TARIFA').AsString := '0';
end;

procedure TdmTarifas.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unstrdprcContador.Connection := oConn;
  unqryArticulosTarifas.Connection := oConn;
  unqryArticulosTarifas.Open;
end;

procedure TdmTarifas.GetCodigoAutoFamilia;
begin
  if unqryTablaG.FindField('CODIGO_TARIFA').AsString = '0' then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'TF';
      ExecProc;
      unqryTablaG.FindField('CODIGO_TARIFA').AsString := ParamByName('pcont').AsString;
    end;
  end;
end;

procedure TdmTarifas.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  GetCodigoAutoFamilia;
end;

initialization
  ForceReferenceToClass(TdmTarifas);
end.
