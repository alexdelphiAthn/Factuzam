{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit UniDataFamilias;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess,
  Uni, inLibUser, UniDataConn;

type
  TdmFamilias = class(TdmBase)
    unstrdprcContador: TUniStoredProc;
    unqryArticulosFamilias: TUniQuery;
    dsArticulosFamilias: TDataSource;
    unqrySubFamilias: TUniQuery;
    dsSubFamilias: TDataSource;
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
//  dmFamilias: TdmFamilias;

implementation

uses
  inMtoFamilias, inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmFamilias.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  unqryTablaG.FindField('CODIGO_FAMILIA').AsString := '0';
  unqryTablaG.FindField('ORDEN_FAMILIA').AsString := '0';
  unqryTablaG.FindField('ACTIVO_FAMILIA').AsString := 'S';
  unqryTablaG.FindField('ESDEFAULT_FAMILIA').AsString := 'N';
end;

procedure TdmFamilias.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unstrdprcContador.Connection := oConn;
  unqryArticulosFamilias.Connection := oConn;
  unqrySubFamilias.Connection := oConn;
  unqryArticulosFamilias.MasterSource := (Owner as TfrmMtoFamilias).dsTablaG;
  unqryArticulosFamilias.Open;
  unqrySubFamilias.Open;

end;

procedure TdmFamilias.GetCodigoAutoFamilia;
begin
  if (unqryTablaG.FindField('CODIGO_Familia').AsString = '0') then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'FA';
      ExecProc;
      unqryTablaG.FindField('CODIGO_Familia').AsString :=
                                                  ParamByName('pcont').AsString;
    end;
  end;
  if (unqryTablaG.FindField('ORDEN_FAMILIA').AsString = '0') then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'FO';
      ExecProc;
      unqryTablaG.FindField('ORDEN_FAMILIA').AsString :=
                                                  ParamByName('pcont').AsString;
    end;
  end;

end;

procedure TdmFamilias.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
    with unqryTablaG do
  begin
    if Trim(FindField('NOMBRE_FAMILIA').AsString) = '' then
    begin
      raise ERangeError.CreateFmt('%s no es un valor válido ' +
                                       'para el campo Nombre de Familias',
               [FindField('NOMBRE_FAMILIA').AsString]);
      Abort;
    end
    else
    if (FindField('CODIGO_FAMILIA').AsString =
        FindField('CODIGO_SUBFAMILIA').AsString) then
    begin
      raise ERangeError.CreateFmt('%s no puede ser padre e hijo a la vez. ' +
                                       'Revise campo Familia Padre',
               [FindField('CODIGO_SUBFAMILIA').AsString]);
      Abort;
    end
    else
      if (FindField('CODIGO_FAMILIA').AsString = '0') then
        GetCodigoAutoFamilia;
  end;
end;
initialization
  ForceReferenceToClass(TdmFamilias);
end.
