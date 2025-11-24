{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit UniDataProveedores;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, UniDataConn;

type
  TdmProveedores = class(TdmBase)
    unstrdprcContador: TUniStoredProc;
    unqryArticulos: TUniQuery;
    dsArticulos: TDataSource;
    unqryLinFacturasArticulos: TUniQuery;
    dsLinFacturasArticulos: TDataSource;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    procedure GetCodigoAutoProveedor;
  end;

//var
//  dmmProveedores: TdmProveedores;

implementation

uses
  inMtoProveedores, inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmProveedores.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unstrdprcContador.Connection := oConn;
  unqryArticulos.Connection := oConn;
  unqryLinFacturasArticulos.Connection := oConn;
  unqryArticulos.Open;
  unqryLinFacturasArticulos.Open;
end;

procedure TdmProveedores.GetCodigoAutoProveedor;
begin
  if unqryTablaG.FindField('CODIGO_PROVEEDOR').AsString = '0' then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'PV';
      ExecProc;
      unqryTablaG.FindField('CODIGO_PROVEEDOR').AsString := ParamByName('pcont').AsString;
    end;
  end;
    if unqryTablaG.FindField('ORDEN_PROVEEDOR').AsString = '0' then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'PO';
      ExecProc;
      unqryTablaG.FindField('ORDEN_PROVEEDOR').AsString := ParamByName('pcont').AsString;
    end;
  end;
end;

procedure TdmProveedores.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryTablaG.FindField('CODIGO_PROVEEDOR').AsString := '0';
  unqryTablaG.FindField('ORDEN_PROVEEDOR').AsString := '0';
end;

procedure TdmProveedores.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  GetCodigoAutoProveedor;
end;

initialization
  ForceReferenceToClass(TdmProveedores);
end.
