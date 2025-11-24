{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit UniDataGeneradorProcesos;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, UniDataConn;

type
  TdmGeneradorProcesos = class(TdmBase)
    unstrdprcContador: TUniStoredProc;
    unqryMetadatos: TUniQuery;
    dsMetadatos: TDataSource;
    dsEstructura: TDataSource;
    unqryEstructura: TUniQuery;
    dsContenido: TDataSource;
    unqryContenido: TUniQuery;
    unstrdprcRefresh: TUniStoredProc;
    unqryVista: TUniQuery;
    dsVista: TDataSource;
    unqryCommand: TUniQuery;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
  public
    procedure GetCodigoAutoGeneradorProcesos;
    //procedure GetCodigoAutoRetencion;
  end;

var
  dmGeneradorProcesos: TdmGeneradorProcesos;

implementation

uses
  inMtoGeneradorProcesos, inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmGeneradorProcesos.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryTablaG.FindField('CODIGO_GENERADORPROCESO').AsString := '0';
end;

procedure TdmGeneradorProcesos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unstrdprcContador.Connection := oConn;
  unqryMetadatos.Connection := oConn;
  unqryEstructura.Connection := oConn;
  unqryContenido.Connection := oConn;
  unstrdprcRefresh.Connection := oConn;
  unqryCommand.Connection := oConn;
end;

procedure TdmGeneradorProcesos.GetCodigoAutoGeneradorProcesos;
begin
  if unqryTablaG.FindField('CODIGO_GENERADORPROCESO').AsString = '0' then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'GP';
      ExecProc;
      unqryTablaG.FindField('CODIGO_GENERADORPROCESO').AsString := ParamByName('pcont').AsString;
    end;
  end;
end;

procedure TdmGeneradorProcesos.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  GetCodigoAutoGeneradorProcesos;
end;
initialization
  ForceReferenceToClass(TdmGeneradorProcesos);
end.
