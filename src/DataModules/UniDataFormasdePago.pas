{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit UniDataFormasdePago;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, UniDataConn;

type
  TdmFormasdePago = class(TdmBase)
    unstrdprcContador: TUniStoredProc;
    unqryFacturasLineas: TUniQuery;
    unqryFacturas: TUniQuery;
    dsFacturas: TDataSource;
    dsFacturasLineas: TDataSource;
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
  public
    procedure GetCodigoAutoFormasdePago;
    //procedure GetCodigoAutoRetencion;
  end;

//var
//  dmFormasdePago: TdmFormasdePago;

implementation

uses
  inMtoFormasdePago, inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmFormasdePago.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryTablaG.FindField('CODIGO_FORMAPAGO').AsString := '0';
  unqryTablaG.FindField('ORDEN_FORMAPAGO').AsString := '0';
  unqryTablaG.FindField('PORCEN_ANTICIPO_FORMAPAGO').AsString := '0';
end;

procedure TdmFormasdePago.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unstrdprcContador.Connection := oConn;
  unqryFacturas.Connection := oConn;
  unqryFacturasLineas.Connection := oConn;
  unqryFacturas.MasterSource := (Self.Owner as TfrmMtoFormasdePago).dsTablaG;
  unqryFacturasLineas.MasterSource :=
                                (Self.Owner as TfrmMtoFormasdePago).dsTablaG;
  unqryFacturas.Open;
  unqryFacturasLineas.Open;
end;

procedure TdmFormasdePago.GetCodigoAutoFormasdePago;
begin
  if unqryTablaG.FindField('CODIGO_FORMAPAGO').AsString = '0' then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'PG';
      ExecProc;
      unqryTablaG.FindField('CODIGO_FORMAPAGO').AsString :=
                                                  ParamByName('pcont').AsString;
    end;
  end;
  if unqryTablaG.FindField('ORDEN_FORMAPAGO').AsString = '0' then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'GO';
      ExecProc;
      unqryTablaG.FindField('ORDEN_FORMAPAGO').AsString :=
                                                  ParamByName('pcont').AsString;
    end;
  end;
end;

procedure TdmFormasdePago.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
    with unqryTablaG do
  begin
    if Trim(FindField('DESCRIPCION_FORMAPAGO').AsString) = '' then
    begin
      raise ERangeError.CreateFmt('%s no es un valor válido ' +
                                  'para el campo Descripción de Formas de Pago',
               [FindField('DESCRIPCION_FORMAPAGO').AsString]);
      Abort;
    end
    else
      GetCodigoAutoFormasdePago;
  end;
end;

initialization
  ForceReferenceToClass(TdmFormasdePago);
end.
